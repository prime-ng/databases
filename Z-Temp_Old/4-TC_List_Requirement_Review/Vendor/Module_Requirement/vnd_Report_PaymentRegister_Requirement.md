# Vendor Payment Register Report

## Report Metadata

| Field | Value |
|-------|-------|
| **Report ID** | RPT-VND-005 |
| **Report Name** | Payment Register |
| **Module** | Vendor Management (VND) |
| **Audience** | Accountant, Finance Manager |
| **Document Version** | 1.0 |
| **Status** | Draft |
| **Last Updated** | 2026-07-19 |

---

## 1. What This Screen Does

The Payment Register shows every successful payment made to vendors within a chosen date period. It's the single place to track, review, and check all money going out to vendors. The screen gives you key summary numbers, charts to spot spending patterns, and a sortable list of every individual payment.

This report replaces manual ledger-scrolling and scattered spreadsheets by putting all payment info in one place. You can zoom into a specific vendor, date window, payment method, or reconciliation status without leaving the screen. It answers these questions at a glance:

- How much money has been paid out this month?
- What's the average payment size and the largest single payment?
- How many transactions were processed and what percentage are matched with bank records?
- Which payment methods are used most?
- How does daily cash outflow trend over time?
- Which vendors received the highest total payments?

---

## 2. When Used

| Frequency | Scenario |
|-----------|----------|
| **Daily** | End-of-day check — confirm all successful payments for the day are accounted for and match bank statements. |
| **Weekly** | Cash outflow review — monitor weekly spend across vendors and spot unusual patterns. |
| **Monthly** | Month-end closing — generate the official payment register for the period, match against bank records, and prepare for audit. |
| **Quarterly** | Vendor spend analysis — review top vendors by amount paid to negotiate terms or consolidate suppliers. |
| **Ad-hoc** | Audit requests — produce a filtered, time-stamped snapshot of all payments for a specific vendor, date range, or status for auditors. |
| **Ad-hoc** | Dispute resolution — find a specific payment by reference or receipt number to confirm it was sent, when, and for how much. |
| **Ad-hoc** | Matched vs unmatched review — identify payments that haven't been matched with bank records so the finance team can follow up. |

The report is also used during the annual financial audit to provide a complete log of all vendor payments for the fiscal year.

---

## 3. Who Can Access

Access to the Payment Register requires a specific permission. The system checks if you're allowed before showing any data.

### 3.1 Permission Key

```
tenant.vendor-report.viewAny
```

### 3.2 Access Rules

| Role | How Access Works | What They See |
|------|-----------------|---------------|
| Super Admin | Automatic | Full access — all organisations, all vendors, all data |
| Finance Manager | Granted manually | Full access — all vendors within their organisation |
| Accountant | Granted manually | Full access — all vendors within their organisation |
| Vendor Manager | Granted manually | Full access — all vendors within their organisation |
| Auditor (read-only) | Granted manually | View only — can see but cannot export or print |
| Clerk | Not granted | No access — the screen is hidden from navigation |

### 3.3 Organisation Separation

Each user only sees their own organisation's payment records. A user from Organisation A can never see payments belonging to Organisation B. The system checks the permission at every screen load. If the user's role does not include this permission, the system shows an access denied message and the report does not load.

### 3.4 Permission Check

```
When a user tries to open the report:
  If the user is a Super Admin:
    Allow access
  If the user has the "tenant.vendor-report.viewAny" permission:
    If the user belongs to the same organisation:
      Allow access
  Otherwise:
    Show "Access Denied" message
```

---

## 4. How It Works

### 4.1 Overview

The Payment Register works by fetching the latest data every time you open it or change a filter. The screen has three areas stacked top to bottom: filters at the top, summary numbers and charts in the middle, and the payment list at the bottom.

### 4.2 Filter Panel

The filter bar sits at the top and stays visible as you scroll. It has these controls:

| Filter | What You Pick | Default | Options |
|--------|--------------|---------|---------|
| Vendor | Pick one or more vendors | All vendors | List of active vendors from your organisation |
| Date Range | Pick a start and end date | Current month (1st to last day) | Preset shortcuts: Today, This Week, This Month, Last Month, This Quarter, This Year, or pick custom dates |
| Payment Method | Pick one or more methods | All methods | Bank Transfer, Cheque, Cash, Card |
| Status | Pick a single status | Successful | Successful, Initiated, Failed, All |
| Matched with Bank | Three-way toggle | All | All, Matched Only, Unmatched Only |

All filters work together (AND logic). Change any filter and the screen refreshes immediately. A "Reset Filters" button puts everything back to defaults.

### 4.3 Request Details

| Property | Value |
|----------|-------|
| **Method** | GET |
| **Address** | `/api/{organisation}/vendor-report/payment-register` |
| **Security** | Login required, organisation check, permission check |

### 4.4 Filter Values Sent

| Value Sent | What It Is |
|------------|------------|
| Organisation | Your organisation's short name from the web address |
| Vendor IDs | One or more vendor IDs if you picked specific vendors |
| From Date | Start of the date range (defaults to 1st of current month) |
| To Date | End of the date range (defaults to last day of current month) |
| Payment Methods | One or more method codes if you picked specific methods |
| Status | Successful, Initiated, Failed, or All |
| Matched | true, false, or not sent for all |
| Page Number | Which page of results to show (defaults to 1) |
| Rows Per Page | How many rows to show (defaults to 25, max 100) |
| Sort By | Which column to sort by (defaults to payment date) |
| Sort Order | Ascending or descending (defaults to newest first) |

### 4.5 What Comes Back

When you open the report or change a filter, the system sends back:

**Summary numbers:**
- Total transactions: 184
- Total money paid out: $9,250,000.00
- Percentage matched with bank: 78.26%
- Average payment size: $50,271.74
- Largest single payment: $750,000.00

**Charts:**
- How payments split by method: Bank Transfer $6,200,000 (67%), Cheque $2,100,000 (23%), Cash $650,000 (7%), Card $300,000 (3%)
- Daily cash outflow: each day's total amount and number of payments
- Top vendors by total paid: Acme Corp $1,850,000, Global Supplies $1,420,000, TechParts Ltd $985,000

**Payment list (paginated):**
- Currently on page 1 of 8
- 25 records shown per page
- Each record shows: reference number, receipt number, vendor name, invoice number, payment date, amount, method, status, whether it's matched with bank, and who paid it

---

## 5. Summary Metrics

Five key numbers appear as cards in a row at the top of the screen. Each card shows a label, the value, and an up/down arrow comparing to the previous period.

### 5.1 The Five KPIs

| Metric | How It's Calculated | Format | What It Means |
|--------|-------------------|--------|---------------|
| **Total Transactions** | Counts all successful, non-cancelled payments matching your filters | Number with commas (e.g., 1,234) | How many payments were processed |
| **Total Money Paid Out** | Adds together all payment amounts in the filtered set | Currency (e.g., $1,234,567.89) | Total cash that went out to vendors |
| **Percentage Matched with Bank** | Divides matched payments by total payments, multiplied by 100 | Percentage (e.g., 78.26%) | How many payments have been confirmed against bank records. Below 95% needs review |
| **Average Payment Size** | Divides total amount by number of payments | Currency (e.g., $50,271.74) | Typical payment amount — helps spot unusually large or small payments |
| **Largest Single Payment** | Finds the biggest individual payment amount | Currency (e.g., $750,000.00) | The single biggest payment made — flags the most significant transaction |

### 5.2 How Each Card Looks

```
+------------------------------------------+
|  Total Transactions         ↑ 12.3%      |
|  1,234                                    |
+------------------------------------------+
```

Each card has: an icon on the left, a label in small text, the value in large bold text, and a trend arrow (green up = increase, red down = decrease) compared to the same period before.

### 5.3 Edge Cases

| Situation | What Happens |
|-----------|-------------|
| No payments match filters | All metrics show 0 or $0.00; percentage matched shows "N/A" |
| No payments are matched | Percentage matched shows 0.00% |
| All payments are matched | Percentage matched shows 100.00% |
| Only one payment in the set | All four amount metrics show the same figure; percentage is either 0% or 100% |
| An amount is missing | Treated as zero; a note is logged for checking |

---

## 6. Charts

Three charts appear below the summary numbers. On a wide screen, the first two sit side by side and the third is full width below. On a phone, they stack one above the other.

### 6.1 How Payments Split by Method (Doughnut/Pie Chart)

**Purpose:** Show what fraction of total money paid went through each payment method.

**Chart Type:** Doughnut (or pie).

**Where the Data Comes From:**
The system takes all successful payments in the selected date range, groups them by payment method, and adds up the amounts for each method. It also works out each method's share as a percentage of the total.

**What You'll See:** Bank Transfer, Cheque, Cash, Card.

**How It Looks:**
- Each method has its own colour: Bank Transfer = blue, Cheque = green, Cash = orange, Card = purple
- A legend sits to the right on wide screens, below on phones
- Hover over a slice to see the method name, dollar amount, and percentage
- The centre shows the total paid (doughnut version only)

**When Things Are Unusual:**
- Only one method used: The chart is a full circle in that single colour showing 100%
- No data: A message saying "No payment data available for the selected filters"
- Unknown method code: Grouped under a grey "Other" slice

### 6.2 Daily Cash Outflow (Line Chart)

**Purpose:** Show how total payments and number of transactions changed day by day over the selected date range.

**Chart Type:** Line chart with two scales (left = dollar amount, right = number of transactions).

**Where the Data Comes From:**
The system groups successful payments by date, adds up the amounts for each day, and counts how many payments happened each day.

**How It Looks:**
- Horizontal axis: each day (formatted as Jul 01, Jul 02, etc.)
- Left vertical axis: total dollar amount
- Right vertical axis: number of transactions
- Amount line: blue with light blue fill underneath
- Transaction count line: grey with dashes
- Light horizontal grid lines only
- Hover to see the date, total amount, and transaction count
- If the date range is very wide (over 90 days), data is grouped by week to keep the chart readable

**When Things Are Unusual:**
- Only one day selected: Shows a single dot with no line
- No data: A flat line at zero with a message
- Days with no payments: The line connects across the gap

### 6.3 Top Vendors by Total Paid (Horizontal Bar Chart)

**Purpose:** Show which vendors received the most money in the selected period.

**Chart Type:** Horizontal bars.

**Where the Data Comes From:**
The system groups successful payments by vendor, adds up the amounts for each vendor, and shows the top 10.

**How It Looks:**
- Vendor names on the left, dollar amounts on the right
- The highest-paid vendor gets the darkest blue bar, going lighter for lower amounts
- Each bar shows the vendor name at the start and the dollar amount at the end
- Hover to see vendor name, total paid, and percentage of overall spend
- Sorted from highest to lowest

**When Things Are Unusual:**
- Fewer than 10 vendors: Only shows the ones that exist
- Tied amounts: Sorted alphabetically
- No data: Shows an empty state message
- Very long vendor names: Truncated with "..." after 30 characters; full name shows on hover

---

## 7. Data Grid

The lower part of the screen lists individual payments in a table. You can sort by any column and flip through pages.

### 7.1 Column Definitions

| # | Column | What It Shows | Sortable | Notes |
|---|--------|---------------|----------|-------|
| 1 | # | Row number on the current page | No | Auto-numbered |
| 2 | Reference / Receipt No | Unique payment reference and/or receipt number | Yes | Clickable to open payment details |
| 3 | Vendor Name | The vendor's legal name | Yes | Clickable to open vendor profile |
| 4 | Invoice Number | The invoice this payment covers | Yes | May be blank if no invoice |
| 5 | Payment Date | Date the payment was processed | Yes | Shown as DD-Mon-YYYY (e.g., 15-Jul-2026) |
| 6 | Amount | How much was paid | Yes | Shown as currency, right-aligned |
| 7 | Method | How they were paid | Yes | Shown as a coloured label: Bank Transfer, Cheque, Cash, Card |
| 8 | Status | Payment outcome | Yes | Green = Successful, Yellow = Initiated, Red = Failed |
| 9 | Matched with Bank | Whether it's confirmed against bank records | Yes | Green checkmark or grey cross |
| 10 | Paid By | Who initiated the payment | Yes | Full name of the person who processed it |

### 7.2 Pagination

- Default: 25 rows per page
- Options: 10, 25, 50, or 100 rows per page
- Navigation: Previous, page numbers (with "..." for many pages), Next, and a page-size selector
- Shows "Showing 1 to 25 of 184 entries" above the grid
- Goes back to page 1 whenever you change a filter

### 7.3 Sorting

- Click a column header to sort: first click = ascending, second click = descending, third click = back to default
- An arrow shows which column is sorted and which direction
- Only one column sorted at a time

### 7.4 Row Actions

| Action | How | What Happens |
|--------|-----|-------------|
| View Payment Detail | Click the reference/receipt number | Opens the full payment information screen or popup |
| View Vendor Profile | Click the vendor name | Opens the vendor's profile page |

### 7.5 Empty State

When no records match the filters:

```
+-------------------------------------------------------+
|                                                       |
|            No Payments Found                          |
|     No payment records match your current filters.   |
|     Try adjusting the vendor, date range, or status  |
|     filters to broaden your search.                  |
|                                                       |
|        [Reset Filters]                                |
|                                                       |
+-------------------------------------------------------+
```

### 7.6 Loading State

While data is being fetched, grey placeholder bars show where numbers, charts, and rows will appear. The filter controls stay usable.

---

## 8. Data Sources

### 8.1 Main Records Used

The Payment Register gets its data from three main sets of records:

1. **Payment Records** — One record for every payment transaction. All summarising and filtering starts here.
2. **Vendor Records** — Provides vendor names and details.
3. **Invoice Records** — Provides invoice numbers for payments that are linked to an invoice.

### 8.2 Supporting Records

1. **Payment Method Labels** — Translates method codes (like "bank_transfer") into readable names (like "Bank Transfer").
2. **User Names** — Provides the full name of the person who made each payment.

### 8.3 Core Data Rules

The system brings together payment records with their vendor names, invoice numbers, payment method labels, and the payer's name. It only includes:
- Successful payments
- Non-cancelled payments
- Payments belonging to your organisation
- Payments within the selected date range

It also respects any vendor, payment method, or matched-with-bank filters you've set.

### 8.4 Performance Notes

The system uses shortcuts (indexes) to find the right records quickly. These shortcuts are set up on:
- Organisation, status, and cancellation status (to find your active records first)
- Payment date and organisation (for date range filtering and default sorting)
- Vendor (for vendor filtering)
- Payment method (for method filtering)
- Whether matched with bank (for matched/unmatched filtering)

---

## 9. Business Rules

### 9.1 Live Calculations

All summary numbers and charts are calculated from the latest data every time you open the report or change a filter. Nothing is pre-calculated or stored. Each filter change re-computes everything fresh. This keeps the numbers accurate. If the report gets slow with large data volumes, a temporary cache (refreshing every 5 minutes) may be added later, but the initial version always shows live data.

### 9.2 Cancelled Records Ignored

Any payment or vendor record that has been cancelled (soft-deleted) is left out of all numbers, charts, and the payment list. This applies to:
- The payment itself
- The vendor's name
- The invoice number

If a payment is linked to a cancelled vendor or invoice, the payment still shows (it was a real transaction), but the vendor name or invoice number will be blank. This prevents accidental data loss.

### 9.3 Only Successful Payments Count in KPIs

Summary numbers and charts only include payments with "Successful" status. Initiated or Failed payments are excluded from the KPIs to keep financial numbers accurate. However, you can change the status filter to see Initiated or Failed payments in the data grid if you need to.

Specifically:
- Summary metrics and charts always use only Successful payments
- The data grid uses whatever status filter you select

### 9.4 How Percentage Matched Is Calculated

```
Percentage Matched = (Number of payments matched with bank / Total number of payments) × 100
```

- "Matched with bank" means the payment record has been confirmed against a bank statement entry.
- "Total payments" means all Successful, non-cancelled payments in the filtered set.

If there are zero payments, the percentage shows "N/A" instead of causing an error.

### 9.5 How Filters Work Together

All filters combine together (AND logic). Changing the vendor filter re-calculates the numbers, charts, and payment list based on the new vendor choice, while keeping all other filter settings. The date range filter has the biggest effect on performance because it controls how much data is scanned.

Filters are applied in this order:
1. Your organisation (always applied)
2. Not cancelled (always applied)
3. Successful status (always applied for KPIs and charts)
4. Date is between the from and to dates (default or chosen)
5. Vendor is one of the selected ones (if vendor filter is active)
6. Payment method is one of the selected ones (if method filter is active)
7. Matched/unmatched status (if toggle is set)

### 9.6 Default Date Range

When you first open the report, the date range defaults to the current month (1st to last day). The system sets these defaults if you don't pick dates yourself. If you leave and come back, the range resets to the current month again — your previous filter choices are not remembered between sessions.

### 9.7 Currency and Number Formatting

All money amounts shown in charts and the grid are formatted according to your organisation's local settings:

| Locale | Example |
|--------|---------|
| US English | $1,234,567.89 |
| UK English | £1,234,567.89 |
| German | 1.234.567,89 € |

The currency symbol comes from your organisation's base currency setting. Amounts always show 2 decimal places. Percentages in charts show 1 decimal place (e.g., 67.0%).

### 9.8 Exporting Data

The report screen has an export button in the top bar:

| Format | File Name | Row Limit |
|--------|-----------|-----------|
| CSV | `payment_register_YYYY-MM-DD.csv` | No limit |
| Excel | `payment_register_YYYY-MM-DD.xlsx` | No limit |
| PDF | `payment_register_YYYY-MM-DD.pdf` | No limit (paginated) |

Exports respect all active filters and include the full result set (not just the current page). The same permission check applies to exporting.

### 9.9 Audit Trail

Every time the Payment Register is opened or exported, the system logs:
- What happened (report viewed or exported)
- Which report (RPT-VND-005)
- Who did it
- Which organisation
- What filters were active
- When it happened
- Where the request came from

---

## 10. Scenarios

### 10.1 Normal Use — Accountant Reviews Monthly Payments

**Who:** Accountant

**Before Starting:** User is logged in, has permission, and navigates to Reports > Payment Register.

**What Happens:**
1. Screen loads showing the current month, Successful payments, all vendors, all methods, all matched/unmatched.
2. Summary numbers show: 184 transactions, $9,250,000.00 total paid, 78.26% matched, $50,271.74 average, $750,000.00 largest payment.
3. Pie chart shows Bank Transfer 67%, Cheque 23%, Cash 7%, Card 3%.
4. Line chart shows daily payments peaking on the 3rd, 15th, and 28th.
5. Bar chart shows Acme Corp as top vendor at $1,850,000.00.
6. Payment list shows 25 records sorted newest first.
7. User clicks "Amount" column to sort — list re-sorts from smallest to largest.
8. User goes to page 2 — next 25 records load.
9. User changes date range to "This Quarter" — all numbers, charts, and list refresh.

**Result:** Accountant has a complete picture of the month's payments and can proceed with bank matching.

---

### 10.2 Filter by One Vendor

**Who:** Finance Manager

**Before Starting:** User is on the report with default filters.

**What Happens:**
1. User picks "Acme Corp" from the vendor list.
2. Summary numbers update: 45 transactions, $1,850,000.00 total, 85.00% matched.
3. Pie chart shows only methods used by Acme Corp.
4. Line chart shows daily payments to Acme Corp only.
5. Bar chart reorders to show Acme Corp at the top.
6. Payment list shows only Acme Corp's 45 payments.

**Result:** All data is scoped to Acme Corp only. No cross-vendor mix-up.

---

### 10.3 Find Unmatched Payments

**Who:** Accountant

**Before Starting:** End-of-month bank matching in progress.

**What Happens:**
1. User sets "Matched with Bank" filter to "Unmatched Only".
2. List updates to show only unmatched payments.
3. Summary numbers still show the overall matched rate for all payments (business rule 9.4).
4. User exports the unmatched list to CSV to cross-check against bank statements.
5. User marks individual payments as matched in the payment detail screen.
6. User returns to the Payment Register and refreshes — matched rate has improved.

**Result:** Unmatched payments are isolated for action, but KPIs still show the full picture.

---

### 10.4 No Data for Selected Period

**Who:** Finance Manager

**Before Starting:** User picks a future date range (e.g., next month).

**What Happens:**
1. All KPI cards show 0 or $0.00.
2. Percentage matched shows "N/A".
3. Charts show empty state illustrations.
4. Payment list shows the empty state message with a "Reset Filters" button.

**Result:** Clean empty state, no errors, easy way to reset filters.

---

### 10.5 Payment Without an Invoice

**Who:** Accountant

**Before Starting:** A payment was made without an associated invoice (e.g., advance payment).

**What Happens:**
1. Payment list shows the record with Invoice Number column blank.
2. All other columns show normally.
3. Summary numbers and charts include this payment.
4. Export includes the row with an empty invoice number cell.

**Result:** The system handles payments without invoices without errors.

---

### 10.6 Large Dataset — Year-End Review

**Who:** Finance Manager

**Before Starting:** Date range spans a full fiscal year with 10,000+ payments.

**What Happens:**
1. Screen loads with default filter (current month) — quick response.
2. User selects "This Year" — takes 4-5 seconds to calculate across 10,000+ records.
3. Loading placeholders show while the data is being fetched.
4. KPIs display correct year-to-date totals.
5. Pagination shows 400+ pages (at 25 per page).
6. User jumps to page 200 — loads fine.

**Result:** Large dataset doesn't crash the browser. Backend completes within acceptable time.

---

### 10.7 Permission Denied

**Who:** Clerk (no permission)

**What Happens:**
1. Clerk tries to open Reports > Payment Register.
2. System shows "Access Denied" message.
3. The report menu item is hidden from the sidebar.

**Result:** Unauthorised users cannot access the report by any means.

---

### 10.8 Organisation Data Separation

**Who:** Super Admin (access to multiple organisations)

**Before Starting:** Super Admin views the report for Organisation A, then switches to Organisation B.

**What Happens:**
1. In Organisation A: shows Organisation A's data only.
2. Super Admin switches to Organisation B.
3. Screen reloads with default filters in Organisation B.
4. Numbers show Organisation B's data only — no mixing.

**Result:** Organisation separation is maintained at all times.

---

### 10.9 Export with Active Filters

**Who:** Finance Manager

**Before Starting:** Vendor filter is set to "Acme Corp", date range is "This Quarter".

**What Happens:**
1. User clicks "Export" and picks CSV.
2. File downloads named `payment_register_2026-07-19.csv`.
3. CSV contains all Acme Corp payments for Q3 (not just the 25 shown on screen).
4. CSV columns match the screen columns exactly.
5. Summary numbers and charts are not included in the CSV export.

**Result:** Export respects filters, exports everything, uses the correct file name.

---

## 11. Dependencies

### 11.1 Records That Must Exist

| What | Why |
|------|-----|
| Payment Records | The core data — must have: reference number, receipt number, vendor, invoice, payment date, amount, method, status, matched flag, who paid it, creation date, last update date |
| Vendor Records | Must have: vendor name and cancellation status |
| Invoice Records | Must have: invoice number and cancellation status |
| Payment Method Labels | Must have entries for Bank Transfer, Cheque, Cash, Card with their codes and readable names |
| User Names | Must have: user names so the report can show who made each payment |
| Performance Shortcuts | All the shortcuts listed in section 8.4 must be in place to keep the report fast |

### 11.2 System Components Needed

| Component | What It Does |
|-----------|-------------|
| Report Controller | Handles the logic for gathering and sending back payment data |
| Permission Check | Makes sure the user has `tenant.vendor-report.viewAny` permission |
| Organisation Check | Extracts and confirms the organisation from the web address |
| Report Logic Service | Holds the reusable rules for building the data |
| Activity Log Service | Records every time the report is viewed or exported |
| Export Service | Generates CSV, Excel, and PDF files using the current filters |

### 11.3 Screen Components Needed

| Component | What It Does |
|-----------|-------------|
| Chart Library | Must support doughnut/pie, line (two scales), and horizontal bar charts |
| Date Picker | Must support preset shortcuts and custom date ranges |
| Multi-Select Dropdown | Must support searching, selecting all, and clearing |
| Data Grid | Must support sorting, pagination, loading placeholders, and responsive columns |
| Web Request Tool | Must support getting data with filter values |
| Currency Formatter | Must support locale-aware currency and number formatting |

### 11.4 Settings Needed

| Setting | Where | Why |
|---------|-------|-----|
| Organisation's Currency | Organisation settings | Determines the currency symbol ($, £, €, etc.) |
| Date Format | Organisation locale | Determines how dates appear in charts and the grid |
| Role Permissions | Role setup | Determines which roles get the `tenant.vendor-report.viewAny` permission |
| Web Address Registration | System routing | The address `/api/{organisation}/vendor-report/payment-register` must be set up with proper security |

### 11.5 Performance Needs

| Need | Reason |
|------|--------|
| Database shortcuts (section 8.4) | Without these, searching through large payment volumes will be unacceptably slow |
| Query tuning | The data retrieval should be checked to confirm the shortcuts are being used |
| Pagination method | Standard page-based navigation may slow down on very deep pages (400+). An alternative approach may be needed if that becomes a problem |
| Caching (future) | If live calculations get too slow, a short-term cache (5 minutes) could be added for the KPI numbers only. The payment list should always show live data |

### 11.6 Testing Needs

| Need | Purpose |
|------|---------|
| Backend tests | Test that the report logic returns correct data for various filter combinations |
| Sample data | Must have realistic test records for payments, vendors, invoices, method labels, and users |
| Test data builders | Tools to quickly create test payment, vendor, and invoice records |
| Frontend tests | Test that filters work, KPIs display, charts render, and the grid paginates correctly |

---

## 12. Appendix

### 12.1 Screen Layout

```
+------------------------------------------------------------------+
|  [Org Logo]  Reports > Payment Register      [Export ▼] [⏻]     |
+------------------------------------------------------------------+
|  Filters:                                                         |
|  [Vendor: All ▼] [Date: Jul 2026 ▼] [Method: All ▼]             |
|  [Status: Successful ▼] [Matched: All ▼]    [Reset Filters]     |
+------------------------------------------------------------------+
|  Summary Numbers:                                                 |
|  +------------+ +------------+ +------------+ +------------+       |
|  | Transactions| | Paid Out   | | Matched %  | | Average    |       |
|  | 1,234       | | $9,250,000 | | 78.26%     | | $50,271.74 |       |
|  | ↑ 12.3%     | | ↓ 2.1%     | | ↑ 5.4%     | | ↑ 3.8%     |       |
|  +------------+ +------------+ +------------+ +------------+       |
+------------------------------------------------------------------+
|  Charts:                                                          |
|  +-----------------------+  +----------------------+              |
|  | By Method (Pie)       |  | Daily Outflow (Line) |              |
|  |                       |  |                      |              |
|  |   ┌─┐ Bank Trf 67%   |  |  ╱╲    ╱╲            |              |
|  |   │ │ Cheque    23%   |  | ╱  ╲  ╱  ╲  ╱╲      |              |
|  |   │ │ Cash       7%   |  |╱    ╲╱    ╲╱  ╲     |              |
|  |   │ │ Card       3%   |  |                  ╲   |              |
|  |   └─┘                 |  |                   ╲  |              |
|  +-----------------------+  +----------------------+              |
|  +------------------------------------------------------+        |
|  | Top Vendors (Bar)                                   |        |
|  | Acme Corp        ████████████████████████ $1,850,000 |        |
|  | Global Supplies  █████████████████████    $1,420,000 |        |
|  | TechParts Ltd    ███████████████          $985,000   |        |
|  | ...                                                 |        |
|  +------------------------------------------------------+        |
+------------------------------------------------------------------+
|  Payment List:                                                    |
|  Showing 1 to 25 of 184 entries                        [25 ▼]   |
|  +----+-------------------+-------------+-------+---------+---+  |
|  | #  | Ref/Receipt No    | Vendor      | Inv # | Date    |...|  |
|  +----+-------------------+-------------+-------+---------+---+  |
|  | 1  | PYMT-2026-07-001  | Acme Corp   | INV.. |15-Jul.. |...|  |
|  | 2  | PYMT-2026-07-002  | Global Sup..| INV.. |15-Jul.. |...|  |
|  | ...                                                          |  |
|  +----+-------------------+-------------+-------+---------+---+  |
|  [<] [1] [2] [3] ... [8] [>]                                    |
+------------------------------------------------------------------+
```

### 12.2 Colour Reference

| Element | Colour | Code |
|---------|--------|------|
| Bank Transfer | Blue | #3B82F6 |
| Cheque | Green | #10B981 |
| Cash | Orange | #F59E0B |
| Card | Purple | #8B5CF6 |
| Matched / Successful badge | Green | #22C55E |
| Initiated badge | Yellow | #EAB308 |
| Failed badge | Red | #EF4444 |
| Chart fill behind amount line | Light blue | rgba(59, 130, 246, 0.2) |
| Chart grid line | Light grey | #E5E7EB |
| Card background | White | #FFFFFF |
| Card border | Light grey | #E5E7EB |
| Empty state text | Muted grey | #9CA3AF |

### 12.3 Glossary

| Term | Meaning |
|------|---------|
| **Payment** | Money sent from your organisation to a vendor. |
| **Matched with Bank** | A payment that has been confirmed against a corresponding entry on a bank statement. |
| **Cancelled Record** | A record that has been marked as removed but not physically deleted. It is hidden from normal views. |
| **Organisation** | A separate, isolated customer instance. Each organisation sees only its own data. |
| **Successful** | A payment that completed without error. |
| **Initiated** | A payment that has been submitted but not yet confirmed. |
| **Failed** | A payment that did not complete successfully. |
| **Method Labels** | A reference list that turns internal method codes into readable names like "Bank Transfer". |

### 12.4 Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-07-19 | System | Initial document creation. |

---

*End of Document — RPT-VND-005 Payment Register Requirement*
