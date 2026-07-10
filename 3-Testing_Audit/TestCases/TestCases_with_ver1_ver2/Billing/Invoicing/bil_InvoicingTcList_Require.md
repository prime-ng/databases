# Invoicing (Invoice Generation) — Test Case List & Business Conditions (`bil_InvoicingTcList_Require`)

- **Module:** Billing (central / prime_db SaaS admin)
- **Feature / Screen:** Invoicing (`invoicing.md`)
- **Primary table:** `bil_tenant_invoices` (prefix `bil_`, verified against `Billing_DDL_v1.sql` line 4 `CREATE TABLE bil_tenant_invoices`)
- **DB scope:** `prime_db` central — **no tenancy scaffolding in the TEST**. The generation path (`generateInvoiceForOrganization`) itself calls `Tenancy::initialize()/end()` to count students in the tenant DB — that is behaviour under test, guarded defensively.
- **URL:** `/billing/billing-management` (Invoicing tab `#invoicing-tab` / `#invoicing-pane`)
- **Controller:** `Modules\Billing\Http\Controllers\BillingManagementController`
- **Models:** `Modules\Billing\Models\BilTenantInvoice` (SoftDeletes + HasFactory), `InvoicingAuditLog`, `BillOrgInvoicingModulesJnt`, `InvoicingPayment`
- **Policy:** `Modules\Billing\Policies\BillingManagementPolicy` (`prime.billing-management.*`)
- **Test style:** browser Dusk (central `http://127.0.0.1:8000`), mirrors committed sibling `prm_InvoicingTab_TestCas`

---

## 1. Business Conditions

### BC-DB — Schema (Source: `DDL-bil_tenant_invoices`, lines 4-51)

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `id` INT UNSIGNED PK auto-increment | DDL-bil_tenant_invoices |
| BC-DB-02 | `invoice_no` VARCHAR(50) NOT NULL, UNIQUE (`uq_tenantInvoices_invoiceNo`) | DDL line 47 |
| BC-DB-03 | `tenant_id` INT UNSIGNED NOT NULL FK → `prm_tenant` (CASCADE) | DDL line 48 |
| BC-DB-04 | `tenant_plan_id` INT UNSIGNED NOT NULL FK → `prm_tenant_plan_jnt` (CASCADE) | DDL line 49 |
| BC-DB-05 | `billing_cycle_id` SMALLINT UNSIGNED NOT NULL FK → `prm_billing_cycles` (RESTRICT) | DDL line 50 |
| BC-DB-06 | Money columns `plan_rate`/`sub_total`/`net_payable_amount`/`paid_amount` DECIMAL, 4 tax lines (tax1..tax4 percent/remark/amount) | DDL lines 15-41 |
| BC-DB-07 | `status` VARCHAR(20) NOT NULL DEFAULT 'PENDING'; **code stores a Dropdown id, not the literal (D37)** | DDL line 39 + Controller:756 |
| BC-DB-08 | `currency` CHAR(3) NOT NULL DEFAULT 'INR' (ISO 4217) | DDL line 38 |
| BC-DB-09 | `is_recurring`/`auto_renew` TINYINT(1) DEFAULT 1 (cast boolean) | DDL lines 42-43 + Model casts |
| BC-DB-10 | Model uses `SoftDeletes`; **DDL has NO `deleted_at` → MIG-BIL-001 (P0)** | Model:16 + Audit-MIG-BIL-001 |
| BC-DB-11 | `bil_tenant_invoicing_audit_logs` — code uses `tenant_invoice_id` (audit flagged `tenant_invoicing_id`, remediated) | Model InvoicingAuditLog + Audit-DATA-BIL-001 |

### BC-VAL — Validation (Source: Controller inline `validate()` — no dedicated FormRequest for this screen)

| ID | Rule | Message behaviour | Source |
|----|------|-------------------|--------|
| BC-VAL-01 | `updateInvoiceRemarks`: `id` required integer | 422 on absence | Controller:916 |
| BC-VAL-02 | `updateInvoiceRemarks`: `remarks` nullable string max:5000 | 422 on overflow | Controller:917 |
| BC-VAL-03 | `store` (generate): `ids` must be a present array | 400 "No plan rate IDs received." | Controller:604 |
| BC-VAL-04 | Filters (`data_type`/`status`/`invoice_status`/`date_range`/`tenat_id`) presence-validated only (`!empty()`), no type/format rules | Controller:236-368 |

### BC-AUTH — Permissions (Source: `Screen-PM` + Policy + Controller gates)

| ID | Operation | Permission (controller / policy) | Source |
|----|-----------|----------------------------------|--------|
| BC-AUTH-01 | View invoicing tab (index) | `Gate::any([... 'prime.billing-management.viewAny' ...])` | Controller:55 / Screen-PM-1 |
| BC-AUTH-02 | Generate invoice (store) | `prime.billing-management.create` | Controller:602 / Screen-PM-2 |
| BC-AUTH-03 | View details (invoice/subscription/module/audit) | `prime.billing-management.view` | Controller:820,839,856,950 |
| BC-AUTH-04 | Update remarks | `prime.billing-management.remark` | Controller:901,915 |
| BC-AUTH-05 | Print | `prime.billing-management.print` | Controller:137 |
| BC-AUTH-06 | Download PDF | `prime.billing-management.pdf` | Controller:476 |
| BC-AUTH-07 | Email / schedule | `prime.billing-management.email-schedule` | Controller:545,563 |
| BC-AUTH-08 | Toggle status | `prime.billing-management.status` | Controller:964 |
| BC-AUTH-09 | Guest → redirect `/login` (`auth`+`verified` middleware on the central group) | routes/web.php |
| BC-AUTH-10 | **Blade partials gate buttons on `prime.invoicing.*` while controller/policy enforce `prime.billing-management.*` — key mismatch → DEV-BIL-INV-001** | invoicing.blade vs Controller/Policy |

### BC-BIZ — Business logic / calculations (Source: Controller `generateInvoiceForOrganization` + Screen-BR)

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Invoice number `INV-YYYYMMDD-NNN`; `NNN` = today's invoice count + 1, zero-padded 3 | Controller:693-694 / Screen-BR |
| BC-BIZ-02 | `sub_total = plan_rate × billing_qty` | Controller:706 / Screen-BR |
| BC-BIZ-03 | `discount_amount = sub_total × discount_percent/100`; `tax_base = sub_total − discount + extra_charges`; each `taxN = tax_base × taxN_percent/100`; `total_tax = tax1+tax2+tax3+tax4` | Controller:707-716 |
| BC-BIZ-04 | `net_payable = sub_total − discount + extra_charges + total_tax` | Controller:717 |
| BC-BIZ-05 | `billing_qty = max(min_billing_qty, total_user_qty)`; `total_user_qty` counted from tenant DB active students | Controller:670-705 / Screen-BR |
| BC-BIZ-06 | `payment_due_date = invoice_date + credit_days` | Controller:696-698 |
| BC-BIZ-07 | Atomic generation in `DB::transaction()`: creates invoice + module junction rows + `GENERATED` audit log; sets `bill_generated=1`, `generated_invoice_id` | Controller:682-799 / Screen-BR |
| BC-BIZ-08 | Generation writes `activityLog($invoice, 'Store', ...)` (event string literal **`Store`**) | Controller:764 |
| BC-BIZ-09 | `store()` returns JSON envelope `{status:true, success_ids:[], failed_ids:[{id,reason}]}` (array contract) | Controller:634-638 |
| BC-BIZ-10 | Invoice/subscription/module details load via AJAX GET → JSON `{html:string}` | Controller:818-862 |

> **Activity-log event string (verbatim):** invoicing writes **`Store`** via `activityLog()` (not `Stored`); reconciliation `toggleStatus` writes **`ToggleStatus`**. Assert the literal strings.

### BC-SM — State machine: invoice `status` lifecycle (Source: Screen "Status Lifecycle")

| ID | State | Trigger | Next State | Enforced? | Source |
|----|-------|---------|-----------|-----------|--------|
| BC-SM-01 | (new) | generate | PENDING (dropdown ordinal 1) | Yes | Controller:722,756 / Screen-SM |
| BC-SM-02 | PENDING | partial payment (Payment module) | PARTIALLY_PAID | Cross-module | Screen-SM |
| BC-SM-03 | PENDING / PARTIALLY_PAID | full payment | PAID | Cross-module; **status taken from request, not derived (BUG-BIL-010)** | Screen-SM / Audit-BUG-BIL-010 |
| BC-SM-04 | PENDING | payment_due_date passed | OVERDUE | **No automated detection** | Screen-SM |
| BC-SM-05 | PENDING | cancel | CANCELLED | **No dedicated cancel endpoint** | Screen-SM |
| BC-SM-06 (illegal) | PAID | — | PENDING | Should be rejected; **not server-guarded (BUG-BIL-010)** | Screen-SM / Audit |

### BC-REF / BC-INT — FK & cross-module (Source: `DDL` + Screen "Filter System / Query Builders")

| ID | Referencing / referenced | onDelete | Source |
|----|--------------------------|----------|--------|
| BC-REF-01 | `bil_tenant_invoices.tenant_id` → `prm_tenant.id` | CASCADE | DDL line 48 |
| BC-REF-02 | `bil_tenant_invoices.tenant_plan_id` → `prm_tenant_plan_jnt.id` | CASCADE | DDL line 49 |
| BC-REF-03 | `bil_tenant_invoices.billing_cycle_id` → `prm_billing_cycles.id` | RESTRICT | DDL line 50 |
| BC-INT-01 | Generation cross-queries the tenant DB (`Student::where('is_active')->count()`) via `Tenancy::initialize()/end()` (try/finally — SEC-BIL-005 remediated) | Controller:668-675 |
| BC-INT-02 | Generation reads `prm_tenant_plan_billing_schedule` + `prm_tenant_plan_rates` + `TenantPlanModule` | Controller:648-774 |
| BC-INT-03 | Module junction `bil_tenant_invoicing_modules_jnt` (tenant_invoice_id, module_id) | DDL lines 53-60 |

### BC-EDG — Edge cases

| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | `date_range` defaults to today when empty (may return empty results) | Controller:242-245 / Screen |
| BC-EDG-02 | One-time invoice: a schedule with `bill_generated=1` cannot be re-invoiced | Screen-BR / Controller buildMainBillingQuery |
| BC-EDG-03 | Injection-shaped filter values must not surface a DB error | Screen "Performance/validation" |
| BC-EDG-04 | Filter param `tenat_id` is a **typo** (not `tenant_id`) — matched verbatim | Controller:82 / Screen |

### Known Source Defects (audit / discovered)

| ID | Severity | Description | Current source state | Proving artifact |
|----|----------|-------------|----------------------|------------------|
| **MIG-BIL-001** | P0 | Model SoftDeletes vs DDL `bil_tenant_invoices` with no `deleted_at` → CRUD breaks on schema-correct DB | **Still present** (dev DB hand-patched) | V1 `test_03`, V2 `test_05` (schema guards) |
| **DATA-BIL-001** | P0 | Audit-log FK column `tenant_invoicing_id` vs `tenant_invoice_id` | **Remediated** — code now uses `tenant_invoice_id` uniformly | V1 `test_02`, V2 `test_03` (lock the fixed contract) |
| **DATA-BIL-002** | P0 | `BilTenantInvoice $fillable` phantom `invoice_amount` + duplicated block | **Remediated** — absent in current model | V1 `test_01`, V2 `test_02` (assert absent + no dupes) |
| **BUG-BIL-011** | P1 | `generateInvoiceForOrganization()` returned bool `false`, read as array by `store()` | **Remediated** — returns `['status'=>false,'message'=>...]` | V1 `test_40`, V2 `test_40` (array contract) |
| **SEC-BIL-005** | P1 | `Tenancy::initialize()/end()` without try/finally, mid-transaction | **Remediated** — count runs BEFORE the tx, inside try/finally | Documented (Gap Cross-Ref) |
| **BUG-BIL-015** | P1 | Invoice-number generation not concurrency-safe | **Mitigated** — unique-collision retry loop (max 5 attempts) added | Documented (BC-BIZ-01 / Gap) |
| **BUG-BIL-010** | P1 | Invoice status taken from request, not derived from cumulative paid | Payment-module path; documented for Invoicing SM | BC-SM-03/06 (manual/gap) |
| **DEV-BIL-INV-001** | P1 | Blade partials gate buttons on `prime.invoicing.*` while controller/policy enforce `prime.billing-management.*` — buttons show/hide on a different permission than the one enforced | **Present** | Gap Cross-Ref #10 (documented) |
| **BUG-BIL-013** | P2 | Broken `billing-management.view` route → controller has no `view()` method | Present | Gap Cross-Ref #2 (documented) |
| **BUG-BIL-014** | P2 | Central billing route block registered 3× | Present | Gap Cross-Ref #2 (documented) |

---

## 2. Test Case List

### Positive

| TC ID | Cat | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|-----|----|--------|-------------|----------|----|----|--------|
| TC-P01 | Config | BC-DB-01..11 | DDL | Schema/columns/unique index + model config | table+cols+unique+SoftDeletes+relations | `test_01` | `test_01`,`test_02` | Automated |
| TC-P02 | Config | BC-DB-11 | Model | Audit-log uses `tenant_invoice_id` (DATA-BIL-001 fixed) | fillable correct | `test_02` | `test_03` | Automated |
| TC-P03 | Config | BC-DB-10 | Model | SoftDeletes column guard (MIG-BIL-001) | `deleted_at` present or fail | `test_03` | `test_05` | Automated |
| TC-P04 | Render | BC-AUTH-01 | Screen | Invoicing tab loads with filters | tab + 4 filter fields + table | `test_04` | `test_30` | Automated |
| TC-P05 | Render | Screen | Tab shows rows or empty state | rows or "No records found." | `test_05` | `test_61` | Automated |
| TC-P06 | Business | BC-BIZ-01 | Controller | Invoice number format INV-YYYYMMDD-NNN | regex + -001 first | `test_10` | `test_10` | Automated |
| TC-P07 | Business | BC-BIZ-02/04 | Controller | Financial formula (sub_total→net_payable) | computed values match | `test_11` | `test_11`,`test_13` | Automated |
| TC-P08 | Business | BC-BIZ-05 | Controller | billing_qty = max(min, count) | max chosen | `test_12` | `test_14` | Automated |
| TC-P09 | Business | BC-BIZ-03 | Controller | discount/tax_base/total_tax formula | computed values | — | `test_12` | Automated |
| TC-P10 | Business | BC-BIZ-06 | Controller | payment_due_date = invoice_date + credit_days | date math | — | `test_15` | Automated |
| TC-P11 | Route | BC-AUTH | routes | central billing-management routes registered | names resolve | — | `test_04` | Automated (defensive) |
| TC-P12 | UI | Screen | Invoicing column headers present | Organization/Invoice No/… | — | `test_60` | Automated |
| TC-P13 | UI | Screen | Pagination container present | table anchor present | — | `test_62` | Automated |
| TC-P14 | Filter | BC-VAL-04 | Controller | data_type=Invoicing Done loads | 200, tab present | — | `test_31` | Automated |
| TC-P15 | Filter | BC-VAL-04 | Controller | data_type=Inv. Need To Generate loads | 200 | — | `test_32` | Automated |
| TC-P16 | Filter | BC-VAL-04 | Controller | date_range filter loads | 200 | — | `test_33` | Automated |
| TC-P17 | Filter | BC-VAL-04 | Controller | status filter loads | 200 | — | `test_34` | Automated |
| TC-P18 | Filter | BC-VAL-04 | Controller | invoice_status filter (under Done) loads | 200 | — | `test_35` | Automated |
| TC-P19 | Status | BC-SM-01/D37 | Controller | status stores a dropdown id | populated | `test_20` | `test_20` | Automated (defensive) |

### State Machine

| TC ID | Cat | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|-----|----|--------|-------------|----------|----|----|--------|
| TC-SM01 | SM | BC-SM-01 | Screen-SM | New invoice initial status = PENDING (ordinal 1) | dropdown id set | `test_20` | `test_20` | Automated (defensive) |
| TC-SM02 | SM | BC-SM-05 | Screen-SM | No dedicated cancel / status-transition endpoint | route absent | — | `test_21` | Automated |
| TC-SM03 | SM | BC-SM-02/03 | Screen-SM | PENDING→PARTIALLY_PAID→PAID via payments | cross-module | — | — | Manual (cross-module) |
| TC-SM04 | SM | BC-SM-06 | Audit-BUG-BIL-010 | Illegal PAID→PENDING not server-guarded | documented | — | — | Manual (DEV) |

### Negative

| TC ID | Cat | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|-----|----|--------|-------------|----------|----|----|--------|
| TC-N01 | Val | BC-VAL-01 | Controller | updateInvoiceRemarks requires id | 422/gated | `test_30` | `test_36` | Automated (defensive) |
| TC-N02 | Val | BC-VAL-02 | Controller | remarks > 5000 chars rejected | 422/gated | — | `test_37` | Automated (defensive) |
| TC-N03 | Val | BC-VAL-03 | Controller | store rejects non-array ids | 400/gated | — | `test_41` | Automated (defensive) |
| TC-N04 | Auth | BC-AUTH-09 | routes | Guest → /login (index) | redirect | `test_50` | `test_50` | Automated |
| TC-N05 | Auth | BC-AUTH-03 | routes | Detail endpoint requires auth | redirect/login | `test_60` | `test_51`,`test_90` | Automated |
| TC-N06 | Auth | BC-AUTH-01 | Controller | Non super-admin forbidden on index | 403/redirect | — | `test_52` | Automated (defensive) |
| TC-N07 | Val | BC-BIZ-10 | Controller | invoice-details bogus id → 404 | 404/gated | `test_60` | `test_44` | Automated (defensive) |
| TC-N08 | Val | BC-BIZ-10 | Controller | subscription-details bogus id → 404 | 404/gated | — | `test_45` | Automated (defensive) |

### Dependency

| TC ID | Sub | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|-----|----|--------|-------------|----------|----|----|--------|
| TC-D01 | C | BC-REF-03 | DDL | billing_cycle_id FK is RESTRICT | RESTRICT | `test_41` | `test_42` | Automated (defensive) |
| TC-D02 | C | BC-REF-01/02 | DDL | tenant_id / tenant_plan_id FK CASCADE | CASCADE | — | `test_42` | Automated (defensive) |
| TC-D03 | E | BC-INT-01/02 | DDL | referenced Prime tables exist | present | — | `test_43` | Automated (defensive) |
| TC-D04 | E | BC-INT-03 | DDL | modules junction shape (tenant_invoice_id, module_id) | columns present | — | `test_71` | Automated (defensive) |
| TC-D05 | F | BC-BIZ-09 | Controller | generate store array contract (BUG-BIL-011) | envelope status:true, failed_ids | `test_40` | `test_40` | Automated (defensive) |

### Edge / Security

| TC ID | Cat | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|-----|----|--------|-------------|----------|----|----|--------|
| TC-EDG01 | Edge | BC-EDG-01 | Controller | default (today) date range still renders | 200 | — | `test_70` | Automated |
| TC-S01 | IDOR | BC-AUTH-09 | routes | invoice-details requires auth | redirect /login | `test_60` | `test_90` | Automated |
| TC-S02 | Injection | BC-EDG-03 | Controller | injection-shaped filter is safe | no SQLSTATE leak | — | `test_91` | Automated |

---

## 3. V2 Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_invoicing_01_schema_columns_and_unique_index_exist | TC-P01 | Config | 01-09 |
| 2 | test_invoicing_02_model_fillable_casts_softdeletes_and_relationships | TC-P01 | Config | 01-09 |
| 3 | test_invoicing_03_audit_log_model_uses_tenant_invoice_id | TC-P02 / DATA-BIL-001 | Config | 01-09 |
| 4 | test_invoicing_04_routes_are_registered_with_expected_names | TC-P11 | Config | 01-09 |
| 5 | test_invoicing_05_softdeletes_column_present_mig_bil_001_guard | TC-P03 / MIG-BIL-001 | Config | 01-09 |
| 6 | test_invoicing_10_invoice_number_format_and_sequence | TC-P06 | Business | 10-19 |
| 7 | test_invoicing_11_sub_total_formula | TC-P07 | Business | 10-19 |
| 8 | test_invoicing_12_discount_tax_base_and_total_tax | TC-P09 | Business | 10-19 |
| 9 | test_invoicing_13_net_payable_formula | TC-P07 | Business | 10-19 |
| 10 | test_invoicing_14_billing_qty_is_max_of_min_and_count | TC-P08 | Business | 10-19 |
| 11 | test_invoicing_15_payment_due_date_formula | TC-P10 | Business | 10-19 |
| 12 | test_invoicing_20_status_column_holds_dropdown_id | TC-SM01 / D37 | State machine | 20-29 |
| 13 | test_invoicing_21_no_dedicated_status_transition_endpoint | TC-SM02 | State machine | 20-29 |
| 14 | test_invoicing_30_tab_loads_with_all_filters | TC-P04 | Validation/UI | 30-39 |
| 15 | test_invoicing_31_filter_invoicing_done_loads | TC-P14 | Filter | 30-39 |
| 16 | test_invoicing_32_filter_need_to_generate_loads | TC-P15 | Filter | 30-39 |
| 17 | test_invoicing_33_filter_date_range_loads | TC-P16 | Filter | 30-39 |
| 18 | test_invoicing_34_filter_status_loads | TC-P17 | Filter | 30-39 |
| 19 | test_invoicing_35_filter_invoice_status_loads | TC-P18 | Filter | 30-39 |
| 20 | test_invoicing_36_remarks_update_requires_id | TC-N01 | Validation | 30-39 |
| 21 | test_invoicing_37_remarks_update_rejects_overlong_remarks | TC-N02 | Validation | 30-39 |
| 22 | test_invoicing_40_generate_store_array_contract_missing_schedule | TC-D05 / BUG-BIL-011 | Integration | 40-49 |
| 23 | test_invoicing_41_generate_store_rejects_non_array_ids | TC-N03 | Integration | 40-49 |
| 24 | test_invoicing_42_fk_delete_rules_match_ddl | TC-D01/D02 | Integration | 40-49 |
| 25 | test_invoicing_43_referenced_tables_exist | TC-D03 | Integration | 40-49 |
| 26 | test_invoicing_44_invoice_details_bogus_id_not_found | TC-N07 | Integration | 40-49 |
| 27 | test_invoicing_45_subscription_details_bogus_id_not_found | TC-N08 | Integration | 40-49 |
| 28 | test_invoicing_50_guest_redirected_to_login | TC-N04 | Permissions | 50-59 |
| 29 | test_invoicing_51_module_details_requires_auth | TC-N05 | Permissions | 50-59 |
| 30 | test_invoicing_52_non_super_admin_forbidden | TC-N06 | Permissions | 50-59 |
| 31 | test_invoicing_60_tab_columns_present | TC-P12 | UI/UX | 60-69 |
| 32 | test_invoicing_61_rows_or_empty_state | TC-P05 | UI/UX | 60-69 |
| 33 | test_invoicing_62_pagination_container_present | TC-P13 | UI/UX | 60-69 |
| 34 | test_invoicing_70_default_date_range_loads | TC-EDG01 | Edge | 70-79 |
| 35 | test_invoicing_71_modules_junction_shape | TC-D04 | Edge | 70-79 |
| 36 | test_invoicing_90_invoice_details_requires_auth | TC-S01 | Security | 90-99 |
| 37 | test_invoicing_91_injection_shaped_filter_is_safe | TC-S02 | Security | 90-99 |

**Counts:** V1 = 14 methods · V2 = 37 methods · V2 ≥ 2×V1 (28) ✅
