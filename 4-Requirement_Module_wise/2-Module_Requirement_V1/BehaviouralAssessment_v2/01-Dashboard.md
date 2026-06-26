# Behavioural Assessment Dashboard — Business Requirements

## What This Screen Does

The Behavioural Assessment Dashboard provides a centralized, real-time analytics hub for school leaders, counsellors, and teachers. It consolidates qualitative scores, pending evaluation tasks, and logged incidents into visual summaries, helping staff monitor student development and address disciplinary or behavioral anomalies immediately.

The dashboard displays high-level metrics, such as total incidents logged this week, pending teacher assessments, top-performing student cohorts, and key warning signals (e.g., spike in severe behavioral infractions).

---

## When This Screen Is Used

- **Admin/Principal** opens the dashboard daily to monitor the overall behavioral climate of the school and track the progress of ongoing assessment periods.
- **School Counsellors** review the dashboard to identify students with a high frequency of negative incidents or severe infractions requiring therapeutic interventions.
- **Teachers** use the dashboard to check if they have pending behavioral grading tasks that need completion before the lock deadline.
- **HODs / Coordinators** check the dashboard to see the count of submitted assessments in their review queue.

---

## Key Widgets & Components

### 1. Key Performance Indicator (KPI) Cards
- **Active Assessment Period**: Name and remaining days of the current grading cycle.
- **Assessments Completed**: Percentage of sections whose assessments are locked.
- **Incidents Logged (This Week)**: Total incident count with an up/down arrow comparison against the previous week.
- **Active Interventions**: Number of students currently undergoing behavioral plans.

### 2. Analytical Charts
- **Incident Severity Distribution**: A donut chart showing the split of incidents by severity levels (Info, Low, Medium, High).
- **Incident Trend (Monthly)**: A line chart plotting Positive vs. Disciplinary incidents recorded week-by-week.
- **Category-wise Averages**: A bar chart displaying school-wide average scores across core behavioural categories (e.g., Collaboration, Cleanliness).

### 3. Actionable Lists & Alerts
- **Recent Severe Incidents**: A grid showing the latest incidents marked with 'High' severity, including student name, class, date, and description.
- **Pending Approvals Alert**: Direct link and count of submissions in the review queue.
- **Counsellor Alert List**: Automatically surfaces students who have accumulated more than three disciplinary infractions in the last 30 days.

---

## Business Rules and Conditions

**Role-Based Data Visibility**
- **Admins & Counsellors** see school-wide data.
- **Class Teachers** see aggregated metrics for their class/section only.
- **Subject Teachers** only see metrics corresponding to sections they teach.

**Interactive Drilldowns**
- Clicking on the "Pending Approvals" card redirects HODs directly to the [Review Queue](./11-Review-Queue.md).
- Clicking on a student’s name in any dashboard widget redirects to their individual [Student Report](./20-Student-Report.md).

**Dynamic Data Fetching**
- Dashboard metrics do not run heavy real-time queries across transactional grading tables on page load. Instead, it aggregates from `ba_computed_scores` and pre-summarized tables to guarantee page load speeds under 2 seconds.

---

## Workflow Steps

**Viewing Dashboard Metrics**
1. User logs in and navigates to the Behavioural Assessment module.
2. The system checks the user's role to determine scope (school-wide or section-level).
3. The dashboard renders widgets, loading charts asynchronously using cached aggregate scores.
4. If there is an active assessment period near its deadline, a red notification banner appears at the top.

**Drilling Down on Alerts**
1. HOD clicks on the "Pending Approvals" card showing `12 Sections Submitted`.
2. HOD is redirected to the [Review Queue](./11-Review-Queue.md) pre-filtered for those 12 sections.

---

## Example Scenario

At the start of November, the School Principal logs into the portal. The Behavioural Assessment Dashboard highlights:
- A red warning banner: `"Term 1 Assessment Period closes in 3 days. 8 sections still pending."`
- The KPI card shows: `Assessments Completed: 78%`
- The Incident Donut chart indicates a 15% increase in "High Severity" disputes.
- The Principal clicks on the `High Severity` slice, which filters the list of severe incidents below. They see two fights logged by different teachers. 
- The Principal clicks on the counsellor alert list to confirm if a counsellor intervention has been assigned to those students.

---

## Related Screens

- [00-Module-Overview.md](./00-Module-Overview.md) — Module purpose and complete schema.
- [06-Periods.md](./06-Periods.md) — Setting active periods and lock dates.
- [11-Review-Queue.md](./11-Review-Queue.md) — Viewing/approving pending entries.
- [12-Incident-Log.md](./12-Incident-Log.md) — Logging new behavioral incidents.
