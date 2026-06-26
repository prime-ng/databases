# Leave Approval Requests — Requirement Document

## Screen Purpose & Overview

This screen is part of the Leave Management sub-menu. The main purpose of this screen is to provide a review dashboard for school supervisors, Department Heads (HODs), HR managers, and the Principal to approve, reject, or request clarification (info/doc requested) for leave applications submitted by staff and teachers.

The screen manages the multi-level leave approval workflow (e.g., Level 1: HOD, Level 2: Principal). Based on school policies and routing rules, the system automatically displays the pending review requests on the appropriate manager's dashboard. A built-in chat window allows managers and employees to discuss the leave request directly to resolve clarifications.

---

## Common Use Cases

1. **Review Pending Leaves:** Checking applicant details, leave balances, dates, and the reason for the leave request.
2. **Approve / Reject Action:** Approving a leave application with a single click or rejecting it with a mandatory reason.
3. **Seek Clarification (Info/Doc Requested):** Asking the employee questions (e.g., "Who is covering your classes?") or requesting a medical certificate. This redirects the application back to the employee.
4. **Auto-Escalation Monitoring:** Automatically escalating a leave request to the next senior manager if a supervisor does not take action within 48 hours.
5. **Administrative Overrule (Quick Lock):** Allowing the Super Admin or HR Director to bypass the multi-level approval chain in urgent situations to directly approve/reject and lock the request thread.

---

## Screen Fields & Input Rules

### Section A: Pending Approvals Grid (Reviews Table)
| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| Applicant Name | Name of the employee requesting leave | Display field (linked to the employee's profile). |
| Leave Type & Dates | The type of leave and the requested date range | Display field (e.g., SL: 25-May to 27-May, 3 Days). |
| Current Level | The current stage of approval review | Display field (e.g., Level 1: HOD Review). |
| Current Status | The current state of the review request | Display status tag (Options: Pending / Under Review / Info Requested). |
| Action Button | Available actions for the supervisor | Click buttons: Approve / Reject / Ask for Clarification. |

### Section B: Action Detail Dialog (Review Pop-up Form)
| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| Action Remarks | Remarks or comments from the reviewer | Required if Rejected. Optional if Approved (e.g., "Work adjusted, approved"). |
| Lock Application? | Policy bypass and override toggle | Restricted to HR Directors/Super Admin. Toggle (Yes / No). Setting to "Yes" bypasses all remaining levels. |
| Chat/Remarks History | Message thread and audit log for the application | Displays system audit logs and sequential discussion messages in a historical timeline. |

---

## Business Rules & Validation Policies

1. **Approval Workflow Modes (ANY_ONE vs ALL):**
   - **ANY_ONE:** If three approvers are mapped to a level (e.g., 3 Admin staff), approval from any single member moves the request to the next level, marking it as skipped for the other two.
   - **ALL:** Every mapped approver at the level must approve. The request will not move to the next level until the last approver has confirmed.

2. **Rejection Interlock:**
   - If a request is rejected at any level of the approval chain, the application is immediately marked as `Rejected`. No further reviews are scheduled, and the system automatically releases the pending days back to the employee's available balance ledger.

3. **Clarification Loop (Info/Doc Requested):**
   - When a manager selects `Info Requested`, the application is routed back to the employee's inbox, and the status updates. Once the employee submits their response, the request returns to the manager's dashboard.

4. **Auto-Read Receipts:**
   - When a manager opens a specific leave details page, the system automatically marks the employee's messages as `Read At` and `Read By` to clear unread notification counters.

---

## Screen Workflows & Operations

### 1. Approving a Leave Request (Approve)
- The manager clicks "Review" next to a pending request on their portal dashboard.
- The manager reviews the request details, including employee leave balances, substitute teacher details, and historical leave patterns.
- The manager enters optional comments and clicks "Approve". The system updates the request to the next level. If it is the final level, the request status changes to `Approved` and the employee's balance ledger is updated.

### 2. Rejecting a Request
- The manager clicks "Reject".
- The manager must fill in the mandatory comments/remarks field in the pop-up window.
- The manager clicks Save. The request status updates to `Rejected` and the pending balances are reversed.

### 3. Asking for Documents / Clarification
- The manager selects "Ask for Info/Doc".
- The manager types the query in the chat window (e.g., "Please attach your medical prescription").
- The manager clicks Send. The status changes to `Doc Requested` and the request is routed back to the employee's self-service portal.

---

## Real-World Example Scenario

**Academic HOD Rajesh Kumar** is reviewing a Casual Leave request from science teacher **Shalini Sen**:

1. Rajesh opens the `Leave Approval Requests` screen and sees Shalini's CL request: `3 Days (25-May to 27-May)`.
2. Rajesh reviews the details:
   - Shalini has mapped Math Teacher `Vikram Rathore` as her substitute, and Vikram has accepted the substitution.
   - Shalini has `5 CL` available (verification passed).
3. Rajesh types a comment in the approval box: `Substitute teacher is assigned. Approved.` and clicks the "Approve" button.
4. Since the policy requires two levels of approval (Level 1: HOD, Level 2: Principal), the request is forwarded to the Principal's dashboard. The status updates to `Under Review` for Level 2, completing Rajesh's action for this request.
