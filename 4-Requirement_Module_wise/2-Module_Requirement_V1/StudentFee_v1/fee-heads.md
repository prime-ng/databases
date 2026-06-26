# Fee Heads — Requirements

## What It Does
Defines the catalog of fee types (heads) that can be charged to students. Each head has a type (Tuition, Admission, Development, Exam, Lab, Library, Transport, Sports, Activity, Hostel), frequency (One-time, Monthly, Quarterly, Half-Yearly, Yearly), and optional tax configuration. Refundable flag controls whether amounts can be refunded on withdrawal.

Features:
- 10 standard fee heads with type classification
- 5 frequency options for billing cycles
- Per-head tax configuration (percentage, applicability toggle)
- Refundable flag for withdrawal scenarios
- Account head code for accounting integration
- Display order for fee structure arrangement
- Soft-delete with full restore/force-delete workflow

## Database Fields

**fee_head_masters**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `code` | VARCHAR(50) | Required. Unique short code: `TUITION`, `ADMISSION`, `DEVELOPMENT`, `EXAM`, `LAB`, `LIBRARY`, `TRANSPORT`, `SPORTS`, `ACTIVITY`, `HOSTEL`. |
| `name` | VARCHAR(200) | Required. Display name. |
| `description` | TEXT | Nullable. |
| `head_type_id` | BIGINT UNSIGNED FK → `sys_dropdowns` | Required. Classifies the head (tuition, admission, etc.). |
| `frequency` | ENUM | `One-time`, `Monthly`, `Quarterly`, `Half-Yearly`, `Yearly`. |
| `is_refundable` | BOOLEAN | Default false. Whether the fee can be refunded on withdrawal. |
| `tax_applicable` | BOOLEAN | Default false. Whether tax (GST) applies to this head. |
| `tax_percentage` | DECIMAL(5,2) | Default 0.00. Tax percentage if tax_applicable = true. |
| `account_head_code` | VARCHAR(50) | Nullable. Accounting integration code. |
| `display_order` | INTEGER | Default 0. Sort order in fee structures. |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

## Business Rules

**Tax Calculation**
- When `tax_applicable = true`: `tax_amount = amount × (tax_percentage / 100)`
- When `tax_applicable = false`: `tax_amount = 0` regardless of `tax_percentage` value
- The `calculateTax(float $amount)` helper method computes tax for a given amount
- The `calculateTotal(float $amount)` helper returns `amount + tax_amount`

**Frequency Behavior**
- `One-time`: Charged once (admission fee, development fee)
- `Monthly`: Charged every month (tuition fee)
- `Quarterly`: Charged every 3 months
- `Half-Yearly`: Charged every 6 months
- `Yearly`: Charged once per academic year

**Refundable Logic**
- `is_refundable = true`: Amount can be refunded via FeeRefund on student withdrawal
- `is_refundable = false`: Not eligible for refund
- Refund eligibility is computed at the head level, not per transaction

**Head Type Integration**
- `head_type_id` references `sys_dropdowns` for dynamic categorization
- Dropdown values: Tuition Fee, Admission Fee, Development Fee, Examination Fee, Laboratory Fee, Library Fee, Transport Fee, Sports Fee, Activity Fee, Hostel Fee

## CRUD Operations

**List Fee Heads**
- Configuration tab shows all heads in a sortable table
- Columns: code, name, type, frequency, refundable, taxable, display order, active status

**Create Fee Head**
- Authorization: `tenant.fee-head-master.create`
- Code auto-suggested from name but editable
- Head type dropdown from sys_dropdowns (tenant-specific)
- Tax section shown/hidden via `tax_applicable` toggle
- Activity logging on create

**Show / Edit / Update / Destroy**
- Code is immutable after creation
- Destroy: deactivates + soft deletes

**Toggle Active Status**
- Toggles `is_active` between 1 and 0
- Inactive heads hidden from fee structure dropdowns

**Soft Delete / Restore / Force Delete**


## Permissions

| Operation | Permission Key |
|---|---|
| View fee heads | `tenant.fee-head-master.viewAny` |
| View fee head details | `tenant.fee-head-master.view` |
| Create fee head | `tenant.fee-head-master.create` |
| Update fee head | `tenant.fee-head-master.update` |
| Delete fee head | `tenant.fee-head-master.delete` |
| Restore / Force delete | `tenant.fee-head-master.restore` / `forceDelete` |
| Toggle status | `tenant.fee-head-master.status` |
