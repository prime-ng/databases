# Services — Apply Leave Tab Requirements

## 1. Functional Overview
Enables students to submit leave requests, track application progress, and communicate with teachers via timeline remark threads.

---

## 2. Directory Layout & Parameters

### A. Leave History List
- Lists applied leaves with leave type, dates, reason, status badge (Submitted, Under Review, Info Requested, Doc Requested, Approved, Rejected, Cancelled).

### B. New Leave Request Form
- **Leave Type**: Dropdown list of active leave types.
- **Dates**: Start Date & End Date fields.
- **Reason**: Detailed explanation.
- **Attachment**: Optional support document/image upload (Max 5MB).
- **Document Label**: Optional label for the uploaded document.

### C. Timeline Remarks Portal
- The details page displays the history of the request and acts as a messaging timeline with the teacher:
  - **Message box**: Submit questions or responses, and attach files.
  - **Action queries**: Respond directly to teacher queries (e.g. "Information Request" or "Document Request").
  - **Cancel action**: Cancel leave applications that are in a non-terminal status.

---

## 3. Database References
- **Models**:
  - `Modules\StudentProfile\Models\LeaveApplication`
  - `Modules\StudentProfile\Models\LeaveApplicationRemark`
- **Tables**:
  - `std_leave_applications`
  - `std_leave_remarks`
