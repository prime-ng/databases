# ATT — Attendance Management
## Module Requirement Document V2
**Version:** 2.0 | **Date:** 2026-03-26 | **Status:** Draft | **Mode:** RBS_ONLY
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** ATT | **Module Path:** `📐 Proposed: Modules/Attendance/`
**Module Type:** Tenant | **Database:** `📐 Proposed: tenant_db`
**Table Prefix:** `att_*`
**Processing Mode:** RBS_ONLY (Greenfield — no standalone ATT module code exists)
**RBS Reference:** Module D — Attendance Management (PrimeAI_Complete_Spec_v2.md)
**V1 Baseline:** `2-Requirement_Module_wise/2-Detailed_Requirements/V1/Dev_Pending/ATT_Attendance_Requirement.md`

---

## Table of Contents
1. [Executive Summary](#1-executive-summary)
2. [Module Overview](#2-module-overview)
   - 2.1 Migration from STD Attendance
   - 2.2 Module Identity
   - 2.3 Module Scale
   - 2.4 Feature Summary
   - 2.5 Menu Path & Architecture
3. [Stakeholders & Roles](#3-stakeholders--roles)
4. [Functional Requirements](#4-functional-requirements)
5. [Data Model](#5-data-model)
6. [API Endpoints & Routes](#6-api-endpoints--routes)
7. [UI Screens](#7-ui-screens)
8. [Business Rules](#8-business-rules)
9. [Workflows](#9-workflows)
10. [Non-Functional Requirements](#10-non-functional-requirements)
11. [Dependencies](#11-dependencies)
12. [Test Scenarios](#12-test-scenarios)
13. [Glossary](#13-glossary)
14. [Suggestions](#14-suggestions)
15. [Appendices](#15-appendices)
16. [V1 to V2 Delta](#16-v1-to-v2-delta)

---

## 1. Executive Summary

The Attendance module (ATT) is the daily operational backbone of school administration in Prime-AI. Indian K-12 schools are legally required to maintain attendance records under CBSE/State Board regulations. The CBSE mandates a minimum 75% attendance for regular students and 85% for board exam eligibility. This module provides a comprehensive, multi-mode attendance management system covering:

- **Student daily attendance** — present, absent, late, half-day, excused, holiday
- **Period-wise subject attendance** — subject teacher marks per timetable period
- **Staff attendance** — check-in/check-out with biometric/RFID device integration
- **Leave management** — student and staff leave application and approval workflows
- **Attendance correction workflow** — teacher submits, HOD/admin approves, with full audit trail
- **Parent notifications** — real-time SMS/push on student absence via NTF module
- **Compliance reporting** — government-format monthly register (CBSE/State Board layout)
- **At-risk analytics** — automatic flagging when attendance falls below threshold

**Implementation Statistics (Greenfield):**
- Controllers: 0 (not started)
- Models: 0 (not started)
- Services: 0 (not started)
- FormRequests: 0 (not started)
- Tests: 0 (not started)
- Completion: 0%

> **All features are proposed (📐 Proposed). No standalone ATT code, DDL, or tests exist yet.**
> Note: Basic attendance views exist under `std_` prefix (STD module AttendanceController, zero auth). ATT supersedes all STD attendance functionality. See Section 2.1 for migration plan.

---

## 2. Module Overview

### 2.1 Migration from STD Attendance

The Student Profile module (STD) contains a rudimentary `AttendanceController` that was built as a placeholder with no authentication checks. The ATT module fully supersedes it.

| Item | STD (legacy) | ATT (this module) |
|------|--------------|-------------------|
| Table prefix | `std_` (attendance fields embedded in student profile tables) | Dedicated `att_*` tables |
| Auth | None (zero auth — security risk) | Full RBAC via policies |
| Staff attendance | None | Complete check-in/check-out + biometric |
| Leave management | None | Full FSM with balance tracking |
| Biometric integration | None | HTTP push API + RFID support |
| Period-level attendance | None | Per-period with timetable linkage |
| Compliance reports | None | CBSE-format monthly register |
| Parent notifications | None | Event-driven via NTF module |

**Migration Steps (implementation phase):**
1. Create all `att_*` tables and backfill from `std_attendances` (if any data exists).
2. Disable/remove ATT-related routes and views from STD module.
3. Delete `STD/AttendanceController.php` after ATT module goes live.
4. Update STD `Student` model to remove hasMany attendance relationship (point to ATT model instead).

### 2.2 Module Identity

| Property | Value |
|---|---|
| Module Name | Attendance |
| Module Code | ATT |
| Laravel Module Namespace | `Modules\Attendance` |
| Module Path | `📐 Proposed: Modules/Attendance/` |
| Route Prefix | `attendance/` |
| Route Name Prefix | `attendance.` |
| DB Table Prefix | `att_*` |
| Module Type | Tenant (database-per-tenant via stancl/tenancy v3.9) |
| Registered In | `routes/tenant.php` |
| nwidart/laravel-modules | v12 |

### 2.3 Module Scale (Proposed)

| Artifact | Count | Notes |
|---|---|---|
| Controllers (Web) | 📐 9 | StudentAttendance, PeriodAttendance, StaffAttendance, CorrectionRequest, RegularizationRequest, LeaveType, LeaveApplication, BiometricDevice, AttendanceReport, AttendanceSettings |
| Controllers (API) | 📐 2 | DeviceSyncController, AttendanceApiController |
| Models | 📐 13 | See Section 5 |
| Services | 📐 6 | AttendanceService, StaffAttendanceService, LeaveService, BiometricSyncService, AttendanceAnalyticsService, AttendanceReportService |
| FormRequests | 📐 12 | One per create/update per main entity |
| Policies | 📐 6 | Per controller |
| DDL Tables (`att_*`) | 📐 14 | See Section 5 |
| Events | 📐 4 | AttendanceMarkedAbsent, AttendanceAtRisk, LeaveStatusChanged, RegularizationApproved |
| Listeners | 📐 3 | SendAbsenceNotification, RecalculateAnalytics, SyncLeaveToAttendance |
| Jobs | 📐 3 | RecalculateStudentAnalyticsJob, SendWeeklyAtRiskReportJob, GenerateMonthlyRegisterJob |
| Views (Blade) | 📐 ~25 | See Section 7 |

### 2.4 Feature Summary

| Feature | Status | RBS Ref |
|---------|--------|---------|
| Student Daily Attendance (Present/Absent/Late/Half-Day/Excused) | 📐 Proposed | D.D1 |
| Student Period/Subject Attendance | 📐 Proposed | D.D1 |
| Bulk Attendance CSV Upload | 📐 Proposed | D.D1 |
| Attendance Lock after cut-off time | 📐 Proposed | D.D1 |
| Attendance Correction Workflow (teacher → admin) | 📐 Proposed | D.D1 |
| Backdated Attendance Entry (with approval) | 📐 Proposed | D.D1 |
| Short Leave / Early Departure Tracking | 📐 Proposed | D.D1 |
| Staff/Teacher Attendance (Check-In/Check-Out) | 📐 Proposed | D.D2 |
| Biometric/RFID Device Integration | 📐 Proposed | D.D5 |
| QR Code / Smart Card Attendance | 📐 Proposed | D.D6 |
| Staff Attendance Regularization Workflow | 📐 Proposed | D.D2 |
| Leave Types Master | 📐 Proposed | D.D2 |
| Student Leave Application and Approval FSM | 📐 Proposed | D.D2 |
| Staff Leave Application and Approval FSM | 📐 Proposed | D.D2 |
| Leave Balance Tracking (per session, with carry-forward) | 📐 Proposed | D.D2 |
| Parent SMS/Notification on Absence | 📐 Proposed | D.D4 |
| Late Arrival Alert to Parents | 📐 Proposed | D.D4 |
| Attendance Shortage / At-Risk Alerts | 📐 Proposed | D.D3 |
| Absentee Pattern Detection (weekday/streak) | 📐 Proposed | D.D3 |
| Student Attendance Reports (Daily/Monthly/Term) | 📐 Proposed | D.D3 |
| Government Compliance Register (CBSE format) | 📐 Proposed | D.D3 |
| Staff Attendance Reports (Department-wise) | 📐 Proposed | D.D3 |
| Holiday Calendar Integration (ACD + override fallback) | 📐 Proposed | D.D3 |
| Consolidation with HRS for salary/payroll deduction | 📐 Proposed | D.D2 |
| Attendance data feed to PAN (Predictive Analytics) | 📐 Proposed | D.D3 |
| Minimum attendance threshold rules (board-configurable) | 📐 Proposed | D.D1 |

### 2.5 Menu Path & Architecture

**Menu Path:**
```
Tenant Dashboard > Attendance
├── Student Attendance
│   ├── Mark Attendance (Daily)
│   ├── Mark Attendance (Period-wise)
│   ├── Attendance Reports
│   └── Leave Applications
├── Staff Attendance
│   ├── Mark Staff Attendance
│   ├── Regularization Requests
│   └── Staff Attendance Reports
└── Settings
    ├── Leave Types
    ├── Biometric Devices
    ├── Notification Configuration
    └── Attendance Rules
```

**Architecture Overview:**
```
[Teacher / Biometric Device / QR Scanner]
    → Mark Student/Staff Attendance
    → att_student_attendances / att_staff_attendances (stored)
    → AttendanceObserver fires AttendanceMarkedAbsent event
    → SendAbsenceNotification listener → NTF module → SMS/push to parent
    → RecalculateStudentAnalyticsJob queued → att_student_analytics updated
    → At-risk threshold check → AttendanceAtRisk event if below warning %

[Admin / HR]
    → Approves leave applications and correction requests
    → Pulls monthly registers and compliance reports
    → Runs GenerateMonthlyRegisterJob for pre-generated PDFs

[Payroll Integration (HRS module)]
    → att_staff_analytics.days_absent feeds monthly LWP (Leave Without Pay) deduction
    → API: GET /attendance/staff/monthly-summary/{employee}/{month}

[Predictive Analytics (PAN module)]
    → Reads att_student_analytics.attendance_percentage for at-risk modelling
    → Reads att_student_analytics.pattern_flags for dropout prediction
```

---

## 3. Stakeholders & Roles

| Actor | Role | Access Level |
|-------|------|-------------|
| School Admin | Full attendance management and configuration | Full CRUD across all attendance, reports, settings |
| Class Teacher | Marks daily attendance for own assigned class-section | Mark + view + correction requests (own class-section only) |
| Subject Teacher | Marks period attendance for own subject periods | Mark + view (own subject + assigned class-sections only) |
| Department Head (HOD) | Reviews correction requests for own department staff | Read: department-level reports; Approve: correction requests |
| HR Admin | Manages staff attendance and regularization approvals | CRUD: staff attendance; Approve: regularization requests and staff leave |
| Principal | Final approval for escalated leaves and backdated corrections | Approve/Reject: corrections, leaves > 3 days, at-risk escalations |
| Student | Views own attendance history; submits leave requests | Read: own data only; Create: leave application |
| Parent/Guardian | Views child attendance; receives absence notifications | Read: own child data only (via Parent Portal) |
| System (automated) | Biometric sync, threshold recalculation, weekly reports | System-level insert/update via Jobs and Events |

**RBAC Permission Codes (for sys_permissions table):**

| Permission | Code |
|---|---|
| Mark student daily attendance | `att.student.mark` |
| Mark period attendance | `att.period.mark` |
| View own class attendance | `att.student.view_own_class` |
| View all attendance (admin) | `att.student.view_all` |
| Submit correction request | `att.correction.create` |
| Approve correction request | `att.correction.approve` |
| Mark staff attendance | `att.staff.mark` |
| Approve regularization | `att.regularization.approve` |
| Manage leave types | `att.leave_type.manage` |
| Approve student leave | `att.leave.approve_student` |
| Approve staff leave | `att.leave.approve_staff` |
| Manage biometric devices | `att.device.manage` |
| View reports | `att.report.view` |
| Export reports | `att.report.export` |
| Manage settings | `att.settings.manage` |

---

## 4. Functional Requirements

> All requirements below are **📐 Proposed** (no code exists). FR codes follow pattern `FR-ATT-NNN`.

---

### FR-ATT-001: Student Daily Attendance Marking 📐

**RBS Ref:** D.D1 | **Priority:** P0 | **Actor:** Class Teacher, Admin

**REQ-ATT-001.1 — Mark Daily Attendance**
- The system shall allow a class teacher or admin to mark daily attendance for all students in a class-section for a given date.
- Attendance statuses: `present`, `absent`, `late`, `half_day`, `excused`, `holiday`.
- Only one daily attendance record per student per date per class-section is permitted (enforced by UNIQUE KEY on `att_student_attendances`).
- The system shall support bulk marking: "Mark All Present" with individual overrides per student.
- Attendance date must not be a future date. Past-date attendance requires a correction request (FR-ATT-003) unless admin performs backdated entry (FR-ATT-003.3).
- The system shall auto-populate class roster from `std_student_academic_sessions` filtered by active academic session and selected class-section.
- Attendance is locked after `att_settings.attendance_lock_time` (configurable, default: end of school day). Locked dates are read-only unless admin overrides.

**REQ-ATT-001.2 — Bulk Attendance CSV Upload**
- Admin may upload a CSV file containing: `roll_no`, `student_id`, `status`, `remarks`.
- System shall validate roll numbers against active roster; invalid rows are flagged in a pre-import error report before any data is written.
- On successful validation, bulk insert proceeds as individual records with `source = 'csv_import'`.
- Failed rows are returned as downloadable error CSV with row number and reason.

**REQ-ATT-001.3 — Attendance Status Logic**
- `late` counts as present for percentage calculation but is flagged separately in reports.
- `half_day` counts as 0.5 days present. `half_day_type` = 'morning' or 'afternoon'.
- `excused` (via approved leave) does not reduce attendance percentage — treated as worked day for compliance.
- `holiday` is auto-set by system via ACD calendar integration; no manual marking is needed on holidays.

**REQ-ATT-001.4 — Short Leave / Early Departure Tracking**
- Teacher may mark a student as `half_day` with `half_day_type = 'afternoon'` to record early departure.
- Reason and approving authority for early departure are logged in `att_student_attendances.remarks`.
- Front office may also record early departure via the FOF module; ATT attendance record is updated accordingly.

**Acceptance Criteria:**
- Teacher selects Class 8A on 25-Mar-2026, system loads full 35-student roster. Marking all present saves 35 `att_student_attendances` records with `status = 'present'`.
- Roll no 12 marked absent → `AttendanceMarkedAbsent` event fired within 1 minute.
- CSV with 5 invalid roll numbers → those 5 rejected with error report; remaining valid rows imported.
- Future date selected → system rejects with validation error `E3003`.

**Test Cases:**
- TC-ATT-001.1: Mark full class present → 35 records created, all `status = 'present'`.
- TC-ATT-001.2: Duplicate marking same student same date → UNIQUE constraint, system shows error.
- TC-ATT-001.3: CSV import with mixed valid/invalid rows → only valid rows inserted, error report returned.
- TC-ATT-001.4: Future date selection → validation error.
- TC-ATT-001.5: Marking after lock time (admin override disabled) → HTTP 403 with message "Attendance locked for this date."

---

### FR-ATT-002: Period-Wise Attendance 📐

**RBS Ref:** D.D1 | **Priority:** P1 | **Actor:** Subject Teacher, Admin

**REQ-ATT-002.1 — Period-Level Attendance**
- Subject teachers shall mark attendance per timetable period (`period_id` linked to `tt_period_types`).
- Period attendance is stored in the same `att_student_attendances` table with `period_id` set (non-NULL).
- The system shall auto-fill all students as present by default; teacher marks only absent students.
- If a student is already marked `absent` for the day (daily attendance, `period_id = NULL`), all their period rows auto-fill as `absent` and cannot be overridden without a correction request.

**REQ-ATT-002.2 — Period Attendance Sync with Daily**
- If period-level records exist for a day and daily attendance has not yet been marked, the system computes daily status: `present` if ≥ 1 period present; `absent` if 0 periods present.
- Subject-level attendance percentage = (periods present / total periods for that subject) × 100, stored in `att_subject_analytics`.
- Period attendance does not override an existing daily attendance record; it supplements it.

**REQ-ATT-002.3 — Timetable Dependency**
- Period attendance screen is enabled only when the Timetable module (TT) is licensed and periods are defined for the class-section.
- If timetable periods are not defined, period attendance screen shows a "Timetable not configured" message and falls back to daily attendance only.

**Acceptance Criteria:**
- Math teacher marks 3 students absent in period 3 → 3 records in `att_student_attendances` with `period_id = 3`.
- Student absent all 6 periods → daily status auto-updates to `absent`.
- Student present in at least 1 period → daily status remains `present`.

**Test Cases:**
- TC-ATT-002.1: Mark period attendance → records with correct `period_id` created.
- TC-ATT-002.2: All periods absent → daily auto-update to `absent` triggered.
- TC-ATT-002.3: Partial absence across periods → daily remains `present`.
- TC-ATT-002.4: Period attendance when TT not licensed → falls back gracefully.

---

### FR-ATT-003: Attendance Correction Workflow 📐

**RBS Ref:** D.D1 | **Priority:** P0 | **Actor:** Teacher, Student, Parent, Admin, Principal

**REQ-ATT-003.1 — Correction Request Submission**
- A teacher, student, or parent may submit an attendance correction request for a past date.
- Request fields: `student_id`, `attendance_date`, `current_status`, `requested_status`, `reason`, optional supporting document (FK → `sys_media`).
- Requests cannot be raised for attendance records older than `att_settings.max_correction_age_days` days (default: 30).
- Each student may have at most 5 open (pending) correction requests at any time (configurable).

**REQ-ATT-003.2 — Correction Approval Chain**
- Level 1: Class teacher reviews and approves or rejects.
- Level 2 (required when correction affects current month compliance): Admin/Principal final approval.
- On final approval, the original `att_student_attendances.status` is updated and the original value is preserved in `att_correction_requests.original_status` for audit.
- Every state change is logged to `sys_activity_logs` with old and new values.

**REQ-ATT-003.3 — Backdated Attendance Entry**
- Admin may enter attendance for a date that has no attendance records at all (not just correction of existing records).
- Backdated entry requires: date selection, reason for backdating, and admin approval note.
- The attendance record is created with `source = 'backdated'` and `marked_by = admin_user_id`.
- Backdated entry for the current month requires no extra approval; backdated entry for prior months requires Principal approval.

**Acceptance Criteria:**
- Parent submits correction for 20-Mar-2026 (absent → excused) → request enters `pending_teacher` state.
- Teacher approves, admin approves → original record updated to `excused`; `sys_activity_logs` records old and new values.
- Correction for date > 30 days old → validation error at submission.

**Test Cases:**
- TC-ATT-003.1: Correction request for date > 30 days → rejected with validation error.
- TC-ATT-003.2: Full approval chain → record updated, audit log entry created.
- TC-ATT-003.3: Teacher rejection → status = `rejected`, requester notified.
- TC-ATT-003.4: Backdated entry current month → no Principal approval required.
- TC-ATT-003.5: Backdated entry prior month → Principal approval required.

---

### FR-ATT-004: Staff Attendance 📐

**RBS Ref:** D.D2 | **Priority:** P0 | **Actor:** Staff, HR Admin

**REQ-ATT-004.1 — Staff Check-In / Check-Out**
- Staff attendance records `check_in_time` and `check_out_time` per working day.
- Status options: `present`, `absent`, `late`, `on_leave`, `half_day`, `work_from_home`, `on_duty`.
- A staff member cannot have two check-in records on the same date; system updates the existing record on second check-in.
- `working_minutes` = `check_out_time − check_in_time` in minutes (NULL if check-out is missing).
- If check-in time exceeds school start + grace period → `status` auto-set to `late`.

**REQ-ATT-004.2 — Staff Regularization**
- If biometric sync fails or staff forgets to check in/out, they submit a regularization request with: `date`, `expected_check_in`, `expected_check_out`, `reason`.
- HR admin approves or rejects. On approval, `att_staff_attendances` is updated and `is_regularized = 1`.
- Regularization requests capped at `att_settings.max_regularization_per_month` per employee per calendar month (default: 3).

**REQ-ATT-004.3 — Payroll Integration**
- `att_staff_analytics.days_absent` (non-leave absences) are fed to HRS Payroll module as LWP (Leave Without Pay) deductions at month-end.
- API endpoint: `GET /api/v1/attendance/staff/monthly-summary/{employee_id}/{year}/{month}` returns: total working days, days present, days on leave, LWP days, attendance percentage.
- HRS Payroll module is the consumer; ATT is the authoritative source.

**Acceptance Criteria:**
- Biometric device syncs check-in at 08:52 (school starts 08:30, grace 15 min) → record `source = 'biometric'`, `check_in_time = 08:52`, `status = 'late'`.
- HR approves regularization → record updated with regularized times and `is_regularized = 1`.
- Third regularization in same month submitted → accepted (at limit); fourth → rejected with `E3004`.

**Test Cases:**
- TC-ATT-004.1: Biometric check-in within grace → `status = 'present'`.
- TC-ATT-004.2: Biometric check-in after grace → `status = 'late'`.
- TC-ATT-004.3: Duplicate check-in same date → updates existing record, no duplicate.
- TC-ATT-004.4: Regularization > monthly limit → system rejects with business rule error.

---

### FR-ATT-005: Biometric / RFID / QR Device Integration 📐

**RBS Ref:** D.D5, D.D6 | **Priority:** P1 | **Actor:** System, Admin

**REQ-ATT-005.1 — Device Master**
- Admin registers biometric/RFID/NFC/QR devices with: `device_name`, `device_code` (unique), `location`, `device_type` (biometric/rfid/nfc/qr), `ip_address`, `port`, `api_endpoint`, `auth_token_encrypted`.
- Device status: `online`, `offline`, `maintenance`. Auto-detected via periodic ping every 5 minutes (scheduled job).
- `applicable_to`: staff / student / both.

**REQ-ATT-005.2 — HTTP Push Sync API**
- Devices push attendance logs via HTTP POST to `/api/v1/attendance/device-sync` with device-specific API key.
- Sync payload: `device_code`, `employee_id` or `student_id`, `timestamp`, `direction` (in/out).
- System processes sync records and creates/updates `att_staff_attendances` or `att_student_attendances` with `source = 'biometric'` or `source = 'rfid'`.
- Anomaly: if check-in > school start + grace → `late`. Two consecutive check-ins for same person within 5 minutes → second ignored (idempotent). API returns HTTP 200 for duplicates to prevent device retry storms.

**REQ-ATT-005.3 — RFID / Smart Card for Student Attendance**
- Students with smart cards (`std_students.smart_card_id`) can tap RFID readers at class entry points.
- System maps `smart_card_id` → `student_id` and creates `att_student_attendances` record.
- Unknown card ID → logged in `att_device_sync_logs.error_code = 'UNKNOWN_CARD'`, alert sent to admin.

**REQ-ATT-005.4 — QR Code Attendance**
- Teacher generates a time-limited (5-minute TTL) QR code for a class-section attendance session.
- Students scan QR with mobile browser → system records attendance as `source = 'qr'`.
- QR session is associated with a specific period or daily slot; expired QR returns error.

**Acceptance Criteria:**
- Device `BIO-001` posts sync for employee `EMP-042` at 08:52 → `att_staff_attendances` created, `source = 'biometric'`, `status = 'late'`.
- Duplicate sync within 5 minutes → ignored, HTTP 200 returned.
- Unknown smart card ID → `att_device_sync_logs` error entry, admin notification.

**Test Cases:**
- TC-ATT-005.1: Valid device sync payload → attendance record created.
- TC-ATT-005.2: Invalid `device_code` → HTTP 401.
- TC-ATT-005.3: Duplicate within 5 min → ignored, no duplicate record, HTTP 200.
- TC-ATT-005.4: Unknown smart card → error logged, admin alerted.
- TC-ATT-005.5: Expired QR code scan → HTTP 422 with `QR_EXPIRED`.

---

### FR-ATT-006: Leave Management 📐

**RBS Ref:** D.D2 | **Priority:** P0 | **Actor:** Student, Parent, Staff, Teacher, HR Admin, Principal

**REQ-ATT-006.1 — Leave Types Master**
- Admin maintains leave types master: `name`, `code`, `max_days_per_year`, `max_consecutive_days`, `is_paid`, `applicable_to` (student/staff/both), `requires_document`, `accrual_type` (fixed/accrual/none), `carry_forward_limit`, `affects_attendance_pct`.
- Default seeded leave types: Medical Leave (ML), Casual Leave (CL), Earned Leave (EL), Maternity Leave (MatL), Paternity Leave (PatL), Student Medical Leave (SML), Student Personal Leave (SPL).
- `affects_attendance_pct = 0` means the leave days are treated as excused and do not reduce the attendance percentage denominator.

**REQ-ATT-006.2 — Student Leave Application**
- Student or parent submits: `leave_type_id`, `from_date`, `to_date`, `reason`, optional medical certificate (FK → `sys_media`).
- System auto-calculates `total_days` as count of working school days in the date range (excludes weekends and holidays from ACD calendar).
- Approval chain: Class teacher → (if > 3 consecutive days) → Principal.
- On approval: creates `att_student_attendances` records with `status = 'excused'` for each working day in range; decrements `att_leave_balances.used_days`.
- Leave beyond `max_consecutive_days` → rejected at application stage with error.

**REQ-ATT-006.3 — Staff Leave Application**
- Same FSM as student but approval chain: Department Head → HR Admin → (if > 5 consecutive days) → Principal.
- On approval: `att_staff_attendances` records updated to `status = 'on_leave'`.
- Half-day leave supported: `is_half_day = 1`, `half_day_type = 'morning'|'afternoon'`.
- LOP (Leave on Pay exhausted): if `balance_days = 0`, system warns approver that this will be unpaid leave. Approver may still approve (HR discretion).

**REQ-ATT-006.4 — Leave Balance Management**
- `att_leave_balances` tracks entitlement, used days, and balance per person per leave type per academic session.
- Session rollover: carry-forward days (up to `att_leave_types.carry_forward_limit`) are migrated to next session via `AttendanceSessionRolloverJob`.
- Leave balance report available per employee / per student.

**Acceptance Criteria:**
- Student applies for 3-day medical leave with doctor's certificate, teacher approves → 3 `att_student_attendances` records set to `excused`, `att_leave_balances.used_days += 3`.
- Staff applies for 6 consecutive days → requires HOD + HR Admin + Principal approval.
- Leave exceeds `max_consecutive_days` → rejected at application stage.

**Test Cases:**
- TC-ATT-006.1: Student leave approved → attendance records created as `excused` for each working day.
- TC-ATT-006.2: Leave exceeds `max_consecutive_days` → system rejects at application stage.
- TC-ATT-006.3: Leave balance exhausted → system warns approver but allows approval (LOP).
- TC-ATT-006.4: Leave cancelled after approval → attendance records reverted to `absent`; balance restored.
- TC-ATT-006.5: Half-day leave → 0.5 days deducted from balance.

---

### FR-ATT-007: Parent Notifications on Absence 📐

**RBS Ref:** D.D4 | **Priority:** P0 | **Actor:** System (automated), Parent

**REQ-ATT-007.1 — Automatic Absence Notification**
- When a student is marked `absent`, the system fires `AttendanceMarkedAbsent` event.
- `SendAbsenceNotification` listener dispatches notification via NTF module.
- Notification payload: `student_name`, `class_section`, `attendance_date`, `period` (if period-level), `school_name`.
- Default channels: SMS to parent's registered mobile + in-app notification to Parent Portal.
- Notification is suppressed if: (a) student already has an approved leave for that date, (b) parent has opted out of attendance notifications.
- Configurable delay: `att_settings.absence_notification_delay_minutes` (default: 5 min) to allow teacher to correct accidental marks before notification fires.

**REQ-ATT-007.2 — Late Arrival Alert**
- When a student is marked `late`, a lighter-tone notification is sent via in-app (not SMS by default).
- Configurable per school: admin can disable late arrival alerts independently of absence alerts.

**REQ-ATT-007.3 — At-Risk Shortage Alert**
- When `att_student_analytics.at_risk_level` transitions to `warning` or `critical`, an `AttendanceAtRisk` event fires.
- `critical` alert: SMS + email to parent; in-app to class teacher + principal.
- `warning` alert: in-app to class teacher + email to parent.

**REQ-ATT-007.4 — Notification Logging**
- Every notification attempt logged in `att_notification_logs` with: `student_id`, `attendance_id`, `channel`, `sent_at`, `delivery_status` (queued/sent/delivered/failed/suppressed).
- NTF module delivery ID stored in `att_notification_logs.ntf_delivery_id` for traceability.

**Acceptance Criteria:**
- Student ID 155 marked absent on 25-Mar-2026 → within 5 minutes parent receives SMS: "Dear Parent, Rahul (Class 8A) was absent on 25-Mar-2026. Please contact school. — Prime School."
- Student on approved leave → no absence notification sent.
- Parent opted out → notification suppressed; `att_notification_logs.delivery_status = 'suppressed'`.

**Test Cases:**
- TC-ATT-007.1: Student marked absent → `AttendanceMarkedAbsent` event fired, NTF queued.
- TC-ATT-007.2: Student on approved leave → no notification.
- TC-ATT-007.3: Parent opted out → `delivery_status = 'suppressed'`.
- TC-ATT-007.4: At-risk critical → SMS + email fired; at-risk warning → in-app + email only.
- TC-ATT-007.5: Late arrival alert disabled in settings → no notification for `late` status.

---

### FR-ATT-008: Attendance Analytics & At-Risk Identification 📐

**RBS Ref:** D.D3 | **Priority:** P1 | **Actor:** System, Admin, Teacher

**REQ-ATT-008.1 — Attendance Percentage Calculation**
- `att_student_analytics` maintains running totals per student per academic session: `total_working_days`, `days_present`, `days_absent`, `days_late`, `days_half_day`, `days_excused`, `attendance_percentage`.
- Formula: `attendance_percentage = ((days_present + days_excused + 0.5 × days_half_day) / total_working_days) × 100`
- `late` counted as present in the formula (no deduction).
- Recalculated on every attendance mark/update/correction via queued `RecalculateStudentAnalyticsJob`.

**REQ-ATT-008.2 — At-Risk Flagging**
- Students with `attendance_percentage` < `att_settings.at_risk_critical_pct` (default: 65%) → `at_risk_level = 'critical'`.
- Students between `at_risk_critical_pct` and `att_settings.at_risk_warning_pct` (default: 75%) → `at_risk_level = 'warning'`.
- Students between `at_risk_warning_pct` and `att_settings.min_attendance_pct_exam` (default: 85%) → `at_risk_level = 'borderline'`.
- Above `min_attendance_pct_exam` → `at_risk_level = 'normal'`.
- Weekly automated report of at-risk students sent to class teachers and Principal via `SendWeeklyAtRiskReportJob`.
- Cross-module: EXM module checks `att_student_analytics.attendance_percentage >= att_settings.min_attendance_pct_exam` before allowing exam registration. ATT provides a policy method `AttendancePolicy::isExamEligible(Student $student): bool`.

**REQ-ATT-008.3 — Absentee Pattern Detection**
- Detect students absent on the same weekday for 4+ consecutive weeks (weekday pattern).
- Detect absence streaks > 3 consecutive school days.
- Patterns stored in `att_student_analytics.pattern_flags` JSON field.
- Pattern detection runs as part of `RecalculateStudentAnalyticsJob`.

**REQ-ATT-008.4 — Staff Attendance Analytics**
- `att_staff_analytics` tracks per employee per session: `total_working_days`, `days_present`, `days_absent`, `days_on_leave`, `late_arrivals_count`, `avg_check_in_time`, `total_working_minutes`, `attendance_percentage`.
- Department-level aggregation available via `StaffAttendanceAnalyticsService::getDepartmentSummary()`.

**Acceptance Criteria:**
- Student with 60/80 working days present → `attendance_percentage = 75.00`, `at_risk_level = 'borderline'`.
- Student absent every Monday for 4 consecutive weeks → `pattern_flags = {"weekday_pattern": {"day": "Monday", "weeks": 4}}`.
- Weekly at-risk job runs → class teacher of 8A receives list of at-risk students.

**Test Cases:**
- TC-ATT-008.1: 52/80 days present → percentage = 65%, `at_risk_level = 'critical'`.
- TC-ATT-008.2: Pattern detection 4 consecutive Mondays absent → pattern_flags populated.
- TC-ATT-008.3: Analytics recalculated after correction → new percentage reflects change.
- TC-ATT-008.4: EXM integration: exam eligibility check → returns false when below 85%.

---

### FR-ATT-009: Attendance Reports & Compliance 📐

**RBS Ref:** D.D3 | **Priority:** P0 | **Actor:** Admin, Teacher, Principal

**REQ-ATT-009.1 — Student Attendance Reports**
- Daily attendance report: class-section-wise count of present/absent/late per day. Filter by date, class, section.
- Monthly attendance summary: student-wise grid — columns = dates (1–31), cells = P/A/L/H/E, footer = total + percentage. Filter by month, class, section.
- Term-wise and annual attendance report with cumulative percentage per student.
- Individual student attendance report: full history with date-wise status.
- Export formats: PDF (DomPDF) and Excel/CSV (native `fputcsv`, no external package).

**REQ-ATT-009.2 — Government Compliance Register (CBSE Format)**
- Monthly Attendance Register in CBSE/State Board prescribed format:
  - Columns: S.No., Admission No., Student Name, Day-1 through Day-31, Total Present, Total Working Days, Percentage.
  - Cells: P (present), A (absent), H (holiday), L (leave/excused), HD (half-day).
  - Footer row: count of present students per day.
- Exportable as PDF (A3 landscape) with school letterhead, class teacher certification statement, and signature blocks for teacher and principal.
- Pre-generated and stored each month via `GenerateMonthlyRegisterJob` (runs on 1st of following month).

**REQ-ATT-009.3 — Staff Attendance Reports**
- Daily staff attendance report: department-wise, showing check-in/check-out times and late arrivals.
- Monthly working hours summary: employee-wise total working minutes per month.
- Department-level absenteeism analysis with trend line.
- LWP summary report: employees with LWP days for payroll integration.

**REQ-ATT-009.4 — At-Risk Students Report**
- Lists all students below exam eligibility threshold, grouped by class-section.
- Shows current percentage, days needed to reach threshold, and projected percentage at term end.
- Exportable as PDF for Principal and parent meeting use.

**Acceptance Criteria:**
- Admin selects Class 10B for March 2026 → monthly register PDF generated in ≤ 10 seconds, correct P/A/H values for all 35 students across 26 working days.
- CBSE compliance PDF: correct school letterhead, signature blocks, class teacher certification text present.

**Test Cases:**
- TC-ATT-009.1: Monthly register 40 students × 26 days → correct cell values, correct percentage column.
- TC-ATT-009.2: Date-range report spanning 3 months → aggregates correctly.
- TC-ATT-009.3: PDF export → generates without error, includes school name and month header.
- TC-ATT-009.4: At-risk report → shows correct days-needed projection for each student.

---

### FR-ATT-010: Attendance Settings & Holiday Calendar Integration 📐

**RBS Ref:** D.D1, Y7.1 | **Priority:** P0 | **Actor:** Admin

**REQ-ATT-010.1 — Attendance Rules Configuration**
- Admin configures per-school in `att_settings`:
  - `school_start_time` (used for late detection)
  - `grace_period_minutes` (default: 15)
  - `attendance_lock_time` (TIME — after this time attendance is locked for the day; default: 17:00)
  - `min_attendance_pct_exam` (default: 85.00)
  - `at_risk_warning_pct` (default: 75.00)
  - `at_risk_critical_pct` (default: 65.00)
  - `max_correction_age_days` (default: 30)
  - `max_regularization_per_month` (default: 3)
  - `send_absence_sms`, `send_late_arrival_alert`, `absence_notification_delay_minutes`
  - `attendance_mode` (day_wise / period_wise / both) — controls which screens are enabled

**REQ-ATT-010.2 — Holiday Calendar Integration**
- System reads holiday/non-working days from ACD module (`acd_calendar_events` where `is_working_day = 0`).
- When computing working days and attendance percentage, holidays are excluded from the denominator.
- If ACD module is not licensed, admin manually flags dates in `att_holiday_overrides`.
- `att_holiday_overrides` entries take precedence over any calculation; ACD calendar is the primary source when licensed.

**Acceptance Criteria:**
- School sets grace period = 15 min, start time = 08:30 → check-in at 08:44 → `present`; 08:46 → `late`.
- Holi (17-Mar-2026) marked as holiday in ACD calendar → March attendance denominator reduced by 1 day.
- ACD not licensed → admin flags holiday manually in `att_holiday_overrides`; system respects it.

---

### FR-ATT-011: PAN (Predictive Analytics) Integration 📐

**RBS Ref:** V2 (PAN module) | **Priority:** P2 | **Actor:** System, Admin

**REQ-ATT-011.1 — Attendance Feed to PAN**
- `att_student_analytics` is the authoritative source for attendance data consumed by the PAN module.
- PAN reads: `attendance_percentage`, `at_risk_level`, `pattern_flags`, `days_absent`, `days_present` per student per session.
- ATT provides a read-only API endpoint for PAN: `GET /api/v1/attendance/analytics/student/{student_id}` (internal Sanctum token auth).
- ATT also provides bulk export: `GET /api/v1/attendance/analytics/class/{class_section_id}` returning all students' analytics for a class-section.

**REQ-ATT-011.2 — Attendance Forecasting Support**
- ATT stores historical session-over-session analytics to support PAN's LSTM / Prophet models.
- Historical data retained per student per session (not purged on session rollover).
- PAN uses this data to predict future attendance patterns and dropout risk.

---

## 5. Data Model

> All tables are **📐 Proposed**. Table prefix: `att_`. Engine: InnoDB. Charset: UTF8MB4.

### 5.1 Table: `att_student_attendances` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK → glb_academic_sessions | |
| org_session_id | INT UNSIGNED | NOT NULL, FK → sch_org_academic_sessions_jnt | School-specific session mapping |
| class_section_id | INT UNSIGNED | NOT NULL, FK → sch_class_section_jnt | |
| student_id | INT UNSIGNED | NOT NULL, FK → std_students | |
| attendance_date | DATE | NOT NULL | |
| period_id | INT UNSIGNED | NULL, FK → tt_period_types | NULL = daily; set for period-level |
| subject_id | INT UNSIGNED | NULL, FK → sch_subjects | Set when period-level |
| status | ENUM('present','absent','late','half_day','excused','holiday') | NOT NULL | |
| half_day_type | ENUM('morning','afternoon') | NULL | When status = half_day |
| source | ENUM('manual','biometric','rfid','qr','csv_import','backdated','system') | NOT NULL DEFAULT 'manual' | How attendance was recorded |
| device_id | INT UNSIGNED | NULL, FK → att_biometric_devices | Set for biometric/rfid/qr source |
| remarks | VARCHAR(255) | NULL | Teacher notes |
| marked_by | BIGINT UNSIGNED | NULL, FK → sys_users | User who marked |
| is_locked | TINYINT(1) | NOT NULL DEFAULT 0 | Locked after cut-off time |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | Soft delete flag |
| created_by | BIGINT UNSIGNED | NULL, FK → sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | Soft delete |
| **UNIQUE KEY** | (class_section_id, student_id, attendance_date, period_id) | | Prevents duplicates |

### 5.2 Table: `att_staff_attendances` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | |
| employee_id | INT UNSIGNED | NOT NULL, FK → sch_employees | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK → glb_academic_sessions | |
| attendance_date | DATE | NOT NULL | |
| check_in_time | TIME | NULL | |
| check_out_time | TIME | NULL | |
| working_minutes | INT UNSIGNED | NULL | Computed: check_out − check_in |
| status | ENUM('present','absent','late','half_day','on_leave','work_from_home','on_duty') | NOT NULL DEFAULT 'absent' | |
| half_day_type | ENUM('morning','afternoon') | NULL | |
| source | ENUM('manual','biometric','rfid','regularized','system') | NOT NULL DEFAULT 'manual' | |
| device_id | INT UNSIGNED | NULL, FK → att_biometric_devices | |
| is_regularized | TINYINT(1) | NOT NULL DEFAULT 0 | |
| regularization_id | INT UNSIGNED | NULL, FK → att_regularization_requests | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK → sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |
| **UNIQUE KEY** | (employee_id, attendance_date) | | One record per employee per day |

### 5.3 Table: `att_biometric_devices` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| device_name | VARCHAR(100) | NOT NULL | |
| device_code | VARCHAR(30) | NOT NULL UNIQUE | Used in API sync auth |
| location | VARCHAR(100) | NULL | e.g., 'Main Gate', 'Staff Room' |
| device_type | ENUM('biometric','rfid','nfc','qr','manual') | NOT NULL DEFAULT 'biometric' | |
| applicable_to | ENUM('student','staff','both') | NOT NULL DEFAULT 'staff' | |
| ip_address | VARCHAR(45) | NULL | IPv4 or IPv6 |
| port | SMALLINT UNSIGNED | NULL DEFAULT 80 | |
| api_endpoint | VARCHAR(255) | NULL | Device push URL |
| auth_token_encrypted | TEXT | NULL | Encrypted via app key |
| device_status | ENUM('online','offline','maintenance') | NOT NULL DEFAULT 'offline' | |
| last_sync_at | TIMESTAMP | NULL | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK → sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |

### 5.4 Table: `att_device_sync_logs` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | |
| device_id | INT UNSIGNED | NOT NULL, FK → att_biometric_devices | |
| raw_payload | JSON | NOT NULL | Full incoming payload |
| person_type | ENUM('student','staff') | NULL | Resolved from payload |
| student_id | INT UNSIGNED | NULL, FK → std_students | |
| employee_id | INT UNSIGNED | NULL, FK → sch_employees | |
| sync_timestamp | TIMESTAMP | NOT NULL | Timestamp from device |
| direction | ENUM('in','out') | NULL | |
| result | ENUM('processed','duplicate','error','unknown_card') | NOT NULL | |
| error_code | VARCHAR(50) | NULL | e.g., UNKNOWN_CARD, INVALID_DEVICE |
| attendance_id | BIGINT UNSIGNED | NULL | FK → created/updated attendance record |
| created_at | TIMESTAMP | NULL | |

### 5.5 Table: `att_leave_types` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| name | VARCHAR(100) | NOT NULL | e.g., 'Medical Leave' |
| code | VARCHAR(10) | NOT NULL UNIQUE | e.g., 'ML', 'CL', 'EL' |
| applicable_to | ENUM('student','staff','both') | NOT NULL DEFAULT 'both' | |
| max_days_per_year | TINYINT UNSIGNED | NOT NULL DEFAULT 12 | |
| max_consecutive_days | TINYINT UNSIGNED | NOT NULL DEFAULT 5 | |
| is_paid | TINYINT(1) | NOT NULL DEFAULT 1 | |
| requires_document | TINYINT(1) | NOT NULL DEFAULT 0 | |
| affects_attendance_pct | TINYINT(1) | NOT NULL DEFAULT 0 | 0 = excused; does not reduce % |
| accrual_type | ENUM('fixed','accrual','none') | NOT NULL DEFAULT 'fixed' | |
| carry_forward_limit | TINYINT UNSIGNED | NOT NULL DEFAULT 0 | Max days to next session |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK → sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |

### 5.6 Table: `att_leave_applications` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | |
| applicant_type | ENUM('student','staff') | NOT NULL | |
| student_id | INT UNSIGNED | NULL, FK → std_students | |
| employee_id | INT UNSIGNED | NULL, FK → sch_employees | |
| leave_type_id | INT UNSIGNED | NOT NULL, FK → att_leave_types | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK → glb_academic_sessions | |
| from_date | DATE | NOT NULL | |
| to_date | DATE | NOT NULL | |
| total_days | DECIMAL(4,1) | NOT NULL | Working days in range (0.5 for half-day) |
| is_half_day | TINYINT(1) | NOT NULL DEFAULT 0 | |
| half_day_type | ENUM('morning','afternoon') | NULL | |
| reason | TEXT | NOT NULL | |
| document_media_id | INT UNSIGNED | NULL, FK → sys_media | Supporting document |
| status | ENUM('pending','pending_principal','approved','rejected','cancelled') | NOT NULL DEFAULT 'pending' | |
| reviewed_by | BIGINT UNSIGNED | NULL, FK → sys_users | Teacher / HOD / HR Admin |
| reviewed_at | TIMESTAMP | NULL | |
| review_remarks | VARCHAR(255) | NULL | |
| approved_by | BIGINT UNSIGNED | NULL, FK → sys_users | Principal / Admin final approver |
| approved_at | TIMESTAMP | NULL | |
| approval_remarks | VARCHAR(255) | NULL | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK → sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |

### 5.7 Table: `att_leave_balances` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| applicant_type | ENUM('student','staff') | NOT NULL | |
| student_id | INT UNSIGNED | NULL, FK → std_students | |
| employee_id | INT UNSIGNED | NULL, FK → sch_employees | |
| leave_type_id | INT UNSIGNED | NOT NULL, FK → att_leave_types | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK → glb_academic_sessions | |
| entitled_days | DECIMAL(4,1) | NOT NULL | From leave type + carry-forward |
| used_days | DECIMAL(4,1) | NOT NULL DEFAULT 0.0 | Incremented on leave approval |
| balance_days | DECIMAL(4,1) | NOT NULL DEFAULT 0.0 | Computed: entitled − used |
| carry_forward_days | DECIMAL(4,1) | NOT NULL DEFAULT 0.0 | From previous session |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK → sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| **UNIQUE KEY** | (applicant_type, student_id, employee_id, leave_type_id, academic_session_id) | | |

### 5.8 Table: `att_correction_requests` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | |
| attendance_id | BIGINT UNSIGNED | NOT NULL, FK → att_student_attendances | |
| student_id | INT UNSIGNED | NOT NULL, FK → std_students | |
| attendance_date | DATE | NOT NULL | For display |
| original_status | ENUM('present','absent','late','half_day','excused') | NOT NULL | Snapshot before correction |
| requested_status | ENUM('present','absent','late','half_day','excused') | NOT NULL | |
| reason | TEXT | NOT NULL | |
| document_media_id | INT UNSIGNED | NULL, FK → sys_media | |
| requested_by | BIGINT UNSIGNED | NOT NULL, FK → sys_users | Initiator |
| status | ENUM('pending','teacher_approved','approved','rejected') | NOT NULL DEFAULT 'pending' | |
| teacher_reviewed_by | BIGINT UNSIGNED | NULL, FK → sys_users | |
| teacher_reviewed_at | TIMESTAMP | NULL | |
| teacher_remarks | VARCHAR(255) | NULL | |
| approved_by | BIGINT UNSIGNED | NULL, FK → sys_users | Admin/Principal final |
| approved_at | TIMESTAMP | NULL | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK → sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |

### 5.9 Table: `att_regularization_requests` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| employee_id | INT UNSIGNED | NOT NULL, FK → sch_employees | |
| attendance_date | DATE | NOT NULL | |
| expected_check_in | TIME | NULL | |
| expected_check_out | TIME | NULL | |
| reason | TEXT | NOT NULL | |
| status | ENUM('pending','approved','rejected') | NOT NULL DEFAULT 'pending' | |
| reviewed_by | BIGINT UNSIGNED | NULL, FK → sys_users | HR admin |
| reviewed_at | TIMESTAMP | NULL | |
| remarks | VARCHAR(255) | NULL | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK → sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |

### 5.10 Table: `att_notification_logs` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | |
| student_id | INT UNSIGNED | NOT NULL, FK → std_students | |
| attendance_id | BIGINT UNSIGNED | NOT NULL, FK → att_student_attendances | |
| guardian_id | INT UNSIGNED | NULL, FK → std_guardians | Which parent notified |
| notification_type | ENUM('absence','late_arrival','at_risk_warning','at_risk_critical','weekly_summary') | NOT NULL | |
| channel | ENUM('sms','email','in_app','push') | NOT NULL | |
| sent_at | TIMESTAMP | NULL | |
| delivery_status | ENUM('queued','sent','delivered','failed','suppressed') | NOT NULL DEFAULT 'queued' | |
| ntf_delivery_id | INT UNSIGNED | NULL | FK to NTF module delivery log |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK → sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |

### 5.11 Table: `att_student_analytics` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | |
| student_id | INT UNSIGNED | NOT NULL, FK → std_students | |
| class_section_id | INT UNSIGNED | NOT NULL, FK → sch_class_section_jnt | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK → glb_academic_sessions | |
| total_working_days | SMALLINT UNSIGNED | NOT NULL DEFAULT 0 | |
| days_present | SMALLINT UNSIGNED | NOT NULL DEFAULT 0 | |
| days_absent | SMALLINT UNSIGNED | NOT NULL DEFAULT 0 | |
| days_late | SMALLINT UNSIGNED | NOT NULL DEFAULT 0 | Counted as present |
| days_half_day | SMALLINT UNSIGNED | NOT NULL DEFAULT 0 | Counted as 0.5 |
| days_excused | SMALLINT UNSIGNED | NOT NULL DEFAULT 0 | Approved leave days |
| attendance_percentage | DECIMAL(5,2) | NOT NULL DEFAULT 0.00 | |
| at_risk_level | ENUM('normal','borderline','warning','critical') | NOT NULL DEFAULT 'normal' | |
| pattern_flags | JSON | NULL | Weekday/streak pattern data |
| last_calculated_at | TIMESTAMP | NULL | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK → sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| **UNIQUE KEY** | (student_id, academic_session_id) | | |

### 5.12 Table: `att_staff_analytics` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| employee_id | INT UNSIGNED | NOT NULL, FK → sch_employees | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK → glb_academic_sessions | |
| total_working_days | SMALLINT UNSIGNED | NOT NULL DEFAULT 0 | |
| days_present | SMALLINT UNSIGNED | NOT NULL DEFAULT 0 | |
| days_absent | SMALLINT UNSIGNED | NOT NULL DEFAULT 0 | |
| days_on_leave | SMALLINT UNSIGNED | NOT NULL DEFAULT 0 | |
| late_arrivals_count | SMALLINT UNSIGNED | NOT NULL DEFAULT 0 | |
| early_departures_count | SMALLINT UNSIGNED | NOT NULL DEFAULT 0 | |
| avg_check_in_time | TIME | NULL | Average over present days |
| total_working_minutes | INT UNSIGNED | NOT NULL DEFAULT 0 | |
| attendance_percentage | DECIMAL(5,2) | NOT NULL DEFAULT 0.00 | |
| lwp_days | DECIMAL(4,1) | NOT NULL DEFAULT 0.0 | Leave Without Pay days for payroll |
| last_calculated_at | TIMESTAMP | NULL | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK → sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| **UNIQUE KEY** | (employee_id, academic_session_id) | | |

### 5.13 Table: `att_settings` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| attendance_mode | ENUM('day_wise','period_wise','both') | NOT NULL DEFAULT 'day_wise' | |
| school_start_time | TIME | NOT NULL DEFAULT '08:30:00' | |
| grace_period_minutes | TINYINT UNSIGNED | NOT NULL DEFAULT 15 | |
| attendance_lock_time | TIME | NOT NULL DEFAULT '17:00:00' | |
| min_attendance_pct_exam | DECIMAL(5,2) | NOT NULL DEFAULT 85.00 | Exam eligibility threshold |
| at_risk_warning_pct | DECIMAL(5,2) | NOT NULL DEFAULT 75.00 | |
| at_risk_critical_pct | DECIMAL(5,2) | NOT NULL DEFAULT 65.00 | |
| max_correction_age_days | TINYINT UNSIGNED | NOT NULL DEFAULT 30 | |
| max_regularization_per_month | TINYINT UNSIGNED | NOT NULL DEFAULT 3 | |
| send_absence_sms | TINYINT(1) | NOT NULL DEFAULT 1 | |
| send_late_arrival_alert | TINYINT(1) | NOT NULL DEFAULT 1 | |
| absence_notification_delay_minutes | TINYINT UNSIGNED | NOT NULL DEFAULT 5 | |
| enable_qr_attendance | TINYINT(1) | NOT NULL DEFAULT 0 | |
| qr_session_ttl_minutes | TINYINT UNSIGNED | NOT NULL DEFAULT 5 | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK → sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |

### 5.14 Table: `att_holiday_overrides` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| holiday_date | DATE | NOT NULL UNIQUE | |
| holiday_name | VARCHAR(100) | NOT NULL | |
| is_full_day | TINYINT(1) | NOT NULL DEFAULT 1 | 0 = half-day |
| applicable_to | ENUM('all','students','staff') | NOT NULL DEFAULT 'all' | |
| note | VARCHAR(255) | NULL | |
| academic_session_id | INT UNSIGNED | NULL, FK → glb_academic_sessions | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK → sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |

### 5.15 Summary: All att_* Tables

| Table | Purpose | Rows/Year (est.) |
|-------|---------|-----------------|
| `att_student_attendances` | Core student attendance records | ~500K (500 students × 220 days × 2 periods avg) |
| `att_staff_attendances` | Staff daily check-in/check-out | ~15K (60 staff × 250 days) |
| `att_biometric_devices` | Device master | ~10 |
| `att_device_sync_logs` | Raw device sync log | ~50K (biometric events) |
| `att_leave_types` | Leave type master (seeded) | ~10 |
| `att_leave_applications` | Leave requests | ~500/year |
| `att_leave_balances` | Per-person per-session leave balance | ~600 |
| `att_correction_requests` | Attendance correction requests | ~200/year |
| `att_regularization_requests` | Staff regularization requests | ~50/year |
| `att_notification_logs` | Absence notification audit | ~10K/year |
| `att_student_analytics` | Per-student running analytics | ~500 per session |
| `att_staff_analytics` | Per-staff running analytics | ~60 per session |
| `att_settings` | School-level configuration | 1 per tenant |
| `att_holiday_overrides` | Manual holiday overrides (ACD fallback) | ~30/year |

---

## 6. API Endpoints & Routes

> All routes are **📐 Proposed**. No routes exist yet.
> All web routes registered in `routes/tenant.php`. API routes in `routes/api.php`.

### 6.1 Web Routes (tenant.php)

```php
Route::middleware(['auth', 'verified', 'EnsureTenantHasModule:attendance'])
    ->prefix('attendance')
    ->name('attendance.')
    ->group(function () {

    // ── STUDENT ATTENDANCE ──────────────────────────────────────────
    Route::get('/student',                          [StudentAttendanceController::class, 'index'])        ->name('student.index');
    Route::get('/student/mark',                     [StudentAttendanceController::class, 'markForm'])     ->name('student.mark');
    Route::post('/student/mark',                    [StudentAttendanceController::class, 'store'])        ->name('student.store');
    Route::get('/student/{attendance}',             [StudentAttendanceController::class, 'show'])         ->name('student.show');
    Route::put('/student/{attendance}',             [StudentAttendanceController::class, 'update'])       ->name('student.update');
    Route::post('/student/bulk-import',             [StudentAttendanceController::class, 'bulkImport'])   ->name('student.bulkImport');

    // ── PERIOD ATTENDANCE ───────────────────────────────────────────
    Route::get('/student/period/mark',              [PeriodAttendanceController::class, 'markForm'])      ->name('period.mark');
    Route::post('/student/period/mark',             [PeriodAttendanceController::class, 'store'])         ->name('period.store');

    // ── CORRECTION REQUESTS ─────────────────────────────────────────
    Route::get('/corrections',                      [CorrectionRequestController::class, 'index'])        ->name('correction.index');
    Route::post('/corrections',                     [CorrectionRequestController::class, 'store'])        ->name('correction.store');
    Route::put('/corrections/{correction}/review',  [CorrectionRequestController::class, 'review'])      ->name('correction.review');
    Route::put('/corrections/{correction}/approve', [CorrectionRequestController::class, 'approve'])     ->name('correction.approve');

    // ── STAFF ATTENDANCE ────────────────────────────────────────────
    Route::get('/staff',                            [StaffAttendanceController::class, 'index'])          ->name('staff.index');
    Route::post('/staff/mark',                      [StaffAttendanceController::class, 'store'])          ->name('staff.store');
    Route::put('/staff/{attendance}',               [StaffAttendanceController::class, 'update'])         ->name('staff.update');

    // ── REGULARIZATION ──────────────────────────────────────────────
    Route::get('/staff/regularization',             [RegularizationController::class, 'index'])           ->name('regularization.index');
    Route::post('/staff/regularization',            [RegularizationController::class, 'store'])           ->name('regularization.store');
    Route::put('/staff/regularization/{req}/approve', [RegularizationController::class, 'approve'])      ->name('regularization.approve');

    // ── LEAVE TYPES ─────────────────────────────────────────────────
    Route::get('/leave-types',                      [LeaveTypeController::class, 'index'])                ->name('leaveType.index');
    Route::post('/leave-types',                     [LeaveTypeController::class, 'store'])                ->name('leaveType.store');
    Route::put('/leave-types/{type}',               [LeaveTypeController::class, 'update'])               ->name('leaveType.update');
    Route::delete('/leave-types/{type}',            [LeaveTypeController::class, 'destroy'])              ->name('leaveType.destroy');

    // ── LEAVE APPLICATIONS ──────────────────────────────────────────
    Route::get('/leaves',                           [LeaveApplicationController::class, 'index'])         ->name('leave.index');
    Route::post('/leaves',                          [LeaveApplicationController::class, 'store'])         ->name('leave.store');
    Route::get('/leaves/{application}',             [LeaveApplicationController::class, 'show'])          ->name('leave.show');
    Route::put('/leaves/{application}/review',      [LeaveApplicationController::class, 'review'])        ->name('leave.review');
    Route::put('/leaves/{application}/approve',     [LeaveApplicationController::class, 'approve'])       ->name('leave.approve');
    Route::put('/leaves/{application}/cancel',      [LeaveApplicationController::class, 'cancel'])        ->name('leave.cancel');

    // ── BIOMETRIC DEVICES ───────────────────────────────────────────
    Route::get('/devices',                          [BiometricDeviceController::class, 'index'])          ->name('device.index');
    Route::post('/devices',                         [BiometricDeviceController::class, 'store'])          ->name('device.store');
    Route::put('/devices/{device}',                 [BiometricDeviceController::class, 'update'])         ->name('device.update');
    Route::delete('/devices/{device}',              [BiometricDeviceController::class, 'destroy'])        ->name('device.destroy');

    // ── REPORTS ─────────────────────────────────────────────────────
    Route::get('/reports/daily',                    [AttendanceReportController::class, 'daily'])         ->name('report.daily');
    Route::get('/reports/monthly',                  [AttendanceReportController::class, 'monthly'])       ->name('report.monthly');
    Route::get('/reports/compliance',               [AttendanceReportController::class, 'compliance'])    ->name('report.compliance');
    Route::get('/reports/staff',                    [AttendanceReportController::class, 'staff'])         ->name('report.staff');
    Route::get('/reports/at-risk',                  [AttendanceReportController::class, 'atRisk'])        ->name('report.atRisk');

    // ── SETTINGS ────────────────────────────────────────────────────
    Route::get('/settings',                         [AttendanceSettingsController::class, 'edit'])        ->name('settings.edit');
    Route::put('/settings',                         [AttendanceSettingsController::class, 'update'])      ->name('settings.update');
});
```

### 6.2 API Routes (api.php)

```php
// ── DEVICE SYNC (Sanctum device token auth) ──────────────────────
Route::post('/v1/attendance/device-sync', [Api\DeviceSyncController::class, 'sync']);

// ── INTERNAL READ API (used by PAN, HRS modules) ─────────────────
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/v1/attendance/analytics/student/{student_id}',
        [Api\AttendanceApiController::class, 'studentAnalytics']);
    Route::get('/v1/attendance/analytics/class/{class_section_id}',
        [Api\AttendanceApiController::class, 'classAnalytics']);
    Route::get('/v1/attendance/staff/monthly-summary/{employee_id}/{year}/{month}',
        [Api\AttendanceApiController::class, 'staffMonthlySummary']);
    Route::get('/v1/attendance/daily',
        [Api\AttendanceApiController::class, 'dailySummary']);
    Route::get('/v1/students/{id}/attendance',
        [Api\AttendanceApiController::class, 'studentHistory']);
});
```

---

## 7. UI Screens

| Screen ID | Screen Name | Route Name | Description |
|-----------|-------------|------------|-------------|
| ATT-SCR-01 | Student Attendance Dashboard | `attendance.student.index` | Today's class-wise summary: present/absent/late counts, pending marking alerts |
| ATT-SCR-02 | Mark Daily Attendance | `attendance.student.mark` | Class-section selector + date picker + student roster with P/A/L/HD toggles; Mark All Present shortcut |
| ATT-SCR-03 | Mark Period Attendance | `attendance.period.mark` | Period selector (from timetable) + subject-level student roster |
| ATT-SCR-04 | Attendance Correction List | `attendance.correction.index` | Pending/approved/rejected corrections with status filters |
| ATT-SCR-05 | Submit Correction Request | `attendance.correction.store` | Form: date, current status, requested status, reason, upload document |
| ATT-SCR-06 | Staff Attendance Dashboard | `attendance.staff.index` | Daily summary widget: check-in counts, late arrivals, absent staff |
| ATT-SCR-07 | Mark Staff Attendance | `attendance.staff.store` | Employee list with manual check-in/check-out time entry |
| ATT-SCR-08 | Regularization Requests | `attendance.regularization.index` | Pending HR approvals with employee details and expected times |
| ATT-SCR-09 | Leave Type Master | `attendance.leaveType.index` | Leave type CRUD with applicable-to and balance rules |
| ATT-SCR-10 | Leave Applications List | `attendance.leave.index` | All applications with status filter, date filter, applicant type filter |
| ATT-SCR-11 | Apply for Leave | `attendance.leave.store` | Multi-step form: dates, leave type, reason, document upload |
| ATT-SCR-12 | Leave Application Detail | `attendance.leave.show` | Full application with approval chain timeline |
| ATT-SCR-13 | Biometric Device Manager | `attendance.device.index` | Device list with online/offline/maintenance status indicator, last sync time |
| ATT-SCR-14 | Daily Attendance Report | `attendance.report.daily` | Class-wise table: date filter, present/absent/late counts, export PDF/CSV |
| ATT-SCR-15 | Monthly Attendance Summary | `attendance.report.monthly` | Student-wise date grid, P/A/L/H cells, percentage column, export PDF/Excel |
| ATT-SCR-16 | Government Compliance Register | `attendance.report.compliance` | CBSE-format register, A3 landscape PDF, school letterhead |
| ATT-SCR-17 | Staff Attendance Report | `attendance.report.staff` | Department-wise report: check-in/out times, LWP days, export |
| ATT-SCR-18 | At-Risk Analytics Dashboard | `attendance.report.atRisk` | At-risk student list with percentage, days to threshold, pattern flags |
| ATT-SCR-19 | Attendance Settings | `attendance.settings.edit` | School-level config: thresholds, lock time, mode, notification toggles |

**Key UX Notes:**
- ATT-SCR-02 (Mark Daily Attendance) must be mobile-optimized. Swipe right = present, swipe left = absent. Teacher typically marks on phone in classroom.
- ATT-SCR-02 uses Livewire or AJAX for real-time roster updates without page reload.
- ATT-SCR-15 and ATT-SCR-16 are heavy render jobs — generate in background with progress indicator.
- ATT-SCR-18 shows traffic-light color coding: red = critical, amber = warning, green = normal.

---

## 8. Business Rules

**BR-ATT-01:** Only one daily attendance record is permitted per student per date per class-section. Duplicate inserts are rejected at the database level via UNIQUE KEY on `(class_section_id, student_id, attendance_date, period_id)`.

**BR-ATT-02:** Attendance cannot be marked for a future date. Any attempt to mark future attendance returns validation error `E3003`.

**BR-ATT-03:** The attendance percentage denominator counts only working school days. Holidays (from ACD calendar or `att_holiday_overrides`) are excluded.

**BR-ATT-04:** An `excused` leave day does not reduce the attendance percentage. It is counted as a worked day for compliance purposes.

**BR-ATT-05:** Late arrival within grace period counts as `present`. Late arrival beyond grace period counts as `late` — still present for percentage calculation but flagged in reports.

**BR-ATT-06:** A `half_day` attendance counts as 0.5 days for percentage calculation.

**BR-ATT-07:** An attendance correction request older than `att_settings.max_correction_age_days` (default: 30 days) cannot be submitted. This prevents retroactive manipulation of finalized government registers.

**BR-ATT-08:** Absence notification to parents must be suppressed when the student already has an approved leave for that date. Notification is also suppressed when parent has opted out of attendance notifications in their portal settings.

**BR-ATT-09:** When `attendance_percentage` drops below `at_risk_critical_pct`, `at_risk_level = 'critical'`; below `at_risk_warning_pct`, `at_risk_level = 'warning'`; below `min_attendance_pct_exam`, `at_risk_level = 'borderline'`. Students below `min_attendance_pct_exam` are ineligible for exam registration (EXM module cross-check).

**BR-ATT-10:** Staff regularization requests exceeding `att_settings.max_regularization_per_month` in a calendar month are automatically rejected at submission.

**BR-ATT-11:** Biometric device sync API requires device-specific API key authentication. Requests with invalid `device_code` or missing auth header are rejected with HTTP 401.

**BR-ATT-12:** Leave balance cannot go negative without approver override. If a leave application would exceed balance, the system warns the approver (unpaid leave territory) but does not auto-reject.

**BR-ATT-13:** When a leave application is approved, corresponding attendance records for the approved date range must be created or updated to `excused` (student) or `on_leave` (staff) status.

**BR-ATT-14:** Attendance for a date is locked after `att_settings.attendance_lock_time`. Locked dates are read-only. Admin can override the lock with a reason.

**BR-ATT-15:** Period attendance for a day cannot be marked if daily attendance for that student on that day is `holiday`.

**BR-ATT-16:** The biometric sync API must return HTTP 200 for duplicate events (within 5-minute window) to prevent device retry storms. The duplicate is silently discarded server-side.

**BR-ATT-17:** The CBSE government compliance register must account for the board-specific minimum: CBSE = 75% for regular promotion, 85% for board exams. Both thresholds are configurable in `att_settings` to support non-CBSE boards.

---

## 9. Workflows

### 9.1 Student Daily Attendance Flow

```
Teacher opens ATT-SCR-02 (Mark Daily Attendance)
  → Selects class-section + date (validated: not future, not locked, not holiday)
  → System loads student roster from std_student_academic_sessions
  → Teacher marks each student (or uses Mark All Present + overrides)
  → Teacher submits form

System processing:
  → Validates: no future date, no locked date, no holiday
  → Checks existing records for duplicates (UNIQUE KEY guard)
  → Bulk inserts att_student_attendances records
  → For each absent student:
      → Fires AttendanceMarkedAbsent event (delayed by absence_notification_delay_minutes)
      → SendAbsenceNotification listener: dispatches NTF event
  → For each late student (beyond grace period):
      → Fires AttendanceLateArrival event (if send_late_arrival_alert = 1)
  → Queues RecalculateStudentAnalyticsJob for each affected student
  → RecalculateStudentAnalyticsJob:
      → Recomputes days_present/absent/late/etc.
      → Recomputes attendance_percentage
      → Updates at_risk_level
      → If at_risk_level changed: fires AttendanceAtRisk event
      → Detects weekday/streak patterns; updates pattern_flags
```

### 9.2 Leave Application FSM

```
States: pending → pending_principal | approved | rejected | cancelled

PENDING (submitted by student/parent/staff)
  ↓ Level-1 Reviewer (class teacher for student; HOD for staff)
  → REJECTED: reviewer_remarks saved; requester notified via NTF
  → APPROVED (direct, if ≤ 3 consecutive days student / ≤ 5 staff):
      → att_leave_balances.used_days += total_days
      → att_student/staff_attendances records created/updated to excused/on_leave
      → Requester notified of approval
  → PENDING_PRINCIPAL (> 3 consecutive days student / > 5 staff or specific leave types):
      ↓ Principal / HR Admin reviews
      → REJECTED: approval_remarks saved; requester notified
      → APPROVED:
          → Same side-effects as direct approval above

APPROVED → CANCELLED (admin action, same academic session only)
  → att_student/staff_attendances records reverted to absent
  → att_leave_balances.used_days decremented
  → Requester notified of cancellation
```

### 9.3 Attendance Correction State Machine

```
States: pending → teacher_approved | approved | rejected

PENDING (submitted by teacher / student / parent)
  ↓ Class teacher reviews
  → REJECTED: teacher_remarks saved; requester notified
  → TEACHER_APPROVED
      ↓ Admin / Principal final review
      → REJECTED: requester notified
      → APPROVED:
          → att_student_attendances.status updated to requested_status
          → original_status preserved in att_correction_requests.original_status
          → RecalculateStudentAnalyticsJob queued
          → sys_activity_logs entry written (old_value, new_value, changed_by)
```

### 9.4 Biometric Sync Flow

```
Biometric Device
  → POST /api/v1/attendance/device-sync (device API key in header)
  → DeviceSyncController:
      → Validates device_code + auth_token (HTTP 401 if invalid)
      → Resolves employee_id or student_id from payload
      → Checks duplicate: same person + direction within 5 minutes → return HTTP 200 (discard)
      → Logs raw payload to att_device_sync_logs
      → direction = 'in':
          → Upsert att_staff/student_attendances.check_in_time
          → If check_in > school_start + grace → status = 'late'
      → direction = 'out':
          → Update att_staff_attendances.check_out_time
          → Compute working_minutes
      → Updates att_biometric_devices.last_sync_at
      → Returns HTTP 200 {"status": "processed"}
```

### 9.5 Staff Regularization Workflow

```
Staff submits regularization (date + expected times + reason)
  → System checks: count of pending/approved requests this calendar month
  → If count >= max_regularization_per_month → rejected: E3004
  → PENDING (within limit)
      ↓ HR Admin reviews
      → REJECTED → Employee notified via NTF in-app
      → APPROVED:
          → att_staff_attendances updated with expected_check_in/check_out
          → is_regularized = 1; regularization_id = att_regularization_requests.id
          → source updated to 'regularized'
          → Employee notified of approval
```

### 9.6 Monthly Analytics Aggregation Flow

```
Scheduled Job: RecalculateStudentAnalyticsJob (queued after each attendance event)
  → SELECT all att_student_attendances for student × session
  → COUNT days by status
  → Apply formula: percentage = ((present + excused + 0.5 × half_day) / working_days) × 100
  → Determine at_risk_level from thresholds in att_settings
  → Detect patterns (weekday, streak) from raw attendance sequence
  → Upsert att_student_analytics

Scheduled Job: GenerateMonthlyRegisterJob (1st of each month, 02:00)
  → For each class-section in all active schools:
      → Generate CBSE compliance register PDF via DomPDF
      → Store in sys_media with tag = 'monthly_attendance_register'
      → Admin notified: "March 2026 Attendance Registers ready"

Scheduled Command: attendance:send-daily-summary (daily 11:00 AM)
  → Aggregates today's attendance across all classes
  → Sends summary to admin dashboard (in-app widget update)
  → Fires NTF event for admin notification
```

---

## 10. Non-Functional Requirements

**NFR-ATT-01 (Performance):**
- Attendance marking for a full class of 60 students must complete in ≤ 2 seconds (bulk insert).
- Bulk CSV import of 500 records must complete in ≤ 10 seconds.
- Monthly compliance report generation for 500 students must complete in ≤ 15 seconds (synchronous) or be queued for background generation.
- `RecalculateStudentAnalyticsJob` must complete per student in ≤ 500ms.

**NFR-ATT-02 (Reliability):**
- Biometric sync API is stateless and idempotent. Duplicate sync within 5 minutes is silently discarded; API returns HTTP 200 for duplicates.
- All queued jobs (`RecalculateStudentAnalyticsJob`, `SendAbsenceNotification`) must use Laravel Queue with retry logic (3 attempts, exponential backoff).

**NFR-ATT-03 (Availability — Offline PWA Consideration):**
- The attendance marking screen (ATT-SCR-02) must be accessible offline on mobile browsers with pending records queued locally and synced when connectivity is restored.
- This is a progressive enhancement; core functionality must work without offline mode.

**NFR-ATT-04 (Data Integrity):**
- All attendance updates write an audit entry to `sys_activity_logs`.
- Original value before any correction is preserved in `att_correction_requests.original_status`.
- Leave cancellation must atomically revert attendance records and restore leave balance in a database transaction.

**NFR-ATT-05 (Security):**
- Biometric device API keys are stored AES-256 encrypted in `att_biometric_devices.auth_token_encrypted`.
- Sync endpoint rejects requests without valid device authentication.
- Teachers can only view and mark attendance for their own assigned class-sections; cross-section access is blocked at the Policy level (`StudentAttendancePolicy`).
- Soft delete on all attendance records; physical delete is never allowed.

**NFR-ATT-06 (Scalability):**
- `RecalculateStudentAnalyticsJob` must be asynchronous (queued). Bulk attendance events for a school of 2,000 students must not block the HTTP response.
- Analytics recalculation uses upsert, not full recalculate from scratch where possible.

**NFR-ATT-07 (Compliance):**
- Monthly attendance register PDF must match CBSE/State Board prescribed format exactly, including signature blocks, school header, class teacher certification statement, and correct column layout for A3 landscape print.
- Attendance data must be retained for at least 7 years per Indian educational record-keeping regulations.

**NFR-ATT-08 (Localization):**
- Attendance reports must support Indian date formats (DD-MM-YYYY).
- Report PDF headers must support school name in regional language (UTF8MB4 stored in `sch_schools.name_regional`).

---

## 11. Dependencies

| Module | Direction | Tables / APIs Consumed | Purpose |
|--------|-----------|----------------------|---------|
| School Setup (`sch_*`) | Consumes | `sch_class_section_jnt`, `sch_classes`, `sch_sections`, `sch_employees`, `sch_teacher_profile`, `sch_schools` | Class-section roster, staff, school config |
| Student Management (`std_*`) | Consumes | `std_students`, `std_student_academic_sessions`, `std_guardians`, `std_student_guardian_jnt`, `std_students.smart_card_id` | Student roster, parent contacts, smart card |
| Global Masters (`glb_*`) | Consumes | `glb_academic_sessions` | Session-scoped attendance |
| System Config (`sys_*`) | Consumes | `sys_users`, `sys_media`, `sys_activity_logs`, `sys_permissions`, `sys_roles` | Auth, media upload, audit, RBAC |
| Notification (NTF) | Pushes events | NTF event bus | Absence/late/at-risk SMS, email, in-app |
| Academics (ACD) | Consumes | `acd_calendar_events` (is_working_day) | Holiday calendar for working-day denominator |
| Timetable (TT) | Consumes | `tt_period_types`, `tt_timetable_cells` | Period definitions for period-level attendance |
| Examination (EXM) | Provides policy | `AttendancePolicy::isExamEligible()` | ATT provides exam eligibility gate |
| HR & Payroll (HRS) | Provides data | `att_staff_analytics.lwp_days` via internal API | Staff LWP days feed payroll deduction |
| Predictive Analytics (PAN) | Provides data | `att_student_analytics` via internal API | Attendance feed for ML models |
| Parent Portal (PPT) | Provides data | Student attendance history + leave application via API | Parent view of child attendance |
| Student Portal (STP) | Provides data | Own attendance history + leave submission | Student self-service |
| Dashboard (DSH) | Provides data | Daily summary widgets, at-risk count | Dashboard KPI widgets |

---

## 12. Test Scenarios

> No tests exist. Full test suite required. Platform: Pest (feature tests), PHPUnit unit tests.

| Test Class | Type | Priority | Scenarios |
|-----------|------|----------|-----------|
| `StudentAttendanceControllerTest` | Feature | P0 | Mark present/absent/late; duplicate prevention; date validation; Mark All Present; locked date rejection |
| `AttendanceCorrectionWorkflowTest` | Feature | P0 | Full correction chain; date age limit; teacher rejection; admin final approval; audit log creation |
| `LeaveApplicationWorkflowTest` | Feature | P0 | Student leave apply → teacher approve → attendance updated to excused; leave > 3 days requires principal; balance deduction; cancellation reverts records |
| `StaffAttendanceControllerTest` | Feature | P0 | Manual check-in/out; late detection; duplicate update (no new record); regularization approval chain |
| `BiometricDeviceSyncTest` | Feature | P0 | Valid sync → record created; invalid device → 401; duplicate within 5 min → 200 + no duplicate; unknown smart card → error logged |
| `AttendanceAnalyticsCalculationTest` | Unit | P0 | Percentage formula correctness; at-risk level thresholds; half-day 0.5 weight; excused days not reducing denominator |
| `LeaveBalanceCalculationTest` | Unit | P0 | Balance deduction on approval; LOP warning at zero balance; carry-forward on session rollover; half-day deducts 0.5 |
| `ParentNotificationTriggerTest` | Feature | P1 | Absent fires NTF event; approved leave suppresses notification; parent opted-out suppresses; late arrival respects setting toggle |
| `MonthlyRegisterReportTest` | Feature | P1 | 40 students × 26 days → correct P/A/H cell values; holiday exclusion; PDF generation succeeds; CBSE column layout |
| `StaffRegularizationLimitTest` | Unit | P1 | Third request in month accepted; fourth rejected; approved regularization updates check-in/out correctly |
| `PatternDetectionTest` | Unit | P2 | 4 consecutive Monday absences → weekday pattern flag; 4 consecutive absent days → streak flag; pattern cleared after recovery |
| `QRAttendanceTest` | Feature | P2 | Valid QR scan → attendance created; expired QR → 422; QR feature disabled in settings → 403 |
| `BackdatedAttendanceTest` | Feature | P2 | Current month backdated → no principal approval needed; prior month → principal required |
| `AttendanceSettingsTest` | Feature | P1 | Settings update persists; grace period affects late detection; lock time blocks marking after threshold |

**Sample Test (Pest syntax):**
```php
it('suppresses absence notification when student has approved leave', function () {
    $student = Student::factory()->create();
    $leave = LeaveApplication::factory()->approved()->create([
        'student_id' => $student->id,
        'from_date' => today(),
        'to_date' => today(),
    ]);

    Event::fake([AttendanceMarkedAbsent::class]);

    AttendanceService::markDaily($student, today(), 'absent');

    // Notification should be suppressed because leave exists
    Event::assertNotDispatched(AttendanceMarkedAbsent::class);
});
```

---

## 13. Glossary

| Term | Definition |
|------|-----------|
| Working Day | A school calendar day that is not a holiday, weekend, or declared non-working day |
| Attendance Percentage | `(days_present + days_excused + 0.5 × days_half_day) / total_working_days × 100` |
| Grace Period | Minutes after school start time within which arrival counts as on-time (not late) |
| Excused Absence | An absence covered by an approved leave application; does not reduce attendance percentage denominator |
| At-Risk Student | A student whose attendance percentage falls below the warning threshold (configurable, default 75%) |
| CBSE Compliance | Central Board of Secondary Education attendance register format and minimum attendance requirements |
| Regularization | Process by which a staff member corrects a missed biometric check-in/check-out via HR approval |
| Biometric Sync | Automated transmission of device attendance logs to the ATT module via HTTP POST API |
| Period Attendance | Subject-level attendance marked per timetable period (vs. once-per-day daily attendance) |
| Half-Day | Attendance status where student/staff was present for only half the working day; counts as 0.5 in percentage |
| LWP | Leave Without Pay — leave taken after leave balance is exhausted; deducted from salary by HRS Payroll |
| Short Leave | Departure before end of school day; recorded as `half_day` with `half_day_type = 'afternoon'` |
| QR Session | A time-limited (TTL configurable) QR code generated by teacher for a single attendance marking session |
| RFID / Smart Card | Radio-frequency identification card carried by student/staff; tapped at entry point for auto-attendance |
| Pattern Flag | A JSON-encoded signal in `att_student_analytics.pattern_flags` indicating a recurring absence pattern |

---

## 14. Suggestions

### Priority 1 — Foundation

1. **Mobile-first attendance marking:** ATT-SCR-02 must be a single-page Livewire form with swipe gestures (right = present, left = absent) optimized for phone screens. Teachers mark attendance on phones in the classroom; desktop-first UI will cause adoption failure.

2. **Idempotent biometric API from day one:** Schools have unreliable biometric devices that retry failed syncs. Design the sync endpoint idempotent at the start rather than retrofitting. The 5-minute duplicate window handles most device retry storms.

3. **Attendance lock mechanism:** Implement `att_settings.attendance_lock_time` from day one. Schools frequently have problems with teachers modifying attendance retroactively. A hard lock with admin-override-only protects data integrity and simplifies government audits.

4. **Configurable board thresholds:** Do not hardcode 75% or 85%. Store in `att_settings`. CBSE uses 75% minimum for promotion and 85% for board exams. State boards may differ. The same system must serve ICSE, IB, and state board schools without code changes.

### Priority 2 — Integration

5. **HRS Payroll integration:** `att_staff_analytics.lwp_days` must be the single source of truth for payroll LWP deductions. Do not build a parallel attendance calculation in HRS. HRS Payroll should call the ATT internal API and trust it. Define the API contract (Section 6.2) at development start.

6. **ACD holiday calendar as primary source:** Do not build a parallel holiday calendar in ATT. `att_holiday_overrides` is only a fallback when ACD module is not licensed. This prevents schools from managing two holiday calendars and getting mismatched working-day counts.

7. **NTF notification timing:** The absence SMS to parents must fire within 5 minutes of attendance marking to be useful. If attendance is marked at 09:00 and SMS arrives at 11:00, parents have already called. Use the configurable delay (`absence_notification_delay_minutes`) with a sensible default of 5 minutes, not 60.

### Priority 3 — Analytics

8. **At-risk counseling workflow:** The at-risk flagging should trigger a workflow where the class teacher is required to log a counseling contact (phone call / parent meeting note) in the system. This satisfies CBSE requirements for proactive intervention documentation and creates a paper trail for board inspections.

9. **Pre-generated compliance reports:** Monthly government compliance register PDFs should be auto-generated on the 1st of each month (via `GenerateMonthlyRegisterJob`) and stored in `sys_media`. This way the report is always instantly available for download — no on-demand generation delay when the school inspector arrives.

10. **PAN integration preparation:** Store `pattern_flags` from the very first implementation. The PAN module's dropout prediction model will need 2–3 sessions of historical attendance data to be useful. Retrofitting historical pattern extraction is expensive. Start capturing it from session 1.

11. **QR attendance for events / PT meetings:** The QR mode (D.D6) is valuable beyond classroom attendance — use it for parent-teacher meetings, school events, and library entry logs. Design the QR session model to be generic enough to attach to any `event_type`, not just classroom periods.

---

## 15. Appendices

### Appendix A: Proposed Seeder Data

```php
// att_leave_types seeds (system-seeded, applicable to both student and staff unless noted)
['name' => 'Medical Leave',         'code' => 'ML',   'applicable_to' => 'both',    'max_days' => 10, 'requires_document' => 1],
['name' => 'Casual Leave',          'code' => 'CL',   'applicable_to' => 'staff',   'max_days' => 12, 'requires_document' => 0],
['name' => 'Earned Leave',          'code' => 'EL',   'applicable_to' => 'staff',   'max_days' => 15, 'carry_forward_limit' => 10],
['name' => 'Maternity Leave',       'code' => 'MatL', 'applicable_to' => 'staff',   'max_days' => 180,'requires_document' => 1],
['name' => 'Paternity Leave',       'code' => 'PatL', 'applicable_to' => 'staff',   'max_days' => 7,  'requires_document' => 1],
['name' => 'Student Medical Leave', 'code' => 'SML',  'applicable_to' => 'student', 'max_days' => 10, 'requires_document' => 1],
['name' => 'Student Personal Leave','code' => 'SPL',  'applicable_to' => 'student', 'max_days' => 5,  'requires_document' => 0],
```

### Appendix B: Notification Event Codes

| Event Code | Trigger | Recipients | Channels |
|-----------|---------|-----------|---------|
| `ATTENDANCE_MARKED_ABSENT` | Student marked absent | Parent/Guardian | SMS + In-App |
| `ATTENDANCE_MARKED_LATE` | Student marked late | Parent/Guardian | In-App |
| `ATTENDANCE_AT_RISK_WARNING` | % drops below warning threshold | Class Teacher + Parent | Email + In-App |
| `ATTENDANCE_AT_RISK_CRITICAL` | % drops below critical threshold | Class Teacher + Principal + Parent | SMS + Email + In-App |
| `LEAVE_APPLICATION_SUBMITTED` | New leave application | Class Teacher / HOD | In-App |
| `LEAVE_APPLICATION_APPROVED` | Leave approved | Student/Parent/Employee | SMS + In-App |
| `LEAVE_APPLICATION_REJECTED` | Leave rejected | Student/Parent/Employee | In-App |
| `STAFF_LATE_ARRIVAL_ALERT` | Staff check-in after grace period | HR Admin + Department Head | In-App |
| `REGULARIZATION_APPROVED` | Staff regularization approved | Employee | In-App |
| `WEEKLY_AT_RISK_SUMMARY` | Weekly job | Class Teachers + Principal | Email |

### Appendix C: Scheduled Commands

| Command | Schedule | Module | Description |
|---------|----------|--------|-------------|
| `attendance:send-daily-summary` | Daily 11:00 AM | ATT, NTF | Today's attendance summary to admin dashboard |
| `attendance:recalculate-analytics` | Daily 23:00 | ATT | Full nightly recalculation of `att_student_analytics` |
| `attendance:send-weekly-at-risk` | Weekly Monday 07:00 | ATT, NTF | At-risk student list to class teachers and principal |
| `attendance:generate-monthly-register` | Monthly, 1st day 02:00 | ATT | Pre-generate CBSE compliance PDF for prior month |
| `attendance:ping-devices` | Every 5 minutes | ATT | Ping all active biometric devices; update `device_status` |
| `attendance:session-rollover` | On session start | ATT | Carry-forward leave balances from prior session |

### Appendix D: Error Codes

| Code | Description |
|------|-------------|
| `E3001` | Attendance already marked for this student/date |
| `E3002` | Student not enrolled in this class-section |
| `E3003` | Attendance cannot be marked for a future date |
| `E3004` | Regularization limit exceeded for this month |
| `E3005` | Correction request too old (exceeds max_correction_age_days) |
| `E3006` | Leave exceeds max_consecutive_days for leave type |
| `E3007` | Invalid biometric device code (HTTP 401) |
| `E3008` | Attendance locked for this date; admin override required |
| `QR_EXPIRED` | QR code session has expired (TTL exceeded) |
| `UNKNOWN_CARD` | Smart card ID not registered in the system |

### Appendix E: RBS Sub-Task Coverage Map

| RBS Sub-Task (PrimeAI_Complete_Spec_v2.md) | FR Coverage |
|-----------|------------|
| D.D1 — Student Attendance (daily, bulk) | FR-ATT-001 |
| D.D1 — Period/subject attendance | FR-ATT-002 |
| D.D1 — Attendance correction | FR-ATT-003 |
| D.D1 — Attendance lock | BR-ATT-14 |
| D.D2 — Staff attendance, regularization | FR-ATT-004 |
| D.D2 — Leave management | FR-ATT-006 |
| D.D3 — Reports (daily, monthly, compliance) | FR-ATT-009 |
| D.D3 — At-risk analytics, pattern detection | FR-ATT-008 |
| D.D4 — Parent notifications | FR-ATT-007 |
| D.D5 — Biometric integration | FR-ATT-005 |
| D.D6 — QR code attendance | FR-ATT-005 (REQ-005.4) |
| Y7.1 — Attendance settings | FR-ATT-010 |
| V2 — PAN attendance forecasting feed | FR-ATT-011 |
| C.C2 — Staff attendance (HRS linkage) | FR-ATT-004 (REQ-004.3) |

---

## 16. V1 to V2 Delta

| Area | V1 Specification | V2 Change | Reason |
|------|-----------------|-----------|--------|
| Module header | Minimal header, no module path or nwidart context | Full V2 header with module identity, scale table, processing mode | Standardized V2 format |
| Migration section | Not in V1 | Added Section 2.1 — detailed STD → ATT migration plan with steps | ATT replaces STD AttendanceController (zero auth) |
| At-risk levels | 3 levels: normal / warning / critical | 4 levels: normal / borderline / warning / critical | Added `borderline` (75–85%) between passing and at-risk for finer-grained action |
| Short leave / early departure | Mentioned briefly | REQ-ATT-001.4 added as explicit requirement | Explicitly called out in V2 prompt scope |
| QR attendance | Listed in V1 feature summary | FR-ATT-005 REQ-005.4 fully specified with TTL, session model | D.D6 RBS sub-module included |
| `att_device_sync_logs` | Not in V1 data model | Added as Table 5.4 | Audit trail for biometric raw payloads; debugging device issues |
| Backdated attendance | Mentioned in FR-ATT-003 | REQ-ATT-003.3 split as dedicated requirement with current/prior month distinction | Explicitly in V2 scope |
| PAN integration | Not in V1 | FR-ATT-011 added | V2 prompt scope: attendance feed to predictive analytics |
| HRS payroll LWP | Mentioned in dependencies | FR-ATT-004 REQ-004.3 and `att_staff_analytics.lwp_days` column added | Explicit payroll deduction integration |
| `att_settings.attendance_mode` | Not in V1 | Added to settings table | Controls whether day_wise / period_wise / both screens are enabled |
| `att_settings.attendance_lock_time` | Not in V1 | Added to settings; BR-ATT-14 added | Required for data integrity and compliance register finalization |
| `att_settings.enable_qr_attendance` | Not in V1 | Added | Controls QR feature availability per school |
| `att_student_attendances.is_locked` | Not in V1 | Added column | Records whether individual attendance record is locked |
| `att_student_attendances.source` | V1 had 6 values | Added `backdated` and `qr` source types | New sources in V2 scope |
| Table count | 13 tables | 14 tables (added `att_device_sync_logs`) | New table for biometric sync audit |
| Test scenarios | 11 test classes | 14 test classes (added QR, backdated, settings tests) | V2 new features need coverage |
| Scheduled commands | Listed in appendix | Formalized with exact cron schedule and command name | Operational clarity for V2 |
| RBAC section | Mentioned in stakeholders | Section 3 expanded with explicit permission code table | Required for sys_permissions seeder |
