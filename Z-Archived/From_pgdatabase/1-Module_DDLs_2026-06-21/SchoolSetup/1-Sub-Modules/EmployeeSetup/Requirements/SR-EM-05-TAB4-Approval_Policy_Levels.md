# Screen Requirement: Approval Policy Levels (Deep Requirements)
## Document ID: SR-EM-05-TAB4
**Module:** SchoolSetup / EmployeeSetup  
**Screen Name:** Leave Configuration > Approval Policy Levels (Tab 4)  
**Route:** `school-setup.leave-config?tab=policy-levels`  
**User Role:** School Administrator, HR Manager  
**Priority:** P1 (High)  
**Status:** Approved for Development  

---

## 1. Screen Overview & Business Purpose

### 1.1 Purpose
This screen builds **multi-level approval chains** within a selected approval policy. Each level represents a **sequential stage** in the approval pipeline. Levels execute in ascending order (Level 1 → Level 2 → Level 3 ...), and each level must be completed before proceeding to the next.

### 1.2 Business Context
Leave approval in schools typically follows a hierarchy:
- **Level 1 (Reporting Manager):** First-level approval — checks if the leave is reasonable
- **Level 2 (Department Head / HR):** Second-level — verifies balance, checks staffing impact
- **Level 3 (Principal):** Final approval for long leaves or special cases
- **Level 4 (Board):** Rare — only for Principal's leave or exceptional cases

### 1.3 Key Concepts
- **Sequential Execution:** Level 1 must approve before Level 2 is activated
- **Approval Mode (ANY_ONE / ALL):** Controls whether any one approver can approve (ANY_ONE) or all of them must approve (ALL)
- **Escalation:** If an approver doesn't act within N hours, the application auto-escalates to the next level
- **Terminal Rejection:** If ANY level rejects, the entire application is rejected (no further levels processed)

---

## 2. Complete Field Definitions (Deep Detail)

### 2.1 `policy_id` (FK → sch_leave_approval_policies.id)
- **Type:** INT UNSIGNED, Required, FK
- **Meaning:** The parent approval policy this level belongs to.
- **Form Control / UI Element:** Read-only Select Dropdown (hidden or disabled on nested level forms)
- **Label:** Parent Approval Policy
- **Placeholder:** Select Policy
- **Validation Rules:** `required|integer|exists:sch_leave_approval_policies,id`
- **UI Behavior:** When adding a level within a specific policy's view, this field is automatically pre-filled and locked (disabled) to prevent users from accidentally changing the policy scope.
- **Error Scenario:** 
  - If blank → "The policy field is required."
  - If modified to invalid ID → "The selected policy is invalid."

### 2.2 `level_number` (Sequence Order)
- **Type:** TINYINT UNSIGNED, Required
- **Meaning:** The position of this level in the approval sequence. Level 1 is the first approver, Level 2 is the second, etc.
- **Form Control / UI Element:** Number Input (read-only in standard forms, modified via reordering UI)
- **Label:** Level Sequence (Step)
- **Help Text:** Sequence step number (e.g. 1 = Level 1). Must be unique within this policy.
- **Validation Rules:** 
  - `required|integer|min:1|max:20`
  - Must be unique when combined with `policy_id` (`unique:sch_leave_approval_policy_levels,level_number,NULL,id,policy_id,{policy_id}`)
- **UI Behavior:** Dynamically pre-calculates the next available number (e.g., if levels 1 and 2 already exist, auto-sets to 3). Supports drag-and-drop table rows on the listing page, which automatically performs bulk reordering updates via an AJAX payload.
- **Error Scenario:** 
  - If empty → "The level sequence step is required."
  - If duplicate → "A level with sequence step {n} already exists for this policy."
  - If < 1 or > 20 → "The level sequence step must be between 1 and 20."

### 2.3 `level_name` (Level Display Name)
- **Type:** VARCHAR(100), Required
- **Meaning:** Human-readable name for this approval stage. Shown in the application approval timeline and notifications.
- **Form Control / UI Element:** Text Input
- **Label:** Level Name
- **Placeholder:** e.g., Department Head Review
- **Validation Rules:** `required|string|max:100`
- **UI Behavior:** Character counter (X/100). Auto-trims leading/trailing whitespace.
- **Error Scenario:** 
  - If blank → "The level name field is required."
  - If > 100 characters → "The level name must not exceed 100 characters."
- **Examples:** "Reporting Manager", "Department Head", "HR Department", "Principal", "Board of Management"

### 2.4 `approval_mode` (Approval Mode)
- **Type:** ENUM('ANY_ONE', 'ALL'), Required, Default = 'ANY_ONE'
- **Meaning:** Determines **how many approvers** at this level must act for the level to be considered "passed."
- **Form Control / UI Element:** Radio Button Group (with cards/cards design)
- **Label:** Approval Mode
- **Options:**
  - **ANY_ONE**: Any single approver at this level can approve and the level passes.
  - **ALL**: Every single assigned approver at this level must approve for the level to pass.
- **Validation Rules:** `required|string|in:ANY_ONE,ALL`
- **UI Behavior:** Highlighted toggle cards. Selecting "ALL" displays a subtle warning badge reminding the administrator that all assigned approvers must log in and approve, which could slow down the request if one of them is absent.
- **Error Scenario:** If modified to a value other than ANY_ONE or ALL → "The selected approval mode is invalid."

### 2.5 `escalation_after_hours` (Auto-Escalation Timeout)
- **Type:** SMALLINT UNSIGNED, Nullable
- **Meaning:** Number of **hours** after which, if no action is taken by the current level's approvers, the application **auto-escalates** to the next level.
- **Form Control / UI Element:** Checkbox toggle ("Enable Auto-Escalation") + Number Input (Grouped with "Hours" suffix)
- **Label:** Auto-Escalation Timeout (Hours)
- **Placeholder:** e.g., 24
- **Help Text:** Leave unchecked or empty if you want the application to wait indefinitely at this level.
- **Validation Rules:** `nullable|integer|min:1|max:720` (cap at 30 days)
- **UI Behavior:** The checkbox handles state toggle:
  - If Checked: Number input field is enabled.
  - If Unchecked: Number input is disabled, greyed out, and reset to NULL.
- **Error Scenario:** 
  - If input is not numeric → "The escalation timeout must be an integer."
  - If < 1 or > 720 → "The escalation timeout must be between 1 and 720 hours."

### 2.6 `notify_applicant_on_escalation` (Escalation Notification)
- **Type:** TINYINT(1), Boolean, Default = 1 (true)
- **Meaning:** Whether the **applicant (employee)** should receive a **notification** when their leave application is auto-escalated from one level to the next due to timeout.
- **Form Control / UI Element:** Bootstrap Slide Toggle Switch
- **Label:** Notify Applicant on Escalation
- **Validation Rules:** `required|boolean`
- **UI Behavior:** Enabled ONLY when `escalation_after_hours` is not null and checkbox is active. Otherwise, greyed out and turned off.
- **Error Scenario:** If modified to invalid boolean value → "The notification setting is invalid."

### 2.7 `is_active` (Active Status)
- **Type:** TINYINT(1), Boolean, Default = 1
- **Meaning:** Soft enable/disable status for this level in the pipeline.
- **Form Control / UI Element:** Bootstrap Slide Toggle Switch
- **Label:** Level Status
- **Validation Rules:** `required|boolean`
- **UI Behavior:** Green switch represents "Active" (enabled), gray represents "Inactive" (disabled). Displays warning text below when deactivating: "Warning: Deactivating this level will cause all active applications to completely skip this step."
- **Error Scenario:** If blank or modified to invalid boolean → "The active status is invalid."

---

## 3. Approval State Machine (Deep Detail)

### 3.1 Complete State Flow

```
Application Submitted
    │
    ▼
Policy Resolved → Find matching policy → Load levels
    │
    ▼
Level 1: Pending (assigned to approvers)
    │
    ├──→ Approve ──→ Level 2: Pending
    │                   │
    │                   ├──→ Approve ──→ Level 3: Pending
    │                   │                   │
    │                   │                   ├──→ Approve → [APPROVED]
    │                   │                   │
    │                   │                   ├──→ Reject → [REJECTED]
    │                   │                   │
    │                   │                   └──→ Escalate → No next level → Escalate to Admin
    │                   │
    │                   ├──→ Reject → [REJECTED]
    │                   │
    │                   ├──→ Info Request → Employee Response → Resume Level 2
    │                   │
    │                   ├──→ Doc Request → Employee Upload → Resume Level 2
    │                   │
    │                   └──→ Escalate (timeout) → Level 3: Pending
    │
    ├──→ Reject → [REJECTED]
    │
    ├──→ Info Request → Employee Response → Resume Level 1
    │
    ├──→ Doc Request → Employee Upload → Resume Level 1
    │
    └──→ Escalate (timeout) → Level 2: Pending
```

### 3.2 Escalation Timer Management

```
WHEN Application reaches Level N:
    Level N Status = Pending
    Escalation Deadline = NOW() + escalation_after_hours
    
    IF escalation_after_hours IS NULL:
        // No auto-escalation — wait indefinitely
        // System may send periodic reminders to approvers
    
    IF escalation_after_hours IS NOT NULL:
        Every X minutes (cron: leave:process-escalations):
            CHECK: Is escalation_deadline passed?
            CHECK: Has ANY action been taken at this level?
            
            If deadline passed AND no action:
                Auto-action = 'Escalated'
                Move to Level N+1
                Set application.current_level_number = N+1
                
            If deadline passed AND some approvers acted but mode=ALL and not all acted:
                // Wait for all approvers
                // BUT if escalation timer is also set for individual approvers?
                // Current design: timer is for the LEVEL, not per approver
                // So if some approved but not all (ALL mode), escalation timer still applies
```

### 3.3 Approval Mode Detailed Conditions

#### Mode: ANY_ONE
```
Actions that trigger level pass:
    - At least 1 approver approves → Level PASSES
    
Actions that trigger level fail:
    - ALL approvers reject → Level FAILS → Application REJECTED
    
Mixed scenario:
    - Approver A: Pending
    - Approver B: Approved
    → Level PASSES (any one approved, moves to next)
    
    - Approver A: Rejected
    - Approver B: Approved
    → Level PASSES (B's approval is sufficient)
    
    - Approver A: Rejected
    - Approver B: Rejected
    → Level FAILS → Application REJECTED
```

#### Mode: ALL
```
Actions that trigger level pass:
    - ALL approvers approve → Level PASSES
    
Actions that trigger level fail:
    - ANY approver rejects → Level FAILS → Application REJECTED
    
Mixed scenario:
    - Approver A: Approved
    - Approver B: Pending
    → Level STILL PENDING (waiting for B)
    
    - Approver A: Approved
    - Approver B: Approved
    → Level PASSES
    
    - Approver A: Approved
    - Approver B: Rejected
    → Level FAILS → Application REJECTED
```

### 3.4 Escalation at Final Level

```
If escalation happens at the FINAL level (last level in the policy):
    There is no next level to escalate to.
    
    Options:
    1. Escalate to Admin/Super Admin (system-level fallback)
    2. Mark as "Pending — Overdue" (manual admin intervention)
    3. Auto-approve based on escalation timeout
    
    Recommendation: Escalate to system administrator with notification.
    The admin can manually approve/reject from the admin dashboard.
```

---

## 4. Validation Rules Matrix

| Field | Required | Constraints |
|-------|----------|-------------|
| policy_id | Yes | Must exist in sch_leave_approval_policies, active |
| level_number | Yes | >= 1, integer, UNIQUE per policy |
| level_name | Yes | Max 100 chars, non-empty |
| approval_mode | Yes | Must be 'ANY_ONE' or 'ALL' |
| escalation_after_hours | No | >= 1 if provided, NULL = no escalation |
| notify_applicant_on_escalation | No | Boolean, default true |
| is_active | Yes | Boolean, default true |

---

## 5. Cross-Field & Business Rules

### Rule 1: Level Number Uniqueness
```
UNIQUE(policy_id, level_number)
    
If a level with number {n} already exists for this policy:
    → Error: "Level number {n} already exists for this policy"
```

### Rule 2: Level Sequence Consistency
```
When inserting a new level:
    Check: Does level_number create a gap in sequence?
    (e.g., policy has levels 1, 3 and you insert level 5)
    → Warning: "Gap detected in level sequence. Levels will execute in order: 1, 3, 5"
    → Suggestion: "Consider renumbering levels sequentially"
```

### Rule 3: No-Approver Warning
```
When saving a level:
    Check: Does this level have at least 1 active approver?
    If NO active approvers:
        → Warning: "This level has no approvers — applications will be stuck at this level"
        → Action: Block save? OR Allow with warning?
    
    Recommendation: Allow save with warning. Approvers can be added later.
```

### Rule 4: Level Deletion & Active Applications
```
When deleting a level:
    Check: Are there any active leave applications currently at this level?
        (applications where current_level_number = this.level_number 
         AND status in (Submitted, Under Review, Info Requested, Doc Requested))
    
    If YES:
        → Error: "Cannot delete this level. There are {count} active leave applications at this level."
        → Action: Block deletion
    
    If NO:
        → Allow deletion
        → All approvers at this level are cascade-deleted
```

### Rule 5: Escalation Hours Validation
```
IF escalation_after_hours IS NOT NULL:
    Must be >= 1 (minimum 1 hour)
    IF escalation_after_hours = 0:
        Treat as NULL (meaning disabled)
```

### Rule 6: Info Request/Doc Request Pause Logic
```
When an approver requests information or document:
    → Escalation timer PAUSES for this level
    → Timer value is stored (remaining_hours)
    → When employee responds:
        → Timer RESUMES from remaining_hours
    → This prevents escalation while waiting for employee input
```

---

## 6. Relationship to Approvers (TAB5)

```
sch_leave_approval_policy_levels (TAB4 — This Screen)
    └── has_many → sch_leave_approval_level_approvers (TAB5)
    
Each level can have multiple approvers of different types:
    - Specific user
    - All users with a role
    - All users with a designation
    - Department head
    - Reporting manager

The approval_mode (ANY_ONE/ALL) controls how these multiple approvers interact.
```

---

## 7. UI/UX Considerations

### 7.1 List View Per Policy
```
When a policy is selected, show levels in sequential order:
    
    Policy: Default School Policy
    ┌─ Level 1 │ Reporting Manager   │ ANY_ONE │ Esc: 24h │ ✓ Active │
    ├─ Level 2 │ HR Department       │ ANY_ONE │ Esc: 48h │ ✓ Active │
    ├─ Level 3 │ Principal           │ ALL     │ Esc: —   │ ✓ Active │
    └─────────────────────────────────────────────────────────────────
    
    Actions: [+ Add Level] [Reorder Levels]
    Row Actions: [Edit] [Manage Approvers →] [Delete Level]
```

### 7.2 Level Reordering UI
```
Drag-and-drop reordering:
    When user reorders levels, level_numbers are auto-updated:
    - Level 1 (dragged to position 3) → becomes Level 3
    - Level 2 → Level 1 (shift)
    - Level 3 → Level 2 (shift)
    
    Confirmation required: "This will renumber all levels. Continue?"
```

---



## Related Documents
- [SR-EM-05-TAB3](./SR-EM-05-TAB3-Leave_Approval_Policies.md) — Parent policy definition
- [SR-EM-05-TAB5](./SR-EM-05-TAB5-Policy_Level_Approvers.md) — Approvers assigned to each level
- [SR-EM-05](./SR-EM-05-Leave_Configuration.md) — Leave Configuration module overview
