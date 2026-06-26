# BRD-04: Health, Medical & Attendance Management

**Document Version:** 1.0
**Date:** 2026-05-21
**Author:** Business Analyst
**Status:** Draft

---

## 1. Business Need

### 1.1 Problem Statement
Schools are responsible for student well-being during school hours. They must maintain accurate health records for emergency response, track medical incidents that occur on campus, ensure vaccination compliance, and record daily attendance for regulatory and safety purposes. Without a centralized system, health information is scattered across paper files, attendance is tracked in registers, and there is no way to quickly identify students with allergies or chronic conditions during an emergency. Attendance records are also prone to errors requiring a formal correction process.

### 1.2 Business Objectives
- Maintain up-to-date health profiles for every student including allergies and chronic conditions
- Track all medical incidents on campus (injuries, sickness, fainting) with follow-up management
- Record vaccination history for compliance with health regulations
- Enable daily attendance marking (present, absent, late, half-day, leave)
- Support period-wise attendance for detailed tracking
- Allow parents/students to request corrections to attendance records
- Ensure role-based access to sensitive health information

---

## 2. Scope

### 2.1 In Scope
- Student health profile (blood group, allergies, chronic conditions, medications, vision, doctor info)
- Vaccination records (vaccine name, dates, next due date)
- Medical incident logging (date, type, description, first aid, action taken)
- Parent notification tracking for medical incidents
- Medical incident follow-up management
- Daily attendance marking (individual and bulk)
- Period-wise attendance (configurable)
- Attendance correction request workflow
- Role-based access control

### 2.2 Out of Scope
- Telemedicine or online doctor consultation
- Prescription management or medication administration
- Biometric/RFID hardware integration for attendance (scanning interface exists, hardware setup is separate)
- Automated attendance via timetable integration
- Leave management (covered in BRD-05)

---

## 3. Stakeholders

| Stakeholder | Interest |
|---|---|
| School Admin | Needs holistic view of student health and attendance for reporting |
| School Nurse | Manages health profiles, logs incidents, tracks vaccinations |
| Class Teacher | Marks daily attendance, responds to medical incidents in classroom |
| Physical Education Teacher | Needs visibility into students with medical restrictions |
| Parent | Wants to know if child was involved in a medical incident or marked absent |
| Student | Needs ability to request attendance corrections |
| Principal | Requires attendance reports and health compliance data |

---

## 4. User Roles & Permissions

| Role | Health View | Health Edit | Attendance Mark | Attendance Corrections | Medical Incidents |
|---|---|---|---|---|---|
| Super Admin | ✓ | ✓ | ✓ | Approve | Full CRUD |
| School Admin | ✓ | ✓ | ✓ | Approve | Full CRUD |
| Principal | ✓ | ✗ | ✗ | View | View |
| Teacher | ✓ | Limited* | ✓ | ✓ (own class) | Report |
| School Nurse | ✓ | ✓ | ✗ | ✗ | Full CRUD |
| Clerk | ✓ | ✓ | ✗ | ✗ | View |

*\*Teachers may only update emergency-relevant health fields.*

---

## 5. Functional Requirements

### 5.1 Student Health Profile
**As a** School Nurse / School Admin,
**I want to** maintain a health profile for every student
**So that** I can quickly access critical medical information during emergencies.

**Requirements:**
- FR-01: System shall capture blood group (A+, A-, B+, B-, AB+, AB-, O+, O-)
- FR-02: System shall capture allergies (food, medication, environmental) and chronic conditions (asthma, diabetes, etc.)
- FR-03: System shall capture ongoing medications and dietary restrictions
- FR-04: System shall capture vision test results (left and right eye)
- FR-05: System shall capture emergency doctor contact information (name and phone)
- FR-06: System shall capture height, weight, and measurement date (latest snapshot)
- FR-07: Each student shall have exactly one health profile

### 5.2 Vaccination Records
**As a** School Nurse / School Admin,
**I want to** record each student's vaccination history
**So that** the school can track immunization compliance and send reminders for upcoming doses.

**Requirements:**
- FR-08: System shall capture vaccine name, date administered, and next due date
- FR-09: System shall allow adding multiple vaccination records per student
- FR-10: System shall allow adding optional remarks for each vaccination

### 5.3 Medical Incident Management
**As a** School Nurse / Teacher,
**I want to** log medical incidents that occur on school premises
**So that** there is a documented record of every health event for parental notification and trend analysis.

**Requirements:**
- FR-11: System shall capture the incident date and time, location (playground, classroom, etc.), and description
- FR-12: System shall categorize the incident type (Injury, Sickness, Fainting, etc.)
- FR-13: System shall record what first aid was given and what action was taken (sent home, rested in sick bay, taken to hospital)
- FR-14: System shall record who reported the incident (teacher/staff member)
- FR-15: System shall track whether the parent was notified
- FR-16: System shall support cases that need follow-up after the initial incident
- FR-17: System shall allow marking an incident as closed with a closure date
- FR-18: System shall support searching for students when logging an incident
- FR-19: System shall allow toggling parent notification and follow-up status via a single click

### 5.4 Daily Attendance — Manual Marking
**As a** Class Teacher,
**I want to** mark attendance for my class each day
**So that** the school has an accurate record of student presence.

**Requirements:**
- FR-20: System shall allow marking individual student attendance (Present, Absent, Late, Half Day, Short Leave, Leave)
- FR-21: System shall allow marking bulk attendance for all students in a class-section at once
- FR-22: System shall capture who marked the attendance and when
- FR-23: System shall allow adding optional remarks per student

### 5.5 Daily Attendance — Period-Wise Marking
**As a** School Admin,
**I want to** enable period-wise attendance tracking
**So that** the school can track attendance per subject period rather than just full-day.

**Requirements:**
- FR-24: System shall support a configurable setting to enable/disable period-wise attendance
- FR-25: When enabled, teachers can mark attendance per period per student
- FR-26: Each period's attendance for a student on a given date is a unique record

### 5.6 Attendance Scan (RFID/QR)
**As a** Class Teacher / School Admin,
**I want to** mark attendance by scanning student ID cards
**So that** attendance marking is faster and more accurate.

**Requirements:**
- FR-27: System shall allow marking attendance by scanning the student's QR code, RFID, or NFC tag
- FR-28: System shall support manual fallback when scanning fails

### 5.7 Attendance Correction Requests
**As a** Parent / Student,
**I want to** request a correction to an attendance record
**So that** I can fix errors (e.g., marked absent when the student was present).

**Requirements:**
- FR-29: System shall allow parents/students to submit correction requests for specific attendance records
- FR-30: FR-29: System shall capture the requested new status and the reason for correction
- FR-31: System shall track the request status (Pending, Approved, Rejected)
- FR-32: Admin/Teacher shall provide remarks when approving or rejecting
- FR-33: On approval, the original attendance record shall be updated
- FR-34: The correction request shall remain in the system as an audit trail

---

## 6. Business Rules

| Rule ID | Rule Description |
|---|---|
| BR-01 | Each student has exactly one health profile (created on first save, updated thereafter) |
| BR-02 | Blood groups are limited to standard types: A+, A-, B+, B-, AB+, AB-, O+, O- |
| BR-03 | Medical incidents are logged with a required date, time, and description |
| BR-04 | The attendance status for a student on a specific date and period can be: Present, Absent, Late, Half Day, Short Leave, or Leave |
| BR-05 | A unique attendance record exists per (student, date, period) combination |
| BR-06 | Attendance marked by a teacher cannot be edited by another teacher (audit trail) |
| BR-07 | Correction requests go through an approval workflow — they do not directly modify the record |
| BR-08 | Only the marked_by user or admin can modify an attendance record directly |
| BR-09 | Period-wise attendance is controlled by a system-wide setting — when disabled, period is always 0 (full day) |

---

## 7. Workflow: Medical Incident Logging

```
Trigger: A student is injured or falls sick on school premises
        ↓
Step 1: Teacher or Nurse logs into the system
        ↓
Step 2: Teacher/Nurse searches for the student by name or admission number
        ↓
Step 3: Teacher/Nurse enters incident details:
        - Date & time of incident
        - Location (Playground, Classroom, Corridor, etc.)
        - Incident type (Injury, Sickness, Fainting, etc.)
        - Description of what happened
        ↓
Step 4: Teacher/Nurse records action taken:
        - First aid given
        - Final action (Sent home, Rested in sick bay, Taken to hospital)
        ↓
Step 5: Teacher/Nurse marks parent notification status
        ↓
Step 6: System saves the incident record
        ↓
Step 7: If follow-up is required, Nurse schedules follow-up and tracks closure
```

---

## 8. Acceptance Criteria

| Criterion | Description |
|---|---|
| AC-01 | Nurse can log a medical incident in under 2 minutes |
| AC-02 | Health profile shows all allergies and conditions for a student on their profile page |
| AC-03 | Teacher can mark bulk attendance for a 40-student class in under 2 minutes |
| AC-04 | Attendance records are unique per student per day (unique constraint enforced) |
| AC-05 | A parent-submitted correction request appears in the admin queue immediately |
| AC-06 | On approval of a correction request, the attendance record updates correctly |
| AC-07 | Dashboard shows today's attendance percentage |
| AC-08 | Medical incidents with follow-up required are clearly flagged for nurse action |

---

## 9. Dependencies

| Dependency | Description |
|---|---|
| BRD-01 — Student Onboarding | Health and attendance records require existing student records |
| BRD-03 — Academic Journey | Attendance links to academic session and class-section |
| System Settings | Period-wise attendance setting must be configured |
| Notification Module | For parent notification alerts on medical incidents |

---

## 10. Assumptions

- Attendance is marked by class teachers, not automated (except scan-based marking)
- Period-wise attendance is a school-level configuration, not per-class
- Medical incidents are logged by school staff, not by students
- Parents are notified separately (system tracks whether notification happened, does not auto-send alerts)
- Correction requests come from Parent Portal or Student Portal

---

*End of BRD-04*
