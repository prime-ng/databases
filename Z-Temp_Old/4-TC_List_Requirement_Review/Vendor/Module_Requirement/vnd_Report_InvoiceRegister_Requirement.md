# RPT-VND-003 — Invoice Register

| **Field**              | **Value**                            |
|------------------------|--------------------------------------|
| **Report Code**        | RPT-VND-003                          |
| **Report Name**        | Invoice Register                     |
| **Module**             | Vendor Management (VND)              |
| **Audience**           | Accountant, Finance Manager          |
| **Version**            | 1.0                                  |
| **Status**             | Draft                                |

---

## 1. What This Report Does

The Invoice Register gives a complete, up-to-the-minute view of every vendor invoice in the organisation. It brings together invoice details, vendor names, agreement references, line items, and payment records in one screen. Accountants and finance managers can:

- See the full lifecycle of each invoice — from when it was raised to when it was fully paid.
- Track what is still owed and spot overdue items quickly.
- Review spending patterns by vendor, agreement, and time period.
- Check that invoice and payment records are accurate and complete.
- Get insights from summary figures, visual charts, and a sortable list of records.

This report is the single source of truth for reconciling vendor invoices and maintaining financial control.

---

## 2. When This Report Is Used

| **Frequency**      | **Use Case**                                                              |
|--------------------|---------------------------------------------------------------------------|
| Daily              | Accounts payable clerk matches incoming payments against invoices.        |
| Weekly             | Finance manager reviews outstanding balances and upcoming cash needs.     |
| Month-End          | Accountant runs the report to verify month-end accruals and provisions.   |
| Quarter-End        | Management reviews vendor spending trends and how agreements are used.    |
| Audit              | Internal or external auditors trace invoices through to payments.         |
| Ad Hoc             | Any user investigates a specific invoice, vendor, or payment discrepancy. |

---

## 3. Who Can Access

| **Role**            | **Permission Needed**                | **What They See**            |
|---------------------|--------------------------------------|------------------------------|
| Accountant          | View vendor reports                  | All data for the organisation |
| Finance Manager     | View vendor reports                  | All data for the organisation |
| Auditor             | View vendor reports                  | Read-only                    |
| System Admin        | Inherits all permissions             | Full access                  |

> The system checks if you are allowed before showing the report. If you do not have the right permission, the report is not shown and you receive a message that access is denied.

---

## 4. How the Report Works

### 4.1 Filter Panel

A set of filters sits at the top of the screen and controls everything below — the summary figures, the charts, and the list of records. Each time you change a filter, the report refreshes automatically.

| **Filter**       | **What You See**          | **Where the Data Comes From**                    | **How It Works**                                                   |
|------------------|---------------------------|--------------------------------------------------|--------------------------------------------------------------------|
| Vendor           | Drop-down, pick multiple  | Active vendors                                   | Shows only the vendors you select; limits the agreement list too.  |
| Date Range       | Calendar, pick a from/to  | Invoice date                                     | Starts with the first of this month up to today.                   |
| Status           | Drop-down, pick multiple  | Calculated on the fly (fully paid / partially paid / pending) | Filters by whether the invoice is paid, partly paid, or unpaid. |
| Agreement        | Drop-down, pick multiple  | Active agreements                                | Only appears when you have selected at least one vendor.           |
| Invoice Number   | Text box                  | Invoice number                                   | Type part of a number to find matching invoices.                   |

### 4.2 How the Report Gets Its Data

1. You open the report. The system checks who you are and whether you are allowed to view it.
2. The system reads the filters you have set (or uses the defaults).
3. It pulls together information from invoices, vendors, agreements, items, and payments.
4. The results are organised into three sections:
   - **Summary figures** — totals and counts.
   - **Charts** — three visual graphs.
   - **Record list** — a page-by-page view of individual invoices.
5. The screen updates to show all of this information.

### 4.3 What the Report Sends Back

When you open the report, the system returns:

- **Summary** — total number of invoices, a breakdown by status, total net payable, total tax, and total discounts.
- **Charts** — a status breakdown chart, a monthly trend over time, and the top vendors by amount billed.
- **Record list** — individual invoice rows sorted by date, shown in pages (25 per page by default). Each row shows the invoice number, vendor, agreement, item, dates, amounts, and payment status.

---

## 5. Summary Metrics

The summary section shows five key figures at the top. All numbers update in real time based on whatever filters you have set.

### 5.1 Total Invoices

| **Attribute**     | **Specification**                                                   |
|------------------|---------------------------------------------------------------------|
| **Label**         | Total Invoices                                                      |
| **What It Shows** | The number of active (not cancelled) invoices that match the current filters. |
| **Formatting**    | Whole number with commas (e.g., "284")                              |
| **Tooltip**       | "Total number of active invoices matching filters."                 |

### 5.2 Status Breakdown

| **Attribute**     | **Specification**                                                   |
|------------------|---------------------------------------------------------------------|
| **Label**         | Status Breakdown                                                    |
| **Values**        | Fully Paid, Partially Paid, Pending                                 |
| **Formatting**    | Three counters with colours:                                        |
|                   | - Fully Paid: green                                                  |
|                   | - Partially Paid: amber                                              |
|                   | - Pending: red                                                       |
| **Tooltip**       | "Count of invoices grouped by payment status."                      |

**How status is determined:**
- If no payments exist at all → **Pending**
- If total payments are greater than zero but less than the full invoice amount → **Partially Paid**
- If total payments equal or exceed the invoice amount → **Fully Paid**

### 5.3 Total Net Payable

| **Attribute**     | **Specification**                                                   |
|------------------|---------------------------------------------------------------------|
| **Label**         | Total Net Payable                                                   |
| **What It Shows** | The total amount owed across all selected invoices.                 |
| **Formatting**    | Currency, 2 decimal places (e.g., "$1,584,290.50")                  |
| **Tooltip**       | "Sum of net payable across all selected invoices."                  |

### 5.4 Total Tax

| **Attribute**     | **Specification**                                                   |
|------------------|---------------------------------------------------------------------|
| **Label**         | Total Tax                                                           |
| **What It Shows** | The total tax charged across all selected invoices.                 |
| **Formatting**    | Currency, 2 decimal places                                          |
| **Tooltip**       | "Sum of tax amounts across all selected invoices."                  |

### 5.5 Total Discount

| **Attribute**     | **Specification**                                                   |
|------------------|---------------------------------------------------------------------|
| **Label**         | Total Discount                                                      |
| **What It Shows** | The total discounts applied across all selected invoices.           |
| **Formatting**    | Currency, 2 decimal places                                          |
| **Tooltip**       | "Sum of discount amounts across all selected invoices."             |

---

## 6. Charts

Three interactive charts help you see the data visually. All charts update when you change the filters.

### 6.1 Invoice Status Distribution (Column Chart)

| **Attribute**     | **Specification**                                                   |
|------------------|---------------------------------------------------------------------|
| **Chart Type**    | Vertical column chart                                               |
| **Horizontal Axis** | Status: "Fully Paid", "Partially Paid", "Pending"                 |
| **Vertical Axis**   | Number of invoices                                                  |
| **Colours**       | Fully Paid = green, Partially Paid = amber, Pending = red           |
| **Legend**        | Hidden (the labels on the axis are clear enough)                    |
| **Tooltip**       | "{status}: {count} invoices ({percentage}%)"                        |

**What it tells you:** How many invoices are fully settled versus still outstanding — at a glance.

### 6.2 Monthly Volume/Amount Trend (Line Chart)

| **Attribute**     | **Specification**                                                   |
|------------------|---------------------------------------------------------------------|
| **Chart Type**    | Line chart with two scales                                          |
| **Horizontal Axis** | Month and year (e.g., "Jan 2026")                                 |
| **Left Scale**    | Number of invoices (blue line)                                      |
| **Right Scale**   | Total amount (green line)                                           |
| **Legend**        | Visible: "Invoice Count" / "Total Amount"                           |
| **Tooltip**       | "{month}: {count} invoices, {amount} total"                         |

**What it tells you:** Whether invoice volume and total amounts are going up or down month by month, and any seasonal patterns.

### 6.3 Top Billing Vendors (Bar Chart)

| **Attribute**     | **Specification**                                                   |
|------------------|---------------------------------------------------------------------|
| **Chart Type**    | Horizontal bar chart                                                |
| **Horizontal Axis** | Total amount billed (currency)                                    |
| **Vertical Axis**   | Vendor name (top 10 by total amount billed)                        |
| **Colour**        | Purple                                                              |
| **Legend**        | Hidden                                                              |
| **Tooltip**       | "{vendor_name}: {net_payable}"                                      |
| **Limit**         | Shows the 10 vendors with the highest totals                        |

**What it tells you:** Which vendors your organisation owes the most to — useful for negotiating terms, consolidating spending, or checking for over-concentration.

---

## 7. Record List

The main list shows one invoice per row, sorted by date with the newest first. You can flip through pages (25 per page) and click any column heading to sort by that column.

### 7.1 Columns

| **Column**        | **What It Shows**                                  | **Formatting**                  | **Can Sort?** | **Can Filter?** |
|-------------------|----------------------------------------------------|--------------------------------|:------------:|:--------------:|
| Invoice Number    | Invoice number                                     | Plain text                     | Yes          | Yes            |
| Vendor Name       | Vendor name                                        | Plain text                     | Yes          | Yes (via panel)|
| Agreement Ref     | Agreement reference number                         | Plain text                     | Yes          | No             |
| Item Name         | Item or service name                               | Plain text                     | Yes          | No             |
| Invoice Date      | Date invoice was issued                            | DD-MMM-YYYY (e.g., 15-Jun-2026)| Yes          | Yes (via panel)|
| Due Date          | Payment due date                                   | DD-MMM-YYYY                    | Yes          | No             |
| Net Payable       | Amount owed on the invoice                         | Currency, 2 decimal places     | Yes          | No             |
| Amount Paid       | Total paid so far                                  | Currency, 2 decimal places     | Yes          | No             |
| Balance Due       | Amount still owed (cannot go below zero)           | Currency, 2 decimal places     | Yes          | No             |
| Status            | Fully Paid / Partially Paid / Pending              | Coloured badge                 | Yes          | Yes (via panel)|

### 7.2 How Status is Determined

| **Condition**                                                        | **Status**       | **Badge Colour** |
|----------------------------------------------------------------------|------------------|:----------------:|
| Amount paid equals or exceeds the net payable                       | Fully Paid       | Green            |
| Some payment received but less than the full amount                 | Partially Paid   | Amber            |
| No payment received at all                                           | Pending          | Red              |

> **Overdue warning:** If the due date has passed and the invoice is not fully paid, the due date shows in bold red with an icon and a message saying how many days overdue.

### 7.3 What You Can Do in the List

| **Feature**         | **How It Works**                                                      |
|---------------------|-----------------------------------------------------------------------|
| Click a row         | Opens the full details for that invoice.                              |
| Sort by column      | Click a column heading to sort ascending or descending. Default: newest invoices first. |
| Change page size    | Choose 25, 50, or 100 rows per page.                                  |
| Resize columns      | Drag column edges to resize; your preference is saved.                |
| Export              | Download the filtered data as CSV or Excel.                           |
| Search within list  | Type to search across visible rows (or the system searches the full set if there are more than 500 rows). |

### 7.4 When No Records Are Found

If no invoices match your filters, the list shows:

> "No invoices found matching the current filters. Try adjusting your search criteria or clearing one or more filters."

A **"Clear All Filters"** button appears to reset everything.

---

## 8. Business Rules

### 8.1 Live Calculations

All figures, charts, and list data are calculated at the moment you view the report. Nothing is stored or cached — you always see the latest information. The only exception is the vendor and agreement lists for the filter dropdowns, which may be temporarily saved for up to 5 minutes to speed up loading.

### 8.2 Cancelled Records Are Excluded

Any record that has been flagged as deleted or cancelled is never included in totals, charts, or the record list. This ensures that deleted invoices, vendors, agreements, items, and payments do not distort your financial figures.

### 8.3 Only Active Invoices Count

Invoices marked as inactive (cancelled, voided, or reversed) are excluded from all calculations. Even if payments were recorded against them, they never appear in the report.

### 8.4 Payment Status Rules

| **Scenario**                                    | **Status**       | **What It Means**                                               |
|-------------------------------------------------|------------------|-----------------------------------------------------------------|
| No payments received                            | Pending          | Invoice raised but nothing paid yet.                            |
| Payments received but less than the full amount | Partially Paid   | Some money received; a balance is still outstanding.            |
| Payments received equal to or more than owed    | Fully Paid       | Invoice is settled.                                             |
| More paid than the invoice amount               | Fully Paid       | The extra amount (overpayment) is handled separately through a credit note or adjustment — it does not change the status. |

**Edge cases to be aware of:**

- **Overpayment:** If more has been paid than the invoice amount, the status stays "Fully Paid". The balance due shows as zero. Overpayments are tracked in a separate credit-on-account report.
- **Zero-value invoice:** If the net payable is zero, the status is immediately "Fully Paid".
- **Multiple payments:** All payments on an invoice are added together before comparing against the invoice amount.

### 8.5 How Filters Work Together

Selecting a vendor limits the agreement list to only that vendor's agreements. The chain works like this:

```
Vendor(s) → Agreement(s) → Item(s)
```

The **Status** filter works independently — it does not affect the vendor, agreement, or item lists, and those do not affect it.

### 8.6 Default Date Range

When you open the report without setting a date range, it automatically shows:
- **From:** The first day of the current month
- **To:** Today

For example, on 19 July 2026, the default range is 1 July 2026 to 19 July 2026.

### 8.7 Chart Rules

| **Chart**                  | **When There Are Zeros**                                | **When Everything Is Empty**                         | **Data Limit** |
|----------------------------|---------------------------------------------------------|------------------------------------------------------|:--------------:|
| Status Distribution        | Statuses with zero invoices are left out.               | Shows a "No Data" placeholder.                       | 3 columns      |
| Monthly Trend              | Months with no data are skipped.                        | Shows an empty chart with "No Data" message.         | 24 months max  |
| Top Billing Vendors        | Vendors with zero amounts are left out.                 | Shows empty chart with "No Data" message.            | Top 10         |

### 8.8 Access Rules

| **Situation**                                            | **What Happens**                                        |
|-----------------------------------------------------------|---------------------------------------------------------|
| You do not have permission to view vendor reports         | You see a message: "You do not have permission to view the Invoice Register report." |
| Your session is not valid or the organisation is not recognised | You see an access error message.                  |

---

## 9. Scenarios

### 9.1 Normal Use — Full Data Set

**Given:** A finance manager opens the Invoice Register with no filters.
**When:** The report loads with the default date range (current month to today).
**Then:**
- Summary figures show accurate counts and totals for the period.
- Status Distribution chart shows three columns in proportion.
- Monthly Trend chart shows a single data point (the current month).
- Record list shows all invoices sorted newest first, 25 per page.
- Each row shows the correct status, balance due, and amount paid.

### 9.2 Filter by a Specific Vendor

**Given:** A user selects "Acme Corp" from the Vendor list.
**When:** The filter is applied.
**Then:**
- The Agreement list shows only Acme Corp agreements.
- Summary figures, charts, and the record list all show only Acme Corp data.

### 9.3 Filter by Status (Pending Only)

**Given:** A user selects "Pending" in the Status filter.
**When:** The filter is applied.
**Then:**
- Total Invoices count updates; Status Breakdown shows only "Pending".
- Status Distribution chart shows only the "Pending" column.
- Monthly Trend shows only pending invoices.
- Top Billing Vendors shows only vendors with pending invoices.
- Record list shows only pending invoices (amount paid = zero).

### 9.4 Date Range Boundary

**Given:** A user selects a date range of 1 January 2026 to 31 January 2026.
**When:** The filter is applied.
**Then:**
- Only invoices dated in January 2026 appear.
- If January is within the last 24 months, the Monthly Trend chart shows a single point for that month.
- If no invoices exist in that range, the list shows the empty state message.

### 9.5 No Data / Empty State

**Given:** Filters are set to criteria that match zero invoices.
**When:** The report refreshes.
**Then:**
- Summary figures show 0 or $0.00.
- Status Breakdown shows all three at 0.
- Each chart shows its "No Data" placeholder.
- Record list shows the empty state message with the "Clear All Filters" button.

### 9.6 Invoice with Overpayment

**Given:** An invoice shows net payable = $1,000.00 and total payments = $1,050.00.
**When:** The report processes this invoice.
**Then:**
- Amount Paid = $1,050.00.
- Balance Due = $0.00.
- Status = Fully Paid.
- The overpayment is not flagged here; the credit-on-account workflow handles it.

### 9.7 Invoice with Multiple Line Items

**Given:** An invoice is linked to an agreement with three items: "Paper", "Pens", "Folders".
**When:** The list displays.
**Then:**
- Item Name column shows "Folders, Paper, Pens" in alphabetical order.
- Hovering over the cell shows the full list.

### 9.8 Invoice with No Agreement

**Given:** An invoice is not linked to any agreement.
**When:** The list displays.
**Then:**
- Agreement Ref shows a dash.
- Item Name shows a dash.
- All other columns show normally.
- The invoice is still included in all figures and charts.

### 9.9 Unauthorised Access Attempt

**Given:** Someone without permission tries to view the report.
**When:** They try to open it.
**Then:**
- They see an error message: "You do not have permission to view the Invoice Register report."
- The report page does not show.

### 9.10 Large Amount of Data

**Given:** The organisation has 50,000+ invoices across many vendors.
**When:** The report loads with default filters (current month only).
**Then:**
- The report loads in under 3 seconds.
- The list shows 25 rows per page.
- The system is set up to handle this volume efficiently.

### 9.11 Multiple People Using the Report at the Same Time

**Given:** Three accountants open the report at the same time for the same organisation.
**When:** Each applies different filters.
**Then:**
- Each person sees only their own filtered results.
- No data gets mixed up between users.
- Everything runs smoothly without delays.

### 9.12 Data Isolation Between Organisations

**Given:** Two different organisations both have an invoice numbered "42".
**When:** An accountant from the first organisation opens the report.
**Then:**
- Only their organisation's invoice shows.
- The other organisation's data is completely invisible.

---

## 10. Dependencies

### 10.1 Records and Files the Report Relies On

| **Record Type**            | **Is It Required?** | **Notes**                                              |
|----------------------------|---------------------|--------------------------------------------------------|
| Invoices                   | Required            | Main source of data.                                   |
| Vendors                    | Required            | Vendor names and details.                              |
| Agreements                 | Optional            | Agreement references, if invoices are linked to one.   |
| Agreement-Item Links       | Optional            | Links between agreements and items.                    |
| Items                      | Optional            | Item or service descriptions.                          |
| Payments                   | Required            | Payment records against invoices.                      |

### 10.2 Performance Settings

| **Setting**                        | **Expected Value**      | **Effect**                                            |
|------------------------------------|-------------------------|-------------------------------------------------------|
| Time zone                          | UTC                     | All date comparisons are in UTC.                      |
| Default page size                  | 25 rows                 | How many rows show per page.                          |
| Maximum page size                  | 100 rows                | The most rows you can show per page.                  |
| Data caching                       | Off                     | Figures are always live, never cached.                |
| Maximum months in Monthly Trend    | 24 months               | The chart does not go further back than 2 years.      |

### 10.3 Error Messages

| **Error Code**   | **What Happens**                                         |
|------------------|----------------------------------------------------------|
| VND-REP-003-01   | You do not have permission to view the Invoice Register. |
| VND-REP-003-02   | Invalid or missing organisation context.                 |
| VND-REP-003-03   | Invalid date range (the from date must be before the to date). |
| VND-REP-003-04   | Page size out of bounds (maximum 100).                   |
| VND-REP-003-05   | Something went wrong while generating the report.        |

---

## 11. Change History

| **Version** | **Date**   | **Author**   | **Description**                     |
|-------------|------------|--------------|-------------------------------------|
| 1.0         | 2026-07-19 | System       | Initial requirement specification.  |

---

*End of Requirement Document — RPT-VND-003*
