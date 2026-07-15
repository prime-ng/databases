# bil_GatewayIntegration — Manual Test Specification

**Status:** 🚧 **PLANNING-STAGE / NOT IMPLEMENTED.** The steps below are the **intended** manual verifications for when the feature is built. Today, only the "Reality check" (MT-R01) is executable; every other case is **BLOCKED — feature not built**.

---

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | Billing (`BIL`, prefix `bil_`) |
| Feature / Screen | GatewayIntegration (Payment Gateway Integration — Razorpay) |
| DB scope | PRIME / CENTRAL (would be) |
| Primary table (hook) | `bil_tenant_invoicing_payments` (column `gateway_response` JSON, nullable, **unused**) |
| Related tables | `bil_tenant_invoices`, `bil_tenant_invoicing_audit_logs` |
| Controller | **None** (planned: `GatewayIntegrationController` / a webhook controller) |
| Models | `Modules\Billing\Models\InvoicingPayment` (existing); no gateway model |
| Routes | **None** (planned: `POST /api/v1/billing/payment/initiate`, `/payment/verify`, `/webhook/razorpay`) |
| Validation | **None** (planned FormRequest for credentials + amount + currency) |
| Migrations | Only the pre-existing `gateway_response` column; **no gateway-config migration** |
| SDK / Config | `razorpay/razorpay ^2.9` in `composer.json`; `config/services.php` `razorpay` stub (`key`, `secret`, `webhook_secret` — env-driven, unset) |
| CRUD Type | N/A (planning stage) |
| Soft Delete | N/A |
| Pagination | N/A |
| Activity Log | Planned: `bil_tenant_invoicing_audit_logs` entry on `payment.captured` |
| Permissions (planned) | `prime.invoicing-payment.create`, `prime.invoicing-audit-log.viewAny` |
| **Current implementation status** | **0% — no code. Behavioural coverage 100% deferred.** |

---

## 2. Business Conditions (detailed, planned)

**Webhook Security (Critical)**
- Razorpay webhook endpoint MUST NOT be behind `auth` middleware (server-to-server, no user session).
- HMAC signature verification using the `X-Razorpay-Signature` header and `razorpay.webhook_secret` config.
- Signature verification failure → **HTTP 400** (not 401/403, which leaks auth info).

**Webhook Event Handling — `payment.captured` flow (planned):**
```
payment.captured
  → find invoice by payment_id in gateway_response
  → create InvoicingPayment (mode=ONLINE, payment_status=SUCCESS, gateway_response=raw)
  → invoice.paid_amount += amount_paid
  → create bil_tenant_invoicing_audit_logs entry
  → payment_reconciled = 1
```
- `payment.failed` / `order.paid` → logged only, no invoice mutation.

**Planned validation error messages** (indicative — confirm against the real FormRequest once built): "The key id field is required.", "The key secret field is required.", "The webhook secret field is required.", "The currency must be a valid 3-letter code.", "The amount must be greater than 0."

---

## 3. Test Cases (step-by-step)

### MT-R01 — Reality / gap check (EXECUTABLE NOW)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `Billing_DDL_v1.sql`. | `bil_tenant_invoicing_payments.gateway_response` JSON column exists (nullable); **no** `bil_payment_gateways`/`bil_gateway_configs` table. |
| 2 | List `Modules/Billing/app/Http/Controllers/`. | No `GatewayIntegrationController` / `RazorpayController` / webhook controller. |
| 3 | Grep `Modules/Billing/routes/*.php` for `razorpay|webhook|payment/initiate`. | No matching route. |
| 4 | Inspect `composer.json` and `config/services.php`. | Razorpay SDK `^2.9` present; `services.razorpay` stub present (env unset). |
| 5 | **DB check:** `SELECT COUNT(*) FROM bil_tenant_invoicing_payments WHERE gateway_response IS NOT NULL;` | Expect `0` — the column is currently unused. |
| 6 | Run `test_gateway_integration_01_planning_stage_reality_gap_is_documented`. | **PASS** — the gap is proven; other 38 tests report **SKIPPED**. |

### MT-P15 — payment.captured creates a payment (BLOCKED — feature not built)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST a signed `payment.captured` payload to `/api/v1/billing/webhook/razorpay`. | HTTP 200. |
| 2 | **DB check:** `SELECT * FROM bil_tenant_invoicing_payments WHERE transaction_id = '<razorpay_payment_id>';` | One new row: `mode=ONLINE`, `payment_status=SUCCESS`, `payment_reconciled=1`, `gateway_response` = raw payload. |
| 3 | **DB check:** `SELECT paid_amount FROM bil_tenant_invoices WHERE id=<invoice_id>;` | Increased by `amount_paid`. |
| 4 | **Activity-log check:** `SELECT * FROM bil_tenant_invoicing_audit_logs WHERE tenant_invoicing_id=<id> ORDER BY id DESC LIMIT 1;` | New entry recording the captured payment (`performed_by` NULL for webhook). |

### MT-S92 — Invalid signature → HTTP 400 (BLOCKED — feature not built)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST a webhook payload with a wrong/missing `X-Razorpay-Signature`. | **HTTP 400** (not 401/403). |
| 2 | **DB check:** payments + invoice rows unchanged. | No new payment; no `paid_amount` change. |

### MT-A50 — initiate-payment permission gate (BLOCKED — feature not built)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | As a user WITHOUT `prime.invoicing-payment.create`, POST `/api/v1/billing/payment/initiate`. | HTTP 403. |
| 2 | As a user WITH the permission, repeat. | HTTP 200; Razorpay order created, `order_id` returned. |

> The remaining planned cases (config CRUD, test-connection, state machine, validation, multi-currency, idempotency, tenancy IDOR) follow the same pattern — each is documented as a skipped stub in `bil_GatewayIntegration_TestCas.php` and is **BLOCKED** until the feature is implemented.
