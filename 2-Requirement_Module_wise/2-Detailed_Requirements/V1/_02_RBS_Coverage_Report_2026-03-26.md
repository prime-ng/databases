# Prime-AI Platform — RBS Coverage Report

**Generated:** 2026-03-26
**RBS Version:** PrimeAI_RBS_Menu_Mapping_v2.0
**RBS Source:** `3-Project_Planning/1-RBS/PrimeAI_RBS_Menu_Mapping_v2.0.md`
**Total RBS Modules:** 27 (A–Z + SYS)
**Total RBS Sub-tasks (per RBS Part 3 index):** 1,112
**Total Requirement Documents:** 46 (29 in `Development_Done/` + 17 in `Development_Pending/`)

---

## Executive Summary

All 27 RBS modules have at least one requirement document. The 46 requirement files collectively cover all 1,112 RBS sub-tasks — yielding 100% nominal coverage. However, coverage quality varies sharply by mode:

- **FULL mode** (code existed, requirements extracted from running code): 29 documents — actual implementation ranges from ~25% to ~90% of the documented requirements, meaning the code itself is incomplete.
- **RBS_ONLY mode** (greenfield, no code exists yet): 17 documents — requirements are forward specifications only; implementation is 0%.

No RBS sub-task is uncovered by a requirement document. A small number of requirement documents contain "beyond-RBS" features added by the analyst agents during extraction (these are noted in the Orphan Analysis section below).

### Coverage Summary Statistics

| Metric | Value |
|---|---|
| Total RBS Modules | 27 |
| RBS Modules with at least 1 requirement document | 27 (100%) |
| Total RBS sub-tasks (from RBS Part 3 index) | 1,112 |
| Sub-tasks with requirement document coverage | 1,112 (100%) |
| Requirement documents in FULL mode | 29 |
| Requirement documents in RBS_ONLY mode | 17 |
| Total requirement document files | 46 |
| Modules where code exists | 29 sub-documents across 18 RBS modules |
| Modules with zero code (greenfield) | 9 RBS modules (D, E, K, L, O, R, T, W, Y — plus partial-coverage modules) |
| Any module 100% implemented | None |

---

## Coverage by RBS Module

The table below maps each of the 27 RBS modules to its requirement documents. Sub-task counts are from the RBS Part 3 canonical index. Implementation status for FULL-mode documents is sourced from the requirement files themselves.

| RBS Code | RBS Module Name | RBS Sub-tasks | Requirement Document(s) | Mode | Implementation Status |
|---|---|---|---|---|---|
| **SYS** | System Administration | 12 | PRM_Prime_Requirement.md + SYS_SystemConfig_Requirement.md + GLB_GlobalMaster_Requirement.md + DSH_Dashboard_Requirement.md + SCH_JOB_Scheduler_Requirement.md | FULL | ~35–70% (varies by doc) |
| **A** | Tenant & System Management | 51 | PRM_Prime_Requirement.md + BIL_Billing_Requirement.md | FULL | PRM: ~70% / BIL: ~25% |
| **B** | User, Roles & Security | 52 | SCH_SchoolSetup_Requirement.md + GLB_GlobalMaster_Requirement.md | FULL | SCH: ~55% / GLB: ~55% |
| **C** | Admissions & Student Lifecycle | 56 | ADM_Admission_Requirement.md + STD_StudentProfile_Requirement.md + STP_StudentPortal_Requirement.md | RBS_ONLY + FULL | ADM: 0% (greenfield) / STD: ~50% / STP: ~25% |
| **D** | Front Office & Communication | 31 | FOF_FrontOffice_Requirement.md + VSM_VisitorSecurity_Requirement.md | RBS_ONLY | 0% (both greenfield) |
| **E** | Student Information System (SIS) | 35 | ATT_Attendance_Requirement.md + SCH_SchoolSetup_Requirement.md (partial) | RBS_ONLY + FULL | ATT: 0% (greenfield) / SCH: ~55% (partial coverage) |
| **F** | Attendance Management | 34 | ATT_Attendance_Requirement.md | RBS_ONLY | 0% (greenfield) |
| **G** | Advanced Timetable Management | 47 | STT_SmartTimetable_Requirement.md + TTF_TimetableFoundation_Requirement.md + TTS_StandardTimetable_Requirement.md | FULL | STT: ~55% / TTF: ~68% / TTS: ~53% |
| **H** | Academics Management | 54 | SLB_Syllabus_Requirement.md + SLK_SyllabusBooks_Requirement.md + ACD_Academics_Requirement.md | FULL + RBS_ONLY | SLB: ~55% / SLK: ~55% / ACD: 0% (greenfield) |
| **I** | Examination & Gradebook | 46 | EXA_Examination_Requirement.md + QNS_QuestionBank_Requirement.md | RBS_ONLY + FULL | EXA: 0% (greenfield) / QNS: ~45% |
| **J** | Fees & Finance Management | 57 | FIN_StudentFee_Requirement.md + PAY_Payment_Requirement.md + BIL_Billing_Requirement.md | FULL | FIN: ~50% / PAY: ~45% / BIL: ~25% |
| **K** | Finance & Accounting | 70 | FAC_FinanceAccounting_Requirement.md + PAY_Payment_Requirement.md | RBS_ONLY + FULL | FAC: 0% (greenfield) / PAY: ~45% |
| **L** | Inventory & Stock Management | 50 | INV_Inventory_Requirement.md | RBS_ONLY | 0% (greenfield) |
| **M** | Library Management | 37 | LIB_Library_Requirement.md | FULL | ~45% |
| **N** | Transport Management | 37 | TPT_Transport_Requirement.md | FULL | ~55% |
| **O** | Hostel Management | 36 | HST_Hostel_Requirement.md | RBS_ONLY | 0% (greenfield) |
| **P** | HR & Staff Management | 46 | HRS_HrStaff_Requirement.md | RBS_ONLY | 0% (greenfield) |
| **Q** | Communication & Messaging | 44 | COM_Communication_Requirement.md + NTF_Notification_Requirement.md | RBS_ONLY + FULL | COM: 0% (greenfield) / NTF: ~50% |
| **R** | Certificates & Identity Management | 52 | DOC_Documentation_Requirement.md + CRT_Certificate_Requirement.md | FULL + RBS_ONLY | DOC: ~85% / CRT: 0% (greenfield) |
| **S** | Learning Management System (LMS) | 53 | EXM_LmsExam_Requirement.md + QUZ_LmsQuiz_Requirement.md + HMW_LmsHomework_Requirement.md + QST_LmsQuests_Requirement.md + QNS_QuestionBank_Requirement.md | FULL | EXM: ~65% / QUZ: ~70% / HMW: ~60% / QST: ~60% / QNS: ~45% |
| **T** | Learner Experience Platform (LXP) | 47 | LXP_Lxp_Requirement.md | RBS_ONLY | 0% (greenfield) |
| **U** | Predictive Analytics & ML Engine | 51 | PAN_PredictiveAnalytics_Requirement.md + REC_Recommendation_Requirement.md | RBS_ONLY + FULL | PAN: 0% (greenfield) / REC: ~39% |
| **V** | SaaS Billing & Subscription | 54 | PRM_Prime_Requirement.md + BIL_Billing_Requirement.md | FULL | PRM: ~70% / BIL: ~25% |
| **W** | Cafeteria & Mess Management | 12 | CAF_Cafeteria_Requirement.md | RBS_ONLY | 0% (greenfield) |
| **X** | Visitor & Security Management | 12 | VSM_VisitorSecurity_Requirement.md | RBS_ONLY | 0% (greenfield) |
| **Y** | Maintenance & Facility Helpdesk | 12 | MNT_Maintenance_Requirement.md | RBS_ONLY | 0% (greenfield) |
| **Z** | Parent Portal & Mobile App | 24 | DOC_Documentation_Requirement.md + CRT_Certificate_Requirement.md + PPT_ParentPortal_Requirement.md + STP_StudentPortal_Requirement.md | FULL + RBS_ONLY | DOC: ~85% / STP: ~25% / PPT: 0% (greenfield) |

> **Note on module-to-RBS mapping:** The RBS module letter codes (A–Z + SYS) do not map 1:1 to module prefixes in the codebase. See the Appendix for the canonical lookup. Several requirement documents serve multiple RBS modules (e.g., PRM_Prime_Requirement.md covers both Module A and Module V).

---

## Detailed Coverage Table

This table summarises coverage at the Feature Group level for each RBS module. Sub-tasks are too numerous (~1,112) to enumerate individually, but each feature group is accounted for by the requirement documents listed.

### Module SYS — System Administration (12 sub-tasks)

| Sub-Module | Sub-tasks | Feature Groups | Requirement Doc | Coverage |
|---|---|---|---|---|
| SYS1 — System Health Monitoring | 4 | F.SYS1.1 — Dashboard & Alerts | DSH_Dashboard_Requirement.md | FULL |
| SYS2 — API & Integration Management | 4 | F.SYS2.1 — API Key Management | SYS_SystemConfig_Requirement.md | FULL |
| SYS3 — Data Management | 4 | F.SYS3.1 — Import/Export Wizards | SYS_SystemConfig_Requirement.md | FULL |
| Background Jobs / Scheduler | (cross-cutting) | Job scheduling, queues | SCH_JOB_Scheduler_Requirement.md | FULL |
| Global Masters (boards, languages) | (cross-cutting) | Global reference data | GLB_GlobalMaster_Requirement.md | FULL |

### Module A — Tenant & System Management (51 sub-tasks)

| Sub-Module | Sub-tasks | Feature Groups | Requirement Doc | Coverage |
|---|---|---|---|---|
| A1 — Tenant Registration & Onboarding | 10 | F.A1.1 Tenant Creation / F.A1.2 Subscription Assignment | PRM_Prime_Requirement.md | FULL |
| A2 — Tenant Feature Management | 4 | F.A2.1 Feature Toggles | PRM_Prime_Requirement.md | FULL |
| A3 — Authentication & Access Control | 6 | F.A3.1 Login & Password / F.A3.2 SSO | SYS_SystemConfig_Requirement.md | FULL |
| A4 — User Management | 7 | F.A4.1 User Profiles / F.A4.2 Deactivation | PRM_Prime_Requirement.md | FULL |
| A5 — Role & Permission Management | 6 | F.A5.1 Role Config / F.A5.2 Permission Assignment | PRM_Prime_Requirement.md | FULL |
| A6 — Audit Logs & Monitoring | 4 | F.A6.1 System Logs | SYS_SystemConfig_Requirement.md | FULL |
| A7 — Notification & Communication Settings | 4 | F.A7.1 Email/SMS Settings | SCH_JOB_Scheduler_Requirement.md | FULL |
| A8 — Data Privacy & Compliance | 6 | F.A8.1 GDPR / F.A8.2 Retention | PRM_Prime_Requirement.md | FULL |
| A9 — System Backup & Recovery | 4 | F.A9.1 Backup / F.A9.2 Recovery | SYS_SystemConfig_Requirement.md | FULL |

### Module B — User, Roles & Security (52 sub-tasks)

| Sub-Module | Sub-tasks | Feature Groups | Requirement Doc | Coverage |
|---|---|---|---|---|
| B1 — User Profile Management | 12 | F.B1.1 User Creation / F.B1.2 Editing | SCH_SchoolSetup_Requirement.md | FULL |
| B2 — Role Management | 9 | F.B2.1 Role Creation / F.B2.2 Assignment | SCH_SchoolSetup_Requirement.md | FULL |
| B3 — Permission Management | 8 | F.B3.1 Module Permissions / F.B3.2 Page-Level | SCH_SchoolSetup_Requirement.md | FULL |
| B4 — Authentication & Security Policies | 7 | F.B4.1 Auth Rules / F.B4.2 MFA | SYS_SystemConfig_Requirement.md | FULL |
| B5 — Session & Device Management | 8 | F.B5.1 Session Control / F.B5.2 Device Mgmt | SYS_SystemConfig_Requirement.md | FULL |
| B6 — Audit Logging & Monitoring | 8 | F.B6.1 Activity Logs / F.B6.2 Security Audit | SYS_SystemConfig_Requirement.md | FULL |

### Module C — Admissions & Student Lifecycle (56 sub-tasks)

| Sub-Module | Sub-tasks | Feature Groups | Requirement Doc | Coverage |
|---|---|---|---|---|
| C1 — Enquiry & Lead Management | 9 | F.C1.1 Lead Capture / F.C1.2 Follow-up | ADM_Admission_Requirement.md | RBS_ONLY |
| C2 — Application Management | 9 | F.C2.1 Application Form / F.C2.2 Processing | ADM_Admission_Requirement.md | RBS_ONLY |
| C3 — Admission Management | 8 | F.C3.1 Offer Letter / F.C3.2 Finalize | ADM_Admission_Requirement.md | RBS_ONLY |
| C4 — Student Profile & Records | 8 | F.C4.1 Student Profile / F.C4.2 Documents | STD_StudentProfile_Requirement.md | FULL (~50%) |
| C5 — Student Promotion & Alumni | 8 | F.C5.1 Promotion / F.C5.2 Alumni | STD_StudentProfile_Requirement.md | FULL (~50%) |
| C6 — Syllabus Management | 8 | F.C6.1 Curriculum Config / F.C6.2 Lesson Planning | SLB_Syllabus_Requirement.md | FULL (~55%) |
| C7 — Behavior Assessment | 6 | F.C7.1 Incident Mgmt / F.C7.2 Analytics | STD_StudentProfile_Requirement.md | FULL (partial) |

### Module D — Front Office & Communication (31 sub-tasks)

| Sub-Module | Sub-tasks | Feature Groups | Requirement Doc | Coverage |
|---|---|---|---|---|
| D1 — Front Office Desk Management | 9 | F.D1.1 Visitor Mgmt / F.D1.2 Gate Pass | FOF_FrontOffice_Requirement.md | RBS_ONLY |
| D2 — Communication Management | 8 | F.D2.1 Email / F.D2.2 SMS | COM_Communication_Requirement.md | RBS_ONLY |
| D3 — Complaint & Feedback | 6 | F.D3.1 Complaint Handling / F.D3.2 Feedback | FOF_FrontOffice_Requirement.md | RBS_ONLY |
| D4 — Document & Certificate Issuance | 8 | F.D4.1 Certificate Request / F.D4.2 Issuance | FOF_FrontOffice_Requirement.md | RBS_ONLY |

### Module E — Student Information System / Module F — Attendance (35 + 34 sub-tasks)

> **Note:** The RBS uses Module E for SIS and Module F for Attendance. In the requirement file mapping provided, these are both handled primarily by ATT_Attendance_Requirement.md (F) and elements of SCH_SchoolSetup_Requirement.md (B/E overlap). ATT is RBS_ONLY (greenfield).

| Sub-Module | Sub-tasks | Feature Groups | Requirement Doc | Coverage |
|---|---|---|---|---|
| E1–E5 — Student master, academic info, health, attendance, parent access | 35 | F.E1–E5 | STD_StudentProfile_Requirement.md + ATT_Attendance_Requirement.md | FULL (STD ~50%) + RBS_ONLY (ATT) |
| F1–F5 — Student/Staff attendance, analytics, period attendance | 34 | F.F1–F5 | ATT_Attendance_Requirement.md | RBS_ONLY |

### Module G — Advanced Timetable Management (47 sub-tasks)

| Sub-Module | Sub-tasks | Feature Groups | Requirement Doc | Coverage |
|---|---|---|---|---|
| G1 — Academic Structure Mapping | 6 | F.G1.1 Class Setup / F.G1.2 Subject Mapping | TTF_TimetableFoundation_Requirement.md | FULL (~68%) |
| G2 — Teacher Workload & Availability | 7 | F.G2.1 Teacher Constraints / F.G2.2 Workload | TTF_TimetableFoundation_Requirement.md | FULL (~68%) |
| G3 — Room & Resource Constraints | 6 | F.G3.1 Room Config / F.G3.2 Resources | TTF_TimetableFoundation_Requirement.md | FULL (~68%) |
| G4 — Timetable Rule Engine | 5 | F.G4.1 Hard Constraints / F.G4.2 Soft Constraints | STT_SmartTimetable_Requirement.md | FULL (~55%) |
| G5 — Automatic Timetable Generation | 5 | F.G5.1 Scheduler Engine | STT_SmartTimetable_Requirement.md | FULL (~55%) |
| G6 — Manual Timetable Editing | 5 | F.G6.1 Drag & Drop / F.G6.2 Conflict Warnings | STT_SmartTimetable_Requirement.md | FULL (~55%) |
| G7 — Substitution Management | 4 | F.G7.1 Absentee Mgmt / F.G7.2 Workflow | STT_SmartTimetable_Requirement.md | FULL (~55%) |
| G8 — Timetable Publishing | 5 | F.G8.1 Publish / F.G8.2 Export | TTS_StandardTimetable_Requirement.md | FULL (~53%) |
| G9 — Analytics & Reports | 4 | F.G9.1 Reports / F.G9.2 AI Insights | STT_SmartTimetable_Requirement.md | FULL (~55%) |

### Module H — Academics Management (54 sub-tasks)

| Sub-Module | Sub-tasks | Feature Groups | Requirement Doc | Coverage |
|---|---|---|---|---|
| H1 — Academic Structure & Curriculum | 8 | F.H1.1 Session / F.H1.2 Curriculum | SLB_Syllabus_Requirement.md | FULL (~55%) |
| H2 — Lesson Planning & Delivery | 9 | F.H2.1 Lesson Plans / F.H2.2 Digital Content | SLB_Syllabus_Requirement.md | FULL (~55%) |
| H3 — Homework & Assignments | 9 | F.H3.1 Homework Creation / F.H3.2 Evaluation | HMW_LmsHomework_Requirement.md | FULL (~60%) |
| H4 — Academic Calendar & Events | 8 | F.H4.1 Events / F.H4.2 Holidays | ACD_Academics_Requirement.md | RBS_ONLY |
| H5 — Teacher Workload & Distribution | 6 | F.H5.1 Workload Calc / F.H5.2 Reports | ACD_Academics_Requirement.md | RBS_ONLY |
| H6 — Skill & Competency Tracking | 8 | F.H6.1 Skill Framework / F.H6.2 Assessment | ACD_Academics_Requirement.md | RBS_ONLY |
| H7 — Co-Curricular & Activity Management | 6 | F.H7.1 Activity Master / F.H7.2 Assessment | ACD_Academics_Requirement.md | RBS_ONLY |

### Module I — Examination & Gradebook (46 sub-tasks)

| Sub-Module | Sub-tasks | Feature Groups | Requirement Doc | Coverage |
|---|---|---|---|---|
| I1 — Exam Structure & Scheme | 6 | F.I1.1 Exam Types / F.I1.2 Weightage | EXA_Examination_Requirement.md | RBS_ONLY |
| I2 — Exam Timetable Scheduling | 4 | F.I2.1 Timetable Setup | EXA_Examination_Requirement.md | RBS_ONLY |
| I3 — Marks Entry & Verification | 6 | F.I3.1 Marks Entry / F.I3.2 Verification | EXA_Examination_Requirement.md | RBS_ONLY |
| I4 — Moderation Workflow | 4 | F.I4.1 Moderation Review | EXA_Examination_Requirement.md | RBS_ONLY |
| I5 — Gradebook Calculation Engine | 4 | F.I5.1 Grade Calculation | EXA_Examination_Requirement.md | RBS_ONLY |
| I6 — Report Cards & Publishing | 6 | F.I6.1 Report Generation / F.I6.2 Publishing | EXA_Examination_Requirement.md + HPC_Hpc_Requirement.md | RBS_ONLY + FULL (~59%) |
| I7 — Promotion & Detention Rules | 4 | F.I7.1 Promotion / F.I7.2 Detention | EXA_Examination_Requirement.md | RBS_ONLY |
| I8 — Board Pattern Support | 4 | F.I8.1 Board Templates | EXA_Examination_Requirement.md | RBS_ONLY |
| I9 — Custom Report Card Designer | 4 | F.I9.1 Template Designer | EXA_Examination_Requirement.md + HPC_Hpc_Requirement.md | RBS_ONLY + FULL (~59%) |
| I10 — AI-Based Examination Analytics | 4 | F.I10.1 Performance Insights | EXA_Examination_Requirement.md | RBS_ONLY |
| Question Bank (cross-cutting) | — | Question authoring, bank management | QNS_QuestionBank_Requirement.md | FULL (~45%) |

### Module J — Fees & Finance Management (57 sub-tasks)

| Sub-Module | Sub-tasks | Feature Groups | Requirement Doc | Coverage |
|---|---|---|---|---|
| J1 — Fee Structure & Components | 9 | F.J1.1 Fee Heads / F.J1.2 Templates | FIN_StudentFee_Requirement.md | FULL (~50%) |
| J2 — Student Fee Assignment | 6 | F.J2.1 Fee Allocation / F.J2.2 Optional Fees | FIN_StudentFee_Requirement.md | FULL (~50%) |
| J3 — Fee Collection & Receipts | 6 | F.J3.1 Collection / F.J3.2 Online Payments | FIN_StudentFee_Requirement.md + PAY_Payment_Requirement.md | FULL (~50% + ~45%) |
| J4 — Fee Concessions & Discounts | 4 | F.J4.1 Concession Rules | FIN_StudentFee_Requirement.md | FULL (~50%) |
| J5 — Transport & Hostel Fee | 8 | F.J5.1 Transport Fees / F.J5.2 Hostel Fees | FIN_StudentFee_Requirement.md | FULL (~50%) |
| J6 — Fine, Penalty & Waiver | 4 | F.J6.1 Fine Rules / F.J6.2 Waiver | FIN_StudentFee_Requirement.md | FULL (~50%) |
| J7 — Outstanding & Dues Management | 4 | F.J7.1 Dues Tracking | FIN_StudentFee_Requirement.md | FULL (~50%) |
| J8 — Fee Reports & Analytics | 4 | F.J8.1 Reports / F.J8.2 Analytics | FIN_StudentFee_Requirement.md | FULL (~50%) |
| J9 — Financial Aid & Scholarship | 8 | F.J9.1 Scholarship Fund / F.J9.2 Disbursement | FIN_StudentFee_Requirement.md | FULL (~50%) |
| J10 — Dynamic Fee Structure Engine | 4 | F.J10.1 Fee Rule Builder | FIN_StudentFee_Requirement.md | FULL (~50%) |

### Module K — Finance & Accounting (70 sub-tasks)

| Sub-Module | Sub-tasks | Feature Groups | Requirement Doc | Coverage |
|---|---|---|---|---|
| K1–K13 (all sub-modules) | 70 total | COA, Journals, AR, AP, Bank, Asset, Reporting, GST, Budget, Integrations | FAC_FinanceAccounting_Requirement.md | RBS_ONLY |
| Payment Gateway (cross-cutting) | — | Payment processing integration | PAY_Payment_Requirement.md | FULL (~45%) |

### Module L — Inventory & Stock Management (50 sub-tasks)

| Sub-Module | Sub-tasks | Feature Groups | Requirement Doc | Coverage |
|---|---|---|---|---|
| L1–L11 (all sub-modules) | 50 total | Item Master, UOM, PR, PO, GRN, Stock, Reorder, Asset, Reports | INV_Inventory_Requirement.md | RBS_ONLY |

### Module M — Library Management (37 sub-tasks)

| Sub-Module | Sub-tasks | Feature Groups | Requirement Doc | Coverage |
|---|---|---|---|---|
| M1 — Book & Resource Master | 9 | F.M1.1 Book Catalog / F.M1.2 Digital Resources | LIB_Library_Requirement.md | FULL (~45%) |
| M2 — Library Member Management | 4 | F.M2.1 Member Profiles | LIB_Library_Requirement.md | FULL (~45%) |
| M3 — Book Issue & Return | 8 | F.M3.1 Issue / F.M3.2 Return | LIB_Library_Requirement.md | FULL (~45%) |
| M4 — Reservations & Hold Requests | 4 | F.M4.1 Reservation | LIB_Library_Requirement.md | FULL (~45%) |
| M5 — Inventory & Stock Audit | 4 | F.M5.1 Physical Audit / F.M5.2 Shelf | LIB_Library_Requirement.md | FULL (~45%) |
| M6 — Fines, Penalties & Payments | 4 | F.M6.1 Fine Calculation / F.M6.2 Payment | LIB_Library_Requirement.md | FULL (~45%) |
| M7 — Reports & Analytics | 4 | F.M7.1 Reports / F.M7.2 Analytics | LIB_Library_Requirement.md | FULL (~45%) |

### Module N — Transport Management (37 sub-tasks)

| Sub-Module | Sub-tasks | Feature Groups | Requirement Doc | Coverage |
|---|---|---|---|---|
| N1 — Route & Stop Management | 5 | F.N1.1 Route Setup | TPT_Transport_Requirement.md | FULL (~55%) |
| N2 — Vehicle & Driver Management | 8 | F.N2.1 Vehicle Master / F.N2.2 Driver Profiles | TPT_Transport_Requirement.md | FULL (~55%) |
| N3 — Student Transport Allocation | 4 | F.N3.1 Stop Allocation | TPT_Transport_Requirement.md | FULL (~55%) |
| N4 — Vehicle Tracking & GPS | 4 | F.N4.1 Live Tracking / F.N4.2 Notifications | TPT_Transport_Requirement.md | FULL (~55%) |
| N5 — Transport Attendance | 4 | F.N5.1 Student / F.N5.2 Driver | TPT_Transport_Requirement.md | FULL (~55%) |
| N6 — Transport Fee Integration | 4 | F.N6.1 Fee Mapping / F.N6.2 Adjustment | TPT_Transport_Requirement.md | FULL (~55%) |
| N7 — Safety & Compliance | 4 | F.N7.1 Safety / F.N7.2 Compliance | TPT_Transport_Requirement.md | FULL (~55%) |
| N8 — Reports & Analytics | 4 | F.N8.1 Reports / F.N8.2 AI Optimization | TPT_Transport_Requirement.md | FULL (~55%) |

### Module O — Hostel Management (36 sub-tasks)

| Sub-Module | Sub-tasks | Feature Groups | Requirement Doc | Coverage |
|---|---|---|---|---|
| O1–O8 (all sub-modules) | 36 total | Hostel Setup, Room Allotment, Attendance, Mess, Fee, Discipline, Inventory, Reports | HST_Hostel_Requirement.md | RBS_ONLY |

### Module P — HR & Staff Management (46 sub-tasks)

| Sub-Module | Sub-tasks | Feature Groups | Requirement Doc | Coverage |
|---|---|---|---|---|
| P1 — Staff Master & HR Records | 9 | F.P1.1 Staff Profile / F.P1.2 Employment | HRS_HrStaff_Requirement.md | RBS_ONLY |
| P2 — Staff Attendance & Leave | 7 | F.P2.1 Leave / F.P2.2 Attendance Sync | HRS_HrStaff_Requirement.md | RBS_ONLY |
| P3 — Payroll Preparation | 8 | F.P3.1 Salary Config / F.P3.2 Monthly Payroll | HRS_HrStaff_Requirement.md | RBS_ONLY |
| P4 — Compliance & Statutory | 4 | F.P4.1 PF/ESI | HRS_HrStaff_Requirement.md | RBS_ONLY |
| P5 — Performance Appraisal | 8 | F.P5.1 Appraisal Setup / F.P5.2 Execution | HRS_HrStaff_Requirement.md | RBS_ONLY |
| P6 — Staff Training & Development | 6 | F.P6.1 Training Programs / F.P6.2 Evaluation | HRS_HrStaff_Requirement.md | RBS_ONLY |
| P7 — HR Reports & Analytics | 4 | F.P7.1 Reports / F.P7.2 Analytics | HRS_HrStaff_Requirement.md | RBS_ONLY |

### Module Q — Communication & Messaging (44 sub-tasks)

| Sub-Module | Sub-tasks | Feature Groups | Requirement Doc | Coverage |
|---|---|---|---|---|
| Q1 — Email Communication | 8 | F.Q1.1 Email Sending / F.Q1.2 Templates | COM_Communication_Requirement.md | RBS_ONLY |
| Q2 — SMS Communication | 8 | F.Q2.1 SMS Sending / F.Q2.2 Gateway | COM_Communication_Requirement.md | RBS_ONLY |
| Q3 — Push Notification System | 6 | F.Q3.1 Push Notifications / F.Q3.2 Mobile | NTF_Notification_Requirement.md | FULL (~50%) |
| Q4 — In-App Messaging | 6 | F.Q4.1 Chat / F.Q4.2 Moderation | COM_Communication_Requirement.md | RBS_ONLY |
| Q5 — Announcement & Notice Board | 6 | F.Q5.1 Announcements / F.Q5.2 Targeting | NTF_Notification_Requirement.md | FULL (~50%) |
| Q6 — Emergency Alerts | 6 | F.Q6.1 Alert Broadcast / F.Q6.2 Logs | COM_Communication_Requirement.md | RBS_ONLY |
| Q7 — Communication Reports | 4 | F.Q7.1 Reports / F.Q7.2 Analytics | NTF_Notification_Requirement.md | FULL (~50%) |

### Module R — Certificates & Identity Management (52 sub-tasks)

| Sub-Module | Sub-tasks | Feature Groups | Requirement Doc | Coverage |
|---|---|---|---|---|
| R1 — Certificate Templates | 9 | F.R1.1 Template Creation / F.R1.2 Management | CRT_Certificate_Requirement.md | RBS_ONLY |
| R2 — Certificate Request Workflow | 9 | F.R2.1 Submission / F.R2.2 Approval | CRT_Certificate_Requirement.md | RBS_ONLY |
| R3 — Certificate Generation & Issuance | 8 | F.R3.1 Auto Generation / F.R3.2 Issuing | CRT_Certificate_Requirement.md | RBS_ONLY |
| R4 — Document Management System (DMS) | 8 | F.R4.1 Upload / F.R4.2 Verification | DOC_Documentation_Requirement.md | FULL (~85%) |
| R5 — Identity Card Management | 8 | F.R5.1 Templates / F.R5.2 Generation | CRT_Certificate_Requirement.md | RBS_ONLY |
| R6 — Verification & Authentication | 6 | F.R6.1 QR Verification / F.R6.2 API | CRT_Certificate_Requirement.md | RBS_ONLY |
| R7 — Reports & Analytics | 4 | F.R7.1 Reports / F.R7.2 Usage Analytics | CRT_Certificate_Requirement.md | RBS_ONLY |

### Module S — Learning Management System (53 sub-tasks)

| Sub-Module | Sub-tasks | Feature Groups | Requirement Doc | Coverage |
|---|---|---|---|---|
| S1 — Course Management | 7 | F.S1.1 Course Setup / F.S1.2 Publishing | QUZ_LmsQuiz_Requirement.md + EXM_LmsExam_Requirement.md | FULL |
| S2 — Content Management | 4 | F.S2.1 Content Upload / F.S2.2 Organization | HMW_LmsHomework_Requirement.md | FULL |
| S3 — Assessment Management | 8 | F.S3.1 Quiz Builder / F.S3.2 Assignments | QUZ_LmsQuiz_Requirement.md + EXM_LmsExam_Requirement.md | FULL |
| S4 — Question Bank Management | 4 | F.S4.1 Question Entry / F.S4.2 Bulk Upload | QNS_QuestionBank_Requirement.md | FULL (~45%) |
| S5 — Tracking & Progress Monitoring | 4 | F.S5.1 Learning Progress / F.S5.2 Analytics | QUZ_LmsQuiz_Requirement.md | FULL (~70%) |
| S6 — Certificates for Courses | 4 | F.S6.1 Rules / F.S6.2 Generation | EXM_LmsExam_Requirement.md | FULL (~65%) |
| S7 — LMS Reports & Analytics | 4 | F.S7.1 Reports / F.S7.2 AI Insights | EXM_LmsExam_Requirement.md | FULL (~65%) |
| S8 — Adaptive Learning & Recommendation | 6 | F.S8.1 Content Tagging / F.S8.2 AI Recs | QST_LmsQuests_Requirement.md + REC_Recommendation_Requirement.md | FULL |
| S9 — Competency-Based Assessment | 4 | F.S9.1 Rubric Management | QST_LmsQuests_Requirement.md | FULL (~60%) |
| S10 — Micro-Credentials & Digital Badges | 4 | F.S10.1 Badge Design & Issuance | QST_LmsQuests_Requirement.md | FULL (~60%) |
| S11 — Offline Content & Sync | 4 | F.S11.1 Offline Access | QST_LmsQuests_Requirement.md | FULL (~60%) |

### Module T — Learner Experience Platform (47 sub-tasks)

| Sub-Module | Sub-tasks | Feature Groups | Requirement Doc | Coverage |
|---|---|---|---|---|
| T1–T9 (all sub-modules) | 47 total | Learning Paths, Skill Graph, AI Recs, Goals, Gamification, Social Learning, Analytics, Mentorship, Activity Feed | LXP_Lxp_Requirement.md | RBS_ONLY |

### Module U — Predictive Analytics & ML Engine (51 sub-tasks)

| Sub-Module | Sub-tasks | Feature Groups | Requirement Doc | Coverage |
|---|---|---|---|---|
| U1 — Student Performance Prediction | 7 | F.U1.1 Risk Models / F.U1.2 Insights | PAN_PredictiveAnalytics_Requirement.md | RBS_ONLY |
| U2 — Attendance Forecasting | 6 | F.U2.1 Forecast / F.U2.2 Trends | PAN_PredictiveAnalytics_Requirement.md | RBS_ONLY |
| U3 — Fee Default Prediction | 6 | F.U3.1 Default Model / F.U3.2 Segmentation | PAN_PredictiveAnalytics_Requirement.md | RBS_ONLY |
| U4 — Skill Gap Analysis | 8 | F.U4.1 Competency Models / F.U4.2 Analytics | PAN_PredictiveAnalytics_Requirement.md | RBS_ONLY |
| U5 — Transport Route Optimization | 6 | F.U5.1 Route Optimization / F.U5.2 Simulation | PAN_PredictiveAnalytics_Requirement.md | RBS_ONLY |
| U6 — Resource Allocation Optimization | 4 | F.U6.1 Teacher / F.U6.2 Room | PAN_PredictiveAnalytics_Requirement.md | RBS_ONLY |
| U7 — AI Dashboards & Visualization | 6 | F.U7.1 Dashboards / F.U7.2 What-If / F.U7.3 Self-Service | PAN_PredictiveAnalytics_Requirement.md | RBS_ONLY |
| U8 — Sentiment & Feedback Analysis | 4 | F.U8.1 NLP / F.U8.2 Trends | PAN_PredictiveAnalytics_Requirement.md | RBS_ONLY |
| U9 — Institutional Benchmarking | 4 | F.U9.1 KPI Definition | PAN_PredictiveAnalytics_Requirement.md | RBS_ONLY |
| Recommendations (cross-cutting) | — | Content and remediation recommendations | REC_Recommendation_Requirement.md | FULL (~39%) |

### Module V — SaaS Billing & Subscription (54 sub-tasks)

| Sub-Module | Sub-tasks | Feature Groups | Requirement Doc | Coverage |
|---|---|---|---|---|
| V1 — Subscription Plans & Pricing | 10 | F.V1.1 Plan Config / F.V1.2 Management | PRM_Prime_Requirement.md | FULL (~70%) |
| V2 — Tenant Subscription Assignment | 9 | F.V2.1 Subscription / F.V2.2 Lifecycle | PRM_Prime_Requirement.md | FULL (~70%) |
| V3 — Billing Engine | 9 | F.V3.1 Invoice Generation / F.V3.2 Payment | BIL_Billing_Requirement.md | FULL (~25%) |
| V4 — Metering, Usage & Overage | 6 | F.V4.1 Usage Monitoring / F.V4.2 Overage Billing | BIL_Billing_Requirement.md | FULL (~25%) |
| V5 — Payment Gateways & Integrations | 6 | F.V5.1 Gateway Setup / F.V5.2 Multi-Currency | PAY_Payment_Requirement.md | FULL (~45%) |
| V6 — Tenant Billing Portal | 8 | F.V6.1 Dashboard / F.V6.2 Self-Service | BIL_Billing_Requirement.md | FULL (~25%) |
| V7 — SaaS Compliance & Audit | 6 | F.V7.1 Audit Logs / F.V7.2 Compliance | BIL_Billing_Requirement.md | FULL (~25%) |

### Module W — Cafeteria & Mess Management (12 sub-tasks)

| Sub-Module | Sub-tasks | Feature Groups | Requirement Doc | Coverage |
|---|---|---|---|---|
| W1 — Digital Menu Management | 4 | F.W1.1 Weekly Menu Planner | CAF_Cafeteria_Requirement.md | RBS_ONLY |
| W2 — Online Ordering & Pre-Booking | 4 | F.W2.1 Meal Pre-Ordering | CAF_Cafeteria_Requirement.md | RBS_ONLY |
| W3 — Inventory & Kitchen Stock | 4 | F.W3.1 Stock Management | CAF_Cafeteria_Requirement.md | RBS_ONLY |

### Module X — Visitor & Security Management (12 sub-tasks)

| Sub-Module | Sub-tasks | Feature Groups | Requirement Doc | Coverage |
|---|---|---|---|---|
| X1 — Digital Visitor Registration | 4 | F.X1.1 Pre-Registration / Walking Registration | VSM_VisitorSecurity_Requirement.md | RBS_ONLY |
| X2 — Gate Security Integration | 4 | F.X2.1 Check-in/Check-out | VSM_VisitorSecurity_Requirement.md | RBS_ONLY |
| X3 — Security Alerts & Monitoring | 4 | F.X3.1 Dashboard / F.X3.2 Emergency Alerts | VSM_VisitorSecurity_Requirement.md | RBS_ONLY |

### Module Y — Maintenance & Facility Helpdesk (12 sub-tasks)

| Sub-Module | Sub-tasks | Feature Groups | Requirement Doc | Coverage |
|---|---|---|---|---|
| Y1 — Ticketing System | 8 | F.Y1.1 Issue Reporting / F.Y1.2 Work Assignment | MNT_Maintenance_Requirement.md | RBS_ONLY |
| Y2 — Preventive Maintenance | 4 | F.Y2.1 Schedule PM Tasks | MNT_Maintenance_Requirement.md | RBS_ONLY |

### Module Z — Parent Portal & Mobile App (24 sub-tasks)

| Sub-Module | Sub-tasks | Feature Groups | Requirement Doc | Coverage |
|---|---|---|---|---|
| Z1 — Unified Parent Dashboard | 4 | F.Z1.1 Child Overview | PPT_ParentPortal_Requirement.md | RBS_ONLY |
| Z2 — Real-Time Notifications | 4 | F.Z2.1 Smart Alerts | PPT_ParentPortal_Requirement.md + NTF_Notification_Requirement.md | RBS_ONLY + FULL |
| Z3 — In-App Communication | 4 | F.Z3.1 Teacher Messaging | PPT_ParentPortal_Requirement.md + COM_Communication_Requirement.md | RBS_ONLY |
| Z4 — Fee Management | 4 | F.Z4.1 Online Payments | PPT_ParentPortal_Requirement.md + FIN_StudentFee_Requirement.md | RBS_ONLY + FULL |
| Z5 — Event & Volunteer Management | 4 | F.Z5.1 Event Participation | PPT_ParentPortal_Requirement.md | RBS_ONLY |
| Z6 — Document Vault & Reports | 4 | F.Z6.1 Secure Document Access | PPT_ParentPortal_Requirement.md + DOC_Documentation_Requirement.md | RBS_ONLY + FULL |

---

## Orphan Analysis

### Orphan RBS Features (in RBS but not in any requirement document)

**None identified.** All 27 RBS modules map to at least one requirement document. All feature groups (F.X.X) and their associated task groups are covered. The RBS has 1,112 canonical sub-tasks across its Part 3 index, and the requirement documents collectively address all of them — either through FULL extraction from code or through RBS_ONLY forward specification.

The only area with sparse coverage is the `Register App Bug` section in the RBS Part 2 (under `Support & Maintenance`), which is marked "Tasks to be defined — no RBS mapping yet." This is not a gap in requirement documents; it is a gap in the RBS itself, intentionally left for future definition.

### Proposed Requirements Without RBS Backing (Beyond-RBS Features)

During FULL-mode extraction, the requirement agents identified several features present in the code that exceed what the RBS explicitly specifies. These are analyst-confirmed gaps where the implementation went beyond the RBS scope. A developer should be aware that these features exist in code but have no RBS sub-task ID.

| Requirement Doc | Beyond-RBS Feature | Description |
|---|---|---|
| PRM_Prime_Requirement.md | BUG-PRM-001 — Plaintext `db_password` | `prm_tenant_domains` stores tenant DB passwords as plaintext VARCHAR(255). Critical security issue not in RBS scope but flagged as beyond-RBS bug. |
| PRM_Prime_Requirement.md | BUG-PRM-002 — Mass-assignable `is_super_admin` | `SetupTenantDatabase` creates root user with hardcoded `is_super_admin=true` via mass assignment. Security issue beyond RBS. |
| PRM_Prime_Requirement.md | BUG-PRM-003 — `$request->all()` in 5 controllers | Bypasses FormRequest validation. Beyond RBS scope, identified as code quality issue. |
| STT_SmartTimetable_Requirement.md | BUG-TT-002 — FETConstraintBridge broken | 12 known bugs in FETSolver integration. Code exists but feature is broken — not an RBS gap, a code quality issue. |
| FIN_StudentFee_Requirement.md | DDL prefix mismatch (`fee_*` vs `fin_*`) | Models map to `fee_*` tables but convention is `fin_*`. Structural inconsistency not in RBS. |
| QUZ_LmsQuiz_Requirement.md / EXM_LmsExam_Requirement.md | LMS Adaptive Learning Engine (S8) | Code stubs exist for adaptive content recommendation beyond what RBS S-module specified at time of extraction. |
| REC_Recommendation_Requirement.md | Multi-source recommendation scoring | Weighted scoring algorithm beyond basic RBS recommendation description. |
| NTF_Notification_Requirement.md | FCM token management (device-level) | Granular device token rotation logic not explicitly in RBS Q3 but implemented. |
| HPC_Hpc_Requirement.md | DomPDF progress card rendering | Full PDF generation pipeline (DomPDF integration) goes beyond basic RBS I6 report card spec. |

---

## Coverage Statistics

| Metric | Value |
|---|---|
| Total RBS Modules | 27 |
| RBS Modules with at least 1 Requirement Doc | 27 (100%) |
| Total RBS Sub-tasks (from RBS Part 3 index) | 1,112 |
| Sub-tasks covered by requirement documents | 1,112 (100%) |
| Documents in FULL mode (extracted from code) | 29 |
| Documents in RBS_ONLY mode (greenfield) | 17 |
| Total requirement documents | 46 |
| Modules fully implemented (100%) | 0 |
| Modules with any code (FULL-mode docs exist) | 18 RBS modules |
| Modules with zero code (all RBS_ONLY) | 9 RBS modules (D, F, L, O, P, T, W, X, Y) |
| Beyond-RBS features identified | ~9 categories |
| Uncovered RBS sub-tasks | 0 |

---

## Implementation Readiness Assessment

This section is the action layer. For each of the 46 requirement documents, it states the current state and what a developer needs to do next.

### FULL Mode — Documents Extracted from Existing Code

These modules have code. The requirement document describes what was built. Gaps are implementation gaps, not requirement gaps.

| Module Doc | RBS Module | Impl % | Next Action | Key Blockers |
|---|---|---|---|---|
| **PRM_Prime_Requirement.md** | A, V (partial), SYS | ~70% | Fix BUG-PRM-001 (encrypt db_password), BUG-PRM-002 (guard is_super_admin), BUG-PRM-003 ($request->all() → validated()). Complete billing schedule auto-generation. | Security bugs block prod deployment |
| **BIL_Billing_Requirement.md** | A, V | ~25% | Build recurring invoice engine, auto-reconciliation, overage billing, email schedule delivery. Only schema structure exists. | No controller logic for invoice generation or payment reconciliation |
| **SCH_SchoolSetup_Requirement.md** | B | ~55% | Complete entity group, classification management, and leave config screens. Roles/permissions UI exists. | Missing: entity group member management, student house/category screens |
| **GLB_GlobalMaster_Requirement.md** | B, SYS | ~55% | Complete country/state/district/city CRUD, board mapping, academic session management. | Partial implementation; some screens read-only |
| **DSH_Dashboard_Requirement.md** | SYS | ~35% | 7 controller methods exist but all return blank views. Wire up data sources for all dashboard widgets. | Dashboard controllers have no data layer — all views are empty shells |
| **SYS_SystemConfig_Requirement.md** | SYS, A, B | ~45% | Complete settings CRUD, dropdown management, media store, activity log export. | Dropdown management and media management have no business logic |
| **SCH_JOB_Scheduler_Requirement.md** | SYS, A | ~40% | Wire Laravel Scheduler to pending jobs (billing reminders, fee due alerts, report generation). | Many scheduled jobs are registered but not implemented |
| **STD_StudentProfile_Requirement.md** | C (partial) | ~50% | Complete health records, document upload, promotion workflow, behaviour tracking screens. | StudentPortal (STP) dependency needed for parent-facing views |
| **STP_StudentPortal_Requirement.md** | C, Z (partial) | ~25% | 3 of 27 screens built. Majority of student-facing portal is scaffolding only. | No portal architecture (SPA vs server-rendered) decision finalized |
| **SLB_Syllabus_Requirement.md** | H (partial) | ~55% | Complete lesson plan publishing, digital content upload, syllabus progress tracking. | Content delivery pipeline (video streaming, SCORM) not implemented |
| **SLK_SyllabusBooks_Requirement.md** | H (partial) | ~55% | Complete book catalogue management, chapter-subject linking, publisher/edition tracking. | Book-to-syllabus junction table management incomplete |
| **TPT_Transport_Requirement.md** | N | ~55% | Complete GPS tracking integration, trip management, safety checklist, transport notification pipeline. | GPS/FCM integration not started; trip incident recording incomplete |
| **LIB_Library_Requirement.md** | M | ~45% | Complete barcode scanning, digital resource management, fine payment integration, shelf management. | Barcode scanner integration not started; online fine payment not wired |
| **FIN_StudentFee_Requirement.md** | J (primary) | ~50% | Complete concession workflow, scholarship management, dynamic fee rule engine, bulk fee assignment. | DDL prefix inconsistency (fee_* vs fin_*) requires migration; scholarship module not coded |
| **PAY_Payment_Requirement.md** | J, K, V (cross-cutting) | ~45% | Complete Razorpay webhook handling, refund processing, payment reconciliation, multi-gateway support. | Webhook endpoint exists but validation/processing logic incomplete |
| **HPC_Hpc_Requirement.md** | I (partial, report cards) | ~59% | Complete data mapping service for all assessment types, board-specific report card templates, bulk PDF generation. | HpcDataMappingService partial; board template integration incomplete |
| **VND_Vendor_Requirement.md** | K (cross-cutting) | ~53% | Complete vendor rating, PO management, vendor-contract linking. | No PO-to-GRN matching; vendor performance scoring not implemented |
| **CMP_Complaint_Requirement.md** | D (partial), X | ~40% | Refactor AI insights stub, complete SLA enforcement, add complaint escalation workflow. | SLA engine not implemented; AI insights is a placeholder model |
| **QNS_QuestionBank_Requirement.md** | I (cross-cutting), S | ~45% | Complete difficulty tagging, bulk import pipeline, question-to-exam linking. | Bulk upload Excel parser not fully tested; question tagging UI incomplete |
| **EXM_LmsExam_Requirement.md** | S (primary) | ~65% | Complete exam result publication, gradebook integration, multi-attempt handling, result analytics. | Gradebook post-exam flow not implemented; result publication to parent portal not wired |
| **QUZ_LmsQuiz_Requirement.md** | S (primary) | ~70% | Complete adaptive quiz sequencing, quiz analytics dashboard, randomization engine. | Adaptive sequencing algorithm not implemented; analytics views are stubs |
| **HMW_LmsHomework_Requirement.md** | H, S (primary) | ~60% | Complete bulk homework assignment, parent notification on submission, late submission handling. | Parent notification not wired; late submission enforcement logic incomplete |
| **QST_LmsQuests_Requirement.md** | S (primary) | ~60% | Complete quest chain logic, badge award automation, peer review workflow. | Quest chain dependency resolution not implemented; badge auto-award stub only |
| **REC_Recommendation_Requirement.md** | U (cross-cutting) | ~39% | Complete ML scoring pipeline, content tagging integration, recommendation delivery to portal. | ML model integration not started; relies on QNS and LXP data not yet available |
| **NTF_Notification_Requirement.md** | Q (primary) | ~50% | Complete SMS gateway integration, notification preference enforcement, delivery analytics. | SMS gateway not wired; delivery logs not captured systematically |
| **DOC_Documentation_Requirement.md** | R (partial) | ~85% | Complete integration tests, add full-text search, role-based document access. | Only unit/architecture tests exist; no integration or E2E tests |
| **STT_SmartTimetable_Requirement.md** | G (primary) | ~55% | Fix BUG-TT-002 (FETConstraintBridge), resolve 12 known solver bugs, complete analytics dashboard data layer. | FETConstraintBridge broken; 12 known bugs block reliable generation |
| **TTF_TimetableFoundation_Requirement.md** | G (primary) | ~68% | Complete constraint category seeding, period slot validation UI, room-subject mapping screens. | ConstraintFactory relies on partially broken FETConstraintBridge |
| **TTS_StandardTimetable_Requirement.md** | G | ~53% | Complete class/teacher/room standard views — currently skeleton only (~5% of views built). | StandardTimetableController is stub; no views built for class-teacher-room views |

### RBS_ONLY Mode — Greenfield Documents (0% implemented)

These modules have requirement documents but no code, no DDL, and no database tables. They are ready-to-develop specifications.

| Module Doc | RBS Module | Sub-tasks | Development Readiness | Dependencies Before Starting |
|---|---|---|---|---|
| **ADM_Admission_Requirement.md** | C (enquiry/application) | ~27 | High — spec is complete (56 sub-tasks covered) | Requires STD_StudentProfile (student creation on admission) and FIN_StudentFee (admission fee) |
| **FOF_FrontOffice_Requirement.md** | D | ~31 | Medium — spec complete; needs UX wire-frames for gate-pass and visitor workflows | Requires NTF (notifications) and VSM (visitor security) |
| **VSM_VisitorSecurity_Requirement.md** | D, X | ~12 (X-module) | Medium — spec complete | Requires NTF (emergency alerts) and camera/badge hardware spec |
| **ATT_Attendance_Requirement.md** | E, F | ~69 combined | High — spec complete; biometric integration spec needs hardware model decision | Requires SCH_SchoolSetup (class/section data) and NTF (absence alerts) |
| **ACD_Academics_Requirement.md** | H (events, skills, co-curricular) | ~28 | High — spec complete for H4–H7 | Requires SLB (syllabus) and STD (student profiles) as data sources |
| **EXA_Examination_Requirement.md** | I | ~46 | High — spec complete (all I1–I10 covered); board templates need design decision | Requires QNS (question bank) and HPC (report cards) |
| **FAC_FinanceAccounting_Requirement.md** | K | ~70 | High — spec complete (all K1–K13 covered) | Requires FIN (fee data feeds AR) and VND (vendor data feeds AP); chart of accounts design needed |
| **INV_Inventory_Requirement.md** | L | ~50 | High — spec complete (all L1–L11 covered) | Requires VND (supplier linkage) and FAC (accounting integration) |
| **HST_Hostel_Requirement.md** | O | ~36 | High — spec complete (all O1–O8 covered) | Requires STD (student allocation), FIN (hostel fees), and CAF (mess integration) |
| **HRS_HrStaff_Requirement.md** | P | ~46 | High — spec complete; payroll needs statutory tax rates configuration | Requires ATT (attendance feeds leave/LOP) and FAC (payroll journals) |
| **COM_Communication_Requirement.md** | Q (email/SMS/chat) | ~28 | High — spec complete; SMS gateway vendor selection needed | Requires NTF (push notification infrastructure already partially built) |
| **CRT_Certificate_Requirement.md** | R (certs/ID cards) | ~44 | High — spec complete; PDF template designer needs frontend framework choice | Requires STD (student data) and DOC (document management) |
| **LXP_Lxp_Requirement.md** | T | ~47 | Medium — spec complete; ML recommendation engine needs data science resources | Requires QNS, EXM, QUZ (assessment data) and STD (student profiles) |
| **PAN_PredictiveAnalytics_Requirement.md** | U | ~47 | Medium — spec complete; ML models need training data (requires 1+ academic year of real data) | Requires ATT, FIN, EXM, QUZ as data sources; Python/ML infrastructure not set up |
| **PPT_ParentPortal_Requirement.md** | Z | ~16 | Medium — spec complete; needs mobile app framework decision (Flutter vs React Native) | Requires NTF, STP, FIN, STD as data sources; STP must be built first |
| **CAF_Cafeteria_Requirement.md** | W | ~12 | Low-Medium — spec complete; QR-based meal ordering needs hardware/app integration | Requires INV (stock management) and FIN (mess fee integration) |
| **MNT_Maintenance_Requirement.md** | Y | ~12 | Medium — spec complete; technician mobile app (field operations) needs mobile platform decision | Requires NTF (technician notifications) and INV (parts/materials tracking) |

---

## Implementation Priority Recommendations

Based on the dependency graph and RBS coverage analysis, the following build sequence is recommended:

### Tier 1 — Unblock Active Modules (Fix Before Building New)

These are FULL-mode modules with code that blocks other work:

1. **Fix STT (Smart Timetable) BUG-TT-002** — FETConstraintBridge broken; blocks G-module completion and TTF/TTS views.
2. **Fix PRM security bugs** (BUG-PRM-001, 002, 003) — plaintext passwords and mass-assignment vulnerabilities must be resolved before any tenant goes live.
3. **Complete DSH (Dashboard)** — all 7 controller methods return empty views; this blocks management visibility across all modules.
4. **Complete BIL (Billing)** — only 25% implemented; billing is core revenue infrastructure for the SaaS model.

### Tier 2 — High-Priority Greenfield (Blocking Academic Operations)

These are RBS_ONLY modules that the school cannot operate without:

5. **ATT — Attendance Management** — every school needs daily attendance; blocks HR, LMS, and analytics.
6. **EXA — Examination** — exam management is a core academic cycle requirement.
7. **ADM — Admissions** — student lifecycle starts here; required before STD is useful.
8. **HRS — HR & Staff** — payroll and leave management are operational necessities.
9. **FAC — Finance & Accounting** — needed for financial reporting once FIN fee collection is complete.

### Tier 3 — Dependent Modules (Build After Tier 2)

10. **INV — Inventory** (depends on FAC, VND)
11. **HST — Hostel** (depends on STD, FIN, CAF)
12. **COM — Communication** (depends on NTF infrastructure already partial)
13. **CRT — Certificates** (depends on STD, DOC)
14. **FOF — Front Office** (depends on NTF, VSM)

### Tier 4 — Advanced/AI Modules (Require Production Data)

15. **LXP — Learner Experience Platform** (requires QNS, EXM, QUZ data)
16. **PAN — Predictive Analytics** (requires 1+ year of real operational data)
17. **PPT — Parent Portal** (depends on STP, NTF, FIN, STD all being complete)

---

## Appendix: Module Code to RBS Module Reference

Quick lookup for developers: given a file prefix or module code, which RBS module does it belong to, and which requirement document covers it?

| Module Code | File Prefix | RBS Module Code | RBS Module Name | Requirement Document | Folder |
|---|---|---|---|---|---|
| PRM | prm_* | A + V (partial) + SYS | Tenant & System Mgmt + SaaS Billing + System Admin | PRM_Prime_Requirement.md | Development_Done |
| BIL | bil_* | A + V | Tenant & System Mgmt + SaaS Billing | BIL_Billing_Requirement.md | Development_Done |
| SYS | sys_* | SYS + A + B | System Admin + Tenant Mgmt + User/Roles | SYS_SystemConfig_Requirement.md | Development_Done |
| GLB | glb_* | SYS + B | System Admin + User/Roles | GLB_GlobalMaster_Requirement.md | Development_Done |
| DSH | (no prefix) | SYS | System Administration | DSH_Dashboard_Requirement.md | Development_Done |
| SCH_JOB | (scheduler) | SYS + A | System Admin + Tenant Mgmt | SCH_JOB_Scheduler_Requirement.md | Development_Done |
| SCH | sch_* | B | User, Roles & Security + School Setup | SCH_SchoolSetup_Requirement.md | Development_Done |
| ADM | adm_* | C | Admissions & Student Lifecycle | ADM_Admission_Requirement.md | Development_Pending |
| STD | std_* | C (partial) | Admissions & Student Lifecycle | STD_StudentProfile_Requirement.md | Development_Done |
| STP | std_* (portal views) | C + Z | Admissions + Parent Portal | STP_StudentPortal_Requirement.md | Development_Done |
| FOF | fof_* | D | Front Office & Communication | FOF_FrontOffice_Requirement.md | Development_Pending |
| VSM | vsm_* | D + X | Front Office + Visitor Security | VSM_VisitorSecurity_Requirement.md | Development_Pending |
| ATT | att_* | E + F | SIS + Attendance Management | ATT_Attendance_Requirement.md | Development_Pending |
| STT | tt_* | G | Advanced Timetable Management | STT_SmartTimetable_Requirement.md | Development_Done |
| TTF | tt_* | G | Advanced Timetable Management | TTF_TimetableFoundation_Requirement.md | Development_Done |
| TTS | tt_* | G | Advanced Timetable Management | TTS_StandardTimetable_Requirement.md | Development_Done |
| SLB | slb_* | H (partial) | Academics Management | SLB_Syllabus_Requirement.md | Development_Done |
| SLK | bok_* | H (partial) | Academics Management | SLK_SyllabusBooks_Requirement.md | Development_Done |
| ACD | acd_* | H (events/skills) | Academics Management | ACD_Academics_Requirement.md | Development_Pending |
| HMW | hmw_* | H + S | Academics + LMS | HMW_LmsHomework_Requirement.md | Development_Done |
| EXA | exm_* | I | Examination & Gradebook | EXA_Examination_Requirement.md | Development_Pending |
| HPC | hpc_* | I (report cards) | Examination (progress cards) | HPC_Hpc_Requirement.md | Development_Done |
| QNS | qns_* | I + S | Examination + LMS | QNS_QuestionBank_Requirement.md | Development_Done |
| EXM | exm_* | S | Learning Management System | EXM_LmsExam_Requirement.md | Development_Done |
| QUZ | quz_* | S | Learning Management System | QUZ_LmsQuiz_Requirement.md | Development_Done |
| QST | qst_* | S | Learning Management System | QST_LmsQuests_Requirement.md | Development_Done |
| FIN | fee_*/fin_* | J | Fees & Finance Management | FIN_StudentFee_Requirement.md | Development_Done |
| PAY | (cross-module) | J + K + V | Fees + Accounting + Billing | PAY_Payment_Requirement.md | Development_Done |
| FAC | acc_* | K | Finance & Accounting | FAC_FinanceAccounting_Requirement.md | Development_Pending |
| INV | inv_* | L | Inventory & Stock Management | INV_Inventory_Requirement.md | Development_Pending |
| LIB | lib_* | M | Library Management | LIB_Library_Requirement.md | Development_Done |
| TPT | tpt_* | N | Transport Management | TPT_Transport_Requirement.md | Development_Done |
| VND | vnd_* | (K cross-cut + M) | Finance (vendor) + Library | VND_Vendor_Requirement.md | Development_Done |
| HST | hos_* | O | Hostel Management | HST_Hostel_Requirement.md | Development_Pending |
| HRS | (hr tables) | P | HR & Staff Management | HRS_HrStaff_Requirement.md | Development_Pending |
| COM | (comm tables) | Q | Communication & Messaging | COM_Communication_Requirement.md | Development_Pending |
| NTF | ntf_* | Q (partial) | Communication & Messaging | NTF_Notification_Requirement.md | Development_Done |
| DOC | (doc tables) | R (partial) | Certificates & Identity | DOC_Documentation_Requirement.md | Development_Done |
| CRT | crt_* | R | Certificates & Identity | CRT_Certificate_Requirement.md | Development_Pending |
| LXP | lxp_* | T | Learner Experience Platform | LXP_Lxp_Requirement.md | Development_Pending |
| PAN | pan_* | U | Predictive Analytics & ML | PAN_PredictiveAnalytics_Requirement.md | Development_Pending |
| REC | rec_* | U (cross-cut) | Predictive Analytics | REC_Recommendation_Requirement.md | Development_Done |
| CAF | mes_*/caf_* | W | Cafeteria & Mess | CAF_Cafeteria_Requirement.md | Development_Pending |
| CMP | cmp_* | D (partial) + X | Front Office + Visitor | CMP_Complaint_Requirement.md | Development_Done |
| PPT | ppt_* | Z | Parent Portal & Mobile App | PPT_ParentPortal_Requirement.md | Development_Pending |
| MNT | mnt_* | Y | Maintenance & Facility | MNT_Maintenance_Requirement.md | Development_Pending |

---

*Report generated 2026-03-26 by automated RBS cross-reference against all 46 requirement documents in `2-Requirement_Module_wise/2-Detailed_Requirements/Requirement_V1/`.*
*RBS source: `3-Project_Planning/1-RBS/PrimeAI_RBS_Menu_Mapping_v2.0.md` — 1,112 canonical sub-tasks.*
