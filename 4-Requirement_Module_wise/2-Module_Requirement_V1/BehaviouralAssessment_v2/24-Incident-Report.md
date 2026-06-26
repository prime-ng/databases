# Incident Report — Business Requirements

## What This Screen Does

The Incident Report dashboard is a standalone tracking and analytical panel focused entirely on real-time conduct tracking. While other reports summarize term grades, this report aggregates the daily logs recorded in the [Incident Log](./12-Incident-Log.md), detailing positive achievements, disciplinary infractions, [Witness testimonies](./13-Witnesses.md), and [Interventions Applied](./14-Interventions-Applied.md).

It compiles transactional logs into high-level analytical widgets (such as Weekly Incident Frequencies, Category Distributions, and Intervention Success Rates), helping the school administration identify repeating behavioral triggers and assess the effectiveness of disciplinary and supportive protocols.

---

## When This Screen Is Used

- **Monthly Administrative Audits**: The Principal reviews the frequency and categories of negative incidents to measure general school safety and order.
- **Parent Confrontation Meetings**: The counsellor opens the report pre-filtered for a specific student to present parent-ready printouts showing timelines of infractions and linked witness statements.
- **Intervention Efficacy Reviews**: Evaluating which restorative interventions show the highest success rates in preventing repeating offenses.

---

## Key Fields & Screen Layout

The dashboard features search parameters at the top, analytical metric widgets in the middle, and a detailed tabular log grid at the bottom.

### Search and Filters
- **Date Range**: Start and End Date pickers (defaults to active term).
- **Incident Type**: Dropdown (Options: `All`, `Positive (Achievements)`, `Negative (Infractions)`).
- **Severity**: Dropdown (Options: `All`, `Info`, `Low`, `Medium`, `High`).
- **Class & Section**: Filter logs by a specific cohort.
- **Student**: Filter by a specific student profile.

### Analytical Charts & Widgets
- **Weekly Frequency Curve**: A line chart plotting the count of incidents logged week-by-week to identify cycles of behavioral spikes (e.g., spikes before school exams or holidays).
- **Intervention Success Rate**: A donut chart showing the percentage of assigned interventions that reached `Completed` status vs. those marked `Cancelled` or `In Progress`.
- **Top 3 Infraction Triggers**: Horizontal bar chart highlighting the categories with the highest incident counts (e.g., "Late Attendance," "Littering").

### Incidents Grid Table
| Date | Student Name | Logged By Staff | Category & Severity | Description | Witness Count | Applied Intervention & Status |
|------|--------------|-----------------|---------------------|-------------|---------------|--------------------------------|
| 2026-11-20 | John Doe | Mr. Roy | Peer Relations (High) | Academic cheating dispute. | `2 Witnesses` | Parent Counseling (Completed) |
| 2026-11-18 | Amit Sharma | Mrs. Priya | Cooperation (Info) | Cleaned laboratory workspace. | `0 Witnesses` | Praise Badge (Completed) |

---

## Business Rules and Conditions

**The Escalation Link**
- The table must fetch links dynamically from:
  - `ba_incidents` (The core event).
  - `ba_incident_witnesses_jnt` (Count of witness records).
  - `ba_incident_intervention_jnt` joined with `ba_interventions` (The corrective actions and their current status).

**Export Compliance & Privacy**
- **CSV & Excel Exports**: When exported for administrative use, the file includes student roll numbers and names.
- **Public/Staff Digests**: When exported as an aggregate school safety digest, the system automatically replaces individual student names with anonymous hashes (e.g., `STUDENT-SHA-123`) to comply with pupil data privacy regulations.

---

## Workflow Steps

**Reviewing Disciplinary Trends**
1. Counsellor logs in and navigates to **Standalone Reports -> Incident Report**.
2. Selects Date Range: `Past 30 Days`, Incident Type: `Negative (Infractions)`, Severity: `High`.
3. Clicks **Generate Report**.
4. The line chart highlights a sudden spike in high-severity incidents during the second week of November.
5. In the grid below, the counsellor filters by "Category".
6. Sees 4 high-severity incidents under "Exam Honesty" matching the dates of mid-term examinations.
7. This trace confirms a correlation between exam stress and honor-code violations, prompting the counsellor to schedule stress-management and ethics assemblies before the next final examination period.

---

## Example Scenario

During a parent assembly, the coordinator wants to present a summary of positive conduct. They open the Incident Report, select Type: `Positive`, pick `PDF` format, and export it. The generated PDF showcases that students logged over 250 positive achievements (helpfulness, academic triumphs, cleanliness initiatives) this term, with a 98% intervention reinforcement completion rate.

---

## Related Screens

- [12-Incident-Log.md](./12-Incident-Log.md) — Source database for behavioral events.
- [13-Witnesses.md](./13-Witnesses.md) — Witness linkages.
- [14-Interventions-Applied.md](./14-Interventions-Applied.md) — Resolution timelines.
- [15-Reports-Hub.md](./15-Reports-Hub.md) — The parent reporting portal.
- [20-Student-Report.md](./20-Student-Report.md) — Individual student profiles.
