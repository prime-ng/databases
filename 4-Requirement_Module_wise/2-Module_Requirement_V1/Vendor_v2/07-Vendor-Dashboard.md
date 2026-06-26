# Vendor Dashboard — Business Requirements

## What This Screen Does

The Vendor Dashboard is the first screen a user lands on when entering the Vendor module. It provides a real-time, at-a-glance summary of the school's entire vendor ecosystem — how many vendors are registered, how many agreements are active, how much money is owed to vendors, and what is the payment completion rate.

Think of the dashboard as the "command centre" for the finance and admin team. Instead of going to each tab separately to understand the current status, the dashboard consolidates all key numbers and recent activity in one place. A principal or finance head can glance at this screen and instantly understand whether vendor payments are on track, how many agreements are expiring soon, and what the total outstanding liability is.

---

## When This Screen Is Used

- Finance head opens the Vendor module first thing in the morning to check payment status
- Admin wants to know which agreements are expiring this month and need renewal
- Principal asks: "How much do we owe to vendors right now?" — the dashboard provides the answer
- Finance team wants to see which vendors have the highest pending invoices
- Admin wants a quick view of recent payment activity without going through the full payment list

---

## Key Metrics Shown on the Dashboard

**Total Vendors**
The count of all active vendors currently registered in the system. This gives a quick sense of how many vendors the school is managing.

**Total Active Agreements**
The number of agreements that are currently in Active status (not Draft, Expired, or Terminated). Only active agreements can generate invoices.

**Agreements Expiring This Month**
A count of active agreements whose end date falls within the current calendar month. This is a proactive alert — the admin needs to renew or terminate these agreements before they expire unnoticed.

**Total Invoiced Amount (Current Period)**
The total rupee value of all invoices generated in the current month or selected period. This represents the total billing commitment for the period.

**Total Amount Paid (Current Period)**
The total amount the school has already paid to vendors in the current period. Comparing this against the Total Invoiced Amount shows how much is still outstanding.

**Total Outstanding (Unpaid / Partially Paid)**
The total balance due across all invoices that are not yet fully paid. This is the school's current financial liability to its vendors.

**Payment Completion Rate**
A percentage showing how much of the total invoiced amount has been paid. For example, if ₹1,00,000 was invoiced and ₹70,000 has been paid, the completion rate is 70%. This is a quick health check for the finance team.

---

## Visual Sections on the Dashboard

**Summary Cards (Top Row)**
Four to six metric cards showing the key numbers mentioned above — Vendors, Active Agreements, Expiring Soon, Outstanding Amount, and Payment Rate. Each card should have a clear icon and colour coding (e.g., green for healthy, orange for warning, red for critical).

**Expiring Agreements Alert List**
A small table or list showing agreements that are expiring within the next 30 days, with the vendor name, agreement reference, and exact expiry date. This prompts admin to take renewal action.

**Recent Invoices**
A list of the most recently generated invoices — showing vendor name, invoice number, invoice date, net payable, and current status. Finance can quickly see the latest billing activity.

**Recent Payments**
A list of the most recent payments recorded — vendor name, payment date, amount, mode, and reconciled status. Helps finance track payment activity without going to the full payment list.

**Outstanding Vendors Chart**
A visual (bar or list) showing top vendors by outstanding balance — i.e., which vendors are owed the most money by the school. This helps prioritise payment scheduling.

---

## Business Rules and Conditions

**Data is Always Current**
The dashboard data is pulled in real-time from the database. There is no manual refresh needed. Every time the dashboard is loaded, it reflects the current state.

**Permission-Based View**
The dashboard should only show data that the logged-in user has permission to view. If a user only has access to view vendors but not invoices, the invoice-related metric cards should be hidden.

**Expiry Alert Threshold**
Agreements are shown in the "expiring soon" list if their end date is within the next 30 days. This gives admin enough lead time to prepare for renewal.

**Billing Period Reference**
The "current period" for invoicing metrics refers to the current calendar month by default. Admin may be able to select a different month for comparison (depending on the report filter available).

---

## Workflow Steps

**Accessing the Dashboard**
Admin clicks on the Vendor module from the main navigation. The first tab (Dashboard) is automatically active and shows all current metrics.

**Reviewing Expiring Agreements**
Admin looks at the expiring agreements section. For each agreement expiring soon, admin navigates to the Vendor Agreement screen and initiates renewal.

**Monitoring Outstanding Payments**
Admin checks the outstanding amount metric. If it is higher than expected, admin navigates to the Vendor Invoice screen, filters by Pending/Partially Paid, and identifies which vendors need payment.

---

## Example Scenario

A school's finance head opens the Vendor module on 25 May 2025 and sees the following on the dashboard:

- Total Vendors: 18
- Active Agreements: 12
- Expiring This Month: 2 (Sharma Transport — 31 May, AquaPure Water — 28 May)
- Total Invoiced (May 2025): ₹3,45,000
- Total Paid (May 2025): ₹2,10,000
- Outstanding: ₹1,35,000
- Payment Completion Rate: 60.9%

The expiry alerts immediately prompt the finance head to contact Sharma Transport and AquaPure to discuss renewal. The ₹1,35,000 outstanding triggers a review of pending invoices to schedule payments before month-end.

---

## Related Screens

- **Vendor Agreement** — Expiring agreements are shown on the dashboard; admin navigates here for renewal
- **Vendor Invoice** — Outstanding invoice amounts drive the financial metrics shown on the dashboard
- **Payment Details** — Recent payment activity is reflected on the dashboard
