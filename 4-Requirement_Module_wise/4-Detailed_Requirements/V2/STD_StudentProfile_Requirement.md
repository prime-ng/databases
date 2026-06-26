# STD — Student Profile
## Module Requirement Document V2
**Version:** 2.0 | **Date:** 2026-03-26 | **Status:** Draft | **Mode:** FULL
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** STD | **Module Path:** `Modules/StudentProfile`
**Module Type:** Tenant | **DB Prefix:** `std_*` | **Completion:** ~50%
**RBS Reference:** Module C — Admissions & Student Lifecycle + Module E — Student Information System

---

> **CRITICAL SECURITY ALERT — P0:** `is_super_admin` is validated and passed directly to `User::create()` in `StudentController::createStudentLogin()`. Any user reaching that endpoint can create a super-admin account. Additionally, `AttendanceController` has **zero** `Gate::authorize()` calls on all methods — any authenticated user can mark attendance for any student. Both must be fixed before next deployment.

---

## 1. Executive Summary

StudentProfile (STD) is the **foundational student data module** for every Prime-AI tenant school. It manages the complete student information lifecycle: system login creation, demographic profile, guardian/parent management, academic session enrollment, health records, medical incidents, document uploads, daily attendance, and administrative reports. Nearly every other tenant module depends on student data from this module.

**Current state:** ~50% complete. Core CRUD flows for student creation, guardian management, session enrollment, documents, health, and attendance are implemented. Critical security gaps (P0 privilege escalation, zero attendance authorization), missing FormRequests (0 of 10+ needed), no Service layer, and absent student promotion/TC workflows are the primary gaps.

| Metric | Value |
|--------|-------|
| Tables | 14 `std_*` tables |
| Controllers | 5 (StudentController ~3000 lines, AttendanceController, MedicalIncidentController, StudentProfileController stub, StudentReportController) |
| Models | 14 |
| FormRequests | 0 (all validation inline — critical gap) |
| Service classes | 0 (all logic inline — critical gap) |
| Tests | 6 Dusk/Browser + 1 Unit (0 HTTP Feature tests) |
| Security issues | P0×2, P1×6, P2×5 |

---

## 2. Module Overview

### 2.1 Purpose

STD manages student registration and identity, demographic and extended profiles, guardian relationships, academic session enrollment, health/vaccination/medical incident records, document uploads, daily attendance, and student lifecycle events (promotion, transfer, alumni).

### 2.2 Module Characteristics

| Attribute | Value |
|-----------|-------|
| Laravel Module | `nwidart/laravel-modules` v12, name `StudentProfile` |
| Namespace | `Modules\StudentProfile` |
| DB Connection | `tenant` (tenant_{uuid}) |
| Table Prefix | `std_*` |
| Route Prefix | `student-profile/` |
| Auth | Spatie Permission v6 via `Gate::authorize()` + `module:STUDENT` middleware |
| Photo Storage | Spatie MediaLibrary (`student_photo` collection, disk: `public`) |
| PDF Export | DomPDF |
| Excel Export | Maatwebsite Excel |
| QR Code | SimpleSoftwareIO/QrCode |
| Policy | `StudentPolicy` (registered), `AttendancePolicy` (file exists, not used) |
| Events | `StudentLoginCreated` Mailable exists; `StudentRegistration` event in `app/Events/` |

### 2.3 Module Position

```
Platform Layer      Module               Depends On
──────────────────────────────────────────────────────────────
Foundation          StudentProfile (STD) SYS, SCH, GLB
Depends on STD      StudentFee (FIN)     std_students, std_student_guardian_jnt
Depends on STD      StudentPortal (STP)  All std_* tables
Depends on STD      SmartTimetable (TT)  std_student_academic_sessions
Depends on STD      Transport (TPT)      std_students, std_student_pay_log
Depends on STD      LmsHomework          std_student_academic_sessions (class_section_id)
Depends on STD      Notification         Guardian notification preferences
```

### 2.4 Scope — In / Out

| In Scope | Out of Scope |
|----------|-------------|
| Student login + profile CRUD | Fee management (FIN module) |
| Guardian/parent management | Student portal self-service (STP module) |
| Academic session enrollment | Period/subject-level attendance (TT/LMS) |
| Document upload and verification | Behavioral assessment (separate module) |
| Health profile and vaccination records | Admission enquiry / lead management (ADM) |
| Medical incident log | Alumni management post-leaving |
| Daily attendance + correction workflow | Student ID card printing automation |
| Reports: admission register, strength, medical | Finance Accounting (FAC module) |
| Student promotion workflow (proposed) | |
| Transfer Certificate generation (proposed) | |

---

## 3. Stakeholders & Roles

| Role | Access Level |
|------|-------------|
| Super Admin | Full access across all students in all tenants |
| School Admin | Full CRUD on all students in tenant; promote, transfer, export |
| Registrar / Clerk | Create and edit student profiles, session assignment, document uploads |
| Class Teacher | View students in own class; mark attendance; no login management |
| Medical Staff | Record and view medical incidents and health profiles |
| Student | Read-only via StudentPortal; no backend access |
| Parent / Guardian | Read-only of own child's data via ParentPortal |

---

## 4. Functional Requirements

### FR-STD-01: Student List & Search
**Status:** ✅ Implemented
**Route:** `GET student-profile/student` → `StudentController::index()`

| Req ID | Requirement | Status |
|--------|-------------|--------|
| FR-STD-01.1 | List all students with pagination (12 per page, newest first) | ✅ |
| FR-STD-01.2 | Search by: admission number, first/last/middle name, user code, email, mobile | ✅ |
| FR-STD-01.3 | Filter by: active/inactive status; complete/incomplete profile (complete = has guardians) | ✅ |
| FR-STD-01.4 | Student card: photo, name, admission number, class/section, session status | ✅ |
| FR-STD-01.5 | Export to Excel (`/student/export/excel`) and PDF (`/student/export/pdf`) | ✅ |
| FR-STD-01.6 | Send credentials email to selected students | ✅ |
| FR-STD-01.7 | Gate check: `tenant.student.viewAny` on index | ✅ |

**Gaps:** CSV export option not available (P3). Excel export for 1000+ students not yet queued — risk of memory exhaustion on synchronous export.

---

### FR-STD-02: Student Login Creation (Tab 1 — Registration)
**Status:** 🟡 Partial — core works, P0 security issue
**Route:** `POST student-profile/student/create-student-login` → `StudentController::createStudentLogin()`

| Req ID | Requirement | Status |
|--------|-------------|--------|
| FR-STD-02.1 | Create sys_user record: name, short_name, email, password (hashed), user_type = STUDENT | ✅ |
| FR-STD-02.2 | Auto-generate `emp_code` in format `STD-{YYYY}-{000001}` (year-based sequential) | ✅ |
| FR-STD-02.3 | Assign "Student" Spatie role via `syncRoles()` | ✅ |
| FR-STD-02.4 | Send welcome email via `StudentLoginCreated` Mailable | ✅ |
| FR-STD-02.5 | Optional fields: 2FA toggle, is_active, profile photo upload | ✅ |
| FR-STD-02.6 | **REMOVE `is_super_admin` from validation rules and `User::create()` payload** | ❌ P0 |
| FR-STD-02.7 | Gate check: `tenant.student.create` before login creation | ❌ P1 |
| FR-STD-02.8 | Replace inline `Validator::make()` with `CreateStudentLoginRequest` FormRequest | ❌ P1 |
| FR-STD-02.9 | After creation → redirect to student edit form at `student_details` tab | ✅ |

**Critical Gap (P0):** `StudentController.php:391,412` — `'is_super_admin' => 'nullable'` in validation, then `'is_super_admin' => $request->boolean('is_super_admin')` in `User::create()`. View `_student-login.blade.php` lines 124, 165-170 exposes the super-admin toggle. This must be removed immediately.

---

### FR-STD-03: Student Details (Tab 2 — Student Detail)
**Status:** ✅ Implemented
**Route:** `POST /create-student-details`, `PUT /{student}/update-student-details`

| Req ID | Requirement | Status |
|--------|-------------|--------|
| FR-STD-03.1 | Basic info: first name, middle name, last name, DOB, gender, admission number, admission date | ✅ |
| FR-STD-03.2 | Identity documents: Aadhar ID (12-digit), APAAR ID, birth certificate number | ✅ |
| FR-STD-03.3 | ID card preferences: card type (QR/RFID/NFC/Barcode), smart card ID, QR code value | ✅ |
| FR-STD-03.4 | Extended profile: religion, caste category, nationality, mother tongue (from sys_dropdowns) | ✅ |
| FR-STD-03.5 | Financial details: bank account, IFSC, bank name, branch, UPI ID, fee depositor PAN | ✅ |
| FR-STD-03.6 | Government flags: `right_to_education`, `is_ews` | ✅ |
| FR-STD-03.7 | Physical stats: height_cm, weight_kg, measurement_date | ✅ |
| FR-STD-03.8 | Address management: permanent + correspondence; city lookup; multiple addresses per student | ✅ |
| FR-STD-03.9 | Replace inline validation with `CreateStudentDetailsRequest` FormRequest | ❌ P1 |
| FR-STD-03.10 | Gate check: `tenant.student.create` on `createStudentDetails()` | ❌ P1 |

---

### FR-STD-04: Guardian / Parent Management (Tab 3 — Parents)
**Status:** ✅ Implemented
**Route:** `POST /create-parent-details`, `PUT /parent/{parent}/update`, `DELETE /{student}/parent/{parent}/delete`

| Req ID | Requirement | Status |
|--------|-------------|--------|
| FR-STD-04.1 | Add guardian: first/last name, gender, mobile (unique), email, occupation, qualification, annual income, preferred language | ✅ |
| FR-STD-04.2 | Link via junction: relation_type (Father/Mother/Guardian), relationship description | ✅ |
| FR-STD-04.3 | Junction flags: is_emergency_contact, can_pickup, is_fee_payer, can_access_parent_portal, can_receive_notifications, notification_preference | ✅ |
| FR-STD-04.4 | Create parent system login (`createParentLogin`) with Parent role for portal access | ✅ |
| FR-STD-04.5 | Delete guardian link | ✅ |
| FR-STD-04.6 | Sibling support: same guardian linked to multiple students | ✅ |
| FR-STD-04.7 | One student may have multiple guardians (Father + Mother + Guardian) | ✅ |
| FR-STD-04.8 | Replace inline validation with `CreateGuardianRequest` FormRequest | ❌ P1 |
| FR-STD-04.9 | Gate check on `createParentDetails()` | ❌ P1 |

---

### FR-STD-05: Academic Session Assignment (Tab 4 — Session)
**Status:** ✅ Implemented
**Route:** `POST /create-student-session`, `PUT /session/{session}/update`, `DELETE /session/{session}/delete`

| Req ID | Requirement | Status |
|--------|-------------|--------|
| FR-STD-05.1 | Assign student to session: academic_session, class_section, roll number (auto/manual), subject_group, house | ✅ |
| FR-STD-05.2 | Only ONE session can be `is_current = 1` per student (enforced by generated column UNIQUE) | ✅ |
| FR-STD-05.3 | Session status: ACTIVE, PROMOTED, LEFT, SUSPENDED, ALUMNI, WITHDRAWN | ✅ |
| FR-STD-05.4 | Transition within DB transaction: set previous `is_current = 0` before setting new `is_current = 1` | ✅ |
| FR-STD-05.5 | Leaving date and reason_quit required when status = LEFT or WITHDRAWN | ✅ |
| FR-STD-05.6 | `count_for_timetable` flag | ✅ |
| FR-STD-05.7 | `count_as_attrition` flag | ✅ |
| FR-STD-05.8 | Replace inline validation with `CreateSessionRequest` FormRequest | ❌ P1 |
| FR-STD-05.9 | Gate check on `createStudentSession()` | ❌ P1 |

---

### FR-STD-06: Previous Education History (Tab 5 — Previous Education)
**Status:** ✅ Implemented
**Route:** `POST /create-student-prev-edu-details`, `PUT /previous-education/{education}/update`, `DELETE /previous-education/{education}/delete`

| Req ID | Requirement | Status |
|--------|-------------|--------|
| FR-STD-06.1 | Record previous school: name, address, board, class passed, year, percentage/grade, medium | ✅ |
| FR-STD-06.2 | TC details: TC number, TC date, is_recognized flag | ✅ |
| FR-STD-06.3 | Multiple previous education records per student | ✅ |
| FR-STD-06.4 | Remarks field per record | ✅ |

---

### FR-STD-07: Student Documents
**Status:** ✅ Implemented
**Route:** `PUT /student-document/{document}/update`, `DELETE /student-document/{document}/delete`, `GET /student-document/{document}/edit`

| Req ID | Requirement | Status |
|--------|-------------|--------|
| FR-STD-07.1 | Upload: document name, type (dropdown), document number, issue date, expiry date, issuing authority | ✅ |
| FR-STD-07.2 | Verification workflow: `is_verified`, `verified_by`, `verification_date` | ✅ |
| FR-STD-07.3 | File stored via `sys_media` (media_id) or direct file_name | ✅ |
| FR-STD-07.4 | Edit document metadata | ✅ |
| FR-STD-07.5 | Delete document | ✅ |
| FR-STD-07.6 | Server-side MIME validation (not just extension) on file upload | 🟡 Needs review |
| FR-STD-07.7 | Expired documents flagged in listing view (`expiry_date < today`) | 📐 Proposed |
| FR-STD-07.8 | TC number uniqueness enforced at application level (no DDL constraint) | 🟡 Partial |

---

### FR-STD-08: Health Profile (Tab — Health)
**Status:** ✅ Implemented
**Route:** `PUT /{student}/health-profile/update`, `POST /create-student-medical-details`

| Req ID | Requirement | Status |
|--------|-------------|--------|
| FR-STD-08.1 | One health profile per student (upsert): blood group, allergies, chronic conditions, medications, dietary restrictions, vision, doctor contact | ✅ |
| FR-STD-08.2 | Vaccination records: vaccine name, date_administered, next_due_date, remarks | ✅ |
| FR-STD-08.3 | Physical stats in health profile: height_cm, weight_kg, measurement_date | ✅ |
| FR-STD-08.4 | Replace inline validation with `UpdateHealthProfileRequest` FormRequest | ❌ P1 |
| FR-STD-08.5 | 📐 Allergy information visible on attendance marking UI (teacher awareness) | 📐 Proposed |

---

### FR-STD-09: Medical Incidents
**Status:** ✅ Implemented
**Controller:** `MedicalIncidentController` — full resource + toggle routes

| Req ID | Requirement | Status |
|--------|-------------|--------|
| FR-STD-09.1 | Record incident: type (dropdown), date, location, description, first aid given, action taken, reported_by | ✅ |
| FR-STD-09.2 | Closure and follow-up: closure_date, follow_up_required toggle | ✅ |
| FR-STD-09.3 | Parent notification toggle: `parent_notified` | ✅ |
| FR-STD-09.4 | Full CRUD + soft delete + restore + force delete + trash view | ✅ |
| FR-STD-09.5 | Gate checks on MedicalIncidentController | 🟡 Needs review (P2) |
| FR-STD-09.6 | Trigger Notification to parent guardian on incident creation | 📐 Proposed |

---

### FR-STD-10: Daily Attendance
**Status:** 🟡 Partial — CRUD works, zero authorization (P0/P1)
**Controller:** `AttendanceController`

| Req ID | Requirement | Status |
|--------|-------------|--------|
| FR-STD-10.1 | Mark daily attendance: Present / Absent / Late / Half Day / Short Leave / Leave | ✅ |
| FR-STD-10.2 | QR scan attendance (`POST attendance/scan`) | ✅ |
| FR-STD-10.3 | Manual attendance entry (`POST attendance/manual`) | ✅ |
| FR-STD-10.4 | Bulk attendance for class (`POST bulk-attendance/store`) | ✅ |
| FR-STD-10.5 | Attendance period support (`attendance_period` column — 0 = daily) | ✅ |
| FR-STD-10.6 | **Add `Gate::authorize()` on ALL AttendanceController methods** | ❌ P0 |
| FR-STD-10.7 | Create `AttendancePolicyRequest` / use existing `AttendancePolicy` file | ❌ P1 |
| FR-STD-10.8 | Wrap `storeBulkAttendance()` in DB transaction | ❌ P1 |
| FR-STD-10.9 | Replace inline `$request->validate()` with `StoreAttendanceRequest` FormRequest | ❌ P1 |
| FR-STD-10.10 | Remove debug comment `// dd($request->all());s` at line 294 | ❌ P3 |

**Gap Detail:** `AttendanceController.php` — every method (index, create, scanAttendance, manualAttendance, bulkAttendanceIndex, storeBulkAttendance) has zero Gate checks. `AttendancePolicy.php` file exists in Policies directory but is not used anywhere.

---

### FR-STD-11: Attendance Corrections
**Status:** 🟡 Partial — model and table exist; workflow incomplete
**Table:** `std_attendance_corrections`

| Req ID | Requirement | Status |
|--------|-------------|--------|
| FR-STD-11.1 | Student/parent submits correction request with reason | 🟡 Model only |
| FR-STD-11.2 | Class teacher reviews and approves/rejects correction | ❌ No controller/routes |
| FR-STD-11.3 | Admin final approval with audit log | ❌ No controller/routes |
| FR-STD-11.4 | `status` field: Pending → Approved/Rejected; `action_by`, `action_at` recorded | ❌ Not implemented |

---

### FR-STD-12: Student Status Management
**Status:** ✅ Implemented

| Req ID | Requirement | Status |
|--------|-------------|--------|
| FR-STD-12.1 | Toggle active/inactive via `POST /{student}/toggle-status` | ✅ |
| FR-STD-12.2 | Soft delete via standard resource `DELETE /student/{id}` | ✅ |
| FR-STD-12.3 | Restore soft-deleted via `PATCH /student/{id}/restore` | ✅ |
| FR-STD-12.4 | Force delete via `DELETE /student/{id}/force-delete` | ✅ |
| FR-STD-12.5 | Bulk restore and bulk force-delete endpoints | ✅ |
| FR-STD-12.6 | Empty trash endpoint (`/student/empty-trash`) | ✅ |
| FR-STD-12.7 | Trash view with restore/force-delete UI | ✅ |

---

### FR-STD-13: Student Promotion Workflow
**Status:** ❌ Not Started
**Proposed Controller:** `StudentPromotionController`

| Req ID | Requirement | Status |
|--------|-------------|--------|
| FR-STD-13.1 | 📐 Bulk promotion: select academic year, map current class → next class for all students | 📐 Proposed |
| FR-STD-13.2 | 📐 Preview promotion mapping before executing | 📐 Proposed |
| FR-STD-13.3 | 📐 Per-student override: skip promotion, demote, mark alumni | 📐 Proposed |
| FR-STD-13.4 | 📐 Promotion creates new `std_student_academic_sessions` record and sets previous `is_current = 0` | 📐 Proposed |
| FR-STD-13.5 | 📐 Promoted student retains all historical session records | 📐 Proposed |
| FR-STD-13.6 | 📐 Promotion job runs asynchronously for large schools | 📐 Proposed |

---

### FR-STD-14: Transfer Certificate (TC) Generation
**Status:** ❌ Not Started

| Req ID | Requirement | Status |
|--------|-------------|--------|
| FR-STD-14.1 | 📐 TC workflow: mark student as LEFT/TRANSFERRED; record TC number, date, reason | 📐 Proposed |
| FR-STD-14.2 | 📐 Generate TC PDF: student name, DOB, admission no, class, session, leaving reason, school principal signature block | 📐 Proposed |
| FR-STD-14.3 | 📐 TC serial number auto-generated and unique per tenant per academic year | 📐 Proposed |
| FR-STD-14.4 | 📐 Issued TC stored as student document via `std_student_documents` | 📐 Proposed |

---

### FR-STD-15: Student Reports
**Status:** ✅ Implemented
**Controller:** `StudentReportController`

| Req ID | Requirement | Status |
|--------|-------------|--------|
| FR-STD-15.1 | Admission Register: all admitted students with admission numbers, dates, class | ✅ |
| FR-STD-15.2 | Student Strength report: class-wise boys/girls/total count | ✅ |
| FR-STD-15.3 | Medical Profile report: blood group summary, chronic conditions across students | ✅ |
| FR-STD-15.4 | Gate check on `StudentReportController` — needs verification/enforcement | 🟡 Needs review |

---

### FR-STD-16: Profile Completion Tracking
**Status:** ✅ Implemented (via helper, not service)

| Req ID | Requirement | Status |
|--------|-------------|--------|
| FR-STD-16.1 | 5-tab completion: Login Details, Student Details, Parent Details, Session Details, Previous Education | ✅ |
| FR-STD-16.2 | `StudentProfileHelper::getProgressPercentage()` computes on-the-fly percentage | ✅ |
| FR-STD-16.3 | `StudentProfileHelper::getFirstIncompleteTab()` navigates to first incomplete tab | ✅ |
| FR-STD-16.4 | `Student::getProfileCompletionAttribute()` returns `{completed, total, percentage, next_tab}` | ✅ |
| FR-STD-16.5 | 📐 Extract ProfileCompletion logic into `StudentProfileCompletionService` for testability | 📐 Proposed |

---

### FR-STD-17: Student Credential Management
**Status:** ✅ Implemented

| Req ID | Requirement | Status |
|--------|-------------|--------|
| FR-STD-17.1 | Send credentials email to selected students (`/students/send-credentials`) | ✅ |
| FR-STD-17.2 | Welcome email via `StudentLoginCreated` Mailable on creation | ✅ |
| FR-STD-17.3 | Verify credentials are transmitted securely (TLS) — review `sendCredentials` method | 🟡 Review |

---

## 5. Data Model

### 5.1 Table Inventory (DDL v2)

| Table | Purpose | Key Columns | Soft Delete |
|-------|---------|-------------|:-----------:|
| `std_students` | Core student entity, linked to `sys_users` | `user_id`, `admission_no`, `dob`, `gender`, `current_status_id`, `is_active` | ✅ `deleted_at` |
| `std_student_profiles` | Extended demographic profile (1:1) | `student_id`, `religion`, `caste_category`, `nationality`, `bank_account_no`, `right_to_education`, `is_ews` | ❌ |
| `std_student_addresses` | Multiple addresses per student (1:N) | `student_id`, `address_type` (Permanent/Correspondence/Guardian/Local), `city_id`, `is_primary` | ❌ |
| `std_guardians` | Parent/guardian master record | `user_code`, `user_id` (nullable), `mobile_no` (UNIQUE), `preferred_language` | ❌ |
| `std_student_guardian_jnt` | Student-guardian M:N junction | `student_id`, `guardian_id`, `relation_type`, `is_fee_payer`, `can_access_parent_portal`, `notification_preference` | ❌ |
| `std_student_academic_sessions` | Class/section allocation per academic year | `student_id`, `academic_session_id`, `class_section_id`, `is_current`, `current_flag` (generated), `session_status_id`, `count_for_timetable` | ❌ |
| `std_previous_education` | Previous schools attended (1:N) | `student_id`, `school_name`, `board`, `tc_number`, `is_recognized` | ❌ |
| `std_student_documents` | Uploaded documents per student (1:N) | `student_id`, `document_type_id`, `is_verified`, `verified_by`, `expiry_date` | ❌ |
| `std_health_profiles` | Medical profile (1:1) | `student_id`, `blood_group`, `allergies`, `chronic_conditions`, `medications`, `vision_left/right`, `doctor_name` | ❌ |
| `std_vaccination_records` | Vaccination history (1:N) | `student_id`, `vaccine_name`, `date_administered`, `next_due_date` | ❌ |
| `std_medical_incidents` | School medical incidents (1:N) | `student_id`, `incident_type_id`, `description`, `parent_notified`, `follow_up_required` | ❌ (has soft-delete in model) |
| `std_student_attendance` | Daily attendance records | `student_id`, `class_section_id`, `attendance_date`, `attendance_period`, `status`, `marked_by` | ❌ |
| `std_attendance_corrections` | Correction requests | `attendance_id`, `requested_by`, `requested_status`, `status` (Pending/Approved/Rejected), `action_by` | ❌ |
| `std_student_pay_log` | Transport/misc payment log | (referenced in Student model, no module model) | — |

### 5.2 Missing SoftDeletes (P2 Gap)

| Model | Table | Fix Required |
|-------|-------|-------------|
| `StudentAttendance` | `std_student_attendance` | Add SoftDeletes + `deleted_at` |
| `StudentAttendanceCorrection` | `std_attendance_corrections` | Add SoftDeletes + `deleted_at` |
| `VaccinationRecord` | `std_vaccination_records` | Add SoftDeletes + `deleted_at` |
| `StudentGuardianJnt` | `std_student_guardian_jnt` | Add SoftDeletes + `deleted_at` |
| `StudentHealthProfile` | `std_health_profiles` | Add SoftDeletes + `deleted_at` |
| `StudentDocument` | `std_student_documents` | Add SoftDeletes + `deleted_at` |

### 5.3 Generated Column — Current Session Guard

```sql
-- std_student_academic_sessions
current_flag INT GENERATED ALWAYS AS (
  CASE WHEN is_current = 1 THEN student_id ELSE NULL END
) STORED
UNIQUE KEY uq_studentSessions_currentFlag (current_flag)
```
This enforces exactly one current session per student at the DB level. Application code must SET `is_current = 0` on the old record before SET `is_current = 1` on the new record, **within a single DB transaction** to avoid constraint violations.

### 5.4 Spatie MediaLibrary Collections

| Collection | Single | Disk | Accepted MIME | Conversions |
|-----------|:------:|------|--------------|------------|
| `student_photo` | Yes | public | jpg, png, gif | thumb (100×100), medium (300×300), large (600×600) |

### 5.5 Key Constraints Summary

| Constraint | Table | Type |
|-----------|-------|------|
| `uq_std_students_admissionNo` | `std_students` | UNIQUE `admission_no` |
| `uq_std_students_aadhar` | `std_students` | UNIQUE `aadhar_id` |
| `uq_std_students_userId` | `std_students` | UNIQUE `user_id` |
| `uq_std_guardians_mobile` | `std_guardians` | UNIQUE `mobile_no` |
| `uq_std_profiles_studentId` | `std_student_profiles` | UNIQUE `student_id` (1:1) |
| `uq_studentSessions_currentFlag` | `std_student_academic_sessions` | UNIQUE `current_flag` (generated) |
| `uq_std_acad_sess_student_session` | `std_student_academic_sessions` | UNIQUE `(student_id, academic_session_id)` |
| `uq_std_att_student_date` | `std_student_attendance` | UNIQUE `(student_id, attendance_date, attendance_period)` |
| `uq_health_student` | `std_health_profiles` | UNIQUE `student_id` (1:1) |

### 5.6 Model — ORM / SoftDeletes Status

| Model | SoftDeletes | `$fillable` reviewed | Issues |
|-------|:-----------:|:-------------------:|--------|
| `Student` | ✅ | ✅ | `is_super_admin` NOT in `$fillable` (vulnerability is in `User::create()`) |
| `Guardian` | ✅ | 🟡 | Review mass-assignment |
| `StudentDetail` | ✅ | 🟡 | Table name mismatch: model expects `std_student_details`, DDL has `std_student_profiles` — **investigate** |
| `StudentProfile` | ✅ | 🟡 | Boundary overlap with StudentDetail |
| `StudentAddress` | ✅ | 🟡 | — |
| `PreviousEducation` | ✅ | 🟡 | — |
| `MedicalIncident` | ✅ | 🟡 | — |
| `StudentAttendance` | ❌ | ❌ | No SoftDeletes |
| `StudentAttendanceCorrection` | ❌ | ❌ | No SoftDeletes |
| `VaccinationRecord` | ❌ | ❌ | No SoftDeletes |
| `StudentGuardianJnt` | ❌ | ❌ | No SoftDeletes |
| `StudentHealthProfile` | ❌ | ❌ | No SoftDeletes |
| `StudentDocument` | ❌ | ❌ | No SoftDeletes |
| `StudentAcademicSession` | ❌ | 🟡 | No SoftDeletes |

---

## 6. API Endpoints & Routes

### 6.1 Route Summary

All routes under prefix `student-profile/`, middleware `['auth', 'verified', 'module:STUDENT']`

| Method | Route | Controller::Method | Gate | Status |
|--------|-------|--------------------|------|--------|
| GET | `student` | `StudentController::index` | `tenant.student.viewAny` | ✅ |
| GET | `student/create` | `StudentController::create` | `tenant.student.create` | ✅ |
| GET | `student/{id}` | `StudentController::show` | `tenant.student.view` | ✅ |
| GET | `student/{id}/edit` | `StudentController::edit` | `tenant.student.update` | ✅ |
| POST | `student/create-student-login` | `::createStudentLogin` | ❌ NONE | 🔴 P1 |
| POST | `student/create-student-details` | `::createStudentDetails` | ❌ NONE | 🔴 P1 |
| POST | `student/create-parent-details` | `::createParentDetails` | ❌ NONE | 🔴 P1 |
| POST | `student/create-student-session` | `::createStudentSession` | ❌ NONE | 🔴 P1 |
| POST | `student/create-student-prev-edu-details` | `::createStudentPrevEduDetails` | ❌ NONE | 🔴 P1 |
| POST | `student/create-student-medical-details` | `::createStudentMedicalDetails` | ❌ NONE | 🔴 P1 |
| POST | `student/create-parent-login` | `::createParentLogin` | ❌ NONE | 🔴 P1 |
| PUT | `student/{user}/update-login` | `::updateLogin` | `tenant.student.update` | ✅ |
| PUT | `student/{student}/update-student-details` | `::updateStudentDetails` | In-method | ✅ |
| PUT | `student/{student}/update-profile` | `::updateProfile` | In-method | ✅ |
| PUT | `student/{student}/update-address` | `::updateStudentAddress` | In-method | ✅ |
| DELETE | `student/address/{addressId}` | `::deleteStudentAddress` | In-method | ✅ |
| PUT | `parent/{parent}/update` | `::updateParentDetails` | In-method | ✅ |
| DELETE | `student/{student}/parent/{parent}/delete` | `::deleteParent` | In-method | ✅ |
| PUT | `session/{session}/update` | `::updateStudentSession` | In-method | ✅ |
| DELETE | `session/{session}/delete` | `::deleteStudentSession` | In-method | ✅ |
| PUT | `student/{student}/health-profile/update` | `::updateHealthProfile` | In-method | ✅ |
| PUT | `vaccination/{vaccination}/update` | `::updateVaccinationRecord` | In-method | ✅ |
| DELETE | `vaccination/{vaccination}/delete` | `::deleteVaccinationRecord` | In-method | ✅ |
| PUT | `student-document/{document}/update` | `::updateStudentDocument` | In-method | ✅ |
| DELETE | `student-document/{document}/delete` | `::deleteStudentDocument` | In-method | ✅ |
| POST | `student/{student}/toggle-status` | `::toggleStatus` | `tenant.student.update` | ✅ |
| POST | `students/send-credentials` | `::sendCredentials` | `tenant.student.update` | ✅ |
| GET | `student/export/{type}` | `::export` | `tenant.student.export` | ✅ |
| GET | `student/trash/view` | `::trashed` | `tenant.student.delete` | ✅ |
| PATCH | `student/{id}/restore` | `::restore` | `tenant.student.delete` | ✅ |
| DELETE | `student/{id}/force-delete` | `::forceDelete` | `tenant.student.delete` | ✅ |
| POST | `student/bulk-restore` | `::bulkRestore` | `tenant.student.delete` | ✅ |
| DELETE | `student/bulk-force-delete` | `::bulkForceDelete` | `tenant.student.delete` | ✅ |
| GET | `attendance` | `AttendanceController::index` | ❌ NONE | 🔴 P0 |
| GET | `attendance/create` | `::create` | ❌ NONE | 🔴 P0 |
| POST | `attendance/scan` | `::scanAttendance` | ❌ NONE | 🔴 P0 |
| POST | `attendance/manual` | `::manualAttendance` | ❌ NONE | 🔴 P0 |
| GET | `bulk-attendance` | `::bulkAttendanceIndex` | ❌ NONE | 🔴 P0 |
| POST | `bulk-attendance/store` | `::storeBulkAttendance` | ❌ NONE | 🔴 P0 |
| GET | `reports-mgt` | `StudentReportController::combinedStudentReport` | 🟡 Review | 🟡 |
| Resource | `medical-incidents` | `MedicalIncidentController` | 🟡 Review | 🟡 |

### 6.2 Planned REST API Endpoints (Missing)

| Method | Endpoint | Description | Priority |
|--------|----------|-------------|---------|
| GET | `/api/v1/students` | Student list with filters | 📐 P2 |
| GET | `/api/v1/students/{id}` | Student full profile | 📐 P2 |
| GET | `/api/v1/students/{id}/attendance` | Student attendance records | 📐 P2 |
| GET | `/api/v1/students/{id}/health` | Student health summary | 📐 P2 |
| POST | `/api/v1/attendance/bulk-mark` | Bulk attendance via mobile app | 📐 P2 |
| GET | `/api/v1/students/{id}/sessions` | Academic session history | 📐 P3 |

### 6.3 Cross-Module Route Issue

`student/create1` route (line 1551, tenant.php) is defined under `school-setup` prefix, not `student-profile` — **cross-module route leakage** (P2). Must be moved or removed.

---

## 7. UI Screens

| Screen | Views | Status |
|--------|-------|--------|
| Student List | `student/index.blade.php` | ✅ |
| Student Create | `student/create.blade.php` (multi-tab) | ✅ |
| Student Edit | `student/edit.blade.php` (8 tab partials) | ✅ |
| Student Show | `student/show` | ✅ |
| Student Trash | `student/trash.blade.php` | ✅ |
| Tab: Login Details | `partials/edit/.../\_student-login.blade.php` | 🔴 Exposes `is_super_admin` toggle |
| Tab: Student Details | `..._student-details.blade.php` | ✅ |
| Tab: Parents | (guardian partial) | ✅ |
| Tab: Session | (session partial) | ✅ |
| Tab: Previous Education | (prev-edu partial) | ✅ |
| Tab: Documents | (documents partial) | ✅ |
| Tab: Health | `..._student-health.blade.php` | ✅ |
| Attendance Index | `attendance/index` | ✅ |
| Attendance Create | `attendance/create` | ✅ |
| Bulk Attendance | (bulk form) | ✅ |
| Medical Incidents | `medical-incidents/` (create/edit/show/index/trash) | ✅ |
| Reports Hub | `reports-mgt` | ✅ |
| Student Export PDF | `exports/pdf.blade.php` | ✅ |
| Email Template | (credential email template) | ✅ |
| Student Promotion | ❌ Not built | 📐 Proposed |
| TC Generation | ❌ Not built | 📐 Proposed |

---

## 8. Business Rules

### 8.1 Student Identity

| Rule ID | Rule |
|---------|------|
| BR-STD-01 | `admission_no` unique per tenant; cannot be changed after assignment |
| BR-STD-02 | `aadhar_id` unique if provided (12-digit numeric); must comply with UIDAI guidelines |
| BR-STD-03 | `email` unique in `sys_users` (shared with all user types) |
| BR-STD-04 | `emp_code` auto-format: `STD-{YYYY}-{000001}` — year-based sequential; cannot be manually set at student creation |
| BR-STD-05 | APAAR ID: 12-digit format (Academic Bank of Credits) — validation pending implementation |
| BR-STD-06 | Student QR code value should not directly expose `admission_no`; use hash/UUID (P2) |

### 8.2 Academic Session Rules

| Rule ID | Rule |
|---------|------|
| BR-STD-07 | Only ONE `is_current = 1` session per student — enforced by generated column UNIQUE constraint |
| BR-STD-08 | Transition must execute within DB transaction: set old `is_current = 0` before setting new `is_current = 1` |
| BR-STD-09 | A student cannot be enrolled in the same `academic_session_id` twice — UNIQUE `(student_id, academic_session_id)` |
| BR-STD-10 | `leaving_date` and `reason_quit` required when `session_status` = LEFT or WITHDRAWN |
| BR-STD-11 | `count_for_timetable = 0` automatically when student is SUSPENDED or WITHDRAWN |

### 8.3 Guardian Rules

| Rule ID | Rule |
|---------|------|
| BR-STD-12 | Mobile number is the unique identifier for a guardian; two guardians cannot share same mobile |
| BR-STD-13 | A complete profile requires at least one guardian with `relation_type` = Father, Mother, or Guardian |
| BR-STD-14 | Guardian `user_id` is NULL until parent portal access granted; portal access creates `sys_users` record |
| BR-STD-15 | `is_fee_payer = 1` guardian referenced in StudentFee sibling discount; at most one per student |
| BR-STD-16 | Notifications sent only to guardians with `can_receive_notifications = 1` |

### 8.4 Attendance Rules

| Rule ID | Rule |
|---------|------|
| BR-STD-17 | Attendance can only be marked for the current academic session's date range |
| BR-STD-18 | Once marked, attendance correction requires formal `std_attendance_corrections` request |
| BR-STD-19 | Correction workflow: student/parent submits → class teacher approves → admin final-approves |
| BR-STD-20 | System should flag attendance < 75% for notification trigger (not yet implemented) |
| BR-STD-21 | `attendance_period = 0` for daily attendance; non-zero for period-wise (controlled by system setting `Period_wise_Student_Attendance`) |
| BR-STD-22 | Bulk attendance must execute in a DB transaction; partial saves not permitted |

### 8.5 Document Rules

| Rule ID | Rule |
|---------|------|
| BR-STD-23 | TC number must be unique if provided — enforced at application level (no DDL constraint) |
| BR-STD-24 | Document verification only by Admin or Registrar roles |
| BR-STD-25 | Expired documents (past `expiry_date`) must be flagged in listing view |
| BR-STD-26 | File uploads must validate MIME type server-side, not just extension |

### 8.6 Profile Completion Rules

| Rule ID | Rule |
|---------|------|
| BR-STD-27 | "Complete" profile: user_id + admission_no + at least one guardian + at least one academic session + at least one previous education record |
| BR-STD-28 | List filter "incomplete" currently checks `doesntHave('guardians')` only — simplified; full check done in edit view |
| BR-STD-29 | Profile completion % is computed on-the-fly; not suitable for high-volume batch queries without caching |

---

## 9. Workflows

### 9.1 New Student Onboarding

```
Admin → Tab 1 (Create Login)
          ↓ createStudentLogin() → sys_users + Student record
        Tab 2 (Student Details)
          ↓ createStudentDetails() → std_students fields + std_student_profiles
        Tab 3 (Parents)
          ↓ createParentDetails() → std_guardians + std_student_guardian_jnt
        Tab 4 (Session)
          ↓ createStudentSession() → std_student_academic_sessions (is_current=1)
        Tab 5 (Previous Education)
          ↓ createStudentPrevEduDetails() → std_previous_education
        Optional: Upload Documents → std_student_documents
        Optional: Health Profile → std_health_profiles
        Optional: Vaccination Records → std_vaccination_records
        → Profile complete → Send credentials email
```

### 9.2 Attendance Correction Workflow

```
Student/Parent → submit correction request (std_attendance_corrections, status=Pending)
  ↓
Class Teacher → review request → approve/reject (status=Approved/Rejected, action_by, action_at)
  ↓
Admin → final approval (audit log)
  ↓
Attendance record updated if approved
```
**Status:** Model and table exist. Controller and routes not yet implemented.

### 9.3 Guardian Portal Access Granting

```
Admin → createParentLogin()
  ↓
sys_users record created with Parent role
  ↓
std_guardians.user_id populated
  ↓
std_student_guardian_jnt.can_access_parent_portal = 1
  ↓
Credentials sent to guardian email
```

### 9.4 Student Promotion (Proposed)

```
Admin → Promotion Wizard
  ↓
Select: current academic year + target academic year
  ↓
System generates: [current_class → next_class] mapping for all students
  ↓
Admin reviews: approve / override per student
  ↓
Bulk Job: foreach student → new std_student_academic_sessions (is_current=1) + old is_current=0
  ↓
Students with session_status = LEFT/WITHDRAWN/ALUMNI are excluded
```

---

## 10. Non-Functional Requirements

### 10.1 Performance

| NFR | Requirement | Status |
|-----|-------------|--------|
| NFR-STD-P1 | Student list paginated at 12 per page; no full-table loads | ✅ |
| NFR-STD-P2 | `show()` eager-loads all relationships in one chain; avoid N+1 | 🟡 Review nested relations |
| NFR-STD-P3 | Photo thumbnail generation deferred to MediaLibrary queued jobs | ✅ |
| NFR-STD-P4 | Excel export for 1000+ students must use chunked/queued export via Laravel Excel | ❌ Currently synchronous |
| NFR-STD-P5 | QR code generation is synchronous — may be slow for bulk ID card generation | 🟡 Watch |
| NFR-STD-P6 | Bulk attendance wrap in DB transaction; test performance at 500+ students per class | ❌ No transaction |

### 10.2 Security

| NFR | Requirement | Priority |
|-----|-------------|---------|
| NFR-STD-S1 | Remove `is_super_admin` from student login creation validation and User::create() payload | P0 |
| NFR-STD-S2 | Add Gate::authorize() to every AttendanceController method | P0 |
| NFR-STD-S3 | Delete `StudentController.bk` backup file (contains `dd()` debug calls) | P1 |
| NFR-STD-S4 | Replace all inline `Validator::make($request->all())` with FormRequest + `$request->validated()` | P1 |
| NFR-STD-S5 | File uploads must validate MIME type server-side | P1 |
| NFR-STD-S6 | Aadhar ID: consider encryption at rest (sensitive PII per UIDAI guidelines) | P2 |
| NFR-STD-S7 | Student QR code value must not expose admission_no directly; use hash/UUID | P2 |
| NFR-STD-S8 | Rate limiting on bulk operations (bulk attendance, bulk export) | P2 |

### 10.3 Data Integrity

| NFR | Requirement |
|-----|-------------|
| NFR-STD-D1 | All student deletions (soft/force) must cascade correctly per FK constraints |
| NFR-STD-D2 | Academic session `is_current` transitions must execute in DB transactions |
| NFR-STD-D3 | Guardian mobile number uniqueness enforced at DB (UNIQUE) + application level |
| NFR-STD-D4 | SoftDeletes must be added to 6 models currently missing the trait |

### 10.4 Indian Regulatory Compliance

| NFR | Requirement |
|-----|-------------|
| NFR-STD-I1 | Aadhar ID: 12-digit numeric validation when provided |
| NFR-STD-I2 | APAAR ID: 12-digit format (Academic Bank of Credits) |
| NFR-STD-I3 | Caste category must include at minimum: SC, ST, OBC, General for government reporting |
| NFR-STD-I4 | Admission register must conform to state education department format |
| NFR-STD-I5 | RTE/EWS flags mandatory for government-aided schools reporting |

---

## 11. Dependencies

### 11.1 Incoming (Modules STD Consumes)

| Module | Model/Table Consumed | Purpose |
|--------|---------------------|---------|
| SystemConfig (SYS) | `sys_users`, `sys_dropdowns`, `sys_dropdown_table` | User creation, religion/caste/status lookups |
| SchoolSetup (SCH) | `sch_class_section_jnt`, `sch_org_academic_sessions_jnt`, `sch_subject_groups` | Session enrollment |
| GlobalMaster (GLB) | `glb_cities`, `glb_languages` | Address city lookup, guardian preferred language |
| Spatie MediaLibrary | `sys_media` | Photo and document file storage |

### 11.2 Outgoing (Modules Consuming STD)

| Module | Data Provided | Integration Point |
|--------|--------------|-------------------|
| StudentFee (FIN) | `Student`, `StudentGuardianJnt` | Fee assignment, invoice generation, sibling discount |
| StudentPortal (STP) | All `std_*` tables | Portal read-only views for students |
| ParentPortal (PPT) | `std_guardians`, `std_student_guardian_jnt` | Portal read-only views for parents |
| SmartTimetable (TT) | `std_student_academic_sessions.count_for_timetable` | Timetable slot generation |
| Transport (TPT) | `std_students`, `std_student_pay_log` | Transport fee payment logs |
| LmsHomework | `std_student_academic_sessions.class_section_id` | Homework assignment by class |
| Notification | Guardian notification preferences | Low attendance alerts, fee reminders |

---

## 12. Test Scenarios

### 12.1 Existing Tests

| Test File | Type | Coverage |
|-----------|------|---------|
| `StudentCreateTest.php` | Browser/Dusk | Student login creation (Tab 1) |
| `StudentEditTest.php` | Browser/Dusk | Student profile edit form navigation |
| `StudentCompleteProfileTest.php` | Browser/Dusk | Full 5-tab profile completion |
| `BulkAttendanceTest.php` | Browser/Dusk | Bulk attendance marking UI |
| `MedicalIncidentTest.php` | Browser/Dusk | Medical incident CRUD UI |
| `StudentModelTest.php` | Unit | StudentProfile model |

### 12.2 Required Feature Tests (Missing — P1)

| Test Scenario | Priority | Rationale |
|--------------|---------|-----------|
| `is_super_admin` NOT assignable in student login creation | P0 | Regression prevention for P0 exploit |
| `createStudentLogin` rejects `is_super_admin = true` in POST payload | P0 | Security regression test |
| Unauthenticated / unauthorized user cannot mark attendance | P0 | AttendanceController auth gap |
| Student CRUD: create → show → edit → delete → restore | P1 | Core smoke test |
| Guardian creation with duplicate mobile → validation error 422 | P1 | BR-STD-12 enforcement |
| Academic session `is_current` uniqueness: cannot set two sessions current | P1 | BR-STD-07 / DB constraint |
| Profile completion percentage computation | P1 | BR-STD-27/29 |
| Student soft delete → trashed → restore → force delete | P1 | Lifecycle |
| Document upload: invalid MIME type rejected | P1 | Security NFR-STD-S5 |
| Bulk attendance DB transaction: rollback on partial failure | P1 | NFR-STD-P6 |
| Attendance correction: Pending → Approved → attendance updated | P2 | BR-STD-19 |
| Export: Excel/PDF generation without N+1 queries | P2 | Performance |
| Sibling guardian links two students via same guardian record | P2 | BR-STD-15 |

### 12.3 Unit Tests Required

| Test | Priority |
|------|---------|
| `StudentProfileHelper::getProgressPercentage()` — all 5 tabs complete | P1 |
| `StudentProfileHelper::getFirstIncompleteTab()` — returns first missing tab | P1 |
| `Student::getProfileCompletionAttribute()` | P1 |
| `admission_no` unique validator in `CreateStudentDetailsRequest` | P1 |
| Aadhar ID format: 12-digit numeric only | P2 |

---

## 13. Glossary

| Term | Definition |
|------|-----------|
| APAAR ID | Academic Bank of Credits ID — 12-digit national student identifier (India) |
| Aadhar | National biometric identity document (12-digit) issued by UIDAI |
| RTE | Right to Education — government quota for underprivileged students |
| EWS | Economically Weaker Section — government category for fee concessions |
| emp_code | System-generated user code (format: `STD-YYYY-000001` for students) |
| current_flag | Generated column in `std_student_academic_sessions` — enforces one current session per student |
| is_current | Boolean: marks the active academic enrollment for a student |
| count_for_timetable | Flag indicating whether the student-session should be counted in timetable generation |
| count_as_attrition | Flag marking a student departure as attrition for HR analytics |
| is_fee_payer | Flag on guardian junction: the guardian responsible for paying school fees |
| can_pickup | Flag: guardian authorized to collect child from school |
| StudentPayLog | Payment log table (`std_student_pay_log`) used by Transport module; no dedicated STD model |
| SoftDeletes | Laravel trait: marks record as deleted via `deleted_at` timestamp; restorable |
| MIME validation | Server-side file type verification based on content (not just file extension) |
| FormRequest | Laravel class encapsulating HTTP request validation and authorization |

---

## 14. Suggestions (V2 Proposed Improvements)

### 14.1 Architecture Refactoring (P1)

| Suggestion | Rationale |
|-----------|-----------|
| Split `StudentController` (~3000 lines) into: `StudentLoginController`, `StudentDetailsController`, `GuardianController`, `StudentSessionController`, `StudentHealthController`, `StudentDocumentController` | Single Responsibility; current monolith is unmaintainable |
| Create `StudentService`, `AttendanceService`, `GuardianService` under `app/Services/` | Extract business logic from controllers; enables testability |
| Create 10+ FormRequest classes (see Section 8) | Remove all inline `Validator::make($request->all())` calls; enforce `$request->validated()` usage |
| Extract `StudentProfileHelper` into proper `StudentProfileCompletionService` with interface | Testable, injectable; remove static helper pattern |

### 14.2 Security Hardening (P0/P1)

| Suggestion | Rationale |
|-----------|-----------|
| Remove `is_super_admin` from `createStudentLogin()` validation and `User::create()` | P0 privilege escalation fix |
| Add `Gate::authorize('tenant.attendance.create')` etc. on all `AttendanceController` methods | P0 authorization gap |
| Register and use `AttendancePolicy` (file already exists) | Completes policy coverage |
| Register policies for `Guardian`, `MedicalIncident`, `StudentDocument` | Missing policy coverage |
| Delete `StudentController.bk` from production | Contains `dd()` debug calls; security/maintenance risk |

### 14.3 Missing Workflows (P2)

| Suggestion | Rationale |
|-----------|-----------|
| Implement Attendance Correction controller and routes (table + model already exist) | P2 feature gap |
| Implement Student Promotion wizard + `StudentPromotionService` | Year-end bulk workflow |
| Implement TC (Transfer Certificate) PDF generation | Common school workflow; affects admission/leaving records |
| Implement `StudentRegistration` event dispatching on profile creation | Enables notification hooks, analytics |
| Add attendance < 75% automated notification trigger | BR-STD-20 |
| Implement CSV export option alongside Excel/PDF | P3 convenience |

### 14.4 Data Quality (P2)

| Suggestion | Rationale |
|-----------|-----------|
| Add SoftDeletes to 6 models missing the trait | Consistent soft-delete behavior |
| Clarify `StudentDetail` vs `StudentProfile` boundary (table name mismatch) | `StudentDetail` model expects `std_student_details` but DDL has `std_student_profiles` |
| Store profile completion % in a computed/cached column | Currently on-the-fly; not scalable for 10,000+ student queries |
| Encrypt Aadhar ID at rest | UIDAI compliance |

---

## 15. Appendices

### 15.1 FormRequest Classes Required

| FormRequest | Controller Method | Key Rules |
|------------|------------------|-----------|
| `CreateStudentLoginRequest` | `createStudentLogin` | `email` unique `sys_users`; `password` confirmed; **NO `is_super_admin`** |
| `CreateStudentDetailsRequest` | `createStudentDetails` | `admission_no` unique `std_students`; `aadhar_id` unique nullable; `dob` before today |
| `CreateGuardianRequest` | `createParentDetails` | `mobile_no` unique `std_guardians`; `relation_type` in Father/Mother/Guardian |
| `CreateSessionRequest` | `createStudentSession` | `academic_session_id` exists; `class_section_id` exists; no duplicate session |
| `UpdateStudentLoginRequest` | `updateLogin` | `email` unique ignore current user |
| `UpdateStudentDetailsRequest` | `updateStudentDetails` | `admission_no` unique ignore current student |
| `UpdateGuardianRequest` | `updateParentDetails` | `mobile_no` unique ignore current guardian |
| `UpdateSessionRequest` | `updateStudentSession` | Status transitions validation |
| `StoreAttendanceRequest` | `scanAttendance`, `manualAttendance` | `status` enum; `date` before_or_equal today |
| `StoreBulkAttendanceRequest` | `storeBulkAttendance` | Array of attendance records; each entry validates status + student_id exists |
| `UpdateHealthProfileRequest` | `updateHealthProfile` | `blood_group` enum; optional text fields |
| `StoreMedicalIncidentRequest` | `MedicalIncidentController::store` | `incident_date` required; `incident_type_id` exists |

### 15.2 Gate / Permission Reference

| Permission Key | Description |
|---------------|-------------|
| `tenant.student.viewAny` | List all students |
| `tenant.student.view` | View single student |
| `tenant.student.create` | Create student login + details |
| `tenant.student.update` | Edit student records |
| `tenant.student.delete` | Soft/force delete, restore |
| `tenant.student.export` | Export Excel/PDF |
| `tenant.attendance.viewAny` | View attendance records |
| `tenant.attendance.create` | Mark attendance |
| `tenant.attendance.update` | Edit attendance records |
| `tenant.attendance.delete` | Delete attendance |
| `tenant.medical-incident.viewAny` | View medical incidents |
| `tenant.medical-incident.create` | Create medical incident |
| `tenant.medical-incident.update` | Edit medical incident |
| `tenant.medical-incident.delete` | Delete medical incident |
| `tenant.student-report.view` | Access student reports |

### 15.3 Controller Split — Proposed

| New Controller | Responsibility | Methods Count |
|---------------|---------------|:-------------:|
| `StudentController` | Index, show, trash, restore, force-delete, export, send-credentials, toggle-status | ~10 |
| `StudentLoginController` | createStudentLogin, updateLogin, createParentLogin | 3 |
| `StudentDetailsController` | createStudentDetails, updateStudentDetails, updateProfile, updateStudentAddress, deleteStudentAddress | 5 |
| `GuardianController` | createParentDetails, updateParentDetails, deleteParent | 3 |
| `StudentSessionController` | createStudentSession, updateStudentSession, deleteStudentSession, getSessionData | 4 |
| `StudentHealthController` | createStudentMedicalDetails, updateHealthProfile, createPrevEduDetails, updateVaccinationRecord, deleteVaccinationRecord | 5 |
| `StudentDocumentController` | updateStudentDocument, deleteStudentDocument, getStudentDocumentData | 3 |
| `AttendanceController` | (keep as-is, add Gate checks) | 6 |
| `MedicalIncidentController` | (keep as-is, add Gate checks) | ~10 |
| `StudentReportController` | (keep as-is, add Gate checks) | 2 |
| `AttendanceCorrectionController` | 📐 New | 5 |
| `StudentPromotionController` | 📐 New | 4 |

---

## 16. Priority Fix Plan

### P0 — Critical (Fix Before Next Deployment)

| # | Action | File(s) | Detail |
|---|--------|---------|--------|
| 1 | Remove `is_super_admin` from student login creation | `StudentController.php:391,412` + `_student-login.blade.php:124,165-170` | Remove from validation rules and `User::create()` payload; never allow student creation to set this flag |
| 2 | Add `Gate::authorize()` to all `AttendanceController` methods | `AttendanceController.php` (all 6 methods) | Use `tenant.attendance.create`, `.update`, `.viewAny` etc.; register and wire `AttendancePolicy` |

### P1 — High (Fix This Sprint — estimated 8 person-days)

| # | Action | Effort |
|---|--------|--------|
| 3 | Create 10+ FormRequest classes (see Appendix 15.1) | 2 days |
| 4 | Split `StudentController` (~3000 lines) into 7 focused controllers | 3 days |
| 5 | Create `StudentService`, `AttendanceService`, `GuardianService` | 2 days |
| 6 | Add `Gate::authorize()` to all `create*` methods in `StudentController` | 0.5 days |
| 7 | Add `Gate::authorize()` to `StudentReportController` | 0.25 days |
| 8 | Delete `StudentController.bk` backup file | 0.1 days |
| 9 | Replace all `$request->all()` with `$request->validated()` throughout | 0.5 days |
| 10 | Write HTTP Feature tests for P0 regressions and core student CRUD | 2 days |

### P2 — Medium (Fix Next Sprint — estimated 5 person-days)

| # | Action | Effort |
|---|--------|--------|
| 11 | Add SoftDeletes to 6 models + DDL migrations for `deleted_at` columns | 1 day |
| 12 | Implement `AttendanceCorrectionController` + routes | 1.5 days |
| 13 | Implement Student Promotion workflow | 2 days |
| 14 | Register policies for Guardian, MedicalIncident, StudentDocument | 0.5 days |
| 15 | Fix cross-module route leakage (`student/create1` under school-setup prefix) | 0.25 days |

### P3 — Low (Backlog)

| # | Action |
|---|--------|
| 16 | Implement TC (Transfer Certificate) PDF generation |
| 17 | Add event dispatching for student lifecycle events (`StudentRegistration`) |
| 18 | Add CSV export option |
| 19 | Remove all commented-out code and debug comments |
| 20 | Encrypt Aadhar ID at rest |
| 21 | Queue Excel export for 1000+ students |
| 22 | Add attendance < 75% notification trigger |

---

## 17. V1 → V2 Delta

| Area | V1 | V2 |
|------|----|----|
| Security Section | Listed P0/P1 issues | Promoted P0 alert to document header; added AttendanceController gate detail per-method table |
| Data Model | Table list + relationships | Added DDL v2 column details, SoftDeletes gap table, constraint summary table, model status table |
| Routes | Key routes table | Full route inventory with Gate status column; cross-module leak noted |
| FR-STD-10 | Attendance: basic gaps | Expanded: period support, all 6 missing gate checks per-method, bulk transaction gap |
| FR-STD-11 | Corrections: mentioned | New dedicated FR with per-step status |
| FR-STD-13 | Promotion: "Missing" | New FR with 6 proposed requirements |
| FR-STD-14 | TC Generation: "Missing" | New FR with 4 proposed requirements |
| Section 8 Business Rules | Free-form notes | Structured rule table with Rule IDs |
| Section 9 Workflows | Not present in V1 | New: onboarding flow, correction workflow, portal access, promotion workflow |
| Section 12 Tests | 6 existing + missing list | Added 13 feature test scenarios + 5 unit test requirements with priorities |
| Section 14 Suggestions | Tech debt list | Split into 4 categories with rationale column |
| Section 15 Appendices | FormRequest rules (partial) | Added Gate reference table, Controller split proposal |
| 🆕 Attendance status values | Not documented | DDL-accurate: Present/Absent/Late/Half Day/Short Leave/Leave (6 values) |
| 🆕 `std_health_profiles` | Missing: vision, doctor contact, medications, dietary_restrictions fields | Documented from DDL v2 |
| 🆕 `std_guardians` DDL | Not fully documented | Added: `user_code`, `preferred_language` FK to `glb_languages` |
| 🆕 Orphan model note | Not documented | `StudentDetail` model: possible table name mismatch (`std_student_details` vs `std_student_profiles`) |
| 🆕 Backup file risk | Listed | Added NFR-STD-S3 for deletion of `StudentController.bk` |
| 🆕 Priority Fix Plan | Not present in V1 | New Section 16: structured P0/P1/P2/P3 fix plan with effort estimates |
| 🆕 `std_student_pay_log` | Not documented | Identified as orphan table — DDL exists, no model in STD module |
| 🆕 Guard junction DDL columns | Not fully documented | `can_pickup`, notification_preference ENUM (Email/SMS/WhatsApp/All) documented |
| 🆕 Attendance period column | Not documented | `attendance_period TINYINT` — 0 = daily; non-zero = period-wise; tied to system setting |
| 🆕 `dis_note` column | Not documented | `std_student_academic_sessions.dis_note TEXT NOT NULL` — dismissal/withdrawal note |

---

## 18. Open Questions

| # | Question | Stakeholder | Priority |
|---|----------|------------|---------|
| 1 | Is `StudentDetail` model intentionally separate from `StudentProfile`, or is it a rename artifact? The model's expected table `std_student_details` does not exist in DDL v2. | Tech Lead | P1 |
| 2 | Should `std_student_attendance` support period-wise attendance directly, or is that exclusively handled by the Timetable/LMS modules? The `attendance_period` column is present in DDL but the system setting `Period_wise_Student_Attendance` controls it. | Product | P1 |
| 3 | What is the intended scope of `std_student_pay_log`? Transport module references it, but there is no model in the StudentProfile module. Should this table be owned by Transport (TPT)? | Tech Lead | P2 |
| 4 | Student Promotion: should a failed-class student be auto-detected (exam results integration) or manually flagged? Does Examination module (EXM) feed into promotion decisions? | Product | P2 |
| 5 | For TC generation: which state education department format should be used? Is a standard national template required, or is it school-configurable? | Product | P2 |
| 6 | Should Aadhar ID be encrypted at rest immediately, or after a dedicated PII encryption feature is built platform-wide? | Tech Lead / Legal | P2 |
| 7 | `StudentReportController::combinedStudentReport` serves both `reports-mgt` and `reports/class-wise-student-strength` routes — is this intentional? The route name suggests different views. | Tech Lead | P3 |

