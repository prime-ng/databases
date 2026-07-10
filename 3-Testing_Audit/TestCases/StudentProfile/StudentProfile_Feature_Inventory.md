# StudentProfile (STD) — Feature Inventory

**Generated:** 2026-Jul-10 15-12
**Mode:** module → (then report)
**Owner:** Testcase_Creator agent

## Registry resolution (Step 0 — module_list.md)

| Field | Value |
|-------|-------|
| MODULE_NAME | StudentProfile |
| CODE | STD |
| PREFIX (registry hint) | `std_` |
| FOLDER_NAME | StudentProfile |
| DDL_FILE_NAME (registry stub) | `StudentProfile_DDL_` → glob-resolved to **`StudentProfile_DDL_v1.6.sql`** |

## DDL-verified prefix & DB scope

- **DDL:** `2-DDL_Tenant_Consolidated/StudentProfile_DDL_v1.6.sql` (header: "Student Profile Module DDL v1.5", "Module: Student Profile (std)").
- **All 18 `CREATE TABLE` statements use the `std_` prefix** — verified (18/18). The DDL-verified prefix is therefore **`std_`** for every feature. (The committed sibling test files use a legacy `spr_` prefix that predates the table-prefix rule; per HARD RULE #4 and the caller mandate, generated artifacts use the DDL-verified `std_`.)
- **DB scope = TENANT-side.** `std_` module-prefixed tables depend on tenant `sys_users`, `glb_*`, `sch_*`. Tenancy scaffolding required: `initializeTenantContext()`, `DUSK_TENANT_URL=http://test.localhost:8000`, tenant resolved via `Modules\Prime\Models\Domain`, tenant activity sink `Modules\GlobalMaster\Models\ActivityLog` (table `activity_logs`).

## DDL tables (18, all `std_`)

`std_students`, `std_student_profiles`, `std_student_addresses`, `std_guardians`, `std_student_guardian_jnt`, `std_student_academic_sessions`, `std_student_opted_subjects`, `std_previous_education`, `std_student_documents`, `std_health_profiles`, `std_vaccination_records`, `std_medical_incidents`, `std_student_attendance`, `std_attendance_corrections`, `std_leave_types`, `std_leave_applications`, `std_leave_application_documents`, `std_leave_application_remarks`.

## Requirement-source basis

The requirement folder `4-Requirement_Module_wise/2-Module_Requirement_V1/StudentProfile_v2/` is **BRD-structured (6 domain BRDs), not one-file-per-screen**:
BRD-01 Student Onboarding & Core Profile · BRD-02 Family & Guardian Management · BRD-03 Academic Journey & Document Management · BRD-04 Health, Medical & Attendance · BRD-05 Student Leave Management · BRD-06 Reports & Dashboard.

Because no per-screen requirement files exist, **the canonical feature (screen) list is derived from real registered routes (`Modules/StudentProfile/routes/web.php`) + controllers + Blade views + DDL**, with the BRDs supplying business-rule context. This basis is documented per HARD-RULE fallback. The committed sibling (`prime_testing/.../StudentProfile/Testcases/spr_*`) confirms the screen decomposition and the browser-Dusk test style that is mirrored.

## Canonical Feature List (ordered: masters → children → transactional → report)

| # | Feature (screen) | Primary table(s) | Controller | Route group | Prefix (DDL) | Type | BRD | Sibling precedent |
|---|------------------|------------------|-----------|-------------|--------------|------|-----|-------------------|
| 1 | **StudentLeaveType** | `std_leave_types` | StudentLeaveTypeController | `student-leave-types.*` (resource + trash/restore/forceDelete/toggleStatus) | `std_` | CRUD master | BRD-05 | — (new) |
| 2 | **StudentCreate** | `std_students` (+ profiles, addresses, guardians, guardian_jnt, academic_sessions, opted_subjects, previous_education, student_documents, health_profiles, vaccination_records) | StudentController (`createStudentLogin/Details/Session/ParentDetails/PrevEduDetails/MedicalDetails`) | `student.*` create + `student.editStudentDetails` | `std_` | CRUD wizard (core master) | BRD-01/02/03 | `spr_StudentCreate` |
| 3 | **StudentEdit** | `std_students` (+ related update targets) | StudentController (`updateLogin/updateStudentDetails/updateProfile/updateStudentAddress/updateParentDetails/updateStudentSession/updatePreviousEducation/updateStudentDocument/updateHealthProfile/updateVaccinationRecord` + `destroy/restore/forceDelete/toggleStatus`) | `student.update*`, `student.trashed/restore/forceDelete/toggleStatus` | `std_` | CRUD | BRD-01/02/03 | `spr_StudentEdit` |
| 4 | **StudentCompleteProfile** | `std_students` (read composite) | StudentController (`completeProfile/show/printIdCard/export/sendCredentials`) | `student.completeProfile`, `student.print-id-card`, `student.export`, `student.send-credentials` | `std_` | read composite | BRD-01/03/06 | `spr_StudentCompleteProfile` |
| 5 | **MedicalIncident** | `std_medical_incidents` | MedicalIncidentController (resource + trash/restore/forceDelete/toggleFollowUp/toggleParentNotified/ajaxGetStudents) | `medical-incidents.*` | `std_` | CRUD child | BRD-04 | `spr_MedicalIncident` |
| 6 | **Attendance** | `std_student_attendance`, `std_attendance_corrections` | AttendanceController (`create/scanAttendance/manualAttendance/bulkAttendanceIndex/storeBulkAttendance`) | `attendance.create/scan/manual`, `attendance.bulk`, `attendance.bulk.store` | `std_` | transactional | BRD-04 | `spr_BulkAttendance` (subset) |
| 7 | **StudentLeave** | `std_leave_applications`, `std_leave_application_documents`, `std_leave_application_remarks` | StdLeaveController (`index/review/updateReview/edit/update/getStudentsBySection/getApplicationsByStudent/storeRemark`) | `student-leave.*` | `std_` | transactional (FSM Submitted→Approved/Rejected) | BRD-05 | — (new) |
| 8 | **StudentReports** | composite read (`std_students`, `std_student_attendance`, `std_medical_incidents`, `std_health_profiles`) | StudentReportController (`combinedStudentReport`) | `reports.index`, `reports.class-strength` | `std_` | report / composite (read-focused) | BRD-06 | — (new) |

## Known StudentProfile audit defects → feature mapping (source: `StudentProfile_Complete_Audit_2026-06-30.md`)

| Defect ID | Severity | Description | Owning feature(s) |
|-----------|----------|-------------|-------------------|
| SEC-STD-01 | P0 | `is_super_admin` fillable in `createStudentLogin()` + edit toggle → privilege escalation | StudentCreate (+ StudentEdit) |
| SEC-STD-02 | P0 | 4 Gate::authorize use wrong prefix `school-setup.student.*` instead of `tenant.student.*` → 403 for all | StudentCreate/StudentEdit |
| SEC-STD-03 | P1 | Aadhar ID stored plaintext (UIDAI) | StudentCreate |
| GAP-STD-06 | P1 | StdLeaveController `Gate::authorize` commented out | StudentLeave |
| AUD-STD-04 | P1 | `activityLog()` commented out on student delete/restore/forceDelete | StudentEdit |
| GAP-STD-08 | P1 | Missing policies for 5 resource areas | cross-cutting (Create/Edit/Attendance/Documents) |
| GAP-STD-05 | P1 | Zero FormRequests for all student create/update routes | StudentCreate/StudentEdit |
| BUG-STD-11 | P2 | `current_flag` not a GENERATED STORED column | StudentCreate (academic sessions) |
| DDL-STD-12 | P2 | SoftDeletes missing from 4 tables | schema (multiple `test_01`) |
| ARCH-STD-13 | P2 | Student model imports downstream modules | StudentCreate |
| PERF-STD-10 | P2 | Synchronous Excel export for large datasets | StudentReports / StudentCompleteProfile |
| BUG-STD-P3-01 | P3 | Debug comment `// dd($request->all());s` in attendance method | Attendance |
| BUG-STD-P3-02 | P3 | `edit.blade.bkp` backup view file | StudentEdit |
| GAP-STD-25 | P3 | QR code exposes `admission_no` directly | StudentCompleteProfile (id-card) |
| GAP-STD-22 | P3 | Attendance <75% notification not implemented | Attendance |
| GAP-STD-19 | P3 | `std_student_pay_log` orphan table (Transport-owned, no STD model) | inventory note (not a STD screen) |

## Explicit gaps / out-of-scope (not generated as screens)

- **StudentProfileController.php**, `Modules/StudentProfile/Http/Controllers/Mobile/*`, `routes/api.php`, `routes/mobile_api.php` — API / mobile surface, not browser screens → **out of browser-screen scope** (flagged; candidate for a future HTTP-feature-test set).
- **`resources/views/student-settings/*`** — Blade views present but **no matching route/controller in `web.php`** → **orphaned screen; not generated** (verify whether wired elsewhere before authoring).
- **`std_student_opted_subjects`** — no standalone screen; exercised inside StudentCreate/StudentEdit academic-session tab.
- **`std_student_pay_log`** (GAP-STD-19) — orphan, Transport-owned; excluded.

## Test style (mirrored)

Browser Dusk (`extends DuskTestCase`, `namespace Tests\Browser`, `use App\Models\User`), tenant scaffolding (`initializeTenantContext()`, `resolveAdminUser()`, `Modules\Prime\Models\Domain`), tenant activity sink `Modules\GlobalMaster\Models\ActivityLog` — mirrored from the committed same-module sibling `prime_testing/tests/Browser/Modules/StudentProfile/Testcases/spr_*_TestCas.php`. One comprehensive `std_{Feature}_TestCas.php` per screen (no V1/V2).
