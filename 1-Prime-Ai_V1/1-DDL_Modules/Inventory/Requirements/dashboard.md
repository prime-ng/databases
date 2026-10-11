# Dashboard — Requirements

## What It Does
Real-time operational dashboard for inventory management. Displays KPI cards (total stock value, pending POs, reorder alerts, overdue maintenance, low stock items), recent stock movements, and quick navigation to all inventory sections.

## Database Fields
No database table. Aggregates data from inv_stock_balances, inv_stock_items, inv_purchase_orders, inv_asset_maintenance, inv_stock_entries tables for real-time display.

## Business Rules

**KPIs Displayed**

| KPI | Source | Refresh |
|---|---|---|
| Total Stock Value | SUM(inv_stock_balances.current_value) | On page load |
| Pending POs Count | COUNT(inv_purchase_orders WHERE status IN ('sent','partial')) | On page load |
| Reorder Alerts Count | COUNT(inv_stock_balances WHERE current_qty <= inv_stock_items.reorder_level) | On page load |
| Overdue Maintenance Count | COUNT(inv_asset_maintenance WHERE status = 'overdue') | On page load |
| Low Stock Items | COUNT(inv_stock_balances WHERE current_qty > 0 AND current_qty <= reorder_level) | On page load |
| Out of Stock Items | COUNT(inv_stock_balances WHERE current_qty = 0 AND items have reorder_level set) | On page load |

**KPI Cards Behavior:**
- Each KPI displayed as a card with icon, numeric value, and label
- Clicking a KPI card navigates to the relevant full report/list page:
  - Total Stock Value → Stock Valuation Report
  - Pending POs → Pending PO Report
  - Reorder Alerts → Reorder Alerts Report
  - Overdue Maintenance → Asset Maintenance list filtered by overdue
  - Low Stock Items → Reorder Alerts Report
  - Out of Stock Items → Reorder Alerts Report
- KPI values are server-rendered on initial page load (not AJAX-dependent for first paint)
- AJAX refresh available: `GET /inventory/dashboard/kpis` returns JSON for periodic refresh

**Recent Stock Movements:**
- Last 10 inv_stock_entries displayed as a compact table
- Columns: Date, Item, Godown, Type (color-coded badge), Qty, Narration
- Auto-refresh via AJAX polling every 60 seconds (configurable)
- Click row navigates to Stock Ledger with item filter pre-applied

**Top Expiring Items:**
- Top 5 items expiring soonest (based on inv_stock_entries.expiry_date)
- Columns: Item, Batch, Expiry Date, Godown, Qty
- Red highlight for already expired, orange for within 7 days
- Click navigates to Expiry Alerts Report

**Stock Value by Godown (Chart):**
- Bar chart showing total stock value per godown
- Source: inv_stock_balances grouped by godown_id
- Rendered client-side using Chart.js or similar library
- JSON data endpoint: `GET /inventory/dashboard/stock-value-by-godown`

**Stock Value by Stock Group (Chart):**
- Pie/donut chart showing stock value distribution across stock groups
- Source: inv_stock_balances joined with inv_stock_items for stock_group_id
- JSON data endpoint: `GET /inventory/dashboard/stock-value-by-group`

**Data Scoping:**
- Store Manager/Admin: sees all godowns and items
- Department Head (future): sees only items consumed by own department
- No warden-style scoping (unlike hostel dashboard) — inventory is centralized

**Dashboard Loading Strategy:**
- Server-side render: KPI values, recent movements, top expiring items (initial load)
- Client-side render: charts (after JSON endpoints respond)
- Lazy load: charts fetched after DOM ready via AJAX
- Caching: KPI values cached for 5 minutes (configurable) via Laravel cache; chart data cached for 15 minutes

## CRUD Operations

**View** — `GET /inventory/dashboard` → renders dashboard with KPIs, charts, recent movements

**KPIs (AJAX)** — `GET /inventory/dashboard/kpis` → returns JSON with latest KPI values

**Stock Value by Godown (AJAX)** — `GET /inventory/dashboard/stock-value-by-godown` → returns JSON for bar chart

**Stock Value by Group (AJAX)** — `GET /inventory/dashboard/stock-value-by-group` → returns JSON for pie chart

**Recent Movements (AJAX)** — `GET /inventory/dashboard/recent-movements` → returns HTML partial or JSON for movements table refresh

No create/edit/delete — read-only aggregate view.

## Permissions

| Operation | Permission Key |
|---|---|
| View dashboard | `inventory.reports.view` |
