# bil_GatewayIntegration — Test Case List & Business Conditions

**Module:** Billing (`BIL`, prefix `bil_`)
**Feature / Screen:** GatewayIntegration (Payment Gateway Integration — Razorpay)
**Screen requirement:** `4-Requirement_Module_wise/2-Module_Requirement_V1/Billing_v1/gateway-integration.md`
**DB scope:** PRIME / CENTRAL (would be, when built) — no tenant scaffolding
**Status:** 🚧 **PLANNING-STAGE / NOT IMPLEMENTED** — zero application code. 100% of behavioural coverage is **deferred (skipped)**.
**Test file:** `bil_GatewayIntegration_TestCas.php` (extends `BillingDuskTestCase`, `Tests\Browser\Modules\Prime\Billing\GatewayIntegration`)

> **Why this set is stubs, not assertions.** Verified in source on 2026-Jul-10:
> no gateway/webhook table in `Billing_DDL_v1.sql` (only a pre-provisioned,
> unused `gateway_response` JSON column on `bil_tenant_invoicing_payments`);
> no `GatewayIntegrationController`/`RazorpayController`/webhook controller;
> no razorpay/webhook/payment-initiate/verify routes in `web.php`/`api.php`.
> The Razorpay SDK (`razorpay/razorpay ^2.9`) is in `composer.json` and a
> `config/services.php` `razorpay` stub exists, but neither is wired.
> Audit `REQ-BIL-014` (Gateway) = "Not started (future)".
> Only **`test_01`** asserts (it proves the gap); every planned-behaviour method
> documents its intended assertion in a comment, then `markTestSkipped(...)`.

---

## 1. Business Conditions

Each BC below is **planned** (the truth the feature WILL enforce once built). Only `BC-DB-01` and the "gap" facts are currently assertable — the rest are traced by skipped stubs.

### BC-DB — Database (from `Billing_DDL_v1.sql`)

| ID | Condition | Source | Assertable now? |
|----|-----------|--------|-----------------|
| BC-DB-01 | `bil_tenant_invoicing_payments.gateway_response` is a **nullable JSON** column, currently unused (the only DB hook that exists). | DDL-`bil_tenant_invoicing_payments` (L73) | ✅ (test_01) |
| BC-DB-02 | No dedicated gateway-config table exists (no `bil_payment_gateways`/`bil_gateway_configs`/etc.). | DDL (absence) | ✅ (test_01) |
| BC-DB-03 | `payment_status` uses ENUM-like values `INITIATED / SUCCESS / FAILED`; `mode` default `ONLINE`; `currency` `CHAR(3)` default `INR`; `payment_reconciled` `tinyint(1)` default 0. | DDL-`bil_tenant_invoicing_payments` | ⏭ planned |
| BC-DB-04 | Payment → invoice FK (`tenant_invoice_id` → `bil_tenant_invoices`) `ON DELETE CASCADE`. | DDL-`bil_tenant_invoicing_payments` | ⏭ planned |

### BC-BIZ — Business rules (planned)

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | `payment.captured` → find invoice by `payment_id` in `gateway_response` → create `InvoicingPayment` → update `invoice.paid_amount` → create audit log → set `payment_reconciled = 1`. | Screen-BR (Webhook Event Handling) |
| BC-BIZ-02 | `payment.failed` / `order.paid` → logged only, **no invoice mutation**. | Screen-BR (Webhook Event Handling) |
| BC-BIZ-03 | Gateway config CRUD (store/update/view/delete) with secrets stored securely and masked on read. | Screen-BR (Future CRUD) |
| BC-BIZ-04 | Test-connection validates stored credentials against Razorpay. | Screen-BR (Future CRUD) |

### BC-SM — State-machine transitions (planned)

| ID | State → Trigger → Next | Source |
|----|------------------------|--------|
| BC-SM-01 | payment `INITIATED` → payment.captured → `SUCCESS` | Screen-BR |
| BC-SM-02 | payment `INITIATED` → payment.failed → `FAILED` | Screen-BR |
| BC-SM-03 | gateway `DISCONNECTED` → test-connection ok → `CONNECTED` | Screen-BR (state) |
| BC-SM-04 | gateway `CONNECTED` → auth/network failure → `ERROR` | Screen-BR (state) |
| BC-SM-05 | gateway `ERROR` → successful retry → `CONNECTED` | Screen-BR (state) |

### BC-VAL — Validation (planned)

| ID | Rule | Source |
|----|------|--------|
| BC-VAL-01 | `key_id` required. | Screen-VR |
| BC-VAL-02 | `key_secret` required (never logged). | Screen-VR |
| BC-VAL-03 | `webhook_secret` required (needed for HMAC verify). | Screen-VR |
| BC-VAL-04 | `currency` must be a valid 3-char ISO code. | DDL + Screen-VR |
| BC-VAL-05 | initiate-payment `amount` must be > 0. | Screen-VR |

### BC-INT — Integration points (planned)

| ID | Condition | Source |
|----|-----------|--------|
| BC-INT-01 | Created payment links to an existing `bil_tenant_invoices` row. | Screen-IP + DDL FK |
| BC-INT-02 | Unmatched `payment_id` → no payment row; logged as anomaly. | Screen-BR |
| BC-INT-03 | Raw webhook payload persisted into `gateway_response` JSON verbatim. | Screen-BR + DDL |
| BC-INT-04 | `payment.captured` writes a `bil_tenant_invoicing_audit_logs` entry. | Screen-BR + DDL |

### BC-AUTH — Permissions (planned)

| ID | Operation | Permission Key | Source |
|----|-----------|----------------|--------|
| BC-AUTH-01 | Initiate online payment | `prime.invoicing-payment.create` | Screen-PM |
| BC-AUTH-02 | View webhook logs | `prime.invoicing-audit-log.viewAny` | Screen-PM |
| BC-AUTH-03 | Guest cannot initiate payment (redirect to /login). | Screen-PM (implied) |

### BC-CFG — Configuration (planned)

| ID | Condition | Source |
|----|-----------|--------|
| BC-CFG-01 | Razorpay keys read from `config('services.razorpay')` (`key`, `secret`, `webhook_secret`) — stub present, unwired. | `config/services.php` (verified) |

### BC-SEC / Tenancy — Security (planned, critical)

| ID | Condition | Source |
|----|-----------|--------|
| BC-SEC-01 | Webhook route MUST NOT be behind `auth` middleware (server-to-server). | Screen-BR (Webhook Security) |
| BC-SEC-02 | Webhook uses HMAC verification via `X-Razorpay-Signature` + `razorpay.webhook_secret`. | Screen-BR (Webhook Security) |
| BC-SEC-03 | Signature failure → **HTTP 400** (not 401/403, which leaks auth info). | Screen-BR (Webhook Security) |
| BC-SEC-04 | A webhook mutates only its own tenant's invoice (no cross-tenant write). | Screen-BR (implied) |
| BC-SEC-05 | Stored `gateway_response` for tenant A is never readable by tenant B (IDOR guard). | Screen-BR (implied) |

---

## 2. Test Case List

**Legend — Status:** `REALITY` = assertive (proves the gap); `DEFERRED` = `markTestSkipped()` planning stub.

### Reality / Gap truth

| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-R01 | Config-truth | BC-DB-01/02, BC-CFG-01 | DDL + source | Prove planning-stage gap | `gateway_response` col present; no gateway table/controller/route; SDK+config recorded (informational) | `test_gateway_integration_01_planning_stage_reality_gap_is_documented` | REALITY |

### Positive / Business (deferred)

| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-P10 | Positive | BC-BIZ-03 | Screen-BR | Store gateway config | Row persisted, secrets encrypted | `..._10_gateway_config_can_be_stored` | DEFERRED |
| TC-P11 | Positive | BC-BIZ-03 | Screen-BR | Update gateway config | Credentials rotated | `..._11_gateway_config_can_be_updated` | DEFERRED |
| TC-P12 | Positive | BC-BIZ-03 | Screen-BR | View gateway config | Secrets masked | `..._12_gateway_config_can_be_viewed` | DEFERRED |
| TC-P13 | Positive | BC-BIZ-03 | Screen-BR | Delete/disable config | Gateway disconnected | `..._13_gateway_config_can_be_deleted` | DEFERRED |
| TC-P14 | Positive | BC-BIZ-04 | Screen-BR | Test connection | Success→connected / fail→error | `..._14_test_connection_validates_credentials` | DEFERRED |
| TC-P15 | Positive | BC-BIZ-01 | Screen-BR | payment.captured creates payment | InvoicingPayment row created | `..._15_webhook_payment_captured_creates_invoicing_payment` | DEFERRED |
| TC-P16 | Positive | BC-BIZ-01 | Screen-BR | payment.captured updates invoice | invoice.paid_amount incremented | `..._16_webhook_payment_captured_updates_invoice_paid_amount` | DEFERRED |
| TC-P17 | Positive | BC-BIZ-01 | Screen-BR | payment.captured sets reconciled | payment_reconciled = 1 | `..._17_webhook_payment_captured_sets_payment_reconciled` | DEFERRED |
| TC-P18 | Positive | BC-BIZ-02 | Screen-BR | payment.failed logs only | No invoice mutation | `..._18_webhook_payment_failed_logs_without_invoice_mutation` | DEFERRED |
| TC-P19 | Positive | BC-BIZ-02 | Screen-BR | order.paid logs only | No invoice mutation | `..._19_webhook_order_paid_logs_without_invoice_mutation` | DEFERRED |

### State-machine (deferred)

| TC ID | Category | BC | Source | Description | Test Method | Status |
|-------|----------|----|--------|-------------|-------------|--------|
| TC-SM20 | SM | BC-SM-01 | Screen-BR | INITIATED→SUCCESS | `..._20_payment_status_initiated_to_success_transition` | DEFERRED |
| TC-SM21 | SM | BC-SM-02 | Screen-BR | INITIATED→FAILED | `..._21_payment_status_initiated_to_failed_transition` | DEFERRED |
| TC-SM22 | SM | BC-SM-03 | Screen-BR | DISCONNECTED→CONNECTED | `..._22_gateway_state_disconnected_to_connected` | DEFERRED |
| TC-SM23 | SM | BC-SM-04 | Screen-BR | CONNECTED→ERROR | `..._23_gateway_state_connected_to_error` | DEFERRED |
| TC-SM24 | SM | BC-SM-05 | Screen-BR | ERROR→CONNECTED (retry) | `..._24_gateway_state_error_to_connected_on_retry` | DEFERRED |

### Negative / Validation (deferred)

| TC ID | Category | BC | Source | Description | Test Method | Status |
|-------|----------|----|--------|-------------|-------------|--------|
| TC-N30 | Negative | BC-VAL-01 | Screen-VR | key_id required | `..._30_credential_key_id_is_required` | DEFERRED |
| TC-N31 | Negative | BC-VAL-02 | Screen-VR | key_secret required | `..._31_credential_key_secret_is_required` | DEFERRED |
| TC-N32 | Negative | BC-VAL-03 | Screen-VR | webhook_secret required | `..._32_webhook_secret_is_required` | DEFERRED |
| TC-N33 | Negative | BC-VAL-04 | DDL+VR | currency ISO-3 | `..._33_currency_must_be_valid_iso_code` | DEFERRED |
| TC-N34 | Negative | BC-VAL-05 | Screen-VR | amount > 0 | `..._34_amount_must_be_positive` | DEFERRED |

### Dependency / Integration (deferred)

| TC ID | Category | BC | Source | Description | Test Method | Status |
|-------|----------|----|--------|-------------|-------------|--------|
| TC-D40 | Dependency (C) | BC-INT-01 | Screen-IP | Payment links to invoice | `..._40_captured_payment_links_to_existing_invoice` | DEFERRED |
| TC-D41 | Dependency (E) | BC-INT-02 | Screen-BR | Unmatched payment_id rejected | `..._41_unmatched_payment_id_is_rejected` | DEFERRED |
| TC-D42 | Dependency (B) | BC-INT-03 | Screen-BR | gateway_response JSON stored | `..._42_gateway_response_stored_as_json` | DEFERRED |
| TC-D43 | Dependency (E) | BC-INT-04 | Screen-BR | Audit log on capture | `..._43_audit_log_entry_created_on_capture` | DEFERRED |

### Permissions (deferred)

| TC ID | Category | BC | Source | Description | Test Method | Status |
|-------|----------|----|--------|-------------|-------------|--------|
| TC-A50 | AuthZ | BC-AUTH-01 | Screen-PM | initiate needs invoicing-payment.create | `..._50_initiate_payment_requires_invoicing_payment_create_permission` | DEFERRED |
| TC-A51 | AuthZ | BC-AUTH-02 | Screen-PM | logs need invoicing-audit-log.viewAny | `..._51_view_webhook_logs_requires_invoicing_audit_log_viewany_permission` | DEFERRED |
| TC-A52 | AuthZ | BC-AUTH-03 | Screen-PM | guest cannot initiate | `..._52_guest_cannot_initiate_payment` | DEFERRED |

### UI / UX (deferred)

| TC ID | Category | BC | Source | Description | Test Method | Status |
|-------|----------|----|--------|-------------|-------------|--------|
| TC-U60 | UI | BC-BIZ-03 | Screen-BR | Payment-init UI renders | `..._60_payment_initiation_ui_renders` | DEFERRED |
| TC-U61 | UI | BC-BIZ-03 | Screen-BR | Tenant payment page renders | `..._61_tenant_facing_payment_page_renders` | DEFERRED |
| TC-U62 | UI | BC-CFG-01 | Screen-BR | checkout.js loads | `..._62_razorpay_checkout_js_loads` | DEFERRED |

### Edge cases (deferred)

| TC ID | Category | BC | Source | Description | Test Method | Status |
|-------|----------|----|--------|-------------|-------------|--------|
| TC-E70 | Edge | BC-DB-03 | DDL | Multi-currency | `..._70_multi_currency_payment_supported` | DEFERRED |
| TC-E71 | Edge | BC-BIZ-01 | Screen-BR | Duplicate webhook idempotent | `..._71_duplicate_webhook_delivery_is_idempotent` | DEFERRED |
| TC-E72 | Edge | BC-BIZ-02 | Screen-BR | Unknown event ignored | `..._72_webhook_for_unknown_event_is_ignored` | DEFERRED |

### Tenancy & Security (deferred, critical)

| TC ID | Category | BC | Source | Description | Test Method | Status |
|-------|----------|----|--------|-------------|-------------|--------|
| TC-S90 | Security | BC-SEC-01 | Screen-BR | Webhook not behind auth | `..._90_webhook_endpoint_is_not_behind_auth_middleware` | DEFERRED |
| TC-S91 | Security | BC-SEC-02 | Screen-BR | HMAC signature verify | `..._91_webhook_signature_verification_uses_hmac` | DEFERRED |
| TC-S92 | Security | BC-SEC-03 | Screen-BR | Invalid sig → HTTP 400 | `..._92_invalid_signature_returns_http_400` | DEFERRED |
| TC-T93 | Tenancy | BC-SEC-04 | Screen-BR | Own-tenant invoice only | `..._93_webhook_processes_only_its_own_tenant_invoice` | DEFERRED |
| TC-T94 | Tenancy | BC-SEC-05 | Screen-BR | gateway_response IDOR guard | `..._94_stored_gateway_response_is_not_exposed_to_other_tenant` | DEFERRED |

---

## 3. Test Method Index

| # | Method (`test_gateway_integration_*`) | TC Map | Category | Band | Status |
|---|----------------------------------------|--------|----------|------|--------|
| 1 | `01_planning_stage_reality_gap_is_documented` | TC-R01 | Config-truth | 01 | **REALITY (asserts)** |
| 2 | `10_gateway_config_can_be_stored` | TC-P10 | Business | 10–19 | Deferred |
| 3 | `11_gateway_config_can_be_updated` | TC-P11 | Business | 10–19 | Deferred |
| 4 | `12_gateway_config_can_be_viewed` | TC-P12 | Business | 10–19 | Deferred |
| 5 | `13_gateway_config_can_be_deleted` | TC-P13 | Business | 10–19 | Deferred |
| 6 | `14_test_connection_validates_credentials` | TC-P14 | Business | 10–19 | Deferred |
| 7 | `15_webhook_payment_captured_creates_invoicing_payment` | TC-P15 | Business | 10–19 | Deferred |
| 8 | `16_webhook_payment_captured_updates_invoice_paid_amount` | TC-P16 | Business | 10–19 | Deferred |
| 9 | `17_webhook_payment_captured_sets_payment_reconciled` | TC-P17 | Business | 10–19 | Deferred |
| 10 | `18_webhook_payment_failed_logs_without_invoice_mutation` | TC-P18 | Business | 10–19 | Deferred |
| 11 | `19_webhook_order_paid_logs_without_invoice_mutation` | TC-P19 | Business | 10–19 | Deferred |
| 12 | `20_payment_status_initiated_to_success_transition` | TC-SM20 | SM | 20–29 | Deferred |
| 13 | `21_payment_status_initiated_to_failed_transition` | TC-SM21 | SM | 20–29 | Deferred |
| 14 | `22_gateway_state_disconnected_to_connected` | TC-SM22 | SM | 20–29 | Deferred |
| 15 | `23_gateway_state_connected_to_error` | TC-SM23 | SM | 20–29 | Deferred |
| 16 | `24_gateway_state_error_to_connected_on_retry` | TC-SM24 | SM | 20–29 | Deferred |
| 17 | `30_credential_key_id_is_required` | TC-N30 | Validation | 30–39 | Deferred |
| 18 | `31_credential_key_secret_is_required` | TC-N31 | Validation | 30–39 | Deferred |
| 19 | `32_webhook_secret_is_required` | TC-N32 | Validation | 30–39 | Deferred |
| 20 | `33_currency_must_be_valid_iso_code` | TC-N33 | Validation | 30–39 | Deferred |
| 21 | `34_amount_must_be_positive` | TC-N34 | Validation | 30–39 | Deferred |
| 22 | `40_captured_payment_links_to_existing_invoice` | TC-D40 | Integration | 40–49 | Deferred |
| 23 | `41_unmatched_payment_id_is_rejected` | TC-D41 | Integration | 40–49 | Deferred |
| 24 | `42_gateway_response_stored_as_json` | TC-D42 | Integration | 40–49 | Deferred |
| 25 | `43_audit_log_entry_created_on_capture` | TC-D43 | Integration | 40–49 | Deferred |
| 26 | `50_initiate_payment_requires_invoicing_payment_create_permission` | TC-A50 | AuthZ | 50–59 | Deferred |
| 27 | `51_view_webhook_logs_requires_invoicing_audit_log_viewany_permission` | TC-A51 | AuthZ | 50–59 | Deferred |
| 28 | `52_guest_cannot_initiate_payment` | TC-A52 | AuthZ | 50–59 | Deferred |
| 29 | `60_payment_initiation_ui_renders` | TC-U60 | UI | 60–69 | Deferred |
| 30 | `61_tenant_facing_payment_page_renders` | TC-U61 | UI | 60–69 | Deferred |
| 31 | `62_razorpay_checkout_js_loads` | TC-U62 | UI | 60–69 | Deferred |
| 32 | `70_multi_currency_payment_supported` | TC-E70 | Edge | 70–79 | Deferred |
| 33 | `71_duplicate_webhook_delivery_is_idempotent` | TC-E71 | Edge | 70–79 | Deferred |
| 34 | `72_webhook_for_unknown_event_is_ignored` | TC-E72 | Edge | 70–79 | Deferred |
| 35 | `90_webhook_endpoint_is_not_behind_auth_middleware` | TC-S90 | Security | 90–99 | Deferred |
| 36 | `91_webhook_signature_verification_uses_hmac` | TC-S91 | Security | 90–99 | Deferred |
| 37 | `92_invalid_signature_returns_http_400` | TC-S92 | Security | 90–99 | Deferred |
| 38 | `93_webhook_processes_only_its_own_tenant_invoice` | TC-T93 | Tenancy | 90–99 | Deferred |
| 39 | `94_stored_gateway_response_is_not_exposed_to_other_tenant` | TC-T94 | Tenancy | 90–99 | Deferred |

**Totals:** 39 methods = **1 assertive (REALITY)** + **38 deferred (`markTestSkipped`)**. Expected run: 1 passed, 38 skipped, 0 failed.

---

## 4. Known Requirement Gap (DEV / audit-equivalent)

| ID | Type | Description | Evidence | Proving artifact |
|----|------|-------------|----------|------------------|
| REQ-BIL-014 | **Unbuilt requirement (DEV/gap)** | Payment Gateway Integration (Razorpay) is entirely unimplemented — no table, controller, route, webhook, UI, or config wiring. | `gateway-integration.md` Current-State table; audit `Billing_Complete_Audit_2026-06-29.md` L382 ("Gateway … Not started (future)"); source verification 2026-Jul-10. | `test_gateway_integration_01_*` (asserts the gap); all 38 stubs enumerate the deferred behaviour. |
