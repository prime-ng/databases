# Asset Categories — Requirements

## Parent Tab: Masters (Inventory) / Also referenced from: Fixed Assets (Accounting)

## What It Does
Manages asset category master records used to classify fixed assets (IT Equipment, Furniture, Vehicles, Buildings, etc.). Each category defines the depreciation rate (WDV method per Income Tax Act) and expected useful life in years. These values are used when auto-creating fixed asset records from GRN postings for asset-type stock items.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment. |
| `name` | VARCHAR(100) | Required. Category name (e.g., IT Equipment, Furniture). |
| `code` | VARCHAR(20) | Nullable. Unique. Short code (IT-EQ, FURN, VEH). |
| `depreciation_rate` | DECIMAL(5,2) | Nullable. Annual WDV depreciation percentage (0.00–100.00). |
| `useful_life_years` | INT | Nullable. Expected useful life in years (>= 1). |
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
| `name` | Required, string, max:100, unique (case-insensitive) | "The name field is required." / "Category name must not exceed 100 characters." / "A category with this name already exists." |
| `code` | Nullable, string, max:20, unique across all asset categories (including soft-deleted) | "The code has already been taken." — checked at application level since DB UNIQUE is nullable and MySQL allows multiple NULLs |
| `depreciation_rate` | Nullable, numeric, min:0, max:100 | "Depreciation rate must be between 0% and 100%." If provided, must be a valid percentage (e.g., 10.00 for 10% per annum). If not provided, defaults to NULL (no depreciation rate set). |
| `useful_life_years` | Nullable, integer, min:1, max:100 | "Useful life must be at least 1 year." / "Useful life must not exceed 100 years." If not provided, defaults to NULL. |

### Depreciation Rate Validation

**Range Constraints:**
- `depreciation_rate` must be between 0.00 and 100.00 inclusive.
- A rate of 0.00 means no depreciation (e.g., Land category).
- A rate of 100.00 means full depreciation in one year (e.g., certain IT equipment).
- The field is DECIMAL(5,2), so precision of up to 2 decimal places is supported (e.g., 15.33% for certain plant & machinery).

**WDV Method Compliance (per Income Tax Act):**
- The `depreciation_rate` is designed for the Written Down Value (WDV) method.
- Standard rates per Income Tax Act Schedule II (suggested values for seeding):
  - IT Equipment (Computers, Servers): 40.00%
  - Furniture & Fittings: 10.00%
  - Office Equipment: 15.00%
  - Plant & Machinery (General): 15.00%
  - Motor Vehicles: 15.00%
  - Buildings (Residential): 5.00%
  - Buildings (Non-Residential): 10.00%
  - Intangible Assets: 25.00%
- These are suggestion defaults; the user can override them.

**Validation on Use:**
- When a GRN creates a fixed asset for an asset-type stock item, the `depreciation_rate` and `useful_life_years` from the asset category are copied to the fixed asset record at creation time.
- If the category's depreciation_rate is later changed, existing fixed assets are NOT retroactively updated. Only new assets created after the change use the new rate.

### Useful Life Validation

- `useful_life_years` must be >= 1 if provided.
- Maximum value: 100 years (sufficient for buildings).
- If both `depreciation_rate` and `useful_life_years` are provided, they should be consistent:
  - Warning (non-blocking): "The specified depreciation rate of {rate}% and useful life of {years} years may not be consistent. A useful life of {years} years would imply an approximate WDV rate of {calculated_rate}%."
  - Calculation: approximate_rate = (1 - (residual_value/cost)^(1/years)) * 100. Using 5% residual value by default.

### Code Uniqueness Rules

- `code` is optional (nullable). Multiple categories can have NULL code.
- If code is provided, it must be unique across ALL asset categories (including soft-deleted).
- Uniqueness is enforced via DB UNIQUE KEY `uq_inv_ac_code` on `code` column.
- Since MySQL UNIQUE allows multiple NULL values, multiple categories with NULL code are permitted.
- Code, when provided, should be short and meaningful (e.g., 'IT-EQ' for IT Equipment, 'FURN' for Furniture).
- Code cannot be changed to a value that conflicts with an existing code (including soft-deleted records): "The code has already been taken."
- Code can be changed from a value to NULL without restriction.

### Deletion Guard — Active Assets

- Before soft-deleting or force-deleting an asset category, the system checks:
  - `SELECT COUNT(*) FROM acc_fixed_assets WHERE asset_category_id = {id} AND deleted_at IS NULL` (or equivalent fixed assets table)
  - `SELECT COUNT(*) FROM inv_stock_items WHERE stock_group_id IN (SELECT id FROM inv_stock_groups WHERE ...) AND item_type = 'asset' AND deleted_at IS NULL` — optional cascade check
- If active fixed assets reference this category, delete is rejected: "Cannot delete asset category with active fixed assets. Reassign assets to another category first."
- This check examines only non-deleted fixed asset records.

### Soft Delete & Restore

**Soft Delete (`DELETE /inventory/asset-categories/{id}` triggered via controller destroy()):**
1. Pre-delete check 1: `SELECT COUNT(*) FROM acc_fixed_assets WHERE asset_category_id = {id} AND deleted_at IS NULL` — must be 0. If > 0, return error: "Cannot delete asset category with active fixed assets. Reassign assets to another category first."
2. Pre-delete action: automatically sets `is_active = 0` (deactivated).
3. The asset category record gets `deleted_at` timestamp set.
4. The record remains in the database (soft-deleted).
5. An audit log entry is created: action = "delete", entity_type = "inv_asset_categories", entity_id = {id}.
6. An activity log entry is created: message = "An asset category was deactivated and soft-deleted."
7. After successful deletion, redirect to route('inventory.asset-categories.index') with flash message flash('trashed.asset_category').

**Restore (`GET /inventory/asset-categories/{id}/restore`):**
1. Only works on soft-deleted records (uses onlyTrashed() query scope).
2. Sets `deleted_at` to NULL.
3. Does NOT automatically set `is_active` back to 1 (remains 0 after restore).
4. An audit log entry is created: action = "restore", entity_type = "inv_asset_categories", entity_id = {id}.
5. After successful restore, redirect to route('inventory.asset-categories.trashed') with flash message flash('restored.asset_category').

**Force Delete (`DELETE /inventory/asset-categories/{id}/force-delete`):**
1. Only available on already soft-deleted records (uses withTrashed() query scope).
2. Pre-delete check: `SELECT COUNT(*) FROM acc_fixed_assets WHERE asset_category_id = {id}` — must be 0 (including soft-deleted assets). If > 0, return error: "Cannot permanently delete asset category with existing fixed assets."
3. The record is permanently removed from the database.
4. An audit log entry is created: action = "force_delete", entity_type = "inv_asset_categories", entity_id = {id}.
5. After successful force delete, redirect to route('inventory.asset-categories.trashed') with flash message flash('force_deleted.asset_category').

**Trash Page (`GET /inventory/asset-categories/trash/view`):**
- Lists only soft-deleted records (uses onlyTrashed() scope).
- Paginated 15 per page.
- Shows columns: Name, Code, Depreciation Rate, Useful Life, Deleted At, Actions (Restore, Force Delete).
- Restore and Force Delete actions are permission-gated.

### Status Toggle

- Route: `POST /inventory/asset-categories/{assetCategory}/toggle-status`.
- AJAX endpoint accepting JSON or form data.
- Toggles `is_active` between 0 and 1.
- Pre-toggle check if toggling from 1 to 0 (deactivating): check for active fixed asset references (same as soft delete pre-check). If assets exist, return JSON error: `{"success": false, "message": "Cannot deactivate category with active fixed assets."}`.
- On success, returns JSON: `{"success": true, "is_active": bool, "message": "Status updated successfully."}`.
- An audit log entry is created on toggle.

### Audit Trail

- Every create, update, soft delete, restore, force delete, and toggle-status action logs to `inv_audit_log`.
- AssetCategoryAuditService::log() is called with: entity_type = "inv_asset_categories", entity_id = {id}, action = {action_type}.
- The global activityLog() helper is also called for each mutation.
- On update: detect changed fields via `$model->getChanges()` (excluding updated_at, updated_by), log old/new values.
- Changes to `depreciation_rate` and `useful_life_years` are logged with special emphasis: "Depreciation rate changed from {old}% to {new}%." because this affects future asset calculations.

### List View

- Controller: AssetCategoryController@index. Gate: 'tenant.inventory.asset-categories.viewAny'.
- Pagination: 20 records per page via `->paginate(20)`.
- Default sort: by `name` ascending.
- Columns displayed:
  1. Name.
  2. Code (badge-styled if present, grey "—" if null).
  3. Depreciation Rate (formatted as "15.00%" or "—" if null).
  4. Useful Life (formatted as "10 years" or "—" if null).
  5. Status (active/inactive badge).
  6. Actions (View, Edit, Delete buttons).
- Filter: search by name or code (text input, submitted on enter or button click).
- Filter: has depreciation rate (yes/no/all) via dropdown — filters categories where depreciation_rate IS NOT NULL / IS NULL / all.
- Filter: status (active/inactive/all) via dropdown, auto-submits on change.
- All filters preserved across pagination via `->withQueryString()`.
- Actions column is permission-gated.

### Integration Rules

- **Referenced by:** `acc_fixed_assets.asset_category_id` (FK — when a fixed asset is created from a GRN for an asset-type stock item, the asset category is determined by the stock item's stock group mapping or explicit selection).
- The `depreciation_rate` and `useful_life_years` from the selected asset category are copied to the fixed asset record at creation time and stored denormalized. Future changes to the category do not affect existing fixed assets.
- Asset category list is used as a dropdown on the Fixed Asset creation/edit form.
- The depreciation rate feeds into the monthly/yearly depreciation calculation engine in the Accounting module.
- HSN/SAC mapping: some categories may have default HSN/SAC codes for GST classification of asset purchases.

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.inventory.asset-categories.viewAny` |
| View details | `tenant.inventory.asset-categories.view` |
| Create | `tenant.inventory.asset-categories.create` |
| Edit/update | `tenant.inventory.asset-categories.update` |
| Soft delete | `tenant.inventory.asset-categories.delete` |
| View trash & restore | `tenant.inventory.asset-categories.restore` |
| Force delete | `tenant.inventory.asset-categories.forceDelete` |
| Toggle status | `tenant.inventory.asset-categories.toggleStatus` |
