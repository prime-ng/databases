# Employee Corrections — Requirement Document

## Screen Purpose & Overview

This screen is part of the Employee Attendance Management sub-menu. Its primary purpose is to manage time adjustments and attendance correction requests submitted by employees.

If an employee forgets to swipe on the biometric machine (e.g., they punched in but forgot to punch out), if the device fails to capture their swipe, or if they are marked with an incorrect daily status, they can submit a time adjustment request through this screen. Managers or HR verify and approve/reject these requests, which automatically updates the daily attendance sheet upon approval.

---

## Common Use Cases

1. **Forgetting to Punch (Forgot Swipe):** Submitting a request to insert the correct check-in or check-out time when an employee forgets to swipe their thumb/card at the device.
2. **Work From Home / On-Tour (Field Duty):** Adjusting attendance when an employee cannot punch at the campus due to a school meeting, field trip, or board examination duty.
3. **Correcting Incorrect Status:** Requesting an adjustment when an employee is mistakenly marked absent or late despite being present at work.
4. **Attaching Supporting Documents:** Attaching a digital copy of a gate pass, doctor's note, or off-duty permission slip to support the correction request.
5. **Manager Approval Workflow:** Routing the request to the designated supervisor for approval, which automatically updates the daily attendance dashboard upon sign-off.

---

## Screen Fields & Input Rules

### Section A: Request Form (Correction Details)
| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| Target Date | The date of the incorrect attendance record | Required. Must select a past date. Current or future dates are blocked. |
| Correction Type | Categorization of the correction request | Required. Dropdown: Forgot Punch In / Forgot Punch Out / Wrong Status / Time Adjustment / On Tour / Work From Home / Other. |
| Requested In-Time | The correct arrival time | Optional. HH:MM format (e.g., 08:30 AM). |
| Requested Out-Time | The correct departure time | Optional. HH:MM format (e.g., 02:30 PM). |
| Requested Status | The desired final attendance status | Optional. Dropdown: Present / Half Day / Present (On Duty). |
| Reason | Explanation for the correction | Required. Text input (e.g., "Official gate pass attached, left early for regional board meeting"). |
| Upload Permission Slip | Digital scan of approval document | Optional. PDF or image upload. Maximum file size: 2MB. |

### Section B: Approval & Action Details (Decision)
| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| Approval Status | The current state of the request | Display field. Options: Pending / Approved / Rejected / Cancelled. Defaults to 'Pending'. |
| Reviewer Remarks | Comments or justification from the manager | Required if the status is set to Rejected. Optional for approvals. |
| Action By | The manager who processed the request | Display field. Auto-populated with the manager's user ID. |
| Applied At | Timestamp of when the database was updated | Display field. Auto-generated timestamp of the approval action. |

---

## Business Rules & Validation Policies

1. **Automatic Timesheet Synchronization:**
   - Once the manager marks a request as `Approved`, the system backend automatically updates the corresponding check-in or check-out times in the daily attendance record.
   - Upon updating the time, the system automatically recalculates total working hours, late minutes, and early-out flags, and updates the daily attendance status (e.g., changing status from Late to Present).

2. **Mandatory Rejection Remarks:**
   - If a manager rejects a correction request, the system requires input in the *Reviewer Remarks* field. The system blocks rejection submissions if this field is empty. Rejections do not modify the daily attendance sheet.

3. **Past Date Verification:**
   - Correction requests are restricted to past dates. The system blocks employees from selecting today's date or future dates on the calendar.

---

## Screen Workflows & Operations

### 1. Submitting a Correction Request (Create)
- The employee opens their dashboard and clicks "+ Apply Correction".
- Selects the target date. The system displays the existing check-in/out times recorded for that date.
- Selects the Correction Type (e.g., Forgot Punch Out) and inputs the correct time.
- Inputs the reason, uploads a scanned gate pass or permission document, and clicks Submit.
- The request status is set to `Pending`, and a notification is sent to the supervisor's inbox.

### 2. Reviewing Requests (Approve / Reject)
- The Manager opens the pending request on their portal to review the details and attachments.
- **Approval:** The manager clicks "Approve". The status transitions to `Approved`, and the employee's timesheet is updated automatically.
- **Rejection:** The manager clicks "Reject", inputs the required rejection reason in the dialog box, and saves. The status transitions to `Rejected`.

---

## Real-World Example Scenario

**TGT Science Teacher Shalini Sen** was unable to log her check-out yesterday evening due to a biometric machine network failure, resulting in the system marking her as "Half Day":

1. Shalini opens the `Employee Corrections` screen and selects the date: `20-May-2026`.
2. Fills in the request form:
   - Correction Type: `Forgot Punch Out`.
   - Requested Out-Time: `02:30 PM` (her shift end time).
   - Reason: `Main gate biometric machine was hanging and not accepting fingerprints at 2:30 PM.`
3. Clicks Submit. The request status is set to `Pending`.
4. In the evening, the HR Manager reviews the request and verifies that the main gate biometric device went offline during checkout hours.
5. HR clicks the `Approve` button.
6. **System Action:** The system automatically inserts a check-out time of `02:30 PM` into Shalini's attendance log for May 20th, recalculates her hours, updates her status from "Half Day" to "Present", and sends an email notification.
