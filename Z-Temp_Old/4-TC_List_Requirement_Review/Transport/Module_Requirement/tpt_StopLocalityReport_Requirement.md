# Stop and Locality Analysis Report

## What This Report Shows

Mrs. Desai, the Principal of Green Valley School, uses this report to see stop-level boarding, allocation, and delay data across routes. This report shows her how many students are allocated to each stop, how many actually board, what the average dwell time is (scheduled vs actual), and the average arrival delay per stop. It helps her answer questions like "Which stop has the most boardings?" and "Is the bus getting delayed at specific stops?"

This report is very helpful when parents complain about a specific stop. If a parent from Green Park stop says the bus always comes late, Mrs. Desai can open this report, select the Green Park stop, and check the average delay and boarding variance.

The report is also useful for planning new routes. When the school opens a new area for transport, Mrs. Desai can look at similar stops on existing routes to estimate how many students might use the new stop.

## Default Data Load / Filters

When Mrs. Desai opens this report, it shows data for the full current month (1st to end of month) by default. These defaults make sure Mrs. Desai sees the most recent and relevant data without any extra effort.

The report has three filters.

The first filter is Date Range. Mrs. Desai can select any from and to date. This allows her to check stop performance for a specific week, month, or term.

The second filter is Route. This dropdown shows all active routes like "Route A - MG Road", "Route B - Lake View", and so on. By default it shows "All Routes". When a specific route is selected, the report shows only the stops belonging to that route.

The third filter is Stop. This dropdown shows all pickup points across all routes. By default it shows "All Stops" so the report shows combined data for all stops. When a specific stop is selected, the report narrows down to data for only that stop.

All three filters work together. If Mrs. Desai selects Route A and stop "Green Park" for July 2026, she will see Green Park stop's performance on Route A for July 2026 only.

## When This Report Is Used

Mrs. Desai uses this report when she receives parent complaints about specific bus stops. If a parent writes an email saying "The bus did not come to Sunshine Apartments stop until 7:50 AM today," Mrs. Desai opens this report, selects that stop, and checks the average arrival delay for the last week.

Mr. Sharma, the Transport In-charge, uses this report every Monday morning to review the previous week's stop performance. He checks which stops had high delays and speaks with the respective drivers. He also checks utilization rates — stops with low boarding numbers relative to allocation may indicate over-allocation.

The school uses this report when planning route optimization at the start of every academic session.

This report is also used during parent-teacher meetings when parents ask about bus timing accuracy. Mrs. Desai can show parents the actual data about how punctual the bus is at their child's stop.

## Key Metrics / KPIs

The report shows four important numbers at the top. These numbers change based on the filters Mrs. Desai applies.

Total Boardings is the first number. It shows the total count of boarding events across all selected stops in the date range. This gives Mrs. Desai a quick sense of how many boarding activities happened.

Allocated Students is the second number. It shows the total number of unique students who are allocated to the stops in the current view. This helps Mrs. Desai understand the total student capacity at the selected stops.

Avg Arrival Delay is the third number. It shows the average delay in minutes across all stops in the current view. The system calculates this by comparing the actual reaching time with the scheduled arrival time at each stop for each trip. The delay is the difference in minutes. All delay minutes across all trips and stops are averaged.

Utilization Rate is the fourth number. It shows the percentage of allocated students who actually boarded, calculated as total boardings divided by total allocated students times 100. This tells Mrs. Desai how effectively each stop is being used. A very low rate may indicate that students allocated to a stop are not actually boarding there, suggesting a data or routing issue.

## Charts and Visualizations

The report has three charts that help Mrs. Desai visualize the stop data.

The first chart is a Bar chart for Boardings vs Allocated. This chart shows stop names along the bottom and student counts on the left side. Each stop has two bars — one showing allocated students (green) and one showing actual boardings (blue). A button toggle lets Mrs. Desai switch between Grouped view (bars side by side) and Stacked view (bars on top of each other). This helps her see the gap between allocation and actual boarding per stop. If a stop has a tall green bar but a short blue bar, many allocated students are not boarding at that stop.

The second chart is a horizontal Bar chart for Delay Analysis. This chart has stop names on the left and delay in minutes on the top. Each stop gets a horizontal bar colored by severity: green for on time (0-5 min), yellow for moderate (6-15 min), and red for high (15+ min). A color legend is shown below the chart. This gives Mrs. Desai a quick visual of which stops have delay problems.

The third chart is a horizontal Bar chart for Stop Utilization Rates. This chart has stop names on the left and utilization percentage on the top (0-100%). Bars are colored by threshold: green for low utilization (under 60%), yellow for moderate (60-80%), and red for over-utilized (80%+). This tells Mrs. Desai which stops may be overcrowded versus underused.

All charts update when filters change. If Mrs. Desai selects a specific route, charts show only that route's stops. If she selects a specific date range, charts reflect data from that period only.

## Data Sources (tables used)

This report pulls data from five different tables in the system.

The first data source is the Route Master table (`tpt_route`). Routes are defined with their name, code, and status. The report uses this table to filter by route.

The second data source is the Pickup Points table (`tpt_pickup_points`). Each pickup point or stop has a name, location, landmark, and status. The report accesses stops through the `pickupPointRoutes` relationship on the Route model, which links pickup points to routes via the junction table `tpt_route_pickup_point_jnt`.

The third data source is the Trip Stop Detail table (`tpt_trip_stop_detail`). This records each stop visit for every trip: scheduled arrival time, actual reaching time, scheduled departure time, actual leaving time, and a reached flag. The report uses this to calculate average arrival delay and dwell time metrics (avg scheduled duration, avg actual duration, variance). The system accesses this through a relationship called `tripStopDetails` on the PickupPoint model.

The fourth data source is the Student Boarding Log table (`tpt_student_boarding_log`). This records each time a student boards or gets off the bus. The report uses this to count how many boarding events happened at each stop. The system accesses this through a relationship called `boardingLogs` on the PickupPoint model.

The fifth data source is the Student Route Allocation table (`tpt_student_route_allocation_jnt`). This tells which student is allocated to which route and which stop. The report uses this to count the unique students allocated to each stop. The system accesses this through a relationship called `studentAllocations` on the PickupPoint model.

## Permissions

This report is protected by a permission rule. The system checks whether the user has the `tenant.stop-analysis.viewAny` permission before showing the Stop & Locality Analysis tab.

If a user tries to open this report without this permission, the tab button is hidden from the navigation bar and the report content is never loaded.

The school system administrator assigns this permission from the user management section. Only staff members who need to analyze stop-level data are given this permission. This ensures that sensitive location and student distribution data is not visible to everyone.

## Who Can Access

The following people at Green Valley School can access this report:

Mrs. Desai, the Principal, has access because she needs to resolve parent complaints about specific stops and make route planning decisions.

Mr. Sharma, the Transport In-charge, has access because he needs to manage daily stop operations and communicate with drivers about delays.

The Vice Principal has access for backup purposes and to assist with parent complaints.

The School Administrator has access for system management and data audits.

Route supervisors and drivers do not have direct access to this report. Mr. Sharma shares relevant stop information with them verbally or through printed sheets when needed. This is because the report contains student-level distribution data that should not be widely shared.

Class teachers, parents, and students do not have access to this report.

## Example Scenario

It is the third week of August 2026. Mrs. Desai has noticed a pattern of complaints from parents whose children board at the "Sun City" stop on Route C. For the last two weeks, parents have been saying the bus arrives late.

Mrs. Desai opens the Stop and Locality Analysis Report. The default view shows all stops across all routes for August 2026. Total Boardings is 340. Allocated Students is 400. Average Arrival Delay across all stops is 6 minutes. Utilization Rate is 85%.

She selects "Route C" from the Route filter. She looks at the bar chart for Boardings vs Allocated. The Sun City stop shows 18 allocated but only 12 boardings. She then checks the delay analysis chart — Sun City has a red bar showing 18 minutes average delay. The utilization chart shows Sun City at 67% utilization (amber/yellow zone).

Mrs. Desai now has clear evidence that the Sun City stop has a serious delay problem and a boarding shortfall. She calls Mr. Sharma and asks him to investigate. Mr. Sharma checks with the Route C driver and finds out that the gate at Sun City apartment complex is very narrow and it takes 8 to 10 minutes for all students to board. Also, some allocated students have moved away but were never deallocated, explaining the low utilization.

Mr. Sharma proposes two solutions. First, clean up the student allocation records for Sun City. Second, ask the parents to have children ready at the gate 5 minutes before the scheduled time. Mrs. Desai approves both suggestions. After implementation in September, the Sun City stop delay comes down from 18 minutes to 5 minutes, and utilization improves to 95%.

## Logic Flow (how the report query works)

Here is how the system builds this report step by step.

Step one: Permission verification. When Mrs. Desai clicks to open this report, the system checks her user account for the `tenant.stop-analysis.viewAny` permission. If the permission is present, the tab content loads via AJAX. If not, the tab is hidden entirely.

Step two: Filter reading. The system reads the date range, route, and stop selections from the filter controls. If no changes have been made, it uses the default values of current full month, all routes, and all stops.

Step three: Query routes and stops. The system queries the Route table with the `pickupPointRoutes.pickupPoint` relationship eager-loaded. If a specific route is selected, it filters to that route. If a specific stop is selected, it filters to routes that have that stop. The routes are also filtered to active status only.

Step four: For each stop on each route, the system calculates `boarding_count` by counting the boarding logs linked to that pickup point within the date range.

Step five: For each stop, the system calculates `allocated_students` by counting unique students from the `studentAllocations` relationship on the pickup point.

Step six: Calculate `avg_arrival_delay`. The system opens the Trip Stop Detail records for each stop where `reached_flag = 1`. For each stop visit, it computes the difference in minutes between `reaching_time` and `sch_arrival_time`. These values are averaged to produce the average arrival delay per stop.

Step seven: Calculate dwell time metrics. The system computes `avg_scheduled_time` as the average of (`sch_departure_time` minus `sch_arrival_time`) in minutes — this is the expected dwell duration per stop. It computes `avg_actual_time` as the average of (`leaving_time` minus `reaching_time`) in minutes — the actual dwell duration. The `boarding_variance` is the difference between actual and scheduled dwell times. A positive variance means the bus is spending more time at the stop than scheduled.

Step eight: Prepare KPI data. Total Boardings is the sum of `boarding_count` across all stops. Allocated Students is the sum of `allocated_students`. Avg Arrival Delay is the average of all `avg_arrival_delay` values. Utilization Rate is (total boardings / total allocated) × 100.

Step nine: Prepare chart data. The bar chart shows each stop's allocated vs boarding count as grouped/stacked bars. The delay analysis chart shows each stop's average delay as a horizontal bar with color-coded severity. The utilization chart shows each stop's utilization percentage as a horizontal bar with color-coded thresholds.

Step ten: Prepare the detailed table. Each row shows: Route Name, Stop Name, Boarding Count, Allocated Students, Scheduled Dwell Time, Actual Dwell Time, Boarding Variance, Avg Arrival Delay, and Utilization Rate. The table is paginated at 10 rows per page.

Step eleven: The system renders the view. The four KPI boxes are at the top in a single row. Below them, the three charts are arranged in two rows: the main bar chart (8 columns) and delay analysis (4 columns) side by side, with the utilization chart below spanning full width. The detailed table is rendered below the charts. Both the charts section and the table section are loaded independently via separate AJAX calls.

Step twelve: The system waits for filter changes or pagination clicks. If Mrs. Desai changes any filter or clicks a pagination link, the system re-queries the data and reloads the corresponding section (charts or table) via AJAX. Charts animate with a 1-second ease-out transition when data updates.
