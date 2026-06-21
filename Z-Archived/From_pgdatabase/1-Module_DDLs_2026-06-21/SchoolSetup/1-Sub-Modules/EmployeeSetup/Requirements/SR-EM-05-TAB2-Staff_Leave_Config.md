# Screen Requirement: Staff Leave Config — Entitlements (Deep Requirements)
## Document ID: SR-EM-05-TAB2
**Module:** SchoolSetup / EmployeeSetup  
**Screen Name:** Leave Configuration > Staff Leave Config (Tab 2)  
**Route:** `school-setup.leave-config?tab=staff-leave-config`  
**User Role:** School Administrator, HR Manager  
**Priority:** P0 (Critical)  
**Status:** Approved for Development  

---

## 1. Screen Overview & Business Purpose

### 1.1 Purpose
This screen defines **role-, department-, designation-, and employment-type-specific leave entitlements** that determine how many days of each leave type an employee receives per year. It is the **bridge between leave types (what exists) and employee balances (what an employee gets)**.

### 1.2 Business Context
Different employee categories get different leave entitlements:
- **Teachers** may get more CL (14 days) than admin staff (12 days)
- **Science Department** may get additional CL (16 days) compared to general teachers
- **Contract employees** may not get EL, while permanent employees do
- **Probationary employees** may not get any leave or get reduced entitlement

This screen allows the school HR to configure these variations with a precedence-based policy matching system.

### 1.3 Key Concepts
- **Policy Matching:** Most specific scope combination wins (Teacher + Science Dept overrides Teacher + All)
- **Priority Tie-Breaker:** When two policies have same specificity, lower priority number wins
- **Catch-All Fallback:** If no policy matches, leave type defaults apply
- **Accrual Methods:** Lump Sum (all at once), Monthly Pro-Rata (earned monthly), Quarterly (earned quarterly)
- **Overrides:** Config-level carry-forward/encashment settings override leave type defaults

---

## 2. Complete Field Definitions (Deep Detail)

### 2.1 `leave_type_id` (FK → sch_staff_leave_types.id)
- **Type:** INT UNSIGNED, Required, FK
- **Meaning:** The leave type (CL, SL, EL, etc.) for which this entitlement policy applies.
- **Business Logic:** Each config row is specific to one leave type. An employee's entitlement for each leave type is resolved independently.
- **Validation:** Must reference an existing, active leave type in `sch_staff_leave_types`
- **UI:** Dropdown showing all active leave types, sorted by display_order

### 2.2 `applies_to_role_id` (FK → sch_employee_roles.id)
- **Type:** INT UNSIGNED, Nullable, FK
- **Meaning:** The employee role this policy applies to. NULL means "all roles" (wildcard/catch-all).
- **Examples:** Teacher, Admin, Accountant, Librarian, Counselor, Support Staff
- **Business Logic (Policy Matching):**
  - IF NOT NULL → policy only matches employees with this exact role
  - IF NULL → policy matches any role (acts as a wildcard)
  - The more specific match (non-NULL) is preferred over NULL
- **UI:** Dropdown of all active roles, plus "All Roles" option (which stores NULL)

### 2.3 `applies_to_department_id` (FK → sch_departments.id)
- **Type:** INT UNSIGNED, Nullable, FK
- **Meaning:** The department this policy applies to. NULL means "all departments."
- **Examples:** Science, Mathematics, English, Computer Science, Administration, Finance
- **Business Logic:** Same as role — non-NULL is more specific and takes priority

### 2.4 `applies_to_designation_id` (FK → sch_designations.id)
- **Type:** INT UNSIGNED, Nullable, FK
- **Meaning:** The designation this policy applies to. NULL means "all designations."
- **Examples:** Senior Teacher, Junior Teacher, Head of Department, Principal, Vice Principal
- **Business Logic:** Same as role/department — non-NULL is more specific

### 2.5 `applies_to_employment_type` (ENUM)
- **Type:** ENUM('Permanent','Contract','Temporary','Visiting','Intern','Probation'), Nullable
- **Meaning:** The employment type this policy applies to. NULL means "all employment types."
- **Business Logic:**
  - Used to differentiate leave entitlements by employment contract type
  - Example: Probation employees may have restricted leave
  - Example: Contract employees may not get EL at all
  - NULL = applies to all employment types (wildcard)

### 2.6 `annual_entitlement` (Days Per Year)
- **Type:** DECIMAL(5,2), Required, Default = 0.00
- **Meaning:** The **total number of days** of this leave type granted to the employee per annual session.
- **Business Logic:**
  - This is the base entitlement seeded as `opening_balance` in `sch_employee_leave_balance` at session start
  - For Lump Sum accrual: full amount is granted at session start
  - For Monthly Pro-Rata: this value is divided by 12 for monthly accrual
  - For Quarterly: this value is divided by 4 for quarterly accrual
- **Examples:**
  - CL = 12 days/year (admin), 16 days/year (science teacher)
  - SL = 10 days/year (all)
  - EL = 20 days/year (permanent), 0 days/year (contract)
  - ML = 90 days/year (female employees)
- **Validation:** 0–365 days

### 2.7 `accrual_method` (Accrual Schedule)
- **Type:** ENUM('Lump_Sum','Monthly_Pro_Rata','Quarterly'), Required
- **Meaning:** How the annual entitlement is **released/accrued** to the employee over the session.
- **Detailed Breakdown:**

#### Lump_Sum
- **Meaning:** Full annual entitlement is granted **immediately at the start** of the session (or on joining date, or after offset period)
- **Formula:** `accrued_balance = annual_entitlement` (all at once)
- **Use Case:** Casual Leave, Sick Leave, Maternity Leave — where full year's leave is available from day one
- **Pros:** Simple, predictable
- **Cons:** Employee who joins mid-year gets full entitlement (unless pro-rata is handled separately)

#### Monthly_Pro_Rata
- **Meaning:** Entitlement is **earned in monthly installments**. Each month, 1/12th of the annual entitlement is added to the employee's balance.
- **Formula:** `monthly_accrual = annual_entitlement / 12`
- **Use Case:** Earned Leave (EL) where leave accrues with service
- **Pros:** Fair for mid-year joiners; encourages regular attendance
- **Cons:** Employees with low tenure have less leave available early in the year
- **Edge Case:** If employee joins mid-month, accrual starts from the next full month

#### Quarterly
- **Meaning:** Entitlement is **earned quarterly**. Each quarter, 1/4th of the annual entitlement is added.
- **Formula:** `quarterly_accrual = annual_entitlement / 4`
- **Use Case:** Some schools give leave on a quarterly basis for budgeting purposes
- **Pros:** Less granular than monthly, still pro-rata-friendly

### 2.8 `accrual_start_offset_months` (Accrual Delay)
- **Type:** TINYINT UNSIGNED, Default = 0
- **Meaning:** Number of months **after the employee's joining date** before accrual of this leave type begins.
- **Business Logic:**
  - `accrual_start_date = employee.joining_date + offset_months`
  - If `months_since_joining < offset_months` → `accrued = 0`
  - After offset period, accrual resumes normally (either lump sum or pro-rata)
- **Use Case:** Probation period where certain leave types (EL) are not available during probation
  - If probation is 6 months, set `accrual_start_offset_months = 6`
  - After 6 months, EL starts accruing
- **Validation:** 0–12 months

### 2.9 `is_carry_forwardable` (Override Leave Type)
- **Type:** TINYINT(1), Nullable in config, Default logic = fallback to leave type
- **Meaning:** Override for the leave type's `is_carry_forwardable` flag at the config level.
- **Business Logic (Override Priority):**
  ```
  IF config.is_carry_forwardable IS NOT NULL:
      USE config.is_carry_forwardable
  ELSE:
      USE leave_type.is_carry_forwardable
  ```
- **Use Case:** Even though CL is carry-forwardable by default, for certain roles (probation), the school may want to disable carry-forward. Config override allows this.

### 2.10 `max_carry_forward` (Override Max)
- **Type:** DECIMAL(5,2), Nullable
- **Meaning:** Override for the leave type's `max_carry_forward` at the config level.
- **Override Logic:** Same as above — config value takes precedence over leave type value
- **Validation:** Required if `is_carry_forwardable = true` at config level

### 2.11 `is_encashable_at_separation` (Override Separation Encashment)
- **Type:** TINYINT(1), Nullable in config
- **Meaning:** Override for leave type's `is_encashable_at_separation` at config level.
- **Override Logic:** Config value takes precedence over leave type value

### 2.12 `max_encashable_days` (Override Encashment Cap)
- **Type:** DECIMAL(5,2), Nullable
- **Meaning:** Override for leave type's `max_encashable_days` at config level.
- **Validation:** Required if `is_encashable_at_separation = true` at config level

### 2.13 `available_during_probation` (Probation Access)
- **Type:** TINYINT(1), Default = 0 (false)
- **Meaning:** Whether this leave type is **available to the employee during their probation period**.
- **Business Logic:**
  - IF `available_during_probation = false`:
    - Employee's entitlement for this leave type = 0 during probation
    - Leave application validation blocks submission
    - Balance row is created with zero opening_balance
  - IF `available_during_probation = true`:
    - Employee can take this leave during probation
    - Entitlement is calculated based on `probation_entitlement_pro_rata` flag
- **Use Case:** CL and SL are typically available during probation; EL is typically not

### 2.14 `probation_entitlement_pro_rata` (Probation Pro-Rata)
- **Type:** TINYINT(1), Default = 1 (true)
- **Meaning:** If leave is available during probation, should the entitlement be **pro-rated** based on probation duration?
- **Business Logic:**
  ```
  IF employee.status = 'Probation' AND available_during_probation = true:
      IF probation_entitlement_pro_rata = true:
          entitlement = annual_entitlement × (probation_completed_months / total_probation_months)
          Example: 12 CL × (3 months completed / 6 months probation) = 6 CL
      IF probation_entitlement_pro_rata = false:
          entitlement = annual_entitlement (full entitlement)
      IF probation_entitlement_pro_rata = true AND probation_not_started:
          entitlement = 0
  ```
- **Use Case:** SL is typically available in full during probation; EL is pro-rated

### 2.15 `priority` (Tie-Breaker)
- **Type:** TINYINT UNSIGNED, Default = 10
- **Meaning:** When multiple config rows match an employee's profile, the row with the **lowest priority number** (highest priority) wins.
- **Business Logic:**
  - Priority is only evaluated when **specificity is equal** (same number of matching non-NULL scope fields)
  - Lower number = higher priority
  - If two policies have the same priority and same specificity → system picks any (unstable — should be prevented)
- **Typical Values:**
  - Priority 1–5: Very specific policies (e.g., Teacher + Science + CL)
  - Priority 5–10: Semi-specific policies (e.g., Teacher + CL)
  - Priority 10: Catch-all policies (e.g., All roles + All departments + CL)

### 2.16 `is_active` (Active Status)
- **Type:** TINYINT(1), Boolean, Default = 1
- **Meaning:** Soft enable/disable. Inactive configs are excluded from policy matching.
- **Business Logic:**
  - Only active configs participate in policy matching
  - Inactive configs are hidden from matching but preserved in database

---

## 3. Policy Matching Algorithm (Deep Detail)

### 3.1 Algorithm Overview
```
FUNCTION: Resolve_Leave_Config(employee, leave_type)
    
    Step 1: Gather all active configs for this leave_type
    Step 2: Filter by scope matching
    Step 3: Sort by specificity descending (most specific first)
    Step 4: Among equal specificity, sort by priority ascending
    Step 5: Return first match
    
    If NO match found → return leave_type default settings
```

### 3.2 Scope Matching Rules

For each config row, check each scope dimension:

| Config Field | Match Condition |
|-------------|-----------------|
| `applies_to_role_id` | IS NULL (matches any) OR equals employee's role_id |
| `applies_to_department_id` | IS NULL (matches any) OR equals employee's department_id |
| `applies_to_designation_id` | IS NULL (matches any) OR equals employee's designation_id |
| `applies_to_employment_type` | IS NULL (matches any) OR equals employee's employment_type |

**A row is a candidate ONLY if ALL non-NULL scope fields match the employee.**

### 3.3 Specificity Scoring

Specificity = count of non-NULL scope fields (higher = more specific)

| Non-NULL Fields | Specificity Score | Example |
|----------------|-------------------|---------|
| None (all NULL) | 0 | Applies to ALL employees (catch-all) |
| Role only | 1 | Applies to all Teachers |
| Role + Department | 2 | Applies to Teachers in Science |
| Role + Department + Designation | 3 | Applies to Senior Teachers in Science |
| Role + Department + Designation + Emp Type | 4 | Applies to Permanent Senior Teachers in Science |

### 3.4 Sort & Winner Selection
```
Sorted Order:
1. Highest specificity first
2. Among same specificity: lowest priority number first
3. First = winner
```

### 3.5 Complete Example

**Employee:** John Doe  
- Role: Teacher (role_id=5)  
- Department: Science (dept_id=3)  
- Designation: Senior Teacher (desig_id=8)  
- Employment Type: Permanent  
- Leave Type: CL (leave_type_id=1)  

**Available Configs:**

| Config | Role | Dept | Desig | EmpType | Entitlement | Priority | Spec |
|--------|------|------|-------|---------|-------------|----------|------|
| A | NULL | NULL | NULL | NULL | 12 | 10 | 0 |
| B | Teacher | NULL | NULL | NULL | 14 | 5 | 1 |
| C | Teacher | Science | NULL | NULL | 16 | 1 | 2 |
| D | Teacher | Science | SrTchr | NULL | 18 | 1 | 3 |
| E | Teacher | Science | NULL | Permanent | 17 | 2 | 3 |
| F | Admin | NULL | NULL | NULL | 10 | 5 | 1 |

**Matching Candidates:**
- A: All NULL → matches → Spec=0, Priority=10, Ent=12
- B: Teacher matches → Spec=1, Priority=5, Ent=14
- C: Teacher+Science matches → Spec=2, Priority=1, Ent=16
- D: Teacher+Science+SrTchr matches → Spec=3, Priority=1, Ent=18
- E: Teacher+Science+Permanent matches → Spec=3, Priority=2, Ent=17
- F: Admin doesn't match → excluded

**Sorted (Spec desc, Priority asc):**
1. D (Spec=3, Pri=1) → **WINNER: 18 CL days**
2. E (Spec=3, Pri=2) → Overridden
3. C (Spec=2, Pri=1) → Overridden
4. B (Spec=1, Pri=5) → Overridden
5. A (Spec=0, Pri=10) → Overridden

**Result:** John gets 18 CL days per year.

---

## 4. Accrual Calculations (Deep Detail)

### 4.1 Lump Sum
```
At session start (or after offset):
    accrued = annual_entitlement
    
At any point during year:
    available = accrued - used - pending
```

### 4.2 Monthly Pro-Rata
```
monthly_increment = annual_entitlement / 12

On each month anniversary (from joining or offset start):
    accrued += monthly_increment
    
At any point:
    accrued = monthly_increment × completed_months
    
Example: 20 EL/year, joined April, in August:
    accrued = 20/12 × 4 = 6.67 days
```

### 4.3 Quarterly
```
quarterly_increment = annual_entitlement / 4

On each quarter completion:
    accrued += quarterly_increment
    
Example: 20 EL/year, Q2 completed:
    accrued = 20/4 × 2 = 10 days
```

### 4.4 Accrual Start Offset
```
IF months_since_joining < accrual_start_offset_months:
    accrued = 0
ELSE:
    effective_start = joining_date + accrual_start_offset_months
    Accrual begins from effective_start
    
Example: EL, offset=6 months, joined Jan 1:
    Jan-Jun: no EL accrual
    Jul onwards: EL starts accruing monthly
    By Dec: 20/12 × 6 = 10 EL accrued
```

### 4.5 Probation Entitlement
```
LET probation_start = employee.joining_date
LET probation_end = employee.probation_end_date
LET total_probation_months = months_between(probation_start, probation_end)
LET elapsed_probation_months = months_between(probation_start, NOW())

IF employee.status = 'Probation':
    IF NOT config.available_during_probation:
        entitlement = 0
    ELSE IF config.probation_entitlement_pro_rata:
        entitlement = round(annual_entitlement × (elapsed_probation_months / total_probation_months), 1)
    ELSE:
        entitlement = annual_entitlement
ELSE:
    entitlement = annual_entitlement (standard)
```

---

## 5. Carry-Forward & Encashment Override Resolution

### 5.1 Override Priority Chain
```
For any carry-forward or encashment setting:

1. CHECK: Is there a value in sch_staff_leave_config for this field?
   - If YES (NOT NULL) → USE config value
   - If NO (NULL) → Go to step 2

2. CHECK: Is there a value in sch_staff_leave_types for this field?
   - If YES → USE leave type value
   - If NO → USE system default (false/0)

This allows config to override leave type settings when needed.
```

### 5.2 Example Override Scenarios
```
Scenario 1: CL leave_type has is_carry_forwardable=true, max_carry_forward=5
    Config for Teachers: is_carry_forwardable=NULL (no config override)
    → Teachers use CL's default: carry-forwardable=true, max=5

Scenario 2: CL has is_carry_forwardable=true
    Config for Probation employees: is_carry_forwardable=false
    → Probation employees: carry-forwardable=false (overridden)
```

---

## 6. Validation Rules Matrix

| Field | Required | Constraints |
|-------|----------|-------------|
| leave_type_id | Yes | Must exist in sch_staff_leave_types, must be active |
| applies_to_role_id | No | Must exist in sch_employee_roles if provided |
| applies_to_department_id | No | Must exist in sch_departments if provided |
| applies_to_designation_id | No | Must exist in sch_designations if provided |
| applies_to_employment_type | No | Must be valid ENUM value if provided |
| annual_entitlement | Yes | 0–365, numeric |
| accrual_method | Yes | Must be Lump_Sum, Monthly_Pro_Rata, or Quarterly |
| accrual_start_offset_months | No | 0–12, integer |
| is_carry_forwardable (override) | No | Boolean (NULL = use leave type default) |
| max_carry_forward | Conditional | Required if override is_carry_forwardable=true, > 0 |
| is_encashable_at_separation (override) | No | Boolean (NULL = use leave type default) |
| max_encashable_days | Conditional | Required if override encashable=true, > 0 |
| available_during_probation | Yes | Boolean, default false |
| probation_entitlement_pro_rata | Yes | Boolean, default true |
| priority | Yes | 1–100, lower = higher priority |
| is_active | Yes | Boolean, default true |

---

## 7. Cross-Field & Unique Validation Rules

### Rule 1: Unique Combination
```
The combination of (leave_type_id + applies_to_role_id + applies_to_department_id + applies_to_designation_id + applies_to_employment_type) MUST be unique.

If a row with the exact same combination already exists:
    → Error: "A leave configuration with this combination already exists"
```

### Rule 2: Scope Conflict Warning
```
If NO active employees match the scope combination:
    → Warning: "No active employees match this scope combination. Policy will never be applied."
```

### Rule 3: Catch-All Warning
```
If ALL scope fields are NULL (applies to everyone):
    → Info: "This policy applies to ALL employees as a catch-all fallback"
```

### Rule 4: Priority Conflict Suggestion
```
When saving with a priority number:
    Check existing priorities for matching scope
    If conflicting priorities exist:
    → Suggestion: "Consider priority {available_range} for this scope combination"
```

### Rule 5: Override Consistency
```
IF is_carry_forwardable override is set to true:
    THEN max_carry_forward SHOULD be set (warning if not)

IF is_carry_forwardable override is set to false:
    THEN max_carry_forward SHOULD be NULL (clear it)
```

---

## 8. Balance Seeding Logic

When an employee is created or a new session starts, `LeaveBalanceService` seeds balance records:

```
FUNCTION: Seed_Balances_For_Employee(employee, session)
    
    FOR EACH active leave_type:
        config = Resolve_Leave_Config(employee, leave_type)
        
        IF config is null:
            CONTINUE (no entitlement for this leave type)
        
        IF probation check fails (available_during_probation = false AND employee in probation):
            opening_balance = 0
        ELSE:
            opening_balance = config.annual_entitlement
            (adjusted for pro-rata if applicable)
        
        CREATE balance record:
            employee_id = employee.id
            session_id = session.id
            leave_type_id = leave_type.id
            opening_balance = computed_value
            carry_forward = 0 (new balance)
            total_used = 0
            total_pending = 0
            manual_adjustment = 0
```

---



## Related Documents
- [SR-EM-05-TAB1](./SR-EM-05-TAB1-Staff_Leave_Types.md) — Leave types referenced by config
- [SR-EM-05-TAB6](./SR-EM-05-TAB6-Employee_Leave_Balance.md) — Balance seeded from these configs
- [SR-EM-05](./SR-EM-05-Leave_Configuration.md) — Leave Configuration module overview
