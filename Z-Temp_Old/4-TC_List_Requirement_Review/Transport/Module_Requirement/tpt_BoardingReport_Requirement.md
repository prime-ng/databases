# Student Boarding and Unboarding Report

## What This Report Shows

Mrs. Desai at Green Valley School uses the Student Boarding and Unboarding Report to track whether every student who boarded a school vehicle in the morning also unboarded at their destination in the afternoon. This is a safety-critical report that Mrs. Desai treats as her most important responsibility. Every school day, students board vehicles from their pickup points and travel to school. In the afternoon, they board again and travel back to their unboarding points. Mrs. Desai needs to know that no student is left on a vehicle at the end of a trip. This report shows the complete list of boarding and unboarding events for any selected date range. It highlights any student who boarded but has no corresponding unboarding record. These cases are flagged as safety risks. The report is essential for daily operations, safety audits, and parent communication. The report gives her visibility into student movement across all routes.

## Default Data Load / Filters

When Mrs. Desai opens this report, it loads as a tab within the Transport Reports page. The report has four KPIs at the top: Total Records, Completed Boardings, Partial Boardings (calculated as total minus completed), and Safety Risks. The data loads via AJAX after the page is ready. Filters available: Academic Session, Route (drop-down), Stop (drop-down), and Date Range. The default date range is the current date. Filters are presented at the top of the page with a filter button and reset link. Note: There is no Student name search filter — the report filters by student_id only, which requires knowing the student's system ID.

## When This Report Is Used

Mrs. Desai uses the Student Boarding and Unboarding Report to verify boarding and unboarding records. It helps identify safety risks. Note: no auto-refresh, no audio/visual alerts, no export/print, no Close Day button, and no Contact Driver.

## Key Metrics / KPIs

The Student Boarding and Unboarding Report displays four key numbers in a summary bar.

Total Records shows the total number of individual boarding log entries that exist for the selected date range and filters. This counts every row in the system.

Completed Boardings shows the number of records where the student has both boarded and unboarded (boarding_time and unboarding_time both present).

Partial Boardings shows the number of records where only boarding OR unboarding is recorded. This is calculated as Total minus Completed. This is a safety-relevant metric.

Safety Risk Count is the number of records where a student has boarded but has no unboarding record (boarding_time present, unboarding_time absent). This is the most important metric on the report.

## Charts and Visualizations

The Student Boarding and Unboarding Report contains two charts.

The first chart is a bar chart titled Daily Boarding Trend. This chart shows Boardings and Unboardings per day across the selected date range. The horizontal axis lists dates, and the vertical axis shows the count. Green bars represent boardings, blue bars represent unboardings.

The second chart is a doughnut chart titled Boarding Status Distribution. This chart shows the proportion of records by status category. There are up to four slices: Completed (green, both boarding and unboarding recorded), Partial (yellow, only one of the two recorded), Missed Boarding (red), and Missed Drop (orange). The legend shows the count and percentage for each slice.

## Data Sources (tables used)

The Student Boarding and Unboarding Report uses data from three tables in the school transport system.

The tpt_student_boarding_log table is the primary data source for this report. Every time a student boards a vehicle, the system creates a record in this table. The record includes the student identifier, the date, the route, the boarding time, and the boarding status. When the student unboards, the same record is updated with the unboarding time and status. This means one record represents the complete journey of one student for one trip. The table distinguishes between morning trips and afternoon trips using a trip type field. Morning trips are from home to school, and afternoon trips are from school to home. The report counts both types together to give the total boarding and unboarding numbers. This table provides the core data for all five KPIs and both charts in the report.

The tpt_route table contains information about each route, such as the route name, the assigned vehicle, and the driver name. This table is used to populate the Route filter drop-down and to label the bars in the route-wise chart. The system uses the boardingRoute and unboardingRoute fields within the boarding log to connect each record to its route details. The route names are displayed in the filter drop-down as simple names like Route 1 or Route 5 Green Valley Extension so Mrs. Desai can easily identify the route she wants to inspect. The driver name is displayed in the detailed record table so Mrs. Desai knows which driver was responsible for each route on each day.

The tpt_pickup_points table stores the names and locations of all pickup and drop-off points. The boardingStop field in the boarding log connects to this table to identify where a student boarded. The unboardingStop field identifies where the student got off. This table is used to display the stop names in the detailed record table below the charts.

These three tables are linked through the route identifier and the student identifier. The system queries these tables together to produce a complete picture of student movement for any selected date range.

## Permissions

Access to the Student Boarding and Unboarding Report is controlled by the permission key tenant.transport.viewAny (controller-level Gate check). The report is a tab within the Transport Reports page, which is also guarded by the tab permission check via `x-backend.tab.nav-tab`. No activityLog is recorded for viewing the report.

## Who Can Access

Any user with `tenant.transport.viewAny` permission can access this report tab. No per-student or per-role restrictions are coded.

## Example Scenario

It is a regular Tuesday afternoon at Green Valley School. Mrs. Desai opens the Transport Reports page and clicks the Student Boarding tab. The filters default to today's date. She does not change any filters and clicks the filter button.

The summary bar shows Total Records as 480, Completed Boardings as 476, Partial Boardings as 4, and Safety Risks as 1. The doughnut chart shows the distribution of Completed/Partial/Missed records. The daily boarding trend bar chart shows boardings and unboardings per day.

Mrs. Desai scrolls to the detailed table and sees a record for Aarav Sharma with a RISK badge. She calls the driver of Route 5. The driver finds Aarav Sharma asleep on the bus and records the unboarding. Mrs. Desai refreshes the page. The Safety Risk count drops to 0.

## Logic Flow

The following describes how the Student Boarding and Unboarding Report actually works in the code.

Step 1: The report is a tab within the Transport Reports page (`transportreport.blade.php`). When the tab is activated, an AJAX call loads the charts section.

Step 2: The controller method `buildStudentBoardingSection()` calls `getStudentBoardingReport()` which queries `StudentBoardingLog` filtered by `trip_date` between the selected date range. Additional filters: `academic_session_id`, `route_id`, `student_id`.

Step 3: Each record is mapped to an object with: `student_name`, `trip_date`, `boarding_time`, `unboarding_time`, `boarding_stop`, `unboarding_stop`, `status` (Completed if both times present, else Partial), `safety_risk` (Yes if boarding_time present but unboarding_time absent).

Step 4: The `boardingSummary` object is computed: `total` (count), `completed` (where status=Completed), `safety_risks` (where safety_risk=Yes), `completion_rate` (percentage).

Step 5: The view renders 4 KPI cards: Total Records, Completed Boardings, Partial Boardings (total - completed), Safety Risks.

Step 6: Two charts render via JavaScript: a bar chart (Daily Boarding Trend showing boardings vs unboardings per day) and a doughnut chart (Boarding Status Distribution showing Completed/Partial/Missed Boarding/Missed Drop). If no data exists, a "No data available" message is displayed on the canvas.

Step 7: Below the charts, a paginated table shows individual records with columns: Student, Class/Section, Date, Route, Boarding time, Unboarding time, Status (Completed/Partial), Safety (SAFE/RISK). The table is NOT searchable or sortable via client-side search, and does NOT support PDF/spreadsheet export.

Step 8: There is no auto-refresh, no safety alert red banner, no audio alert, no Close Day button, no Contact Driver button, and no export functionality. The report is purely read-only display of boarding log data with computed status fields.
