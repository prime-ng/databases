# Attendance Module — Requirement Specification Document
**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Automated Extraction)
**Module Code:** ATT | **Module Type:** Tenant Module
**Table Prefix:** `att_*` | **Processing Mode:** RBS_ONLY (Greenfield — no code exists)
**RBS Reference:** Module F — Attendance Management (34 sub-tasks, lines 2283–2359)

---

## 1. Executive Summary

The Attendance module (ATT) is the daily operational backbone of school administration in Prime-AI. Indian K-12 schools are legally required to maintain attendance records as per CBSE/State Board regulations, including the 85% minimum attendance rule for eligibility to appear in board examinations. This module provides a comprehensive, multi-mode attendance management system covering student daily attendance, period-level subject attendance, teaching and non-teaching staff attendance, biometric/RFID device integration, automated parent notifications for absences, leave management workflows, compliance reporting, and AI-driven at-risk student identification.

**Implementation Statistics (Greenfield):**
- Controllers: 0 (not started)
- Models: 0 (not started)
- Services: 0 (not started)
- FormRequests: 0 (not started)
- Tests: 0 (not started)
- Completion: 0%

**All features are proposed (📐). No code, DDL, or tests exist yet.**

---

## 2. Module Overview

### 2.1 Business Purpose

The Attendance module serves every level of the school hierarchy. For teachers, it provides a fast, mobile-friendly interface to mark student attendance per period. For administrators, it delivers daily summaries, monthly registers, and government compliance reports. For parents, it sends real-time SMS/email alerts when their child is absent. For HR, it tracks staff check-in/check-out with biometric integration and flags regularization requests.

Key Indian regulatory requirements addressed:
- **85% attendance rule** — automatic flagging of students falling below threshold
- **Monthly attendance register** — government-format report (Columns: Roll No, Student Name, Days Present per Date, Total, Percentage)
- **Staff attendance for salary processing** — integration with HR & Payroll module
- **Leave eligibility** — leaves deducted from attendance percentage for board exam eligibility

### 2.2 Feature Summary

| Feature | Status |
|---------|--------|
| Student Daily Attendance (Present/Absent/Late/Half-Day) | 📐 Not Started |
| Student Period/Subject Attendance | 📐 Not Started |
| Bulk Attendance Upload (CSV) | 📐 Not Started |
| Attendance Correction Workflow | 📐 Not Started |
| Staff/Teacher Attendance (Check-In/Check-Out) | 📐 Not Started |
| Biometric/RFID Device Integration | 📐 Not Started |
| Staff Attendance Regularization | 📐 Not Started |
| Leave Types Master | 📐 Not Started |
| Student Leave Application & Approval | 📐 Not Started |
| Staff Leave Application & Approval | 📐 Not Started |
| Parent Notification on Absence (SMS/Email) | 📐 Not Started |
| Student Attendance Reports (Daily, Monthly, Term) | 📐 Not Started |
| Staff Attendance Reports | 📐 Not Started |
| At-Risk Student Analytics (below 75%/85%) | 📐 Not Started |
| Absentee Pattern Detection | 📐 Not Started |
| Government Compliance Report (Monthly Register) | 📐 Not Started |
| Holiday Calendar Integration | 📐 Not Started |

### 2.3 Menu Path

`Tenant Dashboard > Attendance`
- Student Attendance
  - Mark Attendance (Daily)
  - Mark Attendance (Period-wise)
  - Attendance Reports
  - Leave Applications
- Staff Attendance
  - Mark Staff Attendance
  - Regularization Requests
  - Staff Attendance Reports
- Settings
  - Leave Types
  - Biometric Devices
  - Notification Configuration
  - Attendance Rules

### 2.4 Architecture

```
[Teacher / Biometric Device]
    → Mark Student/Staff Attendance
    → att_student_attendances / att_staff_attendances (stored)
    → AttendanceObserver fires event: AttendanceMarkedAbsent
    → NotificationService: sends SMS/Email to parent via NTF module
    → AnalyticsService: recalculates att_student_analytics for threshold check

[Admin]
    → Pulls attendance registers and compliance reports
    → Runs monthly aggregate jobs
    → Approves leave applications

[Student/Parent Portal]
    → Submits leave applications
    → Views attendance history and percentage
```

---

## 3. Stakeholders & Actors

| Actor | Role | Access Level |
|-------|------|-------------|
| School Admin | Full attendance management | Full CRUD across all attendance, reports, settings |
| Class Teacher | Marks daily attendance for own class-section | Mark, view, correct (own class only) |
| Subject Teacher | Marks period attendance for own subject | Mark, view (own subject + class only) |
| Department Head | Views staff attendance for own department | Read: department-level reports |
| HR Admin | Manages staff attendance, regularizations | CRUD: staff attendance, leave approvals |
| Principal | Approves attendance corrections and escalated leaves | Approve/Reject: corrections, leaves |
| Student | Views own attendance, submits leave requests | Read: own data; Create: leave application |
| Parent/Guardian | Views child's attendance, receives notifications | Read: own child data only |
| System (automated) | Biometric sync, threshold alerts, monthly aggregation | System-level insert/update only |

---

## 4. Functional Requirements

### FR-ATT-001: Student Daily Attendance Marking

**RBS Ref:** F.F1.1, F.F1.2

**REQ-ATT-001.1 — Mark Daily Attendance**
- The system shall allow a class teacher or admin to mark daily attendance for all students in a class-section for a given date.
- Attendance statuses: `present`, `absent`, `late`, `half_day`, `excused`, `holiday`.
- Only one daily attendance record per student per date per class-section is permitted.
- The system shall support bulk marking: "Mark All Present" with individual overrides.
- Attendance date must not be a future date. Past-date attendance requires a correction request (see REQ-ATT-003).
- The system shall auto-populate class roster from `std_student_academic_sessions` filtered by the active academic session and the selected class-section.

**REQ-ATT-001.2 — Bulk Attendance CSV Upload**
- Admin may upload a CSV file containing: `roll_no`, `student_id`, `status`, `remarks`.
- System shall validate roll numbers against active roster; invalid rows are flagged in an error report before import.
- On successful validation, bulk insert proceeds as individual records with `source = 'csv_import'`.

**REQ-ATT-001.3 — Attendance Status Logic**
- `late` status is still counted as present for percentage calculation but flagged separately.
- `half_day` counts as 0.5 days present.
- `excused` (via approved leave) does not reduce attendance percentage.
- `holiday` is set by the system via calendar integration — no manual marking needed.

**Acceptance Criteria:**
- Given a teacher selects Class 8A on 25-Mar-2026, the system shows the full student roster. Marking all present and saving creates 35 `att_student_attendances` records.
- Given roll no 12 is marked absent, the system fires `AttendanceMarkedAbsent` event for that student within 1 minute.
- Given a CSV is uploaded with 5 invalid roll numbers, those 5 rows are rejected; remaining valid rows are imported.

**Test Cases:**
- TC-ATT-001.1: Mark full class present → 35 records created, all `status = 'present'`.
- TC-ATT-001.2: Duplicate marking same student same date → UNIQUE constraint violation, system shows error.
- TC-ATT-001.3: CSV import with mixed valid/invalid → only valid rows inserted, error report returned.
- TC-ATT-001.4: Future date selection → system rejects with validation error.

---

### FR-ATT-002: Student Period/Subject Attendance

**RBS Ref:** F.F2.1

**REQ-ATT-002.1 — Period-Level Attendance**
- Subject teachers shall mark attendance per timetable period (period_id linked to timetable).
- Period attendance is independent of daily attendance but syncs: if a student is absent for all periods in a day, daily status is auto-updated to `absent`.
- The system shall auto-fill all students as present by default; teacher marks only absences.
- If a student is already marked absent for the day (daily attendance), all their period rows auto-fill as `absent`.

**REQ-ATT-002.2 — Period Attendance Sync**
- If period-level attendance records exist for a day and daily attendance has not yet been marked, the system shall compute daily status as: present if ≥ 1 period present; absent if 0 periods present.
- Subject-level attendance percentage = (periods present / total periods for that subject) × 100.

**Acceptance Criteria:**
- Given Math teacher marks 3 students absent in period 3, those 3 records are created in `att_student_attendances` with `period_id = 3`.
- Given a student is absent for all 6 periods, daily status auto-updates to `absent`.

**Test Cases:**
- TC-ATT-002.1: Mark period attendance → records with correct period_id created.
- TC-ATT-002.2: All periods absent → daily auto-update to absent triggers.
- TC-ATT-002.3: Partial absence across periods → daily remains 'present'.

---

### FR-ATT-003: Attendance Correction Workflow

**RBS Ref:** F.F1.2

**REQ-ATT-003.1 — Correction Request**
- A teacher, student, or parent may submit an attendance correction request for a past date.
- Request fields: `student_id`, `attendance_date`, `current_status`, `requested_status`, `reason`, optional supporting document (FK to `sys_media`).
- Requests cannot be raised for attendance records older than 30 days (configurable via settings).

**REQ-ATT-003.2 — Correction Approval**
- Class teacher reviews and approves/rejects.
- If rejected by teacher, requester is notified.
- If approved by teacher, admin/principal final approval is required for status changes that affect compliance (e.g., absent → present for dates in the current month).
- On final approval, the original `att_student_attendances` record is updated and a snapshot of the original value is stored in `att_correction_requests` for audit.

**Acceptance Criteria:**
- Given a parent submits a correction for 20-Mar-2026 (absent → excused), request enters 'pending_teacher' state.
- Given teacher approves and admin approves, original record is updated to `excused` and audit log records old and new values.

**Test Cases:**
- TC-ATT-003.1: Correction request for date > 30 days old → rejected with validation error.
- TC-ATT-003.2: Full approval chain → record updated, audit log entry created.
- TC-ATT-003.3: Teacher rejection → status = 'rejected', requester notified.

---

### FR-ATT-004: Staff/Teacher Attendance

**RBS Ref:** F.F4.1, F.F4.2

**REQ-ATT-004.1 — Staff Check-In/Check-Out**
- Staff attendance records `check_in_time` and `check_out_time` per working day.
- Status: `present`, `absent`, `late`, `on_leave`, `half_day`, `work_from_home`, `on_duty`.
- A staff member cannot have two check-in records on the same date; the system updates the existing record.
- `working_hours` computed column = `check_out_time - check_in_time` (in minutes, NULL if check-out missing).

**REQ-ATT-004.2 — Regularization**
- If biometric sync fails or staff forgets to check in/out, they submit a regularization request with: `date`, `expected_check_in`, `expected_check_out`, `reason`.
- HR admin approves/rejects. On approval, `att_staff_attendances` is updated.
- Regularization requests are capped at 3 per month per employee (configurable).

**Acceptance Criteria:**
- Given biometric device syncs check-in at 08:45, a record is created with `source = 'biometric'`, `check_in_time = 08:45`.
- Given HR approves a regularization request, the original record is updated with regularized times and `source` updated to `'regularized'`.

**Test Cases:**
- TC-ATT-004.1: Biometric check-in → record created with correct source and time.
- TC-ATT-004.2: Duplicate check-in same date → updates existing record, no duplicate.
- TC-ATT-004.3: Regularization > 3 per month → system rejects with business rule error.

---

### FR-ATT-005: Biometric/RFID Device Integration

**RBS Ref:** F.F4.1 (ST.F4.1.2.1, ST.F4.1.2.2)

**REQ-ATT-005.1 — Device Master**
- Admin shall register biometric/RFID/NFC devices with: `device_name`, `device_code` (unique), `location`, `device_type` (biometric/rfid/nfc/manual), `ip_address`, `port`, `api_endpoint`, `auth_token_encrypted`.
- Device status: `online`, `offline`, `maintenance`. Auto-detected via periodic ping.

**REQ-ATT-005.2 — Sync Mechanism**
- Devices push attendance logs via HTTP POST to `/api/v1/attendance/device-sync` (Sanctum API key auth).
- Sync payload: `device_code`, `employee_id` or `student_id`, `timestamp`, `direction` (in/out).
- System processes sync records and creates/updates `att_staff_attendances` or `att_student_attendances` with `source = 'biometric'`.
- Anomaly detection: if check-in time is > 30 minutes after school start, flag as `late`. If two consecutive check-ins within 5 minutes, treat as duplicate and ignore.

**REQ-ATT-005.3 — RFID for Student Attendance**
- Students with RFID/smart card (`std_students.smart_card_id`) can tap in at class entry points.
- System maps `smart_card_id` to `student_id` and creates attendance record.

**Acceptance Criteria:**
- Given device `BIO-001` posts a sync event for employee `EMP-042` at 08:52, a staff attendance record is created with `source = 'biometric'`, `check_in_time = 08:52`, flagged `late = true` (if school starts at 08:30).
- Given duplicate sync within 5 minutes for same employee → second record silently ignored.

**Test Cases:**
- TC-ATT-005.1: Valid device sync payload → attendance record created.
- TC-ATT-005.2: Invalid device_code → 401 Unauthorized returned.
- TC-ATT-005.3: Duplicate within 5 min → ignored, no duplicate record.

---

### FR-ATT-006: Leave Management

**RBS Ref:** F.F4.2 (ST.F4.2.1.1, ST.F4.2.1.2)

**REQ-ATT-006.1 — Leave Types Master**
- Admin shall maintain a leave types master: `name`, `code`, `max_days_per_year`, `max_consecutive_days`, `is_paid`, `applicable_to` (student/staff/both), `requires_document`, `accrual_type` (fixed/accrual/none), `carry_forward_limit`.
- System seeds default leave types: Medical Leave (ML), Casual Leave (CL), Earned Leave (EL), Maternity Leave (MatL), Paternity Leave (PatL), Student Medical Leave (SML), Student Personal Leave (SPL).

**REQ-ATT-006.2 — Student Leave Application**
- Student or parent submits a leave application: `leave_type_id`, `from_date`, `to_date`, `reason`, optional medical certificate (sys_media FK).
- Class teacher approves/rejects. For leaves > 3 consecutive days, Principal must also approve.
- On approval, the system creates `att_student_attendances` records with `status = 'excused'` for each school working day in the date range.
- Leave balance is tracked in `att_leave_balances` per academic session.

**REQ-ATT-006.3 — Staff Leave Application**
- Same workflow as student but HR admin + Department Head in approval chain.
- On approval, `att_staff_attendances` records are updated to `status = 'on_leave'`.
- Leave deduction from `att_leave_balances.balance_days`.
- Half-day leave supported: sets `half_day_type` = 'morning' or 'afternoon'.

**Acceptance Criteria:**
- Given student applies for 3-day medical leave with doctor's certificate, teacher approves → 3 `att_student_attendances` records set to `excused`, leave balance decremented by 3.
- Given staff applies for 5 consecutive days (> 3), both HR admin and Principal approval required.

**Test Cases:**
- TC-ATT-006.1: Student leave approved → attendance records created as 'excused' for each working day.
- TC-ATT-006.2: Leave exceeds max_consecutive_days → system rejects at application stage.
- TC-ATT-006.3: Leave balance exhausted → system warns but still allows application (with override flag).

---

### FR-ATT-007: Parent Notification on Absence

**RBS Ref:** F.F3.2

**REQ-ATT-007.1 — Automatic Absence Notification**
- When a student is marked `absent` (status = 'absent'), the system shall fire event `ATTENDANCE_MARKED_ABSENT` to the Notification module (NTF).
- Notification payload: `student_name`, `class_section`, `attendance_date`, `period` (if period-level), `school_name`.
- Default channels: SMS to parent's registered mobile number + In-App notification to parent portal.
- Notification is suppressed if: (a) the absence already has an approved leave, (b) parent has opted out of attendance notifications.

**REQ-ATT-007.2 — Late Arrival Alert**
- When a student is marked `late`, a separate lighter-tone notification (Late Arrival Alert) is sent.
- Configurable per school: admin can disable late arrival alerts independently of absence alerts.

**REQ-ATT-007.3 — Notification Logging**
- Every notification attempt is logged in `att_notification_logs` with: `student_id`, `attendance_id`, `channel`, `sent_at`, `delivery_status`.

**Acceptance Criteria:**
- Given student ID 155 marked absent on 25-Mar-2026, within 2 minutes parent receives SMS: "Dear Parent, Rahul (Class 8A) was absent on 25-Mar-2026. Please contact the school. — Prime School."
- Given student already has an approved leave for that date, no notification is sent.

**Test Cases:**
- TC-ATT-007.1: Student marked absent → NTF event fired within 60 seconds.
- TC-ATT-007.2: Student on approved leave → no notification fired.
- TC-ATT-007.3: Parent opted out → notification suppressed, log records `status = 'suppressed'`.

---

### FR-ATT-008: Attendance Analytics & At-Risk Identification

**RBS Ref:** F.F3.1, F.F3.2 (ST.F3.1.2.1, ST.F3.1.2.2)

**REQ-ATT-008.1 — Attendance Percentage Calculation**
- System maintains `att_student_analytics` with running totals per student per academic session: `total_working_days`, `days_present`, `days_absent`, `days_late`, `days_excused`, `attendance_percentage`.
- `attendance_percentage` = ((days_present + days_excused + 0.5 × days_late) / total_working_days) × 100.
- Recalculated on every attendance mark event via a queued job `RecalculateStudentAnalyticsJob`.

**REQ-ATT-008.2 — At-Risk Flagging**
- Students with `attendance_percentage` < 75% are flagged `at_risk_level = 'critical'`.
- Students with percentage between 75% and 85% are flagged `at_risk_level = 'warning'`.
- Above 85% = `at_risk_level = 'normal'`.
- Weekly automated report of at-risk students is sent to class teachers and Principal via NTF module.

**REQ-ATT-008.3 — Absentee Pattern Detection**
- Detect students absent on the same weekday repeatedly (e.g., absent every Monday for 4 consecutive weeks).
- Detect long absence streaks (> 3 consecutive school days).
- Flag such patterns in `att_student_analytics.pattern_flags` JSON field.

**REQ-ATT-008.4 — Staff Attendance Analytics**
- `att_staff_analytics` tracks per-employee: `total_working_days`, `days_present`, `avg_check_in_time`, `late_arrivals_count`, `early_departures_count`, `absent_count`.
- Department-level aggregation view for HR reports.

**Acceptance Criteria:**
- Given student Rahul has 60 days present out of 80 working days (75%), system flags him as `at_risk_level = 'warning'`.
- Given weekly job runs, class teacher of 8A receives list of at-risk students in their class.

**Test Cases:**
- TC-ATT-008.1: 59/80 days present → percentage = 73.75%, flagged 'critical'.
- TC-ATT-008.2: Pattern detection: absent on 4 consecutive Mondays → pattern_flags includes `{"type": "weekday_pattern", "day": "Monday"}`.
- TC-ATT-008.3: Analytics recalculated after attendance edit → new percentage reflects change.

---

### FR-ATT-009: Attendance Reports & Government Compliance

**RBS Ref:** F.F3.1, F.F5.1

**REQ-ATT-009.1 — Student Attendance Reports**
- Daily attendance report: class-section-wise, shows count present/absent/late per day.
- Monthly attendance summary: student-wise, columns = dates, cells = P/A/L/H, footer = total + percentage.
- Term-wise and annual attendance report with percentage per student.
- Date-range filter, class filter, section filter, individual student filter.
- Export formats: PDF (DomPDF) and Excel (Laravel Excel / CSV).

**REQ-ATT-009.2 — Government Compliance Report**
- Monthly Attendance Register in the format mandated by CBSE/State Boards:
  - Columns: S.No., Admission No., Student Name, then one column per calendar day (1-31), Total Present, Total Working Days, Percentage.
  - Cells: P (present), A (absent), H (holiday), L (leave), HH (half-day).
  - Footer row: count of students present per day.
- Must be exportable as PDF (A3 landscape) with school letterhead and teacher/principal signature blocks.

**REQ-ATT-009.3 — Staff Attendance Reports**
- Daily staff attendance report: department-wise, shows check-in/check-out times, late arrivals.
- Monthly working hours summary: employee-wise total working hours per month.
- Department-level absenteeism analysis.

**Acceptance Criteria:**
- Given admin selects Class 10B for March 2026, monthly register PDF is generated in ≤ 10 seconds with correct P/A/H values for all 35 students across all 26 working days.
- Given term-wise report requested, system calculates from first day of term to today's date.

**Test Cases:**
- TC-ATT-009.1: Monthly register for 40 students, 26 days → correct cell values, correct percentage column.
- TC-ATT-009.2: Date range report for 3 months → aggregates correctly across months.
- TC-ATT-009.3: PDF export → generates without error, includes school name and month header.

---

### FR-ATT-010: Attendance Settings & Holiday Calendar Integration

**RBS Ref:** (Domain knowledge — module configuration)

**REQ-ATT-010.1 — Attendance Rules Configuration**
- Admin shall configure per-school:
  - School start time (used for late detection)
  - Grace period for late arrival (e.g., 15 minutes after start = still counted as 'on time')
  - Minimum attendance percentage for exam eligibility (default 85%)
  - At-risk warning threshold (default 75%)
  - Maximum correction request age (default 30 days)
  - Regularization requests per month limit (default 3)

**REQ-ATT-010.2 — Holiday Calendar Integration**
- The system shall read holiday/non-working days from Academic Calendar (ACD module: `acd_calendar_events` with `is_working_day = 0`).
- When computing working days and attendance percentage, holidays are excluded from the denominator.
- If the ACD module is not licensed, admin manually flags dates as holidays in `att_holiday_overrides`.

**Acceptance Criteria:**
- Given school sets grace period to 15 min and start time 08:30, a check-in at 08:44 is recorded as `present` (not late); 08:46 is recorded as `late`.
- Given Holi (17-Mar-2026) is marked as holiday in ACD calendar, March attendance denominator for students reduces by 1 day.

---

## 5. Data Model

### 5.1 Table: `att_student_attendances` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK→glb_academic_sessions | |
| org_session_id | INT UNSIGNED | NOT NULL, FK→sch_org_academic_sessions_jnt | School-specific session |
| class_section_id | INT UNSIGNED | NOT NULL, FK→sch_class_section_jnt | |
| student_id | INT UNSIGNED | NOT NULL, FK→std_students | |
| attendance_date | DATE | NOT NULL | |
| period_id | INT UNSIGNED | NULL, FK→tt_period_types | NULL = daily; set for period-level |
| subject_id | INT UNSIGNED | NULL, FK→sch_subjects | Set for period-level marking |
| status | ENUM('present','absent','late','half_day','excused','holiday') | NOT NULL | |
| half_day_type | ENUM('morning','afternoon') | NULL | Set when status = half_day |
| source | ENUM('manual','biometric','rfid','csv_import','system') | NOT NULL DEFAULT 'manual' | How attendance was recorded |
| device_id | INT UNSIGNED | NULL, FK→att_biometric_devices | Set for biometric/RFID source |
| remarks | VARCHAR(255) | NULL | |
| marked_by | BIGINT UNSIGNED | NULL, FK→sys_users | Teacher/admin who marked |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | Soft delete |
| **UNIQUE KEY** | (class_section_id, student_id, attendance_date, period_id) | | Prevents duplicates |

### 5.2 Table: `att_staff_attendances` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | |
| employee_id | INT UNSIGNED | NOT NULL, FK→sch_employees | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK→glb_academic_sessions | |
| attendance_date | DATE | NOT NULL | |
| check_in_time | TIME | NULL | |
| check_out_time | TIME | NULL | |
| working_minutes | INT UNSIGNED | NULL (computed) | check_out − check_in in minutes |
| status | ENUM('present','absent','late','half_day','on_leave','work_from_home','on_duty') | NOT NULL DEFAULT 'absent' | |
| half_day_type | ENUM('morning','afternoon') | NULL | |
| source | ENUM('manual','biometric','rfid','regularized','system') | NOT NULL DEFAULT 'manual' | |
| device_id | INT UNSIGNED | NULL, FK→att_biometric_devices | |
| is_regularized | TINYINT(1) | NOT NULL DEFAULT 0 | Updated on regularization approval |
| regularization_id | INT UNSIGNED | NULL, FK→att_regularization_requests | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |
| **UNIQUE KEY** | (employee_id, attendance_date) | | One record per employee per day |

### 5.3 Table: `att_biometric_devices` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| device_name | VARCHAR(100) | NOT NULL | |
| device_code | VARCHAR(30) | NOT NULL, UNIQUE | Used in API sync |
| location | VARCHAR(100) | NULL | e.g., 'Main Gate', 'Staff Room' |
| device_type | ENUM('biometric','rfid','nfc','manual') | NOT NULL DEFAULT 'biometric' | |
| applicable_to | ENUM('student','staff','both') | NOT NULL DEFAULT 'staff' | |
| ip_address | VARCHAR(45) | NULL | IPv4 or IPv6 |
| port | SMALLINT UNSIGNED | NULL DEFAULT 80 | |
| api_endpoint | VARCHAR(255) | NULL | Device's push endpoint URL |
| auth_token_encrypted | TEXT | NULL | Encrypted auth token |
| device_status | ENUM('online','offline','maintenance') | NOT NULL DEFAULT 'offline' | |
| last_sync_at | TIMESTAMP | NULL | Last successful sync |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |

### 5.4 Table: `att_leave_types` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| name | VARCHAR(100) | NOT NULL | e.g., 'Medical Leave' |
| code | VARCHAR(10) | NOT NULL, UNIQUE | e.g., 'ML', 'CL', 'EL' |
| applicable_to | ENUM('student','staff','both') | NOT NULL DEFAULT 'both' | |
| max_days_per_year | TINYINT UNSIGNED | NOT NULL DEFAULT 12 | |
| max_consecutive_days | TINYINT UNSIGNED | NOT NULL DEFAULT 5 | |
| is_paid | TINYINT(1) | NOT NULL DEFAULT 1 | |
| requires_document | TINYINT(1) | NOT NULL DEFAULT 0 | e.g., Medical cert for ML |
| affects_attendance_pct | TINYINT(1) | NOT NULL DEFAULT 0 | 0 = excused leave does not reduce % |
| accrual_type | ENUM('fixed','accrual','none') | NOT NULL DEFAULT 'fixed' | |
| carry_forward_limit | TINYINT UNSIGNED | NOT NULL DEFAULT 0 | Max days to carry to next year |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |

### 5.5 Table: `att_leave_applications` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | |
| applicant_type | ENUM('student','staff') | NOT NULL | |
| student_id | INT UNSIGNED | NULL, FK→std_students | Set when applicant_type = 'student' |
| employee_id | INT UNSIGNED | NULL, FK→sch_employees | Set when applicant_type = 'staff' |
| leave_type_id | INT UNSIGNED | NOT NULL, FK→att_leave_types | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK→glb_academic_sessions | |
| from_date | DATE | NOT NULL | |
| to_date | DATE | NOT NULL | |
| total_days | TINYINT UNSIGNED | NOT NULL | Calculated: working days in range |
| is_half_day | TINYINT(1) | NOT NULL DEFAULT 0 | |
| half_day_type | ENUM('morning','afternoon') | NULL | |
| reason | TEXT | NOT NULL | |
| document_media_id | INT UNSIGNED | NULL, FK→sys_media | Supporting document |
| status | ENUM('pending','pending_principal','approved','rejected','cancelled') | NOT NULL DEFAULT 'pending' | |
| reviewed_by | BIGINT UNSIGNED | NULL, FK→sys_users | Class teacher / HR admin |
| reviewed_at | TIMESTAMP | NULL | |
| review_remarks | VARCHAR(255) | NULL | |
| approved_by | BIGINT UNSIGNED | NULL, FK→sys_users | Principal / Admin |
| approved_at | TIMESTAMP | NULL | |
| approval_remarks | VARCHAR(255) | NULL | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |

### 5.6 Table: `att_leave_balances` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| applicant_type | ENUM('student','staff') | NOT NULL | |
| student_id | INT UNSIGNED | NULL, FK→std_students | |
| employee_id | INT UNSIGNED | NULL, FK→sch_employees | |
| leave_type_id | INT UNSIGNED | NOT NULL, FK→att_leave_types | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK→glb_academic_sessions | |
| entitled_days | TINYINT UNSIGNED | NOT NULL | From leave type + carry forward |
| used_days | DECIMAL(4,1) | NOT NULL DEFAULT 0.0 | Incremented on leave approval |
| balance_days | DECIMAL(4,1) | NOT NULL DEFAULT 0.0 | Computed: entitled − used |
| carry_forward_days | TINYINT UNSIGNED | NOT NULL DEFAULT 0 | From previous session |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| **UNIQUE KEY** | (applicant_type, student_id, employee_id, leave_type_id, academic_session_id) | | |

### 5.7 Table: `att_correction_requests` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | |
| attendance_id | BIGINT UNSIGNED | NOT NULL, FK→att_student_attendances | |
| student_id | INT UNSIGNED | NOT NULL, FK→std_students | |
| attendance_date | DATE | NOT NULL | For display |
| original_status | ENUM('present','absent','late','half_day','excused') | NOT NULL | Snapshot of value before correction |
| requested_status | ENUM('present','absent','late','half_day','excused') | NOT NULL | |
| reason | TEXT | NOT NULL | |
| document_media_id | INT UNSIGNED | NULL, FK→sys_media | |
| requested_by | BIGINT UNSIGNED | NOT NULL, FK→sys_users | Initiator |
| status | ENUM('pending','approved','rejected') | NOT NULL DEFAULT 'pending' | |
| reviewed_by | BIGINT UNSIGNED | NULL, FK→sys_users | Teacher reviewer |
| reviewed_at | TIMESTAMP | NULL | |
| approved_by | BIGINT UNSIGNED | NULL, FK→sys_users | Admin final approval |
| approved_at | TIMESTAMP | NULL | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |

### 5.8 Table: `att_regularization_requests` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| employee_id | INT UNSIGNED | NOT NULL, FK→sch_employees | |
| attendance_date | DATE | NOT NULL | |
| expected_check_in | TIME | NULL | |
| expected_check_out | TIME | NULL | |
| reason | TEXT | NOT NULL | |
| status | ENUM('pending','approved','rejected') | NOT NULL DEFAULT 'pending' | |
| reviewed_by | BIGINT UNSIGNED | NULL, FK→sys_users | HR admin |
| reviewed_at | TIMESTAMP | NULL | |
| remarks | VARCHAR(255) | NULL | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |

### 5.9 Table: `att_notification_logs` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | |
| student_id | INT UNSIGNED | NOT NULL, FK→std_students | |
| attendance_id | BIGINT UNSIGNED | NOT NULL, FK→att_student_attendances | |
| guardian_id | INT UNSIGNED | NULL, FK→std_guardians | Which parent was notified |
| notification_type | ENUM('absence','late_arrival','at_risk_warning','weekly_summary') | NOT NULL | |
| channel | ENUM('sms','email','in_app','push') | NOT NULL | |
| sent_at | TIMESTAMP | NULL | |
| delivery_status | ENUM('queued','sent','delivered','failed','suppressed') | NOT NULL DEFAULT 'queued' | |
| ntf_delivery_id | INT UNSIGNED | NULL | FK to NTF module delivery log |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |

### 5.10 Table: `att_student_analytics` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | |
| student_id | INT UNSIGNED | NOT NULL, FK→std_students | |
| class_section_id | INT UNSIGNED | NOT NULL, FK→sch_class_section_jnt | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK→glb_academic_sessions | |
| total_working_days | SMALLINT UNSIGNED | NOT NULL DEFAULT 0 | Computed from calendar |
| days_present | SMALLINT UNSIGNED | NOT NULL DEFAULT 0 | |
| days_absent | SMALLINT UNSIGNED | NOT NULL DEFAULT 0 | |
| days_late | SMALLINT UNSIGNED | NOT NULL DEFAULT 0 | Counted as present |
| days_half_day | SMALLINT UNSIGNED | NOT NULL DEFAULT 0 | Counted as 0.5 |
| days_excused | SMALLINT UNSIGNED | NOT NULL DEFAULT 0 | Approved leave days |
| attendance_percentage | DECIMAL(5,2) | NOT NULL DEFAULT 0.00 | Recalculated on each attendance event |
| at_risk_level | ENUM('normal','warning','critical') | NOT NULL DEFAULT 'normal' | |
| pattern_flags | JSON | NULL | e.g., {"weekday_pattern": "Monday", "streak": 4} |
| last_calculated_at | TIMESTAMP | NULL | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| **UNIQUE KEY** | (student_id, academic_session_id) | | |

### 5.11 Table: `att_staff_analytics` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| employee_id | INT UNSIGNED | NOT NULL, FK→sch_employees | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK→glb_academic_sessions | |
| total_working_days | SMALLINT UNSIGNED | NOT NULL DEFAULT 0 | |
| days_present | SMALLINT UNSIGNED | NOT NULL DEFAULT 0 | |
| days_absent | SMALLINT UNSIGNED | NOT NULL DEFAULT 0 | |
| days_on_leave | SMALLINT UNSIGNED | NOT NULL DEFAULT 0 | Approved leave |
| late_arrivals_count | SMALLINT UNSIGNED | NOT NULL DEFAULT 0 | |
| avg_check_in_time | TIME | NULL | Average over present days |
| total_working_minutes | INT UNSIGNED | NOT NULL DEFAULT 0 | |
| attendance_percentage | DECIMAL(5,2) | NOT NULL DEFAULT 0.00 | |
| last_calculated_at | TIMESTAMP | NULL | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| **UNIQUE KEY** | (employee_id, academic_session_id) | | |

### 5.12 Table: `att_settings` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| school_start_time | TIME | NOT NULL DEFAULT '08:30:00' | |
| grace_period_minutes | TINYINT UNSIGNED | NOT NULL DEFAULT 15 | |
| min_attendance_pct_exam | DECIMAL(5,2) | NOT NULL DEFAULT 85.00 | Exam eligibility threshold |
| at_risk_warning_pct | DECIMAL(5,2) | NOT NULL DEFAULT 75.00 | |
| at_risk_critical_pct | DECIMAL(5,2) | NOT NULL DEFAULT 65.00 | |
| max_correction_age_days | TINYINT UNSIGNED | NOT NULL DEFAULT 30 | |
| max_regularization_per_month | TINYINT UNSIGNED | NOT NULL DEFAULT 3 | |
| send_absence_sms | TINYINT(1) | NOT NULL DEFAULT 1 | |
| send_late_arrival_alert | TINYINT(1) | NOT NULL DEFAULT 1 | |
| absence_notification_delay_minutes | TINYINT UNSIGNED | NOT NULL DEFAULT 5 | Delay before firing notification |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |

### 5.13 Table: `att_holiday_overrides` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| holiday_date | DATE | NOT NULL, UNIQUE | |
| holiday_name | VARCHAR(100) | NOT NULL | |
| is_full_day | TINYINT(1) | NOT NULL DEFAULT 1 | 0 = half-day |
| applicable_to | ENUM('all','students','staff') | NOT NULL DEFAULT 'all' | |
| note | VARCHAR(255) | NULL | |
| academic_session_id | INT UNSIGNED | NULL, FK→glb_academic_sessions | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |

---

## 6. API & Route Specification

**All routes are proposed (📐). No routes exist yet.**

```
Route::middleware(['auth', 'verified', 'EnsureTenantHasModule:attendance'])
    ->prefix('attendance')
    ->name('attendance.')
    ->group(function () {

    // ── STUDENT ATTENDANCE ─────────────────────────────────────────
    GET    /student                              → StudentAttendanceController@index          attendance.student.index
    GET    /student/mark                         → StudentAttendanceController@markForm       attendance.student.mark
    POST   /student/mark                         → StudentAttendanceController@store          attendance.student.store
    GET    /student/{attendance}                 → StudentAttendanceController@show           attendance.student.show
    PUT    /student/{attendance}                 → StudentAttendanceController@update         attendance.student.update
    POST   /student/bulk-import                  → StudentAttendanceController@bulkImport     attendance.student.bulkImport

    // ── PERIOD ATTENDANCE ──────────────────────────────────────────
    GET    /student/period/mark                  → PeriodAttendanceController@markForm        attendance.period.mark
    POST   /student/period/mark                  → PeriodAttendanceController@store           attendance.period.store

    // ── CORRECTION REQUESTS ────────────────────────────────────────
    GET    /corrections                          → CorrectionRequestController@index          attendance.correction.index
    POST   /corrections                          → CorrectionRequestController@store          attendance.correction.store
    PUT    /corrections/{correction}/review      → CorrectionRequestController@review         attendance.correction.review
    PUT    /corrections/{correction}/approve     → CorrectionRequestController@approve        attendance.correction.approve

    // ── STAFF ATTENDANCE ──────────────────────────────────────────
    GET    /staff                                → StaffAttendanceController@index            attendance.staff.index
    POST   /staff/mark                           → StaffAttendanceController@store            attendance.staff.store
    PUT    /staff/{attendance}                   → StaffAttendanceController@update           attendance.staff.update

    // ── REGULARIZATION ────────────────────────────────────────────
    GET    /staff/regularization                 → RegularizationController@index             attendance.regularization.index
    POST   /staff/regularization                 → RegularizationController@store             attendance.regularization.store
    PUT    /staff/regularization/{req}/approve   → RegularizationController@approve           attendance.regularization.approve

    // ── LEAVE MANAGEMENT ──────────────────────────────────────────
    GET    /leave-types                          → LeaveTypeController@index                  attendance.leaveType.index
    POST   /leave-types                          → LeaveTypeController@store                  attendance.leaveType.store
    PUT    /leave-types/{type}                   → LeaveTypeController@update                 attendance.leaveType.update

    GET    /leaves                               → LeaveApplicationController@index           attendance.leave.index
    POST   /leaves                               → LeaveApplicationController@store           attendance.leave.store
    GET    /leaves/{application}                 → LeaveApplicationController@show            attendance.leave.show
    PUT    /leaves/{application}/review          → LeaveApplicationController@review          attendance.leave.review
    PUT    /leaves/{application}/approve         → LeaveApplicationController@approve         attendance.leave.approve
    PUT    /leaves/{application}/cancel          → LeaveApplicationController@cancel          attendance.leave.cancel

    // ── BIOMETRIC DEVICES ─────────────────────────────────────────
    GET    /devices                              → BiometricDeviceController@index            attendance.device.index
    POST   /devices                              → BiometricDeviceController@store            attendance.device.store
    PUT    /devices/{device}                     → BiometricDeviceController@update           attendance.device.update
    DELETE /devices/{device}                     → BiometricDeviceController@destroy          attendance.device.destroy

    // ── REPORTS ───────────────────────────────────────────────────
    GET    /reports/daily                        → AttendanceReportController@daily           attendance.report.daily
    GET    /reports/monthly                      → AttendanceReportController@monthly         attendance.report.monthly
    GET    /reports/compliance                   → AttendanceReportController@compliance      attendance.report.compliance
    GET    /reports/staff                        → AttendanceReportController@staff           attendance.report.staff
    GET    /reports/analytics                    → AttendanceReportController@analytics       attendance.report.analytics

    // ── SETTINGS ──────────────────────────────────────────────────
    GET    /settings                             → AttendanceSettingsController@edit          attendance.settings.edit
    PUT    /settings                             → AttendanceSettingsController@update        attendance.settings.update
});

// ── DEVICE SYNC API (api.php — Sanctum device token auth) ─────────
POST   /api/v1/attendance/device-sync           → Api/DeviceSyncController@sync
```

---

## 7. UI Screen Inventory

| Screen ID | Screen Name | Route | Description |
|-----------|-------------|-------|-------------|
| ATT-SCR-01 | Student Attendance Dashboard | attendance.student.index | Overview: today's summary, class-wise counts |
| ATT-SCR-02 | Mark Daily Attendance | attendance.student.mark | Class-section roster with status toggles |
| ATT-SCR-03 | Mark Period Attendance | attendance.period.mark | Period selector + subject-level roster |
| ATT-SCR-04 | Attendance Correction List | attendance.correction.index | Pending/approved/rejected corrections |
| ATT-SCR-05 | Submit Correction Request | attendance.correction.store | Form: date, current status, requested status, reason |
| ATT-SCR-06 | Staff Attendance Dashboard | attendance.staff.index | Daily summary, late arrivals widget |
| ATT-SCR-07 | Mark Staff Attendance | attendance.staff.store | Employee list with check-in/check-out |
| ATT-SCR-08 | Regularization Requests | attendance.regularization.index | Pending HR approvals |
| ATT-SCR-09 | Leave Type Master | attendance.leaveType.index | Leave types with CRUD |
| ATT-SCR-10 | Leave Applications List | attendance.leave.index | All applications with status filter |
| ATT-SCR-11 | Apply for Leave | attendance.leave.store | Multi-step form: dates, type, reason, document |
| ATT-SCR-12 | Biometric Device Manager | attendance.device.index | Device list with online/offline status |
| ATT-SCR-13 | Daily Attendance Report | attendance.report.daily | Class-wise counts, date filter |
| ATT-SCR-14 | Monthly Attendance Report | attendance.report.monthly | Student-wise grid, export PDF/Excel |
| ATT-SCR-15 | Government Compliance Register | attendance.report.compliance | CBSE-format monthly register, A3 PDF |
| ATT-SCR-16 | Staff Attendance Report | attendance.report.staff | Department-wise, monthly hours |
| ATT-SCR-17 | At-Risk Analytics | attendance.report.analytics | At-risk students list, trend charts |
| ATT-SCR-18 | Attendance Settings | attendance.settings.edit | School-level config form |

---

## 8. Business Rules & Domain Constraints

**BR-ATT-01:** Only one daily attendance record is permitted per student per date per class-section. Duplicate inserts must be rejected at the database level via UNIQUE KEY.

**BR-ATT-02:** Attendance cannot be marked for a future date. Any attempt to mark future attendance shall return a validation error.

**BR-ATT-03:** The attendance percentage denominator counts only working school days. Holidays (from ACD calendar or `att_holiday_overrides`) are excluded.

**BR-ATT-04:** An `excused` leave day (approved leave) does not reduce the attendance percentage. It is counted as a worked day for compliance purposes.

**BR-ATT-05:** Late arrival (within grace period) counts as `present`. Late arrival (beyond grace period) counts as `late`, which counts as present for percentage but is flagged separately in reports.

**BR-ATT-06:** A half-day counts as 0.5 days for percentage calculation.

**BR-ATT-07:** An attendance correction request older than `att_settings.max_correction_age_days` days cannot be submitted. This protects against retroactive manipulation of finalized registers.

**BR-ATT-08:** Absence notification to parents must be suppressed when the student already has an approved leave for that date (`att_student_attendances.status = 'excused'`).

**BR-ATT-09:** If a student's attendance percentage drops below `att_settings.min_attendance_pct_exam` (default 85%), an alert is triggered and the at-risk level is set to `warning`. Below `at_risk_critical_pct`, the level is `critical`. The student is ineligible for exam registration until restored above threshold (cross-module check with EXM module).

**BR-ATT-10:** Staff regularization requests exceeding `att_settings.max_regularization_per_month` in a calendar month are automatically rejected at the application stage.

**BR-ATT-11:** Biometric device sync API requires device-specific API key authentication. Requests with invalid `device_code` or missing authentication header are rejected with HTTP 401.

**BR-ATT-12:** Leave balance cannot go negative. If a leave application would exceed balance, the system warns the admin/approver (unpaid leave territory), but does not auto-reject — the approver decides.

**BR-ATT-13:** When a leave application is approved, the corresponding `att_student_attendances` or `att_staff_attendances` records for the approved date range must be created/updated to `excused` or `on_leave` status respectively.

---

## 9. Workflow & State Machines

### 9.1 Student Daily Attendance Flow

```
Teacher opens Mark Attendance screen
    → Selects class-section + date
    → System loads student roster from std_student_academic_sessions
    → Teacher marks each student (or uses Mark All Present + overrides)
    → Teacher submits

System processing:
    → Validates: no future date, no duplicates
    → Inserts att_student_attendances records (bulk insert)
    → For each absent/late student: fires AttendanceMarkedAbsent event
    → Event listener queues SMS/email via NTF module
    → RecalculateStudentAnalyticsJob queued per affected student
```

### 9.2 Leave Application State Machine

```
PENDING (submitted by student/parent)
    ↓ Teacher reviews
    → REJECTED (with remarks) → Requester notified
    → PENDING_PRINCIPAL (if > 3 consecutive days or specific leave types)
        ↓ Principal reviews
        → REJECTED → Requester notified
        → APPROVED
    → APPROVED (< 3 days, direct teacher approval)

APPROVED:
    → att_leave_balances.used_days += total_days
    → att_student_attendances records created/updated to 'excused'
    → Requester notified of approval

APPROVED → CANCELLED (admin action, within same academic session)
    → Attendance records reverted to 'absent'
    → Leave balance restored
```

### 9.3 Attendance Correction State Machine

```
PENDING (submitted by teacher/parent/student)
    ↓ Class teacher reviews
    → REJECTED → Requester notified
    → TEACHER_APPROVED
        ↓ Admin/Principal final approval
        → REJECTED → Requester notified
        → APPROVED
            → Original att_student_attendances.status updated
            → Snapshot of original value preserved in att_correction_requests
            → Analytics recalculated
            → Audit log written to sys_activity_logs
```

### 9.4 Biometric Sync Flow

```
Biometric Device
    → POST /api/v1/attendance/device-sync
    → DeviceSyncController validates device_code + auth token
    → Parses payload: employee_id/student_id, timestamp, direction
    → direction = 'in': set check_in_time on att_staff_attendances (upsert)
    → direction = 'out': update check_out_time
    → Anomaly check: if timestamp > school_start + grace = mark 'late'
    → Duplicate check: same employee + direction within 5 min → ignore
    → Update att_biometric_devices.last_sync_at
```

### 9.5 Staff Regularization Workflow

```
Staff submits regularization (date + expected times + reason)
    ↓ System checks: count for month < max_regularization_per_month
    → REJECTED if limit exceeded
    → PENDING (within limit)
        ↓ HR admin reviews
        → REJECTED → Staff notified
        → APPROVED
            → att_staff_attendances updated with regularized times
            → is_regularized = 1, regularization_id set
            → Staff notified
```

---

## 10. Non-Functional Requirements

**NFR-ATT-01 (Performance):** Attendance marking for a full class of 60 students must complete in ≤ 2 seconds. Bulk CSV import of 500 records must complete in ≤ 10 seconds. Monthly compliance report generation for 500 students must complete in ≤ 15 seconds.

**NFR-ATT-02 (Reliability):** Biometric sync API must be stateless and idempotent. Duplicate sync records for the same employee/student within 5 minutes must be silently discarded without error. The API must return HTTP 200 even for duplicates (to prevent device retry storms).

**NFR-ATT-03 (Availability):** The attendance marking screen must be accessible offline on mobile browsers with pending records synced when connectivity is restored (Progressive Web App consideration for mobile teacher app).

**NFR-ATT-04 (Data Integrity):** All attendance updates must write an audit entry to `sys_activity_logs`. The original value before any correction must be preserved in `att_correction_requests.original_status`.

**NFR-ATT-05 (Security):** Biometric device API keys must be stored encrypted. The sync endpoint must reject requests without valid device authentication. Teachers can only view and mark attendance for their own assigned class-sections; cross-section access must be blocked at the policy level.

**NFR-ATT-06 (Scalability):** Analytics recalculation (`RecalculateStudentAnalyticsJob`) must be queued asynchronously. Bulk attendance events (e.g., school of 2,000 students) must not block the HTTP response.

**NFR-ATT-07 (Compliance):** The monthly attendance register PDF must match the CBSE/State Board prescribed format exactly, including signature blocks, school header, class teacher certification statement, and correct column layout.

---

## 11. Cross-Module Dependencies

| Dependency | Direction | Purpose |
|-----------|-----------|---------|
| School Setup (`sch_*`) | Consumes | `sch_class_section_jnt`, `sch_classes`, `sch_sections`, `sch_employees`, `sch_teacher_profile` for roster and staff |
| Student Management (`std_*`) | Consumes | `std_students`, `std_student_academic_sessions`, `std_guardians`, `std_student_guardian_jnt` for student roster and parent contacts |
| Global Masters (`glb_*`) | Consumes | `glb_academic_sessions` for session-scoped attendance |
| System Config (`sys_*`) | Consumes | `sys_users` (marked_by, created_by), `sys_media` (leave documents), `sys_activity_logs` (audit), `sys_dropdown_table` (status lookups) |
| Notification (NTF) | Pushes events | `AttendanceMarkedAbsent`, `AttendanceAtRiskWarning`, `LeaveApproved`, `LeaveRejected` events sent to NTF module |
| Academics (ACD) | Consumes | `acd_calendar_events` (holidays, non-working days) for correct working-day calculation |
| Timetable (TT) | Consumes | Period definitions for period-level attendance |
| Examination (EXM) | Provides | Attendance % eligibility check before exam registration |
| HR & Payroll | Provides | Staff attendance data fed to payroll for salary calculation |

---

## 12. Test Coverage Plan

**No tests exist. Full test suite required.**

| Test Class | Type | Priority | Description |
|-----------|------|----------|-------------|
| StudentAttendanceControllerTest | Feature | P0 | Mark attendance, duplicate prevention, date validation |
| AttendanceCorrectionWorkflowTest | Feature | P0 | Full correction approval chain |
| LeaveApplicationWorkflowTest | Feature | P0 | Leave application, approval, attendance auto-update |
| BiometricDeviceSyncTest | Feature | P0 | Valid/invalid sync payloads, duplicate handling |
| AttendanceAnalyticsCalculationTest | Unit | P0 | Percentage calculation, at-risk thresholds |
| ParentNotificationTriggerTest | Feature | P1 | Absence fires NTF event; leave suppresses it |
| MonthlyRegisterReportTest | Feature | P1 | Correct PDF data for various scenarios |
| StaffAttendanceControllerTest | Feature | P1 | Check-in/out, regularization workflow |
| LeaveBalanceCalculationTest | Unit | P1 | Balance deduction, carry-forward |
| PatternDetectionTest | Unit | P2 | Weekday pattern, streak detection |
| ComplianceReportTest | Feature | P2 | CBSE format validation |

---

## 13. Glossary

| Term | Definition |
|------|-----------|
| Working Day | A school calendar day that is not a holiday or weekend |
| Attendance Percentage | (Days Present + Excused + 0.5×Late) / Total Working Days × 100 |
| Grace Period | Minutes after school start time within which arrival counts as 'on time' |
| Excused Absence | An absence covered by an approved leave application — does not reduce percentage |
| At-Risk Student | A student whose attendance percentage falls below the warning threshold (default 75%) |
| CBSE Compliance | Central Board of Secondary Education attendance register format requirements |
| Regularization | Process by which a staff member corrects a missed biometric check-in/check-out |
| Biometric Sync | Automated transmission of device attendance logs to the system via API |
| Period Attendance | Subject-level attendance marked per timetable period rather than per day |
| Half-Day | Attendance status where student/staff was present for only half of the working day (counts as 0.5) |

---

## 14. Additional Suggestions (Analyst Notes)

**Priority 1 — Foundation:**
1. Implement attendance marking as a mobile-optimized single-page form with swipe gestures for fast marking (teachers typically mark on phones in the classroom).
2. The biometric sync API should be designed idempotent from day one — schools often have unreliable devices that retry failed syncs.
3. Consider a `lock_date` mechanism on `att_settings` so that attendance for months already submitted to the government register cannot be modified without admin override.

**Priority 2 — Integration:**
4. Deep integration with the Notification module is critical for parent trust. The absence SMS must fire within 5 minutes of marking to be useful for parents tracking arrival.
5. Integrate with HR & Payroll module from the start — `att_staff_analytics` should be the authoritative data source for monthly pay calculation, not a secondary report.
6. Coordinate with ACD module for holiday synchronization. Do not build a parallel holiday calendar — consume ACD's `acd_calendar_events` and only use `att_holiday_overrides` as a fallback when ACD module is not licensed.

**Priority 3 — Analytics:**
7. The at-risk flagging should trigger a workflow where the class teacher is required to call/meet the parent (counseling note), and this contact should be logged. This satisfies CBSE requirements for proactive intervention.
8. Consider monthly automated generation and storage of the compliance report PDF so the government report is always ready without on-demand generation delay.
9. Add a QR/barcode-based self-marking mode for student entry at school gate (scan ID card → auto-marks arrival).
10. Future: AI-driven absenteeism prediction based on historical patterns — flag students likely to go at-risk before they actually do.

---

## 15. Appendices

### Appendix A: Proposed Table Summary

| Table | Purpose | Rows (est. annual) |
|-------|---------|-------------------|
| `att_student_attendances` | Core student attendance records | ~500K (500 students × 220 days × 2 periods avg) |
| `att_staff_attendances` | Staff daily check-in/check-out | ~15K (60 staff × 250 days) |
| `att_biometric_devices` | Device master | ~10 |
| `att_leave_types` | Leave type master | ~10 |
| `att_leave_applications` | Leave requests | ~500/year |
| `att_leave_balances` | Per-person per-session leave balance | ~600 (students + staff) |
| `att_correction_requests` | Attendance correction requests | ~200/year |
| `att_regularization_requests` | Staff regularization | ~50/year |
| `att_notification_logs` | Absence notification audit | ~10K/year |
| `att_student_analytics` | Per-student running analytics | ~500 (one per student per session) |
| `att_staff_analytics` | Per-staff running analytics | ~60 (one per employee per session) |
| `att_settings` | School-level config | 1 |
| `att_holiday_overrides` | Manual holiday overrides | ~30/year |

### Appendix B: Notification Event Codes

| Event Code | Trigger | Recipients |
|-----------|---------|-----------|
| `ATTENDANCE_MARKED_ABSENT` | Student marked absent | Parent/Guardian (SMS + In-App) |
| `ATTENDANCE_MARKED_LATE` | Student marked late | Parent/Guardian (In-App) |
| `ATTENDANCE_AT_RISK_WARNING` | % drops below warning threshold | Class Teacher + Parent (Email + In-App) |
| `ATTENDANCE_AT_RISK_CRITICAL` | % drops below critical threshold | Class Teacher + Principal + Parent (SMS + Email) |
| `LEAVE_APPLICATION_SUBMITTED` | New leave application | Class Teacher (In-App) |
| `LEAVE_APPLICATION_APPROVED` | Leave approved | Student/Parent (SMS + In-App) |
| `LEAVE_APPLICATION_REJECTED` | Leave rejected | Student/Parent (In-App) |
| `STAFF_LATE_ARRIVAL_ALERT` | Staff check-in after grace period | HR Admin + Department Head (In-App) |
| `REGULARIZATION_APPROVED` | Staff regularization approved | Employee (In-App) |

### Appendix C: RBS Sub-Task Coverage Map

| RBS Sub-Task | FR Coverage |
|-------------|------------|
| ST.F1.1.1.1–3 (Mark Daily Attendance) | FR-ATT-001 |
| ST.F1.1.2.1–3 (Bulk CSV Upload) | FR-ATT-001 (REQ-001.2) |
| ST.F1.2.1.1–2 (Correction Request) | FR-ATT-003 |
| ST.F1.2.2.1–2 (Correction Approval) | FR-ATT-003 (REQ-003.2) |
| ST.F2.1.1.1–2 (Period Attendance) | FR-ATT-002 |
| ST.F2.1.2.1–2 (Auto-fill + Sync) | FR-ATT-002 (REQ-002.2) |
| ST.F3.1.1.1–2 (Attendance Reports) | FR-ATT-009 |
| ST.F3.1.2.1–2 (Absentee Patterns) | FR-ATT-008 (REQ-008.3) |
| ST.F3.2.1.1–2 (SMS/Email Alerts) | FR-ATT-007 |
| ST.F4.1.1.1–2 (Staff Check-In/Out) | FR-ATT-004 |
| ST.F4.1.2.1–2 (Biometric Sync) | FR-ATT-005 |
| ST.F4.2.1.1–2 (Leave Integration) | FR-ATT-006 |
| ST.F4.2.2.1–2 (Regularization) | FR-ATT-004 (REQ-004.2) |
| ST.F5.1.1.1–2 (Staff Reports) | FR-ATT-009 (REQ-009.3) |
| ST.F5.1.2.1–2 (Department Stats) | FR-ATT-008 (REQ-008.4) |
| ST.F5.2.1.1–2 (Late/Early Alerts) | FR-ATT-007 (staff side) |
