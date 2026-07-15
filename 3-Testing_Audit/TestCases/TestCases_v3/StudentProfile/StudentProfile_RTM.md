# StudentProfile (STD) — Requirements Traceability Matrix (RTM)

**Generated:** 2026-Jul-10 (report mode)
**Traceability chain:** BRD (Source) → Feature/Screen → Primary DDL table(s) → BC group → representative TC band → test method(s) → status.
Method-level detail lives in each feature's `std_{Feature}TcList_Require.md` (BC↔TC↔method) and `std_{Feature}GAPANALYSIS_Require.md` (TC↔method coverage + Cross-Reference Findings + Coverage-Score). This module RTM is the roll-up index across those.

**Requirement basis:** requirement folder `StudentProfile_v2/` is BRD-structured (6 domain BRDs), not per-screen — the canonical screen list was derived from real registered routes + controllers + views + DDL (see `StudentProfile_Feature_Inventory.md`).

## BRD → Feature coverage map

| BRD (Source) | Domain | Feature(s) | Primary DDL table(s) | Coverage |
|--------------|--------|-----------|----------------------|----------|
| BRD-01 Student Onboarding & Core Profile | onboarding, login, core profile | StudentCreate, StudentEdit, StudentCompleteProfile | `std_students`, `std_student_profiles`, `std_student_addresses` | Full |
| BRD-02 Family & Guardian Management | guardians, relationships | StudentCreate, StudentEdit | `std_guardians`, `std_student_guardian_jnt` | Full (within create/edit) |
| BRD-03 Academic Journey & Document Mgmt | sessions, subjects, prev-edu, documents | StudentCreate, StudentEdit, StudentCompleteProfile | `std_student_academic_sessions`, `std_student_opted_subjects`, `std_previous_education`, `std_student_documents` | Full (opted_subjects within session tab) |
| BRD-04 Health, Medical & Attendance | health, incidents, attendance | StudentCreate (health tab), MedicalIncident, Attendance | `std_health_profiles`, `std_vaccination_records`, `std_medical_incidents`, `std_student_attendance`, `std_attendance_corrections` | Full (correction workflow schema-only → GAP-STD-ATT-03) |
| BRD-05 Student Leave Management | leave types, leave FSM | StudentLeaveType, StudentLeave | `std_leave_types`, `std_leave_applications`, `std_leave_application_documents`, `std_leave_application_remarks` | Full (incl. BC-SM) |
| BRD-06 Reports & Dashboard | reports, exports | StudentReports (+ CompleteProfile export/id-card) | composite read + exports | Full (read-focused) |

**All 18 `std_` tables traced to ≥1 feature.** No DDL table left uncovered. (`std_student_pay_log` is Transport-owned / out of module scope — GAP-STD-19.)

## Per-feature BC → TC band → method traceability (roll-up)

| Feature | Methods | BC groups produced | TC bands populated | State machine | Defect proofs |
|---------|:------:|--------------------|--------------------|:-------------:|---------------|
| StudentLeaveType | 42 | DB, VAL, AUTH, BIZ, REF, AUTO | 01/10-19/30-39/40-49/50-59/90-99 | — | DEV-STD-LT-01; GAP-STD-08 rebuttal (`_51`) |
| StudentCreate | 37 | DB, VAL, AUTH, BIZ, REF, AUTO, EDG | 01-09/10-19/30-39/40-49/50-59/90-99 | — | SEC-STD-01/02/03, GAP-STD-05, BUG-STD-11, ARCH-STD-13, DDL-STD-12, DEV-STD-CRE-01 |
| StudentEdit | 54 | DB, VAL, AUTH, BIZ, REF, AUTO, EDG | 01-99 (all bands) | lifecycle | SEC-STD-01/02, AUD-STD-04, GAP-STD-05, BUG-STD-P3-02 + ungated/unvalidated finds |
| StudentCompleteProfile | 27 | DB, AUTH, BIZ, REF, EDG (read-focused) | 01/10-19/30-39/40-49/50-59/60-69/70-79/80-89/90-99 | — | GAP-STD-25, PERF-STD-10 (PDF), DEV-STD-CP-01 |
| MedicalIncident | 53 | DB, VAL, AUTH, BIZ, REF, AUTO, INT, EDG | 01-03/10-18/20-25/30-39/40-45/50-54/60-69/70-72/90-91 | toggle/lifecycle | DEV-MI-01..07, GAP-STD-08 rebuttal |
| Attendance | 44 | DB, VAL, AUTH, BIZ, REF, EDG, CFG | 01/10-19/20/30-39/40-49/50-59/60-69/70-79/90-99 | — | BUG-STD-P3-01 (regression), GAP-STD-22, BUG-STD-ATT-01/02, GAP-STD-ATT-03 |
| StudentLeave | 59 | DB, VAL, AUTH, BIZ, **SM**, INT, REF, AUTO, EDG | 01-09/10-19/**20-29**/30-39/40-49/50-59/60-69/70-79/90-99 | **10 transitions** (6 legal + 4 illegal) | GAP-STD-06 (regression), BUG-STD-14, BUG-STD-15 |
| StudentReports | 38 | DB, AUTH, BIZ, INT, EDG (read-focused) | 01-09/10-19/30-39/40-49/50-59/60-69/70-79/90-99 | — | PERF-STD-10 (PDF), DEV-STD-R1, DEV-STD-R2 |

## Permission / gate traceability (Source: audit permission matrix + Policies)

| Feature | Gate prefix (verified in source) | Policy | Status |
|---------|----------------------------------|--------|--------|
| StudentLeaveType | `tenant.leave-type.*` | LeaveTypePolicy | present (index gate mis-prefixed/commented → DEV-STD-LT-01) |
| StudentCreate/Edit | `tenant.student.*`, `tenant.guardian.*` | StudentPolicy, GuardianPolicy | remediated (was `school-setup.student.*` → SEC-STD-02) |
| MedicalIncident | `tenant.medical-incident.*` (ability-string) | MedicalIncidentPolicy | present (policy not per-object invoked — residual) |
| Attendance | `tenant.attendance.*` | AttendancePolicy | present |
| StudentLeave | `tenant.*` via `Gate::authorize` on all 8 methods | LeaveApplicationPolicy | active now (GAP-STD-06 remediated); `Gate::before` super-admin bypass (05_ #31) |
| StudentReports | `tenant.student.viewAny` | (viewAny) | present |

## Traceability integrity

- Every BRD domain → ≥1 feature (Full). Every `std_` DDL table → ≥1 feature. Every feature's every TC-ID → ≥1 method and every method → a TC/BC (verified in each feature's Gap Analysis).
- Every mapped audit defect (16 STD-tagged) → a proving/regression test; 12 newly-discovered defects added with proving tests.
- Coverage gates met module-wide (Negative 100%, Positive ≥94%, Dependency ≥86% Full/100% covered, Tenancy 100%).
