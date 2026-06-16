# Screen Requirement: Employee Leave Balance (Deep Requirements)
## Document ID: SR-EM-05-TAB6
**Module:** SchoolSetup / EmployeeSetup  
**Screen Name:** Leave Configuration > Employee Leave Balance (Tab 6)  
**Route:** `school-setup.leave-config?tab=leave-balance`  
**User Role:** School Administrator, HR Manager  
**Priority:** P0 (Critical)  
**Status:** Approved for Development  

---

## 1. Screen Overview & Business Purpose

### 1.1 Purpose
This screen displays and manages the **live leave-balance ledger** for every employee, per leave type, per annual session. It is the **source of truth** for how many leave days an employee has available. The balance drives:
- **Leave Application Validation:** Can the employee apply for N days? (available_balance >= N)
- **Payroll Deductions:** For unpaid leave, how many days to deduct?
- **Year-End Carry-Forward:** How many days roll over to next year?
- **Separation Encashment:** How many days to pay out at F&F settlement?

### 1.2 Business Context
- HR needs to see employee-wise leave balance at a glance
- Balance auto-updates when applications are approved/rejected
- HR can manually adjust balance (+/−) with reason tracking
- Balance is seeded from `sch_staff_leave_config` policies at session start

### 1.3 Key Concepts
- **One Row Per (Employee + Session + Leave Type):** Unique constraint ensures no duplicate balances
- **Available Balance:** Auto-computed via generated column: `opening_balance + carry_forward - total_used`
- **Balance Lifecycle:** Opening → (accrued/carried) → Used → Pending → Adjusted
- **Ledger Refresh:** Automatic on approval/rejection/cancellation events

---

## 2. Complete Field Definitions (Deep Detail)

### 2.1 `employee_id` (FK → sch_employees.id)
- **Type:** INT UNSIGNED, Required, FK
- **Meaning:** The employee whose leave balance this record represents.
- **Uniqueness:** Part of the unique constraint: `UNIQUE(employee_id, annual_leave_sessions_id, leave_type_id)`
- **Cascade:** If employee is deleted, their balance records are also deleted (CASCADE)

### 2.2 `annual_leave_sessions_id` (FK → sch_annual_leave_sessions.id)
- **Type:** VARCHAR(9) / INT UNSIGNED, Required, FK
- **Meaning:** The annual leave session for which this balance applies (e.g., "2025-26", "2026 Calendar Year").
- **Note:** In the DDL, this is defined as VARCHAR(9) but should ideally be INT UNSIGNED FK to `sch_annual_leave_sessions.id`. The application layer should handle this mapping.
- **Business Logic:**
  - Each session has its own set of balance records
  - When a new session starts, new balance rows are seeded for all employees
  - Carry-forward from previous session creates new rows in the new session

### 2.3 `leave_type_id` (FK → sch_staff_leave_types.id)
- **Type:** INT UNSIGNED, Required, FK
- **Meaning:** The leave type (CL, SL, EL, etc.) for which this balance applies.
- **Uniqueness:** Part of the unique constraint

### 2.4 `opening_balance` (Session Start Balance)
- **Type:** DECIMAL(5,2), Required, Default = 0.00
- **Meaning:** The balance **granted at the start** of the session. This is the **base entitlement** for the session.
- **How It's Set:**
  ```
  At session start (or employee creation):
      opening_balance = Resolved_annual_entitlement from matching config
      
  Example: Teacher with 16 CL days/year → opening_balance = 16.00
  ```
- **What It Includes:**
  - The annual entitlement from the matching `sch_staff_leave_config`
  - Any pro-rata adjustments for mid-session joiners
  - **Does NOT include** carry_forward (that's a separate field)
- **Can be modified by:** HR manual adjustment (rare)

### 2.5 `carry_forward` (Carried From Previous Session)
- **Type:** DECIMAL(5,2), Required, Default = 0.00
- **Meaning:** Unused leave days **carried forward** from the previous session.
- **Calculation (at year-end rollover):**
  ```
  IF leave_type.is_carry_forwardable = true:
      config = Resolve matching config for this employee + leave_type
      max_cf = config.max_carry_forward ?? leave_type.max_carry_forward ?? UNLIMITED
      
      IF max_cf IS NULL (unlimited):
          carry_forward = prior_session_available_balance
      ELSE:
          carry_forward = MIN(prior_session_available_balance, max_cf)
  ELSE:
      carry_forward = 0.00
  ```
- **Example:**
  - Prior session: 5 CL days remaining
  - CL max_carry_forward = 5
  - carry_forward = MIN(5, 5) = 5.00

### 2.6 `total_used` (Approved Leave Consumed)
- **Type:** DECIMAL(5,2), Required, Default = 0.00
- **Meaning:** Total number of leave days **approved and consumed** so far this session.
- **How It's Updated:**
  ```
  ON Leave Application Approved:
      total_used += approved_days
      
  ON Leave Application Cancellation (after approval):
      total_used -= approved_days (reversal)
      
  ON Leave Application Rejection:
      total_used NOT affected (only pending is affected)
  ```
- **Not Directly Editable:** Updated automatically by system events

### 2.7 `total_pending` (Leave Awaiting Approval)
- **Type:** DECIMAL(5,2), Required, Default = 0.00
- **Meaning:** Total leave days in **applications that are currently pending** (not yet approved or rejected).
- **How It's Updated:**
  ```
  ON Leave Application Submitted:
      total_pending += application.total_days
      
  ON Leave Application Approved:
      total_pending -= approved_days  (moves to total_used)
      
  ON Leave Application Rejected:
      total_pending -= application.total_days  (released back)
      
  ON Leave Application Cancelled (before approval):
      total_pending -= application.total_days  (released back)
      
  ON Leave Application Cancelled (after approval):
      total_used -= approved_days  (reversal; total_pending not affected)
  ```
- **Purpose:** Provides a "pending deduction" view so HR/staff see what's already been applied for

### 2.8 `available_balance` (STORE GENERATED — Live Balance)
- **Type:** DECIMAL(5,2), STORED GENERATED, Read-Only
- **Formula (as per DDL):**
  ```sql
  available_balance = opening_balance + carry_forward - total_used
  ```
- **Important Note:** `total_pending` is NOT subtracted in this formula. The formula only subtracts `total_used`. The `total_pending` is displayed separately for the user's awareness.
- **Display Logic in UI:**
  ```
  Available (for new application) = opening_balance + carry_forward - total_used - total_pending
  ```
  The UI should compute this at the application layer for "real" remaining balance.
- **Edge Cases:**
  - Can be negative if HR overrides/adjustments cause this (should be prevented)
  - Minimum: 0 (balance should not go negative)

### 2.9 `manual_adjustment` (HR Correction)
- **Type:** DECIMAL(5,2), Required, Default = 0.00
- **Meaning:** HR-applied **adjustment (positive or negative)** to correct the balance for special cases.
- **Business Logic:**
  - POSITIVE (+) = Adds days to balance (e.g., bonus leave, error correction)
  - NEGATIVE (−) = Deducts days from balance (e.g., recovery, error correction)
  - Zero (0) = No adjustment
  - Is NOT included in the `available_balance` generated column formula
- **Validation:**
  - If `manual_adjustment != 0`, `adjustment_reason` is REQUIRED
  - Cannot be zero (if adjustment reason is provided, amount must be non-zero)
- **Common Use Cases:**
  - "+5 CL: Special appreciation leave granted by Principal"
  - "-2 SL: Correction — previous approval was in error"

### 2.10 `adjustment_reason` (Audit Trail for Adjustments)
- **Type:** VARCHAR(255), Nullable
- **Meaning:** The reason/justification for the manual adjustment.
- **Validation:**
  - REQUIRED if `manual_adjustment != 0`
  - Should be descriptive enough for audit purposes
  - Max 255 characters

### 2.11 `is_active` (Active Status)
- **Type:** TINYINT(1), Boolean, Default = 1
- **Meaning:** Soft active flag for the balance record.
- **Usage:** Rarely used — balance records should always be active for historical accuracy

### 2.12 Audit Fields
- `created_by`: INT UNSIGNED, FK → sys_users.id — Who created this balance record (system or HR)
- `updated_by`: INT UNSIGNED, FK → sys_users.id — Who last updated this record
- `created_at`: TIMESTAMP — Record creation timestamp
- `updated_at`: TIMESTAMP — Last update timestamp (auto-updates)
- `deleted_at`: TIMESTAMP, Nullable — Soft delete timestamp

---

## 3. Balance Lifecycle (Deep Detail)

### 3.1 Session Start — Seeding Balances

```
1. When a new Annual Leave Session is created:
    → Trigger: AnnualLeaveSession.created
    
2. System identifies all active employees:
    → SELECT FROM sch_employees WHERE is_active = 1 AND deleted_at IS NULL
    
3. For each employee, for each active leave type:
    → Resolve applicable config (TAB2 matching algorithm)
    → Compute opening_balance:
        - If employee is in probation:
            - If config.available_during_probation = false:
                opening_balance = 0
            - Else if config.probation_entitlement_pro_rata = true:
                opening_balance = annual_entitlement × (probation_elapsed / total_probation)
            - Else:
                opening_balance = annual_entitlement
        - Else (not in probation):
            opening_balance = annual_entitlement
    
    4. CREATE balance record:
        employee_id, session_id, leave_type_id,
        opening_balance, carry_forward = 0,
        total_used = 0, total_pending = 0,
        manual_adjustment = 0
```

### 3.2 New Employee Created — Seeding Balances

```
1. When an employee is created (sch_employees row created):
    → Trigger: Employee.created → LeaveBalanceService::seedBalancesForEmployee()
    
2. Find the current active session:
    → SELECT FROM sch_annual_leave_sessions WHERE is_active = 1
    
3. For each active leave type:
    → Same logic as session-start seeding (above)
    → Pro-rata based on join date within session:
        IF joining_date > session.start_date:
            Pro-rata the entitlement:
            months_remaining = months_between(joining_date, session.end_date)
            total_months = months_between(session.start_date, session.end_date)
            opening_balance = annual_entitlement × (months_remaining / total_months)
```

### 3.3 Leave Application Submitted

```
total_pending += applied_days
    
Formula: new_total_pending = old_total_pending + applied_days

Display-only available (for applicant's view):
    available_for_new_application = opening_balance + carry_forward - total_used - total_pending
```

### 3.4 Leave Application Approved (Final Level)

```
total_pending -= approved_days
total_used += approved_days

Formula:
    new_total_pending = old_total_pending - approved_days
    new_total_used = old_total_used + approved_days
    
Note: approved_days may differ from applied_days (partial approval allowed)
```

### 3.5 Leave Application Rejected

```
total_pending -= total_days (release back to pool)

Formula:
    new_total_pending = old_total_pending - total_days
    total_used: NOT affected
```

### 3.6 Leave Application Cancelled (Before Approval)

```
total_pending -= total_days (release back to pool)

Same as rejection: just release pending hold
```

### 3.7 Leave Application Cancelled (After Approval)

```
total_used -= approved_days (reversal)

Formula:
    new_total_used = old_total_used - approved_days
    total_pending: NOT affected (was already moved to total_used on approval)
```

### 3.8 Year-End Rollover (Session End)

```
1. System identifies sessions where end_date has passed and rollover NOT done
    
2. For each employee, for each leave type:
    a. Get current session's available balance:
        current_available = opening_balance + carry_forward - total_used
    
    b. Get next session (the new active session)
    
    c. Calculate carry_forward:
        IF leave_type.is_carry_forwardable (check config override):
            max_cf = resolve max_carry_forward
            IF max_cf IS NULL:
                carry = current_available
            ELSE:
                carry = MIN(current_available, max_cf)
        ELSE:
            carry = 0
    
    d. Get next session's entitlement:
        new_entitlement = resolve config for next session
        opening_balance = new_entitlement (may change if config changed)
    
    e. CREATE new balance row for next session:
        opening_balance = new_entitlement
        carry_forward = carry
        total_used = 0
        total_pending = 0
        manual_adjustment = 0
```

### 3.9 Manual Adjustment

```
1. HR selects employee + leave type
2. Enters adjustment amount (+5 or -3)
3. Enters adjustment reason
4. System updates:
    manual_adjustment += entered_amount
    adjustment_reason = entered_reason
    
Note: The available_balance formula does NOT include manual_adjustment
(LIMITATION: The stored generated column only uses opening + carry - used)

To get TRUE available balance including adjustments:
    TRUE_available = opening_balance + carry_forward + manual_adjustment - total_used - total_pending
    
This must be calculated at the APPLICATION LAYER.
```

---

## 4. Validation Rules Matrix

| Field | Required | Constraints |
|-------|----------|-------------|
| employee_id | Yes | Must exist in sch_employees |
| annual_leave_sessions_id | Yes | Must reference an active session |
| leave_type_id | Yes | Must exist in sch_staff_leave_types |
| opening_balance | Yes | >= 0, max 999.99 |
| carry_forward | Yes | >= 0, max 999.99 |
| total_used | Yes | >= 0, max 999.99 |
| total_pending | Yes | >= 0, max 999.99 |
| manual_adjustment | Yes | Can be negative or positive (zero allowed) |
| adjustment_reason | Conditional | Required if manual_adjustment != 0 |

### Unique Constraint
```
UNIQUE(employee_id, annual_leave_sessions_id, leave_type_id)

Cannot have two balance rows for the same (employee + session + leave type)
```

### Application Layer Cross-Field Validations
```
1. total_used + total_pending <= opening_balance + carry_forward + manual_adjustment
   (Should never exceed total available)

2. opening_balance >= 0 (Cannot have negative entitlement at session start)

3. carry_forward >= 0 (Cannot carry negative balance)

4. manual_adjustment:
    - If manually adjusting +: Increases effective balance
    - If manually adjusting -: Decreases effective balance (with reason)
```

---

## 5. Business Rules

### Rule 1: Available Balance is Auto-Computed
```
available_balance = opening_balance + carry_forward - total_used

BUT effective_balance (for application validation) should be:
    effective_balance = opening_balance + carry_forward + manual_adjustment - total_used - total_pending

The UI should display both:
    - "Available Balance" (from generated column)
    - "Effective Balance" (computed at app layer, including pending + adjustment)
```

### Rule 2: Balance Validation at Leave Application
```
WHEN employee applies for leave:
    IF applied_days > effective_balance:
        → Error: "Insufficient leave balance"
        → Show: "Available: {effective_balance}, Applied: {applied_days}"
```

### Rule 3: Adjustment Requires Reason
```
IF manual_adjustment != 0:
    adjustment_reason must be non-empty
    → Error: "Adjustment reason is required when making manual adjustments"
```

### Rule 4: Balance Cannot Go Negative (Prevention)
```
Before approving leave:
    IF total_used + approved_days > opening_balance + carry_forward + manual_adjustment:
        → Warning: "Approving this leave will result in negative balance"
        → Allow override by HR with reason
        
Note: The system should try to prevent negative balance but allow HR override
in exceptional cases.
```

### Rule 5: Rollover Preservation
```
At session rollover:
    - Carry-forward amount = MIN(remaining, max_carry_forward)
    - Opening balance = NEW entitlement (from current config)
    - Old balance remains in the OLD session (frozen for records)
    - New session has its own balance rows
```

### Rule 6: Manual Adjustment Audit
```
Every manual adjustment should be logged:
    - Before value
    - After value
    - Who made the change
    - When
    - Reason
    
This is achieved via audit fields (updated_by, updated_at)
and the adjustment_reason field.
```

### Rule 7: Balance Read-Only for Non-HR
```
Regular employees can only VIEW their own balance.
Manual adjustments can ONLY be made by HR/Admin users with appropriate permissions.
```

---

## 6. Balance Display & Calculations

### 6.1 Individual Employee Balance View
```
Employee: John Doe (EMP001)
Session: 2025-26

Leave Type │ Opening │ Carry │ Used │ Pending │ Available* │ Adjusted
───────────┼─────────┼───────┼──────┼─────────┼────────────┼─────────
CL         │ 16.00   │ 2.00  │ 4.00 │ 2.00    │ 14.00      │ 0.00
SL         │ 10.00   │ 0.00  │ 0.00 │ 0.00    │ 10.00      │ 0.00
EL         │ 20.00   │ 5.00  │ 3.00 │ 0.00    │ 22.00      │ 0.00
ML         │ 90.00   │ 0.00  │ 0.00 │ 0.00    │ 90.00      │ 0.00
LWP        │ 0.00    │ 0.00  │ 0.00 │ 0.00    │ 0.00       │ 0.00

*Available = Opening + Carry - Used (generated column)
Effective = Opening + Carry + Adjustment - Used - Pending
```

### 6.2 Bulk Employee Balance View
```
Session: 2025-26  │  Department: Science  │  Leave Type: All

Employee   │ Dept │ CL    │ SL    │ EL    │ ML    │ LWP
───────────┼──────┼───────┼───────┼───────┼───────┼───────
John Doe   │ Sci  │ 14.00 │ 10.00 │ 22.00 │ 90.00 │ 0.00
Jane Smith │ Sci  │ 12.00 │ 8.00  │ 18.00 │ 0.00  │ 0.00
Raj Kumar  │ Math │ 10.00 │ 6.00  │ 20.00 │ 0.00  │ 0.00
```

---



## Related Documents
- [SR-EM-05-TAB1](./SR-EM-05-TAB1-Staff_Leave_Types.md) — Leave types referenced in balance
- [SR-EM-05-TAB2](./SR-EM-05-TAB2-Staff_Leave_Config.md) — Entitlements that seed balance
- [SR-EM-05-TAB7](./SR-EM-05-TAB7-Annual_Leave_Sessions.md) — Session definitions for balance periods
- [SR-EM-05](./SR-EM-05-Leave_Configuration.md) — Leave Configuration module overview
