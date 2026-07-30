# Refund Management — Feature Requirement

| Attribute | Value |
|-----------|-------|
| **Module** | Payment |
| **Feature ID** | F5 |
| **Prefix** | `ppt_` |
| **Type** | Infrastructure / Service |
| **Source** | Code analysis + DDL (no FRD) |
| **Version** | V1 — |
| **Status** | ⬜ Not Reviewed |
| **CR** | ◌ None |

---

## 1. Module Overview

Refund Management provides the ability to initiate, track, and finalize refunds against successful payments. It is a **cross-cutting service** used by any payable entity (FeeInvoice, MealCard, etc.) through the polymorphic `payable` relationship on `ptm_payment_payments`. The feature spans:

- **Mobile API** — Initiate a refund, list refunds for a payment (`/api/v1/payments/{ulid}/refund`)
- **Backend UI** — List all refunds across the tenant (`/refunds`)
- **Gateway Integration** — Dispatches refund requests to configured gateways (Razorpay, Offline, PhonePe, CCAvenue, BillDesk, Paytm)
- **Webhook Processing** — Handles asynchronous gateway refund confirmations (e.g., Razorpay `refund.processed`)
- **Event-Driven Side Effects** — Updates FeeInvoice ledger on successful refund via `RefundSucceededListener`

---

## 2. Feature Summary

| Capability | Description |
|---|---|
| Initiate Refund | Create a refund request against a successful payment via API |
| Gateway Refund API | Call the payment gateway's refund endpoint (synchronous for offline, async for online gateways) |
| Partial Refund | Refund any amount ≤ (payment amount − already refunded) |
| Full Refund | When total refunded ≥ payment amount, payment status changes to `refunded` |
| Refund Tracking | Full lifecycle status: `pending` → `processing` → `success` / `failed` |
| Webhook-Driven Status | Online gateways confirm refund via webhook; marks refund `success` |
| Audit Trail | Each refund event logged to `ptm_payment_audit_logs` |
| Fee Ledger Update | On refund success, `RefundSucceededListener` bridges to StudentFee module |
| Concurrency Protection | `lockForUpdate` prevents double-spend / concurrent refunds |
| Gateway Refund Idempotency | Unique constraint on `gateway_refund_id` prevents duplicate processing |

---

## 3. Technical Stack

| Layer | Technology | Details |
|---|---|---|
| Framework | Laravel 12 | Controller-Service pattern |
| API | REST JSON | Sanctum auth, mobile endpoints |
| Backend UI | Blade + AdminLTE | Paginated list view |
| Database | MySQL 8 | InnoDB with foreign keys |
| Concurrency | `lockForUpdate` | Pessimistic lock on Payment row |
| Events | Laravel Event/Listener | 3 events, 3 listeners |
| Authorization | Gates + Policies | `tenant.payment.refund` permission |
| Gateways | Driver pattern | 6 gateway implementations |

---

## 4. Architecture & Flow

### 4.1 Initiate Refund Flow

```
Mobile App                         Backend                          Gateway
    │                                │                                │
    │  POST /api/v1/payments/{ulid}/refund                            │
    │  { amount, reason }                                             │
    │                                │                                │
    ├──────► InitiateRefundRequest ──┤                                │
    │         validates amount, reason                                │
    │         gate: tenant.payment.refund                             │
    │                                │                                │
    │         RefundController@store                                  │
    │           ├─ paymentService->getByUlid(ulid)                    │
    │           ├─ authorize('refund', payment)                       │
    │           └─ refundService->initiate(payment, amount, reason)   │
    │                                │                                │
    │                ┌─ Check: status === 'success'                   │
    │                ├─ lockForUpdate() on Payment                    │
    │                ├─ Compute maxRefundable                         │
    │                ├─ Validate amount <= maxRefundable              │
    │                ├─ Create PaymentRefund (status=pending)         │
    │                ├─ GatewayManager->resolve(gateway.code)         │
    │                ├─ driver->refund(payment, amount)  ──────►      │
    │                │        [Synchronous gateway API call]          │
    │                │                                    │           │
    │                │        ◄──── return {gateway_refund_id,        │
    │                │                 status, raw}                   │
    │                ├─ Update refund: status=processing              │
    │                │   gateway_refund_id, metadata                  │
    │                ├─ Audit log: 'refund.initiated'                 │
    │                └─ Dispatch RefundInitiated                      │
    │                                │                                │
    │  ◄── 201 { refund: {ulid, amount, status, reason} }            │
    │                                │                                │
```

### 4.2 Webhook-Driven Refund Confirmation Flow (Razorpay)

```
Razorpay                             Backend
    │                                  │
    │  POST /payment/webhooks/razorpay │
    │  { event: "refund.processed" }   │
    ├──────► VerifyWebhookSignature    │
    │         (HMAC-SHA256)            │
    │         WebhookController@handle │
    │           ├─ store raw webhook   │
    │           └─ dispatch job        │
    │                                  │
    │         RazorpayGateway@handleRefundProcessed                   
    │           ├─ gateway_refund_id from payload                    
    │           ├─ PaymentRefund::where('gateway_refund_id', $id)    
    │           └─ refundService->markRefundSuccess(refund)          
    │                                  │
    │              ├─ Update: status=success, refunded_at=now        
    │              ├─ Calculate total refunded                       
    │              ├─ If >= amount: Payment.status = 'refunded'      
    │              ├─ Audit log: 'refund.succeeded'                  
    │              └─ Dispatch RefundSucceeded                       
    │                                  │
    │         RefundSucceededListener  │
    │           ├─ FeeInvoice check    │
    │           ├─ FeeInvoiceService::recordRefund()                 
    │           └─ FeeTransaction::markRefunded()                    
    │                                  │
```

### 4.3 Offline Refund Flow

```
Backend User                         Backend
    │                                  │
    │  POST /api/v1/payments/{ulid}/refund                           
    │  { amount, reason }                                             
    │                                  │
    ├──────► (same validation & service flow as above)               
    │                                  │
    │         OfflineGateway@refund()  │
    │           └─ Returns synthetic: │
    │              gateway_refund_id = "OFFLINE-REFUND-XXXXXXXX"     
    │              status = "success"  │
    │              raw = { manual refund note }                      
    │                                  │
    │         (No webhook — synchronous success)                     
    │         markRefundSuccess called? NO — status stays 'processing'
    │                                  │
```

> ⚠️ **Observation:** For OfflineGateway, the `refund()` method returns `status=success` but the `RefundService@initiate()` does **not** call `markRefundSuccess()` — it only updates status to `processing`. For offline refunds, there is no webhook to confirm, so refunds initiated via offline gateway **remain in `processing` status indefinitely**. This is a gap — offline gateway refunds should be auto-marked as success in the service.

---

## 5. Data Model

### 5.1 `ptm_payment_refunds`

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | INT UNSIGNED | PK, AUTO_INCREMENT | |
| `ulid` | CHAR(26) | UNIQUE, NOT NULL | ULID for public reference |
| `payment_id` | INT UNSIGNED | FK → ptm_payment_payments(id) ON DELETE CASCADE | |
| `amount` | DECIMAL(12,2) | NOT NULL | Refund amount |
| `reason` | TEXT | NULLABLE | Human-readable reason |
| `status` | VARCHAR(255) | NOT NULL, DEFAULT 'pending' | pending → processing → success/failed |
| `gateway_refund_id` | VARCHAR(255) | UNIQUE, NULLABLE | Gateway refund reference; unique prevents duplicate processing |
| `metadata` | JSON | NULLABLE | Raw gateway response |
| `initiated_by` | INT UNSIGNED | FK → sys_users(id) ON DELETE SET NULL | Who initiated |
| `created_by` | INT UNSIGNED | NULLABLE | |
| `refunded_at` | TIMESTAMP | NULLABLE | When refund was confirmed |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 | Soft-enable flag |
| `created_at` | TIMESTAMP | NULLABLE | |
| `updated_at` | TIMESTAMP | NULLABLE | |
| `deleted_at` | TIMESTAMP | NULLABLE | Soft delete |

**Indexes:**
- UNIQUE: `ulid`, `gateway_refund_id`
- INDEX: `status`, `payment_id`

**Model Casts:** `amount` → float, `metadata` → array, `refunded_at` → datetime, `is_active` → boolean

### 5.2 `ptm_payment_payments` — Relevant Status Values

| Constant | Value | Description |
|---|---|---|
| `STATUS_INITIATED` | `initiated` | Payment created, awaiting user action |
| `STATUS_PENDING` | `pending` | Payment in-flight |
| `STATUS_SUCCESS` | `success` | Payment captured (refundable state) |
| `STATUS_FAILED` | `failed` | Payment failed |
| `STATUS_CANCELLED` | `cancelled` | Payment cancelled by user |
| `STATUS_REFUNDED` | `refunded` | Fully refunded |

---

## 6. API Contracts

### 6.1 Initiate Refund

```
POST /api/v1/payments/{ulid}/refund
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**

| Field | Type | Required | Rules |
|---|---|---|---|
| `amount` | float | Yes | `required`, `numeric`, `min:0.01` |
| `reason` | string | Yes | `required`, `string`, `max:500` |

**Success Response (201):**
```json
{
    "refund": {
        "ulid": "01JARQ...",
        "amount": 500.00,
        "status": "pending",
        "reason": "Student withdrawn from course"
    }
}
```

**Error Responses:**
- **400** — Validation errors (amount format, reason too long)
- **403** — Missing `tenant.payment.refund` permission
- **404** — Payment not found (by ULID)
- **409** — Payment not in refundable state (`Cannot refund payment in status: {status}`)
- **409** — Amount exceeds refundable (`Refund amount ({X}) exceeds max refundable amount ({Y})`)
- **500** — Gateway driver resolution failure or gateway API error

### 6.2 List Refunds for a Payment

```
GET /api/v1/payments/{ulid}/refunds
Authorization: Bearer <token>
```

**Success Response (200):**
```json
[
    {
        "id": 1,
        "ulid": "01JARQ...",
        "amount": 500.00,
        "reason": "Student withdrawn",
        "status": "success",
        "gateway_refund_id": "rfnd_...",
        "refunded_at": "2026-07-22T10:30:00Z",
        "created_at": "2026-07-22T10:00:00Z"
    }
]
```

**Error Responses:**
- **403** — Missing permission
- **404** — Payment not found

---

## 7. Business Logic / Services

### 7.1 `RefundService@initiate(Payment, float $amount, string $reason, ?int $userId)`

| Step | Logic | Exception | Message |
|---|---|---|---|
| 1 | Validate payment status === `success` | `RuntimeException` | `"Cannot refund payment in status: {status}"` |
| 2 | DB transaction + `lockForUpdate` on Payment | — | Prevents concurrent refunds |
| 3 | Compute `$refundedSoFar = SUM(amount)` WHERE payment_id AND status=success | — | |
| 4 | Compute `$maxRefundable = payment.amount - refundedSoFar` | — | |
| 5 | Validate `$amount <= $maxRefundable` | `InvalidArgumentException` | `"Refund amount ({X}) exceeds max refundable amount ({Y})"` |
| 6 | Create `PaymentRefund` (status=pending, is_active=true) | — | |
| 7 | Resolve gateway driver via `GatewayManager->resolve(gateway.code)` | `Exception` | `"Payment gateway [{code}] not found or inactive."` / `"Gateway driver [{driver}] does not exist."` |
| 8 | Call `driver->refund(payment, amount)` | — | Gateway-specific API call |
| 9 | Update refund: gateway_refund_id, status=processing, metadata=raw | — | |
| 10 | Audit log: `refund.initiated` with actorType='system' | — | |
| 11 | Dispatch `RefundInitiated` event | — | |

### 7.2 `RefundService@markRefundSuccess(PaymentRefund, array $payload)`

| Step | Logic |
|---|---|
| 1 | Update refund: status=success, refunded_at=now |
| 2 | Calculate total refunded for payment (SUM where status=success) |
| 3 | If total refunded >= payment.amount: update payment status=refunded |
| 4 | Audit log: `refund.succeeded` with actorType='gateway' |
| 5 | Dispatch `RefundSucceeded` event |

### 7.3 `RefundService@markRefundFailed(PaymentRefund, string $reason, array $payload)`

| Step | Logic |
|---|---|
| 1 | Update refund: status=failed |
| 2 | Audit log: `refund.failed` with actorType='gateway' |
| 3 | Dispatch `RefundFailed` event with reason |

### 7.4 `RefundService@getRefundsForPayment(Payment)`

Returns all refunds for a payment, ordered by latest first.

---

## 8. Events & Listeners

| Event | Dispatched By | Listener | Action |
|---|---|---|---|
| `RefundInitiated` | `RefundService@initiate` | `RefundInitiatedListener` | Logs audit event `refund.initiated.event` with refund details |
| `RefundSucceeded` | `RefundService@markRefundSuccess` | `RefundSucceededListener` | If payable is FeeInvoice: finds FeeTransaction by gateway_payment_id, calls `FeeInvoiceService@recordRefund()`, calls `FeeTransaction@markRefunded()`, logs `refund.ledger_updated` |
| `RefundFailed` | `RefundService@markRefundFailed` | `RefundFailedListener` | Logs audit event `refund.failed` with reason |

Each event carries `public readonly PaymentRefund $refund`. `RefundFailed` additionally carries a `public readonly string $reason`.

---

## 9. Authorization

| Context | Mechanism | Gate / Permission | Class |
|---|---|---|---|
| Initiate Refund (API) | `InitiateRefundRequest@authorize` | `tenant.payment.refund` | Form Request |
| Initiate Refund (API) | `PaymentPolicy@refund` | `tenant.payment.refund` | Policy on Payment |
| List Refunds for Payment (API) | `PaymentPolicy@refund` | `tenant.payment.refund` | Policy on Payment |
| List All Refunds (Backend) | `$this->authorize('viewAny', PaymentRefund::class)` | Falls through to default Gate | Backend Controller |

> ⚠️ **Gap:** No explicit policy is registered for `PaymentRefund` model in `PaymentServiceProvider`. The backend list authorization for `viewAny` on `PaymentRefund` depends on a fallback gate that may not exist, potentially causing 403 errors or silently granting access.

---

## 10. Validation Rules

| Source | Field | Rules |
|---|---|---|
| `InitiateRefundRequest` | `amount` | `required`, `numeric`, `min:0.01` |
| `InitiateRefundRequest` | `reason` | `required`, `string`, `max:500` |
| `RefundService@initiate` | payment.status | Must equal `Payment::STATUS_SUCCESS` |
| `RefundService@initiate` | amount ≤ maxRefundable | `amount <= (payment.amount - SUM(successful refunds))` |
| Route parameter | `ulid` | Matched by `PaymentService@getByUlid` (char(26)) |

---

## 11. Error Handling

| Scenario | Exception Type | HTTP Code | Message |
|---|---|---|---|
| Payment not in `success` status | `RuntimeException` | 409 | `Cannot refund payment in status: {status}` |
| Amount exceeds refundable | `InvalidArgumentException` | 409 | `Refund amount ({X}) exceeds max refundable amount ({Y})` |
| Gateway not found/inactive | `Exception` | 500 | `Payment gateway [{code}] not found or inactive.` |
| Gateway driver missing | `Exception` | 500 | `Gateway driver [{driver}] does not exist.` |
| Gateway API call fails | Gateway-specific | 502 | Propagated from gateway SDK |
| Concurrent refund (lock conflict) | `QueryException` | 409 | Deadlock or lock wait timeout |
| Duplicate gateway refund ID | `QueryException` | 409 | Unique constraint on `gateway_refund_id` |

---

## 12. State Machine

### 12.1 Refund Status

```
                    ┌──────────┐
                    │  pending │
                    └────┬─────┘
                         │
                    ┌────▼──────┐
                    │ processing│
                    └────┬──────┘
                    ┌────┴─────┐
                    │          │
               ┌────▼───┐  ┌──▼────┐
               │ success │  │ failed│
               └─────────┘  └───────┘
```

- **pending** — Refund record created, no gateway call yet
- **processing** — Gateway refund API called, refund ID obtained, awaiting webhook confirmation
- **success** — Gateway confirmed refund (via webhook)
- **failed** — Gateway rejected refund or error occurred

### 12.2 Payment Status (Refund-Related)

```
 success ──► refunded (when total refunded >= payment.amount)
```

---

## 13. Gateway Interface — `refund()` Contract

All gateways implement `PaymentGatewayInterface::refund()`:

```php
public function refund(Payment $payment, float $amount): array;
```

**Return contract:**
```php
array{
    gateway_refund_id: string|null,  // Gateway refund reference
    status: string,                   // Gateway's refund status
    raw: array                        // Full gateway response
}
```

| Gateway | `gateway_refund_id` | `status` | Notes |
|---|---|---|---|
| Razorpay | `rfnd_...` | From Razorpay API | Calls `payment.fetch(id)->refund()`, amount in paise |
| Offline | `OFFLINE-REFUND-XXXXXXXX` | `success` | Synthetic — no API call |
| PhonePe | Transaction ID from response | From response | |
| CCAvenue | `CCAREF-XXXXXXXX` | From response | |
| BillDesk | `BDREF-XXXXXXXX` | From response | |
| Paytm | From `refundId` in response | From response | |

---

## 14. Backend UI Routes

| Method | URI | Name | Controller |
|---|---|---|---|
| GET | `/refunds` | `payment.backend.refunds.index` | `Backend\RefundController@index` |

Backend list shows all refunds across the tenant with:
- Pagination: 20 per page
- Eager-loaded: `payment.gateway`
- Authorized via: `viewAny` on `PaymentRefund`
- View: `payment::refunds.index`

---

## 15. Security Considerations

| Concern | Mitigation |
|---|---|
| Concurrent refund race condition | `lockForUpdate` on Payment row within transaction |
| Duplicate gateway refund processing | UNIQUE constraint on `gateway_refund_id` |
| Unauthorized refund initiation | Gate permission `tenant.payment.refund` on both FormRequest and Policy |
| Webhook spoofing | `VerifyWebhookSignature` middleware delegates to `PaymentGatewayInterface@verifyWebhookSignature` |
| Refund amount manipulation | Server-side validation against computed `maxRefundable` in locked transaction |
| Idempotency (same refund initiated twice) | Each refund gets unique ULID; payment locked during processing |

---

## 16. Open Items / Gaps

| # | Issue | Severity | Description |
|---|---|---|---|
| 1 | **GAP-REF-001** | Medium | **Offline gateway refunds never complete**: `OfflineGateway@refund()` returns status=success but `RefundService@initiate()` always sets status=processing. No webhook confirms offline refunds. Offline refunds remain in `processing` indefinitely. Fix: detect offline gateway and auto-call `markRefundSuccess()` in the service. |
| 2 | **GAP-REF-002** | Low | **No PaymentRefund policy registered**: Backend `RefundController@index` authorizes `viewAny` on `PaymentRefund`, but no policy is registered for this model in `PaymentServiceProvider`. This may cause unexpected authorization behavior (fails open or 403). |
| 3 | **GAP-REF-003** | Low | **No validation for refund reason encoding**: Refund reason is stored as TEXT with max 500 chars. No sanitization for HTML, XSS, or injection content. |
| 4 | **GAP-REF-004** | Low | **No idempotency key on refund API**: Mobile app could retry the same refund request; if initial request succeeds but response is lost, retry creates a new refund. Mitigation: `lockForUpdate` prevents double-spend but does not detect retries. |
| 5 | **GAP-REF-005** | Low | **No partial refund status on payment**: Payment has `refunded` (fully) but no `partially_refunded` status. A payment with partial refunds still shows as `success`. |
| 6 | **GAP-REF-006** | Low | **No notification event on refund**: No email/SMS/push notification is triggered on refund success/failure. |
| 7 | **GAP-REF-007** | Info | **No cancellation endpoint for processing refunds**: If a refund is stuck in `processing` (e.g., gateway timeout), there is no API/UI to retry or cancel it. |

---

> **Document generated from source code analysis.**
> Source files: RefundController.php (API + Backend), RefundService.php, PaymentRefund.php, PaymentGatewayInterface.php, RazorpayGateway.php, OfflineGateway.php, InitiateRefundRequest.php, PaymentPolicy.php, Events (3), Listeners (3), EventServiceProvider.php, PaymentServiceProvider.php, routes/api.php, routes/web.php
