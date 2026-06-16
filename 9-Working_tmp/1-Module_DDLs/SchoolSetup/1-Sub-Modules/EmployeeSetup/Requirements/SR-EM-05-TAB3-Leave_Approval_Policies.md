# Screen Requirement: Leave Approval Policies (Deep Requirements)
## Document ID: SR-EM-05-TAB3
**Module:** SchoolSetup / EmployeeSetup  
**Screen Name:** Leave Configuration > Leave Approval Policies (Tab 3)  
**Route:** `school-setup.leave-config?tab=approval-policies`  
**User Role:** School Administrator, HR Manager  
**Priority:** P1 (High)  
**Status:** Approved for Development  

---

## 1. Screen Overview & Business Purpose

### 1.1 Purpose
This screen defines the **approval policy masters** that determine **which approval pipeline (chain of approvers)** a leave application must go through before being approved. Policies can be scoped by employee role, department, designation, and/or leave type, with **priority-based matching** similar to Staff Leave Config.

### 1.2 Business Context
Different employee categories require different approval chains:
- **Teachers:** Reporting Manager → Department Head → Principal
- **Admin Staff:** Reporting Manager → HR Manager
- **Principal's leave:** Board of Management (special policy)
- **Short leaves (CL/SL):** 1–2 level approval
- **Long leaves (ML/EL):** 3+ level approval with escalation

### 1.3 Key Concepts
- **Policy Matching:** Same specificity-based matching as Staff Leave Config (most-specific wins)
- **Policy Pipeline:** Each policy has 1+ levels (defined in TAB4), each level has 1+ approvers (defined in TAB5)
- **Scope Dimensions:** Role, Department, Designation, Leave Type — all optional (NULL = wildcard)
- **Fallback:** If no policy matches → leave requires no approval (auto-approved) or admin manually assigns

---

## 2. Complete Field Definitions (Deep Detail)

### 2.1 `name` (Policy Display Name)
- **Type:** VARCHAR(150), Required, Unique
- **Meaning:** Human-readable name for the approval policy. Shown in dropdowns, list views, and the leave application workflow.
- **Form Control / UI Element:** Text Input (with standard text layout)
- **Label:** Policy Name
- **Placeholder:** e.g., Primary Teacher Leave Policy
- **Validation Rules:** 
  - `required|string|max:150|unique:sch_leave_approval_policies,name` (ignore on update)
  - Must not contain special characters except spaces, hyphens, and parentheses
- **UI Behavior:** Character counter (showing X/150). Real-time uniqueness verification via debounced AJAX API check on input change.
- **Error Scenario:** 
  - If blank on submit → "The policy name field is required."
  - If name exists in DB → "An approval policy with this name already exists."
  - If > 150 characters → "The policy name must not exceed 150 characters."
- **Examples:** "Default School Policy", "Teacher Leave Policy", "Admin Leave Policy", "Principal Leave Policy"

### 2.2 `description` (Policy Description)
- **Type:** VARCHAR(500), Optional
- **Meaning:** Free-text description of the policy's purpose, scope, and special conditions.
- **Form Control / UI Element:** Textarea (rows = 3)
- **Label:** Policy Description
- **Placeholder:** e.g., Standard 3-level approval chain for all primary school teaching staff.
- **Validation Rules:** `nullable|string|max:500`
- **UI Behavior:** Characters remaining counter (showing remaining count down from 500).
- **Error Scenario:** If > 500 characters → "The policy description must not exceed 500 characters."

### 2.3 `applies_to_role_id` (FK → sys_roles.id)
- **Type:** INT UNSIGNED, Nullable, FK
- **Meaning:** The employee role this policy applies to. NULL = all roles (wildcard).
- **Form Control / UI Element:** Select2 Searchable Dropdown (Dynamic)
- **Label:** Applies to Role
- **Placeholder:** Select Role (Leave empty for All Roles)
- **Validation Rules:** `nullable|integer|exists:sys_roles,id`
- **UI Behavior:** Fetches active user roles from the system database. Provides clear search-to-filter capability. Choosing the default empty choice stores `NULL` in the database.
- **Error Scenario:** If modified dynamically to a non-existent role → "The selected role is invalid."

### 2.4 `applies_to_department_id` (FK → sch_department.id)
- **Type:** INT UNSIGNED, Nullable, FK
- **Meaning:** The department this policy applies to. NULL = all departments (wildcard).
- **Form Control / UI Element:** Select2 Searchable Dropdown (Dynamic)
- **Label:** Applies to Department
- **Placeholder:** Select Department (Leave empty for All Departments)
- **Validation Rules:** `nullable|integer|exists:sch_department,id`
- **UI Behavior:** Loads active departments from the database. Selecting the default empty choice saves `NULL`.
- **Error Scenario:** If invalid ID selected → "The selected department is invalid."

### 2.5 `applies_to_designation_id` (FK → sch_designation.id)
- **Type:** INT UNSIGNED, Nullable, FK
- **Meaning:** The designation this policy applies to. NULL = all designations (wildcard).
- **Form Control / UI Element:** Select2 Searchable Dropdown (Dynamic)
- **Label:** Applies to Designation
- **Placeholder:** Select Designation (Leave empty for All Designations)
- **Validation Rules:** `nullable|integer|exists:sch_designation,id`
- **UI Behavior:** Loads active designations from the database. Selecting the default empty choice saves `NULL`.
- **Error Scenario:** If invalid ID selected → "The selected designation is invalid."

### 2.6 `applies_to_leave_type_id` (FK → sch_staff_leave_types.id)
- **Type:** INT UNSIGNED, Nullable, FK
- **Meaning:** The leave type this policy applies to. NULL = all leave types (wildcard).
- **Form Control / UI Element:** Select2 Searchable Dropdown (Dynamic)
- **Label:** Applies to Leave Type
- **Placeholder:** Select Leave Type (Leave empty for All Leave Types)
- **Validation Rules:** `nullable|integer|exists:sch_staff_leave_types,id`
- **UI Behavior:** Loads active leave types. Selecting the default empty choice saves `NULL`.
- **Important:** Unlike TAB2 (Staff Leave Config), this field is on the policy itself, meaning you can define approval policies that are specific to certain leave types.
- **Example:** A policy that says "Maternity Leave requires Principal approval" would have `applies_to_leave_type_id = ML`
- **Error Scenario:** If invalid ID selected → "The selected leave type is invalid."

### 2.7 `priority` (Tie-Breaker)
- **Type:** TINYINT UNSIGNED, Required, Default = 10
- **Meaning:** When multiple policies match the same employee context, the one with the **lowest priority number** (highest precedence) is selected.
- **Form Control / UI Element:** Number Input (with dynamic spinner buttons)
- **Label:** Matching Priority (Precedence)
- **Help Text:** Lower values indicate higher matching priority (e.g. 1 will override 10).
- **Validation Rules:** `required|integer|min:1|max:100`
- **UI Behavior:** Built-in numeric boundaries (1 to 100). Validates on keyup/blur to ensure integer-only formatting.
- **Error Scenario:** 
  - If empty → "The priority field is required."
  - If < 1 or > 100 → "The priority must be an integer between 1 and 100."
  - If decimal input → "The priority must be an integer."

### 2.8 `is_active` (Active Status)
- **Type:** TINYINT(1), Boolean, Default = 1
- **Meaning:** Soft enable/disable status. Inactive policies are completely excluded from policy matching.
- **Form Control / UI Element:** Bootstrap Slide Toggle Switch
- **Label:** Policy Status (Active/Inactive)
- **Validation Rules:** `required|boolean`
- **UI Behavior:** Toggle transitions between a green "Active" state and a grey "Inactive" state. Shows text label next to it representing the state.
- **Error Scenario:** If empty or modified to incorrect boolean → "The active status is invalid."

---

## 3. Policy Matching Algorithm (Deep Detail)

### 3.1 Resolution Algorithm
```
FUNCTION: Resolve_Approval_Policy(employee, leave_type)
    
    Step 1: Get all active policies where scope matches
        FOR EACH policy:
            MATCH = true
            
            IF policy.applies_to_role_id IS NOT NULL:
                IF policy.applies_to_role_id != employee.role_id:
                    MATCH = false
            
            IF policy.applies_to_department_id IS NOT NULL:
                IF policy.applies_to_department_id != employee.department_id:
                    MATCH = false
            
            IF policy.applies_to_designation_id IS NOT NULL:
                IF policy.applies_to_designation_id != employee.designation_id:
                    MATCH = false
            
            IF policy.applies_to_leave_type_id IS NOT NULL:
                IF policy.applies_to_leave_type_id != leave_type.id:
                    MATCH = false
            
            IF MATCH = true:
                ADD to candidates
    
    Step 2: Score each candidate by specificity
        specificity = count of non-NULL scope fields (0–4)
    
    Step 3: Sort candidates
        PRIMARY: specificity DESC (most specific first)
        SECONDARY: priority ASC (lowest number first)
    
    Step 4: Return first match, or NULL if no match
```

### 3.2 Specificity Scoring

| Non-NULL Scope Fields | Score | Example |
|----------------------|-------|---------|
| Role + Dept + Desig + LeaveType | 4 | Teacher + Science + SrTchr + CL |
| Role + Dept + LeaveType | 3 | Teacher + Science + CL |
| Role + Dept + Desig | 3 | Teacher + Science + SrTchr |
| Role + LeaveType | 2 | Teacher + CL |
| Dept + LeaveType | 2 | Science + CL |
| Role only | 1 | Teacher |
| LeaveType only | 1 | CL |
| All NULL (catch-all) | 0 | All employees, all leave types |

### 3.3 Complete Matching Example

**Employee:** Jane Smith, Teacher (role), Science (dept), Senior Teacher (desig)  
**Leave Type:** SL (Sick Leave)

**Available Policies:**

| Policy | Role | Dept | Desig | LT | Priority | Spec |
|--------|------|------|-------|-----|----------|------|
| Default | NULL | NULL | NULL | NULL | 10 | 0 |
| Teacher | Teacher | NULL | NULL | NULL | 5 | 1 |
| Tch+Sci | Teacher | Science | NULL | NULL | 3 | 2 |
| Tch+Sci+Sr | Teacher | Science | SrTchr | NULL | 2 | 3 |
| SL Policy | NULL | NULL | NULL | SL | 4 | 1 |
| Tch+SL | Teacher | NULL | NULL | SL | 1 | 2 |

**Matching Candidates:**
- Default (Spec=0, Pri=10) ✓
- Teacher (Spec=1, Pri=5) ✓
- Tch+Sci (Spec=2, Pri=3) ✓
- Tch+Sci+Sr (Spec=3, Pri=2) ✓
- SL Policy (Spec=1, Pri=4) ✓
- Tch+SL (Spec=2, Pri=1) ✓

**Sorted:**
1. Tch+Sci+Sr (Spec=3, Pri=2) → **WINNER**
2. Tch+Sci (Spec=2, Pri=3)
3. Tch+SL (Spec=2, Pri=1) → Wait, this has same Spec(2) but lower Priority(1) than Tch+Sci(Pri=3)
   - BUT: Tch+SL has Spec=2, Tch+Sci+Sr has Spec=3
   - So Tch+Sci+Sr (Spec=3) beats Tch+SL (Spec=2)

**Correct Result:** Tch+Sci+Sr policy is selected → This policy's approval chain will apply.

---

## 4. Policy Validation Rules

### 4.1 Individual Field Validations

| Field | Required | Constraints |
|-------|----------|-------------|
| name | Yes | Max 150 chars, non-empty |
| description | No | Max 500 chars |
| applies_to_role_id | No | Must exist in sch_employee_roles if provided |
| applies_to_department_id | No | Must exist in sch_departments if provided |
| applies_to_designation_id | No | Must exist in sch_designations if provided |
| applies_to_leave_type_id | No | Must exist in sch_staff_leave_types if provided |
| priority | Yes | 1–100, integer |
| is_active | Yes | Boolean, default true |

### 4.2 Cross-Field Validations

| Condition | Rule |
|-----------|------|
| All scope fields NULL | Policy applies to ALL employees and ALL leave types (catch-all) |
| Duplicate scope combination | Should be warned: "Another policy with similar scope already exists" |
| Policy with no levels | Usable? No — must have at least 1 active level (TAB4) to be functional |
| Priority conflict | If another policy has same specificity AND same priority, warn user |

---

## 5. Business Rules

### Rule 1: Policy Must Have Levels
```
A policy is only functional if it has at least 1 active approval level (defined in TAB4).
Policies with NO levels cannot be matched to leave applications.
When viewing a policy in the list:
    → Show level count: "Levels: 3" or "Levels: 0 (Incomplete)"
```

### Rule 2: No-Match Fallback
```
If NO policy matches the employee's context:
    IF leave_type.requires_approval = true:
        → Leave application cannot be submitted
        → Error: "No approval policy configured for your role/department/leave type. Contact HR."
    IF leave_type.requires_approval = false:
        → Leave is auto-approved (no approval needed per leave type rules)
```

### Rule 3: Cascade Delete
```
When a policy is deleted (soft-delete):
    → ALL its levels (TAB4) are cascade-deleted
    → ALL level approvers (TAB5) are cascade-deleted
    → Associated leave applications remain but lose policy reference
```

### Rule 4: Policy Change on Active Applications
```
A policy CANNOT be deleted if there are active leave applications
(status = Submitted/Under Review/Info Requested) that reference this policy.
    
Error: "Cannot delete policy with active leave applications"
    
Solution: Deactivate the policy (is_active = false) instead.
New applications will use another matching policy.
Existing applications continue with their assigned policy.
```

### Rule 5: Inactive Policy Exclusion
```
Only policies with is_active = true AND deleted_at IS NULL
are considered in policy matching.
```

### Rule 6: Workflow Snapshoting / Version Freezing
```
When an employee submits a leave application:
1. The matching policy is resolved using Resolve_Approval_Policy().
2. All active levels (TAB4) for that policy are loaded.
3. For each level, all eligible approvers are resolved (using TAB5 resolution rules) and stored as instantiated approval queue records (sch_employee_leave_approvals).
4. Any subsequent changes to the policy structure (adding/deleting levels, changing approvers) will NOT affect already submitted, active, or historical applications. Those applications continue to follow the snapshotted approval routing resolved at submission time.
```

### Rule 7: Conflict of Interest & Self-Approval Prevention
```
An employee cannot act as an approver for their own leave application under any circumstances.
If the applicant resolves to be one of the approvers at any level of their matched policy:
1. Bypass / Auto-Pass Rule: The system automatically marks their individual approval record as 'N/A' or 'Auto-Passed (Self-Applicant)'.
2. Alternative Approver Rule:
   - In ANY_ONE mode: The remaining assigned approvers at that level must act.
   - In ALL mode: The self-applicant's approval requirement is skipped (e.g. if A and B must approve, and A is the applicant, only B's approval is required).
   - If the self-applicant was the SOLE possible approver at that level (e.g. reporting manager is NULL or they are their own manager):
     - The level is auto-escalated to the next level in the chain.
     - If it is the final level, it is escalated directly to the System Administrator.
```

### Rule 8: Approval Delegation (Out-of-Office / Delegate)
```
If an approver has configured an active delegation rule (due to being on leave or out of office):
1. Dynamic Re-routing: Any approval requests arriving during their delegation window automatically resolve to the designated delegate.
2. Audit Trail: The approval logs must clearly record: "Approved by {Delegate Name} on behalf of {Original Approver Name} via active delegation policy."
```

---

## 6. Relationship to Levels (TAB4) and Approvers (TAB5)

```
sch_leave_approval_policies (TAB3 — This Screen)
    └── has_many → sch_leave_approval_policy_levels (TAB4)
            └── has_many → sch_leave_approval_level_approvers (TAB5)

Policy matching resolves → which policy → then processes levels in order:
    Level 1 (Reporting Manager) → Level 2 (HR) → Level 3 (Principal)
    Each level has approvers who must approve/reject
```

---

## 7. Leave Approval Action Screen: UI, States & Transitions

This section governs the user interface, actions, real-time validations, and workflow transitions when an authorized approver logs in and acts upon a pending leave application.

### 7.1 Screen Layout & Information Hierarchy

The Leave Approval Action Screen is presented as a card-based detail view or a slide-over drawer containing four main informational panels:

#### A. Applicant Employee Profile Card (Top-Left)
*   **Employee Name & Photo:** Full display name, employee ID, profile photo.
*   **Department & Designation:** Displays current active department and designation.
*   **Tenure & Joining Date:** Displays dynamic date calculated since joining.
*   **Active Status Alert:** Visual badge highlighting if the employee is in their probation period.

#### B. Application Details Panel (Top-Right)
*   **Leave Type & Category:** Displays the requested leave type name (CL, SL, EL) with a badge signifying Paid or Unpaid (LWP).
*   **Requested Date Range:** Start date to end date, highlighted visually in a calendar widget.
*   **Total Days Count:** Displays total days requested (including decimal values for half-days).
*   **Reason for Leave:** Free-text reason entered by the employee.
*   **Attachment Section:** Dynamic document previewer displaying uploaded medical or supporting certificates (if applicable). Permits one-click file download.

#### C. Policy & Approval Progress Timeline (Middle)
*   **Visual Pipeline Track:** Step-by-step progress tracker displaying all levels of the matched policy (e.g. Level 1 → Level 2 → Level 3).
*   **Completed Levels Status:** Displays who acted, their status (Approved/Skipped/Escalated), precise date/time stamps, and their written remarks.
*   **Current Pending Level:** Highlighted card signifying the active step. Displays the list of all dynamically resolved authorized users who are permitted to act at this stage.

#### D. Interactive Action Form Panel (Bottom)
*   **Form Control / UI Element:** Segmented Button Group (Radio Cards) + Textarea.
*   **Action Type Select Cards:**
    *   **Approve:** green card, represents approval.
    *   **Reject:** red card, represents rejection.
    *   **Request Info:** amber card, sends query back to employee.
    *   **Request Document:** purple card, requests additional certificate upload.
*   **Approver Remarks Input:** Rich textarea (placeholder: "Provide detailed feedback, reasoning, or queries here...").

---

### 7.2 Action-Specific Fields & Dynamic Validations

| Action Selected | Remarks Field Rule | Supporting Upload Request Rule | Next Workflow State |
| :--- | :--- | :--- | :--- |
| **Approve** | Optional | Hidden | If last level: `Approved`. If intermediate: `Under Review` (moves to next level). |
| **Reject** | **Required** (Min 10 chars) | Hidden | Bypasses all other levels instantly. State transitions to `Rejected`. |
| **Request Info** | **Required** (Min 15 chars) | Hidden | Suspends escalation timers. State transitions to `Info Requested` (moves back to applicant). |
| **Request Document** | **Required** (Min 15 chars) | **Required** (Dropdown detailing document type needed) | Suspends escalation timers. State transitions to `Doc Requested` (moves back to applicant). |

---

### 7.3 Real-Time UI Validations & Interactive Logic

#### A. Empty Remarks Verification
*   **Logic:** When the user clicks the "Submit Action" button, if `Reject`, `Request Info`, or `Request Document` is active and the Remarks textarea contains fewer than the minimum characters:
    *   **Action:** Intercepts form submission, shakes the textarea, highlights the border in red, and displays validation warning: *"Detailed remarks are strictly required for rejections or queries (minimum X characters)."*

#### B. Dynamic Double-Submission Preventer
*   **Logic:** On form submit, the submit button is instantly disabled, showing a spinner icon with text *"Processing Approval Action..."*. This completely blocks rapid clicks causing duplicate transactions or duplicate state logs.

#### C. Balance Impact Indicator (Read-Only Warning)
*   **Logic:** Before submitting approval, the screen displays a real-time summary card detailing the balance impact:
    *   *Current Balance: 12 days*
    *   *Requested: 4 days*
    *   *Remaining Balance after approval: 8 days*
    *   If the requested days exceed the current remaining balance, the balance box changes to amber/red with warning: *"Warning: Approving this request will cause the employee's leave balance to go negative by {x} days."*

---

### 7.4 Workflow State Transitions & Notifications

Upon successful action submission, the system triggers the following cascade in a database transaction:

```
                  [Approver Submits Action]
                              │
            ┌─────────────────┼─────────────────┐
            ▼                 ▼                 ▼
       [APPROVE]          [REJECT]       [REQUEST INFO/DOC]
            │                 │                 │
      If Last Level?          │        State = Info/Doc Requested
     ┌──────┴──────┐          │        Pending = Applicant User ID
    YES            NO         │        Escalation Timer = Paused
     │             │          │                 │
     ▼             ▼          ▼                 ▼
[Approved]   [Next Level]  [Rejected]    [Notification Sent]
```

*   **Audit Logging:** Every status change is captured in `sch_employee_leave_application_remarks` as a `Status_Change` record with `old_status`, `new_status`, `acted_at`, and `approver_user_id`.
*   **Real-time Notifications:** 
    *   **Applicant Email/SMS/Push:** sent dynamically using events (`LEAVE_APPLICATION_REVIEWED`). Tells the employee exactly what action was taken and what the remarks were.
    *   **Next Level Approver Notification:** If intermediate approval, sends email/notification immediately to the newly resolved approvers of the next level: *"A leave application for {Employee Name} is pending your review at Level {n}."*

---

## Related Documents
- [SR-EM-05-TAB4](./SR-EM-05-TAB4-Approval_Policy_Levels.md) — Approval levels (pipeline stages)
- [SR-EM-05-TAB5](./SR-EM-05-TAB5-Policy_Level_Approvers.md) — Approvers assigned to each level
- [SR-EM-05](./SR-EM-05-Leave_Configuration.md) — Leave Configuration module overview
