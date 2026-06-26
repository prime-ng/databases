# Business Requirements Document (BRD)
## Module: Parent Portal
### Feature 03: Attendance & Leave Management

---

## 1. Executive Summary
Parents must be able to track their child's daily presence and formally apply for leaves (medical, casual) with supporting documentation.

## 2. Core Components
- `ParentAttendanceController.php`
- `ParentLeaveController.php`

---

## 3. Detailed Functional Requirements (FR)

### FR-01: Attendance Calendar (`ParentAttendanceController`)
- Displays a month-view calendar.
- Color codes days: Present (Green), Absent (Red), Half-Day (Yellow), Holiday (Gray).
- Provides a summary chart: Total Working Days vs Days Present to show the overall attendance percentage (to ensure the child meets the 75% exam criteria).

### FR-02: Leave Application (`ParentLeaveController`)
- **Submission:** Parent selects `start_date`, `end_date`, `leave_type` (e.g., Sick, Family Event), and enters a `reason`.
- **Attachments:** For medical leaves, the system accepts file uploads (Doctor's Note/Prescription) which are securely stored via Spatie Media Library.
- **Status Workflow:** Initially marked as `Pending`. The Class Teacher or Principal evaluates it on their dashboard.
- **Updates:** If approved, the child's attendance record for those future dates is automatically pre-marked as `On Leave` by the core Attendance module.

---

## 4. Acceptance Criteria
- **Given** my child is sick, **When** I apply for a 2-day leave and upload a medical certificate, **Then** the status shows as 'Pending'. **When** the class teacher approves it, **Then** I receive a notification and the calendar updates those two days to 'On Leave'.
