# Cost Center — Business Requirements

## What This Screen Does

The Cost Center screen manages cost centers used for departmental or project-level cost tracking. Cost centers can be hierarchical (parent-child) and are referenced by vouchers and budgets to allocate expenses and track spending by department or project.

## When This Screen Is Used

- **During accounting setup** when configuring departmental cost tracking.
- **When adding new cost centers** for new departments, projects, or divisions.
- **When restructuring the cost center hierarchy.**

## Key Fields

- **Name** (string 100) — Cost center display name
- **Code** (string 20) — Short identifier, unique
- **Parent** (FK → self, nullable) — Parent cost center for hierarchy
- **Is Active** (boolean)
- **Created By** (FK → sys_users, nullable)

## Business Rules

**Self-Referencing Hierarchy:**
A cost center's parent is another cost center via `parent_id` FK to the same table. A cost center cannot be its own parent.

**Unique Code:**
Cost center code must be unique (enforced by UNIQUE key composite with deleted_at).

**Delete Guard:**
No delete guard implemented — a cost center can be deleted even if it has child cost centers or is referenced by vouchers/budgets. This creates orphan risk.

**Soft Delete:**
Uses SoftDeletes. Trash view, restore, and forceDelete routes available.

**Status Toggle:**
Ajax endpoint `toggleStatus()` flips `is_active`.

## Workflow

1. User navigates to Accounting → Setup Masters → Cost Center.
2. Table shows hierarchical list with Name, Code, Parent, Active toggle, Actions.
3. User creates with name, code, optional parent.
4. No restrictions on deletion — even cost centers with children or in-use can be deleted.

## Requirements

- MUST display at `/accounting/cost-center?tab=cost-centers` as paginated table
- MUST authorize via `tenant.accounting.cost-center.*` policy gates
- MUST support self-referencing parent-child hierarchy
- MUST enforce unique code
- MUST support is_active toggle via Ajax
- MUST support soft delete with trash view, restore, forceDelete
- **SHOULD** add delete guard for cost centers with child cost centers
- **SHOULD** add delete guard for cost centers referenced by vouchers or budgets
