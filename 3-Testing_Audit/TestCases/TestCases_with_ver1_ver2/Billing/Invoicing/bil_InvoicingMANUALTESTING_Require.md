# Invoicing (Invoice Generation) — Manual Test Specification (`bil_InvoicingMANUALTESTING_Require`)

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | Billing (central / prime_db SaaS admin) |
| Feature / Screen | Invoicing (`invoicing.md`) — Invoicing tab of Billing Management |
| URL | `/billing/billing-management` (tab `#invoicing-tab` / pane `#invoicing-pane`) |
| Controller | `Modules\Billing\Http\Controllers\BillingManagementController` |
| Models | `BilTenantInvoice` (SoftDeletes+HasFactory), `InvoicingAuditLog`, `BillOrgInvoicingModulesJnt`, `InvoicingPayment` |
| Validation | Inline `$request->validate()` (remarks: `id` required integer, `remarks` nullable string max:5000); `store` guards `ids` is a present array; filters presence-validated only |
| Migrations | 0 (DDL `Billing_DDL_v1.sql` is schema authority) |
| CRUD Type | Read/report tab + bulk **Generate** action + AJAX detail panels (no create/edit page) |
| Soft Delete | Model uses `SoftDeletes`; DDL lacks `deleted_at` → **MIG-BIL-001 (P0)** (dev DB hand-patched) |
| Pagination | 10 per page (`paginate(10)`) |
| Activity Log | `activityLog($invoice, 'Store', ...)` on generation (event literal **`Store`**); domain audit rows in `bil_tenant_invoicing_audit_logs` (`action_type='GENERATED'`) |
| DB scope | **prime_db central** — no tenant init in test; generation path calls `Tenancy::initialize()/end()` internally to count students |
| Permissions | Controller/Policy: `prime.billing-management.*`. **Blade buttons gate on `prime.invoicing.*` (mismatch → DEV-BIL-INV-001)** |
| Test style | Browser Dusk, central `http://127.0.0.1:8000` (mirrors `prm_InvoicingTab_TestCas`) |

---

## 2. Business Conditions (detailed)

### Invoice generation flow (BC-BIZ)

```
store(ids[])  →  for each schedule id:
  generateInvoiceForOrganization(id):
    1. find TenantPlanBillingSchedule (else ['status'=>false,'message'=>'No billing schedule found.'])
    2. find applicable TenantPlanRate by tenant_plan_id + date window (else 'No applicable plan rate found.')
    3. find Tenant (else 'Tenant not found.')
    4. Tenancy::initialize(tenant); try { count active students in date window } finally { Tenancy::end() }   ← SEC-BIL-005 remediated (try/finally, BEFORE prime tx)
    5. DB::transaction (retry ≤5 on unique-invoice collision — BUG-BIL-015 mitigated):
         invoice_no  = 'INV-'.date('Ymd').'-'.str_pad(todayCount+1,3,'0')      ← BC-BIZ-01
         billing_qty = max(min_billing_qty, total_user_qty)                    ← BC-BIZ-05
         sub_total   = plan_rate * billing_qty                                 ← BC-BIZ-02
         discount    = sub_total * discount_percent/100
         tax_base    = sub_total - discount + extra_charges
         taxN        = tax_base * taxN_percent/100 ; total_tax = Σ taxN        ← BC-BIZ-03
         net_payable = sub_total - discount + extra_charges + total_tax        ← BC-BIZ-04
         payment_due_date = invoice_date + credit_days                        ← BC-BIZ-06
         status      = Dropdown('bil_tenant_invoices.status.invoice_status', ordinal 1).id   ← D37 (id, not 'PENDING')
         create invoice → activityLog(invoice,'Store') → schedule.bill_generated=1, generated_invoice_id
         insert module junction rows → InvoicingAuditLog(action_type='GENERATED')
  returns JSON {status:true, success_ids:[...], failed_ids:[{id,reason}]}      ← BC-BIZ-09 (array contract, BUG-BIL-011 remediated)
```

### Error messages (verbatim)
- Generate, non-array ids → HTTP 400 `{status:false, message:"No plan rate IDs received."}`
- Generate, missing schedule → row in `failed_ids` with `reason:"No billing schedule found."`
- Generate, unique collision after 5 attempts → `reason:"Failed to generate unique invoice number after several attempts due to concurrency."`
- Remarks updated → `{status:true, message:"Remarks updated successfully!"}`

---

## 3. Test Cases (Step / Action / Expected Result)

### TC-P04 — Invoicing tab loads with filters

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Log in as Super Admin; visit `/billing/billing-management` | Billing Management page renders (no 403/404/login) |
| 2 | Ensure the Invoicing tab is active | `#invoicing-pane` visible |
| 3 | Inspect the filter bar | `select[name="data_type"]`, `input[name="date_range"]`, `select[name="status"]` present |
| 4 | Inspect the results area | `#invoicing-pane table` present |
| DB | — | No mutation |

### TC-P06 — Invoice number format

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Compute `INV-`+`date('Ymd')`+`-`+`str_pad(count+1,3,'0')` | Matches `/^INV-\d{8}-\d{3}$/` |
| 2 | For the first invoice of the day | Ends `-001` |

### TC-P07 / TC-P09 / TC-P10 — Financial formulas (worked example: rate 100, qty 10, disc 10%, extra 50, tax1/2 9%)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | sub_total = 100 × 10 | 1000 |
| 2 | discount = 1000 × 10% | 100 |
| 3 | tax_base = 1000 − 100 + 50 | 950 |
| 4 | total_tax = 950×9% + 950×9% | 171 |
| 5 | net_payable = 1000 − 100 + 50 + 171 | 1121 |
| 6 | payment_due (2026-03-01 + 15) | 2026-03-16 |

### TC-D05 — Generate store contract (missing schedule)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Authenticated POST `/billing/billing-management` with `ids=[<bogus>]` | HTTP 200 |
| 2 | Inspect body | `{status:true, success_ids:[], failed_ids:[{id,reason:"No billing schedule found."}]}` (array contract — BUG-BIL-011 fixed) |
| DB | `SELECT COUNT(*) FROM bil_tenant_invoices WHERE …bogus` | 0 rows created |

### TC-N01 / TC-N02 — Remarks validation

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Authenticated POST `/billing/invoice/remarks/update` with no `id` | 422 (id required) |
| 2 | POST with `remarks` of 5001 chars | 422 (max:5000) |

### TC-N04 / TC-S01 — Auth

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | As guest, visit `/billing/billing-management` | Redirected to `/login` |
| 2 | As guest, visit `/billing/invoice-details?id=1` | Redirected to `/login` (never anonymous data) |

### TC-N07 / TC-N08 — Detail endpoints, bogus id

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Authenticated GET `/billing/invoice-details?id=<bogus>` | 404 (`findOrFail`), never 200 with data |
| 2 | Authenticated GET `/billing/subscription-details?id=<bogus>` | 404 (`findOrFail`) |

### TC-D01 / TC-D02 — FK integrity

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `information_schema` FK rules on `bil_tenant_invoices` | `tenant_id`/`tenant_plan_id` = CASCADE; `billing_cycle_id` = RESTRICT |

### TC-SM (cross-module / DEV — manual only)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Post a partial payment (Payment module) on a PENDING invoice | Status → PARTIALLY_PAID (BC-SM-02) |
| 2 | Post full payment | Status → PAID (BC-SM-03) — **note BUG-BIL-010: status is client-supplied, not derived** |
| 3 | Attempt to set a PAID invoice back to PENDING | **Currently accepted** (illegal transition not server-guarded) → log DEV |

### DEV / Documentation checks (manual confirmation)

| ID | Check | Expected |
|----|-------|----------|
| MIG-BIL-001 | `SHOW COLUMNS FROM bil_tenant_invoices LIKE 'deleted_at'` | Column exists in dev (hand-patched); absent on a DDL-only build → SoftDeletes breaks |
| DEV-BIL-INV-001 | Compare Blade `@can('prime.invoicing.*')` vs Controller/Policy `prime.billing-management.*` | Mismatch — a user with `prime.billing-management.*` sees no action buttons (gated on `prime.invoicing.*`) |
| BUG-BIL-013 | `Route::has('central.billing.billing-management.view')` vs controller `view()` | Route may exist but controller has no `view()` method |
| BUG-BIL-014 | Central billing route block | Registered 3× (last-wins) |
