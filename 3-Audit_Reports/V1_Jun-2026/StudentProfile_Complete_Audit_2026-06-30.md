# StudentProfile (STD) — Mode X Complete Audit
**Date:** 2026-06-30  
**Auditor:** Technical Auditor Agent (Mode X — A+B+C+G+D)  
**Module:** `Modules/StudentProfile/`  
**Prefix:** `std_*` (19 tables) — foundational master-data provider for all tenant modules  
**Health Score:** 40/100 (P0-capped)  
**Deploy Gate:** ❌ NO-GO  

---

## Executive Summary

StudentProfile is the identity core of Prime-AI — every other module reads `std_*` tables. The module is substantially implemented (~75% complete by BA estimate): student CRUD, guardian management, attendance, medical incidents, leave management, and export are all functional. Two key BA P0 findings confirmed by live code:

1. **SEC-STD-01:** `is_super_admin` is accepted as a fillable field in `createStudentLogin()` and rendered as a toggle in the edit view — any admin who can reach the student login creation endpoint can silently escalate themselves to platform super-admin.
2. **SEC-STD-02:** Four Gate::authorize calls use the wrong permission prefix `school-setup.student.*` instead of `tenant.student.*` — these check non-existent permissions, causing 403 for all users including legitimate admins on affected operations.

**VERIFIED GOOD (BA claim confirmed):** EnsureTenantHasModule IS applied via `module:STUDENT` alias inside `routes/web.php:12`, wrapping ALL student-profile routes. This is correct architecture, different from most other modules where it's absent. SEC-PLATFORM-003 does NOT apply to STD.

---

## Health Score (40/100 — P0 Capped)

| Layer | Weight | Color | Score | Notes |
|-------|--------|-------|-------|-------|
| L1 Tenant Isolation | 15 | 🟢 Green | 1.0 | EnsureTenantHasModule PRESENT via module:STUDENT in web.php |
| L2 Authentication | 12 | 🟢 Green | 1.0 | Full auth stack in RSP; verified middleware chain |
| L3 Authorization | 12 | 🔴 Red | 0.0 | SEC-STD-01 is_super_admin P0; SEC-STD-02 wrong Gate prefix; missing 5 resource policies |
| L4 Input Validation | 8 | 🔴 Red | 0.0 | 0 FormRequests for student routes; GAP-STD-05 |
| L5 Data Integrity | 8 | 🟡 Amber | 0.5 | current_flag not GENERATED STORED; SoftDeletes missing from 4 tables |
| L6 Business Logic | 10 | 🟡 Amber | 0.5 | Leave workflow built; promotion/TC workflows absent; activityLog commented |
| L7 Output Security | 8 | 🟢 Green | 1.0 | No unescaped {!! !!} on user input found |
| L8 Error/Logging | 5 | 🟡 Amber | 0.5 | activityLog commented out on delete/restore/forceDelete |
| L9 Performance | 5 | 🟡 Amber | 0.5 | Synchronous Excel export; Student model eager-load risk |
| L10 Code Quality | 7 | 🟡 Amber | 0.5 | 4222-line monolith; debug comment; backup .bkp view file |
| L11 Feature Completeness | 10 | 🟡 Amber | 0.5 | Core CRUD 90%+; Promotion/TC/Attendance Correction absent |
| L12 Gap Analysis | 0 | — | — | 29 gaps in BA; this audit adds 0 new; 5 confirmed |

**Raw: P0 present → capped at 40/100. Deploy: NO-GO.**

---

## Deploy Gate Verdict

| Gate | Status | Reason |
|------|--------|--------|
| ❌ Security P0 | BLOCK | SEC-STD-01: is_super_admin privilege escalation via student login creation |
| ❌ Auth P0 | BLOCK | SEC-STD-02: 4 Gate checks use non-existent `school-setup.student.*` prefix |
| ⚠️ PII P1 | WARN | SEC-STD-03: Aadhar ID stored plaintext (UIDAI compliance) |
| ⚠️ Auth P1 | WARN | Leave workflow: Gate::authorize commented out (GAP-STD-06) |
| ✅ Tenant Module Gate | PASS | module:STUDENT middleware confirmed on all routes |
| ✅ Attendance Auth | PASS | Gate::authorize on all 6 AttendanceController methods |
| ✅ Leave Type Auth | PASS | Gate::authorize on all 7 StudentLeaveTypeController methods |

---

## P0 Findings (Critical — Deploy Blockers)

### SEC-STD-01: Privilege Escalation via is_super_admin in Student Login Creation
**Severity:** P0 | **Layer:** Authorization

**Evidence (Controller):**
```php
// Modules/StudentProfile/app/Http/Controllers/StudentController.php

// Line 610 (createStudentLogin validation):
'is_super_admin' => 'nullable',

// Line 631 (User::create call):
'is_super_admin' => $request->boolean('is_super_admin'),
```

**Evidence (View):**
```php
// resources/views/student/partials/edit/student-details-tabs/_student-login.blade.php:124
<x-backend.form.status-switch name="is_super_admin" label="Super Admin"
    :checked="old('is_super_admin', $user->is_super_admin ?? false)" />
```

**Impact:** Any school administrator who can create/edit student logins can toggle the `is_super_admin` flag ON for themselves or any user by sending a crafted POST request. The toggle is present in the UI and accepted by the controller. This is a platform-wide super-admin escalation vector.

**Fix:**
1. Remove `'is_super_admin'` from the validation array at line 610.
2. Remove `'is_super_admin' => $request->boolean('is_super_admin')` from User::create at line 631.
3. Delete the `<x-backend.form.status-switch name="is_super_admin">` component from both create and edit views.

---

### SEC-STD-02: Wrong Permission Prefix in Gate Checks — Operations Fail for All Users
**Severity:** P0 | **Layer:** Authorization

**Evidence:**
```php
// Modules/StudentProfile/app/Http/Controllers/StudentController.php
Line 1090: Gate::authorize('school-setup.student.update');
Line 1212: Gate::authorize('school-setup.student.update');
Line 1316: Gate::authorize('school-setup.student.delete');
Line 1892: Gate::authorize('school-setup.student.update');
```

**Correct prefix** (used on all other methods): `tenant.student.update`, `tenant.student.delete`

**Impact:** The permission `school-setup.student.update` is never seeded — it doesn't exist in the Spatie permission table. Gate::authorize on a non-existent permission throws a 403 for all users (including super-admins without bypass mode). The operations at these 4 lines are **broken for everyone**. Additionally, the commented lines (1301, 1323, 1333) suggest these were copied from SchoolSetup and never corrected.

**Fix:** Replace `school-setup.student.*` with `tenant.student.*` at all 4 active lines.

---

## P1 Findings (Major)

### SEC-STD-03: Aadhar ID Stored in Plaintext — UIDAI Compliance Violation
**Severity:** P1 | **Layer:** Data Integrity / PII

**Evidence:**
```php
// Modules/StudentProfile/app/Models/Student.php
'aadhar_id' in $fillable — no 'encrypted' cast in $casts
```

**Impact:** `std_students.aadhar_id` contains India's 12-digit national ID (UIDAI-issued). Under Indian IT Act and DPDPA 2023, government IDs are sensitive personal data requiring protection at rest. Any DB dump, backup, or raw SQL access exposes all student Aadhar numbers in plaintext.

**Fix:** Add `'aadhar_id' => 'encrypted'` to `Student::$casts`. Note: encrypted columns cannot use SQL equality filters — implement HMAC blind index if search is needed.

---

### GAP-STD-06: StdLeaveController Gate::authorize Commented Out
**Severity:** P1 | **Layer:** Authorization

**Evidence:**
```php
// Modules/StudentProfile/app/Http/Controllers/StdLeaveController.php
Line 25:  // Gate::authorize('tenant.student-leave.viewAny');
Line 250: // Gate::authorize('tenant.student-leave.review');
```

**Impact:** The leave `index()` method has no active Gate check — any user with `module:STUDENT` access can view ALL student leave applications across the school. The `review()` method (approve/reject) is also ungated — any module:STUDENT user can approve or reject any leave application.

**Fix:** Uncomment and restore both Gate::authorize calls. Ensure `LeaveApplicationPolicy` is created and registered.

---

### AUD-STD-04: activityLog() Commented Out on Student Delete / Restore / Force Delete
**Severity:** P1 | **Layer:** Audit / Compliance

**Evidence:**
```php
// Modules/StudentProfile/app/Http/Controllers/StudentController.php
Line 3852: // activityLog($student, 'Deleted', [...])
Line 3916: // activityLog($student, 'Restored', [...])
Line 3979: // activityLog($studentInfo, 'Force Deleted', [...])
```

**Impact:** Student deletion, restoration, and permanent deletion events have no audit trail. School student records are legally auditable (especially for roll number assignment, TC issuance). MedicalIncidentController DOES call activityLog — this inconsistency suggests they were removed accidentally.

**Fix:** Uncomment all three activityLog calls. Add activityLog to StdLeaveController (leave approvals) and StudentLeaveTypeController (type configuration changes).

---

### GAP-STD-08: Missing Policies for 5 Resource Areas
**Severity:** P1 | **Layer:** Authorization

**Registered policies (2):** StudentPolicy, AttendancePolicy  
**Missing (5):** GuardianPolicy, MedicalIncidentPolicy, StudentDocumentPolicy, LeaveApplicationPolicy, LeaveTypePolicy

**Impact:** Guardian CRUD, document verification, medical incident management, and leave management all have no policy coverage. Gate::authorize calls in controllers that reference these resources check only ability strings, with no per-object authorization.

**Fix:** Create and register the 5 missing policies in `StudentProfileServiceProvider::registerPolicies()`.

---

### GAP-STD-05: Zero FormRequests for All Student Create/Update Routes
**Severity:** P1 | **Layer:** Input Validation

**Evidence:** Only 1 FormRequest exists: `StudentLeaveTypeRequest`. All major student routes use inline `Validator::make($request->all())` or `$request->all()` directly — no centralized validation rules, no `$request->validated()` usage.

**Impact:** Mass assignment risk; cannot test validation rules independently; duplicated validation across methods.

**Fix:** Create 12 FormRequests as listed in V2 Appendix 15.1 (StudentLoginRequest, StudentDetailRequest, GuardianRequest, StudentSessionRequest, StudentMedicalDetailRequest, StudentHealthProfileRequest, etc.).

---

## P2 Findings (Significant)

### BUG-STD-11: current_flag Not a GENERATED STORED Column
**Severity:** P2 | **Layer:** Data Integrity

V2 specified `current_flag = GENERATED ALWAYS AS (CASE WHEN is_current = 1 THEN student_id ELSE NULL END) STORED`. Migration creates it as plain nullable INT. Application code must manually maintain `current_flag = student_id` when `is_current = 1`. Any code path that sets `is_current` without updating `current_flag` breaks the UNIQUE enforcement silently.

### DDL-STD-12: SoftDeletes Missing from 4 Tables
**Severity:** P2 | **Layer:** Data Integrity

`std_student_attendance`, `std_student_documents`, `std_health_profiles`, `std_vaccination_records` — no `deleted_at` column. Models have SoftDeletes trait but `->delete()` will silently hard-delete.

### ARCH-STD-13: Student Model Imports from Downstream Modules
**Severity:** P2 | **Layer:** Architecture

`Student.php` imports `Modules\StudentFee\Models\FeeStudentAssignment` (line 13), `Modules\Transport\Models\StudentPayLog` (line 16), `Modules\StudentPortal\Models\ExamAttempt` (line 18). Reversed coupling: if any downstream module is disabled, `Student` model throws class-not-found.

### PERF-STD-10: Synchronous Excel Export for Large Student Datasets
**Severity:** P2 | **Layer:** Performance

`StudentsExport` runs synchronously via `Excel::download()`. Schools with 1000+ students risk PHP memory exhaustion and request timeout. Should use `ShouldQueue` + Livewire/download link.

---

## P3 Findings (Minor)

| Code | Finding | Location |
|------|---------|----------|
| BUG-STD-P3-01 | Debug comment `// dd($request->all());s` in attendance method | StudentController.php |
| BUG-STD-P3-02 | `edit.blade.bkp` backup view file in resources/views | views/student/partials/ |
| GAP-STD-25 | QR code may expose admission_no directly — should use hash/UUID | StudentController |
| GAP-STD-19 | std_student_pay_log orphan table — no STD model; Transport owns it | migrations |
| GAP-STD-22 | Attendance < 75% automated notification not implemented | Missing |

---

## Verified Good (PASS)

| Item | Evidence | Rating |
|------|----------|--------|
| EnsureTenantHasModule | `module:STUDENT` alias at web.php:12 wraps ALL routes | ✅ Strong |
| AttendanceController auth | Gate::authorize on all 6 methods (create×4, viewAny×2) | ✅ Strong |
| StudentLeaveTypeController auth | Gate::authorize on all 7 methods | ✅ Strong |
| MedicalIncidentController activityLog | activityLog() called correctly | ✅ Correct |
| Media storage | Spatie MediaLibrary for photos; conversions: thumb/medium/large | ✅ Correct |
| DomPDF + QR export | ID card generation implemented | ✅ Implemented |

---

## Systemic Pattern Scorecard

| Pattern | Verdict | Notes |
|---------|---------|-------|
| SEC-PLATFORM-003 (EnsureTenantHasModule) | ✅ PRESENT | Applied via module:STUDENT in web.php — DIFFERENT from other modules |
| API RSP no tenancy | ✅ CONFIRMED | mapApiRoutes() dead scaffold only, no tenancy |
| D30 (authorize=true) | ⚠️ PARTIAL | 1 FormRequest (LeaveTypeRequest) returns true; 0 others exist |
| D25 ($request->all()) | ✅ CONFIRMED | Multiple create/update methods use $request->all() |
| AcademicSession cross-layer | ✅ CONFIRMED | STD consumes Modules\Prime\Models\AcademicSession |

---

## Recommended Fix Order

**Sprint 1 (Unblock Deploy):**
1. SEC-STD-01 — Remove is_super_admin from controller + view (1 hour)
2. SEC-STD-02 — Fix 4 Gate prefix strings (30 min)

**Sprint 2 (Auth Hardening):**
3. GAP-STD-06 — Uncomment StdLeaveController Gate calls; create LeaveApplicationPolicy
4. GAP-STD-08 — Register 5 missing policies
5. AUD-STD-04 — Uncomment activityLog calls + add to leave controllers

**Sprint 3 (Validation):**
6. GAP-STD-05 — Create 12 FormRequests (batch work)
7. SEC-STD-03 — Add encrypted cast for aadhar_id

**Sprint 4 (Data Integrity):**
8. BUG-STD-11 — Migrate current_flag to GENERATED STORED
9. DDL-STD-12 — Add SoftDeletes to 4 missing tables

---

*Generated: 2026-06-30 | Technical Auditor Agent (Mode X) | Evidence-based; read-only pass*
