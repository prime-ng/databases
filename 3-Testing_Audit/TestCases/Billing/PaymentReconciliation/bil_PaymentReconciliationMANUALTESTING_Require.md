# Payment Reconciliation — Manual Testing Specification

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | Billing (`BIL`) |
| Feature / Screen | PaymentReconciliation (`Billing_v1/payment-reconciliation.md`) |
| DB scope | **PRIME / CENTRAL** (`prime_db`) — Super-Admin SaaS billing. Runs on `http://127.0.0.1:8000`. |
| URL | `GET /billing/billing-management?type=payment-reconcilation` (tab within Billing Management) |
| Controller | `BillingManagementController@index / @toggleStatus / @printData`; `InvoicingPaymentController@downloadSelectedPdf` |
| Models | `Modules\Billing\Models\InvoicingPayment` (table `bil_tenant_invoicing_payments`), `BilTenantInvoice` (`bil_tenant_invoices`) |
| Policy | `PaymentReconciliationPolicy` (abilities `prime.payment-reconciliation.*`) |
| Validation | None on filters; `updateInvoiceRemarks` → `id required|integer`, `remarks nullable|string|max:5000` |
| Migrations | **None** — DDL `Billing_DDL_v1.sql` is the schema authority (0 executable migrations) |
| CRUD Type | Read/Report + manual boolean toggle (`payment_reconciled`) |
| Soft Delete | Model declares `SoftDeletes` but table has **no `deleted_at`** → broken (DEV-BIL-R01 / MIG-BIL-001) |
| Pagination | 10 per page (`buildPaymentReconciliationQuery()->paginate(10)`) |
| Activity Log | `sys_activity_logs` via `activityLog()`; event string **`ToggleStatus`** (verbatim) |
| Prerequisite | Billing module **enabled** in `prime_testing/modules_statuses.json`; `APP_ENV=testing`; central host `127.0.0.1`. |

**Tab / filter selectors (verbatim from Blade — note the misspelling `reconcilation`):**
- Tab: `#payment-reconcilation-tab` · Pane: `#payment-reconcilation-pane`
- Filters: `input[name="date_range"]`, `select[name="payment_reconcilation_status"]` (values `Reconciled Transactions Only`, `Non-Reconciled Trans. Only`)
- Row toggle: `.toggle-reconcile[data-id="{id}"]` → POST `route('central...billing-management.toggleStatus', id)`
- Print button: `#printFiltered` · PDF button: `#downloadPDFMultiBtnsReconcilation`

---

## 2. Business Conditions (detailed)

### BC-BIZ-02/03 — Toggle & Audit
```
User clicks reconcile switch on a payment row
  → POST /billing/billing-management/{id}/toggle-status   (only _token in body)
  → Gate::authorize('prime.billing-management.status')
  → InvoicingPayment::findOrFail(id)
  → $newStatus = !$payment->payment_reconciled            (flip by current value)
  → save payment_reconciled = $newStatus
  → activityLog($payment, 'ToggleStatus', {message:'Payment reconciliation status changed.', previous_status, new_status})   → sys_activity_logs
  → JSON {success:true, message:'Payment reconciliation updated successfully', data:{payment_reconciled:$newStatus}}
```

### BC-BIZ-04/05 — Filter buckets (reconciliation-total correctness)
```
payment_reconcilation_status = 'Reconciled Transactions Only'   → where payment_reconciled = 1
payment_reconcilation_status = 'Non-Reconciled Trans. Only'     → where payment_reconciled = 0
payment_reconcilation_status = '' (empty)                       → no reconciliation constraint
INVARIANT: count(reconciled=1) + count(reconciled=0) == count(all)
date_range → whereHas('invoice', invoice_date BETWEEN start AND end)
```

### Error messages / responses (verbatim)
| Action | Response |
|--------|----------|
| Toggle on missing id | `findOrFail` → HTTP 404 |
| Remark update invalid | HTTP 422 (validation: `id required|integer`, `remarks max:5000`) |
| PDF download, no ids | JSON `{"error":"No items selected"}` HTTP 400 |
| Remark saved | JSON `{"status":true,"message":"Remarks updated successfully!"}` + audit `action_type='Remark Updated'` |

### Known defect flows
- **DEV-BIL-R01/MIG-BIL-001:** `withTrashed()`/`forceDelete()` on `InvoicingPayment` throw `SQLSTATE[42S22] Unknown column 'deleted_at'`.
- **DEV-BIL-R02:** PDF button visible with `prime.payment-reconciliation.pdf`; endpoint authorizes `prime.invoicing-payment.view` → button-visible-but-403 (or reverse) possible.
- **DEV-BIL-R03:** Print button visible with `prime.payment-reconciliation.print`; endpoint authorizes `prime.billing-management.print`.
- **DEV-BIL-R04:** Payment-remark audit log writes `tenant_invoice_id = payment id` (not invoice id).
- **DEV-BIL-R05:** "Subscription Details" passes `tenant_invoice_id`; handler `findOrFail`s a billing-schedule by that id → wrong record / 404.
- **DEV-BIL-R06:** DDL FK on payments references non-existent `bil_tenant_invoicing` (should be `bil_tenant_invoices`).

---

## 3. Test Cases (Step / Action / Expected)

### TC-P04 — Reconciliation tab loads (method `_10`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Authenticate at `/login` as central admin | Redirected off `/login` |
| 2 | Visit `/billing/billing-management` | Path is `/billing/billing-management`, no 403/404/419 |
| 3 | Activate Payment Reconciliation tab | `#payment-reconcilation-pane` visible |
| 4 | Inspect filters/table | `input[name=date_range]`, `select[name=payment_reconcilation_status]`, pane `table` present |

### TC-P07/P08/P09 — Filter buckets & totals (methods `_13/_14/_15`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed/resolve one reconciled + one unreconciled payment | Rows available (else skip) |
| 2 | `SELECT COUNT(*) WHERE payment_reconciled=1` | Reconciled bucket count |
| 3 | `SELECT COUNT(*) WHERE payment_reconciled=0` | Non-reconciled bucket count |
| 4 | Compare | `bucket1 + bucket0 == COUNT(*) all` (no leakage/overlap) |

### TC-P10 — Toggle 0→1 + audit (method `_16`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed unreconciled payment (`payment_reconciled=0`) | Row created |
| 2 | Click `.toggle-reconcile[data-id=ID]` (or POST toggle endpoint) | AJAX success |
| 3 | `SELECT payment_reconciled FROM bil_tenant_invoicing_payments WHERE id=ID` | `= 1` |
| 4 | Check `sys_activity_logs` (if present) | Recent row with event `ToggleStatus` |
| 5 | Cleanup | Hard-delete seeded row |

### TC-N01 — Toggle missing id 404 (method `_30`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | `actingAs` admin | Authenticated |
| 2 | POST `/billing/billing-management/999999123/toggle-status` | Status ∈ {404,403,419,302} |

### TC-N04 — PDF no ids (method `_33`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `/billing/payment-reconciliation/download-pdf` with `ids=[]` | Status ∈ {400,403,419,302}; body `{"error":"No items selected"}` when 400 |

### TC-N05 — Guest redirect (method `_50`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Clear cookies | Session cleared |
| 2 | Visit `/billing/billing-management?type=payment-reconcilation` | Path contains `/login` |

### TC-D03 — SoftDeletes divergence (method `_42`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Confirm `deleted_at` absent on payments table | Absent |
| 2 | `InvoicingPayment::withTrashed()->limit(1)->get()` | Throws `Unknown column 'deleted_at' / 42S22` (DEV-BIL-R01) |

### TC-A01/A02 — Permission mismatch (methods `_52/_53`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Read `InvoicingPaymentController@downloadSelectedPdf` | Gates `prime.invoicing-payment.view` |
| 2 | Read reconciliation Blade PDF button | `@can('prime.payment-reconciliation.pdf')` |
| 3 | Compare | Differ → DEV-BIL-R02 (same pattern for print → DEV-BIL-R03) |

### TC-U01 — Empty state (method `_60`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit reconciliation tab with `date_range=01-01-2099 - 31-12-2099` | No data rows |
| 2 | Inspect pane | `table` present, no `SQLSTATE` error |

### TC-N08 — XSS in remarks (method `_90`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Read `invoice-remarks.blade.php` | No `{!! $invoice->remarks !!}` unescaped echo (Blade `{{ }}` escaping) |

(Remaining methods `_01,_02,_03,_11,_12,_17,_18,_31,_32,_34,_40,_41,_51,_54,_61,_62,_70,_71,_72,_91` follow the same Step/Action/Expected shape and are automated 1:1 in `bil_PaymentReconciliation_TestCas.php`.)
