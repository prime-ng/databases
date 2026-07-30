# Stock Items — Business Requirements

## What This Screen Does

The Stock Items tab manages raw material inventory used in cafeteria meal preparation. Each stock item tracks **name**, **category** (Grains, Pulses, Vegetables, Fruits, Dairy, Spices, Beverages, Condiments, Cleaning, Other), **unit** of measure, **current quantity**, **reorder level**, **reorder quantity**, and **cost per unit**. Items can be linked to a **supplier** and have an **active/inactive** status.

A **low-stock alert banner** appears at the top of the page when any item's `current_quantity` is at or below its `reorder_level`, with a count of affected items and an "Alert Procurement" button to dispatch reorder notifications.

## When This Screen Is Used

- **Inventory Tracking**: Viewing stock-on-hand quantities across categories
- **Consumption Logging**: Staff deducting used quantities after meal preparation
- **Stock Replenishment**: Adding new stock items or updating quantities
- **Reorder Management**: Triggering procurement alerts when stock runs low
- **Supplier Performance**: Reviewing which items come from which supplier

## Key Fields

- **Name** (string 150) — Item name (e.g., "Basmati Rice", "Chana Dal")
- **Category** (enum) — Grains, Pulses, Vegetables, Fruits, Dairy, Spices, Beverages, Condiments, Cleaning, Other
- **Unit** (string 20) — kg, L, pcs, etc.
- **Supplier** (FK → `caf_suppliers`, nullable) — Preferred vendor
- **Current Quantity** (decimal, default 0) — On-hand stock
- **Reorder Level** (decimal) — Threshold triggering low-stock alert
- **Reorder Quantity** (decimal, nullable) — Recommended order qty
- **Cost Per Unit** (decimal, nullable) — Latest unit cost
- **Is Active** (boolean, default true) — Toggle via status switch

## Business Rules

**Low Stock Detection:** `StockItem` model scope `lowStock()`: `whereColumn('current_quantity', '<=', 'reorder_level')`. The controller checks `$lowStock` and shows a warning banner if count > 0.

**Consumption Logging (logConsumption):** `StockService::logConsumption()` uses `DB::transaction` to atomically:
1. Create a `ConsumptionLog` record (immutable, no SoftDeletes)
2. Deduct `quantity_used` from `current_quantity` (floored at 0)
3. If new qty ≤ reorder_level, call `dispatchReorderAlert()` (placeholder NTF integration)

**Reorder Alert:** `checkReorderLevels()` iterates all active low-stock items and dispatches alerts. Also has optional INV bridge to auto-create purchase requisitions if `caf_inv_integration` setting is enabled.

**Status Toggle:** Ajax endpoint `toggleStatus()` flips `is_active` via `X-backend.table.status-switch` component. Returns JSON `{success, message}`.

**Soft Delete:** Model uses SoftDeletes. Controller has `destroy`, `restore`, `forceDelete` methods.

**ConsumptionLog:** Immutable audit — no SoftDeletes. Fields: stock_item_id, log_date, quantity_used, meal_category_id (nullable), notes, created_by. Linked to StockItem and MenuCategory.

**Activity Logging:**
- Create: `"Stock item {name} created."`
- Update: `"Stock item {name} updated."`
- Delete: `"Stock item {name} deleted."`
- Consumption: `"Consumption logged for stock item {name}."`
- Toggle Status: `"Stock item {name} status updated to active/inactive."`

## Workflow

1. Staff navigates to Cafeteria → Stock & Compliance → Stock Items tab
2. Staff sees paginated table: Item Name, Category, Supplier, On Hand (with low-stock warning icon), Reorder Level, Status toggle, Action buttons
3. "Alert Procurement" button visible in low-stock banner — dispatches reorder notifications
4. Each row has a "Log Consumption" button that opens modal: quantity, meal category, date, notes
5. Staff can create new stock item via create page (separate view)
6. Staff can view item detail page (with consumption log history), edit, or delete
7. Consumed quantity atomically deducted from `current_quantity`

## Related Screens

- **Suppliers** — Second tab; linked via supplier_id
- **FSSAI** — Third tab; compliance records for suppliers
- **Procurement** (INV module) — Optional bridge for purchase requisitions

## Requirements

- MUST display stock items at `/cafeteria/stock-compliance?tab=stock` as paginated table with search + status filter
- MUST authorize via `cafeteria.stock.*` permission gates (note: policy uses `cafeteria.stock.item.*` keys)
- MUST show low-stock alert banner when items below reorder level
- MUST support consumption logging with atomic quantity deduction
- MUST support status toggle via Ajax
- MUST support soft delete with restore/forceDelete
- MUST create immutable ConsumptionLog records for each deduction
- MUST support reorder alert dispatch (placeholder for NTF module)
- MUST log all CRUD and consumption actions via activityLog()
