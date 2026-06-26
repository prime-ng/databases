# Business Requirements Document (BRD)
## Module: Parent Portal
### Feature: Academics & Communication

---

## 1. Executive Summary
Parents need real-time insight into their child's daily school life. This includes viewing attendance, downloading report cards, checking homework, booking PTM (Parent-Teacher Meeting) slots, and raising grievances.

## 2. Business Motive & Rules
- **Read-Only vs Read-Write:** Academic data (Results, Timetable, Homework) is read-only. Leaves, PTM bookings, and Complaints are read-write.
- **Security:** A parent must NEVER be able to see data for a student that does not belong to them.

---

## 3. Detailed Functional Requirements (FR)

### FR-01: Academic Viewers
- **`ParentResultController`:** Fetches Published `HpcReport` cards (from the MarksheetGeneration module) for the `active_student_id` and allows PDF download via the `Template` engine.
- **`ParentAttendanceController`:** Shows a calendar view of the child's attendance.
- **`ParentHomeworkController`:** Lists pending and submitted homework assignments.

### FR-02: Communication & Requests
- **`ParentLeaveController`:** Parents can apply for leaves on behalf of their child. The status transitions (Pending -> Approved/Rejected by Class Teacher).
- **`ParentComplaintController`:** Parents can raise tickets/grievances which route to the Admin/Principal dashboard.
- **`ParentPtmController`:** Fetches available PTM slots for the child's class teacher and allows the parent to reserve a 10-15 minute time block.

---

## 4. Agile User Stories & Acceptance Criteria

#### Story 1: Viewing Report Cards
**As a** Parent,
**I want to** download my child's Final Term marksheet from the portal,
**So that** I don't have to visit the school physically to collect it.

**Acceptance Criteria:**
- **Given** the School Admin has marked the Half-Yearly marksheet as "Published" in the HPC module, **When** I navigate to the Results tab in the Parent Portal, **Then** I see a "Download PDF" button that generates the marksheet using the school's configured HTML template.
