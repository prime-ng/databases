# Policy Level Approvers — Requirement Document

## Screen Purpose & Overview

This screen is the fifth tab under the Leave Config sub-menu. Its main purpose is to assign specific users (Approvers) to each defined Approval Level (Step) to approve or reject staff leave requests.

A key feature of this screen is the ability to configure both dynamic (context-dependent) and static (fixed) approver routing rules. The system evaluates the active step of a leave application and routes notification alerts to the appropriate dashboard for action.

---

## Common Use Cases

1. **Direct Manager Routing (Reporting To):** Routing Level 1 approval alerts dynamically to the applicant's immediate supervisor as defined in their employee profile.
2. **Fixed Person Routing (User):** Ensuring that Level 3 final approval is always routed to a specific individual, such as the Principal (e.g., Mrs. Asha Sharma).
3. **Role/Designation-Based Routing:** Routing Level 2 approval to any staff member holding the "HR Manager" role, allowing the first available HR officer to process it.
4. **Department Head Mapping (HOD):** Dynamically routing requests to department heads (e.g., routing a science teacher's request to the Science HOD, and a maths teacher's request to the Maths HOD).

---

## Screen Fields & Input Rules

| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| Parent Approval Level | The specific policy approval level being configured | Automatically pre-filled by the system based on navigation context (e.g., *Teacher Policy > Level 1*). Read-only. |
| Approver Type | Criteria used to identify the approver(s) (Dropdown) | Required. Options:<br>• **USER:** Routes to a specific, fixed staff member.<br>• **ROLE:** Routes to all employees holding a specific system role.<br>• **DESIGNATION:** Routes to all employees holding a specific designation.<br>• **DEPARTMENT_HEAD:** Routes dynamically to the head of the applicant's department.<br>• **REPORTING_TO:** Routes dynamically to the applicant's immediate reporting manager. |
| Select Staff Member | Search and select a specific employee | Required if *Approver Type* is set to USER. Hidden for other types. |
| Select Target Role | Select a system role (e.g., HR Manager) | Required if *Approver Type* is set to ROLE. Hidden for other types. |
| Select Target Designation | Select a designation (e.g., Vice Principal) | Required if *Approver Type* is set to DESIGNATION. Hidden for other types. |
| Select Target Department | Select a school department (e.g., Science Department) | Required if *Approver Type* is set to DEPARTMENT_HEAD. Hidden for other types. |
| Status (Active/Inactive) | Status toggle for the approver assignment | Default is Active (Toggle ON). If set to Inactive, this approver will not receive workflow notifications. |

---

## Business Rules & Validation Policies

1. **Approver Resolution Logic:**
   - **Static Rules (USER, ROLE, DESIGNATION):** Resolved immediately based on active database linkages. The system identifies matching user accounts when evaluating the step.
   - **Dynamic Rules (REPORTING_TO, DEPARTMENT_HEAD):** Resolved dynamically at runtime when the leave application is submitted. For example, if Amit submits a request, the system retrieves Amit's designated manager from his profile and routes the request to that manager's user ID.

2. **Null/Empty Fallback (Workflow Stall Prevention):**
   - If *REPORTING_TO* is selected, but the applicant has no designated manager mapped in their profile (value is NULL), the system automatically bypasses the stall and forwards the request to the next approval level or the school Administrator for backup processing.

3. **Empty Level Validation:**
   - The system prevents saving a policy level without any active approvers mapped. Attempting to do so triggers a warning: *"This level has no active approvers. Leave applications will get stuck at this step. Please assign an approver."*

4. **Workflow Snapshot Rule:**
   - When a leave request is submitted, the resolved approver user IDs are locked in the permanent transaction log. If an approver transfers departments or leaves the school the next day, the pending request remains in their queue (or is manually redirected by the Admin), while new requests route to the updated approver.

---

## Screen Workflows & Operations

### 1. Assigning an Approver (Create)
- The Admin clicks "+ Add Approver" on the selected policy level dashboard.
- Selects the Approver Type (e.g., REPORTING_TO).
- For dynamic types, the Admin clicks Save immediately. For static types (USER, ROLE, DESIGNATION), the Admin selects the specific target from the corresponding search fields before saving.

### 2. Modifying Approver Settings (Update)
- The Admin selects a row from the assigned approvers grid and clicks "Edit".
- Updates the type or targets (e.g., changing a specific user assignment to a role-based assignment).
- Clicks Save to apply the updated routing rules.

### 3. Removing an Approver (Delete)
- The Admin clicks "Delete" next to the target approver record.
- **Rule:** A warning message confirms: *"Are you sure you want to remove this approver?"* The level must retain at least one active approver rule to keep the policy valid.

---

## Real-World Example Scenario

Configuring **Level 1 (Direct Supervisor Review)** for the **Admin Staff Policy**:

1. The Admin selects `Admin Policy - Level 1 (Manager Review)`.
2. Clicks "+ Add Approver".
3. Sets **Approver Type** = `REPORTING_TO` and clicks Save (no specific name is required).
4. Clicks "+ Add Approver" again to map a backup rule.
5. Sets **Approver Type** = `ROLE` and **Select Target Role** = `HR Manager`. Clicks Save.
6. The **Approval Mode** for Level 1 is set to `ANY_ONE`.
7. **System Behavior:** Priya (an Accountant in the Admin Department) submits a leave request. Her profile lists Raj Kumar as her manager. The system routes the approval alert to two destinations: Raj Kumar's dashboard and Neha's dashboard (who holds the HR Manager role). Raj Kumar approves the request. Because the level mode is set to ANY_ONE, Level 1 completes immediately without waiting for Neha's response.
