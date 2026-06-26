# Dashboard & Reports — Requirements

## What It Does
Central fee management dashboard with key metrics, trend charts, and detailed collection views. Provides at-a-glance financial status: total fee amount, collected amount, outstanding, student count, defaulter tracking, and recent transactions.

Features:
- Summary cards: total fee, collected, outstanding, student count
- Defaulter and scholarship/concession counts
- Recent transactions list
- Top defaulter invoices
- Last 6 months collection trend chart
- Detailed fee collection view per class-section

## Dashboard Components

**Summary Cards**
- Total Fee Amount: Sum of all invoice totals for the current session
- Total Collected: Sum of all successful transaction amounts
- Total Outstanding: Total Fee − Total Collected
- Total Students: Count of students with active fee assignments
- Defaulters: Count of students with `defaulter_score` above threshold
- Scholarship Students: Count of students with approved scholarships
- Concession Students: Count of students with approved concessions

**Charts**
- Last 6 Months Collection Trend: Bar/line chart showing monthly collection amounts
- Class-wise Collection: Total vs collected per class (dashboardFeeCollection view)

**Tables**
- Recent Transactions: Last 10 transactions with student, amount, mode, status
- Top Defaulter Invoices: Invoices with highest overdue amounts or days late
- Class-wise Fee Collection: Detailed per-student paid amounts grouped by class-section

## Routes

**Dashboard**
- Authorization: `tenant.student-fee-management.viewAny`

**Fee Collection Detail**
- Detailed class-section breakdown with per-student amounts

## Permissions

| Operation | Permission Key |
|---|---|
| View dashboard | `tenant.student-fee-management.viewAny` |
