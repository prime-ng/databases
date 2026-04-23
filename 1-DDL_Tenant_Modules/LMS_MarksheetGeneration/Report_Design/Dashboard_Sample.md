# Vendor Management Dashboard Design (Deliverable D)

**Route:** `/operations/vendor/dashboard`
**Role Access:** School Admin, Accountant, Super Admin

## 1. Dashboard Overview
The Vendor Management Dashboard serves as the command center for tracking vendor performance, financial liabilities, and operational alerts. It is designed to provide "at-a-glance" insights into how much the school is spending, which contracts are expiring, and which invoices need immediate attention.

## 2. Wireframe

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  PRIME ERP  |  OPERATIONS  |  FINANCE  |  REPORTS  |  SETTINGS                          [User Profile] │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  Breadcrumb: Operations > Vendor Management > Dashboard                                                │
│                                                                                                        │
│  ┌─────────────────────────────────┐   ┌────────────────────────────────────────────────────────────┐  │
│  │  DASHBOARD FILTERS              │   │  QUICK ACTIONS                                             │  │
│  │  Period: [ This Month ▼ ]       │   │  [+ New Vendor]  [+ Create Contract]  [+ Log Usage]        │  │
│  │  Vendor Type: [ All Types ▼ ]   │   │                                                            │  │
│  └─────────────────────────────────┘   └────────────────────────────────────────────────────────────┘  │
│                                                                                                        │
│  ┌──────────────────────┐  ┌──────────────────────┐  ┌──────────────────────┐  ┌─────────────────────┐ │
│  │ TOTAL PAYABLES       │  │ PENDING INVOICES     │  │ CONTRACTS EXPIRING   │  │ YTD SPEND           │ │
│  │ ₹ 12,45,000          │  │ 8 Bills              │  │ 2 Contracts          │  │ ₹ 1.2 Cr            │ │
│  │ ▲ 12% vs last month  │  │ (3 Overdue)          │  │ (Next 30 Days)       │  │ ▼ 5% vs last year   │ │
│  └──────────────────────┘  └──────────────────────┘  └──────────────────────┘  └─────────────────────┘ │
│                                                                                                        │
│  ┌──────────────────────────────────────────────┐  ┌─────────────────────────────────────────────────┐ │
│  │  SPEND ANALYSIS (BY CATEGORY)                │  │  RECENT INVOICE STATUS                          │ │
│  │  [Pie Chart Visualization]                   │  │  ┌───────────────────────────────────────────┐  │ │
│  │                                              │  │  │ INV #   | VENDOR       | AMOUNT  | STATUS │  │ │
│  │      /``````\  Transport (60%)               │  │  │─────────|──────────────|─────────|────────│  │ │
│  │     |        | Canteen (20%)                 │  │  │ INV-901 | ABC Travels  | ₹ 50k   | Paid   │  │ │
│  │     |________| Security (15%)                │  │  │ INV-902 | Securitas    | ₹ 1.2L  | Pending│  │ │
│  │      \      /  Stationery (5%)               │  │  │ INV-903 | Fresh Food   | ₹ 25k   | Overdue│  │ │
│  │       `----`                                 │  │  │ INV-904 | City Maint.  | ₹ 10k   | Approvd│  │ │
│  │                                              │  │  └───────────────────────────────────────────┘  │ │
│  │  [View Full Report >]                        │  │  [View All Invoices >]                          │ │
│  └──────────────────────────────────────────────┘  └─────────────────────────────────────────────────┘ │
│                                                                                                        │
│  ┌───────────────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │  ⚠️ CRITICAL ALERTS & NOTIFICATIONS                                                               │ │
│  │  [!] "Star Canteen" Agreement expires in 12 days. Renew now to avoid service interruption.        │ │
│  │  [!] Usage Alert: "Bus KA-01-5555" logged 1500km this month (Avg: 800km). Verify Logs.            │ │
│  │  [!] Payment Due: Invoice #INV-888 for "City Security" is overdue by 5 days.                      │ │
│  └───────────────────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                                        │
│  ┌──────────────────────────────────────────────┐  ┌─────────────────────────────────────────────────┐ │
│  │  VENDOR PERFORMANCE (RATING)                 │  │  MONTHLY BURN RATE (Trend)                      │ │
│  │  ┌────────────────────────────────────────┐  │  │  [Bar Chart]                                    │ │
│  │  │ 1. ABC Travels     ⭐⭐⭐⭐⭐ (4.8)    │  │  │       █                                         │ │
│  │  │ 2. Fresh Foods     ⭐⭐⭐⭐   (4.2)    │  │  │    █  █     █                                   │ │
│  │  │ 3. City Security   ⭐⭐⭐     (3.5)    │  │  │    █  █  █  █                                   │ │
│  │  └────────────────────────────────────────┘  │  │    Apr May Jun Jul                              │ │
│  └──────────────────────────────────────────────┘  └─────────────────────────────────────────────────┘ │
│                                                                                                        │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```


```ascii
┌──────────────────────────────────────────────────────────────────────────────────────┐
│ COMPLAINT MANAGEMENT > LIST                                                          │
├──────────────────────────────────────────────────────────────────────────────────────┤
│ [Search Ticket/Name...]   [+ Lodge New Complaint]   [Export]                         │
├──────────────────────────────────────────────────────────────────────────────────────┤
│ FILTER: [Status: Open ▼]  [Dept: Transport ▼]  [Priority: High ▼]  [Time: All ▼]     │
├──────────────────────────────────────────────────────────────────────────────────────┤
│ ☐ │ Ticket #      | Subject             │ Category    │ Priority │ SLA Remaining     │
│──────────────────────────────────────────────────────────────────────────────────────│
│ ☐ │ CMP-1001      | Rash Driving bus 4  | Transport   | [HIGH]   | ⚠️ 2 Hours        │
│ ☐ │ CMP-1002      | Canteen Food Cold   | Food        | [MED]    | 24 Hours          │
│ ☐ │ CMP-1003      | Staff Rude Behavior | HR          | [CRIT]   | ⛔ BREACHED (-4h) |
│   │ ...           | ...                 | ...         | ...      |                   │
│──────────────────────────────────────────────────────────────────────────────────────│
│ Showing 1-10 of 45 Tickets                                              [< 1 2 3 >]  │
└──────────────────────────────────────────────────────────────────────────────────────┘
```


