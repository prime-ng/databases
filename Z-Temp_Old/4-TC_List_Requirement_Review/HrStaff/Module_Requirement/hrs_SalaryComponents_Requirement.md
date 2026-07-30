# Salary Components — Business Requirements

## What This Screen Does

The Salary Components screen allows the school to define the individual building blocks of a salary structure. Each component represents a specific earning, deduction, or employer contribution — such as Basic Pay, House Rent Allowance, Provident Fund, or Professional Tax. Components have a type, calculation method, default value, and taxability flag. They are combined into salary structures to compute an employee's monthly pay.

---

## When This Screen Is Used

- Salary Structure Design when assembling the components that make up a pay package
- Payroll Configuration when defining how each component is calculated (fixed amount, percentage of basic, percentage of gross, statutory, or manual)
- Tax Planning when setting which components are taxable for TDS computation
- Statutory Compliance when configuring mandatory components like PF, ESI, PT, and TDS
- Payslip Layout when ordering components for display on the payslip

## Default Data Load

The screen is loaded via `HrMenuController@hrMasters()` at route `GET /hr-masters` with tab parameter `tab=salary-components`. The controller loads components from `SalaryComponent::orderBy('display_order')->orderBy('name')`, filtered by search and type when the active tab is `salary-components`.

Separately, `SalaryComponentController@index()` at `GET /salary-components` provides a standalone paginated view with 20 records per page, searchable by `name` or `code`, and filterable by `component_type`.

---

## Key Fields at a Glance

**Component Identity**
Each component has a unique code (e.g., BASIC, HRA, PF_EMP) and a descriptive name. The code is used internally by the payroll computation engine to identify and calculate each component.

**Component Classification**
The Component Type categorizes the component as an Earning (adds to gross salary), Deduction (subtracted from gross), or Employer Contribution (part of CTC but not paid to employee). The Calculation Type determines how the amount is computed: Fixed (flat amount), Percentage of Basic, Percentage of Gross, Statutory (computed at payroll time under government rules), or Manual (entered manually each month).

**Computation Details**
The Default Value stores either a fixed INR amount or a percentage value depending on the calculation type. For example, HRA at 25% of Basic would store 25.0000. The Display Order controls the sequence in which components appear on the payslip. The Is Taxable flag determines whether the component contributes to the employee's projected annual income for TDS computation.

**Statutory Controls**
The Is Statutory flag marks components governed by government regulations. Statutory components have restricted fields — their code, component type, and calculation type cannot be modified after creation. They also cannot be deleted.

---

## Business Rules and Conditions

**Unique Code Enforcement**
Every component must have a unique code. The system enforces this with a database unique index. On update, the current record's code is excluded from the uniqueness check.

**Statutory Component Immutability**
Statutory components (PF, ESI, PT, TDS) have restricted editability. Their `code`, `component_type`, and `calculation_type` fields cannot be modified after creation. Attempting to change these fields returns an error.

**Statutory Component Deletion Blocked**
Statutory components cannot be deleted. The controller checks `is_statutory` and returns an error if true.

**Active Structure Reference Guard**
A component cannot be deleted if it is used in any active salary structure. The controller checks `structureComponents()->where('is_active', true)->exists()` and blocks deletion with an error message.

**Component Type Scopes**
The model provides `scopeEarnings()`, `scopeDeductions()`, and `scopeEmployerContributions()` for filtered queries.

---

## Workflow Steps

**Creating a Salary Component**
The HR Manager navigates to HR Masters → Salary Components, clicks Add, enters the code (HRA), name (House Rent Allowance), selects type Earning, calculation type Percentage of Basic, enters default value 25.0000, sets display order 2, marks it as taxable and non-statutory, and saves.

**Editing a Non-Statutory Component**
The HR Manager edits the display order or default value of a non-statutory component. All fields are editable.

**Editing a Statutory Component**
The HR Manager attempts to change the code of a statutory PF component. The system rejects the change with an error message for the restricted field.

---

## Example Scenario

A school configures 14 salary components covering all earnings (Basic, DA, HRA, Conveyance, Medical Allowance, LTA, Special Allowance), deductions (PF Employee, ESI Employee, PT, TDS, LWP Deduction), and employer contributions (PF Employer, ESI Employer). The HR Manager marks PF_EMP and ESI_EMP as statutory and ensures their codes remain immutable after initial setup.

---

## Related Screens

- **Salary Structures** — Combines components into complete pay packages
- **Salary Assignment** — Assigns a structure with its components to an employee
- **Payslip Generation** — Components are computed and displayed on payslips

---

## Requirements

- Controller `SalaryComponentController`: `index()` paginated grid, filterable by search (name/code) and type; `store()` creates with validated + `created_by`/`updated_by`; `show()` loads with `structures` relationship; `edit()` loads edit form; `update()` validates statutory field immutability before updating; `toggleStatus()` flips `is_active` via JSON; `destroy()` guards on `is_statutory` and `structureComponents()->where('is_active', true)->exists()`, then soft-deletes; `trashed()` lists soft-deleted; `restore()` restores and sets `is_active=true`; `forceDelete()` permanently deletes
- Gate: `Gate::authorize('pay.structure.manage')` on all methods
- Route resource: `salary-components` with `except(['create'])`, plus custom `toggle-status`, `trashed`, `restore`, `force-delete`
- Validation `StoreSalaryComponentRequest`: `name` required, max:150; `code` required, max:30, unique on `pay_salary_components.code` ignoring current ID and null `deleted_at`; `component_type` required, in:earning,deduction,employer_contribution; `calculation_type` required, in:fixed,percentage_of_basic,percentage_of_gross,statutory,manual; `default_value` required, numeric, min:0; `is_taxable` required, boolean; `is_statutory` required, boolean; `display_order` required, integer, min:1, max:99; `is_active` required, boolean
- `prepareForValidation()`: casts `is_taxable` (default true), `is_statutory` (default false), `is_active` (default true) to boolean
- Model `SalaryComponent`: SoftDeletes, table `pay_salary_components`, `$fillable` = 12 fields, `$casts` = `default_value` decimal:4, `display_order` integer, `is_taxable` boolean, `is_statutory` boolean, `is_active` boolean; relationships: `structureComponents()` HasMany, `structures()` BelongsToMany via pivot with `sequence_order`, `calculation_formula`, `is_mandatory`, `is_active`; scopes: `active()`, `earnings()`, `deductions()`, `employerContributions()`
- Update guard on statutory: if `is_statutory`, checks `code`, `component_type`, `calculation_type` for changes — rejects with "Cannot modify {field} on statutory components."
- Delete guard 1: if `is_statutory` → "Cannot delete statutory components."
- Delete guard 2: if `structureComponents()->where('is_active', true)->exists()` → "Cannot delete component used in active salary structures."
- Activity logged via `activityLog()` on all state-changing operations
- Policy: `SalaryComponentPolicy` using `hrs.salary_component.manage` for all gates

## Who Can Access

| Gate/Permission | Methods | Notes |
|----------------|---------|-------|
| `pay.structure.manage` | All SalaryComponentController methods | Controller gate |
| `hrs.salary_component.manage` | Policy gates | Policy permission |
| Policy: `SalaryComponentPolicy` | All gates | Uses `hrs.salary_component.manage` |

## Logic Flow

1. **Page Load** — `HrMenuController@hrMasters()` loads tabbed view; `SalaryComponentController@index()` paginated at 20/page. Search by name/code, filter by component_type.
2. **Create** — `store()` validates via request. Booleans auto-cast in `prepareForValidation()`. Redirect to tab with success.
3. **Edit/Update** — `update()` first checks `is_statutory`. If true, verifies `code`, `component_type`, `calculation_type` are unchanged. If any restricted field changed, returns back with error. Otherwise updates with `updated_by`.
4. **Show** — `show()` eager-loads `structures` relationship.
5. **Status Toggle** — AJAX flip of `is_active`.
6. **Delete** — Two guards: `is_statutory` check first, then active structure component check. If both pass, sets `is_active=false`, soft-deletes.

## Validate Before Save

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `name` | required, string, max:150 | — |
| `code` | required, string, max:30, unique:pay_salary_components,code | The code has already been taken. |
| `component_type` | required, in:earning,deduction,employer_contribution | — |
| `calculation_type` | required, in:fixed,percentage_of_basic,percentage_of_gross,statutory,manual | — |
| `default_value` | required, numeric, min:0 | — |
| `is_taxable` | required, boolean | — |
| `is_statutory` | required, boolean | — |
| `display_order` | required, integer, min:1, max:99 | — |
| `is_active` | required, boolean | — |
| **Statutory code (controller)** | `code` unchanged for statutory | "Cannot modify code on statutory components." |
| **Statutory type (controller)** | `component_type` unchanged for statutory | "Cannot modify component type on statutory components." |
| **Statutory calc (controller)** | `calculation_type` unchanged for statutory | "Cannot modify calculation type on statutory components." |

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Duplicate code | "The code has already been taken." | Validation (code.unique) |
| Modify statutory code | "Cannot modify code on statutory components." | Controller check |
| Modify statutory type | "Cannot modify component type on statutory components." | Controller check |
| Modify statutory calculation | "Cannot modify calculation type on statutory components." | Controller check |
| Delete statutory component | "Cannot delete statutory components." | Controller check |
| Delete component in active structure | "Cannot delete component used in active salary structures." | Controller check |

## Success Scenarios

**SC-001 — Creating an Earning Component**
HR Manager creates HRA component with code HRA, type Earning, calculation Percentage of Basic, default value 25.0000, display order 2. System creates and redirects.

**SC-002 — Updating Display Order**
HR Manager changes display order from 5 to 3. System updates successfully.

**SC-003 — Toggling Component Inactive**
HR Manager disables a component via AJAX toggle. JSON success.

## Failure Scenarios

**FC-001 — Changing Statutory Component Code**
HR Manager tries to change code of PF_EMP from PF_EMP to PF. System rejects: "Cannot modify code on statutory components."

**FC-002 — Deleting Statutory Component**
HR Manager tries to delete PF_EMP. System rejects: "Cannot delete statutory components."

**FC-003 — Deleting Component Used in Active Structure**
HR Manager tries to delete BASIC which is part of an active structure. System rejects with appropriate error.

## Dependencies module and tables

| Dependency | Type | Details |
|-----------|------|---------|
| `pay_salary_structures` | Consumer | Components linked via junction table |
| `pay_salary_structure_components` | Child Table | `component_id` FK → blocks delete if active records exist |
| `pay_payroll_run_details` | Consumer | Component values computed during payroll |
| Activity Log | Consumer | `activityLog()` on CRUD |

**Table:** `pay_salary_components`

| Column | Type | Details |
|--------|------|---------|
| id | BIGINT UNSIGNED PK | Auto-increment |
| name | VARCHAR(150) | NOT NULL |
| code | VARCHAR(30) | NOT NULL, UNIQUE (uq_pay_comp_code) |
| component_type | ENUM('earning','deduction','employer_contribution') | NOT NULL |
| calculation_type | ENUM('fixed','percentage_of_basic','percentage_of_gross','statutory','manual') | NOT NULL |
| default_value | DECIMAL(10,4) | NOT NULL DEFAULT 0.0000 |
| is_taxable | TINYINT(1) | NOT NULL DEFAULT 1 |
| is_statutory | TINYINT(1) | NOT NULL DEFAULT 0 |
| display_order | TINYINT UNSIGNED | NOT NULL DEFAULT 99 |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| created_by | BIGINT UNSIGNED | NOT NULL |
| updated_by | BIGINT UNSIGNED | NOT NULL |
| created_at | TIMESTAMP | NULL |
| updated_at | TIMESTAMP | NULL |
| deleted_at | TIMESTAMP | NULL (soft delete) |
