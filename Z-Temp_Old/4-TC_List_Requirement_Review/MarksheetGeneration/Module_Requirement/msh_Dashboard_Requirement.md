# Marksheet Generation Dashboard — Business Requirements

## What This Screen Does

The Marksheet Generation Dashboard is the main overview screen for marksheet operations. It provides academic administrators and coordinators with a bird's-eye view of marksheet configuration, schedules, and computed results across the school. 

The dashboard displays KPI metric tiles at the top, showing counts of active configurations (types, templates, schedules) and calculations (computed results, subject results, IA scores, co-scholastic grades). Below these metrics, it offers tabbed lists showing recent schedules and recently computed student results. This dashboard is the first screen users see when they open the module, serving as a progress tracker for report card generation.

---

## Default Data Load

When the user opens the dashboard, the system calculates and displays the following statistics:
*   Total and active marksheet types.
*   Total and active configuration templates.
*   Total and active marksheet schedules.
*   Total computed student results.
*   Total class assignments in schedules.
*   Total subject practical configurations.
*   Total subject-level results, internal assessment (IA) component marks, and co-scholastic grades computed.

It also loads:
*   The 5 most recently created marksheet schedules.
*   The 5 most recently computed student results, including student names and class sections.

---

## When This Screen Is Used

*   **Progress Monitoring** — During exam seasons, the coordinator checks the dashboard daily to monitor the status of marksheet generation and see how many student results have been computed.
*   **Onboarding and Configuration Audits** — At the start of a term, administrators use the counts to verify that all necessary templates and schedules are active before calculations begin.
*   **Verification of Completeness** — Before publishing results, the coordinator verifies the total computed result count against the school's total student enrollment.

---

## Key Fields at a Glance

**KPI Stats Overview**
A grid of statistic tiles showing counts of:
*   **Marksheet Formats** — Formats configured (e.g., Term, Annual).
*   **Blueprints** — Configuration templates ready.
*   **Active Schedules** — Schedules currently running or planned.
*   **Calculations** — Total student results, subject results, internal assessment marks, and co-scholastic results computed.

**Schedules and Results Tabs**
*   **Recent Schedules** — Lists the latest schedules with their status (Draft, Reviewed, Published, Locked).
*   **Recent Results** — Lists the latest computed student results with their overall percentage and grade.

---

## Business Rules and Conditions

**Live Computation (BR-MSG-009)**
All metrics on the dashboard are calculated in real-time from the database on every page load, ensuring that administrators always see the latest progress.

**Access Gating (BR-MSG-010)**
Only users with permission to view the dashboard can access it. Access to specific configuration details is governed by the user's role permissions.

---

## Workflow Steps

**Checking Dashboard Progress**
It is the end of the term. The Examination Coordinator, Mr. Sharma, opens the Marksheet Generation module. The dashboard loads. He views the metric tiles at the top:
*   Active Templates: 3
*   Active Schedules: 2
*   Computed Student Results: 450

He notices that the computed results count is lower than the expected 480 students. He clicks the **Recent Schedules** tab, finds the active schedule, and clicks it to go to the scheduling details page. He discovers that one class section's results are still in "Draft" because their internal marks are missing. He follows up with the teacher to enter the marks, computes the results, and returns to the dashboard to verify the computed count has updated to 480.

---

## Example Scenario

Greenwood International School has 500 students. The Examination Coordinator, Mrs. Desai, opens the dashboard during report card processing. The dashboard displays:
*   Active templates: 2
*   Computed results: 495

She clicks the **Recent Results** tab and sees the list of the last 5 computed students. She notices 5 results are missing. She navigates to the Results hub to identify the missing student profiles and resolve their status.

---

## Related Screens

*   **Configuration Hub** — Where templates and marksheet formats are set up.
*   **Scheduling Hub** — Where schedules are managed and computed.
*   **Results Hub** — Where all computed grades, marks, and rankings are reviewed.
