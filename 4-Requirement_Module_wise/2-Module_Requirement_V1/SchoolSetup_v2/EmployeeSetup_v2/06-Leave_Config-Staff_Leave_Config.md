# Staff Leave Config — Requirement Document

## Screen Purpose & Overview

This screen is part of the Leave Config sub-menu. Its main purpose is to map individual **Leave Types** (such as CL, SL, EL) to different school staff roles, departments, and designations. 

Through this screen, the Admin defines the annual leave entitlement for specific employee groups, as well as how and when those leaves are credited (accrued) to employee accounts (e.g., as a lump sum at the start of the year, or incrementally on a monthly basis). This screen can also be referred to as the **Leave Allocation Policy Screen**.

---

## Common Use Cases

1. **Defining Role-Wise Leave Allowances:** Awarding teachers 14 Casual Leaves (CL) per year, while administrative staff receive 12 Casual Leaves (CL).
2. **Configuring Accrual Methods:** Setting Earned Leave (EL) to a 'Monthly Pro-Rata' accrual method so employees automatically receive 1.6 leaves each month, while Casual Leave is credited as a 'Lump Sum' at the start of the year.
3. **Restricting Leaves during Probation:** Configuring a policy so that employees on probation are not eligible for Earned Leave (EL) but can accrue and use Sick Leave (SL).
4. **Setting Department-Specific Exceptions:** Granting science department teachers 2 additional days of annual leave compared to other departments due to laboratory duties.

---

## Screen Fields & Input Rules

| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| Leave Type | The leave type for which the policy is being configured | Required. Must select an active leave type defined in the system. |
| Applies To Role | Target staff role for this configuration | Optional. Selecting "All Roles" applies this policy to all staff, or select a specific role (e.g., Teacher). |
| Applies To Department | Target department for this configuration | Optional. Select a specific department (e.g., Science, Academic) or select "All Departments". |
| Applies To Designation | Target designation for this configuration | Optional. Select a specific designation (e.g., Senior Teacher) or select "All Designations". |
| Employment Type | Target contract type for this configuration | Optional. Select from: Permanent, Contract, Temporary, Probation, Intern, or select "All". |
| Annual Entitlement | Total leave days awarded per year | Required. Valid range: 0 to 365 days. |
| Accrual Method | Frequency and method of crediting leaves (Dropdown) | Required. <br>• **Lump Sum:** The entire annual entitlement is credited on the first day of the annual session.<br>• **Monthly Pro-Rata:** Leaves are credited incrementally each month (Annual Entitlement / 12).<br>• **Quarterly:** Leaves are credited every three months (Annual Entitlement / 4). |
| Accrual Start Delay | Delay period before leave accumulation begins | Optional (in months). Default is 0. If set to 6, no leaves will accrue for the first 6 months of employment. |
| Carry-Forward Override | Overrides the general leave type rollover policy | Dropdown: Leave Type Default / Yes / No. (Used to bypass global settings for specific employee categories). |
| Max Carry-Forward Override | Custom limit for carry-forward leaves | Required if Carry-Forward Override is set to Yes. |
| Separation Encashment Override | Overrides general leave type payout rules | Dropdown: Leave Type Default / Yes / No. |
| Max Separation Encashable | Custom limit for payout at separation | Required if Separation Encashment Override is set to Yes. |
| Available During Probation | Indicates if leaves can be used during probation (Yes/No Checkbox) | Default is No. (Usually set to No for Earned Leave, and Yes for Casual or Sick Leave). |
| Probation Pro-Rata | Calculates leave limits proportionally during probation | Default is Yes. (E.g., if annual entitlement is 12 CL and probation is 6 months, the employee can only use up to 6 CL during probation). |
| Matching Priority | Priority sequence for policy execution (Dropdown: 1 to 100) | Required. Default is 10. If an employee matches multiple configurations, the rule with the lowest priority value (e.g., 1) is applied first. |
| Is Active | Status toggle (Yes/No Checkbox) | Required. Only active configurations are evaluated by the leave matching engine. |

---

## Business Rules & Validation Policies

1. **Policy Matching Hierarchy (Specificity & Priority Rule):**
   - When the system determines an employee's leave entitlement, it evaluates active policies using the following matching hierarchy:
     - The policy with the **most specific criteria** matched wins (e.g., a rule matching *Teacher + Science Department + Senior Designation* takes precedence over a general rule matching *Teacher + All Departments*).
     - If multiple matching policies have the same specificity, the policy with the **lowest priority number** is applied (e.g., Priority 1 wins over Priority 10).
     - If no specific rules match, the system falls back to the default "catch-all" configuration (where role and department filters are set to "All").

2. **Duplicate Combination Validation:**
   - The system prevents saving duplicate policies. A combination of Leave Type, Role, Department, Designation, and Employment Type must be unique. Attempting to save a duplicate will trigger: *"A leave configuration with this combination already exists"*.

3. **Accrual Calculations:**
   - **Lump-Sum:** The employee's balance is credited with 100% of the annual entitlement at the start of the session.
   - **Monthly:** The system automatically credits `Annual Entitlement / 12` to the employee's account at the end of each monthly cycle (e.g., a 24-day annual entitlement credits 2.0 days each month).

---

## Screen Workflows & Operations

### 1. Setting Up a New Leave Policy (Create Config)
- The Admin clicks the "+ New Configuration" button.
- Selects the Leave Type and sets the target filters (Role, Department, Designation, and Employment Type).
- Inputs the Annual Entitlement (e.g., 12 days).
- Selects the accrual method (e.g., Lump Sum) and sets the matching priority.
- Clicks Save to activate the configuration rule.

### 2. Updating Policy Rules (Update)
- The Admin clicks "Edit" next to the target configuration in the list.
- Modifies entitlement values, probation settings, or accrual details.
- **Note:** Saving updates prompts a warning alert, notifying the Admin that the system will recalculate and refresh existing employee leave balances according to the new parameters.

### 3. Deactivating a Policy (Soft Delete)
- To retire an old policy, the Admin unchecks the **Is Active** checkbox (sets to 'No').
- The system immediately stops applying this policy to new balance evaluations while retaining historical configuration records.

---

## Real-World Example Scenario

**School ABC** wants to configure **Earned Leave (EL)** rules for permanent teaching staff:

1. The Admin creates a new configuration for Leave Type = `Earned Leave (EL)`.
2. Targets: Applies to Role = `Teacher`, Applies to Department = `All`, Employment Type = `Permanent`.
3. Sets the following rules:
   - **Annual Entitlement** = `24` Days.
   - **Accrual Method** = `Monthly Pro-Rata` (instead of receiving 24 days upfront, teachers accumulate `24 / 12 = 2` EL days per month).
   - **Available During Probation** = `No` (teachers on probation cannot use Earned Leave).
   - **Accrual Start Delay** = `6` Months (no leaves accrue during the first 6 months of employment).
4. Clicks Save.
5. **System Impact:** When a permanent teacher joins, their EL balance remains 0 for the first 6 months. Once they complete 6 months of service, the accrual engine starts automatically crediting them 2 EL days at the end of each month.
