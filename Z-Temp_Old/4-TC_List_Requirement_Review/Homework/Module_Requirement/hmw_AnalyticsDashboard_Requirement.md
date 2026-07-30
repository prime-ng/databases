# Homework Analytics Dashboard — Business Requirements

## What This Screen Does

The Homework Analytics Dashboard is the big-picture overview screen that answers the question: "How is homework going across the school?" Think of it as a car dashboard for homework management — it shows key metrics at a glance, trend charts, and highlights areas that need attention.

When a teacher or administrator opens this dashboard, they can immediately see: How many homework assignments are currently active? How many students have submitted their work? How many submissions are still waiting to be graded? What is the overall submission rate (percentage of students who submitted versus those who were assigned)? Which subjects have the most homework? How have submission trends changed over the past week?

This screen is designed for quick, at-a-glance monitoring. It uses large numbers for key metrics, colour-coded charts for trends, and a simple table for the most recent submissions. All data can be filtered by class, section, subject, and date range, so different users can see the information that matters to them — a class teacher can filter to see only their class data, while the principal can see school-wide data.

---

## When This Screen Is Used

- **Daily Check-In:** A teacher starts their day by checking the dashboard to see how many submissions came in overnight and how many are pending grading.
- **Weekly Review:** An Academic Coordinator reviews the dashboard every Friday to monitor submission rates and identify classes or subjects with low engagement.
- **Administrative Oversight:** The Principal checks the dashboard to ensure homework is being assigned and submitted consistently across the school.
- **Parent-Teacher Meeting Preparation:** A teacher reviews the dashboard to get a quick summary of homework performance before meeting with parents.

---

## Default Data Load

The Analytics Dashboard is the default tab that loads when a user first opens the Homework section. The system automatically computes the following metrics based on the current data (without any filters applied):

**Key Performance Indicators (KPI Cards) — Top Row:**
- **Active Homeworks:** Number of homework that are currently in Published status.
- **Total Assignments:** Total number of assignment records created across all published homework.
- **Total Submissions:** Total number of submissions received across all homework.
- **Pending Grading:** Number of submissions that have been received but not yet graded (marks_obtained is still empty).
- **Submission Rate:** The percentage of assignments that have received submissions (total submissions / total assignments x 100). Displayed as a percentage with a colour indicator (green for high, amber for medium, red for low).

**Charts — Middle Section (Two Columns):**
- **Left Column (Larger):** A bar chart showing submissions over the last 7 days. Each day shows how many submissions were received. This helps identify weekly patterns — for example, submissions might spike on Mondays (after weekend homework) and drop on Fridays.
- **Right Column (Smaller):** A donut chart showing the split between Graded and Pending submissions. This gives an immediate visual of the grading workload.

**Latest Submissions — Bottom Section:**
A compact table showing the 5 most recent submissions with student name, homework title, and status. This gives a quick view of what is happening right now.

**Top Subjects — Side Section:**
A horizontal bar chart showing the top 6 subjects by homework count. This helps identify which subjects have the heaviest homework load.

---

## Key Metrics at a Glance

**Active Homeworks Count**
This number tells you how many homework are currently published and available to students. A very low number might mean teachers are not assigning enough homework. A very high number might mean students are overloaded.

**Total Assignments**
This is the total number of individual student assignment records. For example, if there are 5 active homework and each has 40 students, the total assignments would be approximately 200. This gives a sense of the overall volume of homework being managed.

**Total Submissions**
This is the total number of submissions received across all homework. Comparing this with Total Assignments gives the Submission Rate.

**Submission Rate**
The most important health metric. Calculated as (Total Submissions / Total Assignments) x 100. A high rate (above 85%) means students are consistently submitting their work. A low rate might indicate that homework is too difficult, deadlines are too tight, or students need more encouragement.

**Pending Grading**
This is the number of submissions that have been received but not yet graded. A high number here means teachers have a backlog of grading work. This metric is useful for administrators to identify teachers who might need support or additional time for grading.

**7-Day Submission Trend**
A bar chart showing how many submissions were received each day for the last 7 days. This reveals weekly patterns. For example, if submissions spike on Sunday nights, it might indicate that students are procrastinating and submitting at the last minute.

**Graded vs Pending Split**
A donut chart showing the proportion of submissions that have been graded versus those still pending. An ideal state would show most submissions in the "Graded" section (green) with only a small "Pending" section (amber).

**Top Subjects by Homework Count**
A horizontal bar chart ranking the top 6 subjects by the number of homework created. This helps administrators see if homework load is balanced across subjects or if certain subjects are assigning significantly more homework than others.

---

## Business Rules and Conditions

**All Metrics Respect the Same Filters**
When a user selects a filter (for example, choosing Class 10 from the dropdown), ALL metrics on the dashboard update to reflect only data for that class. The submission rate recalculates, the charts redraw, and the KPI numbers update. This ensures consistency — the user never sees a mismatch between filters and displayed data.

**Submission Rate Formula**
Submission Rate = (Total Submissions / Total Assignments) x 100. If there are no assignments yet, the rate is shown as 0% to avoid a division-by-zero error.

**Empty State**
If no data exists for the selected filters (for example, a new class with no homework yet), all KPI cards show 0, charts show empty datasets, and a message "No data available" is displayed in the tables.

**Dashboard Is Read-Only**
The Analytics Dashboard is for viewing only. No data entry, editing, or actions are available here. All actions (creating homework, grading submissions, etc.) are done in other tabs.

**Default Active Tab**
When a user first navigates to the Homework section, the Analytics Dashboard is the default active tab. This ensures the user sees the overview before diving into specific tabs like Homework List or Submissions.

---

## Example Scenario

**Scenario: Weekly Homework Health Check**

The Principal of Sunshine International School opens the Homework Analytics Dashboard on Friday morning. She sees:

**KPI Cards:**
- Active Homeworks: 15
- Total Assignments: 450
- Total Submissions: 380
- Pending Grading: 42
- Submission Rate: 84.4% (displayed in amber — close to the 85% target)

**Observations:**
1. The submission rate is 84.4% — slightly below the school's target of 85%. This needs attention.
2. 42 submissions are pending grading. The Principal notes this and will remind teachers to clear their grading backlog.
3. The 7-day chart shows a spike on Monday (120 submissions) and a drop on Friday (30 submissions). This matches the pattern of weekend homework being submitted on Monday morning.
4. The "Top Subjects" chart shows Mathematics has 5 active homework, Science has 4, English has 3, and History, Geography, and Art have 1 each. The Principal notes that Mathematics and Science have the heaviest homework load.

**Action Taken:**
The Principal filters by Class 10 and sees that the submission rate drops to 72% for this class — significantly lower than the school average. She decides to speak with the Class 10 teachers about this.

---

## Related Screens

- **Homework Management** — Where homework is created; the dashboard shows aggregate data from this tab.
- **Summary Report** — A more detailed, per-homework breakdown of assignment and submission counts.
- **Submission Tab** — Where individual submissions are managed; the dashboard aggregates this data.

---

## Requirements

**Controller:** Modules\LmsHomework\Http\Controllers\LmsHomeworkController@index()
- All dashboard metrics are computed within the index() method when the active tab is homework_analytics (the default).
- Separate queries are built for Homework (active count + subject grouping), HomeworkAssignment (total assignments), and HomeworkSubmission (submissions, pending grading, chart data).
- All filter conditions (class_id, subject_id, section_id, date range) are applied consistently to all queries using query builder when() clauses.
- Chart data is prepared as PHP arrays and passed to the view as JSON-encoded variables for Chart.js rendering.

**Models Used:**
- Homework (lms_homework) — Active count by published status; homework count grouped by subject
- HomeworkAssignment (lms_homework_assignment) — Total assignments count
- HomeworkSubmission (lms_homework_submissions) — Total submissions, pending grading, graded count, 7-day trend, latest 5 submissions

**Policy:** HomeworkDashboardPolicy (permission group: 	enant.home-work-dashbord.*)
- Note: The permission key uses "dashbord" (without the 'a' in 'dashboard') — this misspelling is intentional and consistent across all files.

**Views:** nalytics/index.blade.php — Dashboard layout with KPI cards, Chart.js containers, and latest submissions table.

**Tab Integration:** The first tab in the hub view with id="homework_analytics" and :active="request('tab', 'homework_analytics')" — making it the default active tab. Guarded by @can('tenant.home-work-dashbord.viewAny').

---

## Who Can Access This Screen

| Role | What They Can See | Permission Needed |
|------|------------------|-------------------|
| Teacher | Dashboard filtered to their own classes (or all data if no filter) | 	enant.home-work-dashbord.viewAny |
| School Admin | All-school dashboard with full data access | 	enant.home-work-dashbord.viewAny |
| Principal | All-school dashboard (read-only) | 	enant.home-work-dashbord.viewAny |

---

## How This Screen Works — Logic Flow (Non-Technical)

When a user opens the Homework section, the system checks whether they have permission to view the dashboard. Since the Analytics tab is the default, it is the first thing they see.

The system runs five queries in the background:
1. Count of homework with Published status (active homeworks).
2. Count of all assignment records (total assignments).
3. Count of all submissions (total submissions).
4. Count of submissions with no marks (pending grading).
5. For the charts: submissions grouped by day (last 7 days), graded vs pending counts, and homework count by subject (top 6).

All five queries respect the same filters. If the user selects "Class 10" from the dropdown, all five queries add a condition to only count records for Class 10. This ensures consistency — the numbers all add up.

The results are passed to the view, where JavaScript (Chart.js) renders the charts. The KPI numbers are displayed as large, bold text in borderless cards with colour-coded icons.

When the user changes a filter and clicks Search, the page reloads with the new filter values, and all queries re-run with the updated filter conditions.

---

## Error Handling and Validation Messages

| Scenario | What the User Sees | Type |
|----------|-------------------|------|
| No data exists for selected filters | All KPIs show 0, charts are empty, "No data available" message shown | Informational |
| Invalid date range selected | "Please select a valid date range." | Validation |
| No submissions exist for chart data | Charts render with empty datasets | Informational |

---

## Success Scenarios

**SC-001 — Dashboard Loads Correctly with Data**
The Principal opens the Homework section. The Analytics Dashboard loads with KPI cards showing accurate numbers, charts rendered with Chart.js, and the latest 5 submissions displayed. All metrics are consistent (e.g., total submissions ≤ total assignments).

**SC-002 — Filters Work Correctly**
A Class 10 teacher selects "Class 10" from the filter dropdown and clicks Search. The dashboard updates to show only data for Class 10. The submission rate recalculates, charts redraw, and all numbers are consistent with the filtered view.

**SC-003 — Empty State Handled Gracefully**
A new subject has no homework yet. The teacher selects it from the filter. All KPI cards show 0, and the charts are empty with a "No data available" message. No errors occur.

---

## Failure Scenarios

**FC-001 — User Without Permission**
A teacher who has not been granted dashboard permission tries to access the Homework section. The Analytics tab is hidden from view (the system checks permissions before rendering the tab). If they try to navigate directly by URL, they receive a 403 Forbidden error.

**FC-002 — Very Large Dataset**
The system handles large datasets efficiently because all metrics are computed using database aggregate queries (COUNT, GROUP BY) rather than loading individual records into memory. Even with thousands of homework and submissions, the dashboard loads within a few seconds.

---

## Dependencies module and tables

| Module | Tables Used | Why |
|--------|-------------|-----|
| LmsHomework | lms_homework, lms_homework_assignment, lms_homework_submissions | All dashboard metrics are computed from these three tables |
| SchoolSetup | sch_classes, sch_sections, sch_subjects | Filter dropdowns and display names |
