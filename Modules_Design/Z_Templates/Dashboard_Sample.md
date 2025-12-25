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

## 3. Interaction Design

### 3.1 KPI Cards (Top Row)
*   **Total Payables**: Sum of `balance_due` from all invoices where status is NOT 'Paid'.
    *   *Click Action*: Navigates to **Invoice List** filtered by `Status = Pending/Overdue`.
*   **Pending Invoices**: Count of invoices awaiting approval or payment.
    *   *Click Action*: Navigates to **Invoice List** filtered by `Status = Pending`.
*   **Contracts Expiring**: Count of agreements where `end_date` is within the next 30 days.
    *   *Click Action*: Navigates to **Agreement List** filtered by `Expiry Date next 30 days`.

### 3.2 Visualizations
*   **Spend Analysis (Pie)**: Aggregates `vnd_invoices.net_payable` grouped by `vnd_vendors.vendor_type_id`.
    *   *Hover*: Shows exact amount (e.g., "Transport: ₹ 8,50,000").
*   **Monthly Burn Rate (Bar)**: Histogram of total approved invoice amounts per month for the current fiscal year.

### 3.3 Critical Alerts
This section uses "Business Logic" to generate actionable insights:
1.  **Expiry Warning**: Triggered if `agreement.end_date - today < 30`.
2.  **Usage Spikes**: Compares current month's `vnd_usage_logs.qty_used` against the rolling average of the last 3 months for the same Item key.
3.  **Payment Overdue**: Triggered if `invoice.due_date < today` AND `status != PAID`.

## 4. Technical Data Sources

| Widget/Section | Primary Table | Logic/Filter |
| :--- | :--- | :--- |
| **Total Payables** | `vnd_invoices` | `SUM(balance_due)` where `status != PAID` |
| **Pending Invoices** | `vnd_invoices` | `COUNT(id)` where `status IN (PENDING, APPROVED)` |
| **Expiring Contracts** | `vnd_agreements` | `COUNT(id)` where `end_date BETWEEN NOW() AND NOW() + INTERVAL 30 DAY` |
| **Spend Analysis** | `vnd_invoices` JOIN `vnd_vendors` | `SUM(net_payable)` GROUP BY `vendor_type_id` |
| **Recent Invoices** | `vnd_invoices` | `SELECT * ORDER BY created_at DESC LIMIT 5` |
| **Alerts** | Mixed | Query `vnd_agreements` (expiry), `vnd_usage_logs` (anomalies), `vnd_invoices` (overdue) |

