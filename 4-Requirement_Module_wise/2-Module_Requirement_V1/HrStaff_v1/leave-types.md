# Leave Types — Requirements

## What It Does
Defines the catalog of leave types available to employees. Each leave type has configurable properties: annual entitlement, carry-forward rules, gender restrictions, paid/unpaid flag, medical certificate requirements, and service eligibility. 15+ fields per leave type for granular policy control. Supports soft-delete with full restore/force-delete workflow.

Features:
- Unique alphanumeric leave code per type
- Configurable carry-forward days
- Gender-specific leave types (maternity, paternity)
- Half-day allowance
- Medical certificate threshold (days after which certificate is required)
- Minimum service months before eligibility
- Max consecutive days restriction
- Teaching / Non-Teaching / All applicability

## Database Fields

**hrs_leave_types**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `code` | VARCHAR(10) | Required. UNIQUE. Short code: `AL`, `SL`, `CL`, `ML`, `PL`, etc. |
| `name` | VARCHAR(100) | Required. Full name: `Annual Leave`, `Sick Leave`, etc. |
| `days_per_year` | DECIMAL(3,1) | Required. Annual entitlement. E.g., 18.0, 12.0, 6.0. Range 0-365. Cast to 1 decimal. |
| `carry_forward_days` | INTEGER | Default 0. Max days that can be carried to next year. Range 0-255. |
| `applicable_to` | ENUM | `all`, `teaching`, `non_teaching`. Defines which employee categories can use this leave. |
| `is_paid` | BOOLEAN | Default true. Whether leave is paid. |
| `requires_medical_cert` | BOOLEAN | Default false. Whether a medical certificate is required. |
| `medical_cert_threshold_days` | INTEGER | Nullable. If set, certificate is only required when leave exceeds this many days. E.g., 3 days for sick leave. |
| `half_day_allowed` | BOOLEAN | Default false. Whether the leave can be taken as half-day. |
| `gender_restriction` | ENUM | `all`, `male`, `female`. Default `all`. |
| `min_service_months` | INTEGER | Default 0. Months of service required before employee is eligible. Range 0-60. |
| `max_consecutive_days` | INTEGER | Nullable. Max days that can be taken in one stretch. E.g., 15 for annual leave. |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

## Business Rules

**Leave Code Uniqueness**
- `code` is unique across all leave types (including soft-deleted)
- Convention: 2-3 uppercase letters (AL = Annual Leave, SL = Sick Leave, CL = Casual Leave, ML = Maternity Leave, PL = Paternity Leave)

**Carry-Forward Calculation**
- At year-end, unused leave days up to `carry_forward_days` are added to the next year's balance
- Days exceeding the carry-forward limit are forfeited
- Leave types with `carry_forward_days = 0` are use-it-or-lose-it (no carry forward)

**Paid vs Unpaid**
- `is_paid = true`: salary is not deducted for this leave
- `is_paid = false`: salary is deducted (treated as leave without pay)
- Leave without pay type is separate from LOP (Loss of Pay) which is absenteeism

**Gender Restriction**
- `all`: any employee can use this leave
- `male`: only employees with male gender can apply
- `female`: only employees with female gender can apply
- Used for maternity leave (female), paternity leave (male)

**Medical Certificate Logic**
- If `requires_medical_cert = true` and `medical_cert_threshold_days` is null: certificate always required
- If `requires_medical_cert = true` and threshold is set: certificate only required when leave duration > threshold
- If `requires_medical_cert = false`: no certificate needed regardless of duration

**Service Eligibility**
- Employees with less than `min_service_months` of service cannot apply for this leave type
- Checked at application time by `LeaveService`

**Consecutive Days Limit**
- If set, the system prevents a single application from exceeding this limit
- Does NOT prevent back-to-back applications for different leave types

## CRUD Operations

**List Leave Types**
- Tabular view with all leave types, paginated
- Shows: code, name, days/year, carry forward, paid status, applicable to, gender restriction
- Active/Inactive badge column

**Create Leave Type**
- Code auto-suggested based on name but manually editable
- Gender restriction dropdown only shows when relevant
- Medical certificate fields hidden unless `requires_medical_cert` is toggled on

**Show Leave Type**
- Full detail view with all 15+ fields displayed read-only

**Edit Leave Type**
- Pre-filled form with current values
- Code field is read-only (immutable after creation)
- Changing `days_per_year` does NOT retroactively adjust existing balances

**Toggle Active Status**
- Toggles `is_active` between 1 and 0
- Inactive leave types cannot be used for new leave applications
- Existing applications for this type are unaffected

**Soft Delete (Trash)**
- Soft-deletes the record
- Existing leave balances and applications referencing this type are preserved (FK stays intact)

**Trashed List**
- Shows only soft-deleted leave types

**Restore**
- Restores the soft-deleted record

**Force Delete**
- Permanently removes the record
- Only allowed if no leave balances or applications reference this type

## Permissions

| Operation | Permission Key |
|---|---|
| View leave types | `hrs.leave_type.manage` |
| Create / Edit / Delete leave types | `hrs.leave_type.manage` |
| Toggle active status | `hrs.leave_type.manage` |
| Restore / Force delete | `hrs.leave_type.manage` |
