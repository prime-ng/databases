# Leave Applications — Requirement Document

## Screen Purpose & Overview

This screen is part of the Leave Management sub-menu. The main purpose of this screen is to provide a self-service portal for school employees and teachers, allowing them to apply for leave online, check the live status of their leave applications, and participate in discussion threads with managers regarding their requests.

Leave rules (such as notice period limits, balance verification, and holiday exclusions) are automatically applied by the system backend. The system calculates actual working leave days by excluding weekends and public holidays that fall within the leave period.

---

## Common Use Cases

1. **New Leave Request:** Submitting a new application for Sick Leave, Casual Leave, or Maternity Leave.
2. **Document Attachment:** Uploading medical certificates or supporting documents for leaves exceeding 3 days.
3. **Substitute Teacher Mapping:** Assigning a backup or substitute teacher to cover classes for the teacher going on leave.
4. **Draft & Cancel Options:** Saving requests as drafts or cancelling/withdrawing applications if plans change.
5. **Contextual Chat Panel:** Replying to queries from the HOD or HR (e.g., "Please hand over work details before leaving") directly within a dedicated chat window for that leave request.

---

## Screen Fields & Input Rules

### Section A: Leave Request Details (Leave Application Form)
| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| Leave Session | The academic or annual session under which the leave is requested | Required. Select the current active annual session (e.g., 2026-27). |
| Leave Type | The type of leave requested | Required. Dropdown options include: Casual Leave (CL) / Sick Leave (SL) / Earned Leave (EL) / Leave Without Pay (LWP). |
| Start Date (From Date) | The first day of the requested leave | Required. Date Picker. |
| End Date (To Date) | The last day of the requested leave | Required. Date Picker. Must be equal to or after the Start Date. |
| Is Half Day? | Indicates if only a half-day leave is required | Toggle button (Yes / No). Defaults to "No". |
| Half Day Slot | Specifies which half of the day is taken off | Required if *Is Half Day?* is set to "Yes". Options: Morning Slot / Afternoon Slot. |
| Is Emergency? | Bypasses standard notice period policies | Toggle button (Yes / No). If set to "Yes", the advance notice period validation rule is bypassed. |
| Total Leave Days | The calculated duration of the leave request | Auto-calculated by the system (excluding school holidays and weekly off-days/weekends). |
| Reason | The reason for requesting leave | Required. Text input (e.g., "Out of town for family function"). |
| Substitute Employee | The employee who will cover duties during the leave | Required if mandated by the leave policy. Selected from the list of active employees. (An employee cannot select themselves as their own substitute). |
| Upload Document | Supporting attachment (e.g., medical certificate) | Required if Sick Leave (SL) is 3 or more days. Supports PDF uploads (Max 10MB). |

### Section B: Status & Ledger Info
| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| Application Status | The current phase of the leave request | Display tag. Options: Draft / Submitted / Under Review / Approved / Rejected / Cancelled. |
| Pending With | The person currently responsible for the next decision | Display field showing the current active approver's name and role. |
| Available Balance | Remaining leave balance for the selected type | Display count. Real-time count of remaining days for the chosen Leave Type. |

---

## Business Rules & Validation Policies

1. **Working Days Calculation (Weekends & Holidays Auto-Exclude):**
   - If an employee applies for leave from `21-May-2026 (Thursday)` to `25-May-2026 (Monday)`, and `24-May` is a Sunday, and `22-May` is a gazetted holiday in the school calendar, the system will automatically calculate the `Total Leave Days` as `3 Days` (Sunday and the holiday are excluded from deduction).
   - If *Is Half Day?* is checked, the calculated count is automatically fixed at `0.5 Days`.

2. **Balance Validation Rule (Insufficient Balance Block):**
   - If an employee has only `2 days` of `Available Balance` left for a specific paid leave type (e.g., CL) and applies for `3 days`, the system will block the submission with an "Insufficient Balance" error. The employee must apply for LWP (Leave Without Pay) instead.

3. **Double Booking / Overlapping Check:**
   - Multiple leave applications cannot overlap on the same date range. If there is already a pending or approved leave request for any of the selected dates, a transaction error will be displayed.

4. **Advance Notice Period Policy:**
   - Non-emergency leave types require a minimum advance notice (for example, Earned Leave must be applied for at least 15 days in advance). If the notice period is not met, the request will be blocked unless the *Is Emergency?* toggle is set to "Yes".

---

## Screen Workflows & Operations

### 1. Applying for Leave (Apply)
- The employee opens the "Apply Leave" page from their self-service portal.
- They select the academic session, leave type, and date range. The system displays the real-time balance and calculated leave days in a side-panel.
- The employee selects a substitute employee and uploads medical or supporting documents if required.
- Upon clicking Submit, the system verifies backend checks (balance validation, overlap validation, required documents).
- If all checks pass, the application status becomes `Submitted`, the pending count increases in the balance ledger, and the request is routed to the first approval authority.

### 2. Cancelling / Withdrawing a Request (Cancel)
- If the leave has not been approved yet or plans change, the employee can click "Cancel Request".
- The application status changes to `Cancelled`, and the pending balance is automatically released and returned to the employee's available balance ledger.

---

## Real-World Example Scenario

**TGT Science Teacher Shalini Sen** needs to apply for 3 days of Casual Leave:

1. Shalini opens the `Leave Applications` screen on her portal.
2. She selects: Leave Type = `Casual Leave`, Dates = `25-May-2026` to `27-May-2026` (3 days).
3. The system verifies her balance: Shalini has `5 CL` remaining, so the balance check passes.
4. Since she is a Teacher and the Casual Leave policy mandates a substitute, she selects Math Teacher `Vikram Rathore` from the substitute dropdown.
5. She enters the reason: `Attending sibling's marriage`.
6. She clicks Submit.
7. The system updates her balance ledger by adding `3 days` to her pending count and routes the request to the Academic HOD for review. Her application status updates to `Submitted`.
