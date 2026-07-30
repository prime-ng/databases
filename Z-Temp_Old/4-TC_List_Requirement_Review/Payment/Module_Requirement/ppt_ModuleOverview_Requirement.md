# Payment Module — Module Overview Requirement

## 1. Module Identity

| Attribute | Value |
|-----------|-------|
| **Module Name** | Payment |
| **Module Prefix** | `ppt_` (shared with other Portal modules) |
| **Table Prefix** | `ptm_` (Payment Tables Module) |
| **Controller Namespace** | `Modules\Payment\Http\Controllers` |
| **Model Namespace** | `Modules\Payment\Models` |
| **Service Layer** | `Modules\Payment\Services` |
| **Module Alias** | `payment` |
| **Route Prefix (Web)** | `/payment` |
| **Route Prefix (API)** | `/api/v1/payments` |
| **Route Prefix (Webhook)** | `/payment/webhooks` |
| **View Namespace** | `payment::` |
| **Provider** | `Modules\Payment\Providers\PaymentServiceProvider` |
| **Event Provider** | `Modules\Payment\Providers\EventServiceProvider` |
| **Route Provider** | `Modules\Payment\Providers\RouteServiceProvider` |

## 2. Module Purpose

The Payment module is a **centralized payment orchestration layer** — not a user-facing UI module. It provides a pluggable gateway architecture where any module model that implements the `Payable` contract can initiate payments via configured gateways.

It owns the complete payment lifecycle (initiate → process → complete/cancel → refund → reconcile) across both online and offline payment methods, with an append-only audit trail, async webhook processing, and CSV-based settlement reconciliation.

## 3. Module Type

**Infrastructure / Service Layer Module**

This module does not have its own screens or tabs in the traditional sense. It is consumed by other modules (StudentFee, Vendor, Library, etc.) via:
- The `Payable` contract interface
- The REST API endpoints (`/api/v1/payments/*`)
- Event-driven listeners
- Backend admin views for payment management, gateway config, reconciliation, and reporting

## 4. Module Scope

### In-Scope

| Area | Description |
|------|-------------|
| **Gateway Configuration** | Manage payment gateway credentials, drivers, priorities, test/live mode per gateway |
| **Payment Lifecycle** | Initiate, complete, cancel payments via API; offline payment recording |
| **Webhook Processing** | Receive, verify (HMAC), store, queue, and process gateway webhooks |
| **Refund Management** | Initiate and track refunds via gateway API; partial refund support |
| **Payment Reconciliation** | Upload settlement CSV; auto-match against local payments; track discrepancies |
| **Audit & Reporting** | Append-only timeline of payment lifecycle events; PDF receipt generation |

### Out-of-Scope

| Area | Reason |
|------|--------|
| Fee structure definition | Handled by StudentFee module |
| Vendor invoice creation | Handled by Vendor module |
| Library fine assessment | Handled by Library module |
| Payment gateway UI checkout page | Handled by consuming module's frontend (mobile/web) |
| Student/parent account dashboard | Handled by ParentPortal / StudentPortal modules |

## 5. Tables Managed

### Core Payment Tables (ptm_ prefix)

| # | Table | Purpose |
|---|-------|---------|
| 1 | `ptm_payment_gateways` | Configured payment gateway drivers, credentials, priority, mode |
| 2 | `ptm_payment_payments` | Core payment records — polymorphic payable (any model) |
| 3 | `ptm_payment_refunds` | Refund records against a payment — supports partial refunds |
| 4 | `ptm_payment_offline_records` | Offline payment details (cash, cheque, DD, bank transfer, UPI) |
| 5 | `ptm_payment_audit_logs` | Append-only payment state change audit trail |
| 6 | `ptm_payment_webhooks` | Inbound gateway webhook events with idempotency keys |
| 7 | `ptm_payment_reconciliations` | Gateway settlement reconciliation summaries |
| 8 | `ptm_reconciliation_lines` | Individual settlement lines matched against payments |

### External Dependencies (non-ptm tables)

| Table | Module | Usage |
|-------|--------|-------|
| `sys_users` | System (auth) | Payment initiator, collector, auditor references |
| `vnd_payments` | Vendor | Vendor invoice payments tied via payable morph |
| `lib_fine_payments` | Library | Library fine payment records tied via payable morph |
| `fee_payment_gateway_logs` | StudentFee | Raw gateway request/response logs for fee transactions |
| `fee_payment_reconciliation` | StudentFee | Cheque/DD lifecycle tracking for fee payments |

## 6. Architecture & Key Design Decisions

### 6.1 Plugin-Style Gateway Architecture

```
Payable (interface)
    ▲
    │ implements
    │
FeeInvoice ──┐
MealCard  ───┤  →  PaymentService::initiate()  →  GatewayManager::resolve(code)
LibFine   ───┘                                          │
                                                        ▼
                                            ┌─────────────────────┐
                                            │  PaymentGateway     │
                                            │  (ptm_payment_gateways) │
                                            │  code, driver, creds │
                                            └────────┬────────────┘
                                                     │ resolves class
                                                     ▼
                                    ┌────────────────────────────────┐
                                    │  PaymentGatewayInterface       │
                                    │  ├─ initiate()                 │
                                    │  ├─ verify()                   │
                                    │  ├─ handleWebhook()            │
                                    │  ├─ refund()                   │
                                    │  └─ verifyWebhookSignature()   │
                                    └────────┬───────────────────────┘
                                             │ implemented by
                    ┌───────────┬──────────────┼──────────────┬──────────────┐
                    ▼           ▼              ▼              ▼              ▼
            RazorpayGateway  PhonePeGateway  PaytmGateway  CCAvenueGateway  BillDeskGateway
                                                                             OfflineGateway
```

### 6.2 Polymorphic Payable Contract

Any model (FeeInvoice, MealCard, LibFine, VndInvoice) implements:

```php
interface Payable {
    getPayableLabel(): string;       // "Fee Invoice #INV-2026-001"
    getPayableAmount(): float;       // Amount due
    getPayableCustomer(): array;     // [name, email, phone, student_id]
    getPayableMetadata(): array;     // Module-specific data for receipts
}
```

### 6.3 Event-Driven Lifecycle

```
Payment Initiated  →  dispatch PaymentInitiated   →  PaymentInitiatedListener
Payment Succeeded  →  dispatch PaymentSucceeded   →  PaymentSucceededListener
Payment Failed     →  dispatch PaymentFailed       →  PaymentFailedListener
Payment Cancelled  →  dispatch PaymentCancelled    →  PaymentCancelledListener
Refund Initiated   →  dispatch RefundInitiated     →  RefundInitiatedListener
Refund Succeeded   →  dispatch RefundSucceeded     →  RefundSucceededListener
Refund Failed      →  dispatch RefundFailed         →  RefundFailedListener
Webhook Received   →  dispatch WebhookReceived     →  WebhookReceivedListener
```

All 8 events + 8 listeners are registered in `EventServiceProvider`.

### 6.4 Webhook Processing Pipeline

```
Gateway POST → webhooks.php (no auth) → VerifyWebhookSignature Middleware
    │ 1. Read raw body
    │ 2. Resolve gateway driver via GatewayManager
    │ 3. driver->verifyWebhookSignature(rawBody, headers)
    │ 4. If invalid → return 401
    │ 5. JSON decode → set request attributes
    ▼
WebhookController::handle()
    │ 1. Extract idempotency_key (gateway-specific)
    │ 2. UNIQUE constraint on idempotency_key prevents duplicates
    │ 3. Store PaymentWebhook record
    │ 4. Dispatch ProcessWebhookJob (queued)
    │ 5. Return 200 immediately
    ▼
ProcessWebhookJob (queue, tries=3, backoff=30s)
    │ 1. driver->handleWebhook(payload)
    │ 2. Update webhook as processed
    │ 3. Dispatch WebhookReceived event
    │ 4. On failure → retry or mark permanently failed
```

### 6.5 Append-Only Audit Trail

`ptm_payment_audit_logs` is immutable:
- No `SoftDeletes` trait
- No `updated_at` column
- Only inserts via `AuditService::log()` / `logStatusChange()` / `logWebhook()`
- Captures: payment_id, event, from_status, to_status, actor_type, actor_id, payload (JSON), ip_address, user_agent

## 7. Available Gateway Drivers

| Driver | Class | Type | Webhook Events |
|--------|-------|------|----------------|
| Razorpay | `RazorpayGateway` | Online | payment.captured, payment.failed, refund.processed |
| PhonePe | `PhonePeGateway` | Online | PAYMENT_SUCCESS, PAYMENT_ERROR, PAYMENT_CANCELLED, TIMED_OUT |
| Paytm | `PaytmGateway` | Online | (TBD per Paytm API) |
| CCAvenue | `CCAvenueGateway` | Online | (TBD per CCAvenue API) |
| BillDesk | `BillDeskGateway` | Online | (TBD per BillDesk API) |
| Offline | `OfflineGateway` | Offline | None — human-verified |

### Offline Payment Methods

| Method | Constant | Description |
|--------|----------|-------------|
| Cash | `OfflinePaymentRecord::METHOD_CASH` | Physical cash collection |
| Cheque | `OfflinePaymentRecord::METHOD_CHEQUE` | Cheque with reference number, tracks bounce |
| Demand Draft | `OfflinePaymentRecord::METHOD_DEMAND_DRAFT` | Bank draft collection |
| Bank Transfer | `OfflinePaymentRecord::METHOD_BANK_TRANSFER` | Direct NEFT/RTGS/IMPS |
| Manual UPI | `OfflinePaymentRecord::METHOD_UPI_MANUAL` | UPI payment outside gateway |

## 8. Permissions (Gates & Policies)

### Permissions Defined

| Permission | Policy Method | Controller Action |
|------------|--------------|-------------------|
| `tenant.payment.gateway.viewAny` | `PaymentGatewayPolicy::viewAny()` | index, show |
| `tenant.payment.gateway.create` | `PaymentGatewayPolicy::create()` | create, store |
| `tenant.payment.gateway.update` | `PaymentGatewayPolicy::update()` | edit, update, toggleStatus |
| `tenant.payment.gateway.delete` | `PaymentGatewayPolicy::delete()` | destroy |
| `tenant.payment.gateway.restore` | `PaymentGatewayPolicy::restore()` | trashedPaymentGateways, restore |
| `tenant.payment.gateway.forceDelete` | `PaymentGatewayPolicy::forceDelete()` | forceDelete |
| `tenant.payment.viewAny` | `PaymentPolicy::viewAny()` | Backend payment list |
| `tenant.payment.view` | `PaymentPolicy::view()` | Payment detail view |
| `tenant.payment.create` | `PaymentPolicy::create()` | API initiate |
| `tenant.payment.update` | `PaymentPolicy::update()` | — |
| `tenant.payment.delete` | `PaymentPolicy::delete()` | — |
| `tenant.payment.refund` | `PaymentPolicy::refund()` | API refund store |
| `tenant.payment.cancel` | `PaymentPolicy::cancel()` | API cancel |
| `tenant.payment.reconciliation.viewAny` | Gate (explicit) | Reconciliation index |
| `tenant.payment.reconciliation.view` | Gate (explicit) | Reconciliation show |
| `tenant.payment.reconciliation.create` | Gate (explicit) | Reconciliation store |
| `tenant.payment.reconciliation.resolve` | Gate (explicit) | Reconciliation resolve |

### Policy Registration

Both `PaymentPolicy` and `PaymentGatewayPolicy` are registered in `PaymentServiceProvider::registerPolicies()` via `Gate::policy()`. Reconciliation abilities use explicit `Gate::define()`.

## 9. Services (Business Logic Layer)

| Service | Responsibility |
|---------|----------------|
| `PaymentService` | initiate(), markSuccess(), markFailed(), cancel(), getByUlid() |
| `GatewayManager` | resolve(code) — instantiates gateway driver with credentials |
| `RefundService` | initiate(), markRefundSuccess(), markRefundFailed(), getRefundsForPayment() |
| `AuditService` | log(), logStatusChange(), logWebhook(), getTimeline() |
| `PaymentReconciliationService` | reconcile(), parseCsv(), matchPayment() |
| `PaymentData` (DTO) | Immutable data transfer object for gateway initiate() |

All services (except DTO) are registered as singletons in the service container.

## 10. Payment Statuses

| Status | Constant | Description |
|--------|----------|-------------|
| `initiated` | `Payment::STATUS_INITIATED` | Record created, awaiting gateway |
| `pending` | `Payment::STATUS_PENDING` | Gateway order created, awaiting completion |
| `success` | `Payment::STATUS_SUCCESS` | Payment completed successfully |
| `failed` | `Payment::STATUS_FAILED` | Payment failed |
| `cancelled` | `Payment::STATUS_CANCELLED` | User-cancelled before gateway processed |
| `refunded` | `Payment::STATUS_REFUNDED` | Fully refunded (auto-set when sum refunds >= amount) |

### Refund Statuses

| Status | Constant | Description |
|--------|----------|-------------|
| `pending` | `PaymentRefund::STATUS_PENDING` | Created, awaiting gateway API call |
| `processing` | `PaymentRefund::STATUS_PROCESSING` | Gateway API called, awaiting confirmation |
| `success` | `PaymentRefund::STATUS_SUCCESS` | Refund confirmed |
| `failed` | `PaymentRefund::STATUS_FAILED` | Refund failed |

### Reconciliation Statuses

| Status | Constant | Description |
|--------|----------|-------------|
| `pending` | `PaymentReconciliation::STATUS_PENDING` | Created during CSV processing |
| `matched` | `PaymentReconciliation::STATUS_MATCHED` | All lines matched successfully |
| `discrepant` | `PaymentReconciliation::STATUS_DISCREPANT` | Some lines unmatched or amount mismatch |
| `resolved` | `PaymentReconciliation::STATUS_RESOLVED` | Marked as resolved by admin |

## 11. Validation Rules

### PaymentGatewayRequest (Create/Update)

| Field | Rules | Notes |
|-------|-------|-------|
| `name` | required, string, max:100 | Human-readable gateway name |
| `code` | required, string, max:50, unique:ptm_payment_gateways,code | Unique identifier, immutable |
| `type` | required, in:online,offline | Gateway type |
| `driver` | required, string, max:255 | Fully qualified driver class name |
| `credentials` | required, array | JSON object with gateway-specific keys |
| `credentials.key` | required, string | API key |
| `credentials.secret` | required, string | API secret |
| `credentials.webhook_secret` | nullable, string | Webhook HMAC secret |
| `extra_config` | nullable, array | JSON config |
| `extra_config.mode` | nullable, in:live,test | Operation mode |
| `priority` | nullable, integer, min:1, max:100 | Display/selection priority |
| `is_active` | nullable, boolean | Active flag |
| `is_test_mode` | nullable, boolean | Test mode flag |

### Business Rule: Only one active gateway per type

The `withValidator()` method on `PaymentGatewayRequest` enforces that only one gateway of a given type (`online`/`offline`) can be active at a time. If `is_active` is truthy and another active gateway of the same type exists, the validation fails.

### InitiatePaymentRequest

| Field | Rules |
|-------|-------|
| `payable_type` | required, class_exists, implements Payable interface |
| `payable_id` | required, integer, min:1 |
| `gateway` | required, in:active gateway codes |
| `offline_method` | required_if:gateway,offline, in:cash,cheque,bank_transfer,demand_draft,upi_manual |
| `offline_reference` | nullable, string, max:100 |
| `offline_notes` | nullable, string, max:500 |

### InitiateRefundRequest

| Field | Rules |
|-------|-------|
| `amount` | required, numeric, min:0.01 |
| `reason` | required, string, max:500 |

## 12. Business Logic Rules

| Rule | Description |
|------|-------------|
| Unique code | Gateway code must be unique across all gateways |
| Single active per type | Only one gateway of each type (online/offline) can be active at a time |
| Active gateway required | Payment initiation requires an active gateway matching the requested code |
| Refundable only on success | Refunds can only be initiated against payments in `success` status |
| Partial refund capped | Refund amount cannot exceed `payment.amount - sum(successful refunds)` |
| Full refund → status update | When accumulated refunds >= payment amount, payment becomes `refunded` |
| Webhook idempotency | `idempotency_key` UNIQUE constraint prevents duplicate webhook processing |
| Signature-first middleware | VerifyWebhookSignature reads raw body BEFORE JSON decode for HMAC integrity |
| Queue-based webhooks | Webhook controller stores → dispatches job → returns 200; gateway retry on non-2xx |
| Soft deletes | All ptm models use SoftDeletes except AuditLog (append-only) |
| Credential encryption | `credentials` cast as `encrypted:array` in PaymentGateway model |
| Audit on every state change | Every payment creation, update, toggle, and delete records an audit entry |

## 13. Routes Summary

### Web Routes (Backend Admin)

| Method | URI | Controller | Permission |
|--------|-----|------------|------------|
| GET | `/payment` | Backend\PaymentController@index | tenant.payment.viewAny |
| GET | `/payment/{ulid}` | Backend\PaymentController@show | tenant.payment.view |
| GET | `/payment/{ulid}/receipt` | Backend\ReceiptController@show | tenant.payment.view |
| GET | `/payment/refunds` | Backend\RefundController@index | viewAny PaymentRefund |
| GET | `/payment/payment-webhooks` | Backend\WebhookController@index | tenant.payment.reconciliation.viewAny |
| GET | `/payment/payment-gateway` | PaymentGatewayController@index | tenant.payment.gateway.viewAny |
| GET | `/payment/payment-gateway/create` | PaymentGatewayController@create | tenant.payment.gateway.create |
| POST | `/payment/payment-gateway` | PaymentGatewayController@store | tenant.payment.gateway.create |
| GET | `/payment/payment-gateway/{id}` | PaymentGatewayController@show | tenant.payment.gateway.viewAny |
| GET | `/payment/payment-gateway/{id}/edit` | PaymentGatewayController@edit | tenant.payment.gateway.update |
| PUT/PATCH | `/payment/payment-gateway/{id}` | PaymentGatewayController@update | tenant.payment.gateway.update |
| DELETE | `/payment/payment-gateway/{id}` | PaymentGatewayController@destroy | tenant.payment.gateway.delete |
| POST | `/payment/payment-gateway/{gateway}/toggle-status` | PaymentGatewayController@toggleStatus | tenant.payment.gateway.update |
| GET | `/payment/payment-gateway/trash/view` | PaymentGatewayController@trashedPaymentGateways | tenant.payment.gateway.restore |
| GET | `/payment/payment-gateway/{id}/restore` | PaymentGatewayController@restore | tenant.payment.gateway.restore |
| DELETE | `/payment/payment-gateway/{id}/force-delete` | PaymentGatewayController@forceDelete | tenant.payment.gateway.forceDelete |
| POST | `/payment/payment/{ulid}/callback` | PaymentController@callback | (authorize via policy) |
| GET | `/payment/payment/reconciliation` | PaymentReconciliationController@index | tenant.payment.reconciliation.viewAny |
| GET | `/payment/payment/reconciliation/{id}` | PaymentReconciliationController@show | tenant.payment.reconciliation.view |
| POST | `/payment/payment/reconciliation` | PaymentReconciliationController@store | tenant.payment.reconciliation.create |
| POST | `/payment/payment/reconciliation/{id}/resolve` | PaymentReconciliationController@resolve | tenant.payment.reconciliation.resolve |

### API Routes (Mobile)

| Method | URI | Controller | Auth |
|--------|-----|------------|------|
| POST | `/api/v1/payments/initiate` | PaymentController@initiate | sanctum |
| POST | `/api/v1/payments/{ulid}/callback` | PaymentController@callback | sanctum |
| POST | `/api/v1/payments/{ulid}/cancel` | PaymentController@cancel | sanctum |
| GET | `/api/v1/payments/{ulid}` | PaymentController@show | sanctum |
| POST | `/api/v1/payments/{ulid}/refund` | RefundController@store | sanctum |
| GET | `/api/v1/payments/{ulid}/refunds` | RefundController@index | sanctum |

### Webhook Routes (No Auth)

| Method | URI | Controller | Middleware |
|--------|-----|------------|------------|
| POST | `/payment/webhooks/{gateway}` | WebhookController@handle | payment.webhook.verify |

## 14. Console Commands

| Command | Signature | Schedule | Description |
|---------|-----------|----------|-------------|
| Reconcile Settlements | `payment:reconcile-settlements {--date=} {--gateway=} {--dry-run}` | Daily at 03:00 | Parse gateway CSV settlements and reconcile against local payments |

## 15. Requirements

### MUST Requirements

| # | Requirement |
|---|-------------|
| R1 | The system MUST provide a Payable contract that any module model can implement to initiate payments |
| R2 | The system MUST support multiple payment gateways simultaneously (Razorpay, PhonePe, Paytm, CCAvenue, BillDesk, Offline) |
| R3 | The system MUST store payment state transitions in an append-only audit trail |
| R4 | The system MUST enforce idempotency on all gateway callback and webhook payloads via unique idempotency keys |
| R5 | The system MUST process webhooks asynchronously via the queue (store → return 200 → process) |
| R6 | The system MUST support partial refunds with gateway API integration |
| R7 | The system MUST support offline payment recording (cash, cheque, DD, bank transfer, manual UPI) |
| R8 | The system MUST reconcile gateway settlement CSVs against local payment records with match/unmatched/mismatch status |
| R9 | The system MUST support credential encryption for saved gateway driver configurations |
| R10 | The system MUST generate downloadable PDF receipts for successful payments |
| R11 | The system MUST dispatch lifecycle events (Initiated/Succeeded/Failed/Cancelled) for listener consumption |
| R12 | The system MUST support test/live mode switching per gateway configuration |

### SHOULD Requirements

| # | Requirement |
|---|-------------|
| S1 | The system SHOULD allow gateway priority ordering for fallback behavior |
| S2 | The system SHOULD retry failed webhook processing up to 3 times with exponential backoff |
| S3 | The system SHOULD track cheque bounce date and notes on offline payment records |

### COULD Requirements

| # | Requirement |
|---|-------------|
| C1 | The system COULD support bulk CSV export of payment and refund records |
| C2 | The system COULD support scheduled auto-reconciliation via cron |

## 16. Dependencies Map

```
Payment Module ───┬─── sys_users (System Auth) ─── FK references (initiated_by, created_by, collected_by)
                  │
                  ├─── ptm_payment_gateways ─── self-reference (gateway FK on payments, refunds, reconciliations)
                  │
                  ├─── Fee Module ─── fee_transactions, fee_payment_gateway_logs, fee_payment_reconciliation
                  │
                  ├─── Vendor Module ─── vnd_invoices, vnd_vendors, vnd_payments
                  │
                  ├─── Library Module ─── lib_fines, lib_fine_payments
                  │
                  └─── SystemConfig ─── sys_dropdown_table (payment_mode FK in vnd_payments)
```
