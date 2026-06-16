# Cost Centers & Budgets — Business Requirements

## Business Need
School administrators need to track income and expenses not just by account type, but by department or activity — "How much did the Primary Wing spend on stationery?" or "Is the Transport department over budget?" Cost centers enable department-wise Profit & Loss tracking. Budgets allow schools to set spending limits and monitor variances.

## Business Objectives
- Track financial performance by department/wing/activity (cost centers)
- Set annual budgets per cost center per ledger
- Monitor actual spending vs budget in real time
- Alert management when spending exceeds configurable thresholds
- Support hierarchical cost centers (Wing → Department → Activity)

## User Stories

**As School Accountant,** I want to:
- Create cost centers for each school wing (Primary, Middle, Senior) and department (Admin, Transport, Sports)
- Organize cost centers in a hierarchy (School → Wing → Department)
- Assign a cost center to voucher line items when recording transactions
- Set annual budget amounts for each ledger within a cost center
- Revise budgets during the year with tracked changes

**As School Admin / Bursar,** I want to:
- View budget utilization per cost center at a glance
- See which departments are approaching or exceeding their budgets
- Drill down from a budget variance to the underlying vouchers
- Review cost center-wise P&L for management decisions

## Key Business Rules

**Cost Center Hierarchy**
- Cost centers form a parent-child tree (e.g., School → Primary Wing → Salaries)
- A cost center can be used across multiple financial years
- Cost centers are optional on voucher items — enables segregation when assigned

**Budget Rules**
- One budget per combination: (Financial Year, Cost Center, Ledger)
- Budget amount must be ≥ 0
- Budgets can be revised during the year (changes are logged)
- Budget vs Actual is computed as: `actual spending vs budgeted amount`

**Variance Tracking**
- Actual = sum of all voucher items against the (ledger, cost center) for the FY
- Available balance = Budget − Actual − Commitments (pending purchase orders)
- Variance % = `((actual − budgeted) / budgeted) × 100`
- Dashboard highlights cost centers exceeding 90% utilization

## Seeded Cost Centers

| Cost Center | Category |
|---|---|
| Primary Wing | Department |
| Middle Wing | Department |
| Senior Wing | Department |
| Administration | Department |
| Transport | Activity |
| Sports | Activity |
| Library | Activity |
| Science Lab | Activity |
| Computer Lab | Activity |
| Hostel | Activity |

## Stakeholders

| Stakeholder | Interest |
|---|---|
| School Accountant | Creates cost centers, sets budgets, tracks spending |
| School Admin / Bursar | Reviews budget compliance, approves budget revisions |
| Wing Heads / HODs | Monitor their department's budget utilization |

## Permissions

| Role | Access |
|---|---|
| School Admin | Full access to cost centers and budgets |
| Accountant | Create/edit cost centers and budgets |
| Auditor | View-only access to budget vs actual reports |
