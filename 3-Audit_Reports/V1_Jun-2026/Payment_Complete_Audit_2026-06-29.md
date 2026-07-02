# Complete Audit — Payment (PAY) — 2026-06-29
> Mode X: A (12-layer) + B (FRD Gap) + C (BR Enforcement) + G (Deploy Gate) + scoped D (Systemic Patterns)
> Auditor: pa-technical-auditor | Branch: main | App path: `/Users/bkwork/Herd/prime_ai/Modules/Payment/`

---

## 1. Executive Summary

The Payment module is structurally the most critical module in the platform — it handles all fee collection, refunds, and gateway orchestration. It is approximately **50–55% functionally complete** with six confirmed production-fatal defects. The three core user-facing flows (payment initiation, refund, reconciliation) are each broken by at least one P0 or P1 finding.

The architecture is well-conceived: ULID public identifiers, encrypted credentials, HMAC-verified webhooks, polymorphic Payable interface, append-only audit logs, and six gateway drivers. However, the implementation has critical gaps in routing, authorization, tenancy, and transactional integrity that prevent any flow from completing correctly in production.

**Health: 40 / 100 (P0-capped; uncapped raw score ≈ 19)**
**DEPLOY: NO-GO**
**P0 count: 6**

Pre-existing issues noted in known-issues.md (SEC-PAY-001/004/008, BUG-PAY-001) are **RESOLVED** in the refactored codebase. New findings are documented below under codes SEC-PAY-009+ and BUG-PAY-002+.

---

## 2. Health Score

| Layer | Weight | Score | Raw | Notes |
|-------|--------|-------|-----|-------|
| L6 Tenancy | 15 | RED | 0.0 | P0: TEN-PAY-001 — API routes missing full tenancy middleware |
| L5 Authorization | 14 | RED | 0.0 | P0: SEC-PAY-009 — no PaymentPolicy class |
| L8 Data Integrity | 13 | RED | 0.0 | P0: DAT-PAY-001 — no DB::transaction in initiate() |
| L7 Validation | 11 | AMBER | 5.5 | Rules solid; D30 authorize() on all 3 FormRequests |
| L12 Deploy Gate | 10 | RED | 0.0 | 6 P0s; D39 permissions not seeded |
| L2 Migration-Model | 9 | RED | 0.0 | P0: BUG-PAY-002 dead model; P1: MIG-PAY-001 method/mode |
| L1 DDL | 7 | AMBER | 3.5 | 6 ENUM columns (D29); no standalone DDL spec |
| L9 Performance | 7 | AMBER | 3.5 | PERF-PAY-001: GatewayManager uncached DB query |
| L10 Queue / Job | 6 | AMBER | 2.5 | JOB-PAY-001: no explicit tenancy re-init in webhook job |
| L4 Code Quality | 4 | AMBER | 2.0 | Hardcoded driver list; unvalidated callback input |
| L3 ORM | 2 | AMBER | 1.0 | priority, failure_reason missing from fillable |
| L11 Frontend | 2 | AMBER | 0.8 | SEC-PAY-012: handler never posts callback for verification |
| **TOTAL** | **100** | | **18.8** | |

P0-cap (6 P0s present) → **Health = 40 / 100**

---

## 3. Deploy Gate Verdict

**NO-GO**

Blocking conditions:
1. Six module-level P0 findings (any one blocks production deploy)
2. Platform P0 DEPLOY-HRZ-01 inherited (queue driver = database; Horizon supervises redis)
3. REQ-PAY-002 AC2 directly violated (no transaction → orphan Payment records on gateway failures)
4. All API payment routes execute in central DB context (TEN-PAY-001)
5. Refund feature completely inaccessible (BUG-PAY-003)

---

## 4. P0 Findings — Production Blockers

### BUG-PAY-002 (P0) — Dead PaymentHistory Model
**File:** `Modules/Payment/app/Models/PaymentHistory.php:12`
`$table = 'ptm_payment_histories'`

Migration 100102 (`Schema::dropIfExists('ptm_payment_histories')`) permanently dropped the `ptm_payment_histories` table. The `PaymentHistory` model still references it. Any code path that touches `PaymentHistory` (including the test file `Unit/PaymentHistoryModelTest.php`) will throw `SQLSTATE[42S02]: Table 'tenant_db.ptm_payment_histories' doesn't exist`.

**Fix:** Delete `PaymentHistory.php` and `Unit/PaymentHistoryModelTest.php`; update any remaining references to query `ptm_payments` directly.

---

### BUG-PAY-003 (P0) — RefundController Has Zero Routes
**Files:** `Modules/Payment/routes/web.php`, `routes/api.php`

`RefundController` implements `store()` and `index()` but neither route file registers any routes to it. The refund feature is fully built on the backend (controller, service, FormRequest, model, migration) but is completely inaccessible from any HTTP client.

**Fix:** Add routes for refund initiation and listing — recommend API routes under `auth:sanctum` + full tenancy middleware stack.

---

### BUG-PAY-004 (P0) — apiResource Routing Mismatch on PaymentController
**File:** `Modules/Payment/routes/api.php:7`

```php
Route::apiResource('payments', PaymentController::class)->names('payment');
```

`Route::apiResource` generates `index/store/show/update/destroy` methods. `PaymentController` has `initiate/callback/cancel/show`. The routing table:
- `GET /v1/payments` → `index()` → **MethodNotAllowedHttpException** (method doesn't exist) → 500
- `POST /v1/payments` → `store()` → **500** (doesn't exist)
- `GET /v1/payments/{payment}` → `show()` → **works**
- `PUT /v1/payments/{payment}` → `update()` → **500** (doesn't exist)
- `DELETE /v1/payments/{payment}` → `destroy()` → **500** (doesn't exist)

The three real methods (`initiate`, `callback`, `cancel`) are never routed at all.

**Fix:** Replace `apiResource` with explicit named routes: `Route::post('payments/initiate', ...)`, `Route::post('payments/{payment}/callback', ...)`, `Route::patch('payments/{payment}/cancel', ...)`.

---

### SEC-PAY-009 (P0) — No PaymentPolicy Class; PolicyNotRegisteredException on Every Payment
**File:** `Modules/Payment/app/Http/Controllers/PaymentController.php` (initiate method)

```php
$this->authorize('initiate', $payable);
```

There is no `Modules/Payment/app/Policies/` directory and no PaymentPolicy registered anywhere (PaymentServiceProvider has no `registerPolicies()`). `$this->authorize('initiate', $payable)` delegates to a policy on `$payable`'s class (e.g., FeeInvoice). If FeeInvoice has no policy with an `initiate` method — and none exists — Laravel throws `Illuminate\Auth\Access\AuthorizationException` or `InvalidArgumentException: Policy not registered`. Every payment initiation attempt crashes.

**Fix:** Create `Modules/Payment/app/Policies/PaymentPolicy.php` registered in `PaymentServiceProvider::boot()` via `Gate::policy(Payment::class, PaymentPolicy::class)`. Add `initiate()`, `cancel()`, `show()` methods with ownership and status checks.

---

### TEN-PAY-001 (P0) — API Routes Missing Full Tenancy Middleware Stack
**File:** `Modules/Payment/app/Providers/RouteServiceProvider.php` (mapApiRoutes method)

```php
Route::middleware('api')->prefix('api')->name('api.')->group(...);
```

Only `api` middleware is applied. The web and webhook route groups correctly apply `InitializeTenancyByDomain`, `PreventAccessFromCentralDomains`, `EnsureTenantIsActive`. The API group does not. All requests to `/api/v1/payments/*` execute with the global (central) database connection — `ptm_payments`, `ptm_payment_gateways`, and all related queries run against the wrong schema.

**Fix:** Apply the full tenancy stack in `mapApiRoutes()`:
```php
Route::middleware(['api', InitializeTenancyByDomain::class, PreventAccessFromCentralDomains::class, EnsureTenantIsActive::class])
```

---

### DAT-PAY-001 (P0) — No DB Transaction in PaymentService::initiate(); FRD AC2 Directly Violated
**File:** `Modules/Payment/app/Services/PaymentService.php` (initiate method)

The initiation flow:
1. `Payment::create([...])` — inserts record in 'initiated' status
2. `$driver->initiate($payment, $payable)` — external API call (Razorpay, etc.)
3. `$payment->update(['gateway_order_id' => ..., 'status' => 'pending'])` — second write

Steps 1–3 are NOT wrapped in `DB::transaction()`. If the gateway API call (step 2) fails, step 1's record persists as an orphan with status 'initiated' and no `gateway_order_id`. If step 3 fails (DB timeout after API succeeds), payment is stuck in 'initiated' status with no order ID.

REQ-PAY-002 Acceptance Criterion 2: "When the gateway API call fails, no Payment Record persists in the database (transaction rollback)." — **DIRECTLY VIOLATED**.

**Fix:**
```php
return DB::transaction(function () use ($gateway, $payable, $request) {
    $payment = Payment::create([...]);
    try {
        $checkout = $driver->initiate($payment, $payable);
    } catch (\Throwable $e) {
        throw $e; // transaction rolls back
    }
    $payment->update(['gateway_order_id' => ..., 'status' => Payment::STATUS_PENDING]);
    return $checkout;
});
```

---

## 5. P1 Findings — Required Before Beta

### SEC-PAY-010 (P1) — PaymentController::cancel() Has Zero Authorization
**File:** `Modules/Payment/app/Http/Controllers/PaymentController.php` (cancel method)

`cancel(string $ulid)` fetches `$this->paymentService->getByUlid($ulid)` with no Gate check, no policy check, no ownership validation. When routes are added (fixing BUG-PAY-004), any authenticated user can cancel any payment by guessing/knowing a ULID. Even though ULID is hard to enumerate, this is an IDOR vulnerability.

**Fix:** Add `$this->authorize('cancel', $payment)` after retrieving the model, with PaymentPolicy::cancel() validating actor ownership.

---

### SEC-PAY-011 (P1) — D39: payment.gateway.* Permissions Never Seeded
**Files:** `Modules/Payment/app/Http/Controllers/PaymentGatewayController.php`, `database/seeders/`

`PaymentGatewayController` uses `Gate::authorize('payment.gateway.viewAny')`, `payment.gateway.create`, `payment.gateway.update`, `payment.gateway.delete`, `payment.gateway.restore`, `payment.gateway.forceDelete`. No seeder in `database/seeders/` or `Modules/Payment/database/seeders/` defines these permissions. `PaymentDatabaseSeeder` exists as a stub only (empty).

Effective result: only super-admin (who bypasses via `Gate::before`) can configure payment gateways. Finance Admin and Bursar roles — the intended actors per the FRD — receive 403 on all gateway configuration screens.

Also a D24 issue: prefix is `payment.gateway.*` not `tenant.*` (platform standard from D22).

**Fix:** Create `PaymentPermissionSeeder` defining `payment.gateway.*` permissions; register under Bursar / Finance Admin roles. Align permission prefix to `tenant.*` convention.

---

### SEC-PAY-012 (P1) — Razorpay Checkout Handler Never Posts Callback for Server-Side Verification
**File:** `Modules/Payment/resources/views/razorpay/process-payment.blade.php:21–24`

```javascript
handler: function (response) {
    alert("Payment Processing... Please wait.");
    window.location.href = "{{ route('student-portal.fee-summary') }}";
},
```

The Razorpay `handler` fires after user completes checkout. It should POST `razorpay_payment_id`, `razorpay_order_id`, `razorpay_signature` back to the server callback endpoint for HMAC-SHA256 verification. Instead it merely redirects to fee summary.

Server-side payment confirmation now depends entirely on Razorpay webhook delivery (asynchronous, not guaranteed). If the webhook fails or delays:
- User sees "success" UI
- Payment status stays 'initiated' in database
- Fee invoice is never marked paid
- No receipt generated

REQ-PAY-002 AC3 ("Server-side HMAC-SHA256 signature verification before marking success") partially unmet.

**Fix:** Change handler to `fetch('/payment/callback/'+response.razorpay_order_id, { method:'POST', body: JSON.stringify(response), headers: {...} })` and redirect only after server confirms success.

---

### TEN-PAY-002 (P1) — No EnsureTenantHasModule on Any Payment Route Group
**File:** `Modules/Payment/app/Providers/RouteServiceProvider.php`

No route group applies `EnsureTenantHasModule` for the 'PAY' module. Any tenant — regardless of subscription plan — can access all payment gateway configuration, payment processing, and webhook endpoints. Violates NFR-PAY licensing model.

**Fix:** Add `EnsureTenantHasModule:PAY` to the web and API middleware stacks.

---

### DAT-PAY-002 (P1) — RefundService Over-Refund: Sum of Prior Refunds Not Checked
**File:** `Modules/Payment/app/Services/RefundService.php` (initiate method)

```php
if ($amount > $payment->amount) {
    throw new \InvalidArgumentException('Refund amount exceeds payment amount.');
}
```

Only the gross payment amount is checked — not the cumulative sum of prior successful refunds. If a ₹1000 payment has a ₹800 refund processed, a second ₹800 refund request passes the check (`800 <= 1000`) and creates a second refund, totalling ₹1600 — 60% over the original amount. BR-PAY-009 directly violated.

No `SELECT FOR UPDATE` on the payment row either → concurrent refund race condition possible.

**Fix:**
```php
$refunded = PaymentRefund::where('payment_id', $payment->id)
    ->where('status', PaymentRefund::STATUS_SUCCESS)
    ->sum('amount');
$maxRefundable = $payment->amount - $refunded;
if ($amount > $maxRefundable) {
    throw new \InvalidArgumentException("Max refundable is ₹{$maxRefundable}");
}
// Inside DB::transaction, add: $payment->lockForUpdate()->fresh()
```

---

### MIG-PAY-001 (P1) — D17: OfflinePaymentRecord.$fillable Has 'method'; Migration Column Is 'mode'
**File:** `Modules/Payment/app/Models/OfflinePaymentRecord.php` vs migration `100106`

The model defines constants `METHOD_CASH`, `METHOD_CHEQUE`, `METHOD_BANK_TRANSFER` and `$fillable` includes `'method'`. The migration creates column `mode` (ENUM: cash/cheque/bank_transfer/demand_draft/upi_manual). Any `OfflinePaymentRecord::create(['method' => 'cash', ...])` throws `SQLSTATE[42S22]: Column not found: 1054 Unknown column 'method'`.

Additionally missing from `$fillable`: `bank_name`, `cheque_date`, `clearance_status`, `receipt_number` — all real columns that cannot be mass-assigned.

**Fix:** Rename `$fillable` entry from `'method'` to `'mode'`; rename model constants; add the four missing columns to `$fillable`.

---

### BUG-PAY-005 (P1) — PaymentGateway.$fillable Missing 'priority'; Controller Silently Drops It
**File:** `Modules/Payment/app/Http/Controllers/PaymentGatewayController.php` (store/update methods)

Controller: `'priority' => $request->priority ?? 1`

`PaymentGateway.$fillable` does not include `'priority'`. Laravel silently drops the field during `PaymentGateway::create([..., 'priority' => 1, ...])`. The `priority` column exists in the migration (100100: `$table->integer('priority')->default(1)`). Every gateway is created/updated with the default priority of 1, making ordering configuration permanently ineffective.

**Fix:** Add `'priority'` to `PaymentGateway.$fillable`.

---

### BUG-PAY-006 (P1) — PaymentController::callback() Passes Unvalidated $request->all() to Driver
**File:** `Modules/Payment/app/Http/Controllers/PaymentController.php` (callback method)

```php
if ($driver->verify($request->all())) {
    $this->paymentService->markSuccess($payment, $request->all());
```

The entire request payload is passed unvalidated to the gateway driver's verify method and then to the payment service. No `FormRequest` validation or `$request->only([...])` filtration is applied. The gateway signature check is performed on the raw payload, but if a malicious actor submits extra fields they are forwarded into the audit log payload. More critically, if `markSuccess()` extracts fields by key from the payload, unvalidated input shapes the payment completion path.

**Fix:** Create `PaymentCallbackRequest` with explicit rules for `razorpay_payment_id`, `razorpay_order_id`, `razorpay_signature` and use `$request->only([...])` instead of `$request->all()`.

---

### BUG-PAY-007 (P1) — getAvailableDrivers() Hardcoded to Razorpay; 5 Gateways Inaccessible
**File:** `Modules/Payment/app/Http/Controllers/PaymentGatewayController.php` (getAvailableDrivers method)

```php
return response()->json(['drivers' => [RazorpayGateway::class]]);
```

BillDeskGateway, CCAvenueGateway, PaytmGateway, PhonePeGateway, and OfflineGateway are fully implemented but not returned by this endpoint. Gateway admin UI can only create/configure Razorpay gateways. Violates REQ-PAY-013 (multi-gateway support).

**Fix:** Return all 6 driver FQCNs from config or discovery — e.g., `config('payment.drivers')` fed from `PaymentServiceProvider`.

---

### BUG-PAY-008 (P1) — ReconciliationController and Routes Completely Absent
**Files:** `Modules/Payment/routes/web.php`, `routes/api.php`

`PaymentReconciliation` model, `ptm_payment_reconciliations` migration (100107), and `computeDiscrepancy()` method all exist. No `ReconciliationController`, no routes. REQ-PAY-009 (reconciliation UI and daily job) has zero backend endpoint coverage.

**Fix:** Create `ReconciliationController` with `index`, `show`, `reconcile` methods; wire routes; add daily `ReconcileGatewaySettlements` console command to scheduler.

---

### JOB-PAY-001 (P1) — ProcessWebhookJob Queries Tenant Tables Without Explicit Tenancy Re-initialization
**File:** `Modules/Payment/app/Jobs/ProcessWebhookJob.php` (handle method)

`handle()` calls `$this->gatewayManager->resolve($webhook->gateway)` → `PaymentGateway::where('code', $code)->first()` and then updates `Payment` records — both tenant tables. The job has no explicit `Tenancy::initialize($tenant)` call. If `QueueTenancyBootstrapper` is not registered in the central `TenancyServiceProvider`, the queue worker runs in central DB context and all queries target the wrong database.

**Risk:** P0 if QueueTenancyBootstrapper is absent; P1 if present but not explicitly verified.

**Fix:** Confirm `QueueTenancyBootstrapper::class` is in `config/tenancy.php` bootstrappers. As defensive measure, add explicit `tenancy()->initialize($this->webhook->tenant_id ?? $tenant)` at top of `handle()`.

---

## 6. P2 Findings — Required Before General Availability

### DAT-PAY-003 (P2) — D29: Six ENUM Columns Across Five Migrations
**Files:** Migrations 100101, 100102, 100103, 100106 (×2), 100107

| Table | Column | Values |
|-------|--------|--------|
| `ptm_payment_gateways` | `type` | online, offline |
| `ptm_payments` | `status` | pending, initiated, success, failed, cancelled, refunded |
| `ptm_payment_refunds` | `status` | pending, processing, success, failed |
| `ptm_offline_payment_records` | `mode` | cash, cheque, bank_transfer, demand_draft, upi_manual |
| `ptm_offline_payment_records` | `clearance_status` | pending, cleared, bounced |
| `ptm_payment_reconciliations` | `status` | pending, matched, discrepant, resolved |

Platform decision D29: ENUM columns are prohibited; status/type values should be driven by `sys_dropdowns` (tenant table). Adding a new status (e.g., 'chargeback') requires an ALTER TABLE migration instead of a dropdown entry.

**Fix (sprints 2–3):** Create `sys_dropdowns` entries for PAY_GATEWAY_TYPE, PAY_PAYMENT_STATUS, PAY_REFUND_STATUS, PAY_OFFLINE_MODE, PAY_CLEARANCE_STATUS, PAY_RECONCILIATION_STATUS; replace ENUM columns with `unsignedBigInteger` FKs.

---

### BUG-PAY-009 (P2) — D17: PaymentWebhook.$fillable Has 'payment_id'; Migration Has No Such Column
**File:** `Modules/Payment/app/Models/PaymentWebhook.php` vs migration `100105`

`$fillable` includes `'payment_id'`; model defines `payment()` BelongsTo. Migration 100105 creates `ptm_payment_webhooks` with no `payment_id` column. The relationship always returns null. If any code does `PaymentWebhook::create(['payment_id' => $id, ...])`, it throws `SQLSTATE[42S22]`. The `WebhookController` does not currently set `payment_id`, so the immediate crash path is inactive, but the relationship is permanently broken.

**Fix:** Add migration: `$table->foreignId('payment_id')->nullable()->constrained('ptm_payments')`. Add `'payment_id'` to migration so the relationship works.

---

### BUG-PAY-010 (P2) — failure_reason Column Exists but Not in Payment.$fillable; PaymentService.markFailed() Never Persists It
**Files:** `Modules/Payment/app/Models/Payment.php`, `Modules/Payment/app/Services/PaymentService.php`

Migration 100102 defines `failure_reason TEXT`. `PaymentService::markFailed($payment, $reason, $payload)` receives `$reason` but has no `$payment->update(['failure_reason' => $reason])` call. `failure_reason` is also absent from `$fillable`. Every payment failure loses its diagnostic reason — support cannot distinguish network failures from declines from signature mismatches.

**Fix:** Add `'failure_reason'` to `Payment.$fillable`; add `'failure_reason' => $reason` to the `markFailed()` update call.

---

### BUG-PAY-011 (P2) — Missing Views: Refund Management, Webhook Log Admin, Payment Detail, Receipt
**File:** `Modules/Payment/resources/views/`

Views present: `payment-gateway/` (full CRUD), `razorpay/process-payment.blade.php`, `index.blade.php`, `partials/payment-history.blade.php`.

Views absent:
- Refund initiation + listing (REQ-PAY-007)
- Webhook log admin (REQ-PAY-008)
- Payment detail / show page (REQ-PAY-011)
- PDF receipt download link (REQ-PAY-012)

The `payment-history.blade.php` partial loops over `$paymentHistories` but no controller populates that variable (index controller is not implemented in PaymentController).

---

### PERF-PAY-001 (P2) — GatewayManager.resolve() Queries DB on Every Call; No Cache
**File:** `Modules/Payment/app/Services/GatewayManager.php` (resolve method)

```php
$gateway = PaymentGateway::where('code', $code)->where('is_active', true)->first();
```

This executes a DB query on every payment initiation, every callback, every webhook processing, and every `InitiatePaymentRequest` validation (the FormRequest also queries for active gateways independently). Gateway configuration is rarely changed — it should be cached.

**Fix:**
```php
return Cache::remember("payment_gateway_{$code}", now()->addMinutes(10), function () use ($code) {
    return PaymentGateway::where('code', $code)->where('is_active', true)->firstOrFail();
});
```
Also apply to `InitiatePaymentRequest::rules()`.

---

### DEAD-PAY-001 (P2) — EventServiceProvider.$listen=[] with $shouldDiscoverEvents=true but No Listener Classes
**File:** `Modules/Payment/app/Providers/EventServiceProvider.php`

```php
protected $listen = [];
protected bool $shouldDiscoverEvents = true;
```

Auto-discovery finds no listeners (no `app/Listeners/` directory). Eight events fire into void: `PaymentSucceeded`, `PaymentFailed`, `PaymentCancelled`, `RefundInitiated`, `RefundSucceeded`, `RefundFailed`, `WebhookReceived`, `WebhookProcessed`.

Downstream consequences:
- `PaymentSucceeded` → FeeInvoice never marked paid (StudentFee module not notified)
- `PaymentSucceeded` → No receipt PDF generated
- `PaymentSucceeded` → No accounting voucher created
- `PaymentSucceeded` / `PaymentFailed` → No notification to parent/student

**Fix:** Create listeners: `MarkFeeInvoicePaidListener`, `SendPaymentReceiptListener`, `CreateAccountingVoucherListener`, `SendPaymentNotificationListener`; register in `$listen` array.

---

## 7. P3 Findings — Technical Debt / Cleanup

### BUG-PAY-012 (P3) — OfflineGateway.initiate() Never Writes to ptm_offline_payment_records
**File:** `Modules/Payment/app/Gateways/OfflineGateway.php` (initiate method)

`initiate()` returns synthetic checkout data (`OFFLINE-XXXX` reference) and records a log message but never creates an `OfflinePaymentRecord`. The `ptm_offline_payment_records` table and `OfflinePaymentRecord` model exist with full field set (bank_name, cheque_date, mode, receipt_number, clearance_status). The write path is completely disconnected.

**Fix:** After creating the Payment record, call `OfflinePaymentRecord::create([...])` in `OfflineGateway::initiate()` or in `PaymentService` immediately after gateway initiation.

---

### DEAD-PAY-002 (P3) — PaymentHistoryModelTest.php Tests Against Dead Table
**File:** `Modules/Payment/tests/Unit/PaymentHistoryModelTest.php`

This test file creates/queries `PaymentHistory` records. Since `ptm_payment_histories` was dropped by migration 100102, any test that touches the DB will throw `Table not found`. This pollutes the test run with false failures and blocks CI if Payment tests are included in the test suite.

**Fix:** Delete this file (see BUG-PAY-002 fix).

---

## 8. Layer Health Summary

| Layer | Status | Key Finding |
|-------|--------|-------------|
| L1 DDL | AMBER | 6 D29 ENUMs in 5 migrations; no standalone DDL spec |
| L2 Migration↔Model | RED | BUG-PAY-002 (dead model), MIG-PAY-001 (method/mode), BUG-PAY-009 (phantom fillable) |
| L3 ORM | AMBER | priority + failure_reason missing from fillable; amount cast float not decimal:2 |
| L4 Code Quality | AMBER | Unvalidated callback input; hardcoded driver list; no debug statements |
| L5 Authorization | RED | No PaymentPolicy; cancel() unprotected; D39 permissions not seeded |
| L6 Tenancy | RED | API routes missing tenancy stack; no EnsureTenantHasModule |
| L7 Validation | AMBER | FormRequest rules are solid; all three FormRequests have D30 authorize() |
| L8 Data Integrity | RED | No transaction in initiate(); over-refund possible; concurrent refund race |
| L9 Performance | AMBER | GatewayManager uncached; FormRequest gateway query uncached |
| L10 Queue/Job | AMBER | No explicit tenancy re-init; $tries/$backoff correctly set |
| L11 Frontend | AMBER | Views use {{ }} escaping; handler never posts callback for verification |
| L12 Deploy Gate | RED | 6 P0s; D39 perms; platform DEPLOY-HRZ-01 |

---

## 9. Reading-Discipline Output (Files Audited)

**Routes:**
- `Modules/Payment/routes/api.php` — apiResource mismatch confirmed (TEN-PAY-001 + BUG-PAY-004)
- `Modules/Payment/routes/web.php` — PaymentGatewayController routed; RefundController absent (BUG-PAY-003)
- `Modules/Payment/routes/webhooks.php` — correct stack; no auth; HMAC middleware ✓

**Providers:**
- `Modules/Payment/app/Providers/RouteServiceProvider.php` — API middleware gap found (TEN-PAY-001)
- `Modules/Payment/app/Providers/PaymentServiceProvider.php` — 4 singletons, middleware alias registered ✓
- `Modules/Payment/app/Providers/EventServiceProvider.php` — `$listen = []`, no listeners (DEAD-PAY-001)

**Controllers (4):**
- `PaymentController.php` — initiate/callback/cancel/show; no policy; callback unvalidated
- `PaymentGatewayController.php` — full CRUD + Gate::authorize; D24 prefix; hardcoded driver
- `RefundController.php` — built but unrouted (BUG-PAY-003)
- `WebhookController.php` — store-then-queue pattern; idempotency_key uniqueness not soft-handled

**Models (8):**
- `Payment.php` — missing failure_reason, initiated_by from fillable; amount cast float
- `PaymentGateway.php` — missing priority from fillable; encrypted:array credentials ✓
- `PaymentRefund.php` — fillable clean ✓
- `PaymentAuditLog.php` — immutable ($timestamps=false, no SoftDeletes) ✓
- `PaymentWebhook.php` — payment_id in fillable but no DB column (BUG-PAY-009)
- `OfflinePaymentRecord.php` — 'method' vs 'mode' D17 mismatch (MIG-PAY-001)
- `PaymentReconciliation.php` — computeDiscrepancy() in PHP; no controller/routes
- `PaymentHistory.php` — P0 dead model; table dropped (BUG-PAY-002)

**Services (4):**
- `PaymentService.php` — no transaction; markFailed doesn't write failure_reason
- `RefundService.php` — in DB::transaction ✓; sum-of-refunds check absent (DAT-PAY-002)
- `GatewayManager.php` — no cache (PERF-PAY-001)
- `AuditService.php` — append-only ✓; logStatusChange(), log(), logWebhook() all correct

**FormRequests (3):**
- `InitiatePaymentRequest.php` — D30 authorize; Payable interface check good; DB query in rules()
- `InitiateRefundRequest.php` — D30 authorize; amount validation missing max-refundable check
- `PaymentGatewayRequest.php` — authorize()=true (D30); hardcoded table name in unique rule

**Jobs:**
- `ProcessWebhookJob.php` — $tries=3, $backoff=30 ✓; no explicit tenancy re-init (JOB-PAY-001)

**Middleware:**
- `VerifyWebhookSignature.php` — reads raw body before JSON decode; hash_equals HMAC-SHA256 ✓

**Gateways (6):**
- `RazorpayGateway.php` — initiate + verify with HMAC check ✓
- `OfflineGateway.php` — mock reference, never writes OfflinePaymentRecord (BUG-PAY-012)
- BillDeskGateway, CCAvenueGateway, PaytmGateway, PhonePeGateway — implemented but inaccessible (BUG-PAY-007)

**Migrations (9):**
- 100100 through 100108 — all read; 6 ENUMs found (DAT-PAY-003); `ptm_payment_histories` confirmed dropped

**Views (9):**
- payment-gateway/: full CRUD views; `{{ }}` escaping throughout ✓
- razorpay/process-payment.blade.php — handler no callback post (SEC-PAY-012)
- partials/payment-history.blade.php — $paymentHistories variable never populated by controller

**Tests (11 files):**
- Unit/PaymentHistoryModelTest.php — dead model (DEAD-PAY-002)
- 10 remaining test files — not executed in this audit; content not read

**Seeders:**
- `database/seeders/` — no payment.gateway.* permission definitions anywhere (D39, SEC-PAY-011)
- `Modules/Payment/database/seeders/PaymentDatabaseSeeder.php` — stub only

---

## 10. FRD Gap Summary (Mode B)

**FRD:** `4-Requirement_Module_wise/0-FRD_Documents/PAY_FRD_Complete_2026-06-29.md`
**Requirements:** REQ-PAY-001 through REQ-PAY-013

| Req | Title | Status | Gap Finding |
|-----|-------|--------|-------------|
| REQ-PAY-001 | Multi-gateway configuration | PARTIAL | Gateway CRUD exists; permission seeder absent (D39); 5/6 drivers hidden in UI (BUG-PAY-007) |
| REQ-PAY-002 | Atomic payment initiation with rollback | VIOLATED | DAT-PAY-001: no DB::transaction; AC2 broken. SEC-PAY-012: handler no callback; AC3 partial. |
| REQ-PAY-003 | Offline payment recording | NOT MET | OfflineGateway never writes to ptm_offline_payment_records (BUG-PAY-012) |
| REQ-PAY-004 | Payment status FSM | PARTIAL | Status ENUM exists; transitions tracked in audit log; no formal state-machine guard |
| REQ-PAY-005 | Immutable audit trail | MET | AuditService append-only; ptm_payment_audit_logs has no updated_at/deleted_at ✓ |
| REQ-PAY-006 | Webhook handling + idempotency | MOSTLY MET | HMAC verify ✓; store-then-queue ✓; duplicate webhook causes 500 not 200 (minor) |
| REQ-PAY-007 | Refund management | NOT MET | RefundController built, zero routes (BUG-PAY-003); over-refund gap (DAT-PAY-002) |
| REQ-PAY-008 | Payment history view | PARTIAL | Blade partial exists; no controller populates $paymentHistories variable |
| REQ-PAY-009 | Reconciliation | NOT MET | Model + table exist; no controller, no routes, no daily job (BUG-PAY-008) |
| REQ-PAY-010 | Multi-gateway routing | PARTIAL | 6 drivers implemented; UI admin can only select Razorpay (BUG-PAY-007) |
| REQ-PAY-011 | Receipt PDF | NOT MET | No listener built; DEAD-PAY-001 (events fire into void) |
| REQ-PAY-012 | Fee invoice integration | NOT MET | PaymentSucceeded event fires but no FeeInvoicePaymentListener exists (DEAD-PAY-001) |
| REQ-PAY-013 | Test mode per gateway | PARTIAL | is_test_mode column (migration 100108) and model field added; no UI checkbox in gateway form; no driver test-mode flag handling verified |

**FRD Coverage: 2 of 13 requirements fully met; 4 partial; 7 not met or violated.**

---

## 11. Business Rule Enforcement (Mode C)

**Business Rules:** BR-PAY-001 through BR-PAY-016

| BR | Description | Status | Note |
|----|-------------|--------|------|
| BR-PAY-001 | Only one active gateway per type | NOT ENFORCED | No DB unique constraint on (type, is_active); no FormRequest validation |
| BR-PAY-002 | Only active gateways shown to payer | PARTIALLY ENFORCED | InitiatePaymentRequest validates gateway_code against active list ✓ |
| BR-PAY-003 | ULID as public payment identifier | ENFORCED | Payment + PaymentRefund use Str::ulid() ✓ |
| BR-PAY-004 | Gateway credentials encrypted at rest | ENFORCED | encrypted:array cast on PaymentGateway.credentials ✓ |
| BR-PAY-005 | Webhook HMAC-SHA256 verification | ENFORCED | VerifyWebhookSignature middleware with hash_equals ✓ |
| BR-PAY-006 | Idempotent webhook processing | PARTIALLY ENFORCED | DB UNIQUE on idempotency_key ✓; duplicate attempt throws 500 instead of 200 (violation of intent) |
| BR-PAY-007 | No status update before verification | VIOLATED | handler() redirects without posting to callback; success depends on webhook only |
| BR-PAY-008 | Audit log immutable | ENFORCED | AuditService insert-only; PaymentAuditLog has no SoftDeletes/updated_at ✓ |
| BR-PAY-009 | Max refund = original - prior refunds | VIOLATED | RefundService checks amount > payment.amount only; sum of prior refunds ignored (DAT-PAY-002) |
| BR-PAY-010 | Refund only for payments in success status | ENFORCED | RefundService status guard present (unreachable via routes, but logic correct) |
| BR-PAY-011 | Gateway failure reason recorded | VIOLATED | markFailed($reason) receives $reason but never writes to failure_reason column (BUG-PAY-010) |
| BR-PAY-012 | Payment record links to payable | ENFORCED | Polymorphic payable_type + payable_id on ptm_payments ✓ |
| BR-PAY-013 | Fee invoice status updated on success | NOT MET | PaymentSucceeded fires but no listener exists (DEAD-PAY-001) |
| BR-PAY-014 | Receipt generated on success | NOT MET | No receipt listener or PDF service exists |
| BR-PAY-015 | Test mode isolates from production | NOT VERIFIED | is_test_mode column exists; driver-level test mode handling not confirmed |
| BR-PAY-016 | Only authorized actors initiate payments | VIOLATED | SEC-PAY-009: PolicyNotRegisteredException; no valid authorization path |

**BR compliance: 6/16 enforced; 3/16 partial; 7/16 violated or not met.**

---

## 12. Systemic Pattern Scorecard (Mode D — Scoped)

| Pattern | Code | Instances in PAY | Severity |
|---------|------|-----------------|---------|
| ENUM columns in migration (D29) | DAT-PAY-003 | 6 columns / 5 migrations | P2 |
| FormRequest authorize() bare auth or true (D30) | — | 3/3 FormRequests (auth()->check() or true) | P1 |
| $fillable references missing columns / phantom columns (D17) | MIG-PAY-001, BUG-PAY-009 | 2 models (OfflinePaymentRecord, PaymentWebhook) | P1 |
| Permissions referenced but never seeded (D39) | SEC-PAY-011 | 6 permission strings in PaymentGatewayController | P1 |
| Non-standard permission prefix (D24) | SEC-PAY-011 | payment.gateway.* instead of tenant.* | P1 |
| Missing DB transaction on multi-step write (D38-adjacent) | DAT-PAY-001 | PaymentService.initiate() | P0 |
| No EnsureTenantHasModule guard (TEN-RTG-001 platform pattern) | TEN-PAY-002 | All route groups | P1 |
| EventServiceProvider empty with shouldDiscoverEvents (HRS pattern) | DEAD-PAY-001 | $listen=[] + no Listeners/ dir | P2 |
| Amount columns cast as float not decimal:2 | — | 3 models (Payment, PaymentRefund, PaymentReconciliation) | P3 |

---

## 13. vs Platform Baseline

| Metric | PAY Module | Platform Baseline |
|--------|-----------|-------------------|
| $request->all() mass-assignment | 0 | 16 controllers (D25) |
| Debug statements (dd/dump) | 0 | ~8 (various) |
| FormRequest D30 authorize()=true / bare auth | 3/3 | ~64% of FormRequests |
| ENUM columns in migrations | 6 | 476 platform-wide |
| Has explicit policy class | NO | ~40% of modules |
| Tenancy stack on API routes | MISSING | Inconsistent platform-wide |
| DB transaction on multi-write service | MISSING | Inconsistent |
| Encrypted sensitive columns | YES (credentials) | Module-dependent |
| Append-only audit log | YES (correct) | Rare (best practice followed) |
| ULID as public identifier | YES | Rare (best practice followed) |
| Dead model / dropped table | YES (PaymentHistory) | BUG-PAY-002 is new pattern |

**Positive differentiators:** Webhook HMAC verification (correct), credential encryption (correct), ULID public IDs (correct), immutable audit log (correct), gateway driver abstraction (solid architecture). PAY has the best security architecture of any module audited — the implementation just hasn't caught up with the design.

**Below baseline:** no PaymentPolicy (most modules have at least partial policies), no permission seeder (D39 present in Vendor and LmsExam but PAY is worse — gateway management is completely locked out).

---

## 14. Recommended Fix Order

### Sprint 1 — Unblock Basic Payment Flow (Resolves all P0s)
1. **TEN-PAY-001**: Add tenancy middleware to `mapApiRoutes()` — 5 minutes
2. **BUG-PAY-004**: Replace `apiResource` with explicit named routes in api.php — 20 minutes
3. **DAT-PAY-001**: Wrap `PaymentService.initiate()` in `DB::transaction()` — 30 minutes
4. **SEC-PAY-009**: Create `PaymentPolicy.php`; register in `PaymentServiceProvider` — 2 hours
5. **BUG-PAY-002**: Delete dead `PaymentHistory.php` and `PaymentHistoryModelTest.php` — 5 minutes
6. **BUG-PAY-003**: Add routes for `RefundController` (at minimum: `POST /api/v1/payments/{payment}/refunds`) — 15 minutes

### Sprint 2 — Security and Data Correctness (Resolves P1s)
7. **MIG-PAY-001**: Fix OfflinePaymentRecord fillable (method→mode) and add missing fields
8. **SEC-PAY-011**: Create PaymentPermissionSeeder; standardize to tenant.* prefix
9. **DAT-PAY-002**: Fix RefundService sum-of-prior-refunds check; add lockForUpdate()
10. **BUG-PAY-010**: Add failure_reason to Payment.$fillable; write it in markFailed()
11. **BUG-PAY-005**: Add priority to PaymentGateway.$fillable
12. **BUG-PAY-007**: Expand getAvailableDrivers() to return all 6 drivers
13. **TEN-PAY-002**: Add EnsureTenantHasModule:PAY to route groups
14. **SEC-PAY-012**: Fix Razorpay handler to POST payment credentials to callback endpoint
15. **JOB-PAY-001**: Verify QueueTenancyBootstrapper; add defensive tenancy init in handle()
16. **BUG-PAY-006**: Replace $request->all() with validated input in callback()

### Sprint 3 — Feature Completion (Resolves P2s and enables GA)
17. **BUG-PAY-008**: Create ReconciliationController + routes + daily scheduler command
18. **DEAD-PAY-001**: Build 4 event listeners (FeeInvoicePaid, Receipt, Accounting, Notification)
19. **BUG-PAY-009**: Add payment_id column to ptm_payment_webhooks via new migration
20. **BUG-PAY-011**: Build missing views (refund, webhook log, payment detail, receipt)
21. **PERF-PAY-001**: Add Cache::remember() in GatewayManager and FormRequest rules()
22. **DAT-PAY-003**: Replace 6 ENUM columns with sys_dropdowns FKs (D29 compliance)
23. **BUG-PAY-012**: Complete OfflineGateway write path to ptm_offline_payment_records

---

## 15. Pre-existing Issue Status (was in known-issues.md)

| Old Code | Old Finding | Current Status |
|----------|-------------|----------------|
| SEC-PAY-001 | Hardcoded Razorpay keys in PaymentController copy.php | RESOLVED — copy.php deleted |
| SEC-PAY-004 | Webhook stores payload before signature verification | RESOLVED — middleware verifies first |
| SEC-PAY-008 | Webhook behind auth:sanctum → 401 | RESOLVED — webhook routes have no auth middleware |
| SEC-PAY-005/006 | PaymentGatewayController + PaymentCallbackController empty stubs | PARTIALLY RESOLVED — PaymentGatewayController is now full CRUD; no PaymentCallbackController (replaced by PaymentController.callback()) |
| BUG-PAY-001 | Duplicate PaymentController copy.php class collision | RESOLVED — copy.php deleted |

---

*End of audit. Report written: 2026-06-29. Auditor: pa-technical-auditor (Mode X).*
*App path: `/Users/bkwork/Herd/prime_ai/Modules/Payment/`*
*FRD: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/0-FRD_Documents/PAY_FRD_Complete_2026-06-29.md`*
*Module Knowledge: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/module-knowledge/PAY_Payment.md`*
