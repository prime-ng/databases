# Stock Groups — Requirements

## Parent Tab: Masters

## What It Does
Hierarchical stock category tree used to classify inventory items. Groups are arranged in a self-referencing parent-child hierarchy (max depth 3). The system is seeded with 10 system groups that cannot be deleted. Each group can optionally be assigned a default Unit of Measure that pre-populates when creating items under that group.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment. |
| `name` | VARCHAR(100) | Required. Display name of the stock group. |
| `code` | VARCHAR(20) | Nullable. Unique. Short code for the group (RAW, FG, TRD). |
| `alias` | VARCHAR(100) | Nullable. Alternative name. |
| `parent_id` | BIGINT UNSIGNED | Nullable. Self-referencing FK to `inv_stock_groups.id`. ON DELETE SET NULL. |
| `default_uom_id` | BIGINT UNSIGNED | Nullable. FK to `inv_units_of_measure.id`. ON DELETE SET NULL. |
| `sequence` | INT | Default 0. Display ordering within same-level siblings. |
| `is_system` | TINYINT(1) | Default 0. 1 = seeded system group, cannot be deleted or force-deleted. |
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
| `name` | Required, string, max:100 | "The name field is required." / "Name must not exceed 100 characters." |
| `code` | Nullable, string, max:20, unique across all stock groups (including soft-deleted) | "The code has already been taken." — checked at application level since DB UNIQUE is nullable and MySQL allows multiple NULLs |
| `alias` | Nullable, string, max:100 | "Alias must not exceed 100 characters." |
| `parent_id` | Nullable, integer, exists:inv_stock_groups,id | "The selected parent group is invalid." Must reference an existing stock group. Cannot self-reference (parent_id cannot equal id). Cannot set parent_id to a descendant (circular reference check). |
| `default_uom_id` | Nullable, integer, exists:inv_units_of_measure,id | "The selected default UOM is invalid." Must reference an existing active UOM. |
| `sequence` | Required, integer, min:0 | "Sequence must be a non-negative integer." Defaults to 0. |
| `is_system` | Read-only after create | Never accepted from user input. Only set by seeder or database migration. Cannot be changed to 0 for system-seeded records. |

### Parent-Child Hierarchy Rules

**Maximum Depth Enforcement:**
- The stock group tree supports a maximum depth of 3 levels (Root → Sub-Group → Sub-Sub-Group).
- Calculated from the root ancestor (where parent_id IS NULL). If adding or moving a group would exceed depth 3, the operation is rejected: "Stock group hierarchy cannot exceed 3 levels."

**Circular Reference Prevention:**
- Before updating `parent_id`, the system must verify that the new parent is not the group itself and is not a descendant of the group.
- Algorithm: starting from the new parent_id, follow parent_id chain upwards. If the current group's id is encountered at any point, reject: "Circular reference detected. A group cannot be its own ancestor."
- This check is performed using a recursive CTE or iterative query in the service layer.

**Root Groups:**
- A root group has `parent_id IS NULL`.
- Only root groups can be defined as `is_system = 1`.

**Orphan Handling:**
- When a parent group is soft-deleted, its children's `parent_id` is set to NULL (ON DELETE SET NULL).
- When a parent group is restored, children are NOT automatically re-attached.
- Orphaned groups (parent_id IS NULL) are displayed at the root level in tree views.

### Code Uniqueness Rules

- `code` is optional (nullable). Multiple groups can have NULL code.
- If code is provided, it must be unique across ALL stock groups (including soft-deleted).
- Uniqueness is enforced via DB UNIQUE KEY `uq_inv_sg_code` on `code` column.
- Since MySQL UNIQUE allows multiple NULL values, multiple groups with NULL code are permitted.
- Code, when provided, should be short and meaningful (e.g., 'RAW' for Raw Materials, 'FG' for Finished Goods, 'TRD' for Trading Goods).
- Code cannot be changed to a value that conflicts with an existing code (including soft-deleted records): "The code has already been taken."
- Code can be changed from a value to NULL without restriction.

### System Group Protection

- The `is_system` flag is set to 1 by the database seeder for 10 predefined stock groups (Raw Materials, Work-in-Progress, Finished Goods, Trading Goods, Consumables, Spares & Maintenance, Packaging Materials, Scrap/By-Products, Services, Fixed Assets).
- System groups cannot be soft-deleted: "System-seeded stock groups cannot be deleted."
- System groups cannot be force-deleted: "System-seeded stock groups cannot be permanently deleted."
- System groups' `is_active` can be toggled off, but they remain visible in the list with a "System" badge.
- `code` and `name` of system groups should ideally not be editable, but if editable, changes should be logged with extra audit detail.

### Default UOM Assignment

- `default_uom_id` is optional. When set, it pre-selects the UOM dropdown when creating a new stock item under this group.
- When creating/editing a stock item, the user can override the default UOM for that specific item.
- The default_uom_id must reference an existing active UOM record. If the referenced UOM is soft-deleted, the FK constraint (ON DELETE SET NULL) sets this field to NULL automatically.
- Validation: if `default_uom_id` is provided, the referenced UOM must have `is_active = 1`. If inactive, return: "The selected default UOM is inactive. Please choose an active UOM."

### Sequence Ordering

- `sequence` determines display order within same-level siblings (groups sharing the same `parent_id`).
- Lower sequence values appear first. Groups with equal sequence are ordered alphabetically by name.
- When fetching the stock group tree, the ORDER BY clause is: `ORDER BY parent_id ASC NULLS FIRST, sequence ASC, name ASC`.
- If no sequence value is provided during creation, it defaults to 0.

### Stock Group Reassignment Guard

- Before soft-deleting or force-deleting a stock group, the system checks for active references:
  - `SELECT COUNT(*) FROM inv_stock_items WHERE stock_group_id = X AND deleted_at IS NULL`
- If count > 0, delete is rejected: "Cannot delete stock group with active stock items. Reassign or delete the items first."
- This check applies to both regular and force-delete operations.
- The check must examine only non-deleted items (deleted_at IS NULL). Items that are themselves soft-deleted do not block deletion.

### Soft Delete & Restore

**Soft Delete (`DELETE /inventory/stock-groups/{id}` triggered via controller destroy()):**
1. Pre-delete check 1: `is_system` must be 0. If 1, return error: "System-seeded stock groups cannot be deleted."
2. Pre-delete check 2: `SELECT COUNT(*) FROM inv_stock_items WHERE stock_group_id = {id} AND deleted_at IS NULL` — must be 0. If > 0, return error: "Cannot delete stock group with active stock items. Reassign or delete the items first."
3. Pre-delete action: automatically sets `is_active = 0` (deactivated).
4. The stock group record gets `deleted_at` timestamp set.
5. The stock group record remains in the database (soft-deleted).
6. Children groups have their `parent_id` set to NULL by the FK constraint (ON DELETE SET NULL). Children are NOT soft-deleted.
7. An audit log entry is created: action = "delete", entity_type = "inv_stock_groups", entity_id = {id}.
8. An activity log entry is created: message = "A stock group was deactivated and soft-deleted."
9. After successful deletion, redirect to route('inventory.stock-groups.index') with flash message flash('trashed.stock_group').

**Restore (`GET /inventory/stock-groups/{id}/restore`):**
1. Only works on soft-deleted records (uses onlyTrashed() query scope).
2. Sets `deleted_at` to NULL.
3. Does NOT automatically set `is_active` back to 1 (remains 0 after restore).
4. An audit log entry is created: action = "restore", entity_type = "inv_stock_groups", entity_id = {id}.
5. After successful restore, redirect to route('inventory.stock-groups.trashed') with flash message flash('restored.stock_group').

**Force Delete (`DELETE /inventory/stock-groups/{id}/force-delete`):**
1. Only available on already soft-deleted records (uses withTrashed() query scope).
2. Pre-delete check 1: `is_system` must be 0. If 1, return error: "System-seeded stock groups cannot be permanently deleted."
3. Pre-delete check 2: stock group must have 0 active stock items (same check as soft delete). If items exist, return error: "Cannot permanently delete stock group with active items."
4. Pre-delete check 3: stock group must have 0 child groups (even soft-deleted children block force-delete). Query: `SELECT COUNT(*) FROM inv_stock_groups WHERE parent_id = {id}`. If > 0, return error: "Cannot permanently delete stock group with child groups. Reassign children first."
5. The record is permanently removed from the database.
6. An audit log entry is created: action = "force_delete", entity_type = "inv_stock_groups", entity_id = {id}.
7. After successful force delete, redirect to route('inventory.stock-groups.trashed') with flash message flash('force_deleted.stock_group').

**Trash Page (`GET /inventory/stock-groups/trash/view`):**
- Lists only soft-deleted records (uses onlyTrashed() scope).
- Paginated 15 per page.
- Shows columns: Name, Code, Deleted At, Actions (Restore, Force Delete).
- Restore and Force Delete actions are permission-gated.

### Status Toggle

- Route: `POST /inventory/stock-groups/{stockGroup}/toggle-status`.
- AJAX endpoint accepting JSON or form data.
- Toggles `is_active` between 0 and 1.
- Pre-toggle check if toggling from 1 to 0 (deactivating): no additional pre-checks beyond standard validation (system groups can be deactivated).
- On success, returns JSON: `{"success": true, "is_active": bool, "message": "Status updated successfully."}`.
- An audit log entry is created on toggle.
- Works on both active and soft-deleted records.

### Audit Trail

- Every create, update, soft delete, restore, force delete, and toggle-status action logs to `inv_audit_log`.
- StockGroupAuditService::log() is called with: entity_type = "inv_stock_groups", entity_id = {id}, action = {action_type}.
- The global activityLog() helper is also called for each mutation.
- On update: detect changed fields via `$model->getChanges()` (excluding updated_at, updated_by), log old/new values.
- Special audit for `is_system` field: any attempt to modify is_system (even if blocked) should be logged as a security event.

### List View

- Controller: StockGroupController@index. Gate: 'tenant.inventory.stock-groups.viewAny'.
- Pagination: 20 records per page via `->paginate(20)`.
- Default sort: by `sequence` ascending, then `name` ascending.
- Eager loads: default_uom relationship (name, symbol), parent relationship (name).
- Columns displayed:
  1. Name (with hierarchy indentation — use CSS padding-left based on depth level).
  2. Code (badge-styled if present, grey "—" if null).
  3. Parent (parent group name, or "—" if root).
  4. Default UOM (symbol or name, or "—" if not set).
  5. System (badge: green "System" badge if is_system=1, hidden otherwise).
  6. Status (active/inactive badge).
  7. Actions (View, Edit, Delete buttons).
- Filter: search by name or code (text input, submitted on enter or button click).
- Filter: parent group dropdown (select root groups, auto-submits on change).
- Filter: system (yes/no/all) via dropdown, auto-submits on change.
- Filter: status (active/inactive/all) via dropdown, auto-submits on change.
- All filters preserved across pagination via `->withQueryString()`.
- Actions column is permission-gated (if user cannot 'update', Edit button hidden; if cannot 'delete', Delete button hidden).
- Tree view alternative: optionally provide a collapsible tree view (JS-based) as a toggle on the list page for small hierarchies.

### Integration Rules

- **Referenced by:** `inv_stock_items.stock_group_id` (FK — required field on stock items).
- Cannot delete a stock group that has active (non-deleted) stock items referencing it.
- When a stock group is soft-deleted, stock items under that group remain active (stock_group_id is NOT set to NULL — constraint uses RESTRICT, not SET NULL).
- The stock group list is used as a dropdown filter on the Stock Items list page.
- Stock group hierarchy is used in inventory reports (group-wise stock summary, category-wise valuation).
- The default_uom_id value is passed as a pre-selected value to the Stock Item create form when the user selects a group first.

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.inventory.stock-groups.viewAny` |
| View details | `tenant.inventory.stock-groups.view` |
| Create | `tenant.inventory.stock-groups.create` |
| Edit/update | `tenant.inventory.stock-groups.update` |
| Soft delete | `tenant.inventory.stock-groups.delete` |
| View trash & restore | `tenant.inventory.stock-groups.restore` |
| Force delete | `tenant.inventory.stock-groups.forceDelete` |
| Toggle status | `tenant.inventory.stock-groups.toggleStatus` |
