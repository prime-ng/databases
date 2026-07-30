# Salary Structures — Business Requirements

## What This Screen Does

The Salary Structures screen allows the school to create and manage salary templates that combine multiple salary components into a complete pay package. Each structure defines which components belong to it, their computation sequence, and whether they are mandatory. Structures can be previewed against a hypothetical CTC to see a full earnings-deductions breakdown before assigning them to an employee.

---

## When This Screen Is Used

- Pay Package Design when the school defines salary templates for different staff categories (teaching, non-teaching, contractual)
- Employee Onboarding when assigning a salary structure to a new employee
- CTC Visualization when HR wants to preview how a given annual CTC breaks down into monthly earnings, deductions, and employer contributions
- Payroll Computation when the system references the structure to compute monthly payslips

## Default Data Load

The screen is loaded via `HrMenuController@hrMasters()` at route `GET /hr-masters` with tab parameter `tab=salary-structures`. The controller loads structures from `SalaryStructure::with('components')->orderBy('name')`, filtered by search when the active tab is `salary-structures`.

Separately, `SalaryStructureController@index()` at `GET /salary-structures` provides a standalone paginated view with 20 records per page, searchable by `name`, with `structureComponents` count (active only) via `withCount()`.

---

## Key Fields at a Glance

**Structure Identity**
The Structure Name is a descriptive label such as "Teaching Staff Structure". An optional Description provides additional context about when and for whom the structure is intended.

**Applicability**
The Applicable To setting restricts the structure to All, Teaching, Non-Teaching, or Contractual staff. This field controls which employees can be assigned this structure during salary assignment.

**Component Composition**
Each structure contains one or more salary components linked via a junction table. For each linked component, the system stores its Sequence Order (computation and display order), a Calculation Formula override (if different from the component's default), and an Is Mandatory flag (prevents removal from the structure).

**CTC Preview**
The preview feature allows HR to enter an annual CTC and see a full month-by-month breakdown of earnings, deductions, employer contributions, and net monthly pay, computed using each component's calculation type and default values.

---

## Business Rules and Conditions

**BASIC Component Required (BR-PAY-011)**
Every salary structure must include the BASIC component. The `SalaryStructureService` validates this in both `createStructure()` and `updateStructure()` by checking that at least one component has the code BASIC. If missing, a `DomainException` with message "Salary structure must include the BASIC component (BR-PAY-011)." is thrown.

**Component Uniqueness Within Structure**
The junction table enforces a unique constraint on `(structure_id, component_id)`, preventing the same component from being added twice to a structure.

**Mandatory Component Protection**
Components marked as `is_mandatory` on the junction record should not be removable from the structure (enforced at the UI level by the service's `syncComponents` behavior — the service soft-deletes existing records and recreates them via `updateOrCreate`).

**Active Assignment Guard**
A salary structure cannot be soft-deleted if it has active salary assignments (where `effective_to_date` is null). The controller checks `salaryAssignments()->where('effective_to_date', null)->exists()` and returns an error.

**Force-Delete Guard**
A salary structure cannot be force-deleted if it has any salary assignments, even historical ones. The controller checks `salaryAssignments()->withTrashed()->exists()` before permanent deletion.

**CTC Preview Validation**
The `preview()` controller requires a positive CTC value. If CTC is zero or negative, it returns a 422 error with message "CTC must be greater than zero."

---

## Workflow Steps

**Creating a Salary Structure**
The HR Manager navigates to HR Masters → Salary Structures, clicks Add, enters the name "Teaching Staff Structure", selects applicable to "Teaching", and adds components: BASIC (sequence 1, mandatory), DA (2), HRA (3, formula override at 20%), Conveyance (4), PF Employee (5, mandatory). The system validates BASIC presence, creates the structure, links all components, and redirects.

**Previewing CTC Breakdown**
The HR Manager opens a structure, clicks Preview, enters an annual CTC of ₹360,000. The system computes monthly breakdown using each component's calculation type and returns a JSON response with earnings (Basic 12,000, DA 6,000, HRA 3,000), deductions (PF 1,800), employer contributions (PF Employer 1,800), and net monthly pay.

---

## Example Scenario

A school designs two salary structures: one for teaching staff (Basic + DA + HRA + Conveyance + PF + ESI) and one for support staff (Basic + HRA + PT). When onboarding a new teacher with CTC ₹420,000, HR assigns the teaching structure. The system validates the CTC falls within the teacher's pay grade range and computes the monthly payslip breakdown.

---

## Related Screens

- **Salary Components** — Defines the individual components used in structures
- **Salary Assignment** — Assigns a structure to an employee with a specific CTC
- **Payroll Runs** — Computes payroll using assigned structures
- **Payslip Generation** — Renders individual component values on payslips

---

## Requirements

- Controller `SalaryStructureController`: `index()` loads paginated grid with `withCount('structureComponents')`; `store()` delegates to `SalaryStructureService@createStructure()`; `show()` loads with active components ordered by sequence + available components for preview; `edit()` loads with all components; `update()` delegates to `SalaryStructureService@updateStructure()`; `toggleStatus()` flips `is_active` via JSON; `preview()` AJAX endpoint validates CTC > 0 and returns breakdown; `destroy()` guards on active salary assignments, soft-deletes; `trashed()` lists soft-deleted; `restore()` restores and sets `is_active=true`; `forceDelete()` guards on any assignments (even historical), deletes junction records in transaction, then force-deletes
- Gate: `Gate::authorize('pay.structure.manage')` on all methods
- Route resource: `salary-structures` with `except(['create'])`, plus custom `toggle-status`, `trashed`, `restore`, `force-delete`, `preview`
- Validation `StoreSalaryStructureRequest`: `name` required, max:200; `description` nullable, max:500; `applicable_to` required, in:all,teaching,non_teaching,contractual; `is_active` required, boolean; `components` required, array, min:1; `components.*.component_id` required, exists:pay_salary_components,id; `components.*.sequence_order` required, integer, min:1, max:99; `components.*.calculation_formula` nullable, max:255; `components.*.is_mandatory` required, boolean
- `prepareForValidation()`: casts `is_active` boolean; normalizes `is_mandatory` in each component
- Service `SalaryStructureService`: `createStructure()` transaction creates structure + syncs components via `syncComponents()`, validates BASIC present; `updateStructure()` transaction updates structure + optionally syncs components, validates BASIC present if components provided; `syncComponents()` soft-deletes existing junction records via `is_active=false`, uses `updateOrCreate` to insert/update; `validateBasicPresent()` checks for component with code BASIC, throws `DomainException` if missing; `previewCtcBreakdown()` computes per-component amounts based on calculation types (fixed, percentage_of_basic, percentage_of_gross, statutory/manual = 0.0)
- Model `SalaryStructure`: SoftDeletes, table `pay_salary_structures`, `$fillable` = 6 fields, `$casts` = `is_active` boolean; relationships: `structureComponents()` HasMany, `components()` BelongsToMany via pivot, `salaryAssignments()` HasMany; scopes: `active()`
- Model `SalaryStructureComponent`: SoftDeletes, table `pay_salary_structure_components`, `$fillable` = 8 fields, `$casts` = `sequence_order` integer, `is_mandatory` boolean, `is_active` boolean; relationships: `structure()` BelongsTo, `component()` BelongsTo; scopes: `active()`
- Delete guard: `salaryAssignments()->where('effective_to_date', null)->exists()` → "Cannot delete structure with active salary assignments."
- Force-delete guard: `salaryAssignments()->withTrashed()->exists()` → "Cannot permanently delete salary structure. It is currently or historically assigned to employees."
- `forceDelete()` uses `DB::transaction` to cascade-delete junction records first, then structure; catches exceptions with generic integrity message
- Activity logged via `activityLog()` on all state-changing operations
- Policy: `SalaryStructurePolicy` using `pay.structure.manage` for all gates

## Who Can Access

| Gate/Permission | Methods | Notes |
|----------------|---------|-------|
| `pay.structure.manage` | All SalaryStructureController methods | Controller + policy gate |
| Policy: `SalaryStructurePolicy` | All gates | Uses `pay.structure.manage` |

## Logic Flow

1. **Page Load** — `HrMenuController@hrMasters()` loads tabbed view; `SalaryStructureController@index()` with `withCount`. Search by name.
2. **Create** — `store()` passes validated data to `SalaryStructureService@createStructure()`. Service validates BASIC component. Transaction: create structure, sync components via `updateOrCreate`. Catches `DomainException` for BASIC validation failure.
3. **Edit/Update** — `edit()` loads structure with components. `update()` passes to service. If components array provided, `syncComponents()` soft-deletes existing (sets `is_active=false`) and recreates.
4. **Show** — `show()` loads active components ordered by sequence + available active components for adding more. Structure ready for preview trigger.
5. **Preview** — `preview()` receives CTC via GET query param. Validates > 0. Calls `service.previewCtcBreakdown()`, returns JSON with earnings, deductions, employer contributions, totals, and net monthly.
6. **Status Toggle** — AJAX flip of `is_active`.
7. **Delete** — Checks active assignments. If none, sets `is_active=false`, soft-deletes.
8. **Force Delete** — Checks any assignments (withTrashed). If none, transaction deletes junction records first then structure. Catches DB exceptions.

## Validate Before Save

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `name` | required, string, max:200 | — |
| `description` | nullable, string, max:500 | — |
| `applicable_to` | required, in:all,teaching,non_teaching,contractual | — |
| `is_active` | required, boolean | — |
| `components` | required, array, min:1 | — |
| `components.*.component_id` | required, exists:pay_salary_components,id | — |
| `components.*.sequence_order` | required, integer, min:1, max:99 | — |
| `components.*.calculation_formula` | nullable, string, max:255 | — |
| `components.*.is_mandatory` | required, boolean | — |
| **BASIC present (service)** | Components must include BASIC code | "Salary structure must include the BASIC component (BR-PAY-011)." |

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Missing BASIC component | "Salary structure must include the BASIC component (BR-PAY-011)." | Service DomainException |
| No components provided | "The components field is required." / "The components must contain at least 1 items." | Validation |
| Invalid component_id | "The selected components.0.component_id is invalid." | Validation (exists) |
| Delete with active assignments | "Cannot delete structure with active salary assignments." | Controller check |
| Force-delete with historical assignments | "Cannot permanently delete salary structure. It is currently or historically assigned to employees." | Controller check |
| CTC zero or negative | "CTC must be greater than zero." | Controller 422 |
| Force-delete DB integrity failure | "Failed to permanently delete salary structure due to a database integrity constraint." | Controller catch |

## Success Scenarios

**SC-001 — Creating a Structure with BASIC**
HR Manager creates "Teaching Staff" structure with BASIC, DA, HRA, PF Employee components. BASIC validated present. Transaction creates structure + 4 junction records. Redirect with success.

**SC-002 — Previewing CTC Breakdown**
HR Manager previews ₹360,000 CTC on a structure. Service computes monthly: Basic 12,000, DA 48% of basic, HRA 25% of basic, etc. Returns JSON with earnings/deductions/net.

**SC-003 — Updating Structure Components**
HR Manager adds a new component to an existing structure. Service syncs: soft-deletes old junction records, creates new ones via updateOrCreate. Updated structure returned.

**SC-004 — Deleting Structure Without Assignments**
HR Manager deletes an unassigned structure. Soft-delete succeeds.

## Failure Scenarios

**FC-001 — Missing BASIC Component on Create**
HR Manager creates structure without BASIC. Service throws DomainException. Redirect back with error: "Salary structure must include the BASIC component (BR-PAY-011)."

**FC-002 — Delete Structure With Active Assignments**
HR Manager tries to delete a structure assigned to an employee with active `effective_to_date = null`. Controller returns error.

**FC-003 — Force-Delete Structure With Historical Assignments**
HR Manager tries to force-delete a structure that was historically assigned. Controller returns error.

**FC-004 — Invalid CTC for Preview**
User enters CTC of 0. Controller aborts with 422: "CTC must be greater than zero."

## Dependencies module and tables

| Dependency | Type | Details |
|-----------|------|---------|
| `pay_salary_components` | FK Table | `component_id` → `id` |
| `pay_salary_structure_components` | Junction Table | `(structure_id, component_id)` unique, FK CASCADE on both |
| `hrs_salary_assignments` | Child Table | `pay_salary_structure_id` FK → blocks delete if active |
| `pay_payroll_run_details` | Consumer | `salary_assignment_id` → structure used for payroll computation |
| `SalaryStructureService` | Service | Business logic for create, update, preview, BASIC validation |
| Activity Log | Consumer | `activityLog()` on CRUD |

**Table:** `pay_salary_structures`

| Column | Type | Details |
|--------|------|---------|
| id | BIGINT UNSIGNED PK | Auto-increment |
| name | VARCHAR(200) | NOT NULL |
| description | TEXT | NULL |
| applicable_to | ENUM('all','teaching','non_teaching','contractual') | NOT NULL DEFAULT 'all' |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| created_by | BIGINT UNSIGNED | NOT NULL |
| updated_by | BIGINT UNSIGNED | NOT NULL |
| created_at | TIMESTAMP | NULL |
| updated_at | TIMESTAMP | NULL |
| deleted_at | TIMESTAMP | NULL (soft delete) |

**Table:** `pay_salary_structure_components`

| Column | Type | Details |
|--------|------|---------|
| id | BIGINT UNSIGNED PK | Auto-increment |
| structure_id | BIGINT UNSIGNED FK | NOT NULL, FK → `pay_salary_structures.id` |
| component_id | BIGINT UNSIGNED FK | NOT NULL, FK → `pay_salary_components.id` |
| sequence_order | TINYINT UNSIGNED | NOT NULL DEFAULT 99 |
| calculation_formula | TEXT | NULL |
| is_mandatory | TINYINT(1) | NOT NULL DEFAULT 0 |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| created_by | BIGINT UNSIGNED | NOT NULL |
| updated_by | BIGINT UNSIGNED | NOT NULL |
| created_at | TIMESTAMP | NULL |
| updated_at | TIMESTAMP | NULL |
| deleted_at | TIMESTAMP | NULL (soft delete) |
