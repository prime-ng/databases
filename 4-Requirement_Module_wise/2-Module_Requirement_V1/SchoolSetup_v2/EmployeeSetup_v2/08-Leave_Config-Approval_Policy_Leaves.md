# Approval Policy Levels — Requirement Document

## Screen Purpose & Overview

This screen is the fourth tab under the Leave Config sub-menu (known in the system as policy levels or approval steps). It is used by the Admin to define the sequential steps (Levels) within each Leave Approval Policy.

For example, for a "Teacher Leave Policy", the Admin can configure the following chain:
- **Level 1:** Review by the reporting manager.
- **Level 2:** Verification by the Department Head.
- **Level 3:** Final approval by the Principal.
This screen implements sequential progression, ensuring requests move step-by-step through the approval chain.

---

## Common Use Cases

1. **Setting Up a Multi-Stage Approval Pipeline:** Defining the exact sequence and number of approval stages a leave request must clear.
2. **Configuring Approval Decision Rules (ANY_ONE / ALL):** Specifying if approval from any single supervisor at a level is sufficient (ANY_ONE) or if all assigned approvers at that level must sign off (ALL).
3. **Setting Up Auto-Escalation (Auto-Forward):** Configuring timeouts (e.g., 24 or 48 hours) so that if an approver does not take action within that timeframe, the request automatically escalates to the next level.
4. **Enforcing Terminal Rejection:** Ensuring that if an approver at any stage rejects the request, the process terminates immediately, and the applicant receives a rejection notice via email or SMS.

---

## Screen Fields & Input Rules

| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| Parent Approval Policy | The parent policy to which these steps belong | Automatically selected in the background based on the Admin's navigation context. Read-only. |
| Level Sequence (Step) | The sequential position of the level (e.g., 1, 2, 3) | Required. Automatically suggested in incremental order. Duplicate sequence numbers within the same policy are not allowed. |
| Level Name | Visual name of the step (e.g., HOD Review, HR Audit) | Required. Length must be between 1 to 100 characters. |
| Approval Mode | Decision mode for the step (Radio Options: ANY_ONE / ALL) | Required. <br>• **ANY_ONE:** Multiple approvers can be assigned to this level, but approval from any one of them clears the step.<br>• **ALL:** All assigned approvers must approve the request to clear the step. |
| Auto-Escalation Timeout | Time limit before the request automatically escalates | Optional (in hours). Range: 1 to 720 hours (max 30 days). If left blank, the request waits indefinitely at this level. |
| Notify Applicant on Escalation | Notification toggle for escalation | Default is Yes. Automatically notifies the employee when a request escalates. |
| Level Status | Status toggle (Yes/No Checkbox) | Default is Active (Yes). If set to Inactive, this step is bypassed in the approval workflow. |

---

## Business Rules & Validation Policies

1. **Sequential Processing Rule:**
   - The system routes approval alerts in order starting with Level 1. Approvers at Level 2 cannot view or act on the request until the requirements of Level 1 are fully satisfied.

2. **Terminal Rejection Policy:**
   - If any approver at any level rejects the leave request, the entire application is instantly marked as 'Rejected' and the workflow terminates. Subsequent levels are bypassed.

3. **Escalation Timer Pausing:**
   - If an approver requests clarification (`Request Info`) or additional documentation (`Request Document`) from the applicant, the auto-escalation timer is **paused**.
   - The timer resumes from where it was paused once the employee submits the requested information or documents.

4. **Escalation at the Final Level:**
   - If a timeout occurs at the final level of the approval chain, the request automatically escalates to the school's Super Administrator or a backup administrator dashboard.

---

## Screen Workflows & Operations

### 1. Adding an Approval Level (Create)
- The Admin clicks the "+ Add Level" button.
- The system automatically assigns the next incremental step number (e.g., Level 2).
- The Admin inputs the Level Name, selects the Approval Mode (ANY_ONE/ALL), and configures escalation options.
- Clicks Save to append the new step to the policy pipeline.

### 2. Reordering Approval Levels (Drag & Drop)
- The Admin can reorder levels in the list using a drag-and-drop interface.
- Changing the order automatically re-sequences the step numbers (e.g., Level 2 becomes Level 1).
- The system displays a confirmation warning: *"This will change the approval order for all new requests. Confirm?"*

### 3. Deleting an Approval Level (Delete)
- The Admin clicks "Delete" next to the target level.
- **Validation Rule:** If any active leave requests are currently pending at this level, the system blocks deletion and displays: *"Cannot delete. Active applications pending at this level."*
- If no applications are pending, the step and its configurations are removed.

---

## Real-World Example Scenario

The Admin wants to configure a 2-stage workflow for the **Primary Teacher Policy**:

1. **Level 1: HOD Review**
   - Mode: `ANY_ONE` (either HOD or Assistant HOD can sign off).
   - Escalation Timeout: `24 Hours` (escalates to Level 2 if inactive for 24 hours).
2. **Level 2: Principal Final Approval**
   - Mode: `ANY_ONE`.
   - Escalation Timeout: `None` (waits indefinitely for the Principal's decision).
3. **Workflow Action:** Priya, a teacher, applies for a 3-day leave.
   - The HOD is out of office and does not check the dashboard for 24 hours.
   - **System Action:** The system automatically bypasses the HOD review stage, flags the request as "Escalated", and routes it directly to the Principal's dashboard.
