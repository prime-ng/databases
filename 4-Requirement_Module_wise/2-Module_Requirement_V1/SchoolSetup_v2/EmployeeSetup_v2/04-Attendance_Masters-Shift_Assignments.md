# Shift Assignments — Requirement Document

## Screen Purpose & Overview

This screen is used to map and assign work shifts to employees and teachers. It is part of the Attendance Masters sub-menu.

When a new employee joins the school or their working hours change, the Admin uses this screen to assign them a shift template. It manages shift duration limits, handles the transitions between old and new shifts, and tracks the historical shift assignment records for every employee.

---

## Common Use Cases

1. **Assigning Shifts to New Joiners:** Assigning a default shift template (e.g., standard timing) to newly onboarded staff.
2. **Scheduling Shift Changes / Transfers:** Reassigning shifts when an employee's schedule changes (e.g., moving an employee from a night rotation to a standard morning shift).
3. **Bulk Shift Assignments:** Assigning a shift template to an entire group of employees (e.g., all primary teachers) simultaneously.
4. **Temporary / Future Shift Scheduling:** Setting up a temporary shift (e.g., for exam invigilation duties) starting from a future date, which automatically activates and expires on predefined dates.
5. **Reviewing Shift Assignment History:** Auditing past, current, and future scheduled shifts for any staff member.

---

## Screen Fields & Input Rules

| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| Employee | Name or Employee ID of the staff member | Required. The selected employee must be active in the system. |
| Current Shift | Currently assigned active shift (Read-only) | Automatically displayed by the system if a shift is already assigned. |
| Assign New Shift | Dropdown list of available shift templates | Required. Only active shift templates are shown in the dropdown list. |
| Effective From Date | Start date for the new shift assignment | Required. The date from which the new shift schedule becomes active. |
| Effective To Date | End date for the shift assignment | Optional. Used for temporary or contract assignments. For permanent, ongoing shifts, leave this blank. |
| Assignment Type | Type of assignment (Dropdown: Regular / Temporary / Contract / Probation) | Required. Defaults to 'Regular'. |
| Reason for Change | Purpose of assigning a new shift (Dropdown: New Joining, Transfer, Promotion, Request, Restructure, Other) | Required. A reason must be selected. |
| Additional Notes | Remarks or supplementary information | Optional. E.g., "Assigned temporary shift for board examination duties." |
| Notify Employee | Email notification flag (Yes/No Checkbox) | If checked, an email containing shift assignment details will automatically be sent to the employee. |

---

## Business Rules & Validation Policies

1. **Single Active Shift Rule:**
   - An employee can have **only one** active shift assignment at any given point in time.
   - When a new shift is assigned, the system automatically terminates the previous shift. The previous shift's end date is automatically set to `New Shift Start Date - 1 day`.

2. **Date Overlap Validation:**
   - The date range of a new shift assignment must not overlap with any existing active or scheduled shift ranges for that employee. If an overlap is detected, the system displays the error: *"Shift already assigned during this period"*.

3. **Status Assignment Logic:**
   - **Active:** If the *Effective From Date* is today or in the past, and the *Effective To Date* is blank or in the future, the assignment status is 'Active'.
   - **Scheduled:** If the *Effective From Date* is in the future, the assignment status is 'Scheduled'. It will automatically become 'Active' when that date is reached.
   - **Expired:** When the *Effective To Date* has passed, the assignment status automatically transitions to 'Expired'.

---

## Screen Workflows & Operations

### 1. Assigning a Shift to an Employee (Single Assignment)
- The Admin clicks the "+ Assign Shift" button.
- Searches and selects the target employee (system displays their current active shift, if any).
- Selects the new shift, start date (Effective From), assignment type, and reason for change.
- Clicks Save. The system automatically updates the end date of the previous shift and activates the new shift assignment.

### 2. Bulk Shift Assignment (Bulk Assignment)
- The Admin clicks the "Bulk Assign" option.
- Selects the target shift template, enters the effective start/end dates, and specifies the reason.
- Filters employees by department or designation and selects multiple employees via checkboxes.
- Clicks "Assign to Selected" to map the shift to all checked employees in one action.

### 3. Viewing Assignment History (View History)
- The Admin clicks "View History" next to any employee's record.
- A pop-up modal or side drawer displays a chronological list of all shifts (past, present, and scheduled) assigned to that employee, along with their start and end dates.

---

## Real-World Example Scenario

**Teacher Amit Patel** is currently working the Standard Shift (09:00 AM - 05:00 PM), which has been active since January 1st, 2026. Due to a schedule change, he needs to be moved to the Morning Shift (07:30 AM - 02:30 PM) starting June 1st, 2026.

1. The Admin searches for Amit Patel on the "Shift Assignments" screen.
2. Clicks "+ Assign Shift".
3. Under **Assign New Shift**, selects: `Morning Shift`.
4. Under **Effective From Date**, selects: `01-Jun-2026`.
5. Under **Reason for Change**, selects: `Transfer`.
6. Clicks Submit.
7. **System Action:** The system automatically sets the end date of Amit's previous Standard Shift assignment to `31-May-2026` (marking it as expired) and schedules the Morning Shift to begin on `01-Jun-2026`.
