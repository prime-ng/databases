# Billing Cycles — Requirements

## What It Does
Manages billing cycle types used to define billing frequency for tenant subscription plans. Supports MONTHLY, QUARTERLY, YEARLY, and ONE_TIME cycles with configurable month counts and recurring flags. Operates on `prime_db` (central database) and serves Super Admins managing subscription billing cycles.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | SMALLINT UNSIGNED PK | Auto-increment |
| `short_name` | VARCHAR(50) | Required. Must be unique. Values: MONTHLY, QUARTERLY, YEARLY, ONE_TIME. |
| `name` | VARCHAR(50) | Required. Display name for the cycle. |
| `months_count` | TINYINT UNSIGNED | Required. Cycle length in months (1-255). |
| `description` | VARCHAR(255) | Nullable. |
| `is_recurring` | BOOLEAN | Default true. Whether cycle auto-renews. |
| `is_active` | BOOLEAN | Default true. Controls availability for assignment. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

## Business Rules

**Unique Short Name**
- `short_name` must be globally unique across all billing cycles
- Uniqueness is validated at the application level, ignoring the current record during updates

**Cycle Length**
- `months_count` minimum is 1, maximum is 255
- Standard values: MONTHLY=1, QUARTERLY=3, YEARLY=12, ONE_TIME=0 or NULL

**Soft Delete Behavior**
- Before soft delete, `is_active` is set to `false`
- Force delete is blocked if any FK references exist (catch Throwable pattern)
- Soft-deleted records are visible in the trash view

**Status Toggle**
- Active/inactive state can be toggled via AJAX POST
- Returns JSON with the new state

**Cross-Module Reference**
- `prm_billing_cycles` table is used by Prime module (`TenantPlanRate`, `TenantPlanBillingSchedule`, `BilTenantInvoice`, `Plan` models)
- Changes to billing cycles affect invoice generation and subscription pricing

## CRUD Operations

**Create**
- Route: `GET /billing/billing-cycle/create` → form
- Submit: `POST /billing/billing-cycle` → validates via BillingCycleRequest → creates record → writes sys_activity_logs → redirects to sales-plan-mgmt#billing
- On success: redirect with flash message confirming creation

**List**
- Route: `/billing/billing-cycle` 
- Shows paginated table with columns: short_name, name, months_count, description, is_active, is_recurring, Actions
- Each row has view, edit, delete, toggle-status actions
- Paginated with standard Laravel pagination

**View**
- Route: `GET /billing/billing-cycle/{billingCycle}`
- Shows full billing cycle details with relationships loaded
- Breadcrumb navigation: Billing Cycle List → View

**Edit**
- Route: `GET /billing/billing-cycle/{billingCycle}/edit` → pre-filled form
- Submit: `PUT /billing/billing-cycle/{billingCycle}` → validates via BillingCycleRequest → updates → logs activity → redirects to sales-plan-mgmt#billing

**Delete (Soft)**
- Route: `DELETE /billing/billing-cycle/{billingCycle}`
- Triggered via SweetAlert2 confirmation popup
- Pre-delete: sets `is_active = false`
- Records a "Deleted" activity log entry

**Restore**
- Route: `GET /billing/billing-cycle/{billingCycle}/restore`
- Trash page: `GET /billing/billing-cycle/trash/view` — lists soft-deleted records with pagination
- Records a "Restored" activity log entry

**Force Delete**
- Route: `DELETE /billing/billing-cycle/{billingCycle}/force-delete`
- Only available for soft-deleted records
- Wrapped in try/catch — FK violation caught and returned as error

**Toggle Status**
- Route: `POST /billing/billing-cycle/{billingCycle}/toggle-status`
- AJAX endpoint
- Returns JSON: `{success: true, is_active: bool, message: string}`

## Permissions

| Operation | Permission Key |
|---|---|
| View billing cycles tab | `prime.billing-cycle.viewAny` |
| View cycle details | `prime.billing-cycle.view` |
| Create billing cycle | `prime.billing-cycle.create` |
| Update billing cycle | `prime.billing-cycle.update` |
| Delete billing cycle | `prime.billing-cycle.delete` |
| Restore billing cycle | `prime.billing-cycle.restore` |
| Force delete billing cycle | `prime.billing-cycle.forceDelete` |
