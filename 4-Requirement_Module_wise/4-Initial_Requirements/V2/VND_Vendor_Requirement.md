# VND — Vendor Management
## Module Requirement Document V2
**Version:** 2.0 | **Date:** 2026-03-26 | **Status:** Draft | **Mode:** FULL
**Module Code:** VND | **DB Prefix:** `vnd_` | **Layer:** Tenant | **Completion:** ~53%
**Laravel Module Path:** `Modules/Vendor/` | **RBS Reference:** Module K — Finance & Accounting (K5/K6/K7)

---

## 1. Executive Summary

The Vendor module manages all school supplier relationships: vendor onboarding (KYC, GST/PAN, bank details), item/service catalogue, contract/agreement management, three billing models (Fixed, Per-Unit, Hybrid), usage logging, invoice generation with PDF/ZIP/email dispatch, payment recording, and a KPI dashboard.

**Current state (2026-03-22 audit):** ~53% production-ready. Core CRUD for vendors, agreements, items, usage logs, and invoices is implemented and routed. Critical gaps include zero authorization on `VendorInvoiceController` (14 methods), unencrypted financial PII (PAN, bank account), a missing service layer (0 of 5 needed services), DDL defects (wrong FK names, trailing commas, redundant `is_deleted` columns), missing FormRequests for invoice and payment operations, and zero test coverage.

| Priority | Issues | Examples |
|----------|--------|---------|
| P0 — Critical | 5 | No service layer; zero auth on VendorInvoiceController; no `EnsureTenantHasModule` middleware |
| P1 — High | 9 | Unencrypted PAN/bank; DDL FK errors; missing FormRequests; commented-out index Gate |
| P2 — Medium | 11 | Missing `is_active`/`created_by` on some tables; redundant `is_deleted`; performance issues |
| P3 — Low | 5 | Route naming; emoji in code; empty result on first load |
| **Total** | **30** | Overall score: 5.3/10 |

---

## 2. Module Overview

### 2.1 Purpose
The Vendor module is the Accounts Payable (AP) foundation for each school tenant. It covers end-to-end procurement and supplier payment tracking within the `tenant_{uuid}` database. When the Accounting module (ACC) is built, vendor payments will post journal entries to `acc_vouchers` automatically. Currently the module operates as a standalone procurement sub-system.

### 2.2 In Scope
- Vendor master: registration, KYC (GST/PAN), categorization, bank/UPI details, document upload
- Item and service catalogue: item master with HSN/SAC codes, pricing, unit of measure
- Contract/agreement management: billing cycle, payment terms, status lifecycle, agreement document upload
- Agreement items (line items): per-item billing model, tax configuration, cross-module entity linkage
- Usage logging: track quantity consumed per agreement item per billing period
- Invoice generation: single and batch; FIXED/PER_UNIT/HYBRID calculation engine; duplicate prevention; PDF + ZIP download
- Invoice email dispatch via queued background job
- Payment recording: multi-invoice payment, reconciliation, payment mode tracking
- Payment status tracking: Pending → Partially Paid → Fully Paid
- Vendor dashboard: aggregated KPIs

### 2.3 Out of Scope (V2 — Pending Future Modules)
- Full Accounts Payable ledger posting (requires Accounting module — ACC)
- Purchase Order (PO) management (RBS K7.1 — 📐 Proposed for V2, not yet implemented)
- Three-way matching: PO → GRN → Invoice (requires Inventory module — INV)
- Vendor rating/scorecard (RBS K6.2 — 📐 Proposed for V2)
- Expense claim management (RBS K7.2 — future)
- GSTR filing integration (RBS K13 — Accounting module scope)
- Vendor self-service portal (📐 Proposed for V2)
- TDS deduction tracking (📐 Proposed for V2)

### 2.4 Module Score Summary (Gap Analysis 2026-03-22)

| Area | Score |
|------|-------|
| DB Integrity | 6/10 |
| Route Integrity | 7/10 |
| Controller Quality | 7/10 |
| Model Quality | 7/10 |
| Service Layer | 2/10 |
| FormRequest Coverage | 6/10 |
| Policy / Auth | 7/10 |
| Test Coverage | 0/10 |
| Security | 5/10 |
| Performance | 6/10 |
| **Overall** | **5.3/10** |

---

## 3. Stakeholders & Roles

### 3.1 User Roles

| Role | Access |
|------|--------|
| Super Admin | Full access to all vendor functions across tenants |
| School Admin | Full access to all vendor functions within own tenant |
| Finance Manager | Full CRUD: vendor, agreement, invoice, payment, usage log |
| Accountant | Full CRUD: vendor, agreement, invoice, payment, usage log |
| Purchase Manager | Create/edit vendor, agreement, items; view invoices and payments |
| Staff (general) | View vendor list only |
| Transport Manager | Read-only vendor list (for vehicle ownership cross-reference) |

### 3.2 Permission Gates

Gates follow the `tenant.{resource}.{action}` pattern.

| Resource | Permissions |
|----------|------------|
| `vendor` | viewAny, view, create, update, delete, restore, forceDelete |
| `vendor-agreement` | viewAny, view, create, update, delete, restore, forceDelete |
| `vendor-item` | viewAny, view, create, update, delete, restore, forceDelete |
| `vendor-usage-log` | viewAny, view, create, update, delete, restore, forceDelete |
| `vendor-invoice` | viewAny, view, create, update, delete |
| `vendor-payment` | viewAny, view, create, update, delete |
| `vendor-dashboard` | view |

### 3.3 Policies Present (7)

All 7 policies are registered in `AppServiceProvider`:
`VendorPolicy`, `VendorAgreementPolicy`, `VendorDashboardPolicy`, `VendorInvoicePolicy`, `VendorPaymentPolicy`, `VndItemPolicy`, `VndUsageLogPolicy`.

**Gap:** Policies are defined but `VendorInvoiceController` never calls any of them (zero auth bug).

---

## 4. Functional Requirements

### FR-VND-01: Vendor Onboarding ✅

**FR-VND-01.1 — Vendor Registration** ✅
- Capture: vendor name, vendor type (dropdown FK), contact person, contact number, email, address.
- Capture tax identifiers: GST number (`gst_number`, 15-char GSTIN format), PAN number (`pan_number`, 10-char format).
- Capture banking details: bank name, account number, IFSC code, branch, UPI ID.
- Upload vendor documents via Spatie Media Library (collection: `vendor_documents`).
- Soft delete with restore and force-delete support (`SoftDeletes` trait).
- AJAX toggle for active/inactive status.

**FR-VND-01.2 — GSTIN Validation** ✅
- GSTIN format: `[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}` (15 chars).
- PAN format: `[A-Z]{5}[0-9]{4}[A-Z]{1}` (10 chars).
- Enforced at `VendorRequest` FormRequest level.
- 🆕 **V2:** GSTIN must also be unique per tenant at DB level (`UNIQUE KEY` on `gst_number`) and FormRequest (`Rule::unique` with soft-delete exclusion).

**FR-VND-01.3 — Vendor Categorization** ✅
- Vendor type stored as `sys_dropdowns` FK (key: vendor type dropdown).
- Transport module queries vendor type to filter transport vendors for vehicle assignment.
- Consistent categorization required for cross-module queries.

**FR-VND-01.4 — Financial PII Encryption** ❌ (currently unencrypted — must fix)
- 🆕 **V2 CRITICAL:** `pan_number` and `bank_account_no` MUST use Laravel `encrypted` cast (AES-256-CBC).
- 🆕 **V2:** `upi_id` SHOULD use `encrypted` cast.
- `gst_number` — semi-public (appears on invoices) — encrypt at rest, decrypt on display.
- Impacts: `Vendor` model `$casts`, search queries must decrypt before filter comparisons.

---

### FR-VND-02: Item and Service Catalogue ✅

**FR-VND-02.1 — Item Master** ✅
- Fields: item code (unique), item name, item type (`SERVICE`/`PRODUCT`), item nature (`CONSUMABLE`/`ASSET`/`SERVICE`/`NA`), category (dropdown), unit of measure (dropdown), HSN/SAC code, default price, reorder level, description.
- Upload item photo (Spatie Media: `item_photo` collection).
- Soft delete with restore support.
- Items are school-level; not vendor-specific at item master level.

**FR-VND-02.2 — HSN/SAC Code** ✅
- HSN code: for goods — determines GST rate classification.
- SAC code: for services.
- Required for GST compliance and GSTR-1 reporting.

**FR-VND-02.3 — Inventory Hook** 📐
- `item_nature` field (`CONSUMABLE`, `ASSET`) is the hook for INV module integration.
- `reorder_level` field is the hook for low-stock alerts when INV module is built.
- When INV is active, PRODUCT-type items consumed via vendor invoices should decrement `inv_stock_ledger`.

---

### FR-VND-03: Agreement (Contract) Management ✅

**FR-VND-03.1 — Agreement Creation** ✅
- Create agreement with: reference number, vendor FK, start date, end date, status (DRAFT/ACTIVE/EXPIRED/TERMINATED), billing cycle (MONTHLY/ONE_TIME/ON_DEMAND), payment terms (days), remarks.
- Upload agreement document (Spatie Media: `agreement` collection).
- `agreement_uploaded` boolean flag tracks document attachment status.

**FR-VND-03.2 — Agreement Status Lifecycle** 🟡
- DRAFT: created, not yet active.
- ACTIVE: in force; invoices can be generated.
- EXPIRED: end date passed; no new invoices.
- TERMINATED: manually closed before end date.
- 🆕 **V2:** Auto-transition ACTIVE → EXPIRED when `end_date < today` via scheduled Artisan command.
- Status transitions enforced at `VendorAgreementService` level.

**FR-VND-03.3 — Agreement Items (Line Items)** ✅
- Each agreement has one or more items in `vnd_agreement_items_jnt`.
- Per item: item reference, billing model, charges, tax configuration (4 tax tiers), entity linkage.
- **Billing Models:**
  - `FIXED`: flat amount per billing cycle regardless of usage.
  - `PER_UNIT`: `unit_rate × qty_used` (aggregated from usage logs).
  - `HYBRID`: `fixed_charge + unit_rate × max(qty_used - min_guarantee_qty, 0)`.
- Tax: `tax1_percent` through `tax4_percent` per line item (typically CGST, SGST, IGST, cess).

**FR-VND-03.4 — Cross-Module Entity Linkage** ✅
- Agreement items link to specific assets via polymorphic-style reference:
  - `related_entity_type` FK → `sys_dropdown_table` (stores table name in `additional_info` JSON)
  - `related_entity_table` varchar (e.g., `tpt_vehicle`, `sch_asset`)
  - `related_entity_id` bigint (PK of linked entity)
- Supports contracts like "Vehicle maintenance for Bus KA-01-AB-1234" or "Driver salary for John Doe".
- `VndAgreement` model imports `Modules\Transport\Models\Vehicle` and `DriverHelper` for resolution.

---

### FR-VND-04: Usage Logging ✅

**FR-VND-04.1 — Usage Log Entry** ✅
- Record: `vendor_id`, `agreement_item_id`, `qty_used`, `usage_date`, `remarks`, `logged_by` (user FK).
- Full CRUD with soft delete, restore, force-delete, and status toggle.
- Usage logs feed PER_UNIT and HYBRID billing model calculations at invoice generation time.

**FR-VND-04.2 — Usage Aggregation at Invoice Time** ✅
- On invoice generation for PER_UNIT or HYBRID items: sum all `qty_used` for matching `vendor_id + agreement_item_id`.
- If no usage logged: default `qty_used = 1` (minimum billable quantity).
- Usage logs for FIXED billing items: optional (no impact on calculation but can be recorded for analytics).

**FR-VND-04.3 — Usage Log Validation** ❌ (no FormRequest — must add)
- 🆕 **V2:** Create `VndUsageLogRequest`: `vendor_id` required/exists, `agreement_item_id` required/exists, `qty_used` required/numeric/min:0, `usage_date` required/date/not_future.
- Verify agreement item billing model is PER_UNIT or HYBRID before logging.

---

### FR-VND-05: Invoice Generation ✅ (partial — auth missing)

**FR-VND-05.1 — Single Invoice Generation** ✅
- Generate invoice for one agreement item (`generateSingle` endpoint).
- Calculation engine in `VendorInvoiceController::generateInvoice()` (to be extracted to service):
  1. Load `VndAgreementItem` with agreement and vendor.
  2. Aggregate `qty_used` from `vnd_usage_logs`.
  3. Calculate `fixed_charge_amt` and `unit_charge_amt` per billing model.
  4. `sub_total = fixed_charge_amt + unit_charge_amt`.
  5. `tax_total = sub_total × (tax1+tax2+tax3+tax4) / 100`.
  6. `net_payable = sub_total + tax_total + other_charges - discount_amount`.
  7. Duplicate prevention: reject if invoice already exists for same `agreement_item_id + billing_start_date + billing_end_date`.
  8. `due_date = invoice_date + agreement.payment_terms_days`.
  9. Create `vnd_invoices` record with status = Pending.
- Returns JSON `{ status: true/false }`.

**FR-VND-05.2 — Batch Invoice Generation** ✅
- Generate invoices for multiple agreement item IDs (`generateMultiple`).
- Partial success supported (success/failed arrays per item).
- One failure does not rollback others.

**FR-VND-05.3 — Invoice Status Lifecycle** ✅
- Status stored as `sys_dropdowns` FK (key: `vnd_invoices.status.status`):
  - `Pending`: no payment received.
  - `Partially Paid`: `amount_paid > 0` and `amount_paid < net_payable`.
  - `Fully Paid`: `amount_paid >= net_payable`.
- 🆕 **V2:** Add `Overdue` status: `due_date < today` and `balance_due > 0`.
- `balance_due` is a STORED generated column: `net_payable - amount_paid`.

**FR-VND-05.4 — Invoice Actions** ✅
- View invoice details (AJAX modal via `details` endpoint, returns rendered HTML).
- View agreement item details (AJAX modal, `type=item`).
- Toggle active status for agreement item and linked invoice.
- Add remarks to invoice (`storeRemark`).
- Print invoice list (filterable by IDs).

**FR-VND-05.5 — PDF Generation** ✅
- Single PDF: DomPDF renders `vendor::vendor-invoice.pdf.agreement` view.
- Batch PDF: multiple agreements rendered as individual PDFs, bundled into ZIP archive (`pdfMultiple`).
- ZIP created at `storage_path('app/')`, returned as download, then deleted.
- Activity logged on PDF download.
- 🆕 **V2 Bug Fix:** Individual temp PDF files must be explicitly deleted after `$zip->close()` (current bug: files leak in storage directory).

**FR-VND-05.6 — Email Dispatch** ✅
- Send invoice emails to vendor for multiple invoices (`sendMultipleEmails`).
- Queued background job: `SendVendorInvoiceEmailJob`.
- Mailable: `VendorInvoiceMail` with view `vendor::emails.invoice`.
- Sender: logged-in user's email.

**FR-VND-05.7 — Invoice Number Uniqueness** ❌ (collision risk — must fix)
- Current scheme: `'INV-' . now()->format('YmdHis') . rand(100,999)` — only 900 values/second.
- 🆕 **V2:** Replace with sequential scheme: `INV-{YYYY}-{NNNNNN}` with `AUTO_INCREMENT` or DB sequence.
- Uniqueness enforced via `UNIQUE KEY uq_vnd_invoice_no (vendor_id, invoice_number)` (already in DDL).

**FR-VND-05.8 — Invoice Approval Workflow** 📐 (new in V2)
- 🆕 **V2:** Add approval step before payment release for invoices above configurable threshold.
- Statuses: Pending → Approval Pending → Approved → Payment Pending → Paid.
- Approver role: Finance Manager or School Admin.
- Rejection returns invoice to Pending with rejection remarks.

---

### FR-VND-06: Payment Management 🟡

**FR-VND-06.1 — Payment Recording** 🟡
- Record payment: `vendor_id`, `invoice_id`, `payment_date`, `amount`, `payment_mode` (dropdown FK), `reference_no`, `status` (INITIATED/SUCCESS/FAILED), `paid_by` (user FK), `remarks`.
- Multi-invoice payment: one request covers multiple invoice IDs.
- All invoice balance updates within `DB::transaction`.

**FR-VND-06.2 — Reconciliation** 🟡
- `reconciled` boolean on payment record.
- `reconciled_by` (user FK) and `reconciled_at` (timestamp) recorded on reconciliation.
- Filter payments by reconciliation status.

**FR-VND-06.3 — Invoice Balance Update** ✅
- On payment: `amount_paid += payment.amount`.
- `balance_due` auto-updates (STORED generated column).
- Status recalculated: Pending → Partially Paid → Fully Paid.

**FR-VND-06.4 — Payment Validation** ❌ (no FormRequest — must add)
- 🆕 **V2:** Create `VendorPaymentRequest`: `invoice_id` required/exists, `amount` required/numeric/min:0.01, `payment_date` required/date, `payment_mode` required/exists, `reference_no` conditional.
- Validate: `amount <= balance_due` (payment cannot exceed outstanding balance).

**FR-VND-06.5 — Payment Modes** ✅
- Stored as Dropdown FK.
- Standard modes: Cash, Cheque, NEFT, RTGS, UPI, Bank Transfer.

**FR-VND-06.6 — TDS Deduction Tracking** 📐 (new in V2)
- 🆕 **V2:** Add `tds_percent` and `tds_amount` columns to `vnd_payments`.
- TDS applies to professional/contractor vendor payments per Income Tax Act.
- `net_paid = amount - tds_amount`.
- TDS report: quarterly summary for Form 26Q filing.

**FR-VND-06.7 — Accounting Integration Hook** 📐 (future — when ACC module built)
- 🆕 **V2 Design:** Add `acc_voucher_id` nullable FK to `vnd_payments` and `vnd_invoices`.
- When ACC module posts a payment voucher, write back the `acc_voucher_id`.
- DR: Expense Ledger, CR: Vendor Ledger (invoice posting).
- DR: Vendor Ledger, CR: Bank Ledger (payment posting).

---

### FR-VND-07: Vendor Dashboard ✅ (routed via VendorController)

**FR-VND-07.1 — Dashboard KPIs** ✅
- Total vendors (active/inactive count).
- Active agreements vs expiring agreements (next 30 days).
- Total invoiced amount (current month and YTD).
- Total paid vs outstanding balance.
- Overdue invoices (past `due_date`, not fully paid).
- Top vendors by spend.

**FR-VND-07.2 — Tabbed Hub View** ✅
- `VendorController::index()` returns tabbed view (`vendor::tab_module.tab`) combining:
  - Vendors list
  - Vendor agreements list
  - Vendor items list
  - Vendor invoices list (data-type filter: "Inv. Need To Generate" / "Invoicing Done")
  - Vendor payments list
  - Usage logs list
- All sub-lists filterable and paginated.

**FR-VND-07.3 — Dashboard Controller Registration** ❌ (not in routes — must fix)
- `VendorDashboardController` defined and `VendorDashboardPolicy` registered but NO route in `tenant.php`.
- Dashboard data currently served via `VendorController::index()` AJAX endpoint.
- 🆕 **V2:** Register `VendorDashboardController` in `tenant.php` with `EnsureTenantHasModule` middleware.

---

### FR-VND-08: Purchase Order Management 📐 (new in V2)

**FR-VND-08.1 — PO Creation** 📐
- 🆕 **V2 RBS K7.1:** Create `vnd_purchase_orders` table.
- Fields: PO number (auto-generated), vendor FK, agreement FK (optional), PO date, expected delivery date, total amount, status (DRAFT/APPROVED/RECEIVED/CANCELLED), created by, approved by.
- PO line items in `vnd_po_items_jnt`: item FK, quantity, unit rate, tax.

**FR-VND-08.2 — PO Approval** 📐
- Approval workflow: DRAFT → Approved (by Finance Manager/Admin).
- Rejection returns to DRAFT with remarks.

**FR-VND-08.3 — GRN (Goods Receipt Note)** 📐
- Create `vnd_grn` table linked to PO.
- Record quantities actually received vs PO quantity.
- Partial receipt supported (PO status → PARTIAL_RECEIVED).

**FR-VND-08.4 — Three-Way Matching** 📐 (requires INV module)
- When INV module is active: PO → GRN → Invoice three-way match before invoice payment approval.
- Invoice can only proceed to payment if GRN quantity matches PO and invoice amount matches GRN.

---

### FR-VND-09: Vendor Performance Rating 📐 (new in V2)

**FR-VND-09.1 — Performance Scorecard** 📐
- RBS K6.2: Rate vendors on: delivery timeliness, invoice accuracy, quality of service, complaint count.
- `vnd_vendor_ratings` table: `vendor_id`, `rating_period`, `delivery_score`, `quality_score`, `invoice_accuracy_score`, `overall_score`, `rated_by`, `remarks`.
- Aggregate rating shown on vendor detail page.

---

### FR-VND-10: Vendor Self-Service Portal 📐 (new in V2)

**FR-VND-10.1 — Portal Access** 📐
- Vendors access a read-only portal via a unique secure token (not a full tenant account).
- View: their invoices, payment status, outstanding balance.
- Submit: new invoices for approval (vendor-initiated invoice entry).
- Portal access controlled by a `portal_enabled` flag on `vnd_vendors`.

---

## 5. Data Model

### 5.1 Table Overview

| Table | Model | Status | Description |
|-------|-------|--------|-------------|
| `vnd_vendors` | `Vendor` | ✅ | Vendor master: KYC, banking, type |
| `vnd_items` | `VndItem` | ✅ | Item/service catalogue: HSN/SAC, price, unit |
| `vnd_agreements` | `VndAgreement` | ✅ | Contract: billing cycle, payment terms, status |
| `vnd_agreement_items_jnt` | `VndAgreementItem` | ✅ | Line items: billing model, tax config |
| `vnd_usage_logs` | `VndUsageLog` | ✅ | Actual usage per agreement item per period |
| `vnd_invoices` | `VndInvoice` | ✅ | Generated invoices: amounts, tax, payment tracking |
| `vnd_payments` | `VndPayment` | ✅ | Payment records: mode, reconciliation |
| `vnd_purchase_orders` | `VndPurchaseOrder` | 📐 | PO management (V2 new) |
| `vnd_po_items_jnt` | `VndPoItem` | 📐 | PO line items (V2 new) |
| `vnd_grn` | `VndGrn` | 📐 | Goods Receipt Notes (V2 new) |
| `vnd_vendor_ratings` | `VndVendorRating` | 📐 | Performance scorecard (V2 new) |

### 5.2 Table: vnd_vendors

| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| `id` | INT UNSIGNED PK | No | Auto-increment |
| `vendor_name` | VARCHAR(100) | No | Unique per tenant |
| `vendor_type_id` | INT UNSIGNED FK | No | → `sys_dropdown_table` |
| `contact_person` | VARCHAR(100) | No | Primary contact |
| `contact_number` | VARCHAR(30) | No | Phone |
| `email` | VARCHAR(100) | Yes | |
| `address` | VARCHAR(512) | Yes | |
| `gst_number` | VARCHAR(50) | Yes | 15-char GSTIN — 🆕 V2: encrypted cast |
| `pan_number` | VARCHAR(50) | Yes | 10-char PAN — 🆕 V2: encrypted cast (CRITICAL) |
| `bank_name` | VARCHAR(100) | Yes | |
| `bank_account_no` | VARCHAR(50) | Yes | 🆕 V2: encrypted cast (CRITICAL) |
| `bank_ifsc_code` | VARCHAR(20) | Yes | 11-char IFSC |
| `bank_branch` | VARCHAR(100) | Yes | |
| `upi_id` | VARCHAR(100) | Yes | 🆕 V2: encrypted cast |
| `is_active` | TINYINT(1) | No | Default 1 |
| `is_deleted` | TINYINT(1) | No | ❌ V2: Remove — use `deleted_at` only |
| `created_at` / `updated_at` | TIMESTAMP | — | Standard |
| `deleted_at` | TIMESTAMP | Yes | Soft delete |
| 🆕 `created_by` | INT UNSIGNED FK | Yes | → `sys_users` — add in V2 |

**DDL Issues:**
- `is_deleted` column is redundant (use `deleted_at` only per project standard). Remove.
- Missing `created_by` column. Add.
- No DB-level unique constraint on `gst_number` — add `UNIQUE KEY uq_vnd_vendor_gst (gst_number)`.

### 5.3 Table: vnd_items

| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| `id` | INT UNSIGNED PK | No | |
| `item_code` | VARCHAR(50) | Yes | Unique key |
| `item_name` | VARCHAR(100) | No | |
| `item_type` | ENUM | No | SERVICE / PRODUCT |
| `item_nature` | ENUM | No | CONSUMABLE / ASSET / SERVICE / NA |
| `category_id` | INT UNSIGNED FK | No | → `sys_dropdown_table` |
| `unit_id` | INT UNSIGNED FK | No | → `sys_dropdown_table` |
| `hsn_sac_code` | VARCHAR(20) | Yes | GST compliance |
| `default_price` | DECIMAL(12,2) | No | Default 0.00 |
| `reorder_level` | DECIMAL(12,2) | No | Default 0.00 — INV hook |
| `item_photo_uploaded` | TINYINT(1) | No | Spatie media flag |
| `description` | TEXT | Yes | |
| `is_active` | TINYINT(1) | No | |
| `is_deleted` | TINYINT(1) | No | ❌ V2: Remove |
| `deleted_at` | TIMESTAMP | Yes | |
| 🆕 `created_by` | INT UNSIGNED FK | Yes | Add in V2 |

### 5.4 Table: vnd_agreements

| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| `id` | INT UNSIGNED PK | No | |
| `vendor_id` | INT UNSIGNED FK | No | → `vnd_vendors` ON DELETE CASCADE |
| `agreement_ref_no` | VARCHAR(50) | Yes | Physical contract ref |
| `start_date` | DATE | No | |
| `end_date` | DATE | No | |
| `status` | ENUM | No | DRAFT / ACTIVE / EXPIRED / TERMINATED |
| `billing_cycle` | ENUM | No | MONTHLY / ONE_TIME / ON_DEMAND |
| `payment_terms_days` | INT UNSIGNED | Yes | Credit period — default 30 |
| `remarks` | TEXT | Yes | |
| `agreement_uploaded` | TINYINT(1) | No | Spatie media flag |
| `is_active` | TINYINT(1) | No | |
| `is_deleted` | TINYINT(1) | No | ❌ V2: Remove |
| `deleted_at` | TIMESTAMP | Yes | |

**DDL Bug (DB-04):** Trailing comma before `) ENGINE=InnoDB` causes syntax error. Must fix.

### 5.5 Table: vnd_agreement_items_jnt

| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| `id` | INT UNSIGNED PK | No | |
| `agreement_id` | INT UNSIGNED FK | No | → `vnd_agreements` ON DELETE CASCADE |
| `item_id` | INT UNSIGNED FK | No | → `vnd_items` ON DELETE RESTRICT |
| `billing_model` | ENUM | No | FIXED / PER_UNIT / HYBRID |
| `fixed_charge` | DECIMAL(12,2) | No | Base charge for FIXED/HYBRID |
| `unit_rate` | DECIMAL(10,2) | No | Per-unit rate for PER_UNIT/HYBRID |
| `min_guarantee_qty` | DECIMAL(10,2) | No | HYBRID: free units threshold |
| `tax1_percent`–`tax4_percent` | DECIMAL(5,2) | No | CGST, SGST, IGST, cess |
| `related_entity_type` | INT UNSIGNED FK | Yes | → `sys_dropdown_table` |
| `related_entity_table` | VARCHAR(60) | Yes | E.g., `tpt_vehicle` |
| `related_entity_id` | INT UNSIGNED | Yes | PK of linked entity |
| `description` | VARCHAR(255) | Yes | |
| `is_active` | TINYINT(1) | No | |
| `is_deleted` | TINYINT(1) | No | ❌ V2: Remove |
| `deleted_at` | TIMESTAMP | Yes | |

**DDL Bug (DB-05):** Trailing comma before `) ENGINE=InnoDB`. Must fix.

### 5.6 Table: vnd_usage_logs

| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| `id` | INT UNSIGNED PK | No | |
| `vendor_id` | INT UNSIGNED FK | No | → `vnd_vendors` ON DELETE CASCADE |
| `agreement_item_id` | INT UNSIGNED FK | No | → `vnd_agreement_items_jnt` (FK currently wrong) |
| `usage_date` | DATE | No | |
| `qty_used` | DECIMAL(10,2) | No | Default 0.00 |
| `remarks` | VARCHAR(255) | Yes | |
| `logged_by` | INT UNSIGNED FK | Yes | → `sys_users` |
| `created_at` / `updated_at` | TIMESTAMP | — | |
| 🆕 `is_active` | TINYINT(1) | No | ❌ Missing — add in V2 |
| 🆕 `deleted_at` | TIMESTAMP | Yes | ❌ Missing — add in V2 |
| 🆕 `created_by` | INT UNSIGNED FK | Yes | ❌ Missing — add in V2 |

**DDL Bug (DB-06/DB-07):** Missing `is_active`, `deleted_at`, `created_by`. FK references `vnd_agreement_items` (wrong — should be `vnd_agreement_items_jnt`). Both must be fixed.

**Index:** 🆕 Add `INDEX idx_vnd_usage_date (usage_date)` for performance.

### 5.7 Table: vnd_invoices

| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| `id` | INT UNSIGNED PK | No | |
| `vendor_id` | INT UNSIGNED FK | No | → `vnd_vendors` ON DELETE RESTRICT |
| `agreement_id` | INT UNSIGNED FK | Yes | → `vnd_agreements` ON DELETE SET NULL |
| `agreement_item_id` | INT UNSIGNED FK | Yes | FK currently wrong — must fix |
| `item_description` | VARCHAR(255) | No | Snapshot of item name at generation |
| `invoice_number` | VARCHAR(50) | No | Unique per vendor |
| `invoice_date` | DATE | No | |
| `billing_start_date` | DATE | Yes | |
| `billing_end_date` | DATE | Yes | |
| `fixed_charge_amt` | DECIMAL(12,2) | No | Snapshot |
| `unit_charge_amt` | DECIMAL(12,2) | No | Snapshot |
| `qty_used` | DECIMAL(10,2) | No | Aggregated from usage logs |
| `unit_rate` | DECIMAL(10,2) | No | Snapshot |
| `min_guarantee_qty` | DECIMAL(10,2) | No | Snapshot |
| `tax1_percent`–`tax4_percent` | DECIMAL(5,2) | No | Snapshot at generation |
| `sub_total` | DECIMAL(12,2) | No | fixed + unit |
| `tax_total` | DECIMAL(12,2) | No | sub_total × tax% / 100 |
| `other_charges` | DECIMAL(12,2) | No | Penalties/bonuses |
| `discount_amount` | DECIMAL(12,2) | No | |
| `net_payable` | DECIMAL(12,2) | No | Final amount due |
| `amount_paid` | DECIMAL(12,2) | No | Running paid total |
| `balance_due` | DECIMAL(12,2) GENERATED | — | net_payable - amount_paid (STORED) |
| `due_date` | DATE | Yes | invoice_date + payment_terms_days |
| `status` | INT UNSIGNED FK | No | → `sys_dropdown_table` |
| `remarks` | VARCHAR(512) | Yes | |
| `is_active` | TINYINT(1) | No | |
| `is_deleted` | TINYINT(1) | No | ❌ V2: Remove |
| `deleted_at` | TIMESTAMP | Yes | |
| 🆕 `acc_voucher_id` | INT UNSIGNED FK | Yes | ACC integration hook |
| 🆕 `approved_by` | INT UNSIGNED FK | Yes | Invoice approval workflow |
| 🆕 `approved_at` | TIMESTAMP | Yes | |

**DDL Bug (DB-08):** FK `fk_vnd_inv_agreement_item` references `vnd_agreement_items` (wrong — should be `vnd_agreement_items_jnt`). Must fix.

### 5.8 Table: vnd_payments

| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| `id` | INT UNSIGNED PK | No | |
| `vendor_id` | INT UNSIGNED FK | No | → `vnd_vendors` ON DELETE RESTRICT |
| `invoice_id` | INT UNSIGNED FK | No | → `vnd_invoices` ON DELETE RESTRICT |
| `payment_date` | DATE | No | |
| `amount` | DECIMAL(14,2) | No | |
| `payment_mode` | INT UNSIGNED FK | No | → `sys_dropdown_table` |
| `reference_no` | VARCHAR(100) | Yes | Cheque/NEFT/UPI ref |
| `status` | ENUM | Yes | INITIATED / SUCCESS / FAILED |
| `paid_by` | INT UNSIGNED FK | Yes | → `sys_users` |
| `reconciled` | TINYINT(1) | No | Default 0 |
| `reconciled_by` | INT UNSIGNED FK | Yes | → `sys_users` |
| `reconciled_at` | TIMESTAMP | Yes | |
| `remarks` | TEXT | Yes | |
| `is_deleted` | TINYINT(1) | No | ❌ V2: Remove |
| `deleted_at` | TIMESTAMP | Yes | |
| 🆕 `is_active` | TINYINT(1) | No | ❌ Missing — add in V2 |
| 🆕 `tds_percent` | DECIMAL(5,2) | Yes | TDS deduction % |
| 🆕 `tds_amount` | DECIMAL(12,2) | Yes | TDS amount deducted |
| 🆕 `acc_voucher_id` | INT UNSIGNED FK | Yes | ACC integration hook |

**Issue (DB-09):** Missing `is_active` column. Must add.
**Issue (DB-11):** `status` is ENUM here but INT FK on `vnd_invoices` — inconsistent pattern. Standardize to dropdown FK.

### 5.9 Relationships

```
vnd_vendors          1 ── N   vnd_agreements
vnd_vendors          1 ── N   vnd_invoices          (direct vendor_id)
vnd_vendors          1 ── N   vnd_payments          (via hasManyThrough through vnd_invoices)
vnd_vendors          1 ── N   vnd_usage_logs

vnd_agreements       1 ── N   vnd_agreement_items_jnt
vnd_agreement_items_jnt N ── 1 vnd_items
vnd_agreement_items_jnt 1 ── N vnd_invoices
vnd_agreement_items_jnt 1 ── N vnd_usage_logs

vnd_invoices         1 ── N   vnd_payments

vnd_agreement_items_jnt.related_entity_id → tpt_vehicle.id       (optional)
vnd_agreement_items_jnt.related_entity_id → tpt_personnel.id     (optional)
vnd_agreement_items_jnt.related_entity_id → sch_asset.id         (optional)
```

---

## 6. API Endpoints & Routes

### 6.1 Route Registration Status

All vendor routes are registered in `routes/tenant.php` under `middleware(['auth','verified'])`, `prefix('vendor')`, `name('vendor.')`.

**Critical Gap (RT-01):** `EnsureTenantHasModule` middleware is NOT applied to the vendor route group. Any authenticated user of any tenant can access vendor routes even if the tenant has not licensed the VND module.

| Controller | Registered In | Auth Gates | Status |
|------------|--------------|------------|--------|
| `VendorController` | `tenant.php` lines 877–881 | Yes (except `index()` commented out) | 🟡 |
| `VendorAgreementController` | `tenant.php` lines 869–873 | Yes | ✅ |
| `VndItemController` | `tenant.php` lines 893–897 | Yes | ✅ |
| `VndUsageLogController` | `tenant.php` lines 885–889 | Yes | ✅ |
| `VendorInvoiceController` | `tenant.php` lines 901–910 | **ZERO AUTH** | ❌ |
| `VendorPaymentController` | `tenant.php` line 915 | Needs audit | 🟡 |
| `VendorDashboardController` | **NOT registered** | N/A | ❌ |

**Module web.php** (`Modules/Vendor/routes/web.php`) registers only `VendorController` under a basic `auth` middleware. This file is effectively dead — all functional routes are in `tenant.php`. The module-level `web.php` should be emptied or used only for development stubs.

### 6.2 Registered Endpoints

#### Vendor CRUD (`VendorController`)
| Method | URL | Route Name | Action |
|--------|-----|-----------|--------|
| GET | `/vendor/vendor` | `vendor.vendor.index` | List vendors (tabbed hub) |
| GET | `/vendor/vendor/create` | `vendor.vendor.create` | Create form |
| POST | `/vendor/vendor` | `vendor.vendor.store` | Store vendor |
| GET | `/vendor/vendor/{vendor}` | `vendor.vendor.show` | Show detail |
| GET | `/vendor/vendor/{vendor}/edit` | `vendor.vendor.edit` | Edit form |
| PUT | `/vendor/vendor/{vendor}` | `vendor.vendor.update` | Update vendor |
| DELETE | `/vendor/vendor/{vendor}` | `vendor.vendor.destroy` | Soft delete |
| GET | `/vendor/vendor/trash/view` | `vendor.vendor.trashed` | Trash list |
| GET | `/vendor/vendor/{id}/restore` | `vendor.vendor.restore` | Restore |
| DELETE | `/vendor/vendor/{id}/force-delete` | `vendor.vendor.forceDelete` | Force delete |
| POST | `/vendor/vendor/{vendor}/toggle-status` | `vendor.vendor.toggleStatus` | Toggle active |

#### Agreement CRUD (`VendorAgreementController`)
| Method | URL | Route Name | Action |
|--------|-----|-----------|--------|
| Standard resource | `/vendor/vendor-agreement` | `vendor.vendor-agreement.*` | Full CRUD |
| GET | `/vendor/vendor-agreement/trash/view` | `vendor.vendor-agreement.trashed` | Trash |
| GET | `/vendor/vendor-agreement/{id}/restore` | `vendor.vendor-agreement.restore` | Restore |
| DELETE | `/vendor/vendor-agreement/{id}/force-delete` | `vendor.vendor-agreement.forceDelete` | Force delete |
| POST | `/vendor/vendor-agreement/{vendor}/toggle-status` | `vendor.vendor-agreement.toggleStatus` | Toggle |

#### Invoice (`VendorInvoiceController`) — **Zero Auth on all endpoints**
| Method | URL | Route Name | Action |
|--------|-----|-----------|--------|
| Standard resource | `/vendor/vendor-invoice` | `vendor.vendor-invoice.*` | Full CRUD |
| GET | `/vendor/vendor-invoice/trash/view` | `vendor.vendor-invoice.trashed` | Trash |
| POST | `/vendor/vendor-invoice/{invoice}/toggle-status` | `vendor.vendor-invoice.toggleStatus` | Toggle |
| POST | `/vendor/vendor-invoice/generate` | `vendor.vendor-invoice.generate` | Single invoice |
| POST | `/vendor/vendor-invoice/generate-multiple` | `vendor.vendor-invoice.generate-multiple` | Batch invoice |
| POST | `/vendor/vendor-invoice/pdf-multiple` | `vendor.vendor-invoice.pdf-multiple` | ZIP PDF download |
| GET | `/vendor/vendor/invoice/print` | `vendor-invoice.print` | Print list |
| GET | `/vendor/vendor/invoice/details` | `invoice.details` | Details modal |

**Route Issues:**
- `vendor/invoice/print` and `vendor/invoice/details` use different prefix (`vendor/invoice/`) vs all other invoice routes (`vendor/vendor-invoice/`) — potential collision with `VendorController` routes (RT-03).
- Route names `invoice.remark.store` and `invoice.details` break the `vendor.*` prefix convention (RT-04).

#### Payment (`VendorPaymentController`)
| Method | URL | Notes |
|--------|-----|-------|
| Standard resource | `/vendor/vendor-payments` | No trash/restore/forceDelete routes (RT-02) |

#### Dashboard
| Method | URL | Route Name |
|--------|-----|-----------|
| GET | `/vendor/dashboard/data` | `vendor.dashboard.data` |

### 6.3 VendorInvoiceController — Zero Auth: All 14 Methods

The following 14 methods have zero authorization checks. Any authenticated tenant user can call them:

| # | Method | Risk |
|---|--------|------|
| 1 | `index()` | View all invoice data |
| 2 | `create()` | Access invoice creation form |
| 3 | `store(Request $request)` | Record payment against invoice |
| 4 | `show($id)` | View invoice detail |
| 5 | `edit($id)` | Access invoice edit form |
| 6 | `update(Request $request, $id)` | Modify invoice |
| 7 | `destroy($id)` | Delete invoice |
| 8 | `toggleStatus(Request $request, $invoice)` | Change item/invoice active status |
| 9 | `generateSingle(Request $request)` | **Generate invoice (creates financial record)** |
| 10 | `generateMultiple(Request $request)` | **Batch invoice generation** |
| 11 | `pdfMultiple(Request $request)` | **Download ZIP of all agreement PDFs** |
| 12 | `sendMultipleEmails(Request $request)` | **Send emails to vendors** |
| 13 | `storeRemark(Request $request)` | Add remarks to invoice |
| 14 | `printList(Request $request)` | Print invoice list |

**Root Cause:** `VendorInvoiceController extends \Illuminate\Routing\Controller` instead of `App\Http\Controllers\Controller`. The base class switch alone does not add auth — explicit Gate checks must be added to each method.

**Required fix:**
```
Change: class VendorInvoiceController extends Controller
To: class VendorInvoiceController extends \App\Http\Controllers\Controller
Then add Gate::authorize('tenant.vendor-invoice.{action}') to each method.
```

---

## 7. UI Screens

### 7.1 Implemented Screens

| Screen | View Path | Status |
|--------|-----------|--------|
| Vendor Hub (tabbed) | `vendor::tab_module.tab` | ✅ |
| Vendor Create/Edit | `vendor::vendor.create` / `.edit` | ✅ |
| Vendor Show | `vendor::vendor.show` | ✅ |
| Vendor Trash | `vendor::vendor.trash` | ✅ |
| Agreement Create/Edit | `vendor::vendor-agreement.create` / `.edit` | ✅ |
| Agreement Show | `vendor::vendor-agreement.show` | ✅ |
| Item Create/Edit/Show | `vendor::vendor-item.*` | ✅ |
| Usage Log Create/Edit/Show | `vendor::usage-log.*` | ✅ |
| Invoice Index | `vendor::vendor-invoice.index` | ✅ |
| Invoice Details (modal) | `vendor::vendor-invoice.invoice-details` | ✅ |
| Agreement Item Details | `vendor::vendor-invoice.agreement-item-details` | ✅ |
| Invoice JS | `vendor::vendor-invoice.js` | ✅ |
| Invoice Print | `vendor::vendor-invoice.print` | ✅ |
| Invoice PDF | `vendor::vendor-invoice.pdf.agreement` | ✅ |
| Payment Details Index | `vendor::payment-details.index` | ✅ |
| Payment JS | `vendor::payment-details.js` | ✅ |
| Dashboard | `vendor::dashboard.index` | ✅ |
| Dashboard JS | `vendor::dashboard.js` | ✅ |
| Email Template | `vendor::emails.invoice` | ✅ |

### 7.2 Proposed New Screens (V2)

| Screen | Status | Notes |
|--------|--------|-------|
| Purchase Order List/Create/Edit | 📐 | FR-VND-08 |
| GRN Create/View | 📐 | FR-VND-08.3 |
| Vendor Performance Scorecard | 📐 | FR-VND-09 |
| TDS Summary Report | 📐 | FR-VND-06.6 |
| Invoice Approval Queue | 📐 | FR-VND-05.8 |
| Vendor Portal (external) | 📐 | FR-VND-10 |

### 7.3 Screen UX Issues

- **Invoice hub (first load):** `vendorInvoiceQuery()` returns empty results when no filters are applied (`// 🔴 NO FILTER → NO DATA`). User sees empty table on first load — must show default data or a prompt. (CT-05)
- **Index tab loading:** `VendorController::index()` fires 6 separate paginated queries in a single request (PERF-01). Refactor to lazy-load each tab via AJAX.
- **Vendor filter dropdown:** `Vendor::get()` loads ALL vendors with all columns for the filter dropdown. Replace with `Vendor::select('id','vendor_name')->active()->get()`. (PERF-03)

---

## 8. Business Rules

### BR-VND-01: GST/PAN Uniqueness Per Tenant ❌
- GSTIN must be unique per tenant (one school cannot have two vendors with identical GSTIN).
- PAN must be unique per tenant.
- **V2 fix:** Add `UNIQUE KEY uq_vnd_vendor_gst (gst_number)` to `vnd_vendors` DDL.
- **V2 fix:** Add `Rule::unique('vnd_vendors','gst_number')->whereNull('deleted_at')->ignore($this->vendor)` to `VendorRequest`.
- FormRequest already makes `gst_number` required — align DDL (DDL has it nullable, FormRequest requires it — inconsistency FR-05).

### BR-VND-02: Invoice Duplicate Prevention ✅ (in code; not service layer)
- System must prevent generating a second invoice for the same `agreement_item_id` with the same billing period (start_date, end_date).
- Current check: `VndInvoice::where('agreement_item_id',...)->whereDate('billing_start_date',...)->whereDate('billing_end_date',...)->exists()`.
- **V2:** Move this check to `VendorInvoiceService::checkDuplicate()`.

### BR-VND-03: Active Agreement Prerequisite ❌
- Invoices can only be generated for agreement items belonging to agreements with `status = ACTIVE`.
- DRAFT, EXPIRED, TERMINATED agreements must block invoice generation.
- **Current state:** Not enforced in code.
- **V2 fix:** Service layer check before invoice creation: throw `BusinessRuleException` if agreement is not ACTIVE.

### BR-VND-04: Payment Cannot Exceed Balance Due ❌
- Payment amount must not exceed `balance_due` on the linked invoice.
- **Current state:** Floor is correct (`max(net_payable - amount_paid, 0)`) but no input validation prevents overpayment.
- **V2 fix:** Add to `VendorPaymentRequest`: `'amount' => 'lte:'.Invoice::find($request->invoice_id)->balance_due`.

### BR-VND-05: Tax Snapshot on Invoice ✅
- Tax percentages copied to `vnd_invoices` at generation time.
- Subsequent changes to agreement item taxes do not affect existing invoices.
- This is correct accounting behaviour. Must be preserved.

### BR-VND-06: Three-Way Matching (Future) 📐
- When INV module is built: PO must exist, GRN must match PO quantity, invoice must match GRN.
- Invoice cannot be approved for payment until 3-way match passes.
- Until INV module is built: invoices generated directly from agreement items.

### BR-VND-07: Agreement Auto-Expiry ❌
- Scheduled job must set `status = EXPIRED` when `end_date < today` and `status = ACTIVE`.
- **V2 fix:** Add `VendorAgreementService::expireAgreements()` called by a daily Artisan command or scheduled via `Kernel.php`.
- Sends notification to Finance Manager listing agreements that expired.

### BR-VND-08: Billing Cycle Frequency Enforcement ❌
- MONTHLY: only one invoice per agreement item per calendar month.
- ONE_TIME: only one invoice per agreement item per agreement lifetime.
- ON_DEMAND: no frequency restriction.
- **Current state:** Partial — billing period start/end date duplicate check exists but does not explicitly enforce calendar month uniqueness.
- **V2 fix:** In `VendorInvoiceService`: check `MONTHLY` → `whereMonth/whereYear` uniqueness; `ONE_TIME` → check no prior invoice exists.

### BR-VND-09: UPI/Bank Details Required for Electronic Payment ❌
- If payment mode is NEFT/RTGS/UPI, `reference_no` must be required.
- If payment mode is Cheque, `reference_no` (cheque number) must be required.
- **V2 fix:** Conditional validation in `VendorPaymentRequest`.

### BR-VND-10: Invoice Number Uniqueness Per Vendor ✅ (DDL) ❌ (generation logic)
- DB-level: `UNIQUE KEY uq_vnd_invoice_no (vendor_id, invoice_number)` already defined.
- Generation logic uses `rand(100,999)` — collision risk at 900 values/second.
- **V2 fix:** Sequential scheme `INV-{YYYY}-{NNNNNN}` with DB-enforced `AUTO_INCREMENT` tracking or Laravel atomic sequence.

---

## 9. Workflows

### WF-VND-01: Vendor Onboarding

```
Actor: Finance Manager / School Admin

1. Navigate to Vendor → Create
2. Fill: vendor name, type, contact person, phone, email, address
3. Fill: GST number (GSTIN format validated), PAN number (PAN format validated)
4. Fill: bank name, account number, IFSC, branch, UPI ID
5. FormRequest validates formats and uniqueness of GSTIN/PAN
6. Save vendor record (is_active = 1)
7. Optional: upload vendor document via Media Library (vendor_documents collection)
8. Activity log entry created
9. Vendor appears in Transport module vendor dropdown (if vendor_type = Transport)
```

### WF-VND-02: Agreement and Invoice Lifecycle (Full FSM)

```
Agreement FSM:
  DRAFT ──[Activate]──→ ACTIVE
  ACTIVE ──[End date passes / manual]──→ EXPIRED
  ACTIVE ──[Manual terminate]──→ TERMINATED
  EXPIRED ──[Renew]──→ DRAFT (new agreement)

Invoice FSM:
  [None] ──[generateSingle/generateMultiple]──→ Pending
  Pending ──[partial payment]──→ Partially Paid
  Partially Paid ──[full payment]──→ Fully Paid
  Pending ──[due_date passes, no payment]──→ Overdue (V2)
  Pending/Partially Paid ──[Approval workflow V2]──→ Approval Pending → Approved

Full workflow:
1. Finance Manager creates Agreement (status: DRAFT)
   → Uploads agreement PDF document
2. Agreement Items added
   → Select item, set billing model + charges + taxes
   → Optional: link to vehicle/driver/asset
3. Agreement activated (status → ACTIVE)
4. [PER_UNIT/HYBRID only] Usage logging
   → Usage Logs entered as services are consumed
5. Invoice Generation
   → Finance Manager selects agreement items
   → VendorInvoiceService runs calculation engine
   → Duplicate check; active agreement check
   → Invoice created: status = Pending, due_date set
   → PDF generated; Email queued to vendor
6. Payment Recording
   → Vendor pays; Finance Manager records: amount, mode, reference, reconciled flag
   → Invoice: amount_paid updated, balance_due recalculated, status transitions
7. Agreement expiry
   → Scheduled job auto-transitions ACTIVE → EXPIRED when end_date passes
   → No new invoices generated against expired agreement
```

### WF-VND-03: Batch Invoice and PDF ZIP Download

```
1. Finance Manager views "Inv. Need To Generate" tab (agreement items with no invoice)
2. Selects multiple items via checkbox
3. Clicks "Generate Multiple" → batch invoice generation (partial success supported)
4. Success/failed counts shown; failed items listed with reason
5. Clicks "Download PDF (Multiple)" → pdfMultiple endpoint
6. System generates individual DomPDF for each selected agreement
7. Creates ZIP bundle at storage_path('app/')
8. ZIP returned as browser download
9. ZIP deleted; individual temp PDFs deleted (V2 fix for SEC-VND-05)
```

### WF-VND-04: Payment Reconciliation

```
1. Bank statement received
2. Finance Manager opens payment record
3. Matches payment entry to bank statement transaction
4. Sets reconciled = true, reconciled_by = current user, reconciled_at = now()
5. Reconciled payments filterable in payments list
6. Unreconciled amounts highlighted in dashboard KPIs
```

### WF-VND-05: Agreement Auto-Expiry (Scheduled Job — V2)

```
Schedule: Daily at 00:05 (low traffic window)

1. Query: vnd_agreements WHERE status = 'ACTIVE' AND end_date < CURDATE()
2. For each: update status = 'EXPIRED'
3. Log: sys_activity_logs (entity: VndAgreement, action: auto_expired)
4. Notify: Finance Manager via notification with list of expired agreements
5. Invoices already generated remain unaffected
```

### WF-VND-06: Purchase Order Lifecycle (V2 Proposed)

```
PO FSM:
  DRAFT ──[Submit for approval]──→ APPROVAL_PENDING
  APPROVAL_PENDING ──[Approve]──→ APPROVED
  APPROVAL_PENDING ──[Reject]──→ DRAFT
  APPROVED ──[Issue PO to vendor]──→ ISSUED
  ISSUED ──[Goods received]──→ RECEIVED / PARTIAL_RECEIVED
  RECEIVED ──[Invoice matched]──→ INVOICED

1. Purchase Manager creates PO against vendor/agreement
2. Finance Manager approves PO
3. PO issued to vendor
4. Goods received — GRN created
5. Vendor submits invoice
6. Three-way match: PO ↔ GRN ↔ Invoice
7. Invoice approved for payment after match passes
```

---

## 10. Non-Functional Requirements (NFRs)

### NFR-VND-01: Authorization (Critical)

| Requirement | Priority | Status |
|-------------|----------|--------|
| All vendor routes must be under `EnsureTenantHasModule` middleware (module: VND) | P0 | ❌ Missing |
| `VendorInvoiceController` — all 14 methods must have Gate checks | P0 | ❌ Missing |
| `VendorController::index()` Gate (`tenant.vendor.viewAny`) must be uncommented | P1 | ❌ Commented out |
| `VendorDashboardController` must be registered in `tenant.php` | P1 | ❌ Not registered |
| `VendorPaymentController` Gate audit required | P1 | 🟡 Unaudited |

### NFR-VND-02: Data Encryption (High)

| Field | Table | V1 State | V2 Requirement |
|-------|-------|----------|----------------|
| `pan_number` | `vnd_vendors` | Plaintext | `encrypted` cast (AES-256-CBC) — Critical |
| `bank_account_no` | `vnd_vendors` | Plaintext | `encrypted` cast — Critical |
| `upi_id` | `vnd_vendors` | Plaintext | `encrypted` cast — High |
| `gst_number` | `vnd_vendors` | Plaintext | `encrypted` cast — Medium |
| `bank_ifsc_code` | `vnd_vendors` | Plaintext | `encrypted` cast — Low (semi-public) |

**Impact of encryption:** DB-level UNIQUE constraint on `pan_number` cannot be used with encrypted values. Uniqueness must be enforced at application level (FormRequest `Rule::unique` before encryption, OR store a deterministic hash alongside for uniqueness checking).

### NFR-VND-03: Service Layer Architecture (P0)

Zero service classes currently exist. All business logic is in controllers (untestable, violates SRP).

| Service Class | Responsibility |
|---------------|---------------|
| `VendorService` | Vendor CRUD, GSTIN/PAN validation, document management |
| `VendorAgreementService` | Agreement lifecycle, status transitions, auto-expiry |
| `VendorInvoiceService` | Calculation engine (FIXED/PER_UNIT/HYBRID), duplicate check, invoice number sequencing, PDF generation |
| `VendorPaymentService` | Payment recording, balance update, reconciliation, TDS calculation |
| `VendorReportService` | Dashboard KPIs, ageing report, payment report, TDS summary |

### NFR-VND-04: Performance

| Issue | Priority | Fix |
|-------|----------|-----|
| `index()` fires 6 paginated queries — heavy on load | P1 | Lazy-load each tab via AJAX (load on tab click) |
| `Vendor::get()` loads ALL vendors for dropdown | P2 | Replace with `select('id','vendor_name')->active()->get()` |
| `vendorInvoiceQuery()` uses multiple `whereHas` | P2 | Replace with JOIN-based query |
| No index on `vnd_usage_logs.usage_date` | P3 | Add `INDEX idx_vnd_usage_date (usage_date)` |

### NFR-VND-05: Rate Limiting

- Invoice generation endpoints (`/generate`, `/generate-multiple`) must have rate limiting applied.
- Recommended: `throttle:10,1` (10 requests per minute per user) on invoice generation routes.
- Batch email endpoint (`sendMultipleEmails`) must be rate-limited: `throttle:5,1`.

### NFR-VND-06: Audit Trail

- All vendor operations must log to `sys_activity_logs`: entity type, entity ID, action, user ID, timestamp.
- `VendorController` already uses `activityLog()` helper.
- `VendorInvoiceController` must add activity logging for: invoice generation, payment recording, PDF download, email dispatch.

### NFR-VND-07: Data Integrity

- All DB transactions involving multiple table updates (payment recording, invoice status update) must use `DB::transaction()`.
- `VendorPaymentController::store()` must wrap payment + invoice balance update in single transaction.

### NFR-VND-08: Queue Configuration

- `SendVendorInvoiceEmailJob` must have retry logic: `$tries = 3`, `backoff = [30, 60, 120]`.
- Failed jobs must log failure with vendor ID and invoice IDs for re-send.
- Queue: `vendor-emails` dedicated queue channel recommended.

---

## 11. Dependencies

### 11.1 Internal Module Dependencies

| Module | Dependency Type | Details |
|--------|----------------|---------|
| **SYS (System Config)** | Required | `sys_dropdown_table`: vendor type, payment mode, item type, item category, unit, invoice status. `sys_media`: vendor docs, agreement docs, item photos. `sys_activity_logs`: audit trail. `sys_users`: paid_by, reconciled_by, created_by FKs. |
| **TPT (Transport)** | Bidirectional | `tpt_vehicle.vendor_id` → `vnd_vendors.id`: vehicle references its supplier. `vnd_agreement_items_jnt.related_entity_id` → `tpt_vehicle.id`: line items link to vehicles. `VehicleController` queries vendor type dropdown. |
| **INV (Inventory)** | Future hook | `vnd_items.item_nature` = CONSUMABLE/ASSET is the INV hook. PO → GRN → Invoice three-way matching requires INV module. |
| **MNT (Maintenance)** | Future hook | Contractor vendors for maintenance work orders will reference `vnd_vendors`. `MNT` work orders can trigger vendor invoices. |
| **FAC (Finance Accounting)** | Future — via D21 | Vendor payments post to `acc_vouchers`. Each vendor needs a corresponding `acc_ledgers` record. Integration deferred until FAC module is built. `vnd_invoices.acc_voucher_id` and `vnd_payments.acc_voucher_id` FKs reserved. |
| **NTF (Notifications)** | Optional | Agreement expiry notifications, overdue invoice alerts to Finance Manager. |

### 11.2 Cross-Module Data Flows

```
VND → TPT:  vnd_vendors.id referenced by tpt_vehicle.vendor_id
TPT → VND:  VehicleController queries vnd_vendors filtered by vendor_type (transport)

VND → INV:  vnd_items.item_nature = CONSUMABLE triggers INV stock update on invoice (future)
INV → VND:  INV purchase receipt triggers GRN; GRN enables invoice approval (future 3-way match)

VND → FAC:  vnd_payments → acc_vouchers (AP payment voucher posting — future)
VND → FAC:  vnd_invoices → acc_vouchers (AP invoice posting — future)
FAC → VND:  acc_voucher_id written back to vnd_invoices/vnd_payments on posting

VND → NTF:  agreement expiry alert, overdue invoice alert → notification queue
VND → NTF:  invoice generated → email to vendor via SendVendorInvoiceEmailJob
```

### 11.3 External Dependencies

| Dependency | Usage |
|-----------|-------|
| `barryvdh/laravel-dompdf` | PDF generation for vendor invoices |
| `spatie/laravel-medialibrary` | Vendor documents, agreement PDFs, item photos |
| `ZipArchive` (PHP built-in) | Batch PDF ZIP download |
| `stancl/tenancy v3.9` | Tenant isolation; `EnsureTenantHasModule` middleware |
| `nwidart/laravel-modules v12` | Module structure |

---

## 12. Test Scenarios

**Current test count: 0 (zero tests exist in `Modules/Vendor/tests/`)**

### 12.1 Unit Tests — Billing Model Calculation Engine

| Test ID | Scenario | Expected Result |
|---------|----------|----------------|
| UT-VND-01 | FIXED billing model: `fixed_charge=5000`, no usage | `sub_total = 5000`, `unit_charge_amt = 0` |
| UT-VND-02 | PER_UNIT: `unit_rate=10`, `qty_used=150` | `unit_charge_amt = 1500`, `fixed_charge_amt = 0` |
| UT-VND-03 | HYBRID: `fixed_charge=2000`, `unit_rate=10`, `min_guarantee_qty=50`, `qty_used=80` | `unit_charge_amt = (80-50)*10 = 300`, `sub_total = 2300` |
| UT-VND-04 | HYBRID: `qty_used < min_guarantee_qty` | `unit_charge_amt = 0` (no over-minimum usage) |
| UT-VND-05 | Tax calculation: `sub_total=10000`, `tax1=9`, `tax2=9` | `tax_total = 1800`, `net_payable = 11800` |
| UT-VND-06 | Discount applied: `net_payable=11800`, `discount=500` | `net_payable = 11300` |
| UT-VND-07 | Other charges: `net_payable=11300`, `other_charges=200` | `net_payable = 11500` |
| UT-VND-08 | PER_UNIT with no usage log (default qty=1) | `unit_charge_amt = 1 * unit_rate` |

### 12.2 Unit Tests — Validation

| Test ID | Scenario | Expected |
|---------|----------|----------|
| UT-VND-09 | Valid GSTIN `27AAAAA0000A1Z5` | Passes validation |
| UT-VND-10 | Invalid GSTIN (wrong length) | Fails with GSTIN format error |
| UT-VND-11 | Valid PAN `AAAAA0000A` | Passes validation |
| UT-VND-12 | Invalid PAN (lowercase) | Fails with PAN format error |
| UT-VND-13 | Duplicate GSTIN in same tenant | Fails uniqueness validation |

### 12.3 Feature Tests — Invoice Generation

| Test ID | Scenario | Expected |
|---------|----------|----------|
| FT-VND-01 | Generate invoice for ACTIVE agreement | Invoice created, status = Pending |
| FT-VND-02 | Generate invoice for DRAFT agreement | Blocked with error |
| FT-VND-03 | Generate invoice for EXPIRED agreement | Blocked with error |
| FT-VND-04 | Duplicate invoice for same item + same billing period | Rejected with duplicate error |
| FT-VND-05 | Batch invoice generation — all valid | All invoices created, success count = n |
| FT-VND-06 | Batch generation — some invalid | Partial success; failed items listed individually |
| FT-VND-07 | MONTHLY agreement: second invoice same month | Blocked by billing cycle enforcement |

### 12.4 Feature Tests — Payment & Authorization

| Test ID | Scenario | Expected |
|---------|----------|----------|
| FT-VND-08 | Record payment < balance_due | Invoice → Partially Paid |
| FT-VND-09 | Record payment = balance_due | Invoice → Fully Paid |
| FT-VND-10 | Record payment > balance_due | Validation error: exceeds balance |
| FT-VND-11 | Payment within DB transaction — DB error | Full rollback |
| FT-VND-12 | Finance Manager calls generateSingle | Authorized |
| FT-VND-13 | Staff user calls generateSingle (after SEC-VND-01 fix) | 403 Forbidden |
| FT-VND-14 | Unauthenticated user calls any vendor route | 401 / redirect to login |
| FT-VND-15 | Tenant without VND module license accesses vendor routes | 403 (EnsureTenantHasModule) |

### 12.5 Feature Tests — Agreement Lifecycle

| Test ID | Scenario | Expected |
|---------|----------|----------|
| FT-VND-16 | Run auto-expiry command: ACTIVE agreement end_date = yesterday | Status → EXPIRED |
| FT-VND-17 | Run auto-expiry command: ACTIVE agreement end_date = tomorrow | Status unchanged |
| FT-VND-18 | Reconcile payment | `reconciled=true`, `reconciled_by`, `reconciled_at` set |
| FT-VND-19 | Changing tax on agreement item after invoice generated | Existing invoice tax unchanged (snapshot preserved) |

---

## 13. Glossary

| Term | Definition |
|------|-----------|
| Vendor | A third-party supplier of goods or services to the school |
| GSTIN | Goods and Services Tax Identification Number (15 characters, India) |
| PAN | Permanent Account Number (10 characters, India — income tax identifier) |
| IFSC | Indian Financial System Code (11 characters, bank branch identifier) |
| HSN | Harmonised System of Nomenclature — code for goods classification under GST |
| SAC | Service Accounting Code — code for services classification under GST |
| Agreement | A formal contract between the school and a vendor defining terms and billing |
| Agreement Item | A line item within an agreement specifying an item/service, billing model, and rates |
| Billing Model | How the agreement item is charged: FIXED, PER_UNIT, or HYBRID |
| min_guarantee_qty | In HYBRID billing: quantity included in the fixed charge before per-unit billing begins |
| Invoice | A generated payable document based on agreement items and usage |
| GRN | Goods Receipt Note — records actual quantity of goods received against a PO |
| PO | Purchase Order — formal authorization to a vendor to supply goods/services |
| Three-Way Match | Validation that PO, GRN, and invoice are consistent before payment |
| TDS | Tax Deducted at Source — income tax deducted on vendor payments (India) |
| Reconciliation | Matching a recorded payment to a bank statement transaction |
| balance_due | Generated column: `net_payable - amount_paid` on invoice |
| AP | Accounts Payable — amounts owed by the school to vendors |
| ACC Voucher | An accounting journal entry in the `acc_vouchers` table (Accounting module) |

---

## 14. Suggestions

### S-VND-01: Extract Billing Calculator as a Testable Value Object
Extract the billing model calculation logic from `VendorInvoiceController::generateInvoice()` into `VendorInvoiceService::calculate(VndAgreementItem $item, float $qtyUsed): InvoiceCalculation`. The `InvoiceCalculation` value object carries all computed amounts. This makes unit testing billing models trivial without a DB.

### S-VND-02: Standardize Status Handling
`vnd_invoices.status` is a dropdown INT FK but `vnd_payments.status` is an ENUM. The project standard uses dropdown FKs for user-visible statuses. Migrate `vnd_payments.status` to a dropdown FK for consistency and to support translated status labels.

### S-VND-03: Event-Driven Agreement Expiry Notifications
Instead of polling in the scheduled command, dispatch a `VendorAgreementExpired` event. Listener sends notification via NTF module. This decouples the notification logic from the expiry logic and allows future listeners (e.g., suspend vendor portal access on expiry).

### S-VND-04: Agreement Renewal Flow
When an EXPIRED agreement is renewed, create a new DRAFT agreement pre-populated from the expired one. Retain original agreement history. Add a `renewed_from_agreement_id` FK on `vnd_agreements` for audit trail.

### S-VND-05: Lazy Tab Loading for Performance
The hub `VendorController::index()` currently runs all 6 queries on page load. Implement tab-based AJAX loading: render the tab layout on first load, then fetch each tab's data via AJAX when the user clicks that tab. Cache filter state in session. This reduces initial page load time by ~80%.

### S-VND-06: Deterministic Hash for Encrypted PAN Uniqueness
When encrypting `pan_number` (which is non-reversible for DB comparison), store a parallel `pan_hash` column using `hash('sha256', strtoupper($pan))`. Use `pan_hash` for uniqueness checks and search. Display the decrypted `pan_number` in UI. This avoids the `UNIQUE KEY` limitation on encrypted fields.

### S-VND-07: Vendor Opening Balance Migration
RBS K2.2 requires vendor opening balance import for existing schools migrating to Prime-AI. Add a `vnd_vendor_opening_balances` table or a seeder tool that creates synthetic invoices representing historical outstanding balances.

### S-VND-08: Overdue Invoice Alert Cron
Add a daily scheduled job: query invoices with `due_date < today AND balance_due > 0`. Set status to `Overdue` (new dropdown value). Dispatch notification to Finance Manager with overdue summary. This enables proactive payment follow-up.

---

## 15. Appendices

### Appendix A: DDL Defects Summary (from Gap Analysis)

| ID | Table | Defect | Fix |
|----|-------|--------|-----|
| DB-01 | `vnd_vendors` | `is_deleted` column — redundant (use `deleted_at`) | Remove column; update model |
| DB-02 | `vnd_vendors` | Missing `created_by` column | Add `created_by INT UNSIGNED NULL` |
| DB-03 | `vnd_items` | Missing `created_by`; redundant `is_deleted` | Same as DB-01/02 |
| DB-04 | `vnd_agreements` | Trailing comma before `) ENGINE=` — syntax error | Remove trailing comma |
| DB-05 | `vnd_agreement_items_jnt` | Trailing comma before `) ENGINE=` — syntax error | Remove trailing comma |
| DB-06 | `vnd_usage_logs` | Missing `is_active`, `deleted_at`, `created_by` | Add all three columns |
| DB-07 | `vnd_usage_logs` | FK references `vnd_agreement_items` (wrong table name) | Fix to `vnd_agreement_items_jnt` |
| DB-08 | `vnd_invoices` | FK references `vnd_agreement_items` (wrong table name) | Fix to `vnd_agreement_items_jnt` |
| DB-09 | `vnd_payments` | Missing `is_active` column | Add `is_active TINYINT(1) DEFAULT 1` |
| DB-10 | Multiple | Both `is_deleted` and `deleted_at` — redundant | Remove `is_deleted` from all tables |
| DB-11 | `vnd_payments` | `status` is ENUM; `vnd_invoices.status` is INT FK — inconsistent | Standardize to dropdown FK |

### Appendix B: Service Classes Required

| Service | Key Methods |
|---------|------------|
| `VendorService` | `create()`, `update()`, `validateGSTIN()`, `validatePAN()`, `toggleStatus()` |
| `VendorAgreementService` | `create()`, `activate()`, `terminate()`, `expireAll()`, `checkExpiry()` |
| `VendorInvoiceService` | `generateSingle()`, `generateMultiple()`, `calculate()`, `checkDuplicate()`, `generateNumber()`, `generatePdf()`, `zipPdfs()` |
| `VendorPaymentService` | `record()`, `updateInvoiceBalance()`, `reconcile()`, `calculateTds()` |
| `VendorReportService` | `dashboardKpis()`, `ageingReport()`, `paymentReport()`, `tdsReport()` |

### Appendix C: FormRequests Required

| FormRequest | Controllers | Covers |
|-------------|------------|--------|
| `VendorRequest` | VendorController | ✅ Exists — add GSTIN uniqueness check |
| `VendorAgreementRequest` | VendorAgreementController | ✅ Exists |
| `VndItemRequest` | VndItemController | ✅ Exists |
| `VendorInvoiceRequest` | VendorInvoiceController | ❌ Create — single/multiple generate validation |
| `VendorPaymentRequest` | VendorPaymentController | ❌ Create — amount≤balance, mode, reference conditional |
| `VndUsageLogRequest` | VndUsageLogController | ❌ Create — vendor exists, item exists, qty≥0, date not future |
| `VendorAgreementItemRequest` | VendorAgreementController | ❌ Create — billing model, charges, tax percents |

### Appendix D: Controllers and File Paths

| Controller | Path | Lines |
|------------|------|-------|
| `VendorController` | `Modules/Vendor/app/Http/Controllers/VendorController.php` | 443 |
| `VendorAgreementController` | `Modules/Vendor/app/Http/Controllers/VendorAgreementController.php` | — |
| `VendorInvoiceController` | `Modules/Vendor/app/Http/Controllers/VendorInvoiceController.php` | — |
| `VendorPaymentController` | `Modules/Vendor/app/Http/Controllers/VendorPaymentController.php` | — |
| `VndItemController` | `Modules/Vendor/app/Http/Controllers/VndItemController.php` | — |
| `VndUsageLogController` | `Modules/Vendor/app/Http/Controllers/VndUsageLogController.php` | — |
| `VendorDashboardController` | `Modules/Vendor/app/Http/Controllers/VendorDashboardController.php` | — |

### Appendix E: Development Effort Estimate (Gap Analysis)

| Priority | Work | Est. Hours |
|----------|------|-----------|
| P0 — Critical | Service layer (5 classes), EnsureTenantHasModule middleware, index Gate, basic tests | 12–16h |
| P1 — High | FormRequests (4 new), DDL fixes (11 items), PAN/bank encryption, VendorInvoiceController auth | 16–24h |
| P2 — Medium | Payment soft-delete routes, index() AJAX lazy-load, scheduled jobs, Policy fixes, Events/Listeners | 12–16h |
| P3 — Low | Route naming, vendor performance analytics, code cleanup | 4–6h |
| Test Suite | Unit (billing engine), Feature (auth, workflow, lifecycle) | 12–16h |
| **Total** | | **56–78 hours** |

---

## 16. V1 → V2 Delta

### 16.1 What Changed from V1

| Area | V1 | V2 Change |
|------|----|-----------|
| Scope | 7 core tables documented | +4 proposed tables (PO, PO items, GRN, vendor ratings) |
| FR-VND-05.7 | Invoice number collision risk noted | Sequential scheme `INV-{YYYY}-{NNNNNN}` specified |
| FR-VND-05.8 | Not in V1 | 📐 Invoice approval workflow added |
| FR-VND-06.6 | Not in V1 | 📐 TDS deduction tracking added |
| FR-VND-06.7 | Mentioned as future | Explicitly designed: `acc_voucher_id` FK columns specified |
| FR-VND-08 | Out of scope in V1 | 📐 Purchase Order management fully specified |
| FR-VND-09 | Out of scope ("not implemented") | 📐 Vendor performance rating specified |
| FR-VND-10 | Out of scope | 📐 Vendor self-service portal added |
| Section 5 (Data Model) | Field-level details | DDL issues called out per table; V2 column additions noted |
| Section 6 (Routes) | Status table | Full endpoint table added; all 14 VendorInvoiceController methods enumerated |
| Section 7 (UI) | Not present in V1 | Full screen inventory added; UX issues documented |
| Section 10 (NFRs) | Not present in V1 | Encryption, rate limiting, queue config, audit trail NFRs added |
| Section 11 (Dependencies) | Integration points only | Full cross-module data flow diagram added |
| Section 12 (Tests) | Priority areas only | 19 specific test scenarios across unit + feature tests |
| Section 14 (Suggestions) | Not present in V1 | 8 actionable architectural suggestions |
| Section 15 (Appendices) | Not present in V1 | DDL defects table, service methods, FormRequest matrix, effort estimate |

### 16.2 Critical Items Carried Forward from V1 (Must Fix Before Production)

| Item | V1 Section | V2 Section | Priority |
|------|-----------|-----------|----------|
| VendorInvoiceController — zero auth (14 methods) | SEC-VND-01 | Section 6.3, NFR-VND-01 | P0 |
| No service layer (0 of 5 classes) | Section 7 | NFR-VND-03, Appendix B | P0 |
| EnsureTenantHasModule missing from route group | Not in V1 | RT-01, NFR-VND-01 | P0 |
| PAN and bank_account_no unencrypted | SEC-VND-02 | NFR-VND-02, FR-VND-01.4 | P1 |
| PDF ZIP temp file leak (SEC-VND-05) | SEC-VND-05 | FR-VND-05.5 | P1 |
| DDL FK errors (vnd_agreement_items → _jnt) | Implied | Appendix A DB-07, DB-08 | P1 |
| DDL syntax errors (trailing commas) | Not in V1 | Appendix A DB-04, DB-05 | P1 |
| Missing FormRequests for invoice/payment/usage | Section 12 | Appendix C | P1 |
| VendorDashboardController not in routes | SEC-VND-03 | FR-VND-07.3 | P1 |
| VendorController::index() Gate commented out | Not in V1 | CT-01, NFR-VND-01 | P1 |
| Zero test coverage | Section 13 | Section 12 | P1 |
| Agreement auto-expiry not implemented | BR-VND-07 | BR-VND-07, WF-VND-05 | P2 |
| Payment amount > balance_due not validated | BR-VND-04 | BR-VND-04, FR-VND-06.4 | P2 |
| Invoice number collision (rand 100-999) | SEC-VND-04 | FR-VND-05.7, BR-VND-10 | P2 |

---

*Document generated: 2026-03-26 | Source: V1 (2026-03-25), Gap Analysis (2026-03-22), tenant_db_v2.sql, Modules/Vendor/ code scan*
*Reviewed against: RBS Module K (K5/K6/K7), tenant_db_v2.sql lines 1808–2034, `/Modules/Vendor/` controllers and routes*
