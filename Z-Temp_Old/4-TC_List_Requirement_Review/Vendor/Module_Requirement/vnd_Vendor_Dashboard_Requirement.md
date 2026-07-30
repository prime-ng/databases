# Vendor Dashboard — Business Requirements

## What This Screen Does

The Vendor Dashboard is the first screen of the Vendor module. It gives administrators and finance teams a real-time overview of the vendor ecosystem — think of it as a mission-control cockpit. Instead of jumping between screens to find basic numbers, users see summary cards, visual breakdowns, and recent activity tables all in one place.

This screen is part of a larger tabbed interface. The tabs let users switch between:
- **Dashboard** (this screen — summary cards, charts, recent activity)
- **Vendor Master** (vendor list and management)
- **Vendor Items / Service Catalogue** (item master management)

---

## When This Screen Is Used

- **Daily Financial Check** — Accountants glance at the dashboard each morning to see month-to-date invoiced vs paid, outstanding amounts, and payment completion rate
- **Contract Expiry Monitoring** — Administrators check the Expiring Soon alert to proactively renew or terminate vendor agreements before they lapse
- **Vendor Performance Review** — Management reviews top vendors by outstanding and invoiced amounts to identify key partners and potential risks
- **Payment Reconciliation** — Finance teams use the recent invoices and payments tables to track the latest transactions without navigating away
- **Category Spend Analysis** — Procurement heads analyse category-wise spend breakdown to optimise budget allocation

---

## Who Can Access This Screen

A user can see the dashboard if they hold **at least one** of these permissions on any vendor record:

| Permission | Description |
|------------|-------------|
| `tenant.vendor.view` | View a specific vendor |
| `tenant.vendor.viewAny` | View all vendors |
| `tenant.vendor-agreement.view` | View a specific vendor agreement |
| `tenant.vendor-agreement.viewAny` | View all vendor agreements |
| `tenant.vendor-invoice.view` | View a specific vendor invoice |
| `tenant.vendor-invoice.viewAny` | View all vendor invoices |

- **School Admin** — Full access to all dashboard data
- **Accounts Manager** — Sees financial KPIs, invoices, payments, and outstanding
- **Purchase Manager** — Sees vendor counts, agreements, and expiring alerts
- **Principal** — Read-only view of summary KPIs and charts

---

## How This Screen Works

When a user opens the Vendor module, the dashboard loads automatically. The screen gathers information from different parts of the system, computes key numbers, and displays everything in a single view:

**Summary Cards (top row)** — Six key numbers shown side by side:

| KPI | How It Is Calculated |
|-----|---------------------|
| Total Active Vendors | Counts all active vendors that have not been removed |
| Total Active Agreements | Counts all agreements that are currently active |
| Expiring Soon (30 days) | Counts active agreements ending within the next 30 days |
| Month Invoiced | Adds up all invoice amounts raised this month |
| Month Paid | Adds up all payment amounts received this month |
| Total Outstanding | Adds up all unpaid amounts across all invoices |

**Expiring Soon Colour Coding**
- **Red**: Agreements expiring within 7 days from today
- **Orange**: Agreements expiring between 8 and 30 days from today

**Charts & Breakdowns**

| Chart | Type | Description |
|-------|------|-------------|
| Category-wise Spend Breakdown | Pie / Doughnut | Total spend grouped by item category |
| Payment Status Distribution | Pie / Doughnut | Count of invoices by status (Paid, Pending, Overdue, Partially Paid) |
| Monthly Invoiced vs Paid Trend | Line / Bar | Month-wise invoiced amount vs paid amount for the last 12 months |
| Payment Method Distribution | Pie / Doughnut | Payment amounts grouped by payment method (Bank Transfer, Cheque, UPI, Cash, etc.) |

**Tables**

| Table | Details |
|-------|---------|
| Top 5 Vendors by Outstanding | Vendors with the highest outstanding invoice amounts, highest first |
| Top 5 Vendors by Invoiced Amount | Vendors with the highest total invoiced amount, highest first |
| Recent 10 Invoices | Last 10 invoices with vendor name, invoice number, date, amount, status |
| Recent 10 Payments | Last 10 payments with vendor name, payment reference, date, amount, method |

**Summary Cards (detailed)**

| Metric | Label | Format | Example |
|--------|-------|--------|---------|
| Total Active Vendors | "Total Vendors" | Number | 48 |
| Total Active Agreements | "Active Agreements" | Number | 23 |
| Expiring Within 30 Days | "Expiring Soon" | Number (coloured) | 5 (2 red, 3 orange) |
| Current Month Invoiced | "Month Invoiced" | Currency (₹) | ₹12,50,000 |
| Current Month Paid | "Month Paid" | Currency (₹) | ₹8,75,000 |
| Total Outstanding | "Outstanding" | Currency (₹) | ₹15,20,000 |
| Payment Completion Rate | "Payment Rate" | Percentage | 70% |

**Payment Completion Rate**

Calculated as: (Total Paid This Month / Total Invoiced This Month) × 100

If nothing was invoiced this month, the rate shows `—` (dash) or `0%`.

---

## Key Metrics

The dashboard shows the following business metrics:

1. **Total Vendors** — How many active vendors exist in the system
2. **Active Agreements** — How many agreements are currently active
3. **Expiring Soon** — How many agreements will expire in the next 30 days, colour-coded by urgency
4. **Month Invoiced** — Total amount billed by vendors this month
5. **Month Paid** — Total amount paid to vendors this month
6. **Outstanding** — Total amount still owed to vendors
7. **Payment Rate** — What percentage of this month's invoices have been paid

---

## Business Rules

### Rule 1: Any Permission Grants Access
If a user has any one of the six permissions (view or view all for vendors, agreements, or invoices), the dashboard loads. If they have none, they see an "Access Denied" message.

### Rule 2: Expiring Soon Colour Codes
- **Red** — Agreement ends within the next 7 days (including today)
- **Orange** — Agreement ends between 8 and 30 days from today
- Agreements ending today are shown in red
- Agreements that have already expired are not counted here

### Rule 3: Last 12 Months Trend
The monthly trend chart always shows exactly 12 months (this month plus the 11 previous months). If there is no activity in a given month, the chart shows zero for both invoiced and paid.

### Rule 4: Top 5 Vendors Sorted Highest First
- Top 5 by Outstanding: Listed from highest to lowest outstanding amount
- Top 5 by Invoiced: Listed from highest to lowest invoiced amount
- If there are fewer than 5 vendors, the list shows however many exist. If none exist, the list is empty.

### Rule 5: Recent 10 Invoices and Payments
- Shows the 10 most recent invoices and payments, newest first
- If there are fewer than 10, the list shows however many exist
- Each entry includes the vendor name for easy reference

### Rule 6: Currency Formatting
The dashboard sends amounts as plain numbers. The screen handles formatting them with the ₹ symbol and Indian numbering system (lakhs/crores).

### Rule 7: Division by Zero Protection
The Payment Completion Rate calculation must guard against "no invoices this month." If nothing was invoiced, the rate shows `—` or `N/A`.

### Rule 8: Payment Status Categories
Invoice statuses are grouped into:
- **Paid** — Fully paid
- **Pending** — Invoice raised, no payment received
- **Partially Paid** — Partial payment received, balance still owed
- **Overdue** — Due date passed, not fully paid
- **Cancelled / Void** — Invoice cancelled or voided

### Rule 9: Category-wise Spend Uses Item Category
Spend breakdown is based on invoice line items or agreement items, grouped by their category. Categories with no spend are not shown.

---

## Scenarios

### Success Scenario 1: Accounts Manager Daily Review
An accounts manager opens the Vendor module. The dashboard shows: 48 Active Vendors, 23 Active Agreements, 5 Expiring Soon (2 red, 3 orange), ₹12,50,000 Month Invoiced, ₹8,75,000 Month Paid, ₹15,20,000 Outstanding, Payment Rate = 70%. The category pie chart shows Stationery (40%), IT Services (30%), Facility Management (20%), Transportation (10%). The monthly trend chart shows invoiced vs paid for the last 12 months. The Recent Invoices table lists the 10 latest invoices. The Top 5 Outstanding list shows "ABC Supplies" at the top with ₹4,50,000 outstanding.

### Success Scenario 2: Purchase Manager Renewal Check
A purchase manager checks the dashboard and sees 3 agreements expiring in red (within 7 days). They go to the Agreements screen to start renewals before the contracts lapse.

### Failure Scenario 1: No Access
A teacher who only has student-related permissions (no vendor permissions) tries to open the Vendor module. The system denies access and shows an "Access Denied" message.

### Failure Scenario 2: System Unavailable
The system that provides invoice data is temporarily unavailable. The dashboard shows a "Dashboard temporarily unavailable — please try again later" message.

### Failure Scenario 3: Fresh School Setup
An administrator opens the dashboard in a brand-new school with no vendors, agreements, or invoices. All summary cards show 0 or ₹0. Charts show empty-state messages. Tables show "No data available." Payment Rate shows "—".

### Example: Mrs. Sharma's Morning Routine

Mrs. Sharma, the Accounts Manager at Sunshine International School, starts her workday by opening the Vendor module.

The dashboard loads automatically:

1. **Summary Cards**: She sees Total Vendors = 48, Active Agreements = 23, Expiring Soon = 5 (2 in red — expiring this week, 3 in orange — expiring this month), Month Invoiced = ₹12,50,000, Month Paid = ₹8,75,000, Outstanding = ₹15,20,000, Payment Rate = 70%.

2. **Category-wise Spend Breakdown**: The pie chart shows that Stationery accounts for 40% of total spend, IT Services for 30%, Facility Management for 20%, and Transportation for 10%. She notes that Transportation spend is lower than expected and makes a mental note to investigate.

3. **Monthly Invoiced vs Paid Trend**: The bar chart shows that invoicing peaked in March (₹18,00,000) but payments lagged in April (₹6,00,000 paid vs ₹14,00,000 invoiced), indicating a payment backlog that needs attention.

4. **Top 5 Vendors by Outstanding**: ABC Supplies tops the list at ₹4,50,000 outstanding. She clicks the vendor name to go to the vendor profile and send a payment reminder.

5. **Recent Invoices**: The table shows the last 10 invoices. She notices one invoice from XYZ Services dated 3 days ago with status "Pending" and a due date of tomorrow. She flags it for priority processing.

6. **Expiring Alerts**: Seeing the 2 red-badged agreements expiring within 7 days, she goes to the Agreements tab to start renewals.

Mrs. Sharma completes her daily review in under 2 minutes without navigating to any other screens — all the information she needs is on the dashboard.

---

## Dependencies

This screen depends on information from the following parts of the system:

| Module | What Information Is Needed |
|--------|---------------------------|
| Vendor Core | Active vendor count |
| Vendor Agreements | Active agreement count, expiring soon list |
| Vendor Invoices | Month invoiced total, outstanding total, recent invoices, payment status distribution, monthly trend |
| Vendor Payments | Month paid total, recent payments, payment method distribution |
| Vendor Items | Category information for spend breakdown |
| System Config | Category labels for spend breakdown |
