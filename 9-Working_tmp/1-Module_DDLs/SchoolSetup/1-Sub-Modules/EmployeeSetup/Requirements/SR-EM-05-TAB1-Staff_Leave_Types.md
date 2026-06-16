# Screen Requirement: Staff Leave Types (Deep Requirements)
## Document ID: SR-EM-05-TAB1
**Module:** SchoolSetup / EmployeeSetup  
**Screen Name:** Leave Configuration > Staff Leave Types (Tab 1)  
**Route:** `school-setup.leave-config?tab=staff-leave-types`  
**User Role:** School Administrator, HR Manager  
**Priority:** P0 (Critical)  
**Status:** Approved for Development  

---

## 1. Screen Overview & Business Purpose

### 1.1 Purpose
This screen manages the **master catalog of leave categories** that the school offers to its staff. Each leave type defines the fundamental rules — whether it is paid/unpaid, requires documentation, allows half-day, can be carried forward, etc. These rules cascade down to leave applications, balance calculations, and payroll.

### 1.2 Business Context
Schools in India typically offer 6–12 leave types. Common examples:
- **CL (Casual Leave)** — Short-duration personal leave, paid, carry-forwardable up to 5–10 days
- **SL (Sick Leave)** — Medical leave, paid, requires medical certificate if > 2 days
- **EL (Earned Leave / Privilege Leave)** — Leave that accrues with service, paid, carry-forwardable
- **ML (Maternity Leave)** — 90 days paid leave for female employees
- **PL (Paternity Leave)** — 15 days paid leave for male employees
- **LWP (Leave Without Pay)** — Unpaid leave when all paid leave is exhausted
- **COMP (Compensatory Off)** — Compensatory leave for working on holidays/weekends
- **RH (Restricted Holiday)** — Optional holiday that employee can choose

### 1.3 Key Capabilities
- Create/edit/delete leave type definitions
- Configure paid/unpaid, carry-forward, encashment rules
- Set documentation requirements per leave type
- Define application constraints (min/max days, advance notice, consecutive days)
- System leave types are protected from deletion
- Visual customization via color hex for calendar displays

---

## 2. Complete Field Definitions (Deep Detail)

### 2.1 `code` (Unique Identifier)
- **Type:** VARCHAR(20), UNIQUE, Required
- **Meaning:** Short alphanumeric code that uniquely identifies the leave type. Used in reports, payslips, and system-wide references.
- **Convention:** Always uppercase, 2–6 characters. Examples: CL, SL, EL, ML, PL, LWP, COMP, RH.
- **Validation Rules:**
  - Must be 2–20 characters long
  - Must be uppercase alphabetic only (A–Z)
  - Underscores and hyphens are NOT allowed
  - Must be unique across all leave types (case-insensitive comparison)
  - Cannot be changed after creation if `is_system = true`
- **UI Behavior:** Auto-uppercase input on keyup; uniqueness check via AJAX on blur
- **Error Scenario:** If duplicate code entered → "Leave type code 'CL' already exists in the system"

### 2.2 `name` (Display Name)
- **Type:** VARCHAR(100), Required
- **Meaning:** Human-readable display name shown in all dropdowns, reports, screens, and notifications.
- **Examples:** "Casual Leave", "Sick Leave", "Earned Leave", "Maternity Leave", "Leave Without Pay"
- **Validation Rules:**
  - Required, max 100 characters
  - Special characters allowed (apostrophes, hyphens, parentheses)
  - Should be unique per organization (preferred, not enforced)
- **UI Behavior:** Shown as the primary label in all leave-related screens

### 2.3 `description` (Long Description)
- **Type:** VARCHAR(500), Optional
- **Meaning:** Free-text field to describe the leave policy, eligibility criteria, special conditions, or any HR notes about this leave type.
- **Usage:** Shown as a tooltip or help-text on the leave application form. Helps employees understand when to use this leave type.
- **Example:** "Casual Leave is for short, personal reasons such as family events, appointments, or personal errands. Must be approved by reporting manager."

### 2.4 `is_paid` (Paid/Unpaid Flag)
- **Type:** TINYINT(1), Boolean, Default = 1 (true)
- **Meaning:** Determines whether leave taken under this type is paid (salary deducted or not).
  - **1 (true)** = Paid Leave: Employee receives full salary for leave days
  - **0 (false)** = Unpaid Leave (Loss of Pay): Salary deducted for leave days
- **Business Logic:**
  - If `is_paid = false` (LWP type), payroll engine deducts `total_days × daily_rate` from salary
  - If `is_paid = true`, no salary deduction for approved leave days
  - This flag is the single most important payroll-control for leave types
- **Standard Types:** CL=Yes, SL=Yes, EL=Yes, ML=Yes, PL=Yes, LWP=No, COMP=Yes

### 2.5 `is_carry_forwardable` (Carry-Forward Eligibility)
- **Type:** TINYINT(1), Boolean, Default = 0 (false)
- **Meaning:** Determines whether any **unused balance** of this leave type at year-end can be **carried forward** to the next annual session.
  - **1 (true):** Unused days roll over to next year (subject to `max_carry_forward` cap)
  - **0 (false):** Unused days lapse at year-end (use-it-or-lose-it)
- **Business Logic:**
  - At year-end rollover (handled by `LeaveRolloverService`):
    - IF `is_carry_forwardable = true`:
      - `carry_forward = MIN(remaining_balance, max_carry_forward)`
      - If `max_carry_forward = NULL` (unlimited): `carry_forward = remaining_balance`
    - IF `is_carry_forwardable = false`:
      - `carry_forward = 0` (all remaining balance expires)
  - This can be overridden by `sch_staff_leave_config` at the role/department level
- **Standard Types:** CL=Yes (capped at 5–10 days), SL=No, EL=Yes (capped at 10–15 days), ML=No, PL=No, LWP=No

### 2.6 `max_carry_forward` (Carry-Forward Cap)
- **Type:** DECIMAL(5,2), Nullable
- **Meaning:** Maximum number of days that can be carried forward. NULL means **unlimited** carry-forward.
- **Business Logic:**
  - Only relevant when `is_carry_forwardable = true`
  - If NULL → no cap on carry-forward
  - If set to value → carry_forward is capped: `carry_forward = MIN(available_balance, max_carry_forward)`
  - Example: If CL has `max_carry_forward = 10` and employee has 15 unused days → only 10 carry forward, 5 lapse
- **Validation Rules:**
  - Required if `is_carry_forwardable = true`
  - Must be > 0 if provided
  - Max value: 365 days
- **Edge Case:** If `max_carry_forward` is set to 0, effectively no carry-forward even though flag is true

### 2.7 `is_encashable` (Year-End Encashment)
- **Type:** TINYINT(1), Boolean, Default = 0 (false)
- **Meaning:** Determines whether unused leave can be **paid out (encashed)** at the end of the year/ session rather than carried forward.
- **Business Logic:**
  - If `is_encashable = true`:
    - At year-end, employee can choose (or auto-encash) unused balance
    - Encashment amount = `unused_days × daily_salary_rate`
    - Encashed days are then deducted from balance (cannot also be carried forward)
  - Typically applies to EL (Earned Leave) in many Indian schools
- **Note:** This is different from `is_encashable_at_separation` which applies at resignation/retirement

### 2.8 `is_encashable_at_separation` (Separation Encashment)
- **Type:** TINYINT(1), Boolean, Default = 0 (false)
- **Meaning:** Determines whether unused leave balance can be **paid out** when the employee **resigns, retires, or is terminated**.
- **Business Logic:**
  - During full & final (F&F) settlement:
    - IF `is_encashable_at_separation = true`:
      - `encashable_days = MIN(available_balance, max_encashable_days)` (if cap exists)
      - `encashment_amount = encashable_days × daily_rate`
    - Government regulations: EL is mandatorily encashable at retirement
- **Standard Types:** EL=Yes, CL=No, SL=No, ML=No

### 2.9 `max_encashable_days` (Encashment Cap at Separation)
- **Type:** DECIMAL(5,2), Nullable
- **Meaning:** Maximum number of days that can be encashed at separation for this leave type.
- **Validation Rules:**
  - Required if `is_encashable_at_separation = true`
  - Must be > 0 if provided
  - NULL = unlimited encashment
- **Example:** If EL has `max_encashable_days = 30` and employee has 45 unused EL days → only 30 are encashable

### 2.10 `requires_doc` (Documentation Requirement)
- **Type:** TINYINT(1), Boolean, Default = 0 (false)
- **Meaning:** Whether the employee **must upload a supporting document** when applying for this leave.
  - **1 (true):** Document upload is mandatory on the leave application form
  - **0 (false):** Document upload is optional or not needed
- **Business Logic:**
  - If `requires_doc = true` AND `min_doc_required_days` is set:
    - Doc is only mandatory when `total_days > min_doc_required_days`
    - Example: SL with `requires_doc = true`, `min_doc_required_days = 2` → For 1-day SL, doc is optional; for 3-day SL, doc is mandatory
  - If `requires_doc = true` AND `min_doc_required_days = NULL`:
    - Doc is mandatory for ALL applications of this leave type
- **Standard Types:** SL=Yes (medical certificate for > 2 days), CL=No, EL=No

### 2.11 `min_doc_required_days` (Document Threshold)
- **Type:** TINYINT UNSIGNED, Nullable
- **Meaning:** The minimum number of leave days beyond which document upload becomes mandatory.
- **Conditional Logic:**
  - Only applicable when `requires_doc = true`
  - If NULL → document is always required regardless of duration
  - If set to 2 → document is only required when applying for more than 2 days
- **Example:** `min_doc_required_days = 2` for SL means: 1-day sick leave = no doc needed; 3-day sick leave = medical certificate required

### 2.12 `requires_substitute` (Substitute Teacher Flag)
- **Type:** TINYINT(1), Boolean, Default = 0 (false)
- **Meaning:** Whether applying for this leave should trigger an **automatic substitute teacher assignment workflow** for teachers.
- **Business Logic:**
  - When a teacher applies for leave with `requires_substitute = true`:
    - The system auto-creates a substitute request in the timetable module
    - The timetable admin or system assigns a substitute teacher for the affected classes/periods
    - Employee's classes during the leave period get auto-marked as "Needs Substitute"
  - Typically true for CL, SL, EL (teacher cannot leave classes unattended)
  - Typically false for ML, PL (planned long leaves where substitute is arranged separately)
- **Note:** Only relevant for employees where `is_teacher = true`

### 2.13 `allows_half_day` (Half-Day Applications)
- **Type:** TINYINT(1), Boolean, Default = 1 (true)
- **Meaning:** Whether employees can apply for **half-day leave** (0.5 day) using this leave type.
- **Business Logic:**
  - If `allows_half_day = true`:
    - Leave application form shows "Half Day" toggle/slot selector
    - Employee selects Morning or Afternoon slot for the half day
    - `total_days` = 0.5 (consumes 0.5 from balance)
  - If `allows_half_day = false`:
    - Half-day option is hidden; minimum application is 1 full day
    - `min_days_per_application` should be >= 1
- **Standard Types:** CL=Yes, SL=Yes, EL=No, ML=No, PL=No, LWP=No

### 2.14 `allows_back_dated` (Back-Dated Applications)
- **Type:** TINYINT(1), Boolean, Default = 0 (false)
- **Meaning:** Whether employees can apply for leave with a `from_date` that is **in the past** (back-dated).
- **Business Logic:**
  - If `allows_back_dated = true`:
    - Employee can select a `from_date` that is before today's date
    - Typically allowed for SL (emergency sick leave applied after recovering)
    - System should show a warning: "Back-dated leaves require verification"
  - If `allows_back_dated = false`:
    - `from_date` must be >= today (or >= today + `min_advance_notice_days`)
    - Fields like `is_emergency` can bypass this for same-day applications
  - Back-dated limit: max 2–7 days in the past (configurable per school)
- **Standard Types:** SL=Yes (max 2 days back-dated), CL=No, EL=No

### 2.15 `requires_approval` (Approval Requirement)
- **Type:** TINYINT(1), Boolean, Default = 1 (true)
- **Meaning:** Whether leave applications of this type **require approval workflow** or are **auto-approved** on submission.
- **Business Logic:**
  - If `requires_approval = true`:
    - Leave application goes through the matching approval policy workflow
    - Application status: Submitted → Under Review → Approved/Rejected
  - If `requires_approval = false`:
    - Leave is **auto-approved** immediately on submission
    - Status goes directly: Submitted → Approved
    - Balance is updated immediately
    - Used for system-level leaves or leaves that don't need approval (e.g., RH, Comp-off)
- **Standard Types:** CL=Yes, SL=Yes, EL=Yes, ML=Yes, PL=Yes, LWP=Yes, COMP=No (auto)

### 2.16 `min_days_per_application` (Minimum Days Per Application)
- **Type:** DECIMAL(4,1), Default = 0.5, Required
- **Meaning:** The **minimum duration** an employee can apply for in a single leave application.
- **Business Logic:**
  - If `allows_half_day = true`: minimum can be 0.5 (half day)
  - If `allows_half_day = false`: minimum should be 1.0
  - Form validation: `total_days >= min_days_per_application`
  - Can be fractional (0.5, 1.0, 1.5, etc.)
- **Validation Rules:**
  - Must be >= 0.5
  - Must be <= `max_days_per_application` (if max_days is set)
  - Max value: 365

### 2.17 `max_days_per_application` (Maximum Days Per Application)
- **Type:** DECIMAL(4,1), Nullable
- **Meaning:** The **maximum duration** an employee can apply for in a single leave application. NULL = unlimited.
- **Business Logic:**
  - Used to cap how many days can be applied at once
  - Example: ML may have `max_days_per_application = 90`
  - Form validation: `total_days <= max_days_per_application`
  - If both `max_days_per_application` and `max_consecutive_days` are set → **stricter wins** (lower value applies)
- **Validation Rules:**
  - If set, must be >= `min_days_per_application`
  - If set, max value: 365
  - NULL = no upper limit per application

### 2.18 `min_advance_notice_days` (Advance Notice Requirement)
- **Type:** TINYINT UNSIGNED, Default = 0, Nullable
- **Meaning:** The number of days **before the leave start date** that the employee must submit the application.
- **Business Logic:**
  - `earliest_start_date = today + min_advance_notice_days`
  - Form validation: `from_date >= (today + min_advance_notice_days)`
  - If `min_advance_notice_days = 0`: Can apply on the same day
  - If `is_emergency = true`: This validation is bypassed (emergency same-day leave)
  - Example: CL with `min_advance_notice_days = 1` → must apply at least 1 day before leave starts
- **Standard Types:** CL=1, SL=0 (can apply same day for sickness), EL=15 (planned leave), ML=0, PL=0

### 2.19 `max_consecutive_days` (Maximum Consecutive Days)
- **Type:** TINYINT UNSIGNED, Nullable
- **Meaning:** Maximum number of **contiguous calendar days** (including weekends/holidays between) that an employee can take in one stretch for this leave type.
- **Business Logic:**
  - If `max_consecutive_days = 30` for SL → cannot apply SL for more than 30 consecutive days
  - If NULL → no limit on consecutive days
  - If `max_days_per_application` is also set → the stricter of the two applies
- **Use Case:** Some leave types are meant for short durations (CL) while others allow long stretches (ML up to 90 days)

### 2.20 `display_order` (Sort Order)
- **Type:** TINYINT UNSIGNED, Default = 100
- **Meaning:** Controls the **sort order** of leave types in dropdowns, lists, and reports.
- **Business Logic:**
  - Lower numbers appear first
  - If two types have same order → alphabetical sort by name
  - Typical ordering: CL(1), SL(2), EL(3), ML(4), PL(5), LWP(6), COMP(7)
- **Validation:** 0–9999

### 2.21 `color_hex` (Calendar Color)
- **Type:** VARCHAR(7), Nullable
- **Meaning:** Hex color code used to **visually distinguish** leave types on the calendar UI, Gantt charts, and attendance dashboards.
- **Format:** Must match `#RRGGBB` pattern (e.g., `#FFD700` for CL, `#FF6B6B` for SL)
- **Validation Rules:**
  - If provided, must be valid hex color format: `/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/`
  - NULL = use system default color
- **Standard Colors:**
  - CL = #FFD700 (Gold)
  - SL = #FF6B6B (Red)
  - EL = #4ECDC4 (Teal)
  - ML = #FF69B4 (Pink)
  - PL = #87CEEB (Sky Blue)
  - LWP = #808080 (Grey)
  - COMP = #98FB98 (Pale Green)

### 2.22 `is_system` (System Protection Flag)
- **Type:** TINYINT(1), Boolean, Default = 0 (false)
- **Meaning:** Marks a leave type as **system-defined** (built-in). System leave types **cannot be deleted or have their core identity fields changed** by users.
- **Business Logic:**
  - If `is_system = true`:
    - Delete button is disabled/hidden in UI
    - Edit form disables code, name fields
    - User cannot set `is_system = true` for new types (only system/seeding scripts can)
  - If `is_system = false`: Fully user-manageable
  - When `trying to delete system type` → "System protected leave types cannot be deleted"
- **Protected System Types Typically:** CL, SL, EL, ML, PL, LWP (default school-mandated types)

### 2.23 `is_active` (Active Status)
- **Type:** TINYINT(1), Boolean, Default = 1 (true)
- **Meaning:** Soft enable/disable flag. Inactive leave types are **hidden** from new leave applications but remain for **historical records**.
- **Business Logic:**
  - IF `is_active = false`:
    - Leave type not shown in "New Leave Application" dropdown
    - Cannot be referenced in new leave configs
    - Existing applications/balances referencing this type remain unaffected
  - Used to retire old leave types without deleting historical data

### 2.24 Audit Fields
- `created_by`: INT UNSIGNED, FK to `sys_users.id` — Who created this leave type
- `created_at`: TIMESTAMP — When created
- `updated_at`: TIMESTAMP — Last updated timestamp (auto-updates)
- `deleted_at`: TIMESTAMP, Nullable — Soft delete timestamp (null = active)

---

## 3. Complete Validation Rules Matrix

| Field | Required | Type | Constraints | Error Message |
|-------|----------|------|-------------|---------------|
| code | Yes | String(20) | Uppercase A-Z, unique | "Leave type code is required and must be unique" |
| name | Yes | String(100) | Non-empty | "Leave type name is required" |
| description | No | String(500) | — | — |
| is_paid | Yes | Boolean | Default true | "Must specify paid/unpaid" |
| is_carry_forwardable | Yes | Boolean | Default false | — |
| max_carry_forward | Conditional | Decimal(5,2) | > 0, max 365; required if carry_forwardable=true | "Max carry forward required when carry-forward is enabled" |
| is_encashable | Yes | Boolean | Default false | — |
| is_encashable_at_separation | Yes | Boolean | Default false | — |
| max_encashable_days | Conditional | Decimal(5,2) | > 0; required if encashable_at_separation=true | "Max encashable days required when encashable at separation" |
| requires_doc | Yes | Boolean | Default false | — |
| min_doc_required_days | No | Integer | >= 1; only relevant if requires_doc=true | — |
| requires_substitute | Yes | Boolean | Default false | — |
| allows_half_day | Yes | Boolean | Default true | — |
| allows_back_dated | Yes | Boolean | Default false | — |
| requires_approval | Yes | Boolean | Default true | — |
| min_days_per_application | Yes | Decimal(4,1) | >= 0.5 | "Minimum must be at least 0.5 days" |
| max_days_per_application | No | Decimal(4,1) | >= min_days, max 365 | "Maximum must be >= minimum days" |
| min_advance_notice_days | No | Integer | >= 0 | "Advance notice must be >= 0" |
| max_consecutive_days | No | Integer | >= 1 | "Consecutive days must be >= 1" |
| display_order | No | Integer | 0–9999 | — |
| color_hex | No | String(7) | Regex: #RGB or #RRGGBB | "Color must be a valid hex code" |
| is_system | Yes | Boolean | Cannot be set to true by user | "Cannot create system leave type" |
| is_active | Yes | Boolean | Default true | — |

---

## 4. Cross-Field Business Rules

### Rule 1: Carry-Forward Dependency
```
IF is_carry_forwardable = true:
    THEN max_carry_forward must be >= 0 (NULL = unlimited)
    
IF is_carry_forwardable = false:
    THEN max_carry_forward should be NULL (ignored)
```

### Rule 2: Encashment Dependency
```
IF is_encashable_at_separation = true:
    THEN max_encashable_days must be >= 0 (NULL = unlimited)
    
IF is_encashable_at_separation = false:
    THEN max_encashable_days should be NULL (ignored)
```

### Rule 3: Documentation Threshold Logic
```
IF requires_doc = true:
    THEN min_doc_required_days is OPTIONAL
        - If set: doc required only when total_days > min_doc_required_days
        - If NULL: doc always required
    
IF requires_doc = false:
    THEN min_doc_required_days should be NULL (ignored)
```

### Rule 4: Half-Day & Minimum Days
```
IF allows_half_day = true:
    THEN min_days_per_application can be 0.5
    
IF allows_half_day = false:
    THEN min_days_per_application must be >= 1.0
    (Recommendation: set min_days_per_application = 1.0)
```

### Rule 5: Maximum Days Conflict Resolution
```
IF both max_days_per_application AND max_consecutive_days are set:
    THEN apply the STRICTER (lower value) of the two
```

### Rule 6: Advance Notice & Emergency Override
```
IF min_advance_notice_days > 0:
    THEN from_date must be >= (submission_date + min_advance_notice_days)
    EXCEPTION: IF is_emergency = true on the application:
        THEN advance notice validation is BYPASSED
```

### Rule 7: System Leave Type Protection
```
IF is_system = true:
    - Cannot delete (delete button disabled)
    - Cannot change code or name
    - Cannot toggle is_system to false
    - Can still toggle is_active
```

### Rule 8: Delete Protection
```
BEFORE deleting a leave type:
    CHECK: Are there any leave applications referencing this type?
    CHECK: Are there any leave balances referencing this type?
    CHECK: Are there any leave configs referencing this type?
    If YES to any: Block deletion → "Cannot delete leave type with existing refs"
    
Action: Instead of delete, SET is_active = false to retire it
```

---

## 5. Standard Leave Type Templates (Indian Schools)

### Casual Leave (CL)
```
Paid = true | Carry-Forwardable = true | Max Carry-Forward = 5
Half-Day = true | Back-Dated = false | Requires Approval = true
Min Days = 0.5 | Max Days = NULL | Advance Notice = 1 day
Max Consecutive = NULL | Requires Substitute = true (for teachers)
```

### Sick Leave (SL)
```
Paid = true | Carry-Forwardable = false | Max Carry-Forward = NULL
Half-Day = true | Back-Dated = true | Requires Doc = true
Min Doc Days = 2 | Requires Approval = true
Min Days = 0.5 | Max Days = NULL | Advance Notice = 0
Max Consecutive = 30 | Requires Substitute = true (for teachers)
```

### Earned Leave / Privilege Leave (EL)
```
Paid = true | Carry-Forwardable = true | Max Carry-Forward = 10
Encashable at Separation = true | Max Encashable = 30
Half-Day = true | Back-Dated = false | Requires Approval = true
Min Days = 1 | Max Days = NULL | Advance Notice = 15 days
Max Consecutive = 30 | Requires Substitute = true (for teachers)
```

### Maternity Leave (ML)
```
Paid = true | Carry-Forwardable = false
Half-Day = false | Back-Dated = false | Requires Approval = true
Min Days = 1 | Max Days = 90 | Advance Notice = 0
Max Consecutive = 90 | Requires Substitute = false
```

### Paternity Leave (PL)
```
Paid = true | Carry-Forwardable = false
Half-Day = false | Back-Dated = false | Requires Approval = true
Min Days = 1 | Max Days = 15 | Advance Notice = 0
Max Consecutive = 15 | Requires Substitute = false
```

### Leave Without Pay (LWP)
```
Paid = false | Carry-Forwardable = false
Half-Day = false | Back-Dated = false | Requires Approval = true
Min Days = 1 | Max Days = NULL | Advance Notice = 0
Max Consecutive = NULL | Requires Substitute = true (for teachers)
```

### Compensatory Off (COMP)
```
Paid = true | Carry-Forwardable = true | Max Carry-Forward = 30
Half-Day = false | Back-Dated = true | Requires Approval = false (auto-approve)
Min Days = 1 | Max Days = NULL | Advance Notice = 0
Max Consecutive = NULL | Requires Substitute = false
```

---

## 6. Screen States & Transitions

### 6.1 List View
- Default sort: `display_order ASC, name ASC`
- Search: Search by code or name (partial match)
- Filters: Active/Inactive/All
- Pagination: 10 items per page
- Actions per row: View, Edit, Delete (disabled for system types)

### 6.2 Create Form
- All fields editable as per rules above
- Fields disabled conditionally based on other field values
- Can set `is_system = false` only (system types are seeded by backend)

### 6.3 Edit Form
- Same as create, but fields pre-populated
- If `is_system = true`: code, name fields are disabled
- If `is_system = true`: cannot set `is_system = false`

### 6.4 View Detail
- Read-only display of all fields
- Shows related configs count, balance count, application count

### 6.5 Delete → Soft Delete
- Sets `is_active = false`
- Sets `deleted_at = NOW()`
- Record is hidden from all active lists
- Can be restored from Trash

---

## 7. Relationship Map

This table is referenced by:
- **sch_staff_leave_config** → `leave_type_id` (FK) — Role-based entitlement configuration
- **sch_leave_approval_policies** → `applies_to_leave_type_id` (FK) — Approval policy scoping
- **sch_employee_leave_applications** → `leave_type_id` (FK) — Every leave application
- **sch_employee_leave_balance** → `leave_type_id` (FK) — Per-type leave balance tracking

---



## Related Documents
- [SR-EM-05-TAB2](./SR-EM-05-TAB2-Staff_Leave_Config.md) — Leave entitlements referencing these types
- [SR-EM-05-TAB6](./SR-EM-05-TAB6-Employee_Leave_Balance.md) — Balance tracking per leave type
- [SR-EM-05](./SR-EM-05-Leave_Configuration.md) — Leave Configuration module overview
