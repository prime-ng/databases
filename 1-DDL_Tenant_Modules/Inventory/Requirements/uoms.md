# Units of Measure (UOM) & UOM Conversions — Requirements

## Parent Tab: Masters

## What It Does
Manages the Unit of Measure master list and inter-UOM conversion rules. The system is seeded with 10 system UOMs (Pieces, Box, Kilogram, Gram, Litre, Millilitre, Meter, Centimeter, Dozen, Pair). UOM conversions define how quantities translate between different UOMs (e.g., 1 Box = 10 Pieces). Stock quantity display precision is governed by each UOM's `decimal_places` setting.

## Database Fields

### inv_units_of_measure

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment. |
| `name` | VARCHAR(50) | Required. Full UOM name (e.g., Pieces). |
| `symbol` | VARCHAR(10) | Required. Short symbol (e.g., Pcs). |
| `decimal_places` | TINYINT | Required. Default 0. Range 0–4. Decimal precision for quantity display. |
| `is_system` | TINYINT(1) | Default 0. 1 = seeded system UOM, cannot delete. |
| `is_active` | TINYINT(1) | Default 1. |
| `created_by` | BIGINT UNSIGNED | Required. FK to `sys_users.id`. |
| `updated_by` | BIGINT UNSIGNED | Required. FK to `sys_users.id`. |
| `created_at` | TIMESTAMP | Nullable. Laravel standard. |
| `updated_at` | TIMESTAMP | Nullable. Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |

### inv_uom_conversions

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment. |
| `from_uom_id` | BIGINT UNSIGNED FK → inv_units_of_measure | Required. Source UOM. Part of unique composite key with `to_uom_id`. |
| `to_uom_id` | BIGINT UNSIGNED FK → inv_units_of_measure | Required. Target UOM. Part of unique composite key with `from_uom_id`. |
| `conversion_factor` | DECIMAL(15,6) | Required. Must be > 0. Defines "1 from_uom = X to_uom". |
| `effective_from` | DATE | Nullable. Conversion valid from this date (optional). |
| `effective_to` | DATE | Nullable. Conversion valid until this date (optional). |
| `is_active` | TINYINT(1) | Default 1. |
| `created_by` | BIGINT UNSIGNED | Required. FK to `sys_users.id`. |
| `updated_by` | BIGINT UNSIGNED | Required. FK to `sys_users.id`. |
| `created_at` | TIMESTAMP | Nullable. Laravel standard. |
| `updated_at` | TIMESTAMP | Nullable. Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |

## Business Rules

### Field-Level Validation

**Units of Measure:**

| Field | Rule | Error Message / Behavior |
|---|---|---|
| `name` | Required, string, max:50, unique (case-insensitive) across all UOMs (including soft-deleted) | "The name field is required." / "Name must not exceed 50 characters." / "A UOM with this name already exists." |
| `symbol` | Required, string, max:10 | "The symbol field is required." / "Symbol must not exceed 10 characters." |
| `decimal_places` | Required, integer, min:0, max:4 | "Decimal places must be between 0 and 4." 0 = whole numbers only (Pieces, Box). 2 = two decimal places (Kilogram, Litre). 3 = three decimal places (certain chemicals). 4 = four decimal places (high-precision lab materials). |
| `is_system` | Read-only after create | Never accepted from user input. Only set by seeder. Cannot be changed. |

**UOM Conversions:**

| Field | Rule | Error Message / Behavior |
|---|---|---|
| `from_uom_id` | Required, integer, exists:inv_units_of_measure,id, different from to_uom_id | "The from UOM is required." / "Source and target UOM must be different." |
| `to_uom_id` | Required, integer, exists:inv_units_of_measure,id, different from from_uom_id | "The to UOM is required." / "Source and target UOM must be different." |
| `conversion_factor` | Required, numeric, gt:0, max:999999.999999 | "Conversion factor must be greater than 0." / "Conversion factor must not exceed 999,999.999999." |
| `effective_from` | Nullable, date | If provided, must be a valid date. If `effective_to` is also provided, `effective_from` must be before `effective_to`. |
| `effective_to` | Nullable, date | If provided, must be a valid date and must be after `effective_from`. |

### UOM Name/Symbol Uniqueness

- UOM `name` must be unique across all UOMs (including soft-deleted), case-insensitive.
- UOM `symbol` should ideally be unique but is not strictly enforced at the DB level (application-level recommendation).
- Example: "Pieces" and "pieces" are considered duplicates — validated via `LOWER(name)` comparison.

### Bidirectional Conversion & Reciprocal Auto-Creation

- When a conversion `A → B = factor` is created, the system must NOT auto-create the reciprocal `B → A = 1/factor`. Reason: the reciprocal may result in a non-terminating decimal or unacceptable rounding.
- The reciprocal conversion must be created manually by the user.
- However, the system MUST validate that if `A → B` exists, there is no conflict with an existing `B → A` conversion. If `B → A` already exists with a different factor, the user is warned: "Warning: A reciprocal conversion (B → A = X) already exists. The conversion you are creating (A → B = Y) implies a reciprocal of 1/Y. If 1/Y != X, this may cause inconsistencies in stock calculations."
- The conversion lookup service must check both directions: if looking for `A → B`, first check for exact match `(from_uom_id=A, to_uom_id=B)`. If not found, check reverse `(from_uom_id=B, to_uom_id=A)` and use `1/conversion_factor`.

### Conversion Factor Constraints

- `conversion_factor` must be strictly greater than 0. Zero or negative values are rejected: "Conversion factor must be greater than 0."
- Maximum precision: 6 decimal places (DECIMAL(15,6)).
- Maximum value: 999999.999999.

### Circular Conversion Prevention

- The system must prevent the creation of a conversion chain that would allow a UOM to be converted to itself through a series of intermediate conversions.
- Example: `Pcs → Box (factor=0.1)`, `Box → Dozen (factor=1.2)`, `Dozen → Pcs (factor=8.333333)` would create a cycle.
- When creating or updating a conversion, the system must traverse the directed graph starting from `to_uom_id` to see if `from_uom_id` is reachable. If reachable, reject: "This conversion would create a circular reference cycle."
- This check is performed using a recursive CTE through the `inv_uom_conversions` table (up to a max depth of 10 hops).

### Self-Conversion Prohibition

- `from_uom_id` cannot equal `to_uom_id`. A UOM cannot be converted to itself.
- Error: "Source and target UOM must be different."
- This is validated at both the application level (form validation) and by the application logic before insert.

### Decimal Places Precision Effects

- `decimal_places` determines how stock quantities are displayed for items using this UOM.
- Display formatting: quantities are rounded to the UOM's decimal_places for display purposes. Calculation precision is always full precision (DECIMAL(15,3) in stock_balances).
- Example: UOM "Kilogram" with decimal_places=2 displays 1.50 kg; UOM "Pieces" with decimal_places=0 displays 5 Pcs.
- When a stock item's UOM is changed, the new UOM's decimal_places governs future display. Existing historical data retains its original precision.
- Auto-suggestion: when selecting a UOM for a new stock item, the decimal_places value is shown alongside the UOM name in the dropdown.

### Soft Delete & Restore (UOM)

**Soft Delete (`DELETE /inventory/uoms/{id}`):**
1. Pre-delete check 1: `is_system` must be 0. If 1, return error: "System-seeded UOMs cannot be deleted."
2. Pre-delete check 2: `SELECT COUNT(*) FROM inv_stock_items WHERE uom_id = {id} AND deleted_at IS NULL` — must be 0. If > 0, return error: "Cannot delete UOM that is referenced by active stock items."
3. Pre-delete check 3: `SELECT COUNT(*) FROM inv_uom_conversions WHERE (from_uom_id = {id} OR to_uom_id = {id}) AND deleted_at IS NULL` — if > 0, related conversions should also be soft-deleted or the user warned: "This UOM has {count} active conversion rule(s). They will also be deactivated."
4. Pre-delete action: automatically sets `is_active = 0`.
5. Side effect: soft-delete all related conversion records (`UPDATE inv_uom_conversions SET deleted_at = NOW(), is_active = 0 WHERE from_uom_id = {id} OR to_uom_id = {id}`).
6. Standard audit trail entry created.

**Restore (`GET /inventory/uoms/{id}/restore`):**
1. Only works on soft-deleted records.
2. Sets `deleted_at` to NULL.
3. Does NOT auto-restore `is_active` (remains 0).
4. Does NOT auto-restore related conversion records (they remain soft-deleted).
5. Standard audit trail entry created.

**Force Delete (`DELETE /inventory/uoms/{id}/force-delete`):**
1. Only available on already soft-deleted records.
2. Pre-delete check 1: `is_system` must be 0.
3. Pre-delete check 2: `SELECT COUNT(*) FROM inv_stock_items WHERE uom_id = {id}` — must be 0 (including soft-deleted items).
4. Pre-delete check 3: force-delete all related conversion records first (cascade).
5. The record is permanently removed.

### Status Toggle

- Route: `POST /inventory/uoms/{uom}/toggle-status`.
- AJAX endpoint accepting JSON or form data.
- Toggles `is_active` between 0 and 1.
- Pre-toggle check if toggling from 1 to 0 (deactivating): check for active stock item references (same as soft delete pre-check 2). If items exist, return JSON error: `{"success": false, "message": "Cannot deactivate UOM referenced by active stock items."}`.
- On success, returns JSON: `{"success": true, "is_active": bool, "message": "Status updated successfully."}`.
- An audit log entry is created on toggle.

### Audit Trail

- Every create, update, soft delete, restore, force delete, and toggle-status action logs to `inv_audit_log`.
- UomAuditService::log() is called with: entity_type = "inv_units_of_measure" or "inv_uom_conversions", entity_id = {id}, action = {action_type}.
- The global activityLog() helper is also called for each mutation.
- For conversions: log on create, factor change, soft-delete, restore.

### List View

- Controller: UomController@index. Gate: 'tenant.inventory.uoms.viewAny'.
- **Two-tab layout:**
  - **Tab 1: Units of Measure** (default active tab). Lists all UOMs.
  - **Tab 2: Conversions** (sub-tab). Lists all conversion rules.

**Tab 1 — Units of Measure:**
- Pagination: 20 records per page via `->paginate(20)`.
- Default sort: by `name` ascending.
- Columns: Name, Symbol, Decimal Places (badge showing the number), System (green badge if is_system=1), Status (active/inactive badge), Actions (View, Edit, Delete buttons).
- Filter: search by name or symbol (text input).
- Filter: system (yes/no/all) via dropdown.
- Filter: status (active/inactive/all) via dropdown.
- The decimal_places column shows a small badge like "0 dp", "2 dp", "3 dp", "4 dp".

**Tab 2 — Conversions:**
- Pagination: 20 records per page via `->paginate(20)`.
- Default sort: by from_uom name ascending.
- Eager loads: from_uom (name, symbol), to_uom (name, symbol).
- Columns: From UOM (symbol), To UOM (symbol), Conversion Factor (formatted with 6 decimal places), Effective Period (from_date — to_date, or "Always" if both null), Status, Actions.
- Filter: search by from_uom or to_uom name (text input).
- Create button opens a modal/form with from_uom_id, to_uom_id, conversion_factor, effective_from, effective_to fields.
- Actions column: Edit, Delete (soft-delete only, no force delete for individual conversion rules).

### Integration Rules

- **Referenced by:** `inv_stock_groups.default_uom_id` (FK), `inv_stock_items.uom_id` (FK), `inv_purchase_requisition_items.uom_id` (FK), `inv_issue_request_items.uom_id` (FK), `inv_purchase_order_items.uom_id` (implicitly through item's UOM), `inv_stock_adjustment_items` (implicitly).
- UOM conversion service (`UomConversionService`) provides a `convert($fromUomId, $toUomId, $qty)` method used by GRN posting, stock issue, stock transfer, and adjustment posting services.
- Conversion lookup algorithm: check exact match first, then reverse (using 1/factor), then fail with "No conversion path found between {from} and {to}."
- The `decimal_places` field from the item's UOM is used for display formatting of stock quantities throughout the inventory module.

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.inventory.uoms.viewAny` |
| View details | `tenant.inventory.uoms.view` |
| Create UOM | `tenant.inventory.uoms.create` |
| Edit/update UOM | `tenant.inventory.uoms.update` |
| Delete (soft) UOM | `tenant.inventory.uoms.delete` |
| View trash & restore UOM | `tenant.inventory.uoms.restore` |
| Force delete UOM | `tenant.inventory.uoms.forceDelete` |
| Create conversion | `tenant.inventory.uom-conversions.create` |
| Edit/update conversion | `tenant.inventory.uom-conversions.update` |
| Delete conversion | `tenant.inventory.uom-conversions.delete` |
| Toggle status | `tenant.inventory.uoms.toggleStatus` |
