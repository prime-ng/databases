# Leave Approval Policies — Requirement Document

## Screen Purpose & Overview

This screen is the third tab under the Leave Config sub-menu. Its main purpose is to design the approval pipeline (Approval Chain) for staff leaves. 

Using this screen, the Admin creates policies that determine who approves an employee's leave request. The policy configuration defines whether an application requires single-level approval (e.g., direct supervisor only) or multi-level approval (e.g., coordinator first, then the principal).

---

## Common Use Cases

1. **Creating Role-Wise Approval Chains:** Routing teacher leave requests to the Senior Coordinator and then to the Principal, while routing support staff requests directly to the Administrative Officer.
2. **Special Routing by Leave Type:** Routing long-term leaves like Maternity Leave (ML) or Earned Leave (EL) directly to the Principal or Director for approval, while keeping Casual Leave (CL) requests routed to the immediate reporting manager.
3. **Automated Hierarchical Validation:** Automatically identifying and notifying the correct manager based on the applicant's role, department, and seniority level.

---

## Screen Fields & Input Rules

| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| Policy Name | Unique and recognizable name for the policy (e.g., Primary Teachers Policy) | Required. Length must be between 1 to 150 characters. Must be unique. |
| Policy Description | Details about the approval routing (e.g., 3-level approval for academics) | Optional. Max 500 characters. |
| Applies To Role | Target employee role for this policy | Optional. Leaving it as "All Roles" applies the policy to all roles, or select a specific role. |
| Applies To Department | Target department for this policy | Optional. Select a specific department or select "All Departments". |
| Applies To Designation | Target designation for this policy | Optional. Select a specific designation or select "All Designations". |
| Applies To Leave Type | Target leave type for this policy | Optional. Select a specific leave type (e.g., Sick Leave) or select "All Leave Types". |
| Matching Priority | Priority sequence for policy check (1 to 100) | Required. Default is 10. If multiple policies match an applicant's profile, the policy with the lowest priority value (e.g., 1) is selected. |
| Policy Status | Toggle switch to activate/deactivate the policy | Required. Only active policies are evaluated by the leave workflow engine. |

---

## Business Rules & Validation Policies

1. **Policy Matching Sequence (Specificity Scoring):**
   - When an employee submits a leave request, the system searches for a matching approval policy:
     - The policy that matches the **highest number of specific criteria** (e.g., Role + Department + Leave Type) is prioritized.
     - If specificity levels are equal, the policy with the **lowest priority value** (e.g., 1 instead of 5) is applied.
     - If no policy matches and the leave type requires approval (`Requires Approval = Yes`), the system blocks submission and displays: *"Contact HR, no approval policy matching your profile."*

2. **Incomplete Policy Warning:**
   - Creating a policy is not sufficient for it to function. The policy must contain at least one active Approval Level and assigned approvers. Otherwise, the policy remains inactive.

3. **Workflow Snapshot Rule:**
   - When a leave request is submitted, the system locks (takes a snapshot of) the active approval steps and designated approvers at that moment.
   - Any subsequent modifications made by the Admin to the approval policy will not affect already pending leave requests; they will proceed under the original workflow snapshot.

4. **Self-Approval / Conflict of Interest Restrictions:**
   - Employees are **prohibited from approving their own leave requests**, even if they are designated as the default approver for that workflow step.
   - The system automatically skips the self-approval step or, if there are multiple approvers at that level, requires action from another designated approver.

---

## Screen Workflows & Operations

### 1. Creating a New Approval Policy (Create)
- The Admin clicks the "+ New Policy" button.
- Enters the Policy Name, Description, and configures the target criteria (Role, Department, Designation, and Leave Type).
- Sets the priority sequence value (e.g., 1, 5, 10).
- Clicks Save to record the master policy. The Admin then configures levels and approvers for this policy in the subsequent tabs.

### 2. Modifying a Policy (Update)
- The Admin clicks "Edit" next to the target policy in the list.
- Updates the filters, description, or priority settings, and saves the changes.

### 3. Deactivating a Policy (Soft Delete)
- Active policies with pending leave applications cannot be permanently deleted.
- The Admin toggles the status to **Inactive**. This prevents new leave applications from using the policy while allowing existing pending requests to complete their cycle.

---

## Real-World Example Scenario

**School Admin** wants to set up a specific approval workflow for **Maternity Leave (ML)**, requiring direct approvals from the HR Head and the Principal instead of the department coordinator.

1. The Admin creates a new policy named `Maternity Special Policy`.
2. Sets Applies to Leave Type = `Maternity Leave (ML)` and Applies to Role = `All`.
3. Sets Priority = `2` (a high priority to ensure it overrides general policies when Maternity Leave is selected).
4. Clicks Save.
5. **Levels Mapping:** The Admin configures two levels for this policy:
   - Level 1: HR Head
   - Level 2: Principal
6. **System Action:** When a teacher submits a Maternity Leave application, the system skips the standard coordinator step and routes the request directly to the HR Head's portal, followed by the Principal's portal.
