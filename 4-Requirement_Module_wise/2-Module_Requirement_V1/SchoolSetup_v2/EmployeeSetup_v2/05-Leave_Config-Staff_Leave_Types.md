# Staff Leave Types — Requirement Document

## Screen Purpose & Overview

This screen is part of the Leave Config sub-menu. Its main purpose is to define and maintain the school's master catalog of leave types. 

Schools typically offer several categories of leave, such as Casual Leave (CL), Sick Leave (SL), Earned Leave (EL), Maternity Leave (ML), and Leave Without Pay (LWP). The Admin uses this screen to configure the rules, salary impact (paid/unpaid), documentation requirements, and submission limits for each leave type.

---

## Common Use Cases

1. **Adding a New Leave Category:** Defining a new category of leave, such as Paternity Leave or Special Medical Leave, in the school system.
2. **Modifying Leave Rules:** Updating policies, such as changing the requirement for submitting a medical certificate from 2 days of sick leave to 3 days.
3. **Setting Salary Deduction Policies:** Creating a "Leave Without Pay (LWP)" type so that any days logged under it automatically trigger salary deductions in the payroll system.
4. **Color Coding for Visual Identification:** Assigning distinct colors (e.g., Red for Sick Leave, Yellow for Casual Leave) to display clearly on school calendars and reports.

---

## Screen Fields & Input Rules

| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| Leave Code | Unique shorthand identifier (e.g., CL, SL, EL, LWP, ML) | Required. Must be capital letters (A-Z) and between 2 to 6 characters long. Duplicate codes are not allowed. |
| Leave Name | Full descriptive name (e.g., Casual Leave) | Required. Length must be between 1 to 100 characters. |
| Description | Explanatory notes about the leave category | Optional. Max 500 characters. This is displayed as a tooltip on the employee's application form. |
| Is Paid | Flag indicating if salary is paid during this leave (Yes/No Checkbox) | Yes (Paid) means no salary deduction. No (LWP) means the employee's salary is deducted per day. |
| Is Carry-Forwardable | Flag to roll over unused balance to the next year (Yes/No Checkbox) | If checked, unused balances at the end of the year transfer to the next year, subject to carry-forward caps. |
| Max Carry-Forward Limit | Maximum number of days that can roll over | Required if *Is Carry-Forwardable* is Yes. Leaving it blank allows unlimited rollover. |
| Is Encashable | Flag indicating if unused leaves can be encashed (Yes/No Checkbox) | If checked, employees can receive monetary compensation for unused balances at the end of the year. |
| Encashable at Separation | Flag for payout upon resignation or retirement (Yes/No Checkbox) | Typically checked for Earned Leave (EL). Unused leaves are paid out during full and final settlement. |
| Max Encashable Days | Maximum days eligible for payout at separation | Required if *Encashable at Separation* is Yes. |
| Requires Document | Flag indicating if supporting documents are required (Yes/No Checkbox) | If checked, uploading files (like a medical certificate) is mandatory during application. |
| Min Days for Document | Threshold duration that triggers mandatory document upload | Optional. E.g., if set to '2', a 1 or 2-day leave does not require documents, but a 3-day or longer leave requires a document. |
| Requires Substitute | Flag indicating if teacher substitution is required (Yes/No Checkbox) | If checked, applying for this leave triggers an alert to the timetable coordinator to schedule a substitute teacher. |
| Allows Half-Day | Flag to allow half-day (0.5 day) applications (Yes/No Checkbox) | If checked, employees can apply for a half-day off. |
| Allows Back-Dated | Flag to allow applying for past dates (Yes/No Checkbox) | Typically checked for Emergency or Sick Leave to allow applications after recovery. |
| Requires Approval | Flag to run approval workflows (Yes/No Checkbox) | If set to No, the leave application is automatically approved upon submission. |
| Min Days per Application | Minimum days allowed in a single request | Defaults to 0.5 (half-day). Must be at least 1.0 if *Allows Half-Day* is set to No. |
| Max Days per Application | Maximum days allowed in a single request | Optional. Useful for long-term leaves like Maternity Leave (e.g., max 180 days). |
| Min Advance Notice Days | Days of advance notice required before the leave start date | Required. Enter '0' for same-day. E.g., 1 day for Casual Leave, 15 days for Earned Leave. |
| Max Consecutive Days | Maximum consecutive days allowed for this leave type | Optional. Prevents submissions exceeding this limit. |
| Display Order | Sorting order sequence in dropdown selection lists | Optional. Lower numbers (e.g., 1, 2) appear higher in dropdown menus. |
| Calendar Color | Highlight color for reports and calendars | Selectable from a color picker dropdown. |

---

## Business Rules & Validation Policies

1. **System Protected Leaves:**
   - Standard leaves like **CL, SL, EL, LWP** are default system-seeded templates.
   - The Admin cannot delete standard leaves, and their codes and names cannot be modified. However, their rules (e.g., notice period, document thresholds) are fully editable.

2. **Notice Period vs. Emergency Exception:**
   - If *Min Advance Notice Days* is configured (e.g., 1 day notice for CL), employees cannot apply for past dates or today's date under normal conditions.
   - If the employee activates an "Emergency" toggle on the form (and the policy permits it), the notice period check is bypassed.

3. **Delete Restrictions:**
   - If a leave type is currently referenced in an employee's leave balance or has been utilized in any historical leave application, it cannot be permanently deleted.
   - In such cases, the Admin must deactivate it by toggling **Is Active = No**. This preserves historical records while removing the option from the new application dropdowns.

---

## Screen Workflows & Operations

### 1. Defining a New Leave Type (Create)
- The Admin clicks the "+ New Leave Type" button.
- A detailed form opens. The Admin inputs the Leave Code (e.g., SL), Name, paid status, rollover settings, and other configuration values.
- Clicks Save. The leave type is activated and becomes available in application dropdowns.

### 2. Modifying Leave Rules (Update)
- The Admin clicks "Edit" next to the target leave type in the list.
- Modifies the rules (e.g., changes the advance notice requirement). The Leave Code remains disabled and cannot be changed.
- Clicks Save to immediately apply the updated rules to all new applications.

### 3. Deactivating/Soft Deleting a Leave Type (Delete)
- If a leave type is no longer used, the Admin toggles **Is Active = No** rather than deleting it.
- This action preserves historical audit data but prevents employees from selecting it for future requests.

---

## Real-World Example Scenario

**School Admin** wants to configure a rule for **Sick Leave (SL)**:

1. The Admin opens the edit form for: Code `SL`, Name: `Sick Leave`.
2. Sets the following configuration values:
   - **Is Paid** = `Yes` (no salary deduction for being sick).
   - **Allows Back-Dated** = `Yes` (allows employees to apply after returning from illness).
   - **Requires Document** = `Yes`.
   - **Min Days for Document** = `2` (no certificate is needed for a 1 or 2-day sick leave, but a medical certificate is mandatory for requests of 3 days or more).
   - **Min Advance Notice Days** = `0` (no advance notice required).
3. The Admin saves the form. Now, if a teacher attempts to apply for a 3-day Sick Leave, the system will prevent submission until a medical certificate is uploaded.
