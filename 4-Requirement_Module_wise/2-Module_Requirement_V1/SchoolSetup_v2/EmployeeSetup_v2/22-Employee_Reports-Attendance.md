# Attendance Report — Requirement Document

## Screen Purpose & Overview

This screen is part of the Employee Reports sub-menu. The main purpose of this screen is to generate detailed daily and monthly attendance reports for school administrators and HR personnel.

This report provides a comprehensive analysis of staff and teacher attendance, including counts for present days, absent days, half-days, late arrivals, and holidays. This page serves as the core attendance verification sheet for payroll calculations and can be exported in Excel and PDF formats.

---

## Common Use Cases

1. **Monthly Register Generation:** Printing the daily attendance register sheet (P/A grid) for all school teachers at the end of the month.
2. **Late Coming Analysis:** Analyzing patterns of staff members who are consistently late (Late Count Report) to address punctuality issues.
3. **Payroll Processing Input:** Sharing the net payable days (working days) report with the accounts department to calculate monthly salaries.
4. **Attendance Summary:** Providing management with average attendance percentages across departments (e.g., "The Academic department has achieved a 95% attendance rate this month").

---

## Screen Fields & Input Rules

### Section A: Report Filters (Search Controls)
| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| Month & Year | The target month and year for the report | Required. Select from the month/year list (e.g., May-2026). Future dates are disabled. |
| Department | Filter by department | Optional. Dropdown options (e.g., Academic, Admin). |
| Staff Role | Filter by system permission role | Optional. Dropdown options (e.g., Teacher, Support Staff). |
| Employee Code / Name | Search for a specific employee | Optional. Text input. |

### Section B: Report Output Columns (Table Columns)
| Column Name (Screen Label) | Display Description | Meaning (Simple terms) |
|---|---|---|
| Employee Code | Unique identifier for the employee | Unique ID. |
| Employee Name | Name of the staff member | Employee name. |
| Total Calendar Days | Total number of days in the selected month | Calendar days in the month (e.g., 31 days). |
| Total Working Days | Scheduled working days according to the shift | Calendar days minus weekends/holidays. |
| Days Present | Total days worked | Count of days with a status of 'Present' or 'Late'. |
| Days Absent | Total days missed without approval | Count of days with a status of 'Absent'. |
| Leaves Taken (Paid) | Approved paid leave days | Count of days with an approved 'Paid Leave' status. |
| LWP (Unpaid Leaves) | Leave without pay days | Count of days with a 'Leave Without Pay' status. |
| Late Days | Total days arrived late | Count of days where a late check-in was recorded. |
| Net Payable Days | Total days for which salary is payable | Formula: `Days Present + Paid Leaves + Paid Holidays`. |

---

## Business Rules & Validation Policies

1. **Net Payable Days Calculation:**
   - The system calculates the net payable days for payroll processing as follows:
     $$\text{Net Payable Days} = \text{Days Present} + \text{Paid Leaves} + (\text{Weekends} + \text{Holidays} \text{ if eligible under policy})$$
   - *In Simple Terms:* Employees receive salary for days marked as Present, approved Paid Leaves, and designated Paid Holidays. Days marked as Absent or Leave Without Pay (LWP) are excluded from the payable days.

2. **Late Penalty Rule Alert:**
   - If an employee accumulates more than 3 late days in a month, the report status column automatically displays a "Late Warning Flag" to assist HR in applying punctuality fines or policies.

---

## Screen Workflows & Operations

### 1. Generating the Attendance Report
- The Admin selects the desired `Month & Year` (e.g., May-2026).
- The Admin applies filters like Department and Designation if needed.
- Click "Generate Report". The tabular data load in the grid after the loading spinner completes.

### 2. Exporting the Report (Excel / PDF)
- HR clicks "Export to Excel" or "Download PDF" to save the report to their computer.
- The system generates and downloads a cleanly formatted summary file to the local directory.

---

## Real-World Example Scenario

**Accounts Head Manish** is reviewing the attendance sheet to process salaries for May-2026:

1. Manish opens the `Attendance Report` page.
2. He selects: Month = `May-2026` and Department = `Academic`.
3. He clicks "Generate Report". The system populates the table:
   - **Sunita Sharma:** Present Days = `20`, Paid Leaves = `2`, Absent = `0`, LWP = `0`. Net Payable Days = `31` (includes paid weekends/holidays).
   - **Vikram Rathore:** Present Days = `18`, Paid Leaves = `0`, Absent = `2`, LWP = `2`. Net Payable Days = `27` (4 days for Absent and LWP are deducted).
4. Manish clicks "Export to Excel" to download the spreadsheet and imports the data directly into the payroll processing software.
