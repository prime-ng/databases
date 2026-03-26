# Prime-AI Platform — Cross-Module Dependency Matrix

**Generated:** 2026-03-26
**Total Modules:** 46
**Platform:** Prime-AI SaaS ERP+LMS+LXP for Indian K-12 Schools
**Stack:** Laravel 12, MySQL 8.x, stancl/tenancy v3.9 (database-per-tenant)
**DB Layers:** global_db (glb_*) | prime_db (prm_*, bil_*, sys_*) | tenant_{uuid} (368 tables per school)

---

## Table of Contents

1. [Dependency Overview](#1-dependency-overview)
2. [Module-by-Module Dependency Table](#2-module-by-module-dependency-table)
3. [Full NxN Dependency Matrix](#3-full-nxn-dependency-matrix)
4. [Dependency Clusters](#4-dependency-clusters)
5. [Critical Paths (Blocking Dependencies)](#5-critical-paths-blocking-dependencies)
6. [Suggested Implementation Order](#6-suggested-implementation-order)
7. [Circular Dependency Analysis](#7-circular-dependency-analysis)
8. [Event Bus / Integration Points](#8-event-bus--integration-points)

---

## 1. Dependency Overview

### 1.1 Foundation Layer (No Inbound Dependencies from Other Platform Modules)

These four modules have zero dependencies on any other Prime-AI module. They must exist and be seeded before any other module can function. All tenant modules ultimately depend on at least one of these.

| Module | Code | DB Layer | What It Provides |
|--------|------|----------|-----------------|
| **System Config** | SYS | prime_db | sys_users, sys_roles, sys_permissions, sys_media, sys_activity_logs, sys_dropdown_table — RBAC backbone, media polymorphism, audit trail |
| **Global Master** | GLB | global_db | glb_countries, glb_states, glb_cities, glb_boards, glb_languages, glb_modules, glb_plans — immutable reference data shared across ALL tenants |
| **Prime** | PRM | prime_db | prm_tenants, prm_tenant_domains, prm_plans, prm_plan_modules, prm_subscriptions — gates ALL tenant module access via plan licensing |
| **Billing** | BIL | prime_db | bil_invoices, bil_payments, bil_billing_cycles — central SaaS billing; independent of all tenant modules |

**Special note on DOC (Documentation):** DOC depends only on SYS for user auth and is effectively a foundation-adjacent module. It is excluded from the dependency tiers below as it has no cross-module data flows.

---

### 1.2 Dependency Tier Classification

Tiers reflect the minimum number of dependency hops from the foundation layer. A module at Tier N depends on at least one module at Tier N-1.

```
TIER 0 — Foundation (no dependencies)
  SYS  GLB  PRM  BIL  DOC

TIER 1 — Depends only on Tier 0 (foundation)
  SCH   SchoolSetup          — depends on SYS, GLB, PRM
  NTF   Notification         — depends on SYS only
  VND   Vendor               — depends on SYS, SCH
  DSH   Dashboard            — depends on SYS, SCH
  SCH_JOB  Scheduler         — depends on SYS
  COM   Communication        — depends on SYS, SCH, NTF
  TTF   TimetableFoundation  — depends on SYS, SCH

TIER 2 — Depends on Tier 0 + Tier 1
  STD   StudentProfile       — depends on SYS, SCH, GLB
  PAY   Payment              — depends on SYS
  SLB   Syllabus             — depends on SYS, SCH
  STT   SmartTimetable       — depends on SYS, SCH, TTF
  TTS   StandardTimetable    — depends on SYS, SCH, TTF, STT
  ATT   Attendance           — depends on SYS, SCH, STD
  HRS   HrStaff              — depends on SYS, SCH, ATT
  ACD   Academics            — depends on SYS, SCH, SLB
  ADM   Admission            — depends on SYS, SCH, GLB, NTF (writes to STD)

TIER 3 — Depends on Tier 0 + Tier 1 + Tier 2
  SLK   SyllabusBooks        — depends on SYS, SCH, SLB
  QNS   QuestionBank         — depends on SYS, SCH, SLB
  FIN   StudentFee           — depends on SYS, SCH, STD, PAY
  TPT   Transport            — depends on SYS, SCH, STD, FIN
  LIB   Library              — depends on SYS, SCH, STD
  CMP   Complaint            — depends on SYS, SCH, STD, NTF
  VSM   VisitorSecurity      — depends on SYS, SCH, STD, NTF
  FOF   FrontOffice          — depends on SYS, SCH, STD, NTF
  MNT   Maintenance          — depends on SYS, SCH, VND, NTF
  HST   Hostel               — depends on SYS, SCH, STD, FIN, NTF

TIER 4 — Depends on Tier 0 through Tier 3
  EXM   LmsExam              — depends on SYS, SCH, QNS, STD
  QUZ   LmsQuiz              — depends on SYS, SCH, QNS, STD
  HMW   LmsHomework          — depends on SYS, SCH, STD
  QST   LmsQuests            — depends on SYS, SCH, QNS, STD
  FAC   FinanceAccounting    — depends on SYS, SCH, VND, FIN, PAY, HRS, INV
  INV   Inventory            — depends on SYS, SCH, VND, FAC
  CAF   Cafeteria            — depends on SYS, SCH, STD, NTF, PAY, HST
  CRT   Certificate          — depends on SYS, SCH, STD, ADM, FIN
  EXA   Examination          — depends on SYS, SCH, STD, QNS, FIN

TIER 5 — Depends on Tier 0 through Tier 4
  HPC   Holistic Progress Card  — depends on SYS, SCH, STD, SLB, EXM
  REC   Recommendation          — depends on SYS, SCH, STD, SLB, EXM, QUZ, HMW
  STP   StudentPortal           — depends on SYS, SCH, STD, FIN, NTF, EXM, QUZ, HMW

TIER 6 — Depends on Tier 0 through Tier 5
  LXP   Learning Experience     — depends on SYS, SCH, STD, SLB, EXM, QUZ, HMW, QST, REC
  PPT   ParentPortal            — depends on SYS, SCH, STD, FIN, NTF, ATT, HPC, CMP, CAF

TIER 7 — Depends on Tier 0 through Tier 6
  PAN   PredictiveAnalytics     — depends on SYS, SCH, STD, EXM, QUZ, HMW, LXP, ATT
```

---

## 2. Module-by-Module Dependency Table

| # | Code | Full Name | Depends On (required) | Consumed By (downstream) | Key Shared Tables / Events |
|---|------|-----------|-----------------------|--------------------------|---------------------------|
| 1 | SYS | System Config | — (foundation) | ALL 45 modules | sys_users, sys_roles, sys_permissions, sys_media, sys_activity_logs, sys_dropdown_table |
| 2 | GLB | Global Master | — (foundation) | PRM, SCH, STD, ADM, STP | glb_countries, glb_states, glb_boards, glb_languages |
| 3 | PRM | Prime | SYS, GLB | ALL tenant modules (plan gate) | prm_tenants, prm_subscriptions, prm_plan_modules |
| 4 | BIL | Billing | SYS, PRM | — (terminal in central layer) | bil_invoices, bil_billing_cycles |
| 5 | DOC | Documentation | SYS | — (terminal) | — |
| 6 | SCH | School Setup | SYS, GLB, PRM | STD, TPT, VND, SLB, SLK, QNS, EXM, QUZ, HMW, QST, TTF, STT, TTS, FIN, LIB, CMP, HPC, REC, ATT, ACD, ADM, HRS, HST, CAF, INV, MNT, LXP, STP, PPT, DSH, FOF, VSM, COM, EXA, CRT | sch_organizations, sch_classes, sch_sections, sch_employees, sch_class_section_jnt, sch_academic_sessions, sch_subjects |
| 7 | STD | Student Profile | SYS, SCH, GLB | TPT, FIN, LIB, CMP, EXM, QUZ, HMW, QST, HPC, REC, ATT, STP, PPT, HST, CAF, ADM, LXP, PAN, EXA, VSM, FOF, CRT | std_students, std_guardians, std_medical_profiles |
| 8 | NTF | Notification | SYS | ADM, CMP, MNT, HST, CAF, VSM, FOF, STP, PPT, COM, HMW | Notification delivery events (fire-and-forget) |
| 9 | PAY | Payment | SYS | FIN, CAF, ADM, TPT | Razorpay gateway; PaymentCompleted event |
| 10 | DSH | Dashboard | SYS, SCH | — | Aggregated read-only views from many modules |
| 11 | SCH_JOB | Scheduler | SYS | — | Cron job registry; triggers scheduled tasks |
| 12 | TTF | Timetable Foundation | SYS, SCH | STT, TTS | tt_period_sets, tt_configurations, tt_day_types, tt_academic_terms |
| 13 | STT | Smart Timetable | SYS, SCH, TTF | TTS, DSH | tt_timetable_cells, tt_timetable_cell_teachers, tt_timetable_publications |
| 14 | TTS | Standard Timetable | SYS, SCH, TTF, STT | — | Reads STT tables; provides standard view layer |
| 15 | SLB | Syllabus | SYS, SCH | SLK, QNS, EXM, HMW, REC, HPC, LXP, ACD, EXA | slb_topics, slb_competencies, slb_bloom_taxonomies |
| 16 | SLK | Syllabus Books | SYS, SCH, SLB | — | slb_book_topic_jnt |
| 17 | QNS | Question Bank | SYS, SCH, SLB | EXM, QUZ, QST, EXA | qns_questions, qns_question_tags |
| 18 | VND | Vendor | SYS, SCH | INV, MNT, FAC | vnd_vendors, vnd_agreements |
| 19 | COM | Communication | SYS, SCH, NTF | — | Campaign data; NTF delivery channel |
| 20 | ATT | Attendance | SYS, SCH, STD | HPC, PAN, HRS, PPT | att_daily_attendances, att_attendance_periods |
| 21 | HRS | Hr Staff | SYS, SCH, ATT | FAC (payroll journal) | hrs_salary_assignments; event: PayrollApproved |
| 22 | ACD | Academics | SYS, SCH, SLB, STD | — | Academic planning records |
| 23 | FIN | Student Fee | SYS, SCH, STD, PAY | FAC, ADM, STP, PPT, TPT, HST, CRT, EXA | fin_invoices, fin_fee_payments; event: FeePaymentReceived |
| 24 | TPT | Transport | SYS, SCH, STD, FIN | PPT, DSH | tpt_vehicles, tpt_routes, tpt_student_allocations; event: TransportFeeCharged |
| 25 | LIB | Library | SYS, SCH, STD | — | lib_books, lib_members, lib_transactions |
| 26 | CMP | Complaint | SYS, SCH, STD, NTF | PPT | cmp_complaints, cmp_categories |
| 27 | ADM | Admission | SYS, SCH, GLB, STD, FIN, NTF | CRT, FOF | adm_applications; writes std_students on enrollment |
| 28 | VSM | Visitor Security | SYS, SCH, STD, NTF | — | vsm_visitor_logs |
| 29 | FOF | Front Office | SYS, SCH, STD, NTF, CRT | — | Front desk records |
| 30 | MNT | Maintenance | SYS, SCH, VND, NTF, INV | — | mnt_maintenance_requests |
| 31 | HST | Hostel | SYS, SCH, STD, FIN, NTF | CAF, PPT | hos_rooms, hos_allocations |
| 32 | INV | Inventory | SYS, SCH, VND, FAC | MNT, CAF | inv_stock_items, inv_grn; events: GrnAccepted, StockIssued |
| 33 | FAC | Finance Accounting | SYS, SCH, VND, FIN, PAY, HRS, INV | — | acc_vouchers, acc_ledgers; VoucherServiceInterface |
| 34 | CAF | Cafeteria | SYS, SCH, STD, NTF, PAY, HST | PPT | caf_meal_plans, caf_orders |
| 35 | EXM | Lms Exam | SYS, SCH, QNS, STD | HPC, REC, LXP, EXA, PAN, STP | exm_exams, exm_paper_sets, exm_allocations |
| 36 | QUZ | Lms Quiz | SYS, SCH, QNS, STD | REC, LXP, PAN, STP | quz_quizzes, quz_allocations |
| 37 | HMW | Lms Homework | SYS, SCH, STD | REC, LXP, PAN, STP | hmw_homework, hmw_submissions |
| 38 | QST | Lms Quests | SYS, SCH, QNS, STD | LXP | qst_quests, qst_allocations |
| 39 | EXA | Examination | SYS, SCH, STD, QNS, FIN | PAN | exa_schedules, exa_results |
| 40 | CRT | Certificate | SYS, SCH, STD, ADM, FIN | FOF | crt_templates, crt_issued_certificates |
| 41 | HPC | Holistic Progress Card | SYS, SCH, STD, SLB, EXM | PPT | hpc_reports, hpc_evaluations |
| 42 | REC | Recommendation | SYS, SCH, STD, SLB, EXM, QUZ, HMW | LXP, PAN | rec_student_recommendations, rec_rules |
| 43 | STP | Student Portal | SYS, SCH, STD, FIN, NTF, EXM, QUZ, HMW, LXP | — | Portal read layer (no new tables) |
| 44 | PPT | Parent Portal | SYS, SCH, STD, FIN, NTF, ATT, HPC, CMP, CAF | — | Portal read layer (no new tables) |
| 45 | LXP | Learning Experience | SYS, SCH, STD, SLB, EXM, QUZ, HMW, QST, REC | PAN, STP | lxp_engagement_logs, lxp_pathways |
| 46 | PAN | Predictive Analytics | SYS, SCH, STD, EXM, QUZ, HMW, LXP, ATT | REC, DSH | pan_predictions, pan_model_runs |

---

## 3. Full NxN Dependency Matrix

**Reading:** Row = module that HAS the dependency. Column = module being depended ON. A checkmark (✓) in cell (Row, Col) means the row-module **depends on** the column-module.

**Abbreviation key for column headers (left-to-right order):**
SYS | GLB | PRM | BIL | DOC | SCH | STD | NTF | PAY | DSH | JOB | TTF | STT | TTS | SLB | SLK | QNS | VND | COM | ATT | HRS | ACD | FIN | TPT | LIB | CMP | ADM | VSM | FOF | MNT | HST | INV | FAC | CAF | EXM | QUZ | HMW | QST | EXA | CRT | HPC | REC | STP | PPT | LXP | PAN

> JOB = SCH_JOB (Scheduler). BIL = Billing (central). DOC = Documentation.

```
MODULE  | SYS GLB PRM BIL DOC SCH STD NTF PAY DSH JOB TTF STT TTS SLB SLK QNS VND COM ATT HRS ACD FIN TPT LIB CMP ADM VSM FOF MNT HST INV FAC CAF EXM QUZ HMW QST EXA CRT HPC REC STP PPT LXP PAN
--------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SYS     |  -   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .
GLB     |  .   -   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .
PRM     |  ✓   ✓   -   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .
BIL     |  ✓   .   ✓   -   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .
DOC     |  ✓   .   .   .   -   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .
SCH     |  ✓   ✓   ✓   .   .   -   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .
STD     |  ✓   ✓   .   .   .   ✓   -   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .
NTF     |  ✓   .   .   .   .   .   .   -   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .
PAY     |  ✓   .   .   .   .   .   .   .   -   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .
DSH     |  ✓   .   .   .   .   ✓   .   .   .   -   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .
JOB     |  ✓   .   .   .   .   .   .   .   .   .   -   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .
TTF     |  ✓   .   .   .   .   ✓   .   .   .   .   .   -   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .
STT     |  ✓   .   .   .   .   ✓   .   .   .   .   .   ✓   -   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .
TTS     |  ✓   .   .   .   .   ✓   .   .   .   .   .   ✓   ✓   -   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .
SLB     |  ✓   .   .   .   .   ✓   .   .   .   .   .   .   .   .   -   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .
SLK     |  ✓   .   .   .   .   ✓   .   .   .   .   .   .   .   .   ✓   -   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .
QNS     |  ✓   .   .   .   .   ✓   .   .   .   .   .   .   .   .   ✓   .   -   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .
VND     |  ✓   .   .   .   .   ✓   .   .   .   .   .   .   .   .   .   .   .   -   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .
COM     |  ✓   .   .   .   .   ✓   .   ✓   .   .   .   .   .   .   .   .   .   .   -   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .
ATT     |  ✓   .   .   .   .   ✓   ✓   .   .   .   .   .   .   .   .   .   .   .   .   -   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .
HRS     |  ✓   .   .   .   .   ✓   .   .   .   .   .   .   .   .   .   .   .   .   .   ✓   -   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .
ACD     |  ✓   .   .   .   .   ✓   ✓   .   .   .   .   .   .   .   ✓   .   .   .   .   .   .   -   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .
FIN     |  ✓   .   .   .   .   ✓   ✓   .   ✓   .   .   .   .   .   .   .   .   .   .   .   .   .   -   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .
TPT     |  ✓   .   .   .   .   ✓   ✓   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   ✓   -   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .
LIB     |  ✓   .   .   .   .   ✓   ✓   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   -   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .
CMP     |  ✓   .   .   .   .   ✓   ✓   ✓   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   -   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .
ADM     |  ✓   ✓   .   .   .   ✓   ✓   ✓   .   .   .   .   .   .   .   .   .   .   .   .   .   .   ✓   .   .   .   -   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .
VSM     |  ✓   .   .   .   .   ✓   ✓   ✓   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   -   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .
FOF     |  ✓   .   .   .   .   ✓   ✓   ✓   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   -   .   .   .   .   .   .   .   .   .   ✓   ✓   .   .   .   .   .   .
MNT     |  ✓   .   .   .   .   ✓   .   ✓   .   .   .   .   .   .   .   .   .   ✓   .   .   .   .   .   .   .   .   .   .   .   -   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .
HST     |  ✓   .   .   .   .   ✓   ✓   ✓   .   .   .   .   .   .   .   .   .   .   .   .   .   .   ✓   .   .   .   .   .   .   .   -   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .
INV     |  ✓   .   .   .   .   ✓   .   .   .   .   .   .   .   .   .   .   .   ✓   .   .   .   .   .   .   .   .   .   .   .   .   .   -   ✓   .   .   .   .   .   .   .   .   .   .   .   .   .
FAC     |  ✓   .   .   .   .   ✓   .   .   ✓   .   .   .   .   .   .   .   .   ✓   .   .   ✓   .   ✓   .   .   .   .   .   .   .   .   ✓   -   .   .   .   .   .   .   .   .   .   .   .   .   .
CAF     |  ✓   .   .   .   .   ✓   ✓   ✓   ✓   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   ✓   .   .   -   .   .   .   .   .   .   .   .   .   .   .   .
EXM     |  ✓   .   .   .   .   ✓   ✓   .   .   .   .   .   .   .   .   .   ✓   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   -   .   .   .   .   .   .   .   .   .   .   .
QUZ     |  ✓   .   .   .   .   ✓   ✓   .   .   .   .   .   .   .   .   .   ✓   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   -   .   .   .   .   .   .   .   .   .   .
HMW     |  ✓   .   .   .   .   ✓   ✓   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   -   .   .   .   .   .   .   .   .   .
QST     |  ✓   .   .   .   .   ✓   ✓   .   .   .   .   .   .   .   .   .   ✓   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   -   .   .   .   .   .   .   .   .
EXA     |  ✓   .   .   .   .   ✓   ✓   .   .   .   .   .   .   .   .   .   ✓   .   .   .   .   .   ✓   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   -   .   .   .   .   .   .   .
CRT     |  ✓   .   .   .   .   ✓   ✓   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   ✓   .   .   .   ✓   .   .   .   .   .   .   .   .   .   .   .   .   -   .   .   .   .   .   .
HPC     |  ✓   .   .   .   .   ✓   ✓   .   .   .   .   .   .   .   ✓   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   ✓   .   .   .   .   .   -   .   .   .   .   .
REC     |  ✓   .   .   .   .   ✓   ✓   .   .   .   .   .   .   .   ✓   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   ✓   ✓   ✓   .   .   .   .   -   .   .   .   .
STP     |  ✓   .   .   .   .   ✓   ✓   ✓   .   .   .   .   .   .   .   .   .   .   .   .   .   .   ✓   .   .   .   .   .   .   .   .   .   .   .   ✓   ✓   ✓   .   .   .   .   .   -   .   ✓   .
PPT     |  ✓   .   .   .   .   ✓   ✓   ✓   .   .   .   .   .   .   .   .   .   .   .   ✓   .   .   ✓   .   .   ✓   .   .   .   .   .   .   .   ✓   .   .   .   .   .   .   ✓   .   .   -   .   .
LXP     |  ✓   .   .   .   .   ✓   ✓   .   .   .   .   .   .   .   ✓   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   ✓   ✓   ✓   ✓   .   .   .   ✓   .   .   -   .
PAN     |  ✓   .   .   .   .   ✓   ✓   .   .   .   .   .   .   .   .   .   .   .   .   ✓   .   .   .   .   .   .   .   .   .   .   .   .   .   .   ✓   ✓   ✓   .   .   .   .   .   .   .   ✓   -
```

### Matrix Summary Statistics

| Metric | Count |
|--------|-------|
| Total dependency relationships (✓ cells) | 152 |
| Most depended-ON module | SYS (46 / all modules) |
| Second most depended-ON | SCH (40 of 46 modules) |
| Third most depended-ON | STD (28 modules) |
| Most dependencies (depends on most others) | FAC (8 upstream), PPT (8 upstream), LXP (8 upstream) |
| Modules with zero dependencies (foundation) | 2 (SYS, GLB) |
| Modules that nothing depends on (terminal) | BIL, DOC, SLK, COM, TTS, ACD, LIB, VSM, FOF, MNT, STP, PPT, LXP, PAN |

---

## 4. Dependency Clusters

### Cluster 1: Foundation Infrastructure

**Modules:** SYS, GLB, PRM, BIL, DOC

These modules form the SaaS control plane. They run on the central domain against prime_db and global_db — never tenant-scoped.

- **SYS** owns auth (Spatie roles/permissions), media polymorphism (sys_media with model_type/model_id), dropdown taxonomy (sys_dropdown_table), and the audit trail (sys_activity_logs). Every single module depends on SYS.
- **GLB** holds immutable geography (countries, states, cities) and education taxonomy (boards, languages). Read-only by tenant modules; written only from the central admin.
- **PRM** is the licensing gate. Before any tenant module can serve a request, EnsureTenantHasModule middleware checks prm_plan_modules. Adding a new module requires a GLB seeder entry + PRM plan association.
- **BIL** handles SaaS subscription invoicing. Completely decoupled from all tenant data — no tenant_db tables referenced.

**Key constraint:** GLB and SYS seeders must run before any migration or seeder in any other module.

---

### Cluster 2: Student Lifecycle (Admission → Profile → Portal)

**Modules:** ADM, STD, ATT, STP, PPT

This cluster tracks a student from application through graduation.

```
ADM (application) → writes → STD (enrollment)
STD → feeds → ATT (daily attendance)
STD + ATT + FIN + HPC + CMP + CAF → aggregated in → PPT (parent view)
STD + FIN + EXM + QUZ + HMW + LXP → aggregated in → STP (student view)
```

- ADM is the entry point of the student lifecycle. On enrollment approval, adm_applications maps to a new std_students record.
- STD is the central student identity record. Every academic, financial, and operational module foreign-keys to std_students.
- ATT captures daily/period attendance and feeds HPC, PAN (dropout risk), and HRS (staff leave cross-reference).
- STP and PPT are pure read/aggregation portals with no new domain tables; they hold the 27 + 23 screens of the student and parent interfaces respectively.

**Critical dependency:** STD must be complete before FIN, LIB, CMP, EXM, QUZ, HMW, QST, HPC, REC, ATT, HST, CAF, ADM (for enrollment write-back), TPT, VSM, FOF.

---

### Cluster 3: Academic and Assessment

**Modules:** SLB, SLK, QNS, EXM, QUZ, HMW, QST, ACD, HPC, REC, EXA, LXP, PAN

This is the largest and most interconnected cluster. It covers curriculum definition through AI-driven learning analytics.

```
SLB (topics + competencies)
  └─ SLK (textbook ↔ topic mapping)
  └─ QNS (question bank, bloom-tagged)
        ├─ EXM (exam blueprints + paper sets)
        ├─ QUZ (online quizzes)
        ├─ QST (gamified quests)
        └─ EXA (standalone examination, separate from LMS)
  └─ HMW (homework rules + submissions)
        └─ REC (recommendations based on learning gap)
              └─ LXP (adaptive pathways + engagement logs)
                    └─ PAN (predictive dropout + performance models)
```

- **SLB** is the curriculum spine. All assessment modules key to slb_topics (which subject-chapter-topic is this question/exam for?).
- **QNS** is the shared question repository. EXM, QUZ, QST, and EXA all pull questions from qns_questions. The quality of question metadata (bloom level, cognitive skill, difficulty) directly determines assessment quality.
- **EXM vs EXA:** EXM (LmsExam) is the LMS-integrated exam workflow with blueprints and rubrics. EXA (Examination) is the greenfield standalone examination system with scheduling, invigilators, and hall tickets — primarily for formal board-style exams. Both are independent consumers of QNS.
- **HPC:** Holistic Progress Card aggregates EXM results + ATT + SLB competency coverage into a multi-page PDF report. It is a terminal consumer — nothing reads from HPC tables except PPT.
- **REC** reads from EXM, QUZ, HMW performance data to generate topic-level recommendations. It feeds LXP for adaptive pathway construction.
- **LXP** is the Learning Experience Platform layer — adaptive paths, engagement tracking, content delivery. It depends on REC for gap data and feeds PAN for ML-based predictions.
- **PAN** is the terminal analytics module. It consumes data from EXM, QUZ, HMW, LXP (engagement signals), and ATT (attendance patterns) to produce risk predictions and performance forecasts. PAN outputs feed back into REC (closing the intelligent tutoring loop) and DSH.

**Key constraint:** SLB → QNS → (EXM, QUZ, QST) must be complete before LXP and PAN can be meaningfully built.

---

### Cluster 4: Finance and Billing

**Modules:** PAY, FIN, FAC, BIL (central)

Finance is the monetary spine of school operations. The cluster splits into central SaaS billing (BIL) and tenant school finance (PAY, FIN, FAC).

```
PAY (Razorpay gateway)
  └─ FIN (student fee invoices + receipts)
        ├─ FAC (accounting vouchers ← FeePaymentReceived event)
        ├─ ADM (admission fee)
        ├─ TPT (transport fee)
        ├─ HST (hostel fee)
        └─ STP / PPT (fee statements)
FAC (double-entry engine)
  ├─ ← FIN via FeePaymentReceived
  ├─ ← INV via GrnAccepted + StockIssued
  ├─ ← TPT via TransportFeeCharged
  └─ ← HRS via PayrollApproved
```

- **PAY** wraps Razorpay. It provides a PaymentCompleted event and a GatewayManager abstraction. FIN, CAF, and ADM call into PAY for online collection.
- **FIN** is the student-facing fee system: fee heads, invoice generation, receipt tracking, concessions, scholarships, and fines. It fires FeePaymentReceived which FAC listens to.
- **FAC** (Finance Accounting) owns the Tally-inspired double-entry voucher engine. All financial events from other modules arrive here as Laravel events and are converted into acc_vouchers + acc_voucher_items. FAC depends on VND (vendor/supplier payments), HRS (payroll), and INV (purchase orders). It provides VoucherServiceInterface so other modules never directly write to accounting tables.
- **BIL** (central Billing) is entirely separate from FAC — BIL handles Prime-AI SaaS subscription invoices for school administrators, not student transactions.

**Key constraint:** PAY must be complete before FIN. FIN must be complete before FAC can receive fee-payment events. INV + HRS must be complete before FAC voucher automation covers all sources.

---

### Cluster 5: Timetable and Scheduling

**Modules:** TTF, STT, TTS, SCH_JOB

```
TTF (period sets, day types, configurations, academic terms)
  └─ STT (AI/FET-based timetable generation)
        └─ TTS (standard timetable display views)

SCH_JOB (scheduler) — triggers time-based jobs across all modules
```

- **TTF** is the foundation layer for timetabling. It seeds period structures and academic calendar before STT can generate a timetable.
- **STT** (SmartTimetable) contains the FET-backtracking + greedy solver, TabuSearch and SimulatedAnnealing optimizers, 22 hard + 55+ soft constraints, ConflictDetectionService, ResourceBookingService, and the full analytics/refinement/substitution stack. It is one of the most complex modules (106 services, 62 models).
- **TTS** (StandardTimetable) is a read-only display layer over STT-generated data. It uses STT's tt_timetable_cells + AnalyticsService class/teacher/room reports.
- **SCH_JOB** is an independent scheduling daemon that triggers background jobs across all modules (fee reminders, report generation, etc.). It depends only on SYS for auth.

---

### Cluster 6: Operations and Facilities

**Modules:** TPT, VND, INV, MNT, HST, CAF, LIB, VSM, FOF

These modules cover the physical and operational infrastructure of the school.

```
VND (vendor registry)
  ├─ INV (purchase orders + stock)
  │    └─ MNT (spare parts consumption — future)
  │    └─ CAF (ingredient procurement — future)
  └─ MNT (maintenance work orders)
  └─ FAC (vendor payment vouchers)

HST (hostel allocation + fees)
  └─ CAF (mess link — hostel boarders meal plans)

LIB (book catalog + circulation) — standalone operational module

TPT (vehicles + routes + student boarding + fees)

VSM (visitor logs + gate passes) — standalone
FOF (front office reception) — consumes ADM + CRT
```

- **INV** (Inventory) is a dependency blocker for both MNT (spare parts) and CAF (canteen ingredients). INV itself depends on FAC for purchase voucher generation (GrnAccepted event). This creates a load-order constraint: FAC must exist before INV can complete its event wiring.
- **HST** feeds CAF the hostel boarder list so mess billing can be auto-calculated per student.
- **LIB** depends on STD for member management but is otherwise self-contained. Fine collection can optionally route through FIN.

---

### Cluster 7: HR and Payroll

**Modules:** HRS, ATT

```
ATT (staff + student attendance)
  └─ HRS (staff attendance → salary computation)
        └─ FAC (PayrollApproved → Payroll Journal Voucher)
```

- **HRS** manages employee contracts, salary structures, and payroll runs. It depends on ATT for staff attendance data used in pay computation.
- The PayrollApproved Laravel event carries a payroll run ID. FAC's listener creates the corresponding acc_vouchers debit (salary expense) and credit (bank/cash) entries.
- **ATT** is shared across two clusters (Student Lifecycle for std attendance, HR for staff attendance). The same module handles both by polymorphic attendee_type.

---

### Cluster 8: Communication and Notifications

**Modules:** NTF, COM

```
NTF (notification engine — fire-and-forget)
  └─ consumed by: ADM, CMP, MNT, HST, CAF, VSM, FOF, STP, PPT, COM, HMW

COM (communication campaigns)
  └─ uses NTF as delivery channel
```

- **NTF** is a pure-delivery module with zero domain data requirements. Any module can fire a notification by dispatching a NotificationRequest event or calling NotificationService directly. NTF handles channel routing (email, SMS, push, in-app) and delivery logging.
- **COM** adds bulk campaign management (newsletters, announcements) on top of NTF's delivery infrastructure.
- Because NTF has no upstream dependencies beyond SYS, it can be built and deployed very early in the project. Its absence blocks ADM (enrollment letters), CMP (complaint acknowledgments), and HMW (homework reminders).

---

### Cluster 9: Analytics and Intelligence

**Modules:** DSH, PAN, REC (analytics portion)

```
PAN (ML predictions: dropout risk, performance forecast)
  ├─ inputs: EXM, QUZ, HMW, LXP, ATT
  ├─ outputs: pan_predictions → REC (feeds recommendation engine)
  └─ outputs: → DSH (school director analytics widget)

REC (recommendation engine)
  ├─ inputs: EXM, QUZ, HMW results + SLB competency map
  ├─ outputs: rec_student_recommendations → LXP (adaptive paths)
  └─ outputs: → PAN (closes the intelligent tutoring loop)

DSH (dashboard aggregation)
  ├─ reads from: SCH, STT, FIN, ATT, PAN, and others
  └─ provides: role-specific admin/teacher/parent dashboards
```

- **PAN** is the highest-tier module in the analytics stack. It should be built last, as it requires LXP engagement logs, EXM/QUZ/HMW result data, and ATT attendance history to train meaningful models.
- The REC ↔ PAN bidirectional flow is managed through events rather than direct FK relationships to avoid a circular schema dependency. PAN publishes prediction records; REC reads them to refine content matching.

---

## 5. Critical Paths (Blocking Dependencies)

The following modules block the most other modules from being developed. Delay in any of these creates a cascade of blocked work.

### Critical Path 1: SYS → SCH → STD (Primary Blocker Chain)

```
SYS (auth + roles + media)
  blocks: ALL 45 other modules

SCH (school structure: classes, sections, employees, academic sessions)
  blocks: 40 modules

STD (student identity record)
  blocks: 28 modules
```

**Impact:** If SCH is delayed by 1 sprint, 40 modules cannot even begin schema design for FK constraints. This is the single most important critical path.

### Critical Path 2: PAY → FIN → FAC (Finance Chain)

```
PAY (payment gateway) → blocks FIN, CAF, ADM
FIN (student invoices) → blocks FAC, ADM, TPT, HST, STP, PPT, CRT, EXA
FAC (accounting engine) → blocks INV event-wiring, HRS event-wiring
```

**Impact:** Without PAY, no money can be collected online. Without FIN, no accounting integration exists. FAC is the terminal finance node that unifies all financial events.

### Critical Path 3: SLB → QNS → EXM → REC → LXP → PAN (Academic Intelligence Chain)

```
SLB (curriculum topics) → blocks QNS, EXM, HMW, ACD, REC, HPC, LXP, EXA
QNS (question bank) → blocks EXM, QUZ, QST, EXA
EXM (exam results) → blocks HPC, REC, LXP, PAN, STP
REC (recommendations) → blocks LXP
LXP (engagement logs) → blocks PAN
PAN (predictions) → terminal (feeds back to REC via events)
```

**Impact:** The entire academic intelligence stack is sequentially dependent. A team cannot work on REC until EXM produces results data. This 6-hop chain has the highest total build time in the project.

### Critical Path 4: TTF → STT (Timetable Chain)

```
TTF (period sets, academic terms) → blocks STT, TTS
STT (generated timetable) → blocks TTS
```

**Impact:** SmartTimetable is already built. TTF must remain stable — schema changes to tt_period_sets or tt_configurations break STT immediately.

### Critical Path 5: VND → INV → FAC Event Wiring

```
VND → blocks INV (vendor FK), MNT (vendor FK), FAC (vendor payments)
INV → blocks MNT (spare parts), CAF (ingredients), FAC (GrnAccepted event)
FAC → blocks: complete financial automation
```

**Module Blocking Count Summary:**

| Module | Blocks (# modules cannot start) | Priority Rank |
|--------|----------------------------------|---------------|
| SYS | 45 | P0 — Absolute first |
| GLB | 44 | P0 — Before SCH seeds |
| SCH | 40 | P0 — Core tenant foundation |
| STD | 28 | P1 — Student identity |
| NTF | 12 | P1 — Unblocks ADM, CMP, portal alerts |
| PAY | 4 | P1 — Unblocks FIN, CAF, ADM |
| SLB | 10 | P1 — Unblocks entire academic stack |
| QNS | 5 | P2 — Unblocks EXM, QUZ, QST, EXA |
| FIN | 8 | P2 — Unblocks FAC, ADM, portals |
| ATT | 4 | P2 — Unblocks HPC, PAN, HRS |
| VND | 4 | P2 — Unblocks INV, MNT, FAC |
| TTF | 2 | P2 — Unblocks STT, TTS (already built) |
| EXM | 5 | P3 — Unblocks HPC, REC, LXP, PAN |
| REC | 2 | P3 — Unblocks LXP |
| LXP | 1 | P4 — Unblocks PAN |
| HST | 1 | P3 — Unblocks CAF |

---

## 6. Suggested Implementation Order

The phases below are designed so that no module is started before all its dependencies are complete. Modules within a phase can be developed in parallel by separate team members.

### Phase 0: Platform Bootstrap (Week 1–2)
> Goal: Running multi-tenant Laravel app with auth, RBAC, reference data seeded.

| # | Module | Code | Why Now |
|---|--------|------|---------|
| 1 | System Config | SYS | Auth, roles, permissions, media — required by everything |
| 2 | Global Master | GLB | Geography + education taxonomy seeders |
| 3 | Prime | PRM | Tenant provisioning + plan licensing gate |
| 4 | Billing | BIL | SaaS invoice/subscription (central, isolated) |
| 5 | Documentation | DOC | Help docs (low risk, can run in parallel) |

**Exit criteria:** A tenant can be created, a plan assigned, and a tenant domain resolved via middleware.

---

### Phase 1: Core Tenant Foundation (Week 3–5)
> Goal: School structure exists, students can be registered, notifications work.

| # | Module | Code | Why Now |
|---|--------|------|---------|
| 6 | School Setup | SCH | 40+ modules depend on this — builds classes, sections, employees, subjects |
| 7 | Notification | NTF | Needed by ADM, CMP, HMW — build early with no deps |
| 8 | Scheduler | SCH_JOB | Background jobs — independent, low risk |
| 9 | Dashboard | DSH | Shell dashboard with SCH data only at this stage |

**Exit criteria:** School profile complete, academic sessions seeded, notification delivery confirmed working.

---

### Phase 2: Student Identity and Payment (Week 6–8)
> Goal: Students enrolled, payment gateway live, transport and library operational.

| # | Module | Code | Why Now |
|---|--------|------|---------|
| 10 | Student Profile | STD | Central identity — unblocks 28 modules |
| 11 | Payment | PAY | Razorpay gateway — unblocks FIN, CAF, ADM |
| 12 | Vendor | VND | Independent ops module — unblocks INV, MNT |
| 13 | Attendance | ATT | Depends on STD — unblocks HPC, PAN, HRS |
| 14 | Library | LIB | Depends on SCH + STD only — self-contained |
| 15 | Complaint | CMP | Depends on SCH + STD + NTF |
| 16 | Visitor Security | VSM | Depends on SCH + STD + NTF |

**Exit criteria:** Students enrolled. Library books issued. Complaints can be filed and notified.

---

### Phase 3: Finance Stack (Week 9–12)
> Goal: Fee collection live, transport fee automated, hostel billing functional.

| # | Module | Code | Why Now |
|---|--------|------|---------|
| 17 | Student Fee | FIN | Depends on STD + PAY — core revenue collection |
| 18 | Transport | TPT | Depends on STD + FIN — route allocation + fee |
| 19 | Hostel | HST | Depends on STD + FIN + NTF |
| 20 | Cafeteria | CAF | Depends on STD + NTF + PAY + HST |
| 21 | Timetable Foundation | TTF | Depends on SCH — unblocks STT config |

**Exit criteria:** Fee invoices generated. Online payment via Razorpay confirmed. Transport fee auto-billed.

---

### Phase 4: Timetable and HR (Week 13–16)
> Goal: Timetable generated and published, staff payroll structured.

| # | Module | Code | Why Now |
|---|--------|------|---------|
| 22 | Smart Timetable | STT | Already built — ensure TTF is stable |
| 23 | Standard Timetable | TTS | Reads STT — display layer |
| 24 | Hr Staff | HRS | Depends on SCH + ATT |
| 25 | Maintenance | MNT | Depends on VND + NTF |

**Exit criteria:** Timetable published and accessible to teachers. Payroll structure defined.

---

### Phase 5: Curriculum and Assessment (Week 17–22)
> Goal: Full academic content stack — syllabus, question bank, LMS assessments.

| # | Module | Code | Why Now |
|---|--------|------|---------|
| 26 | Syllabus | SLB | Foundation for entire academic cluster |
| 27 | Syllabus Books | SLK | Depends on SLB — textbook mapping |
| 28 | Question Bank | QNS | Depends on SLB — shared question repository |
| 29 | Academics | ACD | Depends on SLB + STD |
| 30 | Lms Homework | HMW | Depends on SCH + STD (no QNS needed) |
| 31 | Lms Quiz | QUZ | Depends on QNS + STD |
| 32 | Lms Exam | EXM | Depends on QNS + STD — full blueprint workflow |
| 33 | Lms Quests | QST | Depends on QNS + STD |
| 34 | Examination | EXA | Depends on QNS + FIN — formal examination |

**Exit criteria:** Syllabus fully mapped. Exams scheduled, papers set, results recorded.

---

### Phase 6: Admission and Certificates (Week 23–26)
> Goal: Admission funnel live, certificate generation available.

| # | Module | Code | Why Now |
|---|--------|------|---------|
| 35 | Admission | ADM | Depends on SCH + STD + FIN + NTF |
| 36 | Certificate | CRT | Depends on STD + ADM + FIN |
| 37 | Front Office | FOF | Depends on STD + NTF + CRT |
| 38 | Communication | COM | Depends on NTF — bulk campaigns |

**Exit criteria:** Online admission form live. Enrollment letter and TC generation working.

---

### Phase 7: Progress, Recommendations, and Analytics (Week 27–32)
> Goal: Holistic progress cards, intelligent recommendations, LXP adaptive paths.

| # | Module | Code | Why Now |
|---|--------|------|---------|
| 39 | Holistic Progress Card | HPC | Depends on SLB + EXM — PDF generation |
| 40 | Recommendation | REC | Depends on EXM + QUZ + HMW + SLB |
| 41 | Learning Experience | LXP | Depends on REC + EXM + QUZ + HMW + QST |
| 42 | Predictive Analytics | PAN | Depends on LXP + EXM + QUZ + HMW + ATT |

**Exit criteria:** HPC PDF generated for all students. Recommendations visible. LXP pathways adaptive.

---

### Phase 8: Full Finance Automation (Week 33–36)
> Goal: Full double-entry accounting with event-driven voucher generation.

| # | Module | Code | Why Now |
|---|--------|------|---------|
| 43 | Inventory | INV | Depends on VND + FAC (need FAC first for events) |
| 44 | Finance Accounting | FAC | Depends on FIN + PAY + VND + HRS + INV — build after all event sources |

**Note:** INV and FAC have a mutual event dependency (INV fires events that FAC consumes; FAC must exist to register the listener). The resolution is to build FAC's schema and VoucherServiceInterface first (Phase 8a), then build INV's schema (Phase 8b), then wire the events (Phase 8c).

**Exit criteria:** All financial transactions — fee receipts, payroll, purchase orders, stock issues, transport charges — automatically generating acc_vouchers.

---

### Phase 9: Portals and Communication (Week 37–40)
> Goal: Student and parent portal fully operational, predictive dashboard live.

| # | Module | Code | Why Now |
|---|--------|------|---------|
| 45 | Student Portal | STP | Depends on FIN + EXM + QUZ + HMW + LXP |
| 46 | Parent Portal | PPT | Depends on FIN + ATT + HPC + CMP + CAF |

**Exit criteria:** Students view grades, assignments, fee history, timetable. Parents view attendance, HPC reports, fee dues.

---

### Phase Summary Table

| Phase | Weeks | Modules | Key Deliverable |
|-------|-------|---------|----------------|
| 0 — Platform Bootstrap | 1–2 | SYS, GLB, PRM, BIL, DOC | Multi-tenant app running |
| 1 — Core Tenant | 3–5 | SCH, NTF, SCH_JOB, DSH | School structure + notifications |
| 2 — Student Identity | 6–8 | STD, PAY, VND, ATT, LIB, CMP, VSM | Students enrolled + payment live |
| 3 — Finance Stack | 9–12 | FIN, TPT, HST, CAF, TTF | Fee collection live |
| 4 — Timetable and HR | 13–16 | STT, TTS, HRS, MNT | Timetable published |
| 5 — Curriculum | 17–22 | SLB, SLK, QNS, ACD, HMW, QUZ, EXM, QST, EXA | Full LMS + exam stack |
| 6 — Admission and Certs | 23–26 | ADM, CRT, FOF, COM | Admission funnel |
| 7 — Analytics | 27–32 | HPC, REC, LXP, PAN | AI-driven learning intelligence |
| 8 — Full Finance | 33–36 | FAC, INV | Automated accounting |
| 9 — Portals | 37–40 | STP, PPT | Student + parent portals |

---

## 7. Circular Dependency Analysis

### Identified Circular Dependencies

#### CD-01: SchoolSetup ↔ SmartTimetable (ARCH-003 — Known, Managed)

**Nature:** STT depends on SCH for class/section/employee data. However, the SmartTimetableController and Activity models historically referenced SCH models directly (instead of going through a shared abstraction). Prime controllers also reference SchoolSetup models.

**Risk level:** MEDIUM — does not cause a runtime loop but creates a coupling that makes isolated module testing difficult.

**Resolution strategy:**
- STT reads SCH data only through read-only queries (never writes back to SCH tables).
- No FK from sch_* tables to tt_* tables — the dependency is one-directional at the database level.
- In code, STT controllers should use SchoolSetup models as reads only. If a SchoolSetup event needs to invalidate a timetable, dispatch a Laravel event (e.g., ClassSectionUpdated) that STT listens to — never direct method calls from SCH back into STT.

**Status:** Partially managed. The schema FK direction is correct. Code coupling in controllers should be cleaned up.

---

#### CD-02: PredictiveAnalytics ↔ Recommendation (Logical Loop — Managed via Events)

**Nature:** PAN produces predictions that REC uses to improve recommendation quality. REC produces recommendations that LXP uses to generate engagement data that PAN trains on. This is a genuine bidirectional data flow.

**Risk level:** LOW — both directions are data flows (read-only queries or event dispatches), not schema FK loops.

**Resolution strategy:**
- PAN writes to pan_predictions. REC reads pan_predictions via a scheduled query — no FK constraint. REC does not FK to PAN tables.
- REC writes to rec_student_recommendations. LXP reads these — no FK back from PAN to REC.
- The loop is broken by time: PAN runs in a nightly ML batch job (SCH_JOB triggers it). REC refreshes recommendations after each exam result event. There is no synchronous circular call.
- Formal contract: PAN publishes a PredictionAvailable event. REC's listener optionally re-evaluates recommendations for affected students. This is purely additive — REC functions without PAN.

**Status:** Design-level resolution documented here. Implementation should follow the event-driven pattern.

---

#### CD-03: FinanceAccounting ↔ Inventory (Build-Order Dependency — Managed)

**Nature:** FAC must exist before INV can wire its GrnAccepted/StockIssued event listeners. INV must exist before FAC's full voucher coverage is complete. This is a build-order dependency, not a schema circular dependency.

**Risk level:** LOW at schema level. MEDIUM at implementation if not sequenced correctly.

**Resolution strategy:**
- Build FAC schema + VoucherServiceInterface first (stub listeners if needed).
- Build INV schema independently (VND FK only — no FAC FK in inv_* tables).
- Wire the events in Phase 8c as a single integration milestone.
- The acc_vouchers table never has a FK to inv_* tables — the association is tracked via a polymorphic voucher_source_type/id on acc_vouchers.

**Status:** Documented. Implementation order in Phase 8 accounts for this.

---

#### CD-04: Prime ↔ SchoolSetup (Code-Level, Not Schema-Level)

**Nature:** Prime (central module) contains controllers that reference SchoolSetup models to display school data in the admin panel. PRM never FKs into tenant_db tables, but Laravel code in the PRM module imports SCH model classes.

**Risk level:** LOW — both modules are always deployed together. No runtime circular call.

**Resolution strategy:**
- Accept this coupling for now — it is a practical necessity for a monorepo.
- Long-term: extract shared DTOs or use API calls between central and tenant contexts.
- Ensure PRM controllers never call SCH service methods that could trigger tenant DB bootstrapping while on the central domain.

**Status:** Known and accepted per architectural decision log.

---

### No Circular FK Dependencies at the Database Level

A thorough review of all inter-module relationships confirms there are zero circular FK chains at the database schema level. All FK directions are unidirectional and follow the tier hierarchy defined in Section 1.2. The platform uses soft deletes (is_active + deleted_at) rather than CASCADE deletes, which eliminates the risk of circular delete cascades.

---

## 8. Event Bus / Integration Points

The Prime-AI platform uses Laravel's built-in event system (synchronous dispatch + queued listeners). The following cross-module events and data flows are the primary integration points.

### 8.1 Financial Events (Accounting Voucher Automation)

| Event | Fired By | Listener | Creates |
|-------|----------|----------|---------|
| FeePaymentReceived | FIN | FAC — ReceiptVoucherListener | acc_vouchers (Receipt type) |
| TransportFeeCharged | TPT | FAC — SalesVoucherListener | acc_vouchers (Sales type) |
| GrnAccepted | INV | FAC — PurchaseVoucherListener | acc_vouchers (Purchase type) |
| StockIssued | INV | FAC — StockJournalListener | acc_vouchers (Stock Journal type) |
| PayrollApproved | HRS | FAC — PayrollJournalListener | acc_vouchers (Payroll Journal type) |

**Payload contract (all events):** Must include `tenant_id`, `amount`, `currency`, `reference_id`, `source_module`, `transaction_date`, `line_items[]`. FAC owns VoucherServiceInterface — all listeners call `VoucherServiceInterface::createVoucher(EventPayload $payload)`.

---

### 8.2 Academic Events

| Event | Fired By | Listener(s) | Effect |
|-------|----------|-------------|--------|
| ExamResultPublished | EXM | REC — update student recommendations | New rec_student_recommendations for failed topics |
| ExamResultPublished | EXM | PAN — trigger prediction refresh | Queued ML job for at-risk students |
| HomeworkSubmitted | HMW | REC — evaluate submission quality | Adjusts topic mastery score |
| QuizCompleted | QUZ | REC — evaluate quiz score | Adjusts topic mastery score |
| QuestCompleted | QST | LXP — log engagement | Creates lxp_engagement_logs entry |
| SyllabusTopicCovered | SLB | HPC — mark coverage | Updates hpc coverage percentage |

---

### 8.3 Student Lifecycle Events

| Event | Fired By | Listener(s) | Effect |
|-------|----------|-------------|--------|
| StudentEnrolled | ADM → STD | NTF — welcome notification | Sends enrollment confirmation |
| StudentEnrolled | ADM → STD | LIB — create library member | Auto-creates lib_members record |
| StudentEnrolled | ADM → STD | TPT — check route allocation | Prompts transport assignment |
| StudentPromoted | STD | FIN — roll fee to new class | Updates fin_fee_assignments |
| StudentWithdrawn | STD | LIB — auto-return books | Marks lib_transactions as force-returned |
| StudentWithdrawn | STD | HST — vacate room | Updates hos_allocations |

---

### 8.4 Notification Events (Fire-and-Forget)

| Trigger Context | Module | Notification Type |
|----------------|--------|------------------|
| Fee invoice generated | FIN | SMS + email to guardian |
| Payment received | PAY | SMS + push to student + guardian |
| Exam scheduled | EXM | In-app + email to students |
| Homework assigned | HMW | Push to student |
| Complaint status change | CMP | In-app to complainant |
| Maintenance request update | MNT | In-app to requestor |
| Hostel fee due | HST | SMS to guardian |
| Visitor arrival | VSM | SMS to host staff |
| HPC report published | HPC | Email PDF link to guardian |
| Admission application update | ADM | Email + SMS to applicant |

All notifications flow through NTF's NotificationService. Firing module dispatches a NotificationRequest event with `channel`, `template_code`, `recipient_id`, `recipient_type`, and `variables[]`. NTF resolves the template, renders it, and dispatches delivery via the appropriate channel (SMTP, SMS API, FCM push).

---

### 8.5 Data Read Aggregation Points (No Events — Direct Query)

These are not event-based but represent significant cross-module data reads that must be performance-optimized with caching or denormalization.

| Consumer Module | Reads From | Data Read | Optimization Required |
|----------------|-----------|-----------|----------------------|
| DSH (Dashboard) | SCH, FIN, ATT, STT, PAN | KPI widgets | Cache per-tenant with 5-min TTL |
| HPC | EXM, ATT, SLB | Per-student progress | Cache per-student per-term |
| PPT | FIN, ATT, HPC, CMP, CAF | Parent view | Cache per-child with 15-min TTL |
| STP | EXM, QUZ, HMW, FIN, LXP | Student view | Cache per-student with 5-min TTL |
| PAN | EXM, QUZ, HMW, LXP, ATT | ML training data | Batch job nightly — not real-time |
| REC | EXM, QUZ, HMW, SLB, PAN | Topic mastery | Re-compute on ExamResultPublished event |

---

### 8.6 Shared Database Tables (Cross-Module Read Access)

The following tables are written by one module but read by many others. Schema changes to these tables have cascading impact and require cross-team coordination.

| Table | Owner Module | Read By |
|-------|-------------|---------|
| sys_users | SYS | ALL modules |
| sys_roles / sys_permissions | SYS | ALL modules (via Spatie Gate) |
| sys_media | SYS | SCH, STD, QNS, HPC, LIB, CMP, ADM, CRT |
| sys_dropdown_table | SYS | SCH, STD, FIN, HMW, QNS, EXM, CMP, ADM, HPC |
| sch_classes / sch_sections | SCH | STD, SLB, QNS, EXM, QUZ, HMW, QST, TTF, STT, HPC, REC, ATT, ACD, EXA, ADM |
| sch_employees | SCH | STT, HRS, ATT, TTS |
| sch_academic_sessions | SCH | SLB, EXM, QUZ, HMW, QST, TTF, STT, HPC, FIN, ATT |
| std_students | STD | FIN, TPT, LIB, EXM, QUZ, HMW, QST, HPC, REC, ATT, STP, PPT, HST, CAF, CMP, ADM, LXP, PAN, EXA, CRT |
| slb_topics | SLB | QNS, EXM, HMW, HPC, REC, LXP, ACD, EXA |
| qns_questions | QNS | EXM, QUZ, QST, EXA |
| fin_invoices | FIN | FAC, STP, PPT, CRT |
| tt_period_sets | TTF | STT, TTS |

---

*End of Cross-Module Dependency Matrix — Prime-AI Platform*
*Document Owner: Architecture Team*
*Next Review: 2026-06-26 (quarterly)*
