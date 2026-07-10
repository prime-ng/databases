# Payment Gateway Integration (Razorpay) — Test Case List & Business Conditions

**Module:** Billing (BIL) · **Feature:** GatewayIntegration · **Prefix:** `bil_`
**Primary table:** `bil_tenant_invoicing_payments` (`gateway_response` JSON column, DDL line 73)
**DB scope:** `prime_db` (central Prime-layer SaaS invoicing) — **NO tenant init**
**Test style:** browser Dusk, central base chain `PrimeDuskTestCase → prm_BillingDuskTestCase_TestCas` · User = `App\Models\User`
**Screen source:** `Billing_v1/gateway-integration.md`
**Audit note:** REQ-BIL-014 Gateway = **"Not started (future)"** — full audit `Billing_Complete_Audit_2026-06-29.md`

> **FEATURE STATUS: PLANNED / NOT IMPLEMENTED (zero implementation).** Razorpay SDK
> (`razorpay/razorpay ^2.9`) is installed in the **APP root `composer.json`** but not
> wired. API keys, webhook endpoint, initiation/verify routes, signature verification,
> UI, and multi-currency are all **not built**. This is a **lighter, gap-focused**
> artifact set: current-reality tests assert what is true today; every planned
> contract clause is captured as a documented `markTestSkipped` stub that turns green
> only when the feature is built.

---

## 1. Business Conditions

### BC-DB — Schema (current reality)
| ID | Condition | Source | Status |
|----|-----------|--------|--------|
| BC-DB-01 | `gateway_response` column exists on `bil_tenant_invoicing_payments` | DDL-bil_tenant_invoicing_payments (L73) | Implemented |
| BC-DB-02 | `gateway_response` is `JSON` and nullable | DDL (L73 `JSON DEFAULT NULL`) | Implemented |
| BC-DB-03 | `gateway_response` default is `NULL` (currently unused) | DDL (L73) | Implemented |

### BC-BIZ — Business logic
| ID | Condition | Source | Status |
|----|-----------|--------|--------|
| BC-BIZ-01 | Model casts `gateway_response` to `array` | Model InvoicingPayment `$casts` | Implemented |
| BC-BIZ-02 | `gateway_response` is mass-assignable | Model `$fillable` | Implemented |
| BC-BIZ-03 | Array cast round-trips webhook JSON | Model cast | Implemented |
| BC-BIZ-04 | No webhook controller / handler exists | Modules/Billing (absence) | **Gap — not implemented** |
| BC-BIZ-10 | Webhook endpoint MUST NOT sit behind `auth` middleware | Screen §Webhook Security | **Gap — planned** |
| BC-BIZ-11 | `payment.captured` → match invoice → create payment → update paid_amount → audit → `payment_reconciled=1` | Screen §Webhook Event Handling | **Gap — planned** |
| BC-BIZ-12 | `payment.failed` / `order.paid` logged, no invoice mutation | Screen §Webhook Event Handling | **Gap — planned** |
| BC-BIZ-13 | Raw webhook body persisted verbatim into `gateway_response` | Screen §Webhook Event Handling | **Gap — planned** |
| BC-BIZ-14 | Multi-currency support | Screen §Current State | **Gap — planned** |

### BC-SM — Payment state machine (planned)
| ID | State → Trigger → Next | Source | Status |
|----|------------------------|--------|--------|
| BC-SM-20 | (none) → initiate → Razorpay order created (order_id returned) | Screen §Initiate | **Gap — planned** |
| BC-SM-21 | order → verify(signature ok) → payment captured | Screen §Verify | **Gap — planned** |
| BC-SM-22 | captured → reconcile → `payment_reconciled=1` + audit | Screen §Webhook | **Gap — planned** |
| BC-SM-23 | captured (no matching invoice) → **rejected** (no payment created) | Screen §Webhook (illegal) | **Gap — planned** |

### BC-VAL — Validation / signature (planned)
| ID | Condition | Source | Status |
|----|-----------|--------|--------|
| BC-VAL-01 | No signature-verification code / config today | Modules/Billing (absence) | **Gap — not implemented** |
| BC-VAL-30 | HMAC verify using `X-Razorpay-Signature` + `razorpay.webhook_secret` | Screen §Webhook Security | **Gap — planned** |
| BC-VAL-31 | Invalid signature → HTTP **400** (not 401/403) | Screen §Webhook Security | **Gap — planned** |
| BC-VAL-32 | `/payment/verify` validates payment signature before mutation | Screen §Verify | **Gap — planned** |
| BC-VAL-33 | Missing `X-Razorpay-Signature` header → rejected (400) | Screen §Webhook Security | **Gap — planned** |

### BC-INT — Integration / route registration (current reality)
| ID | Condition | Source | Status |
|----|-----------|--------|--------|
| BC-INT-01 | Razorpay SDK present in **root** `composer.json` (`^2.9`) | root composer.json (L22) | Implemented (dep only) |
| BC-INT-02 | `POST /api/v1/billing/payment/initiate` NOT registered | Screen §Future CRUD | **Gap — not implemented** |
| BC-INT-03 | `POST /api/v1/billing/payment/verify` NOT registered | Screen §Future CRUD | **Gap — not implemented** |
| BC-INT-04 | `POST /api/v1/billing/webhook/razorpay` NOT registered | Screen §Webhook Receiver | **Gap — not implemented** |
| BC-INT-05 | Module `routes/api.php` group is empty (no gateway routes) | Modules/Billing/routes/api.php | Implemented (empty) |
| BC-INT-06 | No `Razorpay` usage in any Billing controller | Modules/Billing controllers | **Gap — not implemented** |
| BC-INT-07 | Module `routes/web.php` central group empty of gateway routes | Modules/Billing/routes/web.php | Implemented (empty) |

### BC-AUTH — Permissions (planned; keys already exist)
| ID | Condition | Source | Status |
|----|-----------|--------|--------|
| BC-AUTH-50 | Initiate → `prime.invoicing-payment.create` (key exists) | Screen-PM-1 / InvoicingPaymentController | Key present, flow **Gap** |
| BC-AUTH-51 | View webhook logs → `prime.invoicing-audit-log.viewAny` | Screen-PM-2 | **Gap — planned** |
| BC-AUTH-52 | initiate/verify behind auth; only webhook public | Screen §API Route Registration | **Gap — planned** |

### BC-EDG — Edge / UI absence
| ID | Condition | Source | Status |
|----|-----------|--------|--------|
| BC-EDG-01 | Nested/large webhook JSON survives cast | Model cast | Implemented |
| BC-EDG-02 | No Razorpay checkout.js / `rzp_` UI markers in views | Billing views | **Gap — not implemented** |
| BC-EDG-03 | No "pay online" / `payment/initiate` UI button | Billing views | **Gap — not implemented** |
| BC-EDG-04 | Tenant-facing payment page not built | Screen §Current State | **Gap — planned** |
| BC-EDG-05 | Sibling money columns (`amount_paid`,`currency`,`payment_reconciled`) present | DDL | Implemented |
| BC-EDG-06 | Duplicate webhook idempotent | Screen §Webhook | **Gap — planned** |
| BC-EDG-07 | Empty `gateway_response` reads back as `null` | Model cast | Implemented |

### BC-S — Security pack (planned)
| ID | Condition | Source | Status |
|----|-----------|--------|--------|
| BC-S-90 | Webhook public yet HMAC-protected | Screen §Webhook Security | **Gap — planned** |
| BC-S-91 | Bad signature → 400, no auth-info leak | Screen §Webhook Security | **Gap — planned** |
| BC-S-92 | Forged/replayed webhook rejected | Screen §Webhook Security | **Gap — planned** |
| BC-S-93 | `/verify` cannot update arbitrary invoice (no IDOR) | Screen §Verify | **Gap — planned** |

---

## 2. Test Case List

### Positive (current reality)
| TC ID | Cat | BC | Source | Description | Expected | V1 | V2 |
|-------|-----|----|--------|-------------|----------|----|----|
| TC-P01 | Schema | BC-DB-01 | DDL-L73 | Column exists | `hasColumn` true | 01 | 01 |
| TC-P02 | Schema | BC-DB-02 | DDL-L73 | JSON + nullable | data_type json, nullable YES | 02 | 02 |
| TC-P03 | Schema | BC-DB-03 | DDL-L73 | Default NULL | column_default null | — | 03 |
| TC-P04 | Model | BC-BIZ-01 | Model | Cast to array | casts[gateway_response]=array | 03 | 04 |
| TC-P05 | Model | BC-BIZ-02 | Model | Fillable | contains gateway_response | 04 | 05 |
| TC-P06 | Model | BC-BIZ-03/EDG-01 | Model | Array cast round-trip | array in/out | 05 | 06 |
| TC-P07 | Model | BC-EDG-01 | Model | Nested webhook JSON survives | currency readable | — | 07 |
| TC-P08 | Dep | BC-INT-01 | composer | Razorpay in root composer | contains razorpay/razorpay | 06 | 08 |
| TC-P09 | Schema | BC-EDG-05 | DDL | Sibling money columns present | 3 columns exist | — | 70 |
| TC-P10 | Model | BC-EDG-07 | Model | Empty gateway_response null | null | — | 72 |

### Negative / absence (current reality)
| TC ID | Cat | BC | Source | Description | Expected | V1 | V2 |
|-------|-----|----|--------|-------------|----------|----|----|
| TC-N01 | Route | BC-INT-02 | Screen | initiate route absent | routeUriExists false | 08 | 40 |
| TC-N02 | Route | BC-INT-03 | Screen | verify route absent | false | 09 | 41 |
| TC-N03 | Route | BC-INT-04 | Screen | webhook route absent | false | 10 | 42 |
| TC-N04 | Route | BC-INT-05 | api.php | api.php no gateway routes | not contains | 11 | 43 |
| TC-N05 | Dep | BC-BIZ-04 (DEV-BIL-020) | module composer | razorpay absent from module composer | not contains | 07 | 09 |
| TC-N06 | Code | BC-BIZ-04 | controllers | no webhook controller | absent | 12 | 44 |
| TC-N07 | Config | BC-VAL-01 | config | no razorpay/webhook_secret config | not contains | 13 | 13(V1)/45 |
| TC-N08 | Code | BC-INT-06 | controllers | no Razorpay usage in controllers | not contains | — | 45 |
| TC-N09 | Route | BC-INT-07 | web.php | web.php no gateway routes | not contains | — | 46 |
| TC-N10 | UI | BC-EDG-02 | views | no checkout.js/rzp_ UI | none found | — | 60 |

### Planned-contract stubs (skipped pending implementation)
| TC ID | Cat | BC | Source | Description | Expected | V2 |
|-------|-----|----|--------|-------------|----------|----|
| TC-D01 | Auth | BC-AUTH-50 | Screen-PM-1 | initiate permission flow | key present, flow pending | 50 |
| TC-SM01 | SM | BC-SM-20 | Screen-SM | initiate → order | skipped | 20 |
| TC-SM02 | SM | BC-SM-21 | Screen-SM | verify → captured | skipped | 21 |
| TC-SM03 | SM | BC-SM-22 | Screen-SM | captured → reconciled | skipped | 22 |
| TC-SM04 | SM | BC-SM-23 | Screen-SM | capture w/o invoice rejected | skipped | 23 |
| TC-V30 | Val | BC-VAL-30 | Screen | HMAC verify | skipped | 30 |
| TC-V31 | Val | BC-VAL-31 | Screen | bad sig → 400 | skipped | 31 |
| TC-V32 | Val | BC-VAL-32 | Screen | verify signature | skipped | 32 |
| TC-V33 | Val | BC-VAL-33 | Screen | missing header → 400 | skipped | 33 |
| TC-B10 | Biz | BC-BIZ-10 | Screen | webhook outside auth | skipped | 10 |
| TC-B11 | Biz | BC-BIZ-11 | Screen | payment.captured flow | skipped | 11 |
| TC-B12 | Biz | BC-BIZ-12 | Screen | non-mutating events | skipped | 12 |
| TC-B13 | Biz | BC-BIZ-13 | Screen | raw response persisted | skipped | 13 |
| TC-B14 | Biz | BC-BIZ-14 | Screen | multi-currency | skipped | 14 |
| TC-D02 | Auth | BC-AUTH-51 | Screen-PM-2 | webhook-log view perm | skipped | 51 |
| TC-D03 | Auth | BC-AUTH-52 | Screen | non-webhook behind auth | skipped | 52 |
| TC-U01 | UI | BC-EDG-03 | views | no pay-online button | none found | 61 |
| TC-U02 | UI | BC-EDG-04 | Screen | tenant payment page | skipped | 62 |
| TC-E01 | Edge | BC-EDG-06 | Screen | idempotent webhook | skipped | 71 |
| TC-S01 | Sec | BC-S-90 | Screen | public + HMAC | skipped | 90 |
| TC-S02 | Sec | BC-S-91 | Screen | 400 no leak | skipped | 91 |
| TC-S03 | Sec | BC-S-92 | Screen | forged/replay rejected | skipped | 92 |
| TC-S04 | Sec | BC-S-93 | Screen | verify no IDOR | skipped | 93 |

---

## 3. V2 Test Method Index (42 methods)

| # | Method | TC / BC | Band |
|---|--------|---------|------|
| 1 | 01_gateway_response_column_exists | TC-P01 | 01-09 schema |
| 2 | 02_gateway_response_is_json_and_nullable | TC-P02 | 01-09 |
| 3 | 03_gateway_response_default_is_null | TC-P03 | 01-09 |
| 4 | 04_model_casts_gateway_response_to_array | TC-P04 | 01-09 |
| 5 | 05_gateway_response_is_fillable | TC-P05 | 01-09 |
| 6 | 06_gateway_response_array_cast_round_trip | TC-P06 | 01-09 |
| 7 | 07_gateway_response_stores_nested_webhook_shape | TC-P07 | 01-09 |
| 8 | 08_razorpay_sdk_present_in_root_composer | TC-P08 | 01-09 |
| 9 | 09_razorpay_absent_from_module_composer | TC-N05 | 01-09 |
| 10 | 10_webhook_must_be_outside_auth_middleware | TC-B10 | 10-19 biz |
| 11 | 11_payment_captured_creates_payment_and_updates_invoice | TC-B11 | 10-19 |
| 12 | 12_other_events_logged_without_invoice_mutation | TC-B12 | 10-19 |
| 13 | 13_raw_webhook_response_persisted_to_gateway_response | TC-B13 | 10-19 |
| 14 | 14_multi_currency_support_planned | TC-B14 | 10-19 |
| 15 | 20_initiate_creates_razorpay_order | TC-SM01 | 20-29 SM |
| 16 | 21_verify_confirms_payment_signature_and_captures | TC-SM02 | 20-29 |
| 17 | 22_captured_sets_payment_reconciled | TC-SM03 | 20-29 |
| 18 | 23_captured_without_matching_invoice_is_rejected | TC-SM04 | 20-29 |
| 19 | 30_webhook_hmac_signature_verified | TC-V30 | 30-39 val |
| 20 | 31_bad_signature_returns_http_400 | TC-V31 | 30-39 |
| 21 | 32_verify_endpoint_validates_payment_signature | TC-V32 | 30-39 |
| 22 | 33_missing_signature_header_rejected | TC-V33 | 30-39 |
| 23 | 40_payment_initiate_route_not_registered | TC-N01 | 40-49 int |
| 24 | 41_payment_verify_route_not_registered | TC-N02 | 40-49 |
| 25 | 42_webhook_route_not_registered | TC-N03 | 40-49 |
| 26 | 43_module_api_routes_has_no_gateway_routes | TC-N04 | 40-49 |
| 27 | 44_no_webhook_controller_exists | TC-N06 | 40-49 |
| 28 | 45_no_razorpay_usage_in_controllers | TC-N08 | 40-49 |
| 29 | 46_module_web_routes_have_no_gateway_routes | TC-N09 | 40-49 |
| 30 | 50_initiate_permission_key_exists_in_controller | TC-D01 | 50-59 auth |
| 31 | 51_webhook_log_view_permission_flow_pending | TC-D02 | 50-59 |
| 32 | 52_non_webhook_gateway_routes_behind_auth_planned | TC-D03 | 50-59 |
| 33 | 60_no_razorpay_checkout_ui_in_views | TC-N10 | 60-69 ui |
| 34 | 61_no_pay_online_button_in_views | TC-U01 | 60-69 |
| 35 | 62_tenant_facing_payment_page_not_built | TC-U02 | 60-69 |
| 36 | 70_payment_money_columns_present | TC-P09 | 70-79 edge |
| 37 | 71_duplicate_webhook_is_idempotent_planned | TC-E01 | 70-79 |
| 38 | 72_null_gateway_response_reads_as_null | TC-P10 | 70-79 |
| 39 | 90_webhook_public_but_hmac_protected | TC-S01 | 90-99 sec |
| 40 | 91_bad_signature_does_not_leak_auth_info | TC-S02 | 90-99 |
| 41 | 92_forged_or_replayed_webhook_rejected | TC-S03 | 90-99 |
| 42 | 93_verify_cannot_update_arbitrary_invoice | TC-S04 | 90-99 |

## 4. Known Source Defects (audit-equivalent)
- **REQ-BIL-014 (P?, feature-level)** — Gateway integration = *Not started (future)*. Whole feature is a documented not-implemented gap.
- **DEV-BIL-020 (P3, doc-only)** — Razorpay SDK declared in APP **root** `composer.json`, not scoped into `Modules/Billing/composer.json`. Reality asserted by `..._09_razorpay_absent_from_module_composer`; flip when the SDK is module-scoped.
