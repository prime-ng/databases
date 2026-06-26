# Invoice Generation — Requirements

## What It Does
Core billing engine that generates invoices for tenant subscription billing schedule records. Cross-queries the tenant's isolated database to count active students, applies plan rates, minimum billing quantities, discounts, extra charges, and up to four configurable tax lines (CGST, SGST, IGST, Custom). Creates invoice records, module junction entries, and audit log entries atomically. Operates on `prime_db` and serves Super Admins.

## Database Fields

**bil_tenant_invoices**

| Field | Type | Conditions |
|---|---|---|
| `id` | INT UNSIGNED PK | Auto-increment |
| `tenant_id` | INT UNSIGNED FK → `prm_tenant` | Required. CASCADE on delete. |
| `tenant_plan_id` | INT UNSIGNED FK → `prm_tenant_plan_jnt` | Required. CASCADE on delete. |
| `billing_cycle_id` | SMALLINT UNSIGNED FK → `prm_billing_cycles` | Required. RESTRICT on delete. |
| `invoice_no` | VARCHAR(50) | Required. UNIQUE. Auto-format: `INV-YYYYMMDD-NNN`. |
| `invoice_date` | DATE | Required. Date of generation. |
| `billing_start_date` | DATE | Required. Period start. |
| `billing_end_date` | DATE | Required. Period end. |
| `min_billing_qty` | INT UNSIGNED | Required. Default 1. Floor for billing quantity. |
| `total_user_qty` | INT UNSIGNED | Required. Default 1. Actual active students from tenant DB. |
| `plan_rate` | DECIMAL(12,2) | Required. Rate from TenantPlanRate. |
| `billing_qty` | INT UNSIGNED | Required. Default 1. `max(min_billing_qty, total_user_qty)`. |
| `sub_total` | DECIMAL(14,2) | Required. Default 0.00. `plan_rate × billing_qty`. |
| `discount_percent` | DECIMAL(5,2) | Required. Default 0.00. |
| `discount_amount` | DECIMAL(12,2) | Required. Default 0.00. |
| `discount_remark` | VARCHAR(50) | Nullable. |
| `extra_charges` | DECIMAL(12,2) | Required. Default 0.00. Add-on charges. |
| `charges_remark` | VARCHAR(50) | Nullable. |
| `tax1_percent` | DECIMAL(5,2) | Required. Default 0.00. CGST or custom. |
| `tax1_remark` | VARCHAR(50) | Nullable. e.g. "CGST" |
| `tax1_amount` | DECIMAL(12,2) | Required. Default 0.00. |
| `tax2_percent` | DECIMAL(5,2) | Required. Default 0.00. SGST or custom. |
| `tax2_remark` | VARCHAR(50) | Nullable. |
| `tax2_amount` | DECIMAL(12,2) | Required. Default 0.00. |
| `tax3_percent` | DECIMAL(5,2) | Required. Default 0.00. IGST or custom. |
| `tax3_remark` | VARCHAR(50) | Nullable. |
| `tax3_amount` | DECIMAL(12,2) | Required. Default 0.00. |
| `tax4_percent` | DECIMAL(5,2) | Required. Default 0.00. Custom tax. |
| `tax4_remark` | VARCHAR(50) | Nullable. |
| `tax4_amount` | DECIMAL(12,2) | Required. Default 0.00. |
| `total_tax_amount` | DECIMAL(12,2) | Required. Default 0.00. Sum of all tax amounts. |
| `net_payable_amount` | DECIMAL(12,2) | Required. Default 0.00. `sub_total − discount + extra_charges + total_tax`. |
| `paid_amount` | DECIMAL(14,2) | Required. Default 0.00. Cumulative payments. |
| `currency` | CHAR(3) | Required. Default 'INR'. ISO 4217. |
| `status` | VARCHAR(20) | Required. Dropdown key: `bil_tenant_invoices.status.invoice_status`. Values: PENDING, PARTIALLY_PAID, PAID, OVERDUE, CANCELLED. |
| `credit_days` | SMALLINT UNSIGNED | Required. Days until payment due. |
| `payment_due_date` | DATE | Required. `invoice_date + credit_days`. |
| `is_recurring` | BOOLEAN | Default true. |
| `auto_renew` | BOOLEAN | Default true. |
| `remarks` | TEXT | Nullable. |
| `created_by` | INT UNSIGNED FK → `sys_users` | Nullable. Missing from current DDL. |
| `deleted_at` | TIMESTAMP | Nullable. Missing from current DDL. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

**bil_tenant_invoicing_modules_jnt**

| Field | Type | Conditions |
|---|---|---|
| `id` | INT UNSIGNED PK | Auto-increment |
| `tenant_invoice_id` | INT UNSIGNED FK → `bil_tenant_invoices` | Required. CASCADE on delete. |
| `module_id` | INT UNSIGNED FK → `glb_modules` | Nullable. SET NULL on delete. |
| `is_active` | BOOLEAN | Required. Default 1. Missing from current DDL. |
| `created_by` | INT UNSIGNED FK → `sys_users` | Nullable. Missing from current DDL. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. Missing from current DDL. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

## Business Rules

**Invoice Number Auto-Generation**
- Format: `INV-YYYYMMDD-NNN` (e.g., `INV-20260326-001`)
- `NNN` = count of invoices created today + 1, zero-padded to 3 digits
- Lock-guarded at the application level to prevent duplicates

**Billing Quantity Calculation**
- `total_user_qty` is counted from the tenant's isolated database via `Tenancy::initialize()`
- Query: `Student::where('is_active', true)->count()`
- `billing_qty = max(min_billing_qty, total_user_qty)`
- After counting, `Tenancy::end()` MUST be called to prevent context leak

**Financial Calculations**
- `sub_total = plan_rate × billing_qty`
- `tax_base = sub_total − discount_amount + extra_charges`
- Each tax line: `tax_amount = tax_base × (tax_percent / 100)`
- `total_tax_amount = tax1_amount + tax2_amount + tax3_amount + tax4_amount`
- `net_payable_amount = sub_total − discount_amount + extra_charges + total_tax_amount`

**Payment Due Date**
- `payment_due_date = invoice_date + credit_days`
- `credit_days` comes from `TenantPlanRate.credit_days`

**One-Time Invoice Constraint**
- A billing schedule entry can only be invoiced once
- `prm_tenant_plan_billing_schedule.bill_generated` flag is set to 1 after generation
- Only records with `bill_generated = 0` appear in the "Inv. Need To Generate" filter

**Currency Default**
- All invoices default to INR (₹)
- `currency` is a CHAR(3) ISO 4217 code

**Status Lifecycle**
- Initial status on creation: PENDING (via dropdown ordinal selection)
- Transition: PENDING → PARTIALLY_PAID (on partial payment)
- Transition: PENDING/ PARTIALLY_PAID → PAID (on full payment)
- Transition: PENDING → OVERDUE (payment_due_date passed, no automated detection)
- Transition: PENDING → CANCELLED (no dedicated cancel endpoint)

**Atomic Generation**
- Invoice generation is wrapped in `DB::transaction()`
- Creates: `bil_tenant_invoices` row, module junction rows, GENERATED audit log entry
- Updates: `prm_tenant_plan_billing_schedule.bill_generated = 1`
- All or nothing — any failure rolls back the entire generation

**Invoice View AJAX**
- Invoice details are loaded via AJAX endpoint returning JSON `{html: string}`
- Details include: invoice metadata, subscription period, plan rate, billing qty, discounts, taxes, totals, payment status

## Filter System Architecture

The invoicing tab uses a centralized filter engine in `BillingManagementController` with 6 specialized query builders, each handling different filter parameters based on the active tab.

### Common Filter Mechanism
- All filters are stored in `$this->filters` array extracted from the request via `$request->only([...])`
- Filters are passed to the view and re-populated in the filter form for persistence
- Filters work entirely via GET query string parameters — no session storage
- A shared `parseDateRange()` method handles the `date_range` parameter format: `"YYYY-MM-DD - YYYY-MM-DD"` (with space-dash-space separator)

### Filter Parameters

| Parameter | Used By Tab | Type | Behavior |
|---|---|---|---|
| `type` | All | Tab selector | Routes to the appropriate query builder: `invoicing` (default), `subscription_data`, `invoice_payment`, `consolidated-payment`, `payment-reconcilation`, `audit-note` |
| `date_range` | All | String | Split on ` - ` delimiter → parsed as `$startDate` (startOfDay) and `$endDate` (endOfDay). Defaults to today if empty. |
| `data_type` | Invoicing | Select | `"Inv. Need To Generate"` → filters by `schedule_billing_date` range AND `bill_generated = 0`. `"Invoicing Done"` → filters by `bill_generated = 1` AND invoice date range. Empty → default date range on schedule_billing_date. |
| `status` | Invoicing, Subscription | Select | For invoicing: filters `is_active` on the billing schedule table (1=Active, 0=Inactive). For subscription: filters tenant plan status (`ACTIVE`/`INACTIVE`). Supports multiple value formats (1, 'ACTIVE', 'active'). |
| `invoice_status` | Invoicing | Select | Only applies when `data_type = "Invoicing Done"`. Filters the generated invoice's `status` column (PENDING, PARTIALLY_PAID, PAID, etc.). |
| `payment_status` | Invoice Payment | Select | Filters `BilTenantInvoice.status` column. |
| `tenat_id` | Consolidated Payment, Audit Log | Select | Filters by `tenant_id` on invoice or invoice relationship. NOTE: typo in parameter name (`tenat_id` not `tenant_id`). |
| `payment_reconcilation_status` | Payment Reconciliation | Select | `"Reconciled Transactions Only"` → `payment_reconciled = 1`. `"Non-Reconciled Trans. Only"` → `payment_reconciled = 0`. |
| `performed_by` | Audit Log | Select | Filters `InvoicingAuditLog.performed_by` by user ID. |
| `audit_status` | Audit Log | Select | Filters `InvoicingAuditLog.action_type` (GENERATED, Partially Paid, Notice Sent, etc.). |
| `search` | Email Schedule | Text | Searches `invoice_no` (LIKE) and tenant `name` (LIKE). |
| `status` (email) | Email Schedule | Select | Filters `BillTenatEmailSchedule.status` (pending, sent, failed, cancelled). |

### Query Builder Dispatch Flow

```
index(Request $request)
  ├── parseDateRange($request)
  ├── $this->filters = $request->only([...9 params...])
  │
  ├── type = "subscription_data"     → buildSubscriptionQuery()     → paginate(10)
  ├── type = "invoice_payment"       → buildInvoicePaymentQuery()   → paginate(10)
  ├── type = "consolidated-payment"  → buildConsolidatedPaymentQuery() → paginate(10)
  ├── type = "payment-reconcilation" → buildPaymentReconciliationQuery() → paginate(10)
  ├── type = "audit-note"            → buildAuditLogQuery()         → paginate(10)
  └── default (invoicing)            → buildMainBillingQuery()      → paginate(10)
```

### buildMainBillingQuery() — Detailed Logic

This is the most complex query builder, handling three distinct modes:

**Mode 1: "Inv. Need To Generate" (`data_type = "Inv. Need To Generate"`)**
- Base: `TenantPlanBillingSchedule` with plan/tenant/invoice relationships
- Date filter: `schedule_billing_date BETWEEN startDate AND endDate`
- Status filter (optional): filters by tenant plan status (Active/Inactive)
- Shows only schedule records where `bill_generated = 0` (not yet invoiced)

**Mode 2: "Invoicing Done" (`data_type = "Invoicing Done"`)**
- Same base query
- Filters: `bill_generated = 1` AND `generatedInvoice.invoice_date BETWEEN startDate AND endDate`
- Invoice status filter (optional): filters by `generatedInvoice.status` via whereHas
- Shows schedule records that have already been invoiced

**Mode 3: Default (no data_type)**
- Same base query
- Date filter: `schedule_billing_date BETWEEN startDate AND endDate`
- Shows all schedule records within the date range regardless of billing status

All modes are paginated at 10 records per page and pass the `$filters` array to the view for form re-population.

### Performance Issues with Filters
- `Tenant::get()` and `User::get()` are called on EVERY index() load (lines 118-119) — loads ALL tenants and ALL users without pagination or filtering. This is a known N+1 performance issue.
- Date range defaults to today if not provided, which may return empty results unexpectedly
- Filter values are validated only by presence checks (`!empty()`) — no type or format validation

## CRUD Operations

**Generate Invoice**
- Route: `POST /billing/billing-management` with `ids[]` array of schedule IDs
- Trigger: Admin selects billing schedule records on the Invoicing tab and clicks generate
- Preconditions: `prime.billing-management.create` permission; schedule not already billed
- Processing loop: For each ID → find schedule → find TenantPlanRate → Tenancy::initialize → count students → calculate → create invoice → set bill_generated → insert modules → create audit log
- Output: JSON `{status: true, success_ids: [], failed_ids: [{id, reason}]}`
- Transaction: Full `DB::transaction()` wrapping all steps for each invoice

**List Invoices**
- Route: `GET /billing/billing-management` with `type=invoicing` (default tab)
- Filter parameters: data_type (Inv. Need To Generate, Generated), invoice_status, date_range, tenant_id
- Paginated 10 per page
- Shows checkboxes for bulk actions (generate, email, PDF download)

**View Invoice Details (AJAX)**
- Route: `GET /billing/invoice-details?id={invoice_id}`
- Returns JSON with rendered HTML partial showing all invoice fields
- Includes: subscription details, module list, payment history, audit log entries

**Invoice Remarks**
- View: `GET /billing/invoice/remarks?id=&type=`
- Update: `POST /billing/invoice/remarks/update`
- Stores arbitrary text notes on the invoice

**Print Invoice**
- Route: `GET /billing/billing-management/print/data?type=default`
- DomPDF-generated A4 invoice suitable for legal use

## Permissions

| Operation | Permission Key |
|---|---|
| View invoicing tab | `prime.billing-management.viewAny` |
| Generate invoice | `prime.billing-management.create` |
| Download invoice PDF | `prime.billing-management.pdf` |
| View invoice details | `prime.billing-management.view` |
| Update invoice remarks | `prime.billing-management.update` |
