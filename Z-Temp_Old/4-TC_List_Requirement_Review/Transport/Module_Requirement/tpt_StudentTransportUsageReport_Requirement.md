# Student Transport Usage Report

## What This Report Shows

This report shows student-level boarding and unboarding activity for students who have a transport allocation. It displays how many boardings and unboarding events each student has, and highlights missed events (boarding without unboarding or vice versa). The report only shows students with transport allocation — it does NOT compare transport-enrolled vs non-transport students.

## Default Data Load / Filters

The report loads as a tab within the Transport Reports page. Filters available: Date Range, Class/Section (dropdown), Route (dropdown), Stop (dropdown). There is no Academic Session filter. The query uses `whereHas('transportAllocation')` so only students with a transport allocation record are included.

## When This Report Is Used

Staff with permission use this report to view boarding/unboarding activity for transport-enrolled students. The report shows per-student boarding counts and flags missed events. Note: the report does NOT show transport vs non-transport comparison, does NOT calculate average attendance percentages, and does NOT support export/PDF.

## Key Metrics / KPIs

The report shows four KPI cards: Total Students (count of students with transport allocation in the filter range), Total Boardings (sum of all boarding events), Total Unboardings (sum of all unboarding events), and Missed Events (count of students with missed pickup or missed drop). There is no "Enrolled in Transport", "Non-Transport", or "Avg Attendance" KPI — the report only shows students who already have transport allocation.

## Charts and Visualizations

The report has three charts:

1. **Student Transport Usage** (bar chart) — Shows boardings and unboardings per student (top 10 students).
2. **Missed Events Analysis** (doughnut chart) — Shows proportion of missed pickups vs missed drops.
3. **Class-wise Transport Usage Analysis** (bar chart) — Shows boardings, unboardings, and missed pickups grouped by class. There is no transport-enrolled vs non-transport comparison, no school average line, and no click-to-filter functionality. Charts auto-update when filters change via AJAX — no separate refresh button.

## Data Sources (tables used)

The primary data source is `std_student_academic_sessions` (with `whereHas('transportAllocation')` filter). Related data comes from `tpt_boarding_log` via the `boardingLogs` relationship. The `transportAllocation` relationship on `StudentAcademicSession` provides route and stop details.

## Permissions

The report is a tab within the Transport Reports page. The page-level access is controlled by `tenant.transport.viewAny` (controller Gate check). The tab itself checks `tenant.student-transport-usage.viewAny` via the `x-backend.tab.nav-tab` permission key.

## Who Can Access

Any user with `tenant.transport.viewAny` AND `tenant.student-transport-usage.viewAny` permissions can access this tab. No per-role restrictions are coded.

## Example Scenario

Mrs. Desai opens the Transport Reports page and selects the Student Transport Usage tab. The report shows 4 KPI cards with counts for her selected filters. A bar chart shows the top 10 students by boardings/unboardings, a doughnut shows missed event distribution, and a class-wise bar chart shows boarding activity across classes. She can scroll down to a paginated table showing individual student data with route, stop, boarding/unboarding counts, and missed event flags.

## Logic Flow (how the report query works)

Step 1: The report is a tab within Transport Reports page. AJAX loads the section.

Step 2: Controller calls `getTransportUsage()` which queries `StudentAcademicSession` filtered by `academic_session_id`, `class_section_id`, and `whereHas('transportAllocation')`.

Step 3: Each session record is mapped to: `student_name`, `class_name`, `section_name`, `route_name`, `stop_name`, `total_boardings`, `total_unboardings`, `missed_boarding` (YES/NO), `missed_drop` (YES/NO).

Step 4: KPI cards show: Total Students (count), Total Boardings (sum), Total Unboardings (sum), Missed Events (missed_boarding + missed_drop counts).

Step 5: Three charts render: bar chart (top 10 students by boardings/unboardings), doughnut (missed pickups vs drops), bar chart (class-wise analysis). If no data, "No data available" shown.

Step 6: Paginated table shows individual records with Student, Class, Route, Stop, Boarded/Unboarded counts, Missed Pickup/Drop badges, and computed Status (Excellent/Good/Fair/Poor based on attendance rate). No click-to-filter, no sort, no export, no PDF.
