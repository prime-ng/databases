# Employee Leave Balance — Requirement Document

## Screen Purpose & Overview

This screen is the sixth tab under the Leave Config sub-menu. It is used by the Admin and HR team to view and manage live leave balances (remaining vacation/time off accounts) for all school employees and teachers.

This screen serves as the single "Source of Truth" for employee leave records. When an employee submits a leave request, the system references this screen to verify leave availability. If the employee does not have sufficient balance, the application is blocked.

---

## Common Use Cases

1. **Viewing Live Leave Balances:** Allowing HR or administrators to check the remaining leave balance for a specific employee (e.g., viewing how many Casual Leaves Teacher Priya Singh has left).
2. **Performing Manual Adjustments (Adding/Subtracting Leaves):** Adjusting balances manually (e.g., adding +2 special leaves gifted by the Principal for outstanding performance, or correcting a balance by subtracting -1 Sick Leave due to an incorrect mark).
3. **Tracking Pending Leaves:** Reviewing leaves currently in the approval queue (pending approval) that are holding a portion of the employee's balance.
4. **Conducting Year-End Audits:** Verifying rolled-over leave balances during the year-end transition.

---

## Screen Fields & Input Rules

| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| Employee | Employee name and ID | Read-only. Displayed after selecting the target employee from the search list. |
| Annual Session | The academic/fiscal year for the leave balance (e.g., 2025-26) | Dropdown selector. Leave balances are tracked separately for each session. |
| Leave Type | The type of leave (e.g., CL, SL, EL) | Read-only. |
| Opening Balance | Initial leaves allocated at the start of the year | Read-only. Automatically seeded from the Policy Configuration. |
| Carry Forward | Rolled-over leave balance from the previous year | Read-only. Automatically computed at the end of the year via a rollover script. |
| Total Used | Cumulative leave days utilized in the current session | Read-only. Automatically incremented upon approval of a leave request. |
| Total Pending | Leave days requested and awaiting approval | Read-only. Incremented when a request is submitted; decremented when a decision is made. |
| Available Balance | Remaining balance in the database | Read-only. Formula: **Opening Balance + Carry Forward - Total Used**. |
| Manual Adjustment | Number of days to add (+) or subtract (-) | Numeric input. Use positive values (+) to increase and negative values (-) to decrease balances. |
| Adjustment Reason | Explanation for the manual adjustment | Required if the manual adjustment value is not 0. Max 255 characters. |

---

## Business Rules & Validation Policies

1. **Unique Balance Constraint:**
   - An employee can have **only one** leave balance record per Leave Type per annual session. The system prevents duplicate records for the same parameters.

2. **Available vs. Effective Balance Calculation:**
   - **Database Available Balance:** Computed using the formula: `Opening + Carry - Used`. This value does not account for pending requests.
   - **Application Validation Balance (Effective Balance):** Evaluated at the time of application using the formula: `Opening + Carry + Adjustment - Used - Pending`.
   - The applicant's request duration cannot exceed this *Effective Balance*. If they attempt to request more than the effective balance, the system blocks submission with the error: *"Insufficient leave balance"*.

3. **Mandatory Manual Adjustment Auditing:**
   - Any manual change to an employee's leave balance by HR is recorded in an audit log.
   - **Rule:** The Admin must enter a valid reason in the *Adjustment Reason* field. The system blocks saving adjustments if this field is left empty.

4. **Negative Balance Override:**
   - The system generally prevents leave balances from falling below zero. In exceptional cases where HR overrides this rule, the system displays a warning: *"This action will lead to a negative balance. Do you want to proceed?"*.

---

## Screen Workflows & Operations

### 1. Viewing and Filtering Balances (Search)
- The Admin selects the target annual session and searches for an employee by name or ID.
- The screen displays a register table showing the employee's balances (CL, SL, EL, etc.) in separate rows or columns.

### 2. Manually Adjusting Leave Balances (Adjustment)
- HR clicks "Adjust Balance" next to the target leave type row.
- A modal pop-up displays the employee's name, leave type, and current balances as read-only.
- HR inputs the adjustment value (e.g., +3.0 or -1.0) and enters a detailed reason.
- Clicks Save. The system updates the ledger, updates the balance grid, and records the action in the audit trail.

---

## Real-World Example Scenario

**Teacher Amit Patel** has the following Casual Leave (CL) details for the current session (2025-26):
- Opening Balance: `12.0`
- Carry Forward: `2.0`
- Used: `4.0`
- Pending Approval (Awaiting Principal Action): `2.0`
- Available Balance (DB): `12 + 2 - 4 = 10.0`
- Effective Balance (App): `12 + 2 - 4 - 2 = 8.0`

Amit worked over a weekend to manage a school event. The Principal approved an incentive of `1.5` extra leave days.

1. HR searches for `Amit Patel` and clicks `Adjust Balance` next to his CL row.
2. Inputs manual adjustment value: `+1.5`.
3. Inputs adjustment reason: `Event management bonus leave approved by Principal`.
4. Clicks Save.
5. **System Action:** The system updates Amit's Available Balance to `11.5` and his Effective Balance to `9.5`. The details are recorded in the audit log.
