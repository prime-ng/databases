# Transport Finance and Leakage Report

## What This Report Shows

Mrs. Desai, the Transport Supervisor at Green Valley School, uses this report together with the school's Accounts Manager to understand the financial health of the transport department. The report reveals something that many schools struggle to track accurately, whether students who are using the school transport service are actually paying for it, and if they are paying the full amount.

This report connects student transport usage data with fee payment records. It shows every student who has been allocated a transport seat, how many days they actually travelled, how much transport fee was assigned to them for the academic session, how much they have paid, and whether there is a balance due. The report then flags each student as having no leakage, partial payment leakage, or no payment leakage based on their payment status relative to their usage.

The report answers critical financial questions like: How much total transport fee should the school have collected this session? How much has actually been collected? How many students are using transport without paying anything? How many students have paid only partially? Which classes or routes have the highest leakage? What is the total amount of unpaid transport fees? Are there students who travelled for the full term but have not paid a single instalment?

Mrs. Desai values this report because transport is a significant revenue source for the school, and leakage directly impacts the transport department's ability to cover fuel costs, driver salaries, vehicle maintenance, and insurance. Before this report existed, the school relied on manual reconciliation between the transport attendance registers and the accounts ledger, which was time-consuming and prone to errors. Now Mrs. Desai and the Accounts Manager can identify leakage cases within minutes and take timely follow-up action.

## Default Data Load / Filters

When the Transport Finance and Leakage Report opens, the system automatically loads data for the current academic session across all classes and all routes. This gives Mrs. Desai a complete view of the transport financial position from the start of the session to the current date.

The report provides the following filter options:

Date Range filter allows Mrs. Desai to select any custom period within the academic session. She uses this when she wants to focus on a specific term or month. For example, at the end of the first term, she sets the date range to cover only the first term months to generate a term-wise leakage report. The date range affects the attendance calculation, meaning the system counts only the boarding days that fall within the selected dates.

Academic Session filter lets Mrs. Desai switch between different academic sessions. This is useful during the transition period between sessions when she needs to compare the current session's leakage with the previous session. The default value is always the current ongoing academic session.

Class filter allows her to narrow the report to specific classes or grades. She uses this when the principal asks about leakage patterns in specific sections of the school. For example, if the primary section has higher transport fee default rates, Mrs. Desai can filter by primary classes and investigate further. The filter shows all available class levels from Nursery to Class Twelve.

Route filter lets her focus on specific transport routes. The Accounts Manager uses this filter when following up on defaulters. If a particular route serves an area where several parents have not paid, the school can send a targeted reminder to all parents on that route. The filter displays all active route names.

All filters can be combined. When Mrs. Desai selects a specific class and a specific route, the report recomputes every metric to show only students matching both criteria.

## When This Report Is Used

Mrs. Desai and the Accounts Manager review this report together on the first working day of every month. This monthly review is a scheduled meeting where they go through the leakage numbers, identify new defaulters, and plan follow-up actions. The Accounts Manager takes the list of leakage cases and initiates phone calls or written reminders to the parents.

At the end of each academic term, the report is used to generate the term-wise transport financial summary. This summary is submitted to the School Management Committee as part of the overall financial review. The committee reviews the total fee assigned, total collected, and the leakage percentage to evaluate the effectiveness of the transport fee collection process.

Before the start of a new academic session, Mrs. Desai uses this report to identify students who had outstanding transport dues from the previous session. The school policy requires that all previous session dues be cleared before a student can be allocated a transport seat for the new session. The report provides the exact balance amount for each defaulter, which is communicated to parents during the re-enrolment process.

When a parent raises a dispute about their transport fee, the Accounts Manager uses this report to show the parent their child's attendance days and the corresponding fee calculation. The detailed per-student view resolves most disputes because parents can see exactly how many days their child travelled and how the fee was calculated based on those days.

The report is also used during internal audits. The school's internal auditor accesses this report to verify that transport fee collections match the student transport usage records. Any discrepancy between the boarding logs and the payment records is flagged and investigated. This audit happens once every six months.

## Key Metrics / KPIs

Fee Assigned represents the total transport fee amount that should have been collected from all students who were allocated transport seats during the selected period. This amount is calculated based on the transport fee structure defined for each student's class and route combination at the start of the academic session. If a student's transport fee for the full session is twelve thousand rupees, and the selected period covers half the session, the Fee Assigned for that student would be prorated to six thousand rupees. Mrs. Desai looks at this number to understand the total revenue potential of the transport department.

Fee Collected is the total amount that has actually been received from students and parents against their transport fee. This number comes from the payment records and includes all payments made through any channel, whether online bank transfer, cheque, cash at the school counter, or payment gateway. Mrs. Desai compares Fee Collected with Fee Assigned to see the collection gap. If Fee Collected is close to Fee Assigned, the transport department is performing well financially.

Total Balance is the difference between Fee Assigned and Fee Collected. This is the amount that is still outstanding and needs to be collected. Mrs. Desai and the Accounts Manager focus on this number because it represents real money that the school is owed for services already delivered. A growing Total Balance trend over multiple months is a warning sign that the collection process needs improvement.

Leakage Cases Count is the number of students who have been identified as having a gap between their transport usage and their payment. The report categorises leakage into two types. The first type is No Payment, which means the student has travelled on school transport but has not paid any transport fee at all during the selected period. The second type is Partial Payment, which means the student has paid something but the amount paid is less than the fee assigned for their usage period. A student is considered a leakage case only if they have active boarding records showing they actually used the transport service. Students who are allocated but never travelled are not leakage cases because they did not consume the service.

The report also shows a Leakage Value amount, which is the sum of the Total Balance for all students flagged as leakage cases. Mrs. Desai uses this to quantify the financial impact of leakage. If the Leakage Value is high, she escalates the matter to the principal for school-wide intervention.

## Charts and Visualizations

The Transport Finance and Leakage Report includes two specialised charts that visually represent the financial data.

The first chart is a Doughnut chart that displays the distribution of students across three payment categories: Paid in Full, Partial Payment, and No Payment. The Paid in Full segment shows the proportion of students who have fully paid their transport fee for the selected period. The Partial Payment segment shows students who have made some payment but still have a balance. The No Payment segment shows students who have used transport but have not paid anything. The doughnut chart gives Mrs. Desai an immediate visual sense of the payment health of the transport department. If the No Payment segment is visibly large, she knows there is a systemic collection problem. If the Partial Payment segment dominates, the issue is more about follow-up on partial defaulters.

The second chart is a Horizontal Bar chart that shows leakage type distribution. Each horizontal bar represents a category of leakage, and the length of the bar shows the number of cases in that category. The categories include No Payment by Class, Partial Payment by Class, No Payment by Route, and Partial Payment by Route. This chart helps Mrs. Desai identify patterns in leakage. If she sees that No Payment cases are concentrated in a specific class, she can investigate whether the transport fee for that class was communicated clearly to parents. If leakage is concentrated on a specific route, it may indicate that the route serves an area where parents have financial difficulties or where communication from the driver or attendant is lacking.

Both charts are interactive. Clicking on any segment of the doughnut chart filters the detailed table below to show only students in that payment category. Clicking on any horizontal bar in the leakage distribution chart filters the table to show students matching that specific leakage type and class or route combination.

## Data Sources

The Transport Finance and Leakage Report draws data from four tables, combining student transport usage records with payment information.

The std_student_academic_sessions table holds records of each student's enrolment in each academic session. A student may appear in this table multiple times across different sessions. The table links to other student-related data including class, section, and roll number. The report uses this table to identify which students are active in the current session and to display their class and section information alongside their transport data.

The tpt_student_route_allocation_jnt table is referenced in the system as transportAllocation. This table stores the record of which route and which specific stop each student is allocated to for transport. A student's allocation includes their pickup point and drop-off point, the route they travel on, and the effective date of the allocation. The report uses this table to determine which students are registered for transport and to calculate the Fee Assigned amount based on their route and class.

The tpt_student_boarding_log table is referenced in the system as boardingLogs. This table records every instance of a student boarding or alighting from a school vehicle. Each record includes the student identifier, the trip identifier, the date, the stop, and the timestamp. The report uses this table to count how many days each student actually used the transport service. A student is considered to have used transport on a given day if they have at least one boarding record for that day within the selected period.

The std_student_pay_log table is referenced in the system as StudentPayLog. This table stores all payment transactions made by or for students. Each record includes the student identifier, the payment date, the payment amount, the fee category such as tuition or transport, and the payment mode. The report filters this table to include only payments where the fee category is Transport, and then sums the amounts to calculate the Fee Collected for each student.

## Permissions

The Transport Finance and Leakage Report is protected by the permission key tenant.transport-finance.viewAny. This permission is distinct from other transport permissions because this report deals with financial data, which is sensitive and requires higher level of access control.

The system checks this permission whenever a user attempts to access the report. Users without this permission see an access denied message. The permission is tenant-scoped, ensuring that financial data from Green Valley School is not visible to users from other schools in a multi-tenant setup.

In addition to the base permission, the system enforces a data sensitivity rule. Users with this permission can view all metrics except individual student names unless they also have a separate financial data access permission. This means that a user can see the aggregate Fee Assigned, Fee Collected, Total Balance, and leakage counts and charts, but cannot see the per-student breakdown table that shows individual student names and their personal payment details. Only users with the additional financial detail permission can expand the per-student table. This layered access ensures that sensitive financial information about individual families is protected.

## Who Can Access

At Green Valley School, access to the Transport Finance and Leakage Report is carefully controlled due to the financial nature of the data.

Mrs. Desai as the Transport Supervisor has full access including the per-student detail view. She needs this access because she is responsible for following up with parents about transport fee defaults and needs to know exactly which student has how much balance. She also uses the per-student data during parent meetings to address disputes.

The Accounts Manager has full access to this report, including the per-student detail. The Accounts Manager is the primary user of the financial data and uses the report to generate collection reports, track payment trends, and initiate recovery actions. The Accounts Manager also provides the data to the external auditor during the annual audit.

The School Principal has access to the summary view of this report. The principal can see the aggregate metrics and the charts but cannot see individual student names unless they specifically request this information from the Accounts Manager. The principal uses the summary view during management committee meetings to report on the financial performance of the transport department.

The Class Teachers and Administrative Staff do not have access to this report. Transport financial data is considered sensitive and is restricted to the transport management and accounts departments only.

## Example Scenario

It is the first week of October, and the first term has just ended at Green Valley School. Mrs. Desai and the Accounts Manager, Mr. Mehta, sit down for their monthly review meeting. Mrs. Desai opens the Transport Finance and Leakage Report. The default view shows data from April to September, covering the full first term.

The doughnut chart immediately catches their attention. The No Payment segment shows twenty-three percent of transport students, meaning nearly one in four students who used transport in the first term have not paid anything at all. The Partial Payment segment shows fifteen percent. Together, thirty-eight percent of transport students have some form of payment leakage.

The Fee Assigned metric shows a total of forty-two lakh rupees for the first term. The Fee Collected shows only thirty-one lakh rupees. The Total Balance is eleven lakh rupees. This is a significant gap. Mrs. Desai is concerned because the transport department's fuel and salary budget for the first term was thirty-five lakh rupees, meaning the school has actually paid more to run the transport than it has collected.

The Leakage Cases Count shows one hundred and forty-seven students. Mr. Mehta notes that this number has increased by twenty-two students compared to the previous month. The new leakage cases are mostly from the primary section, specifically Classes Two and Three.

Mrs. Desai applies the Class filter and selects Class Two. The report recalculates. The horizontal bar chart now shows that in Class Two, most leakage cases are of the No Payment type. She drills down by clicking on the No Payment bar, and the per-student table below shows the list of Class Two students who have not paid any transport fee despite having boarding records.

She notices that four of the students on the list are from the same family. This is a sibling group where all four children use school transport but none of them have paid. The total balance for this family alone is forty-eight thousand rupees. Mrs. Desai flags this as a high-priority case.

Mr. Mehta exports the per-student leakage list for Class Two. He prepares a list of parent names and contact numbers. His plan is to call each parent over the next three days, starting with the sibling group. For parents who do not respond to calls, the school will send a formal reminder letter. If payment is not received within fifteen days of the letter, the case will be escalated to the principal for further action.

Before ending the meeting, Mrs. Desai applies the Route filter to check if any specific route has a disproportionate leakage problem. She finds that Route 4C - Vasant Kunj has a forty-five percent leakage rate, meaning nearly half the students on that route have not paid. She decides to schedule a meeting with the driver and attendant of Route 4C to check whether they have been correctly recording boardings and whether parents on that route have received proper fee communication.

Mrs. Desai and Mr. Mehta agree to meet again in two weeks to review the progress on the follow-up actions. Mr. Mehta will update the payment records as parents make payments, and the report will automatically reflect the improved collection numbers.

## Logic Flow

The Transport Finance and Leakage Report processes data through a series of logical steps that combine transport usage with financial records.

The first step is student identification. The system queries the std_student_academic_sessions table to find all students enrolled in the selected academic session. This provides the initial pool of students who could potentially be transport users.

The second step is transport allocation identification. The system queries the tpt_student_route_allocation_jnt table to find which of these enrolled students have a transport allocation record. A student with a transport allocation is considered a transport-registered student. Only these students are included in the report. Students without a transport allocation are excluded even if they have incidental boarding records.

The third step is filter application. The system applies the selected academic session filter, class filter, and route filter to narrow down the student list. The date range filter is also applied at this stage to set the time boundary for boarding and payment calculations.

The fourth step is usage calculation. For each student in the filtered list, the system queries the tpt_student_boarding_log table to count the number of unique days within the selected date range where the student has at least one boarding record. This count becomes the attendance days figure for that student. A student with zero attendance days is flagged as allocated but not using transport, and such students are not considered leakage cases because they have not consumed the transport service.

The fifth step is fee assignment calculation. The system determines the transport fee amount applicable to each student based on their class and route combination. The fee structure is defined in the system with a daily rate, monthly rate, or term rate. The system multiplies this rate by the number of days in the selected period to arrive at the Fee Assigned for that student. If a student was allocated transport midway through the period, the Fee Assigned is calculated from their allocation start date rather than from the beginning of the period.

The sixth step is payment calculation. The system queries the std_student_pay_log table to find all payment records where the student identifier matches and the fee category is Transport. The system sums the payment amounts within the selected date range. This sum becomes the Fee Collected for that student.

The seventh step is balance calculation. The system subtracts Fee Collected from Fee Assigned for each student. If the result is zero or negative, the student has no balance due. If the result is positive, that amount is the student's Total Balance.

The eighth step is leakage classification. The system applies the leakage logic. If a student has zero attendance days, they are excluded from leakage classification. If a student has one or more attendance days and their Fee Collected is zero, they are classified as No Payment leakage. If a student has one or more attendance days and their Fee Collected is greater than zero but less than Fee Assigned, they are classified as Partial Payment leakage. If a student has paid in full, they are classified as No Leakage. The Leakage Type is recorded as No Payment, Partial Payment, or No Leakage accordingly.

The ninth step is aggregate calculation. The system sums the Fee Assigned across all students to get the total Fee Assigned metric. It sums the Fee Collected to get total Fee Collected. It subtracts total Fee Collected from total Fee Assigned to get Total Balance. It counts the number of students classified as No Payment or Partial Payment to get Leakage Cases Count.

The tenth step is chart generation. The system creates the doughnut chart by grouping students into the three payment categories and calculating the percentage of students in each category. The system creates the horizontal bar chart by further breaking down the leakage categories by class and by route, with separate bars for No Payment and Partial Payment counts within each group.

The eleventh step is data display. The system renders a summary bar at the top showing the aggregate KPIs. Below this, it displays the two charts side by side. Below the charts, it renders a detailed per-student table. Each row in this table shows the student name, class, section, route, attendance days, fee assigned, fee collected, balance, attendance percentage, collection percentage, leakage flag, and leakage type. The table is paginated to handle large numbers of students, sortable by any column, and exportable to PDF or spreadsheet format. The leakage flag is visually indicated through colour coding, with red for No Payment, yellow for Partial Payment, and green for No Leakage.

The report logic also computes derived percentages that help Mrs. Desai and Mr. Mehta understand the severity of leakage. Attendance Percentage is calculated by dividing the student's attendance days by the total school working days in the selected period. This tells them whether the student is a regular transport user or only an occasional one. Collection Percentage is calculated by dividing Fee Collected by Fee Assigned and multiplying by one hundred. A student with a high attendance percentage and a low collection percentage is a high-priority leakage case because they are using the service regularly but not paying.

The system includes a prioritisation ranking within the report logic. After calculating all metrics for each student, the system assigns a priority level to each leakage case. Priority One cases are students who have attended more than seventy-five percent of school days, have zero payment, and have a balance above ten thousand rupees. Priority Two cases are students who have attended more than fifty percent of days and have either zero or partial payment. Priority Three cases are all remaining leakage cases. This prioritisation helps Mrs. Desai and Mr. Mehta focus their follow-up efforts on the cases that represent the highest financial impact.

The report also manages data consistency checks. Before displaying any numbers, the system verifies that the total number of boarding days for each student does not exceed the total number of school working days in the selected period. If a data entry error causes a student to have more boarding records than possible school days, the system caps the attendance days at the maximum possible and flags the student record for manual review. Similarly, the system checks that Fee Collected does not exceed Fee Assigned. If a student has overpaid, perhaps due to a duplicate payment, the system shows the overpayment separately rather than displaying a negative balance.

The logic flow includes a timezone-aware date handling step. Because transport operations at Green Valley School happen early in the morning before sunrise and continue into the evening after sunset, the system needs to correctly attribute boarding records to the right school day. The system uses the school's configured academic day start time, which is four AM, as the boundary. Any boarding record timestamped after four AM on a given day belongs to that day's operations. This prevents midnight confusion where a late evening trip might be incorrectly attributed to the next calendar day.

A final validation step runs before the report data is displayed to Mrs. Desai. The system compares the total number of unique students in the transport allocation table with the total number of unique students appearing in the boarding log. If these numbers differ by more than ten percent, it may indicate that boarding records are not being properly captured for all transport users. The report displays a warning banner in this case, alerting Mrs. Desai to a potential data capture issue that needs investigation before the financial numbers can be relied upon.

The report's logic flow also includes a reconciliation summary section. After all per-student calculations are complete, the system generates a three-way reconciliation that compares the total Fee Assigned from transport allocations, the total Fee Collected from payment logs, and the total expected collection based on attendance days multiplied by the daily transport rate. If these three numbers do not align within an acceptable tolerance, the report highlights the discrepancy. This reconciliation helps Mrs. Desai and Mr. Mehta identify systemic issues such as incorrect fee structure configuration, missing payment records, or errors in the boarding log data before they rely on the report for decision-making.

Payment allocation logic within the report handles cases where a single payment covers multiple periods. If a parent pays the full year's transport fee in a single transaction in April, the system allocates that payment proportionally across all months in the selected period. This means that if Mrs. Desai views the report for a specific month, she will see a portion of that annual payment credited to that month. The allocation is based on the number of school days in each month, ensuring that months with more school days receive a higher allocation of the prepaid amount.

The report also manages refund and adjustment scenarios in its logic. If a student discontinues transport mid-session and receives a fee refund, the system deducts the refunded amount from Fee Collected and also adjusts the Fee Assigned downward to reflect the reduced period of service. If an adjustment is made to a student's fee due to a sibling discount or a late enrolment concession, the system applies this adjustment to the Fee Assigned before calculating the balance. These adjustments ensure that the leakage flags are based on accurate fee expectations rather than outdated fee structures.

A data freeze mechanism is part of the report logic for end-of-period reporting. When Mrs. Desai generates the report for a closed term, the system freezes the data at the end of the term and prevents any subsequent changes to boarding logs or payment records from altering the already-generated report numbers. This ensures that the term-end report is an immutable record that can be referenced during audits and management reviews. If corrections are needed, they are applied to the current period rather than retroactively changing historical reports.
