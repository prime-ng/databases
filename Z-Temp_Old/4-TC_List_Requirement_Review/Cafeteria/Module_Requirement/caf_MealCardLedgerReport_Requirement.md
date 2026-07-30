# Meal Card Ledger Report — Business Requirements

## What This Report Shows

The Meal Card Ledger report provides a financial audit trail of all meal card transactions (top-ups, meal purchases, refunds, adjustments). It summarizes amounts by **transaction type** (Credit/Debit/Refund), shows a **daily balance trend**, and lists individual transactions with card number, amount, and running balance.

## Data Sources

- **`caf_meal_card_transactions`** with `mealCard` (eager loaded)
- **Filtered by**: `student_id` (via whereHas on mealCard), date range on `created_at`, `transaction_type`
- **Aggregates**: Grouped by `transaction_type` for type summary, grouped by date for balance trend

## Report Structure

### KPI Cards (Overview sub-tab)
- **Credit** — Sum of all Credit transaction amounts + count
- **Debit** — Sum of all Debit transaction amounts + count
- **Refund** — Sum of all Refund transaction amounts + count
- **Total Txns** — Total transaction count across unique cards

### Chart: Transaction Amount by Type (Bar)
- X-axis: Top Up, Debit, Refund
- Y-axis: total amount

### Chart: Daily Balance Trend (Line)
- X-axis: dates
- Y-axis: average `balance_after` per day

### Transaction Log sub-tab (Paginated Table)
- Columns: Date, Card #, Type (badge), Amount, Balance, Description
- Paginated 20 per page
- Export PDF button linking to route with current query params

## Filters

| Filter | Source Parameter | Type |
|--------|-----------------|------|
| Date Range | `caf_rpt_df` / `caf_rpt_dt` (hidden inputs) | Daterangepicker |
| Transaction Type | `tx_type` | Dropdown: Credit/Debit/Refund/Adjustment |

## Business Logic

- `student_id` filter uses `whereHas('mealCard')` to find the student's card first
- Date range filters on `created_at` (timestamps, not dates) — start date at `00:00:00`, end date at `23:59:59`
- `balance_after` is taken from the transaction record itself (point-in-time snapshot)
- Daily balance trend uses `avg(balance_after)` per day across all transactions on that day
- Transactions are purchased via pagination (20 per page) in the Transaction Log sub-tab
- Overview runs the same base query separately (duplicate DB call)

## PDF Export

Route: `GET /cafeteria/reports/export/meal-card-ledger`
Layout: `reports-page.exports.meal-card-ledger-pdf`

## Requirements

- MUST display at `/cafeteria/reports-page?tab=meal-card-ledger` with Overview + Transaction Log internal tabs
- MUST authorize via `cafeteria.report.viewAny` gate
- MUST filter by student, date range, and transaction type
- MUST compute Credit/Debit/Refund totals and counts
- MUST show daily average balance trend
- MUST paginate transaction log at 20 per page
- MUST support PDF export via `exportMealCardLedger()`
- MUST show card number and balance_after in transaction log
