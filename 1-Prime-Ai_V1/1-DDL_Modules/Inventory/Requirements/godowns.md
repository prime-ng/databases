# Godowns (Storage Locations) — Requirements

## Parent Tab: Masters

## What It Does
Manages storage location master records with a self-referencing hierarchy (parent-child godown structure). Each godown represents a physical or logical storage location where stock is held. Godowns have an assigned in-charge employee, address information, and support multi-level hierarchy. The system is seeded with 5 system godowns (Main Store, Sub Store 1, Sub Store 2, Raw Material Store, Finished Goods Store).

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment. |
| `name` | VARCHAR(100) | Required. Godown display name (e.g., Main Store). |
| `code` | VARCHAR(20) | Nullable. Unique. Short code (MAIN, RM, FG). |
| `parent_id` | BIGINT UNSIGNED | Nullable. Self-referencing FK to `inv_godowns.id`. ON DELETE SET NULL. |
| `address` | VARCHAR(500) | Nullable. Physical address of the storage location. |
| `in_charge_employee_id` | INT UNSIGNED | Nullable. FK to `sch_employees.id`. ON DELETE SET NULL. |
| `is_system` | TINYINT(1) | Default 0. 1 = seeded godown, cannot delete. |
| `is_active` | TINYINT(1) | Default 1. |
| `created_by` | BIGINT UNSIGNED | Required. FK to `sys_users.id`. |
| `updated_by` | BIGINT UNSIGNED | Required. FK to `sys_users.id`. |
| `created_at` | TIMESTAMP | Nullable. Laravel standard. |
| `updated_at` | TIMESTAMP | Nullable. Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |

## Business Rules

### Field-Level Validation

| Field | Rule | Error Message / Behavior |
|---|---|---|
| `name` | Required, string, max:100 | "The name field is required." / "Godown name must not exceed 100 characters." |
| `code` | Nullable, string, max:20, unique across all godowns (including soft-deleted) | "The code has already been taken." — checked at application level since DB UNIQUE is nullable and MySQL allows multiple NULLs |
| `parent_id` | Nullable, integer, exists:inv_godowns,id | "The selected parent godown is invalid." Must reference an existing godown. Cannot self-reference (parent_id cannot equal id). Cannot set parent_id to a descendant (circular reference check). |
| `address` | Nullable, string, max:500 | "Address must not exceed 500 characters." Truncated to 500 if longer. |
| `in_charge_employee_id` | Nullable, integer, exists:sch_employees,id | "The selected in-charge employee is invalid." Must reference an existing employee record. If employee is deleted, FK constraint sets this to NULL automatically (ON DELETE SET NULL — note: FK is commented out in DDL, must be enforced at application level until uncommented). |
| `is_system` | Read-only after create | Never accepted from user input. Only set by seeder. Cannot be changed to 0 for system-seeded records. |

### Parent-Child Hierarchy Rules

**Maximum Depth Enforcement:**
- The godown tree supports a maximum depth of 4 levels (Root → Sub-Godown → Sub-Sub-Godown → Sub-Sub-Sub-Godown).
- Calculated from the root ancestor (where parent_id IS NULL). If adding or moving a godown would exceed depth 4, the operation is rejected: "Godown hierarchy cannot exceed 4 levels."
- This depth limit ensures that stock balance lookups remain performant.

**Circular Reference Prevention:**
- Before updating `parent_id`, the system must verify that the new parent is not the godown itself and is not a descendant of the godown.
- Algorithm: starting from the new parent_id, follow parent_id chain upwards. If the current godown's id is encountered at any point, reject: "Circular reference detected. A godown cannot be its own ancestor."
- This check is performed using a recursive CTE or iterative query in the service layer.

**Root Godowns:**
- A root godown has `parent_id IS NULL`.
- Only root godowns can be defined as `is_system = 1`.

**Orphan Handling:**
- When a parent godown is soft-deleted, its children's `parent_id` is set to NULL (ON DELETE SET NULL).
- When a parent godown is restored, children are NOT automatically re-attached.
- Orphaned godowns (parent_id IS NULL) are displayed at the root level in tree views.

### Code Uniqueness Rules

- `code` is optional (nullable). Multiple godowns can have NULL code.
- If code is provided, it must be unique across ALL godowns (including soft-deleted).
- Uniqueness is enforced via DB UNIQUE KEY `uq_inv_gdn_code` on `code` column.
- Since MySQL UNIQUE allows multiple NULL values, multiple godowns with NULL code are permitted.
- Code, when provided, should be short and meaningful (e.g., 'MAIN' for Main Store, 'RM' for Raw Material Store, 'FG' for Finished Goods Store).
- Code cannot be changed to a value that conflicts with an existing code (including soft-deleted records): "The code has already been taken."
- Code can be changed from a value to NULL without restriction.

### Employee Reference for Godown In-Charge

- `in_charge_employee_id` is optional. When set, it identifies the employee responsible for this godown.
- The referenced employee must exist in `sch_employees` at the time of assignment.
- One employee can be in charge of multiple godowns (no unique constraint).
- Display: when viewing a godown, show the employee's full name (from sch_employees) alongside a link to the employee profile.
- If the referenced employee is deleted/terminated, the FK (when uncommented) sets this to NULL automatically. At the application level, a scheduled job or event listener should also handle this: "The in-charge employee for godown {name} has been removed as the employee record was deleted."

### System Godown Protection

- The `is_system` flag is set to 1 by the database seeder for 5 predefined godowns.
- System godowns cannot be soft-deleted: "System-seeded godowns cannot be deleted."
- System godowns cannot be force-deleted: "System-seeded godowns cannot be permanently deleted."
- System godowns' `is_active` can be toggled off, but they remain visible in the list with a "System" badge.
- `code` and `name` of system godowns should ideally not be editable, but if editable, changes should be logged with extra audit detail.

### Deletion Guard — Active Stock Balances

- Before soft-deleting or force-deleting a godown, the system checks:
  - `SELECT COUNT(*) FROM inv_stock_balances WHERE godown_id = {id} AND current_qty != 0 AND deleted_at IS NULL`
- If count > 0, delete is rejected: "Cannot delete godown with non-zero stock balances. Transfer stock to another godown first."
- This check applies to both regular and force-delete operations.

### Deletion Guard — Pending GRNs / Issues

- Before soft-deleting or force-deleting a godown, additional checks:
  - `SELECT COUNT(*) FROM inv_purchase_orders WHERE godown_id = {id} AND status IN ('draft','sent','partial') AND deleted_at IS NULL` (if PO has a godown field at header level, or check through GRN tables)
  - `SELECT COUNT(*) FROM inv_issue_requests WHERE godown_id = {id} AND status IN ('submitted','approved','partial') AND deleted_at IS NULL`
- If pending transactions exist, delete is rejected: "Cannot delete godown with pending purchase orders or issue requests. Complete or cancel them first."
- Note: These checks assume godown_id exists on transaction headers. If godown is at line level, adjust queries accordingly.

### Soft Delete & Restore

**Soft Delete (`DELETE /inventory/godowns/{id}` triggered via controller destroy()):**
1. Pre-delete check 1: `is_system` must be 0. If 1, return error: "System-seeded godowns cannot be deleted."
2. Pre-delete check 2: `SELECT SUM(current_qty) FROM inv_stock_balances WHERE godown_id = {id} AND deleted_at IS NULL` — must be 0 (or all null/zero). If > 0, return error: "Cannot delete godown with non-zero stock balances. Transfer stock to another godown first."
3. Pre-delete check 3: pending transactions check as described above.
4. Pre-delete action: automatically sets `is_active = 0` (deactivated).
5. The godown record gets `deleted_at` timestamp set.
6. The godown record remains in the database (soft-deleted).
7. Children godowns have their `parent_id` set to NULL by the FK constraint (ON DELETE SET NULL). Children are NOT soft-deleted.
8. An audit log entry is created: action = "delete", entity_type = "inv_godowns", entity_id = {id}.
9. An activity log entry is created: message = "A godown was deactivated and soft-deleted."
10. After successful deletion, redirect to route('inventory.godowns.index') with flash message flash('trashed.godown').

**Restore (`GET /inventory/godowns/{id}/restore`):**
1. Only works on soft-deleted records (uses onlyTrashed() query scope).
2. Sets `deleted_at` to NULL.
3. Does NOT automatically set `is_active` back to 1 (remains 0 after restore).
4. An audit log entry is created: action = "restore", entity_type = "inv_godowns", entity_id = {id}.
5. After successful restore, redirect to route('inventory.godowns.trashed') with flash message flash('restored.godown').

**Force Delete (`DELETE /inventory/godowns/{id}/force-delete`):**
1. Only available on already soft-deleted records (uses withTrashed() query scope).
2. Pre-delete check 1: `is_system` must be 0.
3. Pre-delete check 2: `SELECT SUM(current_qty) FROM inv_stock_balances WHERE godown_id = {id}` — must be 0 (including soft-deleted balances).
4. Pre-delete check 3: child godowns count must be 0. Query: `SELECT COUNT(*) FROM inv_godowns WHERE parent_id = {id}` — if > 0, return error: "Cannot permanently delete godown with child godowns."
5. The record is permanently removed from the database.
6. Related stock_balances records are cascade-deleted (FK constraint).
7. An audit log entry is created: action = "force_delete", entity_type = "inv_godowns", entity_id = {id}.
8. After successful force delete, redirect to route('inventory.godowns.trashed') with flash message flash('force_deleted.godown').

**Trash Page (`GET /inventory/godowns/trash/view`):**
- Lists only soft-deleted records (uses onlyTrashed() scope).
- Paginated 15 per page.
- Shows columns: Name, Code, Deleted At, Actions (Restore, Force Delete).
- Restore and Force Delete actions are permission-gated.

### Status Toggle

- Route: `POST /inventory/godowns/{godown}/toggle-status`.
- AJAX endpoint accepting JSON or form data.
- Toggles `is_active` between 0 and 1.
- Pre-toggle check if toggling from 1 to 0 (deactivating): same pre-checks as soft delete (stock balances, pending transactions). If any fail, return JSON error: `{"success": false, "message": "Cannot deactivate godown with non-zero stock balances or pending transactions."}`.
- On success, returns JSON: `{"success": true, "is_active": bool, "message": "Status updated successfully."}`.
- An audit log entry is created on toggle.

### Audit Trail

- Every create, update, soft delete, restore, force delete, and toggle-status action logs to `inv_audit_log`.
- GodownAuditService::log() is called with: entity_type = "inv_godowns", entity_id = {id}, action = {action_type}.
- The global activityLog() helper is also called for each mutation.
- On update: detect changed fields via `$model->getChanges()` (excluding updated_at, updated_by), log old/new values.
- Changes to `in_charge_employee_id` are specifically logged with employee name resolution for clarity.

### List View

- Controller: GodownController@index. Gate: 'tenant.inventory.godowns.viewAny'.
- Pagination: 20 records per page via `->paginate(20)`.
- Default sort: by `name` ascending.
- Eager loads: parent relationship (name), inChargeEmployee (full name).
- Columns displayed:
  1. Name (with hierarchy indentation — CSS padding-left based on depth level, with a folder icon).
  2. Code (badge-styled if present, grey "—" if null).
  3. Parent (parent godown name, or "—" if root).
  4. Address (truncated to 50 chars with ellipsis, full text on hover/tooltip).
  5. In-Charge (employee name, or "—" if not assigned).
  6. System (green "System" badge if is_system=1, hidden otherwise).
  7. Status (active/inactive badge).
  8. Actions (View, Edit, Delete buttons).
- Filter: search by name or code (text input, submitted on enter or button click).
- Filter: parent godown dropdown (select root godowns, auto-submits on change).
- Filter: system (yes/no/all) via dropdown, auto-submits on change.
- Filter: status (active/inactive/all) via dropdown, auto-submits on change.
- All filters preserved across pagination via `->withQueryString()`.
- Actions column is permission-gated.
- Alternative tree view: provide a collapsible tree view toggle showing the hierarchy with expand/collapse icons.

### Integration Rules

- **Referenced by:** `inv_stock_balances.godown_id` (FK — required on every stock balance record), `inv_stock_adjustments.godown_id` (FK).
- Every stock transaction (GRN, stock issue, transfer, adjustment) requires a godown_id.
- Godown list is used as a dropdown filter on Stock Items list (showing balance per godown).
- Godown hierarchy is essential for consolidated stock reports (e.g., "Main Store" total includes all child godown balances).
- The in-charge employee receives email notifications for stock alerts (reorder level, expiry) relevant to their godown.

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.inventory.godowns.viewAny` |
| View details | `tenant.inventory.godowns.view` |
| Create | `tenant.inventory.godowns.create` |
| Edit/update | `tenant.inventory.godowns.update` |
| Soft delete | `tenant.inventory.godowns.delete` |
| View trash & restore | `tenant.inventory.godowns.restore` |
| Force delete | `tenant.inventory.godowns.forceDelete` |
| Toggle status | `tenant.inventory.godowns.toggleStatus` |
