# Webhook Processing — Feature Requirement (Infrastructure)

## 1. Feature Overview

| Attribute | Value |
|-----------|-------|
| **Feature ID** | PPT-F4 |
| **Feature Name** | Webhook Processing |
| **Module** | Payment |
| **Table Prefix** | `ptm_` |
| **Type** | Infrastructure / Service Module |
| **Description** | Inbound payment gateway webhook handling. Receives asynchronous server callbacks from payment gateways (Razorpay, PhonePe, Paytm, BillDesk), verifies signatures, stores raw payloads with idempotency protection, queues processing jobs, and dispatches domain events. |
| **Webhook Route** | `POST /payment/webhooks/{gateway}` (no auth middleware) |
| **Backend Route** | `GET /admin/payment/webhooks` (authenticated web) |

---

## 2. Module / Table Prefix

| Table | Purpose |
|-------|---------|
| `ptm_payment_webhooks` | Inbound gateway webhook events (idempotency key, payload, processing status) |
| `ptm_payment_audit_logs` | Webhook receipt audit trail (linked to payments) |

---

## 3. API Endpoints / Routes

### 3.1 Route Registration

```php
// File: routes/webhooks.php
Route::prefix('payment/webhooks')
    ->middleware(['payment.webhook.verify'])
    ->group(function () {
        Route::post('{gateway}', [WebhookController::class, 'handle'])
            ->name('payment.webhook.handle');
    });
```

**Key design decisions:**
- Routes are registered WITHOUT `auth:sanctum` middleware — gateway servers cannot provide bearer tokens
- Tenancy middleware IS applied (InitializeTenancyByDomain + PreventAccessFromCentralDomains + EnsureTenantIsActive) — ensures correct tenant database context
- Security is enforced by `VerifyWebhookSignature` middleware (see Section 10)
- Route pattern: `POST /payment/webhooks/{gateway}` where `{gateway}` is the gateway code (e.g., 'razorpay', 'phonepe')

### 3.2 Endpoint Details

#### POST `/payment/webhooks/{gateway}`

| Attribute | Value |
|-----------|-------|
| **Purpose** | Handle an inbound gateway webhook |
| **Auth** | None (no `auth:sanctum`) |
| **Security** | `VerifyWebhookSignature` middleware — delegates to gateway driver's `verifyWebhookSignature()` |
| **Request Body** | Raw JSON payload from gateway (read as raw body before JSON decode by middleware) |
| **Success Response** | `HTTP 200` — `{status: 'queued'}` |
| **Failure Response** | `HTTP 400` — missing gateway / empty body / invalid JSON<br>`HTTP 401` — invalid signature<br>`HTTP 500` — gateway driver error |

**Flow:**
1. `VerifyWebhookSignature` middleware intercepts the request BEFORE body parsing
2. Middleware reads raw body via `$request->getContent()`
3. Resolves gateway driver via `GatewayManager@resolve($gatewayCode)`
4. Calls `driver->verifyWebhookSignature($rawBody, $normalizedHeaders)`
5. On failure: returns `HTTP 401` with `{error: 'Invalid signature'}`
6. On success: decodes JSON, sets `webhook_payload`, `webhook_raw_body`, `webhook_gateway_code` on request attributes
7. Controller `handle()` method receives the verified payload
8. Extracts idempotency key from payload (gateway-specific extraction)
9. Creates `ptm_payment_webhooks` record with `processed=false`, `signature_valid=true`
10. Dispatches `ProcessWebhookJob` (queued)
11. Returns `HTTP 200` immediately — gateway servers retry on non-2xx with exponential backoff

---

## 4. Request Validation

### Webhook Controller — No Form Request

The webhook endpoint does NOT use a Form Request. Validation is performed by:
1. **VerifyWebhookSignature middleware** — validates:
   - Gateway route parameter is present (400 if missing)
   - Raw body is non-empty (400 if empty)
   - JSON body is valid (400 if malformed)
   - Signature is valid (401 if invalid)
   - Gateway driver can be resolved (500 if error)
2. **Idempotency key extraction** — must produce a non-null value (falls back to `{gateway}_{uniqid}`)
3. **Database UNIQUE constraint** on `idempotency_key` prevents duplicate processing

---

## 5. State Machine / Status Flow

### Webhook Processing States

| State | `processed` column | `error_message` column | Description |
|-------|-------------------|----------------------|-------------|
| Received | `false` | `null` | Webhook stored, job queued |
| Processing | `false` | `null` | Job is running (or retrying) |
| Success | `true` | `null` | Webhook processed successfully |
| Failed (retry) | `false` | Error message | Job threw exception, will retry (up to 3 times) |
| Failed (permanent) | `false` | "Max retries exceeded: {error}" | All 3 retries exhausted |

### ProcessWebhookJob Retry Behavior

| Property | Value |
|----------|-------|
| `$tries` | 3 |
| `$backoff` | 30 seconds (between retries) |
| On failure | Exception re-thrown → queue retries with 30s delay |
| On permanent failure | `failed()` method sets `processed=false`, `error_message="Max retries exceeded: {message}"` |

---

## 6. Service Layer

### GatewayManager@resolve

(See Feature 3 — same service, resolves gateway driver by code.)

### ProcessWebhookJob

| Method | Description |
|--------|-------------|
| `handle(GatewayManager, PaymentService, RefundService)` | Resolves driver, calls `driver->handleWebhook($payload)`, sets `processed=true` on success, sets `error_message` on failure. Re-throws exception for retry. |
| `failed(\Throwable)` | Called after all retries exhausted. Sets `processed=false`, `error_message="Max retries exceeded: {$exception->getMessage()}"`. |

```php
class ProcessWebhookJob implements ShouldQueue
{
    public int $tries = 3;
    public int $backoff = 30;

    public function handle(...): void {
        $driver = $gatewayManager->resolve($this->webhook->gateway);
        $driver->handleWebhook($this->webhook->payload);
        $this->webhook->update(['processed' => true, 'error_message' => null]);
        event(new WebhookReceived($this->webhook));
    }

    public function failed(\Throwable $exception): void {
        $this->webhook->update([
            'processed' => false,
            'error_message' => "Max retries exceeded: {$exception->getMessage()}",
        ]);
    }
}
```

### WebhookReceivedListener

```php
class WebhookReceivedListener {
    public function handle(WebhookReceived $event): void {
        $webhook = $event->webhook;
        $payment = $webhook->payment;
        if (! $payment) return; // Payment may not be linked yet

        $this->auditService->logWebhook(
            payment: $payment,
            gatewayEvent: 'received',
            payload: ['webhook_id' => $webhook->id, 'gateway' => $webhook->gateway, ...]
        );
    }
}
```

---

## 7. Gateway Layer (Webhook Handling)

### PaymentGatewayInterface — Webhook Methods

```php
interface PaymentGatewayInterface {
    public function handleWebhook(array $payload): void;                     // Process webhook payload
    public function getWebhookSecret(): string;                              // Secret for HMAC
    public function verifyWebhookSignature(string $rawBody, array $headers): bool;  // Verify signature
    public function getSupportedEvents(): array;                             // Event types supported
}
```

### Per-Gateway Webhook Behavior

#### RazorpayGateway

| Aspect | Detail |
|--------|--------|
| **Signature Verification** | HMAC-SHA256 of raw body using `webhook_secret`. Header: `x-razorpay-signature`. |
| **Supported Events** | `payment.captured`, `payment.failed`, `refund.processed` |
| **handleWebhook** | Uses `match` on `$payload['event']` |
| **payment.captured** | Extracts `order_id`, `id` (payment_id), `signature` from `payload.payload.payment.entity`. Finds Payment by `gateway_order_id`. Calls `markSuccess()` with payment_id and signature. |
| **payment.failed** | Extracts `order_id`, `error_description` from `payload.payload.payment.entity`. Finds Payment by `gateway_order_id`. Calls `markFailed()` with reason. |
| **refund.processed** | Extracts `id` (refund_id) from `payload.payload.refund.entity`. Finds PaymentRefund by `gateway_refund_id`. Calls `RefundService@markRefundSuccess()`. |

#### PaytmGateway

| Aspect | Detail |
|--------|--------|
| **Signature Verification** | Extracts `CHECKSUMHASH` from decoded JSON. Recomputes HMAC-SHA256 over sorted params. |
| **Supported Events** | `TXN_SUCCESS`, `TXN_FAILURE`, `PENDING`, `REFUND_SUCCESS` |
| **handleWebhook** | Extracts `ORDERID` and `STATUS`. Finds Payment by `ulid`. `TXN_SUCCESS` → `markSuccess()`. `TXN_FAILURE` or `PENDING` → `markFailed()` with `RESPMSG`. |

#### PhonePeGateway

| Aspect | Detail |
|--------|--------|
| **Signature Verification** | X-VERIFY header: SHA256 of raw body + salt_key. Compared with `###`-delimited header value. |
| **Supported Events** | `PAYMENT_SUCCESS`, `PAYMENT_ERROR`, `PAYMENT_CANCELLED`, `TIMED_OUT` |
| **handleWebhook** | Extracts `data.merchantTransactionId` and `code`. Finds Payment by `ulid`. `PAYMENT_SUCCESS` → `markSuccess()`. `PAYMENT_ERROR`, `PAYMENT_CANCELLED`, `TIMED_OUT` → `markFailed()` with code. |

#### BillDeskGateway

| Aspect | Detail |
|--------|--------|
| **Signature Verification** | Extracts `BD_RESPONSE` (pipe-separated). Pops last segment as checksum. Recomputes HMAC-SHA256 over base + checksum_key. |
| **Supported Events** | `0300` (success), `0002` (failed), `0001` (pending) |
| **handleWebhook** | Parses pipe-separated `BD_RESPONSE`. Field 1 = order_id (ULID), Field 14 = status. `0300` → `markSuccess()`. `0002` or `0001` → `markFailed()`. |

#### CCAvenueGateway

| Aspect | Detail |
|--------|--------|
| **Signature Verification** | Always returns `true` (no async webhooks — redirect-only) |
| **handleWebhook** | No-op (redirect-only gateway) |

#### OfflineGateway

| Aspect | Detail |
|--------|--------|
| **Signature Verification** | Always returns `true` (no webhooks) |
| **handleWebhook** | No-op |

---

## 8. Event / Listener Chain

### Webhook Events

| Event | Dispatched By | Payload | Listener |
|-------|---------------|---------|----------|
| `WebhookReceived` | `ProcessWebhookJob@handle` (after success) | `{webhook}` | `WebhookReceivedListener` — logs audit `webhook.received` with webhook_id, gateway, event_type, processed |

### Downstream Payment Events (triggered by driver->handleWebhook)

When `driver->handleWebhook()` calls `PaymentService@markSuccess()` or `markFailed()`, the standard payment lifecycle events are dispatched:

| Gateway Event | Payment Event Triggered |
|---------------|------------------------|
| Razorpay `payment.captured` | `PaymentSucceeded` |
| Razorpay `payment.failed` | `PaymentFailed` |
| Razorpay `refund.processed` | `RefundSucceeded` (via RefundService) |
| Paytm `TXN_SUCCESS` | `PaymentSucceeded` |
| Paytm `TXN_FAILURE` | `PaymentFailed` |
| PhonePe `PAYMENT_SUCCESS` | `PaymentSucceeded` |
| PhonePe `PAYMENT_ERROR` | `PaymentFailed` |
| BillDesk `0300` | `PaymentSucceeded` |
| BillDesk `0002` | `PaymentFailed` |

---

## 9. Audit Trail

### Audit Events for Webhooks

| Event | Actor Type | Payload |
|-------|------------|---------|
| `webhook.{gatewayEvent}.received` (via `AuditService@logWebhook`) | `webhook` | `webhook_id`, `gateway`, `event_type`, `processed` |

The webhook payload itself is stored in the `ptm_payment_webhooks.payload` JSON column for full traceability.

---

## 10. Security & Authorization

### Webhook Security Model

| Layer | Mechanism |
|-------|-----------|
| **Signature Verification** | `VerifyWebhookSignature` middleware — reads raw body, delegates to `$driver->verifyWebhookSignature($rawBody, $headers)` |
| **Gateway Route Parameter** | Must match an active gateway code, otherwise `GatewayManager@resolve` throws |
| **Idempotency** | UNIQUE constraint on `idempotency_key` column prevents duplicate processing |
| **No Auth Middleware** | Deliberately excluded — gateway servers cannot authenticate with Sanctum tokens |

### VerifyWebhookSignature Middleware

| Check | Failure Response |
|-------|-----------------|
| Missing `{gateway}` route parameter | `HTTP 400` — `{error: 'Missing gateway'}` |
| Empty request body | `HTTP 400` — `{error: 'Empty body'}` |
| Invalid JSON body | `HTTP 400` — `{error: 'Invalid JSON'}` |
| Signature verification fails | `HTTP 401` — `{error: 'Invalid signature'}` |
| Gateway driver error | `HTTP 500` — `{error: 'Gateway error'}` |

### Backend Authorization

| Action | Permission | Controller |
|--------|-----------|------------|
| List webhooks | `tenant.payment.reconciliation.viewAny` | `Backend\WebhookController@index` |

Note: The webhook list uses `tenant.payment.reconciliation.viewAny` permission, not `tenant.payment.viewAny`.

### Idempotency Key Extraction

| Gateway | Extraction Logic | Fallback |
|---------|-----------------|----------|
| Razorpay | `payload.payload.payment.entity.id` or `X-Razorpay-Event-Id` header | `{gateway}_{uniqid}` |
| PhonePe | `payload.data.merchantTransactionId` | `{gateway}_{uniqid}` |
| Paytm | `payload.ORDERID` | `{gateway}_{uniqid}` |
| BillDesk | Parse `BD_RESPONSE` pipe-separated, field 1 | `{gateway}_{uniqid}` |
| Default | `null` | `{gateway}_{uniqid}` |

---

## 11. Error Handling

### Error Scenarios

| Scenario | HTTP Code | Response / Behavior |
|----------|-----------|---------------------|
| Missing gateway route param | 400 | `{error: 'Missing gateway'}` |
| Empty request body | 400 | `{error: 'Empty body'}` |
| Invalid JSON body | 400 | `{error: 'Invalid JSON'}` |
| Invalid webhook signature | 401 | `{error: 'Invalid signature'}` |
| Gateway driver error (resolve/instantiate) | 500 | `{error: 'Gateway error'}` |
| Gateway not found or inactive | 500 | `"Payment gateway [{code}] not found or inactive."` |
| HandleWebhook throws (during job) | — | Job retries (up to 3 times, 30s backoff). On permanent failure: `processed=false`, `error_message` set. |
| Duplicate idempotency_key | 200 (but DB UNIQUE violation logged) | Webhook record creation fails silently — gateway retries will receive 200 but no new record created. Note: This is a potential area for improvement — should detect and return 200 gracefully. |

### ProcessWebhookJob Failure Logging

```
// On job failure:
Log::error("ProcessWebhookJob failed for webhook [{id}] gateway [{gateway}]: {message}");

// On permanent failure:
Log::error("ProcessWebhookJob permanently failed for webhook [{id}]: {message}");
```

---

## 12. Backend UI Pages

### Backend\WebhookController@index

| Attribute | Value |
|-----------|-------|
| Route | `GET /admin/payment/webhooks` |
| View | `payment::webhooks.index` |
| Data | `PaymentWebhook::with('payment')->latest()->paginate(20)` |
| Auth | `Gate::authorize('tenant.payment.reconciliation.viewAny')` |
| Columns displayed | gateway, event_type, signature_valid (bool), processed (bool), payment relation |

---

## 13. Database Schema

### ptm_payment_webhooks

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `id` | INT UNSIGNED | PK, AUTO_INCREMENT | |
| `payment_id` | INT UNSIGNED | NULL, FK → ptm_payment_payments.id ON DELETE SET NULL | Linked payment (may be null if not resolved yet) |
| `gateway` | VARCHAR(255) | NOT NULL, INDEXED | Gateway code (e.g., 'razorpay') |
| `event_type` | VARCHAR(255) | NOT NULL, INDEXED | e.g., 'payment.captured', 'TXN_SUCCESS' |
| `idempotency_key` | VARCHAR(255) | UNIQUE, NOT NULL | Prevents duplicate processing |
| `payload` | JSON | NOT NULL | Full gateway payload |
| `signature_valid` | TINYINT(1) | DEFAULT 0 | Always set to 1 (already verified by middleware) |
| `processed` | TINYINT(1) | DEFAULT 0, INDEXED | Set to 1 by ProcessWebhookJob on success |
| `error_message` | TEXT | NULL | Set on job failure |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | INT UNSIGNED | NULL | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | Soft delete |

**Indexes:** idempotency_key (UNIQUE), payment_id, gateway, processed, event_type

---

## 14. Dependencies

### Module Dependencies

| Dependency | Type | Details |
|------------|------|---------|
| Payment module core | Internal | Payment model, PaymentService, RefundService, GatewayManager |
| Laravel Queue | Framework | Required for ProcessWebhookJob async execution |
| Log facade | Framework | Error logging |

### External Service Dependencies

| Gateway | Dependency |
|---------|-----------|
| Razorpay | None (webhook verification uses HMAC, no external API call) |
| Paytm | None (HMAC signature verification) |
| PhonePe | None (SHA256 signature verification) |
| BillDesk | None (HMAC signature verification) |
| CCAvenue | Not applicable (no webhooks) |

**Note:** Unlike the payment initiation flow, webhook processing does NOT make outbound API calls to gateways. Signature verification is done purely with cryptographic primitives (HMAC, SHA256) using pre-shared secrets.

---

## 15. Configuration

### Middleware Registration

The middleware alias `payment.webhook.verify` maps to `VerifyWebhookSignature` class. This must be registered in the Laravel kernel/alley:

```php
// In module's middleware registration or RouteServiceProvider
'payment.webhook.verify' => \Modules\Payment\Http\Middleware\VerifyWebhookSignature::class
```

### Gateway Credentials for Webhook Verification

| Gateway | Credential Used | Description |
|---------|----------------|-------------|
| Razorpay | `webhook_secret` | HMAC secret for signature verification |
| Paytm | `merchant_key` | Used for CHECKSUMHASH verification |
| PhonePe | `salt_key` | Used for X-VERIFY header verification |
| BillDesk | `checksum_key` | Used for HMAC signature verification |

### Queue Configuration

ProcessWebhookJob uses the default Laravel queue connection. Ensure queue worker is running for async processing.

---

## 16. Testing Considerations

### Test Coverage Areas

| Area | Scenarios |
|------|-----------|
| **Signature Verification** | Valid signature → passes; invalid signature → 401; missing signature headers → 401; empty body → 400; missing gateway param → 400; invalid JSON → 400 |
| **Idempotency** | Duplicate idempotency key → UNIQUE violation handled; same payload sent twice → only first creates webhook record |
| **Webhook Storage** | Webhook record created with correct gateway, event_type, payload, signature_valid=true, processed=false |
| **Queue Dispatching** | ProcessWebhookJob dispatched after successful storage |
| **Job Processing** | Driver handleWebhook called with correct payload; processed set to true on success; error_message set on failure |
| **Job Retry** | Failed job retries 3 times with 30s backoff; `failed()` method sets permanent failure message |
| **Per-Gateway Webhook** | Razorpay payment.captured flow; Razorpay payment.failed flow; Razorpay refund.processed flow; Paytm TXN_SUCCESS/TXN_FAILURE; PhonePe PAYMENT_SUCCESS/ERROR/CANCELLED/TIMED_OUT; BillDesk 0300/0002/0001; CCAvenue no-op; Offline no-op |
| **Event Dispatching** | WebhookReceived dispatched after successful processing; WebhookReceivedListener logs audit |
| **Backend UI** | List webhooks paginated; authorized with `tenant.payment.reconciliation.viewAny` |

### Negative / Edge Cases

- Gateway returns unexpected event type → match default null (no-op for Razorpay, ignored)
- Payment not found by gateway_order_id → handleWebhook silently returns (no error thrown)
- PaymentRefund not found by gateway_refund_id → handleWebhook silently returns
- Webhook received for inactive/deleted gateway → GatewayManager throws, middleware returns 500
- Massively large payload → stored in JSON column (check MySQL max_allowed_packet)
- Concurrent webhooks for same idempotency_key → UNIQUE constraint prevents second insert
- Queue worker down → webhook stored but not processed; queue retries when worker comes up
- Job throws non-retryable exception → still retries (no `failed()` type discrimination currently)

### Integration Test Requirements

- Queue driver must be `sync` for testing (or use `Queue::fake()`)
- Mock `GatewayManager@resolve` to return fake driver
- Tenant database context must be set for webhook storage
- Test raw body signature computation matches gateway implementations

---

## Change Log

| V1/V2 | Status | CR | Date | Description |
|-------|--------|----|------|-------------|
| — | ⬜ | ◌ | 2026-07-23 | Initial requirement document generated from code analysis |
