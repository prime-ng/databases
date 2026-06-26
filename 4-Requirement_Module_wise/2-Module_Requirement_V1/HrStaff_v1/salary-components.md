# Salary Components — Requirements

## What It Does
Defines the building blocks of salary structures. Each component has a type (earning, deduction, employer_contribution), calculation method (fixed, percentage of basic, percentage of gross, statutory, manual), and default value. Components are assembled into salary structures via a pivot table with sequence ordering and mandatory flags.

Features:
- 3 component types: earning, deduction, employer contribution
- 5 calculation methods for flexible salary computation
- Component toggling between structures (optional vs mandatory)
- Sequence order for payslip display
- Taxable flag for TDS computation
- Statutory flag for automatic inclusion in compliance registers
- 99-level display ordering
- Soft-delete with full restore/force-delete

## Database Fields

**pay_salary_components**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `name` | VARCHAR(150) | Required. E.g., `Basic Salary`, `HRA`, `DA`, `PF`, `ESI`. |
| `code` | VARCHAR(30) | Required. UNIQUE. Short code: `BASIC`, `HRA`, `DA`, `PF_EMP`, `ESI_EMP`. |
| `component_type` | ENUM | `earning`, `deduction`, `employer_contribution`. |
| `calculation_type` | ENUM | `fixed`, `percentage_of_basic`, `percentage_of_gross`, `statutory`, `manual`. |
| `default_value` | DECIMAL(10,4) | Required. Default value or percentage (e.g., `40.0000` for 40% of basic). Cast to 4 decimals. |
| `is_taxable` | BOOLEAN | Default true. Whether this component is subject to TDS. |
| `is_statutory` | BOOLEAN | Default false. Whether this is a statutory component (PF/ESI/PT). |
| `display_order` | INTEGER | 1-99. Order on payslip. Lower = appears first. |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

## Business Rules

**Component Type Behavior**
- `earning`: Adds to gross salary. Examples: Basic, HRA, DA, Conveyance, Medical Allowance.
- `deduction`: Subtracts from gross salary. Examples: PF (employee share), ESI (employee share), PT, TDS, Loan Recovery.
- `employer_contribution`: Employer's additional cost. Examples: PF (employer share), ESI (employer share), Gratuity, Insurance. Shown on CTC computation but not part of employee gross/net.

**Calculation Method Behavior**
- `fixed`: `default_value` is the absolute amount in currency. E.g., Basic = 25000.00.
- `percentage_of_basic`: `default_value` is a percentage. Computed as `basic × (default_value / 100)`. E.g., HRA = 40% of Basic.
- `percentage_of_gross`: `default_value` is a percentage of gross (sum of all earnings). E.g., PF = 12% of gross.
- `statutory`: Calculated by statutory rules (PF ceiling, ESI threshold, PT slabs). `default_value` is ignored.
- `manual`: No automatic computation. Value is entered manually during payroll run or override.

**Code Uniqueness**
- `code` is unique across all salary components (including soft-deleted)
- Convention: uppercase snake_case. E.g., `BASIC`, `HRA`, `PF_EMP`, `ESI_EMP`, `PT`, `TDS`.

**Taxable vs Non-Taxable**
- `is_taxable = true`: Component is included in taxable income for TDS calculation
- `is_taxable = false`: Excluded from TDS calculation
- Example: Basic is taxable, HRA can be partially exempt with rent receipts

**Statutory Components**
- `is_statutory = true`: Automatically included in statutory compliance registers (PF, ESI, PT)
- These components are always mandatory in salary structures
- Cannot be removed from a structure if any employee has this component assigned
- Calculation method is typically `statutory`

**Display Order**
- 1-99 range
- Lower number = appears first on payslip
- Earnings first (1-49), then deductions (50-79), then employer contributions (80-99) by convention

## CRUD Operations

**List Salary Components**
- Filterable by: component type, calculation type, is_statutory
- Grouped/sorted by display_order
- Active/Inactive badge

**Create Salary Component**
- Code auto-suggested from name but manually editable

**Show / Edit / Update / Destroy**
- Code is immutable after creation

**Toggle Active Status**
- Inactive components cannot be added to new structures
- Existing structures with this component are unaffected

**Soft Delete / Restore / Force Delete**
- Component cannot be force-deleted if used in any salary structure

## Permissions

| Operation | Permission Key |
|---|---|
| View / Manage salary components | `hrs.salary_component.manage` |
| Create / Edit / Delete | `hrs.salary_component.manage` |
| Toggle status / Restore / Force delete | `hrs.salary_component.manage` |
