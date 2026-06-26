# Academics — My Attendance Tab Requirements

## 1. Functional Overview
Displays detailed class attendance statistics and monthly logs, showing whether the student was present, absent, late, or on leave.

---

## 2. Page Structure & Parameters

### A. Vitals summary
- **Total School Days**: Overall logged sessions.
- **Present Count**: Present status logs.
- **Absent Count**: Absent status logs.
- **Late Count**: Late arrivals count.
- **Leave Count**: Approved leave application days.
- **Present Percentage**: Present count divided by total school days.

### B. Monthly Grouped Logs
- Renders tables grouped by month (e.g. "March 2026"):
  - **Date & Day**: Date of session.
  - **Status Badge**:
    - `Present` (Green)
    - `Absent` (Red)
    - `Late` (Orange)
    - `Leave` (Blue)
    - `Half-Day` (Yellow)
  - **Remarks**: Class teacher comments or excuse logs.

---

## 3. Database References
- **Model**: `Modules\StudentProfile\Models\StudentAttendance`
- **Table**: `std_student_attendance`
- **Fields**:
  - `student_id`
  - `academic_session_id`
  - `attendance_date`
  - `status`
  - `remarks`
