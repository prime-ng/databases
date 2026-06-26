# Holiday Calendar — Requirement Document

## Screen Purpose & Overview

This screen is used to manage the school's annual holiday calendar. The Administrator or HR team uses this screen to input all planned holidays for the academic year (e.g., Summer Vacation, Diwali, Independence Day).

The calendar plays a critical role in **Leave Balance Calculation**. When an employee applies for leave, the system automatically checks if any scheduled holidays fall within the requested date range and excludes those holidays from the total leave days deducted.

---

## Common Use Cases

1. **Adding National Holidays:** Setting up standard national holidays, such as Independence Day or Republic Day, that apply to all employees.
2. **Configuring School Vacations:** Marking long-term seasonal closures, like Summer or Winter break (which span multiple days), in the school calendar.
3. **Setting Department or Role-Specific Holidays:** Defining holidays that apply only to specific employee groups (e.g., Winter Vacation for teaching staff, while administrative staff continue to work).
4. **Managing Optional/Restricted Holidays:** Setting up specific holidays (e.g., regional festivals) where employees can choose a limited number of days off from a predefined list.

---

## Screen Fields & Input Rules

| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| Holiday Code | Unique identifier code (e.g., REP-2026, DW-2026) | Required. Must be unique. Two holidays cannot share the same code. |
| Holiday Name | Descriptive name of the holiday (e.g., Gandhi Jayanti, Diwali Break) | Required. Length must be between 1 to 100 characters. |
| Holiday Category | Classification dropdown: Public / School / Restricted / Optional | Required. Categorizes the holiday type for policy rules. |
| Description | Explanatory note or details about the holiday | Optional. |
| Holiday Date Type | Indicates if the holiday is for a single day or range (Dropdown: Single Date / Date Range) | Required. If "Single Date" is selected, only one date is defined. If "Date Range" is selected, both start and end dates must be provided. |
| From Date | The start date of the holiday | Required. Must fall within the active academic/annual session dates. |
| To Date | The end date of the holiday | Required if "Date Range" is selected. Must be greater than or equal to the From Date (**To Date >= From Date**). |
| Applies To Scope | Determines which staff members get the holiday (Dropdown: All / By Role / By Department) | Defaults to 'All'. If 'By Role' is selected, the admin must select the target roles. If 'By Department' is selected, the admin must select the target departments. |
| Is Paid Holiday | Flag indicating salary eligibility (Yes/No Checkbox) | Default is Yes. Working days marked as paid holidays do not result in salary deductions. |
| Is Optional | Flag for restricted or optional holidays (Yes/No Checkbox) | Default is No. If checked, the holiday is added to the optional pool that employees can choose from. |
| Is Active | Status toggle (Yes/No Checkbox) | Default is Yes. Inactive holidays are excluded from leave calculations and calendar views. |

---

## Business Rules & Validation Policies

1. **Leave Day Count Exclusion:**
   - If an employee applies for Casual Leave (CL) from Monday to Friday, and Wednesday is a designated Public Holiday (e.g., Independence Day):
   - The system calculates the net leave deduction as **4 days**, not 5. The holiday on Wednesday is automatically excluded from the leave balance deduction.
   - Weekends (Saturdays and Sundays) are also excluded from the leave day count by default, unless specified otherwise by the school policy.

2. **Restricted Designation & Scope:**
   - If the *Applies To Scope* is set to a specific role (e.g., *Support Staff*), only employees with that role will have the holiday on their calendar. Teachers and Admin staff will see it as a regular working day.

3. **Optional Holiday Limits:**
   - If the school's policy allows employees to take a maximum of 2 optional/restricted holidays per year, the employee portal will show the list of available optional holidays.
   - Once an employee selects and reserves 2 optional holidays, the remaining options in the list are automatically locked and disabled.

---

## Screen Workflows & Operations

### 1. Adding a New Holiday (Create)
- The Admin clicks the "+ New Holiday" button.
- Enters basic details like Code, Name, and selects the Holiday Category.
- Selects the Date Type (Single Date/Date Range) and enters the dates.
- Configures the scope (All, By Role, By Department) and flags (Is Paid, Is Optional, Is Active).
- Clicks Save. The holiday is added to the system and is immediately reflected on the staff calendar.

### 2. Bulk Import from Excel/CSV (Bulk Add)
- To set up the calendar quickly, the Admin can click "Import from CSV".
- The Admin downloads the standardized Excel/CSV template, fills in the yearly holiday list, and uploads it.
- If validation errors are found, the system displays the specific row numbers and error reasons. On successful validation, all holidays are loaded into the grid.

### 3. Editing Holiday Details (Update)
- The Admin clicks "Edit" on a holiday row from the grid.
- Modifies details as required. If dates are changed, the new dates must still fall within the active academic/annual session.

---

## Real-World Example Scenario

**School ABC** plans a 6-day "Holi Break" from March 15th to March 20th. In this calendar year, March 15th is a Saturday and March 16th is a Sunday (which are already designated non-working weekends).

1. The Admin clicks "New Holiday" and enters:
   - Code: `HOLI-26`
   - Name: `Holi Break Vacation`
   - Category: `School Holiday`
2. Selects Date Type: `Date Range`. From Date: `15 March 2026`, To Date: `20 March 2026`.
3. Scope: `All Employees`. Is Paid: `Yes`, Is Optional: `No`.
4. Clicks Save.
5. **System Calculation:** Although the holiday covers 6 calendar days, the system automatically excludes the weekend days (15th and 16th March). The holiday calendar records this as **4 net holidays**.
6. When a teacher applies for leave from March 12th to March 22nd, the system automatically skips both the Holi holidays (4 days) and the weekends, deducting leave balance only for the actual working days.
