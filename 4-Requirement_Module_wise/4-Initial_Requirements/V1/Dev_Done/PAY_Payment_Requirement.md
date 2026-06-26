# Payment Module — Requirement Specification Document
**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Automated Extraction)
**Module Code:** PAY | **Module Type:** Tenant Module
**Table Prefix:** `pay_*` | **Processing Mode:** FULL
**RBS Reference:** Module J — Fees & Finance Management (partial — payment gateway subsystem)

---

## 1. Executive Summary

The Payment module (PAY) is the online payment gateway integration layer for Prime-AI, enabling schools to collect student fees digitally through Razorpay (with a pluggable architecture that can accommodate additional gateways). The module implements a clean gateway abstraction via `PaymentService → GatewayManager → RazorpayGateway (implements PaymentGatewayInterface)` and uses an event-driven pattern for post-payment processing.

**Implementation Statistics:**
- Controllers: 2 (PaymentController, PaymentGatewayController)
- Models: 5 (Payment, PaymentGateway, PaymentHistory, PaymentRefund, PaymentWebhook)
- Services: 2 (PaymentService, GatewayManager)
- FormRequests: 1 (PaymentGatewayRequest)
- Gateways: 2 (BaseGateway, RazorpayGateway)
- Events: 2 (PaymentSucceeded, PaymentFailed)
- DTO: 1 (PaymentData)
- Contract: 1 (PaymentGatewayInterface)
- Tests: 8
- Completion: ~45%

**Critical Issues Identified:**

1. **SEC-004 — WEBHOOK BEHIND AUTH MIDDLEWARE:** The `handleWebhook()` method in `PaymentController` is exposed via a route that uses `auth` middleware. Razorpay webhooks are server-to-server calls — they have no user session or auth token. This means ALL webhook calls return **HTTP 401**, effectively disabling automatic payment status reconciliation. This is a critical production bug.

2. **NO DDL SCHEMA FOR `pay_*` TABLES:** The tenant_db_v2.sql file does not contain any `pay_*` table definitions. The models reference table names like `ptm_payment_gateways` (note the `ptm_` prefix — a typo/inconsistency). The database schema is entirely undefined. This module has no migration foundation.

3. **TABLE PREFIX INCONSISTENCY:** `PaymentController` validates `gateway` against `ptm_payment_gateways` (`exists:ptm_payment_gateways,code`) — but the module prefix convention requires `pay_*`. This inconsistency must be resolved.

4. **PLAINTEXT GATEWAY CREDENTIALS:** `GatewayManager::resolve()` passes `$gateway->credentials` directly from the database to `RazorpayGateway`. There is no encryption layer for API keys and secrets stored in the payment gateway table.

---

## 2. Module Overview

### 2.1 Business Purpose

Indian schools increasingly require online fee collection capabilities. The Payment module provides:
- Integration with Razorpay (India's leading payment gateway) for fee collection
- Pluggable gateway architecture allowing future addition of PayU, Paytm, Instamojo, etc.
- Complete payment lifecycle: initiation → gateway redirect → webhook confirmation → receipt
- Polymorphic payable design linking payments to any entity (fee invoice, exam fee, etc.)
- Idempotent webhook handling preventing double-processing of payments
- Refund tracking capability

### 2.2 Feature Summary

| Feature | Status |
|---------|--------|
| Razorpay Order Creation | Implemented — `RazorpayGateway::initiate()` |
| Payment History Tracking | Implemented — `PaymentHistory` model |
| Webhook Handling (Razorpay) | Implemented but blocked by auth middleware (SEC-004) |
| Webhook Signature Verification | Implemented — HMAC-SHA256 via X-Razorpay-Signature |
| Payment Success/Failure Events | Implemented — `PaymentSucceeded`, `PaymentFailed` |
| Gateway Configuration UI | `PaymentGatewayController` exists |
| Refund Processing | `PaymentRefund` model exists, no controller |
| Receipt Generation | NOT implemented |
| Polymorphic Payable | Implemented via `payable_type` / `payable_id` |
| Gateway Credential Encryption | NOT implemented — plaintext storage |
| pay_* DDL Schema | NOT DEFINED |

### 2.3 Menu Path

`Tenant Dashboard > Finance > Payment Gateway`
- Gateway Settings
- Payment Transactions
- Refunds
- Webhook Logs

### 2.4 Architecture — Pluggable Gateway Pattern

```
[Fee Collection Form]
    → POST /payments/make-payment
    → PaymentController::makePayment()
    → PaymentService::createPayment($data)
        1. Create PaymentHistory (status='initiated')
        2. GatewayManager::resolve($gateway_code)
            → PaymentGateway::where('code', $code)->first()
            → new $gateway->driver($credentials, $extraConfig)   // driver class from DB
        3. RazorpayGateway::initiate(PaymentData $dto)
            → Razorpay\Api\Api::order->create([...])
        4. Update PaymentHistory (order_id = Razorpay order_id)
        5. Return checkout_data
    → Render razorpay.process-payment view (Razorpay Checkout.js)

[Customer completes payment on Razorpay]
    → Razorpay calls POST /webhooks/payment/{gateway}   [BROKEN — auth middleware]
    → PaymentController::handleWebhook()
        1. Store raw payload in PaymentWebhook
        2. GatewayManager::resolve(gateway)
        3. verifyWebhookSignature() — HMAC-SHA256
        4. processWebhookEvent():
            - payment.captured → PaymentHistory::markSuccess($paymentId) → PaymentSucceeded::dispatch()
            - payment.failed → PaymentHistory::markFailed() → PaymentFailed::dispatch()
        5. Mark webhook processed_at
```

---

## 3. Stakeholders & Actors

| Actor | Role | Access |
|-------|------|--------|
| School Admin (Finance) | Configure gateways, view all transactions | Full access |
| Bursar / Accountant | View transactions, process refunds | View + refund |
| Parent | Initiate fee payment | Initiate payment only |
| Razorpay (external) | Send webhooks for payment events | Unauthenticated webhook endpoint |
| System | Process payment events, update fee records | Automated via event listeners |

---

## 4. Functional Requirements

### FR-PAY-01: Payment Gateway Configuration

**RBS Ref:** F.J3.2 — Online Payments / Gateway Integration

**REQ-PAY-01.1 — Gateway CRUD**
- Admin shall be able to create, view, edit, and delete payment gateway configurations.
- Gateway record fields: `name`, `code` (unique), `driver` (fully-qualified class name), `credentials` (JSON, encrypted at rest), `extra_config` (JSON), `is_active`.
- At minimum, the system shall support Razorpay as the default gateway.
- Only active gateways shall be available for payment initiation.

**REQ-PAY-01.2 — Credential Security**
- Gateway credentials (API key, secret, webhook secret) shall be encrypted before storing in the database.
- The `GatewayManager` shall decrypt credentials before passing them to the gateway driver.
- Credential fields shall not be exposed in API responses or logs.

**REQ-PAY-01.3 — Gateway Testing**
- Admin shall be able to test a configured gateway by initiating a test order (₹1 amount) from the settings page.

**Acceptance Criteria:**
- Given admin creates a Razorpay gateway with valid key/secret, a test order can be created.
- Given gateway `is_active = false`, `GatewayManager::resolve()` throws "not found or inactive" exception.
- Given invalid credentials, `RazorpayGateway` constructor throws "credentials are missing" exception.

**Current Implementation:**
- `PaymentGatewayController` exists with `PaymentGatewayRequest` for validation.
- `GatewayManager::resolve()` fetches gateway from DB and instantiates driver class.
- No encryption of credentials — stored as plaintext JSON.

---

### FR-PAY-02: Payment Initiation

**RBS Ref:** F.J3.2 — Gateway Integration / Auto-reconcile

**REQ-PAY-02.1 — Create Razorpay Order**
- The system shall accept a payment request with: `amount` (numeric, min 1), `gateway` (code), `payable_type` (model class), `payable_id` (int).
- Amount shall be in INR (default currency).
- A `PaymentHistory` record shall be created with `status = 'initiated'` before calling the gateway.
- The Razorpay order shall be created via `Api::order->create(['receipt' => $paymentId, 'amount' => $amount * 100, 'currency' => 'INR', 'payment_capture' => 1])`.
- The `PaymentHistory.order_id` shall be updated with the Razorpay `order_id` on success.

**REQ-PAY-02.2 — Checkout Rendering**
- On successful order creation, the system shall render `payment::razorpay.process-payment` view with `checkout_data`:
  - `key`: Razorpay public key
  - `order_id`: Razorpay order ID
  - `amount`: order amount in paise
  - `currency`: 'INR'

**REQ-PAY-02.3 — Polymorphic Payable**
- Payment is associated to any payable entity via `payable_type` (e.g., `App\Models\FeeInvoice`) and `payable_id`.
- This allows the same payment infrastructure to serve fee invoices, exam fees, hostel charges, etc.

**Acceptance Criteria:**
- Given valid request, Razorpay order is created and checkout view is rendered.
- Given Razorpay API throws exception, user is redirected back with error message.
- Given `payable_type` does not correspond to a valid model, validation fails.

**Current Implementation:**
- `PaymentController::makePayment()` — fully implemented.
- `PaymentService::createPayment()` — fully implemented.
- `RazorpayGateway::initiate()` — fully implemented.
- Validation uses `exists:ptm_payment_gateways,code` — table name prefix inconsistency (should be `pay_payment_gateways`).

---

### FR-PAY-03: Webhook Processing

**RBS Ref:** F.J3.2 — Auto-reconcile online payments

**REQ-PAY-03.1 — Webhook Endpoint Security (CRITICAL FIX REQUIRED)**
- The webhook endpoint `POST /webhooks/payment/{gateway}` MUST be excluded from `auth` middleware.
- Webhook authentication shall be performed via signature verification, not session/token auth.
- The webhook endpoint must be added to Laravel's CSRF exemption list.

**REQ-PAY-03.2 — Signature Verification**
- For Razorpay: compute `hash_hmac('sha256', $request->getContent(), $webhookSecret)` and compare with `X-Razorpay-Signature` header using `hash_equals()` (timing-safe comparison).
- If signature verification fails, return HTTP 400 with error message.
- If webhook secret is not configured, throw exception and return HTTP 400.

**REQ-PAY-03.3 — Event Processing**
- `payment.captured` event: Find `PaymentHistory` by `order_id`, call `markSuccess($razorpayPaymentId, $payload)`, dispatch `PaymentSucceeded` event.
- `payment.failed` event: Find `PaymentHistory` by `order_id`, call `markFailed($payload)`, dispatch `PaymentFailed` event.
- Idempotency: if `PaymentHistory` is already in success state (`isSuccess()` returns true), skip processing and return HTTP 200.
- All received webhooks shall be stored in `PaymentWebhook` table before processing.

**REQ-PAY-03.4 — Webhook Logging**
- Store all incoming webhook payloads in `pay_payment_webhooks` table.
- Mark webhook as `processed = true` with `processed_at` timestamp on successful handling.
- On failure, webhook remains unprocessed with error logged.

**Acceptance Criteria:**
- Given Razorpay sends `payment.captured` webhook with valid signature → PaymentHistory status updated to 'success', PaymentSucceeded dispatched.
- Given invalid webhook signature → HTTP 400 returned, PaymentHistory unchanged.
- Given duplicate `payment.captured` for already-successful payment → HTTP 200 returned, no double-processing.
- Given webhook endpoint is currently behind auth middleware → HTTP 401 always returned (CURRENT BUG — SEC-004).

**Current Implementation:**
- `handleWebhook()` method is fully implemented logically.
- `verifyWebhookSignature()` — correct HMAC-SHA256 with timing-safe comparison.
- `processWebhookEvent()` — idempotency check implemented.
- **BUG SEC-004:** Routes file (`web.php`) uses `auth` middleware — webhook always gets HTTP 401.

---

### FR-PAY-04: Payment History & Tracking

**RBS Ref:** F.J3.1, F.J8.1

**REQ-PAY-04.1 — Payment History**
- Each payment attempt shall create a `PaymentHistory` record.
- Status lifecycle: `initiated` → `success` / `failed`.
- The `markSuccess($paymentId, $payload)` method shall update: `gateway_payment_id`, `status = 'success'`, `gateway_payload` (full webhook payload), `paid_at`.
- The `markFailed($payload)` method shall update: `status = 'failed'`, `failure_reason`, `gateway_payload`.
- `isSuccess()` helper method checks if `status == 'success'`.

**REQ-PAY-04.2 — Payment Dashboard**
- Admin shall view paginated list of all payment transactions with gateway, amount, status, date.
- Filter by: date range, gateway, status, payable type.

**Current Implementation:**
- `PaymentHistory` model exists with `markSuccess()`, `markFailed()`, `isSuccess()` methods assumed.
- `PaymentController::paymentManagement()` returns list view with both gateways and histories.

---

### FR-PAY-05: Refund Processing

**RBS Ref:** F.J6.2

**REQ-PAY-05.1 — Refund Initiation**
- Admin shall be able to initiate a refund for a successful payment.
- Refund fields: `payment_id` (FK to PaymentHistory), `amount`, `reason`, `status`, `gateway_refund_id`, `refunded_at`.
- Full and partial refunds shall be supported.
- Razorpay refund API shall be called to process the refund.

**Current Implementation:**
- `PaymentRefund` model exists.
- No controller or route for refunds.
- Razorpay refund API not yet integrated.

---

## 5. Data Model

### 5.1 CRITICAL: No DDL Defined

**The `pay_*` tables have no DDL definition in `tenant_db_v2.sql`.** The model references `ptm_payment_gateways` (which appears to be a typo of `pay_`). The following schema must be created.

### 5.2 Proposed Table: `pay_payment_gateways`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| tenant_id | INT UNSIGNED | NOT NULL | Multi-tenant |
| name | VARCHAR(100) | NOT NULL | Display name |
| code | VARCHAR(50) | NOT NULL, UNIQUE(tenant_id,code) | e.g., 'razorpay' |
| driver | VARCHAR(255) | NOT NULL | FQCN of gateway driver class |
| credentials | JSON | NULL | Encrypted API credentials |
| extra_config | JSON | NULL | Additional gateway settings |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |
| deleted_at | TIMESTAMP NULL | | Soft delete |

**Index:** `idx_pay_gateway_code` on (`tenant_id`, `code`)

### 5.3 Proposed Table: `pay_payment_history`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| tenant_id | INT UNSIGNED | NOT NULL | |
| payable_type | VARCHAR(255) | NOT NULL | Polymorphic — model class |
| payable_id | INT UNSIGNED | NOT NULL | Polymorphic — record ID |
| gateway | VARCHAR(50) | NOT NULL | Gateway code used |
| order_id | VARCHAR(255) | NULL, UNIQUE | Razorpay order_id |
| gateway_payment_id | VARCHAR(255) | NULL | Razorpay payment_id (after capture) |
| amount | DECIMAL(12,2) | NOT NULL | In major currency unit (INR) |
| currency | CHAR(3) | DEFAULT 'INR' | |
| status | ENUM | NOT NULL | initiated / success / failed |
| failure_reason | TEXT | NULL | |
| gateway_payload | JSON | NULL | Full webhook payload |
| paid_at | DATETIME | NULL | When payment was confirmed |
| created_by | INT UNSIGNED | NULL | FK → sys_user |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |
| deleted_at | TIMESTAMP NULL | | |

**Indexes:** `idx_pay_order` on (`order_id`), `idx_pay_payable` on (`payable_type`, `payable_id`), `idx_pay_status` on (`status`, `paid_at`)

### 5.4 Proposed Table: `pay_payment_webhooks`

| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED PK | |
| tenant_id | INT UNSIGNED | |
| gateway | VARCHAR(50) | Gateway identifier |
| event_type | VARCHAR(100) NULL | e.g., 'payment.captured' |
| payload | JSON | Raw webhook payload |
| processed | TINYINT(1) | DEFAULT 0 |
| processed_at | DATETIME NULL | |
| error_message | TEXT NULL | If processing failed |
| created_at | TIMESTAMP | |
| updated_at | TIMESTAMP | |

**Index:** `idx_pay_webhook_gateway` on (`gateway`, `processed`)

### 5.5 Proposed Table: `pay_payment_refunds`

| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED PK | |
| payment_history_id | INT UNSIGNED | FK → pay_payment_history |
| amount | DECIMAL(12,2) | Refund amount |
| reason | TEXT NULL | Reason for refund |
| status | ENUM | pending / processed / failed |
| gateway_refund_id | VARCHAR(255) NULL | Razorpay refund_id |
| refunded_at | DATETIME NULL | |
| initiated_by | INT UNSIGNED | FK → sys_user |
| is_active | TINYINT(1) | DEFAULT 1 |
| created_at | TIMESTAMP | |
| updated_at | TIMESTAMP | |

### 5.6 Existing Model — PaymentData DTO

```
PaymentData:
  paymentId: string     (PaymentHistory.id as string)
  amount: float         (in INR)
  currency: string      (default 'INR')
  payableType: string   (model class)
  payableId: int        (record ID)
```

---

## 6. API & Route Specification

### 6.1 Current Web Routes (`routes/web.php`)

```php
Route::middleware(['auth', 'verified'])->group(function () {
    Route::resource('payments', PaymentController::class)->names('payment');
});
```

**Issues:**
- Resource route is too broad — `PaymentController` has custom methods not matching REST.
- Webhook route must be OUTSIDE the auth middleware group.

### 6.2 Required Route Structure

```php
// ── Authenticated tenant routes ─────────────────────────────────────────
Route::middleware(['auth', 'verified', 'tenant'])->prefix('finance/payments')->group(function () {

    // Gateway Configuration
    Route::resource('gateways', PaymentGatewayController::class)
         ->names('payment.gateway');
    Route::post('gateways/{gateway}/test', [PaymentGatewayController::class, 'test'])
         ->name('payment.gateway.test');

    // Payment Management
    GET  /                                → PaymentController@paymentManagement  → payment.payment-management
    POST /make-payment                    → PaymentController@makePayment         → payment.make-payment
    POST /callback                        → PaymentController@makePaymentCallback → payment.callback
    GET  /history                         → PaymentController@index               → payment.index
    GET  /refunds                         → RefundController@index                → payment.refunds.index
    POST /refunds                         → RefundController@store                → payment.refunds.store
});

// ── UNAUTHENTICATED webhook endpoint ────────────────────────────────────
Route::post('/webhooks/payment/{gateway}', [PaymentController::class, 'handleWebhook'])
     ->name('payment.webhook')
     ->withoutMiddleware(['auth', 'verified', 'tenant']);
     // Must also add to CSRF exception in VerifyCsrfToken middleware
```

### 6.3 API Responses

**Make Payment — Success:**
```json
{ "redirect": "<razorpay checkout view rendered>" }
```

**Make Payment — Failure:**
```
Redirect back with: error = "Payment initiation failed: <message>"
```

**Webhook — Success:**
```json
{ "status": "ok" }
```

**Webhook — Failure:**
```json
{ "error": "<message>" }
```

---

## 7. UI Screen Inventory

| Screen | Route | Status |
|--------|-------|--------|
| Payment Management Dashboard | /finance/payments | Partially implemented |
| Gateway List & Config | /finance/payments/gateways | Controller exists, route needs fix |
| Add/Edit Gateway | /finance/payments/gateways/create | Controller exists |
| Make Payment (fee initiation) | /finance/payments/make-payment | Implemented |
| Razorpay Checkout | payment::razorpay.process-payment | View exists |
| Payment History | /finance/payments/history | Partially implemented |
| Refund Management | /finance/payments/refunds | Model only, no UI |
| Webhook Logs | /finance/payments/webhooks | NOT implemented |

---

## 8. Business Rules & Domain Constraints

**BR-PAY-01:** Only one gateway with `code = 'razorpay'` can be active at a time per tenant.

**BR-PAY-02:** Webhook processing is idempotent — if a `PaymentHistory` record is already in `status = 'success'`, subsequent `payment.captured` webhooks for the same `order_id` must be silently acknowledged (HTTP 200) without re-processing.

**BR-PAY-03:** Gateway credentials (key, secret, webhook_secret) must be stored encrypted. Plaintext storage is a P0 security issue. Use Laravel's `Crypt::encryptString()` / `Crypt::decryptString()` or a dedicated vault service.

**BR-PAY-04:** Amounts are stored in INR (major unit, DECIMAL(12,2)). When calling Razorpay API, amounts must be converted to paise (multiply by 100).

**BR-PAY-05:** A `PaymentHistory` record transitions through states in one direction only: `initiated → success` or `initiated → failed`. Successful payments cannot be moved back to failed or initiated.

**BR-PAY-06:** The webhook endpoint must not require authentication. It must only validate the Razorpay signature using `X-Razorpay-Signature` header.

**BR-PAY-07:** Refunds can only be initiated for payments in `status = 'success'`. The refund amount cannot exceed the original payment amount.

**BR-PAY-08:** All gateway driver classes must implement `PaymentGatewayInterface` with methods: `initiate(PaymentData $data): array`, `verify(array $payload): bool`, `handleWebhook(array $payload): void`.

---

## 9. Workflow & State Machines

### 9.1 Payment Lifecycle

```
INITIATION
  → User clicks "Pay Now"
  → PaymentHistory created (status = 'initiated')
  → Razorpay order created
  → User redirected to Razorpay Checkout

PAYMENT PROCESSING (on Razorpay's servers)
  → User enters card/UPI details
  → Razorpay processes payment

RESULT (via Webhook — currently broken SEC-004)
  → payment.captured → markSuccess() → status = 'success' → PaymentSucceeded event
  → payment.failed   → markFailed()  → status = 'failed'  → PaymentFailed event

POST-PAYMENT
  → PaymentSucceeded listener updates fee invoice as paid
  → Notification sent to parent/student
  → Receipt generated
```

### 9.2 PaymentHistory Status Machine

```
initiated ─── [Razorpay payment.captured webhook] ──→ success
          ─── [Razorpay payment.failed webhook] ────→ failed
```

### 9.3 Refund State Machine

```
pending ─── [Admin initiates refund, Razorpay API called] ──→ processed
        ─── [Razorpay refund API fails] ──────────────────→ failed
```

---

## 10. Non-Functional Requirements

**NFR-PAY-01 (Security — P0):** Gateway credentials stored in `pay_payment_gateways.credentials` MUST be encrypted. The webhook endpoint MUST be removed from `auth` middleware. These are production-blocking security defects.

**NFR-PAY-02 (Idempotency):** Webhook processing must be idempotent. Network timeouts can cause Razorpay to retry webhooks. The system must handle duplicate `payment.captured` events gracefully.

**NFR-PAY-03 (Reliability):** The system should queue webhook processing for non-trivial handlers (e.g., updating fee records, sending receipts). The `PaymentSucceeded` event handler should implement `ShouldQueue` for fee update processing.

**NFR-PAY-04 (Audit):** All payment events (initiation, success, failure, refund) shall be logged to `sys_activity_logs` via the platform's audit trail.

**NFR-PAY-05 (PCI-DSS Awareness):** The system must never log raw payment card data. Razorpay's tokenization ensures card data never reaches the Prime-AI servers.

**NFR-PAY-06 (Extensibility):** Adding a new payment gateway should require only: (a) creating a new class implementing `PaymentGatewayInterface`, (b) inserting a `pay_payment_gateways` record with the driver FQCN. No core code changes required.

---

## 11. Cross-Module Dependencies

| Dependency | Direction | Purpose |
|-----------|-----------|---------|
| Finance/Fees (fin_*) | Consumes | `PaymentSucceeded` event updates `fin_fee_payments` as paid |
| Notification (ntf_*) | Consumes | Fire PAYMENT_RECEIVED event after successful webhook |
| SystemConfig (sys_*) | Consumes | `sys_user` for `created_by`; `sys_activity_logs` for audit |
| Student Management | Consumes | Link payment to student via payable polymorphism |
| Razorpay SDK | External | `razorpay/razorpay` Composer package |
| Laravel Queue | Infrastructure | For async webhook processing (recommended) |

---

## 12. Test Coverage

**Current Tests (8 files):**

| Test File | Type | What It Tests |
|-----------|------|---------------|
| PaymentControllerTest.php | Feature | Controller HTTP tests |
| PaymentGatewayControllerTest.php | Feature | Gateway CRUD tests |
| GatewayManagerTest.php | Unit | GatewayManager resolve logic |
| PaymentDataDtoTest.php | Unit | PaymentData DTO construction |
| PaymentEventsTest.php | Unit | PaymentSucceeded/Failed event dispatch |
| PaymentGatewayModelTest.php | Unit | PaymentGateway model |
| PaymentGatewayRequestTest.php | Unit | Form request validation |
| PaymentHistoryModelTest.php | Unit | PaymentHistory model methods |

**Missing Tests:**

| Test | Priority | Reason |
|------|----------|--------|
| WebhookSignatureVerificationTest | P0 | SEC-004 — webhook security critical |
| RazorpayGatewayTest | P0 | Core payment initiation path |
| PaymentIdempotencyTest | P1 | Duplicate webhook handling |
| RefundWorkflowTest | P1 | Refund lifecycle |

---

## 13. Glossary

| Term | Definition |
|------|-----------|
| Gateway | A payment processing service (e.g., Razorpay, PayU) |
| Order ID | Razorpay's identifier for a payment order (created before checkout) |
| Payment ID | Razorpay's identifier for a completed payment transaction |
| Webhook | HTTP callback from Razorpay to notify of payment events |
| Paise | 1/100th of an Indian Rupee — Razorpay uses paise for amounts |
| Payable | Any entity that can be paid for (fee invoice, exam fee, etc.) |
| Checkout | The Razorpay payment form shown to the user |
| Capture | Razorpay finalizing a payment and transferring funds |
| HMAC-SHA256 | Hash-based signature algorithm used for webhook verification |

---

## 14. Additional Suggestions (Analyst Notes)

**Priority 0 — Security (Production Blockers):**
1. **Fix SEC-004 immediately** — Move webhook route outside `auth` middleware group. Add webhook route to `VerifyCsrfToken::$except` array. This is the single most impactful fix.
2. **Encrypt gateway credentials** — Wrap `credentials` and `extra_config` JSON fields with Laravel encryption (`Crypt::encryptString`) before storing. Add `getCredentialsAttribute()` and `setCredentialsAttribute()` accessors to `PaymentGateway` model.
3. **Fix table prefix** — Change `ptm_payment_gateways` to `pay_payment_gateways` in `PaymentController` validation rule.

**Priority 1 — Schema Definition:**
4. **Create DDL for all `pay_*` tables** — Write migration files for `pay_payment_gateways`, `pay_payment_history`, `pay_payment_webhooks`, `pay_payment_refunds` as defined in Section 5. This is a blocker for the entire module.

**Priority 2 — Feature Completion:**
5. Implement refund controller and UI using Razorpay's refund API (`$this->api->payment->fetch($id)->refund(['amount' => $paise])`).
6. Implement receipt/invoice PDF generation after successful payment using DomPDF (already used in HPC module).
7. Add `PaymentSucceeded` event listener that marks the corresponding fee invoice as paid in the Finance module.
8. Implement Razorpay Checkout.js frontend properly with callback verification (current `makePaymentCallback()` is a stub).

**Priority 3 — Gateway Expansion:**
9. Add PayU gateway driver for broader payment option coverage.
10. Add UPI-specific flow detection and routing.
11. Consider adding payment link generation (Razorpay Payment Links API) for sending fee payment links via WhatsApp/email.

---

## 15. Appendices

### Appendix A: Key File Paths

| File | Path |
|------|------|
| PaymentController | `Modules/Payment/app/Http/Controllers/PaymentController.php` |
| PaymentService | `Modules/Payment/app/Services/PaymentService.php` |
| GatewayManager | `Modules/Payment/app/Services/GatewayManager.php` |
| RazorpayGateway | `Modules/Payment/app/Gateways/RazorpayGateway.php` |
| PaymentGatewayInterface | `Modules/Payment/app/Contracts/PaymentGatewayInterface.php` |
| PaymentData DTO | `Modules/Payment/app/DTO/PaymentData.php` |
| Web Routes | `Modules/Payment/routes/web.php` |
| DDL | NOT DEFINED in tenant_db_v2.sql |

### Appendix B: Known Bugs & Security Issues

| ID | Severity | Description | Fix |
|----|----------|-------------|-----|
| SEC-004 | CRITICAL | Webhook behind `auth` middleware → always 401 | Move webhook route outside auth group |
| BUG-PAY-001 | HIGH | No `pay_*` DDL schema defined | Create migration files |
| BUG-PAY-002 | HIGH | Table name `ptm_payment_gateways` instead of `pay_payment_gateways` | Fix validation rule in PaymentController |
| BUG-PAY-003 | HIGH | Gateway credentials stored in plaintext | Add encryption to PaymentGateway model |
| BUG-PAY-004 | MEDIUM | `makePaymentCallback()` is a stub — no verification | Implement Razorpay signature verification on callback |

### Appendix C: Razorpay Integration Checklist

- [ ] Razorpay key_id and key_secret stored encrypted in `pay_payment_gateways`
- [ ] Webhook secret configured and stored encrypted
- [ ] Webhook endpoint added to CSRF exclusion list
- [ ] Webhook endpoint removed from auth middleware
- [ ] `X-Razorpay-Signature` verified on every webhook
- [ ] Idempotency: duplicate webhooks handled gracefully
- [ ] Amount conversion: INR × 100 = paise for API calls
- [ ] Payment capture mode: `payment_capture = 1` (auto-capture enabled)
