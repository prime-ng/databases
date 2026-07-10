# Invoice Payments — Manual Testing Specification

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | Billing |
| Feature | InvoicingPayment (Invoice Payments tab) |
| DB scope | **prime_db CENTRAL** — Super-Admin billing management (no tenant context) |
| URL (tab) | `http://127.0.0.1:8000/billing/billing-management` → tab `#invoicing-payment-tab` / pane `#invoicing-payment-pane` |
| Record payment | `POST /billing/invoicing-payment` (name `billing.invoicing-payment.store`) |
| Add-payment form (AJAX) | `GET /billing/invoicing-payment/create?id={invoice_id}` → `{html}` |
| Payment details (AJAX) | `GET /billing/billing/payment-details?id={invoice_id}` → `{html}` |
| Consolidated store | `POST /billing/billing/consolidated-store` |
| Controller | `Modules\Billing\Http\Controllers\InvoicingPaymentController` |
| FormRequest | `Modules\Billing\Http\Requests\StoreInvoicePaymentRequest` |
| Model | `Modules\Billing\Models\InvoicingPayment` (table `bil_tenant_invoicing_payments`) |
| Policy | `Modules\Billing\Policies\InvoicingPaymentPolicy` (`Modules\Prime\Models\User`) |
| Migrations | Raw DDL `Billing_DDL_v1.sql` (no Laravel migration file for this table) |
| Soft delete | Model uses `SoftDeletes` **but DDL has no `deleted_at`** → MIG-BIL-001 (P0) |
| Pagination | 10/page on the tab list (`$resultsPayment->links()`) |
| Activity log | `activityLog($invoice, 'Store', ['message' => 'Invoice Payment Data Updated .'])` (event literal `Store`) + `bil_tenant_invoicing_audit_logs` row per payment |
| Permissions | `prime.invoicing-payment.{viewAny\|view\|create\|update\|delete\|print\|remark\|pdf}` |

### Environment prerequisites
- **Billing module must be ENABLED** in `prime_testing/modules_statuses.json` (disabled ⇒ 404 on all routes — E19).
- `APP_ENV=testing` for the Dusk run (bypasses CSRF/419 — E20).
- Prime tests must run against `http://127.0.0.1:8000` (enforced by `PrimeDuskTestCase`).
- Central admin resolvable via `is_super_admin=1` or `DUSK_ADMIN_EMAIL`/`DUSK_ADMIN_PASSWORD`.
- At least one `bil_tenant_invoices` row must exist for the payment-recording cases (Billing ships no factories — mutation cases skip cleanly if none exists).

---

## 2. Business Conditions (detailed)

### Cumulative paid + status auto-calc (BC-BIZ-01..03, BC-SM)
```
store(payload):
  paid_amount = paid_amount + amount_paid            # never decremented
  if paid_amount >= net_payable_amount:  status = PAID
  elif paid_amount > 0:                  status = PARTIALLY_PAID
  else:                                   status = PENDING
  # overpayment (paid > net) allowed -> still PAID
```
Invoice status IDs are resolved from `Dropdown` (`bil_tenant_invoices.status`).

### Transaction atomicity (BC-BIZ-04 — SEC-BIL-001 remediated)
```
DB::beginTransaction()
try { create payment; update invoice; create audit log; activityLog(); DB::commit(); }
catch (Exception e) { DB::rollBack(); return 500 JSON; }
```
> Screen doc claims "no try/catch". **Current source HAS it.** Manual check: submit an invalid payload → confirm NO orphan payment row.

### Audit event_info whitelist (BC-BIZ-05 — SEC-BIL-011 remediated)
`event_info` = JSON of `{payment_id, previous_paid, amount_added, new_paid_amount, payment_mode, payment_status, payment_date, transaction_id, remarks}`. **Not** `$request->all()`. Manual check: inspect `bil_tenant_invoicing_audit_logs.event_info` → must not contain `_token` or raw form dump.

### Defect flows
- **BUG-BIL-010:** payment row `payment_status` receives `invoice_payments` (PENDING/PARTIAL/PAID) — invoice-status text, mismatching DDL enum {INITIATED,SUCCESS,FAILED} and the `paymentStatusData()` Dropdown-id relation.
- **BUG-BIL-011:** `consolidated_amount` set = `amount_paid` on every single payment (should be NULL unless consolidated).
- **VAL-BIL-001:** controller reads `$request->date` / `$request->tenant_invoice_id` directly (not `$request->validated()`); `payment_mode` has no `in:` enum; `pay_mode_other.required_if` message has no matching rule.
- **MIG-BIL-001 (P0):** `SoftDeletes` + no `deleted_at`.
- **MIG-BIL-002:** DDL `payment_status NOT NULL VARCHAR(20)` mis-ordered.
- **DATA-BIL-001:** DDL FK references col `tenant_invoicing_id` (absent) / table `bil_tenant_invoicing` (wrong) — runtime column is `tenant_invoice_id`.

---

## 3. Manual Test Cases (Step / Action / Expected — with DB & activity-log checks)

### TC-P03 — Invoice Payment tab loads
| Step | Action | Expected |
|------|--------|----------|
| 1 | Log in as central Super-Admin | Dashboard |
| 2 | Visit `/billing/billing-management` | Billing Management loads (no 403/404/419) |
| 3 | Click `#invoicing-payment-tab` | `#invoicing-payment-pane` visible |
| 4 | Inspect filter bar | `input[name="date_range"]`, `select[name="payment_status"]`, hidden `type=invoice_payment` present |
| 5 | Inspect table head | Columns: Organization, Invoice No., Invoice Date, Paymen Due Date, Invoice Amount, Total Amount Paid, Payment Status, Action |

### TC-P04 — Add-payment form (AJAX)
| Step | Action | Expected |
|------|--------|----------|
| 1 | On a row, click **Recd. Payment** (`.add-payment-details`) | AJAX `GET /billing/invoicing-payment/create?id={id}` |
| 2 | Inspect response | `{html}` containing `<form id="invoicePaymentForm">`, Date, Payment Mode dropdown, Amount Paid, Currency=INR |

### TC-P06 / TC-P08 — Record partial payment
| Step | Action | Expected |
|------|--------|----------|
| 1 | Note invoice `net_payable_amount` (N) and `paid_amount` (P) | e.g. N=1000, P=0 |
| 2 | Submit payment amount_paid=1.00, invoice_payments=PARTIAL | JSON `{status:true, message:'Payment saved successfully!'}` |
| 3 | `SELECT paid_amount FROM bil_tenant_invoices WHERE id={id}` | = P + 1.00 |
| 4 | `SELECT status FROM bil_tenant_invoices WHERE id={id}` | derived → PARTIALLY_PAID (0<paid<net) |
| 5 | `SELECT payment_status, consolidated_amount FROM bil_tenant_invoicing_payments ORDER BY id DESC LIMIT 1` | payment_status='PARTIAL' (**BUG-BIL-010**); consolidated_amount=1.00 (**BUG-BIL-011**) |
| 6 | `SELECT COUNT(*) FROM bil_tenant_invoicing_audit_logs WHERE tenant_invoice_id={id}` | +1 (BC-INT-01) |
| 7 | Inspect `event_info` of that audit row | whitelisted keys only; no `_token`/raw dump (SEC-BIL-011) |

### TC-P09 — Complete payment → PAID
| Step | Action | Expected |
|------|--------|----------|
| 1 | Submit amount_paid = remaining (net − paid) | success |
| 2 | `SELECT paid_amount, status` | paid ≥ net; status = PAID |

### TC-P10 — Overpayment allowed
| Step | Action | Expected |
|------|--------|----------|
| 1 | Submit amount_paid = net + 100 | success |
| 2 | `SELECT paid_amount, status` | paid > net; status = PAID |

### TC-N01 — Missing invoice
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST store without `tenant_invoice_id` (authenticated) | 422; "Invoice is required." |

### TC-N02 — Non-existent invoice
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST store `tenant_invoice_id=999999999` | 422; "Selected invoice does not exist." |

### TC-N03 — Amount below minimum
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST store `amount_paid=0` (or negative) | 422; "Payment amount must be greater than zero." |

### TC-N07 — Guest blocked
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `/billing/invoicing-payment` while logged out | 302 → /login (or 401/419) |

### TC-N08 — XSS in remarks
| Step | Action | Expected |
|------|--------|----------|
| 1 | Record payment with `remarks='<script>alert(1)</script>'` | success (stored verbatim) |
| 2 | Open Payment Details panel | remarks rendered escaped; no live `<script>` in DOM |

### TC-D04 / TC-D02 — Atomicity + soft-delete gap
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST store with `amount_paid` omitted | 422; NO new payment row (atomicity) |
| 2 | `SHOW COLUMNS FROM bil_tenant_invoicing_payments LIKE 'deleted_at'` | empty → MIG-BIL-001 confirmed |
| 3 | Attempt `InvoicingPayment::first()->delete()` | fails / errors on missing `deleted_at` (document, do not fix) |
