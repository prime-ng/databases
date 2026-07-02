# VND — Vendor Management | Complete Analysis Pack
**Version:** 1.0 | **Date:** 2026-06-30 | **Agent:** Business Analyst (Complete Analysis Pack Mode)
**Module Code:** VND | **Table Prefix:** `vnd_*` | **DB Layer:** Tenant (tenant_db)
**FRD Spine:** `VND_FRD_2026-06-30.md` — all REQ-/BR-/RPT-/ENH- IDs are defined there; this document references and extends them

**Sources Read:**
- `AI_Brain/agents/business-analyst.md` (role definition)
- `AI_Brain/config/paths.md` (path resolution)
- `AI_Brain/memory/modules-map.md` (module inventory)
- `AI_Brain/memory/tenancy-map.md` (multi-tenancy architecture)
- `AI_Brain/module-knowledge/VND_Vendor.md` (module knowledge, seeded 2026-06-30)
- `4-Initial_Requirements/V2/VND_Vendor_Requirement.md` (V2 requirement, 2026-03-26)
- `2-Module_Requirement_V1/Vendor_v2/` (9 V1 screen spec files)
- `Modules/Vendor/` code filesystem scan (2026-06-30): 8 controllers, 8 models, 3 FormRequests, 0 services, 1 job, 2 seeders

---

## Table of Contents

1. [FRD Reference Summary](#section-1-frd-reference-summary)
2. [Requirements Traceability Matrix (RTM)](#section-2-requirements-traceability-matrix)
3. [Business Rules Register + Requirement Conditions Catalog + Validation Catalog](#section-3-business-rules-register-conditions-and-validation)
4. [Process Flows + FSM Catalog](#section-4-process-flows-and-fsm-catalog)
5. [Data Dictionary + Cross-Module Dependency Map](#section-5-data-dictionary-and-cross-module-dependency-map)
6. [NFR Catalog + Risk Register](#section-6-nfr-catalog-and-risk-register)
7. [Prioritization (MoSCoW + RICE) + Effort Estimation + Sprint Tasks](#section-7-prioritization-and-effort-estimation)
8. [User Stories + Acceptance Criteria + Reporting KPI Spec](#section-8-user-stories-and-reporting-spec)
9. [Feature Specification (Screen-by-Screen)](#section-9-feature-specification)
10. [Requirements-vs-Code Gap Analysis](#section-10-requirements-vs-code-gap-analysis)
11. [Module Knowledge Update Record](#section-11-module-knowledge-update)

---

## Section 1 — FRD Reference Summary

**FRD file:** `VND_FRD_2026-06-30.md` (sibling of this file)

| Metric | Count |
|--------|-------|
| Functional Requirements (REQ-VND) | 14 |
| Business Rules (BR-VND) | 20 |
| Reports (RPT-VND) | 5 |
| Future Enhancements (ENH-VND) | 8 |
| P0 Requirements | 9 (REQ-VND-001 through 009) |
| P1 Requirements | 4 (REQ-VND-010 through 013) |
| P2 Requirements | 1 (REQ-VND-014) |

**Module Scope:** Tenant. Data isolated per school — no `tenant_id` column; isolation enforced by database-per-tenant architecture (stancl/tenancy v3.9). All queries run in tenant_db context automatically when accessed through tenant middleware.

**Estimated Implementation Completeness (2026-06-30):** ~55–60% of core scope implemented; 0% of P1+ enhancements started.

---

## Section 2 — Requirements Traceability Matrix (RTM)

| REQ-ID | Feature | Priority | BR Refs | Screen(s) | Workflow(s) | Report(s) | Implementation Status | Key Gap |
|--------|---------|----------|---------|-----------|-------------|-----------|----------------------|---------|
| REQ-VND-001 | Vendor Registration | P0 | BR-001, BR-012, BR-019 | Vendor Hub (Vendor tab) · Vendor Create/Edit | WF-VND-01 | RPT-VND-001 | Partial (~75%) | PII unencrypted; index Gate commented out |
| REQ-VND-002 | Item/Service Catalogue | P0 | BR-017, BR-020 | Vendor Hub (Item tab) · Item Create/Edit | — | RPT-VND-001 | Partial (~80%) | Missing `created_by`; `is_deleted` redundancy |
| REQ-VND-003 | Agreement Management | P0 | BR-006, BR-011, BR-007, BR-019 | Vendor Hub (Agreement tab) · Agreement Create/Edit | WF-VND-02, WF-VND-05 | RPT-VND-002 | Partial (~75%) | Auto-expiry not built; DDL trailing-comma syntax error |
| REQ-VND-004 | Agreement Items & Billing Models | P0 | BR-008, BR-020 | Agreement Create/Edit (embedded items panel) | WF-VND-02 | RPT-VND-002 | Partial (~70%) | No FormRequest for agreement items; billing model validation missing |
| REQ-VND-005 | Usage Logging | P0 | BR-013, BR-014, BR-015 | Vendor Hub (Usage Log tab) · Usage Log Create/Edit | WF-VND-02 | RPT-VND-001 | Partial (~65%) | No FormRequest; DDL missing `is_active`/`deleted_at` — soft-delete broken |
| REQ-VND-006 | Invoice Generation | P0 | BR-002, BR-003, BR-005, BR-010, BR-008, BR-015 | Vendor Hub (Invoice tab — "Need to Generate") | WF-VND-02, WF-VND-03 | RPT-VND-003 | Partial (~70%) | ZERO auth on all 14 VendorInvoiceController methods; no service layer; invoice number collision risk |
| REQ-VND-007 | Invoice PDF, ZIP & Email | P0 | — | Vendor Hub (Invoice tab) | WF-VND-03 | — | Partial (~70%) | PDF file leak after ZIP download; email job exists but unconfigured |
| REQ-VND-008 | Payment Recording | P0 | BR-004, BR-009, BR-016 | Vendor Hub (Invoice tab — "Invoicing Done") · Payment modal | WF-VND-02 | RPT-VND-005 | Partial (~55%) | No VendorPaymentRequest; payment > balance not validated; no DB transaction wrapper verified |
| REQ-VND-009 | Payment Reconciliation | P0 | — | Payment Details tab · Payment Edit modal | WF-VND-04 | RPT-VND-005 | Partial (~70%) | VendorPaymentController Gate audit incomplete |
| REQ-VND-010 | Vendor Dashboard | P1 | — | Vendor Hub (Dashboard tab) | — | — | Partial (~50%) | VendorDashboardController not registered in routes; dashboard served via AJAX fallback |
| REQ-VND-011 | Vendor Reports (5-tab) | P1 | — | Separate Report Hub screen | — | RPT-VND-001–005 | Partial (~40%) | VendorReportController exists; route registration unclear; 5 report view partials present |
| REQ-VND-012 | Agreement Auto-Expiry | P1 | BR-007 | (no screen — scheduled background job) | WF-VND-05 | — | Not Started (0%) | No Artisan command, no scheduler entry, no notification dispatch |
| REQ-VND-013 | Document Management | P1 | — | Vendor Create/Edit · Agreement Create/Edit · Item Create/Edit | — | — | Partial (~75%) | Spatie media library integrated; document uploaded flags present |
| REQ-VND-014 | Status & Soft-Delete Lifecycle | P2 | BR-012, BR-016 | All CRUD screens (trash views, status toggles) | — | — | Partial (~70%) | Payment delete does not recalculate invoice; dependency warning on vendor delete missing |

---

## Section 3 — Business Rules Register, Conditions Catalog, and Validation Catalog

### 3.1 Business Rules Register (Standalone)

*(These are the same 20 rules from FRD Section 4; reproduced here as standalone reference for downstream gap analyses.)*

| ID | Rule | Type | Trigger | Enforcement Point | Implementation |
|----|------|------|---------|-----------------|---------------|
| BR-VND-001 | GSTIN must be unique per school; PAN must be unique per school | Validation | Vendor create/update | Vendor registration form | Partial — format validated; no DB-level UNIQUE KEY on GST/PAN |
| BR-VND-002 | No duplicate invoice for same agreement item + billing period | Validation / Workflow | Invoice generation | Invoice generation step | Yes — in code; needs service layer extraction |
| BR-VND-003 | Invoice generation requires Active agreement | Workflow | Invoice generation | Invoice generation step | Not enforced — no agreement status check in current code |
| BR-VND-004 | Payment amount ≤ balance due | Validation | Payment recording | Payment form | Not enforced — no VendorPaymentRequest |
| BR-VND-005 | Invoice snapshots billing parameters at generation | Workflow | Invoice generation | Invoice creation | Yes — implemented |
| BR-VND-006 | Agreement end date > start date | Validation | Agreement create/update | Agreement form | Yes — in VendorAgreementRequest |
| BR-VND-007 | Daily process expires Active agreements past end date | Workflow | Daily schedule | Scheduled command | Not implemented |
| BR-VND-008 | Billing cycle frequency (Monthly = 1/month; One-Time = 1/lifetime) | Workflow | Invoice generation | Invoice generation | Partial — start/end date duplicate check only |
| BR-VND-009 | NEFT/RTGS/UPI payments require reference number; Cheque requires cheque number | Validation | Payment recording | Payment form | Not enforced |
| BR-VND-010 | Invoice number unique per vendor; auto-generated sequential | Validation / Workflow | Invoice generation | Invoice creation | Partial — UNIQUE KEY in DDL; generation uses rand() — collision risk |
| BR-VND-011 | Agreement cannot activate without at least one active item | Validation | Agreement status change | Agreement edit | Not enforced |
| BR-VND-012 | Delete vendor with active dependencies triggers warning | Validation | Vendor delete | Vendor delete action | Not enforced |
| BR-VND-013 | Usage quantity > 0 | Validation | Usage log create/update | Usage log form | Not enforced — no VndUsageLogRequest |
| BR-VND-014 | Usage date within agreement period and not in future | Validation | Usage log create/update | Usage log form | Not enforced |
| BR-VND-015 | Default qty = 1 if no usage logs | Calculation | Invoice generation | Calculation engine | Yes — implemented |
| BR-VND-016 | Deleting payment requires invoice balance recalculation | Workflow | Payment delete | Payment delete action | Not enforced |
| BR-VND-017 | Item deactivation blocked if linked to active agreement (warning) | Validation | Item status toggle | Item toggle action | Not enforced |
| BR-VND-018 | Data isolated per school | Permission | Every data access | Database-per-tenant architecture | Yes — architectural enforcement |
| BR-VND-019 | Only active vendors in agreement creation dropdowns | Workflow | Agreement create | Agreement form | Partial — active scope likely applied |
| BR-VND-020 | Only active items in agreement item selection | Workflow | Agreement item add | Agreement item form | Not verified |

### 3.2 Requirement Conditions Catalog

*(See also: `5-Requirement_Conditions/VND_Conditions.md` — this section is the canonical source, the file in that folder points here.)*

| Condition ID | Entity / Field | Condition (business statement) | Type | Trigger | On-Violation Behaviour |
|-------------|---------------|-------------------------------|------|---------|----------------------|
| BR-VND-001-A | Vendor / GSTIN | GSTIN must match 15-character Indian GSTIN pattern | Validation | Vendor save | Form error: "GSTIN format is invalid. Example: 27ABCDE1234F1Z5" |
| BR-VND-001-B | Vendor / GSTIN | GSTIN must be unique within this school | Validation | Vendor save | Form error: "This GSTIN is already registered for another vendor" |
| BR-VND-001-C | Vendor / PAN | PAN must match 10-character Indian PAN pattern | Validation | Vendor save | Form error: "PAN format is invalid. Example: ABCDE1234F" |
| BR-VND-001-D | Vendor / PAN | PAN must be unique within this school | Validation | Vendor save | Form error: "This PAN is already registered for another vendor" |
| BR-VND-002 | Invoice / Agreement Item + Billing Period | No invoice with same agreement item ID, billing start date, and billing end date may exist | Validation | Invoice generation | Generation blocked: "An invoice for this item and billing period already exists" |
| BR-VND-003 | Invoice / Agreement Status | Agreement linked to the item must be in Active status | Workflow | Invoice generation | Generation blocked: "Cannot generate invoice — agreement is not Active" |
| BR-VND-004 | Payment / Amount | Payment amount must not exceed balance due on the invoice | Validation | Payment recording | Form error: "Payment amount cannot exceed the remaining balance due of ₹{balance}" |
| BR-VND-006-A | Agreement / End Date | End date must be after start date | Validation | Agreement save | Form error: "End date must be after start date" |
| BR-VND-007 | Agreement / End Date + Status | Active agreement with end date before today transitions to Expired | Workflow | Daily scheduled process | Status updated to Expired; Finance Manager notified |
| BR-VND-008-A | Invoice / Billing Cycle = Monthly | Only one invoice per agreement item per calendar month | Workflow | Invoice generation | Generation blocked: "A monthly invoice for this item already exists for {Month Year}" |
| BR-VND-008-B | Invoice / Billing Cycle = One-Time | Only one invoice per agreement item for the agreement's lifetime | Workflow | Invoice generation | Generation blocked: "A one-time invoice for this item already exists" |
| BR-VND-009-A | Payment / Payment Mode | NEFT, RTGS, and UPI payments require a reference number | Validation | Payment save | Form error: "Reference number is required for NEFT/RTGS/UPI payments" |
| BR-VND-009-B | Payment / Payment Mode | Cheque payments require a cheque number | Validation | Payment save | Form error: "Cheque number is required for Cheque payments" |
| BR-VND-011 | Agreement / Status Transition | Agreement must have at least one active item to transition from Draft to Active | Validation | Agreement status change | Error: "Add at least one active agreement item before activating this agreement" |
| BR-VND-012 | Vendor / Delete | Vendor with active agreements or pending invoices triggers warning before delete | Validation | Vendor delete | Warning dialog: "This vendor has active agreements. Deleting will not remove the agreements. Continue?" |
| BR-VND-013 | Usage Log / Quantity | Quantity used must be greater than zero | Validation | Usage log save | Form error: "Quantity must be greater than zero" |
| BR-VND-014-A | Usage Log / Date | Usage date must not be in the future | Validation | Usage log save | Form error: "Usage date cannot be in the future" |
| BR-VND-014-B | Usage Log / Date | Usage date should fall within the agreement's start and end dates | Validation | Usage log save | Warning (or error): "Usage date is outside the agreement period ({start} to {end})" |
| BR-VND-016 | Payment / Delete | Deleting a payment must trigger recalculation of linked invoice's paid total and status | Workflow | Payment delete confirmation | System recalculates invoice balance and updates status; audit log entry written |
| BR-VND-017 | Item / Deactivation | Item linked to active agreement displays warning before status is toggled to Inactive | Validation | Item status toggle | Warning dialog: "This item is used in {n} active agreements. Deactivating it will affect future agreement item selection." |

### 3.3 Validation and Edge-Case Catalog

| Field / Rule | Valid Example | Invalid Example | Boundary | Empty/Null | Concurrency Case | Expected Behaviour |
|-------------|--------------|----------------|----------|------------|-----------------|-------------------|
| GSTIN | `27ABCDE1234F1Z5` | `12345` (too short) | Exactly 15 chars | Nullable — field is optional | Two Finance Managers register same GSTIN simultaneously | DB unique constraint or application-level lock prevents second save |
| PAN | `ABCDE1234F` | `abcde1234f` (lowercase) | Exactly 10 chars | Nullable — field is optional | Duplicate PAN entered by two users at once | First save wins; second receives uniqueness error |
| Agreement End Date | 2026-03-31 (after start 2026-04-01 is invalid; 2026-04-30 is valid) | 2026-03-31 when start is 2026-04-01 | Same day as start date → invalid | Required field | — | Validation rejects; form returned with date error |
| Payment Amount | ₹10,000 when balance due is ₹15,000 | ₹20,000 when balance due is ₹15,000 | Equal to balance due → valid (full payment) | Required; must be > 0 | Two Finance Managers record payment simultaneously against same invoice | DB transaction + invoice lock prevents double-payment exceeding balance |
| Usage Quantity | 50 (for water jars) | -5 or 0 | 0.01 (minimum valid) | Required; must be > 0 | Two staff log usage for same item at same time | No concurrency issue — logs are additive, not mutually exclusive |
| Invoice Generation (batch) | 3 items all valid | 2 valid + 1 with no active agreement | Mixed batch | If item list is empty, endpoint returns error | Concurrent batch + single generation for same item | Second request after first creates invoice gets duplicate-prevention error |
| FIXED billing amount | Fixed charge = ₹25,000; sub-total = ₹25,000 | Fixed charge = 0 (zero-value invoice) | Fixed charge = ₹0.01 → generates ₹0.01 invoice | Fixed charge is required; defaults to 0.00 | — | Zero-value invoice is technically valid but should warn |
| HYBRID billing — qty below guarantee | Fixed = ₹10,000; unit rate = ₹50; guarantee = 100; qty = 80 | — | qty = exactly 100 → zero variable charge | — | — | Variable charge = max(80-100,0) × 50 = 0; sub-total = ₹10,000 |
| Invoice number (sequential) | `INV-2026-000001` | Two invoices with same number for same vendor | Sequence overflow (>999,999 per year) | Auto-generated; not user-entered | Concurrent invoice generation | Sequential generator with atomic DB increment prevents collision |

---

## Section 4 — Process Flows and FSM Catalog

### 4.1 Process Flows

*(The five core workflows are fully specified in FRD Section 6 — Workflows 1 through 5. The FSM catalog below supplements with state machine detail.)*

### 4.2 FSM Catalog

#### FSM-VND-01: Agreement Status

**Entity:** Vendor Agreement | **States backed by:** `vnd_agreements.status` ENUM

| From State | Event / Action | Guard (Condition) | To State | Side-Effects |
|-----------|---------------|------------------|----------|-------------|
| — (new) | Admin creates agreement | Any authorised user | Draft | Agreement record created; audit log entry |
| Draft | Admin activates agreement | At least one active agreement item exists (BR-VND-011) | Active | Agreement becomes billable; no notification |
| Draft | Admin deletes agreement | No invoices linked | (soft-deleted) | Soft delete; removed from active list |
| Active | Daily scheduled process runs | Agreement end date < today | Expired | Status updated; Finance Manager notified; no new invoices can be generated |
| Active | Admin manually terminates | — | Terminated | Status updated; audit log; no new invoices |
| Active | Admin soft-deletes | Warning shown; no pending invoices | (soft-deleted) | Soft delete with warning |
| Expired | Admin creates new agreement | — | Draft (new agreement) | New agreement created (renew pattern); original remains Expired |
| Terminated | — | Cannot re-activate | (terminal) | — |

**Terminal States:** Terminated | **Illegal Transitions (must be blocked):** Expired → Active (without creating a new agreement), Terminated → Active, Draft → Expired (only system can do this via auto-expiry, not manual)

---

#### FSM-VND-02: Invoice Status

**Entity:** Vendor Invoice | **States backed by:** `vnd_invoices.status` FK → `sys_dropdown_table` (Pending / Partially Paid / Fully Paid; Overdue in future)

| From State | Event / Action | Guard (Condition) | To State | Side-Effects |
|-----------|---------------|------------------|----------|-------------|
| — (none) | Finance generates invoice | Agreement Active; item Active; no duplicate for period | Pending | Invoice record created with net payable; due date set; audit log |
| Pending | Finance records partial payment | Payment amount < balance due | Partially Paid | `amount_paid` updated; `balance_due` recalculated (GENERATED STORED column auto-updates) |
| Pending | Finance records full payment | Payment amount = balance due | Fully Paid | Same as above |
| Partially Paid | Finance records further payment(s) | Cumulative paid < net payable | Partially Paid | Running paid total updated |
| Partially Paid | Finance records final payment | Cumulative paid reaches net payable | Fully Paid | Invoice closed |
| Pending / Partially Paid | Finance deletes a payment | — | Recalculated (may revert) | `amount_paid` reduced; status recomputed; audit log |
| Pending | [Future] Due date passes | balance_due > 0 AND due_date < today | Overdue | ENH-VND future release |
| Any | Finance toggles invoice inactive | — | (inactive, same status) | Billing paused on that item |

**Terminal States:** Fully Paid (cannot be re-opened without manual override) | **Illegal Transitions:** Fully Paid → Pending (without payment deletion)

---

#### FSM-VND-03: Payment Status

**Entity:** Vendor Payment | **States backed by:** `vnd_payments.status` ENUM (INITIATED / SUCCESS / FAILED)

| From State | Event / Action | Guard | To State | Side-Effects |
|-----------|---------------|-------|----------|-------------|
| — (new) | Finance records payment | Valid payment data; amount ≤ balance due | INITIATED | Payment recorded; invoice balance updated |
| INITIATED | Finance confirms cleared in bank | — | SUCCESS | Marked SUCCESS; available for reconciliation |
| INITIATED | Payment rejected/failed | — | FAILED | Marked FAILED; must be re-initiated |
| SUCCESS | Finance marks reconciled | — | SUCCESS (reconciled=Yes) | Reconciled timestamp + user recorded |
| Any | Finance deletes payment | — | (deleted) | Soft-deleted; linked invoice balance recalculated |

---

## Section 5 — Data Dictionary and Cross-Module Dependency Map

### 5.1 Data Dictionary (Business View)

#### Entity: Vendor

| Business Field | Meaning | Type | Required | Allowed Values | PII? |
|---------------|---------|------|----------|---------------|------|
| Vendor Name | Legal or trading name of the supplier | Text (100 chars) | Yes | Unique per school | Internal |
| Vendor Type | Category of supplier (e.g., Transport, Canteen, Security) | Dropdown (from master list) | Yes | Configured per school | Internal |
| Contact Person | Name of the person to contact at the vendor organisation | Text (100 chars) | Yes | — | Internal |
| Contact Number | Phone number for the contact person | Text (30 chars) | Yes | — | Internal |
| Email | Vendor's business email address; used for invoice delivery | Text (100 chars) | No | Standard email format | Internal |
| Address | Vendor's registered business address | Text (512 chars) | No | — | Internal |
| GSTIN | Goods and Services Tax Identification Number | Text (50 chars) | No | 15-char GSTIN pattern; unique per school | Confidential |
| PAN Number | Permanent Account Number | Text (50 chars) | No | 10-char PAN pattern; unique per school | Sensitive (PII) |
| Bank Name | Name of the vendor's bank | Text (100 chars) | No | — | Internal |
| Bank Account Number | Vendor's bank account number | Text (50 chars) | No | — | Sensitive (PII) |
| Bank IFSC Code | 11-character bank branch identifier | Text (20 chars) | No | Standard IFSC format | Internal |
| Bank Branch | Name of the bank branch | Text (100 chars) | No | — | Internal |
| UPI ID | Vendor's UPI payment identifier | Text (100 chars) | No | — | Confidential |
| Status | Whether the vendor is currently active or suspended | Toggle | No | Active / Inactive (default: Active) | — |
| Document Uploaded | Flag indicating a KYC document has been attached | Boolean | No | Yes / No (default: No) | — |

#### Entity: Vendor Item (Catalogue)

| Business Field | Meaning | Type | Required | Allowed Values | PII? |
|---------------|---------|------|----------|---------------|------|
| Item Code | Short unique code for this item | Text (50 chars) | No | Unique per school | Internal |
| Item Name | Full descriptive name | Text (100 chars) | Yes | — | Internal |
| Item Type | Whether the item is a tangible product or a service | Dropdown | Yes | Service / Product | Internal |
| Item Nature | How the item is tracked for procurement purposes | Dropdown | Yes | Consumable / Asset / Service / Not Applicable | Internal |
| Category | Broader procurement classification | Dropdown | Yes | From master dropdown list | Internal |
| Unit of Measurement | How the quantity is measured | Dropdown | Yes | From master dropdown list (e.g., Per Month, Per Trip, Per Unit) | Internal |
| HSN / SAC Code | Government tax classification code | Text (20 chars) | No | HSN for products; SAC for services | Internal |
| Default Price | Suggested unit rate for the item | Currency | Yes | ≥ 0 (default 0) | Internal |
| Reorder Level | Minimum stock quantity before a procurement alert | Decimal | No | ≥ 0; applicable to product items | Internal |
| Description | Additional notes about the item | Long text | No | — | Internal |
| Status | Whether the item is currently available for selection | Toggle | No | Active / Inactive | — |

#### Entity: Vendor Agreement

| Business Field | Meaning | Type | Required | Allowed Values | PII? |
|---------------|---------|------|----------|---------------|------|
| Agreement Reference Number | Unique identifier for this contract | Text (50 chars) | No | Unique per school | Internal |
| Vendor | The vendor this agreement belongs to | Dropdown (active vendors) | Yes | — | Internal |
| Start Date | The date the contract begins | Date | Yes | Must be before end date | Internal |
| End Date | The date the contract expires | Date | Yes | Must be after start date | Internal |
| Agreement Status | Current lifecycle state of the agreement | Controlled status | No | Draft / Active / Expired / Terminated | Internal |
| Billing Cycle | How frequently invoices are raised under this agreement | Dropdown | Yes | Monthly / One-Time / On-Demand | Internal |
| Payment Terms (Days) | Number of days from invoice date within which payment must be made | Number | No | Integer ≥ 0 (default 30) | Internal |
| Remarks | Internal notes about the agreement | Long text | No | — | Internal |
| Agreement Document Uploaded | Flag indicating signed agreement PDF is attached | Boolean | No | Yes / No | — |

#### Entity: Agreement Item (Line Item)

| Business Field | Meaning | Type | Required | Allowed Values | PII? |
|---------------|---------|------|----------|---------------|------|
| Item | The catalogue item being contracted | Dropdown (active items) | Yes | — | Internal |
| Billing Model | How the charge is calculated | Dropdown | Yes | Fixed / Per Unit / Hybrid | Internal |
| Fixed Charge | Flat rate per billing cycle | Currency | For Fixed and Hybrid | ≥ 0 | Internal |
| Unit Rate | Price per unit consumed | Currency | For Per Unit and Hybrid | ≥ 0 | Internal |
| Minimum Guarantee Quantity | In Hybrid billing, the quantity included in the fixed charge | Decimal | For Hybrid | ≥ 0 | Internal |
| Tax 1 through Tax 4 Percentage | GST tax rates (CGST, SGST, IGST, Cess) | Decimal percentage | No | 0–100 each | Internal |
| Related Asset Type | The type of school asset this item applies to | Dropdown | No | Vehicle / Personnel / School Asset / etc. | Internal |
| Related Asset | The specific school asset linked to this line item | ID reference | No | PK of the linked entity | Internal |
| Description | Additional notes for this line item | Text (255 chars) | No | — | Internal |

#### Entity: Usage Log

| Business Field | Meaning | Type | Required | Allowed Values | PII? |
|---------------|---------|------|----------|---------------|------|
| Vendor | The vendor whose consumption is being recorded | Dropdown (active vendors) | Yes | — | Internal |
| Agreement Item | The specific item being consumed | Dropdown (active items for selected vendor) | Yes | — | Internal |
| Usage Date | The date the service was consumed or product was received | Date | Yes | Not in future; within agreement period | Internal |
| Quantity Used | The number of units consumed on this date | Decimal | Yes | > 0 | Internal |
| Remarks | Notes about this consumption entry | Text (255 chars) | No | — | Internal |
| Logged By | The user who entered this record (auto-captured) | System-generated | — | — | Internal |

#### Entity: Invoice

| Business Field | Meaning | Type | Required | Allowed Values | PII? |
|---------------|---------|------|----------|---------------|------|
| Invoice Number | Unique auto-generated reference | Text (50 chars) | Auto | Sequential: INV-{YYYY}-{NNNNNN} | Internal |
| Vendor | The vendor being billed | Reference | Auto | — | Internal |
| Agreement | The agreement under which this invoice is raised | Reference | Auto | — | Internal |
| Item Description | Snapshot of the item name at generation | Text (255 chars) | Auto | — | Internal |
| Invoice Date | Date the invoice was generated | Date | Auto | Today's date | Internal |
| Billing Start Date | Start of the period this invoice covers | Date | Auto | From agreement | Internal |
| Billing End Date | End of the period this invoice covers | Date | Auto | From agreement | Internal |
| Quantity Used | Total usage for the billing period (from logs; default 1) | Decimal | Auto | ≥ 1 | Internal |
| Fixed Charge Amount | Snapshot of fixed charge at generation | Currency | Auto | — | Confidential |
| Variable Charge Amount | Calculated variable portion | Currency | Auto | ≥ 0 | Confidential |
| Sub-Total | Fixed + Variable amount | Currency | Auto | — | Confidential |
| Tax Total | Sub-total × combined tax rate / 100 | Currency | Auto | — | Confidential |
| Other Charges | Additional charges entered at generation | Currency | Optional | ≥ 0 | Confidential |
| Discount Amount | Discount entered at generation | Currency | Optional | ≥ 0 | Confidential |
| Net Payable | Final amount due: sub-total + tax + other charges - discount | Currency | Auto | — | Confidential |
| Amount Paid | Running total of all payments received against this invoice | Currency | Auto | ≥ 0 | Confidential |
| Balance Due | Remaining amount: Net Payable − Amount Paid (computed automatically) | Currency | Auto (computed) | ≥ 0 | Confidential |
| Due Date | Invoice date + payment terms days | Date | Auto | — | Internal |
| Invoice Status | Current payment state | Status | Auto | Pending / Partially Paid / Fully Paid | Internal |
| Remarks | Notes on the invoice | Text (512 chars) | No | — | Internal |

#### Entity: Payment

| Business Field | Meaning | Type | Required | Allowed Values | PII? |
|---------------|---------|------|----------|---------------|------|
| Payment Date | Date the school made or recorded the payment | Date | Yes | — | Internal |
| Vendor | The vendor being paid (auto from invoice) | Reference | Auto | — | Internal |
| Invoice | The invoice this payment is applied to | Dropdown | Yes | Only Pending or Partially Paid invoices | Internal |
| Amount | Amount paid in this transaction | Currency | Yes | > 0; ≤ balance due | Confidential |
| Payment Mode | Method used to make the payment | Dropdown | Yes | Cash / Cheque / NEFT / RTGS / UPI / Bank Transfer | Internal |
| Reference Number | Transaction ID, UTR, or cheque number | Text (100 chars) | Conditional | Required for NEFT / RTGS / UPI / Cheque modes | Internal |
| Payment Status | Current state of the payment transaction | Status | Yes | INITIATED / SUCCESS / FAILED | Internal |
| Reconciled | Whether this payment has been matched to the bank statement | Toggle | No | Yes / No (default: No) | Internal |
| Paid By | The logged-in user who recorded this payment (auto-captured) | System-generated | — | — | Internal |
| Remarks | Notes about this payment | Long text | No | — | Internal |

---

### 5.2 Cross-Module Dependency Map

#### Inbound Dependencies (Vendor module reads from)

| Source Module | Data / Entity Used | Why |
|--------------|-------------------|-----|
| System Configuration | Dropdown master lists (vendor type, item category, unit, payment mode, related entity type) | Populates all category/classification dropdowns throughout the module |
| System Configuration | Activity log service | Records all create/update/delete actions for audit trail |
| System Configuration | User master | Captures `logged_by`, `paid_by`, `reconciled_by`, `created_by` user references |
| Transport | Vehicle master (`tpt_vehicle`) | Agreement items link to specific vehicles for transport contracts |
| Transport | Personnel master (`tpt_personnel`) | Agreement items link to drivers and helpers for personnel contracts |
| School Setup | Asset master (`sch_asset`) | [inferred] Agreement items may link to school assets for maintenance contracts |

#### Outbound Dependencies (Vendor module feeds / is consumed by)

| Target Module | Data / Mechanism | What is Provided |
|--------------|-----------------|-----------------|
| Accounting (ACC) | Future — when ACC is built: `vnd_invoices.acc_voucher_id` and `vnd_payments.acc_voucher_id` FK columns receive written-back voucher IDs | AP invoice journal vouchers (Dr: Expense Ledger, Cr: Vendor Ledger) and payment journal vouchers (Dr: Vendor Ledger, Cr: Bank Ledger) |
| Inventory (INV) | Future — `vnd_items.item_nature` (Consumable/Asset) and `vnd_items.reorder_level` fields serve as integration hooks | Vendor invoices for consumable products should decrement INV stock; `reorder_level` drives low-stock alerts |
| Transport | `vnd_vendors` table — Transport module queries vendors filtered by vendor type to populate vehicle assignment dropdowns | Transport vendors available for vehicle and route cost tracking |
| Notification | Background notification dispatch when agreement auto-expiry runs (Workflow 5) | Sends agreement expiry alert to Finance Manager |

#### Integration Events (Outbound)

| Event | Trigger | Consumer | Payload |
|-------|---------|---------|--------|
| VendorAgreementExpired (future design) | Daily auto-expiry process transitions agreement to Expired | Notification module → Finance Manager | Agreement ref, vendor name, expiry date |
| VendorInvoiceEmailDispatched | Finance triggers "Email to Vendor" | Background job queue (`SendVendorInvoiceEmailJob`) | Invoice IDs, vendor email, sender email |

---

## Section 6 — NFR Catalog and Risk Register

### 6.1 NFR Catalog

| NFR-ID | Category | Requirement (measurable) | Acceptance Threshold |
|--------|----------|------------------------|---------------------|
| NFR-VND-001 | Performance | Vendor hub initial page render | < 3 seconds on standard school hardware; tabs load on-demand via AJAX |
| NFR-VND-002 | Performance | Single invoice generation | < 5 seconds with up to 500 usage log entries |
| NFR-VND-003 | Performance | Batch invoice generation (50 items) | < 30 seconds; partial failure does not block remaining |
| NFR-VND-004 | Performance | ZIP PDF download (20 invoices) | < 60 seconds |
| NFR-VND-005 | Performance | Dashboard metrics page load | < 5 seconds; live database query |
| NFR-VND-006 | Security | All 14 VendorInvoiceController endpoints must have permission checks | Zero unauthenticated access to any invoice endpoint; verified by automated test |
| NFR-VND-007 | Security | Module accessible only to licensed schools | `EnsureTenantHasModule` middleware applied to every vendor route group |
| NFR-VND-008 | Security | PAN and bank account number at rest | AES-256 encryption via Laravel encrypted cast; decrypted only at display |
| NFR-VND-009 | Security | GSTIN and UPI ID at rest | AES-256 encryption via Laravel encrypted cast |
| NFR-VND-010 | Security | Invoice generation rate limiting | Maximum 10 invoice generation requests per user per minute |
| NFR-VND-011 | Security | Email dispatch rate limiting | Maximum 5 batch email requests per user per minute |
| NFR-VND-012 | Security | Audit trail completeness | All financial operations (invoice generate, payment record, payment delete) logged with user, timestamp, record reference |
| NFR-VND-013 | Security | Payment database transaction | Payment recording (payment insert + invoice balance update) wrapped in single DB transaction; no partial update on DB error |
| NFR-VND-014 | Usability | Invoice hub default view | First-load shows items that need invoicing (not empty table) |
| NFR-VND-015 | Usability | Billing model preview | Invoice generation modal shows calculated breakdown before Finance Manager confirms |
| NFR-VND-016 | Usability | Dashboard expiry colour coding | Agreements expiring within 7 days shown in red; 8–30 days in orange |
| NFR-VND-017 | Usability | Vendor / agreement dropdowns | Searchable type-to-filter (not plain selects) for all key reference dropdowns |
| NFR-VND-018 | Scalability | Vendor records per school | Must support up to 200 vendor records per school without performance degradation |
| NFR-VND-019 | Scalability | Usage log records | Must support up to 10,000 usage log entries per agreement item per year |
| NFR-VND-020 | Compliance | GST compliance | GSTIN and PAN stored; HSN/SAC codes captured on all items; tax breakdown on invoices matches GST rules (CGST+SGST for intra-state; IGST for inter-state) |

### 6.2 Risk Register

| RISK-ID | Risk | Category | Likelihood | Impact | Mitigation | Owner | Early Warning |
|---------|------|----------|:----------:|:------:|------------|-------|--------------|
| RISK-VND-001 | VendorInvoiceController zero auth — any authenticated user generates invoices, downloads all vendor PDF data, emails vendors | Security | H | H | Immediate fix: change base class; add Gate checks to all 14 methods; add feature test for each endpoint | Developer | Test coverage = 0; code review |
| RISK-VND-002 | PAN and bank account numbers stored in plaintext — financial PII exposed in DB breach | Security | M | H | Add Laravel encrypted cast to Vendor model `$casts`; add `pan_hash` deterministic hash column for uniqueness checking | Developer | Next DB audit or penetration test |
| RISK-VND-003 | EnsureTenantHasModule not applied — unlicensed schools access vendor module | Security | H | M | Add `EnsureTenantHasModule:Vendor` to vendor route group middleware | Developer | Routine route audit |
| RISK-VND-004 | `vnd_usage_logs` has no `deleted_at` column — soft-delete is fully broken; every `$log->delete()` call throws SQL error in production | Data Integrity | H | H | Migration: add `is_active`, `deleted_at`, `created_by` to `vnd_usage_logs`; fix FK name | Developer | Any usage log delete action in production |
| RISK-VND-005 | Invoice number collision — `rand(100,999)` produces only 900 values/second; duplicate invoice numbers at high billing volume | Data Integrity | M | H | Replace with sequential `INV-{YYYY}-{NNNNNN}` using atomic DB sequence or auto-increment helper | Developer | High-volume invoice generation month |
| RISK-VND-006 | `balance_due` is GENERATED STORED — if it appears in `$fillable`, any Eloquent fill will throw DB error | Data Integrity | M | H | Verify `VndInvoice::$fillable` does not include `balance_due`; add test | Developer | Any invoice payment recording |
| RISK-VND-007 | No service layer — billing model calculation logic in controller is untestable; refactoring risk when breaking changes are needed | Architecture | H | M | Extract `VendorInvoiceService`, `VendorAgreementService`, `VendorPaymentService` as P0 architecture task | Tech Lead | Any new billing model requirement |
| RISK-VND-008 | PDF ZIP temp file leak — individual PDFs not deleted after ZIP creation; storage fills over time | Performance / Storage | M | M | Add explicit `unlink()` for each temp PDF after `$zip->close()` | Developer | Storage disk usage trending up |
| RISK-VND-009 | Zero test coverage — no automated verification of billing model calculations, auth, or invoice lifecycle | Quality | H | H | Create VendorInvoiceAuthTest, BillingModelCalculationTest, InvoiceNumberUniquenessTest as P0 | Developer / Tester | Any production billing error |
| RISK-VND-010 | `VndAgreement` model hard-imports `Modules\Transport\Models\Vehicle` — if Transport module is disabled, Vendor module throws class-not-found error | Architecture | M | H | Replace direct model import with generic polymorphic resolver: `DB::table($table)->find($id)` | Developer | Transport module disable test |

---

## Section 7 — Prioritization and Effort Estimation

### 7.1 MoSCoW Prioritization

#### Must Have (Production Blockers — no ship without these)

| Item | Rationale |
|------|-----------|
| REQ-VND-006 Invoice Generation + security fix (RISK-VND-001) | Core financial function; currently has zero auth — any user can generate invoices |
| REQ-VND-001 Vendor PII encryption (RISK-VND-002) | Financial PII (PAN, bank account) in plaintext violates data protection obligation |
| Module access control (RISK-VND-003) | Unlicensed school access is a billing/compliance risk |
| REQ-VND-005 Usage log DDL fix (RISK-VND-004) | Usage log soft-delete is broken — production error on any delete |
| Service layer extraction (RISK-VND-007) | Required for test coverage and maintainability |
| REQ-VND-008 VendorPaymentRequest | No validation on payment amount — overpayment is currently allowed |
| Test coverage (RISK-VND-009) | Financial module requires automated verification of calculations |

#### Should Have (Required before broader rollout)

| Item | Rationale |
|------|-----------|
| REQ-VND-012 Agreement auto-expiry scheduled job | Without this, expired agreements remain Active and new invoices can be generated |
| REQ-VND-010 Dashboard route registration | VendorDashboardController is dead code; dashboard is a key Finance Manager tool |
| REQ-VND-011 Reports route verification | VendorReportController route registration status unclear — verify and fix |
| BR-VND-003 Active agreement check on invoice generation | Invoices can currently be generated against expired/terminated agreements |
| BR-VND-009 Conditional reference number validation | Traceability for NEFT/RTGS/UPI payments |
| Invoice number sequential scheme (RISK-VND-005) | Collision risk at scale |
| REQ-VND-007 PDF temp file cleanup (RISK-VND-008) | Server storage leak |

#### Could Have (Quality and compliance improvements)

| Item | Rationale |
|------|-----------|
| BR-VND-011 Agreement activation item check | UX guardrail |
| BR-VND-012 Vendor delete dependency warning | Data integrity protection |
| BR-VND-017 Item deactivation warning | Avoids breaking active agreements |
| Dashboard lazy-tab AJAX loading (NFR-VND-001) | Performance improvement; current page load fires 6 queries simultaneously |
| REQ-VND-014 Payment delete balance recalculation (BR-VND-016) | Data consistency on payment deletion |

#### Won't Have (This Release — future enhancements)

ENH-VND-001 through ENH-VND-008 (PO, GRN, three-way match, invoice approval, TDS, performance scorecard, vendor portal, ACC integration) — deferred to future releases as defined in FRD Section 8.

---

### 7.2 RICE Prioritization (Top Items)

| Item | Reach | Impact | Confidence | Effort (h) | RICE Score | Priority |
|------|-------|--------|:----------:|:----------:|:----------:|:--------:|
| VendorInvoiceController auth fix | All schools | 10 (security) | 9 | 8 | 112 | P0-1 |
| VendorPaymentRequest creation | All schools | 8 | 9 | 4 | 162 | P0-2 |
| EnsureTenantHasModule on routes | All schools | 9 | 10 | 2 | 405 | P0-3 |
| Usage log DDL migration | All schools | 9 | 10 | 3 | 270 | P0-4 |
| Service layer extraction | All schools | 8 | 8 | 20 | 25 | P0-5 |
| PII encryption | All schools | 9 | 8 | 8 | 81 | P1-1 |
| Agreement auto-expiry job | All schools | 7 | 9 | 6 | 94 | P1-2 |
| Sequential invoice numbering | All schools | 6 | 9 | 4 | 121 | P1-3 |

---

### 7.3 Effort Estimation and Sprint Task Breakdown

| # | Task | Type | Effort (h) | REQ / BR Ref | Depends On | Sprint |
|---|------|------|:----------:|-------------|-----------|-------|
| 1 | Fix `VendorInvoiceController` — change base class + add Gate::authorize to all 14 methods | Backend | 6 | REQ-VND-006, NFR-VND-006 | — | S1 |
| 2 | Add `EnsureTenantHasModule:Vendor` to all vendor route groups | Backend | 2 | NFR-VND-007 | — | S1 |
| 3 | Migration: add `is_active`, `deleted_at`, `created_by` to `vnd_usage_logs`; fix FK name | Schema | 3 | REQ-VND-005 | — | S1 |
| 4 | Migration: add `is_active` to `vnd_payments` | Schema | 1 | REQ-VND-008 | — | S1 |
| 5 | Create `VendorPaymentRequest` — validate amount ≤ balance_due; conditional reference number | Backend | 4 | REQ-VND-008, BR-VND-004, BR-VND-009 | — | S1 |
| 6 | Create `VndUsageLogRequest` — qty > 0; date not future; item active | Backend | 3 | REQ-VND-005, BR-VND-013, BR-VND-014 | Task 3 | S1 |
| 7 | Create `VendorAgreementItemRequest` — billing model, required fields per model | Backend | 4 | REQ-VND-004 | — | S1 |
| 8 | Extract `VendorInvoiceService` — calculate(), generateSingle(), generateMultiple(), generateNumber(), generatePdf(), zipPdfs() | Backend | 16 | REQ-VND-006, REQ-VND-007, RISK-VND-007 | Task 1 | S1–S2 |
| 9 | Fix PDF ZIP temp file leak — delete individual PDFs after `$zip->close()` | Backend | 2 | REQ-VND-007, RISK-VND-008 | Task 8 | S2 |
| 10 | Add encrypted cast to Vendor model for PAN, bank_account_no, gst_number, upi_id | Backend | 4 | NFR-VND-008, NFR-VND-009 | — | S2 |
| 11 | Add `pan_hash` (SHA-256) column to `vnd_vendors` for uniqueness checking on encrypted PAN | Schema + Backend | 4 | BR-VND-001 | Task 10 | S2 |
| 12 | Uncomment `Gate::authorize('tenant.vendor.viewAny')` in VendorController::index() | Backend | 1 | REQ-VND-001 | Task 1 | S2 |
| 13 | Register VendorDashboardController routes in tenant.php | Backend | 2 | REQ-VND-010 | — | S2 |
| 14 | Extract `VendorAgreementService` — activate(), terminate(), expireAll(), status transition validation | Backend | 8 | REQ-VND-003, BR-VND-007, BR-VND-011 | — | S2 |
| 15 | Create daily Artisan command `vendor:expire-agreements` + scheduler entry in Kernel.php | Backend + Config | 4 | REQ-VND-012, BR-VND-007 | Task 14 | S3 |
| 16 | Dispatch notification to Finance Manager on agreement auto-expiry | Backend | 3 | REQ-VND-012 | Task 15 | S3 |
| 17 | Extract `VendorPaymentService` — record(), updateInvoiceBalance(), reconcile() | Backend | 8 | REQ-VND-008, REQ-VND-009, BR-VND-016 | Task 5 | S3 |
| 18 | Replace invoice number scheme: remove `rand()`; implement `INV-{YYYY}-{NNNNNN}` sequential | Backend | 4 | BR-VND-010, RISK-VND-005 | Task 8 | S3 |
| 19 | Add BR-VND-003 active agreement check to invoice generation | Backend | 2 | BR-VND-003 | Task 8 | S3 |
| 20 | Add billing cycle frequency enforcement (Monthly / One-Time) to invoice generation | Backend | 4 | BR-VND-008 | Task 8 | S3 |
| 21 | Implement payment delete recalculation on VendorPaymentService::delete() | Backend | 3 | BR-VND-016 | Task 17 | S3 |
| 22 | Verify VendorReportController route registration; fix if dead code | Backend | 2 | REQ-VND-011 | — | S3 |
| 23 | Replace hard Transport model import in VndAgreement with generic polymorphic resolver | Backend | 3 | RISK-VND-010 | — | S3 |
| 24 | Remove `is_deleted` column from 5 tables (migration + model `$fillable` cleanup) | Schema + Backend | 4 | Multiple DDL issues | Tasks 3, 4 | S4 |
| 25 | Add `created_by` to `vnd_vendors`, `vnd_items`, `vnd_usage_logs` (migration + model) | Schema + Backend | 3 | DDL-VND-02/03 | — | S4 |
| 26 | Write BillingModelCalculationTest (FIXED, PER_UNIT, HYBRID — 8 unit test cases) | Testing | 6 | REQ-VND-006 | Task 8 | S4 |
| 27 | Write VendorInvoiceAuthTest (all 14 endpoints — auth required, permission enforced) | Testing | 8 | REQ-VND-006, NFR-VND-006 | Tasks 1, 8 | S4 |
| 28 | Write PaymentValidationTest (amount ≤ balance_due; mode+reference; reconciliation) | Testing | 4 | REQ-VND-008, REQ-VND-009 | Tasks 5, 17 | S4 |
| 29 | Write AgreementLifecycleTest (auto-expiry, activation guard, invoice block on expired) | Testing | 4 | REQ-VND-003, REQ-VND-012 | Tasks 14, 15 | S4 |
| 30 | Implement lazy AJAX tab loading for Vendor Hub (load each tab on first click) | Frontend | 8 | NFR-VND-001 | — | S5 |
| 31 | Add billing model calculation preview to invoice generation modal | Frontend | 4 | NFR-VND-015 | Task 8 | S5 |
| 32 | Dashboard expiry colour coding (7-day red / 30-day orange) | Frontend | 2 | NFR-VND-016 | Task 13 | S5 |

**Total Estimated Effort:**
| Sprint | Tasks | Hours |
|--------|-------|-------|
| S1 (P0 Security + DDL) | 1–7 | 23h |
| S2 (Service Layer + PII + Dashboard) | 8–13 | 29h |
| S3 (Business Rules + Scheduled Job) | 14–23 | 41h |
| S4 (Cleanup + Test Coverage) | 24–29 | 29h |
| S5 (Frontend Performance) | 30–32 | 14h |
| **Total** | **32 tasks** | **136h** |

*Assumptions: DDL migrations can run against existing schema without data migration; PII encryption requires no backfill of existing records (or an explicit migration script if records exist); Notification module is available for agreement expiry alerts.*

---

## Section 8 — User Stories and Reporting Spec

### 8.1 User Stories with Acceptance Criteria (P0 and P1 Requirements)

---

#### US-VND-001 | P0 | REQ-VND-001
**As a Finance Manager, I want to register a new vendor with tax and banking details so that I can create agreements and process payments for that supplier.**

Scenario: Successful vendor registration
Given I am logged in as Finance Manager and navigate to Add Vendor
When I fill in the vendor name, type, contact person, GSTIN (27ABCDE1234F1Z5), PAN (ABCDE1234F), bank details, and click Save
Then the vendor is saved with Active status and appears at the top of the vendor list

Scenario: GSTIN format rejected
Given I am on the Add Vendor form
When I enter a GSTIN with fewer than 15 characters and click Save
Then I receive a field-level error "GSTIN format is invalid" and the vendor is not saved

Scenario: Duplicate GSTIN rejected
Given vendor "ABC Supplies" exists with GSTIN 27ABCDE1234F1Z5
When I try to create another vendor with the same GSTIN
Then I receive an error "This GSTIN is already registered for another vendor"

Scenario: Permission denied
Given I am logged in as General Staff
When I navigate to Add Vendor
Then I receive an access-denied response (403)

Definition of Done: Vendor saved; audit log entry created; vendor visible in agreement creation dropdown; PII fields encrypted at rest.

---

#### US-VND-002 | P0 | REQ-VND-003
**As a Finance Manager, I want to create and activate an agreement for a vendor so that I can start generating invoices for services provided.**

Scenario: Agreement created in Draft
Given a vendor "Sharma Transport" exists and I am logged in as Finance Manager
When I create an agreement with reference AGR-2026-T-001, dates 2026-04-01 to 2027-03-31, Monthly billing, 30-day payment terms
Then the agreement is saved in Draft status with the uploaded agreement flag set to No

Scenario: Activation blocked without items
Given the above Draft agreement exists with no items added
When I try to change status from Draft to Active
Then I receive an error "At least one active agreement item is required"

Scenario: Successful activation
Given the agreement has two active items
When I change status to Active
Then the agreement status becomes Active and items are available for invoice generation

Scenario: End date before start date
Given I enter start date 2026-12-01 and end date 2026-06-01
Then I receive an error "End date must be after start date"

---

#### US-VND-003 | P0 | REQ-VND-006
**As a Finance Manager, I want to generate invoices for vendor agreement items so that the school can track and pay its vendor liabilities.**

Scenario: Single invoice generation — Fixed billing
Given an Active agreement item with Fixed billing model, fixed charge ₹25,000, CGST 9%, SGST 9%, payment terms 30 days
When I click Generate Invoice for that item with invoice date 2026-05-01
Then the invoice is created with sub-total ₹25,000, tax ₹4,500, net payable ₹29,500, due date 2026-05-31, status Pending

Scenario: Invoice blocked for expired agreement
Given an agreement in Expired status
When I click Generate Invoice for one of its items
Then I receive an error "Cannot generate invoice — agreement is not Active"

Scenario: Duplicate invoice blocked
Given an invoice already exists for item ID 5 with billing period 2026-05-01 to 2026-05-31
When I try to generate another invoice for item ID 5 with the same billing period
Then I receive an error "An invoice for this item and billing period already exists"

Scenario: Batch generation — partial success
Given 4 items: 2 valid, 1 with expired agreement, 1 duplicate
When I batch-generate for all 4
Then 2 invoices are created; 2 failures are reported; the 2 successes are not rolled back

Scenario: Permission denied
Given I am logged in as General Staff
When I call the generate invoice endpoint
Then I receive a 403 response

---

#### US-VND-004 | P0 | REQ-VND-008
**As an Accountant, I want to record payments against vendor invoices so that the invoice balance and status stay accurate.**

Scenario: Partial payment
Given invoice INV-2026-000001 with net payable ₹29,500 and no payments yet (status: Pending)
When I record a payment of ₹15,000 on 2026-05-10 via NEFT (ref: UTR123456)
Then the invoice status changes to Partially Paid, amount paid = ₹15,000, balance due = ₹14,500

Scenario: Full payment
Given the same invoice with amount paid ₹15,000 and balance due ₹14,500
When I record a payment of ₹14,500
Then the invoice status changes to Fully Paid, balance due = ₹0

Scenario: Payment exceeds balance
Given balance due = ₹14,500
When I try to record ₹20,000
Then I receive a validation error "Payment amount cannot exceed the remaining balance due of ₹14,500"

Scenario: NEFT without reference number
Given I select NEFT as payment mode and leave reference number blank
Then I receive a validation error "Reference number is required for NEFT/RTGS/UPI payments"

---

#### US-VND-005 | P0 | REQ-VND-005
**As a Purchase Manager, I want to log the actual quantity of services consumed so that the invoice calculation is accurate for Per Unit and Hybrid billing.**

Scenario: Usage logged successfully
Given vendor "AquaPure" has an active Per Unit agreement item for 20L Water Jars at ₹35/jar
When I log 50 jars received on 2026-05-08 with remark "Mid-week delivery"
Then the usage log is saved and the cumulative total for that item is 50

Scenario: Quantity zero rejected
When I try to log 0 jars
Then I receive a validation error "Quantity must be greater than zero"

Scenario: Future date rejected
When I try to log usage with date 2026-06-30 (one week from today being 2026-06-23)
Then I receive an error "Usage date cannot be in the future"

Scenario: Default quantity on invoice generation
Given no usage logs exist for a Per Unit item
When Finance generates an invoice
Then the invoice quantity shows 1 and the amount = 1 × unit rate × (1 + tax%)

---

#### US-VND-006 | P1 | REQ-VND-010
**As a Finance Manager, I want to see the Vendor Dashboard when I open the module so that I know the current payment health at a glance.**

Scenario: Dashboard loads with current data
Given it is 2026-05-25, 18 active vendors, 12 active agreements, 2 expiring within 30 days
When I open the Vendor module
Then I see the Dashboard tab active showing: Total Vendors: 18, Active Agreements: 12, Expiring Soon: 2, and the expiry alert list with those two agreements

Scenario: Outstanding metric reflects last payment
Given outstanding balance was ₹1,35,000 before a ₹25,000 payment was recorded 2 minutes ago
When I refresh the dashboard
Then outstanding shows ₹1,10,000

Scenario: User without invoice permission
Given I am logged in as Purchase Manager
When I open the Dashboard
Then I see vendor and agreement KPI cards but not the invoice-amount metric cards

---

#### US-VND-007 | P1 | REQ-VND-012
**As a Finance Manager, I want agreements to expire automatically when their end date passes so that I never accidentally generate invoices against a closed contract.**

Scenario: Auto-expiry runs successfully
Given agreement AGR-2026-T-001 has status Active and end date 2026-05-29 (yesterday)
When the scheduled daily process runs
Then AGR-2026-T-001 status changes to Expired and I receive a notification listing it

Scenario: Active agreement unaffected
Given agreement AGR-2026-T-002 has end date 2026-06-30 (tomorrow)
When the daily process runs
Then AGR-2026-T-002 remains Active

Scenario: Expired agreement blocks invoice
Given AGR-2026-T-001 is now Expired
When Finance tries to generate an invoice for its items
Then generation is blocked: "Cannot generate invoice — agreement is not Active"

---

### 8.2 Reporting KPI Specification

#### KPI Catalog (Vendor Module)

| KPI | Definition / Formula | Source Data | Target | Cadence |
|-----|---------------------|------------|--------|--------|
| Payment Collection Rate | Total amount paid ÷ total net payable × 100 (for selected period) | `vnd_payments`, `vnd_invoices` | > 85% by month-end | Monthly |
| Average Days Overdue | Mean of (current date − due date) for all invoices with balance_due > 0 and due_date < today | `vnd_invoices` | < 15 days | Monthly |
| Agreement Renewal Rate | Active agreements renewed within 30 days of expiry ÷ total expired agreements | `vnd_agreements` | > 90% | Quarterly |
| Outstanding Liability | Sum of `balance_due` for all active, non-fully-paid invoices | `vnd_invoices` | < 10% of monthly budget | Monthly |
| Top Outstanding Vendor | Vendor with highest sum of `balance_due` | `vnd_invoices` grouped by `vendor_id` | — | On-demand |
| Reconciliation Rate | Reconciled payments ÷ total SUCCESS payments × 100 | `vnd_payments` | > 95% | Monthly |

---

## Section 9 — Feature Specification (Screen-by-Screen)

### Screen 1: Vendor Hub (Multi-Tab)
**Route:** `/vendor/vendor` | **Route Name:** `vendor.vendor.index` | **Layout:** Tabbed (7 tabs)

**Tabs:** Dashboard · Vendor · Vendor Item · Vendor Agreement · Vendor Invoice · Payment Details · Usage Log

**Access:** Finance Manager, Accountant, Purchase Manager (read-only for staff); tab-level permission control

**Empty State:** Each tab shows a styled empty state message when no data is found; invoice tab defaults to "Need to Generate" view and prompts the user to select a vendor and date range

---

### Screen 2: Vendor Create / Edit
**Route:** `/vendor/vendor/create` (create) · `/vendor/vendor/{id}/edit` (edit)

| # | Field | Type | Required | Validation | Notes |
|---|-------|------|:--------:|-----------|-------|
| 1 | Vendor Name | Text | Yes | Unique per school; max 100 chars | — |
| 2 | Vendor Type | Dropdown | Yes | From sys_dropdowns (vendor type key) | Transport type shows vendor to Transport module |
| 3 | Contact Person | Text | Yes | Max 100 chars | — |
| 4 | Contact Number | Text | Yes | Max 30 chars | — |
| 5 | Email | Text | No | Email format | Used for invoice email delivery |
| 6 | Address | Textarea | No | Max 512 chars | — |
| 7 | GSTIN | Text | No | 15-char GSTIN pattern; unique per school | Stored encrypted (V2 fix) |
| 8 | PAN Number | Text | No | 10-char PAN pattern; unique per school | Stored encrypted (V2 fix) |
| 9 | Bank Name | Text | No | Max 100 chars | — |
| 10 | Bank Account Number | Text | No | — | Stored encrypted (V2 fix) |
| 11 | Bank IFSC Code | Text | No | 11 chars | — |
| 12 | Bank Branch | Text | No | Max 100 chars | — |
| 13 | UPI ID | Text | No | Max 100 chars | Stored encrypted (V2 fix) |
| 14 | Vendor Document | File upload | No | PDF/image | Stored via media library; updates "document uploaded" flag |

**Actions:** Save · Cancel | **Permissions:** Create/Edit Vendor

---

### Screen 3: Vendor List (within Vendor tab)
**Columns:** Vendor Name · Type · Contact Person · Contact Number · GSTIN · Status · Document Uploaded · Actions

**Filters:** Vendor Type (dropdown) · Status (Active / Inactive / All) · Search by name

**Actions per row:** View · Edit · Toggle Status · Soft Delete · Restore (Trash view only) · Permanent Delete (Trash view only)

**Permissions:** View: all roles; Edit/Delete: Finance Manager, School Admin

---

### Screen 4: Vendor Item Create / Edit
**Route:** `/vendor/vendor-item/create` · `/vendor/vendor-item/{id}/edit`

| # | Field | Type | Required | Validation |
|---|-------|------|:--------:|-----------|
| 1 | Item Code | Text | No | Unique per school; max 50 chars |
| 2 | Item Name | Text | Yes | Max 100 chars |
| 3 | Item Type | Dropdown | Yes | Service / Product |
| 4 | Item Nature | Dropdown | Yes | Consumable / Asset / Service / Not Applicable |
| 5 | Category | Dropdown | Yes | From sys_dropdowns (item category key) |
| 6 | Unit | Dropdown | Yes | From sys_dropdowns (unit key) |
| 7 | HSN / SAC Code | Text | No | Max 20 chars |
| 8 | Default Price | Currency | Yes | ≥ 0; default 0.00 |
| 9 | Reorder Level | Decimal | No | ≥ 0; applicable for Product type |
| 10 | Description | Textarea | No | — |
| 11 | Item Photo | File upload | No | Image; via media library |

---

### Screen 5: Vendor Agreement Create / Edit (with embedded Agreement Items)
**Route:** `/vendor/vendor-agreement/create` · `/vendor/vendor-agreement/{id}/edit`

**Agreement Header Fields:**

| # | Field | Type | Required | Validation |
|---|-------|------|:--------:|-----------|
| 1 | Agreement Reference No | Text | No | Unique per school; max 50 chars |
| 2 | Vendor | Dropdown | Yes | Active vendors only |
| 3 | Start Date | Date | Yes | Before end date |
| 4 | End Date | Date | Yes | After start date |
| 5 | Status | Dropdown | Yes | Draft (default) / Active / Terminated; Expired set by system |
| 6 | Billing Cycle | Dropdown | Yes | Monthly / One-Time / On-Demand |
| 7 | Payment Terms (Days) | Number | No | Integer ≥ 0; default 30 |
| 8 | Remarks | Textarea | No | — |
| 9 | Agreement Document | File upload | No | PDF; updates "agreement uploaded" flag |

**Agreement Item Sub-form (repeating, one per item):**

| # | Field | Type | Required | Validation |
|---|-------|------|:--------:|-----------|
| 1 | Item | Dropdown | Yes | Active catalogue items |
| 2 | Billing Model | Dropdown | Yes | Fixed / Per Unit / Hybrid |
| 3 | Fixed Charge | Currency | If Fixed or Hybrid | ≥ 0 |
| 4 | Unit Rate | Currency | If Per Unit or Hybrid | ≥ 0 |
| 5 | Min Guarantee Qty | Decimal | If Hybrid | ≥ 0 |
| 6 | Tax 1–4 % | Decimal (×4) | No | 0–100 each |
| 7 | Related Asset Type | Dropdown | No | From sys_dropdowns |
| 8 | Related Asset | Reference | No | PK of linked entity (vehicle/person/asset) |
| 9 | Description | Text | No | Max 255 chars |

---

### Screen 6: Vendor Invoice Hub (Invoice Tab — Two Views)

**View A: "Inv. Need To Generate" (pending items)**
Filters: Data Type = "Inv. Need To Generate" · Vendor · Date Range (billing period)
Columns: Vendor Name · Agreement Ref · Item Name · Billing Model · Fixed Charge · Unit Rate · Min Guarantee Qty · Status · Action
Actions per row: Generate Invoice (single) · View Agreement Details
Bulk actions: Generate Multiple Invoices (with optional Other Charges + Discount modal)

**View B: "Invoicing Done" (generated invoices)**
Filters: Data Type = "Invoicing Done" · Vendor · Date Range (invoice date)
Columns: Vendor Name · Agreement Ref · Item Name · Invoice Number · Invoice Date · Qty Used · Net Payable · Amount Paid · Balance Due · Status · Action
Actions per row: Add Payment · View Invoice Details · Add Remark · Download PDF · Email to Vendor
Bulk actions: Generate Bulk PDF (ZIP download) · Bulk Email

**Generate Invoice Modal fields:** Billing Start Date · Billing End Date · Other Charges (optional) · Discount Amount (optional) · Calculated preview (sub-total, tax, net payable)

---

### Screen 7: Payment Details Tab

Filters: Vendor · Date Range · Payment Status (INITIATED / SUCCESS / FAILED) · Reconciled (Yes / No / All)
Columns: Payment Date · Vendor Name · Invoice Number · Amount · Payment Mode · Reference No · Status · Reconciled · Paid By · Actions
Actions per row: Edit · Delete

**Edit Payment Modal fields:** Payment Date · Amount (read-only if invoice is Fully Paid) · Payment Mode · Reference No · Status · Reconciled toggle · Remarks

**Empty State:** "No payments found. Payments are recorded from the Vendor Invoice tab."

---

### Screen 8: Usage Log Tab

Filters: Vendor · Date Range
Columns: Vendor Name · Agreement Item · Usage Date · Quantity Used · Remarks · Logged By · Actions
Actions per row: Edit · Delete

**Add Usage Log form:** Vendor (dropdown) · Agreement Item (cascading dropdown filtered by vendor) · Usage Date · Quantity Used · Remarks

---

### Screen 9: Vendor Dashboard Tab

**Layout:** Summary cards (row 1) + Expiring Agreements alert table + Recent Invoices list + Recent Payments list + Top Outstanding Vendors bar chart

**Summary Cards:**
- Total Active Vendors (count)
- Total Active Agreements (count)
- Expiring Within 30 Days (count; orange/red if > 0)
- Total Invoiced This Month (₹ amount)
- Total Paid This Month (₹ amount)
- Outstanding Balance (₹ amount)
- Payment Completion Rate (%)

---

### Screen 10: Vendor Reports Hub

**Layout:** 5-tab report hub (Vendor Ledger Summary active by default)
**Master Filter Panel (shared across all tabs):** Date Range · Vendor · Agreement (cascading) · Item (cascading)
**Per-tab content:** Summary metric cards + 2–3 visual charts + paginated data grid with export button (PDF/Excel/CSV)
*(See FRD Section 7 for full per-report specification.)*

---

## Section 10 — Requirements-vs-Code Gap Analysis (BA-Scope)

*(This is the BA-level requirement-coverage gap analysis. For deep code/security/performance defect hunting, hand off to Technical Auditor.)*

| REQ-ID | Feature | Code Status | Evidence | Gap |
|--------|---------|:-----------:|---------|-----|
| REQ-VND-001 | Vendor Registration | PARTIAL | VendorController (443 lines), VendorRequest exists, 7 policies registered. VendorPolicy.viewAny Gate commented out in VendorController::index(). | Index Gate disabled; PII fields unencrypted; no UNIQUE key on GST/PAN at DB level; `is_deleted` redundancy |
| REQ-VND-002 | Item Catalogue | PARTIAL | VndItemController, VndItemRequest exist. CRUD working. | `is_deleted` redundancy; missing `created_by`; no check on active agreement before deactivation |
| REQ-VND-003 | Agreement Management | PARTIAL | VendorAgreementController, VendorAgreementRequest exist. Basic CRUD working. | No agreement item count check before activation (BR-VND-011); DDL trailing-comma syntax error; `is_deleted` redundancy; no auto-expiry |
| REQ-VND-004 | Agreement Items with Billing Models | PARTIAL | VndAgreementItem model exists. Items stored via agreement controller. | No FormRequest for agreement items; billing model validation missing; hard Transport model import |
| REQ-VND-005 | Usage Logging | PARTIAL | VndUsageLogController, VndUsageLog model exist. | No FormRequest; DDL missing `is_active` and `deleted_at` — soft-delete call throws SQL error; no date/quantity validation |
| REQ-VND-006 | Invoice Generation | PARTIAL (CRITICAL) | VendorInvoiceController exists with generateSingle(), generateMultiple(). Calculation engine present. | ZERO authorization on ALL 14 methods; no service layer; invoice number uses rand(); no active-agreement check (BR-VND-003); no billing cycle frequency check (BR-VND-008); no FormRequest |
| REQ-VND-007 | PDF, ZIP, Email | PARTIAL | pdfMultiple(), sendMultipleEmails(), SendVendorInvoiceEmailJob all present. DomPDF used. | PDF temp file leak (no unlink after zip close); job retry config not verified |
| REQ-VND-008 | Payment Recording | PARTIAL | VendorPaymentController exists. Basic payment storage working. | No VendorPaymentRequest; payment amount not validated against balance_due; no transaction wrapper verified; payment delete does not recalculate invoice |
| REQ-VND-009 | Payment Reconciliation | PARTIAL | Reconciled fields exist on vnd_payments. Edit payment likely present. | VendorPaymentController Gate audit unconfirmed |
| REQ-VND-010 | Vendor Dashboard | PARTIAL | VendorDashboardController exists. Dashboard views present. | Controller NOT registered in tenant.php routes — dead code; dashboard served via VendorController AJAX fallback |
| REQ-VND-011 | Vendor Reports | PARTIAL | VendorReportController exists. 5 report view partials found. | Route registration status unclear; may be dead code |
| REQ-VND-012 | Agreement Auto-Expiry | NOT STARTED | No Artisan command found. No scheduler entry. No notification dispatch. | Entire feature missing |
| REQ-VND-013 | Document Management | PARTIAL | Spatie media library integrated. Document upload flags present on models. | Minor: no download permission check explicitly confirmed |
| REQ-VND-014 | Soft-Delete Lifecycle | PARTIAL | Most controllers have trash/restore/forceDelete routes. | Payment controller missing trash/restore; payment delete does not recalculate invoice (BR-VND-016) |

**Gap Summary:**
- NOT STARTED: 1 feature (REQ-VND-012 Agreement Auto-Expiry)
- CRITICAL PARTIAL: 1 feature (REQ-VND-006 Invoice Generation — zero auth on all endpoints)
- PARTIAL: 12 features (various gaps from minimal to significant)
- DONE: 0 features fully complete

**P0 Blockers Before Production:**
1. VendorInvoiceController — zero auth on 14 endpoints (SEC-VND-01)
2. PAN and bank account plaintext storage (SEC-VND-02)
3. EnsureTenantHasModule missing (GAP-VND-03)
4. Service layer entirely absent (ARCH-VND-04)
5. VendorDashboardController not registered (GAP-VND-05)
6. Usage log DDL missing soft-delete columns — every delete throws SQL error (BUG-VND-06)

---

## Section 11 — Module Knowledge Update Record

Module knowledge file updated: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/module-knowledge/VND_Vendor.md`

**Session additions:**
- Complete Analysis Pack produced (2026-06-30)
- FRD: 14 REQ, 20 BR, 5 RPT, 8 ENH documented
- RTM: 14 rows mapping each REQ to screen, workflow, report, and code status
- Sprint plan: 32 tasks across 5 sprints, 136h total estimated
- Feature Specification: 10 screens documented with field tables
- User stories: 7 user stories with full Gherkin acceptance criteria
- Risk Register: 10 risks identified (6 High impact)
- Gap Analysis: All 14 REQs assessed against code; 6 P0 blockers confirmed

**Next Steps (for downstream agents):**
1. Technical Auditor — deep code audit of VendorInvoiceController (14 zero-auth endpoints), service layer design
2. DB Architect — DDL v2 with fixes: remove `is_deleted`, add `created_by`, fix FK names, add UNIQUE KEY on GST/PAN, add `pan_hash`, add usage_date index
3. Backend Developer — Sprint 1 tasks (Tasks 1–7 above) starting with SEC-VND-01 fix
4. Testing Architect — BillingModelCalculationTest and VendorInvoiceAuthTest as P0 test deliverables

---

*Complete Analysis Pack saved: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/0-FRD_Documents/VND_FRD_Complete_2026-06-30.md`*
*FRD saved: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/0-FRD_Documents/VND_FRD_2026-06-30.md`*
*Requirement Conditions Catalog: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/5-Requirement_Conditions/VND_Conditions.md`*
*Module Knowledge: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/module-knowledge/VND_Vendor.md`*
