# PAY — Payment Gateway Integration
## Module Requirement Document V2
**Version:** 2.0 | **Date:** 2026-03-26 | **Status:** Draft | **Mode:** FULL
**Module Code:** PAY | **Module Type:** Tenant | **Table Prefix:** `pay_*`
**RBS Reference:** Module J — Fees & Finance Management (payment gateway subsystem)
**Completion:** ~45% | **Laravel Repo:** `Modules/Payment/`

---

## 1. Executive Summary

The Payment module (PAY) is the online payment gateway integration layer for Prime-AI, enabling schools to collect student fees digitally. It implements a clean gateway abstraction (`PaymentService → GatewayManager → RazorpayGateway`) and uses an event-driven pattern for post-payment processing.

**V2 Status Summary:**

| Area | V1 Status | V2 Target |
|------|-----------|-----------|
| Gateway abstraction (interface + DTO + BaseGateway) | ✅ Solid | ✅ Keep + extend |
| Razorpay order creation | ✅ Working | ✅ Keep |
| Gateway CRUD (Controller + FormRequest + views) | ✅ Complete | 🟡 Fix prefix + add encryption |
| Webhook handling logic | ✅ Implemented | ❌ BLOCKED by auth middleware (SEC-02) |
| Payment initiation | ✅ Working | 🟡 Needs FormRequest + idempotency |
| `Payment` model | ❌ Stub (only `is_active`) | 📐 Complete rebuild |
| DDL / migrations | ❌ No tables defined anywhere | 📐 Define all `pay_*` tables |
| Table prefix consistency | ❌ Mix of `ptm_*`, `pmt_*`, `pay_*` | 📐 Standardize to `pay_*` |
| Credential encryption | ❌ Plaintext | 📐 Laravel `Crypt::encryptString()` |
| Refund processing | ❌ Model stub only | 📐 Full implementation |
| Payment receipt/PDF | ❌ Not started | 📐 DomPDF integration |
| Payment callback verification | ❌ Stub redirect only | 📐 Implement signature check |
| Policies / authorization | ❌ No Policy class | 📐 PaymentPolicy |
| Activity logging | 🟡 Only in GatewayController | 📐 All state changes |

**Production-Blocking Issues (must fix before go-live):**
1. **SEC-02** — Webhook route is inside `auth` middleware. All gateway callbacks return HTTP 401.
2. **DB-01 through DB-06** — No `pay_*` or `ptm_*` tables exist in `tenant_db_v2.sql`. The module has no DDL foundation.
3. **SEC-01** — Gateway credentials (`key`, `secret`, `webhook_secret`) stored as plaintext JSON.
4. **MD-01/02/03** — `Payment` model is a stub with `$fillable = ['is_active']` only.

---

## 2. Module Overview

### 2.1 Business Purpose

Indian schools require online fee collection through regulated payment gateways. The Payment module provides:

- Integration with Razorpay (India's leading payment gateway) as the primary supported gateway
- A pluggable, interface-driven gateway architecture allowing future addition of PayU, PayTm, CCAvenue, Stripe, Instamojo
- Complete payment lifecycle: initiation → Razorpay order creation → checkout rendering → webhook confirmation → fee record update → receipt
- Polymorphic payable design linking payments to any entity (fee invoice, exam fee, hostel charge, library fine, etc.)
- Idempotent webhook handling preventing double-processing of duplicate callbacks
- Refund tracking and processing via gateway refund APIs
- Per-tenant gateway configuration with encrypted credential storage

### 2.2 Scope and Boundaries

**In scope:**
- Payment gateway configuration and management per tenant
- Payment initiation for any payable entity (polymorphic)
- Razorpay checkout flow (order creation → Checkout.js → webhook confirmation)
- Webhook signature verification and event processing
- Payment history tracking with full lifecycle states
- Refund initiation and tracking
- Payment receipts (PDF)
- Audit trail for all payment events

**Out of scope:**
- Fee invoice creation (handled by FIN — Finance/Fees module)
- Student account balance management (FIN module)
- Vendor payment processing (VND module uses separate `VendorPaymentController`)
- Library fine payment processing (LIB module handles via separate endpoint)

### 2.3 Architectural Pattern

```
[Fee Invoice / Any Payable Entity]
    → POST /payment/make-payment
    → PaymentController::makePayment()        [FormRequest validation]
    → PaymentService::createPayment($data)
        1. DB::transaction begin
        2. PaymentHistory::create(status='initiated')
        3. GatewayManager::resolve($code)
            → PaymentGateway::where('code')->active()->first()
            → decrypt credentials
            → new RazorpayGateway($credentials, $extraConfig)
        4. RazorpayGateway::initiate(PaymentData $dto)
            → Razorpay\Api\Api::order->create([...])
        5. PaymentHistory::update(order_id=Razorpay order_id)
        6. DB::transaction commit
        7. Return checkout_data
    → Render payment::razorpay.process-payment

[Customer completes payment on Razorpay's hosted checkout]
    → Razorpay calls POST /webhooks/payment/{gateway}  [UNAUTHENTICATED — CSRF exempt]
    → PaymentController::handleWebhook()
        1. Store raw payload in pay_payment_webhooks
        2. GatewayManager::resolve($gateway) [decrypts credentials]
        3. verifyWebhookSignature() — HMAC-SHA256 vs X-Razorpay-Signature
        4. processWebhookEvent():
            payment.captured → markSuccess() → PaymentSucceeded::dispatch()
            payment.failed   → markFailed()  → PaymentFailed::dispatch()
        5. webhook->update(processed=true, processed_at=now())
        6. Return HTTP 200 JSON {status: 'ok'}

[PaymentSucceeded event]
    → FeeInvoicePaymentListener — marks fin_fee_invoices as paid
    → NotificationListener — sends receipt to parent/student
```

### 2.4 Menu Path

`Tenant Dashboard > Finance > Payments`
- Payment Management (dashboard)
- Gateway Settings (CRUD)
- Transaction History
- Refunds
- Webhook Logs

---

## 3. Stakeholders & Roles

| Actor | Role | Access Level |
|-------|------|-------------|
| School Admin (Finance) | Configure gateways, view all transactions | Full access |
| Bursar / Accountant | View transactions, initiate and track refunds | View + refund |
| Parent | Initiate payment for fee invoices | Initiate only (own payments) |
| Student (portal) | View own payment history and receipts | Read own records |
| Razorpay (external server) | POST webhook callbacks | Unauthenticated webhook endpoint only |
| System / Event Listeners | Update fee records, send notifications after payment | Automated — no UI |

---

## 4. Functional Requirements

### FR-PAY-01: Payment Gateway Configuration

**RBS Ref:** F.J3.2 — Online Payments / Gateway Integration
**Status:** 🟡 Partial (CRUD exists; encryption, prefix, and module middleware missing)

#### REQ-PAY-01.1 — Gateway CRUD ✅

Admin shall be able to create, view, edit, soft-delete, restore, and force-delete payment gateway configurations.

Gateway record fields:
- `name` (VARCHAR 100) — display name, e.g., "Razorpay Production"
- `code` (VARCHAR 50) — machine identifier, unique per tenant, e.g., 'razorpay'
- `driver` (VARCHAR 255) — fully qualified class name of gateway driver
- `credentials` (JSON, encrypted) — API key, secret, webhook_secret
- `extra_config` (JSON) — mode (live/test), display_name, supported_methods, etc.
- `priority` (INT) — ordering for multiple gateways
- `is_active` (BOOLEAN) — enables/disables gateway for payment initiation

Only active gateways shall be offered for payment initiation. Inactive gateways are hidden from checkout flows.

#### REQ-PAY-01.2 — Credential Encryption 📐 (NOT implemented — P0)

Gateway `credentials` field (containing `key`, `secret`, `webhook_secret`) MUST be encrypted before storage.

Implementation approach:
- Add `setCredentialsAttribute($value)` accessor to `PaymentGateway` model: `$this->attributes['credentials'] = Crypt::encryptString(json_encode($value));`
- Add `getCredentialsAttribute($value)` accessor: `return json_decode(Crypt::decryptString($value), true);`
- `GatewayManager::resolve()` passes already-decrypted credentials (via model accessor) to gateway constructor — no change required to service layer
- Existing `credentials` cast as `array` must be removed (encryption wraps raw bytes, not valid JSON for Laravel's array cast)

Credential fields must never appear in:
- API responses
- Log entries
- Error messages
- Activity log `data` columns

#### REQ-PAY-01.3 — Gateway Testing 📐 (NOT implemented — P2)

Admin shall test a configured gateway from the settings UI:
- A "Test Connection" button on the gateway show/edit page
- Creates a ₹1 test order via the gateway's `initiate()` method
- Returns success/failure response inline (AJAX, no redirect)
- Test orders should be flagged with `extra_config.mode = 'test'`

#### REQ-PAY-01.4 — Module Middleware 📐 (NOT applied — P0)

The `EnsureTenantHasModule` middleware must be applied to all payment routes to enforce module licensing.

**Acceptance Criteria:**
- Given admin creates a Razorpay gateway with valid credentials and `is_active = true`, the gateway appears in the payment initiation form.
- Given `is_active = false`, `GatewayManager::resolve()` throws "not found or inactive" and checkout fails gracefully.
- Given the credentials field is set, the stored value in the DB is an encrypted string (not plaintext JSON).
- Given a school tenant without the Payment module in their plan, all payment routes return 403.

---

### FR-PAY-02: Payment Initiation

**RBS Ref:** F.J3.2 — Gateway Integration / Fee Collection
**Status:** 🟡 Partial (Razorpay order creation works; FormRequest missing; DB transaction missing; table prefix wrong)

#### REQ-PAY-02.1 — Create Payment Order ✅ (logic correct, infrastructure gaps)

The system shall accept a payment request with:
- `amount` (numeric, min:1, max:500000) — in INR
- `gateway` (string) — gateway code, must exist and be active in `pay_payment_gateways`
- `payable_type` (string) — polymorphic model class (e.g., `Modules\Finance\Models\FeeInvoice`)
- `payable_id` (integer, min:1) — ID of the payable entity

Processing flow:
1. Validate request using `MakePaymentRequest` FormRequest (not inline validation)
2. Authorize via `PaymentPolicy::makePayment()` (not yet created)
3. Wrap entire flow in `DB::transaction()`
4. Create `PaymentHistory` with `status = 'initiated'`
5. Build `PaymentData` DTO with `customer` array (name, email, contact from auth user)
6. Call `GatewayManager::resolve($gateway)->initiate($dto)`
7. Update `PaymentHistory.order_id` with gateway's returned order ID
8. Log activity: "Payment initiated for [payable_type]#[payable_id], amount ₹[amount]"
9. Return view with `checkoutData`

#### REQ-PAY-02.2 — Checkout Rendering ✅

On successful order creation, render `payment::razorpay.process-payment` with:
- `checkoutData.key` — Razorpay public key (from decrypted credentials)
- `checkoutData.order_id` — Razorpay order ID
- `checkoutData.amount` — amount in paise (INR × 100)
- `checkoutData.currency` — 'INR'
- `checkoutData.name` — school name
- `checkoutData.description` — payment description (e.g., "Fee Payment — Jan 2026")
- `checkoutData.prefill` — `{name, email, contact}` from authenticated user

#### REQ-PAY-02.3 — Polymorphic Payable ✅

Any entity can be a "payable" — the system stores `payable_type` and `payable_id` in `pay_payment_histories`. Supported payable types at V2:
- `Modules\Finance\Models\FeeInvoice`
- `Modules\Library\Models\LibFine`
- `Modules\Hostel\Models\HostelFee` (future)

#### REQ-PAY-02.4 — Payment Callback 🟡 (stub only — needs implementation)

`makePaymentCallback()` currently redirects with a generic message. Razorpay's Checkout.js sends `razorpay_payment_id`, `razorpay_order_id`, `razorpay_signature` to the callback URL on client-side completion.

V2 requirement: The callback shall verify the Razorpay client-side signature (`razorpay_payment_id|razorpay_order_id` signed with `key_secret`) and record the preliminary payment confirmation. Note: the definitive confirmation should come from the server-side webhook, not the client callback (client can be manipulated).

#### REQ-PAY-02.5 — Idempotency 📐 (NOT implemented — P1)

If an identical payment request (same `payable_type`, `payable_id`, same amount) has an existing `PaymentHistory` in `initiated` state less than 30 minutes old, the system shall reuse the existing order rather than creating a duplicate. This prevents double-orders from form re-submissions.

**Acceptance Criteria:**
- Given valid request, `PaymentHistory` is created with `status = 'initiated'`, Razorpay order is created, checkout view is rendered.
- Given Razorpay API throws an exception, the DB transaction is rolled back, no orphan `PaymentHistory` record exists.
- Given validation table prefix is `pay_payment_gateways` (not `ptm_payment_gateways`), validation succeeds for valid gateway codes.
- Given duplicate submission within 30 min for same payable, existing order is reused.

---

### FR-PAY-03: Webhook Processing

**RBS Ref:** F.J3.2 — Auto-reconcile online payments
**Status:** ❌ BLOCKED (auth middleware returns HTTP 401 for all webhook calls — SEC-02)

#### REQ-PAY-03.1 — Webhook Route Configuration (CRITICAL FIX — P0) 📐

The webhook route `POST /webhooks/payment/{gateway}` MUST be:
1. Placed OUTSIDE all `auth`, `verified`, and `tenant` middleware groups
2. Added to `VerifyCsrfToken::$except` array (or defined in routes that skip CSRF)
3. Protected ONLY via gateway signature verification (not session/token auth)

Current broken state: The route is at `tenant.php` line 326 inside `Route::middleware(['auth', 'verified'])` group — every webhook call from Razorpay's servers returns HTTP 401 because there is no user session.

Required fix location in `routes/tenant.php`:
```php
// OUTSIDE all auth middleware — at top level of tenant routes
Route::post('/webhooks/payment/{gateway}', [PaymentController::class, 'handleWebhook'])
     ->name('payment.webhook')
     ->withoutMiddleware(['auth', 'verified', 'tenant', 'EnsureTenantHasModule']);
```

And in `app/Http/Middleware/VerifyCsrfToken.php`:
```php
protected $except = [
    'webhooks/payment/*',
    // other webhook paths
];
```

#### REQ-PAY-03.2 — Signature Verification ✅ (implemented correctly, blocked by route)

For Razorpay webhooks:
- Read raw request body (not parsed payload): `$request->getContent()`
- Read `X-Razorpay-Signature` header
- Compute: `hash_hmac('sha256', rawBody, webhookSecret)`
- Compare with `hash_equals()` (timing-safe — prevents timing attacks)
- If mismatch: return HTTP 400 with generic error (do NOT expose internal details)
- If webhook secret not configured: return HTTP 400 "Webhook not configured"

Current implementation in `verifyWebhookSignature()` is correct. The credential access `$gatewayInstance->credentials['webhook_secret']` will automatically use decrypted value once encryption accessors are added.

Note (SEC-03): Do NOT expose `$e->getMessage()` in the HTTP response body. Replace with a generic "Webhook processing error" message. Internal details go only to `Log::error()`.

#### REQ-PAY-03.3 — Event Processing ✅ (implemented; will work once route is fixed)

Supported Razorpay webhook events:

| Event | Processing |
|-------|-----------|
| `payment.captured` | Lookup `PaymentHistory` by `order_id`, call `markSuccess($paymentId, $payload)`, dispatch `PaymentSucceeded` |
| `payment.failed` | Lookup `PaymentHistory` by `order_id`, call `markFailed($payload)`, dispatch `PaymentFailed` |
| `refund.created` | 📐 Lookup `PaymentRefund` by `gateway_refund_id`, update status to 'processed' |
| `payment.dispute.created` | 📐 Log to `pay_payment_webhooks`, flag payment for review |

**Idempotency:** If `PaymentHistory.isSuccess()` is already true when `payment.captured` arrives, return HTTP 200 immediately without re-processing. Current implementation handles this correctly.

#### REQ-PAY-03.4 — Webhook Logging ✅

All received webhook payloads must be stored in `pay_payment_webhooks` BEFORE attempting signature verification or processing. This ensures:
- Replay/debugging capability for failed webhooks
- Audit trail of all gateway communications
- Ability to re-process failed webhooks manually

Fields to store: `gateway`, `event_type`, `payload` (full JSON), `processed` (default false), `processed_at`, `error_message`.

Note: `PaymentWebhook` model uses table `pmt_payment_webhooks` (typo — should be `pay_payment_webhooks`). Fix model `$table` property.

**Acceptance Criteria:**
- Given Razorpay sends `payment.captured` with valid signature and webhook route is not behind auth → `PaymentHistory.status = 'success'`, `PaymentSucceeded` dispatched, webhook record `processed = true`.
- Given invalid webhook signature → HTTP 400 returned, generic error message only, `PaymentHistory` unchanged.
- Given duplicate `payment.captured` for already-successful payment → HTTP 200, no double-processing.
- Given webhook route currently behind auth → HTTP 401 (current bug — SEC-02 must be fixed).
- Given `$e->getMessage()` exposure removed → HTTP 400 returns only `{error: "Webhook processing error"}`.

---

### FR-PAY-04: Payment History & Tracking

**RBS Ref:** F.J3.1, F.J8.1
**Status:** 🟡 Partial (model well-built; view exists; `Payment` model is stub; no DDL)

#### REQ-PAY-04.1 — PaymentHistory Model 🟡

The `PaymentHistory` model (`ptm_payment_histories` → rename to `pay_payment_histories`) has a well-implemented set of status methods.

V2 additions needed:
- Add `SoftDeletes` trait (MD-04) — payment records must never be hard-deleted for audit purposes
- Add `created_by` to `$fillable` (MD-05) — FK to `sys_users.id` for the user who initiated payment
- Add `is_active` to `$fillable` and `$casts` (MD-06)
- Add `failure_reason` column and fillable for richer error tracking
- Add `paid_at` (DATETIME) column set in `markSuccess()`
- Rename `transaction_id` to `gateway_payment_id` (aligns with Razorpay nomenclature)
- Rename `gateway_response` to `gateway_payload` (more accurate — stores full webhook payload)

#### REQ-PAY-04.2 — Payment Management Dashboard 🟡

Admin view (`payment::index`) shows:
- Paginated list of recent transactions with: gateway, payable entity name, amount, currency, status badge, initiated at, paid at
- Summary cards: Total collected today, this month, this year; Pending payments count; Failed payments count
- Quick filters: by gateway, by status, by date range

#### REQ-PAY-04.3 — Payment History List 🟡

Dedicated history page with:
- Full-text search by order_id or gateway_payment_id
- Date range filter
- Gateway filter
- Status filter (initiated / success / failed / cancelled / refunded)
- Export to CSV

#### REQ-PAY-04.4 — Payment Detail View 📐 (NOT implemented)

Individual payment record showing:
- All `pay_payment_histories` fields
- Linked payable entity (e.g., fee invoice details)
- Gateway webhook payload (collapsible JSON view)
- Associated refunds list
- Download receipt button (if status = 'success')

**Acceptance Criteria:**
- Given `markSuccess($paymentId, $payload)` is called → `status = 'success'`, `gateway_payment_id = $paymentId`, `gateway_payload = $payload`, `paid_at = now()`.
- Given `markFailed($payload)` is called → `status = 'failed'`, `failure_reason` extracted from payload, `gateway_payload = $payload`.
- Given `isSuccess()` called on a success record → returns `true`.
- Given admin views payment history → paginated, filterable, sorted by latest first.

---

### FR-PAY-05: Refund Processing

**RBS Ref:** F.J6.2
**Status:** ❌ Not implemented (model stub only — no controller, no service method, no routes, no views)

#### REQ-PAY-05.1 — Refund Initiation 📐

Admin/Accountant shall initiate refunds for payments in `status = 'success'`:
1. Select a payment from the history list
2. Enter refund amount (must be ≤ original payment amount minus any prior refunds)
3. Enter refund reason
4. System calls Razorpay Refund API: `$api->payment->fetch($gatewayPaymentId)->refund(['amount' => $paise])`
5. On success: create `PaymentRefund` record, dispatch `PaymentRefunded` event
6. On failure: return error, do not create refund record

#### REQ-PAY-05.2 — Refund Status Tracking 📐

- `PaymentRefund` record is created with `status = 'pending'` on initiation
- Razorpay sends `refund.created` webhook → update to `status = 'processed'`, set `refunded_at`
- If Razorpay API call fails synchronously → `status = 'failed'`, log error
- `PaymentHistory.status` updated to `'refunded'` after full refund processed (partial refunds keep status as 'success')

#### REQ-PAY-05.3 — Refund Constraints 📐

- Refunds can only be initiated for `PaymentHistory.status = 'success'`
- Total refunded amount across all refunds for one payment cannot exceed original `amount`
- Refunds must be recorded in `sys_activity_logs`
- Partial refunds supported (refund amount < original amount)

**Acceptance Criteria:**
- Given payment with `status = 'success'`, admin can initiate a refund up to the full amount.
- Given total existing refunds = ₹200 on a ₹500 payment, only ₹300 further refund is allowed.
- Given Razorpay refund API returns success, `PaymentRefund.gateway_refund_id` is stored and `status = 'processed'`.
- Given payment in `status = 'failed'`, refund initiation is blocked.

---

### FR-PAY-06: Payment Receipt Generation

**RBS Ref:** F.J8.1 — Digital Receipts
**Status:** ❌ Not implemented

#### REQ-PAY-06.1 — PDF Receipt 📐

After `PaymentSucceeded` event:
1. Generate a PDF receipt using DomPDF (already available in the platform — used by HPC module)
2. Receipt includes: school logo, school name, receipt number, payment date, student name, payable description, amount, gateway, transaction ID, "PAID" watermark
3. Store receipt PDF to `sys_media` (polymorphic media — linked to `PaymentHistory`)
4. Send receipt to parent/student email via notification

#### REQ-PAY-06.2 — Receipt Download 📐

- GET `/payment/history/{id}/receipt` → download PDF receipt
- Only accessible to: the payer (authenticated user who initiated), school admin, accountant
- If PDF not yet generated, generate on-the-fly

---

### FR-PAY-07: Payment Policies & Authorization

**RBS Ref:** F.A2 — RBAC
**Status:** ❌ No Policy class exists (PL-01)

#### REQ-PAY-07.1 — PaymentPolicy 📐

Create `Modules/Payment/app/Policies/PaymentPolicy.php` with:

| Method | Capability Key | Description |
|--------|---------------|-------------|
| `viewAny` | `payment.viewAny` | View payment dashboard and list |
| `makePayment` | `payment.makePayment` | Initiate a payment |
| `refund` | `payment.refund` | Initiate refund |
| `viewWebhookLogs` | `payment.viewWebhookLogs` | View webhook log table |
| `configureGateway` | `payment.gateway.*` | Use existing gateway.* permissions |

Currently `makePayment()` has NO authorization check (PL-03) — any authenticated user can initiate payments.

---

### FR-PAY-08: Webhook Logs View

**RBS Ref:** Operational tooling
**Status:** ❌ Not implemented

#### REQ-PAY-08.1 — Webhook Log Table 📐

Admin view showing all records in `pay_payment_webhooks`:
- Columns: ID, gateway, event_type, processed (badge), processed_at, created_at
- Actions: View raw payload (modal), Re-process (for failed webhooks)
- Filter by: gateway, processed status, date range

#### REQ-PAY-08.2 — Re-processing Failed Webhooks 📐

Admin shall be able to manually trigger re-processing of a webhook record that has `processed = false`. This triggers the same `processWebhookEvent()` logic with the stored payload.

---

## 5. Data Model

### 5.1 CRITICAL: No DDL Defined Anywhere

**None of the Payment module tables exist in `tenant_db_v2.sql` or any migration files.** Code inspection confirms:
- `Payment` model → `ptm_payments`
- `PaymentGateway` model → `ptm_payment_gateways`
- `PaymentHistory` model → `ptm_payment_histories`
- `PaymentWebhook` model → `pmt_payment_webhooks` (different typo — `pmt_` vs `ptm_`)
- `PaymentRefund` model → table name not set (uses default `payment_refunds`)

**V2 Decision: All tables MUST use `pay_` prefix.** All model `$table` properties must be updated.

### 5.2 Table: `pay_payment_gateways`

```sql
CREATE TABLE pay_payment_gateways (
    id              INT UNSIGNED     NOT NULL AUTO_INCREMENT,
    name            VARCHAR(100)     NOT NULL COMMENT 'Display name e.g. Razorpay Production',
    code            VARCHAR(50)      NOT NULL COMMENT 'Machine code e.g. razorpay',
    driver          VARCHAR(255)     NOT NULL COMMENT 'FQCN of gateway driver class',
    credentials     TEXT             NOT NULL COMMENT 'Laravel-encrypted JSON: key, secret, webhook_secret',
    extra_config    JSON             NULL     COMMENT 'mode: live/test, display_name, supported_methods',
    priority        TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Order in payment method selection',
    is_active       TINYINT(1)       NOT NULL DEFAULT 1,
    created_at      TIMESTAMP        NULL,
    updated_at      TIMESTAMP        NULL,
    deleted_at      TIMESTAMP        NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_pay_gateway_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

Notes:
- `credentials` is `TEXT` (not `JSON`) because the value is an encrypted blob, not valid JSON
- `code` is unique globally (not per-tenant) since this is a tenant-scoped database
- `priority` allows ordering when multiple gateways are active

### 5.3 Table: `pay_payment_histories`

```sql
CREATE TABLE pay_payment_histories (
    id                  INT UNSIGNED     NOT NULL AUTO_INCREMENT,
    payable_type        VARCHAR(255)     NOT NULL COMMENT 'Polymorphic: model class',
    payable_id          INT UNSIGNED     NOT NULL COMMENT 'Polymorphic: record ID',
    gateway             VARCHAR(50)      NOT NULL COMMENT 'Gateway code used',
    order_id            VARCHAR(255)     NULL     COMMENT 'Razorpay order_id (set after order create)',
    gateway_payment_id  VARCHAR(255)     NULL     COMMENT 'Razorpay payment_id (set after capture)',
    amount              DECIMAL(12,2)    NOT NULL COMMENT 'In major currency unit (INR)',
    currency            CHAR(3)          NOT NULL DEFAULT 'INR',
    status              ENUM(
                            'initiated',
                            'pending',
                            'success',
                            'failed',
                            'cancelled',
                            'refunded'
                        )                NOT NULL DEFAULT 'initiated',
    failure_reason      TEXT             NULL     COMMENT 'Human-readable failure message',
    gateway_payload     JSON             NULL     COMMENT 'Full webhook payload stored on confirmation',
    paid_at             DATETIME         NULL     COMMENT 'Set when status transitions to success',
    idempotency_key     VARCHAR(255)     NULL     COMMENT 'SHA256 of payable_type+payable_id+amount for dedup',
    created_by          INT UNSIGNED     NULL     COMMENT 'FK sys_users.id — initiating user',
    is_active           TINYINT(1)       NOT NULL DEFAULT 1,
    created_at          TIMESTAMP        NULL,
    updated_at          TIMESTAMP        NULL,
    deleted_at          TIMESTAMP        NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_pay_order (order_id),
    UNIQUE KEY uq_pay_idempotency (idempotency_key),
    INDEX idx_pay_payable (payable_type, payable_id),
    INDEX idx_pay_status_date (status, paid_at),
    INDEX idx_pay_gateway_payment (gateway_payment_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

Notes:
- `order_id` UNIQUE index enables O(1) webhook lookup by Razorpay order_id
- `idempotency_key` prevents duplicate orders for the same payable + amount within the dedup window
- `deleted_at` enables soft deletes (required for audit — no hard deletes on financial records)

### 5.4 Table: `pay_payment_webhooks`

```sql
CREATE TABLE pay_payment_webhooks (
    id              INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    gateway         VARCHAR(50)   NOT NULL COMMENT 'Gateway identifier e.g. razorpay',
    event_type      VARCHAR(100)  NULL     COMMENT 'e.g. payment.captured, payment.failed',
    payload         JSON          NOT NULL COMMENT 'Full raw webhook payload',
    processed       TINYINT(1)    NOT NULL DEFAULT 0,
    processed_at    DATETIME      NULL,
    error_message   TEXT          NULL     COMMENT 'Processing error if any',
    created_at      TIMESTAMP     NULL,
    updated_at      TIMESTAMP     NULL,
    PRIMARY KEY (id),
    INDEX idx_pay_webhook_gateway (gateway, processed),
    INDEX idx_pay_webhook_event (event_type, processed)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

Notes:
- No `deleted_at` — webhook logs are append-only, never deleted
- No `is_active` — not a "domain entity", it's a technical log table

### 5.5 Table: `pay_payment_refunds`

```sql
CREATE TABLE pay_payment_refunds (
    id                  INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    payment_history_id  INT UNSIGNED  NOT NULL COMMENT 'FK pay_payment_histories.id',
    amount              DECIMAL(12,2) NOT NULL COMMENT 'Refund amount (may be partial)',
    reason              TEXT          NULL,
    status              ENUM(
                            'pending',
                            'processing',
                            'processed',
                            'failed'
                        )             NOT NULL DEFAULT 'pending',
    gateway_refund_id   VARCHAR(255)  NULL     COMMENT 'Razorpay refund_id from API response',
    refunded_at         DATETIME      NULL     COMMENT 'Set when refund confirmed by webhook',
    initiated_by        INT UNSIGNED  NOT NULL COMMENT 'FK sys_users.id',
    is_active           TINYINT(1)    NOT NULL DEFAULT 1,
    created_at          TIMESTAMP     NULL,
    updated_at          TIMESTAMP     NULL,
    PRIMARY KEY (id),
    INDEX idx_pay_refund_payment (payment_history_id),
    INDEX idx_pay_refund_status (status),
    CONSTRAINT fk_pay_refund_history
        FOREIGN KEY (payment_history_id) REFERENCES pay_payment_histories (id)
        ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 5.6 Table: `pay_payments` (rename from `ptm_payments`)

The `Payment` model (stub) references `ptm_payments`. This table likely represents the primary payment record linking gateway transactions to the application domain. It needs full definition:

```sql
CREATE TABLE pay_payments (
    id                  INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    payment_history_id  INT UNSIGNED  NOT NULL COMMENT 'FK pay_payment_histories.id',
    payable_type        VARCHAR(255)  NOT NULL,
    payable_id          INT UNSIGNED  NOT NULL,
    amount              DECIMAL(12,2) NOT NULL,
    currency            CHAR(3)       NOT NULL DEFAULT 'INR',
    status              ENUM('pending','paid','partially_refunded','refunded','cancelled')
                                      NOT NULL DEFAULT 'pending',
    notes               TEXT          NULL,
    is_active           TINYINT(1)    NOT NULL DEFAULT 1,
    created_by          INT UNSIGNED  NULL,
    created_at          TIMESTAMP     NULL,
    updated_at          TIMESTAMP     NULL,
    deleted_at          TIMESTAMP     NULL,
    PRIMARY KEY (id),
    INDEX idx_pay_payments_payable (payable_type, payable_id),
    CONSTRAINT fk_pay_payments_history
        FOREIGN KEY (payment_history_id) REFERENCES pay_payment_histories (id)
        ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 5.7 Model Summary — Prefix Corrections Required

| Model | Current `$table` | V2 `$table` | Issues |
|-------|-----------------|-------------|--------|
| `Payment` | `ptm_payments` | `pay_payments` | Stub — rebuild entirely |
| `PaymentGateway` | `ptm_payment_gateways` | `pay_payment_gateways` | Rename; add encryption accessors |
| `PaymentHistory` | `ptm_payment_histories` | `pay_payment_histories` | Add SoftDeletes, created_by, is_active, paid_at |
| `PaymentWebhook` | `pmt_payment_webhooks` | `pay_payment_webhooks` | Fix typo (`pmt_` → `pay_`) |
| `PaymentRefund` | (unset — defaults to `payment_refunds`) | `pay_payment_refunds` | Complete rebuild |

### 5.8 PaymentData DTO ✅

```php
// Modules/Payment/app/DTO/PaymentData.php
class PaymentData {
    public function __construct(
        public string $paymentId,   // PaymentHistory.id as string
        public float  $amount,      // INR (major unit)
        public string $currency,    // 'INR'
        public string $payableType, // model class
        public int    $payableId,   // record ID
        public array  $customer,    // [name, email, contact]
        public array  $metadata     // arbitrary extra data
    ) {}
}
```

V2 addition: populate `customer` from authenticated user in `PaymentService::createPayment()`.

---

## 6. API Endpoints & Routes

### 6.1 Current Route Analysis

Current registration in `routes/tenant.php` lines 319–336:

```php
Route::middleware(['auth', 'verified'])->prefix('payment')->name('payment.')->group(function () {
    Route::get('/payment-management', ...)             // payment.payment-management
    Route::get('/payment', ...)                         // payment.payment.index
    Route::post('/payment/make-payment', ...)           // payment.payment.makePayment
    Route::get('/payment/course/purchase-successfull', ...) // payment.payment.course.purchase-successfull
    Route::post('/payment/webhook/{gateway}', ...)      // payment.payment.handle-webhook  [BUG: behind auth]
    Route::resource('payment-gateway', ...)
    // + trash/restore/forceDelete/toggleStatus
});
```

**Issues:**
- RT-01: `EnsureTenantHasModule` middleware not applied
- RT-02: Webhook route inside `auth` middleware — all gateway callbacks return 401
- RT-03: Route name `payment.course.purchase-successfull` — typo + domain-specific name
- RT-04: No refund routes
- RT-05: No per-user payment history for parent/student portal

### 6.2 V2 Required Route Structure

```php
// ── 1. UNAUTHENTICATED WEBHOOK — MUST be OUTSIDE all middleware ─────────────
// In tenant.php, BEFORE any middleware groups:
Route::post('/webhooks/payment/{gateway}', [PaymentController::class, 'handleWebhook'])
     ->name('payment.webhook');
// Also add to VerifyCsrfToken::$except: 'webhooks/payment/*'

// ── 2. Authenticated Tenant Routes ─────────────────────────────────────────
Route::middleware(['auth', 'verified', 'tenant', 'module:payment'])
     ->prefix('payment')
     ->name('payment.')
     ->group(function () {

    // Dashboard
    Route::get('/management', [PaymentController::class, 'paymentManagement'])
         ->name('management');

    // Payment initiation
    Route::post('/make-payment', [PaymentController::class, 'makePayment'])
         ->name('make-payment');
    Route::get('/callback', [PaymentController::class, 'makePaymentCallback'])
         ->name('callback');

    // Transaction history
    Route::get('/history', [PaymentController::class, 'index'])
         ->name('history');
    Route::get('/history/{id}', [PaymentController::class, 'show'])
         ->name('history.show');
    Route::get('/history/{id}/receipt', [PaymentController::class, 'downloadReceipt'])
         ->name('history.receipt');

    // Refunds
    Route::get('/refunds', [PaymentRefundController::class, 'index'])
         ->name('refunds.index');
    Route::post('/refunds', [PaymentRefundController::class, 'store'])
         ->name('refunds.store');
    Route::get('/refunds/{id}', [PaymentRefundController::class, 'show'])
         ->name('refunds.show');

    // Webhook logs (admin only)
    Route::get('/webhook-logs', [PaymentController::class, 'webhookLogs'])
         ->name('webhook-logs');
    Route::post('/webhook-logs/{id}/reprocess', [PaymentController::class, 'reprocessWebhook'])
         ->name('webhook-logs.reprocess');

    // Gateway configuration
    Route::resource('gateways', PaymentGatewayController::class)
         ->names('gateway');
    Route::get('/gateways/trash', [PaymentGatewayController::class, 'trashedPaymentGateways'])
         ->name('gateway.trashed');
    Route::post('/gateways/{id}/restore', [PaymentGatewayController::class, 'restore'])
         ->name('gateway.restore');
    Route::delete('/gateways/{id}/force-delete', [PaymentGatewayController::class, 'forceDelete'])
         ->name('gateway.force-delete');
    Route::post('/gateways/{payment_gateway}/toggle-status', [PaymentGatewayController::class, 'toggleStatus'])
         ->name('gateway.toggle-status');
    Route::post('/gateways/{gateway}/test', [PaymentGatewayController::class, 'testGateway'])
         ->name('gateway.test');
});
```

### 6.3 API Response Contracts

**POST /payment/make-payment — Success (renders view)**

Redirects to `payment::razorpay.process-payment` view with `$checkoutData`.

**POST /payment/make-payment — Failure**
```
Redirect back with session('error') = "Payment initiation failed: [message]"
```

**POST /webhooks/payment/{gateway} — Success**
```json
HTTP 200
{"status": "ok"}
```

**POST /webhooks/payment/{gateway} — Invalid Signature**
```json
HTTP 400
{"error": "Invalid webhook signature."}
```

**POST /webhooks/payment/{gateway} — Processing Error**
```json
HTTP 400
{"error": "Webhook processing error."}
```
Note: Never expose internal exception messages (`$e->getMessage()`) in the response body.

**POST /payment/refunds — Success**
```json
HTTP 200
{"success": true, "refund_id": 42, "message": "Refund initiated successfully."}
```

**POST /gateways/{gateway}/test — Success**
```json
HTTP 200
{"success": true, "message": "Gateway connection verified.", "order_id": "order_xxx"}
```

---

## 7. UI Screens

| # | Screen | Route | Status | Notes |
|---|--------|-------|--------|-------|
| 1 | Payment Management Dashboard | GET /payment/management | 🟡 Partial | Exists; add summary cards |
| 2 | Gateway List | Redirects to dashboard | ✅ | Routes to management page |
| 3 | Add Gateway | GET /payment/gateways/create | ✅ | View exists |
| 4 | Edit Gateway | GET /payment/gateways/{id}/edit | ✅ | View exists |
| 5 | View Gateway | GET /payment/gateways/{id} | ✅ | View exists |
| 6 | Trashed Gateways | GET /payment/gateways/trash | ✅ | View exists |
| 7 | Make Payment (fee form) | POST /payment/make-payment | 🟡 | Validation fix needed |
| 8 | Razorpay Checkout | Rendered view (Checkout.js) | ✅ | `payment::razorpay.process-payment` |
| 9 | Payment History List | GET /payment/history | 🟡 | View exists as partial; needs dedicated page |
| 10 | Payment Detail | GET /payment/history/{id} | ❌ | Not implemented |
| 11 | Refund Management | GET /payment/refunds | ❌ | Views missing |
| 12 | Webhook Logs | GET /payment/webhook-logs | ❌ | Not implemented |
| 13 | Payment Receipt (PDF) | GET /payment/history/{id}/receipt | ❌ | Not implemented |

### Screen Detail: Payment Management Dashboard (Screen 1)

Layout:
- **Top row (4 cards):** Total Collected (all time), This Month, Pending Count, Failed Count
- **Middle:** Recent transactions table (last 10) with gateway badge, amount, status, date
- **Sidebar or tab:** Gateway status cards (active gateways with mode indicator)
- **Quick links:** View All Transactions, Manage Gateways, View Refunds

### Screen Detail: Razorpay Checkout (Screen 8)

The `process-payment.blade.php` view must:
- Load Razorpay Checkout.js from `https://checkout.razorpay.com/v1/checkout.js`
- Auto-open the Razorpay modal on page load
- Set handler callback to POST to `/payment/callback` with `razorpay_payment_id`, `razorpay_order_id`, `razorpay_signature`
- Handle cancellation (redirect back with `error = 'Payment cancelled'`)
- Note: the public `key` in checkout data must be the raw Razorpay key ID (never the secret)

---

## 8. Business Rules

**BR-PAY-01 — Gateway Uniqueness:** Only one gateway configuration per `code` value is allowed per tenant. Two gateways cannot share the same code (enforced by UNIQUE constraint on `pay_payment_gateways.code`).

**BR-PAY-02 — Idempotent Webhooks:** If a `PaymentHistory` record already has `status = 'success'`, any subsequent `payment.captured` webhook for the same `order_id` must be acknowledged with HTTP 200 and silently ignored. Double-processing must never occur.

**BR-PAY-03 — Credential Encryption (P0):** Gateway `credentials` (key, secret, webhook_secret) MUST be encrypted at rest using Laravel's `Crypt::encryptString()`. Credentials must never appear in:
- Database as plaintext
- API responses
- Log files
- Error messages

**BR-PAY-04 — Amount Conversion:** Amounts are stored in INR as `DECIMAL(12,2)` in major units. The Razorpay API accepts amounts in paise (minor units). Conversion: `amount_in_paise = amount_in_inr * 100`. This conversion occurs in `RazorpayGateway::initiate()` and must never be applied twice.

**BR-PAY-05 — Payment Status Transitions:** `PaymentHistory.status` follows a one-directional state machine:
- `initiated` → `success` (via `payment.captured` webhook)
- `initiated` → `failed` (via `payment.failed` webhook)
- `initiated` → `cancelled` (user cancellation)
- `success` → `refunded` (after full refund processed)
- No backward transitions are permitted

**BR-PAY-06 — Webhook Authentication:** The webhook endpoint must not use session/token authentication. The only authentication mechanism is HMAC-SHA256 signature verification using the gateway's `webhook_secret`.

**BR-PAY-07 — Refund Limits:** Refunds may only be initiated for `status = 'success'` payments. The sum of all refund amounts for a single payment cannot exceed the original `amount`. Partial refunds are permitted.

**BR-PAY-08 — Gateway Interface Contract:** All gateway driver classes must implement `PaymentGatewayInterface`:
- `initiate(PaymentData $data): array` — creates order, returns `gateway_order_id` and `checkout_data`
- `verify(array $payload): bool` — verifies client-side payment signature
- `handleWebhook(array $payload): void` — gateway-specific webhook processing (reserved, currently unused)

**BR-PAY-09 — Auto-Capture:** Razorpay orders must be created with `payment_capture = 1` (auto-capture). Manual capture flow is not supported in V2.

**BR-PAY-10 — No Card Data:** Raw payment card data must never be transmitted to or stored by Prime-AI servers. Razorpay's tokenization and hosted checkout ensure card data never reaches the application layer.

**BR-PAY-11 — DB Transaction Isolation:** The sequence (create `PaymentHistory` → call gateway → update `order_id`) must be wrapped in a `DB::transaction()`. If the gateway call fails, the orphan `PaymentHistory` record must be rolled back.

---

## 9. Workflows

### 9.1 Payment Lifecycle FSM

```
                        ┌─────────────┐
                        │  INITIATED  │
                        └──────┬──────┘
                               │ PaymentService::createPayment()
                               │ Razorpay order created
                               │ PaymentHistory.order_id set
                               ▼
                    ┌──────────────────────┐
                    │ RAZORPAY CHECKOUT.JS │
                    │  (user enters card)  │
                    └──────────┬───────────┘
                               │
                ┌──────────────┼──────────────┐
                │              │              │
                ▼              ▼              ▼
           [captured]      [failed]     [cancelled]
                │              │              │
      webhook   ▼   webhook    ▼    user      ▼
        markSuccess()    markFailed()   markCancelled()
                │              │              │
                ▼              ▼              ▼
           SUCCESS           FAILED       CANCELLED
                │
         ┌──────┴──────────────────────┐
         │ PaymentSucceeded::dispatch() │
         │ Fee invoice marked paid      │
         │ Receipt generated            │
         │ Parent notified              │
         └─────────────────────────────┘
                │
                │ [admin initiates refund]
                ▼
           REFUNDING
                │
         ┌──────┴──────────────────────┐
         │ Razorpay Refund API called   │
         │ PaymentRefund record created │
         │ refund.created webhook       │
         └─────────────────────────────┘
                │
                ▼
           REFUNDED (full) / SUCCESS (partial refund)
```

### 9.2 Webhook Processing Sequence

```
Razorpay Server
    │
    │ POST /webhooks/payment/razorpay
    │ Header: X-Razorpay-Signature: <hmac>
    │ Body: {event: "payment.captured", payload: {...}}
    │
    ▼
[CSRF bypass — route outside middleware]
    │
    ▼
PaymentController::handleWebhook($request, $gateway)
    │
    ├─1─ PaymentWebhook::create({gateway, event_type, payload})  [always — even before verify]
    │
    ├─2─ GatewayManager::resolve($gateway)
    │       └─ PaymentGateway::where(code)->active()->first()
    │       └─ decrypt credentials
    │       └─ new RazorpayGateway($creds)
    │
    ├─3─ verifyWebhookSignature($request, $gateway, $instance)
    │       └─ hash_hmac('sha256', rawContent, webhookSecret)
    │       └─ hash_equals($computed, $header)
    │       └─ throws Exception if mismatch → HTTP 400
    │
    ├─4─ processWebhookEvent($payload, $gateway)
    │       ├─ event = 'payment.captured'
    │       │       └─ PaymentHistory::where(order_id)->first()
    │       │       └─ if isSuccess() → return (idempotency)
    │       │       └─ markSuccess($paymentId, $payload)
    │       │       └─ PaymentSucceeded::dispatch($paymentHistory)
    │       └─ event = 'payment.failed'
    │               └─ PaymentHistory::where(order_id)->first()
    │               └─ if not isSuccess() → markFailed($payload)
    │               └─ PaymentFailed::dispatch($paymentHistory)
    │
    ├─5─ $webhook->update({processed: true, processed_at: now()})
    │
    └─6─ return JSON {status: 'ok'}, HTTP 200
```

### 9.3 Refund Processing Sequence

```
Admin clicks "Refund" on payment detail page
    │
    ▼
POST /payment/refunds
    {payment_history_id, amount, reason}
    │
    ▼
PaymentRefundController::store()
    │
    ├─1─ Validate: payment exists, status='success', amount ≤ available
    ├─2─ Authorize: PaymentPolicy::refund()
    ├─3─ PaymentRefund::create({payment_history_id, amount, reason, status='pending'})
    ├─4─ GatewayManager::resolve(payment->gateway)
    ├─5─ $api->payment->fetch($gatewayPaymentId)->refund(['amount' => paise])
    ├─6─ On success: $refund->update({gateway_refund_id, status='processed', refunded_at})
    │            $payment->markRefunded() if full refund
    │            activityLog(...)
    └─7─ On failure: $refund->update({status='failed'})
                 Log::error(...)
                 return error response
```

---

## 10. Non-Functional Requirements

**NFR-PAY-01 — Security (P0):**
- Gateway credentials MUST be encrypted. Storing API keys in plaintext is a P0 production blocker.
- Webhook endpoint MUST be outside `auth` middleware. Current SEC-02 is a complete showstopper for payment reconciliation.
- Webhook error responses must not expose internal exception messages (SEC-03).
- Consider IP allowlisting for Razorpay's published webhook IP ranges as an additional layer (SEC-04).

**NFR-PAY-02 — PCI-DSS Scope Reduction:**
- Card data must never be transmitted to Prime-AI servers (Razorpay's hosted checkout maintains PCI-DSS scope).
- Prime-AI is not a "cardholder data environment" — scope is limited to webhook payloads (which contain payment IDs, not card numbers).
- Log sanitization: never log `credentials`, `key`, `secret`, or `card.*` fields.

**NFR-PAY-03 — Idempotency:**
- Webhook processing must tolerate duplicate delivery (Razorpay retries on non-2xx response). The `isSuccess()` guard in `processWebhookEvent()` handles this correctly.
- Payment initiation should use the `idempotency_key` column to prevent duplicate orders from form re-submissions.

**NFR-PAY-04 — Reliability:**
- `PaymentSucceeded` event listener (fee update, notification, receipt generation) should implement `ShouldQueue` to prevent webhook processing from timing out.
- Webhook handling (steps 1–4) is synchronous and fast. Only post-payment side effects should be queued.
- Target webhook acknowledgment time: < 500ms (Razorpay times out after 30s).

**NFR-PAY-05 — Audit Trail:**
- All payment events (initiated, success, failed, cancelled, refunded) must be recorded in `sys_activity_logs`.
- Credential changes in gateway config must log the change without logging the new credential values.
- Refund initiations must log: refund ID, payment ID, amount, initiated_by.

**NFR-PAY-06 — Extensibility:**
- Adding a new gateway requires only: (a) implement `PaymentGatewayInterface`, (b) insert a `pay_payment_gateways` record. No core code changes.
- `GatewayManager::resolve()` uses the `driver` FQCN from DB to instantiate — fully data-driven.
- The `getAvailableDrivers()` method in `PaymentGatewayController` should be moved to a config file (`config/payment.php`) to avoid coupling UI to code.

**NFR-PAY-07 — Performance:**
- `pay_payment_histories.order_id` UNIQUE index ensures O(1) webhook lookup.
- `PaymentGateway` records should be cached (e.g., 5 min TTL) since they rarely change and are fetched on every payment.
- `paymentManagement()` calls `PaymentGateway::ordered()->paginate(10)` twice (PERF-03) — should be called once and passed to both dashboards.

**NFR-PAY-08 — Compatibility:**
- Laravel 12 + PHP 8.2
- `razorpay/razorpay` Composer package
- DomPDF (`barryvdh/laravel-dompdf`) for receipts — already in platform dependencies (HPC module)
- stancl/tenancy v3.9 — tenant database context required for all pay_* table queries

---

## 11. Dependencies

### 11.1 Internal Module Dependencies

| Module | Direction | Purpose |
|--------|-----------|---------|
| Finance/Fees (FIN) | Inbound → PAY | Fee invoice initiates payment; `PaymentSucceeded` event marks invoice paid |
| Finance/Fees (FIN) | PAY → Outbound | `fin_fee_payments` updated via `PaymentSucceeded` listener |
| Notification (NTF) | PAY → Outbound | Payment receipt notification dispatched via NTF after success |
| SystemConfig (SYS) | PAY → Outbound | `sys_activity_logs` for audit; `sys_media` for receipt storage; `sys_users.id` for `created_by` |
| Student Profile (STD) | PAY → Reference | Student details (name, email, phone) for checkout prefill and receipt |
| Library (LIB) | LIB → PAY | Library fines payable via payment system (`payable_type = LibFine`) |
| HPC Module | Reference | DomPDF usage pattern for receipt PDF generation |

### 11.2 External Dependencies

| Dependency | Purpose | Version |
|-----------|---------|---------|
| `razorpay/razorpay` | Razorpay PHP SDK | ^2.8 |
| `barryvdh/laravel-dompdf` | PDF receipt generation | Already in platform |
| Laravel Queue | Async webhook post-processing | Platform default |
| Laravel Crypt facade | Credential encryption/decryption | Built-in |
| Razorpay Checkout.js CDN | Client-side checkout modal | `https://checkout.razorpay.com/v1/checkout.js` |

### 11.3 Event Contracts

**`PaymentSucceeded` event** (dispatched from `handleWebhook()` or `processWebhookEvent()`):
- Payload: `PaymentHistory $paymentHistory`
- Expected listeners:
  - `FeeInvoicePaymentListener` → mark `fin_fee_invoices` as paid
  - `PaymentReceiptListener` → generate PDF and store to `sys_media`
  - `PaymentNotificationListener` → send notification via NTF module

**`PaymentFailed` event**:
- Payload: `PaymentHistory $paymentHistory`
- Expected listeners:
  - `PaymentFailedNotificationListener` → notify parent of failed payment

---

## 12. Test Scenarios

### 12.1 Existing Tests (8 files — the only module with any tests in the codebase)

| File | Type | Coverage |
|------|------|----------|
| `Feature/PaymentControllerTest.php` | Feature | Controller HTTP endpoints |
| `Feature/PaymentGatewayControllerTest.php` | Feature | Gateway CRUD |
| `Unit/GatewayManagerTest.php` | Unit | `resolve()` logic |
| `Unit/PaymentDataDtoTest.php` | Unit | DTO construction |
| `Unit/PaymentEventsTest.php` | Unit | Event dispatch |
| `Unit/PaymentGatewayModelTest.php` | Unit | Gateway model |
| `Unit/PaymentGatewayRequestTest.php` | Unit | Form request validation |
| `Unit/PaymentHistoryModelTest.php` | Unit | Status helper methods |

### 12.2 Required New Tests (V2)

**TS-PAY-01: WebhookRouteTest (P0)**
```
Scenario: Webhook endpoint is accessible without authentication
  Given the webhook route is outside auth middleware
  When POST /webhooks/payment/razorpay is called without Authorization header
  Then response is NOT 401 (route is reachable)
  And signature verification is attempted
```

**TS-PAY-02: WebhookSignatureVerificationTest (P0)**
```
Scenario: Valid signature accepted
  Given a Razorpay webhook with correct HMAC-SHA256 signature
  When POST /webhooks/payment/razorpay
  Then HTTP 200 returned, webhook processed

Scenario: Invalid signature rejected
  Given a Razorpay webhook with tampered signature
  When POST /webhooks/payment/razorpay
  Then HTTP 400 returned, PaymentHistory unchanged
  And response body does NOT contain internal error details

Scenario: Missing webhook secret
  Given gateway has no webhook_secret configured
  When POST /webhooks/payment/razorpay
  Then HTTP 400 returned, generic error message
```

**TS-PAY-03: WebhookIdempotencyTest (P0)**
```
Scenario: Duplicate payment.captured webhook
  Given PaymentHistory with status='success'
  When payment.captured webhook arrives again with same order_id
  Then HTTP 200 returned immediately
  And PaymentSucceeded event NOT dispatched again
  And PaymentHistory unchanged
```

**TS-PAY-04: CredentialEncryptionTest (P0)**
```
Scenario: Credentials stored encrypted
  Given admin creates gateway with credentials {key: 'rzp_test_...', secret: '...'}
  When record is saved
  Then raw DB value of credentials column is encrypted (not plaintext JSON)
  And getCredential('key') returns decrypted value 'rzp_test_...'
```

**TS-PAY-05: PaymentInitiationTransactionTest (P1)**
```
Scenario: Gateway API failure rolls back PaymentHistory
  Given Razorpay API throws exception during order create
  When makePayment() is called
  Then no PaymentHistory record exists in DB (transaction rolled back)
  And redirect back with error message
```

**TS-PAY-06: RefundWorkflowTest (P1)**
```
Scenario: Full refund on successful payment
  Given PaymentHistory with status='success', amount=500
  When refund of 500 is initiated
  Then PaymentRefund created with status='pending'
  And Razorpay refund API is called with amount=50000 (paise)
  And PaymentRefund.status='processed' after API success
  And PaymentHistory.status='refunded'

Scenario: Partial refund
  Given PaymentHistory amount=500, prior refund=200
  When refund of 200 is initiated (total would be 400)
  Then refund is created successfully
  And PaymentHistory.status remains 'success'

Scenario: Over-refund blocked
  Given PaymentHistory amount=500, prior refund=200
  When refund of 400 is attempted (total would be 600)
  Then validation error: "Refund amount exceeds available balance"
```

**TS-PAY-07: TablePrefixTest (P0)**
```
Scenario: All models reference pay_* tables
  Then Payment::$table = 'pay_payments'
  Then PaymentGateway::$table = 'pay_payment_gateways'
  Then PaymentHistory::$table = 'pay_payment_histories'
  Then PaymentWebhook::$table = 'pay_payment_webhooks'
  Then PaymentRefund::$table = 'pay_payment_refunds'
```

**TS-PAY-08: MakePaymentFormRequestTest (P1)**
```
Scenario: Validation uses correct table name
  Given makePayment request with gateway='razorpay'
  And pay_payment_gateways table has razorpay record
  Then validation passes (not ptm_payment_gateways)

Scenario: Amount max limit enforced
  Given makePayment request with amount=600000
  Then validation fails: amount must not exceed 500000
```

---

## 13. Glossary

| Term | Definition |
|------|-----------|
| Gateway | A payment processing service (Razorpay, PayU, CCAvenue, Stripe, etc.) |
| Order | A Razorpay construct created before the customer pays; has `order_id` |
| Payment | The actual transaction; has `payment_id`; created after customer completes checkout |
| Webhook | HTTP POST callback from Razorpay to Prime-AI notifying of payment events |
| Paise | 1/100th of Indian Rupee; Razorpay API uses paise for all amounts |
| Checkout.js | Razorpay's JavaScript SDK that renders the payment modal |
| Capture | Razorpay finalizing and settling a payment; triggers `payment.captured` webhook |
| HMAC-SHA256 | Hash-Based Message Authentication Code using SHA-256; used for webhook signature verification |
| Idempotency | Property of an operation that produces the same result if executed multiple times |
| Payable | Any domain entity that can be paid for (fee invoice, fine, etc.) via polymorphic association |
| Soft Delete | Marking a record as deleted via `deleted_at` without removing from DB (financial records require this) |
| PCI-DSS | Payment Card Industry Data Security Standard; Razorpay's hosted checkout keeps Prime-AI out of scope |
| `ptm_` prefix | Erroneous prefix used in Payment module code; all should be `pay_` |
| `pmt_` prefix | Second erroneous prefix variant (used in PaymentWebhook model); should be `pay_` |

---

## 14. Suggestions

### Priority 0 — Production Blockers (fix before any beta testing)

1. **Fix SEC-02 (webhook route):** Move the webhook route definition to OUTSIDE any `middleware()` group in `routes/tenant.php`. Add `webhooks/payment/*` to `VerifyCsrfToken::$except`. This is a one-line fix that unblocks the entire payment reconciliation flow.

2. **Define DDL and create migrations:** Write Laravel migration files for all 5 tables (`pay_payments`, `pay_payment_gateways`, `pay_payment_histories`, `pay_payment_webhooks`, `pay_payment_refunds`). Without these, the module cannot be deployed to any environment.

3. **Fix all `$table` properties:** Update all 5 models to use `pay_` prefix. Update `PaymentGatewayRequest.php` validation rule from `ptm_payment_gateways` to `pay_payment_gateways`. Update `PaymentController.php` inline validation rule.

4. **Implement credential encryption:** Add `getCredentialsAttribute()` and `setCredentialsAttribute()` to `PaymentGateway`. Change column type from `JSON` to `TEXT` in DDL (encrypted blob is not valid JSON). Remove the `credentials => array` cast entry and handle de-serialization in the accessor.

5. **Rebuild `Payment` model:** Add full `$fillable`, `$casts`, `SoftDeletes`, relationships to `PaymentHistory`, and polymorphic `payable()` morphTo.

6. **Create `PaymentPolicy`:** Add authorization to `makePayment()` (currently zero auth check — any user can initiate payments of any amount for any entity).

### Priority 1 — Required Before Beta

7. **Create `MakePaymentRequest` FormRequest:** Replace inline `$request->validate()` in `PaymentController::makePayment()` with a proper FormRequest class. Include `max:500000` on amount field.

8. **Wrap `createPayment()` in `DB::transaction()`:** Prevents orphan `PaymentHistory` records when Razorpay API throws exception.

9. **Add `SoftDeletes` to `PaymentHistory`:** Financial records must never be hard-deleted.

10. **Add `EnsureTenantHasModule` middleware** to payment route group.

11. **Implement refund flow:** `PaymentRefundController`, `RefundService::processRefund()`, refund views. Use Razorpay's `$api->payment->fetch($id)->refund(['amount' => $paise])`.

12. **Fix SEC-03:** Replace `return response()->json(['error' => $e->getMessage()], 400)` with `return response()->json(['error' => 'Webhook processing error.'], 400)`. Log internal details only.

13. **Remove credential fields from activity log data:** In `PaymentGatewayController::store()` and `update()`, never include `credentials` in the `activityLog()` call's data array.

### Priority 2 — Required Before GA

14. **Payment receipt PDF:** Use DomPDF (same pattern as HPC module). Create `PaymentReceiptListener` implementing `ShouldQueue` listening to `PaymentSucceeded`. Store to `sys_media`.

15. **Implement callback verification:** `makePaymentCallback()` should verify Razorpay's client-side signature (`razorpay_payment_id|razorpay_order_id` + `key_secret`). Note: this is a secondary confirmation; the webhook remains the authoritative source.

16. **Webhook logs UI:** Implement the webhook logs view for admin debugging and manual re-processing.

17. **Cache `PaymentGateway` records:** Use `Cache::remember('payment.gateway.razorpay', 300, fn() => ...)` in `GatewayManager::resolve()`.

18. **Add `PaymentSucceeded` → `FeeInvoicePaymentListener`:** Implement the missing listener that marks `fin_fee_invoices` as paid when `PaymentSucceeded` fires.

### Priority 3 — Nice to Have

19. **PayU gateway driver:** Add `PayUGateway implements PaymentGatewayInterface` for broader coverage.

20. **Razorpay Payment Links:** Use `$api->paymentLink->create([...])` to generate shareable fee payment links sent via WhatsApp/email (useful for schools sending reminders).

21. **IP allowlisting for webhooks:** Validate `$request->ip()` against Razorpay's published IP ranges before processing.

22. **Payment analytics:** Add a dedicated analytics tab on the payment dashboard with monthly collection trends, gateway-wise breakdown, and failure rate metrics.

23. **Move gateway drivers list to config:** Replace `getAvailableDrivers()` hardcoded array in `PaymentGatewayController` with a `config/payment.php` entry.

---

## 15. Appendices

### Appendix A: File Inventory

| File | Path | Status |
|------|------|--------|
| `PaymentController` | `Modules/Payment/app/Http/Controllers/PaymentController.php` | 🟡 Functional but needs fixes |
| `PaymentGatewayController` | `Modules/Payment/app/Http/Controllers/PaymentGatewayController.php` | ✅ Well implemented |
| `PaymentService` | `Modules/Payment/app/Services/PaymentService.php` | 🟡 Missing DB::transaction |
| `GatewayManager` | `Modules/Payment/app/Services/GatewayManager.php` | ✅ Clean |
| `RazorpayGateway` | `Modules/Payment/app/Gateways/RazorpayGateway.php` | ✅ Correct implementation |
| `BaseGateway` | `Modules/Payment/app/Gateways/BaseGateway.php` | ✅ Abstract base |
| `PaymentGatewayInterface` | `Modules/Payment/app/Contracts/PaymentGatewayInterface.php` | ✅ Clean interface |
| `PaymentData` DTO | `Modules/Payment/app/DTO/PaymentData.php` | ✅ Good design |
| `PaymentGatewayRequest` | `Modules/Payment/app/Http/Requests/PaymentGatewayRequest.php` | 🟡 Wrong table prefix |
| `Payment` model | `Modules/Payment/app/Models/Payment.php` | ❌ Stub |
| `PaymentGateway` model | `Modules/Payment/app/Models/PaymentGateway.php` | 🟡 No encryption accessors |
| `PaymentHistory` model | `Modules/Payment/app/Models/PaymentHistory.php` | 🟡 Missing SoftDeletes, paid_at |
| `PaymentWebhook` model | `Modules/Payment/app/Models/PaymentWebhook.php` | ❌ Wrong prefix (`pmt_`) |
| `PaymentRefund` model | `Modules/Payment/app/Models/PaymentRefund.php` | ❌ Empty stub |
| `PaymentFailed` event | `Modules/Payment/app/Events/PaymentFailed.php` | ✅ |
| `PaymentSucceeded` event | `Modules/Payment/app/Events/PaymentSucceeded.php` | ✅ |
| Web routes | `Modules/Payment/routes/web.php` | 🟡 Unused (actual in tenant.php) |
| API routes | `Modules/Payment/routes/api.php` | — |
| Tenant routes | `routes/tenant.php` lines 319–336 | ❌ Webhook behind auth |
| DDL | `tenant_db_v2.sql` | ❌ No tables defined |

### Appendix B: Bug & Security Issue Registry

| ID | Severity | Description | Current State | Fix |
|----|----------|-------------|---------------|-----|
| SEC-01 | P0 CRITICAL | Gateway credentials stored as plaintext JSON | `PaymentGateway.credentials` cast as `array` | Add `getCredentialsAttribute` / `setCredentialsAttribute` with `Crypt::encryptString` |
| SEC-02 | P0 CRITICAL | Webhook route inside `auth` middleware — all gateway callbacks return HTTP 401 | `tenant.php` line 326 inside `middleware(['auth','verified'])` | Move route outside auth group; add to CSRF except |
| SEC-03 | P1 HIGH | `handleWebhook()` returns `$e->getMessage()` to external caller | `PaymentController.php` line 116 | Return generic "Webhook processing error" |
| DB-01 | P0 CRITICAL | No `pay_*` tables in DDL or migrations | `tenant_db_v2.sql` — no `pay_` or `ptm_` tables found | Create 5 migration files |
| DB-07 | P0 CRITICAL | `Payment` model is a stub with only `$fillable = ['is_active']` | `Payment.php` lines 11–13 | Complete rebuild |
| DB-04 | P1 HIGH | `PaymentHistory` table name `ptm_payment_histories` (no DDL) | `PaymentHistory.php` line 12 | Rename to `pay_payment_histories` in model and DDL |
| DB-05 | P1 HIGH | `PaymentWebhook` table name `pmt_payment_webhooks` (typo variant) | `PaymentWebhook.php` line 11 | Rename to `pay_payment_webhooks` |
| RT-01 | P0 HIGH | `EnsureTenantHasModule` middleware not applied to payment routes | `tenant.php` line 320 | Add `module:payment` to route group middleware |
| RT-03 | P2 MEDIUM | Route name typo: "purchase-successfull" (double-l) | `tenant.php` line 325 | Rename to `payment.callback` |
| MD-04 | P1 HIGH | `PaymentHistory` missing `SoftDeletes` | `PaymentHistory.php` — no trait | Add `use SoftDeletes;` |
| MD-01 | P0 CRITICAL | `Payment` model stub | `Payment.php` | Full rebuild |
| SV-01 | P1 HIGH | `createPayment()` missing `DB::transaction()` | `PaymentService.php` lines 17–47 | Wrap in transaction |
| PL-01 | P0 HIGH | No `PaymentPolicy` class | Directory does not exist | Create `PaymentPolicy` |
| PL-03 | P1 HIGH | `makePayment()` has no authorization check | `PaymentController.php` line 43 | Add `Gate::authorize('payment.makePayment')` |
| FR-01 | P1 HIGH | `makePayment()` uses inline validation not FormRequest | `PaymentController.php` line 45 | Create `MakePaymentRequest` |
| PERF-02 | P2 MED | `PaymentGateway` fetched from DB on every payment initiation | `GatewayManager.php` | Add `Cache::remember()` |

### Appendix C: Razorpay Integration Checklist

- [ ] `key_id` and `key_secret` stored encrypted via `Crypt::encryptString()`
- [ ] `webhook_secret` stored encrypted
- [ ] Webhook endpoint at `/webhooks/payment/razorpay` — no auth middleware
- [ ] Webhook endpoint in `VerifyCsrfToken::$except`
- [ ] `X-Razorpay-Signature` verified on every webhook call
- [ ] Webhook processing is idempotent (duplicate `payment.captured` safe)
- [ ] Amount: INR stored as `DECIMAL(12,2)`, Razorpay API receives `amount * 100` (paise)
- [ ] Auto-capture: `payment_capture = 1` in order creation
- [ ] Checkout.js `key` is the public `key_id` only (never secret)
- [ ] Client callback verifies `razorpay_payment_id|razorpay_order_id` signature
- [ ] `PaymentSucceeded` → fee invoice marked paid
- [ ] No card data in logs, DB, or error responses

### Appendix D: Gap Analysis Score

| Area | V1 Score | V2 Target |
|------|----------|-----------|
| DB Integrity | 3/10 | 9/10 (after DDL + prefix fix) |
| Route Integrity | 6/10 | 9/10 (after webhook fix + module middleware) |
| Controller Quality | 6/10 | 8/10 (after FormRequest + transaction) |
| Model Quality | 5/10 | 9/10 (after stub rebuild + encryption) |
| Service Layer | 7/10 | 9/10 (after transaction wrapping + refund service) |
| FormRequest | 4/10 | 8/10 (after MakePaymentRequest added) |
| Policy/Auth | 3/10 | 8/10 (after PaymentPolicy created) |
| Test Coverage | 7/10 | 9/10 (after webhook + refund tests) |
| Security | 5/10 | 9/10 (after credential encryption + webhook route fix) |
| Performance | 6/10 | 8/10 (after caching + dedup) |
| **Overall** | **5.2/10** | **8.6/10** |

---

## 16. V1 to V2 Delta

### New in V2

| Change | Section | Rationale |
|--------|---------|-----------|
| `pay_payments` table full DDL | §5.6 | Stub model needed schema definition |
| `idempotency_key` column in `pay_payment_histories` | §5.3 | Prevents duplicate orders from re-submissions |
| `failure_reason` column extracted to separate field | §5.3 | Better failure diagnostics than burying in `gateway_payload` |
| `paid_at` column in `pay_payment_histories` | §5.3 | Required for receipt timestamps and financial reporting |
| `PaymentRefund` table DDL with FK constraint | §5.5 | Model was a stub with no schema |
| V2 route structure with refund + webhook-logs routes | §6.2 | Missing routes added |
| `FR-PAY-06` Receipt generation requirement | §4 | Business need not in V1 |
| `FR-PAY-07` PaymentPolicy requirement | §4 | Zero auth on makePayment is critical gap |
| `FR-PAY-08` Webhook logs view | §4 | Operations / debugging requirement |
| DB transaction wrapping in `createPayment()` | §4, §14 | Data integrity gap |
| `customer` array in `PaymentData` DTO | §5.8 | Prefill checkout form fields |
| `refund.created` webhook event handling | §4 FR-PAY-03.3 | Webhook event coverage expansion |
| SEC-04 IP allowlisting suggestion | §14 | Defense-in-depth for webhook endpoint |
| Razorpay Payment Links (Priority 3) | §14 | New capability for fee reminders |

### Changed from V1

| V1 | V2 | Reason |
|----|-----|--------|
| `gateway_payment_id` called "transaction_id" in model | Renamed to `gateway_payment_id` | Align with Razorpay/gateway nomenclature |
| `gateway_response` column name | Renamed to `gateway_payload` | More accurate — it stores the full webhook payload |
| Table prefix described as "proposed as `pay_*`" | Firmly standardized as `pay_*` — all models must change | Clear directive vs suggestion |
| V1 described `payment.captured` as "V2 proposed" for `refund.created` | Now listed as required V2 implementation | Escalated priority |
| `credentials` cast as `array` | Cast removed; encryption via model accessors; column type `TEXT` | Encryption incompatible with JSON cast |
| Webhook route fix described as "required" | Same, but with exact code location (`tenant.php` line 326) and fix mechanism | Precision |

### Preserved from V1

- Gateway abstraction pattern (Interface + DTO + BaseGateway + GatewayManager) — architecture is sound
- `RazorpayGateway::initiate()` implementation — correct Razorpay order creation
- Webhook signature verification logic in `verifyWebhookSignature()` — HMAC-SHA256 with `hash_equals()` is correct
- Idempotency guard in `processWebhookEvent()` — correct approach
- `PaymentGatewayController` full CRUD + trash/restore/forceDelete/toggleStatus — well implemented
- `PaymentHistory` status helper methods — `markSuccess()`, `markFailed()`, `markCancelled()`, `markRefunded()`, `isSuccess()`, etc.
- All 8 existing test files — retain and extend
- Event-driven post-payment processing pattern — `PaymentSucceeded` / `PaymentFailed`
