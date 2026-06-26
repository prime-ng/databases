# Staffing Report — Requirement Document

## Screen Purpose & Overview

This screen is part of the Employee Reports sub-menu. The main purpose of this screen is to provide a clear representation of school staffing levels, total headcounts, and department-wise vacancy statuses.

Through this report, school management and HR can monitor the number of staff members assigned to each department (such as the Science Department, Admin, or Accounts), check their employment status (Permanent/Contract), and identify vacant positions that require recruitment.

---

## Common Use Cases

1. **Annual Budget Planning:** Verifying the total school manpower count before the start of a new academic year.
2. **Hiring Decisions:** Checking for teacher shortages (vacancies) in departments like English or Math that could disrupt scheduling and the school timetable.
3. **Diversity & Role Distribution:** Monitoring the ratio of permanent, temporary, probationary, and guest staff to manage operational risks.
4. **Department Sizing Report:** Presenting total headcount growth trends and department-wise ratios in management meetings.

---

## Screen Fields & Input Rules

### Section A: Report Filters (Search Controls)
| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| Filter by Department | The department to filter the staffing list | Optional. Dropdown options (e.g., Academic, IT Department). |
| Employment Type | The employment category | Optional. Dropdown options (e.g., Permanent, Temporary, Contract). |
| Status | The operational status of the staff | Required. Options: Active Staff / Inactive Staff (Resigned/Retired). |

### Section B: Report Output Columns (Table Columns)
| Column Name (Screen Label) | Display Description | Meaning (Simple terms) |
|---|---|---|
| Department Name | Name of the department | E.g., Academic. |
| Job Designation | Job role or title | E.g., Senior Teacher, Lab Assistant. |
| Sanctioned Positions | Approved positions authorized by the school board | Total approved seats (e.g., 5). |
| Active Count | Staff members currently working in that role | Number of active employees currently assigned. |
| In Probation | Staff members undergoing probation | Count of employees in probationary status. |
| Vacant Positions | Number of unfilled positions | Formula: `Sanctioned Positions - Active Count`. |
| Attrition Rate (%) | Percentage of staff who left this month | Department-level resignation rate. |

---

## Business Rules & Validation Policies

1. **Manpower Capacity Formula:**
   - The system calculates vacant positions using the following equation:
     $$\text{Vacant Positions} = \text{Sanctioned Positions} - \text{Active Count}$$
   - If the active headcount exceeds the sanctioned positions, the report displays a warning flag (Red Alert) indicating an "Over-Staffed" status.

2. **Compliance & Inactive Sync:**
   - Soft-deleted (archived) employees are excluded from the "Active Count". Their data is displayed separately within the inactive/retired headcount section.

---

## Screen Workflows & Operations

### 1. Viewing the Staffing Summary Report
- The Admin selects the desired filters.
- Click "Generate". The screen displays a consolidated summary card and a detailed table.
- A graphical visualization (Pie Chart or Bar Graph) is displayed to show the distribution of total headcount by department.

### 2. Exporting the Report
- HR downloads the report as an Excel file to share the staffing headcount document with the management audit committee.

---

## Real-World Example Scenario

**School HR Director Rajesh Kumar** is generating a staffing report for an upcoming school management board meeting:

1. Rajesh opens the `Staffing Report` page.
2. He sets the filter: Status = `Active Staff`.
3. He clicks "Generate Report" to display the statistics:
   - **Academic Department (Senior Teacher - Science):** Sanctioned = `4`, Active = `3`, Vacant = `1` (Hiring needed).
   - **Admin Department (Accountant):** Sanctioned = `2`, Active = `2`, Vacant = `0` (Balanced).
   - **Support Staff (Bus Driver):** Sanctioned = `5`, Active = `6`, Vacant = `-1` (Warning: Over-staffed by 1 member).
4. Rajesh downloads the staffing deficit chart and adds a proposal to fill the science teacher vacancy to the meeting agenda.
