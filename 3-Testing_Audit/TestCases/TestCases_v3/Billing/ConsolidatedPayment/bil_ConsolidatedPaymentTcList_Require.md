# Consolidated Payment — Test Case List & Business Conditions (`bil_`)

- **Module:** Billing (BIL) — **Prime / Central** (`prime_db`)
- **Feature / Screen:** Consolidated Payment (Billing Management → Consolidated Payment tab)
- **Primary table:** `bil_tenant_invoicing_payments` (prefix `bil_`)
- **Controller:** `Modules\Billing\Http\Controllers\InvoicingPaymentController::consolidatedStore()`
- **FormRequest:** `Modules\Billing\Http\Requests\ConsolidatedPaymentRequest`
- **Policy:** `Modules\Billing\Policies\ConsolidatedPaymentPolicy` (`prime.consolidated-payment.*`)
- **Store route:** `billing.consolidated.store` (POST) → actual path `/billing/billing/consolidated-store`
- **Test file:** `bil_ConsolidatedPayment_TestCas.php` (37 methods, single suite)
- **Test style:** Browser Dusk, central base `BillingDuskTestCase` (127.0.0.1); endpoint/validation via in-process HTTP (`postJson`, constraint 14).

---

## 1. Business Conditions

### BC-DB (schema — Source: `DDL-bil_tenant_invoicing_payments`, `DDL-bil_tenant_invoices`, `DDL-bil_tenant_invoicing_audit_logs`)

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `bil_tenant_invoicing_payments` exists with `id, tenant_invoice_id, payment_date, transaction_id, mode, mode_other, amount_paid, consolidated_amount, currency, payment_status, gateway_response, payment_reconciled, remarks` | DDL |
| BC-DB-02 | `consolidated_amount DECIMAL(14,2) NULL` — set only for consolidated payments; holds the total cheque/transfer amount | DDL, Screen-§DB |
| BC-DB-03 | `amount_paid DECIMAL(14,2) NOT NULL` — per-invoice allocation | DDL, Screen-§DB |
| BC-DB-04 | `bil_tenant_invoices` exposes `paid_amount`, `net_payable_amount`, `status`, `tenant_id` | DDL |
| BC-DB-05 | `bil_tenant_invoicing_audit_logs` exposes `action_type`, `tenant_invoice_id`, `performed_by`, `event_info` | DDL |
| BC-DB-06 | Model casts: `amount_paid=decimal:2`, `payment_reconciled=boolean`, `gateway_response=array` | Model |
| BC-DB-07 | `InvoicingPayment` declares `SoftDeletes` — but DDL omits `deleted_at`/`updated_at` on payments/audit tables (**DEV-BIL-004**) | Model vs DDL, Audit-MIG-BIL-001 |

### BC-VAL (validation — Source: `ConsolidatedPaymentRequest`)

| ID | Rule | Message | Source |
|----|------|---------|--------|
| BC-VAL-01 | `payment_dates required\|date` | "Please enter the payment date." / "Please enter a valid payment date." | Screen-VR-1 |
| BC-VAL-02 | `payment_mode required\|string\|max:50` | "Please select a payment mode." | Screen-VR-2 |
| BC-VAL-03 | `amount_paid required\|numeric\|min:0` | "Please enter the amount paid." / "The amount must be a valid number." / "The amount cannot be less than zero." | Screen-VR-3 |
| BC-VAL-04 | `payment_consolidated_status required\|string\|max:50` | "Please select the payment status." | Screen-VR-4 |
| BC-VAL-05 | `pay_mode_other`, `transaction_id`, `gateway_resp` nullable with max lengths | — | Request |
| BC-VAL-06 | **GAP:** `invoice_ids[]`, `new_payment[]`, `payment_status[]` have NO rules — trusted raw (**DEV-BIL-002**) | Screen-§ValidationGaps, Audit-VAL-BIL-001 |

### BC-AUTH (authorization — Source: Controller `Gate::authorize`, `ConsolidatedPaymentPolicy`, `BillingServiceProvider`)

| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | `consolidatedStore()` authorizes `prime.invoicing-payment.create` (note: not the `consolidated-payment` ability) | Controller:189 |
| BC-AUTH-02 | `prime.consolidated-payment.{viewAny,view,create,update,delete,print,pdf,remark,restore,forceDelete}` gates defined | ServiceProvider:75 |
| BC-AUTH-03 | Route group middleware `auth,verified` — guest is redirected to `/login`; guest POST rejected | routes/web.php:324 |
| BC-AUTH-04 | Central super-admin `Gate::before` resolves dotted abilities (runtime 403 for a limited user is bypassed for super-admin) | AppServiceProvider, Audit |

### BC-BIZ (business logic — Source: `consolidatedStore()`, Screen business rules)

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Single payment distributed across multiple outstanding invoices of a tenant | Screen-§WhatItDoes |
| BC-BIZ-02 | Empty selection returns `{status:false,'No invoices selected.'}` **before** `beginTransaction()` (**DEV-BIL-001** remediation) | Controller:194 |
| BC-BIZ-03 | Loop each invoice: create `InvoicingPayment` (with `consolidated_amount`) → increment `paid_amount` → derive status → create `PAYMENT_UPDATED` audit → `activityLog('Store')` | Controller:204-291 |
| BC-BIZ-04 | BR-BIL-025: total stored in `consolidated_amount`, allocation in `amount_paid` | Screen-BR, Audit |
| BC-BIZ-05 | BR-BIL-020: `paid_amount` is add-only (cumulative) | Controller:242 |
| BC-BIZ-06 | Activity-log event literal string is `'Store'`; audit `action_type` literal is `'PAYMENT_UPDATED'` | Controller:269,289 |
| BC-BIZ-07 | Whole loop is wrapped in `try { … DB::commit(); } catch { DB::rollBack(); }` returning 500 on failure | Controller:203-306 |

### BC-SM (state machine — invoice status — Source: `consolidatedStore()` status derivation)

| ID | State → Trigger → Next | Source |
|----|------------------------|--------|
| BC-SM-01 | `PARTIAL` when `0 < paid_amount < net_payable_amount` | Controller:256 |
| BC-SM-02 | `PAID` when `paid_amount >= net_payable_amount` | Controller:254 |
| BC-SM-03 | `PENDING` when `paid_amount = 0` | Controller:258 |
| BC-SM-04 | Zero allocation → invoice skipped, no state change (BR-BIL-024) | Controller:209 |
| BC-SM-05 | Status is **derived server-side** (BUG-BIL-010 remediation — no longer from request) | Controller:244-260 |

### BC-INT / BC-REF (integration — Source: models, DDL FKs)

| ID | Condition | Source |
|----|-----------|--------|
| BC-INT-01 | `InvoicingPayment.tenant_invoice_id → bil_tenant_invoices.id`; `BilTenantInvoice::payments()` hasMany | Model |
| BC-REF-01 | DDL declares `ON DELETE CASCADE` payment → invoice | DDL |
| BC-REF-02 | Audit row `performed_by = auth()->id()` (FK → users, `ON DELETE SET NULL`) | DDL, Controller:271 |

### BC-EDG (edge cases)

| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Missing invoice inside loop leaves an orphan payment (payment created, then `continue`) (**DEV-BIL-006**) | Controller:216-238 |
| BC-EDG-02 | No reconciliation of `sum(new_payment)` vs `amount_paid` (**DEV-BIL-007**) | Controller (absent) |
| BC-EDG-03 | Overpayment beyond `net_payable_amount` is not blocked (add-only) (**DEV-BIL-007b**) | Controller:242 |
| BC-EDG-04 | Requirement route `/billing/consolidated-store` double-segments to `/billing/billing/consolidated-store` (**DEV-BIL-003**) | routes/web.php:389 |

---

## 2. Test Case List

### Positive (`TC-P`)

| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-DB-01..07 | DDL | Schema/model/request/policy config truth | All asserts pass / documented | `_01` | Automated |
| TC-P02 | BC-VAL msgs | Request | Error messages match source verbatim | Match | `_02` | Automated |
| TC-P03 | BC-DB-04/05 | DDL | Related tables present | Present | `_03` | Automated |
| TC-P04 | BC-BIZ-01 | Screen | Billing Management loads consolidated tab | Pane visible | `_10` | Automated |
| TC-P05 | BC-BIZ | Blade | All header form fields present | Present | `_11` | Automated |
| TC-P06 | BC-BIZ | Blade | Outstanding table columns present | Present | `_12` | Automated |
| TC-P07 | BC-BIZ | Blade | `amount_paid` defaults to 0 | "0" | `_13` | Automated |
| TC-P08 | BC-AUTH-02 | @can | Submit control visible for privileged user | Present | `_14` | Automated |
| TC-P09 | BC-EDG-04 | routes | Store + PDF routes registered by name | Registered | `_15` | Automated |
| TC-P10 | BC-BIZ-04/05 | Controller | Positive allocation persists payment + audit + cumulative paid | Persisted | `_17` | Automated (defensive) |
| TC-P11 | BC-BIZ-06 | Controller | Activity-log `'Store'` + audit `PAYMENT_UPDATED` literals | Present | `_18` | Automated |
| TC-P12 | BC-SM-01/02/05 | Controller | Status derived server-side | Derived | `_20` | Automated |
| TC-P13 | BC-SM-04 | Controller | Zero allocation skipped | Skipped | `_21` | Automated |
| TC-P14 | BC-INT-01 | Model | Relationships wired both directions | Wired | `_40` | Automated |
| TC-P15 | BC-REF-01 | DDL | Cascade FK declared | Declared | `_41` | Automated |
| TC-P16 | BC-REF-02 | Controller | Audit records `performed_by` | Records | `_44` | Automated |
| TC-P17 | BC-AUTH-02 | ServiceProvider | Policy/gate abilities defined | Defined | `_52` | Automated |
| TC-P18 | BC-BIZ | Blade | Search/filter form present | Present | `_60` | Automated |
| TC-P19 | BC-BIZ | Blade | Empty-state table renders | Rendered | `_61` | Automated |

### Negative (`TC-N`)

| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-N01 | BC-BIZ-02 | Controller | Empty selection → soft `{status:false}` | 200 status:false | `_16` | Automated |
| TC-N02 | BC-VAL-01 | Request | Missing `payment_dates` | 422 + message | `_30` | Automated |
| TC-N03 | BC-VAL-01 | Request | Invalid `payment_dates` | 422 + message | `_31` | Automated |
| TC-N04 | BC-VAL-02 | Request | Missing `payment_mode` | 422 + message | `_32` | Automated |
| TC-N05 | BC-VAL-03 | Request | Missing `amount_paid` | 422 + message | `_33` | Automated |
| TC-N06 | BC-VAL-03 | Request | Non-numeric `amount_paid` | 422 + message | `_34` | Automated |
| TC-N07 | BC-VAL-03 | Request | Negative `amount_paid` | 422 + message | `_35` | Automated |
| TC-N08 | BC-VAL-04 | Request | Missing `payment_consolidated_status` | 422 + message | `_36` | Automated |
| TC-N09 | BC-VAL-06 | Request | Array inputs unvalidated (DEV-BIL-002) | not 422 for arrays | `_37` | Automated |
| TC-N10 | BC-AUTH-03 | Middleware | Guest redirected to login | `/login` | `_50` | Automated |
| TC-N11 | BC-AUTH-03 | Middleware | Guest POST rejected | 401/403/302/419 | `_51` | Automated |

### Dependency / Security (`TC-D` / `TC-S` / `TC-T`)

| TC ID | Sub | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-D01 | E | BC-EDG-01 | Controller | Missing invoice creates orphan payment (DEV-BIL-006) | Documented/proven | `_42` | Automated |
| TC-D02 | B | BC-DB-07 | Model/DDL | SoftDelete columns guarded (DEV-BIL-004) | Documented | `_43` | Automated |
| TC-D03 | G | BC-EDG-02 | Controller | Sum(allocation) ≠ total not reconciled (DEV-BIL-007) | Not reconciled | `_70` | Automated |
| TC-D04 | G | BC-EDG-03 | Controller | Overpayment not blocked (DEV-BIL-007b) | Not blocked | `_71` | Automated |
| TC-T01 | — | BC-AUTH-04 | Base | Central context, no tenant init | Not initialized | `_90` | Automated |
| TC-S01 | — | — | Controller | Stored-XSS payload stored raw | Raw at rest | `_91` | Automated (defensive) |
| TC-S02 | — | BC-EDG-01 | Controller | Non-existent invoice id tolerated, no orphan | No leak | `_92` | Automated (defensive) |

---

## 3. Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | `_01_schema_model_and_request_configuration_are_correct` | TC-P01 | Config | 01–09 |
| 2 | `_02_request_messages_match_source_strings` | TC-P02 | Config | 01–09 |
| 3 | `_03_related_tables_are_present` | TC-P03 | Config | 01–09 |
| 4 | `_10_billing_management_page_loads_tab` | TC-P04 | BIZ | 10–19 |
| 5 | `_11_tab_exposes_all_payment_form_fields` | TC-P05 | BIZ | 10–19 |
| 6 | `_12_outstanding_invoice_table_columns_present` | TC-P06 | BIZ | 10–19 |
| 7 | `_13_amount_paid_defaults_to_zero` | TC-P07 | BIZ | 10–19 |
| 8 | `_14_submit_button_visible_for_privileged_user` | TC-P08 | BIZ | 10–19 |
| 9 | `_15_consolidated_store_route_registered` | TC-P09 | BIZ | 10–19 |
| 10 | `_16_empty_selection_returns_soft_failure` | TC-N01 | BIZ | 10–19 |
| 11 | `_17_positive_allocation_persists_payment_and_audit` | TC-P10 | BIZ | 10–19 |
| 12 | `_18_activity_log_store_event_is_written` | TC-P11 | BIZ | 10–19 |
| 13 | `_20_invoice_status_derived_server_side` | TC-P12 | SM | 20–29 |
| 14 | `_21_zero_allocation_is_skipped` | TC-P13 | SM | 20–29 |
| 15 | `_30_store_requires_payment_date` | TC-N02 | VAL | 30–39 |
| 16 | `_31_store_rejects_invalid_payment_date` | TC-N03 | VAL | 30–39 |
| 17 | `_32_store_requires_payment_mode` | TC-N04 | VAL | 30–39 |
| 18 | `_33_store_requires_amount_paid` | TC-N05 | VAL | 30–39 |
| 19 | `_34_store_rejects_non_numeric_amount` | TC-N06 | VAL | 30–39 |
| 20 | `_35_store_rejects_negative_amount` | TC-N07 | VAL | 30–39 |
| 21 | `_36_store_requires_payment_status` | TC-N08 | VAL | 30–39 |
| 22 | `_37_array_inputs_are_not_validated` | TC-N09 | VAL | 30–39 |
| 23 | `_40_payment_invoice_relationships_wired` | TC-P14 | INT | 40–49 |
| 24 | `_41_invoice_cascade_relationship_declared` | TC-P15 | REF | 40–49 |
| 25 | `_42_missing_invoice_creates_orphan_payment` | TC-D01 | INT | 40–49 |
| 26 | `_43_soft_delete_columns_are_guarded` | TC-D02 | REF | 40–49 |
| 27 | `_44_audit_row_records_performed_by` | TC-P16 | REF | 40–49 |
| 28 | `_50_guest_redirected_to_login` | TC-N10 | AUTH | 50–59 |
| 29 | `_51_guest_cannot_post_consolidated_store` | TC-N11 | AUTH | 50–59 |
| 30 | `_52_policy_and_gate_abilities_defined` | TC-P17 | AUTH | 50–59 |
| 31 | `_60_search_filter_form_present` | TC-P18 | UIX | 60–69 |
| 32 | `_61_empty_state_renders` | TC-P19 | UIX | 60–69 |
| 33 | `_70_sum_allocation_not_reconciled_to_total` | TC-D03 | EDG | 70–79 |
| 34 | `_71_overpayment_not_blocked` | TC-D04 | EDG | 70–79 |
| 35 | `_90_runs_in_central_context_without_tenant` | TC-T01 | Tenancy | 90–99 |
| 36 | `_91_xss_payload_in_text_field_is_stored_raw` | TC-S01 | Security | 90–99 |
| 37 | `_92_nonexistent_invoice_id_is_tolerated` | TC-S02 | Security | 90–99 |

---

## 4. Known Source Defects (DEV-###)

| DEV | Audit ref | Sev | Status | Description | Proving method |
|-----|-----------|-----|--------|-------------|----------------|
| DEV-BIL-001 | SEC-BIL-002 | P0 | **Remediated** | No-rollback + early-return-in-tx | `_16`, `_20` (guard now precedes tx; try/catch present) |
| DEV-BIL-002 | VAL-BIL-001 | P2 | **Open** | `invoice_ids`/`new_payment`/`payment_status` unvalidated | `_37` |
| DEV-BIL-003 | RT (new) | P3 | **Open** | Route double-prefixes to `/billing/billing/consolidated-store` | `_15` |
| DEV-BIL-004 | MIG-BIL-001 | P0 | **Open** | SoftDeletes/timestamps declared, DDL columns absent | `_43` |
| DEV-BIL-006 | new | P2 | **Open** | Orphan payment on missing invoice inside loop | `_42` |
| DEV-BIL-007 | new | P2 | **Open** | No sum(allocation) vs total reconciliation; overpayment not capped | `_70`, `_71` |
