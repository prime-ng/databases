# Payment Gateway Integration (Razorpay) — Manual Test Specification

> **PLANNING-STAGE / NOT-IMPLEMENTED FEATURE.** Manual test cases below describe
> both the **current-state truth** (verifiable today) and the **planned contract**
> (marked *PLANNED — pending implementation*; not executable until the feature is
> built). Do not treat "planned" cases as defects; they are the acceptance contract.

## 1. Feature Information
| Field | Value |
|-------|-------|
| Module | Billing (BIL) |
| Feature | GatewayIntegration (Razorpay) |
| Screen requirement | `Billing_v1/gateway-integration.md` |
| DB scope | `prime_db` central (Prime-layer SaaS invoicing) — NO tenant init |
| Primary table | `bil_tenant_invoicing_payments` |
| Key column | `gateway_response JSON DEFAULT NULL` (DDL line 73) |
| Model | `Modules\Billing\Models\InvoicingPayment` (`gateway_response` fillable, cast `array`, SoftDeletes) |
| Controller | **None routed** — planned; Razorpay SDK dependency only |
| Routes (planned) | `POST /api/v1/billing/payment/initiate`, `/verify`, `/webhook/razorpay` (webhook OUTSIDE auth) |
| Dependency | `razorpay/razorpay ^2.9` — in APP **root** `composer.json` (line 22), NOT module composer |
| Validation | None yet (planned HMAC signature verification) |
| Permissions (planned) | `prime.invoicing-payment.create` (initiate), `prime.invoicing-audit-log.viewAny` (webhook logs) |
| Soft delete | Model uses `SoftDeletes` (payments table) |
| Activity log | Domain trail `bil_tenant_invoicing_audit_logs` (planned webhook audit entry) |
| Status | **Not started (future)** — REQ-BIL-014 |

## 2. Business Conditions (detail)

**Webhook Security (critical, planned)**
- Endpoint `POST /api/v1/billing/webhook/razorpay` MUST NOT be behind `auth` middleware (server-to-server, no session).
- MUST verify HMAC using `X-Razorpay-Signature` header + `razorpay.webhook_secret` config.
- On signature failure → **HTTP 400** (NOT 401/403 — avoids leaking auth state).

**Webhook Event Handling (planned)**
```
payment.captured
  └─ find invoice by payment_id in gateway_response
       └─ create InvoicingPayment
            └─ update invoice.paid_amount
                 └─ write bil_tenant_invoicing_audit_logs entry
                      └─ set payment_reconciled = 1
payment.failed / order.paid
  └─ log only — NO invoice mutation
```

**Current-state truth**
- `gateway_response` JSON/nullable column exists and is cast to `array`, fillable — but **unused**.
- No routes, no webhook controller, no signature code, no UI, no razorpay config keys.

## 3. Test Cases

### TC-P01 — gateway_response column exists (current)
| Step | Action | Expected |
|------|--------|----------|
| 1 | DB check | `SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_NAME='bil_tenant_invoicing_payments' AND COLUMN_NAME='gateway_response'` → 1 |

### TC-P02 — gateway_response is JSON + nullable (current)
| Step | Action | Expected |
|------|--------|----------|
| 1 | DB check | `DATA_TYPE` = `json`, `IS_NULLABLE` = `YES`, `COLUMN_DEFAULT` = NULL |

### TC-P04/P05/P06 — model configuration (current)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Inspect `InvoicingPayment::$casts` | `gateway_response => array` |
| 2 | Inspect `$fillable` | contains `gateway_response` |
| 3 | Set `$model->gateway_response = ['event'=>'payment.captured']`; read back | array with `event` key; stored attribute is JSON string |

### TC-P08 / TC-N05 — Razorpay dependency location (current)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Open APP root `composer.json` | contains `"razorpay/razorpay": "^2.9"` |
| 2 | Open `Modules/Billing/composer.json` | does NOT contain `razorpay` (documented gap DEV-BIL-020) |

### TC-N01..N03 — planned routes absent (current)
| Step | Action | Expected |
|------|--------|----------|
| 1 | List registered routes | no URI matching `billing/payment/initiate` |
| 2 | List registered routes | no URI matching `billing/payment/verify` |
| 3 | List registered routes | no URI matching `billing/webhook/razorpay` |
| 4 | Visit `/api/v1/billing/webhook/razorpay` | HTTP 404 (route not defined) |

### TC-N04/N07/N08/N09 — no gateway code/config (current)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Open `Modules/Billing/routes/api.php` | empty `v1` group; no razorpay/webhook |
| 2 | Open `Modules/Billing/config/config.php` | only `['name'=>'Billing']`; no `webhook_secret` |
| 3 | Grep Billing controllers | no `Razorpay` usage; no webhook controller file |

### TC-N10 / TC-U01 — no gateway UI (current)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Grep `Modules/Billing/resources/views` | no `checkout.razorpay.com`, `rzp_`, `payment/initiate`, `pay-online` markers |

### PLANNED — pending implementation (not executable today)
| TC | Action (future) | Expected (acceptance) |
|----|-----------------|-----------------------|
| TC-SM01 | POST initiate with invoice | Razorpay order created; `order_id` returned |
| TC-SM02 | POST verify with valid signature | payment marked captured |
| TC-SM03 | Deliver `payment.captured` webhook | InvoicingPayment created; `invoice.paid_amount` updated; audit entry; `payment_reconciled=1` |
| TC-SM04 | `payment.captured` with unknown invoice | rejected; no payment row |
| TC-V30/31/33 | Deliver webhook with invalid/missing `X-Razorpay-Signature` | HTTP **400**; no mutation |
| TC-B12 | Deliver `payment.failed` | logged; invoice unchanged |
| TC-B10 | Inspect webhook route middleware | NOT behind `auth`; HMAC-guarded |
| TC-S02 | Bad signature | 400 (not 401/403), no auth-info leak |
| TC-S03 | Replay a valid webhook twice | idempotent; single payment |
| TC-S04 | Verify payment for another tenant's invoice | rejected (no IDOR) |
| TC-U02 | Open tenant-facing payment page | (once built) checkout renders |

## 4. Environment Prerequisites
- Billing module ENABLED in `prime_testing/modules_statuses.json` (currently most modules `false` → 404).
- `APP_ENV=testing` for any browser flow (CSRF bypass).
- `prime_ai` cloned alongside the runner (`base_path()` resolves app files: `composer.json`, `Modules/Billing/...`).
