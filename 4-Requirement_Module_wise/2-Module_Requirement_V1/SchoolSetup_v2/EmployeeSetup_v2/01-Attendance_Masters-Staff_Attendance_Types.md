# Staff Attendance Types — Requirement Document

## Screen Purpose & Overview

This screen is part of the Attendance Masters sub-menu. The main purpose of this screen is to define and manage the different daily attendance states (such as Present, Absent, Half Day, Late, and Paid Leave) for school staff and teachers. 

Each attendance type is associated with specific rules. For example, it determines whether salary is deducted if an employee arrives late, or what percentage of payment is received when an employee takes a half-day.

---

## Common Use Cases

1. **Setting Daily Attendance Rules:** The school wants to mark employees as "Late (LT)" when they scan their fingerprints past the start time, but still grant full pay (if they fall within the grace period).
2. **Configuring Paid/Unpaid Leaves:** Ensuring that an employee's salary is automatically calculated at 0% when they are on "Leave Without Pay (LWP)".
3. **Defining Approval Rules:** Requiring mandatory supervisor approval whenever a staff member is marked "Absent" or takes a "Half-Day".
4. **Setting Color Coding for Reports:** Assigning visual colors to attendance states, such as Green for 'Present' and Red for 'Absent', for clean monthly registers.

---

## Screen Fields & Input Rules

| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| Attendance Code | Short unique shorthand code (e.g., PR, AB, HD, LT, LWP) | Required. Must be unique. Two attendance types cannot share the same code. |
| Attendance Name | Full descriptive name (e.g., Present, Absent, Half Day, Late, Sick Leave) | Required. Length must be between 1 to 100 characters. |
| Category | Classification category (Dropdown: Attendance / Leave / Holiday / Other) | Required. Crucial for grouping reports. |
| Description | Explanatory note about the attendance type | Optional. |
| Is Present | Flag to treat this status as 'Present' (Yes/No Checkbox) | If checked, the employee is counted as present in statistical dashboards. |
| Can Be Half-Day | Flag to allow half-day marking (Yes/No Checkbox) | If checked, this state can be selected as a half-day options during daily attendance marking. |
| Affects Payroll | Flag indicating salary impact (Yes/No Checkbox) | If checked, the payroll system will process salaries based on the assigned Payroll Percentage. |
| Requires Approval | Flag indicating manager approval requirement (Yes/No Checkbox) | If checked, selecting this status triggers an automatic approval request workflow. |
| Payroll Percentage | Salary percentage received under this status (0% to 100%) | Required. E.g., 100% for Present, 50% for Half-Day, 0% for Absent. |
| Color Code | Visual color for calendars and reports | Picked from a color dropdown menu. |
| Display Order | Relative sorting order in dropdown selection list | Optional. Smaller numbers appear higher on dropdown lists. |
| Is Active | Status toggle (Yes/No Checkbox) | Inactive attendance types cannot be selected during new attendance marking. |

---

## Business Rules & Validation Policies

1. **System Protected Types (Built-in Types):**
   - Certain standard types like **Present (PR)**, **Absent (AB)**, **Late (LT)**, **Half-Day (HD)**, and **Holiday (HO)** are system-locked defaults.
   - The Administrator cannot delete these default types, and their core codes and categories cannot be modified.

2. **Payroll Correlation (Salary Impact):**
   - If *Affects Payroll* is set to 'Yes', the payroll system computes salary as follows:
     - **Full Day Present:** Full daily wage = 100% of daily salary.
     - **Half-Day:** Half daily wage = 50% of daily salary.
     - **Absent / LWP:** Zero daily wage = 0% of daily salary.
   - If *Affects Payroll* is set to 'No', this status does not deduct salary (e.g., paid leaves).

3. **Approval Flow Integration:**
   - If *Requires Approval* is set to 'Yes' (e.g., for 'Late' or 'Absent' correction), the marked attendance remains as 'Pending Approval' until confirmed by a manager.

---

## Screen Workflows & Operations

### 1. Creating a New Attendance Type (Create)
- The Admin clicks the "+ New Type" button.
- A form opens where they enter the Code, Name, and select the Category.
- The Admin configures behavior flags (Is Present, Can Be Half-Day, Affects Payroll, Requires Approval).
- The Admin enters the payroll percentage (e.g., 100 for Present, 0 for Absent).
- Click Save. The new type is added to the database and appears in the master list.

### 2. Editing Attendance Type Details (Update)
- The Admin clicks "Edit" next to any custom attendance type in the list.
- Fields are updated. **Note:** Default system codes cannot be edited.
- Click Save to apply the changes.

### 3. Deactivating / Archiving (Delete)
- To preserve historical audit trails, attendance types are never permanently deleted from the database.
- Clicking "Delete" archives the record (Soft Delete), removing it from active dropdowns while preserving history.

---

## Real-World Example Scenario

**School ABC** wants to create a new attendance status called "On Duty (OD)" for teachers who go out on school promotion campaigns. The status should count as Present with full pay, without requiring manager approval.

1. The Admin clicks "+ New Type" and enters: Code `OD`, Name: `On Duty`.
2. Selects Category: `Attendance`.
3. Sets Behavior Flags:
   - Is Present = **Yes** (the employee is actively working).
   - Can Be Half-Day = **Yes**.
   - Affects Payroll = **Yes** (salary needs to be processed).
   - Requires Approval = **No** (pre-approved duty).
4. Sets Payroll Percentage: **100%** (no salary deduction).
5. Selects Color: **Blue**.
6. Clicks Submit.
7. Now, teachers can select "OD" as an option on the daily attendance sheet.
