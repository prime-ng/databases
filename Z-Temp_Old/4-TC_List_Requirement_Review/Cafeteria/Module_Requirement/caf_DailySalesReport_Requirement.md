# Daily Sales Report — Business Requirements

## What This Report Shows

The Daily Sales report provides a snapshot of cafeteria meal orders for a selected date (or the first day of a date range), excluding cancelled orders. It aggregates all non-cancelled orders into **sales by category**, **hourly sales trend**, and a **detailed item-level** breakdown with quantities and revenue.

## Data Sources

- **`caf_orders`** with `items.menuItem.category` (eager loaded)
- **Filtered by**: `order_date` (single date), `meal_category_id`, excludes `status = 'Cancelled'`
- **Aggregates**: Groups order line items by `menu_item_id`, sums `quantity` and `line_total`

## Report Structure

### KPI Cards (Overview sub-tab)
- **Total Revenue** — Sum of all order line item totals (₹)
- **Items Sold** — Total quantity across all line items
- **Avg Order Value** — Total Revenue ÷ Number of distinct orders
- **Categories** — Count of distinct meal categories in the result set

### Chart: Sales by Category (Bar)
- X-axis: meal category names
- Y-axis: total quantity sold per category

### Chart: Hourly Sales Trend (Line)
- X-axis: hours (e.g., "09:00", "10:00") based on `order.created_at`
- Y-axis: total revenue per hour

### Detailed Records sub-tab (Table)
- Columns: Item Name, Category, Qty Sold, Unit Price, Total
- Foot: Total Revenue row

## Filters

| Filter | Source Parameter | Type |
|--------|-----------------|------|
| Date | `caf_rpt_df` / `caf_rpt_dt` (single date via daterangepicker) | Hidden inputs |
| Meal Category | `meal_category_id` | Dropdown from `MenuCategory::active()` |

## Business Logic

- Only orders with status other than 'Cancelled' are included
- Line items are grouped by `menu_item_id`; all cancelled orders' items are excluded
- `total_amount` from `caf_orders` is NOT used — revenue is recomputed from `line_total` on `caf_order_items`
- Hourly trend uses `created_at` timestamp (when order was placed/confirmed)

## PDF Export

Route: `GET /cafeteria/reports/export/daily-sales`
Layout: `reports-page.exports.daily-sales-pdf`

## Requirements

- MUST display at `/cafeteria/reports-page?tab=daily-sales` with Overview + Detailed Records internal tabs
- MUST authorize via `cafeteria.report.viewAny` gate
- MUST filter by single date and meal category
- MUST compute Total Revenue from order_items.line_total, not orders.total_amount
- MUST compute Avg Order Value as revenue ÷ distinct order count
- MUST show hourly trend based on order created_at
- MUST exclude cancelled orders from all aggregations
- MUST support PDF export via `exportDailySales()`
