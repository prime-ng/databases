# Daily Sales — Business Requirements

## What This Screen Does

The Daily Sales screen provides a daily summary of all cafeteria sales — orders placed, POS transactions processed, payment mode breakdown, and total revenue. It consolidates data from Orders and POS Transactions into a single daily view for admin and finance team review.

---

## When This Screen Is Used

- End-of-day reconciliation — how much did the cafeteria earn today?
- Finance team needs daily sales data for accounting
- Admin wants to compare sales trends across days or weeks
- Identifying peak sales periods (which meal category generates most revenue)
- Monthly sales reporting

---

## Key Fields at a Glance

**Date**
The sales date being viewed or reported on.

**Order Summary**
- Total orders placed (pre-orders + counter orders)
- Orders by status (Confirmed, Served, Cancelled)
- Order revenue by payment mode (MealCard, Cash, Subscription)

**POS Summary**
- Total POS transactions processed
- Cash collected
- Meal Card amounts debited
- Number of active POS sessions

**Payment Mode Breakdown**
- MealCard: Total amount deducted from wallets
- Cash: Total cash collected
- Subscription: Total covered by subscription plans

**Revenue Totals**
- Gross revenue (before cancellations/refunds)
- Net revenue (after cancellations/refunds)
- Refund totals for the day

---

## Business Rules and Conditions

**Data Source**
Daily sales data is computed from `caf_orders`, `caf_order_items`, `caf_pos_transactions`, and `caf_meal_card_transactions`. It is a read-only aggregated view — no direct data entry.

**Real-Time Updates**
Sales figures update in real-time as orders are placed and POS transactions are processed.

**Cancellation Adjustments**
Cancelled orders are excluded from net revenue. Refunds issued are shown separately.

**Date Range Filtering**
Default view is today. Admin can select any date range for comparison.

---

## Workflow Steps

**Viewing Today's Sales**
Open the Daily Sales screen to see today's real-time summary with order counts, revenue, and payment mode breakdown.

**Viewing Historical Sales**
Select a date range to see aggregated sales for that period. Data can be exported for accounting.

**Comparing Sales**
View side-by-side comparison of selected dates or periods to identify trends.

---

## Example Scenario

**March 25 Daily Sales Summary:**
- Total Orders: 156 (142 Confirmed, 10 Served, 4 Cancelled)
- POS Transactions: 89 (MealCard: 62, Cash: 27)
- Revenue:
  - MealCard: ₹8,450
  - Cash: ₹2,150
  - Subscription: ₹0 (covered by plan)
  - Gross: ₹10,600
  - Refunds: ₹360 (4 cancelled orders)
  - Net: ₹10,240
- Active POS Sessions: 2 (Morning shift, Afternoon shift)

---

## Related Screens

- **Orders** — Individual order data feeds into daily sales
- **POS Sessions** — POS transaction data feeds into daily sales
- **Meal Card Ledger** — MealCard payment details
