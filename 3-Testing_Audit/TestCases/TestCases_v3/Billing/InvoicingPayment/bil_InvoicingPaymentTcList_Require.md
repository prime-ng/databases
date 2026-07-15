# Invoicing Payment — Test Case List & Business Conditions

- **Module:** Billing (`BIL`) — DB scope: **PRIME / CENTRAL** (`prime_db`)
- **Feature / Screen:** InvoicingPayment (screen file `Billing_v1/invoice-payments.md`)
- **Primary table:** `bil_tenant_invoicing_payments` (prefix `bil_`, Billing_DDL_v1.sql line ~62)
- **Controller:** `Modules\Billing\Http\Controllers\InvoicingPaymentController`
- **FormRequest:** `Modules\Billing\Http\Requests\StoreInvoicePaymentRequest`
- **Model:** `Modules\Billing\Models\InvoicingPayment` (SoftDeletes, HasFactory)
- **Policy:** `Modules\Billing\Policies\InvoicingPaymentPolicy`
- **Test file:** `bil_InvoicingPayment_TestCas.php` (single comprehensive suite, 39 methods)
- **Test base:** `BillingDuskTestCase` (central 127.0.0.1; `authenticateCentral` / `visitAuthenticated` / `centralUrl`)

---

## 1. Business Conditions

### BC-DB (schema / DDL truth) — Source: `DDL-bil_tenant_invoicing_payments`
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `bil_tenant_invoicing_payments` exists with PK `id` (INT UNSIGNED) | DDL-payments |
| BC-DB-02 | `tenant_invoice_id` INT UNSIGNED NOT NULL, FK → `bil_tenant_invoices` | DDL-payments |
| BC-DB-03 | `payment_date` DATE NOT NULL | DDL-payments |
| BC-DB-04 | `transaction_id` VARCHAR(100) NULL | DDL-payments |
| BC-DB-05 | `mode` VARCHAR(20) NOT NULL DEFAULT 'ONLINE' (dropdown key `bil_tenant_invoicing_payments.mode`) | DDL-payments / Screen-BR |
| BC-DB-06 | `mode_other` VARCHAR(20) NULL (**DDL 20 vs FormRequest max:100 mismatch**) | DDL-payments / Req |
| BC-DB-07 | `amount_paid` DECIMAL(14,2) NOT NULL | DDL-payments |
| BC-DB-08 | `consolidated_amount` DECIMAL(14,2) NULL | DDL-payments (change-log) |
| BC-DB-09 | `currency` CHAR(3) NOT NULL DEFAULT 'INR' | DDL-payments |
| BC-DB-10 | `payment_status` VARCHAR(20) NOT NULL DEFAULT 'SUCCESS' | DDL-payments |
| BC-DB-11 | `gateway_response` JSON NULL (model cast `array`) | DDL-payments / Model |
| BC-DB-12 | `payment_reconciled` TINYINT(1) NOT NULL DEFAULT 0 (model cast `boolean`) | DDL-payments / Model |
| BC-DB-13 | `remarks` VARCHAR(255) NULL | DDL-payments |
| BC-DB-14 | **No `deleted_at` column** although model declares `SoftDeletes` → MIG-BIL-001 | DDL-payments / Audit-MIG-BIL-001 |

### BC-VAL (validation) — Source: `StoreInvoicePaymentRequest`
| ID | Rule | Message | Source |
|----|------|---------|--------|
| BC-VAL-01 | `tenant_invoice_id` required + `exists:bil_tenant_invoices,id` | "Invoice is required." / "Selected invoice does not exist." | Screen-VR-1 |
| BC-VAL-02 | `date` required, date | (default) | Screen-VR-2 |
| BC-VAL-03 | `amount_paid` required, numeric, `min:0.01` | "Payment amount must be greater than zero." | Screen-VR-3 |
| BC-VAL-04 | `currency` required, string, `max:10` | (default) | Screen-VR-4 |
| BC-VAL-05 | `payment_mode` required, string, `max:50` | (default) | Screen-VR-5 |
| BC-VAL-06 | `pay_mode_other` nullable, string, `max:100` (DDL col is 20) | (default) | Screen-VR-6 |
| BC-VAL-07 | `transaction_id` nullable, string, `max:100` | (default) | Screen-VR-7 |
| BC-VAL-08 | `invoice_payments` required; `payment_status` required | (default) | Screen-VR-8 |
| BC-VAL-09 | `payment_reconciled` nullable, `in:on,1,0,yes,no,YES,NO` | (default) | Screen-VR-9 |
| BC-VAL-10 | `gateway_resp` nullable, string, `max:1000`; `remarks` nullable, string, `max:255` | (default) | Screen-VR-10 |

### BC-AUTH (authorization) — Source: `InvoicingPaymentPolicy` + `Gate::authorize` in controller
| ID | Ability | Guards | Source |
|----|---------|--------|--------|
| BC-AUTH-01 | `prime.invoicing-payment.viewAny` | `index()` | Screen-PM-1 |
| BC-AUTH-02 | `prime.invoicing-payment.view` | `paymentDetails()`, `show()` | Screen-PM-2 |
| BC-AUTH-03 | `prime.invoicing-payment.create` | `create()`, `store()`, `consolidatedStore()`, FormRequest `authorize()` | Screen-PM-3 |
| BC-AUTH-04 | `prime.invoicing-payment.update` | `edit()`, `update()` | Screen-PM-4 |
| BC-AUTH-05 | `prime.invoicing-payment.delete` | `destroy()` | Screen-PM-5 |
| BC-AUTH-06 | Guest is blocked (redirect/401) | `auth` + `verified` middleware | Screen-PM |

### BC-BIZ (business logic) — Source: controller + Screen business rules
| ID | Behaviour | Source |
|----|-----------|--------|
| BC-BIZ-01 | Store creates an `InvoicingPayment` and increments invoice `paid_amount = old + amount_paid` | Screen-BR (Cumulative) |
| BC-BIZ-02 | Invoice `status` derived **server-side**: paid ≥ net → PAID; 0 < paid < net → PARTIAL; else PENDING (BUG-BIL-010 remediated) | Screen-BR / Audit-BUG-BIL-010 |
| BC-BIZ-03 | Overpayment is **accepted** (paid may exceed net); invoice still PAID | Screen-BR (Overpayment) |
| BC-BIZ-04 | Store wrapped in `DB::beginTransaction`/`commit` with try/catch + `DB::rollBack` (SEC-BIL-001 remediated) | Audit-SEC-BIL-001 |
| BC-BIZ-05 | Audit log row inserted (`bil_tenant_invoicing_audit_logs`) with whitelisted `event_info` (no `$request->all()`; SEC-BIL-011 remediated) | Audit-SEC-BIL-011 |
| BC-BIZ-06 | `activityLog($invoice, 'Store', …)` recorded | Controller:123 |
| BC-BIZ-07 | Add-payment form served as JSON `{html}` via `create()`; payment list via `paymentDetails()` | Screen-CRUD |
| BC-BIZ-08 | Success JSON: `{status:true, message:'Payment saved successfully!'}` | Controller:127 |

### BC-SM (state-machine: invoice payment status) — Source: Screen status auto-calculation
| ID | State → Trigger → Next | Source |
|----|-----------------------|--------|
| BC-SM-01 | PENDING → partial payment (0 < paid < net) → PARTIAL | Screen-SM-1 |
| BC-SM-02 | PARTIAL → completing payment (paid ≥ net) → PAID | Screen-SM-2 |
| BC-SM-03 | PENDING → full payment (paid ≥ net) → PAID | Screen-SM-3 |

### BC-INT / BC-REF (integration / FK) — Source: DDL FKs
| ID | Relationship | onDelete | Source |
|----|--------------|----------|--------|
| BC-REF-01 | `tenant_invoice_id` → `bil_tenant_invoices.id` | CASCADE | DDL-payments |
| BC-INT-01 | Invoice seed depends on `prm_tenant`, `prm_tenant_plan_jnt`, `prm_billing_cycles` | — | DDL |
| BC-INT-02 | Audit rows land in `bil_tenant_invoicing_audit_logs` (**col mismatch** `tenant_invoice_id` vs DDL `tenant_invoicing_id`, DATA-BIL-001) | Audit-DATA-BIL-001 |

### BC-EDG (edge) — Source: Screen edge cases / DDL limits
| ID | Edge | Source |
|----|------|--------|
| BC-EDG-01 | `amount_paid` boundary 0.01 accepted | Screen-VR-3 |
| BC-EDG-02 | `pay_mode_other` up to 100 chars accepted by request but DDL column only 20 (truncation risk) | DDL/Req |
| BC-EDG-03 | Whitespace-only remarks tolerated | Screen |
| BC-EDG-04 | Client-supplied status cannot force PAID on a below-net invoice | Screen-BR / trust boundary |

### BC-CFG (config)
| ID | Setting | Source |
|----|---------|--------|
| BC-CFG-01 | Currency default 'INR' in add-payment form | Blade add-payment |
| BC-CFG-02 | Payment mode dropdown key `bil_tenant_invoicing_payments.mode` | Blade add-payment |

### Known Source Defects (audit-equivalent codes)
| ID | Sev | State (verified in current source) | Proving test |
|----|-----|-----------------------------------|--------------|
| MIG-BIL-001 | P0 | **LIVE** — SoftDeletes without `deleted_at` on `bil_tenant_invoicing_payments` | test_02 |
| SEC-BIL-001 | P0 | **REMEDIATED** — `store()` has try/catch + `DB::rollBack` | test_41 |
| SEC-BIL-002 | P0 | **REMEDIATED** — `consolidatedStore()` guard precedes `beginTransaction` | test_42 |
| BUG-BIL-010 | P1 | **REMEDIATED** — status derived server-side from paid vs net | test_13/14/43/92 |
| SEC-BIL-011 | P1 | **REMEDIATED** — `event_info` whitelisted (no `$request->all()`) | test_44 |
| DATA-BIL-001 | P1 | **LIVE (adjacent)** — audit-log column name mismatch handled defensively in cleanup | (purgeInvoice) |
| BC-EDG overpayment | — | By-design accept (no rejection rule) | test_15 |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | Cat | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-P01 | Positive | BC-DB-01..14 | DDL | Schema/model/request config truth | All columns/casts/rules present | test_01 | Ready |
| TC-P02 | Positive | BC-BIZ-07 | Screen | Add-payment form JSON html | `{html}` incl. `invoicePaymentForm` | test_11 | Ready |
| TC-P03 | Positive | BC-BIZ-01 | Screen-BR | Store creates payment + increments paid | Payment row + paid_amount += amount | test_12 | Ready |
| TC-P04 | Positive | BC-BIZ-02 | Screen-BR | Status derived PAID when paid ≥ net | Status ≠ PENDING | test_13 | Ready |
| TC-P05 | Positive | BC-BIZ-02 | Screen-BR | Status derived PARTIAL when paid < net | paid < net retained | test_14 | Ready |
| TC-P06 | Positive | BC-BIZ-07 | Screen | Payment-details JSON html | `{html}` | test_16 | Ready |
| TC-P07 | Positive | BC-BIZ | Screen | Tab loads with filters | date_range + payment_status + table | test_10 | Ready |

### State machine (TC-SM)
| TC ID | Cat | BC | Source | Description | Method | Status |
|-------|-----|----|--------|-------------|--------|--------|
| TC-SM01 | SM | BC-SM-01 | Screen-SM-1 | PENDING → PARTIAL | test_20 | Ready |
| TC-SM02 | SM | BC-SM-02 | Screen-SM-2 | PARTIAL → PAID | test_21 | Ready |
| TC-SM03 | SM | BC-SM-03 | Screen-SM-3 | PENDING → PAID (full) | test_13 | Ready |

### Negative (TC-N)
| TC ID | Cat | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-N01 | Negative | BC-VAL-01,03,04,05,08 | Screen-VR | Empty payload | 422 with required errors | test_30 | Ready |
| TC-N02 | Negative | BC-VAL-03 | Screen-VR-3 | amount_paid = 0 | 422 "greater than zero" | test_31 | Ready |
| TC-N03 | Negative | BC-VAL-03 | Screen-VR-3 | amount_paid non-numeric | 422 amount_paid | test_32 | Ready |
| TC-N04 | Negative | BC-VAL-01 | Screen-VR-1 | Non-existent invoice | 422 "does not exist" | test_33 | Ready |
| TC-N05 | Negative | BC-VAL-04,05 | Screen-VR | currency>10 / mode>50 | 422 length | test_34 | Ready |
| TC-N06 | Negative | BC-VAL-09 | Screen-VR-9 | payment_reconciled invalid | 422 | test_35 | Ready |
| TC-N07 | Negative | BC-VAL-10 | Screen-VR-10 | remarks>255 | 422 | test_36 | Ready |
| TC-N08 | Negative | BC-AUTH-06 | Screen-PM | Guest on index | 401/403/302 | test_50 | Ready |
| TC-N09 | Negative | BC-AUTH-03 | Screen-PM-3 | Limited user store | 403 | test_51 | Ready |
| TC-N10 | Negative | BC-AUTH-02 | Screen-PM-2 | Limited user payment-details | 403 | test_52 | Ready |
| TC-N11 | Negative | BC-EDG-04 | Screen-BR | Client PAID below net rejected by server | Status ≠ PAID | test_92 | Ready |

### Dependency (TC-D)
| TC ID | Sub | BC | Source | Description | Method | Status |
|-------|-----|----|--------|-------------|--------|--------|
| TC-D01 (C) | Ref integrity | BC-REF-01 | DDL | FK tenant_invoice_id → invoices | test_40 | Ready |
| TC-D02 (E) | Cross-module | BC-BIZ-04 | Audit | store() atomic rollback | test_41 | Ready |
| TC-D03 (E) | Cross-module | BC-BIZ-04 | Audit | consolidatedStore guard order | test_42 | Ready |
| TC-D04 (E) | Cross-module | BC-BIZ-02 | Audit | status derivation source | test_43 | Ready |
| TC-D05 (E) | Cross-module | BC-BIZ-05 | Audit | audit event_info whitelist | test_44 | Ready |
| TC-D06 (B) | Soft-delete | BC-DB-14 | Audit | MIG-BIL-001 SoftDeletes/deleted_at | test_02 | Ready |
| TC-D07 (F) | Lifecycle | BC-BIZ-01 | Screen | paid accumulation across payments | test_20/21 | Ready |

### Edge / Config (TC-E)
| TC ID | BC | Source | Description | Method | Status |
|-------|----|--------|-------------|--------|--------|
| TC-E01 | BC-EDG-01 | Screen-VR-3 | 0.01 boundary accepted | test_70 | Ready |
| TC-E02 | BC-EDG-02 | DDL/Req | mode_other 20 vs 100 mismatch documented | test_71 | Ready |
| TC-E03 | BC-EDG-03 | Screen | whitespace remarks | test_72 | Ready |
| TC-E04 | BC-CFG-01/02 | Blade | currency INR + mode dropdown key | test_80 | Ready |

### Tenancy / Security (TC-T / TC-S) — central surface
| TC ID | Cat | BC | Source | Description | Method | Status |
|-------|-----|----|--------|-------------|--------|--------|
| TC-T01 | Tenancy | BC-AUTH | Screen | Super-admin reaches any invoice (no per-tenant scope) | test_90 | Ready |
| TC-S01 | Security | BC-EDG | Screen | XSS in remarks escaped by Blade | test_91 | Ready |
| TC-S02 | Security | BC-EDG-04 | Screen | client-forced status blocked | test_92 | Ready |
| TC-S03 | Security | BC-VAL | Screen | injection-shaped filter handled | test_93 | Ready |
| TC-UX01 | UI | BC-BIZ | Screen | filters + table pane | test_60 | Ready |
| TC-UX02 | UI | BC-BIZ | Screen | action menu / empty state | test_61 | Ready |
| TC-UX03 | UI | BC-BIZ-07 | Blade | payment-details empty-state markup | test_62 | Ready |
| TC-AUTH07 | Auth | BC-AUTH | Policy | policy ability keys | test_53 | Ready |

---

## 3. Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_invoicing_payment_01_migration_model_and_request_configuration_are_correct | TC-P01 | Schema | 01-09 |
| 2 | test_invoicing_payment_02_softdeletes_declared_without_deleted_at_column_documents_mig_bil_001 | TC-D06 | Schema/Defect | 01-09 |
| 3 | test_invoicing_payment_03_routes_are_registered | TC-P01 | Schema/Routes | 01-09 |
| 4 | test_invoicing_payment_10_tab_loads_with_filters | TC-P07 | BC-BIZ | 10-19 |
| 5 | test_invoicing_payment_11_add_payment_form_endpoint_returns_html | TC-P02 | BC-BIZ | 10-19 |
| 6 | test_invoicing_payment_12_store_creates_payment_and_increments_invoice_paid_amount | TC-P03 | BC-BIZ | 10-19 |
| 7 | test_invoicing_payment_13_status_derived_paid_when_paid_meets_net_payable | TC-P04/TC-SM03 | BC-BIZ | 10-19 |
| 8 | test_invoicing_payment_14_status_derived_partial_when_paid_below_net | TC-P05 | BC-BIZ | 10-19 |
| 9 | test_invoicing_payment_15_overpayment_is_accepted_by_design | BC-EDG overpay | BC-BIZ | 10-19 |
| 10 | test_invoicing_payment_16_payment_details_endpoint_returns_html | TC-P06 | BC-BIZ | 10-19 |
| 11 | test_invoicing_payment_20_pending_to_partial_transition | TC-SM01 | BC-SM | 20-29 |
| 12 | test_invoicing_payment_21_partial_to_paid_transition | TC-SM02 | BC-SM | 20-29 |
| 13 | test_invoicing_payment_30_store_requires_mandatory_fields | TC-N01 | BC-VAL | 30-39 |
| 14 | test_invoicing_payment_31_amount_paid_below_minimum_is_rejected | TC-N02 | BC-VAL | 30-39 |
| 15 | test_invoicing_payment_32_amount_paid_non_numeric_is_rejected | TC-N03 | BC-VAL | 30-39 |
| 16 | test_invoicing_payment_33_nonexistent_invoice_fails_exists_rule | TC-N04 | BC-VAL | 30-39 |
| 17 | test_invoicing_payment_34_currency_and_mode_length_limits_enforced | TC-N05 | BC-VAL | 30-39 |
| 18 | test_invoicing_payment_35_payment_reconciled_only_accepts_whitelisted_values | TC-N06 | BC-VAL | 30-39 |
| 19 | test_invoicing_payment_36_remarks_length_limit_enforced | TC-N07 | BC-VAL | 30-39 |
| 20 | test_invoicing_payment_40_fk_tenant_invoice_id_references_invoices_table | TC-D01 | BC-REF | 40-49 |
| 21 | test_invoicing_payment_41_store_transaction_has_rollback_sec_bil_001_remediation | TC-D02 | BC-INT | 40-49 |
| 22 | test_invoicing_payment_42_consolidated_store_guard_precedes_transaction_sec_bil_002 | TC-D03 | BC-INT | 40-49 |
| 23 | test_invoicing_payment_43_status_is_derived_server_side_bug_bil_010_remediation | TC-D04 | BC-INT | 40-49 |
| 24 | test_invoicing_payment_44_audit_event_info_uses_whitelist_not_request_all_sec_bil_011 | TC-D05 | BC-INT | 40-49 |
| 25 | test_invoicing_payment_50_guest_cannot_reach_index | TC-N08 | BC-AUTH | 50-59 |
| 26 | test_invoicing_payment_51_store_requires_create_permission | TC-N09 | BC-AUTH | 50-59 |
| 27 | test_invoicing_payment_52_payment_details_requires_view_permission | TC-N10 | BC-AUTH | 50-59 |
| 28 | test_invoicing_payment_53_policy_maps_abilities_to_prime_invoicing_payment_keys | TC-AUTH07 | BC-AUTH | 50-59 |
| 29 | test_invoicing_payment_60_index_pane_exposes_filters_and_table | TC-UX01 | UI | 60-69 |
| 30 | test_invoicing_payment_61_action_menu_or_empty_state_present | TC-UX02 | UI | 60-69 |
| 31 | test_invoicing_payment_62_payment_details_partial_renders_empty_state_markup | TC-UX03 | UI | 60-69 |
| 32 | test_invoicing_payment_70_minimum_amount_boundary_accepted | TC-E01 | Edge | 70-79 |
| 33 | test_invoicing_payment_71_mode_other_length_mismatch_ddl_vs_request_is_documented | TC-E02 | Edge | 70-79 |
| 34 | test_invoicing_payment_72_whitespace_only_remarks_do_not_break_store | TC-E03 | Edge | 70-79 |
| 35 | test_invoicing_payment_80_add_payment_form_defaults_currency_inr | TC-E04 | Config | 80-89 |
| 36 | test_invoicing_payment_90_central_superadmin_can_reach_any_invoice_create_form | TC-T01 | Tenancy | 90-99 |
| 37 | test_invoicing_payment_91_xss_in_remarks_is_stored_escaped_by_blade | TC-S01 | Security | 90-99 |
| 38 | test_invoicing_payment_92_client_supplied_status_cannot_force_paid_below_net | TC-N11/TC-S02 | Security | 90-99 |
| 39 | test_invoicing_payment_93_injection_shaped_filter_input_is_handled | TC-S03 | Security | 90-99 |

**Total: 39 test methods.**
