# StudentFee Dashboard — Business Requirements

## What This Screen Does

The StudentFee Dashboard is the landing screen of the StudentFee module. It gives administrators, accounts managers, and principals a real-time financial cockpit — summary KPIs, collection trends, recent transactions, and defaulter alerts — all in a single view without navigating to separate screens.

This screen is the first tab in a larger tabbed interface. The tabs let users switch between:

- **Dashboard** (this screen — summary cards, charts, recent activity, defaulter alerts)
- **Configuration** (fee heads, groups, structures, installments, concessions)
- **Assignment** (student fee assignments)
- **Billing** (fee invoices)
- **Payment** (transactions and receipts)
- **Fine Management** (fine rules and fine transactions)
- **Scholarship** (scholarship definitions and applications)
- **Governance** (name removal log)

A secondary drill-down view (`dashboardFeeCollection`) provides class-section-wise fee collection details.

---

## When This Screen Is Used

- **Morning Financial Check** — Accounts managers open the dashboard each morning to see total fee collected vs outstanding, defaulter count, and recent payments
- **End-of-Day Reconciliation** — Cashiers verify the day's collections against the recent transactions list
- **Defaulter Monitoring** — Administrators check the top defaulter invoices list to identify students with highest overdue amounts for follow-up
- **Collection Trend Analysis** — Management reviews the 6-month collection trend chart to track fee collection momentum across the academic year
- **Scholarship/Concession Oversight** — Quick counts of approved scholarship students and concession students provide at-a-glance financial aid visibility
- **Fee Collection Details** — Accountants drill into the class-section view to compare total fee vs collected per class

---

## Who Can Access This Screen

| Permission                              | Description                                       |
| --------------------------------------- | ------------------------------------------------- |
| `tenant.student-fee-management.viewAny` | View the dashboard and all fee management screens |

- **School Admin** — Full access to all dashboard data
- **Accounts Manager** — Sees financial KPIs, recent transactions, defaulter list, collection trends
- **Principal** — Read-only view of summary KPIs and defaulter alerts
- **Cashier** — Sees recent transactions for reconciliation

If a user does not have the `tenant.student-fee-management.viewAny` permission, the system denies access and shows an "Access Denied" message via `Gate::authorize()`.

---

## How This Screen Works

When a user opens the StudentFee module, the dashboard loads automatically. It queries the current academic session, then computes key financial numbers from five primary models:

### Summary Cards (top row)

| KPI                     | How It Is Calculated                                                                                                    |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| Total Fee Amount        | Sum of `total_fee_amount` from all active `fee_student_assignments` in the current session                              |
| Total Fee Collected     | Sum of `amount` from `fee_transactions` where `status = 'Success'` for students with assignments in the current session |
| Total Fee Outstanding   | `Total Fee Amount − Total Fee Collected` (clamped to minimum 0)                                                         |
| Total Students Enrolled | Count from `student_academic_sessions` where `academic_session_id` = current session and `session_status_id = 1`        |
| Defaulter Students      | Count of `fee_invoices` where `status = 'Overdue'`, linked to assignments in the current session                        |
| Scholarship Students    | Count of `fee_scholarship_applications` where `status = 'Approved'` for students in the current session                 |
| Concession Students     | Count of `fee_student_concessions` where `approval_status = 'Approved'`, linked to assignments in the current session   |

### Charts

| Chart                          | Type     | Description                                                                                  |
| ------------------------------ | -------- | -------------------------------------------------------------------------------------------- |
| Last 6 Months Collection Trend | Bar/Line | Month-wise total collected amount for the last 6 calendar months (Success transactions only) |

### Tables

| Table                    | Details                                                                                                                                               |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| Recent 5 Transactions    | Latest 5 `fee_transactions` with status Success or Pending, showing student name, transaction no, amount, payment mode, payment date                  |
| Top 5 Defaulter Invoices | 5 `fee_invoices` with status Overdue, sorted by `balance_amount` descending, showing student name, invoice no, total amount, balance amount, due date |

### Class-Section Fee Collection View (Dashboard Fee Collection)

The detailed view (`dashboardFeeCollection()`) provides a class-section wise breakdown:

- **Grouped by Class-Section**: Students grouped under their class-section header
- **Per-Student Details**: Each student row shows fee structure name, total fee amount, paid amount (from successful transactions), outstanding
- **Summary Per Class**: Total fee, total collected, total outstanding per class-section group
- **Chart**: Class-section wise bar chart comparing total fee vs collected

### Empty State

When no current academic session exists, the dashboard returns:

- All summary cards show 0 or ₹0
- Charts show empty arrays
- Tables show empty collections
- No 403 error — gracefully degrades to zero state

---

## Key Metrics

The dashboard shows the following business metrics:

1. **Total Fee Amount** — Sum of all active fee assignment totals for the current session
2. **Total Fee Collected** — Sum of all successful payment amounts for the current session
3. **Total Fee Outstanding** — Unpaid balance (Total Fee Amount − Total Fee Collected)
4. **Total Students Enrolled** — Number of students actively enrolled in the current session
5. **Defaulter Students** — Number of overdue invoices in the current session
6. **Scholarship Students** — Number of approved scholarship applications in the current session
7. **Concession Students** — Number of approved student concessions in the current session

---

## Business Rules

### Rule 1: Current Session Scoping

All dashboard queries are scoped to the current academic session resolved via `AcademicSession::current()`. If no current session exists, the dashboard renders in a zero-data empty state.

### Rule 2: Total Fee Collected Uses Successful Transactions Only

Only transactions with `status = 'Success'` are included in the total collected amount. Pending, Failed, and Refunded transactions are excluded.

### Rule 3: Outstanding Calculation

`TotalFeeOutstanding = max(0, TotalFeeAmount − TotalFeeCollected)`. This ensures outstanding never shows a negative value even if over-collection occurs (e.g., via refunds not yet processed).

### Rule 4: Student Count Uses Academic Session Status

Enrolled student count queries `student_academic_sessions` with `session_status_id = 1` to count only currently enrolled students (not transferred, withdrawn, or graduated).

### Rule 5: Defaulter Identification

Defaulter students are identified by invoices with `status = 'Overdue'`. The `Overdue` status is set when an invoice's due date has passed and the balance is not fully paid. The dashboard shows the count (total overdue invoices) and the top 5 by balance amount.

### Rule 6: Scholarship/Concession Filtering

Scholarship students are counted from applications with `status = 'Approved'`. Concession students are counted from concessions with `approval_status = 'Approved'`. Both are further filtered to the current session's students.

### Rule 7: Recent Transactions Limit

The recent transactions list is limited to the most recent 5 records (by `payment_date` DESC), including both Success and Pending status transactions.

### Rule 8: Top Defaulter Sorting

Top defaulter invoices are sorted by `balance_amount` descending, limited to 5 records. This highlights the students with the highest outstanding debt.

### Rule 9: Last 6 Months Chart

The collection trend chart always shows exactly 6 months (the current month plus 5 previous months). Each month shows the sum of successful transaction amounts for that month. If there is no activity in a given month, the chart shows zero.

### Rule 10: Graceful Degradation

If `AcademicSession::current()` returns null (no active session configured), all KPIs default to zero/empty. No exception is thrown — the view renders with blank data.

### Rule 11: No Caching

The dashboard recomputes all metrics on every page load. There is no caching layer — each request re-queries the database for all KPIs, counts, and lists.

### Rule 12: No Date Range Filtering

The dashboard always reports metrics for the entire current academic session. There is no from_date/to_date filter on the main dashboard view. The detailed fee collection view is also session-scoped.

---

## Scenarios

### Success Scenario 1: Accounts Manager Daily Review

An accounts manager opens the StudentFee module. The dashboard shows: Total Fee Amount = ₹1,25,00,000, Total Fee Collected = ₹85,00,000, Total Fee Outstanding = ₹40,00,000, Total Students = 450, Defaulters = 23, Scholarship Students = 15, Concession Students = 28. The 6-month chart shows a rising collection trend from August (₹10,00,000) to January (₹18,00,000). The Recent 5 Transactions table lists the latest payments with student names, amounts, and modes. The Top 5 Defaulter list shows the highest overdue amounts starting at ₹45,000.

### Success Scenario 2: End-of-Day Reconciliation

A cashier opens the dashboard after the school day ends. The Total Fee Collected shows ₹1,20,000 for the session. The Recent 5 Transactions shows the last 5 payments recorded today — 3 cash payments, 1 UPI, 1 cheque. The cashier verifies that the day's cash drawer matches the sum of cash transactions recorded.

### Success Scenario 3: Principal Monthly Review

The Principal reviews the dashboard at the end of the month. Total Fee Collected has grown 15% over last month. The defaulter count has decreased from 35 to 23. The Principal notes the scholarship count (15 students) and concession count (28 students) for the board meeting presentation.

### Success Scenario 4: Administrator Fee Collection Drill-Down

An administrator clicks on the Fee Collection Details link to see the class-section breakdown. The view shows Class 10-A has 40 students with total fee ₹8,00,000 but only ₹5,50,000 collected (68.75% collection rate). Class 12-B shows 95% collection. The administrator identifies Class 10-A for follow-up.

### Failure Scenario 1: No Academic Session

The school's new academic year has not been configured yet. A user opens the dashboard. All KPIs show 0 or ₹0. Charts are empty. No error is thrown — the dashboard gracefully renders with empty data.

### Failure Scenario 2: No Access

A teacher who only has academic permissions (no `tenant.student-fee-management.viewAny`) tries to open the StudentFee module. The system denies access and shows a 403 "This action is unauthorized." message.

### Failure Scenario 3: Fresh School Setup

An administrator opens the dashboard in a brand-new school with no student assignments, no invoices, and no transactions. All summary cards show 0 or ₹0. Charts show empty. Tables show "No data available" (empty collections). This is the same as the no-session state.

### Example: Mr. Verma's Morning Routine

Mr. Verma, the Accounts Manager at Sunshine International School, starts his workday by opening the Fee Management module.

The dashboard loads automatically:

1. **Summary Cards**: Total Fee Amount = ₹1,25,00,000, Total Collected = ₹85,00,000, Outstanding = ₹40,00,000, Total Students = 450, Defaulters = 23, Scholarship = 15, Concession = 28.

2. **6-Month Collection Trend**: The chart shows August (₹10,00,000), September (₹12,00,000), October (₹14,00,000), November (₹13,50,000), December (₹17,50,000), January (₹18,00,000). The trend is upward, which is healthy.

3. **Recent 5 Transactions**: The table lists:
    - Rahul Sharma — ₹25,000 — UPI — 23 Jan 2026
    - Priya Singh — ₹18,500 — Cash — 23 Jan 2026
    - Amit Kumar — ₹45,000 — Cheque — 22 Jan 2026
    - Sneha Patel — ₹12,000 — Net Banking — 22 Jan 2026
    - Vikram Joshi — ₹30,000 — DD — 21 Jan 2026

4. **Top 5 Defaulter Invoices**: The list shows:
    - Rohan Gupta — INV-2026-0421 — ₹45,000 balance — Due 15 Dec 2025
    - Ananya Reddy — INV-2026-0387 — ₹38,000 balance — Due 10 Dec 2025
    - Arjun Nair — INV-2026-0512 — ₹32,500 balance — Due 20 Dec 2025
    - Divya Desai — INV-2026-0298 — ₹28,000 balance — Due 05 Dec 2025
    - Karan Mehta — INV-2026-0445 — ₹22,000 balance — Due 18 Dec 2025

5. **Scholarship & Concession**: 15 students have approved scholarships and 28 have approved concessions. Mr. Verma clicks through to verify the totals.

Mr. Verma completes his daily financial review in under 3 minutes — all the key information is on one screen.

---

## Dependencies

This screen depends on information from the following parts of the system:

| Module                       | What Information Is Needed                                              |
| ---------------------------- | ----------------------------------------------------------------------- |
| Fee Student Assignments      | Total fee amount sum, student ID list for session-specific scoping      |
| Fee Invoices                 | Defaulter count (Overdue status), top defaulter list, balance amounts   |
| Fee Transactions             | Total collected sum, recent transaction list, per-month collection sums |
| Fee Student Concessions      | Approved concession student count                                       |
| Fee Scholarship Applications | Approved scholarship application count                                  |
| Student Profile              | Enrolled student count per session                                      |
| Prime Core                   | Current academic session resolution                                     |

### Primary Tables Referenced

| Table                           | Columns Used                                                                                  | Purpose                                             |
| ------------------------------- | --------------------------------------------------------------------------------------------- | --------------------------------------------------- |
| `fee_student_assignments`       | `academic_session_id`, `student_id`, `total_fee_amount`, `is_active`                          | Total fee sum, active student IDs                   |
| `fee_transactions`              | `student_id`, `amount`, `status`, `payment_date`, `payment_mode`                              | Total collected, recent transactions, monthly chart |
| `fee_invoices`                  | `student_assignment_id`, `status`, `balance_amount`, `invoice_no`, `due_date`, `total_amount` | Defaulter count, top defaulter list                 |
| `fee_scholarship_applications`  | `student_id`, `status`                                                                        | Approved scholarship count                          |
| `fee_student_concessions`       | `student_assignment_id`, `approval_status`                                                    | Approved concession count                           |
| `student_academic_sessions`     | `academic_session_id`, `session_status_id`                                                    | Enrolled student count                              |
| `sch_org_academic_sessions_jnt` | `id` (via AcademicSession model)                                                              | Current session resolution                          |

### Controller Methods

| Method                     | Route                                               | Gate                                    | Purpose                                                                       |
| -------------------------- | --------------------------------------------------- | --------------------------------------- | ----------------------------------------------------------------------------- |
| `dashboard()`              | `GET /student-fee/dashboard`                        | `tenant.student-fee-management.viewAny` | Main dashboard with summary cards, chart, recent transactions, top defaulters |
| `dashboardFeeCollection()` | `GET /student-fee/dashboard/fee-collection-details` | `tenant.student-fee-management.viewAny` | Detailed class-section-wise fee collection breakdown                          |
