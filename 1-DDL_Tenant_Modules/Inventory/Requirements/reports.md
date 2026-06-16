# Reports — Requirements

## What It Does
Parameterized operational and analytical reports across all inventory domains — stock balance, valuation, ledger, consumption, procurement, reorder alerts, expiry alerts, asset register, and movers analysis. Supports PDF, CSV, and Excel export with date-range and entity filters on all reports.

## Database Fields
No dedicated tables. Aggregates data from inv_stock_entries, inv_stock_balances, inv_stock_items, inv_stock_groups, inv_godowns, inv_issue_requests, inv_purchase_orders, inv_goods_receipt_notes, inv_assets, inv_asset_maintenance tables.

## Report Suites

| Report | Description | Filters | Export |
|---|---|---|---|
| Stock Balance Report | Current quantity and value per item per godown | Item, Godown, Stock Group, Item Type | CSV/Excel/PDF |
| Stock Valuation Report | Total stock value grouped by valuation method | Valuation Method (FIFO/WAC/LPC), Stock Group | CSV/Excel |
| Stock Ledger Report | Detailed movement log with pagination | Item, Godown, Entry Type, Date Range, Voucher ID | CSV/Excel |
| Consumption Report | Department-wise and period-wise stock consumption | Department, Date Range, Item, Godown | CSV/Excel |
| Purchase Register | All purchase orders in date range | Date Range, Vendor, Status, Godown | CSV/Excel |
| Pending PO Report | Unreceived and partially received purchase orders | Vendor, Date Range, Days Overdue | CSV/Excel |
| GRN Register | All goods receipt notes in date range | Date Range, Vendor, PO, Status | CSV/Excel |
| Reorder Alerts | Items at or below reorder level | Godown, Stock Group, Item | CSV/Excel |
| Fast/Slow Movers | Velocity analysis of stock movement (issues + consumption) | Period (30/60/90 days), Godown, Top/Bottom N | CSV/Excel |
| Expiry Alerts | Items expiring within X days | Days Ahead (default 30), Godown, Item | CSV/Excel |
| Asset Register | Full asset listing with condition and book value | Asset Category, Condition, Godown, Department | CSV/Excel |

## CRUD Operations

**Index** — `GET /inventory/reports` → report selection page with links to each report suite

**Stock Balance** — `GET /inventory/reports/stock-balance` → balance report with group-by toggle

**Stock Valuation** — `GET /inventory/reports/stock-valuation` → valuation summary by method

**Stock Ledger** — `GET /inventory/reports/stock-ledger` → paginated ledger with detail

**Consumption** — `GET /inventory/reports/consumption` → dept-wise consumption analysis

**Purchase Register** — `GET /inventory/reports/purchase-register` → PO listing in date range

**Pending PO** — `GET /inventory/reports/pending-po` → unreceived/overdue POs

**GRN Register** — `GET /inventory/reports/grn-register` → GRN listing with status

**Reorder Alerts** — `GET /inventory/reports/reorder-alerts` → items below threshold

**Fast/Slow Movers** — `GET /inventory/reports/movers` → velocity report with period selector

**Expiry Alerts** — `GET /inventory/reports/expiry-alerts` → expiring items list

**Asset Register** — `GET /inventory/reports/asset-register` → full asset listing

**Export** — `GET /inventory/reports/{report}/export/{format}` → CSV, Excel, or PDF download

## Business Rules

**Shared Rules Across All Reports:**
- All reports require `inventory.reports.view` permission
- Export requires `inventory.reports.export` permission
- Date range filtering on all time-series reports (default: current month)
- Pagination: 25 records per page for large result sets; exports bypass pagination (full data)
- All filters preserved on export (exported data matches filtered view)
- Default sort: ascending by item name, date, or other natural key depending on report
- Maximum export rows: 10,000 (configurable via school setting); larger exports trigger queued job notification

**Stock Balance Report:**
- Source: inv_stock_balances joined with inv_stock_items, inv_stock_groups, inv_godowns
- Group by: item or godown (toggle)
- Columns: Item Name, SKU, Stock Group, Godown, Current Qty, Current Value, Last Movement Date
- Zero qty items included by default; can be filtered out via checkbox

**Stock Valuation Report:**
- Source: inv_stock_balances aggregated by valuation_method
- Columns: Valuation Method, Items Count, Total Qty, Total Value
- Drill-down: click method to see item-level breakdown

**Stock Ledger Report:**
- Source: inv_stock_entries (immutable audit trail)
- Columns: Date, Entry Type, Item, Godown, Qty, Rate, Amount, Voucher ID, Batch, Narration
- Voucher ID filter enables Accounting reconciliation

**Consumption Report:**
- Source: inv_stock_entries WHERE entry_type IN ('outward', 'adjustment') with negative variance
- Group by: department and month
- Columns: Department, Period, Item, Total Qty, Total Value
- Compare: select two periods for consumption comparison

**Purchase Register:**
- Source: inv_purchase_orders with inv_vendors
- Columns: PO Number, Date, Vendor, Status, Total Amount, Net Amount, Expected Delivery
- Status filter for open/closed/cancelled POs

**Pending PO Report:**
- Source: inv_purchase_orders WHERE status IN ('sent', 'partial') AND (expected_delivery_date < NOW() OR expected_delivery_date IS NULL)
- Columns: PO Number, Vendor, Order Date, Expected Delivery, Days Overdue, Items Count, Received %
- Overdue highlight: red for past expected_delivery_date

**GRN Register:**
- Source: inv_goods_receipt_notes with inv_vendors, inv_purchase_orders
- Columns: GRN Number, Date, PO Number, Vendor, Godown, Status, Received By

**Reorder Alerts:**
- Source: inv_stock_balances.current_qty <= inv_stock_items.reorder_level
- Columns: Item, SKU, Stock Group, Godown, Current Qty, Reorder Level, Reorder Qty, Preferred Vendor, Last Purchase Rate
- Action button: "Create PR" redirects to PR creation with pre-filled item
- Auto-refresh: manual refresh button (no auto-polling)

**Fast/Slow Movers:**
- Source: inv_stock_entries grouped by item for selected period
- Fast movers: items with highest outward quantity (top 20 sorted descending)
- Slow movers: items with lowest outward quantity (bottom 20 sorted ascending)
- Non-moving: items with zero outward entries in selected period
- Columns: Item, SKU, Stock Group, Total Outward Qty, Total Outward Value, Transactions Count, Days Since Last Movement

**Expiry Alerts:**
- Source: inv_stock_entries with expiry_date NOT NULL WHERE expiry_date <= NOW() + INTERVAL {days} DAY
- Group by: item, batch
- Columns: Item, Batch Number, Godown, Expiry Date, Days Until Expiry, Current Stock Qty
- Categorization: Expired (red), Expiring within 7 days (orange), Expiring within 30 days (yellow)

**Asset Register:**
- Source: inv_assets with inv_asset_categories, inv_stock_items, inv_godowns, inv_asset_maintenance (for last maintenance date)
- Columns: Asset Tag, Item Name, Category, Condition, Purchase Date, Cost, Book Value, Warranty Expiry, Assigned To, Godown, Last Maintenance

**Export Behavior:**
- CSV: streamed as fputcsv() via php://temp, chunk(500) for large datasets
- Excel: Laravel Excel or PhpSpreadsheet with formatted columns, auto-width, header styling
- PDF: DomPDF template styled for print with school header and footer
- File naming: {report_name}_{school_code}_{date}.{format}
- Export limits enforced: max 10,000 rows per export; queued for larger sets with download notification

## Permissions

| Operation | Permission Key |
|---|---|
| View reports | `inventory.reports.view` |
| Export reports | `inventory.reports.export` |
