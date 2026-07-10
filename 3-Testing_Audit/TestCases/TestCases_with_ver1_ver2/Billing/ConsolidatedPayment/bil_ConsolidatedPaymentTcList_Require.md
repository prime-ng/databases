# Consolidated Payment — Test Case List & Business Conditions

- **Module:** Billing (Prime / central Super-Admin, `prime_db` — NO tenant init)
- **Feature / Screen:** Consolidated Payment tab (`consolidated-payments.md`)
- **Primary table:** `bil_tenant_invoicing_payments` (prefix **`bil_`**, `Billing_DDL_v1.sql` line 62)
- **List:** `GET /billing/billing-management?type=consolidated-payment` → `BillingManagementController@index` (consolidated branch)
- **Store:** `POST /billing/billing/consolidated-store` → `InvoicingPaymentController@consolidatedStore`
- **PDF:** `GET /billing/billing/download-consolidated-pdf` → `downloadConsolidatedPdf`; selected: `POST /billing/payment-reconciliation/download-pdf` → `downloadSelectedPdf`
- **Print:** `GET /billing/billing-management/print/data?type=consolidated-payment` → `printData`
- **Style:** browser Dusk, mirrors committed sibling `prm_ConsolidatedPaymentTab_TestCas` (central chain: `authenticateCentral` / `visitAuthenticated` / `centralUrl` / `ensureTabVisible`).

> Screen-doc corrections verified against real source: the screen requirement lists `prime.billing-management.*` for the tab/store/pdf, but the **actual gates are** `prime.consolidated-payment.viewAny` (list branch), `prime.invoicing-payment.create` (store), `prime.invoicing-payment.view` (both PDF endpoints). Assertions use the real strings.

---

## 1. Business Conditions

### BC-DB — schema (source: `Billing_DDL_v1.sql`)

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `bil_tenant_invoicing_payments` exists with `id, tenant_invoice_id, payment_date, transaction_id, mode, mode_other, amount_paid, consolidated_amount, currency, payment_status, gateway_response, payment_reconciled, remarks, created_at, updated_at` | DDL-bil_tenant_invoicing_payments |
| BC-DB-02 | `consolidated_amount DECIMAL(14,2) NULL` — set only for consolidated payments | Screen-DB, DDL |
| BC-DB-03 | `amount_paid DECIMAL(14,2) NOT NULL` — per-invoice allocation | Screen-DB, DDL |
| BC-DB-04 | `currency CHAR(3) DEFAULT 'INR'` | DDL |
| BC-DB-05 | `payment_reconciled tinyint(1) DEFAULT 0` | DDL |
| BC-DB-06 | `gateway_response JSON` (model cast `array`) | DDL, Model |
| BC-DB-07 | `payment_status VARCHAR(20) DEFAULT 'SUCCESS'` (DDL declares the modifier order swapped — DDL bug) | DDL |
| BC-DB-08 | Payments FK intends `tenant_invoice_id` → `bil_tenant_invoices` ON DELETE CASCADE; **DDL FK names non-existent `tenant_invoicing_id` / `bil_tenant_invoicing`** | DDL, Audit-MIG/DATA |
| BC-DB-09 | Model uses `SoftDeletes` but DDL table has **no `deleted_at`** | Model, DDL, Audit-MIG-BIL-001 |
| BC-DB-10 | Audit `bil_tenant_invoicing_audit_logs`: `action_type VARCHAR(20)`, `performed_by` FK → `users` SET NULL, `created_at` only (no `updated_at`/`deleted_at`) | DDL, Audit-DATA-BIL-001 |

### BC-VAL — validation (source: `ConsolidatedPaymentRequest`)

| ID | Rule / message | Source |
|----|----------------|--------|
| BC-VAL-01 | `payment_dates` required\|date → "Please enter the payment date." / "Please enter a valid payment date." | Request |
| BC-VAL-02 | `payment_mode` required\|string\|max:50 → "Please select a payment mode." | Request |
| BC-VAL-03 | `pay_mode_other` nullable\|string\|max:255 | Request |
| BC-VAL-04 | `transaction_id` nullable\|string\|max:255 | Request |
| BC-VAL-05 | `amount_paid` required\|numeric\|min:0 → "Please enter the amount paid." / "The amount must be a valid number." / "The amount cannot be less than zero." | Request |
| BC-VAL-06 | `payment_consolidated_status` required\|string\|max:50 → "Please select the payment status." | Request |
| BC-VAL-07 | `payment_reconciled` nullable\|in:on,1,0,yes,no,YES,NO; `prepareForValidation` maps only `on`/`1`→1 else 0 | Request |
| BC-VAL-08 | `gateway_resp` nullable\|string\|max:1000 | Request |
| BC-VAL-09 | **No rules for `invoice_ids[]`, `new_payment[]`, `payment_status[]`** — consumed unvalidated (VAL-BIL-001) | Audit-VAL-BIL-001 |
| BC-VAL-10 | `authorize()` = `Gate::allows('prime.invoicing-payment.create')` | Request |

### BC-AUTH — authorization

| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | List consolidated branch authorizes `prime.consolidated-payment.viewAny` | BillingManagementController@index |
| BC-AUTH-02 | Page-level `Gate::any([invoicing-payment.viewAny, subscription.viewAny, billing-management.viewAny, consolidated-payment.viewAny, payment-reconciliation.viewAny, invoicing-audit-log.viewAny])` | @index |
| BC-AUTH-03 | `consolidatedStore` → `prime.invoicing-payment.create` | InvoicingPaymentController |
| BC-AUTH-04 | `downloadConsolidatedPdf` → `prime.invoicing-payment.view` | Controller |
| BC-AUTH-05 | `downloadSelectedPdf` → `prime.invoicing-payment.view` | Controller |
| BC-AUTH-06 | `printData` (consolidated) → `prime.billing-management.print` + `prime.consolidated-payment.viewAny` | @printData |
| BC-AUTH-07 | `ConsolidatedPaymentPolicy` maps `prime.consolidated-payment.*` — **dead** (create/pdf paths gate on `invoicing-payment.*`) | Audit-DEAD-BIL-001 |

### BC-BIZ — business rules

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Single payment allocated across many invoices: `foreach ($request->invoice_ids ...)` | Screen-BR, Controller |
| BC-BIZ-02 | `consolidated_amount` = total `amount_paid` stored on EACH row; per-row `amount_paid` = `receivingAmount` | Screen-BR, Controller |
| BC-BIZ-03 | Zero-allocation skip: `if ($receivingAmount <= 0) continue;` | Screen-BR, Controller |
| BC-BIZ-04 | Cumulative paid update: `invoice.paid_amount = previousPaid + receivingAmount` | Screen-BR, Controller |
| BC-BIZ-05 | Invoice status derived server-side (PAID/PARTIAL/PENDING via GlobalMaster Dropdown) | Controller |
| BC-BIZ-06 | Atomic: `DB::beginTransaction`/`commit` wrapped in try/catch + `DB::rollBack` (**SEC-BIL-002 remediated**) | Controller, Audit-SEC-BIL-002 |
| BC-BIZ-07 | Empty-selection guard **before** `beginTransaction` → JSON `{status:false,'No invoices selected.'}` (open-tx leak fixed) | Controller |
| BC-BIZ-08 | Per-invoice `InvoicingAuditLog` `action_type='PAYMENT_UPDATED'` + `activityLog($invoice,'Store',...)` (audit insert blocked by DATA-BIL-001 on correct DDL) | Controller, Audit-DATA-BIL-001 |
| BC-BIZ-09 | `currency` hardcoded `'INR'` | Controller |
| BC-BIZ-10 | `payment_reconciled` cast to int on insert | Controller |
| BC-BIZ-11 | Success → JSON `{status:true,'Consolidated payment saved successfully!'}` | Controller |
| BC-BIZ-12 | Missing invoice inside loop → `continue` (skip, not fatal) | Controller |

### BC-REF — referential integrity

| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `payments.tenant_invoice_id` → `bil_tenant_invoices(id)` CASCADE (DDL FK column name broken) | DDL |
| BC-REF-02 | `audit.performed_by` → `users(id)` SET NULL | DDL, Audit-DATA-BIL-001 |

### BC-INT — integration

| ID | Condition | Source |
|----|-----------|--------|
| BC-INT-01 | List uses `withSum('payments','amount_paid')` → `payments_sum_amount_paid` | Screen-Filter, @buildConsolidatedPaymentQuery |
| BC-INT-02 | List hard filter `whereColumn('paid_amount','<','net_payable_amount')` (oldest due first) | Screen-Filter, Controller |
| BC-INT-03 | PDF path uses `whereColumn('paid_amount','!=','net_payable_amount')` — **inconsistent** with list `<` | Controller |
| BC-INT-04 | Status resolved via `Modules\GlobalMaster\Models\Dropdown` key `bil_tenant_invoices.status` | Controller |
| BC-INT-05 | Audit `user()` relation via `performed_by` | Model |

### BC-EDG — edge cases

| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Overpaid invoices (`paid_amount > net_payable`) excluded from list (`<` not `!=`) | Screen-Filter |
| BC-EDG-02 | `payment_reconciled` `yes`/`no` → stored 0 (only `on`/`1` map to 1) | Request |
| BC-EDG-03 | `amount_paid = 0` passes request validation (`min:0`) | Request |
| BC-EDG-04 | No server-side check that `sum(new_payment) == amount_paid` (JS-only) | Screen-Neg, Controller |
| BC-EDG-05 | `gateway_response` cast `array` but stored from a plain string field → read-decode risk | Model, Controller |

---

## 2. Test Case List

### Positive (TC-P)

| TC ID | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|----|--------|-------------|----------|----|----|--------|
| TC-P01 | BC-DB-01 | DDL | Payments table has all DDL columns | hasColumns true | 01 | 01 | ✅ |
| TC-P02 | BC-DB-02 | DDL | `consolidated_amount` nullable present | column present | 01 | 02 | ✅ |
| TC-P03 | BC-BIZ-01 | Screen-BR | Loop across selected invoices | foreach present | 10 | 10 | ✅ |
| TC-P04 | BC-BIZ-02 | Screen-BR | `consolidated_amount` = total; per-row = receiving | source assert | 11 | 12,13 | ✅ |
| TC-P05 | BC-BIZ-04 | Screen-BR | Cumulative paid_amount update | source assert | — | 14 | ✅ |
| TC-P06 | BC-BIZ-05 | Controller | Server-side status derivation | source assert | — | 15 | ✅ |
| TC-P07 | BC-BIZ-06 | Controller | Atomic tx + rollBack | source assert | — | 16 | ✅ |
| TC-P08 | BC-BIZ-11 | Controller | Success JSON message | source assert | — | 18 | ✅ |
| TC-P09 | BC-INT-01 | Controller | withSum payments | source assert | — | 40 | ✅ |
| TC-P10 | BC-INT-02 | Controller | List `<` hard filter | source assert | 14 | 41 | ✅ |
| TC-P11 | — | Blade | Tab loads with form fields | fields present | 04 | 60 | ✅ |
| TC-P12 | — | Blade | List table + totals footer | present | 05 | 62 | ✅ |
| TC-P13 | — | Blade | Tenant/date/type filters render | present | 06 | 63 | ✅ |
| TC-P14 | BC-AUTH-04 | Controller | PDF endpoint returns 200/403 | not 500 | 12 | 64 | ✅ |
| TC-P15 | BC-BIZ-08 | Controller | audit action_type / activity event | source assert | 15,16 | 44 | ✅ |

### Negative (TC-N)

| TC ID | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|----|--------|-------------|----------|----|----|--------|
| TC-N01 | BC-BIZ-07 | Controller | Store with no invoices | `{status:false,'No invoices selected.'}` | 07 | 17 | ✅ |
| TC-N02 | BC-VAL-01 | Request | Missing payment_dates | 422 + message | 08 | 30 | ✅ |
| TC-N03 | BC-VAL-02 | Request | Missing payment_mode | 422 + message | — | 31 | ✅ |
| TC-N04 | BC-VAL-05 | Request | Missing amount_paid | 422 + message | — | 32 | ✅ |
| TC-N05 | BC-VAL-06 | Request | Missing payment_consolidated_status | 422 + message | — | 33 | ✅ |
| TC-N06 | BC-VAL-05 | Request | Non-numeric amount | 422 + message | — | 34 | ✅ |
| TC-N07 | BC-VAL-05 | Request | Negative amount | 422 + message | — | 35 | ✅ |
| TC-N08 | BC-VAL-01 | Request | Invalid date | 422 + message | — | 36 | ✅ |
| TC-N09 | BC-VAL-07 | Request | reconciled yes/no → 0 | prepareForValidation | — | 39,74 | ✅ |
| TC-N10 | BC-VAL-09 | Audit | Array rules absent (VAL-BIL-001) | not in rules() | 03 | 07 | ✅ |
| TC-N11 | BC-AUTH-03 | Controller | Guest store rejected | not 200 | 13 | 56,90 | ✅ |
| TC-N12 | BC-EDG-04 | Controller | No allocation-sum check | absent | — | 72 | ✅ |

### Dependency (TC-D)

| TC ID | Sub | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|-----|----|--------|-------------|----------|----|----|--------|
| TC-D01 | C | BC-REF-01 | DDL | Payment→invoice CASCADE FK intent | source/DDL | — | 46 | ✅ |
| TC-D02 | E | BC-REF-02 | DDL | Audit performed_by→users SET NULL | source assert | — | 44,45 | ✅ |
| TC-D03 | B | BC-DB-09 | Audit | SoftDeletes vs missing deleted_at (MIG-BIL-001) | documented gap | 01 | 03 | ✅ |
| TC-D04 | E | BC-INT-04 | Controller | Status via GlobalMaster Dropdown | source assert | — | 15 | ✅ |
| TC-D05 | G | BC-BIZ-12 | Controller | Missing invoice in loop skipped | source assert | — | 43 | ✅ |
| TC-D06 | E | BC-INT-03 | Controller | PDF `!=` vs list `<` inconsistency | source assert | — | 42 | ✅ |
| TC-D07 | F | BC-EDG-05 | Model | gateway_response array cast vs string | source assert | — | 73 | ✅ |

### Security (TC-S)

| TC ID | BC | Source | Description | Expected | V2 | Status |
|-------|----|--------|-------------|----------|----|--------|
| TC-S01 | BC-AUTH-03 | Controller | Store requires auth | not 200 | 90 | ✅ |
| TC-S02 | BC-EDG-05 | Controller | XSS payload not reflected | escaped/blocked | 91 | ✅ |
| TC-S03 | BC-DB-01 | Model | Mass-assignment guarded (`id`/`created_at` not fillable) | not fillable | 92 | ✅ |
| TC-S04 | BC-AUTH-04 | Controller | Direct PDF access gated (IDOR) | gate present | 93 | ✅ |

---

## 3. V2 Method Index

| # | Method | TC Map | Band |
|---|--------|--------|------|
| 01 | 01_payments_table_columns_match_ddl | TC-P01 | 01-09 schema |
| 02 | 02_consolidated_amount_is_nullable | TC-P02 | 01-09 |
| 03 | 03_softdeletes_without_deleted_at_is_documented_gap | TC-D03 | 01-09 |
| 04 | 04_model_table_and_fillable | TC-P01 | 01-09 |
| 05 | 05_model_casts | TC-P01 | 01-09 |
| 06 | 06_request_has_all_scalar_rules | TC-N02..N08 | 01-09 |
| 07 | 07_request_missing_array_rules_val_bil_001 | TC-N10 | 01-09 |
| 08 | 08_request_authorize_uses_invoicing_payment_gate | BC-VAL-10 | 01-09 |
| 09 | 09_audit_model_uses_tenant_invoice_id | TC-D02 | 01-09 |
| 10 | 10_loops_over_all_selected_invoices | TC-P03 | 10-19 biz |
| 11 | 11_zero_allocation_skip | BC-BIZ-03 | 10-19 |
| 12 | 12_consolidated_amount_is_total_amount_paid | TC-P04 | 10-19 |
| 13 | 13_per_row_amount_paid_is_receiving_amount | TC-P04 | 10-19 |
| 14 | 14_cumulative_paid_amount_update | TC-P05 | 10-19 |
| 15 | 15_status_derived_server_side | TC-P06 | 10-19 |
| 16 | 16_transaction_is_atomic_with_rollback | TC-P07 | 10-19 |
| 17 | 17_empty_guard_runs_before_transaction | TC-N01 | 10-19 |
| 18 | 18_success_response_message | TC-P08 | 10-19 |
| 19 | 19_currency_hardcoded_inr | BC-BIZ-09 | 10-19 |
| 30-36 | validation message cases | TC-N02..N08 | 30-39 val |
| 37 | 37_payment_mode_max_50_rule | BC-VAL-02 | 30-39 |
| 38 | 38_gateway_resp_max_1000_rule | BC-VAL-08 | 30-39 |
| 39 | 39_prepare_for_validation_maps_reconciled | TC-N09 | 30-39 |
| 40 | 40_list_uses_with_sum_payments | TC-P09 | 40-49 int |
| 41 | 41_list_hard_filter_less_than | TC-P10 | 40-49 |
| 42 | 42_pdf_filter_uses_not_equal_inconsistency | TC-D06 | 40-49 |
| 43 | 43_invoice_not_found_is_skipped | TC-D05 | 40-49 |
| 44 | 44_audit_fk_performed_by_user | TC-D02 | 40-49 |
| 45 | 45_audit_insert_depends_on_valid_user_fk | TC-D02 | 40-49 |
| 46 | 46_invoice_payments_relationship | TC-D01 | 40-49 |
| 50 | 50_tab_viewany_gate | BC-AUTH-01 | 50-59 auth |
| 51 | 51_index_gate_any_list | BC-AUTH-02 | 50-59 |
| 52 | 52_store_gate_invoicing_payment_create | BC-AUTH-03 | 50-59 |
| 53 | 53_download_pdf_gate_invoicing_payment_view | BC-AUTH-04 | 50-59 |
| 54 | 54_print_data_gate | BC-AUTH-06 | 50-59 |
| 55 | 55_policy_maps_dead_consolidated_permissions | BC-AUTH-07 | 50-59 |
| 56 | 56_guest_store_is_rejected | TC-N11 | 50-59 |
| 57 | 57_submit_button_gated_by_create_permission | BC-AUTH | 50-59 |
| 60 | 60_tab_renders_all_static_fields | TC-P11 | 60-69 ui |
| 61 | 61_row_inputs_present_when_data_exists | TC-P12 | 60-69 |
| 62 | 62_totals_footer_present | TC-P12 | 60-69 |
| 63 | 63_tenant_and_date_filters_render | TC-P13 | 60-69 |
| 64 | 64_download_pdf_endpoint_returns_pdf_or_gate | TC-P14 | 60-69 |
| 65 | 65_responsive_smoke_mobile_viewport | UI smoke | 60-69 |
| 70 | 70_overpaid_invoices_excluded_from_list | TC-D06/EDG-01 | 70-79 edge |
| 71 | 71_zero_amount_paid_passes_validation | BC-EDG-03 | 70-79 |
| 72 | 72_no_server_side_allocation_sum_check | TC-N12 | 70-79 |
| 73 | 73_gateway_response_array_cast_vs_string_store | TC-D07 | 70-79 |
| 74 | 74_reconciled_yes_no_becomes_zero | TC-N09 | 70-79 |
| 75 | 75_consolidated_print_crash_documented | BUG-BIL-005 | 70-79 |
| 90 | 90_store_requires_authentication | TC-S01 | 90-99 sec |
| 91 | 91_xss_payload_in_gateway_resp_is_not_reflected | TC-S02 | 90-99 |
| 92 | 92_mass_assignment_guarded_by_fillable | TC-S03 | 90-99 |
| 93 | 93_idor_direct_pdf_access_is_gated | TC-S04 | 90-99 |

**Counts:** V1 = 16 methods, V2 = 60 methods (60 ≥ 2 × 16 = 32 ✅).

---

## 4. Known Source Defects (carried from `Billing_Complete_Audit_2026-06-29.md` + this scan)

| ID | Sev | Summary | Current-source status | Proving test |
|----|-----|---------|-----------------------|--------------|
| MIG-BIL-001 | P0 | SoftDeletes/default-timestamps vs DDL tables lacking `deleted_at`/`updated_at` | **LIVE** — payments has no `deleted_at`; audit has `created_at` only | V1-01, V2-03 |
| DATA-BIL-001 | P0 | Audit-log column/FK mismatch (`tenant_invoicing_id` vs `tenant_invoice_id`) + `performed_by`→`users` FK blocks inserts | **Model remediated** to `tenant_invoice_id`; DDL FK still broken (`tenant_invoicing_id`/`bil_tenant_invoicing`); performed_by FK risk remains | V2-09, V2-44, V2-45 |
| SEC-BIL-002 | P0 | consolidatedStore open-tx early return, no rollback | **REMEDIATED** — try/catch + rollBack; empty guard moved before `beginTransaction` | V2-16, V2-17 |
| VAL-BIL-001 | P2 | Missing array validation for `invoice_ids/new_payment/payment_status` | **LIVE** | V1-03, V2-07 |
| DEAD-BIL-001 | P2 | Dead `ConsolidatedPaymentPolicy` (real paths use `invoicing-payment.*`) | **Partly remediated** — no longer imports non-existent model; policy still effectively dead | V2-55 |
| BUG-BIL-005 | P2 | Consolidated print path crash | **Verify** — asserted defensively; markTestSkipped if 500 reproduced | V2-75 |
| INT-BIL-CP-01 (new) | P3 | List filter `<` vs PDF filter `!=` diverge on overpaid invoices | LIVE (documented) | V2-42, V2-70 |
