# Assets — Business Requirements

## What This Screen Does

The Assets page at `/inventory/assets-page` manages the complete lifecycle of school fixed assets (computers, furniture, vehicles, lab equipment, etc.). It has two tabs:

- **Asset Register** (default) — Card list of all assets with search, category filter, and condition/status filter. Each card shows the asset tag, name, assigned employee/godown, condition, and category.
- **Maintenance Schedule** — Table of maintenance records with status filter (scheduled/completed/overdue). Each record shows asset tag, type, vendor, cost, dates, and status.

Assets can be created automatically via **GRN acceptance** (when `stockItem.item_type === 'asset'`) or manually through the AssetController.

## When This Screen Is Used

- **Asset Tracking**: Viewing all organisational assets with their current condition, location, and assignment
- **Asset Creation**: Manually adding assets or auto-creating from GRN for capital items
- **Asset Transfer**: Reassigning assets between godowns or employees (logs movement history)
- **Asset Disposal**: Marking assets as disposed (locked from further edits) with reason and date
- **Maintenance Scheduling**: Recording and tracking maintenance events with vendor, cost, and due dates
- **Print Tags**: Generating printable asset tag labels

## Key Fields

### Asset (`inv_assets`)
- **Asset Tag** (unique) — Auto-generated `ASSET-YYYY-NNNNN` (year + 5-digit sequence), or manually overridden
- **Asset Name** (required) — Human-readable name, max 100 chars
- **Category** (FK → `inv_asset_categories`) — Asset classification category
- **Stock Item** (FK → `inv_stock_items`) — Link to the inventory stock item
- **GRN Item** (FK → `inv_grn_items`, nullable) — Source GRN item if auto-created
- **Supplier** (nullable) — Supplier name
- **Serial No** (nullable) — Manufacturer serial number
- **Model No** (nullable) — Manufacturer model number
- **Purchase Date** (date) — Date of purchase
- **Purchase Cost** (decimal 12,2) — Purchase price
- **Warranty Expiry** (date, nullable) — Warranty end date
- **Tag Color** (nullable) — Color code for printed tag
- **Condition** (enum) — `good` / `fair` / `poor` / `under_repair` / `disposed`
- **Assigned To** (FK → `inv_godowns` or `sch_employees`, nullable) — Current assignment location or employee
- **Employee Assignment** (FK → `sch_employees`, nullable) — Directly assigned employee
- **Is Active** (boolean) — Soft enable/disable

### Asset Maintenance (`inv_asset_maintenance`)
- **Asset** (FK → `inv_assets`) — The asset being maintained
- **Type** (varchar) — e.g. "Annual Service", "Repair", "Calibration"
- **Vendor** (FK → `vnd_vendors`, nullable) — Service vendor
- **Vendor Name** (nullable) — Free-text vendor name
- **Cost** (decimal 12,2, nullable) — Maintenance cost
- **Description** (text, nullable) — Details of maintenance
- **Maintenance Date** (date) — When maintenance was performed
- **Next Due Date** (date, nullable) — When next maintenance is due
- **Status** (enum) — `scheduled` / `completed` / `overdue`

### Asset Movement (`inv_asset_movements`)
- **Asset** (FK → `inv_assets`) — The asset moved
- **From Godown** (FK → `inv_godowns`, nullable) — Source location
- **To Godown** (FK → `inv_godowns`, nullable) — Destination location
- **From Employee** (FK → `sch_employees`, nullable) — Previous assignee
- **To Employee** (FK → `sch_employees`, nullable) — New assignee
- **Reason** (text, nullable) — Why the transfer occurred
- **Moved By** (BIGINT UNSIGNED) — Who performed the transfer

## Business Rules

### Asset Tag Generation
Tag format: `ASSET-YYYY-NNNNN`. The sequence resets per year. Generated via `AssetService::generateAssetTag()`.

### Auto-Creation from GRN
When a GRN is accepted and `stockItem.item_type === 'asset'`, one Asset record is created per integer unit (e.g. qty 5 creates 5 assets with sequential tags). This is triggered by the `GrnAccepted` event → `CreateAssetFromGrn` listener.

### Lifecycle States
- **Active** (condition: good/fair/poor) — Normal operational state. Can be transferred, maintained, edited.
- **Under Repair** (condition: under_repair) — Asset is being repaired. Can be returned to active or disposed.
- **Disposed** (condition: disposed) — Asset is permanently removed from use. **Disposed assets cannot be edited** — the `update()` method checks `if ($asset->condition === 'disposed')` and throws a `DomainException`. Only a restore/undo can make it editable again.

### Transfer Business Logic
`AssetService::transfer()`:
1. Sets new `godown_id` and/or `employee_id`
2. Creates an `AssetMovement` record with from/to godowns/employees
3. Logs the transfer in activity log
4. Requires at least one of: godown_id, employee_id to change

### Disposal Business Logic
`AssetService::dispose()`:
1. Sets `condition = 'disposed'`
2. Records `disposed_at` timestamp
3. Records `disposed_reason`
4. Fires `AssetDisposed` event
5. Dispatches a job to notify Accounting

### Maintenance Rules
- Maintenance records are **not editable** after creation (no update route) — only delete is supported
- Maintenance status can be: `scheduled` (future), `completed` (done), `overdue` (past due date)
- Overdue status is likely determined by comparing `next_due_date` against today

### Print Tag
The `printTag()` method on AssetController generates a printable view of the asset tag via `assets/print-tag.blade.php`.

### Activity Logging
All CRUD operations log activity:
- Create: `"Asset '{asset_name}' created."`
- Update: `"Asset '{asset_name}' updated."`
- Delete: `"Asset '{asset_name}' deleted."`
- Transfer: `"Asset '{asset_name}' transferred from {from} to {to}."`
- Dispose: `"Asset '{asset_name}' disposed: {reason}."`

## Workflow

1. Staff navigates to Inventory → Assets page
2. **Asset Register tab**: Shows paginated card list of all assets with search, category dropdown filter, condition/status filter
3. Staff clicks an asset card → navigates to show page with tabs (Details, Movements, Maintenance)
4. **Show page**: Details tab shows full asset info; Movements tab lists transfer history; Maintenance tab lists maintenance records
5. From show page, staff can **Transfer** (modal with godown/employee select), **Dispose** (modal with reason/date), or **Add Maintenance** (modal with vendor/cost/date)
6. From show page, staff can **Print Tag** to generate a printable label
7. **Maintenance Schedule tab** (on assets page): Shows all maintenance records sorted by date desc with status filter

## Related Screens

- **Asset Categories** — Masters tab; defines category taxonomy and depreciation config
- **Stock Items** — Item definition; item_type='asset' triggers GRN→Asset auto-creation
- **GRN** — Source document for asset auto-creation via `GrnAccepted` event
- **Accounting** — Asset depreciation sync via `AssetDisposed` event job

## Requirements

- MUST display Asset Register at `/inventory/assets-page` as paginated card list with search, category filter, condition filter
- MUST display Maintenance Schedule as second tab with status filter and date-sorted table
- MUST authorize via `tenant.inventory.asset.*` policy gates
- MUST validate store with 13 rules (name required, asset_tag nullable unique, category required, condition required enum, etc.)
- MUST validate update with 9 rules, block update if condition=disposed (DomainException)
- MUST auto-generate asset tag `ASSET-YYYY-NNNNN` if not provided
- MUST auto-create Asset from GRN item when stockItem.item_type='asset' via GrnAccepted→CreateAssetFromGrn
- MUST support transfer with AssetMovement logging
- MUST support disposal with AssetDisposed event + accounting job
- MUST support maintenance CRUD (create/delete only, no update)
- MUST support print tag view
- MUST support soft-delete lifecycle
- MUST log all lifecycle operations via activityLog()
