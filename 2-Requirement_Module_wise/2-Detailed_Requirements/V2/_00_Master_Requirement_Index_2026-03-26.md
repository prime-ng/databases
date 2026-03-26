# Master Requirement Index — Prime-AI Platform
**Date:** 2026-03-26
**Version:** V2.0
**Scope:** All 46 modules — ERP + LMS + LXP for Indian K-12 schools
**Platform:** Laravel 12 + PHP 8.2 + MySQL 8.x + Multi-tenant SaaS

---

## 1. Summary Statistics

| Metric | Count | Notes |
|--------|-------|-------|
| Total modules | 46 | |
| V2 files completed | 17 | Batches 1, 8, 9, 10 |
| V2 files pending | 29 | Batches 2–7 |
| Mode: FULL | 29 | Batches 1–6 — full narrative + schema |
| Mode: RBS_ONLY | 17 | Batches 7–10 — RBS feature list only |
| Scope: Central | 5 | Modules 1–5 (global SaaS layer) |
| Scope: Tenant | 41 | Modules 6–46 (per-school layer) |
| Total V2 lines written | ~21,610 | Completed 17 modules |
| Avg lines per FULL module | ~1,340 | Range: 1,030–1,596 |
| Avg lines per RBS_ONLY module | ~1,200 | Range: ~800–1,987 |

---

## 2. Batch Summary

| Batch | Modules | Mode | V2 Status | Notes |
|-------|---------|------|-----------|-------|
| 1 | PRM, BIL, GLB, SYS, SCH_JOB | FULL | ✅ Done | Central layer — SaaS platform |
| 2 | SCH, TTF, STT, TTS, DSH | FULL | ⏳ Pending | School setup + Timetable |
| 3 | STD, STP, SLB, SLK, DOC | FULL | ⏳ Pending | Student + Syllabus |
| 4 | HMW, QUZ, QST, EXM, QNS | FULL | ⏳ Pending | LMS assessment suite |
| 5 | FIN, PAY, NTF, CMP, REC | FULL | ⏳ Pending | Finance + Notifications |
| 6 | TPT, LIB, VND, HPC | FULL | ⏳ Pending | Ops + Hardware/HPC |
| 7 | ADM, ATT, ACD, EXA, FOF | RBS_ONLY | ⏳ Pending | Core school ops |
| 8 | HRS, FAC, INV, HST, COM | RBS_ONLY | ✅ Done | Backend services |
| 9 | LXP, PAN, CRT, PPT, CAF | RBS_ONLY | ✅ Done | Emerging + portals |
| 10 | VSM, MNT | RBS_ONLY | ✅ Done | Facility ops |

---

## 3. Complete Module Index

| # | Code | Full Name | Table Prefix | Scope | Batch | Mode | V2 File | Lines | Key Features |
|---|------|-----------|-------------|-------|-------|------|---------|-------|--------------|
| 1 | PRM | Prime App | prm_ | Central | 1 | FULL | PRM_Prime_Requirement.md | 1,405 | Tenant mgmt, plan subscriptions, module licensing, white-labeling |
| 2 | BIL | Billing | bil_ | Central | 1 | FULL | BIL_Billing_Requirement.md | 1,585 | SaaS billing, invoicing, payment gateway, dunning, usage metering |
| 3 | GLB | Global Master | glb_ | Central | 1 | FULL | GLB_GlobalMaster_Requirement.md | 1,596 | Countries, states, boards, languages, currencies, translations |
| 4 | SYS | System Config | sys_ | Central | 1 | FULL | SYS_SystemConfig_Requirement.md | 1,066 | Roles, permissions, settings, dropdowns, media, audit logs |
| 5 | SCH_JOB | Scheduler/Jobs | sch_job_ | Central | 1 | FULL | SCH_JOB_Scheduler_Requirement.md | 1,030 | Cron jobs, queue workers, scheduled tasks, job monitoring |
| 6 | SCH | School Setup | sch_ | Tenant | 2 | FULL | ⏳ Pending | — | School profile, branches, academic years, class/section setup |
| 7 | TTF | Timetable Foundation | tt_ | Tenant | 2 | FULL | ⏳ Pending | — | Period config, day types, subject-teacher mapping, constraints |
| 8 | STT | Smart Timetable | tt_ | Tenant | 2 | FULL | ⏳ Pending | — | Auto-generation, backtracking solver, analytics, substitution |
| 9 | TTS | Standard Timetable | tt_ | Tenant | 2 | FULL | ⏳ Pending | — | Manual timetable creation, class/teacher/room views |
| 10 | DSH | Dashboard | dash_ | Tenant | 2 | FULL | ⏳ Pending | — | Role-based dashboards, widgets, KPI tiles, quick actions |
| 11 | STD | Student Profile | std_ | Tenant | 3 | FULL | ⏳ Pending | — | Student registration, family, documents, health, history |
| 12 | STP | Student Portal | stp_ | Tenant | 3 | FULL | ⏳ Pending | — | Student self-service portal, assignments, results, fee view |
| 13 | SLB | Syllabus | slb_ | Tenant | 3 | FULL | ⏳ Pending | — | Curriculum mapping, lesson plans, topic coverage tracking |
| 14 | SLK | Syllabus Books | bok_ | Tenant | 3 | FULL | ⏳ Pending | — | Book lists, publisher catalog, assignment to class/subject |
| 15 | DOC | Documentation | doc_ | Tenant | 3 | FULL | ⏳ Pending | — | Document templates, student certificates, bulk generation |
| 16 | HMW | LMS Homework | hmw_ | Tenant | 4 | FULL | ⏳ Pending | — | Homework assignment, submission, grading, feedback |
| 17 | QUZ | LMS Quiz | quz_ | Tenant | 4 | FULL | ⏳ Pending | — | Online quizzes, auto-grading, result analysis |
| 18 | QST | LMS Quests | qst_ | Tenant | 4 | FULL | ⏳ Pending | — | Gamified learning journeys, badges, leaderboards |
| 19 | EXM | LMS Exam | exm_ | Tenant | 4 | FULL | ⏳ Pending | — | Online exams, proctoring, answer sheet, result publication |
| 20 | QNS | Question Bank | qns_ | Tenant | 4 | FULL | ⏳ Pending | — | Question repository, tagging, difficulty, reuse across modules |
| 21 | FIN | Student Fee | fin_ | Tenant | 5 | FULL | ⏳ Pending | — | Fee heads, concessions, challan, due tracking, receipts |
| 22 | PAY | Payment | pay_ | Tenant | 5 | FULL | ⏳ Pending | — | Gateway integration, UPI, netbanking, reconciliation |
| 23 | NTF | Notification | ntf_ | Tenant | 5 | FULL | ⏳ Pending | — | SMS, email, push, in-app, templates, delivery status |
| 24 | CMP | Complaint | cmp_ | Tenant | 5 | FULL | ⏳ Pending | — | Complaint intake, escalation, resolution, SLA tracking |
| 25 | REC | Recommendation | rec_ | Tenant | 5 | FULL | ⏳ Pending | — | AI-driven content/learning recommendations per student |
| 26 | TPT | Transport | tpt_ | Tenant | 6 | FULL | ⏳ Pending | — | Routes, stops, vehicles, driver mgmt, GPS tracking, fee |
| 27 | LIB | Library | lib_ | Tenant | 6 | FULL | ⏳ Pending | — | Book catalog, OPAC, issue/return, fines, e-resources |
| 28 | VND | Vendor | vnd_ | Tenant | 6 | FULL | ⏳ Pending | — | Vendor master, contracts, PO, delivery, payments |
| 29 | HPC | HPC | hpc_ | Tenant | 6 | FULL | ⏳ Pending | — | High-performance computing lab, usage tracking, reports |
| 30 | ADM | Admission | adm_ | Tenant | 7 | RBS_ONLY | ⏳ Pending | — | Enquiry, application, interview, selection, enrollment |
| 31 | ATT | Attendance | att_ | Tenant | 7 | RBS_ONLY | ⏳ Pending | — | Student/staff attendance, biometric, leave, reports |
| 32 | ACD | Academics | acd_ | Tenant | 7 | RBS_ONLY | ⏳ Pending | — | Grade setup, marksheet, progress report, CCE/CBSE norms |
| 33 | EXA | Examination | exa_ | Tenant | 7 | RBS_ONLY | ⏳ Pending | — | Exam schedule, hall ticket, invigilation, marks entry |
| 34 | FOF | Front Office | fof_ | Tenant | 7 | RBS_ONLY | ⏳ Pending | — | Reception desk, visitor log, ID cards, call log, courier |
| 35 | HRS | HR & Staff | hrs_ | Tenant | 8 | RBS_ONLY | HRS_HrStaff_Requirement.md | 971 | Staff master, contracts, appraisal, payroll inputs, leave mgmt |
| 36 | FAC | Finance Accounting | acc_ | Tenant | 8 | RBS_ONLY | FAC_FinanceAccounting_Requirement.md | 1,454 | Chart of accounts, vouchers, P&L, balance sheet, D21 integration |
| 37 | INV | Inventory | inv_ | Tenant | 8 | RBS_ONLY | INV_Inventory_Requirement.md | 1,631 | Stock mgmt, GRN, issues, PO, vendor payments, audits |
| 38 | HST | Hostel | hst_ | Tenant | 8 | RBS_ONLY | HST_Hostel_Requirement.md | 1,563 | Room allocation, wardens, mess plans, hostel fees, discipline |
| 39 | COM | Communication | com_ | Tenant | 8 | RBS_ONLY | COM_Communication_Requirement.md | 1,987 | Channels, announcements, circulars, chat, SMS/email dispatch |
| 40 | LXP | Learning Experience | lxp_ | Tenant | 9 | RBS_ONLY | LXP_Lxp_Requirement.md | 990 | Adaptive learning paths, content curation, skill mapping |
| 41 | PAN | Predictive Analytics | pan_ | Tenant | 9 | RBS_ONLY | PAN_PredictiveAnalytics_Requirement.md | 1,015 | Dropout prediction, performance forecasting, intervention alerts |
| 42 | CRT | Certificate | crt_ | Tenant | 9 | RBS_ONLY | CRT_Certificate_Requirement.md | 808 | Certificate templates, auto-generation, digital signatures |
| 43 | PPT | Parent Portal | ppt_ | Tenant | 9 | RBS_ONLY | PPT_ParentPortal_Requirement.md | 1,453 | Parent app/web, fee view, attendance, results, communication |
| 44 | CAF | Cafeteria | caf_ | Tenant | 9 | RBS_ONLY | CAF_Cafeteria_Requirement.md | 1,257 | Menu mgmt, meal plans, canteen billing, dietary tracking |
| 45 | VSM | Visitor Security | vsm_ | Tenant | 10 | RBS_ONLY | ⏳ Pending (named VSM) | ~800 | Visitor log, gate pass, ID verification, security alerts |
| 46 | MNT | Maintenance | mnt_ | Tenant | 10 | RBS_ONLY | ⏳ Pending (named MNT) | ~800 | AMC, work orders, asset repairs, vendor dispatch, cost tracking |

> **Note on Batch 10:** VSM and MNT were completed and confirmed "Done" in the batch progress tracker but their V2 files may be located outside the standard V2 directory. Verify file paths before finalizing the index.

---

## 4. Completed V2 Files — Line Count Summary

| # | Code | File | Lines | Mode |
|---|------|------|-------|------|
| 1 | PRM | PRM_Prime_Requirement.md | 1,405 | FULL |
| 2 | BIL | BIL_Billing_Requirement.md | 1,585 | FULL |
| 3 | GLB | GLB_GlobalMaster_Requirement.md | 1,596 | FULL |
| 4 | SYS | SYS_SystemConfig_Requirement.md | 1,066 | FULL |
| 5 | SCH_JOB | SCH_JOB_Scheduler_Requirement.md | 1,030 | FULL |
| 6 | HRS | HRS_HrStaff_Requirement.md | 971 | RBS_ONLY |
| 7 | FAC | FAC_FinanceAccounting_Requirement.md | 1,454 | RBS_ONLY |
| 8 | INV | INV_Inventory_Requirement.md | 1,631 | RBS_ONLY |
| 9 | HST | HST_Hostel_Requirement.md | 1,563 | RBS_ONLY |
| 10 | COM | COM_Communication_Requirement.md | 1,987 | RBS_ONLY |
| 11 | LXP | LXP_Lxp_Requirement.md | 990 | RBS_ONLY |
| 12 | PAN | PAN_PredictiveAnalytics_Requirement.md | 1,015 | RBS_ONLY |
| 13 | CRT | CRT_Certificate_Requirement.md | 808 | RBS_ONLY |
| 14 | PPT | PPT_ParentPortal_Requirement.md | 1,453 | RBS_ONLY |
| 15 | CAF | CAF_Cafeteria_Requirement.md | 1,257 | RBS_ONLY |
| 16 | VSM | (Batch 10) | ~800 | RBS_ONLY |
| 17 | MNT | (Batch 10) | ~800 | RBS_ONLY |
| **—** | **TOTAL** | **17 files** | **~21,610** | |

---

## 5. Pending V2 Files — Batch Queue

| Priority | Batch | Modules | Mode | Complexity |
|----------|-------|---------|------|------------|
| Next | 2 | SCH, TTF, STT, TTS, DSH | FULL | High — STT is 2,993-line controller |
| Next | 3 | STD, STP, SLB, SLK, DOC | FULL | Medium-High |
| Next | 4 | HMW, QUZ, QST, EXM, QNS | FULL | High — LMS suite interlinked |
| Next | 5 | FIN, PAY, NTF, CMP, REC | FULL | High — FIN has complex fee logic |
| Next | 6 | TPT, LIB, VND, HPC | FULL | Medium |
| Later | 7 | ADM, ATT, ACD, EXA, FOF | RBS_ONLY | Medium |

---

## 6. Key Observations

### 6.1 Architecture Notes
- **3-layer multi-tenant SaaS:** `global_db` (shared reference) → `prime_db` (SaaS mgmt) → `tenant_db` (per-school)
- **Table prefixes are module-scoped:** Each module owns its prefix; shared tables use `sys_` and `glb_`
- **Soft deletes everywhere:** All tables carry `is_active` + `deleted_at` pattern
- **Polymorphic audit:** `sys_activity_logs` and `sys_media` serve all modules via morphable FK

### 6.2 Module Groupings by Business Domain
- **SaaS Platform:** PRM, BIL, GLB, SYS, SCH_JOB
- **School Ops:** SCH, TTF, STT, TTS, DSH, SCH_JOB
- **Student Management:** STD, STP, ATT, ACD, ADM
- **Learning (LMS/LXP):** SLB, SLK, HMW, QUZ, QST, EXM, QNS, LXP, REC
- **Finance:** FIN, PAY, FAC, BIL
- **HR & Operations:** HRS, ATT, INV, VND, MNT, HST, CAF, TPT, LIB
- **Communication & Portals:** COM, NTF, CMP, STP, PPT, FOF, VSM
- **Intelligence:** PAN, REC, LXP, DSH
- **Compliance/Certification:** CRT, EXA, DOC

### 6.3 High-Dependency Modules
These modules are consumed by many others — schema/API changes here have wide blast radius:
- **QNS** (Question Bank): consumed by QUZ, QST, EXM, HMW, LXP
- **FAC** (Finance Accounting): consumes from FIN, PAY, HRS, INV, TPT via D21 integration
- **COM** (Communication): delivery channel for NTF, HMW, CMP, ATT, ADM
- **SYS** (System Config): roles/permissions/settings consumed by ALL modules
- **GLB** (Global Master): lookup data consumed by ALL modules

### 6.4 V2 vs V1 Upgrade Notes
- V1 docs (in `Requirement_V1/`) were module-specific but inconsistent in depth
- V2 standardizes: Context → RBS Features → DB Schema → API Contracts → Business Rules → UI/UX
- FULL mode V2 docs average ~1,340 lines vs V1 average ~400 lines (+235% depth)
- RBS_ONLY V2 docs average ~1,200 lines — these are new (V1 had pending stubs only)

### 6.5 Naming Convention for V2 Files
```
{CODE}_{FullName}_Requirement.md
Examples:
  PRM_Prime_Requirement.md
  BIL_Billing_Requirement.md
  HRS_HrStaff_Requirement.md
```

---

## 7. File Location Reference

| Layer | Base Path |
|-------|-----------|
| V2 files | `2-Requirement_Module_wise/2-Detailed_Requirements/V2/` |
| V1 files (archived) | `2-Requirement_Module_wise/2-Detailed_Requirements/Requirement_V1/` |
| RBS spec | `3-Project_Planning/1-RBS/PrimeAI_Complete_Spec_v2.md` |
| Batch progress | `2-Requirement_Module_wise/2-Detailed_Requirements/V2/_batch_progress.md` |

---

*Index auto-generated 2026-03-26. Re-run after each batch completion to update line counts and status.*
