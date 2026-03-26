# Prime-AI Platform — Master Requirement Index
**Generated:** 2026-03-26
**Total Modules:** 46 (29 FULL + 17 RBS_ONLY)
**Total Documents:** 46 requirement files
**Coverage:** All modules from Prime-AI ERP + LMS + LXP platform for Indian K-12 Schools
**Platform Stack:** Laravel 12 · PHP 8.2+ · MySQL 8.x · nwidart/laravel-modules v12 · stancl/tenancy v3.9
**Architecture:** 3-layer multi-tenant SaaS — global_db · prime_db · tenant_{uuid} (database-per-tenant)

---

## Quick Stats

| Metric | Value |
|---|---|
| Total requirement documents | 46 |
| FULL mode (Development_Done) | 29 modules |
| RBS_ONLY mode (Development_Pending) | 17 modules |
| Central-scoped modules | 5 (PRM, GLB, SYS, BIL, DOC) |
| Tenant-scoped modules | 41 |
| Total lines across all 46 files | ~42,552 |
| Total words across all 46 files | ~302,704 |
| Total FRs (Development_Done) | ~348 functional requirements |
| Total FRs (Development_Pending) | ~290 functional requirements |
| Total routes documented (Development_Done) | ~1,148 routes |
| Total routes documented (Development_Pending) | ~703 routes proposed |
| Modules with P0 security issues | 3 (SYS, QNS, HMW) |
| Modules at 0% code completion | 17 (all List B) |
| Average file size — FULL mode | ~756 lines / ~5,360 words |
| Average file size — RBS_ONLY mode | ~1,179 lines / ~8,663 words |

---

## Index — All 46 Modules

| # | Code | Module Name | Laravel Module | Mode | Scope | RBS Ref | Requirement File | Code % | Key Notes |
|---|---|---|---|---|---|---|---|---|---|
| 1 | PRM | Prime | Prime | FULL | Central | Module A/SYS | [PRM_Prime_Requirement.md](Development_Done/PRM_Prime_Requirement.md) | 70% | 21 ctrl, 27 models, 9 tests, ~80 routes |
| 2 | GLB | GlobalMaster | GlobalMaster | FULL | Central | Module B | [GLB_GlobalMaster_Requirement.md](Development_Done/GLB_GlobalMaster_Requirement.md) | 55% | 15 ctrl, 12 models, 4 tests, ~50 routes |
| 3 | SYS | SystemConfig | SystemConfig | FULL | Central | Module SYS | [SYS_SystemConfig_Requirement.md](Development_Done/SYS_SystemConfig_Requirement.md) | 50% | P0: zero auth on all 7 SystemConfigController methods |
| 4 | BIL | Billing | Billing | FULL | Central | Module F/A | [BIL_Billing_Requirement.md](Development_Done/BIL_Billing_Requirement.md) | 55% | 6 ctrl, 6 models, 1 test, ~25 routes |
| 5 | DOC | Documentation | Documentation | FULL | Central | Module Z | [DOC_Documentation_Requirement.md](Development_Done/DOC_Documentation_Requirement.md) | 65% | 3 ctrl, 2 models, 1 test, ~16 routes |
| 6 | SCH | SchoolSetup | SchoolSetup | FULL | Tenant | Module B/E | [SCH_SchoolSetup_Requirement.md](Development_Done/SCH_SchoolSetup_Requirement.md) | 55% | 40 ctrl, 42 models, 0 tests, ~523 routes |
| 7 | STD | StudentProfile | StudentProfile | FULL | Tenant | Module C/D | [STD_StudentProfile_Requirement.md](Development_Done/STD_StudentProfile_Requirement.md) | 50% | 5 ctrl, 14 models, 6 tests, ~16 routes |
| 8 | TPT | Transport | Transport | FULL | Tenant | Module G | [TPT_Transport_Requirement.md](Development_Done/TPT_Transport_Requirement.md) | 55% | 31 ctrl, 36 models, 0 tests, ~32 routes |
| 9 | VND | Vendor | Vendor | FULL | Tenant | Module M | [VND_Vendor_Requirement.md](Development_Done/VND_Vendor_Requirement.md) | 55% | 7 ctrl, 8 models, 0 tests, ~16 routes |
| 10 | CMP | Complaint | Complaint | FULL | Tenant | Module X | [CMP_Complaint_Requirement.md](Development_Done/CMP_Complaint_Requirement.md) | 40% | 8 ctrl, 6 models, 4 tests, ~16 routes |
| 11 | NTF | Notification | Notification | FULL | Tenant | Module V | [NTF_Notification_Requirement.md](Development_Done/NTF_Notification_Requirement.md) | 50% | All routes COMMENTED OUT in current code |
| 12 | PAY | Payment | Payment | FULL | Tenant | Module K | [PAY_Payment_Requirement.md](Development_Done/PAY_Payment_Requirement.md) | 45% | 2 ctrl, 5 models, 8 tests, ~16 routes |
| 13 | DSH | Dashboard | Dashboard | FULL | Tenant | Module SYS | [DSH_Dashboard_Requirement.md](Development_Done/DSH_Dashboard_Requirement.md) | 39% | 1 ctrl, 0 models, 0 tests, ~16 routes |
| 14 | SCH_JOB | Scheduler | Scheduler | FULL | Tenant | Module SYS | [SCH_JOB_Scheduler_Requirement.md](Development_Done/SCH_JOB_Scheduler_Requirement.md) | 40% | 1 ctrl, 2 models, 1 test, ~16 routes |
| 15 | SLB | Syllabus | Syllabus | FULL | Tenant | Module H | [SLB_Syllabus_Requirement.md](Development_Done/SLB_Syllabus_Requirement.md) | 55% | 15 ctrl, 22 models, 0 tests, ~16 routes |
| 16 | SLK | SyllabusBooks | SyllabusBooks | FULL | Tenant | Module H | [SLK_SyllabusBooks_Requirement.md](Development_Done/SLK_SyllabusBooks_Requirement.md) | 55% | 4 ctrl, 6 models, 0 tests, ~16 routes |
| 17 | QNS | QuestionBank | QuestionBank | FULL | Tenant | Module J | [QNS_QuestionBank_Requirement.md](Development_Done/QNS_QuestionBank_Requirement.md) | 45% | P0: HARDCODED API KEYS in source code |
| 18 | EXM | LmsExam | LmsExam | FULL | Tenant | Module J | [EXM_LmsExam_Requirement.md](Development_Done/EXM_LmsExam_Requirement.md) | 65% | 11 ctrl, 11 models, 0 tests, ~17 routes |
| 19 | QUZ | LmsQuiz | LmsQuiz | FULL | Tenant | Module J | [QUZ_LmsQuiz_Requirement.md](Development_Done/QUZ_LmsQuiz_Requirement.md) | 70% | 5 ctrl, 6 models, 0 tests, ~16 routes |
| 20 | HMW | LmsHomework | LmsHomework | FULL | Tenant | Module J | [HMW_LmsHomework_Requirement.md](Development_Done/HMW_LmsHomework_Requirement.md) | 60% | P0: Fatal PHP error in HoemworkData() method |
| 21 | QST | LmsQuests | LmsQuests | FULL | Tenant | Module J | [QST_LmsQuests_Requirement.md](Development_Done/QST_LmsQuests_Requirement.md) | 60% | 4 ctrl, 4 models, 0 tests, ~16 routes |
| 22 | REC | Recommendation | Recommendation | FULL | Tenant | Module U | [REC_Recommendation_Requirement.md](Development_Done/REC_Recommendation_Requirement.md) | 40% | 10 ctrl, 11 models, 0 tests, ~16 routes |
| 23 | HPC | Hpc | Hpc | FULL | Tenant | Module N | [HPC_Hpc_Requirement.md](Development_Done/HPC_Hpc_Requirement.md) | 59% | 22 ctrl, 32 models, 8 tests, ~8 routes |
| 24 | FIN | StudentFee | StudentFee | FULL | Tenant | Module F | [FIN_StudentFee_Requirement.md](Development_Done/FIN_StudentFee_Requirement.md) | 55% | 15 ctrl, 23 models, 24 tests, ~16 routes |
| 25 | LIB | Library | Library | FULL | Tenant | Module Q | [LIB_Library_Requirement.md](Development_Done/LIB_Library_Requirement.md) | 45% | 26 ctrl, 35 models, 15 tests, ~35 routes |
| 26 | STT | SmartTimetable | SmartTimetable | FULL | Tenant | Module P | [STT_SmartTimetable_Requirement.md](Development_Done/STT_SmartTimetable_Requirement.md) | 48% | 12 ctrl, 62 models, 106 svc, 7 tests, ~41 routes |
| 27 | TTF | TimetableFoundation | TimetableFoundation | FULL | Tenant | Module P | [TTF_TimetableFoundation_Requirement.md](Development_Done/TTF_TimetableFoundation_Requirement.md) | 55% | 24 ctrl, 32 models, 7 tests, ~262 routes |
| 28 | TTS | StandardTimetable | StandardTimetable | FULL | Tenant | Module P | [TTS_StandardTimetable_Requirement.md](Development_Done/TTS_StandardTimetable_Requirement.md) | 5% | 1 ctrl, 0 models, 0 tests, ~30 routes |
| 29 | STP | StudentPortal | StudentPortal | FULL | Tenant | Module C/S | [STP_StudentPortal_Requirement.md](Development_Done/STP_StudentPortal_Requirement.md) | 35% | 3 ctrl, 0 models, 7 tests, ~16 routes |
| 30 | ADM | Admission | Admission | RBS_ONLY | Tenant | Module C | [ADM_Admission_Requirement.md](Development_Pending/ADM_Admission_Requirement.md) | 0% | 12 ctrl proposed, 18 tables, 22 FRs, 10 tests proposed |
| 31 | ACD | Academics | Academics | RBS_ONLY | Tenant | Module H | [ACD_Academics_Requirement.md](Development_Pending/ACD_Academics_Requirement.md) | 0% | ~10 ctrl proposed, ~10 tables, ~10 FRs |
| 32 | ATT | Attendance | Attendance | RBS_ONLY | Tenant | Module E | [ATT_Attendance_Requirement.md](Development_Pending/ATT_Attendance_Requirement.md) | 0% | ~8 ctrl proposed, ~8 tables, ~8 FRs |
| 33 | CAF | Cafeteria | Cafeteria | RBS_ONLY | Tenant | Module W | [CAF_Cafeteria_Requirement.md](Development_Pending/CAF_Cafeteria_Requirement.md) | 0% | 8 ctrl proposed, 10 tables, 9 FRs, ~52 routes |
| 34 | COM | Communication | Communication | RBS_ONLY | Tenant | Module V | [COM_Communication_Requirement.md](Development_Pending/COM_Communication_Requirement.md) | 0% | ~10 ctrl proposed, 11 tables, 25 FRs |
| 35 | CRT | Certificate | Certificate | RBS_ONLY | Tenant | Module Z | [CRT_Certificate_Requirement.md](Development_Pending/CRT_Certificate_Requirement.md) | 0% | ~8 ctrl proposed, 8 tables, 12 FRs |
| 36 | EXA | Examination | Examination | RBS_ONLY | Tenant | Module I | [EXA_Examination_Requirement.md](Development_Pending/EXA_Examination_Requirement.md) | 0% | ~10 ctrl proposed, 16 tables, 14 FRs |
| 37 | FAC | FinanceAccounting | FinanceAccounting | RBS_ONLY | Tenant | Module K | [FAC_FinanceAccounting_Requirement.md](Development_Pending/FAC_FinanceAccounting_Requirement.md) | 0% | ~12 ctrl proposed, 14 tables, 14 FRs |
| 38 | FOF | FrontOffice | FrontOffice | RBS_ONLY | Tenant | Module D | [FOF_FrontOffice_Requirement.md](Development_Pending/FOF_FrontOffice_Requirement.md) | 0% | 10 ctrl proposed, 12 tables, ~15 FRs, 20 tests proposed |
| 39 | HRS | HrStaff | HrStaff | RBS_ONLY | Tenant | Module R | [HRS_HrStaff_Requirement.md](Development_Pending/HRS_HrStaff_Requirement.md) | 0% | ~12 ctrl proposed, 14 tables, 29 FRs, 15 tests proposed |
| 40 | HST | Hostel | Hostel | RBS_ONLY | Tenant | Module O | [HST_Hostel_Requirement.md](Development_Pending/HST_Hostel_Requirement.md) | 0% | 14 ctrl proposed, 15 tables, ~18 FRs |
| 41 | INV | Inventory | Inventory | RBS_ONLY | Tenant | Module L | [INV_Inventory_Requirement.md](Development_Pending/INV_Inventory_Requirement.md) | 0% | 14 ctrl proposed, 19 tables, 15 FRs |
| 42 | LXP | Lxp | Lxp | RBS_ONLY | Tenant | Module T | [LXP_Lxp_Requirement.md](Development_Pending/LXP_Lxp_Requirement.md) | 0% | ~10 ctrl proposed, 14 tables, 12 FRs |
| 43 | MNT | Maintenance | Maintenance | RBS_ONLY | Tenant | Module Y | [MNT_Maintenance_Requirement.md](Development_Pending/MNT_Maintenance_Requirement.md) | 0% | 8 ctrl proposed, 9 tables, ~10 FRs, ~58 routes |
| 44 | PAN | PredictiveAnalytics | PredictiveAnalytics | RBS_ONLY | Tenant | Module U | [PAN_PredictiveAnalytics_Requirement.md](Development_Pending/PAN_PredictiveAnalytics_Requirement.md) | 0% | ~10 ctrl proposed, 12 tables, 17 FRs |
| 45 | PPT | ParentPortal | ParentPortal | RBS_ONLY | Tenant | Module S | [PPT_ParentPortal_Requirement.md](Development_Pending/PPT_ParentPortal_Requirement.md) | 0% | ~8 ctrl proposed, 10 tables, ~12 FRs |
| 46 | VSM | VisitorSecurity | VisitorSecurity | RBS_ONLY | Tenant | Module D | [VSM_VisitorSecurity_Requirement.md](Development_Pending/VSM_VisitorSecurity_Requirement.md) | 0% | ~6 ctrl proposed, 8 tables, ~8 FRs |

---

## List A — Development_Done (29 Modules, FULL Mode)

Requirements extracted from live code + schema + tests. Each document covers: module overview, DB tables, functional requirements (FRs), API/route inventory, controller/model/service inventory, test coverage, known gaps, and P0 issues.

### Central-Scoped Modules (5)

These modules live outside tenant isolation and operate at the SaaS platform layer (global_db / prime_db).

| # | Code | Module Name | Lines | Words | Controllers | Models | Tests | Routes | Completion | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | PRM | Prime | 759 | 4,549 | 21 | 27 | 9 | ~80 | 70% | Tenant lifecycle, plan/module licensing, RBS Module A/SYS |
| 2 | GLB | GlobalMaster | 1,181 | 8,480 | 15 | 12 | 4 | ~50 | 55% | Countries, states, boards, languages, RBS Module B |
| 3 | SYS | SystemConfig | 542 | 3,623 | 4 | 3 | 1 | ~16 | 50% | **CRITICAL: no auth on SystemConfigController (7 methods)** |
| 4 | BIL | Billing | 1,623 | 13,341 | 6 | 6 | 1 | ~25 | 55% | Tenant billing, plan subscriptions, RBS Module F/A |
| 5 | DOC | Documentation | 699 | 5,698 | 3 | 2 | 1 | ~16 | 65% | Platform documentation engine, RBS Module Z |

**Central subtotal:** 4,804 lines · 35,691 words

---

### Tenant-Scoped Modules — School Administration (8)

| # | Code | Module Name | Lines | Words | Controllers | Models | Tests | Routes | Completion | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| 6 | SCH | SchoolSetup | 837 | 5,439 | 40 | 42 | 0 | ~523 | 55% | School profile, infra, class setup; largest route count |
| 7 | STD | StudentProfile | 739 | 5,292 | 5 | 14 | 6 | ~16 | 50% | Student registration, profile, guardian linking |
| 8 | TPT | Transport | 677 | 4,573 | 31 | 36 | 0 | ~32 | 55% | Routes, vehicles, assignments, GPS tracking |
| 9 | VND | Vendor | 728 | 4,975 | 7 | 8 | 0 | ~16 | 55% | Vendor master, contracts, purchase orders |
| 10 | CMP | Complaint | 1,626 | 12,327 | 8 | 6 | 4 | ~16 | 40% | Complaint lifecycle, escalation, resolution |
| 11 | NTF | Notification | 685 | 4,193 | 12 | 14 | 0 | ~16 | 50% | **WARNING: all routes currently COMMENTED OUT** |
| 13 | DSH | Dashboard | 488 | 3,964 | 1 | 0 | 0 | ~16 | 39% | Role-based dashboard widgets, KPI aggregation |
| 14 | SCH_JOB | Scheduler | 382 | 2,291 | 1 | 2 | 1 | ~16 | 40% | Background job scheduling, cron management |

**School Administration subtotal:** 6,162 lines · 43,054 words

---

### Tenant-Scoped Modules — Academic & Curriculum (9)

| # | Code | Module Name | Lines | Words | Controllers | Models | Tests | Routes | Completion | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| 15 | SLB | Syllabus | 607 | 4,077 | 15 | 22 | 0 | ~16 | 55% | Curriculum mapping, chapters, topics, learning objectives |
| 16 | SLK | SyllabusBooks | 497 | 2,983 | 4 | 6 | 0 | ~16 | 55% | Prescribed textbook catalog linked to syllabus |
| 17 | QNS | QuestionBank | 871 | 5,084 | 7 | 17 | 0 | ~16 | 45% | **P0: HARDCODED API KEYS** — AI-generated questions |
| 18 | EXM | LmsExam | 716 | 4,529 | 11 | 11 | 0 | ~17 | 65% | Exam scheduling, papers, grading, results |
| 19 | QUZ | LmsQuiz | 612 | 4,205 | 5 | 6 | 0 | ~16 | 70% | Interactive quizzes, scoring, attempts |
| 20 | HMW | LmsHomework | 523 | 3,339 | 5 | 5 | 0 | ~16 | 60% | **P0: Fatal PHP error** in HoemworkData() method |
| 21 | QST | LmsQuests | 530 | 3,638 | 4 | 4 | 0 | ~16 | 60% | Gamified learning quests, badges, progress |
| 22 | REC | Recommendation | 452 | 3,038 | 10 | 11 | 0 | ~16 | 40% | AI-driven learning recommendations, personalisation |
| 29 | STP | StudentPortal | 582 | 3,960 | 3 | 0 | 7 | ~16 | 35% | Student self-service portal, assignments, grades |

**Academic & Curriculum subtotal:** 5,390 lines · 34,853 words

---

### Tenant-Scoped Modules — Timetable (3)

| # | Code | Module Name | Lines | Words | Controllers | Models | Services | Tests | Routes | Completion | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 26 | STT | SmartTimetable | 852 | 5,750 | 12 | 62 | 106 | 7 | ~41 | 48% | AI constraint-based scheduler; TabuSearch + SA optimizers |
| 27 | TTF | TimetableFoundation | 783 | 5,382 | 24 | 32 | — | 7 | ~262 | 55% | Period/day/room/teacher slot management foundation |
| 28 | TTS | StandardTimetable | 538 | 3,218 | 1 | 0 | — | 0 | ~30 | 5% | Manual timetable viewer; reuses AnalyticsService grids |

**Timetable subtotal:** 2,173 lines · 14,350 words

---

### Tenant-Scoped Modules — Finance & Operations (4)

| # | Code | Module Name | Lines | Words | Controllers | Models | Tests | Routes | Completion | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| 12 | PAY | Payment | 625 | 3,864 | 2 | 5 | 8 | ~16 | 45% | Razorpay/Stripe gateway, receipts, refunds |
| 23 | HPC | Hpc | 1,669 | 10,866 | 22 | 32 | 8 | ~8 | 59% | Health, Physical, Co-curricular — PDF (DomPDF), web forms |
| 24 | FIN | StudentFee | 653 | 4,805 | 15 | 23 | 24 | ~16 | 55% | Fee structures, collection, receipts, dues, waivers |
| 25 | LIB | Library | 1,043 | 7,955 | 26 | 35 | 15 | ~35 | 45% | Book catalog, issue/return, OPAC, overdue fines |

**Finance & Operations subtotal:** 3,990 lines · 27,490 words

---

### Development_Done Summary

| Category | Modules | Total Lines | Total Words | Avg Completion |
|---|---|---|---|---|
| Central | 5 | 4,804 | 35,691 | 59% |
| School Administration | 8 | 6,162 | 43,054 | 48% |
| Academic & Curriculum | 9 | 5,390 | 34,853 | 53% |
| Timetable | 3 | 2,173 | 14,350 | 36% |
| Finance & Operations | 4 | 3,990 | 27,490 | 51% |
| **List A Total** | **29** | **22,519** | **155,438** | **~51%** |

---

## List B — Development_Pending (17 Modules, RBS_ONLY Mode)

Requirements generated from RBS (Requirements Baseline Specification) document only. No code exists. Each document covers: module overview, proposed DB schema, functional requirements, proposed API/route design, proposed controller/service structure, test plan outline, and integration dependencies.

| # | Code | Module Name | Lines | Words | Proposed Ctrl | Proposed Tables | FRs | Routes | Tests Proposed | RBS Ref | Priority |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 30 | ADM | Admission | 1,981 | 13,522 | 12 | 18 | 22 | ~54 | 10 | Module C | High |
| 31 | ACD | Academics | 1,250 | 10,012 | ~10 | ~10 | ~10 | ~30 | 8 | Module H | High |
| 32 | ATT | Attendance | 1,063 | 8,361 | ~8 | ~8 | ~8 | ~25 | 6 | Module E | High |
| 33 | CAF | Cafeteria | 969 | 6,806 | 8 | 10 | 9 | ~52 | 10 | Module W | Medium |
| 34 | COM | Communication | 1,207 | 8,813 | ~10 | 11 | 25 | ~45 | 12 | Module V | High |
| 35 | CRT | Certificate | 1,131 | 7,780 | ~8 | 8 | 12 | ~30 | 10 | Module Z | Medium |
| 36 | EXA | Examination | 1,115 | 8,285 | ~10 | 16 | 14 | ~40 | 12 | Module I | High |
| 37 | FAC | FinanceAccounting | 1,167 | 9,354 | ~12 | 14 | 14 | ~50 | 12 | Module K | High |
| 38 | FOF | FrontOffice | 1,547 | 10,577 | 10 | 12 | ~15 | ~50 | 20 | Module D | Medium |
| 39 | HRS | HrStaff | 1,343 | 9,347 | ~12 | 14 | 29 | ~60 | 15 | Module R | High |
| 40 | HST | Hostel | 981 | 8,384 | 14 | 15 | ~18 | ~50 | 12 | Module O | Medium |
| 41 | INV | Inventory | 1,068 | 8,898 | 14 | 19 | 15 | ~55 | 11 | Module L | Medium |
| 42 | LXP | Lxp | 1,116 | 7,704 | ~10 | 14 | 12 | ~35 | 15 | Module T | High |
| 43 | MNT | Maintenance | 950 | 6,765 | 8 | 9 | ~10 | ~58 | 10 | Module Y | Low |
| 44 | PAN | PredictiveAnalytics | 1,228 | 9,056 | ~10 | 12 | 17 | ~40 | 12 | Module U | Medium |
| 45 | PPT | ParentPortal | 1,054 | 7,639 | ~8 | 10 | ~12 | ~35 | 10 | Module S | High |
| 46 | VSM | VisitorSecurity | 863 | 5,963 | ~6 | 8 | ~8 | ~30 | 8 | Module D | Medium |
| | **List B Total** | | **20,033** | **147,266** | | | | | | | |

### List B Development Priority Classification

**High Priority** (must build before platform GA): ADM, ACD, ATT, COM, EXA, FAC, HRS, LXP, PPT
**Medium Priority** (post-GA or concurrent): CAF, CRT, FOF, HST, INV, PAN, VSM
**Low Priority** (phase 3): MNT

---

## Platform-Wide P0 Security Issues (Must Fix Before Production)

The following critical issues were identified during requirement extraction from live code. They represent production blockers and must be resolved before any public deployment.

### P0-001 — Zero Authentication on SystemConfigController (Module: SYS)
- **File:** `Modules/SystemConfig/Http/Controllers/SystemConfigController.php`
- **Severity:** Critical
- **Impact:** All 7 controller methods are accessible without any authentication or authorization middleware. An unauthenticated attacker can read and modify system configuration values.
- **Fix Required:** Apply `auth:sanctum` + appropriate role/permission middleware to all routes in `SystemConfig/routes/web.php` and `api.php`.
- **Requirement Document:** [SYS_SystemConfig_Requirement.md](Development_Done/SYS_SystemConfig_Requirement.md)

### P0-002 — Hardcoded API Keys in QuestionBank (Module: QNS)
- **File:** `Modules/QuestionBank/Http/Controllers/` (one or more controllers)
- **Severity:** Critical
- **Impact:** Third-party AI service API keys (likely OpenAI or similar) are hardcoded directly in PHP source files. Any git repository exposure or code review leaks the keys, resulting in unauthorized API usage and billing fraud.
- **Fix Required:** Move all API keys to `.env` file, access via `config()` helpers. Rotate all exposed keys immediately. Add `.env` secret scanning to CI/CD pipeline.
- **Requirement Document:** [QNS_QuestionBank_Requirement.md](Development_Done/QNS_QuestionBank_Requirement.md)

### P0-003 — Fatal PHP Error in LmsHomework (Module: HMW)
- **File:** `Modules/LmsHomework/Http/Controllers/` — `HoemworkData()` method (note: typo in method name)
- **Severity:** Critical (crashes homework listing for all students/teachers)
- **Impact:** Fatal PHP error causes HTTP 500 on the homework data endpoint. The feature is non-functional in production. Affects all classes attempting to access homework assignments.
- **Fix Required:** Debug and resolve the fatal error. Additionally fix the method name typo (`HoemworkData` → `HomeworkData`) and add regression test coverage.
- **Requirement Document:** [HMW_LmsHomework_Requirement.md](Development_Done/HMW_LmsHomework_Requirement.md)

### Additional High-Severity Warnings (Not P0 but Must Fix Before GA)

| ID | Module | Issue | Document |
|---|---|---|---|
| W-001 | NTF | All notification routes commented out — feature completely disabled | [NTF_Notification_Requirement.md](Development_Done/NTF_Notification_Requirement.md) |
| W-002 | TTS | Standard Timetable only 5% complete — controller is a stub | [TTS_StandardTimetable_Requirement.md](Development_Done/TTS_StandardTimetable_Requirement.md) |
| W-003 | STP | Student Portal at 35% — significant gaps vs RBS spec | [STP_StudentPortal_Requirement.md](Development_Done/STP_StudentPortal_Requirement.md) |
| W-004 | DSH | Dashboard at 39% — most widget data sources not implemented | [DSH_Dashboard_Requirement.md](Development_Done/DSH_Dashboard_Requirement.md) |
| W-005 | Multiple | 14 of 29 FULL-mode modules have zero test coverage | See index above |

---

## Processing Mode Legend

### FULL Mode (Development_Done — 29 modules)

Applied to modules where substantial Laravel code already exists. The requirement document is **extracted and reverse-engineered** from:
1. Controller source files — route bindings, method signatures, validation rules, business logic
2. Model files — Eloquent relationships, fillable fields, casts, scopes
3. Service/Job/Event files — business process flows
4. Database schema (`tenant_db.sql`, `prime_db.sql`, `global_db.sql`) — table structures, constraints, indexes
5. Test files — Pest/PHPUnit test cases, assertions, edge cases
6. Routes files (`web.php`, `api.php`) — named routes, middleware groups

FULL mode documents act as both **as-built documentation** and **gap analysis** — they identify what is implemented vs what RBS specified.

### RBS_ONLY Mode (Development_Pending — 17 modules)

Applied to modules where **no Laravel code has been written yet**. The requirement document is **greenfield specification** derived entirely from:
1. The RBS (Requirements Baseline Specification) master document
2. Platform architecture patterns established by existing modules
3. Integration dependency analysis with completed modules

RBS_ONLY mode documents act as **implementation blueprints** — they define the full scope before a single line of code is written. Each document includes proposed DB schema, proposed controller structure, route naming conventions (following established patterns), and a test plan outline.

---

## File Statistics

### Development_Done (29 files) — Detailed Breakdown

| File | Lines | Words | Approx. Pages |
|---|---|---|---|
| HPC_Hpc_Requirement.md | 1,669 | 10,866 | ~43 |
| CMP_Complaint_Requirement.md | 1,626 | 12,327 | ~49 |
| BIL_Billing_Requirement.md | 1,623 | 13,341 | ~53 |
| GLB_GlobalMaster_Requirement.md | 1,181 | 8,480 | ~34 |
| LIB_Library_Requirement.md | 1,043 | 7,955 | ~32 |
| QNS_QuestionBank_Requirement.md | 871 | 5,084 | ~20 |
| STT_SmartTimetable_Requirement.md | 852 | 5,750 | ~23 |
| SCH_SchoolSetup_Requirement.md | 837 | 5,439 | ~22 |
| TTF_TimetableFoundation_Requirement.md | 783 | 5,382 | ~22 |
| STD_StudentProfile_Requirement.md | 739 | 5,292 | ~21 |
| VND_Vendor_Requirement.md | 728 | 4,975 | ~20 |
| EXM_LmsExam_Requirement.md | 716 | 4,529 | ~18 |
| DOC_Documentation_Requirement.md | 699 | 5,698 | ~23 |
| NTF_Notification_Requirement.md | 685 | 4,193 | ~17 |
| TPT_Transport_Requirement.md | 677 | 4,573 | ~18 |
| FIN_StudentFee_Requirement.md | 653 | 4,805 | ~19 |
| PAY_Payment_Requirement.md | 625 | 3,864 | ~15 |
| QUZ_LmsQuiz_Requirement.md | 612 | 4,205 | ~17 |
| SLB_Syllabus_Requirement.md | 607 | 4,077 | ~16 |
| STP_StudentPortal_Requirement.md | 582 | 3,960 | ~16 |
| SYS_SystemConfig_Requirement.md | 542 | 3,623 | ~14 |
| TTS_StandardTimetable_Requirement.md | 538 | 3,218 | ~13 |
| QST_LmsQuests_Requirement.md | 530 | 3,638 | ~15 |
| HMW_LmsHomework_Requirement.md | 523 | 3,339 | ~13 |
| SLK_SyllabusBooks_Requirement.md | 497 | 2,983 | ~12 |
| DSH_Dashboard_Requirement.md | 488 | 3,964 | ~16 |
| REC_Recommendation_Requirement.md | 452 | 3,038 | ~12 |
| SCH_JOB_Scheduler_Requirement.md | 382 | 2,291 | ~9 |
| PRM_Prime_Requirement.md | 759 | 4,549 | ~18 |
| **List A Total** | **22,519** | **155,438** | **~620** |

### Development_Pending (17 files) — Detailed Breakdown

| File | Lines | Words | Approx. Pages |
|---|---|---|---|
| ADM_Admission_Requirement.md | 1,981 | 13,522 | ~54 |
| FOF_FrontOffice_Requirement.md | 1,547 | 10,577 | ~42 |
| HRS_HrStaff_Requirement.md | 1,343 | 9,347 | ~37 |
| ACD_Academics_Requirement.md | 1,250 | 10,012 | ~40 |
| PAN_PredictiveAnalytics_Requirement.md | 1,228 | 9,056 | ~36 |
| COM_Communication_Requirement.md | 1,207 | 8,813 | ~35 |
| FAC_FinanceAccounting_Requirement.md | 1,167 | 9,354 | ~37 |
| CRT_Certificate_Requirement.md | 1,131 | 7,780 | ~31 |
| LXP_Lxp_Requirement.md | 1,116 | 7,704 | ~31 |
| EXA_Examination_Requirement.md | 1,115 | 8,285 | ~33 |
| INV_Inventory_Requirement.md | 1,068 | 8,898 | ~36 |
| ATT_Attendance_Requirement.md | 1,063 | 8,361 | ~33 |
| PPT_ParentPortal_Requirement.md | 1,054 | 7,639 | ~31 |
| HST_Hostel_Requirement.md | 981 | 8,384 | ~34 |
| CAF_Cafeteria_Requirement.md | 969 | 6,806 | ~27 |
| MNT_Maintenance_Requirement.md | 950 | 6,765 | ~27 |
| VSM_VisitorSecurity_Requirement.md | 863 | 5,963 | ~24 |
| **List B Total** | **20,033** | **147,266** | **~588** |

### Combined Totals

| Metric | Value |
|---|---|
| Total lines | 42,552 |
| Total words | 302,704 |
| Estimated printed pages (at 250 words/page) | ~1,211 pages |
| Average lines per FULL mode document | 777 lines |
| Average lines per RBS_ONLY document | 1,178 lines |
| Average words per FULL mode document | 5,360 words |
| Average words per RBS_ONLY document | 8,663 words |
| Largest document (FULL) | ADM: 1,981 lines / 13,522 words |
| Smallest document (FULL) | SCH_JOB: 382 lines / 2,291 words |
| Largest document (RBS_ONLY) | ADM: 1,981 lines / 13,522 words |
| Smallest document (RBS_ONLY) | VSM: 863 lines / 5,963 words |

> Note: RBS_ONLY documents are consistently longer than FULL mode documents because they include
> proposed schema DDL, full FR elaborations, and test plan outlines that are more expansive as
> greenfield blueprints, whereas FULL mode documents are constrained to what the code actually implements.

---

## Module Dependency Map

Key cross-module dependencies relevant to implementation sequencing:

```
PRM ──► BIL          (billing requires prime tenant records)
PRM ──► GLB          (prime uses global reference data)
SCH ──► STD          (student profiles require school/class setup)
SCH ──► TTF ──► STT  (smart timetable requires timetable foundation)
SCH ──► TTF ──► TTS  (standard timetable requires timetable foundation)
SLB ──► SLK          (syllabus books map to syllabus topics)
SLB ──► QNS          (question bank references syllabus topics)
QNS ──► EXM          (exam papers drawn from question bank)
QNS ──► QUZ          (quizzes drawn from question bank)
STD ──► FIN          (student fees require student profiles)
STD ──► HPC          (health records linked to student profiles)
STD ──► STP          (student portal requires student profiles)
FIN ──► PAY          (payment gateway integrates with fee module)
NTF ──► ALL          (notification system consumed by all modules)
SYS ──► ALL          (system config provides settings to all modules)
--- Pending modules ---
STD ──► ADM          (admission feeds student profile creation)
STD ──► ATT          (attendance linked to enrolled students)
EXM ──► EXA          (formal examination extends LMS exam patterns)
FIN ──► FAC          (finance accounting integrates with fee collection)
STD ──► PPT          (parent portal mirrors student portal data)
```

---

## Revision History

| Date | Version | Description | Author |
|---|---|---|---|
| 2026-03-26 | v1.0 | Initial creation — all 46 module requirement documents indexed | AI-assisted |

---

*This index file is the navigation root for the Prime-AI Platform Requirement Library v1.*
*All relative links in the Index column point to files within the `Development_Done/` and `Development_Pending/` subdirectories adjacent to this file.*
*Total library: 46 documents · 302,704 words · ~1,211 estimated pages.*
