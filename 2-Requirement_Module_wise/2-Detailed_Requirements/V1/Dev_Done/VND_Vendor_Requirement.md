# VND — Vendor Management Module
## Requirement Document v1.0

**Module Code:** VND
**Module Name:** Vendor Management
**DB Prefix:** `vnd_*`
**Layer:** Tenant Module (per-school database)
**RBS Reference:** Module K — Finance & Accounting, Sections K5/K6/K7 (lines 2957–2988)
**Document Date:** 2026-03-25
**Status:** Development ~53% complete

---

## Section 1 — Module Overview

The Vendor module manages all third-party supplier relationships for a school: vendor onboarding (KYC, categorization, GST/PAN details), contract/agreement management, item/service catalogue, usage logging, invoice generation with multi-billing-model support (Fixed / Per-Unit / Hybrid), payment recording with reconciliation, and document management.

The module is positioned as the Accounts Payable (AP) foundation. When the Accounting module (ACC) is built, vendor payments will flow through the voucher engine. Currently, the Vendor module operates as a standalone procurement and payment tracking sub-system within the tenant schema.

The module is a Tenant-layer module, running inside each school's isolated `tenant_{uuid}` database, with the `vnd_` prefix for all its tables.

---

## Section 2 — Scope

### In Scope
- Vendor master: registration, KYC (GST, PAN), categorization, bank/UPI details
- Item and service catalogue: item master with HSN/SAC codes, pricing, categories
- Contract/agreement management: agreement terms, billing cycle, payment terms, document upload
- Agreement items (line items): billing model per item/service (Fixed, Per-Unit, Hybrid), tax configuration
- Usage logging: track quantity consumed per agreement item per period
- Invoice generation: single or batch; FIXED / PER_UNIT / HYBRID billing model calculation; duplicate prevention; PDF generation and ZIP download
- Invoice email dispatch (background Job)
- Payment recording: multi-invoice payment, amount reconciliation, payment modes, reconciliation flag
- Payment status tracking on invoice: Pending → Partially Paid → Fully Paid
- Vendor Dashboard: aggregated KPIs

### Out of Scope
- Full Accounts Payable ledger posting (requires Accounting module — future)
- Purchase Order (PO) management (defined in RBS K7.1, not yet implemented)
- Three-way matching: PO → GRN → Invoice (requires Inventory module — future)
- Vendor rating/scorecard (RBS K6.2 — not implemented)
- Expense claim management (RBS K7.2 — not implemented)
- GSTR filing integration (RBS K13 — Accounting module scope)

---

## Section 3 — User Roles and Permissions

| Role | Access Level |
|---|---|
| Super Admin | Full access all vendor functions |
| School Admin | Full access all vendor functions |
| Finance Manager / Accountant | Full CRUD on vendor, agreement, invoice, payment |
| Purchase Manager | Create vendor, agreement, items; view invoices |
| Staff | View vendor list only |
| Transport Manager | Read vendor list (for vehicle ownership cross-reference) |

Permission gates follow `tenant.{resource}.{action}` pattern:
- `tenant.vendor.viewAny`, `tenant.vendor.view`, `tenant.vendor.create`, `tenant.vendor.update`, `tenant.vendor.delete`, `tenant.vendor.restore`, `tenant.vendor.forceDelete`
- `tenant.vendor-agreement.*`
- `tenant.vendor-item.*`
- `tenant.vendor-usage-log.*`

**Critical Bug — VendorInvoiceController Zero Auth:**
`VendorInvoiceController` extends `Illuminate\Routing\Controller` (not `App\Http\Controllers\Controller`) and has **zero Gate checks** across 14 methods. Any authenticated user can generate invoices, record payments, download PDF bundles, and send emails. This is a critical authorization failure.

---

## Section 4 — Functional Requirements

### FR-VND-1: Vendor Onboarding

**FR-VND-1.1 — Vendor Registration**
- Capture vendor name, vendor type (dropdown), contact person, contact number, email, address.
- Capture tax identifiers: GST number (`gst_number`), PAN number (`pan_number`).
- Capture banking details: bank name, account number, IFSC code, branch, UPI ID.
- Upload vendor documents (Spatie Media Library collection: `vendor_documents`, single file).
- Vendor type is a dropdown-driven classification (e.g., Transport, Stationery, Catering, IT, Maintenance, Utilities).
- Soft delete with restore and force-delete support.
- AJAX toggle for active/inactive status.

**FR-VND-1.2 — GSTIN Validation**
- GST number must be validated against the 15-character GSTIN format: `[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}`.
- PAN number must be validated against the 10-character format: `[A-Z]{5}[0-9]{4}[A-Z]{1}`.
- Validation enforced at FormRequest level.

**FR-VND-1.3 — Vendor Categorization**
- Vendor type dropdown supports multiple vendor categories.
- The Transport module uses `vendor_type_id` dropdown with key `vnd_vendors.vendor_type_id.vendor_type_id` to filter transport vendors for vehicle assignment.
- Consistent categorization is required for cross-module queries.

### FR-VND-2: Item and Service Catalogue

**FR-VND-2.1 — Item Master**
- Define items/services that can be purchased from vendors.
- Fields: item code, item name, item type (dropdown: Product/Service), item nature (dropdown), category (dropdown), unit of measure (dropdown), HSN/SAC code, default price, reorder level, description.
- Upload item photo (Spatie Media: `item_photo`).
- Soft delete with restore.
- Items are school-level; not vendor-specific at the item master level.

**FR-VND-2.2 — HSN/SAC Code**
- HSN code: used for goods; determines GST classification.
- SAC code: used for services.
- Must be recorded for GST compliance (required for GSTR-1 filing).

### FR-VND-3: Agreement (Contract) Management

**FR-VND-3.1 — Agreement Creation**
- Create vendor agreement with: reference number (`agreement_ref_no`), vendor, start date, end date, status (DRAFT / ACTIVE / EXPIRED / TERMINATED), billing cycle (MONTHLY / ONE_TIME / ON_DEMAND), payment terms (days), remarks.
- Upload agreement document (Spatie Media: `agreement` collection, single PDF/image file).
- `agreement_uploaded` boolean flag tracks document attachment status.

**FR-VND-3.2 — Agreement Status Lifecycle**
- DRAFT: agreement created, not yet active.
- ACTIVE: agreement in force; invoices can be generated.
- EXPIRED: end date passed; no new invoices.
- TERMINATED: manually closed before end date.
- System should auto-transition to EXPIRED when `end_date < today` (scheduled job or on-access check).

**FR-VND-3.3 — Agreement Items (Line Items)**
- Each agreement has one or more agreement items (line items) in `vnd_agreement_items_jnt`.
- Per line item: item reference, billing model, charges, tax configuration, related entity linkage.
- **Billing Models:**
  - `FIXED`: flat amount per billing period regardless of usage.
  - `PER_UNIT`: `unit_rate × qty_used` (from usage log).
  - `HYBRID`: fixed charge + `unit_rate × max(qty_used - min_guarantee_qty, 0)`.
- Tax: up to 4 tax percentages (`tax1_percent` through `tax4_percent`) per line item.
- `related_entity_type` and `related_entity_id` allow linking a line item to a specific asset (e.g., a specific vehicle in `tpt_vehicle`) or person (e.g., a driver in `tpt_personnel`).

**FR-VND-3.4 — Related Entity Linkage (Cross-Module)**
- Agreement items can be linked to Transport entities: vehicle (`tpt_vehicle`) or driver/helper (`tpt_personnel`).
- This supports contracts such as "Vehicle maintenance contract for Bus KA-01-AB-1234" or "Driver salary agreement for John Doe".
- `related_entity_table` stores the table name; `related_entity_id` stores the FK.

### FR-VND-4: Usage Logging

**FR-VND-4.1 — Usage Log Entry**
- Record actual quantity consumed per vendor per agreement item: `vendor_id`, `agreement_item_id`, `qty_used`, `usage_date`.
- Usage logs feed into PER_UNIT and HYBRID billing model calculations at invoice generation time.
- CRUD with soft delete, restore, force-delete, and status toggle.

**FR-VND-4.2 — Usage Aggregation at Invoice Time**
- When generating an invoice for a PER_UNIT or HYBRID item, the system sums all usage log entries for `vendor_id + agreement_item_id` → `qty_used`.
- If no usage is logged, `qty_used` defaults to 1 (minimum billable quantity logic).

### FR-VND-5: Invoice Generation

**FR-VND-5.1 — Single Invoice Generation**
- Generate invoice for one agreement item (`generateSingle`).
- Calculation engine (in `VendorInvoiceController::generateInvoice()`):
  1. Look up `VndAgreementItem` with agreement and vendor.
  2. Aggregate `qty_used` from `vnd_usage_logs`.
  3. Calculate `fixed_charge_amt`, `unit_charge_amt` based on billing model.
  4. Calculate `sub_total = fixed_charge_amt + unit_charge_amt`.
  5. Calculate `tax_total = sub_total × (tax1+tax2+tax3+tax4) / 100`.
  6. Calculate `net_payable = sub_total + tax_total`.
  7. Apply `other_charges` and `discount_amount`.
  8. **Duplicate prevention:** Check if invoice exists for same `agreement_item_id` + billing period (start/end date). Reject if duplicate.
  9. Set `due_date = invoice_date + agreement.payment_terms_days`.
  10. Create `vnd_invoices` record with status = Pending.
- Returns JSON response (`status: true/false`).

**FR-VND-5.2 — Batch Invoice Generation**
- Generate invoices for multiple agreement item IDs in one request (`generateMultiple`).
- Each item processed independently; partial success supported (success/failed arrays in response).
- Errors per item are captured individually — one failure does not rollback others.

**FR-VND-5.3 — Invoice Status Lifecycle**
- Invoice statuses are stored as Dropdown IDs (key: `vnd_invoices.status.status`):
  - `Pending`: newly generated, no payment.
  - `Partially Paid`: `amount_paid > 0` but `amount_paid < net_payable`.
  - `Fully Paid`: `amount_paid >= net_payable`.
- Invoice `amount_paid` and `balance_due` (computed attribute) update on each payment.

**FR-VND-5.4 — Invoice Actions**
- View invoice details (AJAX modal: `details` endpoint, returns rendered HTML).
- View agreement item details (AJAX modal: `details` endpoint, `type=item`).
- Toggle active status for agreement item and its linked invoice.
- Add remarks to invoice (`storeRemark` endpoint).
- Print invoice list (filterable by IDs).

**FR-VND-5.5 — PDF Generation**
- Single PDF: DomPDF renders `vendor::vendor-invoice.pdf.agreement` view.
- Batch PDF: multiple agreements rendered as individual PDFs, bundled into a ZIP archive (`pdfMultiple`).
- ZIP created at `storage_path('app/')`, returned as download, then deleted.
- Activity logged on PDF download.

**FR-VND-5.6 — Email Dispatch**
- Send invoice emails to vendor for multiple invoices (`sendMultipleEmails`).
- Dispatched as a queued background job: `SendVendorInvoiceEmailJob`.
- Email uses `VendorInvoiceMail` Mailable with blade template `vendor::emails.invoice`.
- Sender is the logged-in user's email.

### FR-VND-6: Payment Management

**FR-VND-6.1 — Payment Recording**
- Record payment against one or more invoices: `vendor_id`, `invoice_id`, `payment_date`, `amount`, `payment_mode` (dropdown), `reference_no`, `status` (default: SUCCESS), `paid_by` (user FK), `remarks`.
- Multi-invoice payment: one payment request can cover multiple invoice IDs.
- Single vendor or per-invoice vendor assignment supported.

**FR-VND-6.2 — Reconciliation**
- `reconciled` boolean flag on payment record.
- `reconciled_by` (user FK) and `reconciled_at` (timestamp) recorded when reconciled.
- Reconciliation can be set at time of payment entry or later.

**FR-VND-6.3 — Invoice Balance Update**
- On each payment, the linked invoice is updated:
  - `amount_paid += payment.amount`
  - `balance_due = max(net_payable - amount_paid, 0)`
  - Status recalculated: Pending → Partially Paid → Fully Paid.
- All updates within a DB transaction (`DB::transaction`).

**FR-VND-6.4 — Payment Dashboard View**
- `VendorController::index()` aggregates payment data via `vendorPaymentsQuery()`.
- Filterable by: vendor, date range, payment status, reconciliation flag.
- `VendorDashboardController` provides KPI aggregates.

**FR-VND-6.5 — Payment Modes**
- Payment mode stored as Dropdown FK (`vnd_payments.payment_mode`).
- Standard modes: Cash, Cheque, NEFT, RTGS, UPI, Bank Transfer.

### FR-VND-7: Vendor Dashboard

**FR-VND-7.1 — Dashboard KPIs**
- Total vendors (active/inactive).
- Active agreements vs expiring agreements (next 30 days).
- Total invoiced amount (current month / YTD).
- Total paid vs outstanding balance.
- Overdue invoices (past `due_date`, not fully paid).
- Top vendors by spend.

**FR-VND-7.2 — Vendor Tab Module View**
- `VendorController::index()` returns a tabbed view (`vendor::tab_module.tab`) combining:
  - Vendors list
  - Vendor agreements list
  - Vendor items list
  - Vendor invoices list (with data-type filter: "Inv. Need To Generate" / "Invoicing Done")
  - Vendor payments list
  - Usage logs list
- All sub-lists are filterable and paginated.

---

## Section 5 — Data Model

### Core Tables

| Table | Model Class | Description |
|---|---|---|
| `vnd_vendors` | `Vendor` | Vendor master: KYC, banking, type |
| `vnd_items` | `VndItem` | Item/service catalogue: HSN/SAC, price, unit |
| `vnd_agreements` | `VndAgreement` | Contract: billing cycle, payment terms, status |
| `vnd_agreement_items_jnt` | `VndAgreementItem` | Line items per agreement: billing model, tax |
| `vnd_usage_logs` | `VndUsageLog` | Actual usage per agreement item per period |
| `vnd_invoices` | `VndInvoice` | Generated invoices: amounts, tax, payment tracking |
| `vnd_payments` | `VndPayment` | Payment records: mode, reconciliation |

### Relationships

```
vnd_vendors 1—N vnd_agreements
vnd_vendors 1—N vnd_invoices (direct vendor_id)
vnd_vendors 1—N vnd_payments (via hasManyThrough through vnd_invoices)

vnd_agreements 1—N vnd_agreement_items_jnt
vnd_agreement_items_jnt N—1 vnd_items
vnd_agreement_items_jnt 1—N vnd_invoices
vnd_agreement_items_jnt 1—N vnd_usage_logs

vnd_invoices 1—N vnd_payments

vnd_agreement_items_jnt.related_entity_id → tpt_vehicle.id (optional)
vnd_agreement_items_jnt.related_entity_id → tpt_personnel.id (optional)
```

### Field Details: vnd_vendors

| Column | Type | Notes |
|---|---|---|
| `vendor_name` | varchar | Required |
| `vendor_type_id` | FK → sys_dropdowns | Categorizes vendor |
| `contact_person` | varchar | Primary contact name |
| `contact_number` | varchar | Phone — see SEC note below |
| `email` | varchar | |
| `address` | text | |
| `gst_number` | varchar | 15-char GSTIN — see SEC note below |
| `pan_number` | varchar | 10-char PAN — see SEC note below |
| `bank_name` | varchar | |
| `bank_account_no` | varchar | See SEC note below |
| `bank_ifsc_code` | varchar | 11-char IFSC |
| `bank_branch` | varchar | |
| `upi_id` | varchar | |
| `is_active` | boolean | Soft active flag |
| `deleted_at` | timestamp | Soft delete |

### Field Details: vnd_agreement_items_jnt

| Column | Type | Notes |
|---|---|---|
| `agreement_id` | FK → vnd_agreements | Parent agreement |
| `item_id` | FK → vnd_items | Item/service reference |
| `billing_model` | enum | FIXED / PER_UNIT / HYBRID |
| `fixed_charge` | decimal(10,2) | Used for FIXED and HYBRID |
| `unit_rate` | decimal(10,2) | Used for PER_UNIT and HYBRID |
| `min_guarantee_qty` | decimal(10,2) | HYBRID: free units before per-unit billing |
| `tax1_percent` | decimal(5,2) | CGST typically |
| `tax2_percent` | decimal(5,2) | SGST typically |
| `tax3_percent` | decimal(5,2) | IGST or cess |
| `tax4_percent` | decimal(5,2) | Additional cess / surcharge |
| `related_entity_type` | FK → sys_dropdowns | Entity type (Vehicle, Personnel, etc.) |
| `related_entity_table` | varchar | Table name for polymorphic ref |
| `related_entity_id` | bigint | PK of related entity |

### Field Details: vnd_invoices

| Column | Type | Notes |
|---|---|---|
| `vendor_id` | FK → vnd_vendors | |
| `agreement_id` | FK → vnd_agreements | |
| `agreement_item_id` | FK → vnd_agreement_items_jnt | |
| `invoice_number` | varchar | Auto-generated: INV-{YmdHis}{rand} |
| `invoice_date` | date | |
| `billing_start_date` | date | Matches agreement.start_date |
| `billing_end_date` | date | Matches agreement.end_date |
| `fixed_charge_amt` | decimal(10,2) | Snapshot at generation time |
| `unit_charge_amt` | decimal(10,2) | Snapshot at generation time |
| `qty_used` | decimal(10,2) | Aggregated from usage logs |
| `unit_rate` | decimal(10,2) | Snapshot at generation time |
| `min_guarantee_qty` | decimal(10,2) | Snapshot at generation time |
| `tax1_percent` through `tax4_percent` | decimal(5,2) | Snapshot at generation time |
| `sub_total` | decimal(10,2) | fixed + unit |
| `tax_total` | decimal(10,2) | sub_total × total_tax_pct / 100 |
| `other_charges` | decimal(10,2) | Miscellaneous additions |
| `discount_amount` | decimal(10,2) | Discount applied |
| `net_payable` | decimal(10,2) | Final amount due |
| `amount_paid` | decimal(10,2) | Running paid total |
| `balance_due` | computed | net_payable - amount_paid |
| `due_date` | date | invoice_date + payment_terms_days |
| `status` | FK → sys_dropdowns | Pending / Partially Paid / Fully Paid |

---

## Section 6 — Controllers Inventory

### Controllers and Route Status

| Controller | Route Registration | Auth | Notes |
|---|---|---|---|
| `VendorController` | Registered in `tenant.php` | Yes (Gates present) | Hub controller — tabbed view + CRUD |
| `VendorAgreementController` | Registered in `tenant.php` | Yes | Agreement CRUD + soft delete |
| `VndItemController` | Registered in `tenant.php` | Yes | Item CRUD + soft delete |
| `VndUsageLogController` | Registered in `tenant.php` | Yes | Usage log CRUD + soft delete |
| `VendorInvoiceController` | Registered in `tenant.php` | **ZERO AUTH** | 14 methods, zero Gate checks |
| `VendorPaymentController` | Registered in `tenant.php` | Unknown — needs audit | Payment CRUD |
| `VendorDashboardController` | **NOT registered** | N/A | Only in module web.php (inaccessible) |

**Critical Finding:** The module's own `routes/web.php` only registers `VendorController` under a simple auth middleware. All the route registrations that make the module functional are in the central `routes/tenant.php`. The module-level `web.php` is effectively a dead file for production.

**VendorDashboardController** is defined but not registered in `tenant.php`. The dashboard is inaccessible via any route unless called indirectly through `VendorController::index()`.

### Gate Authorization Status

| Controller | Gate Coverage |
|---|---|
| `VendorController` | Full Gates on all actions |
| `VendorAgreementController` | Full Gates (via Policy: `VendorAgreementPolicy`) |
| `VndItemController` | Full Gates (via Policy: `VndItemPolicy`) |
| `VndUsageLogController` | Full Gates (via Policy: `VndUsageLogPolicy`) |
| `VendorInvoiceController` | **Zero Gates — critical bug** |
| `VendorPaymentController` | To be audited |
| `VendorDashboardController` | Not reachable — no route |

---

## Section 7 — Services Gap

**Current service class count: 0**

All business logic is in controllers. The invoice generation logic in `VendorInvoiceController::generateInvoice()` is particularly complex (~100 lines of business calculation) and must be extracted into a service class.

**Required service classes:**

| Service Class | Responsibility |
|---|---|
| `VendorService` | Vendor CRUD, GSTIN/PAN validation, document management |
| `VendorAgreementService` | Agreement lifecycle, status transitions, expiry checks |
| `VendorInvoiceService` | Invoice generation calculation engine, duplicate check, PDF generation |
| `VendorPaymentService` | Payment recording, reconciliation, invoice balance update |
| `VendorReportService` | KPI aggregations for dashboard, ageing report, payment report |

---

## Section 8 — Business Rules

### BR-VND-01: GST/PAN Uniqueness
- A vendor's GSTIN should be unique per tenant (one school cannot register the same vendor twice under different names).
- PAN should also be unique per tenant.
- Uniqueness constraint at DB level recommended; validation at FormRequest level required.

### BR-VND-02: Invoice Duplicate Prevention
- The system must prevent generating a second invoice for the same `agreement_item_id` with the same billing period (start_date, end_date).
- Current implementation: `VndInvoice::where('agreement_item_id', ...)->whereDate('billing_start_date', ...)->whereDate('billing_end_date', ...)->exists()`.
- This check is correct but only runs within the controller. It must be enforced in the service layer.

### BR-VND-03: Invoice Generation Prerequisite
- Invoices can only be generated for agreement items belonging to agreements with status = ACTIVE.
- Agreement with status = DRAFT, EXPIRED, or TERMINATED must not allow invoice generation.
- This business rule is not currently enforced in code — must be added.

### BR-VND-04: Payment Cannot Exceed Invoice Net Payable
- A single payment or cumulative payments cannot exceed `net_payable`.
- Current code calculates `balance_due = max(net_payable - amount_paid, 0)` — balance floor is correct.
- However, the system does not currently validate that the payment `amount` doesn't exceed `balance_due`. This validation must be added.

### BR-VND-05: Tax Snapshot on Invoice
- Tax percentages are copied to the invoice at generation time (snapshot).
- Subsequent changes to `tax1_percent...tax4_percent` on the agreement item do not affect already-generated invoices.
- This is the correct accounting behaviour and must be preserved.

### BR-VND-06: Three-Way Matching (Future — When Inventory Module Built)
- When the Inventory module (INV) is built, the following 3-way matching rule applies:
  - Purchase Order (PO) must exist.
  - Goods Receipt Note (GRN) must match PO quantity.
  - Vendor invoice must match PO/GRN.
  - Invoice can only be approved for payment after 3-way match passes.
- Until then, invoices are generated directly from agreement items.

### BR-VND-07: Agreement Auto-Expiry
- A scheduled job or on-access check should auto-set `status = EXPIRED` when `end_date < today` and status is still ACTIVE.
- This prevents invoices from being generated against expired agreements.

### BR-VND-08: Billing Cycle Enforcement
- MONTHLY billing: only one invoice per agreement item per calendar month should be generated.
- ONE_TIME billing: only one invoice per agreement item per agreement lifetime.
- ON_DEMAND: no frequency restriction; generate any time.
- Current duplicate prevention (same billing period start/end) partially enforces this but does not explicitly enforce calendar month uniqueness for MONTHLY agreements.

---

## Section 9 — Workflows

### WF-VND-01: Vendor Onboarding

```
1. Admin navigates to Vendor → Create
2. Fills vendor details (name, type, contact, GST, PAN, bank details)
3. FormRequest validates GSTIN format, PAN format, required fields
4. Vendor record saved (status: active)
5. Optional: upload vendor document via Media Library
6. Activity log entry created
```

### WF-VND-02: Agreement and Invoice Lifecycle

```
1. Finance Manager creates Agreement for vendor
   → Status = DRAFT
   → Uploads agreement PDF document
2. Agreement Items (line items) added
   → Select item from catalogue
   → Set billing model, charges, taxes
   → Optional: link to related entity (vehicle/driver)
3. Agreement activated
   → Status → ACTIVE (manual change or auto on start_date)
4. Usage logging (for PER_UNIT / HYBRID items)
   → Usage Logs entered as services are consumed
5. Invoice Generation
   → Finance Manager selects agreement items to invoice
   → System runs calculation engine
   → Invoice created with status = Pending, due_date set
   → PDF generated and available for download
   → Email dispatched to vendor via queued job
6. Payment Recording
   → Vendor makes payment
   → Finance Manager records payment: amount, mode, reference, reconciled flag
   → Invoice amount_paid updated, balance_due recalculated
   → Status updated: Pending → Partially Paid → Fully Paid
7. Agreement expires
   → Auto-transition to EXPIRED when end_date passes
   → No new invoices can be generated
```

### WF-VND-03: Batch Invoice and PDF Download

```
1. Finance Manager views "Inv. Need To Generate" list (agreement items with no invoice)
2. Selects multiple items via checkbox
3. Clicks "Generate Multiple" → batch invoice generation
4. Success/failed counts displayed
5. Clicks "Download PDF" → pdfMultiple endpoint
6. System generates individual PDFs for each agreement, creates ZIP bundle
7. ZIP file downloaded to browser, temp files cleaned up
```

### WF-VND-04: Payment Reconciliation

```
1. Bank statement received
2. Finance Manager opens payment record
3. Matches payment to bank statement transaction
4. Sets reconciled = true, reconciled_by = current user, reconciled_at = now
5. Reconciled payments visible in reconciled filter on payments list
```

---

## Section 10 — Integration Points

### INT-VND-01: Transport Module (Bidirectional)
- `tpt_vehicle.vendor_id` → `vnd_vendors.id`: Vehicle records reference the vendor supplying/maintaining the vehicle.
- `vnd_agreement_items_jnt.related_entity_id` → `tpt_vehicle.id` or `tpt_personnel.id`: Agreement line items can be tied to specific vehicles or drivers.
- `VehicleController` queries `Vendor::where('vendor_type_id', ...)` to populate vendor dropdown during vehicle creation.
- The `VndAgreement` model directly imports `Modules\Transport\Models\Vehicle` and `Modules\Transport\Models\DriverHelper` for related entity resolution.

### INT-VND-02: Accounting Module (Future — acc_*)
- When the Accounting module is built, vendor payments in `vnd_payments` must post journal entries to `acc_vouchers` (AP payment vouchers).
- Invoice generation should post AP invoice entries (Dr: Expense Ledger, Cr: Vendor Ledger).
- Each vendor in `vnd_vendors` must have a corresponding ledger in `acc_ledgers`.
- This integration is defined in RBS K5 (Vendor Bills) and K5.2 (Vendor Payments).
- **Design consideration:** `vnd_invoices` and `vnd_payments` should add `acc_voucher_id` FK columns when Accounting module is built, to link back to the posted voucher.

### INT-VND-03: Global Dropdowns
- Vendor type, payment mode, item type, item nature, item category, item unit, agreement status are all stored as `sys_dropdowns` entries.
- Invoice status is a dropdown (key: `vnd_invoices.status.status`) with values: Pending, Partially Paid, Fully Paid.

### INT-VND-04: System Media Library
- Vendor documents: `vnd_vendors` → `vendor_documents` collection.
- Agreement documents: `vnd_agreements` → `agreement` collection.
- Item photos: `vnd_items` → `item_photo` collection.
- All stored via `spatie/laravel-medialibrary` in `sys_media` table.

### INT-VND-05: User / Auth
- `vnd_payments.paid_by` → `users.id`: Records who processed the payment.
- `vnd_payments.reconciled_by` → `users.id`: Records who reconciled the payment.
- `sys_activity_logs` records audit trail for all Vendor operations.

---

## Section 11 — Security Issues (Critical)

### SEC-VND-01: VendorInvoiceController — Zero Authorization — CRITICAL
**Severity: Critical**

`VendorInvoiceController` has **no Gate or Policy checks** on any of its 14 methods:
- `index()`, `create()`, `store()` (payment recording), `show()`, `edit()`, `update()`, `destroy()` — basic CRUD
- `toggleStatus()` — changes item/invoice active status
- `generateSingle()` — generates invoice and creates financial record
- `generateMultiple()` — batch invoice generation
- `pdfMultiple()` — generates and downloads ZIP of all agreement PDFs
- `sendMultipleEmails()` — sends emails to vendors
- `storeRemark()` — updates invoice remarks
- `printList()`, `details()` — read operations

**Any authenticated user in the tenant can generate invoices, record payments, trigger batch email sends, and download financial PDFs.** This is a critical financial authorization failure.

**Required Fix:**
1. Change `extends Illuminate\Routing\Controller` to `extends App\Http\Controllers\Controller`.
2. Add Gate checks to every method:
   - `generate*`: `tenant.vendor-invoice.create`
   - `store` (payment): `tenant.vendor-payment.create`
   - `pdfMultiple`, `printList`, `details`: `tenant.vendor-invoice.view`
   - `sendMultipleEmails`: `tenant.vendor-invoice.update`
   - `toggleStatus`: `tenant.vendor-invoice.update`
   - `destroy`: `tenant.vendor-invoice.delete`

### SEC-VND-02: Financial PII Stored Unencrypted — HIGH
**Severity: High**

The `vnd_vendors` table stores financial PII in plaintext:
- `pan_number`: PAN card number is a sensitive tax identifier.
- `bank_account_no`: Bank account number is sensitive financial data.
- `gst_number`: While semi-public (visible on invoices), GSTIN storage in bulk is a data risk.

**Required Fix:** Encrypt `pan_number` and `bank_account_no` using Laravel's `encrypted` cast (AES-256-CBC). These fields are needed for display but must not be stored in plaintext.

### SEC-VND-03: VendorDashboardController Not Accessible
**Severity: Medium**

`VendorDashboardController` is not registered in `tenant.php`. No route exists for it. The `VendorDashboardPolicy` is defined but can never be enforced. This means either:
- The dashboard is silently failing to load (404), or
- Dashboard data is served through `VendorController::index()` instead (confirmed by code inspection).

The orphaned controller and policy should either be integrated into tenant routes or removed.

### SEC-VND-04: Invoice Number Collision Risk
**Severity: Medium**

Invoice numbers are generated as `'INV-' . now()->format('YmdHis') . rand(100,999)`. The `rand()` function provides only 900 possible values per second, creating a collision risk during bulk generation. Replace with a sequential, DB-enforced unique number scheme (e.g., `INV-{year}-{NNNNNN}` with a dedicated sequence or `AUTO_INCREMENT` suffix).

### SEC-VND-05: PDF ZIP Temp File Cleanup
**Severity: Low**

In `pdfMultiple()`, individual temp PDF files are created at `storage_path('app/')` and added to the ZIP. The ZIP file is deleted after the response, but individual temp PDFs are **not** explicitly deleted. This leaks PDF files in the storage directory.

```php
$tempFile = storage_path('app/' . Str::random(10) . '.pdf');
file_put_contents($tempFile, $pdf->output());
$zip->addFile($tempFile, $fileName);
// ← tempFile never deleted
```

**Required Fix:** After `$zip->close()`, iterate through temp files and call `@unlink($tempFile)`.

---

## Section 12 — FormRequests Inventory

| FormRequest | Covers |
|---|---|
| `VendorRequest` | Vendor create/update: name, type, contact, GST/PAN format, bank details |
| `VendorAgreementRequest` | Agreement create/update: vendor, dates, billing cycle, payment terms |
| `VndItemRequest` | Item create/update: code, name, type, HSN/SAC, price |

**Gaps — No FormRequests exist for:**
- `VendorInvoiceController` methods — zero validation at FormRequest level (uses inline `$request->validate()` in some methods, none in others)
- `VendorPaymentController` — payment recording has no FormRequest
- `VndUsageLogController` — usage log entries have no FormRequest

**Required FormRequests to create:**
1. `VendorInvoiceRequest` — generate single/multiple invoice validation
2. `VendorPaymentRequest` — payment amount, mode, date, reference validation
3. `VndUsageLogRequest` — usage log entry validation
4. `VendorAgreementItemRequest` — line item create/update (billing model, charge, tax)

---

## Section 13 — Tests Gap

**Current test count: 0**

The Vendor module has Policies defined (`VendorPolicy`, `VendorAgreementPolicy`, `VendorInvoicePolicy`, `VendorPaymentPolicy`, `VndItemPolicy`, `VndUsageLogPolicy`, `VendorDashboardPolicy`) but no corresponding tests.

**Priority test areas:**
1. Invoice generation calculation: FIXED, PER_UNIT, HYBRID billing models
2. Invoice duplicate prevention (same billing period check)
3. Payment recording and invoice balance update
4. GST/PAN format validation in VendorRequest
5. VendorInvoiceController Gate authorization (regression test after SEC-VND-01 fix)
6. Tax snapshot: changing tax on agreement item after invoice generation must not change invoice
7. Agreement status lifecycle transitions

---

## Section 14 — Gaps and Pending Work

### Critical Bugs to Fix Before Production

1. `VendorInvoiceController` — zero authorization on 14 methods (SEC-VND-01).
2. `pan_number` and `bank_account_no` stored unencrypted (SEC-VND-02).
3. PDF ZIP temp file leak — individual PDFs not deleted after ZIP creation (SEC-VND-05).
4. `VendorDashboardController` not registered in routes (SEC-VND-03).

### Missing Business Rule Enforcement

| Rule | Status |
|---|---|
| Invoice generation blocked for non-ACTIVE agreements | Not implemented |
| Payment amount cannot exceed balance_due | Not validated |
| GSTIN uniqueness per tenant | Not enforced at DB or FormRequest level |
| MONTHLY billing cycle: one invoice per month | Not enforced |
| Agreement auto-expiry on end_date | Not implemented (no scheduled job) |

### Missing Features (vs. RBS)

| RBS Requirement | Status |
|---|---|
| Purchase Order management (K7.1) | Not implemented |
| Three-way matching PO → GRN → Invoice (K5.1.2) | Not implemented (requires Inventory) |
| Vendor rating and performance scorecard (K6.2) | Not implemented |
| Expense claim management (K7.2) | Not implemented |
| Vendor opening balance import (K2.2) | Not implemented |
| Accounting voucher posting from vendor payment (K5.2.2) | Not implemented (requires Accounting) |
| GSTR data export for vendor invoices (K13) | Not implemented (requires Accounting) |

### Architecture Gaps

| Gap | Impact |
|---|---|
| Zero service classes (0 of 5 needed) | Business logic in controllers; untestable |
| Invoice calculation in controller method | Cannot unit test billing model calculation |
| Module web.php is a dead file | Confusing; only tenant.php routes are used |
| `VendorDashboardController` orphaned | Dashboard unreachable by route |
| Policies defined but zero tests | Policies may have logic bugs undetected |

---

## Section 15 — Development Priority

### Phase 1 — Critical Bug Fixes (Sprint 1)
1. Fix `VendorInvoiceController` — add `extends App\Http\Controllers\Controller`, add Gate checks to all 14 methods.
2. Encrypt `pan_number` and `bank_account_no` in `vnd_vendors` (Laravel `encrypted` cast).
3. Fix ZIP temp file leak in `pdfMultiple()` — delete temp PDFs after ZIP close.
4. Register `VendorDashboardController` in `tenant.php` routes.

### Phase 2 — Service Layer (Sprint 2)
5. Create `VendorInvoiceService` — extract billing model calculation engine from controller.
6. Create `VendorPaymentService` — payment recording, balance update, reconciliation.
7. Create `VendorAgreementService` — agreement lifecycle, auto-expiry check.
8. Create `VendorReportService` — KPI aggregations, ageing reports.

### Phase 3 — Missing Business Rules (Sprint 3)
9. Add: invoice generation blocked when agreement status != ACTIVE.
10. Add: payment amount validation against balance_due.
11. Add: GSTIN uniqueness constraint (DB unique index + FormRequest check).
12. Add: MONTHLY billing cycle — one invoice per calendar month enforcement.
13. Add: Artisan command or scheduled job for agreement auto-expiry.
14. Fix invoice number generation — replace `rand()` with sequential scheme.

### Phase 4 — Missing FormRequests and Validation (Sprint 4)
15. Create `VendorInvoiceRequest`, `VendorPaymentRequest`, `VndUsageLogRequest`, `VendorAgreementItemRequest`.
16. Audit all inline `$request->validate()` calls and replace with FormRequests.

### Phase 5 — Testing (Sprint 5)
17. Unit tests for all billing model calculations (FIXED, PER_UNIT, HYBRID with min_guarantee_qty).
18. Feature tests for invoice generation workflow (single + batch).
19. Feature tests for payment recording and invoice status transitions.
20. Feature tests for VendorInvoiceController authorization (after SEC-VND-01 fix).

### Phase 6 — Future Integrations (Post-Core)
21. Accounting module integration: vendor payment → `acc_vouchers` posting.
22. Purchase Order management (RBS K7.1).
23. Three-way matching when Inventory module is built.
24. Vendor rating and performance scorecard (RBS K6.2).

---

*Document generated: 2026-03-25 | Reviewed against: Module code at `/Modules/Vendor`, RBS Module K Sections K5/K6/K7, tenant_db schema*
