# Leave Balance Report — Requirement Document

## Screen Purpose & Overview

This screen is part of the Employee Reports sub-menu. The main purpose of this screen is to generate and analyze leave balance reports (summaries of remaining leaves) for all school employees and teachers.

Through this report, HR and school management can track how many leaves were allocated to each employee at the start of the year (opening balance), how many have been consumed (total used), how many are currently pending approval (total pending), and the remaining days left in each leave category (CL, SL, EL, LWP).

---

## Common Use Cases

1. **Year-End Rollover Check:** Verifying carry-forward counts or encashment calculations when the annual session ends.
2. **Leave Balance Audit:** Resolving leave balance disputes (e.g., if an employee claims to have 5 CL remaining but the portal shows only 3) by checking the opening balance, consumption logs, and adjustments history.
3. **Mid-Session Adjustment Review:** Tracking manual positive or negative leave balance adjustments made by HR, along with their associated reasons.
4. **General HR Verification:** Allowing HR to verify an employee's actual available balance before approving requests for extended leaves.

---

## Screen Fields & Input Rules

### Section A: Report Filters (Search Controls)
| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| Academic Session | The academic or calendar year session | Required. Dropdown list (e.g., Session 2026-27). |
| Department | Filter by department | Optional. Dropdown. |
| Leave Type | Filter by a specific type of leave | Optional. Options: All / Casual Leave / Sick Leave / Earned Leave. |
| Employee Search | Search by employee name or code | Optional. Text input. |

### Section B: Report Output Columns (Table Columns)
| Column Name (Screen Label) | Display Description | Meaning (Simple terms) |
|---|---|---|
| Employee Code | Unique identifier for the employee | Staff unique ID. |
| Employee Name | Name of the staff member | Employee name. |
| Designation | Employee's job title | Job role (e.g., PGT Biology). |
| Leave Category | Code representing the leave type | E.g., CL, SL, EL. |
| Opening Balance | Leaves allocated at the start of the session | Base annual entitlement allocation. |
| Carry Forward | Leaves carried over from the previous year | Rollover count from the prior session. |
| Manual Adjustment | Balance adjustments made manually by HR | Mid-term adjustments (e.g., +2.0 or -1.5). |
| Total Used | Leaves consumed to date | Count of Approved leaves. |
| Total Pending | Leaves currently awaiting approval | Count of Submitted/Under Review leaves. |
| Available Balance | Net remaining leaves | Formula: `(Opening + Carry Forward + Adjustment) - Used - Pending`. |

---

## Business Rules & Validation Policies

1. **Balance Formula Validation:**
   - The system calculates the available balance using the following equation:
     $$\text{Available Balance} = (\text{Opening} + \text{Carry Forward} + \text{Adjustment}) - \text{Total Used} - \text{Total Pending}$$
   - The available balance cannot be negative, except for LWP (Leave Without Pay) which is configured as an unlimited, zero-balanced leave type.

2. **Audit Reason Lock:**
   - If a row contains a value under "Manual Adjustment", the system provides a read-only details pop-up showing the name of the admin who performed the adjustment, the adjustment date, and the "Adjustment Reason".

---

## Screen Workflows & Operations

### 1. Generating the Leave Balance Sheet
- The HR user selects the Academic Session (e.g., 2026-27).
- They select the Leave Type (e.g., `Casual Leave (CL)`) to view CL status for all staff.
- Click "Search". The grid loads the CL balances for all active staff members.

### 2. Exporting and Sharing
- HR clicks "Export to Excel" to download the report as a spreadsheet to email the remaining balance lists to the respective department HODs.

---

## Real-World Example Scenario

**HR Coordinator Pooja Gupta** is checking the remaining Sick Leave balances for teachers in the Primary block:

1. Pooja opens the `Leave Balance Report` page.
2. She selects: Session = `2026-27`, Department = `Academic`, and Leave Type = `Sick Leave`.
3. She clicks "Generate" and views the report:
   - **Sunita Sharma:** Opening = `10`, Carry Forward = `0`, Manual Adjustment = `+2` (special medical allowance), Used = `3`, Pending = `1`. Available Balance = `8 Days`.
   - **Vikram Rathore:** Opening = `10`, Carry Forward = `0`, Manual Adjustment = `0`, Used = `8`, Pending = `0`. Available Balance = `2 Days`.
4. Pooja reviews the list and sends an internal email to teachers with low sick leave balances to advise them to monitor their leaves.
