# RPT-VND-001 — Vendor Ledger Summary

---

## 1. Title

| Field | Value |
|-------|-------|
| **Report ID** | RPT-VND-001 |
| **Report Name** | Vendor Ledger Summary |
| **Module** | Vendor (VND) |
| **Type** | Summary / Financial Report |
| **Audience** | Finance Manager, Principal |

---

## 2. What This Screen Does

This screen gives the Principal and Finance Manager a single birds-eye view of every vendor the school does business with. It shows all the important numbers at a glance — how much we owe, how much we have paid, how much is overdue, and how well we are keeping up with our bills. The screen also includes simple charts and a detailed list so you can see the full picture for each vendor.

The screen lets you narrow the view using simple dropdowns (date range, vendor, agreement, item). Every number you see is calculated live from the latest records, so you are always looking at current information.

---

## 3. When Used

| Scenario | How Often |
|----------|-----------|
| Monthly check of how much the school owes vendors | Monthly |
| Principal reviews what the school still owes | As needed / Weekly |
| Finance team matches vendor invoices against payments made | Weekly |
| Daily tracking of payments that are past due | Daily |
| Checking how the school's spending patterns look over time | Quarterly |
| Management reviews how quickly the school pays its bills | Monthly |

---

## 4. Who Can Access

| Role | What They Can Do |
|------|------------------|
| Finance Manager | Full access — can see all vendor information, numbers, charts, and the detailed list |
| Principal | Full access — can see all vendor information, numbers, charts, and the detailed list |

If you are not allowed to view this report, the screen will not open and you will see a message saying you do not have permission.

---

## 5. How It Works

### Overall Flow

1. The Finance Manager or Principal opens the Vendor Ledger Summary screen.
2. The system checks if you are allowed to view the report.
   - If you are not allowed, you see a "permission denied" message.
   - If you are allowed, the report screen opens with all vendors shown.
3. The screen shows filtering options at the top (date range, vendor, agreement, item).
4. As you pick filters, the numbers, charts, and list below update automatically.
5. The system gathers the latest financial data from all vendor invoices and payments, calculates everything on the spot, and presents it clearly.

### How the Dropdown Filters Work

The filter area at the top of the screen has four controls that work from broad to narrow:

| Filter | What It Does |
|--------|--------------|
| **Date Range** | Pick a start date and an end date. The system will only show invoices from that period. Default is the current month. |
| **Vendor** | Pick a specific vendor. Once chosen, the Agreement list will only show agreements for that vendor. |
| **Agreement** | Pick a specific agreement. Once chosen, the Item list will only show items under that agreement. |
| **Item** | Pick a specific item under the chosen agreement. |

**Important rule about these dropdowns:** If you change a higher-level filter (say you switch from one vendor to another), the lower-level filters (Agreement and Item) will be cleared so you don't accidentally see data that belongs to the wrong vendor.

### How the Screen Updates

- Every time you change a filter, the screen pauses briefly (a fraction of a second) to avoid flickering, then fetches the latest numbers.
- The summary cards at the top update with new totals.
- The charts redraw to reflect the new data.
- The detailed list at the bottom refreshes with updated rows.
- All of this happens without reloading the entire page.

---

## 6. Summary Metrics (The 7 Key Numbers)

These seven cards appear at the top of the screen. Each one tells you something important about your vendor finances.

| # | Metric | What It Means | How It Looks |
|---|--------|---------------|--------------|
| 1 | **Total Registered Vendors** | How many vendors we have on file, not counting any that have been removed from the system | A whole number (e.g., 245) |
| 2 | **Active Vendors** | How many vendors are currently marked as active | A whole number, with a subtitle like "189 of 245 active" |
| 3 | **Total Invoiced** | The total dollar amount of all invoices we have received from vendors that are in a valid status (not draft, not cancelled) | A dollar amount (e.g., $1,250,000.00) |
| 4 | **Total Paid** | The total dollar amount we have successfully paid to vendors so far | A dollar amount (e.g., $875,000.00) |
| 5 | **Total Outstanding** | What remains unpaid — this is Total Invoiced minus Total Paid | A dollar amount (e.g., $375,000.00) |
| 6 | **Total Overdue** | Invoices that are past their due date and still have money owing | A dollar amount (e.g., $42,500.00) |
| 7 | **Collection Rate** | The percentage of our bills that we have paid so far. Calculated as Total Paid divided by Total Invoiced, multiplied by 100. | A percentage (e.g., 70.00%). Shows a color bar: green if 80% or above, amber between 50% and 79%, red below 50% |

### How Each Card Looks

- Each card has a label (the metric name), the value, and a small picture/icon.
- Money amounts show the currency symbol (e.g., $).
- The Collection Rate card shows a progress bar colored green, amber, or red.
- Active Vendors shows an extra line like "189 of 245 active".
- Cards are arranged in rows: 4 cards on the first row, 3 on the second row on a computer screen.

---

## 7. Charts (3 Visual Summaries)

### Chart A — Spend by Vendor Type (Pie/Doughnut Chart)

**Title:** Spend by Vendor Type

This chart looks like a circle cut into slices. Each slice represents a type of vendor (for example, Corporate, Individual, Government). The bigger the slice, the more money we have invoiced from that type of vendor.

- Shows the total invoiced amount broken down by vendor type.
- Hover your mouse over a slice to see the exact dollar amount and percentage.
- A legend below the chart tells you which color goes with which vendor type.

### Chart B — Top 5 Outstanding Vendors (Bar Chart)

**Title:** Top 5 Outstanding Vendors

This chart shows bars — one bar for each of the five vendors that we owe the most money to. The taller the bar, the more we owe that vendor.

- Only the top 5 vendors with the highest outstanding balance are shown.
- The vendor names are listed along the side, and the dollar amounts are shown as bars.
- Useful for quickly identifying which vendors need to be paid first.

### Chart C — Monthly Billing Trend (Bar and Line Chart)

**Title:** Monthly Billing Trend

This chart shows how our invoicing and payments have changed month by month. It has two things shown together:
- **Bars** showing how much we were invoiced each month.
- **A line** showing how much we paid each month.

This lets you see at a glance whether our payments are keeping up with the invoices coming in.

### Chart Rules That Apply to All Three

- All charts update automatically when you change the date range or any filter.
- If no data matches your filters, the chart area says "No data available."
- Hovering over any chart element shows the exact numbers.
- Colors match the school's standard chart color scheme.
- Legend for the pie chart is below it; for bar and line charts it is to the right.

---

## 8. Data Grid (The Detailed Vendor List)

Below the charts is a table with one row per vendor. Each row shows the following information:

| # | Column Name | What It Shows |
|---|-------------|---------------|
| 1 | **Vendor Name** | The registered name of the vendor |
| 2 | **Vendor Type** | Whether the vendor is an individual, a company, a government agency, etc. |
| 3 | **Contact Person** | The name of the person we deal with at the vendor |
| 4 | **Contact Number** | The phone number for the contact person |
| 5 | **Total Agreements** | How many agreements we have with this vendor |
| 6 | **Active Agreements** | How many of those agreements are currently active |
| 7 | **Total Invoices** | How many invoices this vendor has sent us |
| 8 | **Total Invoiced Amount** | The total dollar amount of all invoices from this vendor |
| 9 | **Total Paid Amount** | The total dollar amount we have paid to this vendor |
| 10 | **Outstanding Amount** | Total Invoiced minus Total Paid — what we still owe |
| 11 | **Overdue Amount** | Invoices that are past due and still unpaid |
| 12 | **Last Invoice Date** | The date of the most recent invoice from this vendor |
| 13 | **Last Payment Date** | The date we last made a payment to this vendor |

### How the List Behaves

| Feature | How It Works |
|---------|--------------|
| **Page size** | 25 vendors shown at a time by default; you can change to 10, 25, 50, or 100 |
| **Sorting** | Click any column heading to sort the list by that column. Default sort is by Outstanding Amount from highest to lowest. |
| **Search** | A search box lets you type in a vendor name, type, or contact person to filter the list quickly |
| **Export** | Buttons to download the list as a CSV file, an Excel file, or a PDF (respects your current filters and sort order) |
| **Click a row** | Clicking any vendor row takes you to a detailed report just for that vendor |
| **When nothing matches** | Shows the message "No vendors match the selected filters." |
| **While loading** | Shows a placeholder or spinner while the data is being fetched |
| **On small screens** | Some columns hide to keep the important info visible; Vendor Name and Outstanding Amount always stay |

---

## 9. Business Rules

### 9.1 Live Numbers — No Storing Old Copies

Every number on this screen is calculated right when you ask for it. Nothing is stored or reused from an earlier calculation. This is important because financial data must always be current and accurate.

### 9.2 Hiding Removed Records

Any vendor, agreement, invoice, or payment that has been removed from the system is not counted anywhere on this screen — not in the summary numbers, not in the charts, not in the list.

### 9.3 Which Invoices Count

Only invoices in these statuses are included in the financial totals:
- **Counted:** Active, Approved, Submitted
- **Not counted:** Draft, Cancelled, Void, Rejected

Only payments that were successfully completed are counted in Total Paid and Collection Rate.

### 9.4 Default Date Range

When you first open the screen, the date range is set to the current month (from the 1st to the last day). If you clear the date range entirely, the system shows data for all time.

### 9.5 Cascading Dropdown Rules

- Choosing a vendor limits the Agreement list to that vendor's agreements only.
- Choosing an agreement limits the Item list to that agreement's items only.
- Changing the vendor clears both the Agreement and Item selections.
- Changing the agreement clears the Item selection.
- If no vendor is selected, the Agreement and Item dropdowns are greyed out and can't be used.
- Any time a filter changes, the numbers, charts, and list update automatically.

### 9.6 Currency Display

- All money amounts show the currency symbol (e.g., $) with commas for thousands and two decimal places.
- Zero amounts show as $0.00.
- The currency symbol can be changed in the school's system settings.

### 9.7 Protecting Against Division by Zero

The Collection Rate is calculated by dividing Total Paid by Total Invoiced. If Total Invoiced is zero (no invoices), the Collection Rate is shown as 0% instead of causing an error.

### 9.8 Dates and Timezone

All dates follow the school's configured timezone. "Today" means the current date in the school's timezone. Date ranges include both the start and end dates.

### 9.9 How Payments Link to Invoices

Payments are linked to specific invoices. Invoices are linked to vendors either directly or through agreements. The system correctly follows these links so that each vendor's totals are accurate.

---

## 10. Success Scenario

**Who:** Finance Manager
**When:** July 15, 2026

1. Finance Manager opens Vendor → Reports → Vendor Ledger Summary.
2. The screen loads with the date range set to July 1–31, 2026. All vendors are shown.
3. The seven summary cards show:
   - Total Registered Vendors: 245
   - Active Vendors: 189 of 245 active
   - Total Invoiced: $1,250,000.00
   - Total Paid: $875,000.00
   - Total Outstanding: $375,000.00
   - Total Overdue: $42,500.00
   - Collection Rate: 70.00%
4. The pie chart shows spending by vendor type:
   - Corporate: $625,000 (50%)
   - Individual: $375,000 (30%)
   - Government: $250,000 (20%)
5. The bar chart shows the top 5 vendors we owe money to:
   - ABC Corp: $85,000
   - XYZ Ltd: $62,000
   - Mega Supplies: $48,000
   - Tech Partners: $35,000
   - Global Services: $22,000
6. The list shows 245 vendors, sorted by highest outstanding amount first.
   - Row 1: ABC Corp | Corporate | John Smith | +1-555-0100 | 5 agreements | 3 active | 12 invoices | $250,000 invoiced | $165,000 paid | $85,000 outstanding | $12,000 overdue | 2026-07-10 | 2026-07-05
7. Finance Manager selects Vendor = "ABC Corp" from the dropdown.
8. The Agreement dropdown now shows only the 5 agreements for ABC Corp. The Item dropdown becomes available.
9. The numbers update to show only ABC Corp data:
   - Total Invoiced: $250,000.00
   - Total Paid: $165,000.00
   - Total Outstanding: $85,000.00
   - Collection Rate: 66.00%
10. Finance Manager selects Agreement = "Supply Agreement 2026".
11. The Item dropdown shows 3 items under that agreement.
12. The screen refreshes with data for that agreement only.
13. Finance Manager exports the list to Excel for further analysis.

---

## 11. What Could Go Wrong

| # | Problem | What the System Does | Message You See |
|---|---------|---------------------|-----------------|
| 1 | Someone who isn't allowed tries to open the report | The screen does not open | "You do not have permission to view this report." |
| 2 | No data matches the filters you selected | All numbers show $0 or 0; charts say no data; list is empty | "No vendors match the selected filters." |
| 3 | The system cannot connect to the data source | Error notification appears | "Unable to load report data. Please try again later." |
| 4 | The request takes too long (over 30 seconds) | The loading indicator times out | "Request timed out. Please try again or narrow your filter criteria." |
| 5 | You pick a start date that is after the end date | The screen prevents you from submitting | "The start date must be before the end date." |
| 6 | The system cannot calculate the Collection Rate (no invoices) | Gracefully shows 0% | 0% displayed (no error) |
| 7 | The vendor list fails to load | Agreement and Item dropdowns stay disabled | "Failed to load vendor list." |

---

## 12. Example Walkthrough

**User:** Finance Manager
**Date:** July 15, 2026

**Step-by-step:**
1. Finance Manager opens Vendor → Reports → Vendor Ledger Summary
2. Screen loads with date range July 1–31, 2026
3. Summary cards show all vendors' numbers
4. Pie chart shows spending split by vendor type
5. Bar chart shows top 5 vendors we owe the most
6. List shows all 245 vendors sorted by outstanding amount
7. Finance Manager picks "ABC Corp" from Vendor dropdown
8. Agreement list updates to show only ABC Corp's agreements
9. Numbers and charts now show only ABC Corp data
10. Finance Manager picks "Supply Agreement 2026" from Agreement dropdown
11. Item dropdown shows 3 items under that agreement
12. Screen refreshes for just that agreement
13. Finance Manager clicks Export to download the data as an Excel file

---

## 13. Related Screens

| Screen | Name | How They Connect |
|--------|------|------------------|
| RPT-VND-002 | Vendor Ledger Detail | Click a vendor row to see detailed transactions for that vendor |
| RPT-VND-003 | Vendor Payment History | Shows all payments made to a selected vendor |
| MNT-VND-001 | Vendor Master List | The main screen where vendor information is managed |
| RPT-VND-004 | Vendor Aging Report | Focuses on how overdue invoices are spread across different time periods |
| RPT-VND-005 | Vendor Spend Analysis | Looks at spending patterns and trends in more detail |
| RPT-VND-006 | Agreement Summary Report | Shows financial summaries grouped by agreement |

---

## 14. Dependencies

### 14.1 Information That Must Exist

For this screen to work properly, the following information must already be recorded in the system:

| What's Needed | Why |
|---------------|-----|
| Vendor master list | Basic information about every vendor |
| Agreement records | Agreements linking vendors to what they supply |
| Invoice records | All financial invoices from vendors |
| Payment records | Records of payments made to vendors |
| Agreement item records | Individual line items under each agreement |
| Lookup values for vendor types | The categories vendors are sorted into (Corporate, Individual, etc.) |

### 14.2 Technical Building Blocks

| Component | Purpose |
|-----------|---------|
| Code that generates the report screen | Produces the page layout with filters, cards, charts, and list |
| The report page template | The visual layout of the report screen |
| Permission check | Makes sure only authorized users can view the report |
| Chart-drawing tool | Draws the pie, bar, and line charts |
| Table/grid tool | Makes the list sortable, searchable, and pageable |
| Communication layer | Handles sending filter choices to the system and receiving updated data |

### 14.3 System Settings That Affect This Screen

| Setting | Why It Matters |
|---------|----------------|
| Currency symbol (e.g., $) | Controls how money amounts are displayed |
| Date format | Controls how dates appear throughout the screen |
| Timezone | Ensures "today" and overdue calculations use the correct date |
| Page size defaults | Determines how many rows show per page by default |

---

## 15. Revision History

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| 1.0 | 2026-07-19 | System | Initial requirement specification for RPT-VND-001 Vendor Ledger Summary |

---

*End of Document — RPT-VND-001 Vendor Ledger Summary Requirement*
