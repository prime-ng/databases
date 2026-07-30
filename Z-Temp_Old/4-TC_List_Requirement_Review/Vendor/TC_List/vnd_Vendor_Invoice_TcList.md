# vnd_Vendor_Invoice_TcList

## Module: Vendor → Vendor Invoice Management → Invoice CRUD + Billing Engine

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Vendor (VND) — Invoice Management |
| Tab Group | Vendor Dashboard (Invoices Tab) |
| Features | Invoice List, Create/View/Edit, Invoice Generation (Single/Multiple), Billing Engine (FIXED/PER_UNIT/HYBRID), Tax Calculation, Payment Reconciliation, Toggle Invoice Status, Remark Management, PDF Generation (Single/ZIP), Print List, Invoice Details API, Email Scheduling, Misnamed store() for Payment Creation |
| URL(s) | `/vendor-invoice`, `/vendor-invoice/create`, `/vendor-invoice/{vendor-invoice}/edit`, `/vendor-invoice/{vendor-invoice}`, `/vendor-invoice/trash/view`, `/vendor-invoice/{id}/toggle-status`, `/vendor-invoice/generate`, `/vendor-invoice/generate-multiple`, `/invoice/remark`, `/vendor-invoice/pdf-multiple`, `/vendor/invoice/print`, `/vendor/invoice/details`, `/invoice/email/multiple` |
| Controller | `Modules\Vendor\Http\Controllers\VendorInvoiceController` (605 lines) |
| Model(s) | `VndInvoice`, `VndAgreementItem`, `VndAgreement`, `Vendor`, `VndPayment`, `VndUsageLog` |
| Validation | **No FormRequest** — all methods use plain `Illuminate\Http\Request`; only inline `$request->validate()` in some methods |
| Permission Gates | `tenant.vendor-invoice.viewAny`, `tenant.vendor-invoice.view`, `tenant.vendor-invoice.create`, `tenant.vendor-invoice.update`, `tenant.vendor-invoice.delete`, `tenant.vendor-invoice.status`, `tenant.vendor-invoice.remark`, `tenant.vendor-invoice.pdf`, `tenant.vendor-invoice.print`, `tenant.vendor-invoice.email-schedule` (10+ gates) |
| Soft Deletes | Yes — VndInvoice model uses `SoftDeletes` trait (no trashed/restore/forceDelete methods in controller) |
| Events | No activityLog() calls found in any controller method |

---

## 2. Pre-conditions

- Required permissions: `tenant.vendor-invoice.viewAny`, `tenant.vendor-invoice.create`, `tenant.vendor-invoice.update`, `tenant.vendor-invoice.view`, `tenant.vendor-invoice.delete`, `tenant.vendor-invoice.status`, `tenant.vendor-invoice.remark`, `tenant.vendor-invoice.pdf`, `tenant.vendor-invoice.print`, `tenant.vendor-invoice.email-schedule`
- At least one active Vendor must exist in `vnd_vendors` (FK: `vendor_id` RESTRICT)
- At least one active Agreement must exist in `vnd_agreements` (FK: `agreement_id` SET NULL)
- At least one active Agreement Item must exist in `vnd_agreement_items_jnt` (FK: `agreement_item_id` SET NULL)
- For invoice generation tests: VndAgreementItem must have billing_model, rates set, and VndUsageLog records for qty calculation
- For pending status tests: `sys_dropdown_table` must have an entry for `vnd_invoices.status` with value `Pending`
- For PDF/print tests: at least one invoice record generated
- For email tests: mail queue/driver configured
- For toggle-status tests: at least one active and one inactive invoice record
- For duplicate prevention tests: at least one invoice exists with unique agreement_item_id + billing_start_date + billing_end_date combination
- For payment creation tests (store()): at least one invoice exists for payment recording
- trashed/restore/forceDelete routes exist but controller methods are missing (Known Issue)

---

## 3. Default Data Load

### 3.1 Index View Data

The `index()` method returns:
- Returns `invoice.index` view (no complex query logic in controller — view handled by frontend/tab)

### 3.2 Create View Data

The `create()` method returns:
- Returns `invoice.create` view (no additional data loaded in controller)

### 3.3 Filter/Search Behaviour

- `index()` — No search/filter params processed in controller; returns view only
- `printList(Request)` — Queries `VndAgreementItem::with(['agreement.vendor', 'item', 'invoices'])` with optional `agreement_ids` filter, renders print view
- `details(Request)` — Returns JSON HTML for invoice or agreement item detail based on `type` param (`invoice_detail` vs `agreement_item_detail`)

---

## 4. BC-DB — Database Schema

### 4.1 `vnd_invoices` — Primary Invoice Table

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| vendor_id | INT UNSIGNED | NOT NULL | — | FK → vnd_vendors(id) RESTRICT |
| agreement_id | INT UNSIGNED | YES | NULL | FK → vnd_agreements(id) SET NULL |
| agreement_item_id | INT UNSIGNED | YES | NULL | FK → vnd_agreement_items_jnt(id) SET NULL |
| item_description | VARCHAR(255) | YES | NULL | Line-item description |
| invoice_number | VARCHAR(50) | NOT NULL | — | Unique invoice ref ('INV-' . YmdHis . rand(100,999)) |
| invoice_date | DATE | NOT NULL | — | Invoice issuance date |
| billing_start_date | DATE | YES | NULL | Billing period start |
| billing_end_date | DATE | YES | NULL | Billing period end |
| fixed_charge_amt | DECIMAL(12,2) | YES | 0.00 | Fixed charge (from agreement item) |
| unit_charge_amt | DECIMAL(12,2) | YES | 0.00 | Per-unit charge (from agreement item) |
| qty_used | DECIMAL(10,2) | YES | 0.00 | Actual quantity used |
| unit_rate | DECIMAL(10,2) | YES | 0.00 | Per-unit rate (from agreement item) |
| min_guarantee_qty | DECIMAL(10,2) | YES | 0.00 | Minimum guarantee (from agreement item) |
| tax1_percent | DECIMAL(5,2) | YES | 0.00 | Tax 1 percentage |
| tax2_percent | DECIMAL(5,2) | YES | 0.00 | Tax 2 percentage |
| tax3_percent | DECIMAL(5,2) | YES | 0.00 | Tax 3 percentage |
| tax4_percent | DECIMAL(5,2) | YES | 0.00 | Tax 4 percentage |
| sub_total | DECIMAL(12,2) | YES | 0.00 | Base amount before tax |
| tax_total | DECIMAL(12,2) | YES | 0.00 | Total tax amount |
| other_charges | DECIMAL(12,2) | YES | 0.00 | Additional charges |
| discount_amount | DECIMAL(12,2) | YES | 0.00 | Discount applied |
| net_payable | DECIMAL(12,2) | YES | 0.00 | Final payable amount |
| amount_paid | DECIMAL(12,2) | YES | 0.00 | Amount already paid |
| **balance_due** | DECIMAL(12,2) | **GENERATED ALWAYS AS (net_payable - amount_paid) STORED** | — | **GENERATED COLUMN** — computed by DB |
| due_date | DATE | YES | NULL | Payment due date |
| status | INT UNSIGNED | YES | NULL | FK → sys_dropdown_table(id) RESTRICT (from getPendingStatusId()) |
| remarks | TEXT | YES | NULL | Invoice remarks |
| is_active | TINYINT(1) | YES | 1 | Active flag |
| is_deleted | TINYINT(1) | YES | 0 | Legacy deleted flag |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | Update time |
| deleted_at | TIMESTAMP | YES | NULL | Soft delete time |

**Indexes:**
- PRIMARY KEY (`id`)
- UNIQUE KEY `uq_vnd_invoice_no` (`vendor_id`, `invoice_number`)
- KEY `fk_vnd_inv_vendor` (`vendor_id`)
- KEY `fk_vnd_inv_agreement` (`agreement_id`)
- KEY `fk_vnd_inv_agreement_item` (`agreement_item_id`)
- KEY `fk_vnd_inv_status` (`status`)

**Foreign Keys:**

| FK Name | Column | References | On Delete |
|---------|--------|------------|-----------|
| fk_vnd_inv_vendor | vendor_id | vnd_vendors(id) | RESTRICT |
| fk_vnd_inv_agreement | agreement_id | vnd_agreements(id) | SET NULL |
| fk_vnd_inv_agreement_item | agreement_item_id | vnd_agreement_items_jnt(id) | SET NULL |
| fk_vnd_inv_status | status | sys_dropdown_table(id) | RESTRICT |

**Generated Column Conflict:**
- `balance_due` is defined as `GENERATED ALWAYS AS (net_payable - amount_paid) STORED` in DDL
- Model `boot()` has a `saving` event that also computes `balance_due` (and `$casts` includes balance_due as decimal)
- Accessor `getBalanceDueAttribute()` also computes `net_payable - amount_paid`
- **This is a CONFLICT** — attempting to write to a GENERATED column will cause MySQL error

---

## 5. BC-VAL — Validation Rules

### 5.1 Current State: Mixed Validation (No FormRequest)

The controller uses plain `Illuminate\Http\Request` throughout. Validation is inconsistent:

| Method | Validation Approach | Fields Validated | Notes |
|--------|---------------------|------------------|-------|
| store() | Manual `$request->validate()` | invoice_id: required, exists:vnd_invoices,id; amount: required, numeric; payment_date: required, date; payment_mode, remarks, txn_no, txn_date: nullable | **Misnamed: actually creates VndPayment** |
| update() | Manual `$request->validate()` | amount: required, numeric | **STUB** — only validates amount, no actual update logic |
| toggleStatus() | Manual `$request->validate()` | is_active: required, boolean | Also toggles linked VndAgreementItem |
| generateSingle() | Manual `$request->validate()` | agreement_item_id: required, numeric; billing_start_date: required, date; billing_end_date: required, date; other_charges: nullable, numeric; discount_amount: nullable, numeric | Invoice generation input |
| generateMultiple() | Manual `$request->validate()` | agreement_item_ids: required, array; (each): required, numeric; other_charges: nullable, numeric; discount_amount: nullable, numeric | Batch generation |
| storeRemark() | Manual `$request->validate()` | id: required, numeric; remarks: required | Remark update |
| pdfMultiple() | Manual `$request->validate()` | agreement_ids: required, array; (each): required, numeric | PDF generation (queries VndAgreementItem — wrong table) |
| sendMultipleEmails() | Manual `$request->validate()` | invoice_ids: nullable, array | Email dispatch |
| index() | None | — | No validation needed |
| create() | None | — | No validation needed |
| show() | None | — | Route model binding |
| edit() | None | — | Route model binding |
| destroy() | None | — | **STUB** — no logic |
| printList() | None | — | No validation |
| details() | None | — | No validation |

### 5.2 Known Validation Gaps

| Gap | Severity | Details |
|-----|----------|---------|
| No FormRequest for any method | **Critical** | Inconsistent, inline validation scattered across methods; no reusable rules |
| update() validates only amount field | **High** | No actual invoice data update; stub does nothing meaningful |
| destroy() no validation | **High** | No delete logic at all; stub redirects |
| generateSingle() no exists check on agreement_item_id | **Medium** | Validates numeric but no `exists:vnd_agreement_items_jnt,id` — non-existent ID causes 500 |
| generateMultiple() lacks individual validation | **Medium** | Array items validated only as `numeric`; no exists check |
| pdfMultiple() queries wrong table (VndAgreementItem not VndInvoice) | **High** | agreement_ids param named misleadingly; actually filters agreement items |
| No amount_paid/total paid validation in store() (payment create) | **Medium** | No check that payment amount does not exceed balance_due |
| No uniqueness validation for invoice_number generation | **Medium** | `rand(100,999)` collision risk — no retry logic |
| printList() no validation on filters | **Low** | Agreement_ids filter optional, no validation |

---

## 6. BC-AUTH — Authorization

| Permission Gate | Controller Method(s) | Model Policy |
|----------------|---------------------|-------------|
| tenant.vendor-invoice.viewAny | index() | Policy@viewAny |
| tenant.vendor-invoice.view | show(), details() | Policy@view |
| tenant.vendor-invoice.create | create(), generateSingle(), generateMultiple() | Policy@create |
| tenant.vendor-invoice.update | edit(), update() | Policy@update |
| tenant.vendor-invoice.delete | destroy() | Policy@delete |
| tenant.vendor-invoice.status | toggleStatus() | Policy@status |
| tenant.vendor-invoice.remark | storeRemark() | Policy@remark |
| tenant.vendor-invoice.pdf | pdfMultiple() | Policy@pdf |
| tenant.vendor-invoice.print | printList() | Policy@print |
| tenant.vendor-invoice.email-schedule | sendMultipleEmails() | Policy@emailSchedule |

**Note:** store() (which actually creates payments) uses `Gate::authorize('tenant.vendor-invoice.create')` despite creating a VndPayment record — permission gate name does not match action.

**Blade @can directives (expected in views):**
- `@can('tenant.vendor-invoice.viewAny')` — List access
- `@can('tenant.vendor-invoice.create')` — Generate Invoice button
- `@can('tenant.vendor-invoice.update')` — Edit action
- `@can('tenant.vendor-invoice.view')` — View action
- `@can('tenant.vendor-invoice.delete')` — Delete action
- `@can('tenant.vendor-invoice.status')` — Status toggle
- `@can('tenant.vendor-invoice.remark')` — Remark button
- `@can('tenant.vendor-invoice.pdf')` — PDF download
- `@can('tenant.vendor-invoice.print')` — Print action
- `@can('tenant.vendor-invoice.email-schedule')` — Email schedule

---

## 7. BC-BIZ — Business Logic

| BC-BIZ ID | Rule | Description |
|-----------|------|-------------|
| BC-BIZ-01 | FIXED Billing Calculation | generateInvoice(): when billing_model=FIXED, base amount = VndAgreementItem.fixed_charge. unit_rate and min_guarantee_qty are not used. qty_used is recorded from VndUsageLog sum but does not affect base amount. |
| BC-BIZ-02 | PER_UNIT Billing Calculation | generateInvoice(): when billing_model=PER_UNIT, base amount = max(qty_used, min_guarantee_qty) * unit_rate. fixed_charge is not included. The greater of actual usage and minimum guarantee is used. |
| BC-BIZ-03 | HYBRID Billing Calculation | generateInvoice(): when billing_model=HYBRID, base amount = fixed_charge_amt + (max(qty_used, min_guarantee_qty) * unit_rate). Combines both FIXED and PER_UNIT components. |
| BC-BIZ-04 | Usage Quantity Aggregation | generateInvoice(): queries VndUsageLog for sum of qty_used grouped by vendor_id + agreement_item_id for the billing period; returns 0 if no usage logs exist |
| BC-BIZ-05 | Tax Calculation | generateInvoice(): total_tax_percent = tax1_percent + tax2_percent + tax3_percent + tax4_percent. tax_total = base_amount * (total_tax_percent / 100). |
| BC-BIZ-06 | Invoice Financial Fields | generateInvoice(): sub_total = base_amount; other_charges and discount_amount passed as params (default 0); net_payable = sub_total + tax_total + other_charges - discount_amount; amount_paid = 0.00 initially; balance_due = net_payable - amount_paid (GENERATED COLUMN). |
| BC-BIZ-07 | Duplicate Invoice Prevention | generateInvoice(): before creation, checks if VndInvoice already exists with same agreement_item_id AND billing_start_date AND billing_end_date. If found, throws exception or returns error — prevents double-billing. |
| BC-BIZ-08 | Invoice Number Generation | generateInvoice(): invoice_number = 'INV-' . now()->format('YmdHis') . rand(100,999). Uses timestamp with random suffix — COLLISION RISK under high concurrency (no unique DB retry, no lock). |
| BC-BIZ-09 | Pending Status Lookup | generateInvoice(): calls getPendingStatusId() which queries sys_dropdown_table for vnd_invoices.status/Pending entry to set the initial invoice status. |
| BC-BIZ-10 | Single Invoice Generation | generateSingle(Request): validates input (agreement_item_id, billing_start_date, billing_end_date, other_charges, discount_amount), calls generateInvoice() private method |
| BC-BIZ-11 | Multiple Invoice Generation | generateMultiple(Request): validates agreement_item_ids as required array, loops through each ID calling generateInvoice() with shared other_charges/discount_amount |
| BC-BIZ-12 | Toggle Status Cascades to Agreement Item | toggleStatus(): toggles is_active on the VndInvoice record AND also toggles is_active on the linked VndAgreementItem (loaded via agreement_item_id) — unexpected side effect on agreement item status |
| BC-BIZ-13 | Remark Update | storeRemark(Request): validates id and remarks fields, finds VndInvoice by ID, updates remarks, redirects back with success flash |
| BC-BIZ-14 | PDF Multiple Generation | pdfMultiple(Request): validates agreement_ids as required array, queries VndAgreementItem (NOT VndInvoice — wrong table), generates and returns ZIP archive of PDFs |
| BC-BIZ-15 | Print List | printList(Request): queries VndAgreementItem with eager-loaded relations (agreement.vendor, item, invoices), renders print view |
| BC-BIZ-16 | Invoice Details API | details(Request): based on type param: 'invoice_detail' returns HTML for single invoice; 'agreement_item_detail' returns HTML for agreement item with invoice data. Returns JSON with success/html. |
| BC-BIZ-17 | Email Scheduling | sendMultipleEmails(Request): validates optional invoice_ids array, dispatches SendVendorInvoiceEmailJob for scheduling invoice email notifications |
| BC-BIZ-18 | Store Creates Payment (Misnamed) | store(Request): despite being named "store" (expected to create invoice), this method actually creates a VndPayment record linked to an invoice. Validates invoice_id, amount, payment_date, etc. |
| BC-BIZ-19 | Payment Reconciliation | store(): after creating VndPayment, updates VndInvoice.amount_paid (adds payment amount to existing amount_paid); balance_due adjusts automatically via GENERATED column |
| BC-BIZ-20 | update() is a STUB | update(Request, $id): only validates amount field as required|numeric, then redirects without actually updating any invoice data |
| BC-BIZ-21 | destroy() is a STUB | destroy($id): no delete logic, no findOrFail, simply redirects with flash message |

| BC-BIZ-23 | Balance Due — Triple Definition Conflict | balance_due is defined as (a) GENERATED ALWAYS AS column in DDL, (b) computed in model boot() saving event, and (c) exposed via getBalanceDueAttribute() accessor. The generated column and model event conflict — attempting to save will write to a generated column causing MySQL error. |
| BC-BIZ-24 | No Activity Logging | Unlike other Vendor controllers (Vendor, Agreement, Item, Usage Log) which call activityLog() on CRUD operations, VendorInvoiceController does NOT call activityLog() anywhere |

---

## 8. BC-REF — Referential Integrity

| Foreign Key | Column | References Table | On Delete |
|-------------|--------|-----------------|-----------|
| fk_vnd_inv_vendor | vnd_invoices.vendor_id | vnd_vendors.id | RESTRICT |
| fk_vnd_inv_agreement | vnd_invoices.agreement_id | vnd_agreements.id | SET NULL |
| fk_vnd_inv_agreement_item | vnd_invoices.agreement_item_id | vnd_agreement_items_jnt.id | SET NULL |
| fk_vnd_inv_status | vnd_invoices.status | sys_dropdown_table.id | RESTRICT |

**UNIQUE KEY:**
- `uq_vnd_invoice_no` (vendor_id, invoice_number) — Ensures each vendor has unique invoice numbers

**Cascade Behaviour:**
- Vendor DELETE RESTRICT — cannot delete vendor if invoices exist (prevented by FK)
- Agreement DELETE SET NULL — deleting an agreement sets agreement_id to NULL (invoice preserved)
- Agreement Item DELETE SET NULL — deleting agreement item sets agreement_item_id to NULL (invoice preserved)
- Status DELETE RESTRICT — cannot delete dropdown status if invoices reference it
- No CASCADE from invoices to payments — VndPayment has its own FK to vnd_invoices

---

## 9. Test Case Summary

### 9.1 Invoice CRUD + Billing Engine — Positive TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-VNDINV-P01 | Invoice | Positive | index() — view loads with Gate authorization | 3 |
| TC-VNDINV-P02 | Invoice | Positive | create() — form view loads with Gate authorization | 3 |
| TC-VNDINV-P03 | Invoice | Positive | show() — invoice detail view loads with Gate | 4 |
| TC-VNDINV-P04 | Invoice | Positive | edit() — edit form loads with pre-filled invoice data | 3 |
| TC-VNDINV-P05 | Billing Engine | Positive | generateSingle() — FIXED billing model, no taxes, no charges | 7 |
| TC-VNDINV-P06 | Billing Engine | Positive | generateSingle() — PER_UNIT billing with qty_used > min_guarantee | 7 |
| TC-VNDINV-P07 | Billing Engine | Positive | generateSingle() — PER_UNIT billing with qty_used < min_guarantee (min guarantee applied) | 7 |
| TC-VNDINV-P08 | Billing Engine | Positive | generateSingle() — HYBRID billing model | 7 |
| TC-VNDINV-P09 | Billing Engine | Positive | generateSingle() — all 4 tax percentages calculated correctly | 6 |
| TC-VNDINV-P10 | Billing Engine | Positive | generateSingle() — with other_charges and discount_amount | 6 |
| TC-VNDINV-P11 | Billing Engine | Positive | generateSingle() — zero usage log (qty_used=0) for PER_UNIT model | 6 |
| TC-VNDINV-P12 | Billing Engine | Positive | generateMultiple() — batch generation for multiple agreement items | 6 |
| TC-VNDINV-P13 | Billing Engine | Positive | generateInvoice() — duplicate prevention (same item + billing period) | 4 |
| TC-VNDINV-P14 | Billing Engine | Positive | generateInvoice() — invoice_number format verification | 4 |
| TC-VNDINV-P15 | Billing Engine | Positive | generateInvoice() — pending status lookup from sys_dropdown_table | 4 |
| TC-VNDINV-P16 | Invoice | Positive | toggleStatus() — toggle invoice is_active from active to inactive | 4 |
| TC-VNDINV-P17 | Invoice | Positive | toggleStatus() — toggle invoice is_active from inactive to active | 4 |
| TC-VNDINV-P18 | Invoice | Positive | toggleStatus() — side effect: also toggles linked VndAgreementItem is_active | 4 |
| TC-VNDINV-P19 | Invoice | Positive | storeRemark() — update invoice remarks | 4 |
| TC-VNDINV-P20 | Invoice | Positive | storeRemark() — update remarks multiple times (overwrite behaviour) | 4 |
| TC-VNDINV-P21 | Payment | Positive | store() — creates VndPayment record (misnamed method) | 5 |
| TC-VNDINV-P22 | Payment | Positive | store() — payment reconciliation updates invoice amount_paid | 4 |
| TC-VNDINV-P23 | Payment | Positive | store() — full payment with all optional fields (payment_mode, txn_no, txn_date, remarks) | 5 |
| TC-VNDINV-P24 | PDF | Positive | pdfMultiple() — generates ZIP of PDFs for given agreement IDs | 5 |
| TC-VNDINV-P25 | Print | Positive | printList() — renders print view with agreement item data | 4 |
| TC-VNDINV-P26 | Print | Positive | printList() — filter by agreement_ids | 4 |
| TC-VNDINV-P27 | API | Positive | details() — returns invoice detail HTML for type=invoice_detail | 4 |
| TC-VNDINV-P28 | API | Positive | details() — returns agreement item detail HTML for type=agreement_item_detail | 4 |
| TC-VNDINV-P29 | Email | Positive | sendMultipleEmails() — dispatches email jobs for invoice IDs | 4 |
| TC-VNDINV-P30 | Email | Positive | sendMultipleEmails() — sends to all invoices when invoice_ids is empty | 3 |
| TC-VNDINV-P31 | Invoice | Positive | update() — stub validation passes for valid amount field | 3 |
| TC-VNDINV-P32 | Invoice | Positive | destroy() — stub redirects gracefully | 2 |
| TC-VNDINV-P33 | Billing Engine | Positive | generateSingle() — item_description populated from agreement item description | 5 |
| TC-VNDINV-P34 | Billing Engine | Positive | generateSingle() — recurring monthly invoice generation (different billing periods) | 5 |
| TC-VNDINV-P35 | Billing Engine | Positive | generateSingle() — FIXED model with zero fixed_charge (free item) | 5 |
| TC-VNDINV-P36 | Billing Engine | Positive | generateInvoice() — tax_total = 0 when all tax percentages are 0 | 5 |
| TC-VNDINV-P37 | Billing Engine | Positive | generateInvoice() — other_charges and discount_amount both > 0 net correctly | 5 |
| TC-VNDINV-P38 | Billing Engine | Positive | generateSingle() — agreement with SET NULL FK behaviour (agreement_id null after agreement delete) | 5 |
| TC-VNDINV-P39 | Billing Engine | Positive | generateMultiple() — mixed billing models in single batch | 7 |
| TC-VNDINV-P40 | Invoice | Positive | pdfMultiple() — single agreement ID generates single PDF (not ZIP) | 4 |
| TC-VNDINV-P41 | Billing Engine | Positive | generateSingle() — FIXED model: fixed_charge only, usageQty recorded but not used | 5 |
| TC-VNDINV-P42 | Billing Engine | Positive | generateSingle() — PER_UNIT model: usageQty × unit_rate (no min_guarantee check) | 5 |
| TC-VNDINV-P43 | Billing Engine | Positive | generateSingle() — HYBRID model: fixed_charge + max(usageQty - min_guarantee_qty, 0) × unit_rate | 5 |
| TC-VNDINV-P44 | Billing Engine | Positive | generateMultiple() — batch generation with array of agreement_item_ids, returns success+failed arrays | 6 |
| TC-VNDINV-P45 | Billing Engine | Positive | generateMultiple() — partial failure: some items fail, others succeed | 5 |
| TC-VNDINV-P46 | Billing Engine | Positive | generateInvoice() — FIXED model: fixed_charge only, usageQty=max(usageQty,1) recorded | 5 |
| TC-VNDINV-P47 | Billing Engine | Positive | generateInvoice() — PER_UNIT model: usageQty × unit_rate (no min_guarantee subtraction) | 5 |
| TC-VNDINV-P48 | Billing Engine | Positive | generateInvoice() — HYBRID model: fixed_charge + max(usageQty - min_guarantee_qty, 0) × unit_rate | 5 |
| TC-VNDINV-P49 | Billing Engine | Positive | generateInvoice() — tax calculation: sum(tax1-4_percent) × subTotal / 100 | 5 |
| TC-VNDINV-P50 | Billing Engine | Positive | generateInvoice() — duplicate prevention: invoice exists for same agreement_item_id + agreement dates | 4 |
| TC-VNDINV-P51 | Billing Engine | Positive | generateInvoice() — invoice_number format: 'INV-' . YmdHis . rand(100,999) | 4 |
| TC-VNDINV-P52 | Invoice | Positive | toggleStatus() — toggles VndAgreementItem.is_active + VndInvoice.is_active by agreement_item_id | 5 |
| TC-VNDINV-P53 | Invoice | Positive | storeRemark() — updates invoice.remarks via findOrFail with invoice_id and remark | 4 |
| TC-VNDINV-P54 | PDF | Positive | pdfMultiple() — generates ZIP of PDFs for given agreement_ids, skips missing items | 5 |
| TC-VNDINV-P55 | PDF | Positive | pdfMultiple() — handles missing agreement items gracefully (continue + skip) | 4 |
| TC-VNDINV-P56 | Print | Positive | printList() — returns print view with agreement items, optional ids filter | 4 |
| TC-VNDINV-P57 | API | Positive | details() — type=invoice returns invoice detail HTML as JSON | 4 |
| TC-VNDINV-P58 | API | Positive | details() — type=agreement_item_detail (default) returns agreement item detail HTML as JSON | 4 |
| TC-VNDINV-P59 | Email | Positive | sendMultipleEmails() — dispatches SendVendorInvoiceEmailJob with invoice_ids array | 4 |
| TC-VNDINV-P60 | Billing Engine | Positive | getPendingStatusId() — returns ID of sys_dropdown where key=vnd_invoices.status AND value=Pending AND is_active=1 | 3 |

### 9.2 Invoice CRUD + Billing Engine — Negative TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-VNDINV-N01 | Invoice | Negative | Permission — index without tenant.vendor-invoice.viewAny | 2 |
| TC-VNDINV-N02 | Invoice | Negative | Permission — create without tenant.vendor-invoice.create | 2 |
| TC-VNDINV-N03 | Invoice | Negative | Permission — generateSingle without tenant.vendor-invoice.create | 2 |
| TC-VNDINV-N04 | Invoice | Negative | Permission — generateMultiple without tenant.vendor-invoice.create | 2 |
| TC-VNDINV-N05 | Invoice | Negative | Permission — show without tenant.vendor-invoice.view | 2 |
| TC-VNDINV-N06 | Invoice | Negative | Permission — edit without tenant.vendor-invoice.update | 2 |
| TC-VNDINV-N07 | Invoice | Negative | Permission — update without tenant.vendor-invoice.update | 2 |
| TC-VNDINV-N08 | Invoice | Negative | Permission — destroy without tenant.vendor-invoice.delete | 2 |
| TC-VNDINV-N09 | Invoice | Negative | Permission — toggleStatus without tenant.vendor-invoice.status | 2 |
| TC-VNDINV-N10 | Invoice | Negative | Permission — storeRemark without tenant.vendor-invoice.remark | 2 |
| TC-VNDINV-N11 | Invoice | Negative | Permission — pdfMultiple without tenant.vendor-invoice.pdf | 2 |
| TC-VNDINV-N12 | Invoice | Negative | Permission — printList without tenant.vendor-invoice.print | 2 |
| TC-VNDINV-N13 | Invoice | Negative | Permission — sendMultipleEmails without tenant.vendor-invoice.email-schedule | 2 |
| TC-VNDINV-N14 | Invoice | Negative | Permission — details without tenant.vendor-invoice.view | 2 |
| TC-VNDINV-N15 | Billing Engine | Negative | generateSingle() — missing agreement_item_id | 2 |
| TC-VNDINV-N16 | Billing Engine | Negative | generateSingle() — agreement_item_id non-existent (no exists validation) | 3 |
| TC-VNDINV-N17 | Billing Engine | Negative | generateSingle() — missing billing_start_date | 2 |
| TC-VNDINV-N18 | Billing Engine | Negative | generateSingle() — missing billing_end_date | 2 |
| TC-VNDINV-N19 | Billing Engine | Negative | generateSingle() — invalid date format for billing dates | 2 |
| TC-VNDINV-N20 | Billing Engine | Negative | generateSingle() — other_charges non-numeric | 2 |
| TC-VNDINV-N21 | Billing Engine | Negative | generateSingle() — discount_amount non-numeric | 2 |
| TC-VNDINV-N22 | Billing Engine | Negative | generateMultiple() — agreement_item_ids not an array | 2 |
| TC-VNDINV-N23 | Billing Engine | Negative | generateMultiple() — empty agreement_item_ids array | 2 |
| TC-VNDINV-N24 | Billing Engine | Negative | generateMultiple() — one ID in array is non-existent | 3 |
| TC-VNDINV-N25 | Billing Engine | Negative | generateInvoice() — duplicate invoice attempt (same item + billing period) | 3 |
| TC-VNDINV-N26 | Billing Engine | Negative | generateInvoice() — agreement item has no billing model set (null) | 3 |
| TC-VNDINV-N27 | Billing Engine | Negative | generateInvoice() — agreement item soft-deleted | 3 |
| TC-VNDINV-N28 | Invoice | Negative | toggleStatus() — missing is_active parameter | 2 |
| TC-VNDINV-N29 | Invoice | Negative | toggleStatus() — non-boolean is_active value | 2 |
| TC-VNDINV-N30 | Invoice | Negative | toggleStatus() — non-existent invoice ID | 2 |
| TC-VNDINV-N31 | Invoice | Negative | storeRemark() — missing id parameter | 2 |
| TC-VNDINV-N32 | Invoice | Negative | storeRemark() — missing remarks parameter | 2 |
| TC-VNDINV-N33 | Invoice | Negative | storeRemark() — non-existent invoice ID | 2 |
| TC-VNDINV-N34 | Payment | Negative | store() — missing invoice_id (payment creation) | 2 |
| TC-VNDINV-N35 | Payment | Negative | store() — invoice_id non-existent | 3 |
| TC-VNDINV-N36 | Payment | Negative | store() — missing amount | 2 |
| TC-VNDINV-N37 | Payment | Negative | store() — amount non-numeric | 2 |
| TC-VNDINV-N38 | Payment | Negative | store() — missing payment_date | 2 |
| TC-VNDINV-N39 | Invoice | Negative | update() — missing amount (stub validation) | 2 |
| TC-VNDINV-N40 | Invoice | Negative | update() — amount non-numeric (stub validation) | 2 |
| TC-VNDINV-N41 | Invoice | Negative | update() — stub does NOT update any invoice field | 3 |
| TC-VNDINV-N42 | Invoice | Negative | destroy() — stub does NOT soft-delete invoice | 3 |
| TC-VNDINV-N43 | Invoice | Negative | PDF — pdfMultiple() missing agreement_ids | 2 |
| TC-VNDINV-N44 | Invoice | Negative | PDF — pdfMultiple() agreement_ids not an array | 2 |
| TC-VNDINV-N45 | Invoice | Negative | PDF — pdfMultiple() agreement_ids contains non-numeric value | 2 |
| TC-VNDINV-N46 | Invoice | Negative | Print — printList() with non-existent agreement_ids | 3 |
| TC-VNDINV-N47 | Invoice | Negative | API — details() with non-existent invoice ID | 2 |
| TC-VNDINV-N48 | Invoice | Negative | API — details() with invalid type parameter | 2 |
| TC-VNDINV-N49 | Invoice | Negative | Email — sendMultipleEmails() invoice_ids contains non-existent ID | 3 |
| TC-VNDINV-N50 | Billing Engine | Negative | generateSingle() — billing_start_date after billing_end_date | 3 |
| TC-VNDINV-N51 | Billing Engine | Negative | generateInvoice() — unit_rate=0 with PER_UNIT model (net_payable=0) | 4 |
| TC-VNDINV-N52 | Billing Engine | Negative | generateSingle() — negative other_charges accepted (no validation) | 3 |
| TC-VNDINV-N53 | Billing Engine | Negative | generateSingle() — negative discount_amount accepted (inflates net_payable) | 3 |
| TC-VNDINV-N54 | Billing Engine | Negative | generateInvoice() — invoice_number collision possibility | 3 |
| TC-VNDINV-N55 | Invoice | Negative | Balance due — attempt to manually write to GENERATED column via model | 3 |

### 9.3 Code Review TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-CR-VINV-01 | Code Review | Review | index() — Gate authorize + view return | 3 |
| TC-CR-VINV-02 | Code Review | Review | create() — Gate authorize + view return | 2 |
| TC-CR-VINV-03 | Code Review | Review | show() — Gate + findOrFail + with relations | 3 |
| TC-CR-VINV-04 | Code Review | Review | edit() — Gate + findOrFail + view with data | 3 |
| TC-CR-VINV-05 | Code Review | Review | store() — MISNAMED: creates VndPayment, not invoice | 6 |
| TC-CR-VINV-06 | Code Review | Review | update() — STUB: validates only amount, no update logic | 3 |
| TC-CR-VINV-07 | Code Review | Review | destroy() — STUB: no delete logic, just redirect | 2 |
| TC-CR-VINV-08 | Code Review | Review | toggleStatus() — Gate + validate + toggle invoice + toggle agreement item + response | 5 |
| TC-CR-VINV-09 | Code Review | Review | generateSingle() — Gate + validate + call generateInvoice | 4 |
| TC-CR-VINV-10 | Code Review | Review | generateMultiple() — Gate + validate + loop generateInvoice | 4 |
| TC-CR-VINV-11 | Code Review | Review | generateInvoice() — PRIVATE: core billing engine logic | 8 |
| TC-CR-VINV-12 | Code Review | Review | generateInvoice() — FIXED billing calculation flow | 5 |
| TC-CR-VINV-13 | Code Review | Review | generateInvoice() — PER_UNIT billing calculation flow | 5 |
| TC-CR-VINV-14 | Code Review | Review | generateInvoice() — HYBRID billing calculation flow | 5 |
| TC-CR-VINV-15 | Code Review | Review | generateInvoice() — tax calculation (sum of 4 percents) | 4 |
| TC-CR-VINV-16 | Code Review | Review | generateInvoice() — duplicate prevention logic | 4 |
| TC-CR-VINV-17 | Code Review | Review | generateInvoice() — invoice_number generation (timestamp + rand) | 3 |
| TC-CR-VINV-18 | Code Review | Review | getPendingStatusId() — PRIVATE: sys_dropdown_table lookup | 3 |
| TC-CR-VINV-19 | Code Review | Review | storeRemark() — Gate + validate + update + redirect | 4 |
| TC-CR-VINV-20 | Code Review | Review | pdfMultiple() — Gate + validate + query VndAgreementItem (wrong table) | 4 |
| TC-CR-VINV-21 | Code Review | Review | printList() — Gate + query VndAgreementItem with relations | 3 |
| TC-CR-VINV-22 | Code Review | Review | details() — Gate + switch on type param + return JSON HTML | 4 |
| TC-CR-VINV-23 | Code Review | Review | sendMultipleEmails() — Gate + validate + dispatch job | 3 |
| TC-CR-VINV-24 | Code Review | Review | VndInvoice Model — fillable (28 fields), casts, boot saving event | 5 |
| TC-CR-VINV-25 | Code Review | Review | VndInvoice Model — generated column conflict (DDL vs model boot vs accessor) | 4 |
| TC-CR-VINV-26 | Code Review | Review | VndInvoice Model — relationships (vendor, payments, agreement, agreementItem, statusDropdown) | 4 |
| TC-CR-VINV-27 | Code Review | Review | VndInvoice Model — scopes (active, inDateRange) and helpers (getIsPaidAttribute) | 4 |
| TC-CR-VINV-28 | Code Review | Review | No activityLog() calls in entire controller (inconsistent with other Vendor controllers) | 2 |
| TC-CR-VINV-29 | Code Review | Review | No FormRequest — all validation inline and inconsistent | 3 |
| TC-CR-VINV-30 | Code Review | Review | pdfMultiple queries VndAgreementItem not VndInvoice (wrong table) | 3 |
| TC-CR-VINV-31 | Code Review | Review | balance_due triple definition: GENERATED column + boot() event + accessor | 4 |
| TC-CR-VINV-32 | Code Review | Review | Redirect consistency check — all methods redirect behaviour | 4 |

### 9.4 Dependency TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-D-VINV-01 | Dependency | Dependency | Vendor FK RESTRICT — cannot delete vendor with invoices | 3 |
| TC-D-VINV-02 | Dependency | Dependency | Agreement FK SET NULL — deleting agreement preserves invoice (agreement_id=null) | 4 |
| TC-D-VINV-03 | Dependency | Dependency | Agreement Item FK SET NULL — deleting item preserves invoice (agreement_item_id=null) | 4 |
| TC-D-VINV-04 | Dependency | Dependency | Status FK RESTRICT — cannot delete dropdown status referenced by invoices | 3 |
| TC-D-VINV-05 | Dependency | Dependency | UNIQUE KEY — same vendor cannot have duplicate invoice_number | 3 |
| TC-D-VINV-06 | Dependency | Dependency | UNIQUE KEY — different vendors can have same invoice_number | 3 |
| TC-D-VINV-07 | Dependency | Dependency | Generate invoice requires VndUsageLog records for qty aggregation | 4 |
| TC-D-VINV-08 | Dependency | Dependency | Generate invoice requires sys_dropdown_table entry for Pending status | 3 |
| TC-D-VINV-09 | Dependency | Dependency | store() (payment create) depends on existing invoice in vnd_invoices | 3 |
| TC-D-VINV-10 | Dependency | Dependency | GENERATED column balance_due — verify MySQL version supports GENERATED ALWAYS AS | 3 |
| TC-D-VINV-11 | Dependency | Dependency | VndPayment table FK constraint depends on vnd_invoices.id | 3 |
| TC-D-VINV-12 | Dependency | Dependency | SoftDeletes — verified deleted_at column exists in vnd_invoices | 2 |
| TC-D-VINV-13 | Dependency | Dependency | sendMultipleEmails depends on queue worker and mail configuration | 3 |
| TC-D-VINV-14 | Dependency | Dependency | pdfMultiple requires PDF library and ZIP extension | 3 |

---

## 10. Test Case Steps

### 10.1 Positive TC Steps — Invoice CRUD + Billing Engine

#### TC-VNDINV-P01: index() — view loads with Gate authorization

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.vendor-invoice.viewAny` permission navigates to `/vendor-invoice` | Invoice index view loads |
| 2 | Verify view returned is `invoice.index` | Correct view |
| 3 | Verify no search/filter params processed at controller level (view handles UI) | Controller passes through |

#### TC-VNDINV-P02: create() — form view loads with Gate authorization

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.vendor-invoice.create` permission navigates to `/vendor-invoice/create` | Invoice create form loads |
| 2 | Verify view returned is `invoice.create` | Correct view |
| 3 | Verify no additional data loaded in controller (form handled by view) | Minimal controller logic |

#### TC-VNDINV-P03: show() — invoice detail view loads with Gate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.vendor-invoice.view` permission accesses `/vendor-invoice/{id}` | Show view loads |
| 2 | Verify `findOrFail($id)` loads correct invoice | Invoice found |
| 3 | Verify vendor, agreement, agreementItem, payments relations accessible in view | Relations loaded |
| 4 | Verify all 35 columns viewable: invoice_number, dates, financial fields, status, remarks | All fields displayed |

#### TC-VNDINV-P04: edit() — edit form loads with pre-filled invoice data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.vendor-invoice.update` permission accesses `/vendor-invoice/{id}/edit` | Edit form loads |
| 2 | Verify invoice data pre-filled in form fields | Pre-populated |
| 3 | Verify view returned is `invoice.edit` | Correct view |

#### TC-VNDINV-P05: generateSingle() — FIXED billing model, no taxes, no charges

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create VndAgreementItem with billing_model='FIXED', fixed_charge=10000.00, all tax%=0, unit_rate=0, min_guarantee_qty=0 | Agreement item configured |
| 2 | POST `/vendor-invoice/generate` with agreement_item_id=X, billing_start_date='2026-01-01', billing_end_date='2026-01-31' | Request sent |
| 3 | Verify VndInvoice created in vnd_invoices | Invoice record exists |
| 4 | Verify invoice_number starts with 'INV-' followed by YmdHis + 3-digit random | Number format correct |
| 5 | Verify sub_total = 10000.00, tax_total = 0.00, net_payable = 10000.00 | FIXED calculation correct |
| 6 | Verify fixed_charge_amt = 10000.00, unit_charge_amt = 0.00, qty_used = 0.00 | Fields populated from agreement item |
| 7 | Verify status = Pending (from sys_dropdown_table lookup) | Pending status |

#### TC-VNDINV-P06: generateSingle() — PER_UNIT billing with qty_used > min_guarantee

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create VndAgreementItem with billing_model='PER_UNIT', unit_rate=500.00, min_guarantee_qty=100.00 | Agreement item configured |
| 2 | Create VndUsageLog records for same vendor+agreement_item totaling qty_used=150.00 | Usage logs with qty > min_guarantee |
| 3 | POST `/vendor-invoice/generate` with agreement_item_id=X, billing dates covering the usage period | Request sent |
| 4 | Verify VndInvoice created | Invoice exists |
| 5 | Verify qty_used = 150.00 (sum from usage logs) | Usage aggregated |
| 6 | Verify net_payable = max(150, 100) * 500 = 75000.00 | PER_UNIT: uses actual qty (exceeds min) |
| 7 | Verify unit_charge_amt = 500.00, min_guarantee_qty = 100.00 from agreement item | Rates copied correctly |

#### TC-VNDINV-P07: generateSingle() — PER_UNIT billing with qty_used < min_guarantee

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create VndAgreementItem with billing_model='PER_UNIT', unit_rate=500.00, min_guarantee_qty=100.00 | Agreement item configured |
| 2 | Create VndUsageLog records totaling qty_used=30.00 (below min_guarantee) | Usage logs with qty < min_guarantee |
| 3 | POST generate request | Request sent |
| 4 | Verify qty_used = 30.00 (actual from usage logs) | Usage recorded |
| 5 | Verify net_payable = max(30, 100) * 500 = 50000.00 | Min guarantee applied (100 * 500) |
| 6 | Verify discount_amount and other_charges = 0.00 (not provided) | Defaults to zero |

#### TC-VNDINV-P08: generateSingle() — HYBRID billing model

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create VndAgreementItem with billing_model='HYBRID', fixed_charge=5000.00, unit_rate=200.00, min_guarantee_qty=50.00 | HYBRID configured |
| 2 | Create VndUsageLog totaling qty_used=75.00 | Usage > min_guarantee |
| 3 | POST generate request with agreement_item_id=X | Request sent |
| 4 | Verify net_payable = 5000.00 (fixed) + max(75, 50) * 200 = 5000 + 15000 = 20000.00 | HYBRID calculation correct |
| 5 | Verify fixed_charge_amt = 5000.00, unit_rate = 200.00, qty_used = 75.00, min_guarantee_qty = 50.00 | All fields recorded |

#### TC-VNDINV-P09: generateSingle() — all 4 tax percentages calculated correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create VndAgreementItem with FIXED, fixed_charge=1000.00, tax1=5.00, tax2=3.00, tax3=2.00, tax4=1.00 | 4 taxes configured |
| 2 | POST generate request | Request sent |
| 3 | Verify sub_total = 1000.00 (FIXED base) | Base amount correct |
| 4 | Verify total_tax_percent = 5+3+2+1 = 11.00% | Tax percent sum correct |
| 5 | Verify tax_total = 1000 * 0.11 = 110.00 | Tax calculation correct |
| 6 | Verify net_payable = 1000 + 110 = 1110.00 | Net payable with tax |

#### TC-VNDINV-P10: generateSingle() — with other_charges and discount_amount

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create VndAgreementItem with FIXED, fixed_charge=10000.00, tax1=10.00 | Configured with tax |
| 2 | POST generate with other_charges=500.00, discount_amount=1000.00 | Additional params |
| 3 | Verify sub_total = 10000.00 | Base correct |
| 4 | Verify tax_total = 10000 * 0.10 = 1000.00 | Tax on base |
| 5 | Verify net_payable = 10000 + 1000 + 500 - 1000 = 10500.00 | Net with charges and discount |
| 6 | Verify invoice has other_charges=500.00, discount_amount=1000.00 | Fields recorded |

#### TC-VNDINV-P11: generateSingle() — zero usage log (qty_used=0) for PER_UNIT model

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create VndAgreementItem with PER_UNIT, unit_rate=300.00, min_guarantee_qty=50.00 | PER_UNIT configured |
| 2 | Ensure NO VndUsageLog records exist for this vendor+agreement_item | No usage |
| 3 | POST generate request | Request sent |
| 4 | Verify qty_used = 0.00 (no usage logs, returns 0) | Zero usage |
| 5 | Verify net_payable = max(0, 50) * 300 = 15000.00 | Min guarantee applied |
| 6 | Verify VndUsageLog sum query returns 0 gracefully | No error |

#### TC-VNDINV-P12: generateMultiple() — batch generation for multiple agreement items

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 VndAgreementItems with different billing models/rates | 3 items exist |
| 2 | POST `/vendor-invoice/generate-multiple` with agreement_item_ids=[1,2,3] and shared billing dates | Batch request |
| 3 | Verify 3 VndInvoice records created (one per agreement item) | 3 invoices |
| 4 | Verify each invoice has correct calculation based on its agreement item's billing model | Calculations correct |
| 5 | Verify all invoices have same billing_start_date and billing_end_date (shared params) | Consistent dates |
| 6 | Verify success flash or response indicating all 3 generated | Batch success |

#### TC-VNDINV-P13: generateInvoice() — duplicate prevention (same item + billing period)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice already exists for agreement_item_id=X with billing_start_date='2026-01-01', billing_end_date='2026-01-31' | Existing invoice |
| 2 | Attempt to generate invoice for same agreement_item_id + same billing dates | Duplicate request |
| 3 | Verify generateInvoice() detects duplicate via where check and throws exception/error | Duplicate prevented |
| 4 | Verify no second invoice record created in vnd_invoices | No duplicate record |

#### TC-VNDINV-P14: generateInvoice() — invoice_number format verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Generate an invoice | Invoice created |
| 2 | Verify invoice_number matches pattern: INV-YYYYMMDDHHmmSSNNN (14 digits + 3 random) | Format confirmed |
| 3 | Generate second invoice 1+ second later | Different timestamp |
| 4 | Verify both invoice_numbers are unique | No collision |

#### TC-VNDINV-P15: generateInvoice() — pending status lookup from sys_dropdown_table

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure sys_dropdown_table has entry for type='vnd_invoices.status', name='Pending' | Status exists |
| 2 | Generate an invoice | Invoice created |
| 3 | Verify invoice.status = id of the Pending dropdown entry | Pending status set |
| 4 | Remove the Pending status entry from sys_dropdown_table and generate again | Error or null status |

#### TC-VNDINV-P16: toggleStatus() — toggle invoice is_active from active to inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice exists with is_active=1 | Active invoice |
| 2 | POST `/vendor-invoice/{id}/toggle-status` with is_active=0 | Toggle request |
| 3 | Verify JSON response: `{"success": true, "is_active": false}` | AJAX success |
| 4 | Verify DB: invoice.is_active = 0 | Invoice deactivated |

#### TC-VNDINV-P17: toggleStatus() — toggle invoice is_active from inactive to active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice exists with is_active=0 | Inactive invoice |
| 2 | POST toggle-status with is_active=1 | Toggle request |
| 3 | Verify JSON response: `{"success": true, "is_active": true}` | AJAX success |
| 4 | Verify DB: invoice.is_active = 1 | Invoice activated |

#### TC-VNDINV-P18: toggleStatus() — side effect: also toggles linked VndAgreementItem is_active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice has agreement_item_id=X linking to VndAgreementItem with is_active=1 | Agreement item active |
| 2 | Toggle invoice status (is_active=0) | Invoice deactivated |
| 3 | Verify VndAgreementItem X also has is_active=0 | Unexpected side effect |
| 4 | Toggle invoice back (is_active=1) and verify agreement item also set to 1 | Both toggled |

#### TC-VNDINV-P19: storeRemark() — update invoice remarks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice exists with remarks = NULL | No remarks |
| 2 | POST `/invoice/remark` with id=X, remarks="Payment pending verification" | Remark request |
| 3 | Verify invoice.remarks = "Payment pending verification" | Remarks updated |
| 4 | Verify redirect back with success flash message | Flash success |

#### TC-VNDINV-P20: storeRemark() — update remarks multiple times (overwrite behaviour)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice has remarks = "First remark" | Existing remark |
| 2 | POST storeRemark with remarks="Second remark" | Overwrite |
| 3 | Verify invoice.remarks = "Second remark" (overwritten, not appended) | Overwritten |
| 4 | Verify no history of previous remark kept | No audit trail |

#### TC-VNDINV-P21: store() — creates VndPayment record (misnamed method)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice exists with net_payable=5000.00, amount_paid=0.00, balance_due=5000.00 | Valid invoice |
| 2 | POST `/vendor-invoice` (store route) with invoice_id=X, amount=2000.00, payment_date='2026-02-15' | Payment request |
| 3 | Verify VndPayment record created with amount=2000.00, invoice_id=X | Payment created |
| 4 | Verify payment has payment_date='2026-02-15' | Date recorded |
| 5 | Verify VndInvoice.amount_paid updated to 2000.00 (partial payment) | Amount paid updated |

#### TC-VNDINV-P22: store() — payment reconciliation updates invoice amount_paid

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice has net_payable=10000.00, amount_paid=3000.00, balance_due=7000.00 | Partial paid |
| 2 | Create another payment of 5000.00 via store() | Additional payment |
| 3 | Verify VndPayment record created | Payment recorded |
| 4 | Verify invoice.amount_paid updated to 8000.00 (3000+5000) | Cumulative amount paid |

#### TC-VNDINV-P23: store() — full payment with all optional fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice exists with net_payable=5000.00 | Valid invoice |
| 2 | POST store() with invoice_id=X, amount=5000.00, payment_date='2026-02-15', payment_mode='BANK_TRANSFER', txn_no='TXN123456', txn_date='2026-02-14', remarks='Full payment' | Full request |
| 3 | Verify VndPayment with all fields populated | Payment with all data |
| 4 | Verify invoice.amount_paid = 5000.00 | Fully paid |
| 5 | Verify invoice.balance_due = 0.00 (calculated by generated column) | Zero balance |

#### TC-VNDINV-P24: pdfMultiple() — generates ZIP of PDFs for given agreement IDs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Multiple invoices exist linked to multiple agreement items | Invoices available |
| 2 | POST `/vendor-invoice/pdf-multiple` with agreement_ids=[1,2,3] | PDF request |
| 3 | Verify response is a ZIP file containing 3 PDFs | ZIP returned |
| 4 | Verify each PDF contains correct invoice data for each agreement item | Content correct |
| 5 | Verify query searches VndAgreementItem (not VndInvoice) — Known Issue | Wrong table queried |

#### TC-VNDINV-P25: printList() — renders print view with agreement item data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoices exist with agreement items having vendor, item relations | Test data |
| 2 | GET `/vendor/invoice/print` | Print view loads |
| 3 | Verify VndAgreementItem::with(['agreement.vendor', 'item', 'invoices']) is queried | Relations loaded |
| 4 | Verify print-friendly view renders with all data | Print view rendered |

#### TC-VNDINV-P26: printList() — filter by agreement_ids

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Agreement items exist with IDs 1, 2, 3, 4 | Multiple items |
| 2 | GET `/vendor/invoice/print?agreement_ids=1,3` | Filtered request |
| 3 | Verify only agreement items 1 and 3 are in the result | Filtered correctly |
| 4 | Verify items 2 and 4 are excluded | Excluded |

#### TC-VNDINV-P27: details() — returns invoice detail HTML for type=invoice_detail

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice exists with ID=X | Valid invoice |
| 2 | GET `/vendor/invoice/details?type=invoice_detail&id=X` | Detail request |
| 3 | Verify JSON response: `{"success": true, "html": "..."}` | JSON success |
| 4 | Verify HTML contains invoice financial details, dates, status | Content correct |

#### TC-VNDINV-P28: details() — returns agreement item detail HTML for type=agreement_item_detail

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Agreement item exists with invoices | Valid item |
| 2 | GET `/vendor/invoice/details?type=agreement_item_detail&id=X` | Detail request |
| 3 | Verify JSON response with agreement item + invoice data | JSON success |
| 4 | Verify HTML includes item info, billing model, rates, linked invoices | Content correct |

#### TC-VNDINV-P29: sendMultipleEmails() — dispatches email jobs for invoice IDs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoices exist with IDs 1, 2, 3 | Valid invoices |
| 2 | POST `/invoice/email/multiple` with invoice_ids=[1,2,3] | Email request |
| 3 | Verify SendVendorInvoiceEmailJob dispatched for each invoice ID | 3 jobs dispatched |
| 4 | Verify no error thrown and request succeeds | Processed successfully |

#### TC-VNDINV-P30: sendMultipleEmails() — sends to all invoices when invoice_ids is empty

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Multiple invoices exist in database | Invoices available |
| 2 | POST `/invoice/email/multiple` with empty or missing invoice_ids | No filter |
| 3 | Verify jobs dispatched for all invoices (or handled gracefully) | All processed |

#### TC-VNDINV-P31: update() — stub validation passes for valid amount field

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice exists with ID=X | Valid invoice |
| 2 | PUT `/vendor-invoice/{id}` with amount=1000.00 | Update request |
| 3 | Verify validation passes and redirect occurs (no actual update happens) | Stub redirects |

#### TC-VNDINV-P32: destroy() — stub redirects gracefully

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice exists with ID=X | Valid invoice |
| 2 | DELETE `/vendor-invoice/{id}` | Delete request |
| 3 | Verify redirect occurs with flash message (no actual delete) | Stub redirects |

#### TC-VNDINV-P33: generateSingle() — item_description populated from agreement item

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | VndAgreementItem has description="Website maintenance service" | Item with description |
| 2 | Generate invoice for this item | Invoice created |
| 3 | Verify invoice.item_description = "Website maintenance service" | Description copied |
| 4 | Verify VndAgreementItem loaded via load('agreement.vendor', 'item') before field copy | Relation eager-loaded |

#### TC-VNDINV-P34: generateSingle() — recurring monthly invoice generation (different billing periods)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Generate invoice for agreement_item_id=X for Jan 2026 (billing_start='2026-01-01', billing_end='2026-01-31') | First invoice |
| 2 | Generate invoice for same item for Feb 2026 (different billing period) | Second invoice |
| 3 | Verify duplicate prevention does NOT block (different billing_end_date) | Both created |
| 4 | Verify each invoice has correct net_payable based on respective usage periods | Correct per period |

#### TC-VNDINV-P35: generateSingle() — FIXED model with zero fixed_charge (free item)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | VndAgreementItem with billing_model='FIXED', fixed_charge=0.00 | Free item |
| 2 | Generate invoice | Invoice created |
| 3 | Verify sub_total = 0.00, net_payable = 0.00 | Zero amount |
| 4 | Verify tax_total = 0.00 (any tax% on 0 base = 0) | No tax |
| 5 | Verify invoice created successfully (no division by zero, no error) | Graceful handling |

#### TC-VNDINV-P36: generateInvoice() — tax_total = 0 when all tax percentages are 0

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | VndAgreementItem with FIXED=5000.00, all tax%=0 | No taxes |
| 2 | Generate invoice | Invoice created |
| 3 | Verify tax1-4_percent = 0.00 | Tax fields zero |
| 4 | Verify tax_total = 0.00 | No tax calculated |
| 5 | Verify net_payable = sub_total + 0 + other_charges - discount = 5000.00 | Only base amount |

#### TC-VNDINV-P37: generateInvoice() — other_charges and discount_amount both > 0 net correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | VndAgreementItem FIXED=10000.00, tax1=5% | Configured |
| 2 | Generate with other_charges=2000.00, discount_amount=3000.00 | Both params |
| 3 | Verify sub_total=10000.00, tax_total=500.00 | Base + tax |
| 4 | Verify net_payable = 10000 + 500 + 2000 - 3000 = 9500.00 | Net calculation |
| 5 | Verify other_charges and discount_amount both > 0 in invoice record | Fields stored |

#### TC-VNDINV-P38: generateSingle() — agreement with SET NULL FK behaviour

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice has agreement_id=5 (FK to vnd_agreements) | Invoice with agreement |
| 2 | Delete the agreement from vnd_agreements | Agreement deleted |
| 3 | Verify invoice.agreement_id = NULL (SET NULL) | FK set to null |
| 4 | Verify invoice still exists in vnd_invoices | Invoice preserved |
| 5 | Verify invoice.vendor_id still intact (RESTRICT so vendor not deletable) | Vendor preserved |

#### TC-VNDINV-P39: generateMultiple() — mixed billing models in single batch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Agreement items: Item1 (FIXED=5000), Item2 (PER_UNIT, rate=100, min=10), Item3 (HYBRID, fixed=2000, rate=50, min=20) | 3 mixed items |
| 2 | Usage logs: Item2 qty=15, Item3 qty=30 | Usage data |
| 3 | POST generate-multiple with agreement_item_ids=[1,2,3] | Batch request |
| 4 | Verify Invoice1: net_payable=5000 (FIXED) | FIXED correct |
| 5 | Verify Invoice2: net_payable=max(15,10)*100=1500 (PER_UNIT) | PER_UNIT correct |
| 6 | Verify Invoice3: net_payable=2000+max(30,20)*50=2000+1500=3500 (HYBRID) | HYBRID correct |
| 7 | Verify all 3 invoices share same billing_start_date and billing_end_date | Consistent |

#### TC-VNDINV-P40: pdfMultiple() — single agreement ID generates single PDF

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Single agreement item with invoice exists | One item |
| 2 | POST pdfMultiple with agreement_ids=[1] | Single item request |
| 3 | Verify response is a PDF file (or ZIP with 1 file) | PDF returned |
| 4 | Verify PDF contains correct invoice data | Content correct |

#### TC-VNDINV-P41: generateSingle() — FIXED model: fixed_charge only, usageQty recorded but not used

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create VndAgreementItem with billing_model='FIXED', fixed_charge=10000.00, all tax%=0 | FIXED item configured |
| 2 | POST `/vendor-invoice/generate` with agreement_item_id=X | Request sent |
| 3 | Verify VndInvoice created with sub_total = 10000.00 (fixed_charge only) | FIXED calculation correct |
| 4 | Verify qty_used = max(usageLogSum, 1) — at least 1 even with no usage logs | Usage floor applied |
| 5 | Verify unit_charge_amt = 0.00 (no per-unit component for FIXED) | No unit charge |

#### TC-VNDINV-P42: generateSingle() — PER_UNIT model: usageQty × unit_rate (no min_guarantee check)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create VndAgreementItem with billing_model='PER_UNIT', unit_rate=500.00, min_guarantee_qty=100.00 | PER_UNIT item configured |
| 2 | Create VndUsageLog records totaling qty_used=150.00 for this vendor+agreement_item | Usage logs exist |
| 3 | POST `/vendor-invoice/generate` with agreement_item_id=X | Request sent |
| 4 | Verify VndInvoice created with unit_charge_amt = 150 × 500 = 75000.00 (usageQty × unit_rate) | PER_UNIT: no min_guarantee check |
| 5 | Verify qty_used = max(150, 1) = 150, fixed_charge_amt = 0.00 | Usage recorded, no fixed charge |

#### TC-VNDINV-P43: generateSingle() — HYBRID model: fixed_charge + max(usageQty - min_guarantee_qty, 0) × unit_rate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create VndAgreementItem with billing_model='HYBRID', fixed_charge=5000.00, unit_rate=200.00, min_guarantee_qty=50.00 | HYBRID item configured |
| 2 | Create VndUsageLog records totaling qty_used=75.00 | Usage > min_guarantee |
| 3 | POST `/vendor-invoice/generate` with agreement_item_id=X | Request sent |
| 4 | Verify sub_total = 5000.00 (fixed) + max(75 - 50, 0) × 200 = 5000 + 5000 = 10000.00 | HYBRID: excess over min_guarantee billed |
| 5 | Verify fixed_charge_amt = 5000.00, unit_charge_amt = 5000.00, qty_used = max(75,1) = 75 | Fields recorded correctly |

#### TC-VNDINV-P44: generateMultiple() — batch generation with array of agreement_item_ids, returns success+failed arrays

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 VndAgreementItems with different billing models | 3 items exist |
| 2 | POST `/vendor-invoice/generate-multiple` with agreement_item_ids=[1,2,3] | Batch request |
| 3 | Verify 3 VndInvoice records created (one per agreement item) | 3 invoices |
| 4 | Verify each invoice has correct calculation based on its agreement item's billing model | Calculations correct |
| 5 | Verify JSON response contains `success` array with all 3 IDs | Success array populated |
| 6 | Verify JSON response contains `failed` array (empty) | Failed array empty |

#### TC-VNDINV-P45: generateMultiple() — partial failure: some items fail, others succeed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 2 valid VndAgreementItems and use 1 non-existent ID | Mixed valid/invalid |
| 2 | POST `/vendor-invoice/generate-multiple` with agreement_item_ids=[valid1, 99999, valid2] | Batch with one invalid |
| 3 | Verify valid items generate invoices successfully | Valid items processed |
| 4 | Verify JSON response `success` array contains valid IDs | Success array populated |
| 5 | Verify JSON response `failed` array contains the invalid ID with reason | Failed array populated |

#### TC-VNDINV-P46: generateInvoice() — FIXED model: fixed_charge only, usageQty=max(usageQty,1) recorded

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | VndAgreementItem with billing_model='FIXED', fixed_charge=10000.00, all tax%=0 | FIXED item |
| 2 | Ensure NO VndUsageLog records exist for this vendor+item | No usage logs |
| 3 | Generate invoice via generateSingle() | Invoice created |
| 4 | Verify sub_total = 10000.00 (fixed_charge only), unit_charge_amt = 0.00 | FIXED: only fixed charge |
| 5 | Verify qty_used = max(0, 1) = 1 (usage floor applied) | Usage floor = 1 |

#### TC-VNDINV-P47: generateInvoice() — PER_UNIT model: usageQty × unit_rate (no min_guarantee subtraction)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | VndAgreementItem with billing_model='PER_UNIT', unit_rate=500.00, min_guarantee_qty=100.00 | PER_UNIT item |
| 2 | VndUsageLog records totaling qty_used=150.00 | Usage logs |
| 3 | Generate invoice | Invoice created |
| 4 | Verify sub_total = 150 × 500 = 75000.00 (usageQty × unit_rate, NO min_guarantee check) | PER_UNIT: direct multiplication |
| 5 | Verify qty_used = max(150, 1) = 150, min_guarantee_qty = 100.00 (recorded but not used in calc) | Min guarantee stored but not applied |

#### TC-VNDINV-P48: generateInvoice() — HYBRID model: fixed_charge + max(usageQty - min_guarantee_qty, 0) × unit_rate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | VndAgreementItem with billing_model='HYBRID', fixed_charge=5000.00, unit_rate=200.00, min_guarantee_qty=50.00 | HYBRID item |
| 2 | VndUsageLog records totaling qty_used=75.00 | Usage > min_guarantee |
| 3 | Generate invoice | Invoice created |
| 4 | Verify sub_total = 5000.00 (fixed) + max(75 - 50, 0) × 200 = 5000 + 5000 = 10000.00 | HYBRID: excess over min_guarantee |
| 5 | Verify fixed_charge_amt = 5000.00, unit_charge_amt = 5000.00, qty_used = max(75,1) = 75 | Fields recorded correctly |

#### TC-VNDINV-P49: generateInvoice() — tax calculation: sum(tax1-4_percent) × subTotal / 100

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | VndAgreementItem with FIXED, fixed_charge=1000.00, tax1=5.00, tax2=3.00, tax3=2.00, tax4=1.00 | 4 taxes configured |
| 2 | Generate invoice | Invoice created |
| 3 | Verify sub_total = 1000.00 (FIXED base) | Base amount correct |
| 4 | Verify tax_total = 1000.00 × (5+3+2+1)/100 = 1000 × 0.11 = 110.00 | Tax calculation correct |
| 5 | Verify net_payable = sub_total + tax_total = 1000 + 110 = 1110.00 (no other_charges/discount in net) | Net = subTotal + taxTotal |

#### TC-VNDINV-P50: generateInvoice() — duplicate prevention: invoice exists for same agreement_item_id + agreement dates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice already exists for agreement_item_id=X (using agreement.start_date and agreement.end_date as billing dates) | Existing invoice |
| 2 | Attempt to generate invoice for same agreement_item_id | Duplicate request |
| 3 | Verify generateInvoice() detects duplicate via whereDate check on agreement.start_date and agreement.end_date | Duplicate detected |
| 4 | Verify exception thrown: 'Invoice already generated for this period' | Duplicate prevented |

#### TC-VNDINV-P51: generateInvoice() — invoice_number format: 'INV-' . YmdHis . rand(100,999)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Generate an invoice | Invoice created |
| 2 | Verify invoice_number matches pattern: INV-YYYYMMDDHHmmSSNNN (14 digits + 3 random) | Format confirmed |
| 3 | Generate second invoice 1+ second later | Different timestamp |
| 4 | Verify both invoice_numbers are unique | No collision |

#### TC-VNDINV-P52: toggleStatus() — toggles VndAgreementItem.is_active + VndInvoice.is_active by agreement_item_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | VndAgreementItem exists with is_active=1, linked VndInvoice exists with is_active=1 | Both active |
| 2 | POST `/vendor-invoice/{agreement_item_id}/toggle-status` with is_active=0 | Toggle request |
| 3 | Verify VndAgreementItem.is_active = 0 (toggled first) | Agreement item deactivated |
| 4 | Verify VndInvoice (where agreement_item_id = id) is_active = 0 | Invoice deactivated |
| 5 | Verify JSON response: `{"success": true, "is_active": false}` | AJAX response |

#### TC-VNDINV-P53: storeRemark() — updates invoice.remarks via findOrFail with invoice_id and remark

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice exists with remarks = NULL | No remarks |
| 2 | POST `/invoice/remark` with invoice_id=X, remark="Payment pending verification" | Remark request |
| 3 | Verify invoice.remarks = "Payment pending verification" | Remarks updated |
| 4 | Verify JSON response: `{"status": true, "message": "Remark saved successfully"}` | JSON success |

#### TC-VNDINV-P54: pdfMultiple() — generates ZIP of PDFs for given agreement_ids, skips missing items

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Multiple VndAgreementItems exist with IDs 1, 2, 3 | Agreement items available |
| 2 | POST `/vendor-invoice/pdf-multiple` with agreement_ids=[1,2,3] | PDF request |
| 3 | Verify response is a ZIP file containing 3 PDFs | ZIP returned |
| 4 | Verify each PDF contains correct agreement item data | Content correct |
| 5 | Verify query searches VndAgreementItem (not VndInvoice) — Known Issue KI-06 | Wrong table queried |

#### TC-VNDINV-P55: pdfMultiple() — handles missing agreement items gracefully (continue + skip)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | VndAgreementItem exists with ID=1, ID=3 exists, ID=2 does NOT exist | Mixed existence |
| 2 | POST pdfMultiple with agreement_ids=[1, 99999, 3] | One non-existent ID |
| 3 | Verify VndAgreementItem::find(99999) returns null → skipped via continue | Missing item skipped |
| 4 | Verify ZIP contains PDFs for IDs 1 and 3 only (2 PDFs) | Partial ZIP generated |

#### TC-VNDINV-P56: printList() — returns print view with agreement items, optional ids filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Multiple VndAgreementItems exist with agreement.vendor, item, invoices relations | Test data |
| 2 | GET `/vendor/invoice/print` | Print view loads |
| 3 | Verify VndAgreementItem::with(['agreement.vendor', 'item', 'invoices']) is queried | Relations loaded |
| 4 | GET `/vendor/invoice/print?ids=1,3` and verify only items 1 and 3 returned | Filter by ids works |

#### TC-VNDINV-P57: details() — type=invoice returns invoice detail HTML as JSON

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice exists with ID=X | Valid invoice |
| 2 | GET `/vendor/invoice/details?type=invoice&id=X` | Detail request |
| 3 | Verify VndInvoice::with(['vendor','agreement','agreementItem'])->find($id) loads invoice | Invoice loaded |
| 4 | Verify JSON response: `{"status": true, "html": "..."}` with invoice detail HTML | JSON success |

#### TC-VNDINV-P58: details() — type=agreement_item_detail (default) returns agreement item detail HTML as JSON

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | VndAgreementItem exists with ID=X | Valid agreement item |
| 2 | GET `/vendor/invoice/details?type=other&id=X` (any type other than 'invoice') | Detail request |
| 3 | Verify VndAgreementItem::with(['agreement.vendor', 'item'])->find($id) loads item | Item loaded |
| 4 | Verify JSON response: `{"status": true, "html": "..."}` with agreement item detail HTML | JSON success |

#### TC-VNDINV-P59: sendMultipleEmails() — dispatches SendVendorInvoiceEmailJob with invoice_ids array

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoices exist with IDs 1, 2, 3 | Valid invoices |
| 2 | POST `/invoice/email/multiple` with invoice_ids=[1,2,3] | Email request |
| 3 | Verify SendVendorInvoiceEmailJob dispatched once with the invoice_ids array and user email | Single job dispatched |
| 4 | Verify JSON response: `{"status": true, "message": "Emails sent successfully"}` | Success response |

#### TC-VNDINV-P60: getPendingStatusId() — returns ID of sys_dropdown where key=vnd_invoices.status AND value=Pending AND is_active=1

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure sys_dropdown_table has entry: key='vnd_invoices.status', value='Pending', is_active=1 | Status exists |
| 2 | Generate an invoice (calls getPendingStatusId() internally) | Invoice created |
| 3 | Verify invoice.status = ID of the Pending dropdown entry | Pending status set |

### 10.2 Negative TC Steps — Invoice CRUD + Billing Engine

#### TC-VNDINV-N01: Permission — index without tenant.vendor-invoice.viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-invoice.viewAny` accesses `/vendor-invoice` | 403 Forbidden |

#### TC-VNDINV-N02: Permission — create without tenant.vendor-invoice.create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-invoice.create` accesses `/vendor-invoice/create` | 403 Forbidden |

#### TC-VNDINV-N03: Permission — generateSingle without tenant.vendor-invoice.create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-invoice.create` POSTs to `/vendor-invoice/generate` | 403 Forbidden |

#### TC-VNDINV-N04: Permission — generateMultiple without tenant.vendor-invoice.create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-invoice.create` POSTs to `/vendor-invoice/generate-multiple` | 403 Forbidden |

#### TC-VNDINV-N05: Permission — show without tenant.vendor-invoice.view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-invoice.view` accesses `/vendor-invoice/{id}` | 403 Forbidden |

#### TC-VNDINV-N06: Permission — edit without tenant.vendor-invoice.update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-invoice.update` accesses `/vendor-invoice/{id}/edit` | 403 Forbidden |

#### TC-VNDINV-N07: Permission — update without tenant.vendor-invoice.update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-invoice.update` PUTs to `/vendor-invoice/{id}` | 403 Forbidden |

#### TC-VNDINV-N08: Permission — destroy without tenant.vendor-invoice.delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-invoice.delete` DELETEs `/vendor-invoice/{id}` | 403 Forbidden |

#### TC-VNDINV-N09: Permission — toggleStatus without tenant.vendor-invoice.status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-invoice.status` POSTs toggle-status | 403 Forbidden |

#### TC-VNDINV-N10: Permission — storeRemark without tenant.vendor-invoice.remark

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-invoice.remark` POSTs to `/invoice/remark` | 403 Forbidden |

#### TC-VNDINV-N11: Permission — pdfMultiple without tenant.vendor-invoice.pdf

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-invoice.pdf` POSTs pdf-multiple | 403 Forbidden |

#### TC-VNDINV-N12: Permission — printList without tenant.vendor-invoice.print

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-invoice.print` accesses `/vendor/invoice/print` | 403 Forbidden |

#### TC-VNDINV-N13: Permission — sendMultipleEmails without tenant.vendor-invoice.email-schedule

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-invoice.email-schedule` POSTs email/multiple | 403 Forbidden |

#### TC-VNDINV-N14: Permission — details without tenant.vendor-invoice.view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-invoice.view` accesses `/vendor/invoice/details` | 403 Forbidden |

#### TC-VNDINV-N15: generateSingle() — missing agreement_item_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST generate without agreement_item_id | Validation error |
| 2 | Verify error: "The agreement item id field is required." | Error shown |

#### TC-VNDINV-N16: generateSingle() — agreement_item_id non-existent

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST generate with agreement_item_id=99999 | Non-existent ID |
| 2 | Controller validates only numeric — no exists check | Validation passes |
| 3 | generateInvoice() tries to load VndAgreementItem — findOrFail returns 404 | 404 error |

#### TC-VNDINV-N17: generateSingle() — missing billing_start_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST generate without billing_start_date | Validation error |
| 2 | Verify error: "The billing start date field is required." | Error shown |

#### TC-VNDINV-N18: generateSingle() — missing billing_end_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST generate without billing_end_date | Validation error |
| 2 | Verify error: "The billing end date field is required." | Error shown |

#### TC-VNDINV-N19: generateSingle() — invalid date format for billing dates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST generate with billing_start_date="not-a-date" | Invalid date |
| 2 | Verify validation error: date validation fails | Error returned |

#### TC-VNDINV-N20: generateSingle() — other_charges non-numeric

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST generate with other_charges="abc" | Non-numeric |
| 2 | Verify validation error: "The other charges must be a number." | Error returned |

#### TC-VNDINV-N21: generateSingle() — discount_amount non-numeric

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST generate with discount_amount="abc" | Non-numeric |
| 2 | Verify validation error: "The discount amount must be a number." | Error returned |

#### TC-VNDINV-N22: generateMultiple() — agreement_item_ids not an array

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST generate-multiple with agreement_item_ids="not-array" | Not array |
| 2 | Verify validation error: "The agreement item ids must be an array." | Error returned |

#### TC-VNDINV-N23: generateMultiple() — empty agreement_item_ids array

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST generate-multiple with agreement_item_ids=[] | Empty array |
| 2 | Each item validated as required — fails on empty | Error (or loops 0 times creating 0 invoices) |

#### TC-VNDINV-N24: generateMultiple() — one ID in array is non-existent

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST generate-multiple with agreement_item_ids=[1, 99999, 3] | Mixed valid/invalid |
| 2 | Valid IDs 1 and 3 generate successfully | Partial success |
| 3 | Invalid ID 99999 causes 404 in generateInvoice() | Transaction not atomic |

#### TC-VNDINV-N25: generateInvoice() — duplicate invoice attempt (same item + billing period)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice exists for agreement_item_id=1, billing_start='2026-01-01', billing_end='2026-01-31' | Existing invoice |
| 2 | POST generate with same agreement_item_id and same dates | Duplicate |
| 3 | Verify error/exception thrown — duplicate prevention triggered | Duplicate blocked |

#### TC-VNDINV-N26: generateInvoice() — agreement item has no billing model set (null)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | VndAgreementItem with billing_model = NULL | Missing model |
| 2 | POST generate for this item | Invoice generation attempted |
| 3 | Verify error — no billing model to determine calculation | Error thrown |

#### TC-VNDINV-N27: generateInvoice() — agreement item soft-deleted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | VndAgreementItem is soft-deleted (deleted_at set) | Trashed item |
| 2 | POST generate for this item | generateInvoice does not use withTrashed |
| 3 | Verify findOrFail returns 404 (SoftDeletes excludes it) | 404 error |

#### TC-VNDINV-N28: toggleStatus() — missing is_active parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST toggle-status without is_active in request body | Validation error |
| 2 | Verify error: "The is active field is required." | Error returned |

#### TC-VNDINV-N29: toggleStatus() — non-boolean is_active value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST toggle-status with is_active="not-boolean" | Invalid boolean |
| 2 | Verify error: "The is active field must be true or false." | Error returned |

#### TC-VNDINV-N30: toggleStatus() — non-existent invoice ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST toggle-status for invoice ID 99999 | Non-existent |
| 2 | Verify 404 from findOrFail | 404 error |

#### TC-VNDINV-N31: storeRemark() — missing id parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/invoice/remark` without id | Validation error |
| 2 | Verify error: "The id field is required." | Error returned |

#### TC-VNDINV-N32: storeRemark() — missing remarks parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/invoice/remark` without remarks | Validation error |
| 2 | Verify error: "The remarks field is required." | Error returned |

#### TC-VNDINV-N33: storeRemark() — non-existent invoice ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/invoice/remark` with id=99999 | Non-existent |
| 2 | Verify 404 from findOrFail | 404 error |

#### TC-VNDINV-N34: store() — missing invoice_id (payment creation)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/vendor-invoice` without invoice_id | Validation error |
| 2 | Verify error: "The invoice id field is required." | Error returned |

#### TC-VNDINV-N35: store() — invoice_id non-existent

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST store() with invoice_id=99999 | Non-existent invoice |
| 2 | VndPayment created with non-existent FK (will fail at DB level or store null) | DB error or 500 |
| 3 | Verify error handling — no exists validation before insert | Unhandled exception |

#### TC-VNDINV-N36: store() — missing amount

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST store() without amount | Validation error |
| 2 | Verify error: "The amount field is required." | Error returned |

#### TC-VNDINV-N37: store() — amount non-numeric

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST store() with amount="abc" | Non-numeric |
| 2 | Verify validation error: "The amount must be a number." | Error returned |

#### TC-VNDINV-N38: store() — missing payment_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST store() without payment_date | Validation error |
| 2 | Verify error: "The payment date field is required." | Error returned |

#### TC-VNDINV-N39: update() — missing amount (stub validation)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT `/vendor-invoice/{id}` without amount | Validation error |
| 2 | Verify error: "The amount field is required." | Error returned (stub only validates amount) |

#### TC-VNDINV-N40: update() — amount non-numeric (stub validation)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT `/vendor-invoice/{id}` with amount="abc" | Non-numeric |
| 2 | Verify validation error: "The amount must be a number." | Error returned |

#### TC-VNDINV-N41: update() — stub does NOT update any invoice field

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice has remarks="Original", amount_paid=0 | Initial state |
| 2 | PUT update with amount=5000 and any other params | Stub request |
| 3 | Verify invoice remarks still "Original", amount_paid still 0 | No fields changed |

#### TC-VNDINV-N42: destroy() — stub does NOT soft-delete invoice

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice has deleted_at=NULL | Active invoice |
| 2 | DELETE `/vendor-invoice/{id}` | Stub request |
| 3 | Verify invoice.deleted_at still NULL (not soft-deleted) | No delete occurred |

#### TC-VNDINV-N43: pdfMultiple() — missing agreement_ids

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST pdfMultiple without agreement_ids | Validation error |
| 2 | Verify error: "The agreement ids field is required." | Error returned |

#### TC-VNDINV-N44: pdfMultiple() — agreement_ids not an array

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST pdfMultiple with agreement_ids="not-array" | Invalid |
| 2 | Verify validation error: "The agreement ids must be an array." | Error returned |

#### TC-VNDINV-N45: pdfMultiple() — agreement_ids contains non-numeric value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST pdfMultiple with agreement_ids=[1, "abc", 3] | Mixed values |
| 2 | Each item validated required|numeric — "abc" fails | Validation error |

#### TC-VNDINV-N46: printList() — with non-existent agreement_ids

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/vendor/invoice/print?agreement_ids=99999` | Non-existent |
| 2 | Query returns empty collection | Empty result |
| 3 | Print view renders with no data (graceful) | Empty print view |

#### TC-VNDINV-N47: details() — with non-existent invoice ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET details?type=invoice_detail&id=99999 | Non-existent invoice |
| 2 | Controller loads VndInvoice::find($id) (not findOrFail) | Returns null |
| 3 | Verify JSON response with success=false or error | Graceful null handling |

#### TC-VNDINV-N48: details() — with invalid type parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET details?type=invalid_type&id=1 | Invalid type |
| 2 | Controller switch/case may not handle unexpected type | Returns default or error |

#### TC-VNDINV-N49: sendMultipleEmails() — invoice_ids contains non-existent ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST email/multiple with invoice_ids=[1, 99999] | Mixed valid/invalid |
| 2 | Job dispatched for each ID — non-existent ID job may fail | Partial failure |
| 3 | Verify error handling — no validation of invoice existence | Unhandled |

#### TC-VNDINV-N50: generateSingle() — billing_start_date after billing_end_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST generate with start_date='2026-02-01', end_date='2026-01-31' | Start after end |
| 2 | No validation rule for date order (no after:start_date check) | Validation passes |
| 3 | generateInvoice creates invoice with inverted dates | Data quality issue |

#### TC-VNDINV-N51: generateInvoice() — unit_rate=0 with PER_UNIT model (net_payable=0)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | VndAgreementItem PER_UNIT, unit_rate=0.00, min_guarantee_qty=100 | Zero rate |
| 2 | Generate invoice with qty_used=50 | Request |
| 3 | Verify net_payable = max(50, 100) * 0 = 0.00 | Zero amount invoice |
| 4 | Verify invoice generated with all fields but net_payable=0 | Valid but no charge |

#### TC-VNDINV-N52: generateSingle() — negative other_charges accepted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST generate with other_charges=-500.00 | Negative charge |
| 2 | Validation passes (numeric allows negative, no min:0 rule) | Accepted |
| 3 | net_payable reduced by 500 (acts like additional discount) | Unexpected behaviour |

#### TC-VNDINV-N53: generateSingle() — negative discount_amount accepted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST generate with discount_amount=-1000.00 | Negative discount |
| 2 | Validation passes (numeric allows negative, no min:0 rule) | Accepted |
| 3 | net_payable increased by 1000 (acts like additional charge) | Unexpected behaviour |

#### TC-VNDINV-N54: generateInvoice() — invoice_number collision possibility

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Simulate high-concurrency scenario: two invoices generated at same second with same rand(100,999) value | Collision scenario |
| 2 | Second insert hits UNIQUE KEY constraint on uq_vnd_invoice_no | DB integrity violation |
| 3 | Verify no retry/regeneration logic in generateInvoice() | Unhandled exception |

#### TC-VNDINV-N58: Balance due — attempt to manually write to GENERATED column via model

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | VndInvoice model boot() saving event computes $this->balance_due | Model event writes to balance_due |
| 2 | Attempt to save the model | MySQL error: "Cannot update generated column" |
| 3 | Verify conflict between GENERATED column and model event | Save fails |

### 10.3 Code Review TC Steps

#### TC-CR-VINV-01: index() — Gate authorize + view return

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-invoice.viewAny')` at method start | Gate present |
| 2 | Review return view: `invoice.index` | View returned |
| 3 | Review no data passed to view (no query, no pagination) | Minimal controller logic |

#### TC-CR-VINV-02: create() — Gate authorize + view return

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-invoice.create')` | Gate present |
| 2 | Review return view: `invoice.create` | View returned |

#### TC-CR-VINV-03: show() — Gate + findOrFail + with relations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-invoice.view')` | Gate present |
| 2 | Review `VndInvoice::with(['vendor', 'agreement', 'agreementItem', ...])->findOrFail($id)` | Eager loading |
| 3 | Review compact('invoice') passed to `invoice.show` view | Data passed to view |

#### TC-CR-VINV-04: edit() — Gate + findOrFail + view with data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-invoice.update')` | Gate present |
| 2 | Review `VndInvoice::findOrFail($id)` | Model binding |
| 3 | Review return view: `invoice.edit` with invoice data | Edit view returned |

#### TC-CR-VINV-05: store() — MISNAMED: creates VndPayment, not invoice

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-invoice.create')` — uses invoice create permission despite creating payment | Permission mismatch |
| 2 | Review `$request->validate([...])` — validates invoice_id, amount, payment_date, payment_mode, txn_no, txn_date, remarks | Inline validation |
| 3 | Review `VndPayment::create([...])` — creates payment, NOT invoice | Method creates payment |
| 4 | Review update of invoice.amount_paid after payment creation | Payment reconciliation |
| 5 | Review redirect with flash message | Redirect |
| 6 | Note: Method name `store()` is misleading — should be named `storePayment()` or similar | Naming issue |

#### TC-CR-VINV-06: update() — STUB: validates only amount, no update logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-invoice.update')` | Gate present |
| 2 | Review `$request->validate(['amount' => 'required|numeric'])` — only amount validated | Minimal validation |
| 3 | Review no `$invoice->update(...)` call — redirect occurs without saving | No update logic |

#### TC-CR-VINV-07: destroy() — STUB: no delete logic, just redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-invoice.delete')` | Gate present |
| 2 | Review no `findOrFail`, no `$invoice->delete()`, no SoftDeletes call | No deletion |

#### TC-CR-VINV-08: toggleStatus() — Gate + validate + toggle invoice + toggle agreement item + response

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-invoice.status')` | Gate present |
| 2 | Review `$request->validate(['is_active' => 'required|boolean'])` | Validation |
| 3 | Review `VndInvoice::findOrFail($id)` | Model binding |
| 4 | Review `$invoice->agreementItem->update(['is_active' => $isActive])` — also toggles linked agreement item | Side effect |
| 5 | Review JSON response based on success | AJAX response |

#### TC-CR-VINV-09: generateSingle() — Gate + validate + call generateInvoice

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-invoice.create')` | Gate present |
| 2 | Review `$request->validate([...])` — agreement_item_id, dates, other_charges, discount_amount | Input validation |
| 3 | Review call to `$this->generateInvoice($agreementItemId, true, $otherCharges, $discountAmount)` | Delegates to private method |
| 4 | Review `$single=true` flag passed to generateInvoice | Single mode |

#### TC-CR-VINV-10: generateMultiple() — Gate + validate + loop generateInvoice

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-invoice.create')` | Gate present |
| 2 | Review `$request->validate([...])` — agreement_item_ids array validation | Input validation |
| 3 | Review `foreach ($request->agreement_item_ids as $id) { $this->generateInvoice($id, false, ...); }` | Loop |
| 4 | Review `$single=false` flag passed in loop | Batch mode |

#### TC-CR-VINV-11: generateInvoice() — PRIVATE: core billing engine logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review method signature: `private function generateInvoice($agreementItemId, $single, $otherCharges, $discountAmount)` | Private, 4 params |
| 2 | Review `VndAgreementItem::with(['agreement.vendor', 'item'])->findOrFail($agreementItemId)` | Load item with relations |
| 3 | Review usage qty aggregation: `VndUsageLog::where(...)->sum('qty_used')` | Usage sum query |
| 4 | Review billing model switch: `if ($agreementItem->billing_model === 'FIXED')` ... `PER_UNIT` ... `HYBRID` | 3 billing models |
| 5 | Review tax calculation: sum of 4 tax percents to tax_total | Tax logic |
| 6 | Review duplicate check: `VndInvoice::where(agreement_item_id, billing_start_date, billing_end_date)->exists()` | Duplicate prevention |
| 7 | Review invoice creation: `VndInvoice::create([...28+ fields])` | Invoice creation |
| 8 | Review no DB::transaction wrapping — each step is independent | No atomicity |

#### TC-CR-VINV-12: generateInvoice() — FIXED billing calculation flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `if ($agreementItem->billing_model === 'FIXED')` branch | FIXED branch |
| 2 | Review `$baseAmount = $agreementItem->fixed_charge` | Base = fixed_charge |
| 3 | Review `$netPayable = $baseAmount` | No qty/rate multiplication |
| 4 | Review fixed_charge_amt set from $agreementItem->fixed_charge | Fixed charge copied |
| 5 | Review qty_used not factored into calculation | Usage ignored for FIXED |

#### TC-CR-VINV-13: generateInvoice() — PER_UNIT billing calculation flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `elseif ($agreementItem->billing_model === 'PER_UNIT')` branch | PER_UNIT branch |
| 2 | Review `$chargeableQty = max($totalQtyUsed, $agreementItem->min_guarantee_qty)` | Max of actual vs min |
| 3 | Review `$baseAmount = $chargeableQty * $agreementItem->unit_rate` | Qty x rate |
| 4 | Review unit_rate, qty_used, min_guarantee_qty copied from agreement item | Fields copied |
| 5 | Review fixed_charge_amt = 0.00 (not applicable for PER_UNIT) | No fixed charge |

#### TC-CR-VINV-14: generateInvoice() — HYBRID billing calculation flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `elseif ($agreementItem->billing_model === 'HYBRID')` branch | HYBRID branch |
| 2 | Review `$chargeableQty = max($totalQtyUsed, $agreementItem->min_guarantee_qty)` | Max qty |
| 3 | Review `$baseAmount = $agreementItem->fixed_charge + ($chargeableQty * $agreementItem->unit_rate)` | Fixed + (qty x rate) |
| 4 | Review both fixed_charge_amt and unit_charge_amt populated | Both fields set |
| 5 | Review qty_used and min_guarantee_qty copied | Qty fields copied |

#### TC-CR-VINV-15: generateInvoice() — tax calculation (sum of 4 percents)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$totalTaxPercent = $agreementItem->tax1_percent + ... + tax4_percent` | Sum of 4 taxes |
| 2 | Review `$taxTotal = $baseAmount * ($totalTaxPercent / 100)` | Tax on base |
| 3 | Review `$netPayable = $baseAmount + $taxTotal + $otherCharges - $discountAmount` | Net with tax+charges |
| 4 | Review tax1-4_percent stored on invoice record | Tax fields persisted |

#### TC-CR-VINV-16: generateInvoice() — duplicate prevention logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$existingInvoice = VndInvoice::where('agreement_item_id', $agreementItemId)` | Query by agreement item |
| 2 | Review `->where('billing_start_date', $billingStartDate)->where('billing_end_date', $billingEndDate)` | Date match |
| 3 | Review `->exists()` check | Existence check |
| 4 | Review conditional throw/abort if duplicate found | Duplicate prevention |

#### TC-CR-VINV-17: generateInvoice() — invoice_number generation (timestamp + rand)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$invoiceNumber = 'INV-' . now()->format('YmdHis') . rand(100, 999)` | Format: INV-YYYYMMDDHHmmSSNNN |
| 2 | Review no DB lock, no retry on UNIQUE violation | Collision gap |
| 3 | Review no sequence table or auto-increment pattern | No proper sequence |

#### TC-CR-VINV-18: getPendingStatusId() — PRIVATE: sys_dropdown_table lookup

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `private function getPendingStatusId()` — queries Dropdown model | Private lookup |
| 2 | Review `Dropdown::where('type', 'vnd_invoices.status')->where('name', 'Pending')->first()` | Type + name filter |
| 3 | Review returns `$status->id ?? null` (nullable return) | Null if not found |

#### TC-CR-VINV-19: storeRemark() — Gate + validate + update + redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-invoice.remark')` | Gate present |
| 2 | Review `$request->validate(['id' => 'required|numeric', 'remarks' => 'required'])` | Validation |
| 3 | Review `VndInvoice::findOrFail($id)->update(['remarks' => $request->remarks])` | Update remarks |
| 4 | Review redirect back with success flash | Flash redirect |

#### TC-CR-VINV-20: pdfMultiple() — Gate + validate + query VndAgreementItem (wrong table)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-invoice.pdf')` | Gate present |
| 2 | Review `$request->validate(['agreement_ids' => 'required|array', 'agreement_ids.*' => 'required|numeric'])` | Validation |
| 3 | Review `VndAgreementItem::whereIn('id', $request->agreement_ids)->get()` — queries AGREEMENT ITEMS, not invoices | Wrong table (Known Issue KI-06) |
| 4 | Review PDF/ZIP generation logic | PDF generation |

#### TC-CR-VINV-21: printList() — Gate + query VndAgreementItem with relations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-invoice.print')` | Gate present |
| 2 | Review `VndAgreementItem::with(['agreement.vendor', 'item', 'invoices'])` | Eager loading |
| 3 | Review `when($request->agreement_ids, ...)` filter | Optional filter |

#### TC-CR-VINV-22: details() — Gate + switch on type param + return JSON HTML

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-invoice.view')` | Gate present |
| 2 | Review `switch ($request->type) { case 'invoice_detail': ... case 'agreement_item_detail': ... }` | Type switch |
| 3 | Review `VndInvoice::find($id)` (not findOrFail) for invoice detail | Null-safe find |
| 4 | Review JSON response: `return response()->json(['success' => true, 'html' => $html])` | JSON API |

#### TC-CR-VINV-23: sendMultipleEmails() — Gate + validate + dispatch job

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-invoice.email-schedule')` | Gate present |
| 2 | Review `$request->validate(['invoice_ids' => 'nullable|array'])` | Optional array |
| 3 | Review `SendVendorInvoiceEmailJob::dispatch($invoiceId)` for each invoice | Job dispatch |

#### TC-CR-VINV-24: VndInvoice Model — fillable (28 fields), casts, boot saving event

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$fillable` array — 28 fields (vendor_id through is_active) | All fillable financial fields |
| 2 | Review `$casts` — all date fields, all decimal, is_active/is_deleted to boolean | Casts configured |
| 3 | Review `boot()` — `saving` event that computes balance_due | Model event (conflicts with GENERATED column) |
| 4 | Review `getBalanceDueAttribute()` accessor — also computes net_payable - amount_paid | Accessor (triple definition) |
| 5 | Review `getIsPaidAttribute()` helper — checks if amount_paid >= net_payable | Is-paid helper |

#### TC-CR-VINV-25: VndInvoice Model — generated column conflict (DDL vs model boot vs accessor)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review DDL: `balance_due GENERATED ALWAYS AS (net_payable - amount_paid) STORED` | DB computed column |
| 2 | Review model `boot()`: `static::saving(function ($invoice) { $invoice->balance_due = ... })` | Model attempts to write to GENERATED column |
| 3 | Review `getBalanceDueAttribute()`: accessor also computes value | Accessor override |
| 4 | Note: Attempting to save model will write to balance_due — MySQL will reject write to generated column | **CRITICAL CONFLICT** |

#### TC-CR-VINV-26: VndInvoice Model — relationships

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `vendor()` — belongsTo Vendor::class | Vendor relationship |
| 2 | Review `payments()` — hasMany VndPayment::class | Payments relationship |
| 3 | Review `agreement()` — belongsTo VndAgreement::class | Agreement relationship |
| 4 | Review `agreementItem()` — belongsTo VndAgreementItem::class | Agreement item relationship |

#### TC-CR-VINV-27: VndInvoice Model — scopes and helpers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `scopeActive($query)` — where is_active = true | Active scope |
| 2 | Review `scopeInDateRange($query, $from, $to)` — whereBetween invoice_date | Date range scope |
| 3 | Review `getIsPaidAttribute()` — returns `$this->amount_paid >= $this->net_payable` | Is-paid check |

#### TC-CR-VINV-28: No activityLog() calls in entire controller

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search VendorInvoiceController for `activityLog(` | No calls found |
| 2 | Compare with other Vendor controllers (Vendor, Agreement, Item) which all call activityLog() | Inconsistent |
| 3 | Note: No audit trail for any invoice operation | Missing audit logging |

#### TC-CR-VINV-29: No FormRequest — all validation inline and inconsistent

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review all method signatures — none use FormRequest type hints | All use plain Request |
| 2 | Review validation coverage — some methods validate, some don't | Inconsistent |
| 3 | Note: No reusable validation rules — each method duplicates inline validation | Maintenance burden |

#### TC-CR-VINV-30: pdfMultiple queries VndAgreementItem not VndInvoice (wrong table)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review pdfMultiple() query: `VndAgreementItem::whereIn('id', ...)->get()` | Queries agreement items |
| 2 | Note: Parameter named `agreement_ids` but queries `VndAgreementItem` (agreement item IDs) | Name mismatch |
| 3 | Verify expected behaviour: should query VndInvoice for PDF generation | Wrong entity |

#### TC-CR-VINV-31: balance_due triple definition: GENERATED column + boot() event + accessor

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review DDL balance_due definition | GENERATED ALWAYS AS STORED |
| 2 | Review model boot() saving event | Writes to balance_due on every save |
| 3 | Review getBalanceDueAttribute() accessor | Computed on read |
| 4 | Note: The boot() event attempts to write to a generated column — will cause MySQL error on save | **Critical bug** |

#### TC-CR-VINV-32: Redirect consistency check — all methods redirect behaviour

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review generateSingle() redirect | Returns appropriate response |
| 2 | Review generateMultiple() redirect | Returns appropriate response |
| 3 | Review store() (payment) redirect | Redirect route |
| 4 | Review storeRemark() redirect | Redirect back |

### 10.4 Dependency TC Steps

#### TC-D-VINV-01: Vendor FK RESTRICT — cannot delete vendor with invoices

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor V1 has at least one invoice in vnd_invoices | Referenced vendor |
| 2 | Attempt to delete V1 from vnd_vendors | RESTRICT violation |
| 3 | Verify DB error: Cannot delete or update a parent row — FK constraint fails | Delete blocked |

#### TC-D-VINV-02: Agreement FK SET NULL — deleting agreement preserves invoice

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice has agreement_id=5 (references vnd_agreements) | Referenced agreement |
| 2 | Delete agreement ID 5 from vnd_agreements | Agreement deleted |
| 3 | Verify invoice.agreement_id = NULL (SET NULL) | FK set to null |
| 4 | Verify invoice still exists and all other fields intact | Invoice preserved |

#### TC-D-VINV-03: Agreement Item FK SET NULL — deleting item preserves invoice

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice has agreement_item_id=10 (references vnd_agreement_items_jnt) | Referenced item |
| 2 | Delete agreement item ID 10 from junction table | Item deleted |
| 3 | Verify invoice.agreement_item_id = NULL (SET NULL) | FK set to null |
| 4 | Verify invoice still exists | Invoice preserved |

#### TC-D-VINV-04: Status FK RESTRICT — cannot delete dropdown status referenced by invoices

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Status D1 is used as invoice.status in vnd_invoices | Referenced dropdown |
| 2 | Attempt to delete D1 from sys_dropdown_table | RESTRICT violation |
| 3 | Verify DB error: Cannot delete or update a parent row — FK constraint fails | Delete blocked |

#### TC-D-VINV-05: UNIQUE KEY — same vendor cannot have duplicate invoice_number

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice exists with vendor_id=1, invoice_number='INV-20260101120000123' | Existing invoice |
| 2 | Attempt to create another invoice for vendor_id=1 with same invoice_number | Duplicate |
| 3 | Verify UNIQUE constraint violation on uq_vnd_invoice_no | Insert blocked |

#### TC-D-VINV-06: UNIQUE KEY — different vendors can have same invoice_number

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice exists for vendor_id=1 with invoice_number='INV-20260101120000123' | Vendor 1 invoice |
| 2 | Create invoice for vendor_id=2 with same invoice_number | Different vendor |
| 3 | Verify creation succeeds (UNIQUE is on vendor_id + invoice_number composite) | Both allowed |

#### TC-D-VINV-07: Generate invoice requires VndUsageLog records for qty aggregation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | VndAgreementItem with PER_UNIT billing | Item configured |
| 2 | No VndUsageLog records exist for this vendor+item | No usage data |
| 3 | Generate invoice | qty_used=0, min_guarantee applied |
| 4 | Create VndUsageLog records and regenerate for new period | Usage now aggregated |

#### TC-D-VINV-08: Generate invoice requires sys_dropdown_table entry for Pending status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure sys_dropdown_table has entry: type='vnd_invoices.status', name='Pending' | Status exists |
| 2 | Generate invoice | Status set to Pending ID |
| 3 | Remove Pending entry from sys_dropdown_table | Missing status |
| 4 | Generate another invoice | getPendingStatusId() returns null |

#### TC-D-VINV-09: store() (payment create) depends on existing invoice in vnd_invoices

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No invoice with ID=X exists | Non-existent invoice |
| 2 | POST store() with invoice_id=X | Validation passes (numeric check only) |
| 3 | VndPayment created with invoice_id=X — FK constraint violated at DB level | DB error |

#### TC-D-VINV-10: GENERATED column balance_due — verify MySQL version compatibility

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check MySQL version: `SELECT VERSION()` | Requires MySQL 5.7+ for generated columns |
| 2 | Verify `balance_due` column definition in migration | GENERATED ALWAYS AS (net_payable - amount_paid) STORED |
| 3 | Verify generated column is not writable | Column is read-only from DB perspective |

#### TC-D-VINV-11: VndPayment table FK constraint depends on vnd_invoices.id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice I1 has payments in vnd_payments | Referenced invoice |
| 2 | Verify VndPayment FK constraint on invoice_id | FK exists |
| 3 | Note: Cascade behaviour depends on vnd_payments FK definition | Check FK on payments table |

#### TC-D-VINV-12: SoftDeletes — verified deleted_at column exists in vnd_invoices

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check database schema: `DESCRIBE vnd_invoices;` | deleted_at column exists (TIMESTAMP NULL) |
| 2 | Verify VndInvoice model uses SoftDeletes trait | Trait imported |

#### TC-D-VINV-13: sendMultipleEmails depends on queue worker and mail configuration

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify queue connection configured (database, redis, sync) | Queue config |
| 2 | Verify mail driver configured (smtp, mailgun, log) | Mail config |
| 3 | Verify SendVendorInvoiceEmailJob class exists and implements ShouldQueue | Job class |

#### TC-D-VINV-14: pdfMultiple requires PDF library and ZIP extension

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify PDF generation library (barryvdh/laravel-dompdf or similar) installed | Composer dependency |
| 2 | Verify PHP ZipArchive extension available | php-zip extension |
| 3 | Verify ZIP file generation logic produces valid archive | ZIP creation |

---

## 11. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|--------|-----|------|-------------------|---------------------|
| GET | `/vendor-invoice` | vendor-invoice.index | index() | tenant.vendor-invoice.viewAny |
| GET | `/vendor-invoice/create` | vendor-invoice.create | create() | tenant.vendor-invoice.create |
| POST | `/vendor-invoice` | vendor-invoice.store | store() (creates PAYMENT, not invoice!) | tenant.vendor-invoice.create |
| GET | `/vendor-invoice/{vendor_invoice}` | vendor-invoice.show | show() | tenant.vendor-invoice.view |
| GET | `/vendor-invoice/{vendor_invoice}/edit` | vendor-invoice.edit | edit() | tenant.vendor-invoice.update |
| PUT/PATCH | `/vendor-invoice/{vendor_invoice}` | vendor-invoice.update | update() (STUB) | tenant.vendor-invoice.update |
| DELETE | `/vendor-invoice/{vendor_invoice}` | vendor-invoice.destroy | destroy() (STUB) | tenant.vendor-invoice.delete |
| GET | `/vendor-invoice/trash/view` | vendor-invoice.trashed | **MISSING** — no controller method | N/A (will 500) |
| GET/POST | `/vendor-invoice/{id}/restore` | vendor-invoice.restore | **MISSING** — no controller method | N/A (will 500) |
| DELETE | `/vendor-invoice/{id}/force-delete` | vendor-invoice.forceDelete | **MISSING** — no controller method | N/A (will 500) |
| POST | `/vendor-invoice/{id}/toggle-status` | vendor-invoice.toggleStatus | toggleStatus() | tenant.vendor-invoice.status |
| POST | `/vendor-invoice/generate` | vendor-invoice.generateSingle | generateSingle() | tenant.vendor-invoice.create |
| POST | `/vendor-invoice/generate-multiple` | vendor-invoice.generateMultiple | generateMultiple() | tenant.vendor-invoice.create |
| POST | `/invoice/remark` | vendor-invoice.storeRemark | storeRemark() | tenant.vendor-invoice.remark |
| POST | `/vendor-invoice/pdf-multiple` | vendor-invoice.pdfMultiple | pdfMultiple() | tenant.vendor-invoice.pdf |
| GET | `/vendor/invoice/print` | vendor-invoice.printList | printList() | tenant.vendor-invoice.print |
| GET | `/vendor/invoice/details` | vendor-invoice.details | details() | tenant.vendor-invoice.view |
| POST | `/invoice/email/multiple` | vendor-invoice.sendMultipleEmails | sendMultipleEmails() | tenant.vendor-invoice.email-schedule |

---

## 12. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-01 | store() is MISNAMED — creates payments, not invoices | **High** | The `store()` method on `POST /vendor-invoice` does NOT create invoices. It creates `VndPayment` records. The name suggests invoice creation but the logic handles payment recording. This is extremely misleading for maintainers. |
| KI-02 | update() is a STUB — validates only amount field, no actual update | **High** | The `update()` method only validates `amount` as required|numeric and redirects. No invoice fields are actually updated. Any PUT request to update an invoice silently discards all data. |
| KI-03 | destroy() is a STUB — no actual delete logic | **High** | The `destroy()` method has no delete logic at all. No `findOrFail`, no `->delete()`, no SoftDeletes call. Simply redirects. Invoices can never be deleted through this route. |
| KI-04 | balance_due is BOTH a GENERATED column AND computed in model — CONFLICT | **Critical** | The DDL defines `balance_due` as `GENERATED ALWAYS AS (net_payable - amount_paid) STORED` (read-only from DB). However, the model's `boot()` saving event ALSO sets `$this->balance_due = ...` which tries to WRITE to the generated column. Any save/update to VndInvoice will fail with MySQL error: "Cannot update generated column". |
| KI-05 | pdfMultiple queries VndAgreementItem not VndInvoice | **High** | The `pdfMultiple()` method queries `VndAgreementItem::whereIn('id', $agreementIds)` instead of `VndInvoice`. The parameter is named `agreement_ids` but it actually queries the `vnd_agreement_items_jnt` table. PDFs are generated based on agreement items, not invoices — wrong entity. |
| KI-06 | invoice_number uses rand(100,999) — collision risk under high concurrency | **Medium** | `generateInvoice()` creates invoice numbers as `'INV-' . now()->format('YmdHis') . rand(100,999)`. If two users generate invoices in the same second AND get the same rand value, the UNIQUE KEY constraint `uq_vnd_invoice_no` throws an integrity violation. No retry/lock mechanism exists. |
| KI-07 | toggleStatus toggles BOTH invoice AND linked agreement_item is_active | **Medium** | `toggleStatus()` updates `is_active` on the VndInvoice AND also calls `$invoice->agreementItem->update(['is_active' => $isActive])`. Toggling an invoice's status unexpectedly modifies the linked agreement item's status — a potentially destructive side effect. |
| KI-08 | No FormRequest — all validation is inline and inconsistent | **Medium** | No FormRequest classes exist. Each method has its own ad-hoc `$request->validate()` call with different rules. Some methods (destroy, update-stub) have minimal or no validation. No reusable validation rules exist. |
| KI-09 | No activityLog() calls — missing audit trail | **High** | Every other Vendor controller (Vendor, Agreement, Item, Usage Log) calls `activityLog()` for audit trail on CRUD operations. VendorInvoiceController has ZERO activityLog() calls. No audit trail for any invoice generation, payment creation, status toggle, or remark update. |
| KI-10 | printList queries VndAgreementItem not VndInvoice | **Medium** | `printList()` queries `VndAgreementItem::with(['agreement.vendor', 'item', 'invoices'])` — this is an agreement item list, not an invoice list. For a feature called "invoice print", it should query VndInvoice records. The filter param is also `agreement_ids` not `invoice_ids`. |

---

## 13. Feature Summary Matrix

| Feature | Controller Method(s) | Key Models | Pagination |
|---------|---------------------|------------|------------|
| Invoice List (View) | index() | VndInvoice | None (view only) |
| Create Invoice (View) | create() | VndInvoice | None (form) |
| View Invoice Detail | show() | VndInvoice + Vendor + Agreement + AgreementItem + Payments | None |
| Edit Invoice (View) | edit() | VndInvoice | None (form) |
| Update Invoice | update() (STUB) | — | None (no-op) |
| Delete Invoice | destroy() (STUB) | — | None (no-op) |
| Toggle Invoice Status | toggleStatus() | VndInvoice, VndAgreementItem | None (AJAX) |
| Generate Single Invoice | generateSingle(), generateInvoice() (private) | VndAgreementItem, VndAgreement, Vendor, VndUsageLog, VndInvoice | None |
| Generate Multiple Invoices | generateMultiple(), generateInvoice() (private) | VndAgreementItem, VndAgreement, Vendor, VndUsageLog, VndInvoice | None |
| Update Invoice Remarks | storeRemark() | VndInvoice | None |
| Create Payment (Misnamed) | store() | VndPayment, VndInvoice | None |
| Generate PDF ZIP | pdfMultiple() | VndAgreementItem (wrong table) | None |
| Print Invoice List | printList() | VndAgreementItem (wrong table) | None |
| Invoice Details API | details() | VndInvoice, VndAgreementItem | None |
| Schedule Invoice Email | sendMultipleEmails() | VndInvoice, SendVendorInvoiceEmailJob | None |
| Pending Status Lookup | getPendingStatusId() (private) | sys_dropdown_table | None |
| FIXED Billing Calculation | generateInvoice() (private) | VndAgreementItem | N/A (calculation) |
| PER_UNIT Billing Calculation | generateInvoice() (private) | VndAgreementItem, VndUsageLog | N/A (calculation) |
| HYBRID Billing Calculation | generateInvoice() (private) | VndAgreementItem, VndUsageLog | N/A (calculation) |
| Tax Calculation (4 taxes) | generateInvoice() (private) | VndAgreementItem | N/A (calculation) |
| Duplicate Invoice Prevention | generateInvoice() (private) | VndInvoice | N/A (validation) |

---

## 14. Billing Calculation Reference

### 14.1 Billing Model Formulas

| Model | Formula | Components | Notes |
|-------|---------|------------|-------|
| FIXED | `net_payable = fixed_charge` | fixed_charge from VndAgreementItem | qty_used recorded but not used in calculation |
| PER_UNIT | `net_payable = max(qty_used, min_guarantee_qty) * unit_rate` | qty_used from VndUsageLog sum, min_guarantee_qty and unit_rate from VndAgreementItem | Min guarantee ensures minimum billing |
| HYBRID | `net_payable = fixed_charge + (max(qty_used, min_guarantee_qty) * unit_rate)` | fixed_charge + per-unit component | Combines both models |

### 14.2 Tax and Final Calculation

| Step | Calculation | Notes |
|------|------------|-------|
| 1 | `base_amount` from billing model (above) | Depends on billing_model |
| 2 | `total_tax_percent = tax1 + tax2 + tax3 + tax4` | Sum of 4 tax rates from VndAgreementItem |
| 3 | `tax_total = base_amount * (total_tax_percent / 100)` | Tax on base amount |
| 4 | `sub_total = base_amount` | Sub-total equals base amount |
| 5 | `net_payable = sub_total + tax_total + other_charges - discount_amount` | Final payable (before payments) |
| 6 | `amount_paid = 0` (initially) | Updated by payment reconciliation |
| 7 | `balance_due = net_payable - amount_paid` | GENERATED column (DB computed) |

### 14.3 Usage Quantity Aggregation

```
SELECT COALESCE(SUM(qty_used), 0)
FROM vnd_usage_logs
WHERE vendor_id = ? AND agreement_item_id = ?
  AND usage_date BETWEEN ? AND ?
```

- Returns 0 if no usage logs found for the vendor + agreement item + date range
- `COALESCE` handles NULL sum when no records match

### 14.4 Duplicate Prevention Query

```
SELECT EXISTS(
  SELECT 1 FROM vnd_invoices
  WHERE agreement_item_id = ?
    AND billing_start_date = ?
    AND billing_end_date = ?
)
```

- Blocks generation if same agreement_item + same billing period already invoiced
- Check performed BEFORE invoice creation

---

## 15. VndInvoice Model Reference

### 15.1 Fillable Fields (28)

`vendor_id`, `agreement_id`, `agreement_item_id`, `item_description`, `invoice_number`, `invoice_date`, `billing_start_date`, `billing_end_date`, `fixed_charge_amt`, `unit_charge_amt`, `qty_used`, `unit_rate`, `min_guarantee_qty`, `tax1_percent`, `tax2_percent`, `tax3_percent`, `tax4_percent`, `sub_total`, `tax_total`, `other_charges`, `discount_amount`, `net_payable`, `amount_paid`, `due_date`, `status`, `remarks`, `is_active`, `is_deleted`

### 15.2 Casts

| Field | Cast Type |
|-------|-----------|
| invoice_date, billing_start_date, billing_end_date, due_date | date |
| fixed_charge_amt, unit_charge_amt, qty_used, unit_rate, min_guarantee_qty | decimal:2 |
| tax1_percent, tax2_percent, tax3_percent, tax4_percent | decimal:2 |
| sub_total, tax_total, other_charges, discount_amount, net_payable, amount_paid, balance_due | decimal:2 |
| is_active, is_deleted | boolean |

### 15.3 Mutators / Accessors

- `getBalanceDueAttribute()` — computes `$this->net_payable - $this->amount_paid` (accessor override)
- `getIsPaidAttribute()` — returns `$this->amount_paid >= $this->net_payable`
- `boot()` saving event — sets `$this->balance_due = $this->net_payable - $this->amount_paid` (conflicts with GENERATED column)

### 15.4 Scopes

- `scopeActive($query)` — `$query->where('is_active', true)`
- `scopeInDateRange($query, $from, $to)` — `$query->whereBetween('invoice_date', [$from, $to])`

### 15.5 Relationships

- `vendor()` — belongsTo `Vendor::class`
- `payments()` — hasMany `VndPayment::class`
- `agreement()` — belongsTo `VndAgreement::class`
- `agreementItem()` — belongsTo `VndAgreementItem::class`
- `statusDropdown()` — belongsTo `Dropdown::class` (for status FK)

---

## 16. VendorInvoiceController Method Inventory (605 lines)

| Method | Visibility | Lines (est.) | Has Gate | Has Validation | Logic Completeness |
|--------|-----------|-------------|----------|---------------|-------------------|
| index() | public | ~5 | Yes | No | Complete (returns view) |
| create() | public | ~5 | Yes | No | Complete (returns view) |
| store() | public | ~25 | Yes | Yes (inline) | Misnamed — creates Payment |
| show($id) | public | ~10 | Yes | No | Complete |
| edit($id) | public | ~10 | Yes | No | Complete |
| update(Request, $id) | public | ~10 | Yes | Yes (amount only) | **STUB** — no update logic |
| destroy($id) | public | ~5 | Yes | No | **STUB** — no delete logic |
| toggleStatus(Request, $id) | public | ~20 | Yes | Yes (inline) | Complete + side effect |
| generateSingle(Request) | public | ~20 | Yes | Yes (inline) | Complete |
| generateMultiple(Request) | public | ~15 | Yes | Yes (inline) | Complete |
| generateInvoice(...) | private | ~100 | No (private) | No (internal) | Core billing engine |
| getPendingStatusId() | private | ~10 | No (private) | No (internal) | Complete (lookup) |
| storeRemark(Request) | public | ~15 | Yes | Yes (inline) | Complete |
| pdfMultiple(Request) | public | ~25 | Yes | Yes (inline) | Wrong table (VndAgreementItem) |
| printList(Request) | public | ~15 | Yes | No | Wrong table (VndAgreementItem) |
| details(Request) | public | ~25 | Yes | No | Complete |
| sendMultipleEmails(Request) | public | ~15 | Yes | Yes (inline) | Complete |
| **trashed()** | **MISSING** | — | — | — | **Missing — route returns 500** |
| **restore($id)** | **MISSING** | — | — | — | **Missing — route returns 500** |
| **forceDelete($id)** | **MISSING** | — | — | — | **Missing — route returns 500** |

---
