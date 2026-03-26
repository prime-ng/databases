# StudentProfile Module — Requirement Specification Document

**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Automated Extraction)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** STD | **Module Path:** `Modules/StudentProfile`
**Module Type:** Tenant Module | **Database:** `tenant_{uuid}`
**Table Prefix:** `std_*` (shared with StudentPortal) | **Completion:** ~50%
**RBS Reference:** Module C — Admissions & Student Lifecycle (lines 2013–2133) + Module E — Student Information System (lines 2203–2282)

---

> **CRITICAL SECURITY NOTICE:** A **P0 security vulnerability** exists in `StudentController::createStudentLogin()`. The field `is_super_admin` is in the validation schema and directly assigned to `User::create([..., 'is_super_admin' => $request->boolean('is_super_admin'), ...])`. This means any user who can access the student creation form (including students themselves if they can access that route) could escalate a new student login to super-admin. This must be removed from the fillable payload immediately.

---

## Table of Contents

1. [Module Overview](#1-module-overview)
2. [Scope and Boundaries](#2-scope-and-boundaries)
3. [Actors and User Roles](#3-actors-and-user-roles)
4. [Functional Requirements](#4-functional-requirements)
5. [Data Model](#5-data-model)
6. [Controller & Route Inventory](#6-controller--route-inventory)
7. [Form Request Validation Rules](#7-form-request-validation-rules)
8. [Business Rules](#8-business-rules)
9. [Permission & Authorization Model](#9-permission--authorization-model)
10. [Tests Inventory](#10-tests-inventory)
11. [Known Issues & Technical Debt](#11-known-issues--technical-debt)
12. [API Endpoints](#12-api-endpoints)
13. [Non-Functional Requirements](#13-non-functional-requirements)
14. [Integration Points](#14-integration-points)
15. [Pending Work & Gap Analysis](#15-pending-work--gap-analysis)

---

## 1. Module Overview

### 1.1 Purpose

StudentProfile is the **core student data management module** for Prime-AI tenant schools. It is responsible for the complete student information lifecycle: from creating a student's system login, capturing personal and demographic details, linking guardians, assigning academic sessions, tracking health records and medical incidents, managing documents, recording attendance, and generating student-related reports.

StudentProfile is a foundational module — nearly every other tenant module (StudentFee, StudentPortal, SmartTimetable, LmsHomework, Transport, etc.) depends on its data.

### 1.2 Module Position in the Platform

```
Platform Layer      Module               Database
──────────────────────────────────────────────────────
Tenant Foundation   StudentProfile (STD) tenant_{uuid}
Depends on STD      StudentFee (FIN)     tenant_{uuid}
Depends on STD      StudentPortal (STP)  tenant_{uuid}
Depends on STD      SmartTimetable (TT)  tenant_{uuid}
Depends on STD      Transport (TPT)      tenant_{uuid}
Depends on STD      LmsHomework          tenant_{uuid}
Depends on STD      Notification         tenant_{uuid}
```

### 1.3 Module Characteristics

| Attribute            | Value                                                            |
|----------------------|------------------------------------------------------------------|
| Laravel Module       | `nwidart/laravel-modules` v12, name `StudentProfile`             |
| Namespace            | `Modules\StudentProfile`                                         |
| Module Code          | STD                                                              |
| Domain               | Tenant (school-specific subdomain)                               |
| DB Connection        | `tenant` (tenant_{uuid})                                         |
| Table Prefix         | `std_*`                                                          |
| Auth                 | Spatie Permission v6.21 via `Gate::authorize()`                  |
| Controllers          | 5 (StudentController, StudentProfileController, AttendanceController, MedicalIncidentController, StudentReportController) |
| Models               | 14                                                               |
| Services             | 0 (business logic inline — P1 gap)                               |
| FormRequests         | 0 (all validation inline — P1 gap)                               |
| Tests                | 6 (5 Browser/Dusk tests + 1 Unit)                                |
| Photo Storage        | Spatie MediaLibrary (`student_photo` collection, disk: `public`) |
| PDF Generation       | DomPDF (student export PDF)                                      |
| Excel Export         | Maatwebsite Excel (student list export)                          |
| QR Code              | SimpleSoftwareIO/QrCode (student ID card QR)                     |
| Policy               | `StudentPolicy` (exists but method coverage uncertain)           |

---

## 2. Scope and Boundaries

### 2.1 In Scope

- Student login creation and management (user account creation with Student role assignment)
- Student basic details (name, DOB, gender, admission number, Aadhar, APAAR)
- Extended profile (religion, caste category, nationality, mother tongue, bank details, RTE flag)
- Student addresses (permanent, correspondence, guardian, local — multiple)
- Guardian/parent management (create, link to student with relationship type and permissions)
- Academic session management (class/section allocation, roll number, house, session status)
- Previous education history
- Student document management (upload, verify, manage TC/marksheets/ID proofs)
- Health profile (blood group, allergies, chronic conditions, vaccination records)
- Medical incident management (school incident recording and follow-up)
- Daily attendance recording and correction requests
- Student reports (admission register, strength report, medical profile report)
- Student profile completion tracking (5-tab progress indicator)
- Student export (Excel and PDF)
- Credential sending (email student login credentials)

### 2.2 Out of Scope

- Student fee management (StudentFee module)
- Student portal self-service (StudentPortal module)
- Period/subject-level attendance (handled in Timetable/LMS modules)
- Behavioral assessment and incidents (separate Behavioral Assessment module)
- Alumni management post-leaving (Student promotion to alumni — partial)
- Student ID card printing (design exists, printing not automated)
- Enquiry/Lead management (separate Admission Enquiry module — pending)
- Admission application form (separate Admission module — pending)

### 2.3 Module Dependencies

| Dependency              | Direction  | Purpose                                                      |
|-------------------------|------------|--------------------------------------------------------------|
| SystemConfig (SYS)      | Incoming   | RBAC gates, `sys_dropdowns` for religion/caste/nationality   |
| SchoolSetup (SCH)       | Incoming   | `ClassSection`, `AcademicSession`, `SubjectGroup`, `Organization` |
| GlobalMaster (GLB)      | Incoming   | `City`, `Dropdown` models for address and nationality        |
| Notification module     | Outgoing   | Student notifications on profile events                      |
| StudentFee (FIN)        | Outgoing   | Provides `Student` model consumed by fee assignment          |
| Transport (TPT)         | Outgoing   | `StudentPayLog` referenced in Student model                  |
| MediaLibrary (Spatie)   | Internal   | Photo upload and thumbnail generation                        |

---

## 3. Actors and User Roles

| Role                  | Access Level                                                                    |
|-----------------------|---------------------------------------------------------------------------------|
| Super Admin           | Full access across all students in all tenants                                  |
| School Admin          | Full CRUD access to all students in tenant                                      |
| Class Teacher         | View students in own class; limited edit (attendance); no login management      |
| Registrar / Clerk     | Create and edit student profiles, document uploads, session assignment          |
| Medical Staff         | Record and view medical incidents and health profiles                           |
| Student               | Read-only view of own profile via StudentPortal; no access to backend           |
| Parent / Guardian     | Read-only view of own child's data via StudentPortal                            |

---

## 4. Functional Requirements

### 4.1 Student List & Search (C4, E1)

**REF: ST.E1.1.2.1, ST.E1.1.2.2**

- `ST.STD.4.1.1` — List all students in tenant with pagination (12 per page, newest first)
- `ST.STD.4.1.2` — Search by: admission number, first/last/middle name, user code (`emp_code`), email, mobile number
- `ST.STD.4.1.3` — Filter by: active/inactive status, profile completion status (complete = has guardians; incomplete = no guardians)
- `ST.STD.4.1.4` — Student card displays: photo, name, admission number, class/section, current session status
- `ST.STD.4.1.5` — Export student list to Excel (`student/export/excel`) and PDF (`student/export/pdf`)
- `ST.STD.4.1.6` — Send credentials email to selected students (`students/send-credentials`)

### 4.2 Student Login Creation (C4, E1 — Tab 1: Registration)

**REF: ST.C3.2.1.2, ST.E1.1.1.3**

- `ST.STD.4.2.1` — Admin creates student system user account: name, short_name, email, password (hashed), user_type = STUDENT
- `ST.STD.4.2.2` — System auto-generates `emp_code` in format `STD-{YYYY}-{000001}` (sequential 6-digit)
- `ST.STD.4.2.3` — System assigns "Student" role via Spatie (`syncRoles`)
- `ST.STD.4.2.4` — Welcome email sent to student with credentials (`StudentLoginCreated` Mailable)
- `ST.STD.4.2.5` — Optional: 2FA toggle, is_active, profile photo upload at creation
- **P0 SECURITY VIOLATION: `is_super_admin` field is validated and assigned in `createStudentLogin()`. Must be removed immediately.**
- `ST.STD.4.2.6` — After login creation, admin is redirected to student edit form at "student_details" tab

### 4.3 Student Details (C4, E1 — Tab 2: Student Detail)

**REF: ST.E1.1.1.1, ST.E1.1.1.2, ST.C4.1.1.1, ST.C4.1.1.2**

- `ST.STD.4.3.1` — Capture basic student info: first name, middle name, last name, DOB, gender, admission number, admission date
- `ST.STD.4.3.2` — Capture identity documents: Aadhar ID, APAAR ID, birth certificate number
- `ST.STD.4.3.3` — Capture ID card preferences: card type (QR/RFID/NFC/Barcode), smart card ID, QR code value
- `ST.STD.4.3.4` — Extended profile: religion, caste category, nationality, mother tongue (all from sys_dropdowns)
- `ST.STD.4.3.5` — Financial details: bank account, IFSC, bank name, branch, UPI ID, fee depositor PAN
- `ST.STD.4.3.6` — RTE/EWS flags: `right_to_education`, `is_ews`
- `ST.STD.4.3.7` — Physical stats snapshot: height_cm, weight_kg, measurement_date
- `ST.STD.4.3.8` — Address management: add permanent + correspondence addresses; city lookup; multiple addresses per student
- `ST.STD.4.3.9` — Update student profile via `PUT /student/{student}/update-profile`
- `ST.STD.4.3.10` — Update student address via `PUT /student/{student}/update-address`; delete address via `DELETE /student/address/{addressId}`

### 4.4 Guardian / Parent Management (C4, E1 — Tab 3: Parents)

**REF: ST.E1.2.2.1, ST.E1.2.2.2, ST.C4.1.1.2**

- `ST.STD.4.4.1` — Add new guardian: first name, last name, gender, mobile (unique), email, occupation, qualification, annual income, preferred language
- `ST.STD.4.4.2` — Link guardian to student via junction: relation type (Father/Mother/Guardian), relationship description (Uncle/Sister/etc.)
- `ST.STD.4.4.3` — Set junction flags: is_emergency_contact, can_pickup, is_fee_payer, can_access_parent_portal, can_receive_notifications, notification_preference
- `ST.STD.4.4.4` — Create parent system login (`createParentLogin` route): sets up sys_user with Parent role for portal access
- `ST.STD.4.4.5` — Delete guardian link via `DELETE /student/{student}/parent/{parent}/delete`
- `ST.STD.4.4.6` — Guardian can be linked to multiple students (sibling scenario — same guardian linked via multiple junction records)
- `ST.STD.4.4.7` — One student may have multiple guardians (Father + Mother + Guardian types)

### 4.5 Academic Session Assignment (C3, E2 — Tab 4: Session)

**REF: ST.C3.2.1.1, ST.E2.1.1.1, ST.E2.1.1.2, ST.E2.1.2.1**

- `ST.STD.4.5.1` — Assign student to academic session: select academic_session, class_section (class + section), roll number (auto or manual), subject group, house (dropdown)
- `ST.STD.4.5.2` — Only ONE session can be current at a time (UNIQUE generated column `current_flag = student_id WHERE is_current = 1`)
- `ST.STD.4.5.3` — Session status (dropdown): ACTIVE, PROMOTED, LEFT, SUSPENDED, ALUMNI, WITHDRAWN
- `ST.STD.4.5.4` — On session change: set `is_current = 0` on previous; `is_current = 1` on new
- `ST.STD.4.5.5` — Record leaving date, reason quit (from dropdown) when status = LEFT/WITHDRAWN
- `ST.STD.4.5.6` — `count_for_timetable` flag: marks whether this student-session should be counted in timetable generation
- `ST.STD.4.5.7` — `count_as_attrition` flag: marks leaving as attrition for HR analytics
- `ST.STD.4.5.8` — Create session via `POST /student/create-student-session`; update via PUT

### 4.6 Previous Education History (C4 — Tab 5: Previous Education)

**REF: ST.C3.2.2.1, ST.C4.2.1.1**

- `ST.STD.4.6.1` — Record previous school: name, address, board (CBSE/ICSE/State), class passed, year, percentage/grade, medium of instruction
- `ST.STD.4.6.2` — Record TC details: TC number, TC date, recognized flag
- `ST.STD.4.6.3` — Multiple previous education records per student (one-to-many)
- `ST.STD.4.6.4` — Create via `POST /student/create-student-prev-edu-details`

### 4.7 Student Documents (C4 — Document Upload)

**REF: ST.C4.2.1.1, ST.C4.2.1.2, ST.C4.2.2.1, ST.C4.2.2.2**

- `ST.STD.4.7.1` — Upload documents: document name, type (from dropdown: TC/Marksheet/Aadhar/Medical), document number, issue date, expiry date, issuing authority
- `ST.STD.4.7.2` — Document verification workflow: `is_verified` flag, `verified_by` (sys_user), `verification_date`
- `ST.STD.4.7.3` — Document file stored via `sys_media` (optional `media_id`) or direct `file_name`
- `ST.STD.4.7.4` — Edit document metadata via `PUT /student-document/{document}/update`
- `ST.STD.4.7.5` — Delete document via `DELETE /student-document/{document}/delete`
- `ST.STD.4.7.6` — Get document data for edit form via `GET /student-document/{document}/edit`

### 4.8 Health Profile (E4 — Tab: Health)

**REF: ST.E4.1.1.1, ST.E4.1.1.2, ST.E4.1.2.1, ST.E4.1.2.2**

- `ST.STD.4.8.1` — Create/update health profile: blood group, allergies (text), chronic conditions (text), emergency medication, physical disability notes, special needs
- `ST.STD.4.8.2` — Record vaccination history: vaccine name, vaccine code, date given, next due date, administered by, batch number, certificate upload
- `ST.STD.4.8.3` — One health profile per student (one-to-one); multiple vaccination records (one-to-many)
- `ST.STD.4.8.4` — Update via `PUT /student/{student}/health-profile/update`
- `ST.STD.4.8.5` — Create via `POST /student/create-student-medical-details`

### 4.9 Medical Incidents (E4 — Medical Incidents)

**REF: ST.E4.2.1.1, ST.E4.2.1.2, ST.E4.2.2.1, ST.E4.2.2.2**

- `ST.STD.4.9.1` — Record school medical incident: incident type (from dropdown), incident date, description, initial action taken, nurse/doctor attending
- `ST.STD.4.9.2` — Upload doctor's prescription / medical documents (via media)
- `ST.STD.4.9.3` — Follow-up tracking: schedule follow-up date, record recovery progress, close incident
- `ST.STD.4.9.4` — Full CRUD: create, edit, view, delete, soft-delete, restore
- `ST.STD.4.9.5` — Managed by `MedicalIncidentController` (separate from StudentController)

### 4.10 Daily Attendance (E3, F1 — Attendance)

**REF: ST.E3.1.1.1, ST.E3.1.1.2, ST.E3.1.2.1, ST.E3.1.2.2, ST.F1.1.1.1**

- `ST.STD.4.10.1` — Mark daily attendance for a student: Present / Absent / Late / Half-Day
- `ST.STD.4.10.2` — Record absence reason
- `ST.STD.4.10.3` — Attendance correction request: student/parent submits correction with supporting document
- `ST.STD.4.10.4` — Correction approval: teacher reviews; admin final approval with audit log
- `ST.STD.4.10.5` — Full CRUD + soft delete on `std_student_attendance` and `std_attendance_corrections`
- `ST.STD.4.10.6` — **CRITICAL GAP: AttendanceController has zero `Gate::authorize()` calls**

### 4.11 Student Reports (C4, E1 — Reports)

**REF: ST.E3.2.1.1, ST.E3.2.1.2, ST.C4**

- `ST.STD.4.11.1` — Admission Register report: list of all admitted students with admission numbers, dates, class
- `ST.STD.4.11.2` — Student Strength report: class-wise student count (boys/girls/total)
- `ST.STD.4.11.3` — Medical Profile report: health summary across students (blood groups, chronic conditions)
- `ST.STD.4.11.4` — Reports hub at `student-profile/reports`; managed by `StudentReportController`

### 4.12 Student Status Management

**REF: ST.C5.2.1.1, ST.C5.2.2.1**

- `ST.STD.4.12.1` — Toggle student active/inactive status via `POST /student/{student}/toggle-status`
- `ST.STD.4.12.2` — Soft delete student via standard `DELETE /student/{id}` (soft delete via `deleted_at`)
- `ST.STD.4.12.3` — Restore soft-deleted student via `PATCH /student/{id}/restore`
- `ST.STD.4.12.4` — Force delete via `DELETE /student/{id}/force-delete`
- `ST.STD.4.12.5` — Bulk restore and bulk force-delete endpoints
- `ST.STD.4.12.6` — Trash view for soft-deleted students
- `ST.STD.4.12.7` — Get trashed student detail via API endpoint `GET /api/student/{id}/trash-details`

### 4.13 Profile Completion Tracking

- `ST.STD.4.13.1` — 5-tab completion model: Login Details, Student Details, Parent Details, Session Details, Previous Education
- `ST.STD.4.13.2` — Completion percentage computed by `StudentProfileHelper::getProgressPercentage()`
- `ST.STD.4.13.3` — First incomplete tab calculated by `StudentProfileHelper::getFirstIncompleteTab()`
- `ST.STD.4.13.4` — On edit form load, system automatically shows first incomplete tab
- `ST.STD.4.13.5` — `Student::getProfileCompletionAttribute()` returns array: `{completed, total, percentage, next_tab}`

---

## 5. Data Model

### 5.1 Core Tables

| Table Name                       | Purpose                                                   | Key Columns                                     |
|----------------------------------|-----------------------------------------------------------|-------------------------------------------------|
| `std_students`                   | Core student entity, linked to `sys_users`                | `user_id`, `admission_no`, `first_name`, `dob`, `current_status_id` |
| `std_student_profiles`           | Extended demographic profile                              | `student_id`, `religion`, `caste_category`, `bank_account_no`, `right_to_education` |
| `std_student_addresses`          | Addresses (1:N per student)                               | `student_id`, `address_type`, `city_id`, `pincode`, `is_primary` |
| `std_guardians`                  | Parent/guardian master record                             | `user_id`, `mobile_no` (UNIQUE), `first_name`, `last_name` |
| `std_student_guardian_jnt`       | Student-guardian relationships (M:N)                      | `student_id`, `guardian_id`, `relation_type`, `is_fee_payer`, `can_access_parent_portal` |
| `std_student_academic_sessions`  | Class/section allocation per academic year                | `student_id`, `academic_session_id`, `class_section_id`, `is_current`, `session_status_id` |
| `std_previous_education`         | Previous schools attended                                 | `student_id`, `school_name`, `board`, `tc_number` |
| `std_student_documents`          | Uploaded documents per student                            | `student_id`, `document_type_id`, `is_verified`, `verified_by` |
| `std_health_profiles`            | Medical profile (1:1)                                     | `student_id`, `blood_group`, `allergies`, `chronic_conditions` |
| `std_medical_incidents`          | School medical incidents (1:N)                            | `student_id`, `incident_type`, `incident_date`, `action_taken` |
| `std_vaccination_records`        | Vaccination history (1:N)                                 | `student_id`, `vaccine_name`, `date_given`, `next_due_date` |
| `std_student_attendance`         | Daily attendance records                                  | `student_id`, `date`, `status` (Present/Absent/Late/Half-Day) |
| `std_attendance_corrections`     | Attendance correction requests                            | `attendance_id`, `requested_by`, `approval_status` |
| `std_student_detail` (StudentDetail model) | Additional student details               | `student_id`, extended demographic fields       |

### 5.2 Key Relationships

```
sys_users (1)─────────────────── std_students (1)
                                       │
                        ┌──────────────┼──────────────────┐
                        │              │                  │
              std_student_profiles  std_guardians     std_student_addresses
                                  (via junction)
                                        │
                             std_student_guardian_jnt
                                        │
                                    sys_users (parent login)

std_students (1)──── std_student_academic_sessions (N)
                         └── sch_class_section_jnt → class + section

std_students (1)──── std_previous_education (N)
std_students (1)──── std_student_documents (N)
std_students (1)──── std_health_profiles (1)
std_students (1)──── std_vaccination_records (N)
std_students (1)──── std_medical_incidents (N)
std_students (1)──── std_student_attendance (N)
```

### 5.3 Generated Column — Current Session Guard

The `std_student_academic_sessions` table uses a MySQL generated column to enforce single-current-session:
```sql
current_flag INT GENERATED ALWAYS AS (
  CASE WHEN is_current = 1 THEN student_id ELSE NULL END
) STORED
UNIQUE KEY uq_studentSessions_currentFlag (current_flag)
```
This means `SET is_current = 0` on the previous session must happen before `SET is_current = 1` on the new session in the same transaction.

### 5.4 Spatie MediaLibrary Collections (Student)

| Collection Name  | Single File | Disk   | Accepted MIME          | Conversions          |
|------------------|:-----------:|--------|------------------------|----------------------|
| `student_photo`  | Yes         | public | jpg, png, gif          | thumb (100×100), medium (300×300), large (600×600) |

### 5.5 Student Model $fillable (Current State)

Current `$fillable` in `Student` model:
```php
['user_id', 'admission_no', 'admission_date', 'student_qr_code',
 'student_id_card_type', 'smart_card_id', 'aadhar_id', 'apaar_id',
 'birth_cert_no', 'first_name', 'middle_name', 'last_name', 'gender',
 'dob', 'photo_file_name', 'media_id', 'current_status_id', 'is_active', 'note']
```
Note: `is_super_admin` is NOT in `Student.$fillable` — the vulnerability is in `User::create()` inside `createStudentLogin()` where `is_super_admin` is passed directly from the validated request.

---

## 6. Controller & Route Inventory

### 6.1 Controllers

| Controller                  | Responsibility                                              | Primary Model       |
|-----------------------------|-------------------------------------------------------------|---------------------|
| `StudentController`         | Full student lifecycle: login creation, CRUD, export, credentials | Student, User |
| `StudentProfileController`  | Student settings/profile-specific operations                | StudentProfile      |
| `AttendanceController`      | Daily attendance CRUD and correction workflow               | StudentAttendance   |
| `MedicalIncidentController` | Medical incident CRUD with soft delete                      | MedicalIncident     |
| `StudentReportController`   | Admission register, strength, medical reports               | Student (aggregated)|

### 6.2 Route Inventory (Selected Key Routes)

All routes under prefix `student-profile/`, middleware `auth + verified`:

| Method | Route                                           | Controller Method             | Gate Check              |
|--------|-------------------------------------------------|-------------------------------|-------------------------|
| GET    | `/student/create1`                              | `create`                      | `tenant.student.create` |
| GET    | `/student/{student}/edit-student-details`       | `editStudentDetails`          | `tenant.student.update` |
| GET    | `/student/{student}`                            | `show`                        | `tenant.student.view`   |
| POST   | `/student/create-student-login`                 | `createStudentLogin`          | (no gate — P1 gap)      |
| POST   | `/student/create-student-details`               | `createStudentDetails`        | (no gate — P1 gap)      |
| POST   | `/student/create-student-session`               | `createStudentSession`        | (no gate — P1 gap)      |
| POST   | `/student/create-parent-details`                | `createParentDetails`         | (no gate — P1 gap)      |
| PUT    | `/student/{user}/update-login`                  | `updateLogin`                 | `tenant.student.update` |
| PUT    | `/student/{student}/update-student-details`     | `updateStudentDetails`        | (gate in method)        |
| PUT    | `/student/{student}/update-profile`             | `updateProfile`               | (gate in method)        |
| PUT    | `/student/{student}/update-address`             | `updateStudentAddress`        | (gate in method)        |
| DELETE | `/student/address/{addressId}`                  | `deleteStudentAddress`        | (gate in method)        |
| DELETE | `/student/{student}/parent/{parent}/delete`     | `deleteParent`                | (gate in method)        |
| PUT    | `/student/{student}/health-profile/update`      | `updateHealthProfile`         | (gate in method)        |
| PUT    | `/student-document/{document}/update`           | `updateStudentDocument`       | (gate in method)        |
| DELETE | `/student-document/{document}/delete`           | `deleteStudentDocument`       | (gate in method)        |
| POST   | `/student/{student}/toggle-status`              | `toggleStatus`                | `tenant.student.update` |
| POST   | `/students/send-credentials`                    | `sendCredentials`             | `tenant.student.update` |
| GET    | `/student/export/{type}`                        | `export`                      | `tenant.student.export` |
| GET    | `/student/trash/view`                           | `trashed`                     | `tenant.student.delete` |
| PATCH  | `/student/{id}/restore`                         | `restore`                     | `tenant.student.delete` |
| DELETE | `/student/{id}/force-delete`                    | `forceDelete`                 | `tenant.student.delete` |
| POST   | `/student/bulk-restore`                         | `bulkRestore`                 | `tenant.student.delete` |
| DELETE | `/student/bulk-force-delete`                    | `bulkForceDelete`             | `tenant.student.delete` |
| GET    | `/api/student/{id}/trash-details`               | `getTrashedStudentDetails`    | Admin API               |

### 6.3 Student Allocation Routes (Separate StudentAllocation)

| Method | Route                                            | Purpose                      |
|--------|--------------------------------------------------|------------------------------|
| GET    | `/student-allocation`                            | Bulk class allocation listing|
| POST   | `/student-allocation/validate/file`              | CSV upload validation        |
| POST   | `/student-allocation/start/import`               | Start CSV import             |
| GET    | `/student-allocation/allocation/export`          | Export allocation data       |

---

## 7. Form Request Validation Rules

**CRITICAL GAP: 0 FormRequest classes exist. All validation is inline in controllers.**

### 7.1 CreateStudentLoginRequest (to be created — highest priority)

```
name:                    required|string|max:255
short_name:              required|string|max:255|unique:sys_users,short_name
email:                   required|email|max:255|unique:sys_users,email
phone_no:                nullable|string|max:32
mobile_no:               nullable|string|max:32
password:                required|string|min:8|confirmed
status:                  required|in:ACTIVE,INVITED,DISABLED
is_active:               nullable|boolean
two_factor_auth_enabled: nullable|boolean
user_img:                nullable|image|mimes:jpg,jpeg,png,webp|max:2048
-- NOTE: is_super_admin MUST NOT appear in this request class --
```

### 7.2 CreateStudentDetailsRequest (to be created)

```
first_name:         required|string|max:50
middle_name:        nullable|string|max:50
last_name:          nullable|string|max:50
gender:             required|in:Male,Female,Transgender,Prefer Not to Say
dob:                required|date|before:today
admission_no:       required|string|max:50|unique:std_students,admission_no
admission_date:     required|date
aadhar_id:          nullable|string|max:20|unique:std_students,aadhar_id
apaar_id:           nullable|string|max:100
current_status_id:  required|exists:sys_dropdowns,id
```

### 7.3 CreateGuardianRequest (to be created)

```
first_name:      required|string|max:50
last_name:       nullable|string|max:50
gender:          required|in:Male,Female,Transgender,Prefer Not to Say
mobile_no:       required|string|max:20|unique:std_guardians,mobile_no
email:           nullable|email|max:100
relation_type:   required|in:Father,Mother,Guardian
relationship:    required|string|max:50
is_fee_payer:    nullable|boolean
can_access_parent_portal: nullable|boolean
```

### 7.4 CreateSessionRequest (to be created)

```
academic_session_id: required|exists:sch_org_academic_sessions_jnt,id
class_section_id:    required|exists:sch_class_section_jnt,id
roll_no:             nullable|integer|min:1
subject_group_id:    nullable|exists:sch_subject_groups,id
house:               nullable|exists:sys_dropdowns,id
session_status_id:   required|exists:sys_dropdowns,id
```

### 7.5 StoreAttendanceRequest (to be created)

```
student_id:    required|exists:std_students,id
date:          required|date|before_or_equal:today
status:        required|in:Present,Absent,Late,Half-Day
reason:        nullable|string|max:255
```

---

## 8. Business Rules

### 8.1 Student Identity Rules

- `BR.STD.8.1.1` — Admission number (`admission_no`) must be unique per tenant; cannot be changed after assignment
- `BR.STD.8.1.2` — Aadhar ID must be unique if provided (UNIQUE constraint in DDL)
- `BR.STD.8.1.3` — Student user (`sys_users`) email must be globally unique (same table used for all user types)
- `BR.STD.8.1.4` — `emp_code` auto-format: `STD-{YYYY}-{000001}` — year-based sequential; cannot be manually set during student creation (only updated via `updateLogin`)

### 8.2 Session Management Rules

- `BR.STD.8.2.1` — Only ONE academic session can have `is_current = 1` per student at any time (enforced by generated column UNIQUE constraint)
- `BR.STD.8.2.2` — Setting a new current session must first set `is_current = 0` on all other sessions for that student within a DB transaction
- `BR.STD.8.2.3` — A student cannot be assigned to the same academic session twice (UNIQUE on `student_id + academic_session_id`)
- `BR.STD.8.2.4` — Leaving date must be set when session_status = LEFT or WITHDRAWN
- `BR.STD.8.2.5` — `count_for_timetable = 0` when student is suspended or withdrawn (prevents ghost slots in timetable)

### 8.3 Guardian Rules

- `BR.STD.8.3.1` — Mobile number is the unique identifier for a guardian; two guardians cannot share the same mobile number
- `BR.STD.8.3.2` — A student must have at least one guardian with `relation_type = Father` or `Mother` or `Guardian` for profile to be "complete"
- `BR.STD.8.3.3` — Guardian's `user_id` is NULL until parent portal access is granted; granting portal access creates a `sys_users` record and links it
- `BR.STD.8.3.4` — `is_fee_payer` guardian is referenced in StudentFee sibling discount calculation; at most one guardian should be `is_fee_payer = 1` per student
- `BR.STD.8.3.5` — Notifications are sent to guardians with `can_receive_notifications = 1`

### 8.4 Attendance Rules

- `BR.STD.8.4.1` — Attendance can only be marked for the current academic session's date range
- `BR.STD.8.4.2` — Once marked and approved, attendance correction requires a formal correction request via `std_attendance_corrections`
- `BR.STD.8.4.3` — Attendance correction: student/parent submits with document; class teacher approves; admin final-approves with audit log
- `BR.STD.8.4.4` — System should flag attendance < 75% for notification triggers (not yet implemented)

### 8.5 Health Profile Rules

- `BR.STD.8.5.1` — One health profile per student; `upsert` pattern (create if not exists, update if exists)
- `BR.STD.8.5.2` — Allergy information is mandatory to display on attendance marking UI (teacher awareness)
- `BR.STD.8.5.3` — Medical incidents are school-level records; parent/guardian notification must be sent on incident creation
- `BR.STD.8.5.4` — Vaccination records are informational; no workflow approval needed

### 8.6 Document Rules

- `BR.STD.8.6.1` — TC (Transfer Certificate) number must be unique if provided (no DDL constraint — must be enforced at application level)
- `BR.STD.8.6.2` — Verification can only be done by authorized roles (Admin, Registrar)
- `BR.STD.8.6.3` — Expired documents (past `expiry_date`) should be flagged in the document listing view

### 8.7 Profile Completion Rules

- `BR.STD.8.7.1` — "Complete" profile requires: user_id + admission_no + mobile (in profile) + at least one guardian + at least one academic session + at least one previous education record
- `BR.STD.8.7.2` — List filter "incomplete" checks only `doesntHave('guardians')` currently — this is a simplified check; full 5-tab completion is tracked in the edit view
- `BR.STD.8.7.3` — Profile completion percentage is computed on-the-fly (not stored); not suitable for high-volume batch queries

---

## 9. Permission & Authorization Model

### 9.1 Gate Checks Currently Implemented

| Method                    | Gate Check                         | Status   |
|---------------------------|------------------------------------|----------|
| `index()`                 | `tenant.student.viewAny`           | Done     |
| `create()`                | `tenant.student.create`            | Done     |
| `show()`                  | `tenant.student.view`              | Done     |
| `edit()`                  | `tenant.student.update`            | Done     |
| `updateLogin()`           | `tenant.student.update`            | Done     |
| `createStudentLogin()`    | NONE                               | Gap — P1 |
| `createStudentDetails()`  | NONE                               | Gap — P1 |
| `createStudentSession()`  | NONE                               | Gap — P1 |
| `createParentDetails()`   | NONE                               | Gap — P1 |
| AttendanceController (all)| NONE                               | Gap — P1 |

### 9.2 StudentPolicy

A `StudentPolicy` class exists at `Modules/StudentProfile/app/Policies/StudentPolicy.php`. Policy registration in `StudentProfileServiceProvider` needs verification to ensure it is bound to the `Student` model and all relevant methods are defined.

### 9.3 Required Permissions (Spatie)

| Permission Key                          | Description                                  |
|-----------------------------------------|----------------------------------------------|
| `tenant.student.viewAny`               | List all students                            |
| `tenant.student.view`                  | View individual student profile              |
| `tenant.student.create`               | Create student (login + details)             |
| `tenant.student.update`               | Edit student records                         |
| `tenant.student.delete`               | Soft/force delete, restore                   |
| `tenant.student.export`               | Export Excel/PDF                             |
| `tenant.attendance.viewAny`            | View attendance records                      |
| `tenant.attendance.create`            | Mark attendance                              |
| `tenant.attendance.update`            | Edit attendance records                      |
| `tenant.medical-incident.viewAny`      | View medical incidents                       |
| `tenant.medical-incident.create`      | Create medical incident                      |
| `tenant.student-report.view`          | Access student reports                       |

---

## 10. Tests Inventory

### 10.1 Existing Tests (6 tests)

| Test File                          | Type          | Coverage                                          |
|------------------------------------|---------------|---------------------------------------------------|
| `StudentCreateTest.php`            | Browser/Dusk  | Student login creation workflow (tab 1)           |
| `StudentEditTest.php`              | Browser/Dusk  | Student profile edit form navigation              |
| `StudentCompleteProfileTest.php`   | Browser/Dusk  | Full 5-tab profile completion workflow            |
| `BulkAttendanceTest.php`           | Browser/Dusk  | Bulk attendance marking UI flow                   |
| `MedicalIncidentTest.php`          | Browser/Dusk  | Medical incident CRUD UI flow                     |
| `tests/Unit/StudentProfile/` (1)   | Unit          | Unit test for StudentProfile model                |

### 10.2 Critical Tests Missing

- Unit test: `is_super_admin` NOT assignable via student creation form (regression prevention)
- Feature test: `createStudentLogin` validates and rejects `is_super_admin = true` in payload
- Feature test: attendance authorization (non-authorized role cannot mark attendance)
- Feature test: guardian creation with duplicate mobile number returns validation error
- Feature test: session current_flag uniqueness enforcement (cannot set two sessions as current)
- Unit test: `StudentProfileHelper::getProgressPercentage()` and `getFirstIncompleteTab()`
- Feature test: student soft delete, restore, force delete flow

---

## 11. Known Issues & Technical Debt

### 11.1 P0 — Critical Security Issues

| Issue                                     | Severity | Detail                                                                                                                                                                                                                                                    |
|-------------------------------------------|----------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **`is_super_admin` writable via student login** | P0  | In `StudentController::createStudentLogin()`, the request is validated with `'is_super_admin' => 'nullable'` and then used directly: `User::create([..., 'is_super_admin' => $request->boolean('is_super_admin'), ...])`. Any admin who creates a student login (or any student who somehow reaches this form with crafted POST data) can create a super-admin account. **Fix: Remove `is_super_admin` from the validation rules and from the `User::create()` payload entirely. Students can never be super-admins.** |

### 11.2 P1 — High-Priority Issues

| Issue                                      | Severity | Detail                                                                                              |
|--------------------------------------------|----------|-----------------------------------------------------------------------------------------------------|
| **AttendanceController has zero Gate checks** | P1    | All attendance CRUD endpoints have no `Gate::authorize()` calls. Any authenticated user can create/edit attendance for any student. Must add authorization on all AttendanceController methods. |
| **`createStudentLogin()` has no Gate check** | P1     | The step that creates a `sys_users` record for a student has no authorization check. Should require `Gate::authorize('tenant.student.create')`. |
| **0 FormRequest classes**                  | P1       | All 5 controllers use inline `$request->validate()`. Must be extracted.                            |
| **0 Service classes**                      | P1       | `StudentController` is approximately 800+ lines. Session creation, guardian creation, and profile update logic should be extracted to `StudentService`. |
| **Commented-out update methods**           | P1       | Several key update methods (`updateStudentDetails`, `updateStudentSession`, `updateStudentLogin`, `updateParentLogin`) are commented out in routes; replaced by new routes but old URLs may be cached. |

### 11.3 P2 — Medium Priority

| Issue                               | Detail                                                                                                    |
|-------------------------------------|-----------------------------------------------------------------------------------------------------------|
| Only Browser/Dusk tests             | All 5 existing tests are browser automation tests (slow, fragile, require live browser). Need HTTP feature tests. |
| No student promotion workflow       | C5 (Promotion Processing): bulk class promotion for new academic year — not implemented                   |
| No TC (Transfer Certificate) generation | C5.2.2: TC PDF generation not implemented; student can only be marked as alumni/left                |
| Sibling linking not enforced        | No validation that siblings share the same fee-paying guardian when applying sibling discount             |
| Student allocation import           | CSV import exists but validation error display in UI needs verification                                   |
| `std_student_detail` vs `std_student_profiles` | Two models cover similar demographic data; boundary not clearly documented                    |

---

## 12. API Endpoints

### 12.1 Existing Internal API Endpoints

| Method | Route                                      | Purpose                          | Auth              |
|--------|--------------------------------------------|----------------------------------|-------------------|
| GET    | `/api/student/{id}/trash-details`          | Get soft-deleted student details | auth + verified   |
| GET    | `/fee-student-assignment/sections-by-class/{classId}` | AJAX section list     | auth + verified   |

### 12.2 Planned API Endpoints (Missing)

| Method | Endpoint                                  | Description                      |
|--------|-------------------------------------------|----------------------------------|
| GET    | `/api/v1/students`                        | Student list with filters        |
| GET    | `/api/v1/students/{id}`                   | Student full profile             |
| GET    | `/api/v1/students/{id}/attendance`        | Student attendance records       |
| GET    | `/api/v1/students/{id}/health`            | Student health summary           |
| POST   | `/api/v1/attendance/bulk-mark`            | Bulk attendance via app          |

---

## 13. Non-Functional Requirements

### 13.1 Performance

- Student list query must be paginated (currently 12 per page) — do not load all students for search
- Eager loading pattern for `show()`: all relationships loaded in one chain; avoid N+1 queries
- Photo thumbnail generation is deferred to Spatie MediaLibrary queued conversions
- Excel export for large schools (1000+ students) must be queued via `Laravel\Excel` chunk export

### 13.2 Security

- `is_super_admin` P0 fix must be first deployment priority
- Student file uploads (photos, documents) must validate MIME type server-side (not just extension)
- Aadhar ID storage must comply with UIDAI guidelines; consider encryption at rest for sensitive fields
- Student QR code value should not expose `admission_no` directly; use a hash/UUID

### 13.3 Data Integrity

- All student deletion (soft or force) must cascade correctly to related tables as defined in FK constraints
- Academic session `is_current` transitions must execute within DB transactions to prevent race conditions
- Guardian mobile number uniqueness must be enforced (DB UNIQUE + application validation)

### 13.4 Indian Compliance

- Aadhar ID field: 12-digit numeric validation when provided
- APAAR ID: Academic Bank of Credits — 12-digit format (validation pending)
- Caste category values must include SC, ST, OBC, General as minimum for government reporting
- Student admission register must conform to state education department format

---

## 14. Integration Points

| Module                    | Integration Method             | Data Flow                                                  |
|---------------------------|--------------------------------|------------------------------------------------------------|
| StudentFee (FIN)          | `Student`, `FeeStudentAssignment` models | Fee assignment, invoice generation uses student data |
| StudentPortal (STP)       | `auth()->user()->student` chain | Portal reads all std_* tables                              |
| SmartTimetable (TT)       | `StudentAcademicSession.count_for_timetable` | Timetable generation filters by this flag         |
| Transport (TPT)           | `StudentPayLog` relationship   | Transport fee payment logs per student                     |
| LmsHomework               | Student class/section assignment | Homework assigned by class_section_id                     |
| Notification module       | `Notification::send()` facade  | Profile events, low attendance alerts, fee reminders       |
| SystemConfig (SYS)        | `sys_dropdowns` table          | Religion, caste, nationality, student status lookups       |
| GlobalMaster (GLB)        | `City`, `Dropdown` models      | City lookup for addresses                                  |
| SchoolSetup (SCH)         | `ClassSection`, `AcademicSession`, `Organization` | Session and class data                   |

---

## 15. Pending Work & Gap Analysis

### 15.1 Completion Status by Feature Area

| Feature Area                     | Status   | Notes                                                         |
|----------------------------------|----------|---------------------------------------------------------------|
| Student Login Creation           | Done     | P0 fix needed: remove `is_super_admin` from payload           |
| Student Basic Details CRUD       | Done     | Create, edit, view, list all working                          |
| Student Address Management       | Done     | Add, update, delete working                                   |
| Guardian Management              | Done     | Create, link, delete guardian works                           |
| Parent Login Creation            | Done     | `createParentLogin` route exists                              |
| Academic Session Assignment      | Done     | Create session, current flag logic working                    |
| Previous Education               | Done     | CRUD complete                                                 |
| Document Upload & Verification   | Done     | Upload and basic CRUD; verification flag manageable           |
| Health Profile                   | Done     | Create and update working                                     |
| Vaccination Records              | Done     | CRUD via StudentController                                    |
| Medical Incidents                | Done     | Separate MedicalIncidentController, full CRUD                 |
| Daily Attendance                 | Done     | CRUD + soft delete; no authorization (P1 gap)                 |
| Attendance Corrections           | Done     | Correction request and approval workflow                      |
| Reports (Admission/Strength/Medical) | Done | 3 reports built in StudentReportController                  |
| Excel Export                     | Done     | `StudentsExport` class with Maatwebsite                       |
| PDF Export                       | Done     | DomPDF via `exports/pdf.blade.php`                            |
| Send Credentials                 | Done     | Email via `StudentLoginCreated` Mailable                      |
| Student Promotion Workflow       | Missing  | C5.1 — bulk promotion for new academic year                   |
| Alumni Management                | Missing  | C5.2 — mark alumni, close records                             |
| TC Generation PDF                | Missing  | C5.2.2 — Transfer Certificate PDF                             |
| Profile Completion Service       | Partial  | Helper class exists; not a Service; no queued computation     |
| FormRequest Classes (all)        | Missing  | P1 — all write operations need FormRequest extraction         |
| Service Layer                    | Missing  | P1 — StudentService for complex business logic                |
| Authorization on create* methods | Missing  | P1 — `createStudentLogin`, `createStudentDetails`, etc.       |
| Authorization on AttendanceController | Missing | P1 — all methods lack Gate checks                         |
| Feature Tests (HTTP)             | Missing  | P1 — only Browser/Dusk tests exist                            |
| `is_super_admin` P0 fix          | URGENT   | P0 — must be fixed immediately                                |
