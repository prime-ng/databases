# Reports & Dashboard — Business Requirements

## Business Need
School management needs visibility into the institution's financial health — daily cash position, monthly income vs expenses, outstanding fee receivables, vendor payables aging, budget compliance, and GST data for filing. These reports support decision-making, audit compliance, and statutory filing.

## Business Objectives
- Provide standard accounting reports (Trial Balance, P&L, Balance Sheet) adapted for the Trust/Society model
- Give real-time dashboard KPIs for daily financial monitoring
- Track outstanding receivables and payables with aging analysis
- Support GST compliance reporting (GSTR-1, GSTR-3B)
- Enable budget variance monitoring per cost center
- Allow report export for offline analysis

## Reports Overview

### Financial Statements

| Report | What It Shows | Who Uses It |
|---|---|---|
| **Trial Balance** | All ledgers with their total debits and credits for a period | Accountant — validates books are balanced |
| **Income & Expenditure (P&L)** | Total income vs total expenses for a period. Surplus = income > expense | Admin/Bursar — monthly performance review |
| **Balance Sheet** | Assets = Liabilities + Equity as on a specific date | Admin — overall financial position |

### Transaction Reports

| Report | What It Shows | Who Uses It |
|---|---|---|
| **Day Book** | All vouchers for a specific date, filterable by type | Accountant — daily transaction review |
| **Cash Book** | Cash account transactions with running balance | Cashier/Accountant — daily cash position |
| **Bank Book** | Bank account transactions with running balance | Accountant — bank balance monitoring |
| **Ledger Report** | Full transaction history of any single ledger with opening/closing balance | Accountant/Admin — detailed account review |

### Management Reports

| Report | What It Shows | Who Uses It |
|---|---|---|
| **Outstanding Receivables** | Student-wise fee dues with 30/60/90+ day aging buckets | Admin — fee collection follow-up |
| **Outstanding Payables** | Vendor-wise pending payments with aging | Accountant — payment scheduling |
| **Transport Fee Outstanding** | Student-wise transport fee dues with aging | Transport Admin |
| **Budget vs Actual** | Budgeted amount vs actual spending per cost center per ledger, with variance % | Admin/Bursar — budget control |

### Compliance Reports

| Report | What It Shows | Who Uses It |
|---|---|---|
| **GSTR-1** | Outward supply data — invoice-wise GSTIN, HSN/SAC, taxable value, tax amount | CA/Tax Consultant — monthly filing |
| **GSTR-3B** | Monthly summary: total outward/inward taxable value, net tax payable | CA/Tax Consultant — monthly filing |
| **Bank Reconciliation Statement** | Unreconciled items per bank ledger | Accountant/Auditor — monthly reconciliation |

## Dashboard Widgets

### KPI Cards (Top Row)
- **Fee Collected MTD** — Total fee receipts for the current month
- **Expenses MTD** — Total payments/expenses for the current month
- **Bank Balance** — Sum of all bank account ledger balances
- **Outstanding Receivables** — Total student debtor balance
- **Transport Fee Outstanding** — Total transport fee dues

### Charts
- **Monthly Trend:** Income vs Expense line/bar chart for the year
- **Budget Utilization:** Gauge per cost center showing % of budget used
- **Receivables Aging:** Pie chart showing 30/60/90+ day buckets

### Quick Links
- New Voucher (dropdown: Payment/Receipt/Contra/Journal)
- Day Book (today's transactions)
- Trial Balance (current period)
- Bank Reconciliation (pending reconciliations)

## User Stories

**As School Accountant,** I want to:
- View the Trial Balance at any time to ensure books are balanced
- Run the Day Book for a specific date to review all transactions
- Generate the Income & Expenditure report monthly for management review
- View outstanding receivables to follow up on unpaid fees
- Run the Bank Reconciliation Statement for the auditor
- Export any report as needed

**As School Admin / Bursar,** I want to:
- See key financial KPIs on the dashboard without running reports
- View the monthly income vs expense trend at a glance
- Check budget utilization per department to control spending
- Identify top overdue student accounts for collection action
- Generate the Balance Sheet for board meetings

**As CA / Tax Consultant,** I want to:
- Generate GSTR-1 and GSTR-3B data for monthly tax filing
- Export the Trial Balance for audit preparation

## Report Behavior
- All balances are computed from voucher transactions — never stored
- Reports respect financial year boundaries
- Cancelled vouchers are excluded by default
- All monetary amounts shown in INR (₹)

## Stakeholders

| Stakeholder | Interest |
|---|---|
| School Accountant | Generates reports daily/monthly, uses for bookkeeping |
| School Admin / Bursar | Reviews financial health, makes decisions based on reports |
| Principal | High-level financial oversight |
| Auditor | Requires standard financial statements for audit |
| CA / Tax Consultant | Uses GST reports for compliance filing |

## Permissions

| Role | Access |
|---|---|
| School Admin | Full access — all reports and dashboard |
| Accountant | All reports, dashboard, data export |
| Cashier | Cash Book, Bank Book only |
| Auditor | Read-only access to all reports |
