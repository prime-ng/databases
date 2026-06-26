# Salary Structures — Requirements

## What It Does
Assembles salary components into a complete compensation structure. Maps component sequence, calculation formula overrides, and mandatory flags via a pivot table. Preview mode computes CTC breakdown. Structures are assigned to employees via SalaryAssignment. Supports applicability filtering by employee category.

Features:
- Component assembly with sequence ordering and pivot metadata
- Per-component formula override in the structure
- Mandatory/optional component toggling per structure
- CTC breakdown preview (AJAX)
- Employee category applicability filter
- Soft-delete with full restore/force-delete

## Database Fields

**pay_salary_structures**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `name` | VARCHAR(200) | Required. E.g., `Standard Teaching Staff`, `Contractual Staff`. |
| `description` | VARCHAR(500) | Nullable. Optional notes. |
| `applicable_to` | ENUM | `all`, `teaching`, `non_teaching`, `contractual`. |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

**pay_salary_structure_components** (Pivot)

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `structure_id` | BIGINT UNSIGNED FK → `pay_salary_structures` | Required. CASCADE on delete. |
| `component_id` | BIGINT UNSIGNED FK → `pay_salary_components` | Required. CASCADE on delete. |
| `sequence_order` | INTEGER | Required. Display/computation order. 1-99. |
| `calculation_formula` | VARCHAR(255) | Nullable. Override the component's default calculation type. E.g., `percentage_of_basic|50.00` means 50% of basic. |
| `is_mandatory` | BOOLEAN | Default true. Whether this component must always be included. |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

## Business Rules

**Component Assembly**
- A structure consists of at least one component (validated: `components` array min:1)
- Each component has a `sequence_order` (1-99) determining computation and display order
- Components are computed in sequence order (earnings first, then deductions)
- If a component's `is_mandatory = false`, it can be optionally excluded during assignment

**Calculation Formula Override**
- If `calculation_formula` is null, the component's default `calculation_type` and `default_value` are used
- If set, format: `{calculation_type}|{value}`. E.g., `percentage_of_basic|50.00`
- Override applies to ALL employees assigned to this structure
- Override does NOT change the component's global definition

**Employer Contribution Handling**
- `employer_contribution` type components are included in structure for CTC calculation
- They are NOT part of employee gross/net pay
- They ARE part of the total CTC shown in preview

**Preview AJAX**
- Accepts optional `ctc_amount` query parameter
- Computes full CTC breakdown: each component's value, total earnings, total deductions, employer costs, net pay
- Returns JSON for dynamic front-end display

**Applicability**
- `applicable_to` filters which employees can be assigned this structure
- An employee's category (teaching/non-teaching/contractual) must match
- `all` allows any employee

## CRUD Operations

**List Salary Structures**
- Table with name, applicable_to, component count, active status
- Click to expand component list

**Create Salary Structure**
- Component selection with drag-and-drop reordering for sequence
- Each component row: sequence, name, mandatory toggle, formula override (optional)

**Show / Edit / Update / Destroy**
- Editing components (adding/removing) shows CTC impact preview
- Cannot remove a component that is currently assigned to an employee

**Preview (AJAX)**
- Optional `ctc_amount` parameter to test different CTC levels
- Returns JSON breakdown: each component value, totals

**Toggle Active Status / Soft Delete / Restore / Force Delete**

## Permissions

| Operation | Permission Key |
|---|---|
| View / Manage salary structures | `hrs.salary_component.manage` |
| Create / Edit / Delete | `hrs.salary_component.manage` |
| Preview | `hrs.salary_component.manage` |
