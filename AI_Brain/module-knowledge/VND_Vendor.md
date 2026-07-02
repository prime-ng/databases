# Module Knowledge — VND: Vendor
**Seeded:** 2026-06-30 | **Agent:** Business Analyst
**Version:** 1.0

---

## Module Facts

| Attribute | Value |
|-----------|-------|
| Module Name | Vendor |
| Module Code | VND |
| Table Prefix | `vnd_*` |
| Laravel Module Path | `Modules/Vendor/` |
| Namespace | `Modules\Vendor` |
| DB Layer | **Tenant** — tenant_db (no `tenant_id` column; isolated by DB connection) |
| Domain Scope | Tenant — Finance Manager, Accountant, Purchase Manager, School Admin |
| V2 Requirement | Exists: `VND_Vendor_Requirement.md` (2026-03-26); ~53% completion (5.3/10) |
| V1 Screen Specs | 9 files in `Vendor_v2/` |
| RBS Reference | Module K — Finance & Accounting (K5/K6/K7) |
| Accounting Dependency | Future — vendor payments will post journal entries to `acc_vouchers` when ACC module is built |

### Verified File Counts (from `find Modules/Vendor -type f` — 2026-06-30)

| Component | Actual | V2 Said | Notes |
|-----------|--------|---------|-------|
| Controllers | 8 | 8 | VendorAgreementController, VendorController, VendorDashboardController, VendorInvoiceController, VendorPaymentController, VendorReportController, VndItemController, VndUsageLogController |
| Models | 8 | 7 | Vendor, VendorDashboard, VndAgreement, VndAgreementItem, VndInvoice, VndItem, VndPayment, VndUsageLog |
| FormRequests | 3 | 5 | VendorAgreementRequest, VendorRequest, VndItemRequest — **MISSING** VendorPaymentRequest, VndUsageLogRequest |
| Policies | 7 | 7 | All 7 registered in AppServiceProvider (confirmed) |
| Jobs | 1 | 1 | SendVendorInvoiceEmailJob |
| Mail | 1 | 1 | VendorInvoiceMail |
| Tests | 0 | 0 | Feature/ and Unit/ both empty (only .gitkeep) |
| Seeders | 2 | — | VendorDatabaseSeeder, VendorDummyDataSeeder |
| Views | ~40 | — | Full CRUD for vendor/agreement/item/usage-log; invoice index, dashboard, reports (5 partials) |

---

## Module Score Summary (V2 Gap Analysis 2026-03-22)

| Area | Score | Key Issue |
|------|-------|-----------|
| DB Integrity | 6/10 | FK errors, is_deleted redundancy, missing columns |
| Route Integrity | 7/10 | EnsureTenantHasModule missing; VendorDashboardController unregistered |
| Controller Quality | 7/10 | VendorInvoiceController zero auth |
| Model Quality | 7/10 | No encrypted casts for PII |
| Service Layer | **2/10** | Zero services — all business logic in controllers |
| FormRequest Coverage | 6/10 | 3 of 5 controllers covered |
| Policy / Auth | 7/10 | 7 policies registered; VendorInvoiceController ignores them all |
| Test Coverage | **0/10** | Zero tests |
| Security | 5/10 | Financial PII unencrypted; VendorInvoiceController zero auth |
| Performance | 6/10 | N+1 risk; no indexes on usage_date |
| **Overall** | **5.3/10** | — |

---

## DDL Table Inventory (7 active tables + 4 proposed V2 tables)

### Active Tables

| Table | Model | SoftDeletes | Key DDL Issues |
|-------|-------|:-----------:|----------------|
| `vnd_vendors` | `Vendor` | YES | `is_deleted` redundant (remove); missing `created_by`; no UNIQUE on `gst_number`; PAN/bank_account_no unencrypted |
| `vnd_items` | `VndItem` | YES | `is_deleted` redundant; missing `created_by` |
| `vnd_agreements` | `VndAgreement` | YES | `is_deleted` redundant; trailing comma DDL syntax error before `) ENGINE=InnoDB` |
| `vnd_agreement_items_jnt` | `VndAgreementItem` | YES | `is_deleted` redundant; trailing comma DDL syntax error |
| `vnd_usage_logs` | `VndUsageLog` | Partial | Missing `is_active`, `deleted_at`, `created_by`; FK name `fk_vnd_usage_item` references `vnd_agreement_items` (wrong — should be `vnd_agreement_items_jnt`) |
| `vnd_invoices` | `VndInvoice` | YES | `is_deleted` redundant; `balance_due` is GENERATED STORED — never write; FK `fk_vnd_inv_agreement_item` references `vnd_agreement_items` (wrong name) |
| `vnd_payments` | `VndPayment` | Partial | Missing `is_active`; `is_deleted` redundant; `status` is ENUM here but INT FK on vnd_invoices — inconsistent |

### Proposed V2 Tables (not yet built)

| Table | Model | Status |
|-------|-------|--------|
| `vnd_purchase_orders` | `VndPurchaseOrder` | 📐 V2 FR-VND-08 |
| `vnd_po_items_jnt` | `VndPoItem` | 📐 V2 FR-VND-08 |
| `vnd_grn` | `VndGrn` | 📐 V2 FR-VND-08 (requires INV module) |
| `vnd_vendor_ratings` | `VndVendorRating` | 📐 V2 FR-VND-09 |

### Column Details for Critical Tables

#### `vnd_vendors`
| Column | Type | Notes |
|--------|------|-------|
| `vendor_name` | VARCHAR(100) | Unique per tenant |
| `vendor_type_id` | INT UNSIGNED FK | → `sys_dropdown_table` |
| `gst_number` | VARCHAR(50) NULL | 🆕 V2: encrypted cast + UNIQUE KEY needed |
| `pan_number` | VARCHAR(50) NULL | **CRITICAL** 🆕 V2: encrypted cast (AES-256-CBC) |
| `bank_account_no` | VARCHAR(50) NULL | **CRITICAL** 🆕 V2: encrypted cast |
| `bank_ifsc_code` | VARCHAR(20) NULL | 11-char IFSC |
| `upi_id` | VARCHAR(100) NULL | 🆕 V2: encrypted cast |
| `is_deleted` | TINYINT(1) | ❌ Redundant — remove; use `deleted_at` only |

#### `vnd_agreement_items_jnt`
| Column | Type | Notes |
|--------|------|-------|
| `billing_model` | ENUM | FIXED / PER_UNIT / HYBRID |
| `fixed_charge` | DECIMAL(12,2) | Base charge for FIXED/HYBRID |
| `unit_rate` | DECIMAL(10,2) | Per-unit rate for PER_UNIT/HYBRID |
| `min_guarantee_qty` | DECIMAL(10,2) | HYBRID: free units threshold |
| `tax1_percent`–`tax4_percent` | DECIMAL(5,2) | CGST, SGST, IGST, cess |
| `related_entity_type` | INT FK NULL | → `sys_dropdown_table` (stores entity table name in additional_info JSON) |
| `related_entity_table` | VARCHAR(60) NULL | E.g., `tpt_vehicle`, `sch_asset` |
| `related_entity_id` | INT UNSIGNED NULL | PK of linked entity |

#### `vnd_invoices`
| Column | Type | Notes |
|--------|------|-------|
| `invoice_number` | VARCHAR(50) | UNIQUE KEY `uq_vnd_invoice_no(vendor_id, invoice_number)` |
| `fixed_charge_amt` | DECIMAL(12,2) | Snapshot at generation |
| `unit_charge_amt` | DECIMAL(12,2) | Snapshot |
| `sub_total` | DECIMAL(12,2) | fixed + unit |
| `tax_total` | DECIMAL(12,2) | sub_total × sum(tax%) / 100 |
| `net_payable` | DECIMAL(12,2) | Final amount due |
| `amount_paid` | DECIMAL(12,2) | Running paid total |
| `balance_due` | DECIMAL(12,2) GENERATED STORED | net_payable - amount_paid — **NEVER write this column** |
| `status` | INT UNSIGNED FK | → `sys_dropdown_table` (Pending/Partially Paid/Fully Paid) |

---

## Known Gaps & Open Issues

### P0 — Critical (Security / Production Blockers)

| ID | Issue | Location |
|----|-------|---------|
| SEC-VND-01 | **VendorInvoiceController has ZERO authorization on all 14 methods** — any authenticated user can generate invoices, batch-generate, download ZIP PDFs, and send emails to vendors. Root cause: `extends \Illuminate\Routing\Controller` instead of `App\Http\Controllers\Controller`. Fix: change base class + add `Gate::authorize('tenant.vendor-invoice.{action}')` to each method | `VendorInvoiceController.php` |
| SEC-VND-02 | **`pan_number` and `bank_account_no` stored as plaintext** — must use Laravel `encrypted` cast (AES-256-CBC) on `Vendor` model. Also encrypt `gst_number` and `upi_id`. Encrypted columns cannot be searched directly — DB queries must load and decrypt. | `Models/Vendor.php` `$casts` |
| GAP-VND-03 | `EnsureTenantHasModule` middleware absent from ALL vendor routes — any authenticated user of any tenant can access vendor routes without a license | `routes/tenant.php` vendor group |
| ARCH-VND-04 | **Zero service layer** — all invoice calculation logic (3 billing models: FIXED, PER_UNIT, HYBRID), batch generation, PDF ZIP creation, and email dispatch logic embedded directly in `VendorInvoiceController`. V2 requires 5 services: `VendorInvoiceService`, `VendorAgreementService`, `VendorPaymentService`, `VendorReportService`, `VendorUsageService`. | All VND controllers |
| GAP-VND-05 | `VendorDashboardController` defined and `VendorDashboardPolicy` registered but NO route in `tenant.php` — dashboard controller is dead code; dashboard data served via `VendorController::index()` AJAX fallback | `routes/tenant.php` |

### P1 — High

| ID | Issue | Location |
|----|-------|---------|
| BUG-VND-06 | `vnd_usage_logs` missing `is_active`, `deleted_at`, `created_by` columns in DDL — `VndUsageLog` model has `SoftDeletes` trait but no `deleted_at` column exists — every soft delete call throws DB error | DDL + migration needed |
| BUG-VND-07 | `vnd_payments` missing `is_active` column — `VendorPaymentPolicy::viewAny()` may reference non-existent scope | DDL + migration needed |
| BUG-VND-08 | Invoice number collision risk — current scheme: `'INV-' . now()->format('YmdHis') . rand(100,999)` → only 900 unique values/second under load; must replace with sequential `INV-{YYYY}-{NNNNNN}` | `VendorInvoiceController::generateInvoice()` |
| BUG-VND-09 | DDL FK error: `vnd_usage_logs.agreement_item_id` FK references `vnd_agreement_items` (wrong — table is `vnd_agreement_items_jnt`); same error on `vnd_invoices.agreement_item_id` FK | DDL |
| BUG-VND-10 | DDL trailing comma syntax errors in `vnd_agreements` and `vnd_agreement_items_jnt` — `) ENGINE=InnoDB` has a leading comma causing syntax error in raw DDL scripts | DDL |
| GAP-VND-11 | `VendorController::index()` has `Gate::authorize` call commented out — any authenticated tenant user can view the full vendor hub list | `VendorController.php` |
| GAP-VND-12 | Missing `VendorPaymentRequest` — `VendorPaymentController::store()` uses raw `$request` — no validation for `amount <= balance_due` | FormRequests/ |
| GAP-VND-13 | Missing `VndUsageLogRequest` — `VndUsageLogController::store()` uses raw `$request` — no validation that qty_used ≥ 0 or usage_date is not future | FormRequests/ |
| BUG-VND-14 | `balance_due` in `vnd_invoices` is GENERATED STORED — must not appear in `VndInvoice::$fillable`; any Eloquent write attempt will fail silently or throw | `Models/VndInvoice.php` |
| ARCH-VND-15 | `VndAgreement` model imports `Modules\Transport\Models\Vehicle` for cross-module entity resolution — creates hard coupling from Vendor to Transport. Must replace with a generic polymorphic resolver using `related_entity_table` and `related_entity_id` | `Models/VndAgreement.php` |

### P2 — Medium

| ID | Issue | Location |
|----|-------|---------|
| BUG-VND-16 | ZIP PDF download: temp PDF files are NOT deleted after `$zip->close()` — file leak in `storage/app/` | `VendorInvoiceController::pdfMultiple()` |
| BUG-VND-17 | `invoice.details` and `invoice.print` routes use `/vendor/invoice/` prefix vs all other invoice routes using `/vendor/vendor-invoice/` — route name inconsistency + potential collision with `VendorController` routes | `routes/tenant.php` |
| DDL-VND-18 | 5 tables have redundant `is_deleted` column: vnd_vendors, vnd_items, vnd_agreements, vnd_agreement_items_jnt, vnd_invoices — project standard uses `deleted_at` only | DDL |
| DDL-VND-19 | `vnd_vendors` missing `created_by` FK; `vnd_items` missing `created_by`; `vnd_usage_logs` missing `created_by` — inconsistent with platform standard | DDL |
| DDL-VND-20 | No UNIQUE KEY on `vnd_vendors.gst_number` — two vendors with same GSTIN can be created | DDL |
| GAP-VND-21 | Agreement status auto-transition (ACTIVE → EXPIRED when end_date < today) not implemented — requires Artisan command or Cron job | FR-VND-03.2 |
| GAP-VND-22 | `vnd_payments.status` is ENUM (INITIATED/SUCCESS/FAILED) but `vnd_invoices.status` is INT FK → sys_dropdowns — inconsistent status pattern across the module | DDL |
| PERF-VND-23 | `vnd_usage_logs` missing index on `usage_date` — PER_UNIT/HYBRID billing period aggregation does full-table scan per invoice generation | DDL |
| GAP-VND-24 | `VendorReportController` registered in routes but no reports routes appear in the route listing — dead controller? | Routes |

### P3 — Backlog

| ID | Issue |
|----|-------|
| GAP-VND-25 | Zero test coverage — highest priority missing tests: VendorInvoice auth test (14 unauthenticated endpoints), billing model calculation test (FIXED/PER_UNIT/HYBRID), invoice number uniqueness test |
| GAP-VND-26 | Invoice approval workflow (FR-VND-05.8) not implemented — no approval step before payment release |
| GAP-VND-27 | TDS tracking (FR-VND-06.6) not implemented — `tds_percent`/`tds_amount` missing from `vnd_payments` |
| GAP-VND-28 | ACC integration hooks (`acc_voucher_id` FK on invoices/payments) not added yet — needed when ACC module is built |
| GAP-VND-29 | PO management (FR-VND-08), GRN, vendor ratings (FR-VND-09) — not started; tables not created |
| GAP-VND-30 | Module `routes/web.php` registers only `VendorController` under basic auth — dead code since all functional routes are in `routes/tenant.php`; causes route duplication |

---

## Feature Area Status (as of 2026-06-30)

| # | Feature | FR | Status | Notes |
|---|--------|----|--------|-------|
| 1 | Vendor Master CRUD | FR-VND-01 | 🟡 75% | CRUD works; index Gate commented out; PII unencrypted; is_deleted redundancy |
| 2 | Item/Service Catalogue | FR-VND-02 | 🟡 80% | CRUD complete; is_deleted redundancy; missing created_by |
| 3 | Agreement Management | FR-VND-03 | 🟡 75% | CRUD works; auto-expiry not implemented; DDL trailing comma; is_deleted |
| 4 | Usage Logging | FR-VND-04 | 🟡 65% | CRUD exists; no FormRequest; missing is_active/deleted_at on table — soft delete broken |
| 5 | Invoice Generation | FR-VND-05 | 🟡 70% | Generation logic works; ZERO auth on all 14 methods; invoice number collision risk; PDF file leak |
| 6 | Payment Management | FR-VND-06 | 🟡 55% | Basic payment recording exists; no FormRequest; reconciliation implemented; TDS missing |
| 7 | Vendor Dashboard | FR-VND-07 | 🟡 50% | Views exist; controller not registered in routes; data served via VendorController AJAX |
| 8 | Reports | FR-VND | 🟡 40% | VendorReportController exists; 5 report partials in views; unclear route registration |
| 9 | Purchase Order Management | FR-VND-08 | ❌ 0% | Not started; tables not created |
| 10 | Vendor Performance Rating | FR-VND-09 | ❌ 0% | Not started |
| 11 | Vendor Self-Service Portal | FR-VND-10 | ❌ 0% | Not started |
| 12 | Invoice Approval Workflow | FR-VND-05.8 | ❌ 0% | Not started |
| 13 | EnsureTenantHasModule | — | ❌ 0% | Not applied to any route |
| 14 | Service Layer | — | ❌ 0% | Zero services; 5 needed |
| 15 | Test Coverage | — | ❌ 0/10 | Zero tests |

---

## Invoice Calculation Engine (currently in VendorInvoiceController — needs extraction)

Three billing models applied at invoice generation time:

| Billing Model | Formula |
|--------------|---------|
| `FIXED` | `sub_total = fixed_charge` (regardless of usage) |
| `PER_UNIT` | `unit_charge = unit_rate × qty_used` (aggregated from usage logs); `sub_total = unit_charge` |
| `HYBRID` | `unit_charge = unit_rate × max(qty_used - min_guarantee_qty, 0)`; `sub_total = fixed_charge + unit_charge` |
| All models | `tax_total = sub_total × (tax1+tax2+tax3+tax4) / 100`; `net_payable = sub_total + tax_total + other_charges - discount_amount` |

**Usage aggregation rule:** Sum `vnd_usage_logs.qty_used` for matching `vendor_id + agreement_item_id`. If no usage logged, default `qty_used = 1`.

**Duplicate prevention:** Reject if invoice already exists for same `agreement_item_id + billing_start_date + billing_end_date`.

**Due date:** `due_date = invoice_date + agreement.payment_terms_days`.

> This logic is embedded in `VendorInvoiceController::generateInvoice()`. Must be extracted to `VendorInvoiceService::generate()`.

---

## Cross-Module Entity Linkage (Agreement Items)

`vnd_agreement_items_jnt` supports polymorphic-style entity linking for contracts about specific assets:

| Field | Purpose |
|-------|---------|
| `related_entity_type` | FK → `sys_dropdown_table` (dropdown stores entity table name in `additional_info` JSON) |
| `related_entity_table` | Varchar: e.g., `tpt_vehicle`, `sch_asset`, `tpt_personnel` |
| `related_entity_id` | INT: PK of linked entity |

Examples: "Vehicle maintenance for Bus KA-01-AB-1234" (`related_entity_table = tpt_vehicle, related_entity_id = 42`)

> `VndAgreement` model currently imports `Modules\Transport\Models\Vehicle` directly — tight coupling. Must replace with generic resolver: `DB::table($agreementItem->related_entity_table)->find($agreementItem->related_entity_id)`.

---

## Permission Architecture

### Registered Policies (7 — all confirmed in AppServiceProvider)

| Policy | Model | Permission Prefix |
|--------|-------|------------------|
| `VendorPolicy` | `Vendor` | `tenant.vendor.*` |
| `VendorAgreementPolicy` | `VndAgreement` | `tenant.vendor-agreement.*` |
| `VndItemPolicy` | `VndItem` | `tenant.vendor-item.*` |
| `VndUsageLogPolicy` | `VndUsageLog` | `tenant.vendor-usage-log.*` |
| `VendorInvoicePolicy` | `VndInvoice` | `tenant.vendor-invoice.*` |
| `VendorPaymentPolicy` | `VndPayment` | `tenant.vendor-payment.*` |
| `VendorDashboardPolicy` | `VendorDashboard` | `tenant.vendor-dashboard.view` |

> All 7 policies ARE registered (unlike most modules). The critical failure is `VendorInvoiceController` never calling any of them — the policy exists but is never consulted.

### Role-Based Access Target

| Role | Access Level |
|------|-------------|
| School Admin | Full all vendor functions |
| Finance Manager | Full CRUD: vendor, agreement, invoice, payment, usage |
| Accountant | Full CRUD: vendor, agreement, invoice, payment, usage |
| Purchase Manager | Create/edit vendor+agreement+items; view-only invoices+payments |
| Staff (general) | View vendor list only |
| Transport Manager | Read-only vendor list |

---

## Cross-Module Dependencies

### VND Consumes From

| Source | Data | Usage |
|--------|------|-------|
| SystemConfig | `sys_dropdowns` | vendor_type_id, category_id, unit_id, payment_mode, invoice status, entity type |
| Transport | `tpt_vehicle`, `tpt_personnel` | Cross-module entity linkage via `related_entity_table` (hard import in VndAgreement) |
| SchoolSetup | `sys_users` | `logged_by`, `paid_by`, `reconciled_by` FKs |

### VND Provides To

| Consumer | Data | Notes |
|----------|------|-------|
| Accounting (ACC) | Vendor payments (when ACC built) | `acc_voucher_id` FK hook on `vnd_invoices` and `vnd_payments` |
| Inventory (INV) | PRODUCT item consumption | `item_nature = CONSUMABLE/ASSET` hook; `reorder_level` field |
| Transport | Vendor type categorization | Transport queries vendor type to find transport vendors for vehicle assignment |

---

## V1 Screen Spec Inventory (9 files)

| File | Coverage |
|------|---------|
| `00-Module-Overview.md` | Architecture, modules, stakeholders |
| `01-Vendor-Master.md` | Vendor registration, KYC, PAN/GST, bank details, documents |
| `02-Vendor-Item.md` | Item/service catalogue, HSN/SAC, pricing |
| `03-Vendor-Agreement.md` | Agreement CRUD, billing models, line items, entity linkage |
| `04-Vendor-Invoice.md` | Invoice generation, billing calculation, PDF/ZIP, email dispatch |
| `05-Payment-Details.md` | Payment recording, reconciliation, payment modes |
| `06-Usage-Log.md` | Usage tracking for PER_UNIT/HYBRID billing |
| `07-Vendor-Dashboard.md` | KPI cards, aggregated statistics |
| `08-Vendor-Reports.md` | 5 report views: agreement, invoice register, outstanding, payment register, vendor ledger summary |

---

## Design Decisions Made

| Decision | Detail | Source |
|----------|--------|--------|
| Three billing models | FIXED, PER_UNIT, HYBRID in `vnd_agreement_items_jnt.billing_model` ENUM — determines invoice calculation algorithm | V2 FR-VND-03.3 |
| `balance_due` as GENERATED STORED column | `net_payable - amount_paid` auto-computed by MySQL — never write this column from PHP | DDL `vnd_invoices` |
| Snapshot billing amounts on invoice | `fixed_charge_amt`, `unit_rate`, `tax1-4_percent` copied from agreement item at generation time — invoice is immutable record even if agreement changes | V2 FR-VND-05.1 |
| Duplicate invoice prevention | Reject if invoice for same `agreement_item_id + billing_start_date + billing_end_date` already exists | V2 FR-VND-05.1 step 7 |
| Partial success on batch generation | One failed invoice in `generateMultiple` does not rollback others — returns success/failed arrays | V2 FR-VND-05.2 |
| `vnd_agreement_items_jnt` polymorphic entity linkage | Three-column pattern (`related_entity_type` FK, `related_entity_table` varchar, `related_entity_id` int) for flexible cross-module contract references | V2 FR-VND-03.4 |
| `sys_dropdowns` for invoice status | Invoice status (Pending/Partially Paid/Fully Paid) stored as FK to `sys_dropdowns` — allows custom status names without migration | V2 design |
| `vnd_payments.status` as ENUM | Inconsistency with invoice status — `vnd_payments.status` uses ENUM (INITIATED/SUCCESS/FAILED) not FK | Current DDL; P2 to standardize |

---

## Route Registration Pattern

All functional routes registered in central `routes/tenant.php` under:
- `middleware(['auth', 'verified'])` — **EnsureTenantHasModule NOT applied (P0 gap)**
- Prefix: `vendor`, Name prefix: `vendor.`

Module-level `Modules/Vendor/routes/web.php` registers only `VendorController` under `auth` — effectively dead code (all real routes in tenant.php).

Key route issues:
- `VendorDashboardController` — NOT registered in tenant.php (no dashboard route)
- `invoice.details` and `invoice.print` route names break the `vendor.*` prefix convention
- `/vendor/invoice/` vs `/vendor/vendor-invoice/` prefix mismatch for invoice detail/print routes
- `VendorPaymentController` resource — missing trash/restore/forceDelete routes

---

## Lessons Learned

- [2026-06-30 | Business Analyst] `VendorInvoiceController` has ZERO authorization on all 14 methods because it extends `\Illuminate\Routing\Controller` instead of `App\Http\Controllers\Controller`. This is a subtle root cause that would be easy to miss — the fix is one line (change extends target) + adding Gate::authorize to each method. Always verify base class when a controller appears to bypass auth.
- [2026-06-30 | Business Analyst] VND has the highest security risk concentration of any seeded module: financial PII (PAN, bank account) stored in plaintext, zero auth on invoice generation (anyone can create financial records), and no EnsureTenantHasModule. This module must not go to production in its current state for a financial module.
- [2026-06-30 | Business Analyst] `balance_due` on `vnd_invoices` is a GENERATED STORED column. This is the second module (after TTF's `duration_minutes`) with generated columns. Always grep new modules for `AS (` or `GENERATED` in DDL migrations; these columns must not appear in `$fillable`.
- [2026-06-30 | Business Analyst] The `is_deleted` column pattern appears on 5 tables in this module — a project anti-pattern since the platform uses `deleted_at` (SoftDeletes). V2 explicitly calls this out for removal. When reviewing VND code, do not use `is_deleted` for filtering; use `whereNull('deleted_at')` or Eloquent scopes.
- [2026-06-30 | Business Analyst] `vnd_usage_logs` is missing `deleted_at` in DDL but `VndUsageLog` has `SoftDeletes` trait — every call to `$log->delete()` will throw a SQL error (Column not found: 1054). This is a silent P1 bug that means the usage log soft-delete feature is fully broken even though the UI shows it.
- [2026-06-30 | Business Analyst] `VndAgreement` model imports `Modules\Transport\Models\Vehicle` directly for the polymorphic entity lookup. This creates a class-loading dependency: if Transport module is disabled, Vendor module throws a class-not-found error. The generic resolver pattern (`DB::table($table)->find($id)`) should replace all direct model imports for polymorphic resolution.

---

## FRD Summary

| Attribute | Value |
|-----------|-------|
| FRD File | `VND_FRD_2026-06-30.md` |
| Complete Analysis Pack | `VND_FRD_Complete_2026-06-30.md` |
| Date | 2026-06-30 |
| REQ count | 14 (P0: 9, P1: 4, P2: 1) |
| BR count | 20 |
| RPT count | 5 |
| ENH count | 8 |
| Workflow count | 5 |
| Sprint tasks | 32 tasks, ~136h total |
| User stories | 7 (all P0 and P1 REQs covered) |
| Screen specs | 10 screens documented |
| Conditions catalog | `5-Requirement_Conditions/VND_Conditions.md` |

---

## Pending Next Steps

### P0 — Production Blockers (must fix before any production use)

1. Fix `VendorInvoiceController` — change extends to `App\Http\Controllers\Controller`; add `Gate::authorize('tenant.vendor-invoice.{action}')` to all 14 methods (Sprint S1, Task 1, 6h)
2. Add `EnsureTenantHasModule:Vendor` to vendor route group in `tenant.php` (Sprint S1, Task 2, 2h)
3. Migration: add `is_active`, `deleted_at`, `created_by` to `vnd_usage_logs`; fix FK name to `vnd_agreement_items_jnt` (Sprint S1, Task 3, 3h)
4. Migration: add `is_active` to `vnd_payments` (Sprint S1, Task 4, 1h)
5. Create `VendorPaymentRequest` — validate amount ≤ balance_due; conditional reference number for NEFT/UPI/Cheque (Sprint S1, Task 5, 4h)
6. Create `VndUsageLogRequest` — qty > 0; date not future; within agreement period (Sprint S1, Task 6, 3h)
7. Create `VendorAgreementItemRequest` — billing model + required fields per model (Sprint S1, Task 7, 4h)
8. Extract `VendorInvoiceService` — calculate(), generateSingle(), generateMultiple(), generateNumber(), generatePdf(), zipPdfs() (Sprint S2, Task 8, 16h)
9. Add `encrypted` cast to `Vendor` model for `pan_number`, `bank_account_no`, `gst_number`, `upi_id` (Sprint S2, Task 10, 4h)
10. Register `VendorDashboardController` routes in `tenant.php` (Sprint S2, Task 13, 2h)

### P1 — High Priority

11. Fix invoice number scheme: remove `rand()`; implement `INV-{YYYY}-{NNNNNN}` sequential (Sprint S3, Task 18, 4h)
12. Add active-agreement check to invoice generation (BR-VND-003) (Sprint S3, Task 19, 2h)
13. Add billing cycle frequency enforcement Monthly/One-Time (Sprint S3, Task 20, 4h)
14. Create `vendor:expire-agreements` Artisan command + scheduler entry (Sprint S3, Task 15, 4h)
15. Dispatch notification to Finance Manager on auto-expiry (Sprint S3, Task 16, 3h)
16. Uncomment `Gate::authorize('tenant.vendor.viewAny')` in VendorController::index() (Sprint S2, Task 12, 1h)
17. Fix PDF ZIP temp file leak — unlink individual PDFs after `$zip->close()` (Sprint S2, Task 9, 2h)
18. Replace hard Transport model import in VndAgreement with generic polymorphic resolver (Sprint S3, Task 23, 3h)

### P1 — Test Coverage

19. Write `BillingModelCalculationTest` — 8 unit test cases (FIXED/PER_UNIT/HYBRID) (Sprint S4, Task 26, 6h)
20. Write `VendorInvoiceAuthTest` — all 14 zero-auth endpoints (Sprint S4, Task 27, 8h)
21. Write `PaymentValidationTest` (Sprint S4, Task 28, 4h)
22. Write `AgreementLifecycleTest` (Sprint S4, Task 29, 4h)

### P2 — Cleanup

23. Remove `is_deleted` columns from 5 tables (migration + $fillable cleanup) (Sprint S4, Task 24, 4h)
24. Add `created_by` to vnd_vendors, vnd_items, vnd_usage_logs (Sprint S4, Task 25, 3h)
25. Implement lazy AJAX tab loading for Vendor Hub (Sprint S5, Task 30, 8h)
26. Add billing model calculation preview modal (Sprint S5, Task 31, 4h)

### Downstream Handoffs

- **Technical Auditor:** Deep code audit of `VendorInvoiceController` (14 zero-auth endpoints); `VendorPaymentController` Gate audit; `VendorReportController` route verification; `balance_due` in `$fillable` check
- **DB Architect:** DDL v2 — remove `is_deleted`, add `created_by`, fix FK names, add UNIQUE KEY on gst_number, add `pan_hash` SHA-256 column, add `INDEX idx_vnd_usage_date`
- **Backend Developer:** Sprint S1 tasks (priority order: Task 2 → Task 1 → Task 3 → Task 4 → Task 5 → Task 6)
- **Testing Architect:** BillingModelCalculationTest + VendorInvoiceAuthTest as P0 test deliverables

---

## Version History

| Version | Date | Agent | Changes |
|---------|------|-------|---------|
| 1.0 | 2026-06-30 | Business Analyst | Initial seed — V2 requirement (full read) + V1 screen specs (9 files) + filesystem verification; billing model logic documented; all 30 V2 gaps catalogued |
| 2.0 | 2026-06-30 | Business Analyst | Complete Analysis Pack produced: FRD (14 REQ, 20 BR, 5 RPT, 8 ENH), RTM, BR register, Conditions catalog, FSM catalog (3 FSMs), Data dictionary, Cross-module map, NFR catalog (20 NFRs), Risk register (10 risks), MoSCoW + RICE prioritization, Sprint tasks (32 tasks, 136h), 7 user stories, 10 screen specs, Requirements-vs-code gap analysis |
| 3.0 | 2026-06-30 | Technical Auditor | Mode X Complete Audit — Health 35/100, NO-GO. 4×P0, 8×P1, 6 stale BA findings cleared. Report: `Vendor_Complete_Audit_2026-06-30.md` |

---

## Mode X Audit Lessons (2026-06-30)

**Audit type:** Mode X (A+B+C+G+D) | **Health:** 35/100 (P0-capped) | **NO-GO**

### Critical P0 Findings
1. **MIG-VND-002** — `balance_due` is a plain DECIMAL in `create_vnd_invoices_table.php:36`. DDL spec says `GENERATED ALWAYS AS (net_payable - amount_paid) STORED`. Not in `$fillable` → all controller writes silently dropped. Fix: new migration converting it to GENERATED STORED.
2. **SEC-VND-010** — `pan_number`, `bank_account_no`, `gst_number`, `upi_id` in plain VARCHAR. Add `Encrypted` cast to Vendor model + data-migration job for existing rows.
3. **DAT-VND-001** — No `lockForUpdate()` on invoice row before payment writes in `VendorInvoiceController::store()`, `VendorPaymentController::update()`, and `destroy()`. Concurrent payments from two Finance Managers can corrupt `amount_paid`.
4. **SEC-PLATFORM-003** — EnsureTenantHasModule absent from RSP. Platform-wide fix needed.

### Key Pattern Discoveries
- **D36 pattern confirmed VND:** `balance_due` column — same as `balance_amount` in FIN (BUG-FIN-05). Two financial modules ship stale balance columns. Cross-module fix opportunity.
- **generateMultiple() failure masking:** `generateInvoice()` internal catch-all hides batch failures. Any method using the generate-then-collect pattern should be verified for this anti-pattern across the codebase.
- **SendVendorInvoiceEmailJob triple failure:** Missing tenancy init + missing retry config + wrong email recipient (admin vs vendor) = fully broken vendor email workflow. Jobs touching tenant data MUST call `tenancy()->initialize()`.
- **VndAgreement → Transport hard-import:** Cross-module tight coupling (imports `Modules\Transport\Models\Vehicle` and `Modules\Transport\Models\DriverHelper`). Pattern to watch: model files using `use Modules\{OtherModule}\`.

### What Was Above Baseline (Keep)
- 7 policies in VendorServiceProvider — zero duplicate kills (unlike EXM 13×, TTF 19×)
- `VendorInvoiceController` (14+ methods) — all gated despite extending base Controller (not App\Http\Controllers\Controller)
- `VendorAgreementController` — consistent prefix, FormRequest used throughout
- `VndItemController` — FormRequest, working toggleStatus, consistent prefix
- No dd()/dump() debug contamination found across any file
