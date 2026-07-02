# Module Knowledge — Payment (PAY)
> Source: Live code audit 2026-06-29 | Agent: pa-business-analyst
> All counts verified against: `/Users/bkwork/Herd/prime_ai/Modules/Payment/`

---

## Module Facts

| Field | Value |
|-------|-------|
| Module Name | Payment |
| Module Code | PAY |
| Module Type | Tenant (runs on tenant domain, accesses tenant_db) |
| Table Prefix | `ptm_*` (actual in code; V2 req prescribed `pay_*` — deviation noted) |
| Route Prefix | `/payment/` (web), `/api/v1/payments` (API), `/payment/webhooks/` (webhooks) |
| Laravel Module Path | `Modules/Payment/` |
| DDL Status | 7 tables via migrations (2026-06-18 series); no standalone DDL file |
| Module Prefix in CLAUDE.md | `pmt_` listed; code actually uses `ptm_` (reversed characters) |
| Controllers | 4 |
| Models | 8 |
| Services | 4 |
| FormRequests | 3 |
| Views | 9 |
| Events | 8 |
| Jobs | 1 |
| Gateways (drivers) | 6 (Razorpay, Offline, BillDesk, CCAvenue, Paytm, PhonePe) |
| Middleware | 1 (VerifyWebhookSignature) |
| Contracts | 2 (Payable, PaymentGatewayInterface) |
| DTO | 1 (PaymentData) |
| Tests | 11 files (2 Feature, 9 Unit) — modules-map says 8; 3 added since 2026-06-21 audit |
| Seeders | 1 (PaymentDatabaseSeeder — stub) |
| Completion | ~65–70% |
| FRD Status | Generated 2026-06-29 |

---

## DDL Table Inventory (7 ptm_* tables — all tenant_db)

| Table | Purpose | Key Columns | Notes |
|-------|---------|-------------|-------|
| `ptm_payment_gateways` | Gateway configuration per school | name, code (unique), driver (FQCN), credentials (encrypted text), extra_config (JSON), type (online/offline), supported_modules (JSON), priority, is_active, is_test_mode | SoftDeletes; credentials column is TEXT (not JSON) because value is Laravel-encrypted blob |
| `ptm_payments` | Primary payment record | ulid (unique), payable_type, payable_id, gateway_id FK, amount DECIMAL(12,2), currency, status ENUM(pending/initiated/success/failed/cancelled/refunded), gateway_order_id, gateway_payment_id, gateway_signature, failure_reason, metadata (JSON), paid_at, is_active, initiated_by FK, created_by FK | SoftDeletes; polymorphic payable; rebuilt by migration 100102 |
| `ptm_payment_refunds` | Refund records per payment | ulid, payment_id FK, gateway_refund_id, amount DECIMAL(12,2), reason, status ENUM(pending/processing/success/failed), initiated_by FK, metadata (JSON), refunded_at, is_active, created_by FK | SoftDeletes |
| `ptm_payment_audit_logs` | Immutable payment event log | payment_id FK, event, from_status, to_status, actor_type, actor_id, payload (JSON), ip_address, user_agent, created_at | Append-only — NO SoftDeletes, NO updated_at; bigInt PK for high-volume |
| `ptm_payment_webhooks` | Inbound gateway webhook store | gateway, event_type, idempotency_key (unique), payload (JSON), signature_valid, processed, processed_at, error_message, is_active, created_by | SoftDeletes; fixed from `pmt_payment_webhooks` typo |
| `ptm_offline_payment_records` | Cash/cheque/DD/bank/UPI manual records | payment_id FK, mode ENUM(cash/cheque/bank_transfer/demand_draft/upi_manual), reference_number, bank_name, cheque_date, clearance_status ENUM(pending/cleared/bounced), collected_at, cheque_bounce_at, collected_by FK, receipt_number (unique), notes | SoftDeletes |
| `ptm_payment_reconciliations` | Gateway settlement reconciliation | gateway_id FK (bigint), date, expected_amount, settled_amount, discrepancy (PHP-computed), status ENUM(pending/matched/discrepant/resolved), bank_statement_json, resolved_by FK, notes | Unique per gateway+date; SoftDeletes |

**Dead table:** `ptm_payment_histories` — dropped by migration 100102. `PaymentHistory` model still references this non-existent table. P0 gap.

---

## Controller Inventory

| Controller | Key Actions | Route File | Auth |
|-----------|------------|-----------|------|
| PaymentController | initiate(), callback(), cancel(), show() | api.php (but `apiResource` mapping is misaligned) | auth:sanctum |
| PaymentGatewayController | Full CRUD + trash/restore/forceDelete/toggleStatus | web.php | auth (web) |
| RefundController | store(), index() | NOT ROUTED — no routes defined for RefundController | — |
| WebhookController | razorpay() — store + queue ProcessWebhookJob | webhooks.php | NO auth (HMAC only) |

---

## Service Inventory

| Service | Responsibility |
|---------|---------------|
| PaymentService | Payment lifecycle: initiate(), markSuccess(), markFailed(), cancel(), getByUlid() |
| RefundService | Refund lifecycle: initiate(), markRefundSuccess(), markRefundFailed(), getRefundsForPayment() |
| GatewayManager | Resolves gateway driver by code from DB; instantiates with decrypted credentials |
| AuditService | Append-only audit log: log(), logStatusChange(), logWebhook(), getTimeline() |

---

## Gateway Driver Inventory

| Driver Class | Protocol | Implementation Status |
|-------------|---------|----------------------|
| RazorpayGateway | Razorpay Orders API + Checkout.js | Fully implemented; HMAC-SHA256 sig verify |
| OfflineGateway | Manual cash/cheque/DD/bank/UPI | Fully implemented; creates offline reference |
| BillDeskGateway | BillDesk v1.5 pipe-separated form-post | Implemented (HMAC-SHA256 checksum) |
| CCAvenueGateway | CCAvenue AES-128 encrypted form-post | Implemented |
| PaytmGateway | Paytm txnToken REST API | Implemented |
| PhonePeGateway | PhonePe S2S redirect + SHA256+salt | Implemented |

Only Razorpay is exposed in `getAvailableDrivers()` in PaymentGatewayController. Other gateways are fully implemented but not selectable through the UI (P1 gap).

---

## Known Gaps & Open Issues

### P0 — Critical / Production Blockers

| ID | Issue | Evidence |
|----|-------|----------|
| GAP-PAY-P0-01 | Dead PaymentHistory model — `ptm_payment_histories` table was dropped by migration 100102 but PaymentHistory.php still references it. Any code using PaymentHistory will throw "Table not found". | Migration: `Schema::dropIfExists('ptm_payment_histories')` |
| GAP-PAY-P0-02 | RefundController has no routes — `store()` and `index()` are unreachable. Refund feature is built but cannot be accessed. | Neither web.php, api.php, nor webhooks.php route to RefundController |
| GAP-PAY-P0-03 | PaymentController `apiResource` mismatch — `api.php` registers `Route::apiResource('payments', PaymentController::class)` but controller has `initiate/callback/cancel/show` not standard `index/store/update/destroy`. Only `show` maps correctly. | api.php vs PaymentController.php method names |
| GAP-PAY-P0-04 | No PaymentPolicy class — `makePayment()` has `$this->authorize('initiate', $payable)` which requires a policy on the payable model, not on Payment. No PaymentPolicy.php exists. Authorization is unverifiable. | `ls Modules/Payment/` — no Policies/ dir |

### P1 — High / Required Before Beta

| ID | Issue | Evidence |
|----|-------|----------|
| GAP-PAY-P1-01 | EnsureTenantHasModule not applied — RSP middleware stack has web + tenancy + auth but not module licensing check. Any tenant can access payment routes regardless of plan. | RouteServiceProvider.php — no EnsureTenantHasModule |
| GAP-PAY-P1-02 | UI exposes only Razorpay — getAvailableDrivers() returns only RazorpayGateway FQCN. BillDesk, CCAvenue, Paytm, PhonePe drivers are implemented but hidden from admin UI. | PaymentGatewayController::getAvailableDrivers() |
| GAP-PAY-P1-03 | No views for refund management, webhook logs, payment detail page, receipt download — 4 functional areas have backend logic but no UI. | resources/views/ listing |
| GAP-PAY-P1-04 | ReconciliationController missing — PaymentReconciliation model exists with 4-state FSM and computeDiscrepancy() but no controller or routes. | Modules/Payment/ — no ReconciliationController.php |
| GAP-PAY-P1-05 | OfflinePaymentRecord write path missing — OfflineGateway creates reference IDs but no code path writes to ptm_offline_payment_records. Model and gateway exist; no service method connects them. | OfflineGateway.php initiate() returns mock data; no OfflinePaymentRecord::create() call anywhere |

### P2 — Medium / Required Before GA

| ID | Issue | Evidence |
|----|-------|----------|
| GAP-PAY-P2-01 | PDF receipt generation not implemented — PaymentSucceeded event dispatched but EventServiceProvider.$listen is empty (uses auto-discovery). No receipt listener built yet. | EventServiceProvider.php: $listen = [] |
| GAP-PAY-P2-02 | No event listeners wired — PaymentSucceeded, PaymentFailed, RefundSucceeded are dispatched but no listeners consume them. Fee invoice not marked paid. No notifications sent. | EventServiceProvider.php: $listen = [] |
| GAP-PAY-P2-03 | Gateway record caching absent — GatewayManager queries DB on every payment initiation. No Cache::remember(). | GatewayManager::resolve() — DB query every call |
| GAP-PAY-P2-04 | Table prefix inconsistency — V2 requirement prescribed `pay_*`; actual code uses `ptm_*`. Minor but affects cross-module documentation and FRD handoffs. | All 7 tables use ptm_* |
| GAP-PAY-P2-05 | PaymentGatewayRequest hardcodes table name `ptm_payment_gateways` — correct for current state but should be config-driven to survive a prefix rename. | PaymentGatewayRequest.php line 22 |

---

## Design Decisions Made

| Decision | Detail |
|----------|--------|
| Table prefix `ptm_*` (not `pay_*`) | V2 req prescribed `pay_*`, but implementation used `ptm_*`. Do not rename without a migration and model update pass. |
| Credentials stored as encrypted TEXT | `PaymentGateway.credentials` cast as `encrypted:array`. Column type is TEXT (not JSON) because encrypted blob is not valid JSON. |
| Webhook processing: store-then-queue | WebhookController stores raw payload to `ptm_payment_webhooks` FIRST, then dispatches `ProcessWebhookJob`. Returns HTTP 200 immediately. This prevents Razorpay retry storms. |
| Polymorphic Payable via interface | Any model implementing `Payable` contract can accept payments. PaymentService calls `getPayableAmount()`, `getPayableLabel()`, `getPayableCustomer()`, `getPayableMetadata()`. |
| ULID as public payment identifier | Both `ptm_payments.ulid` and `ptm_payment_refunds.ulid` use ULID (not ID) as the externally-facing identifier. This prevents ID enumeration attacks. |
| Audit log: immutable append-only | `ptm_payment_audit_logs` has no `updated_at`, no `deleted_at`, no SoftDeletes. Once a row is inserted it cannot be modified. |
| Refund amount check in PHP | `RefundService.initiate()` checks `amount > payment->amount` in PHP before calling gateway API. Additional constraint: total prior successful refunds not checked (gap — should sum prior refunds). |
| Discrepancy computed in PHP | `PaymentReconciliation::computeDiscrepancy()` computes `expected - settled` in PHP (not a DB generated column). Must call before save. |

---

## Cross-Module Dependencies

**Inbound (modules that call into Payment):**
| Source | What | How |
|--------|------|-----|
| StudentFee | FeeInvoice initiates payment | Implements Payable interface; passes payable_type=FeeInvoice to payment initiation |
| Cafeteria | MealCard top-up initiates payment | Implements Payable interface (planned) |
| Library | LibFine initiates payment | Implements Payable interface (planned) |
| Hostel | HostelFee initiates payment | Implements Payable interface (future) |

**Outbound (Payment calls into):**
| Target | What | Mechanism |
|--------|------|-----------|
| StudentFee | Mark fee invoice as paid | PaymentSucceeded event → FeeInvoicePaymentListener (NOT YET BUILT — GAP) |
| Notification | Receipt notification to parent/student | PaymentSucceeded event → PaymentNotificationListener (NOT YET BUILT — GAP) |
| Accounting | Record receipt voucher in acc_vouchers | PaymentSucceeded event → AccountingVoucherListener (NOT YET BUILT — GAP) |
| SchoolSetup / StudentProfile | Customer details for checkout prefill | Payable::getPayableCustomer() resolves student name/email/phone |
| sys_users | created_by, initiated_by FKs | All payment tables reference sys_users.id |
| sys_activity_logs | Activity logging in GatewayController | activityLog() helper |

---

## Lessons Learned

- [2026-06-29 | pa-business-analyst] Payment module was listed at ~45% in V2 req doc (dated 2026-03-26) with "no DDL". By 2026-06-29, DDL exists (7 tables), credential encryption is implemented, webhook route is correctly outside auth, and 6 gateway drivers are built. Always verify against live code — V2 docs lag by months.
- [2026-06-29 | pa-business-analyst] The `ptm_payment_histories` table was dropped by migration 100102 but PaymentHistory model still references it — this is a dead model creating a P0 table-not-found error. Always reconcile DDL ↔ migration ↔ model three-way when seeding knowledge.
- [2026-06-29 | pa-business-analyst] Table prefix `ptm_*` (not `pay_*` and not `pmt_*`) — the actual prefix has characters `t` and `m` transposed compared to the module abbreviation `pmt`. This creates confusion in documentation. The canonical truth is the model `$table` property.
- [2026-06-29 | pa-business-analyst] 11 test files exist (not 8 per modules-map). The modules-map is audited periodically — always recount from the filesystem for accuracy. The 3 extra are AuditServiceTest, OfflineGatewayTest, PaymentStatusConstantsTest (added after 2026-06-21).

---

## Pending Next Steps

1. **Fix P0 gaps** before any beta testing:
   - Resolve dead PaymentHistory model (either drop model + update references, or restore table)
   - Wire RefundController to routes
   - Fix PaymentController apiResource mismatch (or switch to named routes matching controller methods)
   - Create PaymentPolicy for authorization

2. **Technical Audit** — hand off to pa-technical-auditor (Mode X) for:
   - Security layers: missing EnsureTenantHasModule; no refund over-refund prevention across multiple refunds; event listeners missing (PaymentSucceeded fires into void)
   - DB audit: ptm_payments FK on initiated_by sys_users; test mode flag behavior
   - Test coverage: existing 11 tests need verification they actually run

3. **FRD is complete** — downstream:
   - DB Architect: define PTM table DDL in 0-DDL_Masters if needed
   - Developer: build missing views (refund, webhook logs, payment detail, receipt)
   - Developer: wire event listeners (PaymentSucceeded → fee update + notification + voucher)
   - Developer: implement OfflinePaymentRecord write path in OfflineGateway

---

## Version History

| Date | Agent | Change |
|------|-------|--------|
| 2026-06-29 | pa-business-analyst | Initial seed — live code audit; verified all counts; identified 7 ptm_* tables, 11 test files, dead PaymentHistory model, missing RefundController routes, 6 gateway drivers |
