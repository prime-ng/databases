# Payment Lifecycle — Feature Requirement (Infrastructure)

## 1. Feature Overview

| Attribute | Value |
|-----------|-------|
| **Feature ID** | PPT-F3 |
| **Feature Name** | Payment Lifecycle — Initiate → Complete → Cancel |
| **Module** | Payment |
| **Table Prefix** | `ptm_` |
| **Type** | Infrastructure / Service Module |
| **Description** | Core payment lifecycle covering initiation (online/offline), gateway callback processing, user-initiated cancellation, and payment status queries. Integrates with all configured gateway drivers and dispatches domain events for consuming modules. |
| **API Base** | `/api/mobile/v1/payments` (authenticated) |
| **Backend Base** | `/admin/payments` (authenticated web) |

---

## 2. Module / Table Prefix

All tables in this feature belong to the Payment module:

| Table | Purpose |
|-------|---------|
| `ptm_payment_gateways` | Configured gateway instances (code, driver class, credentials) |
| `ptm_payment_payments` | Core payment records (polymorphic payable, ULID-identified) |
| `ptm_payment_refunds` | Refund records against a payment |
| `ptm_payment_offline_records` | Offline payment details (cash, cheque, DD, bank transfer, UPI) |
| `ptm_payment_audit_logs` | Append-only audit trail for payment status transitions |

---

## 3. API Endpoints / Routes

### 3.1 Route Registration

All payment lifecycle routes are registered under the `auth:sanctum` middleware group, prefix `/api/mobile/v1`:

```php
Route::middleware(['auth:sanctum'])->prefix('v1')->group(function () {
    Route::post('payments/initiate',     [PaymentController::class, 'initiate']);  // payment.initiate
    Route::post('payments/{ulid}/callback', [PaymentController::class, 'callback']); // payment.callback
    Route::post('payments/{ulid}/cancel',   [PaymentController::class, 'cancel']);   // payment.cancel
    Route::post('payments/{ulid}/refund',   [RefundController::class, 'store']);     // payment.refund.store
    Route::get('payments/{ulid}/refunds',   [RefundController::class, 'index']);     // payment.refund.index
    Route::get('payments/{ulid}',           [PaymentController::class, 'show']);     // payment.show
});
```

### 3.2 Endpoint Details

#### POST `/api/mobile/v1/payments/initiate`

| Attribute | Value |
|-----------|-------|
| **Purpose** | Initiate a new payment for a payable model |
| **Auth** | Sanctum bearer token |
| **Authorization** | `tenant.payment.create` (via InitiatePaymentRequest and PaymentPolicy@create) |
| **Request Body** | See Section 4 |
| **Success Response** | `HTTP 201` — `{payment: {ulid, amount, status}, checkout: {...}}` |
| **Failure Response** | `HTTP 422` — validation errors / `HTTP 403` — unauthorized / `HTTP 404` — payable/gateway not found |

**Flow:**
1. `InitiatePaymentRequest` validates the input (payable_type exists + implements Payable, payable_id >= 1, gateway code is active)
2. Payable model resolved via `$payableClass::findOrFail($payableId)`
3. `PaymentPolicy@create` — user must have `tenant.payment.create`
4. If `gateway == 'offline'`, collect `offline_method`, `offline_reference`, `offline_notes`
5. `PaymentService@initiate()` executes within a DB transaction
6. Gateway resolved via `GatewayManager@resolve(code)` → instantiates driver with credentials
7. `driver->initiate(PaymentData)` called — returns `{gateway_order_id, checkout_data}`
8. Payment status transitions: `initiated` → `pending` (after gateway initiation)
9. For offline payments: creates `ptm_payment_offline_records` row
10. Dispatches `PaymentInitiated` event
11. Returns `{payment: {ulid, amount, status}, checkout: {...}}`

#### POST `/api/mobile/v1/payments/{ulid}/callback`

| Attribute | Value |
|-----------|-------|
| **Purpose** | Handle gateway redirect callback after payment |
| **Auth** | Sanctum bearer token |
| **Authorization** | `tenant.payment.create` (via PaymentCallbackRequest) and `PaymentPolicy@view` |
| **Request Body** | `{razorpay_payment_id, razorpay_order_id, razorpay_signature}` — all required strings |
| **Success Response** | `HTTP 200` — `{status: 'success'}` |
| **Failure Response** | `HTTP 422` — `{status: 'failed'}` on verification failure |

**Flow:**
1. Payment resolved by ULID via `PaymentService@getByUlid`
2. `PaymentPolicy@view` — user must have `tenant.payment.view`
3. Gateway driver resolved via `GatewayManager@resolve(code)`
4. `driver->verify(payload)` called with the callback payload fields
5. If verified: `PaymentService@markSuccess()` — status → `success`, records `gateway_payment_id`, `gateway_signature`, `paid_at`, dispatches `PaymentSucceeded`
6. If not verified: `PaymentService@markFailed()` — status → `failed`, records `failure_reason`, dispatches `PaymentFailed`
7. Audit logged for both paths

#### POST `/api/mobile/v1/payments/{ulid}/cancel`

| Attribute | Value |
|-----------|-------|
| **Purpose** | Cancel a pending payment |
| **Auth** | Sanctum bearer token |
| **Authorization** | `tenant.payment.cancel` (via PaymentPolicy@cancel) |
| **Request Body** | Empty |
| **Success Response** | `HTTP 200` — `{status: 'cancelled'}` |

**Flow:**
1. Payment resolved by ULID
2. `PaymentPolicy@cancel` — user must have `tenant.payment.cancel`
3. `PaymentService@cancel()` — status → `cancelled`, dispatches `PaymentCancelled`
4. Audit logged

#### GET `/api/mobile/v1/payments/{ulid}`

| Attribute | Value |
|-----------|-------|
| **Purpose** | Show payment details with gateway, refunds, audit logs |
| **Auth** | Sanctum bearer token |
| **Authorization** | `tenant.payment.view` (via PaymentPolicy@view) |
| **Response** | Payment model with loaded relations: `gateway`, `refunds`, `auditLogs` |

---

## 4. Request Validation Rules

### InitiatePaymentRequest

| Field | Rules | Details |
|-------|-------|---------|
| `payable_type` | `required`, `string`, custom validator | Must be an existing class that implements `Payable` interface. Error: "The payable type [{value}] does not exist." / "The payable type [{value}] must implement the Payable interface." |
| `payable_id` | `required`, `integer`, `min:1` | Primary key of the payable model |
| `gateway` | `required`, `string`, `in:{active_gateway_codes}` | Dynamically computed from `PaymentGateway::where('is_active', true)->pluck('code')` |
| `offline_method` | `required_if:gateway,offline`, `string`, `in:cash,cheque,bank_transfer,demand_draft,upi_manual` | Only when gateway is 'offline' |
| `offline_reference` | `nullable`, `string`, `max:100` | Optional reference number |
| `offline_notes` | `nullable`, `string`, `max:500` | Optional notes |

**Authorization guard** (in `authorize()` method): `auth()->check() && auth()->user()->can('tenant.payment.create')`

### PaymentCallbackRequest

| Field | Rules | Details |
|-------|-------|---------|
| `razorpay_payment_id` | `required`, `string` | Razorpay payment ID |
| `razorpay_order_id` | `required`, `string` | Razorpay order ID |
| `razorpay_signature` | `required`, `string` | HMAC signature |

**Note:** This request is Razorpay-specific in its field names. Other gateway callbacks are handled differently (see gateway sections).

**Authorization guard**: `auth()->check() && auth()->user()->can('tenant.payment.create')`

### InitiateRefundRequest

| Field | Rules | Details |
|-------|-------|---------|
| `amount` | `required`, `numeric`, `min:0.01` | Refund amount |
| `reason` | `required`, `string`, `max:500` | Refund reason |

**Authorization guard**: `auth()->check() && auth()->user()->can('tenant.payment.refund')`

---

## 5. State Machine / Status Flow

### Payment Status Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `STATUS_INITIATED` | `initiated` | Payment record created but not yet sent to gateway |
| `STATUS_PENDING` | `pending` | Gateway order created, awaiting completion |
| `STATUS_SUCCESS` | `success` | Payment verified and completed |
| `STATUS_FAILED` | `failed` | Gateway verification failed or payment declined |
| `STATUS_CANCELLED` | `cancelled` | User cancelled before gateway processed |
| `STATUS_REFUNDED` | `refunded` | Payment fully refunded (set by RefundService) |

### Status Transition Diagram

```
  [Initiation]
       |
  initiated ──► pending ──► success ──► refunded (via refund flow)
       |            |
       |            +──► failed
       |
       +──► cancelled
```

### Allowed Transitions

| From | To | Trigger | Method |
|------|----|---------|--------|
| (new) | `initiated` | Payment creation | `Payment::create()` |
| `initiated` | `pending` | Gateway order created | `PaymentService@initiate` |
| `pending` | `success` | Gateway verification passes | `PaymentService@markSuccess` |
| `pending` | `failed` | Gateway verification fails | `PaymentService@markFailed` |
| `initiated` | `cancelled` | User cancels | `PaymentService@cancel` |
| `pending` | `cancelled` | User cancels | `PaymentService@cancel` |
| `success` | `refunded` | Full refund completed | `RefundService@markRefundSuccess` |

**Note:** The code does not enforce state-machine guards (no "canTransitionFrom" check). Any status can be overwritten by calling the respective service method. This is a potential improvement area.

### Refund Status Constants (PaymentRefund model)

| Constant | Value |
|----------|-------|
| `STATUS_PENDING` | `pending` |
| `STATUS_PROCESSING` | `processing` |
| `STATUS_SUCCESS` | `success` |
| `STATUS_FAILED` | `failed` |

---

## 6. Service Layer

### PaymentService

| Method | Signature | Description |
|--------|-----------|-------------|
| `initiate` | `(Payable $payable, string $gatewayCode, ?int $userId, array $offlineData): array` | Creates payment, resolves gateway, calls driver->initiate(), creates offline record if offline. Returns `{payment, checkout}`. Runs in DB transaction. |
| `markSuccess` | `(Payment $payment, array $gatewayPayload): void` | Sets status=success, records gateway_payment_id, gateway_signature, paid_at. Logs audit. Dispatches PaymentSucceeded. |
| `markFailed` | `(Payment $payment, string $reason, array $payload): void` | Sets status=failed, records failure_reason. Logs audit. Dispatches PaymentFailed. |
| `cancel` | `(Payment $payment): void` | Sets status=cancelled. Logs audit. Dispatches PaymentCancelled. |
| `getByUlid` | `(string $ulid): Payment` | Finds payment by ULID or throws ModelNotFoundException. |

### RefundService

| Method | Signature | Description |
|--------|-----------|-------------|
| `initiate` | `(Payment $payment, float $amount, string $reason, ?int $userId): PaymentRefund` | Validates refundable state (must be `success`), checks max refundable amount with row lock, creates refund record, calls gateway `driver->refund()`. Throws `RuntimeException` if payment not success. Throws `InvalidArgumentException` if amount exceeds max refundable. |
| `markRefundSuccess` | `(PaymentRefund $refund, array $payload): void` | Sets refund status=success, refunded_at=now. If total refunded >= payment.amount, sets payment status=refunded. Dispatches RefundSucceeded. |
| `markRefundFailed` | `(PaymentRefund $refund, string $reason, array $payload): void` | Sets refund status=failed. Dispatches RefundFailed. |
| `getRefundsForPayment` | `(Payment $payment): Collection` | Returns all refunds for a payment, latest first. |

### GatewayManager

| Method | Signature | Description |
|--------|-----------|-------------|
| `resolve` | `(string $code): PaymentGatewayInterface` | Finds active gateway by code, validates driver class exists, instantiates driver with credentials + extra_config. Errors: "Payment gateway [{code}] not found or inactive." / "Gateway driver [{driverClass}] does not exist." |

### AuditService

| Method | Signature | Description |
|--------|-----------|-------------|
| `log` | `(Payment $payment, string $event, ?string $fromStatus, ?string $toStatus, ?string $actorType, ?int $actorId, array $payload, ?Request $request): PaymentAuditLog` | Creates immutable audit log entry |
| `logStatusChange` | Same as log but event=`status.changed` | Convenience wrapper for status transitions |
| `logWebhook` | `(Payment $payment, string $gatewayEvent, array $payload): PaymentAuditLog` | Logs webhook receipt. Event name: `webhook.{gatewayEvent}` |
| `getTimeline` | `(Payment $payment): Collection` | Returns audit timeline, oldest first |

---

## 7. Gateway Layer (Drivers)

### PaymentGatewayInterface

```php
interface PaymentGatewayInterface {
    public function initiate(PaymentData $data): array;       // Returns {gateway_order_id, checkout_data}
    public function verify(array $payload): bool;              // Verify redirect callback
    public function handleWebhook(array $payload): void;       // Handle webhook payload
    public function refund(Payment $payment, float $amount): array;  // Initiate refund
    public function getWebhookSecret(): string;                // Raw webhook secret
    public function getSupportedEvents(): array;               // List of event names
    public function verifyWebhookSignature(string $rawBody, array $headers): bool;  // Verify webhook HMAC
}
```

### PaymentData DTO

| Field | Type | Description |
|-------|------|-------------|
| `ulid` | `string` | Payment ULID |
| `amount` | `float` | Payment amount |
| `currency` | `string` | Currency code (default: INR) |
| `label` | `string` | Human-readable label from Payable |
| `customerName` | `string` | Customer name from Payable |
| `customerEmail` | `string` | Customer email from Payable |
| `customerPhone` | `string` | Customer phone from Payable |
| `metadata` | `array` | Metadata from Payable |

### Payable Contract

```php
interface Payable {
    public function getPayableLabel(): string;           // e.g. "Fee Invoice #INV-2026-001"
    public function getPayableAmount(): float;           // Amount due
    public function getPayableCustomer(): array;         // {name, email, phone, student_id}
    public function getPayableMetadata(): array;         // Free-form metadata
}
```

### Gateway Implementations

| Gateway | Driver Class | Initiate Flow | Verify Flow | Refund Flow |
|---------|-------------|---------------|-------------|-------------|
| **Razorpay** | `RazorpayGateway` | Creates Razorpay order via API (paise × 100). Returns `{key, order_id, ulid, amount, currency, name, email, contact, notes}` | HMAC-SHA256 signature verification: `hash_hmac('sha256', order_id\|\|payment_id, key_secret)` | API refund via `$api->payment->fetch()->refund()` |
| **Offline** | `OfflineGateway` | Generates `OFFLINE-XXXXXXXX` reference. Returns customer details. | `verify()` always returns `true` (human-approved) | Returns synthetic `OFFLINE-REFUND-XXXXXXXX` ID |
| **Paytm** | `PaytmGateway` | POST to `/theia/api/v1/initiateTransaction` with HMAC-SHA256 signed payload. Returns `{txn_token, order_id, mid, amount, callback_url}` | Verifies `CHECKSUMHASH` in callback payload | POST to `/v2/refund/apply` |
| **PhonePe** | `PhonePeGateway` | POST to `/pg/v1/pay` with base64-encoded payload and SHA256+salt checksum. Returns redirect URL. | Verifies `X-VERIFY` header checksum | POST to `/pg/v1/refund` |
| **CCAvenue** | `CCAvenueGateway` | AES-128-CBC encrypted form-post. Returns `{action, enc_request, access_code}` | Decrypts `encResp`, checks `order_status === 'Success'` | Synthetic `CCAV-REFUND-XXXX` (pending) |
| **BillDesk** | `BillDeskGateway` | HMAC-SHA256 signed pipe-separated message. Returns form-post action + msg. | Verifies HMAC on `BD_RESPONSE` | Synthetic `BDESK-REFUND-XXXX` (pending) |

### Gateway Credentials

Each gateway stores credentials as encrypted JSON in `ptm_payment_gateways.credentials` (cast as `encrypted:array`):

| Gateway | Expected Credential Keys |
|---------|------------------------|
| Razorpay | `key_id`, `key_secret`, `webhook_secret` |
| Offline | (none required) |
| Paytm | `merchant_id`, `merchant_key`, `website`, `callback_url` |
| PhonePe | `merchant_id`, `salt_key`, `salt_index`, `redirect_url`, `callback_url` |
| CCAvenue | `merchant_id`, `access_code`, `working_key`, `redirect_url`, `cancel_url` |
| BillDesk | `merchant_id`, `security_id`, `checksum_key`, `return_url` |

---

## 8. Event / Listener Chain

### Payment Lifecycle Events

| Event | Dispatched By | Payload | Listeners |
|-------|---------------|---------|-----------|
| `PaymentInitiated` | `PaymentService@initiate` | `{payment}` | `PaymentInitiatedListener` — logs audit `payment.initiated.event` |
| `PaymentSucceeded` | `PaymentService@markSuccess` | `{payment}` | `PaymentSucceededListener` — logs audit `payment.succeeded` + calls `$payable->recordPaymentSuccess($payment)` if method exists |
| `PaymentFailed` | `PaymentService@markFailed` | `{payment, reason}` | `PaymentFailedListener` — logs audit `payment.failed` + calls `$payable->recordPaymentFailure($payment, $reason)` if method exists |
| `PaymentCancelled` | `PaymentService@cancel` | `{payment}` | `PaymentCancelledListener` — logs audit `payment.cancelled` |

### Refund Events

| Event | Dispatched By | Payload | Listeners |
|-------|---------------|---------|-----------|
| `RefundInitiated` | `RefundService@initiate` | `{refund}` | `RefundInitiatedListener` — logs audit `refund.initiated.event` |
| `RefundSucceeded` | `RefundService@markRefundSuccess` | `{refund}` | `RefundSucceededListener` — logs audit `refund.ledger_updated`, bridges to StudentFee module (FeeTransaction markRefunded) |
| `RefundFailed` | `RefundService@markRefundFailed` | `{refund, reason}` | `RefundFailedListener` — logs audit `refund.failed` |

**Design note:** Consuming modules react to events via their own listeners registered on these events. The Payment module does not depend on any consuming module.

---

## 9. Audit Trail

### ptm_payment_audit_logs Schema

| Column | Type | Description |
|--------|------|-------------|
| `id` | INT UNSIGNED PK | Auto-increment |
| `payment_id` | INT UNSIGNED FK | References ptm_payment_payments |
| `event` | VARCHAR(255) | Event name |
| `from_status` | VARCHAR(255) NULL | Previous status |
| `to_status` | VARCHAR(255) NULL | New status |
| `actor_type` | VARCHAR(255) NULL | 'user', 'system', 'gateway', 'webhook' |
| `actor_id` | INT UNSIGNED NULL | Actor's user ID |
| `payload` | JSON NULL | Contextual data |
| `ip_address` | VARCHAR(45) NULL | Request IP |
| `user_agent` | TEXT NULL | Request user agent |
| `created_at` | TIMESTAMP | Managed manually (no updated_at) |

**Immutability:** `PaymentAuditLog` does NOT use `SoftDeletes`. It is append-only — no updates, no deletes.

### Audit Events Logged per Status Transition

| Transition | Event Name | Actor Type | Payload Contains |
|------------|------------|------------|-----------------|
| initiated → pending | `payment.initiated` | `system` | `gateway_code`, `amount` |
| initiated → pending | `payment.initiated.event` (listener) | `system` | `gateway_order_id`, `gateway_payment_id` |
| pending → success | `status.changed` (service) | `gateway` | `{...gatewayPayload}` |
| pending → success | `payment.succeeded` (listener) | `gateway` | `gateway_payment_id`, `gateway_order_id`, `paid_at` |
| pending → failed | `status.changed` (service) | `gateway` | `reason`, `{...payload}` |
| pending → failed | `payment.failed` (listener) | `gateway` | `reason`, `gateway_payment_id` |
| any → cancelled | `status.changed` (service) | `user` | (none) |
| any → cancelled | `payment.cancelled` (listener) | `user` | `gateway_order_id`, `gateway_payment_id` |
| success → refunded | `refund.initiated` | `system` | `refund_ulid`, `amount`, `reason` |
| success → refunded | `refund.succeeded` | `gateway` | `refund_ulid`, `gateway_refund_id` |

---

## 10. Security & Authorization

### Permission Strings

| Permission | Used By | Controller Action |
|------------|---------|-------------------|
| `tenant.payment.create` | `InitiatePaymentRequest@authorize`, `PaymentPolicy@create` | `initiate` |
| `tenant.payment.view` | `PaymentPolicy@view` | `callback`, `show` |
| `tenant.payment.viewAny` | `PaymentPolicy@viewAny` | Backend `index` |
| `tenant.payment.cancel` | `PaymentPolicy@cancel` | `cancel` |
| `tenant.payment.refund` | `PaymentPolicy@refund`, `InitiateRefundRequest@authorize` | `refund.store`, `refund.index` |
| `tenant.payment.update` | `PaymentPolicy@update` | (reserved) |
| `tenant.payment.delete` | `PaymentPolicy@delete` | (reserved) |

### Policy: PaymentPolicy

| Method | Gate | Permission |
|--------|------|------------|
| `viewAny` | `tenant.payment.viewAny` | List all payments |
| `view` | `tenant.payment.view` | Show single payment |
| `create` | `tenant.payment.create` | Initiate payment |
| `update` | `tenant.payment.update` | Update payment |
| `delete` | `tenant.payment.delete` | Delete payment |
| `refund` | `tenant.payment.refund` | Initiate refund |
| `cancel` | `tenant.payment.cancel` | Cancel payment |

### API Security

- All API routes are behind `auth:sanctum` middleware
- All actions check authorization via `$this->authorize()` or Gate facade
- `InitiatePaymentRequest` and `PaymentCallbackRequest` both guard with `tenant.payment.create`
- Payment resolution uses ULID (not auto-increment ID) — no enumeration risk
- Gateway credentials stored encrypted (cast as `encrypted:array`)

### Backend Security

- Backend `index`: `PaymentPolicy@viewAny` check
- Backend `show`: `PaymentPolicy@view` check
- Receipt download: `PaymentPolicy@view` check

---

## 11. Error Handling

### Exception / Error Scenarios

| Scenario | HTTP Code | Response / Behavior |
|----------|-----------|---------------------|
| Invalid `payable_type` (class not found) | 422 | `"The payable type [{value}] does not exist."` |
| Payable does not implement `Payable` | 422 | `"The payable type [{value}] must implement the Payable interface."` |
| Invalid gateway code | 422 | Validation error (gateway must be in active list) |
| Inactive/missing gateway | 500 | `"Payment gateway [{code}] not found or inactive."` (from GatewayManager) |
| Missing gateway driver class | 500 | `"Gateway driver [{driverClass}] does not exist."` (from GatewayManager) |
| Payable not found | 404 | ModelNotFoundException → 404 |
| Payment not found by ULID | 404 | ModelNotFoundException |
| Unauthorized (missing permission) | 403 | Laravel authorization exception |
| Unauthenticated (no token) | 401 | Sanctum authentication exception |
| Callback verification fails | 422 | `{status: 'failed'}` |
| Refund on non-success payment | 500 | `"Cannot refund payment in status: {status}"` (RuntimeException) |
| Refund amount exceeds max refundable | 422 | `"Refund amount ({amount}) exceeds max refundable amount ({maxRefundable})"` (InvalidArgumentException) |
| Missing Razorpay credentials | 500 | `"Razorpay credentials (key_id, key_secret) are missing."` |
| Offline method required when gateway=offline | 422 | `validation.required_if` error |

### Payment Model Scopes

| Scope | Query |
|-------|-------|
| `scopeSuccessful($query)` | `where('status', 'success')` |
| `scopeInFlight($query)` | `whereIn('status', ['initiated', 'pending'])` |

---

## 12. Backend UI Pages

### Backend/PaymentController@index

- Route: `GET /admin/payments`
- View: `payment::payments.index`
- Data: `Payment::with('gateway')->latest()->paginate(20)`
- Auth: `PaymentPolicy@viewAny` (`tenant.payment.viewAny`)

### Backend/PaymentController@show

- Route: `GET /admin/payments/{ulid}`
- View: `payment::payments.show`
- Data: `Payment::with(['gateway', 'refunds', 'auditLogs', 'webhooks', 'offlineRecord'])->where('ulid', $ulid)->firstOrFail()`
- Auth: `PaymentPolicy@view` (`tenant.payment.view`)

### Backend/ReceiptController@show

- Route: `GET /admin/payments/{ulid}/receipt`
- Returns: PDF download via DomPDF (`Barryvdh\DomPDF`)
- View: `payment::receipts.pdf`
- Data: `Payment::with(['gateway', 'payable'])->where('ulid', $ulid)->firstOrFail()`
- Auth: `PaymentPolicy@view` (`tenant.payment.view`)
- Filename: `receipt-{ulid}.pdf`

---

## 13. Database Schema

### ptm_payment_payments

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `id` | INT UNSIGNED | PK, AUTO_INCREMENT | |
| `ulid` | CHAR(26) | UNIQUE, NOT NULL | Public identifier, generated by `Str::ulid()` |
| `payable_type` | VARCHAR(255) | NOT NULL | Morph map class name |
| `payable_id` | INT UNSIGNED | NOT NULL | FK to payable model (no DB constraint — polymorphic) |
| `gateway_id` | BIGINT UNSIGNED | NOT NULL, FK → ptm_payment_gateways.id ON DELETE CASCADE | |
| `initiated_by` | INT UNSIGNED | NULL, FK → sys_users.id ON DELETE SET NULL | User who initiated |
| `created_by` | INT UNSIGNED | NULL | User who created |
| `amount` | DECIMAL(12,2) | NOT NULL | |
| `currency` | CHAR(3) | DEFAULT 'INR' | |
| `gateway_order_id` | VARCHAR(255) | NULL, INDEXED | Order ID from gateway |
| `gateway_payment_id` | VARCHAR(255) | UNIQUE, NULL | Payment ID from gateway |
| `gateway_signature` | VARCHAR(255) | NULL | Gateway signature hash |
| `status` | VARCHAR(20) | NOT NULL, DEFAULT 'pending', INDEXED | initiated/pending/success/failed/cancelled/refunded |
| `failure_reason` | TEXT | NULL | |
| `metadata` | JSON | NULL | Payable metadata |
| `paid_at` | TIMESTAMP | NULL | |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | Soft delete |

**Indexes:** ulid (UNIQUE), gateway_payment_id (UNIQUE), status, (payable_type, payable_id), gateway_id, gateway_order_id

### ptm_payment_offline_records

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `id` | INT UNSIGNED | PK, AUTO_INCREMENT | |
| `payment_id` | INT UNSIGNED | NOT NULL, FK → ptm_payment_payments.id ON DELETE CASCADE | |
| `method` | VARCHAR(255) | NOT NULL, INDEXED | cash/cheque/bank_transfer/demand_draft/upi_manual |
| `reference_number` | VARCHAR(255) | NULL | |
| `collected_by` | INT UNSIGNED | NULL, FK → sys_users.id ON DELETE SET NULL | |
| `collected_at` | TIMESTAMP | NULL | Set to `now()` on creation |
| `cheque_bounce_at` | TIMESTAMP | NULL | |
| `notes` | TEXT | NULL | |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | INT UNSIGNED | NULL | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | Soft delete |

### ptm_payment_refunds

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | INT UNSIGNED | PK, AUTO_INCREMENT |
| `ulid` | CHAR(26) | UNIQUE, NOT NULL |
| `payment_id` | INT UNSIGNED | NOT NULL, FK → ptm_payment_payments.id ON DELETE CASCADE |
| `amount` | DECIMAL(12,2) | NOT NULL |
| `reason` | TEXT | NULL |
| `status` | VARCHAR(255) | DEFAULT 'pending' |
| `gateway_refund_id` | VARCHAR(255) | UNIQUE, NULL |
| `metadata` | JSON | NULL |
| `initiated_by` | INT UNSIGNED | NULL, FK → sys_users.id ON DELETE SET NULL |
| `created_by` | INT UNSIGNED | NULL |
| `refunded_at` | TIMESTAMP | NULL |
| `is_active` | TINYINT(1) | DEFAULT 1 |
| `created_at` | TIMESTAMP | NULL |
| `updated_at` | TIMESTAMP | NULL |
| `deleted_at` | TIMESTAMP | NULL |

### ptm_payment_audit_logs

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | INT UNSIGNED | PK, AUTO_INCREMENT |
| `payment_id` | INT UNSIGNED | NOT NULL, FK → ptm_payment_payments.id ON DELETE CASCADE |
| `event` | VARCHAR(255) | NOT NULL, INDEXED |
| `from_status` | VARCHAR(255) | NULL |
| `to_status` | VARCHAR(255) | NULL |
| `actor_type` | VARCHAR(255) | NULL, INDEXED |
| `actor_id` | INT UNSIGNED | NULL |
| `payload` | JSON | NULL |
| `ip_address` | VARCHAR(45) | NULL |
| `user_agent` | TEXT | NULL |
| `created_at` | TIMESTAMP | NULL |

**Note:** No `updated_at`, no `deleted_at` — append-only.

### ptm_payment_gateways

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | BIGINT UNSIGNED | PK, AUTO_INCREMENT |
| `name` | VARCHAR(255) | NOT NULL |
| `code` | VARCHAR(255) | UNIQUE, NOT NULL |
| `type` | VARCHAR(20) | DEFAULT 'online' |
| `driver` | VARCHAR(255) | NOT NULL (fully qualified class name) |
| `credentials` | TEXT | NULL (encrypted:array cast) |
| `extra_config` | JSON | NULL |
| `priority` | INT | DEFAULT 1 |
| `is_active` | TINYINT(1) | DEFAULT 0 |
| `deleted_at` | TIMESTAMP | NULL |
| `created_at` | TIMESTAMP | NULL |
| `updated_at` | TIMESTAMP | NULL |

---

## 14. Dependencies

### Module Dependencies

| Dependency | Type | Details |
|------------|------|---------|
| `SchoolSetup` (sys_users) | Foreign Key | `initiated_by`, `created_by`, `collected_by` reference `sys_users` |
| Consuming modules | Optional | Fee, Library, MealCard, etc. implement `Payable` interface; listen to Payment events |
| `Barryvdh\DomPDF` | Package | Receipt PDF generation |
| `Razorpay\Api\Api` | Package | Razorpay SDK for order creation and refund |
| Laravel `Http` client | Framework | Used by Paytm, PhonePe gateways |
| Laravel Queue | Framework | Webhook processing (via ProcessWebhookJob) |

### External Service Dependencies (per gateway)

| Gateway | External Dependency |
|---------|-------------------|
| Razorpay | Razorpay API (`api.razorpay.com`) |
| Paytm | Paytm API (`securegw.paytm.in`) |
| PhonePe | PhonePe API (`api.phonepe.com/apis/hermes`) |
| BillDesk | BillDesk API (`www.billdesk.com/pgidsk/PGIMerchantPayment`) |
| CCAvenue | CCAvenue API (`secure.ccavenue.com`) |

---

## 15. Configuration

### Gateway Configuration

All gateway configuration is stored in the `ptm_payment_gateways` table:

- `code`: Unique string identifier (e.g., 'razorpay', 'offline', 'paytm', 'phonepe', 'ccavenue', 'billdesk')
- `driver`: Fully qualified class name of the gateway driver
- `credentials`: Encrypted JSON containing gateway-specific keys
- `is_active`: Boolean flag — inactive gateways are skipped in validation
- `type`: 'online' or 'offline'

### InitiatePaymentRequest Gateway Validation

The `gateway` field validation rule `in:{active_gateway_codes}` is dynamically computed at request time from:
```php
$activeGateways = PaymentGateway::where('is_active', true)->pluck('code')->toArray();
```

### Environment / App Configuration

- All API routes use Sanctum for authentication
- Queue connection for ProcessWebhookJob uses default queue configuration
- DomPDF for receipt generation uses default configuration

---

## 16. Testing Considerations

### Test Coverage Areas

| Area | Scenarios |
|------|-----------|
| **Initiate** | Valid payable with each gateway; invalid payable_type; payable not implementing Payable; inactive gateway; offline payment with each method; offline payment without required fields |
| **Callback** | Valid Razorpay signature → success; invalid signature → failure; payment not found; unauthorized user |
| **Cancel** | Cancel initiated payment; cancel pending payment; cancel already completed payment; unauthorized user |
| **Show** | Payment with all relations loaded; payment not found; unauthorized user |
| **Refund** | Full refund; partial refund; refund exceeding max refundable; refund on non-success payment; refund on initiated/cancelled payment |
| **Gateway Resolution** | Active gateway resolves; inactive gateway throws; missing driver class throws |
| **Audit Trail** | Every status change creates audit log; audit log is append-only (no updates) |
| **Events** | Each event is dispatched; each listener writes audit log; payable hook methods called when present |

### Boundary Conditions

- Zero amount payable
- Very large amounts (DECIMAL(12,2) max: 99,999,999,999.99)
- Concurrent refund initiation (row lock testing)
- Gateway credential decryption failures
- Payment with same ULID (UNIQUE constraint)
- Duplicate gateway_payment_id (UNIQUE constraint)

### Integration Test Requirements

- Gateway API calls are external — mock HTTP responses for Paytm, PhonePe
- Razorpay SDK methods should be mocked
- Queue worker required for ProcessWebhookJob testing
- Tenant database isolation required

---

## Change Log

| V1/V2 | Status | CR | Date | Description |
|-------|--------|----|------|-------------|
| — | ⬜ | ◌ | 2026-07-23 | Initial requirement document generated from code analysis |
