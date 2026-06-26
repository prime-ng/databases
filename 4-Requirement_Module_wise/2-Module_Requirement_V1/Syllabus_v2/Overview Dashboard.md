# Overview Dashboard — Business Requirements

## What This Screen Does

The Overview Dashboard is the executive command center for the Principal, Academic Director, and Heads of Departments. It aggregates millions of granular data points from the Syllabus Module into high-level visual widgets, providing an instant snapshot of the school's academic health.

Rather than making the Principal read through hundreds of rows of topic completion statuses, this screen uses advanced business intelligence logic to calculate overall completion percentages, flag lagging classrooms, and monitor teacher workload.

---

## When This Screen Is Used

- Daily Standups checked every morning by the Principal to gauge the pulse of the school's academic progress
- Board Meetings displayed during monthly management meetings to present visual, undeniable proof of curriculum execution
- Bottleneck Identification used to instantly identify critical systemic issues like why an entire cohort is behind schedule

---

## Key Dashboard Widgets and Metrics

**School-Wide Completion Dial**
A gauge chart displays the total percentage of the yearly syllabus completed across all classes. It does not simply count topics. It calculates the percentage based on the weightage or importance assigned to each completed topic relative to the total syllabus.

**Lagging and At-Risk Sections Alert**
A critical widget highlighting specific classes or sections that are falling significantly behind their scheduled completion dates. If a section is more than a week overdue on a high-priority lesson, it flashes red here in a list format.

**Teacher Workload and Pace**
A bar chart compares teachers based on their actual syllabus completion versus their planned targets. It shows exactly how many planned classes a teacher has successfully delivered this week versus what was originally scheduled.

**NEP Compliance Score**
A summarized radar chart metric showing how much of the syllabus taught so far has addressed higher-order cognitive, emotional, and physical skills, proving real-time compliance with National Education Policy standards.

---

## Business Rules and Conditions

**Role-Based Access Control Filtering**
The data displayed on this dashboard is deeply dynamic and heavily restricted based on the user's logged-in role. The Principal sees unfiltered, aggregated data for the entire school. For an HOD, the system automatically filters the data to show only the subjects under their department. For a Teacher, the system displays a personalized, isolated dashboard showing only their assigned sections and how their personal pace ranks against the expected school timeline.

**Exclusion Logic for Optional Content**
The calculation engine must respect the settings defined in the Topics Master. If a teacher marks an optional or extra-curricular topic as complete, the system must not artificially inflate the School-Wide Completion Dial, ensuring the core academic metric remains accurate.

---

## Workflow Steps

**Reviewing and Drilling Down on Alerts**
The Principal logs into the portal, clicks on the Syllabus Module, and navigates to the Overview Dashboard. The dashboard loads, displaying the School-Wide Completion Dial. The Principal notices the Lagging Alerts widget is flashing red for Class 10-C Mathematics. They click directly on the red alert, and the system deep-links them to the detailed Progress Tracker report, automatically pre-filtered to 10-C Mathematics, where they can see exactly which chapter is causing the delay.

---

## Example Scenario

During a parent-teacher meeting, an anxious parent complains that the syllabus is moving too slowly compared to a neighboring school. 

The Principal opens the Overview Dashboard on their tablet, clicks on the parent's child's specific section, and shows the parent the visual gauge. The Principal explains that the visual data shows the section has completed 65% of the syllabus by Week 20, which the algorithm confirms is exactly on track and perfectly aligned with the annual planner and the Board's recommendations. The visual, real-time data instantly resolves the parent's concern.

---

## Related Screens

- **Progress Tracker** — The detailed, tabular report that sits behind these high-level widgets
- **Lesson Date Planning** — The source of the Planned vs Actual metrics driving the Lagging Alerts
