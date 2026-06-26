# Vendor Reports — Business Requirements

## What This Screen Does

The Vendor Reports screen serves as a centralized intelligence hub that provides deep, real-time reporting and financial insights across the school's entire vendor ecosystem. Rather than offering a single flat report, it is structured as a multi-tab analytical dashboard that aggregates data from all facets of vendor operations: registrations, active agreements, invoices, payments, and outstanding liabilities.

Think of this screen as the primary tool for the school's internal auditing, budgeting, and financial planning. It allows finance directors, accountants, and school administrators to monitor where money is being spent, assess contract performance, track historical payment rates, and identify overdue balances before they impact vendor relationships.

---

## When This Screen Is Used

- **Year-End / Monthly Auditing**: Accountants pull complete billing registers, paid amounts, and tax figures to close financial books.
- **Cash Flow Planning**: Finance managers review outstanding aging lists to prioritize vendor payouts.
- **Contract Audits**: Administrative staff examine expiring agreements to decide on renewals or terminations.
- **Payment Verification**: Admins audit vendor transactions to resolve payment discrepancy claims.
- **Budgeting & Spend Analysis**: School heads evaluate spending distribution by vendor type to renegotiate pricing terms.

---

## Key Report Types and Metrics

### 1. Vendor Ledger Summary Report
Provides a high-level summary of each vendor's complete transactional profile within a specified date range.

* **Summary Metrics**:
  * **Total Registered Vendors**: Overall count of vendors mapped in the system.
  * **Active Vendors**: Count of vendors actively conducting business.
  * **Total Invoiced**: Total billing commitments generated in the selected period.
  * **Total Paid**: Total amount successfully disbursed to vendors.
  * **Total Outstanding**: Remaining unpaid liability for the period.
  * **Total Overdue**: Unpaid amount past the respective invoice due dates.
  * **Payment Collection Rate (%)**: A percentage tracking payment efficiency (`Total Paid / Total Invoiced * 100`).
* **Visual Charts**:
  * **Spend Breakdown by Vendor Type**: Pie/donut chart illustrating spending distribution across categories (e.g., Transport, Food, Security).
  * **Top Outstanding Vendors**: Bar chart listing the top 5 vendors with the highest unpaid balances.
  * **Monthly Billing Trend**: Bar/Line chart comparing invoiced vs paid amounts month-by-month.
* **Data Grid Fields**:
  * Vendor Name, Vendor Type, Contact Person, Contact Number, Total Agreements, Active Agreements, Total Invoices, Total Invoiced Amount, Total Paid Amount, Total Outstanding Amount, Overdue Amount, Last Invoice Date, Last Payment Date, Active Status.

### 2. Agreement Report
Tracks active contracts, billing frequencies, and agreement lifecycles to ensure school compliance.

* **Summary Metrics**:
  * **Total Agreements**: Total count of all legal contracts.
  * **Status Breakdown**: Count of agreements grouped by status (Active, Draft, Expired, Terminated).
  * **Total Contract Value**: Total value of invoices generated under active agreements.
* **Visual Charts**:
  * **Agreement Status Breakdown**: Donut chart showing percentages of active vs draft vs expired contracts.
  * **Value by Billing Cycle**: Value distribution across different cycle terms (Daily, Weekly, Monthly, Annual).
  * **Top Vendors by Contract Count**: Displays vendors with the highest number of agreements.
* **Agreements Expiring Soon Alerts**:
  * A dedicated table listing active agreements expiring within the next 30 days, promoting timely renewal conversations.
* **Data Grid Fields**:
  * Agreement Ref No, Vendor Name, Start Date, End Date, Billing Cycle, Status, Invoiced Value, Items Covered.

### 3. Invoice Register
Logs all individual billing invoices received from vendors.

* **Summary Metrics**:
  * **Total Invoices**: Overall count of invoices generated.
  * **Status Breakdown**: Counts categorized as Fully Paid, Partially Paid, Unpaid, or Overdue.
  * **Financial Aggregates**: Total gross amount, net payable, total tax amount, and total discount amount.
* **Visual Charts**:
  * **Invoice Status Distribution**: Column chart representing invoice count by payment status.
  * **Invoicing Trends**: Line chart showing monthly invoice volume and amount.
  * **Top Billing Vendors**: Bar chart of vendors with the highest billing sums.
* **Data Grid Fields**:
  * Invoice Number, Vendor Name, Agreement Ref, Billed Item, Invoice Date, Due Date, Net Payable, Amount Paid, Balance Due.

### 4. Outstanding Report
Conducts aging analysis on unpaid and partially paid invoices to identify overdue debts.

* **Summary Metrics**:
  * **Total Outstanding Liability**: Total sum of unpaid balances across all active invoices.
  * **Outstanding Invoice Count**: Total count of pending invoices.
  * **Overdue Count vs Within-Due Count**: Distribution of invoices past their due dates vs those still within their payment terms.
  * **Aging Buckets**: Outstanding sums divided by delay periods (0–30 Days, 31–60 Days, 61–90+ Days).
  * **Average Overdue Days**: The mean delay time across all overdue invoices.
  * **Largest Single Outstanding Invoice**: Highest unpaid invoice value on file.
* **Visual Charts**:
  * **Aging Distribution**: Bar chart showing liability concentrations across aging buckets.
  * **Outstanding by Vendor**: Bar chart displaying top 10 vendors by outstanding balances.
  * **Weekly Delay Trend**: Line chart tracking overdue amounts by week.
* **Data Grid Fields**:
  * Invoice Number, Vendor Name, Due Date, Net Payable, Amount Paid, Balance Due, Days Overdue (`Current Date - Due Date`).

### 5. Payment Register
Audits all successful financial disbursements recorded in the system.

* **Summary Metrics**:
  * **Total Disbursements**: Overall count of successful payments.
  * **Total Amount Disbursed**: Total cash outflows.
  * **Reconciliation Rate**: Count of Reconciled vs Pending Reconciliation transactions.
  * **Average & Largest Payment**: Insights into transaction sizes.
* **Visual Charts**:
  * **Spend by Payment Mode**: Pie chart dividing payouts by mode (Bank Transfer, Cheque, Cash, Card).
  * **Daily Outflow Trend**: Line chart tracking daily spend activities.
  * **Top Disbursed Vendors**: Bar chart representing vendors receiving the highest payouts.
* **Data Grid Fields**:
  * Payment Ref/Receipt No, Vendor Name, Invoice Number, Payment Date, Amount, Payment Mode, Reconciliation Status.

---

## Global Filter & Option Syncing Rules

To make reports useful, the screen utilizes a master filter panel that dynamically cascades selections:

1. **Date Range Filter**:
   - Restricts all data records. By default, it displays the current month (from `Start of Month` to `End of Month`).
2. **Cascading Dropdowns (AJAX-Driven)**:
   - **Vendor Select**: Restricts data to a single vendor.
   - **Agreement Select**: If a vendor is chosen, this dropdown instantly updates to show only agreements belonging to that vendor.
   - **Item Select**: Updates dynamically to show only items linked to the selected agreement (or vendor if no specific agreement is chosen).

---

## Business Rules and Conditions

- **Live Aggregation**: Data is pulled directly from transaction tables. All charts and aggregates recalculate in real-time when filters are applied.
- **Valid Financial Statuses**:
  - Invoices must be active (`is_active = true`) to count toward spending/invoiced metrics.
  - Payments must be successful (`status = 'SUCCESS'`) and non-deleted (`is_deleted = 0`) to count toward paid metrics.
- **Overdue Calculations**:
  - `overdue_days = Current Date - Due Date` (applied only when `Due Date` is past and `Balance Due > 0`).
- **Expiry Alert Threshold**: Agreements appear in the "expiring soon" alerts if their end date is within 30 days of the current date and their status is `ACTIVE`.

---

## Workflow Steps

1. **Accessing Reports**:
   - Administrative user selects the **Vendor Reports** sidebar menu. The screen loads with the **Vendor Ledger Summary** tab active by default.
2. **Selecting a Report Type**:
   - The user switches tabs based on their goal (e.g., choosing **Outstanding Report** for aging analysis).
3. **Filtering Records**:
   - The user selects a target date range and filters by a specific vendor. The cascading dropdowns load corresponding agreements.
4. **Analyzing Visual Summaries**:
   - The user analyzes the summary metric cards and visual charts to identify key patterns.
5. **Auditing the Data Grid**:
   - The user paginates through the data grid at the bottom to audit individual transaction rows.

---

## Example Scenario

On **21 May 2026**, the school's Auditor logs in to audit the Vendor Module. 

1. They navigate to **Vendor Reports** -> **Outstanding Report** and filter by date range `01 May 2026` to `21 May 2026`.
2. The summary cards show:
   * **Total Outstanding Liability**: ₹2,45,000
   * **Aging Buckets**: ₹1,80,000 (0–30 Days), ₹45,000 (31–60 Days), ₹20,000 (61–90+ Days)
   * **Avg Overdue Days**: 18.5 days
3. The **Outstanding by Vendor** bar chart reveals that ₹1,20,000 of the outstanding amount belongs to a single transport vendor (Sharma Transport).
4. The auditor scrolls to the grid, filters for "Sharma Transport," exports the list of unpaid invoices, and sends it directly to the finance clerk to schedule payments.

---

## Related Screens

- **Vendor Registration**: Selected vendors in reports link back to their respective profile screens.
- **Vendor Agreement**: Expiring agreements link to the agreement details page for contract renewals.
- **Vendor Invoice**: Unpaid records in the outstanding report link directly to the invoice screen to initiate payments.
- **Payment Details**: Audited disbursements link back to the payment ledger for verification.
