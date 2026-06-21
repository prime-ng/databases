# Screen Requirement: Policy Level Approvers (Deep Requirements)
## Document ID: SR-EM-05-TAB5
**Module:** SchoolSetup / EmployeeSetup  
**Screen Name:** Leave Configuration > Policy Level Approvers (Tab 5)  
**Route:** `school-setup.leave-config?tab=level-approvers`  
**User Role:** School Administrator, HR Manager  
**Priority:** P1 (High)  
**Status:** Approved for Development  

---

## 1. Screen Overview & Business Purpose

### 1.1 Purpose
This screen assigns **specific approvers** to each approval policy level. Approvers can be defined in **five different ways**:
- **USER** — A specific person (fixed)
- **ROLE** — Anyone holding a certain role (dynamic)
- **DESIGNATION** — Anyone with a certain designation (dynamic)
- **DEPARTMENT_HEAD** — The head of a specific department (resolved at runtime)
- **REPORTING_TO** — The applicant's reporting manager (resolved at runtime)

This flexibility supports both fixed approval chains (e.g., "Amit Singh must approve") and dynamic/changing chains (e.g., "applicant's reporting manager" — which changes when managers change).

### 1.2 Business Context
Different approval routing strategies:
- **Fixed Routing:** "Mrs. Sharma (Principal) must always approve" → USER type
- **Role-Based Routing:** "Any HR Manager can approve" → ROLE type
- **Dynamic Routing:** "The applicant's reporting manager" → REPORTING_TO type
- **Department Routing:** "Head of Science Department" → DEPARTMENT_HEAD type

### 1.3 Key Concepts
- **Approver Resolution:** Dynamic approvers (REPORTING_TO, DEPARTMENT_HEAD) are resolved at **leave application submission time**, not at configuration time
- **Multiple Approvers:** A level can have multiple approvers (different types). How they interact depends on the level's `approval_mode` (TAB4)
- **No Approver = Stuck:** If a level has zero approvers, applications get stuck at this level

---

## 2. Complete Field Definitions (Deep Detail)

### 2.1 `level_id` (FK → sch_leave_approval_policy_levels.id)
- **Type:** INT UNSIGNED, Required, FK
- **Meaning:** The approval policy level this approver record belongs to.
- **Form Control / UI Element:** Read-only Select Dropdown (hidden or disabled on nested level forms)
- **Label:** Parent Approval Level
- **Placeholder:** Select Level
- **Validation Rules:** `required|integer|exists:sch_leave_approval_policy_levels,id`
- **UI Behavior:** Locked and pre-filled when adding an approver card directly under a policy level. Formatted as: "Policy Name > Level Name (L{n})" for context.
- **Error Scenario:** 
  - If blank → "The level ID is required."
  - If modified to invalid ID → "The selected level is invalid."

### 2.2 `approver_type` (Type of Approver)
- **Type:** ENUM('USER','ROLE','DESIGNATION','DEPARTMENT_HEAD','REPORTING_TO'), Required
- **Meaning:** Determines **how the approver is identified** — as a specific user, by role, by designation, as department head, or as the reporting manager.
- **Form Control / UI Element:** Select Dropdown or Tabbed Segmented Button Group
- **Label:** Approver Category / Type
- **Placeholder:** Select Approver Type
- **Validation Rules:** `required|string|in:USER,ROLE,DESIGNATION,DEPARTMENT_HEAD,REPORTING_TO`
- **UI Behavior:** Acts as the **conditional rendering engine** for the rest of the form. When changed, it instantly triggers jQuery/JS animations to:
  - If `USER`: Shows `approver_user_id` searchable Select2. Hides all other entity select fields.
  - If `ROLE`: Shows `approver_role_id` Select2. Hides all other entity select fields.
  - If `DESIGNATION`: Shows `approver_designation_id` Select2. Hides all other entity select fields.
  - If `DEPARTMENT_HEAD`: Shows `approver_department_id` Select2. Hides all other entity select fields.
  - If `REPORTING_TO`: Completely hides all nested entity select fields (no extra inputs required).
- **Error Scenario:** If empty or modified to a non-existent ENUM option → "The selected approver type is invalid."

### 2.3 `approver_user_id` (FK → sys_users.id)
- **Type:** INT UNSIGNED, Nullable, FK
- **Meaning:** The specific user who can approve at this level.
- **Form Control / UI Element:** Searchable Select2 Dropdown (AJAX-enabled)
- **Label:** Select Staff Member
- **Placeholder:** Search by staff name, email, or employee code...
- **Validation Rules:** `required_if:approver_type,USER|nullable|integer|exists:sys_users,id`
- **UI Behavior:** Visible ONLY when `approver_type` is set to `USER`. Fetches active staff members from the API endpoint dynamically with page-scroll loading. Automatically cleared, hidden, and marked non-required if `approver_type` changes.
- **Error Scenario:** 
  - If `USER` selected but field is left empty → "The user field is required when approver type is USER."
  - If selected user ID does not exist → "The selected user is invalid."

### 2.4 `approver_role_id` (FK → sys_roles.id)
- **Type:** INT UNSIGNED, Nullable, FK
- **Meaning:** The employee role whose holders can approve at this level.
- **Form Control / UI Element:** Select2 Searchable Dropdown
- **Label:** Select Target Role
- **Placeholder:** Select Role
- **Validation Rules:** `required_if:approver_type,ROLE|nullable|integer|exists:sys_roles,id`
- **UI Behavior:** Visible ONLY when `approver_type` is set to `ROLE`. Populates all active roles in the organization.
- **Error Scenario:** 
  - If `ROLE` selected but field is left empty → "The role field is required when approver type is ROLE."
  - If selected role ID does not exist → "The selected role is invalid."

### 2.5 `approver_designation_id` (FK → sch_designation.id)
- **Type:** INT UNSIGNED, Nullable, FK
- **Meaning:** The designation whose holders can approve at this level.
- **Form Control / UI Element:** Select2 Searchable Dropdown
- **Label:** Select Target Designation
- **Placeholder:** Select Designation
- **Validation Rules:** `required_if:approver_type,DESIGNATION|nullable|integer|exists:sch_designation,id`
- **UI Behavior:** Visible ONLY when `approver_type` is set to `DESIGNATION`. Populates all active designations.
- **Error Scenario:** 
  - If `DESIGNATION` selected but field is left empty → "The designation field is required when approver type is DESIGNATION."
  - If selected designation ID does not exist → "The selected designation is invalid."

### 2.6 `approver_department_id` (FK → sch_department.id)
- **Type:** INT UNSIGNED, Nullable, FK
- **Meaning:** The department whose head is the approver.
- **Form Control / UI Element:** Select2 Searchable Dropdown
- **Label:** Select Target Department
- **Placeholder:** Select Department
- **Validation Rules:** `required_if:approver_type,DEPARTMENT_HEAD|nullable|integer|exists:sch_department,id`
- **UI Behavior:** Visible ONLY when `approver_type` is set to `DEPARTMENT_HEAD`. Populates all active departments.
- **Error Scenario:** 
  - If `DEPARTMENT_HEAD` selected but field is left empty → "The department field is required when approver type is DEPARTMENT_HEAD."
  - If selected department ID does not exist → "The selected department is invalid."

### 2.7 `is_active` (Active Status)
- **Type:** TINYINT(1), Boolean, Default = 1
- **Meaning:** Soft enable/disable status for this specific approver assignment.
- **Form Control / UI Element:** Bootstrap Slide Toggle Switch
- **Label:** Status (Active/Inactive)
- **Validation Rules:** `required|boolean`
- **UI Behavior:** Toggle transitions between a green "Active" state and a grey "Inactive" state. Shows text label next to it representing the state.
- **Error Scenario:** If empty or modified to incorrect boolean → "The active status is invalid."

---

## 3. Approver Resolution at Runtime (Deep Detail)

### 3.1 Resolution Timing

```
Approvers are resolved at TWO points:

1. At CONFIGURATION TIME (this screen):
   - No resolution needed — just storing the rule
   - Validation: Check that the referenced entities exist (user/role/designation/department)

2. At LEAVE APPLICATION SUBMISSION TIME:
   - Dynamic types (REPORTING_TO, DEPARTMENT_HEAD) are resolved NOW
   - Static types (USER, ROLE, DESIGNATION) are resolved NOW (find the matching users)
   - The resolved user IDs are stored in sch_employee_leave_approvals for audit/history
```

### 3.2 Resolution Logic Per Type

| Type | Resolution SQL/Logic | Returns |
|------|---------------------|---------|
| USER | `User.find(approver_user_id)` | Single user |
| ROLE | `User.joins(:employee).where(employee: { role_id: approver_role_id, is_active: true })` | Multiple users possible |
| DESIGNATION | `User.joins(:employee).where(employee: { designation_id: approver_designation_id, is_active: true })` | Multiple users possible |
| DEPARTMENT_HEAD | Find the employee who is the head of the specified department | Single user |
| REPORTING_TO | `Employee.find(applicant.employee_id).reporting_to.user` | Single user |

### 3.3 Resolution Failure Handling

| Type | Failure Scenario | Fallback |
|------|-----------------|----------|
| USER | User is deactivated or not found | Cannot resolve → level is stuck; notify admin |
| ROLE | No active users with this role | Cannot resolve → level is stuck; notify admin |
| DESIGNATION | No active users with this designation | Cannot resolve → level is stuck; notify admin |
| DEPARTMENT_HEAD | No HOD assigned for this department | Escalate to next level or admin |
| REPORTING_TO | Employee has no reporting_to set | Escalate to next level or admin |

### 3.4 Multiple Approvers Interaction

When a level has MULTIPLE approver records (e.g., one USER + one ROLE):

```
Level has:
    - Approver A (USER): Amit Singh
    - Approver B (ROLE): HR Manager role

Depending on level's approval_mode:

ANY_ONE mode:
    - Amit approves → Level passes (any one is enough)
    - OR any HR Manager approves → Level passes

ALL mode:
    - Amit must approve AND at least one HR Manager must approve
    → Both categories must have at least one approval
```

---

## 4. Validation Rules Matrix

### 4.1 Type-Dependent Required Fields

| Approver Type | Required Field(s) | Optional Fields |
|---------------|------------------|-----------------|
| USER | `approver_user_id` | All others NULL |
| ROLE | `approver_role_id` | All others NULL |
| DESIGNATION | `approver_designation_id` | All others NULL |
| DEPARTMENT_HEAD | `approver_department_id` | All others NULL |
| REPORTING_TO | None (auto-resolved) | All others NULL |

### 4.2 Cross-Field Validations

| Validation | Logic | Error |
|------------|-------|-------|
| Exactly one approver ID matches type | For USER type, approver_user_id must be set and others NULL | — |
| Duplicate approver | Same (level_id + approver_type + approver_entity_id) cannot exist twice | "This approver is already assigned to this level" |
| User existence | approver_user_id must exist in sys_users | "Selected user not found" |
| Role existence | approver_role_id must exist in sch_employee_roles | "Selected role not found" |
| Designation existence | approver_designation_id must exist in sch_designations | "Selected designation not found" |
| Department existence | approver_department_id must exist in sch_departments | "Selected department not found" |

### 4.3 Complete Validation Rules

| Field | Required | Constraints |
|-------|----------|-------------|
| level_id | Yes | Must exist in sch_leave_approval_policy_levels |
| approver_type | Yes | Must be USER, ROLE, DESIGNATION, DEPARTMENT_HEAD, REPORTING_TO |
| approver_user_id | Conditional | Required if type=USER, must exist |
| approver_role_id | Conditional | Required if type=ROLE, must exist |
| approver_designation_id | Conditional | Required if type=DESIGNATION, must exist |
| approver_department_id | Conditional | Required if type=DEPARTMENT_HEAD, must exist |
| approver_reporting_to_id | No | Reserved for future |
| is_active | Yes | Boolean, default true |

---

## 5. Business Rules

### Rule 1: One Approver Type Per Record
```
Each approver record has EXACTLY one approver type.
Exactly one of the approver_*_id fields should be non-NULL (matching the type).

Example valid records:
    {type: USER, approver_user_id: 5, others: NULL}
    {type: ROLE, approver_role_id: 3, others: NULL}
    {type: REPORTING_TO, all approver_*_id fields: NULL}
```

### Rule 2: Duplicate Prevention
```
UNIQUE(level_id, approver_type, approver_user_id, approver_role_id, 
       approver_designation_id, approver_department_id)

The combination must be unique. Same user cannot be assigned twice to the same level.
```

### Rule 3: REPORTING_TO Fallback
```
If REPORTING_TO resolves to NULL (employee has no reporting manager):
    → Automatically escalate to the next level
    → OR if this is the final level, escalate to system admin
```

### Rule 4: Dynamic Resolution at Submit Time
```
DYNAMIC types (REPORTING_TO, DEPARTMENT_HEAD):
    → Resolved at LEAVE APPLICATION SUBMISSION time
    → The resolved user is stored in sch_employee_leave_approvals.approver_user_id
    → This ensures the approval trail is preserved even if reporting structure changes later

STATIC types (USER, ROLE, DESIGNATION):
    → Can be resolved at any time (configuration or submission)
    → The resolved user(s) are stored at submission time for audit trail
```

### Rule 5: No Approver at Level = Stuck
```
If a level has ZERO active approvers:
    → Applications reaching this level will be stuck
    → System should detect this and alert admin
    → Admin must either:
        a. Add approvers to this level
        b. Deactivate this level (applications skip it)
        c. Delete this level
```

### Rule 6: Approver Deactivation Handling
```
If an approver (user) is deactivated while there are pending applications at their level:
    → At the next process-approval cron run:
        → Check if the assigned approver is still active
        → If NOT active:
            → Skip this approver
            → If ANY_ONE mode and other approvers exist → continue
            → If ALL mode and no remaining active approvers → escalate to admin
            → If only approver → escalate to admin
```

### Rule 7: Cascade Delete
```
When a policy level is deleted:
    → ALL approver records for that level are cascade-deleted
    → Pending approval actions referencing this level become orphaned
    → System should check for pending approvals before allowing deletion
```

---

## 6. Complete Example Scenarios

### Scenario 1: Default School Policy — Level 1 (Reporting Manager)
```
Policy: Default School Policy
Level: L1 - Reporting Manager (ANY_ONE, Esc: 24h)

Approvers:
    1. Type: REPORTING_TO → Applicant's reporting manager
    
Resolution:
    When John (Teacher, Science) applies for leave:
    → John's reporting manager is found: Jane (HOD Science)
    → Level 1 approver = Jane (user_id=42)
    → Jane gets notification to approve/reject
```

### Scenario 2: Teacher Leave Policy — Level 2 (HR)
```
Policy: Teacher Leave Policy
Level: L2 - HR Department (ANY_ONE, Esc: 48h)

Approvers:
    1. Type: ROLE → HR Manager role
    2. Type: USER → Amit Singh (HR Director)
    
Resolution:
    → All users with HR Manager role are found (3 users)
    → Amit Singh (user_id=10) is also added
    → Total approvers = 4
    → Any ONE of them can approve (ANY_ONE mode)
```

### Scenario 3: Admin Leave Policy — Level 3 (Principal)
```
Policy: Admin Leave Policy
Level: L3 - Principal (ALL, No escalation)

Approvers:
    1. Type: DESIGNATION → Principal designation
    2. Type: USER → Vice Principal (user_id=5)
    
Resolution:
    → Users with Principal designation = 1 (Mrs. Sharma)
    → Vice Principal = user 5
    → BOTH must approve (ALL mode)
```

### Scenario 4: Science Department — Level 1
```
Policy: Science Department Policy
Level: L1 - Department Head (ANY_ONE, Esc: 24h)

Approvers:
    1. Type: DEPARTMENT_HEAD → Science Department (dept_id=3)
    
Resolution:
    → At application submit time:
    → Find the HOD of Science Department → Dr. Gupta (employee_id=15)
    → Level 1 approver = Dr. Gupta
```

---



## Related Documents
- [SR-EM-05-TAB4](./SR-EM-05-TAB4-Approval_Policy_Levels.md) — Parent level definition
- [SR-EM-05-TAB3](./SR-EM-05-TAB3-Leave_Approval_Policies.md) — Parent policy definition
- [SR-EM-05](./SR-EM-05-Leave_Configuration.md) — Leave Configuration module overview
