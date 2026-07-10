# Payment Reconciliation — Test Case List & Business Conditions

**Module:** Billing (BIL) · **Feature/Screen:** Payment Reconciliation (`payment-reconciliation.md`)
**Layer:** prime_db **central** (Prime layer — NOT tenant; no tenant init)
**Prefix:** `bil_` (primary table `bil_tenant_invoicing_payments`, column `payment_reconciled`, DDL line 74)
**Type:** Status-toggle-on-existing-payment **+ report** (no create/edit/delete matrix)
**Primary source:** `BillingManagementController@toggleStatus` + `buildPaymentReconciliationQuery`, `InvoicingPaymentController@downloadSelectedPdf`, `InvoicingPayment` model, `PaymentReconciliationPolicy`, routes/web.php 335-336 + 390, reconciliation Blade partial, `activityLog()` helper → `sys_activity_logs`.
**Test style:** Browser Dusk (central chain) mirroring committed sibling `prm_PaymentReconciliationTab_TestCas`; base class `prm_BillingDuskTestCase_TestCas`.

---

## 1. Business Conditions

### BC-DB — Schema (Source: `DDL-bil_tenant_invoicing_payments`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `payment_reconciled` `tinyint(1) NOT NULL DEFAULT 0` (0=unreconciled, 1=reconciled) | DDL:74 |
| BC-DB-02 | PK `id INT UNSIGNED`; row is one payment against one invoice | DDL:63 |
| BC-DB-03 | `tenant_invoice_id INT UNSIGNED NOT NULL` FK → `bil_tenant_invoices` (DDL FK text malformed: references `bil_tenant_invoicing`/`tenant_invoicing_id` — see Known Defects) | DDL:64,79 |
| BC-DB-04 | Table has `created_at`/`updated_at`; **no `deleted_at`** despite model `SoftDeletes` (MIG-BIL-001) | DDL:76-77 |

### BC-VAL — Validation (Source: controller, `Screen §CRUD`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `toggleStatus` performs **no** body validation — it flips by current value only; unknown/missing id → `findOrFail` 404 | Controller:962-1047 / Screen-BR |
| BC-VAL-02 | (Adjacent) `updateInvoiceRemarks` validates `id` required integer, `remarks` nullable string max 5000 | Controller:913-919 |
| BC-VAL-03 | `downloadSelectedPdf` requires non-empty `ids[]`; empty → JSON `{error:'No items selected'}` HTTP 400 | InvoicingPaymentController:363-365 |

### BC-AUTH — Authorization (Source: controller gates, policy, `Screen §Permissions`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Reconciliation list branch: `Gate::authorize('prime.payment-reconciliation.viewAny')` | Controller:106 / Screen-PM |
| BC-AUTH-02 | Toggle: `Gate::authorize('prime.billing-management.status')` (NOT `payment-reconciliation.status`) | Controller:964 / Screen-PM |
| BC-AUTH-03 | PDF export: `Gate::authorize('prime.invoicing-payment.view')` — **mismatch** vs UI `@can('prime.payment-reconciliation.pdf')` (DEV-BIL-R01) | InvoicingPaymentController:362 + Blade:93 |
| BC-AUTH-04 | Print: `Gate::authorize('prime.billing-management.print')` | Controller:137 |
| BC-AUTH-05 | Super-admin `Gate::before` resolves every dotted ability (auth not bypassed; policies dead-but-harmless) | AppServiceProvider / Audit |
| BC-AUTH-06 | All billing routes behind `auth`,`verified`; guest → redirect `/login` | routes/web.php |

### BC-BIZ — Business logic (Source: `Screen-BR`, controller, activity log)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Manual toggle only: flips `payment_reconciled` 0↔1, no precondition/automated matching | Screen-BR "Manual Toggle Only" |
| BC-BIZ-02 | Toggle JSON: `{success:true, message:'Payment reconciliation updated successfully', data:{payment_reconciled:bool}}` | Controller:1040-1046 |
| BC-BIZ-03 | Every toggle logged via `activityLog($payment,'ToggleStatus',[...])` → `sys_activity_logs`; message `'Payment reconciliation status changed.'` + `previous_status`/`new_status` | Controller:1034-1038 / Screen-BR "Audit Trail" |
| BC-BIZ-04 | `buildPaymentReconciliationQuery()` = `InvoicingPayment::with('invoice')` + three-way status filter (+ optional date_range via `whereHas('invoice')`) | Controller:318-338 / Screen §Filter |
| BC-BIZ-05 | `downloadSelectedPdf` returns `application/pdf` for selected payment ids | InvoicingPaymentController:360-381 |
| BC-BIZ-06 | Print writes `activityLog(...,'Store','Payment Reconcilation Data Print.')` | Controller:180-186 |

### BC-SM — State machine: `payment_reconciled` (Source: `Screen-BR`, `toggleStatus`)
| ID | State → Trigger → Next | Legality | Source |
|----|-----------------------|----------|--------|
| BC-SM-01 | Unreconciled(0) → toggle → Reconciled(1) | Legal | Screen-SM |
| BC-SM-02 | Reconciled(1) → toggle → Unreconciled(0) | Legal | Screen-SM |
| — | No illegal transitions exist (pure boolean flip, no precondition guard — noted as a gap in Screen "No validation or precondition check") | n/a | Screen-BR |

### BC-REF / BC-INT — References & integration
| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `tenant_invoice_id` → `bil_tenant_invoices.id` (DDL comment ON DELETE CASCADE) | DDL:79 |
| BC-INT-01 | `InvoicingPayment::invoice()` belongs-to `BilTenantInvoice` — used for Organization/Invoice No. display | Model:56-59 |
| BC-INT-02 | Activity logs written to GlobalMaster `sys_activity_logs` (cross-module sink) | activityLog.php / ActivityLog model |

### BC-EDG — Edge cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Toggle route param named `{session}` (`/billing-management/{session}/toggle-status`) but controller binds positionally by id via `findOrFail` — misnomer, functionally works | routes/web.php:335 / Controller:962 |
| BC-EDG-02 | Filter is exact string match: `''`=all, `'Reconciled Transactions Only'`=1, `'Non-Reconciled Trans. Only'`=0; any other value falls through → all. Empty `date_range` applies **no** date filter (not today-scoped) | Controller:329-335 |
| BC-EDG-03 | Model `SoftDeletes` vs no `deleted_at` column → any Eloquent query appends `WHERE deleted_at IS NULL` and can throw on a schema-correct DB (MIG-BIL-001) | Audit MIG-BIL-001 |

---

## 2. Test Case List

### Positive
| TC ID | Cat | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|-----|----|--------|-------------|----------|----|----|--------|
| TC-P01 | Schema | BC-DB-01..04 | DDL | Table/column/model config truth | Column tinyint(1), fillable, boolean cast, invoice relation | 01,02 | 01,02,03,04,06 | Ready |
| TC-P02 | Report | BC-AUTH-01 | Screen-PM | Tab loads with filters | Pane + date_range + status select + table present | 03 | 60 | Ready |
| TC-P03 | Report | BC-EDG-02 | Screen | Three-way status options present | Both option labels visible | 04 | 61 | Ready |
| TC-P04 | Report | BC-BIZ-04 | Controller | Table columns render | Org/Invoice No./Payment Date/Reconcile headings | 05 | 64 | Ready |
| TC-P05 | State | BC-SM-01,BC-BIZ-02 | Screen-SM | Toggle 0→1 | JSON success + persisted 1 | 06 | 10 | Ready |
| TC-P06 | State | BC-SM-02 | Screen-SM | Toggle 1→0 | JSON `data.payment_reconciled=false` + persisted 0 | — | 11 | Ready |
| TC-P07 | State | BC-BIZ-01 | Screen-BR | Double toggle round-trips | Value returns to original | — | 12 | Ready |
| TC-P08 | State | BC-BIZ-01 | Controller | Toggle ignores body | Flip by current value regardless of body | — | 13 | Ready |
| TC-P09 | Audit | BC-BIZ-03 | Controller | Toggle writes `ToggleStatus` log | Row in sys_activity_logs, subject=InvoicingPayment | 07 | 20 | Ready |
| TC-P10 | Audit | BC-BIZ-03 | Controller | Log records acting admin | `user_id` = admin id | 07 | 21 | Ready |
| TC-P11 | Audit | BC-BIZ-03 | Controller | Log properties carry transition | message + previous_status/new_status | — | 22 | Ready |
| TC-P12 | Audit | BC-BIZ-03 | Screen-BR | Append-only: N toggles → N rows | count increases by N | — | 23 | Ready |
| TC-P13 | Auth | BC-AUTH-01,05 | Screen-PM | Admin views reconciliation index | HTTP 200 | 12 | 50 | Ready |
| TC-P14 | Auth | BC-AUTH-02 | Controller | Toggle gate string | `prime.billing-management.status` in source | — | 51 | Ready |
| TC-P15 | Auth | BC-AUTH-01 | Controller | Index gate string | `prime.payment-reconciliation.viewAny` in source | 01 | 52 | Ready |
| TC-P16 | Auth | BC-AUTH-03 | DEV-BIL-R01 | PDF gate mismatch documented | endpoint gate `invoicing-payment.view` | 14 | 53 | Ready |
| TC-P17 | Auth | BC-AUTH-01 | Audit | Policy import remediated | No `App\Models\PaymentReconciliation` import | — | 54 | Ready |
| TC-P18 | Report | BC-BIZ-04 | Controller | Reconciled-only filter loads | HTTP 200 | — | 62 | Ready |
| TC-P19 | Report | BC-BIZ-04 | Controller | Non-reconciled-only filter loads | HTTP 200 | — | 63 | Ready |
| TC-P20 | Report | BC-BIZ-04 | Controller | Report headings render | Amount Recd./Reconcile etc. visible | 05 | 64 | Ready |
| TC-P21 | Export | BC-BIZ-05 | Controller | PDF export success | HTTP 200 application/pdf | 11 | 65 | Ready |

### Negative
| TC ID | Cat | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|-----|----|--------|-------------|----------|----|----|--------|
| TC-N01 | Val | BC-VAL-01 | Controller | Toggle missing id | HTTP 404 (findOrFail) | 08 | 30 | Ready |
| TC-N02 | Val | BC-VAL-01 | Controller | Toggle non-numeric id | 404/400/500, never 200 | — | 31 | Ready |
| TC-N03 | Val | BC-VAL-03 | Controller | PDF empty ids[] | 400 `No items selected` | 09 | 32 | Ready |
| TC-N04 | Val | BC-VAL-03 | Controller | PDF missing ids key | 400 | — | 33 | Ready |
| TC-N05 | Auth | BC-AUTH-06 | routes | Guest toggle POST | 302 redirect (login) | — | 34 | Ready |
| TC-N06 | Auth | BC-AUTH-06 | routes | Guest browser visit | Lands on `/login` | 10 | 35 | Ready |

### Dependency
| TC ID | Cat | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|-----|----|--------|-------------|----------|----|----|--------|
| TC-D01 | B | BC-EDG-03 | MIG-BIL-001 | SoftDeletes vs DDL divergence | Documented (recorded, not failed) | 02 | 05 | Ready |
| TC-D02 | E | BC-INT-01 | Model | Payment resolves invoice | Relation loads / tenant_invoice_id set | — | 40 | Ready |
| TC-D03 | C | BC-REF-01 | DDL | Invoices parent table exists | `bil_tenant_invoices` present | — | 41 | Ready |
| TC-D04 | E | BC-INT-02 | GlobalMaster | Logs in shared activity table | Row present in sys_activity_logs | — | 42 | Ready |
| TC-D05 | G | BC-EDG-01 | routes | Toggle route `{session}` param | Route registered, uri has toggle-status | 13 | 70 | Ready |
| TC-D06 | G | BC-EDG-02 | Controller | Unknown filter value falls through | HTTP 200 (all) | — | 71 | Ready |
| TC-D07 | G | BC-EDG-02 | Controller | Empty date_range not today-scoped | HTTP 200 | — | 72 | Ready |
| TC-D08 | G | BC-BIZ-01 | Controller | Rapid serial toggles consistent | 4 flips → original | — | 73 | Ready |

### Security
| TC ID | Cat | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|-----|----|--------|-------------|----------|----|----|--------|
| TC-S01 | S | BC-AUTH-06 | routes | Guest JSON toggle unauthorized | 401/419/302/403 | — | 90 | Ready |
| TC-S02 | S | BC-VAL-03 | Controller | PDF scalar ids not OK | not 200 | — | 91 | Ready |
| TC-S03 | S | BC-EDG-02 | Controller | Injection-shaped filter safe (literal) | HTTP 200, no execution | — | 92 | Ready |

---

## 3. V2 Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_..._01_table_and_column_exist | TC-P01 | Schema | 01-09 |
| 2 | test_..._02_reconciled_column_is_boolean_family | TC-P01 | Schema | 01-09 |
| 3 | test_..._03_model_fillable_and_cast | TC-P01 | Schema | 01-09 |
| 4 | test_..._04_invoice_relation_wired | TC-P01/BC-INT-01 | Schema | 01-09 |
| 5 | test_..._05_softdeletes_vs_ddl_divergence | TC-D01 | Schema/Edge | 01-09 |
| 6 | test_..._06_activity_log_table_shape | TC-P01/BC-BIZ-03 | Schema | 01-09 |
| 7 | test_..._10_toggle_unreconciled_to_reconciled | TC-P05 | Biz | 10-19 |
| 8 | test_..._11_toggle_reconciled_to_unreconciled | TC-P06 | Biz | 10-19 |
| 9 | test_..._12_double_toggle_round_trips | TC-P07 | Biz | 10-19 |
| 10 | test_..._13_toggle_ignores_request_body | TC-P08 | Biz | 10-19 |
| 11 | test_..._20_toggle_writes_toggle_status_event | TC-P09 | State/Audit | 20-29 |
| 12 | test_..._21_activity_log_user_is_admin | TC-P10 | State/Audit | 20-29 |
| 13 | test_..._22_activity_log_properties_carry_transition | TC-P11 | State/Audit | 20-29 |
| 14 | test_..._23_each_toggle_appends_a_row | TC-P12 | State/Audit | 20-29 |
| 15 | test_..._30_toggle_missing_id_404 | TC-N01 | Validation | 30-39 |
| 16 | test_..._31_toggle_non_numeric_id_not_ok | TC-N02 | Validation | 30-39 |
| 17 | test_..._32_pdf_empty_ids_400 | TC-N03 | Validation | 30-39 |
| 18 | test_..._33_pdf_missing_ids_400 | TC-N04 | Validation | 30-39 |
| 19 | test_..._34_guest_toggle_redirects | TC-N05 | Validation/Auth | 30-39 |
| 20 | test_..._35_guest_browser_redirect | TC-N06 | Validation/Auth | 30-39 |
| 21 | test_..._40_payment_resolves_invoice | TC-D02 | Integration | 40-49 |
| 22 | test_..._41_invoices_parent_table_exists | TC-D03 | Integration | 40-49 |
| 23 | test_..._42_logs_use_globalmaster_table | TC-D04 | Integration | 40-49 |
| 24 | test_..._50_admin_views_index | TC-P13 | Permissions | 50-59 |
| 25 | test_..._51_toggle_gate_string_is_billing_management_status | TC-P14 | Permissions | 50-59 |
| 26 | test_..._52_index_gate_string_is_reconciliation_viewany | TC-P15 | Permissions | 50-59 |
| 27 | test_..._53_pdf_gate_mismatch | TC-P16 | Permissions | 50-59 |
| 28 | test_..._54_policy_import_remediated | TC-P17 | Permissions | 50-59 |
| 29 | test_..._60_tab_loads_with_filters | TC-P02 | UI/Report | 60-69 |
| 30 | test_..._61_three_way_options_present | TC-P03 | UI/Report | 60-69 |
| 31 | test_..._62_reconciled_only_filter_loads | TC-P18 | UI/Report | 60-69 |
| 32 | test_..._63_non_reconciled_only_filter_loads | TC-P19 | UI/Report | 60-69 |
| 33 | test_..._64_report_columns_render | TC-P20 | UI/Report | 60-69 |
| 34 | test_..._65_pdf_export_success | TC-P21 | UI/Report | 60-69 |
| 35 | test_..._70_toggle_route_uses_session_param | TC-D05 | Edge | 70-79 |
| 36 | test_..._71_unknown_filter_value_falls_through | TC-D06 | Edge | 70-79 |
| 37 | test_..._72_empty_date_range_not_today_scoped | TC-D07 | Edge | 70-79 |
| 38 | test_..._73_rapid_serial_toggles_consistent | TC-D08 | Edge | 70-79 |
| 39 | test_..._90_guest_json_toggle_unauthorized | TC-S01 | Security | 90-99 |
| 40 | test_..._91_pdf_scalar_ids_not_ok | TC-S02 | Security | 90-99 |
| 41 | test_..._92_injection_shaped_filter_safe | TC-S03 | Security | 90-99 |

**Counts:** V1 = 14 methods · V2 = 41 methods (≥ 2× V1 = 28). ✅

---

## 4. Known Source Defects (audit + discovered)

| ID | Sev | Where | Note | Proving test |
|----|-----|-------|------|--------------|
| MIG-BIL-001 | P0 | `InvoicingPayment` SoftDeletes vs DDL `bil_tenant_invoicing_payments` (no `deleted_at`) | Any Eloquent query appends `WHERE deleted_at IS NULL` → throws on a schema-correct prime_db. Live dev DB may be hand-patched (audit degrades to P1). | V1_02, V2_05 |
| DATA-BIL-001 | P0 | Audit-log model `tenant_invoicing_id` vs DDL `tenant_invoice_id` | Affects the **adjacent** remarks/audit path (`updateInvoiceRemarks` → `InvoicingAuditLog`), NOT the reconciliation toggle (which logs to `sys_activity_logs`). Documented for completeness. | (adjacent — remarks feature) |
| DEV-BIL-R01 | P2 | `InvoicingPaymentController@downloadSelectedPdf` gate | Endpoint authorizes `prime.invoicing-payment.view` while the UI button is guarded by `@can('prime.payment-reconciliation.pdf')` — permission-key mismatch (a read-only invoicing-payment viewer can export reconciliation PDFs; a reconciliation-only pdf grantee is blocked at the endpoint). | V1_14, V2_53 |
| DEAD-BIL-001 | P2 | Audit flagged `PaymentReconciliationPolicy` importing non-existent `App\Models\PaymentReconciliation` + dead policy | **Verified REMEDIATED in current source:** policy now imports `Modules\Billing\Models\InvoicingPayment` + `Modules\Prime\Models\User`, and abilities are wired via `Gate::define('prime.payment-reconciliation.*', [PaymentReconciliationPolicy::class, $ability])`. Guard against regression. | V2_54 |
| OBS-BIL-R02 | P3 | Toggle route param `{session}` | Copy-paste misnomer; binds positionally by id (`findOrFail`). Functional, cosmetic only. | V2_70 |
