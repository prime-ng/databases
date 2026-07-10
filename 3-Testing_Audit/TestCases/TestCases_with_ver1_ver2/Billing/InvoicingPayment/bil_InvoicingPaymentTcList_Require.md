# Invoice Payments — Test Case List & Business Conditions

- **Module / Feature:** Billing / InvoicingPayment (Invoice Payments tab of Billing Management)
- **Screen source:** `Billing_v1/invoice-payments.md`
- **Primary table:** `bil_tenant_invoicing_payments` (DDL `Billing_DDL_v1.sql` line 62) — prefix **`bil_`**
- **DB scope:** **prime_db CENTRAL** (Super-Admin billing) — **NO tenant init**. Mirrors committed sibling `prm_InvoicingPaymentTab_TestCas` / `BillingDuskTestCase`.
- **Controller:** `Modules\Billing\Http\Controllers\InvoicingPaymentController`
- **FormRequest:** `Modules\Billing\Http\Requests\StoreInvoicePaymentRequest`
- **Model:** `Modules\Billing\Models\InvoicingPayment`
- **Policy:** `Modules\Billing\Policies\InvoicingPaymentPolicy` (`Modules\Prime\Models\User`)
- **Routes:** `billing.invoicing-payment.*` (resource) + `billing.payment-details` + `billing.consolidated.store`
- **Feature type:** create + report (record payment; read-only tab list). CRUD `edit/update/destroy` are stubs (empty methods).

> **IMPORTANT — "read the real source" corrections to the intake brief.** Several defects in the brief are actually **remediated in current source**; only the genuinely-present ones are asserted:
> - `authorize()` is **gated** (`Gate::allows('prime.invoicing-payment.create')`), **not** `true`.
> - `store()` **DOES** wrap in `DB::beginTransaction()` + `try/catch` + `DB::rollBack()` (SEC-BIL-001 not reproducible; tested as an atomicity guarantee).
> - `event_info` is **whitelisted** (payment_id, previous_paid, amount_added, new_paid_amount, payment_mode, payment_status, payment_date, transaction_id, remarks) — **not** `$request->all()` (SEC-BIL-011 not reproducible).
> - Invoice `status` **is derived server-side** from cumulative paid (BUG-BIL-010 "status from request" is corrected). The **remaining** real defect is that the *payment row's* `payment_status` is written from the form's `invoice_payments` value (PENDING/PARTIAL/PAID) — invoice-status text, not the DDL payment enum (INITIATED/SUCCESS/FAILED) nor a Dropdown id.

---

## 1. Business Conditions

### BC-DB — Schema (Source: `DDL-bil_tenant_invoicing_payments`, lines 62–79)

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `id` INT UNSIGNED PK auto-increment | DDL |
| BC-DB-02 | `tenant_invoice_id` INT UNSIGNED NOT NULL, FK → `bil_tenant_invoices` CASCADE | DDL / Screen-DB |
| BC-DB-03 | `payment_date` DATE NOT NULL | DDL |
| BC-DB-04 | `transaction_id` VARCHAR(100) nullable | DDL |
| BC-DB-05 | `mode` VARCHAR(20) NOT NULL DEFAULT 'ONLINE' (enum ONLINE/BANK_TRANSFER/CASH/CHEQUE) | DDL |
| BC-DB-06 | `mode_other` VARCHAR(20) nullable | DDL |
| BC-DB-07 | `amount_paid` DECIMAL(14,2) NOT NULL | DDL |
| BC-DB-08 | `consolidated_amount` DECIMAL(14,2) NULL (only for consolidated payments) | DDL |
| BC-DB-09 | `currency` CHAR(3) NOT NULL DEFAULT 'INR' | DDL |
| BC-DB-10 | `payment_status` VARCHAR(20) DEFAULT 'SUCCESS' (enum INITIATED/SUCCESS/FAILED). **DDL type mis-ordered `NOT NULL VARCHAR(20)` → MIG-BIL-002** | DDL |
| BC-DB-11 | `gateway_response` JSON nullable | DDL |
| BC-DB-12 | `payment_reconciled` TINYINT(1) NOT NULL DEFAULT 0 | DDL |
| BC-DB-13 | `remarks` VARCHAR(255) nullable | DDL |
| BC-DB-14 | **NO `deleted_at` column** but model uses `SoftDeletes` → **MIG-BIL-001 (P0)** | DDL / Model |
| BC-DB-15 | DDL FK references non-existent col `tenant_invoicing_id` / wrong table `bil_tenant_invoicing` → **DATA-BIL-001** | DDL |

### BC-VAL — Validation (Source: `StoreInvoicePaymentRequest`)

| ID | Rule | Message | Source |
|----|------|---------|--------|
| BC-VAL-01 | `tenant_invoice_id` required, exists:bil_tenant_invoices,id | "Invoice is required." / "Selected invoice does not exist." | Request |
| BC-VAL-02 | `date` required, date | (default) | Request |
| BC-VAL-03 | `amount_paid` required, numeric, min:0.01 | "Payment amount must be greater than zero." | Request |
| BC-VAL-04 | `currency` required, string, max:10 | (default) | Request |
| BC-VAL-05 | `payment_mode` required, string, max:50 — **no `in:` enum** → VAL-BIL-001 | (default) | Request |
| BC-VAL-06 | `invoice_payments` / `payment_status` required | (default) | Request |
| BC-VAL-07 | `payment_reconciled` in:on,1,0,yes,no,YES,NO | (default) | Request |
| BC-VAL-08 | `pay_mode_other.required_if` **message exists but no matching rule** → VAL-BIL-001 | "Please specify other payment mode." | Request |

### BC-AUTH — Permissions (Source: `Screen-PM`, Policy, Controller gates)

| ID | Ability | Gate / Permission | Source |
|----|---------|-------------------|--------|
| BC-AUTH-01 | View tab | `prime.invoicing-payment.viewAny` | Controller `index` |
| BC-AUTH-02 | View details | `prime.invoicing-payment.view` | Controller `paymentDetails/show` |
| BC-AUTH-03 | Record payment | `prime.invoicing-payment.create` | Controller `store/create`, Request `authorize()` |
| BC-AUTH-04 | Update payment | `prime.invoicing-payment.update` | Controller `edit/update` (stubs) |
| BC-AUTH-05 | Delete payment | `prime.invoicing-payment.delete` | Controller `destroy` (stub) |

### BC-BIZ — Business logic (Source: `Screen-BR`, Controller)

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Cumulative paid: `new_paid = old_paid + amount_paid` | Screen-BR / Controller L75 |
| BC-BIZ-02 | `paid_amount` never decremented | Screen-BR |
| BC-BIZ-03 | Overpayment allowed; invoice still PAID | Screen-BR / Controller L87 |
| BC-BIZ-04 | Payment recording wrapped in DB transaction + `DB::rollBack()` on exception (SEC-BIL-001 remediated) | Controller L52,131 |
| BC-BIZ-05 | Audit `event_info` whitelisted (SEC-BIL-011 remediated) | Controller L110 |
| BC-BIZ-06 | Activity log event literal `'Store'` on invoice | Controller L123 |
| BC-BIZ-07 | `payment_reconciled` 'YES' → 1 else 0 | Controller L66 |
| BC-BIZ-08 | **BUG-BIL-011:** `consolidated_amount` set = `amount_paid` for single payments (should be NULL) | Controller L61 |
| BC-BIZ-09 | **BUG-BIL-010:** payment row `payment_status` = form `invoice_payments` (invoice-status text), not payment enum/Dropdown id | Controller L64 / Blade |
| BC-BIZ-10 | **VAL-BIL-001:** controller reads `$request->date` etc. directly, bypassing `$request->validated()` | Controller L55-68 |

### BC-SM — Invoice status state machine (Source: `Screen-SM`, Controller L87-93)

| ID | State → Trigger → Next | Source |
|----|-----------------------|--------|
| BC-SM-01 | PENDING → partial payment (0<paid<net) → PARTIALLY_PAID | Screen-SM / Controller |
| BC-SM-02 | PARTIALLY_PAID → payment completes (paid≥net) → PAID | Screen-SM / Controller |
| BC-SM-03 | PENDING → full payment (paid≥net) → PAID | Screen-SM / Controller |
| BC-SM-04 | Any → overpayment (paid>net) → PAID (allowed) | Screen-SM / Controller |
| BC-SM-05 | (illegal) paid_amount decremented — never happens | Screen-BR |

### BC-REF / BC-INT — Referential / integration

| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `tenant_invoice_id` → `bil_tenant_invoices.id` ON DELETE CASCADE | DDL / Screen-DB |
| BC-INT-01 | Each payment insert also inserts an `InvoicingAuditLog` row (payment depends on audit — DATA-BIL-001) | Controller L104 |
| BC-INT-02 | `mode` / `payment_status` resolve via `Dropdown` (`paymentModeData`/`paymentStatusData`) | Model |

### BC-EDG — Edge

| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Amount with >2 decimals truncated by DECIMAL(14,2) | DDL |
| BC-EDG-02 | Overpayment large value accepted | Screen-BR |
| BC-EDG-03 | Zero / negative amount rejected by min:0.01 | Request |

---

## 2. Test Case List

### Positive (TC-P)

| TC ID | Category | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|----------|----|--------|-------------|----------|----|----|--------|
| TC-P01 | Config | BC-DB-01..13 | DDL | Table + columns exist | All present | 01 | 01,02 | Auto |
| TC-P02 | Config | BC-DB, Model | Model | Fillable/casts/relations correct | Match source | 03,04,40 | 05,06,07,40 | Auto |
| TC-P03 | UI | BC-AUTH-01 | Screen | Tab loads with filters + table | Pane visible | 10,11,12 | 60,61,62 | Auto |
| TC-P04 | AJAX | BC-AUTH-03 | Screen | Add-payment form returns html | `{html}` | 20 | 64 | Auto |
| TC-P05 | AJAX | BC-AUTH-02 | Screen | Payment-details returns html | `{html}` | 21 | 63 | Auto |
| TC-P06 | Biz | BC-BIZ-01 | Screen-BR | Store increments paid_amount | paid += amount | — | 10 | Auto |
| TC-P07 | Biz | BC-BIZ-02 | Screen-BR | paid_amount never decremented | monotonic | — | 11 | Auto |
| TC-P08 | SM | BC-SM-01 | Screen-SM | Partial → PARTIALLY_PAID invariant | 0<paid<net | — | 20 | Auto |
| TC-P09 | SM | BC-SM-02/03 | Screen-SM | Complete → PAID invariant | paid≥net | — | 21 | Auto |
| TC-P10 | SM/Edg | BC-SM-04 | Screen-BR | Overpayment allowed, stays PAID | paid>net | — | 22 | Auto |
| TC-P11 | Biz | BC-BIZ-07 | Controller | reconciled YES → 1 | =1 | — | 15 | Auto |
| TC-P12 | Int | BC-INT-01 | Controller | Store writes audit row | count+1 | — | 42 | Auto |
| TC-P13 | Biz | BC-DB-09 | Controller | Currency INR persists | INR | — | 72 | Auto |

### Negative (TC-N)

| TC ID | Category | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|----------|----|--------|-------------|----------|----|----|--------|
| TC-N01 | Val | BC-VAL-01 | Request | Missing tenant_invoice_id | 422 "Invoice is required." | 31 | 30 | Auto |
| TC-N02 | Val | BC-VAL-01 | Request | Non-existent invoice id | 422 "does not exist" | — | 31 | Auto |
| TC-N03 | Val | BC-VAL-03 | Request | amount_paid below min | 422 ">zero" | — | 32,71 | Auto |
| TC-N04 | Val | BC-VAL-03 | Request | Non-numeric amount | 422 | — | 33 | Auto |
| TC-N05 | Val | BC-VAL-04 | Request | Missing currency | 422 | — | 34 | Auto |
| TC-N06 | Val | BC-VAL-05 | Request | Missing payment_mode | 422 | — | 35 | Auto |
| TC-N07 | Auth | BC-AUTH-03 | Middleware | Guest POST store | 302/401/419 | 30 | 37 | Auto |
| TC-N08 | Sec | BC-BIZ-13 | Screen | XSS in remarks escaped on render | not raw `<script>` | — | 38 | Auto |
| TC-N09 | Auth | BC-AUTH-01 | Middleware | Unauthenticated tab visit → /login | redirect | 50 | 52 | Auto |

### Dependency / Defect (TC-D)

| TC ID | Sub | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|-----|----|--------|-------------|----------|----|----|--------|
| TC-D01 | E | BC-INT-01 | Controller | Audit insert dependency (DATA-BIL-001) | audit+1 | — | 42 | Auto |
| TC-D02 | B | BC-DB-14 | DDL/Model | SoftDeletes vs no deleted_at (MIG-BIL-001) | column absent | 02 | 03 | Auto (defect) |
| TC-D03 | C | BC-REF-01 | DDL | FK column/table mismatch (DATA-BIL-001) | runtime col = tenant_invoice_id | — | 44 | Auto (defect) |
| TC-D04 | G | BC-BIZ-04 | Controller | Rejected payment → no orphan row (atomicity) | count unchanged | 91 | 91 | Auto |

### Known Source Defects (audit-equivalent BUG/MIG/SEC/VAL/DATA-BIL)

| ID | Sev | Title | Present in current source? | Proving test |
|----|-----|-------|----------------------------|--------------|
| MIG-BIL-001 | P0 | SoftDeletes model, DDL lacks `deleted_at` | **YES** | V1 `02`, V2 `03` |
| MIG-BIL-002 | P1 | DDL `payment_status NOT NULL VARCHAR(20)` type mis-ordered | **YES (DDL)** | V2 `04` (doc) |
| DATA-BIL-001 | P0 | DDL FK → non-existent `tenant_invoicing_id` / wrong table `bil_tenant_invoicing` | **YES (DDL)** | V2 `44` |
| BUG-BIL-010 | P1 | Payment row `payment_status` = invoice-status form value (not payment enum/Dropdown id) | **YES** (reframed; invoice status derivation is correct) | V1 `90`, V2 `90` |
| BUG-BIL-011 | P2 | `consolidated_amount` populated for single payments | **YES** | V2 `14` |
| VAL-BIL-001 | P2 | Controller uses `$request->` not `validated()`; `mode` has no `in:`; dead `required_if` message | **YES** | V1 `05`, V2 `09,36,93` |
| SEC-BIL-001 | P0 | "no try/catch → open transaction" | **NO — remediated** (try/catch+rollBack present); tested as atomicity | V1 `91`, V2 `91` |
| SEC-BIL-011 | P1 | audit logs `$request->all()` | **NO — remediated** (whitelisted event_info) | V2 `92` |

---

## 3. V2 Test Method Index

| # | Method | TC map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_..._01_table_exists | TC-P01 | Schema | 01–09 |
| 2 | test_..._02_all_ddl_columns_present | TC-P01 | Schema | 01–09 |
| 3 | test_..._03_deleted_at_missing_documents_mig_bil_001 | TC-D02 | Schema/Defect | 01–09 |
| 4 | test_..._04_payment_status_column_is_string_type | MIG-BIL-002 | Schema | 01–09 |
| 5 | test_..._05_model_fillable_matches_ddl | TC-P02 | Model | 01–09 |
| 6 | test_..._06_model_casts_are_correct | TC-P02 | Model | 01–09 |
| 7 | test_..._07_dropdown_relations_declared | TC-P02/BUG-010 | Model | 01–09 |
| 8 | test_..._08_store_request_rules_complete | BC-VAL | Request | 01–09 |
| 9 | test_..._09_request_message_without_matching_rule... | VAL-BIL-001 | Request/Defect | 01–09 |
| 10 | test_..._10_store_increments_invoice_paid_amount | TC-P06 | Biz | 10–19 |
| 11 | test_..._11_paid_amount_is_never_decremented | TC-P07 | Biz | 10–19 |
| 12 | test_..._14_single_payment_sets_consolidated_amount_bug_bil_011 | BUG-BIL-011 | Biz/Defect | 10–19 |
| 13 | test_..._15_payment_reconciled_yes_maps_to_one | TC-P11 | Biz | 10–19 |
| 14 | test_..._20_partial_payment_moves_invoice_to_partial | TC-P08 | SM | 20–29 |
| 15 | test_..._21_completing_payment_marks_invoice_paid_invariant | TC-P09 | SM | 20–29 |
| 16 | test_..._22_overpayment_is_allowed_and_stays_paid | TC-P10 | SM/Edge | 20–29 |
| 17 | test_..._30_missing_tenant_invoice_id_rejected | TC-N01 | Val | 30–39 |
| 18 | test_..._31_nonexistent_invoice_id_rejected | TC-N02 | Val | 30–39 |
| 19 | test_..._32_amount_below_min_rejected | TC-N03 | Val | 30–39 |
| 20 | test_..._33_non_numeric_amount_rejected | TC-N04 | Val | 30–39 |
| 21 | test_..._34_missing_currency_rejected | TC-N05 | Val | 30–39 |
| 22 | test_..._35_missing_payment_mode_rejected | TC-N06 | Val | 30–39 |
| 23 | test_..._36_unconstrained_mode_is_accepted_documents_val_bil_001 | VAL-BIL-001 | Val/Defect | 30–39 |
| 24 | test_..._37_store_rejects_guest | TC-N07 | Auth | 30–39 |
| 25 | test_..._38_xss_in_remarks_is_not_reflected_raw | TC-N08 | Security | 30–39 |
| 26 | test_..._40_payment_belongs_to_invoice | TC-P02 | FK | 40–49 |
| 27 | test_..._42_store_writes_audit_log_row | TC-D01 | Integration | 40–49 |
| 28 | test_..._44_ddl_fk_column_mismatch_documented_data_bil_001 | TC-D03 | FK/Defect | 40–49 |
| 29 | test_..._50_store_request_authorize_is_gated | BC-AUTH-03 | Perm | 50–59 |
| 30 | test_..._51_policy_maps_prime_permissions | BC-AUTH | Perm | 50–59 |
| 31 | test_..._52_tab_requires_authenticated_session | TC-N09 | Perm | 50–59 |
| 32 | test_..._60_tab_loads_with_filters | TC-P03 | UI | 60–69 |
| 33 | test_..._61_table_headers_present | TC-P03 | UI | 60–69 |
| 34 | test_..._62_date_range_and_status_filters_present | TC-P03 | UI | 60–69 |
| 35 | test_..._63_payment_details_panel_lists_expected_columns | TC-P05 | UI | 60–69 |
| 36 | test_..._64_add_payment_form_returns_html | TC-P04 | UI | 60–69 |
| 37 | test_..._70_high_precision_amount_persists_two_decimals | BC-EDG-01 | Edge | 70–79 |
| 38 | test_..._71_negative_amount_is_rejected_by_min_rule | TC-N03 | Edge | 70–79 |
| 39 | test_..._72_currency_defaults_to_inr_from_form | TC-P13 | Edge | 70–79 |
| 40 | test_..._90_payment_status_stores_form_invoice_status_bug_bil_010 | BUG-BIL-010 | Defect | 90–99 |
| 41 | test_..._91_rejected_payment_leaves_no_orphan_row | TC-D04/SEC-BIL-001 | Security | 90–99 |
| 42 | test_..._92_audit_event_info_is_whitelisted_not_request_all | SEC-BIL-011 | Security | 90–99 |
| 43 | test_..._93_controller_reads_request_not_validated... | VAL-BIL-001 | Security/Defect | 90–99 |

**V1 methods:** 17 · **V2 methods:** 43 · **Ratio:** 2.53× (≥ 2× gate met).
