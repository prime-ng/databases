# Overview Dashboard — Business Requirements

## What This Screen Does

The Overview Dashboard is the executive command center for the Principal, Academic Director, and Heads of Departments. It aggregates millions of granular data points from the Syllabus Module into high-level visual widgets, providing an instant snapshot of the school's academic health.

Rather than making the Principal read through hundreds of rows of topic completion statuses, this screen uses advanced business intelligence logic to calculate overall completion percentages, flag lagging classrooms, and monitor teacher workload.

---
## Default Data Load

The Report screens (Dashboard, Progress Tracker, Coverage Audit, Resource Matrix, Planning Accuracy) are all rendered by SyllabusController@report() (GET /syllabus/report). They load shared dropdowns (classes, subjects, academic sessions) plus tab-specific queries against slb_syllabus_schedule with filters for academic_session_id, class_id, and subject_id. Dashboard uses aggregation queries; Progress/Coverage/Resource/Accuracy use paginated queries (10/page).

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

---


## Requirements

- System must load dashboard widgets under the `dashboard` tab on `report.index` (route: `GET /report`, name: `report.index`)
- System must compute `$stats` array in `SyllabusController@report()` via a single aggregation query on `SyllabusSchedule`:
  - `total_topics`: total count of scoped records
  - `released`: count where `is_active = 1`
  - `overdue`: count where `is_active = 0 AND scheduled_end_date < today`
  - `progress`: percentage = `(released / total_topics) * 100`
- System must compute `$subjectCoverage` as a grouped bar chart dataset: join `sch_subjects`, group by `subject_id`, compute `total` and `released`, derive percentage
- System must compute `$trendData` for the last 15 days: group by `DATE(updated_at)`, count released records
- System must compute `$classProgress` grouped by `class_id` (join `sch_classes`), showing `total` and `completed` counts per class
- System must compute `$statusDistribution` associative array: `On Track`, `Overdue`, `Released`
- System must compute `$recentCompletions`: last 10 released records ordered by `updated_at` DESC, eager-loaded with `topic`, `lesson`, `class`, `subject`
- System must check `tenant.syllabus-view-dashboard.viewAny` permission via `SyllabusReportPolicy::viewDashboard()`
- View partial: `resources/views/report/partials/dashboard.blade.php`

---


## Who Can Access This Screen

- **Principal** — Full school-wide dashboard with all metrics visible
- **Academic Director** — Full school-wide view for curriculum oversight
- **Head of Department** — Filtered view showing only their department's subjects and teachers
- **Teacher** — Personalised dashboard showing only their assigned sections and personal pace comparison

All access is gated by `SyllabusReportPolicy::viewDashboard()` which checks `tenant.syllabus-view-dashboard.viewAny`.

---


## How This Screen Works — Logic Flow (Non-Technical)

The Overview Dashboard is a read-only tab rendered by `SyllabusController@report()`. When the user navigates to the report page with `tab=dashboard`, the controller executes a series of aggregated queries against the `slb_syllabus_schedule` table. All queries are scoped by the `$applyFilters` closure which conditionally adds `WHERE` clauses for `academic_session_id`, `class_id`, and `subject_id` based on the user's filter selections. Stats cards are computed in a single `selectRaw` query with `COUNT(*)` and conditional `SUM` expressions. Chart data (`subjectCoverage`, `trendData`, `classProgress`) each use separate `join` + `groupBy` queries to produce structured datasets. `$recentCompletions` fetches the 10 most recently updated active records with their relations. All data is passed to `syllabus::report.index` which renders the `dashboard.blade.php` partial inside the tab framework.

---


## Validate Before Save

**Skip Validate Before Save** — This screen is a read-only dashboard with BI widgets.

---


## Error Handling and Validation Messages

- **Role Scope Warning:** "Some widgets may be empty due to your access permissions. Contact your administrator if you believe data is missing."
- **Stale Data Notice:** "Dashboard data was last refreshed at [timestamp]. Pull down or click Refresh to load the latest data."
- **No Active Session Error:** "No active academic session found. Please activate a session in Academic Setup before using the dashboard."
- **Widget Load Failure:** "One or more widgets failed to load. Please refresh the page or contact support."

---


## Success Scenarios

- A Principal views the dashboard every morning and immediately spots a red alert for Class 10-C Mathematics being 8 days behind. They click the alert and are taken to the Progress Tracker pre-filtered to that section, enabling swift intervention.
- An HOD uses the Teacher Workload bar chart during a weekly meeting to show Mrs. Sharma that she has completed only 40% of her planned topics versus 85% by her peers, prompting a mentoring conversation.
- The school management board views the NEP Compliance Score widget during a quarterly review and sees the school has achieved 72% compliance, validating their curriculum reforms.

---


## Failure Scenarios

- The dashboard loads with zero data because the academic session has no syllabus plans created yet, showing empty widgets across the board and requiring the user to first set up Lesson Date Planning.
- The lagging alerts widget is empty despite teachers being behind schedule because the "Exclude Optional Content" rule incorrectly filtered out core topics due to a misconfiguration in the Topics Master.
- A Teacher logs in but sees a blank dashboard because their class-section assignment has not been set up in the system, requiring HR to update the teacher's schedule.

---


## Dependencies module and tables

| Module | Tables |
|--------|--------|
| Syllabus Core | `slb_syllabus_schedule` (primary aggregation source) |
| Syllabus / Lesson Planning | `slb_lessons`, `slb_topics` |
| Academic Setup | `sch_org_academic_sessions_jnt`, `sch_classes`, `sch_subjects` |
