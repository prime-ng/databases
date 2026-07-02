# STD: StudentProfile — Complete Analysis Pack
**Version:** 1.0 | **Date:** 2026-06-30 | **Module Code:** STD | **Prefix:** `std_*`
**FRD Reference:** `STD_FRD_2026-06-30.md` (same folder — all REQ-/BR-/RPT-/ENH- IDs originate there)
**Sources:** DDL v1.6 · V2 Requirement (2026-03-26) · V1 BRD-01–06 · Module Knowledge v1.0 (2026-06-30)

---

## Table of Contents
1. [Section A — Requirements Traceability Matrix (RTM)](#section-a)
2. [Section B — Business Rules + Conditions Catalog + Validation & Edge Cases](#section-b)
3. [Section C — Process Flows + FSM Catalog](#section-c)
4. [Section D — Data Dictionary + Cross-Module Dependency Map](#section-d)
5. [Section E — NFR Catalog + Risk Register](#section-e)
6. [Section F — Prioritization (MoSCoW / RICE) + Effort Estimation](#section-f)
7. [Section G — User Stories + Acceptance Criteria (P0/P1 REQs)](#section-g)
8. [Section H — Reporting & KPI Specification](#section-h)
9. [Section I — Feature Specification (Key Screens)](#section-i)
10. [Section J — Requirements-vs-Code Gap Analysis](#section-j)

---

## Section A — Requirements Traceability Matrix (RTM) {#section-a}

> All IDs reference the FRD (`STD_FRD_2026-06-30.md`). Code Status = DONE / PARTIAL / NOT STARTED based on module knowledge v1.0 code verification (2026-06-30).

| REQ-ID | Feature | Priority | BR Refs | Screen(s) | Workflow | Report(s) | Code Status | Key Gaps |
|---|---|---|---|---|---|---|---|---|
| REQ-STD-001 | Student List & Search | P0 | — | Student List (index) | — | — | DONE (90%) | CSV export missing |
| REQ-STD-002 | Student System Account Creation | P0 | BR-001,003,004 | Create (Tab 1) | WF-1 Step 1 | — | PARTIAL (60%) | P0: is_super_admin not removed; no Gate::authorize on createStudentLogin; no FormRequest |
| REQ-STD-003 | Student Demographic Profile | P0 | BR-001,002,005,006,007 | Edit (Tab 2) | WF-1 Step 2 | — | PARTIAL (75%) | No FormRequest; some Gate calls use wrong permission prefix |
| REQ-STD-004 | Address Management | P0 | BR-008 | Edit (Tab 2 / Address section) | — | — | DONE (80%) | No FormRequest |
| REQ-STD-005 | Student Photo Management | P0 | — | Create/Edit (Tab 1) | — | — | DONE (90%) | — |
| REQ-STD-006 | Guardian / Parent Management | P0 | BR-009,010,011,012,013 | Edit (Tab 3) | WF-1 Step 4 | — | PARTIAL (75%) | No GuardianPolicy; no FormRequest; no fee-payer enforcement |
| REQ-STD-007 | Parent Portal Access Granting | P1 | BR-011 | Edit (Tab 3) | WF-3 | — | DONE (85%) | — |
| REQ-STD-008 | Academic Session Enrollment | P0 | BR-014,015,016,017,018 | Edit (Tab 4) | WF-2 | — | PARTIAL (75%) | current_flag not GENERATED STORED; no FormRequest; leaving-date rule not enforced |
| REQ-STD-009 | Subject Selection per Enrollment | P1 | — | Edit (Tab 4 extension) | — | — | PARTIAL (50%) | Model and DDL exist; no dedicated UI or routes confirmed |
| REQ-STD-010 | Previous Education History | P0 | — | Edit (Tab 5) | WF-1 Step 6 | — | DONE (85%) | SoftDeletes added via 2026-06 migration |
| REQ-STD-011 | Student Document Upload & Verification | P0 | BR-019,020,021,022 | Edit (Documents tab) | — | — | PARTIAL (70%) | No DocumentPolicy; missing SoftDeletes on std_student_documents table; expired-doc flag absent |
| REQ-STD-012 | Health Profile | P0 | — | Edit (Health tab) | — | — | PARTIAL (70%) | No FormRequest; missing SoftDeletes on std_health_profiles; medical data plaintext |
| REQ-STD-013 | Vaccination Records | P1 | — | Edit (Health tab) | — | — | PARTIAL (70%) | Missing SoftDeletes on std_vaccination_records |
| REQ-STD-014 | Medical Incident Log | P0 | BR-023 | Medical Incidents (separate resource) | — | — | DONE (85%) | Gate review needed on MedicalIncidentController |
| REQ-STD-015 | Daily Attendance Marking | P0 | BR-024,026,028 | Attendance (index/create/bulk) | — | — | DONE (85%) | Gate::authorize IS present (code-verified 2026-06-30); no FormRequest; no bulk transaction |
| REQ-STD-016 | Attendance Correction Workflow | P1 | BR-025,026,027 | Correction (not built) | WF-4 | — | NOT STARTED (10%) | Table + model exist; no controller, routes, or approval UI |
| REQ-STD-017 | Student Status Management | P0 | — | Student List / Edit | WF-6 | — | DONE (95%) | activityLog commented out for delete/restore/force-delete |
| REQ-STD-018 | Profile Completion Tracking | P1 | BR-029,030 | Edit (all tabs) | — | — | DONE (90%) | Helper + accessor implemented; extraction to service proposed |
| REQ-STD-019 | Student Credential Management | P1 | — | Student List | — | — | DONE (85%) | — |
| REQ-STD-020 | Student Data Export | P1 | — | Student List | — | RPT-STD-001/002 | PARTIAL (80%) | Export not queued; large exports risk timeout |
| REQ-STD-021 | Leave Type Configuration | P1 | BR-031 | Leave Types (CRUD) | — | — | PARTIAL (70%) | StdLeaveController Gate::authorize commented out |
| REQ-STD-022 | Leave Application Submission | P1 | BR-031,032,033,034 | Leave Application (form) | WF-5 | — | PARTIAL (60%) | Gate commented out; attendance auto-update on approval absent; annual quota not enforced |
| REQ-STD-023 | Leave Review & Teacher Decision | P1 | BR-035,036,037,038 | Leave Review (teacher) | WF-5 Steps 3–4 | — | PARTIAL (60%) | Gate commented out; partial-approval attendance logic absent |
| REQ-STD-024 | Leave Communication Thread | P1 | BR-038,039 | Leave Application (thread) | WF-5 Step 5 | — | PARTIAL (55%) | Remark model and DDL support it; application-level auto-logging on status change needs verification |
| REQ-STD-025 | Auto Attendance Update on Leave Approval | P1 | BR-035,036,037 | System (automated) | WF-5 Step 4a | — | NOT STARTED (0%) | No attendance-creation logic triggered from leave approval |
| REQ-STD-026 | Administrative Reports | P1 | — | Reports Hub | — | RPT-STD-001,002,003 | DONE (70%) | Gate check on StudentReportController needs review |

**RTM Totals:** 26 REQ — 12 P0 / 14 P1 | 39 BR | 3 RPT | 7 ENH

---

## Section B — Business Rules Register + Requirement Conditions Catalog + Validation & Edge Cases {#section-b}

> Business Rules are defined in FRD Section 4 (BR-STD-001 through BR-STD-039). This section provides the Conditions Catalog and Validation & Edge-Case detail.

### B.1 Requirement Conditions Catalog

> Also saved to: `{REQUIREMENT_CONDITIONS}/STD_Conditions.md`

| Condition ID | Entity / Field | Condition (Business) | Type | Trigger | On-Violation Behaviour |
|---|---|---|---|---|---|
| BR-STD-001 | Admission Number | Must be unique per school; immutable after first assignment | Validation | Save Student Details | Reject with "Admission number already exists" error |
| BR-STD-002 | Aadhar ID | If provided: exactly 12 numeric digits; unique across all students | Validation | Save Student Details | Reject with "Aadhar ID must be 12 digits" / "Aadhar already registered" |
| BR-STD-003 | Student Email | Unique across all system users | Validation | Create Account | Reject with "Email already in use" |
| BR-STD-004 | Student Code | Auto-generated; cannot be set manually | Validation | Create Account | Strip any submitted value; auto-assign |
| BR-STD-005 | APAAR ID | If provided: exactly 12 digits | Validation | Save Student Details | Reject with format error |
| BR-STD-006 | QR Code Payload | Must not contain raw Admission Number | Security | QR Code generation | Use internal hash/UUID as payload |
| BR-STD-007 | Height / Weight | Height: 30–300 cm; Weight: 1–500 kg; Measurement Date required if either present | Validation | Save Student Details | Reject out-of-range values; require date if missing |
| BR-STD-008 | Is Primary (Address) | Exactly one address may be primary at any time | Validation | Save Address | Auto-clear primary from other addresses when new one set |
| BR-STD-009 | Guardian Mobile | Unique across all guardians in the school | Validation | Save Guardian | Reject with "Mobile number already registered to another guardian" |
| BR-STD-010 | Guardian Completeness | At least one guardian with relation Father / Mother / Guardian required | Validation | Profile Completion check | Flag profile as incomplete; prevent "complete" status |
| BR-STD-011 | Guardian Portal Login | Created only on explicit "Grant Portal Access" action | Workflow | Grant Portal Access | Do not create login automatically when guardian record saved |
| BR-STD-012 | Fee Payer Flag | At most one Fee Payer per student | Validation | Save Guardian Junction | Reject if another guardian already has Is Fee Payer = Yes for this student |
| BR-STD-013 | Notification Dispatch | Only to guardians with Receive Notifications = Yes | Permission | Notification dispatch | Skip guardians with flag = No; use preferred channel for those with flag = Yes |
| BR-STD-014 | Current Enrollment | Exactly one enrollment marked Current per student | Concurrency | Set Enrollment as Current | DB unique constraint (current_flag) prevents second Current; application must validate before attempting |
| BR-STD-015 | Enrollment Transition | Must execute within a DB transaction | Concurrency | Enrollment transition | On failure: rollback; student retains original current enrollment |
| BR-STD-016 | Duplicate Enrollment | One enrollment per academic year per student | Validation | Save Enrollment | Reject with "Student already enrolled in this academic year" |
| BR-STD-017 | Leaving Date + Reason | Required when Session Status = Left or Withdrawn | Validation | Save Enrollment Status | Reject with field-required errors |
| BR-STD-018 | Timetable Eligibility | Auto-set to No when status = Suspended or Withdrawn | Workflow | Session Status change | System sets count_for_timetable = 0 automatically |
| BR-STD-019 | Document Verification | Only Admin or Registrar may mark Is Verified = Yes | Permission | Verify Document | Reject unauthorized verify action |
| BR-STD-020 | Expired Document Flag | Documents past expiry date shown with visual flag | Validation | View Documents | Display "Expired" badge; do not block viewing |
| BR-STD-021 | TC Number Uniqueness | Unique per school per academic year | Validation | Document Save / TC generation | Reject duplicate TC number |
| BR-STD-022 | MIME Validation | Server-side based on file content | Security | File Upload | Reject file if MIME does not match allowed types; return error |
| BR-STD-023 | Parent Notification (Incident) | Set Parent Notified = Yes when notification occurs | Workflow | Save Medical Incident | Notify and flag field; do not auto-notify via system (manual flag) |
| BR-STD-024 | Attendance Date Range | Must be within student's current active enrollment period | Validation | Mark Attendance | Reject attendance for future dates or dates outside enrollment |
| BR-STD-025 | Attendance Immutability | Can only be changed via Correction Request | Workflow | Attendance Edit | Block direct edit; direct to Correction Request workflow |
| BR-STD-026 | Correction Two-Step | Class Teacher → School Admin | Workflow | Correction submit | Cannot skip teacher step; admin step follows teacher approval only |
| BR-STD-027 | Attendance < 75% | Triggers guardian notification | Workflow | Scheduled attendance calculation | Fire notification event for eligible guardians |
| BR-STD-028 | Bulk Attendance Transaction | All-or-nothing; partial saves not permitted | Concurrency | Bulk Attendance submit | On any failure: rollback all records in batch |
| BR-STD-029 | Profile Completeness Definition | All five stages present | Validation | Profile Completion check | Display incomplete status until all five stages present |
| BR-STD-030 | Profile % Computation | Must not be computed via full-table scan for bulk lists | Calculation | Profile list queries | Use cached or computed-column approach |
| BR-STD-031 | Half-Day Constraint | Only when from_date = to_date | Validation | Submit Leave Application | Reject half-day flag if date range spans multiple days |
| BR-STD-032 | Leave Routing | Routed to class teacher of current class-section at submission time | Workflow | Submit Leave Application | class_section_id recorded on application at submission |
| BR-STD-033 | Max Consecutive Days | Cannot exceed leave type policy | Validation | Submit Leave Application | Reject with "Exceeds maximum days for this leave type" |
| BR-STD-034 | Annual Quota | Total approved days ≤ leave type annual maximum | Calculation | Submit Leave Application | Reject if quota exhausted; show remaining days |
| BR-STD-035 | Leave → Attendance Auto-Create | Creates Leave attendance records on Approved | Workflow | Leave Approval action | Create std_student_attendance records within a transaction |
| BR-STD-036 | No Attendance on Reject / Cancel | Rejected or cancelled leave has no attendance impact | Workflow | Leave Rejection / Cancellation | Do not create or modify attendance records |
| BR-STD-037 | Partial Approval | Only approved_days get Leave attendance records | Calculation | Partial Leave Approval | Create records for first N approved days of range |
| BR-STD-038 | Auto-Log Status Changes | Every FSM transition logged as system remark | Workflow | Any Leave Status Change | Auto-insert remark with old_status, new_status, timestamp |
| BR-STD-039 | Student Response → Status Revert | Student reply reverts status to Submitted | Workflow | Student response posted | Set application status = Submitted; mark originating request as resolved |

---

### B.2 Validation & Edge-Case Catalog

| Field / Rule | Valid Example | Invalid Example | Boundary | Empty / Null | Concurrency Case | Expected Behaviour |
|---|---|---|---|---|---|---|
| Admission Number | "STD-2026-000042" | "STD-2025-000042" (existing) | Exactly unique | Not allowed (required) | Two admissions simultaneously with same auto-number | Lock counter with DB transaction; second call gets incremented number |
| Aadhar ID | "234567890123" (12 digits) | "12345" (too short) / "ABCD12345678" (non-numeric) | Exactly 12 digits | Null allowed (optional) | Two students submitted with same Aadhar | DB UNIQUE constraint rejects second insert |
| Guardian Mobile | "9876543210" | "98765" (too short) / existing mobile of another guardian | — | Not allowed (required) | Sibling added with same guardian mobile | Guardian record already exists; staff links existing record |
| Current Enrollment | One session as Current | Two sessions with is_current = 1 | Only one | Not allowed if student has sessions | Concurrent session saves | current_flag UNIQUE constraint rejects second; application transaction handles ordering |
| Attendance Date | Today or past date within enrollment | Future date / date outside enrollment period | Exactly today | Not allowed | Two teachers simultaneously marking attendance for same student | DB UNIQUE on (student_id, date, period) rejects duplicate |
| Bulk Attendance | All 40 students saved | Record 22 fails validation | — | Empty class list shows message | Two teachers submit bulk for same class simultaneously | Second insert hits UNIQUE constraint; both transactions see partial failures; all rollback |
| Leave Days | 3 days, leave type max = 5 | 8 days, leave type max = 5 | Exactly max_days_per_application | Not allowed (required) | Student submits while annual quota being updated | Validate at submission time against current approved total |
| Half-Day Leave | from_date = to_date | from_date ≠ to_date with is_half_day = 1 | Single day only | N/A | — | Reject with "Half-day only allowed for single-day applications" |
| Document Expiry | expiry_date in future | expiry_date = today - 1 (expired) | Exactly today (show warning) | Null = no expiry (no flag) | — | Flag as "Expired" in UI; document remains accessible |
| Photo Upload | image/jpeg MIME | application/pdf MIME with .jpg extension | — | Allowed (photo is optional) | — | Server validates MIME from file magic bytes; reject non-image |
| Profile Completion | All 5 stages present | Missing Previous Education only | 4/5 stages (incomplete) | New student with only account created | — | Show 20% completion; link to first incomplete tab |

---

## Section C — Process Flows + FSM Catalog {#section-c}

> Workflows are fully documented in FRD Section 6. This section provides the FSM catalog and a concise process flow summary.

### C.1 Leave Application FSM

**Entity:** Leave Application (`std_leave_applications`)
**Backed by:** `status` ENUM column (8 states)

| From State | Event / Action | Guard (Condition) | To State | Side-Effects |
|---|---|---|---|---|
| (none) | Student creates application | Student has active enrollment | Draft | Record created; visible only to student |
| Draft | Student submits | All required fields present; document if required | Submitted | System remark logged; teacher inbox updated |
| Submitted | Teacher opens application | Teacher assigned to student's class-section | Under Review | System remark logged |
| Under Review | Teacher approves | — | Approved | System remark logged; attendance auto-created for approved days |
| Under Review | Teacher rejects | Rejection remarks provided | Rejected | System remark logged; no attendance impact |
| Under Review | Teacher requests info | Query message provided | Info Requested | System remark logged; notification dispatched to student |
| Under Review | Teacher requests document | Document request message provided | Doc Requested | System remark logged; notification dispatched to student |
| Info Requested | Student responds | Response message provided | Submitted | Originating remark marked resolved; system remark logged; teacher notified |
| Doc Requested | Student uploads / responds | Document uploaded or response provided | Submitted | Originating remark marked resolved; system remark logged; teacher notified |
| Draft | Student cancels | Application not yet Approved or Rejected | Cancelled | System remark logged; no attendance impact |
| Submitted | Student cancels | Application not yet Approved or Rejected | Cancelled | System remark logged; no attendance impact |
| Info Requested | Student cancels | — | Cancelled | System remark logged |
| Doc Requested | Student cancels | — | Cancelled | System remark logged |

**Terminal States:** Approved, Rejected, Cancelled
**Illegal Transitions (must be blocked):** Cancelled → any state; Approved → any state; Rejected → any state; Draft → Approved (skip submit); Submitted → Approved (skip Under Review)

---

### C.2 Attendance Correction FSM

**Entity:** Attendance Correction Request (`std_attendance_corrections`)

| From State | Event | Guard | To State | Side-Effects |
|---|---|---|---|---|
| (none) | Student/Parent submits | Original attendance record exists | Pending | Teacher notified |
| Pending | Class Teacher approves Step 1 | Remarks provided | Approved (Step 1) | Admin notified for Step 2 |
| Pending | Class Teacher rejects | Remarks provided | Rejected | Student notified; attendance unchanged |
| Approved (Step 1) | Admin gives final approval | — | Approved | Attendance record updated; student notified |
| Approved (Step 1) | Admin rejects | Remarks provided | Rejected | Student notified; attendance unchanged |

**Terminal States:** Approved (final), Rejected

---

### C.3 Student Academic Session Status FSM

**Entity:** Academic Enrollment — Session Status (`session_status_id` → sys_dropdown_table)

| From State | Event | To State | Side-Effects |
|---|---|---|---|
| Active | Normal progression | Promoted | is_current set to 0; new enrollment created as Current |
| Active | Student transfers out | Left | Leaving date and reason required |
| Active | Disciplinary action | Suspended | Timetable eligibility set to No |
| Active | Student voluntarily withdraws | Withdrawn | Timetable eligibility set to No; leaving date required |
| Any | End of school career | Alumni | is_current set to 0 |

---

## Section D — Data Dictionary + Cross-Module Dependency Map {#section-d}

### D.1 Data Dictionary — Business View

> 19 `std_*` tables in tenant_db. All data isolated per school by DB connection context.

| Table (Business Name) | Business Purpose | Key Relationships | Soft Deletes | PII Level |
|---|---|---|---|---|
| Student Record (`std_students`) | Core student entity — identity, admission, status | Links to System Account (1:1) | Yes | High |
| Extended Profile (`std_student_profiles`) | Demographics, banking, government flags | Student (1:1) | Via migration | High |
| Address (`std_student_addresses`) | Multiple addresses per student | Student (1:N) | Via migration | Medium |
| Guardian (`std_guardians`) | Parent/guardian master record | Multiple students via junction | Via migration | Medium/High |
| Student-Guardian Link (`std_student_guardian_jnt`) | M:N relationship + relationship flags | Student + Guardian | Missing | Low |
| Academic Enrollment (`std_student_academic_sessions`) | Class-section + year assignment | Student + Class-Section | Missing | Low |
| Opted Subject (`std_student_opted_subjects`) | Subject choices per enrollment | Enrollment + Subject | Missing | Low |
| Previous Education (`std_previous_education`) | Prior school history | Student (1:N) | Via migration | Low |
| Student Document (`std_student_documents`) | Uploaded ID/cert files | Student (1:N) | Missing | Medium |
| Health Profile (`std_health_profiles`) | Medical background (1:1) | Student (1:1) | Missing | High |
| Vaccination Record (`std_vaccination_records`) | Immunization history | Student (1:N) | Missing | Medium |
| Medical Incident (`std_medical_incidents`) | School health events | Student (1:N) | Yes | High |
| Daily Attendance (`std_student_attendance`) | Per-day attendance log | Student + Class-Section | Missing | Low |
| Correction Request (`std_attendance_corrections`) | Attendance amendment requests | Attendance Record | Missing | Low |
| Leave Type (`std_leave_types`) | School-configured leave categories | (master) | Yes | Low |
| Leave Application (`std_leave_applications`) | Student leave requests | Student + Leave Type + Class-Section | Yes | Low |
| Leave Document (`std_leave_application_documents`) | Supporting files for leave | Leave Application | Yes | Low |
| Leave Remark (`std_leave_application_remarks`) | Teacher↔Student communication thread + audit log | Leave Application | No | Low |
| Student Pay Log (`std_student_pay_log`) | Transport-related payment log | Orphan — referenced by Transport module | No | Low |

**SoftDeletes Gap (5 tables missing):** `std_student_attendance`, `std_student_documents`, `std_health_profiles`, `std_vaccination_records`, `std_student_academic_sessions`

---

### D.2 Cross-Module Dependency Map

**STD consumes from (Inbound dependencies):**

| Source Module | Data / Entity | Why |
|---|---|---|
| SystemConfig (SYS) | `sys_users`, `sys_dropdowns`, `sys_dropdown_table` | Student/parent user creation; religion/caste/status dropdown values |
| SchoolSetup (SCH) | `sch_class_section_jnt`, `sch_org_academic_sessions_jnt`, `sch_subject_groups`, `sch_subjects`, `sch_study_formats` | Session enrollment; class assignment; subject selection |
| GlobalMaster (GLB) | `glb_cities`, `glb_languages` | Address city lookup; guardian preferred language |
| Spatie MediaLibrary | `sys_media` | Student photo and document file storage |

**STD provides to (Outbound — downstream modules depend on std_* data):**

| Consumer Module | Mechanism | Data Provided | Risk if STD unavailable |
|---|---|---|---|
| StudentFee (FIN) | FK + direct model imports | `std_students.id`, `std_student_guardian_jnt.is_fee_payer` | Fee assignment, invoice, sibling discount broken | HIGH |
| StudentPortal (STP) | Direct read of all std_* tables | Full student profile, attendance, session data | Portal entirely broken | HIGH |
| ParentPortal (PPT) | FK reads | `std_guardians`, `std_student_guardian_jnt` | Parent cannot view child data | HIGH |
| MarksheetGeneration (MSG) | FK reads | `std_students`, `std_student_academic_sessions` | Marksheet generation broken | HIGH |
| SmartTimetable (TT) | Flag read | `std_student_academic_sessions.count_for_timetable` | Incorrect timetable slot counts | Medium |
| Transport (TPT) | FK + `std_student_pay_log` | `std_students`, transport payment logs | Transport allocation broken | Medium |
| LmsHomework | FK read | `std_student_academic_sessions.class_section_id` | Homework assignment by class broken | Medium |
| LmsExam | FK read | `std_student_academic_sessions`, `std_students` | Exam student groups broken | Medium |
| BehaviouralAssessment (BHA) | FK read | `std_students` | Remark tracking broken | Low |
| Recommendation (REC) | FK read | `std_students` | Student recommendations broken | Low |
| Notification | Junction flag read | `std_student_guardian_jnt.can_receive_notifications`, `.notification_preference` | Guardian notification dispatch broken | Medium |

**Reversed Coupling (architectural risk — must be resolved):**

The `Student` model (`Modules/StudentProfile/app/Models/Student.php`) currently imports from three downstream modules:
- `Modules\StudentFee\Models\FeeStudentAssignment`
- `Modules\Transport\Models\StudentPayLog`
- `Modules\StudentPortal\Models\ExamAttempt` / `ExamResult`

If any of these modules is disabled, the `Student` model throws a class-not-found error, making the entire StudentProfile module unusable. The correct pattern is for downstream modules to own their FK relationships pointing to `std_students.id` — StudentProfile must not import from modules that depend on it.

---

## Section E — NFR Catalog + Risk Register {#section-e}

### E.1 NFR Catalog

| NFR-ID | Category | Requirement | Acceptance Threshold |
|---|---|---|---|
| NFR-STD-001 | Performance | Student list page load | < 2 seconds for 10,000+ student school |
| NFR-STD-002 | Performance | Student omni-search response | < 2 seconds |
| NFR-STD-003 | Performance | Bulk attendance save (500 students) | No timeout; completes < 10 seconds |
| NFR-STD-004 | Performance | Large Excel export (500+ students) | Queued asynchronously; HTTP request returns immediately |
| NFR-STD-005 | Performance | Profile completion % per student | < 200 ms; bulk queries must use cache or computed column |
| NFR-STD-006 | Security | No privilege escalation on student account creation | Zero occurrences of is_super_admin in form or payload |
| NFR-STD-007 | Security | All permission-protected routes enforce authorization | 100% coverage; no unauthorized data access possible |
| NFR-STD-008 | Security | Aadhar ID encrypted at rest | UIDAI compliance; encrypted cast in model |
| NFR-STD-009 | Security | Bank account number encrypted at rest | Financial PII compliance |
| NFR-STD-010 | Security | File MIME validation server-side | All upload endpoints validate content-based MIME |
| NFR-STD-011 | Security | QR code payload does not expose Admission Number | QR payload = hash/UUID; no raw admission_no |
| NFR-STD-012 | Security | Rate limiting on bulk operations | Bulk attendance, bulk export: rate-limited per IP/user |
| NFR-STD-013 | Security | Medical/health record access logging | All reads of health profile and incidents logged |
| NFR-STD-014 | Usability | New student admission completable in under 5 minutes | P95 task completion < 5 min in user testing |
| NFR-STD-015 | Usability | Multi-tab form shows completion status and links to first incomplete tab | Visual indicator on all 5 tabs; direct link to first incomplete |
| NFR-STD-016 | Usability | Photo displays immediately after upload | No full page reload required |
| NFR-STD-017 | Compliance | Aadhar ID: 12-digit numeric validation | Input rejected if not 12 numeric digits |
| NFR-STD-018 | Compliance | APAAR ID: 12-digit format validation | Input rejected if wrong format |
| NFR-STD-019 | Compliance | Caste categories: SC, ST, OBC, General present | Mandatory dropdown values for government reporting |
| NFR-STD-020 | Compliance | Admission Register format per state department | Format verified by admin before deployment |
| NFR-STD-021 | Compliance | RTE and EWS flags capturable | Fields present and saved for government-aided schools |
| NFR-STD-022 | Scalability | Data isolated per school — no cross-tenant access | Database-per-tenant architecture; no tenant_id column needed |
| NFR-STD-023 | Availability | Module must not create hard dependency on downstream modules | Student model must not import from StudentFee, Transport, or StudentPortal |

---

### E.2 Risk Register

| Risk ID | Risk | Category | Likelihood | Impact | Mitigation | Owner | Early Warning |
|---|---|---|---|---|---|---|---|
| RISK-STD-001 | `is_super_admin` not removed — attacker creates super-admin account via student creation endpoint | Security | H | H | Remove field from validation and User::create() payload immediately; remove from view toggle | Tech Lead | Any student creation audit log review |
| RISK-STD-002 | Wrong permission prefix (`school-setup.student.*`) causes silent authorization failure on 5+ StudentController methods | Security | H | H | Replace all active Gate calls with correct `tenant.student.*` prefix | Developer | Permission audit; check method-level Gate calls |
| RISK-STD-003 | Aadhar ID stored in plaintext — UIDAI compliance violation; data breach exposure | Compliance | M | H | Add encrypted cast to Student model; migrate existing data; handle search impact | Tech Lead / Legal | Any security audit |
| RISK-STD-004 | Student model hard-imports from downstream modules — if StudentFee or Transport disabled, all StudentProfile pages crash | Architecture | M | H | Remove imports from Student.php; let downstream modules own their FK relationships | Architect | Module disable / test environment |
| RISK-STD-005 | Excel export for large schools (1000+ students) runs synchronously — PHP timeout or memory exhaustion | Performance | H (large schools) | M | Queue export via ShouldQueue interface; return download link | Developer | School with 500+ students exports |
| RISK-STD-006 | `current_flag` not a GENERATED STORED column — application code must manually synchronize it | Data Integrity | M | M | Enforce: any code setting is_current = 1 must also set current_flag = student_id in same transaction | Developer | Session assignment bugs |
| RISK-STD-007 | Zero HTTP Feature tests — regressions (including P0 exploits) not caught automatically | Quality | H | H | Write minimum test suite covering: is_super_admin regression, attendance auth, student CRUD, guardian mobile | Testing Lead | CI pipeline failures |
| RISK-STD-008 | Attendance Correction workflow partially built (table + model only) — students cannot formally request corrections | Feature Gap | H | M | Implement AttendanceCorrectionController, routes, and two-step approval UI | Developer | Teacher complaints; attendance disputes |
| RISK-STD-009 | Leave application auto-attendance not implemented — approving leave does not mark attendance as Leave | Feature Gap | M | M | Implement attendance-creation logic on leave approval | Developer | Leave approved but attendance shows Absent |
| RISK-STD-010 | StdLeaveController Gate::authorize commented out — any authenticated user can approve or reject leave | Security | M | H | Uncomment and verify Gate::authorize on all leave management methods | Developer | Unauthorized leave approvals |

---

## Section F — Prioritization + Effort Estimation {#section-f}

### F.1 MoSCoW Prioritization

**Must Have (P0 — Core):**
- REQ-STD-001 Student List & Search
- REQ-STD-002 Student System Account Creation (with SEC fix)
- REQ-STD-003 Student Demographic Profile
- REQ-STD-004 Address Management
- REQ-STD-005 Student Photo Management
- REQ-STD-006 Guardian Management
- REQ-STD-008 Academic Session Enrollment
- REQ-STD-010 Previous Education History
- REQ-STD-011 Student Document Upload & Verification
- REQ-STD-012 Health Profile
- REQ-STD-014 Medical Incident Log
- REQ-STD-015 Daily Attendance Marking
- REQ-STD-017 Student Status Management

**Should Have (P1 — Standard):**
- REQ-STD-007 Parent Portal Access Granting
- REQ-STD-009 Subject Selection per Enrollment
- REQ-STD-013 Vaccination Records
- REQ-STD-016 Attendance Correction Workflow (partial build — needs completion)
- REQ-STD-018 Profile Completion Tracking
- REQ-STD-019 Student Credential Management
- REQ-STD-020 Student Data Export
- REQ-STD-021 Leave Type Configuration
- REQ-STD-022 Leave Application Submission
- REQ-STD-023 Leave Review & Teacher Decision
- REQ-STD-024 Leave Communication Thread
- REQ-STD-025 Auto Attendance Update on Leave Approval
- REQ-STD-026 Administrative Reports

**Could Have (P2 — Enhanced):**
- ENH-STD-001 Student Promotion Wizard
- ENH-STD-002 Transfer Certificate Generation
- ENH-STD-003 Bulk Student Import
- ENH-STD-004 CSV Export
- ENH-STD-005 < 75% Attendance Notification
- ENH-STD-007 REST API

**Won't Have (this release):**
- ENH-STD-006 ID Card Printing Automation (hardware dependency)

---

### F.2 Effort Estimation & Sprint Task Breakdown

> Based on complexity comparison to Hostel (36 tables, ~100h) and Library (30 tables, ~80h). STD has 19 tables but significant security debt and architectural concerns.

**Sprint 0 — Security & Architecture (8 person-days)**

| # | Task | Type | Effort (h) | Depends On | Priority |
|---|---|---|---|---|---|
| 1 | Remove is_super_admin from StudentController + view | Security Fix | 2h | — | P0 |
| 2 | Fix wrong permission prefix (school-setup → tenant) on 5+ active Gate calls | Security Fix | 3h | — | P0 |
| 3 | Add `'aadhar_id' => 'encrypted'` cast; handle search impact | Security Fix | 4h | — | P0 |
| 4 | Encrypt bank_account_no in StudentProfile model | Security Fix | 2h | Task 3 | P1 |
| 5 | Remove hard cross-module imports from Student.php | Refactor | 4h | — | P1 |
| 6 | Uncomment Gate::authorize in StdLeaveController (lines 25, 250) | Security Fix | 1h | — | P0 |

**Sprint 1 — FormRequests & Authorization (6 person-days)**

| # | Task | Type | Effort (h) | Depends On |
|---|---|---|---|---|
| 7 | CreateStudentLoginRequest (no is_super_admin; email unique) | FormRequest | 2h | Task 1 |
| 8 | CreateStudentDetailsRequest (admission_no unique; aadhar 12-digit; DOB before today) | FormRequest | 3h | Task 3 |
| 9 | CreateGuardianRequest (mobile unique; relation_type enum) | FormRequest | 2h | — |
| 10 | CreateSessionRequest (no duplicate year; leaving date conditional) | FormRequest | 3h | — |
| 11 | StoreAttendanceRequest + StoreBulkAttendanceRequest | FormRequest | 3h | — |
| 12 | UpdateHealthProfileRequest | FormRequest | 2h | — |
| 13 | Register GuardianPolicy, StudentDocumentPolicy, LeaveApplicationPolicy | Authorization | 3h | — |
| 14 | Uncomment / re-implement activityLog() in StudentController (lines 3852, 3916, 3979) | Audit | 2h | — |
| 15 | Add activityLog() to StdLeaveController and StudentLeaveTypeController | Audit | 2h | — |

**Sprint 2 — Missing Workflows (8 person-days)**

| # | Task | Type | Effort (h) | Depends On |
|---|---|---|---|---|
| 16 | Add SoftDeletes to 5 tables (attendance, documents, health, vaccination, sessions) | Schema | 4h | — |
| 17 | Implement AttendanceCorrectionController + routes (two-step approval) | Backend | 8h | Sprint 1 |
| 18 | Implement leave approval → auto-attendance creation (BR-STD-035) | Backend | 6h | Task 6 |
| 19 | Implement BR-STD-038/039 (auto-remark on status change; student response → status revert) | Backend | 4h | — |
| 20 | Queue Excel export via ShouldQueue (StudentsExport) | Performance | 2h | — |
| 21 | Wrap storeBulkAttendance in DB transaction | Backend | 2h | Sprint 1 |

**Sprint 3 — Test Coverage (5 person-days)**

| # | Task | Type | Effort (h) | Depends On |
|---|---|---|---|---|
| 22 | Feature test: is_super_admin cannot be set (SEC regression) | Testing | 3h | Sprint 0 |
| 23 | Feature test: attendance authorization (all 6 methods) | Testing | 3h | Sprint 1 |
| 24 | Feature test: student CRUD lifecycle (create → edit → delete → restore → force-delete) | Testing | 4h | Sprint 1 |
| 25 | Feature test: guardian duplicate mobile rejected | Testing | 2h | Sprint 1 |
| 26 | Feature test: current enrollment uniqueness | Testing | 2h | Sprint 1 |
| 27 | Feature test: bulk attendance rollback on partial failure | Testing | 3h | Sprint 2 |

**Sprint 4 — Enhancements (10+ person-days)**

| # | Task | Type | Effort (h) |
|---|---|---|---|
| 28 | Student Promotion Wizard (ENH-STD-001) | Backend + Frontend | 16h |
| 29 | Transfer Certificate PDF generation (ENH-STD-002) | Backend + PDF | 8h |
| 30 | Bulk student import Excel/CSV (ENH-STD-003) | Backend | 10h |
| 31 | REST API endpoints for mobile app (ENH-STD-007) | API | 8h |

**Total Remediation Estimate:** Sprint 0–3 = ~38 person-days | Sprint 4 = ~21 additional person-days

---

## Section G — User Stories + Acceptance Criteria (P0 / P1 REQs) {#section-g}

### US-STD-001 (REQ-STD-001): View and Find Any Student

**As a** School Admin, **I want to** search the student list by name, admission number, or mobile **so that** I can quickly locate any student without scrolling.

**Acceptance Criteria:**
```
Scenario: Happy path search
  Given I am logged in as School Admin with View Students permission
  When I enter "Rahul" in the search field and submit
  Then the student list shows only students whose name contains "Rahul"
  And the list is paginated at 12 per page

Scenario: Filter by status
  Given I am viewing the student list
  When I select filter "Inactive"
  Then only students with is_active = No are shown

Scenario: Permission denied
  Given a user without the View Students permission
  When they navigate to the student list URL
  Then they receive an "Access Denied" response
```

---

### US-STD-002 (REQ-STD-002): Create a Student Login Account

**As a** Registrar, **I want to** create a system login for a new student **so that** the student can access the school portal immediately.

**Acceptance Criteria:**
```
Scenario: Happy path
  Given I am logged in as Registrar with Create Student permission
  When I submit the account creation form with valid name, email, and password
  Then a student system account is created with Student role
  And a welcome email is sent to the student's email
  And the system auto-assigns a unique Student Code (format: STD-YYYY-NNNNNN)

Scenario: Duplicate email rejected
  Given a student already exists with email "john@example.com"
  When I submit a new student form with the same email
  Then the form is rejected with "Email already in use"

Scenario: Privilege escalation blocked
  Given any user submits a student creation form with is_super_admin=true in the payload
  Then the is_super_admin value is ignored
  And the created account does NOT have super-admin rights

Scenario: Permission denied
  Given a Class Teacher (no Create Student permission)
  When they attempt to submit the student creation form
  Then they receive an Access Denied error
```

---

### US-STD-008 (REQ-STD-008): Assign Student to Academic Session

**As a** School Admin, **I want to** assign a student to their class-section for an academic year **so that** the student appears in the correct class lists and attendance sheets.

**Acceptance Criteria:**
```
Scenario: Happy path
  Given the student has an active account
  When I create an enrollment for Academic Year 2026-27 in Class 9-A
  Then the enrollment is saved and marked as Current
  And any previous Current enrollment is automatically marked Historical within the same DB transaction

Scenario: Duplicate year rejected
  Given the student is already enrolled in Academic Year 2026-27
  When I try to create a second enrollment for the same year
  Then the system rejects with "Student already enrolled in this academic year"

Scenario: Left status requires leaving date
  Given I set Session Status to "Left"
  When I try to save without a Leaving Date and Reason
  Then the form rejects with validation errors on both fields

Scenario: Empty state — first enrollment
  Given a student with no enrollments
  When I view the Session tab
  Then an empty state message is shown with a prompt to add the first enrollment
```

---

### US-STD-015 (REQ-STD-015): Mark Daily Attendance

**As a** Class Teacher, **I want to** mark attendance for my class **so that** the school has an accurate daily record of who was present.

**Acceptance Criteria:**
```
Scenario: Happy path (bulk class)
  Given I am logged in as Class Teacher with Mark Attendance permission
  When I submit a bulk attendance form for my class of 40 students
  Then all 40 attendance records are saved in a single transaction
  And the student list shows today's attendance status for each student

Scenario: QR scan
  Given a student presents their QR code
  When the system validates the QR payload
  Then an attendance record is created for that student for today

Scenario: Duplicate attendance rejected
  Given attendance has already been marked for student X on today
  When I try to mark attendance again for the same student and date
  Then the second attempt is rejected

Scenario: Permission denied
  Given an Accountant (no Mark Attendance permission)
  When they attempt to access the attendance URL
  Then they receive Access Denied

Scenario: Partial bulk failure rollback
  Given 40 students in bulk form
  When record 22 fails (e.g., invalid status value)
  Then all 40 records are rolled back
  And no partial save occurs
```

---

### US-STD-022 (REQ-STD-022): Submit a Student Leave Application

**As a** Student, **I want to** submit a digital leave application **so that** my class teacher can review and approve my absence officially.

**Acceptance Criteria:**
```
Scenario: Happy path
  Given I am a Student with an active enrollment
  When I submit a leave application for Sick Leave for 2 days with a reason
  Then the application is created with status "Submitted"
  And the system routes it to my class teacher
  And a status-change remark is auto-logged

Scenario: Half-day rejected for multi-day
  Given I check "Half Day" on a leave application with from_date ≠ to_date
  Then the submission is rejected with "Half-day only valid for single-day applications"

Scenario: Max days exceeded
  Given the Sick Leave type has max_days_per_application = 3
  When I apply for 5 days of Sick Leave
  Then the submission is rejected with the policy limit message

Scenario: Document required
  Given Medical Leave requires a supporting document
  When I submit a Medical Leave application without any attachment
  Then the submission is rejected with "Medical leave requires a supporting document"

Scenario: Cancel before decision
  Given my leave application is in "Submitted" status
  When I cancel the application
  Then status changes to "Cancelled"
  And no attendance records are created or modified
```

---

### US-STD-025 (REQ-STD-025): Auto-Update Attendance on Leave Approval

**As a** School Admin / Class Teacher, **I want** attendance to be automatically updated when I approve a leave application **so that** approved leave days do not appear as "Absent" on reports.

**Acceptance Criteria:**
```
Scenario: Full approval
  Given a leave application for 3 days is in "Submitted" status
  When I approve with approved_days = 3
  Then 3 attendance records are created with status "Leave" for the 3 days
  And the application status changes to "Approved"

Scenario: Partial approval
  Given a leave application for 5 days
  When I approve with approved_days = 3
  Then exactly 3 attendance records (for the first 3 days) are created with status "Leave"

Scenario: Rejection — no attendance impact
  Given a leave application is in "Submitted" status
  When I reject the application
  Then no attendance records are created or modified
  And the application status changes to "Rejected"
```

---

## Section H — Reporting & KPI Specification {#section-h}

### RPT-STD-001: Admission Register (Detailed)

| Attribute | Value |
|---|---|
| Purpose | Official chronological record of all student admissions; government inspection ready |
| Audience | Principal, School Admin, Registrar, Government Inspector |
| Frequency | On demand; typically printed at term start and for government visits |
| Contents | Serial No. (row), Admission Number, Full Name, Date of Admission, Date of Birth, Gender, Category (SC/ST/OBC/General/Other), Class-Section, Academic Year, Current Status |
| Filters | Academic Year (required), Class, Section, Gender, Category, Status |
| Grouping | By Class, then Section, then Admission Number ascending |
| Export | PDF (print-ready; A4 landscape) |
| Rule | Format must comply with applicable state education department circular |

### RPT-STD-002: Student Strength Report (Detailed)

| Attribute | Value |
|---|---|
| Purpose | Class-wise student head count for planning and government submission |
| Audience | Principal, School Admin |
| Frequency | On demand; monthly for government reports |
| Contents | Class | Section | Boys | Girls | Total; Grand Total row at bottom |
| Filters | Academic Year (required) |
| Grouping | By Class ascending, then Section |
| Export | PDF, Excel |

### RPT-STD-003: Medical Profile Report (Detailed)

| Attribute | Value |
|---|---|
| Purpose | Emergency preparedness; medical staff awareness; health planning |
| Audience | Medical Staff, Principal, School Admin |
| Frequency | On demand; updated each term |
| Contents (3 sub-reports) | (1) Blood group distribution: Group → Count → % of students; (2) Students with chronic conditions: Name, Class, Condition; (3) Students with allergies: Name, Class, Allergy description |
| Filters | Class, Section, Blood Group |
| Export | PDF |

### KPI Catalog

| KPI | Definition | Source Data | Target | Cadence |
|---|---|---|---|---|
| Profile Completion Rate | % of students with all 5 profile stages complete | std_student_profiles, std_guardians, std_student_academic_sessions, std_previous_education | ≥ 95% | Monthly |
| Attendance Rate | (Present + Leave) / Total School Days × 100 per student | std_student_attendance | ≥ 75% per student | Weekly |
| Admission Register Currency | % of students with Admission Number assigned | std_students | 100% | On admission |
| Below-75% Attendance Count | Number of students with attendance < 75% in current term | std_student_attendance | 0 | Weekly |
| Leave Approval Cycle Time | Average hours from submission to final decision | std_leave_applications | < 48 hours | Monthly |
| Guardian Linkage Rate | % of students with at least one linked guardian | std_student_guardian_jnt | 100% | Monthly |

---

## Section I — Feature Specification (Key Screens) {#section-i}

### Screen 1: Student List (index)

**Route:** `GET /student`
**Layout:** Card grid (2–4 per row) with search/filter sidebar
**Actors:** All roles (read); Admin/Registrar (actions)

| # | Field (Label) | Type | Required | Notes |
|---|---|---|---|---|
| 1 | Search | Text input | No | Searches: admission no, name, code, email, mobile |
| 2 | Status Filter | Dropdown | No | All / Active / Inactive |
| 3 | Profile Filter | Dropdown | No | All / Complete / Incomplete |

**Card Actions:** View Profile, Edit, Delete (Admin only)
**List Actions:** Export Excel, Export PDF, Send Credentials (checkbox selection)
**Pagination:** 12 per page; newest first
**Empty State:** "No students found. Click '+ New Admission' to add the first student."
**Permissions:** `tenant.student.viewAny` required

---

### Screen 2: Student Create / Edit — 8-Tab Form

| Tab | Route / Action | Key Fields | Required Completion |
|---|---|---|---|
| Tab 1: Account | POST create-student-login | Email, Short Name, Password (confirm), Photo, 2FA, Is Active | Always |
| Tab 2: Details | POST create-student-details | Full Name, DOB, Gender, Admission No, Aadhar, APAAR, Religion, Caste, Nationality, Bank, RTE/EWS, Height/Weight | Always |
| Tab 2 (cont): Addresses | POST create-address | Address Type, Line, City, Pincode, Is Primary | Optional |
| Tab 3: Parents | POST create-parent-details | Guardian First/Last Name, Gender, Mobile, Relation Type, Junction Flags | At least 1 guardian |
| Tab 4: Session | POST create-student-session | Academic Year, Class-Section, Roll No, Status, Is Current | At least 1 session |
| Tab 4 (cont): Subjects | POST opted-subjects | Subject, Study Format, Is Optional | Optional |
| Tab 5: Previous Education | POST create-prev-edu | School Name, Board, Class Passed, Year, TC Number | At least 1 record |
| Tab 6: Documents | PUT student-document | Document Name, Type, File Upload, Issue/Expiry Date | Optional |
| Tab 7: Health | POST/PUT health-profile | Blood Group, Allergies, Chronic Conditions, Vision | Optional |
| Tab 8: Leave | Managed separately | (View only in student context) | — |

**Progress Indicator:** Completion percentage and first incomplete tab link shown at top of edit view.
**Permissions:** Varies per tab — `tenant.student.create` / `tenant.student.update`

---

### Screen 3: Leave Application List (Teacher Review Inbox)

**Route:** `GET /student-leave`
**Layout:** Table with status badges and action buttons
**Actor:** Class Teacher (filtered to own class section)

| Column | Notes |
|---|---|
| Student Name + Class | Student with class-section badge |
| Leave Type | Leave type code and name |
| Date Range | From – To; total days |
| Status | Badge: Submitted / Under Review / Info Requested / Doc Requested |
| Applied On | Date submitted |
| Actions | Review (open detail), Approve, Reject, Request Info, Request Doc |

**Filters:** Status, Class-Section, Date Range
**Empty State:** "No pending leave applications for your class."
**Permissions:** `tenant.student-leave.viewAny` required; filtered to teacher's class section

---

## Section J — Requirements-vs-Code Gap Analysis {#section-j}

> This is the BA-level requirements coverage gap analysis. For deep code/security/tenancy gaps, refer the Technical Auditor (Mode X). Gaps listed here are requirement-coverage oriented.

### J.1 P0 Gaps (Production Blockers)

| Gap ID | REQ Ref | BR Ref | Gap Description | Evidence | Remediation |
|---|---|---|---|---|---|
| GAP-STD-P0-01 | REQ-STD-002 | NFR-STD-006 | Privilege escalation: is_super_admin present in validation rules and User::create() payload in createStudentLogin() | StudentController.php:391,412; view _student-login.blade.php:124,165 | Remove from validation, payload, and view — Sprint 0 Task 1 |
| GAP-STD-P0-02 | REQ-STD-003 | NFR-STD-007 | Wrong permission prefix: active Gate::authorize calls use 'school-setup.student.*' instead of 'tenant.student.*' | StudentController.php lines ~1090, 1212, 1316, 1892, 2528 | Replace prefix on all active calls — Sprint 0 Task 2 |
| GAP-STD-P0-03 | REQ-STD-021–024 | NFR-STD-007 | Leave management Gate::authorize commented out in StdLeaveController | StdLeaveController.php:25,250 | Uncomment and verify — Sprint 0 Task 6 |

### J.2 P1 Gaps (High Priority — This Sprint)

| Gap ID | REQ Ref | BR Ref | Gap Description | Code Evidence | Remediation |
|---|---|---|---|---|---|
| GAP-STD-P1-01 | REQ-STD-002–015 | — | Zero FormRequests for all student-facing create/update routes | StudentController uses inline Validator::make() and $request->all() throughout | Create 12 FormRequest classes — Sprint 1 Tasks 7–12 |
| GAP-STD-P1-02 | REQ-STD-017 | — | activityLog() commented out in StudentController for delete, restore, force-delete | StudentController.php:3852, 3916, 3979 | Uncomment / re-implement — Sprint 1 Task 14 |
| GAP-STD-P1-03 | REQ-STD-021–024 | — | activityLog() absent from StdLeaveController and StudentLeaveTypeController | Neither controller calls activityLog() | Add calls — Sprint 1 Task 15 |
| GAP-STD-P1-04 | REQ-STD-006, 011, 014, 021–024 | — | Policies absent for: Guardian, StudentDocument, MedicalIncident, LeaveApplication, LeaveType | StudentProfileServiceProvider registers only StudentPolicy + AttendancePolicy | Register 5 missing policies — Sprint 1 Task 13 |
| GAP-STD-P1-05 | REQ-STD-016 | BR-STD-025,026 | Attendance Correction workflow: controller and routes entirely absent | std_attendance_corrections table and StudentAttendanceCorrection model exist; no routes or controller | Implement AttendanceCorrectionController — Sprint 2 Task 17 |
| GAP-STD-P1-06 | REQ-STD-025 | BR-STD-035 | No auto-attendance creation on leave approval | No attendance-creation code in leave approval path | Implement attendance trigger on Approved — Sprint 2 Task 18 |
| GAP-STD-P1-07 | REQ-STD-015 | BR-STD-028 | Bulk attendance not wrapped in DB transaction | storeBulkAttendance() — no DB::transaction() | Wrap in transaction — Sprint 2 Task 21 |
| GAP-STD-P1-08 | Multiple | NFR-STD-008,009 | Aadhar ID and bank account stored in plaintext | Student model: no encrypted cast on aadhar_id; StudentProfile: no cast on bank_account_no | Add encrypted casts — Sprint 0 Tasks 3–4 |
| GAP-STD-P1-09 | REQ-STD-008 | BR-STD-014 | current_flag is a plain nullable INT, not a GENERATED STORED column as specified in DDL v1.6 | Migration 2026_06_15_151307 — column is regular INT; DDL says GENERATED ALWAYS AS STORED | Any code setting is_current must also manually set current_flag; migration to add GENERATED column recommended |

### J.3 P2 Gaps (Medium — Next Sprint)

| Gap ID | REQ Ref | Gap Description | Remediation |
|---|---|---|---|
| GAP-STD-P2-01 | REQ-STD-011, 012, 015, 013 | SoftDeletes missing from 5 tables: std_student_attendance, std_student_documents, std_health_profiles, std_vaccination_records, std_student_academic_sessions | Add deleted_at column via alter-table migrations — Sprint 2 Task 16 |
| GAP-STD-P2-02 | Multiple | Student model imports from downstream modules (StudentFee, Transport, StudentPortal) — coupling reversal | Remove imports; let downstream modules own FK relationships — Sprint 0 Task 5 |
| GAP-STD-P2-03 | REQ-STD-020 | Excel export synchronous — risk for 500+ student schools | Queue via ShouldQueue — Sprint 2 Task 20 |
| GAP-STD-P2-04 | REQ-STD-024 | Leave application status-change auto-logging as system remark needs verification | Verify and implement if absent — Sprint 2 Task 19 |
| GAP-STD-P2-05 | REQ-STD-024 | Student response → status revert to Submitted logic not confirmed in code | Verify BR-STD-039 enforcement — Sprint 2 Task 19 |
| GAP-STD-P2-06 | REQ-STD-008 | BR-STD-018: Timetable Eligibility auto-set on Suspended/Withdrawn not confirmed | Verify and add if absent — Sprint 2 |
| GAP-STD-P2-07 | REQ-STD-011 | Expired document flag (BR-STD-020) absent from document listing view | Add UI flag and query filter — Sprint 2 |
| GAP-STD-P2-08 | REQ-STD-009 | Subject Selection per Enrollment (std_student_opted_subjects) — model and table exist; no confirmed UI or dedicated routes | Implement SubjectOptController or integrate into Session tab — Sprint 3 |

### J.4 P3 / Backlog Gaps

| Gap ID | REQ / ENH Ref | Gap |
|---|---|---|
| GAP-STD-P3-01 | ENH-STD-001 | Student Promotion Wizard not started |
| GAP-STD-P3-02 | ENH-STD-002 | Transfer Certificate PDF generation not started (tc_issued flag migration exists) |
| GAP-STD-P3-03 | ENH-STD-003 | Bulk student import (Excel) not implemented |
| GAP-STD-P3-04 | ENH-STD-004 | CSV export not available (Excel + PDF only) |
| GAP-STD-P3-05 | ENH-STD-005 | Attendance < 75% notification trigger not implemented |
| GAP-STD-P3-06 | REQ-STD-003 | BR-STD-006: QR code payload review — may expose raw admission_no |
| GAP-STD-P3-07 | All | Zero HTTP Feature tests — entire module untested at integration level |
| GAP-STD-P3-08 | — | Debug artifact `edit.blade.bkp` present in views directory; should be removed |
| GAP-STD-P3-09 | — | `std_student_pay_log` is an orphan table — no STD model; ownership ambiguity with Transport module |

---

## Module Knowledge Update

> After producing this Complete Analysis Pack, the module knowledge file at
> `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/module-knowledge/STD_StudentProfile.md`
> has been kept current (version 1.0 seeded on 2026-06-30 with identical findings). No update required beyond adding the FRD reference and Complete Pack reference.

**FRD Summary:**
- FRD File: `STD_FRD_2026-06-30.md`
- REQ Count: 26 (P0=12, P1=14)
- BR Count: 39
- Workflow Count: 6
- Report Count: 3
- ENH Count: 7
- Complete Pack: `STD_FRD_Complete_2026-06-30.md`

---

*Complete Analysis Pack generated by pa-business-analyst agent | 2026-06-30*
*All IDs (REQ-/BR-/RPT-/ENH-) originate in STD_FRD_2026-06-30.md and are referenced here without renumbering.*
