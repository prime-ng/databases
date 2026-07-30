# RPT-VND-002 — Agreement Report

---

## 1. Title

**Agreement Report (RPT-VND-002)**

---

## 2. What This Screen Does

The Agreement Report gives school administrators and finance managers a full view of all vendor agreements. It helps track contract values, see which agreements are active, draft, expired, or terminated, spot agreements expiring within the next 30 days, and check invoicing and item details per agreement. The screen combines everything into one dashboard with interactive filters, summary numbers, charts, expiry alerts, and a detailed list.

---

## 3. When Used

- **Monthly/period-end financial review** — Finance managers review contract values and invoices.
- **Pre-renewal planning** — School admin identifies agreements nearing expiry to start renewals.
- **Audit and compliance checks** — Stakeholders verify agreement counts, statuses, and whether documents have been uploaded.
- **Operational oversight** — Daily or weekly check of active agreements, drafts awaiting finalisation, and terminated agreements.
- **Vendor performance reviews** — Analyse top vendors by number of agreements and value across different billing cycles.

---

## 4. Who Can Access

| Role | Permission | Notes |
|------|-----------|-------|
| School Admin | View Vendor Reports | Full access to all vendor agreements for the school |
| Finance Manager | View Vendor Reports | Full access to all vendor agreements for the school |

If a user does not have permission to view vendor reports, the system does not show the report and redirects them with an error message.

---

## 5. How It Works

### 5.1 Filter Panel

A filter panel at the top of the page lets you narrow down what you see. All filters are optional. When no filters are set, the report shows the current month by default.

| Filter | Type | What It Does |
|--------|------|-------------|
| Date Range | Pick a start and end date | Defaults to the first and last day of the current month. The system shows only agreements whose start date falls within this range. |
| Vendor | Searchable dropdown list | Shows all vendors. Selecting a vendor also limits the Agreement and Item dropdowns to that vendor only. |
| Agreement | Searchable dropdown list | Only available after selecting a vendor. Shows agreements belonging to that vendor. Selecting one scopes the whole report to that single agreement. |
| Item | Searchable dropdown list | Only available after selecting a vendor. Shows items linked to that vendor's agreements. Filters the list and summary numbers to agreements that include the selected item. |

#### Cascading Rules

1. The **Vendor** list always shows all active vendors.
2. The **Agreement** list is disabled until a vendor is selected; it then shows only agreements for that vendor.
3. The **Item** list is disabled until a vendor is selected; it then shows only items for that vendor's agreements.
4. When the **Vendor** changes, both **Agreement** and **Item** reset and reload.
5. When **Agreement** is selected, the **Item** filter still works independently.
6. Every filter change refreshes the page results.

### 5.2 How Data Flows

1. When the page loads, the system fetches report data using the default date range (current month).
2. Each time a filter changes, the system fetches fresh data.
3. The response fills four sections: summary metrics, charts, expiry alerts, and the data grid.
4. A loading indicator shows while data is being fetched.
5. If something goes wrong, the system shows a friendly error with a retry option.

---

## 6. Summary Metrics

Four key numbers shown in a row below the filter panel.

| Metric | How It Is Calculated | Formatting |
|--------|---------------------|------------|
| **Total Agreements** | Counts all agreements that are not deleted, applying any active filters | Whole number (e.g. 128) |
| **Status Breakdown** | Groups and counts agreements by their current status | Individual counts shown per status: Active (45), Draft (30), Expired (38), Terminated (15) |
| **Total Contract Value** | Adds together the net payable amounts from invoices on active agreements, applying any active filters | Currency format (e.g. $1,250,000.00) |
| **Expiring Soon** | Counts active agreements whose end date falls within the next 30 days | Whole number (e.g. 7) |

### Visual Layout

```
+--------------------+------------------------+---------------------------+--------------------+
|  Total Agreements  |  Status Breakdown      |  Total Contract Value     |  Expiring Soon     |
|       128          |  Active: 45           |     $1,250,000.00         |        7           |
|                    |  Draft: 30            |                           |                    |
|                    |  Expired: 38          |                           |                    |
|                    |  Terminated: 15       |                           |                    |
+--------------------+------------------------+---------------------------+--------------------+
```

---

## 7. Charts

### 7.1 Status Breakdown (Donut Chart)

- **Type:** Donut chart
- **Segments:** Active, Draft, Expired, Terminated
- **Colours:**
  - Active: green
  - Draft: amber
  - Expired: red
  - Terminated: grey
- **Legend:** Shown below the chart
- **Tooltip shows:** Label, value, and percentage
- **Centre text:** Total of all status counts
- **Resizes:** Yes, fits the screen

### 7.2 Value by Billing Cycle (Bar Chart)

- **Type:** Vertical bar chart
- **Shows:** Total contract value split by billing cycle (Monthly, One-Time, On-Demand)
- **Y-axis:** Total Contract Value in dollars
- **Colour:** Blue
- **Tooltip shows:** Billing cycle and dollar value
- **Gridlines:** Light grey lines on the Y-axis only
- **Resizes:** Yes

### 7.3 Top Vendors by Agreement Count (Bar Chart)

- **Type:** Horizontal bar chart
- **Shows:** Top 10 vendors with the most agreements, sorted highest to lowest
- **Y-axis:** Vendor company names (truncated to 25 characters if long)
- **X-axis:** Number of agreements
- **Colour:** Purple
- **Tooltip shows:** Vendor name and agreement count
- **Resizes:** Yes

---

## 8. Expiry Alert Table

Shows agreements expiring within the next 30 days. Displayed below the charts and above the data grid. Maximum 50 records, sorted by end date (soonest first).

### Columns

| Column | What It Shows | Formatting |
|--------|---------------|------------|
| Agreement Ref No | Agreement reference number | Clickable link to the agreement details |
| Vendor Name | Vendor company name | Plain text |
| Start Date | When the agreement started | e.g. 15 Jan 2026 |
| End Date | When the agreement ends | e.g. 15 Jan 2026. Row is highlighted **red** if 7 or fewer days remain, **amber** if 14 or fewer days remain |
| Days Remaining | How many days until expiry | Number with "days" suffix. Red if 7 or fewer, amber if 14 or fewer |
| Billing Cycle | How the vendor bills | Title case (e.g. Monthly) |
| Status | Current agreement status | Green badge for Active |

### Row Highlighting

| Condition | Style |
|-----------|-------|
| 7 or fewer days remaining | Row background light red, end date and days remaining in bold red with a warning icon |
| 14 or fewer days remaining | Row background light amber, end date and days remaining in amber |
| More than 14 days remaining | No special styling |

### Empty State

If no agreements are expiring in the next 30 days, a success message appears: "No agreements are expiring within the next 30 days."

---

## 9. Data Grid

A paginated, sortable, searchable table showing the full list of agreements based on the filters applied.

### Columns

| Column | Sortable | Filterable | Formatting |
|--------|----------|------------|------------|
| Agreement Ref No | Yes | Yes (text search) | Clickable link to agreement details |
| Vendor Name | Yes | Yes (text search) | Plain text |
| Start Date | Yes | No | e.g. 15 Jan 2026 |
| End Date | Yes | No | e.g. 15 Jan 2026 |
| Billing Cycle | Yes | Yes (choose from All, Monthly, One-Time, On-Demand) | Title case |
| Status | Yes | Yes (choose from All, Active, Draft, Expired, Terminated) | Colour-coded badge |
| Total Invoiced | Yes | No | Currency ($X,XXX.XX) |
| Items Count | Yes | No | Whole number |
| Document Uploaded | No | Yes (choose from All, Yes, No) | Checkmark or cross icon |

### Pagination

- Default: 25 records per page
- Options: 10, 25, 50, 100
- Shows: "Showing 1–25 of 150 results" with page navigation

### Sorting

- Click any column header to sort
- Default sort: newest start date first
- One column at a time
- Arrow icon shows which column is sorted and in which direction

### Search

A search box above the grid lets you type to filter by agreement reference number or vendor name.

---

## 10. Business Rules

### 10.1 Live Aggregation

All summary numbers (total agreements, total contract value, total invoiced) are calculated in real time. No stored snapshots are used.

### 10.2 Deleted Records Excluded

The system always excludes deleted agreements, vendors, and invoices throughout the report.

### 10.3 Expiry Alert (30-Day Threshold)

- Only active agreements with an end date within the next 30 days are included.
- The threshold is fixed at 30 days.

### 10.4 Cascading Filters

When a higher-level filter changes (e.g. vendor), lower-level filters (agreement, item) reset automatically.

### 10.5 Date Range Default

When no date range is selected, the report defaults to the current month (first day to last day).

### 10.6 Chart Rules

| Chart | Rule |
|-------|------|
| Status Breakdown (Donut) | Always show all 4 status segments even if a count is zero |
| Value by Billing Cycle (Bar) | Only show billing cycles that exist in the filtered data. If none, show "No data available." |
| Top Vendors (Horizontal Bar) | Limit to 10 vendors. If fewer than 10 exist, show all. X-axis starts at zero. |

### 10.7 Currency Formatting

All dollar values display with:
- Dollar sign prefix
- Thousands comma separator
- Two decimal places
- Example: $1,250,000.00

### 10.8 Empty State

If no records match the filters:
- Summary metrics show zero or $0.00
- Charts show "No data available"
- Data grid shows "No records found"
- Expiry alert table shows the success message

---

## 11. Success and Failure Scenarios

### 11.1 Success Scenarios

| Scenario | Expected Outcome |
|----------|------------------|
| User with permission loads report with default date range | All four sections show data; only the current month date range is pre-applied |
| User selects a specific vendor | Cascading dropdowns update; all sections refresh to show only that vendor's data |
| User selects a vendor and an agreement | Report focuses on a single agreement; all numbers reflect that one agreement |
| User applies an item filter | Data grid filters to agreements containing that item; summary numbers and charts update |
| User sorts by Total Invoiced descending | Grid reorders with highest invoiced amount first |
| User changes page in the data grid | Next page loads while keeping all filters and sorting |
| Expiry alerts exist | Table shows with appropriate row highlighting based on days remaining |
| No expiry alerts exist | Success banner displayed |

### 11.2 Failure Scenarios

| Scenario | Expected Outcome |
|----------|------------------|
| User without permission tries to access | System redirects to dashboard with error: "You do not have permission to view this report." |
| System error occurs | Screen shows "Failed to load report data. Please try again." with a Retry button |
| Network timeout | Screen shows timeout error after 30 seconds with a retry option |
| Invalid filter value (e.g. nonexistent vendor) | System shows a validation error next to the relevant filter |
| Date range exceeds one year | System rejects with error: "Date to must be within 365 days of date from." |

### 11.3 Validation Rules

| Field | Rule |
|-------|------|
| Date From | Required if Date To is present; must be a valid date |
| Date To | Required if Date From is present; must be on or after Date From and within 365 days of Date From |
| Vendor | Must be an existing vendor |
| Agreement | Must be an existing agreement |
| Item | Must be an existing item |
| Per Page | Must be 10, 25, 50, or 100 |
| Page | Must be at least 1 |

---

## 12. Revision History

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| 1.0 | 2026-07-19 | System | Initial requirement specification for RPT-VND-002 Agreement Report |
