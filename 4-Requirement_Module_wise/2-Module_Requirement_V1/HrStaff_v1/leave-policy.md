# Leave Policy & Balances — Requirements

## What It Does
Configures global leave policy rules that apply across all leave types: backdated application limits, advance notice requirements, approval level configuration (1 or 2 levels), and optional holiday counting. Manages employee leave balances: initialization at academic year start with carry-forward, tracking of used days, LOP days, and available days computation.

Features:
- Singleton leave policy per academic year (or global default)
- 1 or 2 level approval workflow
- Backdated application validation (max N days)
- Advance notice requirement (min N days)
- Optional holiday allocation
- Annual balance initialization with carry-forward from prior year
- Balance adjustments with audit trail
- Computed available days = allocated + carry_forward - used
- Soft-delete with restore for balances

## Database Fields

**hrs_leave_policies**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `academic_year_id` | BIGINT UNSIGNED FK → `glb_academic_sessions` | Nullable. If null, acts as global default policy. |
| `max_backdated_days` | INTEGER | Default 0. Max days in the past an application can be submitted. Range 0-30. |
| `min_advance_days` | INTEGER | Default 0. Min days in advance an application must be submitted. Range 0-30. |
| `approval_levels` | INTEGER | 1 or 2. Number of approval levels required. |
| `optional_holiday_count` | INTEGER | Default 0. Number of optional holidays employees can choose. Range 0-10. |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

**hrs_leave_balances**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `employee_id` | BIGINT UNSIGNED FK → `sch_employees` | Required. CASCADE on delete. |
| `leave_type_id` | BIGINT UNSIGNED FK → `hrs_leave_types` | Required. CASCADE on delete. |
| `academic_year_id` | BIGINT UNSIGNED FK → `glb_academic_sessions` | Required. |
| `allocated_days` | DECIMAL(5,1) | Required. Days allocated for this year. Default 0.0. |
| `carry_forward_days` | DECIMAL(5,1) | Required. Days carried from prior year. Default 0.0. |
| `used_days` | DECIMAL(5,1) | Required. Days used so far. Default 0.0. |
| `lop_days` | DECIMAL(5,1) | Required. Loss of pay days. Default 0.0. |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

**hrs_leave_balance_adjustments**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `leave_balance_id` | BIGINT UNSIGNED FK → `hrs_leave_balances` | Required. CASCADE on delete. |
| `adjustment_days` | DECIMAL(4,1) | Required. Positive or negative adjustment. |
| `reason` | VARCHAR(255) | Required. Reason for the adjustment. |
| `adjusted_by` | BIGINT UNSIGNED FK → `sch_employees` | Who made the adjustment. |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

## Business Rules

**Policy Resolution Order**
1. Look for policy matching the employee's current `academic_year_id`
2. Fall back to global default policy (where `academic_year_id IS NULL`)
3. If no policy exists at all, default values are used (max_backdated=0, min_advance=0, approval_levels=1)

**Approval Level Behavior**
- Level 1: Direct manager / reporting head approves
- Level 2 (if enabled): Higher authority (principal / HR head) approves after level 1
- `approval_levels = 1`: Single approval workflow
- `approval_levels = 2`: Two-level approval — application moves from pending → pending_l2 → approved

**Backdated Application Rule**
- Leave application `from_date` cannot be more than `max_backdated_days` in the past
- A value of 0 means no backdated applications are allowed
- Example: max_backdated_days = 3 → can apply for leave starting up to 3 days ago

**Advance Notice Rule**
- Leave application must be submitted at least `min_advance_days` before `from_date`
- A value of 0 means same-day applications are allowed
- Example: min_advance_days = 2 → must apply at least 2 days before leave starts

**Balance Initialization (`initializeBalances`)**
- Called at the start of each academic year for all employees
- For each leave type: creates a LeaveBalance row with `allocated_days = leave_type.days_per_year`
- If prior year balance exists, `carry_forward_days = min(prior.available, leave_type.carry_forward_days)`
- If no prior year, carry_forward_days = 0
- Idempotent: if balance already exists for this employee + leave_type + year, skips

**Available Days Computation**
- `available_days = allocated_days + carry_forward_days - used_days - lop_days`
- Computed via model accessor `getAvailableDaysAttribute()`
- Used during leave application validation to ensure sufficient balance

**Balance Deduction on Leave Approval**
- On final approval (level 1 for single-level, level 2 for two-level): `used_days += application.days_count`
- On leave cancellation: `used_days -= application.days_count`
- On leave rejection: no balance impact

**Balance Adjustments**
- Manual adjustments via `LeaveService::adjustBalance()` create a `LeaveBalanceAdjustment` record
- Adjustments can be positive (add days) or negative (remove days)
- Each adjustment records: reason, adjusted_by, timestamp
- Adjustments are append-only — corrections are done via new adjustment, never by deleting old ones

## CRUD Operations

**Show Leave Policy**
- Displays current policy settings
- If no academic-year-specific policy exists, shows global default
- Dropdown to select academic year (optional)

**Update Leave Policy**
- Saves or updates policy for the selected academic year
- Creates a new row if none exists for that year

**View Leave Balances**
- Shows balance table: employee name, leave type, allocated, carry_forward, used, lop, available
- Filterable by employee, leave type, academic year
- Paginated

**Initialize Leave Balances**
- Batch initializes balances for all employees for the given academic year
- Can optionally specify a prior academic year for carry-forward calculation
- Idempotent: does not overwrite existing balances

**Trashed Balances**
- Shows soft-deleted leave balance records

**Restore Balance**
- Restores a soft-deleted balance

## Permissions

| Operation | Permission Key |
|---|---|
| View leave policy | `hrs.leave.balance.view` |
| Update leave policy | `hrs.employment.manage` |
| View all leave balances | `hrs.leave.balance.view` |
| Initialize leave balances | `hrs.employment.manage` |
| Restore trashed balances | `hrs.employment.manage` |
