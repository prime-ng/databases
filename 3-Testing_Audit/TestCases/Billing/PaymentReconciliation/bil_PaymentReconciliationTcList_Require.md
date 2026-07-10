# Payment Reconciliation — Test Case List & Business Conditions

**Module:** Billing (`BIL`) · **Prefix:** `bil_` · **Feature:** PaymentReconciliation
**Screen:** `Billing_v1/payment-reconciliation.md` (PRIMARY) · **DB scope:** PRIME / CENTRAL (`prime_db`, `127.0.0.1`)
**Primary tables:** `bil_tenant_invoicing_payments` (+ joined `bil_tenant_invoices`)
**Controller:** `Modules\Billing\Http\Controllers\BillingManagementController@index` (`type=payment-reconcilation`) · `@toggleStatus` · `@printData` · `InvoicingPaymentController@downloadSelectedPdf`
**Policy:** `Modules\Billing\Policies\PaymentReconciliationPolicy`
**Test file (one per screen):** `bil_PaymentReconciliation_TestCas.php` · **Style:** browser Dusk, `extends BillingDuskTestCase`
**Screen type:** READ/REPORT + manual boolean toggle (report-focused matrix — no create/edit/delete CRUD).

---

## 1. Business Conditions

### BC-DB (schema) — Source: `DDL-bil_tenant_invoicing_payments`, `DDL-bil_tenant_invoices`
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `bil_tenant_invoicing_payments` exists with `id, tenant_invoice_id, payment_date, transaction_id, mode, mode_other, amount_paid, consolidated_amount, currency, payment_status, payment_reconciled, remarks` | DDL:62-79 |
| BC-DB-02 | `payment_reconciled` is `tinyint(1) NOT NULL DEFAULT 0` (toggled 0↔1) | DDL:74 / Screen-BR |
| BC-DB-03 | `tenant_invoice_id` is `INT UNSIGNED NOT NULL` FK → `bil_tenant_invoices(id)` | DDL:64,78 |
| BC-DB-04 | Model casts `payment_reconciled=>boolean`, `gateway_response=>array`, `amount_paid=>decimal:2` | Model:31-36 |
| BC-DB-05 | Model `$fillable` includes `tenant_invoice_id, payment_reconciled, remarks, amount_paid, consolidated_amount` | Model:16-29 |
| BC-DB-06 | `bil_tenant_invoices` exists (joined for org/invoice_no/net_payable_amount display) | DDL:4-51 |

### BC-BIZ (business rules / behaviour) — Source: `Screen-BR`, Controller/Model
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Reconciliation is **manual only** — toggle flips `payment_reconciled` with no precondition/validation | Screen-BR (Manual Toggle Only) |
| BC-BIZ-02 | Toggle derives new state from **current value** (`$newStatus = !$payment->payment_reconciled`), not request body | Controller:869 / Screen-EDG |
| BC-BIZ-03 | Every toggle writes an activity-log entry with event **`ToggleStatus`** and message `Payment reconciliation status changed.` (prev/new state) to `sys_activity_logs` | Controller:876-880 / Screen-BR (Audit Trail) |
| BC-BIZ-04 | Reconciled filter (`'Reconciled Transactions Only'`) → `payment_reconciled = 1`; Non-reconciled (`'Non-Reconciled Trans. Only'`) → `= 0`; empty → all | Controller:335-341 / Screen-Filter |
| BC-BIZ-05 | Buckets partition the set: reconciled + non-reconciled = all payments (reconciliation-total correctness) | Derived / Screen-BR |
| BC-BIZ-06 | `date_range` filters by the **invoice's** `invoice_date` via `whereHas('invoice')` | Controller:328-332 / Screen-Filter |
| BC-BIZ-07 | Default query eager-loads the invoice (`InvoicingPayment::with('invoice')`) | Controller:326 |
| BC-BIZ-08 | List paginates 10 per page | Controller:113 |
| BC-BIZ-09 | Toggle JSON: `{success:true, message:'Payment reconciliation updated successfully', data:{payment_reconciled:bool}}` | Controller:882-888 |

### BC-VAL (validation) — Source: Controller / `Screen-VR`
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | No FormRequest / server-side validation on reconciliation filter inputs | Screen (Not Defined in Code) |
| BC-VAL-02 | Toggle on a missing payment id → `findOrFail` → 404 | Controller:866 |
| BC-VAL-03 | `updateInvoiceRemarks` validates `id` required|integer, `remarks` nullable|string|max:5000 → 422 on breach | Controller:758-761 |
| BC-VAL-04 | PDF download with empty `ids` → JSON `{error:'No items selected'}` HTTP 400 | InvoicingPaymentController:363-365 |

### BC-AUTH (permissions) — Source: `Screen-PM`, Policy, Controller gates
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Index accessible only with one of the `Gate::any` billing view abilities; reconciliation branch gates `prime.payment-reconciliation.viewAny`, else `abort(403)` | Controller:61-68,112 |
| BC-AUTH-02 | Toggle gates `prime.billing-management.status` (shared, no reconciliation-specific key) | Controller:806 |
| BC-AUTH-03 | Print (`printData`) gates `prime.billing-management.print` | Controller:143 |
| BC-AUTH-04 | PDF (`downloadSelectedPdf`) gates `prime.invoicing-payment.view` | InvoicingPaymentController:362 |
| BC-AUTH-05 | Guest (unauthenticated) is redirected to `/login` (middleware `auth`,`verified`) | routes web.php:323 |
| BC-AUTH-06 | Super-admin passes all abilities via Spatie `Gate::before` | Audit L.18 |

### BC-REF / BC-INT (integrity / integration) — Source: DDL, Model
| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `tenant_invoice_id` → `bil_tenant_invoices(id)`; DDL declares `ON DELETE CASCADE` | DDL:78 (see DEV-BIL-R06) |
| BC-INT-01 | Reconciliation row references an existing invoice (org/invoice_no resolved through `invoice` relation) | Model:56-59 |

### BC-EDG (edge) — Source: `Screen-EDG`, Audit
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Toggle posts only `_token`; new state inferred from current value | Controller:869 |
| BC-EDG-02 | "Subscription Details" link passes invoice id but `subscriptionDetails()` expects billing-schedule id (DEV-BIL-R05) | Blade:189 / Controller:663 |
| BC-EDG-03 | Remark audit log stores payment id in `tenant_invoice_id` column for payment remarks (DEV-BIL-R04) | Controller:777 |
| BC-EDG-04 | SoftDeletes declared but `deleted_at` absent → `withTrashed()` throws (DEV-BIL-R01 / MIG-BIL-001) | Model:12 / DDL:62-79 |

### Known Source Defects (audit-equivalent DEV-###)
| DEV | Severity | Description | Proving test |
|-----|----------|-------------|--------------|
| DEV-BIL-R01 | P0 (schema) | `InvoicingPayment` uses `SoftDeletes` but `bil_tenant_invoicing_payments` has no `deleted_at`; `withTrashed()`/`forceDelete()` throw `42S22` (audit Layer-2 / MIG-BIL-001) | `_01`, `_42` |
| DEV-BIL-R02 | P2 | PDF button guarded by `prime.payment-reconciliation.pdf`, endpoint authorizes `prime.invoicing-payment.view` (mismatch) | `_52` |
| DEV-BIL-R03 | P2 | Print button guarded by `prime.payment-reconciliation.print`, endpoint authorizes `prime.billing-management.print` (mismatch) | `_53` |
| DEV-BIL-R04 | P3 | Remark audit-log stores payment id in `tenant_invoice_id` column for payment remarks | `_72` |
| DEV-BIL-R05 | P2 | "Subscription Details" link passes invoice id but handler expects billing-schedule id | `_71` |
| DEV-BIL-R06 | P1 (DDL) | Payments FK references non-existent table `bil_tenant_invoicing` (should be `bil_tenant_invoices`) | `_41` (doc) |
| BUG-BIL-014 | P2 | Central billing route block registered 3× (audit RT-04) | `_02` (context) |

---

## 2. Test Case List

### Positive (`TC-P`)
| TC ID | Category | BC | Source | Description | Expected | Method | Status |
|-------|----------|----|--------|-------------|----------|--------|--------|
| TC-P01 | Config | BC-DB-01..06 | DDL/Model | Schema, model, casts, relation, softdelete divergence correct | All asserts pass | `_01` | Automated |
| TC-P02 | Config | BC-AUTH-01..04 | Routes/Policy | Routes + policy abilities registered | Registered | `_02` | Automated |
| TC-P03 | Config | BC-BIZ-03, BC-AUTH-01..04 | Controller | Gate strings + `ToggleStatus` event verbatim | Match source | `_03` | Automated |
| TC-P04 | Render | BC-BIZ-07 | Screen | Tab loads with filters + table | Present | `_10` | Automated |
| TC-P05 | Filter UI | BC-BIZ-04 | Screen | Both reconciliation states offered | Present | `_11` | Automated |
| TC-P06 | Render | BC-DB-01 | Screen | Table exposes reconciliation columns | Present | `_12` | Automated |
| TC-P07 | Filter | BC-BIZ-04 | Controller | Reconciled bucket returns only reconciled | No leakage | `_13` | Automated |
| TC-P08 | Filter | BC-BIZ-04 | Controller | Non-reconciled bucket returns only unreconciled | No leakage | `_14` | Automated |
| TC-P09 | Totals | BC-BIZ-05 | Derived | Buckets partition full set | reconciled+non=all | `_15` | Automated |
| TC-P10 | Toggle | BC-BIZ-02,03 | Controller | Toggle 0→1 + activity log | Flips + logged | `_16` | Automated |
| TC-P11 | Toggle | BC-BIZ-02 | Controller | Toggle 1→0 | Flips | `_17` | Automated |
| TC-P12 | Query | BC-BIZ-06,07 | Controller | Report reflects DB state / eager loads invoice | Well-formed | `_18` | Automated |
| TC-P13 | Print | BC-AUTH-03 | Controller | Reconciliation print view renders | No 500/SQL | `_34` | Automated |
| TC-P14 | UI | BC-BIZ-08 | Controller | Paginates 10/page | Confirmed | `_61` | Automated |
| TC-P15 | Export | BC-AUTH-03,04 | Blade | Print + PDF controls present for admin | Present | `_62` | Automated |

### Negative (`TC-N`)
| TC ID | Category | BC | Source | Description | Expected | Method | Status |
|-------|----------|----|--------|-------------|----------|--------|--------|
| TC-N01 | 404 | BC-VAL-02 | Controller | Toggle missing payment id | 404 (accepted set) | `_30` | Automated |
| TC-N02 | 422 | BC-VAL-03 | Controller | Remark update missing id | 422 (accepted set) | `_31` | Automated |
| TC-N03 | 422 | BC-VAL-03 | Controller | Remark > 5000 chars | 422 (accepted set) | `_32` | Automated |
| TC-N04 | 400 | BC-VAL-04 | Controller | PDF download no ids | 400 (accepted set) | `_33` | Automated |
| TC-N05 | Guest | BC-AUTH-05 | Routes | Guest redirected to `/login` | Redirect | `_50` | Automated |
| TC-N06 | Guest | BC-AUTH-05 | Routes | Guest toggle not 200 | 302/401/419 | `_91` | Automated |
| TC-N07 | AuthZ | BC-AUTH-01 | Controller | Index aborts 403 without billing view ability | `abort(403)` present | `_51` | Automated |
| TC-N08 | XSS | BC-EDG (sec) | Blade | Remarks not echoed unescaped | Escaped | `_90` | Automated |

### Dependency (`TC-D`)
| TC ID | Sub | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-D01 | E | BC-INT-01 | Model | Payment linked to existing invoice | Exists | `_40` | Automated |
| TC-D02 | C | BC-REF-01 | DDL | FK targets `bil_tenant_invoices` (DEV-BIL-R06 note) | Correct target | `_41` | Automated |
| TC-D03 | B | BC-EDG-04 | Model/DDL | SoftDeletes withTrashed fails w/o `deleted_at` (DEV-BIL-R01) | Throws 42S22 | `_42` | Automated |

### Authorization / Edge / Security detail
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-A01 | BC-AUTH-04 | Src compare | PDF endpoint perm ≠ button perm (DEV-BIL-R02) | Differ | `_52` | Automated |
| TC-A02 | BC-AUTH-03 | Src compare | Print endpoint perm ≠ button perm (DEV-BIL-R03) | Differ | `_53` | Automated |
| TC-A03 | BC-AUTH-02 | Controller | Toggle gates `billing-management.status` | Present | `_54` | Automated |
| TC-E01 | BC-EDG-01 | Controller | Toggle uses current value | Confirmed | `_70` | Automated |
| TC-E02 | BC-EDG-02 | Blade/Controller | Subscription-details id-type mismatch (DEV-BIL-R05) | Confirmed | `_71` | Automated |
| TC-E03 | BC-EDG-03 | Controller | Remark audit stores payment id in invoice col (DEV-BIL-R04) | Confirmed | `_72` | Automated |
| TC-U01 | BC-BIZ-04 | Screen | Empty state renders without error | No SQL error | `_60` | Automated |

---

## 3. Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | `test_paymentreconciliation_01_schema_model_and_request_configuration_are_correct` | TC-P01, TC-D03 | Config | 01-09 |
| 2 | `test_paymentreconciliation_02_routes_and_policy_wiring_are_registered` | TC-P02 | Config | 01-09 |
| 3 | `test_paymentreconciliation_03_controller_gates_and_activity_event_strings_are_exact` | TC-P03 | Config | 01-09 |
| 4 | `test_paymentreconciliation_10_tab_loads_with_filters_and_table` | TC-P04 | Biz/Render | 10-19 |
| 5 | `test_paymentreconciliation_11_filter_dropdown_offers_both_reconciliation_states` | TC-P05 | Biz | 10-19 |
| 6 | `test_paymentreconciliation_12_table_exposes_reconciliation_columns` | TC-P06 | Biz/Render | 10-19 |
| 7 | `test_paymentreconciliation_13_reconciled_filter_returns_only_reconciled_rows` | TC-P07 | Biz | 10-19 |
| 8 | `test_paymentreconciliation_14_non_reconciled_filter_returns_only_unreconciled_rows` | TC-P08 | Biz | 10-19 |
| 9 | `test_paymentreconciliation_15_buckets_partition_the_full_set` | TC-P09 | Biz/Totals | 10-19 |
| 10 | `test_paymentreconciliation_16_toggle_flips_unreconciled_to_reconciled_and_logs` | TC-P10 | Biz | 10-19 |
| 11 | `test_paymentreconciliation_17_toggle_flips_reconciled_to_unreconciled` | TC-P11 | Biz | 10-19 |
| 12 | `test_paymentreconciliation_18_reconciliation_report_reflects_db_state` | TC-P12 | Biz | 10-19 |
| 13 | `test_paymentreconciliation_30_toggle_missing_payment_returns_404` | TC-N01 | Validation | 30-39 |
| 14 | `test_paymentreconciliation_31_remark_update_requires_integer_id` | TC-N02 | Validation | 30-39 |
| 15 | `test_paymentreconciliation_32_remark_update_rejects_overlong_remarks` | TC-N03 | Validation | 30-39 |
| 16 | `test_paymentreconciliation_33_pdf_download_without_ids_returns_error` | TC-N04 | Validation | 30-39 |
| 17 | `test_paymentreconciliation_34_print_view_renders_for_reconciliation_type` | TC-P13 | Validation/Render | 30-39 |
| 18 | `test_paymentreconciliation_40_payment_is_linked_to_its_invoice` | TC-D01 | Integration | 40-49 |
| 19 | `test_paymentreconciliation_41_payment_fk_targets_the_invoices_table` | TC-D02 | Integration | 40-49 |
| 20 | `test_paymentreconciliation_42_softdeletes_guard_documents_missing_deleted_at` | TC-D03 | Integration | 40-49 |
| 21 | `test_paymentreconciliation_50_guest_is_redirected_to_login` | TC-N05 | AuthZ | 50-59 |
| 22 | `test_paymentreconciliation_51_index_requires_a_reconciliation_view_permission` | TC-N07 | AuthZ | 50-59 |
| 23 | `test_paymentreconciliation_52_pdf_endpoint_permission_differs_from_button_permission` | TC-A01 | AuthZ | 50-59 |
| 24 | `test_paymentreconciliation_53_print_endpoint_permission_differs_from_button_permission` | TC-A02 | AuthZ | 50-59 |
| 25 | `test_paymentreconciliation_54_toggle_endpoint_gates_billing_management_status` | TC-A03 | AuthZ | 50-59 |
| 26 | `test_paymentreconciliation_60_empty_state_renders_without_error` | TC-U01 | UI/UX | 60-69 |
| 27 | `test_paymentreconciliation_61_reconciliation_list_paginates_ten_per_page` | TC-P14 | UI/UX | 60-69 |
| 28 | `test_paymentreconciliation_62_export_controls_present_for_permitted_admin` | TC-P15 | UI/UX | 60-69 |
| 29 | `test_paymentreconciliation_70_toggle_uses_current_value_not_request_body` | TC-E01 | Edge | 70-79 |
| 30 | `test_paymentreconciliation_71_subscription_details_link_passes_invoice_id_edge` | TC-E02 | Edge | 70-79 |
| 31 | `test_paymentreconciliation_72_remark_audit_log_stores_payment_id_in_invoice_column_edge` | TC-E03 | Edge | 70-79 |
| 32 | `test_paymentreconciliation_90_remark_value_is_escaped_in_details_view` | TC-N08 | Security | 90-99 |
| 33 | `test_paymentreconciliation_91_toggle_rejects_unauthenticated_request` | TC-N06 | Security | 90-99 |

**Total: 33 test methods** (report-focused screen). Every TC-ID maps to ≥1 method; every method maps back to a TC/BC.
