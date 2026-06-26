# Leave Usage Report — Requirement Document

## Screen Purpose & Overview

This screen is part of the Employee Reports sub-menu. The main purpose of this screen is to analyze leave utilization trends and absenteeism patterns among school staff and teachers.

Through this report, school management can identify which leave types are most frequently utilized (e.g., if there is a higher volume of Casual Leave requests on Fridays and Mondays), which departments have the highest leave volumes, and identify absenteeism patterns that impact school operations and class scheduling.

---

## Common Use Cases

1. **Absenteeism Pattern Detection:** Verifying an employee's leave pattern (e.g., checking if they frequently take Casual Leave adjacent to weekends).
2. **Leave Type Ratio Analysis:** Analyzing the distribution ratio between different leave types, such as Casual Leave vs. Sick Leave.
3. **Department Leave Load Analysis:** Monitoring which month has the highest leave utilization in the Academic department (e.g., assessing leave levels during exam preparation or board exam periods).
4. **Proxy/Substitute Cost Audit:** Tracking the frequency and costs of assigning substitute teachers when regular teachers are on leave.

---

## Screen Fields & Input Rules

### Section A: Report Filters (Search Controls)
| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| Selection Period | The timeframe for the report analysis | Required. Dropdown options: This Month / Last 3 Months / Annual Session. |
| Department | Filter by department | Optional. Dropdown selection. |
| Leave Category | The specific leave type to analyze | Optional. Options: All / CL / SL / EL / LWP. |
| Trigger Threshold (Days) | Minimum consecutive leave days to filter | Optional. Numeric input (e.g., show employees who took more than 5 consecutive leaves). |

### Section B: Report Analysis Columns (Table Columns)
| Column Name (Screen Label) | Display Description | Meaning (Simple terms) |
|---|---|---|
| Employee Name | Name of the staff member | Employee name. |
| Department | Department of the employee | Department. |
| Total Leaves Applied | Number of leave requests submitted | Count of total applications. |
| Approved Leaves (Days) | Total approved leave days | Sum of approved leave days. |
| LWP Days Count | Total Leave Without Pay days | Sum of unpaid leave days. |
| Consecutive Leave Hits | Stretches of consecutive leave days | Frequency of consecutive leave stretches. |
| Weekend Interlocks | Occurrences of leaves linked to weekends | Friday/Monday overlap pattern count. |
| Substitute Assigned Count | Times a substitute was required | Number of substitute teacher requests generated. |

---

## Business Rules & Validation Policies

1. **Weekend Interlock Check:**
   - The system automatically flags leave requests where the start date falls on a Monday or the end date falls on a Friday. This highlights trends in weekend clubbing (creating extended weekends).

2. **Absenteeism Threshold Alert:**
   - If an employee takes late arrivals or short-leaves more than 3 times in a single month without a verified medical reason or emergency certificate, the system automatically flags their profile with a **"High Absenteeism Risk"** status tag.

---

## Screen Workflows & Operations

### 1. Running the Leave Pattern Analysis
- The user selects the Date Period (e.g., `Last 3 Months`).
- The user enters a threshold value (e.g., `5 Days`).
- Click "Generate Analysis". The system loads the department-wise charts and individual employee tabular records.
- A graphical visualization (Bar Chart) loads to display trends, such as the average Sick Leave usage during peak weather conditions.

### 2. Exporting Trend Sheets
- Using the export functionality, HR can download the trend analysis sheet with detailed notes as an Excel file.

---

## Real-World Example Scenario

**The Vice Principal** is reviewing the `Leave Usage Report` to understand the high rate of class substitutions:

1. The Vice Principal opens the `Leave Usage Report` page.
2. They select the filters: Period = `Last 3 Months` and Department = `Academic`.
3. The system generates the report:
   - **Shalini Sen:** Total Leaves Approved = `12 Days`, Consecutive Stretches = `2` (Maternity-related medical follow-ups), Substitutes Required = `4 times`.
   - **Teacher B:** Total Leaves Approved = `15 Days`, Weekend Interlocks = `5` (Casual Leave applied on consecutive Fridays and Mondays).
4. Based on the high number of weekend interlocks, school management decides to update the leave policy, requiring Principal approval for any Casual Leave requests that block or extend weekends.
