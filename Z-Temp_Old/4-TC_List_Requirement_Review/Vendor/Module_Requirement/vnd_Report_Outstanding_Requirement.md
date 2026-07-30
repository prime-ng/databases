# RPT-VND-004 — Outstanding Report (Ageing Analysis)

| **Field** | **Value** |
|---|---|
| **Report ID** | RPT-VND-004 |
| **Report Name** | Outstanding Report (Ageing Analysis) |
| **Module** | Vendor Management |
| **Type** | Financial & Analytical |
| **Primary Audience** | Finance Manager, Principal |
| **Secondary Audience** | Accounts Payable Team, Operations Manager |

---

## 1. What This Screen Does

This report gives the Finance Manager and Principal a real-time view of every unpaid or partly-paid vendor bill. It groups those bills by how late they are (0–30 days, 31–60 days, 61–90 days, and over 90 days late), and shows key numbers such as the total amount owed, how many bills are past due, and the average number of days bills are late.

This is not just a list of transactions. It is a decision-support tool that combines summary numbers, easy-to-read charts, and a sortable table in one screen. Every number is calculated live so it is always up to date.

---

## 2. When Used

| **Frequency** | **Purpose** |
|---|---|
| Daily (morning check-in) | Review new past-due items and see which bills are getting later |
| Weekly (review meeting) | Present outstanding position to Principal and Finance Manager |
| Month-End / Period-Close | Reconcile vendor liabilities before finalising accounts payable |
| Ad-hoc | Investigate a specific vendor's past-due status or answer cash-flow questions |
| Audit / Compliance | Provide evidence of aged payables analysis for internal or external audit |

---

## 3. Who Can Access

| **Role** | **Access Level** |
|---|---|
| Finance Manager | Full data — sees all vendors for their authorised schools / entities |
| Principal | Full data — sees all vendors for their school |
| Accounts Payable Clerk | Full data — same access as Finance Manager |
| Operations Manager | Full data |
| Auditor (read-only) | Full data but cannot make changes |

---

## 4. How It Works

### 4.1 How the Screen is Organised

When the user opens the report, the system pulls together all unpaid vendor bills and displays them in three areas:

1. **Summary numbers (KPI cards)** at the top — total owed, number of bills, past-due counts, average days late, biggest bill.
2. **Charts** in the middle — a bar chart showing how much is owed in each late category, a bar chart of the top 10 vendors with largest balances, and a line chart showing the weekly trend of past-due amounts.
3. **Data grid** at the bottom — a detailed table of every unpaid bill that can be sorted, filtered, and exported.

### 4.2 Global Filter Panel

Every piece of data on the screen is controlled by a single filter panel at the top. Changing any filter updates the summary numbers, charts, and table all at once.

| **Filter** | **What It Does** | **Default** |
|---|---|---|
| Vendor | Pick one or more vendors from a searchable list | All vendors |
| Date Range (invoice date) | Set a from-date and to-date to narrow by when the invoice was raised | Today's date only |
| Ageing Bucket | Choose a late-payment group: 0–30, 31–60, 61–90, 90+ days, or All | All |
| Overdue Status | Show only past-due bills, only bills still within their due date, or all bills | All |

**How filters work together:**
- All filters are combined — every filter narrows the results further.
- Changing any filter refreshes everything on screen.
- By default, the date range shows only today. The user must extend it manually to see older bills.
- The vendor list is searchable — start typing a name and the system suggests matching vendors.

---

## 5. Summary Metrics (6 KPIs)

Six key numbers appear at the top as KPI cards in a horizontal row. Each card shows the label, the number, and (for most) an arrow showing whether the number has gone up or down compared to the previous period.

| **#** | **Metric** | **How It Is Calculated** | **Format** | **Trend Arrow** |
|---|---|---|---|---|
| 1 | **Total Outstanding Liability** | Adds together every unpaid bill balance | RM 999,999.99 | Up/down vs previous period |
| 2 | **Outstanding Invoice Count** | Counts every bill that still has an unpaid balance | 999 | Up/down vs previous period |
| 3 | **Overdue Count** | Counts bills that are past their due date and still unpaid | 999 | Up/down vs previous period |
| 4 | **Within Due Count** | Counts bills that are not yet past their due date | 999 | Not shown (opposite of Overdue) |
| 5 | **Average Overdue Days** | Averages how late each past-due bill is | 99.9 days | Up/down vs previous period |
| 6 | **Largest Single Outstanding** | The biggest unpaid bill amount | RM 999,999.99 | Not shown (informational) |

### 5.1 Ageing Buckets (Inline Summary Section)

Below the KPI row, a summary table shows the four late-payment groups with count and amount.

| **Bucket** | **Count** | **Amount (RM)** | **% of Total** |
|---|---|---|---|
| 0–30 Days | 28 | 84,500.00 | 14.5% |
| 31–60 Days | 31 | 142,300.75 | 24.3% |
| 61–90 Days | 19 | 98,500.25 | 16.8% |
| 90+ Days | 11 | 259,419.50 | 44.4% |

---

## 6. Charts

Three charts appear below the summary metrics. Each chart responds to the global filter panel and shows tooltips when the user hovers over bars or lines.

### 6.1 Chart 1 — Ageing Distribution (Bar Chart)

| **Property** | **Value** |
|---|---|
| **Type** | Grouped bar chart |
| **X-Axis** | Ageing buckets (0–30, 31–60, 61–90, 90+) |
| **Y-Axis (Left)** | Number of bills |
| **Y-Axis (Right)** | Amount (RM) |
| **Series** | Count (blue bars), Amount (orange bars) |
| **Legend** | Yes, at top |
| **Tooltip** | Shows bucket name, count, amount, percentage of total |
| **Purpose** | See how much money is owed in each late-payment group |

### 6.2 Chart 2 — Top 10 Vendors by Outstanding (Bar Chart)

| **Property** | **Value** |
|---|---|
| **Type** | Horizontal bar chart |
| **X-Axis** | Outstanding Amount (RM) |
| **Y-Axis** | Vendor name (top 10, largest first) |
| **Series** | Single — Outstanding Amount |
| **Legend** | Hidden (single series) |
| **Tooltip** | Shows vendor name, outstanding amount, number of bills |
| **Purpose** | Identify which vendors are owed the most money |

### 6.3 Chart 3 — Weekly Overdue Trend (Line Chart)

| **Property** | **Value** |
|---|---|
| **Type** | Multi-series line chart |
| **X-Axis** | Week label (e.g., "W1", "W2") |
| **Y-Axis (Left)** | Past-due Amount (RM) |
| **Y-Axis (Right)** | Number of past-due bills |
| **Series** | Past-due Amount (solid line), Bill Count (dashed line) |
| **Legend** | Yes, at top |
| **Tooltip** | Shows week, past-due amount, bill count |
| **Purpose** | Track whether past-due liabilities are rising or falling week by week |

---

## 7. Data Grid

### 7.1 Column Definitions

The table at the bottom shows one row for every bill that still has an unpaid balance. The user can sort by any column and filter by typing into the search box.

| **#** | **Column** | **Format** | **Sortable** | **Filterable** | **Notes** |
|---|---|---|---|---|---|
| 1 | Invoice Number | Plain text | Yes | Yes | Click to see invoice details |
| 2 | Vendor Name | Plain text | Yes | Yes | Click to see vendor profile |
| 3 | Invoice Date | Date (DD-MMM-YYYY) | Yes | No | |
| 4 | Due Date | Date (DD-MMM-YYYY) | Yes | No | |
| 5 | Net Payable | RM 999,999.99 | Yes | No | Original bill amount before any payments |
| 6 | Amount Paid | RM 999,999.99 | Yes | No | Total of all payments made against this bill |
| 7 | Balance Due | RM 999,999.99 | Yes | Yes | Must be more than zero (unpaid portion) |
| 8 | Days Overdue | 999 days | Yes | No | How many days past the due date (only shown if bill is unpaid and past due) |
| 9 | Status | Badge / Chip | Yes | No | "Overdue" (red) or "Within Due" (green) |

### 7.2 Grid Features

| **Feature** | **Status** | **Details** |
|---|---|---|
| Pagination | Enabled | 50 rows per page (adjustable: 25 / 50 / 100) |
| Column Sorting | Enabled | Click a column header to sort A-to-Z or Z-to-A |
| Column Filtering | Enabled | Type to filter by Invoice Number, Vendor Name, or Balance Due |
| Row Selection | Enabled | Checkbox column; supports Select All |
| Export | Enabled | CSV export of the currently filtered data (all pages) |
| Row Link | Enabled | Click Invoice Number to see invoice detail; click Vendor Name to see vendor profile |
| Inline Status Badge | Enabled | "Overdue" (red background) or "Within Due" (green background) |

### 7.3 Row Highlighting Rules

| **Condition** | **Style** |
|---|---|
| More than 90 days late | Row background: light orange; bold text |
| More than 60 days late | Row background: light yellow |
| More than 30 days late | Row background: light grey |
| Balance Due over RM 50,000 | Amount cell in bold red text |
| Status = "Overdue" | Red badge with white text |
| Status = "Within Due" | Green badge with white text |

---

## 8. Data Source

The report reads from three groups of information:
1. **Vendor bills** — each bill record holds the invoice number, date, due date, total amount, and unpaid balance.
2. **Vendor names** — the master list of vendors for name lookups.
3. **Payments** — payment records that reduce the unpaid balance on each bill.

The system only shows records that have not been deleted or archived. Fully paid bills (zero balance) are never shown.

---

## 9. Key Performance Indicator (KPI) Definitions

### 9.1 Days Overdue

| **Property** | **Value** |
|---|---|
| **KPI ID** | KPI-VND-004-01 |
| **Name** | Days Overdue |
| **How It Is Calculated** | Today's date minus the bill's due date |
| **Units** | Days |
| **When It Applies** | Only when the bill still has an unpaid balance AND the due date is in the past |
| **When It Is Blank** | The bill is not yet past due (future due date) or is fully paid |
| **Where It Is Used** | Column #8 in the data grid, ageing bucket grouping, and the Average Overdue Days metric |
| **Edge Case** | If the due date is in the future, this KPI is blank (the bill is "Within Due") |
| **Edge Case** | If the balance is zero (fully paid), this KPI is blank (the bill does not appear in the report) |

### 9.2 Ageing Bucket Categories

| **Bucket** | **Condition (Days Late)** |
|---|---|
| 0–30 Days | 0 to 30 days late |
| 31–60 Days | 31 to 60 days late |
| 61–90 Days | 61 to 90 days late |
| 90+ Days | 91 or more days late |

### 9.3 Summary-Level KPIs

| **KPI** | **How It Is Calculated** |
|---|---|
| Total Outstanding Liability | Adds together all unpaid bill balances |
| Outstanding Invoice Count | Counts all bills that still have an unpaid balance |
| Overdue Count | Counts bills that are both unpaid AND past their due date |
| Within Due Count | Counts bills that are unpaid but not yet past their due date |
| Average Overdue Days | Averages the days-late number for all past-due bills |
| Largest Single Outstanding | Finds the biggest single unpaid bill balance |

---

## 10. Business Rules

### 10.1 Live Calculation

Every number on the screen is calculated live. There is no saved snapshot or overnight batch job. When the Finance Manager opens the report or changes a filter, the system reads the latest data and recalculates everything. This includes payments that were recorded just seconds ago.

### 10.2 Soft-Delete Filtering

When a bill, vendor, or payment is deleted (archived) in the system, it does not appear in this report. The report always shows only active records.

### 10.3 Overdue Calculation Rules

1. A bill is "overdue" if it has an unpaid balance AND its due date is in the past.
2. A bill is "within due" if it has an unpaid balance AND its due date is today or in the future.
3. Fully paid bills (zero balance) are excluded from the report entirely.
4. Bills with a future due date still count toward the total outstanding amount and the invoice count, but they are classed as "Within Due" and do not show a days-late number.
5. Unpaid balances should never be negative. If a negative balance somehow exists, it is excluded.

### 10.4 Ageing Bucket Categorisation Rules

1. The days-late number is calculated first.
2. The bucket is determined by how many days late the bill is.
3. Bills that are not past due (blank days-late) do not appear in the ageing chart.
4. The four buckets cover every possible days-late value with no gaps or overlaps.
5. Bucket boundaries are:
   - 0–30: 0 to 30 days late
   - 31–60: 31 to 60 days late
   - 61–90: 61 to 90 days late
   - 90+: 91 or more days late

### 10.5 Cascading Filters

All filters update everything on screen at the same time. There is no "Apply" button — the screen reacts immediately.

1. User changes Vendor filter → Summary numbers, charts, and the table all update.
2. User changes Date Range → Every section updates.
3. User selects Ageing Bucket → The table filters to that group; summary numbers and charts recalculate.
4. User selects Overdue Status → The table filters; the overdue and within-due counts adjust.

**Conflict:** If the user sets Overdue Status to "Within Due" and Ageing Bucket to "90+ Days", there will be no results (a bill cannot be both within due and 90+ days late). The screen should show a helpful message instead of a blank screen.

### 10.6 Date Range Default

The Date Range filter defaults to today's date. The Finance Manager usually wants to see what is outstanding right now. For historical analysis, the date range can be extended manually.

**Note:** With the default set to today, the report may show very few bills if few were raised today. The screen should display a notice: "Showing bills with invoice date = today. Extend the date range for a broader view."

### 10.7 Chart Format Rules

| **Rule** | **Ageing Distribution** | **Top 10 Vendors** | **Weekly Overdue Trend** |
|---|---|---|---|
| Max data points | 4 (fixed) | 10 (fixed) | Up to 8 weeks |
| Sort order | 0–30 then 90+ | Largest amount first | Earliest week first |
| Empty state | Show empty bars at zero | Show "No data" message | Show flat line at zero |
| Currency format | RM 999,999.99 | RM 999,999.99 | RM 999,999.99 |
| Colour palette | Blue (count), Orange (amount) | Teal | Purple (amount), Grey (count) |
| Legend | Top, horizontal | Hidden (single series) | Top, horizontal |
| Grid lines | Enabled (light grey, dashed) | Enabled (light grey, dashed) | Enabled (light grey, dashed) |

### 10.8 Performance Rules

1. The system should have the right indexes in place so the report runs quickly even with many bills.
2. The table shows up to 100 rows per page.
3. If the report takes longer than 30 seconds, the system should show a friendly error asking the user to narrow the date range.
4. If no records match the filters, the system should skip chart and summary calculations entirely.

---

## 11. Scenarios

### 11.1 Scenario A — Finance Manager Daily Review

**Actor:** Finance Manager
**Goal:** Review today's outstanding position
**Steps:**
1. Go to Reports → Vendor → Outstanding Report.
2. Default filters load (date range = today, vendor = all, ageing bucket = all, overdue status = all).
3. Summary metrics show: Total Outstanding Liability = RM 584,720.50, 142 unpaid bills, 89 past due.
4. The 90+ Days bucket has RM 259,419.50 (44.4% of total) — a red flag.
5. Click the "90+ Days" ageing bucket filter.
6. The table narrows to 11 high-risk bills.
7. Sort the table by Balance Due descending to see the largest past-due bill first.
8. Click the Invoice Number to investigate further.
9. Export the filtered view to CSV for the Principal's meeting.

### 11.2 Scenario B — Principal Monthly Review

**Actor:** Principal
**Goal:** Assess overall vendor payment health
**Steps:**
1. Open the Outstanding Report and set date range to the last 3 months.
2. Look at the Weekly Overdue Trend chart — past-due amounts have increased 23% over 8 weeks.
3. Hover over data points to see exact values for each week.
4. Review the Top 10 Vendors chart — three vendors account for 52% of total outstanding.
5. Instruct the Finance Manager to prioritise those three vendors for follow-up.
6. Click Export CSV to send the report to the Board.

### 11.3 Scenario C — AP Clerk Vendor-Specific Query

**Actor:** Accounts Payable Clerk
**Goal:** Check a specific vendor's past-due status
**Steps:**
1. Select vendor "ABC Supplies" from the vendor filter.
2. All metrics and charts recalculate for that vendor only.
3. The table shows 4 past-due bills totalling RM 18,400.
4. The largest bill (RM 12,000) is 67 days late.
5. Click the vendor name to open the vendor profile and initiate payment.

### 11.4 Scenario D — Period-End Reconciliation

**Actor:** Finance Manager
**Goal:** Reconcile vendor liabilities before month-end close
**Steps:**
1. Set date range to the full accounting period (e.g., 01-Jun-2026 to 30-Jun-2026).
2. Compare Total Outstanding Liability against the Accounts Payable general ledger balance.
3. Investigate any material discrepancies by reviewing the table.
4. Export full data for audit trail.
5. Verify that fully paid bills are excluded (zero balance).

### 11.5 Scenario E — Audit Trail Review

**Actor:** External Auditor
**Goal:** Verify aged payables as of a historical date
**Steps:**
1. Set date range to the audit period (e.g., 01-Jan-2026 to 31-Mar-2026).
2. Review the Ageing Distribution chart to verify the school's reported ageing categories.
3. Spot-check 10 table rows against source documents (invoices and payment receipts).
4. Confirm all unpaid balances are positive and no deleted records appear.
5. Use the exported CSV as supporting evidence for the audit file.

### 11.6 Scenario F — Empty State / No Results

**Actor:** Finance Manager
**Condition:** No unpaid bills match the filter criteria
**Behaviour:**
- Summary metrics all show zero or a dash.
- Charts show empty state illustrations.
- Table shows: "No unpaid bills match your filter criteria. Try adjusting the date range or clearing vendor filters."
- A "Clear All Filters" button is shown prominently.

---

## 12. Dependencies

### 12.1 Feature Dependencies

| **Item** | **Relation** |
|---|---|
| Creating a vendor bill (raising an invoice) | Creates the bills that appear in this report |
| Recording a payment to a vendor | Reduces the unpaid balance; fully paid bills drop out of the report |
| Managing vendor records (editing / deleting) | Removing a vendor also removes them from the vendor filter list |

### 12.2 System Feature Flags

| **Flag** | **Default** | **Purpose** |
|---|---|---|
| Vendor Reports enabled | On | Master switch for the entire Vendor Reports section |
| Outstanding Report enabled | On | Switch for this specific report |
| CSV export enabled | On | Turn CSV export on or off |
| Ageing chart enabled | On | Show or hide the Ageing Distribution chart |
| Top 10 chart enabled | On | Show or hide the Top Vendors chart |
| Weekly trend chart enabled | On | Show or hide the Weekly Overdue Trend chart |

---

## 13. Error Handling & Edge Cases

| **Situation** | **What Should Happen** |
|---|---|
| System cannot reach the data | Screen shows "Unable to load report data. Please try again." |
| Report takes too long (over 30 seconds) | Screen shows "Report is taking too long. Narrow your date range." |
| No data for selected filters | Summary shows zeros; charts show empty state; table says "No records found." |
| Invalid date range (from is after to) | The date picker shows an inline error message |
| Vendor list has more than 10,000 vendors | The user must type at least 2 characters to search; results limited to 25 |
| Bill has no due date | The bill shows as "Within Due" with no days-late number |
| Multiple currencies (future need) | Not supported in version 1. Assumes single currency (RM). |

---

## 14. Screen Layout

### 14.1 Page Layout (Top to Bottom)

```
┌──────────────────────────────────────────────────────┐
│  [Breadcrumb]  Reports  >  Vendor  >  Outstanding     │
│                                                        │
│  ┌──────────────────────────────────────────────────┐ │
│  │        GLOBAL FILTER PANEL                        │ │
│  │  Vendor: [▼ ABC Supplies ▼]  Date: [19-Jul-26]   │ │
│  │  Ageing: [All] [0-30] [31-60] [61-90] [90+]      │ │
│  │  Status: [All] [Overdue] [Within Due]             │ │
│  └──────────────────────────────────────────────────┘ │
│                                                        │
│  ┌───────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐  │
│  │Total  │  │Outstanding│  │ Overdue  │  │  Avg    │  │
│  │Liability│  │ Count    │  │ Count    │  │Overdue  │  │
│  │584,720 │  │   142    │  │   89     │  │ 38.7d   │  │
│  └───────┘  └──────────┘  └──────────┘  └─────────┘  │
│                                                        │
│  ┌────────────────────┐ ┌──────────────┐ ┌──────────┐ │
│  │  Aging Distribution│ │ Top 10      │ │ Weekly   │ │
│  │  (Bar Chart)       │ │ Vendors     │ │ Trend    │ │
│  │                    │ │ (Bar Chart) │ │ (Line)   │ │
│  └────────────────────┘ └──────────────┘ └──────────┘ │
│                                                        │
│  ┌──────────────────────────────────────────────────┐ │
│  │  DATA TABLE  (50 rows)                            │ │
│  │  [ ] Inv# | Vendor | Due | Net | Paid | Bal |Days│ │
│  │  [✓] INV001| ABC  |... |...  | ...  | ... | 45  │ │
│  │  [ ] INV002| XYZ  |... |...  | ...  | ... | 12  │ │
│  │  ...                                              │ │
│  │  [<<] [1] [2] [3] [>>]  [Export CSV]             │ │
│  └──────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────┘
```

### 14.2 Responsive Behaviour

| **Screen Width** | **Layout Change** |
|---|---|
| Wide (1200px or more) | Full 3-column chart row; 6 KPI cards in one row |
| Medium (768px – 1199px) | Charts stack to 2+1; KPI cards wrap to 3 per row |
| Narrow (less than 768px) | Charts stack vertically (1 per row); KPI cards wrap to 2 per row; filter panel collapses |

### 14.3 Loading States

| **Component** | **While Loading** |
|---|---|
| Summary KPIs | Grey pulsing rectangles (skeleton cards) |
| Charts | Grey outline shapes with animated bars/lines |
| Data Table | 6 rows of grey pulsing rectangles |
| Filter Panel | Normal — filters are always interactive |

---

## 15. Audit Trail & Logging

| **Event** | **What Is Logged** |
|---|---|
| Report opened | User name, school/tenant, time, IP address |
| Filters changed | User name, the filter values used |
| CSV exported | User name, filter summary, number of rows exported |
| Report timed out | User name, filter values, how long it took before timeout |

---

## 16. Acceptance Criteria

| **#** | **Criterion** | **How to Verify** |
|---|---|---|
| AC-1 | Total Outstanding Liability equals the sum of all unpaid bill balances for the selected filters | Compare with manual addition of known data |
| AC-2 | Ageing bucket counts match manual grouping by days late | Spot-check with known bills |
| AC-3 | Days Overdue for each row = today minus the due date (only for unpaid, past-due bills) | Manual date arithmetic |
| AC-4 | Deleted/archived records are excluded from all metrics, charts, and table | Archive a record; confirm it disappears from the report |
| AC-5 | Changing any filter updates summary, charts, and table all at once | Change a filter; confirm all three sections update |
| AC-6 | CSV export contains the same rows as the filtered table | Compare file to on-screen data |
| AC-7 | Conflicting filters (e.g., "Within Due" + "90+ Days") show a helpful message, not a blank screen | Apply conflicting filters; confirm message appears |
| AC-8 | Date range default is today's date | Open report; check the date picker values |
| AC-9 | Top 10 Vendors chart shows exactly 10 bars (or fewer if data is limited) | Visual inspection |
| AC-10 | Page loads within 5 seconds on a dataset of 50,000 bills | Performance test with load-testing tool |

---

## 17. Revision History

| **Version** | **Date** | **Author** | **Change Description** |
|---|---|---|---|
| 1.0 | 19-Jul-2026 | Prime AI System | Initial creation — comprehensive vendor outstanding report specification |
