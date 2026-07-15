# StudentProfile (STD) — Coverage Dashboard

**Generated:** 2026-Jul-10 (report mode)
**Module folder:** `TestCases/StudentProfile/`
**DDL:** `StudentProfile_DDL_v1.6.sql` · **Prefix (DDL-verified):** `std_` (18/18 tables) · **DB scope:** TENANT
**Test style:** Browser Dusk (`extends DuskTestCase`, tenant scaffolding), mirrored from committed sibling `spr_*`.
**Total:** 8 features · 8 single test files (ONE `.php` each, no V1/V2) · **354 test methods** · 56 per-feature artifacts + 3 module docs.

## Per-feature coverage

| # | Feature | Type | Methods | Negative | Positive | Dependency | Tenancy/Sec | Verdict | php -l |
|---|---------|------|:------:|:--------:|:--------:|:----------:|:-----------:|---------|:------:|
| 1 | StudentLeaveType | CRUD master | 42 | 100% | 100% (95% Full) | 100% | 100% | PASS | clean |
| 2 | StudentCreate | CRUD wizard | 37 | 100% | 100% | 100% | 100% | PASS WITH NOTES | clean |
| 3 | StudentEdit | CRUD | 54 | 100% | 95% | 100% | 100% | PASS WITH NOTES | clean |
| 4 | StudentCompleteProfile | read composite | 27 | 100% | 100% | 100% | 100% | PASS WITH NOTES | clean |
| 5 | MedicalIncident | CRUD child | 53 | 100% | 100% (96% Full) | 100% (86% Full) | 100% | PASS WITH NOTES | clean |
| 6 | Attendance | transactional | 44 | 100% | 94% | 100% | 100% | PASS WITH NOTES | clean |
| 7 | StudentLeave | transactional FSM | 59 | 100% | 100% | 100% (1 Full + 2 partial) | 100% | PASS WITH NOTES | clean |
| 8 | StudentReports | report/composite | 38 | 100% | 100% | 100% | 100% | PASS WITH NOTES | clean |
| | **Total / gate** | | **354** | **100%** ✅ | **≥94%** ✅ (gate ≥90) | **≥86% Full → 100% covered** ✅ | **100%** ✅ | 1 PASS, 7 PASS-WITH-NOTES | 8/8 clean |

Coverage gates (Negative 100% · Positive ≥90% · Dependency ≥90% · Tenancy 100% on P0/P1) **met for every feature.**

## State-machine coverage (workflow features)

| Feature | FSM | Transitions covered |
|---------|-----|---------------------|
| StudentLeave | `std_leave_applications` Submitted→Approved/Rejected (+Under Review / Info Requested / Doc Requested / Cancelled) | 10 (6 legal + 4 guarded-illegal) — plus auto status-change log + no-source-guard defect proof (BUG-STD-15) |

## Environment prerequisite (all features)

- **`STUDENT` module must be ENABLED** in `prime_testing/modules_statuses.json` (currently `false` → 404 on all routes). Documented per 05_ #19 as an env prerequisite, not a test-code fix. Dusk was **not executed** in this run (module disabled); only `php -l` was run per instruction. Static schema/route/source-defect assertions run regardless.

## Module Defect Register (audit-mapped + newly discovered)

Legend: **P** present/confirmed in current source · **R** remediated since audit (test = regression guard) · **N** newly discovered (proving test authored).

| Defect ID | Sev | State | Feature | Proving test | Note |
|-----------|-----|:-----:|---------|--------------|------|
| SEC-STD-01 (is_super_admin escalation) | P0 | R (residual) | StudentCreate/StudentEdit | create `_92/_93`, edit `_80/_81/_92` | Controller remediated; toggle still rendered in the **create** login partial → residual |
| SEC-STD-02 (wrong `school-setup.student.*` gate) | P0 | R | StudentCreate/StudentEdit | `_09/_51`, `_52/_53/_54` | All gates now `tenant.student.*` |
| SEC-STD-03 (Aadhar plaintext) | P1 | R | StudentCreate/StudentEdit | `_05`, `_85` | `encrypted` cast + `aadhar_id_hash` blind index |
| AUD-STD-04 (activityLog commented on delete/restore/forceDelete) | P1 | R | StudentEdit | `_84`, `_21/_23/_24` | Calls active in current controller |
| GAP-STD-05 (zero FormRequests on student routes) | P1 | P | StudentCreate/StudentEdit | `_06`, `_82` | Only `StudentLeaveTypeRequest` exists; inline validation elsewhere |
| GAP-STD-06 (StdLeave gates commented) | P1 | R | StudentLeave | `_51/_52` | Gates active on all 8 methods now; `Gate::before` super-admin bypass noted (05_ #31) |
| GAP-STD-08 (5 missing policies) | P1 | R (stale) | LeaveType / MedicalIncident | `_51`; MI policy check | Policies exist; rebutted (residual: ability-string gates bypass per-object policy) |
| BUG-STD-11 (`current_flag` not GENERATED STORED) | P2 | P | StudentCreate | `_07` (information_schema) | Migration creates plain nullable int |
| DDL-STD-12 (SoftDeletes missing 4 tables) | P2 | P (inverse) | StudentCreate/StudentEdit | `_04`, `_01/_26` | Migrations add column, models lack trait → column/trait disagree (05_ #30) |
| ARCH-STD-13 (Student model imports downstream) | P2 | P | StudentCreate | `_08` | Imports StudentFee/Transport/StudentPortal |
| PERF-STD-10 (sync Excel export) | P2 | R (partial) | StudentReports/CompleteProfile | reports `_43`, profile `_81` | Excel/CSV now queued; **PDF branch still synchronous** |
| BUG-STD-P3-01 (stray `dd()` debug) | P3 | R | Attendance | `_94` | Absent in current source (regression guard) |
| BUG-STD-P3-02 (`edit.blade.bkp`) | P3 | P | StudentEdit | `_83` | Backup view file present |
| GAP-STD-25 (QR exposes admission_no) | P3 | P | StudentCompleteProfile | `_80` | id-card exposes admission_no/aadhar/qr plaintext |
| GAP-STD-22 (attendance <75% notification) | P3 | P | Attendance | `_95` | Not implemented |
| DEV-STD-CRE-01 | P3 | N | StudentCreate | `_38` | `first_name` rule `max:100` vs DDL `VARCHAR(50)` |
| DEV-STD-CP-01 | P3 | N | StudentCompleteProfile | (candidate) | `aadhar_id` encrypted cast into `VARCHAR(20)` — verify in source |
| DEV-MI-01..07 | Low–High | N | MedicalIncident | `_70/_71/_43/_41/_69/_16` + gap | incl. **DEV-MI-03 (High)**: `update()` `exists:users,id` vs `store()` `exists:sys_users,id` (no `users` table in tenant) |
| BUG-STD-14 | Med | N | StudentLeave | `_70` | `remark_type` DDL ENUM Title_Case vs lowercase model constants |
| BUG-STD-15 | Med | N | StudentLeave | `_28` | `updateReview`/`LeaveService::review()` validate target status only → illegal FSM moves accepted |
| BUG-STD-ATT-01 | Med | N | Attendance | `_97` | `storeBulkAttendance` lacks status `in:` enum validation |
| BUG-STD-ATT-02 | Low | N | Attendance | `_96` | `getAttendanceReport()` dead (no route) |
| GAP-STD-ATT-03 | Low | N | Attendance | `_98` | correction workflow schema-only, unimplemented |
| DEV-STD-R1 | Med | N | StudentReports | `_63` | breadcrumb links unregistered `complaint.reports.summary` → 500 |
| DEV-STD-R2 | Low | N | StudentReports | `_70` | `?? $currentSession->id` null-deref when no current session |

> Note: several P0/P1 audit items (SEC-STD-01/02/03, AUD-STD-04, GAP-STD-06, GAP-STD-08) are **remediated in current source** vs the 2026-06-30 audit; tests assert the observed current behavior (remediation = regression proof; still-present = defect proof) per HARD RULE 10/11.

## 05_ constraints appended this run (reconciled)

- **#29** — runner (`prime_testing`) has no app `Modules/*` source on disk; resolve `prime_ai` via `MAIN_PROJECT_PATH`/fallbacks, fail-soft (Attendance).
- **#30** — consolidated DDL diverges from live migrations for soft-delete/GENERATED columns; assert via live `Schema`/`information_schema`, not the DDL file (StudentCreate).
- **#31** — `Gate::before` grants all abilities to Super Admin; auth negative tests must use a stripped non-super user; re-verify "gate commented out" audit claims (StudentLeave).
- **#32** — resolve real app source via `ReflectionClass::getFileName()` (base_path = runner, not prime_ai) for source-content assertions (StudentEdit).
