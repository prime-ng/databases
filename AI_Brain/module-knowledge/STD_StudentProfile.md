# Module Knowledge — STD: StudentProfile
**Seeded:** 2026-06-30 | **Agent:** Business Analyst
**Version:** 1.0

---

## Module Facts

| Attribute | Value |
|-----------|-------|
| Module Name | StudentProfile |
| Module Code | STD |
| Table Prefix | `std_*` |
| Laravel Module Path | `Modules/StudentProfile/` |
| Namespace | `Modules\StudentProfile` |
| DB Layer | **Tenant** — tenant_{uuid} (no `tenant_id` column; isolated by DB connection) |
| Domain Scope | Foundational master-data module — core identity provider for all other tenant modules |
| V2 Requirement | `STD_StudentProfile_Requirement.md` (2026-03-26); ~50% completion stated, actual higher |
| V1 Screen Specs | 6 BRD files in `StudentProfile_v2/` (`BRD-01` through `BRD-06`) |
| RBS Reference | Module C — Admissions & Student Lifecycle + Module E — Student Information System |
| CLAUDE.md Status | 100% listed (Tenant module) |
| Route Prefix | `student-profile/` (module routes) |
| Auth Middleware | `module:STUDENT` alias maps to `EnsureTenantHasModule` (confirmed in bootstrap/app.php line 31) |
| Photo Storage | Spatie MediaLibrary `student_photo` collection; disk: public; conversions: thumb/medium/large |
| PDF Export | DomPDF |
| Excel Export | Maatwebsite Excel |
| QR Code | SimpleSoftwareIO/QrCode |

### Verified File Counts (from `find Modules/StudentProfile -type f` — 2026-06-30)

| Component | Actual | V2 Said | Notes |
|-----------|--------|---------|-------|
| Controllers (desktop) | 7 | 5 | StudentController (4222 lines), AttendanceController, MedicalIncidentController, StudentProfileController (stub), StudentReportController, StdLeaveController, StudentLeaveTypeController |
| Controllers (mobile) | 2 | — | Mobile/AttendanceController, Mobile/AdminStudentLeaveController |
| Models | 18 | 14 | +4 new: LeaveApplication, LeaveApplicationDocument, LeaveApplicationRemark, LeaveType (all leave-management beyond V2 scope) |
| FormRequests | 1 | 0 | StudentLeaveTypeRequest only — all student-facing routes still use inline validation |
| Policies | 2 registered | 1 active | StudentPolicy + AttendancePolicy registered in StudentProfileServiceProvider |
| Services | 1 | 0 | LeaveService only — no StudentService, AttendanceService, GuardianService |
| Exports | 1 | — | StudentsExport (Excel) |
| Emails | 1 | — | StudentLoginCreated Mailable |
| Helpers | 1 | — | StudentProfileHelper (getProgressPercentage, getFirstIncompleteTab) |
| Tests | 0 HTTP Feature | 6 Dusk + 1 Unit | Zero HTTP Feature tests; Browser/Dusk tests exist outside module folder |
| Seeders | 6 | — | StudentProfileDatabaseSeeder, StudentSeeder, StudentGuardianSeeder, StudentHealthProfileSeeder, StudentMedicalIncidentSeeder, StudentVaccinationSeeder |
| Views (blade files) | ~120 | — | Student CRUD (with 8 tab partials for create + edit), attendance, medical incidents, leave management, reports, email, exports |
| Data Providers | 1 | — | StudentIdCardDataProvider |
| Migrations | 19 | 14 | 5 additional: std_leave_types, std_leave_applications, std_leave_application_documents, std_leave_application_remarks, std_student_opted_subjects |

---

## Module Score Summary (V2 Gap Analysis 2026-03-26, updated with 2026-06-30 code verification)

| Area | Score | Key Issue |
|------|-------|-----------|
| DB Integrity | 6/10 | 5 tables missing SoftDeletes; current_flag not true GENERATED STORED column |
| Route Integrity | 8/10 | EnsureTenantHasModule IS applied; some routes still use wrong permission prefix |
| Controller Quality | 4/10 | 4222-line monolith; wrong permission prefix in ~6 methods; is_super_admin not removed |
| Model Quality | 5/10 | No Aadhar encryption; hard cross-module imports create reversed coupling |
| Service Layer | **2/10** | 1 LeaveService only; no StudentService, AttendanceService, GuardianService |
| FormRequest Coverage | **1/10** | 1 FormRequest for leave types; zero for all student-facing create/update routes |
| Policy / Auth | 6/10 | 2 policies registered and used; 5 resource areas have no policy (Guardian, MedicalIncident, Document, Leave, LeaveType) |
| Activity Logging | **0/10** | activityLog() commented out in StudentController; missing from leave controllers |
| Test Coverage | **1/10** | Zero HTTP Feature tests (6 Browser/Dusk + 1 Unit exist) |
| Security | 3/10 | is_super_admin P0 not fixed; Aadhar plaintext; wrong permission prefixes |
| Performance | 6/10 | Synchronous Excel export for large datasets; Student model eager-loads risk |
| **Overall** | **4.2/10** | Lower than V2's 50% implied — security and audit gaps are critical |

---

## DDL Table Inventory (19 std_* tables)

### Core Student Tables

| Table | Model | SoftDeletes | GENERATED Column | PII Sensitivity | DDL Issues |
|-------|-------|:-----------:|:----------------:|-----------------|------------|
| `std_students` | `Student` | YES (created) | No | HIGH: aadhar_id (unencrypted), DOB | No encrypted cast on aadhar_id |
| `std_student_profiles` | `StudentProfile` | YES (added 2026-06-18) | No | HIGH: bank_account_no, religion, caste_category | Bank account stored plaintext |
| `std_student_addresses` | `StudentAddress` | YES (added 2026-06-18) | No | Medium | — |
| `std_guardians` | `Guardian` | YES (added 2026-06-18) | No | HIGH: mobile_no (UNIQUE), preferred_language | — |
| `std_student_guardian_jnt` | `StudentGuardianJnt` | — | No | Low | UNIQUE constraint on deleted_at included in index |
| `std_student_academic_sessions` | `StudentAcademicSession` | NO | `current_flag` — **NOT GENERATED; regular INT with UNIQUE** | Low | current_flag must be manually set by application |
| `std_previous_education` | `PreviousEducation` | YES (added 2026-06-18) | No | Low | — |
| `std_student_documents` | `StudentDocument` | NO | No | Medium | Missing SoftDeletes trait + deleted_at |
| `std_health_profiles` | `StudentHealthProfile` | NO | No | HIGH: blood_group, allergies, chronic_conditions, medications, vision, doctor_name | Missing SoftDeletes; medical data plaintext |
| `std_vaccination_records` | `VaccinationRecord` | NO | No | Medium | Missing SoftDeletes |
| `std_medical_incidents` | `MedicalIncident` | YES (added 2026-06-18) | No | HIGH: incident description, first aid, parent_notified | Medical data plaintext |

### Attendance Tables

| Table | Model | SoftDeletes | DDL Issues |
|-------|-------|:-----------:|------------|
| `std_student_attendance` | `StudentAttendance` | NO | Missing SoftDeletes; attendance_period TINYINT (0=daily) |
| `std_attendance_corrections` | `StudentAttendanceCorrection` | NO | Controller/routes not implemented despite model existing |

### Leave Management Tables (beyond V2 scope — added post V2)

| Table | Model | SoftDeletes | Notes |
|-------|-------|:-----------:|-------|
| `std_leave_types` | `LeaveType` | YES | code, max_days_per_application, max_days_per_year, requires_document, allow_half_day, advance_notice_days |
| `std_leave_applications` | `LeaveApplication` | — | Student leave application record |
| `std_leave_application_documents` | `LeaveApplicationDocument` | — | Supporting documents for leave |
| `std_leave_application_remarks` | `LeaveApplicationRemark` | — | Staff remarks on leave applications |

### Supplementary Tables

| Table | Model | SoftDeletes | Notes |
|-------|-------|:-----------:|-------|
| `std_student_opted_subjects` | `StudentOptedSubject` | — | Optional subject choices per student-session; beyond V2 scope |
| `std_student_pay_log` | `StudentPayLog` (in Transport module) | — | **Orphan** — DDL exists, no STD model; owned/referenced by Transport module |

### Critical Column Detail — `std_student_academic_sessions`

| Column | Type | Notes |
|--------|------|-------|
| `is_current` | BOOLEAN | 1 = active enrollment |
| `current_flag` | INT NULLABLE | **NOT GENERATED STORED** — application must set `current_flag = student_id` when `is_current = 1`, NULL otherwise |
| `UNIQUE uq_studentSessions_currentFlag` | on `current_flag` | Enforces one current session per student via NULL-exclusion |
| `UNIQUE uq_std_acad_sess_student_session` | on `(student_id, academic_session_id)` | Prevents duplicate enrollment in same year |
| `session_status_id` | FK → sys_dropdowns | Status: ACTIVE / PROMOTED / LEFT / SUSPENDED / ALUMNI / WITHDRAWN |
| `dis_note` | TEXT NOT NULL | Dismissal/withdrawal note — was undocumented in V1 |
| `count_for_timetable` | BOOLEAN | Timetable eligibility flag |
| `count_as_attrition` | BOOLEAN | HR analytics flag |

### Critical Column Detail — `std_students`

| Column | Type | PII | Issue |
|--------|------|-----|-------|
| `aadhar_id` | VARCHAR | **Sensitive PII** | No Laravel `encrypted` cast — stored in plaintext; UIDAI compliance violation |
| `admission_no` | VARCHAR | Internal | UNIQUE per tenant |
| `student_qr_code` | VARCHAR | — | Must not directly expose admission_no (should use hash/UUID) |

---

## Known Gaps & Open Issues

### P0 — Critical (Security / Production Blockers)

| ID | Issue | Location |
|----|-------|---------|
| SEC-STD-01 | **`is_super_admin` NOT removed from `createStudentLogin()`** — `'is_super_admin' => 'nullable'` at line 610 and `'is_super_admin' => $request->boolean('is_super_admin')` in `User::create()` at line 631. Any user reaching this endpoint via a crafted POST request can elevate themselves to super-admin. View `_student-login.blade.php` still exposes the toggle. **Must be removed before any deployment.** | `StudentController.php:610,631` + view `_student-login.blade.php` |
| SEC-STD-02 | **Wrong permission prefix `school-setup.student.*`** used instead of `tenant.student.*` at minimum 5 active Gate::authorize calls (lines 1090, 1212, 1316, 1892, 2528) in StudentController. These calls check a non-existent permission gate — legitimate users are either denied or the gate fails open, depending on policy resolution. Inconsistent with the established `tenant.*` namespace. | `StudentController.php` multiple methods |
| SEC-STD-03 | **Aadhar ID stored in plaintext** — `aadhar_id` is in `Student::$fillable` with no `encrypted` cast. Indian national ID (12-digit UIDAI-issued) is legally protected PII; must use Laravel `'aadhar_id' => 'encrypted'` cast. Encrypted columns cannot be searched directly — queries must load-and-compare, or use a deterministic HMAC index. | `Models/Student.php` `$casts` |

### P1 — High

| ID | Issue | Location |
|----|-------|---------|
| AUD-STD-04 | **`activityLog()` commented out for all student lifecycle events** — delete, restore, and force-delete actions in StudentController (lines 3852, 3916, 3979) have activityLog calls wrapped in comments. School student records are legally auditable; absent audit trail is a compliance gap. MedicalIncidentController DOES call activityLog (confirmed). | `StudentController.php:3852,3916,3979` |
| GAP-STD-05 | **Zero FormRequests for all student-facing routes** — `createStudentLogin`, `createStudentDetails`, `createParentDetails`, `createStudentSession`, `createStudentMedicalDetails`, `updateStudentDetails`, `updateHealthProfile` all use inline `Validator::make($request->all())` and `$request->all()` (not `$request->validated()`). Mass assignment risk, no centralized rules, untestable. V2 Appendix 15.1 lists 12 FormRequest classes needed. | All StudentController create/update methods |
| GAP-STD-06 | **StdLeaveController Gate::authorize commented out** — leave index and review methods have authorization calls commented at lines 25 and 250. Any `module:STUDENT` user can view all leave applications and approve/reject them without authorization. | `StdLeaveController.php:25,250` |
| GAP-STD-07 | **No service layer for student business logic** — StudentController is 4222 lines containing login creation, profile updates, session management, health records, document uploads, attendance, guardian management, and exports all in one controller class. V2 proposes split into 7 controllers + 3 services. | `StudentController.php` |
| GAP-STD-08 | **No policies for Guardian, MedicalIncident, StudentDocument, LeaveApplication, LeaveType** — only StudentPolicy and AttendancePolicy are registered. All other resource areas (guardian CRUD, document verify, medical incident management, leave management) have no policy coverage. | `StudentProfileServiceProvider.php` |
| BUG-STD-09 | **`activityLog()` missing from StdLeaveController and StudentLeaveTypeController** — leave approvals and type configuration changes have no audit log. | `StdLeaveController.php`, `StudentLeaveTypeController.php` |
| PERF-STD-10 | **Synchronous Excel export for large student datasets** — `StudentsExport` runs synchronously; for 1000+ student schools this risks PHP memory limit exhaustion and request timeout. Must use Laravel Excel's `ShouldQueue` interface. | `Exports/StudentsExport.php` |

### P2 — Medium

| ID | Issue | Location |
|----|-------|---------|
| BUG-STD-11 | **`current_flag` not a true GENERATED STORED column** — migration implements it as a regular nullable integer. V2 spec and DDL v4 describe it as `GENERATED ALWAYS AS (CASE WHEN is_current = 1 THEN student_id ELSE NULL END) STORED`. Application code must manually set `current_flag = student_id` when setting `is_current = 1`. Any code path that updates `is_current` without updating `current_flag` breaks the uniqueness enforcement silently. | `2026_06_15_151307_create_std_student_academic_sessions_table.php` |
| DDL-STD-12 | **SoftDeletes missing from 5 tables** — `std_student_attendance`, `std_student_documents`, `std_health_profiles`, `std_vaccination_records`, `std_student_academic_sessions` have no `deleted_at` column. Models have the SoftDeletes trait but calling `->delete()` will fail or silently not soft-delete depending on column existence. The 2026-06-18 migration only addressed 3 tables (previous_education, addresses, profiles) + guardians + medical_incidents separately. | DDL + migrations |
| ARCH-STD-13 | **Student model hard-imports downstream modules** — `Student.php` imports `Modules\StudentFee\Models\FeeStudentAssignment`, `Modules\Transport\Models\StudentPayLog`, `Modules\StudentPortal\Models\ExamAttempt`, `Modules\StudentPortal\Models\ExamResult`. StudentProfile should be a pure data provider; these downstream modules should own their FK relationships. If StudentFee, Transport, or StudentPortal modules are disabled, Student model throws class-not-found errors. | `Models/Student.php` lines 13, 16, 18 |
| GAP-STD-14 | **Attendance Correction workflow (FR-STD-11) not implemented** — `std_attendance_corrections` table and `StudentAttendanceCorrection` model exist but no controller, no routes, no approval workflow. The three-step correction process (student/parent → class teacher → admin) is fully absent. | Missing controller + routes |
| GAP-STD-15 | **Student Promotion wizard (FR-STD-13) not implemented** — no `StudentPromotionController`, no service, no routes. Year-end bulk promotion to next class section is a critical school workflow. | Not started |
| GAP-STD-16 | **Transfer Certificate generation (FR-STD-14) not implemented** — no TC PDF generation, no TC serial number scheme, no TC document storage workflow. `tc_issued` column migration exists (`2026_06_15_155842_add_tc_issued_to_std_students_table`) so the flag is present but the full workflow is absent. | Not started |
| ARCH-STD-17 | **StudentController incorrect permission prefix** on multiple commented-out methods suggests they were copied from SchoolSetup and never corrected. Even the active calls (lines 1090, 1212, 1316) use `school-setup.student.*`. | `StudentController.php` |
| SEC-STD-18 | **Medical records stored in plaintext** — `std_health_profiles` contains blood_group, allergies, chronic_conditions, medications, vision data; `std_medical_incidents` contains incident descriptions. These are health data under Indian privacy norms. No encryption or access logging beyond the general Gate check. | `Models/StudentHealthProfile.php`, `Models/MedicalIncident.php` |

### P3 — Backlog

| ID | Issue |
|----|-------|
| GAP-STD-19 | `std_student_pay_log` is an orphan STD table — referenced by Transport module with no STD model; ownership ambiguity must be resolved |
| GAP-STD-20 | Bulk student import (Excel/CSV) not implemented — no import class or job; required for onboarding large schools |
| GAP-STD-21 | CSV export not available (only Excel + PDF) |
| GAP-STD-22 | Attendance < 75% automated notification trigger not implemented (BR-STD-20) |
| GAP-STD-23 | `edit.blade.bkp` backup file in views directory should be removed |
| GAP-STD-24 | `StudentController.php` line `// dd($request->all());s` debug comment at attendance line — cleanup |
| GAP-STD-25 | QR code value may expose `admission_no` directly — should use hash/UUID (BR-STD-06) |
| GAP-STD-26 | APAAR ID (12-digit) validation not yet enforced in any FormRequest (BR-STD-05) |
| GAP-STD-27 | Profile completion % computed on-the-fly — not scalable for 10,000+ student queries; consider caching or computed column |
| GAP-STD-28 | `StudentProfile` model vs `StudentDetail` model boundary overlap — V2 notes `StudentDetail` expects `std_student_details` table which does not exist in DDL; only `std_student_profiles` exists |
| GAP-STD-29 | Zero HTTP Feature tests — highest priority: SEC-STD-01 regression, attendance auth, student CRUD lifecycle |

---

## Feature Area Status (as of 2026-06-30)

| # | Feature | FR | Status | Notes |
|---|--------|----|--------|-------|
| 1 | Student List & Search | FR-STD-01 | 🟢 90% | Pagination, search, filter, export all work; CSV export missing |
| 2 | Student Login Creation (Tab 1) | FR-STD-02 | 🔴 60% | Core works; **P0: is_super_admin not removed**; no FormRequest; no Gate on createStudentLogin |
| 3 | Student Details (Tab 2) | FR-STD-03 | 🟡 75% | CRUD works; no FormRequest; some Gates missing or wrong prefix |
| 4 | Guardian Management (Tab 3) | FR-STD-04 | 🟡 75% | CRUD works; no FormRequest; no Guardian policy |
| 5 | Academic Session (Tab 4) | FR-STD-05 | 🟡 75% | CRUD works; current_flag not auto-computed; no FormRequest |
| 6 | Previous Education (Tab 5) | FR-STD-06 | 🟢 85% | CRUD works; SoftDeletes added |
| 7 | Student Documents | FR-STD-07 | 🟡 70% | CRUD works; no policy; missing SoftDeletes on table |
| 8 | Health Profile | FR-STD-08 | 🟡 70% | Upsert works; no FormRequest; missing SoftDeletes; plaintext medical data |
| 9 | Medical Incidents | FR-STD-09 | 🟢 85% | Full CRUD + SoftDeletes + activityLog; Gate review needed |
| 10 | Daily Attendance | FR-STD-10 | 🟢 85% | Gate::authorize IS present on all methods (V2 gap fixed); no FormRequest; no bulk transaction |
| 11 | Attendance Corrections | FR-STD-11 | 🔴 10% | Table + model exist; controller/routes/workflow absent |
| 12 | Student Status Management | FR-STD-12 | 🟢 95% | Full lifecycle (toggle/delete/restore/force/bulk/trash) implemented |
| 13 | Student Promotion | FR-STD-13 | ❌ 0% | Not started |
| 14 | Transfer Certificate | FR-STD-14 | ❌ 5% | tc_issued flag added; full workflow absent |
| 15 | Student Reports | FR-STD-15 | 🟡 70% | 3 reports exist; Gate review needed |
| 16 | Profile Completion Tracking | FR-STD-16 | 🟢 90% | Helper + attribute accessor implemented; service extraction proposed |
| 17 | Student Credential Management | FR-STD-17 | 🟢 85% | Send credentials + welcome email work |
| 18 | Leave Management | (beyond V2) | 🟡 60% | Leave types CRUD + leave review workflow built; Gates commented out; no activityLog |
| 19 | EnsureTenantHasModule | — | 🟢 100% | `module:STUDENT` = EnsureTenantHasModule — applied to all routes |
| 20 | Service Layer | — | 🔴 5% | LeaveService only; no student-core services |
| 21 | FormRequests | — | 🔴 5% | StudentLeaveTypeRequest only; 12+ needed |
| 22 | Activity Logging | — | 🔴 25% | MedicalIncidentController has it; StudentController has it commented out; LeaveControllers missing |
| 23 | Test Coverage (Feature) | — | ❌ 0% | Zero HTTP Feature tests |

---

## Cross-Module Dependencies

**STD is the master-data provider for the platform. This section is the most critical part of this knowledge file.**

### STD Consumes From (Inbound)

| Source Module | Data / Table | Why |
|---------------|-------------|-----|
| SystemConfig (SYS) | `sys_users`, `sys_dropdowns`, `sys_dropdown_table` | User creation for student/parent logins; religion/caste/status/session_status lookups |
| SchoolSetup (SCH) | `sch_class_section_jnt`, `sch_org_academic_sessions_jnt`, `sch_subject_groups`, `Organization`, `User` models | Session enrollment; academic year; class assignment |
| GlobalMaster (GLB) | `glb_cities`, `glb_languages` | Address city lookup; guardian preferred language |
| Prime (PRM) | `AcademicSession` model | Academic session context |
| Spatie MediaLibrary | `sys_media` | Student photo storage; document file references |

### STD Provides To (Outbound — these modules DEPEND on std_* data)

| Consumer Module | Mechanism | Data Provided | Coupling Risk |
|----------------|-----------|--------------|---------------|
| StudentFee (FIN) | FK + service reads | `std_students.id`, `std_student_guardian_jnt.is_fee_payer` | Fee assignment, invoice, sibling discount | **HIGH** |
| StudentPortal (STP) | All std_* tables | Full student profile read-only views | **HIGH** — STP reads virtually every std_* table |
| SmartTimetable (TT) | `std_student_academic_sessions.count_for_timetable` | Timetable slot generation | Medium |
| Transport (TPT) | `std_students`, `std_student_pay_log` | Student transport allocation; payment logs | Medium |
| LmsHomework | `std_student_academic_sessions.class_section_id` | Homework assignment by class | Medium |
| LmsExam | `std_student_academic_sessions`, `std_students` | Exam student group membership | Medium |
| MarksheetGeneration (MSG) | `std_students`, `std_student_academic_sessions` | Marksheet generation; student-session context | **HIGH** |
| BehaviouralAssessment (BA) | `std_students` | Student remark tracking | Low |
| Recommendation (REC) | `std_students` | Recommendations per student | Low |
| Notification | `std_student_guardian_jnt.can_receive_notifications`, `notification_preference` | Guardian notification dispatch | Medium |

### Reversed Coupling Warning

`Student.php` currently IMPORTS from downstream modules:

| Import | Line | Problem |
|--------|------|---------|
| `Modules\StudentFee\Models\FeeStudentAssignment` | 13 | If StudentFee disabled, Student model breaks |
| `Modules\Transport\Models\StudentPayLog` | 16 | If Transport disabled, Student model breaks |
| `Modules\StudentPortal\Models\ExamAttempt` | 18 | If StudentPortal disabled, Student model breaks |
| `Modules\StudentPortal\Models\ExamResult` | line 242 inline | Same risk |

These downstream modules should own their FK relationships pointing to `std_students.id`. `Student.php` must not import from modules that depend on it.

---

## Permission Architecture

### Registered Policies (2 — confirmed in StudentProfileServiceProvider.php)

| Policy | Model | Permission Prefix | Registration |
|--------|-------|------------------|-------------|
| `StudentPolicy` | `Student` | `tenant.student.*` | `Gate::policy(Student::class, StudentPolicy::class)` — line 52 |
| `AttendancePolicy` | `StudentAttendance` | `tenant.attendance.*` | `Gate::policy(StudentAttendance::class, AttendancePolicy::class)` — line 53 |

### Unregistered / Missing Policies

| Resource | Policy Needed | Current State |
|----------|-------------|---------------|
| Guardian | `GuardianPolicy` | No policy; no registration |
| StudentDocument | `StudentDocumentPolicy` | No policy; no registration |
| MedicalIncident | `MedicalIncidentPolicy` | No policy; no registration |
| LeaveApplication | `LeaveApplicationPolicy` | No policy; no registration |
| LeaveType | `LeaveTypePolicy` | No policy; no registration |

### Permission Key Reference (from V2 Appendix 15.2)

| Permission Key | Description |
|---------------|-------------|
| `tenant.student.viewAny` | List all students |
| `tenant.student.view` | View single student profile |
| `tenant.student.create` | Create student login + details |
| `tenant.student.update` | Edit student records |
| `tenant.student.delete` | Soft/force delete, restore |
| `tenant.student.export` | Export Excel/PDF |
| `tenant.attendance.viewAny` | View attendance records |
| `tenant.attendance.create` | Mark attendance |
| `tenant.attendance.update` | Edit attendance |
| `tenant.attendance.delete` | Delete attendance |
| `tenant.medical-incident.viewAny` | View medical incidents |
| `tenant.medical-incident.create` | Create medical incident |
| `tenant.medical-incident.update` | Edit medical incident |
| `tenant.medical-incident.delete` | Delete medical incident |
| `tenant.student-report.view` | Access student reports |

### Wrong Prefix Bug (Active P0 — active calls using wrong gate)

StudentController contains active `Gate::authorize('school-setup.student.*')` calls at approximately lines 1090, 1212, 1316, 1892, 2528. All should use `tenant.student.*` prefix consistent with the permission key reference above.

---

## Admission Number (emp_code) Generation

| Attribute | Value |
|-----------|-------|
| Format | `STD-{YYYY}-{000001}` (year-based sequential, zero-padded to 6 digits) |
| Location | `StudentController::createStudentLogin()` |
| Stored In | `sys_users.emp_code` |
| Business Rule | BR-STD-04: Cannot be manually set at student creation; auto-assigned |
| Uniqueness | Unique per tenant (no DDL constraint confirmed; enforced at application level) |
| Gap | No FormRequest validation prevents supplying a custom value in POST payload |
| Concurrency Gap | Sequential counter not wrapped in `lockForUpdate()` — duplicate codes possible under concurrent admission registration |

---

## PII / Data Protection

| Field | Table | Sensitivity | Current State | Required Action |
|-------|-------|-------------|---------------|----------------|
| `aadhar_id` | `std_students` | **Sensitive PII — UIDAI** | Plaintext in `$fillable`, no cast | Add `'aadhar_id' => 'encrypted'` to `$casts`; DDL column must be VARBINARY or longer VARCHAR to hold encrypted value |
| `bank_account_no` | `std_student_profiles` | **Financial PII** | Stored plaintext | Encrypt cast |
| `dob` | `std_students` | Personal | Plaintext — standard practice | Acceptable |
| `blood_group` | `std_health_profiles` | Health | Plaintext | Accept; flag if medical sensitivity rises |
| `allergies` | `std_health_profiles` | Health — sensitive | Plaintext | Consider encryption or access logging |
| `chronic_conditions` | `std_health_profiles` | Health — sensitive | Plaintext | Consider encryption or access logging |
| `medications` | `std_health_profiles` | Health — sensitive | Plaintext | Consider encryption or access logging |
| `mobile_no` | `std_guardians` | Personal | Plaintext (UNIQUE key — cannot encrypt without deterministic HMAC) | Acceptable if DB access is secured |
| Incident descriptions | `std_medical_incidents` | Health | Plaintext | Access logging via activityLog at minimum |
| Student photo | `sys_media` (MediaLibrary) | Personal | Managed by Spatie MediaLibrary; disk: public | Review public disk exposure for photo URL guessing |

**Encryption Implementation Note:** Once `aadhar_id` is encrypted, it cannot be filtered/searched by value directly via SQL. Application queries that filter by Aadhar (e.g., duplicate-check on admission) must load-and-compare or use a separate deterministic HMAC column for indexed lookups.

---

## Route Registration Pattern

All functional routes registered in module-level `Modules/StudentProfile/routes/web.php` under:
```
Route::middleware('module:STUDENT')->group(function () { ... })
```

`module:STUDENT` resolves to `EnsureTenantHasModule` (confirmed in `bootstrap/app.php` line 31).

The module routes are loaded by `StudentProfileServiceProvider` / `RouteServiceProvider`.

**Central `routes/tenant.php` involvement:**
- Line 50: imports `StudentController` use statement
- Lines 210-217: Comment notes STD routes moved to module's `routes/web.php`
- Line 343: `SeederController::seedAdmission` route remains in tenant.php

**No route prefix is set** at group level in `web.php` — individual routes define their own paths starting with `/student/`, `/attendance/`, `/session/`, etc.

**Key Route Issues:**
- `reports-mgt` and `reports/class-wise-student-strength` both resolve to `StudentReportController::combinedStudentReport` — same handler for two conceptually different report URLs
- Mobile routes registered in separate `Modules/StudentProfile/routes/mobile_api.php` — not covered by `module:STUDENT` middleware (verify independently)
- `student-leave/` routes have Gate::authorize commented out

---

## V1 Screen Spec Inventory (6 BRD files)

| File | Coverage |
|------|---------|
| `BRD-01_Student_Onboarding_and_Core_Profile.md` | Student login creation, personal details, identity documents |
| `BRD-02_Family_and_Guardian_Management.md` | Guardian records, junction flags, portal access granting |
| `BRD-03_Academic_Journey_and_Document_Management.md` | Session assignment, previous education, document uploads |
| `BRD-04_Health_Medical_and_Attendance.md` | Health profile, vaccination, medical incidents, daily attendance |
| `BRD-05_Student_Leave_Management.md` | Leave types, application workflow, remarks, documents |
| `BRD-06_Reports_and_Dashboard.md` | Admission register, student strength, medical profile reports |

Note: These are BRD-format documents (Business Requirements Documents), not traditional per-screen specs. Richer than V1 specs for most modules.

---

## Design Decisions Made

| Decision | Detail | Source |
|----------|--------|--------|
| `module:STUDENT` = EnsureTenantHasModule | Confirmed: alias registered in bootstrap/app.php. All STD routes protected. | Code verification 2026-06-30 |
| AttendanceController Gate::authorize present | V2 reported zero authorization; code shows Gate::authorize IS called (lines 21, 53, 141, 216, 240, 306). Gap was addressed after V2 was written. | Code verification 2026-06-30 |
| `current_flag` not GENERATED STORED | DDL v4 specifies GENERATED; migration uses plain nullable INT. Application must manually set current_flag. The unique constraint still functions via NULL exclusion. | Migration verification 2026-06-30 |
| Leave management within STD module | Student Leave (std_leave_types, std_leave_applications, etc.) implemented inside StudentProfile module, not a separate module. BRD-05 exists for it. | Code + routes 2026-06-30 |
| Photo: Spatie MediaLibrary | `student_photo` collection with three size conversions (thumb 100×100, medium 300×300, large 600×600). Disk: public. | Student model |
| `std_student_pay_log` ownership | Table exists in tenant migrations but no STD model — Transport module imports StudentPayLog. Ownership is ambiguous (Open Question #3 in V2). | Code + migration |
| SoftDeletes migration approach | Added via alter-table migrations in 2026-06 batch rather than in original creates. Affects: guardians, medical_incidents, previous_education, addresses, student_profiles. Still missing from 5 tables. | Migration review 2026-06-30 |

---

## Lessons Learned

- [2026-06-30 | Business Analyst] V2 reported AttendanceController as a P0 gap (zero Gate::authorize). Code verification shows Gate::authorize IS present on all 6 attendance methods (lines 21, 53, 141, 216, 240, 306). Always verify code before trusting a V2 report's gap status — the code may have been updated after V2 was written.
- [2026-06-30 | Business Analyst] StudentProfile is architecturally inverted in Student.php: it imports from StudentFee, Transport, and StudentPortal — three modules that depend on it. This is a class-loading risk (module disabled = Student model breaks) and an architecture violation. The correct pattern: downstream modules own their FK relationships pointing at std_students.id, never imported back.
- [2026-06-30 | Business Analyst] `module:STUDENT` middleware is not a custom middleware — it IS `EnsureTenantHasModule` via an alias. Do not flag it as missing just because the class name doesn't appear directly. Always check bootstrap/app.php or Kernel.php for alias resolution.
- [2026-06-30 | Business Analyst] `current_flag` in std_student_academic_sessions is NOT a GENERATED STORED column despite V2/DDL saying so. The migration shows a regular nullable INT with a unique constraint. Any code change that updates `is_current` must also set `current_flag` manually; forgetting breaks the one-current-session guarantee at application level while appearing to succeed at DB level.
- [2026-06-30 | Business Analyst] activityLog() commented out in StudentController while MedicalIncidentController calls it correctly. This is the most common pattern across modules — activity logging is added to secondary controllers but the monolithic StudentController was never cleaned up. Always grep individually per controller.
- [2026-06-30 | Business Analyst] Wrong permission prefix (`school-setup.student.*` instead of `tenant.student.*`) in StudentController active Gate calls is a silent P0: the wrong gate key means either a different policy is consulted or the check fails open/closed unpredictably. This type of bug does not throw errors — it silently applies wrong authorization.

---

## Pending Next Steps

**P0 Immediate:**
1. Remove `is_super_admin` from `StudentController::createStudentLogin()` validation (line 610) and `User::create()` payload (line 631); remove corresponding view toggle
2. Fix wrong permission prefix — replace all `school-setup.student.*` active Gate calls with `tenant.student.*`
3. Add `'aadhar_id' => 'encrypted'` to `Student::$casts`; add bank_account_no encryption to StudentProfile model

**P1 This Sprint:**
4. Uncomment or re-implement `activityLog()` calls in StudentController (delete/restore/force-delete at lines 3852, 3916, 3979)
5. Uncomment Gate::authorize in `StdLeaveController` (lines 25, 250)
6. Add activityLog() to StdLeaveController and StudentLeaveTypeController
7. Create minimum required FormRequests: CreateStudentLoginRequest (no is_super_admin), CreateStudentDetailsRequest, CreateGuardianRequest, StoreAttendanceRequest, StoreBulkAttendanceRequest
8. Add SoftDeletes to 5 missing tables: std_health_profiles, std_student_academic_sessions, std_student_attendance, std_student_documents, std_vaccination_records

**P2 Next Sprint:**
9. Remove hard cross-module imports from Student.php (StudentFee, Transport, StudentPortal)
10. Implement AttendanceCorrectionController + routes (model + table already exist)
11. Register missing policies: GuardianPolicy, MedicalIncidentPolicy, StudentDocumentPolicy, LeaveApplicationPolicy
12. Convert StudentController Excel export to queued via ShouldQueue
13. Begin StudentController refactor: split into 7 focused controllers per V2 Appendix 15.3

**P3 Backlog:**
14. Implement Student Promotion wizard (FR-STD-13)
15. Implement TC PDF generation workflow (FR-STD-14)
16. Add bulk import (Excel) for student onboarding
17. Remove `edit.blade.bkp` backup file
18. Write HTTP Feature tests: SEC-STD-01 regression, attendance auth, student CRUD lifecycle, guardian duplicate mobile

---

## FRD Summary (produced 2026-06-30)

| Artifact | File | Path |
|----------|------|------|
| FRD | `STD_FRD_2026-06-30.md` | `0-FRD_Documents/` |
| Complete Analysis Pack | `STD_FRD_Complete_2026-06-30.md` | `0-FRD_Documents/` |
| Requirement Conditions Catalog | `STD_Conditions.md` | `5-Requirement_Conditions/` |

| Counter | Count | Notes |
|---------|-------|-------|
| REQ-STD- | 26 | P0=12, P1=14 |
| BR-STD- | 39 | 39 business rules; 43 testable conditions in STD_Conditions.md |
| Workflows | 6 | New Admission, Session Transition, Parent Portal Access, Attendance Correction, Leave Application FSM, Archive/Restore |
| FSMs | 3 | Leave Application (8 states), Attendance Correction (5 states), Session Status (5 states) |
| RPT-STD- | 3 | Admission Register, Student Strength, Medical Profile |
| ENH-STD- | 7 | Promotion Wizard, TC Generation, Bulk Import, CSV Export, <75% Notification, ID Card, REST API |
| NFR-STD- | 22 | Performance (5), Security (8), Usability (3), Compliance (5), Scalability (1) |
| Risks | 10 | 4 High Impact/High Likelihood + 6 Medium |
| RTM Rows | 26 | All 26 REQs traced to BR, screen, workflow, code status |
| User Stories | 6 | US-STD-001 through US-STD-006 with Gherkin AC (key P0/P1 REQs) |
| Gap Summary | P0=3, P1=9, P2=9, P3=9 | Total 30 identified gaps |

---

## Version History

| Version | Date | Agent | Changes |
|---------|------|-------|---------|
| 1.0 | 2026-06-30 | Business Analyst | Initial seed — V2 requirement (full read, 1000-line doc) + V1 screen specs (6 BRD files) + full filesystem verification; 19 std_* tables counted; Gate status verified in code vs V2 claims (AttendanceController gap resolved); is_super_admin confirmed still present; cross-module reversed coupling documented |
| 1.1 | 2026-06-30 | Business Analyst | FRD + Complete Analysis Pack + Conditions Catalog produced. FRD Summary block added above. 26 REQ, 39 BR, 43 conditions, 3 FSMs, 10 risks, 30 gaps catalogued. |
| 1.2 | 2026-06-30 | Technical Auditor | Mode X Complete Audit. Health 40/100 P0-capped. NO-GO. 15 new Lessons Learned added. Pending Next Steps updated with confirmed P0/P1/P2 findings and stale correction table. |

---

## Mode X Audit Lessons Learned (2026-06-30 — Technical Auditor)

- **[SEC-STD-01 CONFIRMED P0]** `is_super_admin` is still writable in createStudentLogin(): line 610 `'is_super_admin' => 'nullable'` and line 631 `'is_super_admin' => $request->boolean('is_super_admin')` in User::create. UI toggle in `_student-login.blade.php:124`. Any school admin reaching this endpoint can escalate any user to platform super-admin.
- **[SEC-STD-02 CONFIRMED P0]** Wrong Gate prefix at 4 live lines: 1090, 1212, 1892 use `school-setup.student.update`; line 1316 uses `school-setup.student.delete`. Permission `school-setup.student.*` does not exist in Spatie — throws 403 for all users including super-admins. Fix: replace with `tenant.student.update/delete`.
- **[SEC-STD-03 CONFIRMED P1]** `std_students.aadhar_id` — no `encrypted` cast in Student model. Plaintext in DB dumps violates DPDPA 2023. Fix: add `'aadhar_id' => 'encrypted'` to `$casts`; use HMAC blind index for search.
- **[GAP-STD-06 CONFIRMED P1]** StdLeaveController lines 25 and 250 have Gate::authorize commented out. Leave index and review (approve/reject) are ungated — any `module:STUDENT` user can view/approve all student leave requests.
- **[AUD-STD-04 CONFIRMED P1]** activityLog() commented out at lines 3852 (delete), 3916 (restore), 3979 (forceDelete) in StudentController. MedicalIncidentController DOES log correctly — this was probably accidentally removed during a refactor.
- **[GAP-STD-08 CONFIRMED P1]** Only 2 policies registered: StudentPolicy (Student::class) and AttendancePolicy (StudentAttendance::class). Missing: GuardianPolicy, MedicalIncidentPolicy, StudentDocumentPolicy, LeaveApplicationPolicy, LeaveTypePolicy.
- **[GAP-STD-05 CONFIRMED P1]** Only 1 FormRequest exists (StudentLeaveTypeRequest). All student create/update/guardian/medical/document paths use inline `Validator::make($request->all())` or raw `$request->all()`.
- **[STALE BA CLEARED: AttendanceController Gate]** BA v1.0 claimed "Gate facade not imported in AttendanceController — all Gate calls fatal". CLEARED: live code has full Gate::authorize on all 6 AttendanceController methods. Gate IS imported.
- **[STALE BA CLEARED: Leave DEAD CODE]** BA v1.0 claimed leave subsystem was DEAD CODE (no controller, no routes). CLEARED: StdLeaveController exists with index/store/show/edit/update/destroy/review routes. Feature IS live but auth is commented out.
- **[STALE BA CLEARED: module web.php stub only]** BA v1.0 claimed "module web.php registers only stub controller". CLEARED: routes/web.php has full student CRUD + guardian + attendance + leave + medical + document routes wrapped in `module:STUDENT`.
- **[UNIQUE ARCHITECTURE: EnsureTenantHasModule]** STD applies `module:STUDENT` via the `module` route middleware alias INSIDE routes/web.php:12, not in the RSP. This wraps ALL routes 100%. This is the ONLY tenant module on the platform with correct module-gate coverage. SEC-PLATFORM-003 does NOT apply to STD.
- **[BUG-STD-11 CONFIRMED P2]** `std_student_academic_sessions.current_flag` — V2 specified as `GENERATED ALWAYS AS (CASE WHEN is_current = 1 THEN student_id ELSE NULL END) STORED`. Live migration creates it as plain `nullable INT`. Application code must manually set it; any code path that sets `is_current` without setting `current_flag` breaks the UNIQUE safety net.
- **[DDL-STD-12 CONFIRMED P2]** 4 tables missing deleted_at despite model using SoftDeletes: `std_student_attendance`, `std_student_documents`, `std_health_profiles`, `std_vaccination_records`. The `->delete()` call will hard-delete.
- **[ARCH-STD-13 CONFIRMED P2]** Student.php imports: line 13 `FeeStudentAssignment`, line 16 `StudentPayLog`, line 18 `ExamAttempt`. Reversed coupling: if StudentFee, Transport, or StudentPortal modules are disabled, the Student model throws class-not-found on instantiation.
- **[PERF-STD-10 CONFIRMED P2]** `StudentsExport` uses `Excel::download()` — synchronous on the request thread. No queue. For 1000+ students this risks PHP memory exhaustion and request timeout.
