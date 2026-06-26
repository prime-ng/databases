# Business Requirements Document (BRD)
## Module: Parent Portal
### Feature 09: Mobile App API Architecture

---

## 1. Executive Summary
The Parent Portal is not just a web application; it powers a native mobile application (iOS/Android). The Mobile API controllers provide aggregated JSON payloads to minimize HTTP requests on mobile networks.

## 2. Core Components
- `MobileParentController.php`
- `ParentAttendanceApiController.php`
- `ParentLeaveApiController.php`
- `ParentPtmApiController.php`
- `ParentSessionApiController.php`

---

## 3. Detailed Functional Requirements (FR)

### FR-01: Aggregated Children Context (`GET /api/mobile/v1/parent/children`)
- **Purpose:** On app launch, the app needs to know all children linked to the parent.
- **Payload Design:** Rather than just returning IDs, the endpoint aggregates:
  - `name`, `class`, `section`, `rollNo`
  - `academicSession` (e.g., 2026-2027)
  - Array of `subjects` (resolved via `sch_subject_groups`)
- Indicates which child is the `active_child_id`.

### FR-02: Mega Dashboard Payload (`GET /api/mobile/v1/parent/dashboard`)
- **Purpose:** Prevents the mobile app from making 5 separate API calls to render the home screen.
- **Aggregated Modules:**
  - **Attendance:** Calculates YTD total days vs present days to return a clean `attendancePct` (e.g., 85%).
  - **Timetable:** Uses `TimetableCell` to return today's exact schedule, explicitly filtering out breaks (`is_break = false`).
  - **Homework:** Checks `HomeworkSubmission` to calculate the exact count of pending (unsubmitted) assignments.
  - **Exams:** Queries `ExamAllocation` to return the count of active upcoming exams.
  - **Fees:** Sums unpaid invoices to return a unified `totalPendingFee` amount.

### FR-03: Push Token Registration (`ParentSessionApiController`)
- When the parent installs the app, the mobile app sends its `device_token_fcm` (Firebase Cloud Messaging).
- The API registers this token into the `ppt_parent_sessions` table, mapping it to the `guardian_id`.
- If the token changes or expires, the app sends a refresh call to overwrite it.
- **Logout Sequence:** Drops the FCM token to ensure another parent logging into the same device doesn't receive the previous parent's alerts.

---

## 4. Acceptance Criteria
- **Given** I launch the Parent Mobile App, **When** the dashboard screen loads, **Then** it makes a single `GET /api/mobile/v1/parent/dashboard` call and receives my child's attendance %, today's classes, and my total pending fee balance in one unified JSON payload under 500ms.
