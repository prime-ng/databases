# Stock Consumption Report — Business Requirements

## What This Report Shows

The Stock Consumption report tracks raw material usage logged via consumption logs over a date range. It aggregates usage by **stock item** (summing `quantity_used`), shows **current on-hand quantities**, and flags items where current stock is at or below the reorder level.

## Data Sources

- **`caf_consumption_logs`** with `stockItem` (eager loaded)
- **Filtered by**: `log_date` range (`from_date`/`to_date`), `stock_item_id`
- **Aggregates**: Grouped by `stock_item_id`, sums `quantity_used`

## Report Structure

### KPI Cards (Overview sub-tab)
- **Total Used** — Sum of all `quantity_used` across filtered logs
- **Items Tracked** — Count of distinct stock items with usage in range
- **Avg Daily** — Total Used ÷ number of days in range (or distinct log dates present)
- **Low Stock** — Count of items where `current_quantity ≤ reorder_level`

### Chart: Consumption by Item (Bar)
- X-axis: stock item names
- Y-axis: total quantity used

### Chart: Consumption Distribution (Pie)
- Shares by stock item, showing relative consumption

### Detailed Records sub-tab (Table)
- Columns: Item, Unit, Total Used, No. of Entries

## Filters

| Filter | Source Parameter | Type |
|--------|-----------------|------|
| Date Range | `caf_rpt_df` / `caf_rpt_dt` (hidden inputs) | Daterangepicker |
| Stock Item | `stock_item_id` | Dropdown from `StockItem::active()` |

## Business Logic

- Consumption logs are immutable (no SoftDeletes)
- `low_stock_count` compares each item's `current_quantity` against its own `reorder_level`
- Avg daily uses date range days when provided; falls back to distinct log dates in result set
- Stock items with zero consumption in the range do not appear

## PDF Export

Route: `GET /cafeteria/reports/export/stock-consumption`
Layout: `reports-page.exports.stock-consumption-pdf`

## Requirements

- MUST display at `/cafeteria/reports-page?tab=stock-consumption` with Overview + Detailed Records internal tabs
- MUST authorize via `cafeteria.report.viewAny` gate
- MUST filter by date range and stock item
- MUST compute Total Used as sum of quantity_used
- MUST compute Low Stock using each item's reorder_level (not hardcoded threshold)
- MUST compute avg daily using date range or distinct log dates fallback
- MUST show consumption bar chart and pie distribution chart
- MUST support PDF export via `exportStockConsumption()`
