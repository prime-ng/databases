# Prime-AI Platform — Detailed Gap Analysis

**Date:** 2026-03-15
**Based on:** `PrimeAI_RBS_Menu_Mapping_v2.0.md` (27 modules, 1112 sub-tasks)
**Verified against:** Actual codebase + AI Brain deep-audit (2026-03-14/15)
**Scope:** Every pending or incomplete module, sub-module, functionality, task and sub-task

---

## Summary of Gaps

| Category | Count |
|----------|-------|
| Modules 100% missing (0% done) | **9** (K, L, O, R, SYS, T, U, W, X, Y) |
| Modules with critical gaps (<50%) | **8** (C, D, F, I, P, S, Z, M) |
| Modules functional but incomplete (50-80%) | **5** (A, B, G, H, J, Q, V) |
| Modules near-complete (>80%) | **2** (N, E partially) |
| **Total pending sub-tasks** | **~762 of 1112** |

---

## CATEGORY 1 — Modules NOT STARTED (0%)

These 9 modules have zero code implementation. They represent **359 sub-tasks** (32% of total RBS).

### Module K — Finance & Accounting (70 sub-tasks)

**No module exists.** Reserved prefix `acc_`. DB tables referenced in DDL but no Laravel module.

| Sub-Module | Sub-Tasks | What's Needed |
|-----------|----------|---------------|
| K1 — Chart of Accounts | 9 | Account groups, sub-groups, ledger CRUD, GST linkage |
| K2 — Opening Balances | 4 | Ledger opening, student/vendor CSV import |
| K3 — Journal Entry | 6 | Manual JE, approval workflow, recurring journals |
| K4 — Accounts Receivable | 8 | Auto-post fee invoices, payment recording, aging reports |
| K5 — Accounts Payable | 4 | Vendor bills, payment processing |
| K6 — Vendor Management | 4 | Vendor profiles, rating system |
| K7 — Purchase & Expense | 4 | PO creation, expense claims |
| K8 — Bank & Cash Mgmt | 6 | Bank reconciliation, cashbook |
| K9 — Asset & Depreciation | 4 | Asset register, SLM/WDV depreciation |
| K10 — Financial Reporting | 5 | Trial Balance, P&L, Balance Sheet, dashboards |
| K11 — Tally/QuickBooks Integration | 4 | XML export, API sync |
| K12 — Budget & Cost Center | 6 | Budget allocation, variance reports |
| K13 — GST & Tax Compliance | 6 | HSN/SAC codes, e-invoicing, GSTR reports |

### Module L — Inventory & Stock Management (50 sub-tasks)

**No module exists.**

| Sub-Module | Sub-Tasks | What's Needed |
|-----------|----------|---------------|
| L1 — Item Master | 10 | Categories, items, SKUs, batch/expiry tracking |
| L2 — UOM | 4 | Unit of measurement CRUD + conversion |
| L3 — Vendor Linkage | 4 | Vendor-item assignment, rate contracts |
| L4 — Purchase Requisition | 4 | PR creation, bulk upload |
| L5 — Purchase Order | 4 | PR→PO conversion, PO lifecycle |
| L6 — GRN | 4 | Goods receipt, quality check |
| L7 — Stock Ledger | 4 | Inward/outward posting |
| L8 — Stock Issue | 4 | Department issue, consumption tracking |
| L9 — Reorder Automation | 4 | Min stock alerts, auto-PR |
| L10 — Asset vs Consumable | 4 | Asset tagging, movement register |
| L11 — Reports & Analytics | 4 | Stock reports, consumption analytics |

### Module O — Hostel Management (36 sub-tasks)

**No module exists.** Reserved prefix `hos_`.

| Sub-Module | Sub-Tasks | What's Needed |
|-----------|----------|---------------|
| O1 — Hostel & Room Setup | 8 | Hostel config, room types, allocation rules |
| O2 — Student Allotment | 4 | Room assignment, change requests |
| O3 — Attendance & In-Out | 4 | Daily hostel attendance, movement register |
| O4 — Mess Management | 4 | Weekly menu, meal attendance |
| O5 — Hostel Fee | 4 | Fee assignment, proration |
| O6 — Discipline | 4 | Incident recording, warning workflow |
| O7 — Hostel Inventory | 4 | Beds/furniture tracking, damage reporting |
| O8 — Reports | 4 | Occupancy, utilization reports |

### Module R — Certificates & ID Card Management (52 sub-tasks)

**No module exists.**

| Sub-Module | Sub-Tasks | What's Needed |
|-----------|----------|---------------|
| R1 — Certificate Templates | 9 | Template designer (merge fields, QR code, versioning) |
| R2 — Request Workflow | 9 | Student request, approval stages, tracking |
| R3 — Generation & Issuance | 8 | Auto-fill, digital signature, bulk generation, print |
| R4 — Document Management | 8 | Upload, bulk upload, verification, access control |
| R5 — ID Card | 8 | ID card template designer, barcode/QR, bulk print |
| R6 — Verification System | 6 | QR scan verification, API verification |
| R7 — Reports | 4 | Issued/pending reports, analytics |

### Module SYS — System Administration (12 sub-tasks)

| Sub-Module | Sub-Tasks | What's Needed |
|-----------|----------|---------------|
| SYS1 — Health Monitoring | 4 | Real-time metrics dashboard, alerts for CPU/RAM/disk/queue |
| SYS2 — API Management | 4 | API key CRUD, webhook config, delivery logs |
| SYS3 — Data Management | 4 | Import/export wizards, data archival |

### Module T — Learner Experience Platform (47 sub-tasks)

| Sub-Module | Sub-Tasks | What's Needed |
|-----------|----------|---------------|
| T1 — Personalized Paths | 7 | Learning path creation, AI-based path suggestions |
| T2 — Skill Graph | 6 | Skill framework, skill-to-content mapping, radar chart |
| T3 — AI Recommendations | 4 | ML model for content recommendation, peer-based |
| T4 — Learning Goals | 4 | Goal setting, progress tracking, reminders |
| T5 — Gamification | 4 | Badge criteria, auto-award, leaderboards |
| T6 — Social Learning | 6 | Discussion forums, thread management, peer mentoring |
| T7 — Learning Analytics | 4 | Engagement tracking, AI outcome prediction |
| T8 — Mentorship | 8 | Program setup, matching, session logging, feedback |
| T9 — Activity Feed | 4 | Personalized feed, ranking algorithm |

### Module U — Predictive Analytics & ML Engine (51 sub-tasks)

| Sub-Module | Sub-Tasks | What's Needed |
|-----------|----------|---------------|
| U1 — Performance Prediction | 7 | Risk scoring, early warning, weak concept identification |
| U2 — Attendance Forecasting | 6 | Absence probability, intervention suggestions |
| U3 — Fee Default Prediction | 6 | Payment history analysis, auto-alerts, parent segmentation |
| U4 — Skill Gap Analysis | 8 | Competency models, personalized actions, group reports |
| U5 — Transport Optimization | 6 | Route optimization, fuel analytics, simulation |
| U6 — Resource Allocation | 4 | Teacher/room optimization |
| U7 — AI Dashboards | 6 | ML dashboards, what-if analysis, custom report builder |
| U8 — Sentiment Analysis | 4 | NLP for feedback, sentiment trends, alerts |
| U9 — Institutional Benchmarking | 4 | KPI definition, peer comparison |

### Module W — Cafeteria & Mess (12 sub-tasks)

| Sub-Module | Sub-Tasks | What's Needed |
|-----------|----------|---------------|
| W1 — Menu Management | 4 | Weekly menu planner, publish & notify |
| W2 — Online Ordering | 4 | Pre-booking interface, order management |
| W3 — Kitchen Stock | 4 | Raw material inventory, consumption tracking |

### Module X — Visitor & Security (12 sub-tasks)

| Sub-Module | Sub-Tasks | What's Needed |
|-----------|----------|---------------|
| X1 — Digital Registration | 4 | Pre-registration QR, walk-in registration |
| X2 — Gate Security | 4 | Check-in/out scanning, overdue flagging |
| X3 — Security Alerts | 4 | Live dashboard, emergency broadcast |

### Module Y — Maintenance Helpdesk (12 sub-tasks)

| Sub-Module | Sub-Tasks | What's Needed |
|-----------|----------|---------------|
| Y1 — Ticketing System | 8 | Ticket creation, auto-prioritization, technician assignment, tracking |
| Y2 — Preventive Maintenance | 4 | PM checklists, auto-generated work orders |

---

## CATEGORY 2 — Modules with Critical Gaps (<50%)

### Module C — Admissions & Student Lifecycle (25% done, 42 sub-tasks pending)

| Sub-Module | Status | Gap Details |
|-----------|--------|------------|
| **C1 — Enquiry & Lead** (0%) | NOT STARTED | Need: AdmissionEnquiry module with lead capture, counselor assignment, follow-up scheduling, status tracking, lead→application conversion. 9 sub-tasks. |
| **C2 — Application Mgmt** (0%) | NOT STARTED | Need: Application form, fee challan, document verification, interview scheduling. 9 sub-tasks. |
| **C3 — Admission Mgmt** (0%) | NOT STARTED | Need: Offer letter generation, admission fee, enrollment, student ID card. 8 sub-tasks. |
| C4 — Student Profile (87%) | DONE | Minor: Document verification status update workflow missing. |
| **C5 — Promotion & Alumni** (0%) | NOT STARTED | Need: Promotion criteria engine, bulk class assignment, TC generation, alumni tracking. 8 sub-tasks. |
| C6 — Syllabus (87%) | DONE | Minor: Syllabus progress tracking vs timeline + lag alerts missing. |
| **C7 — Behavior Assessment** (0%) | NOT STARTED | Need: Behavior module (prefix `beh_`): incident recording, severity levels, corrective actions, parent meeting scheduling, behavior reports, pattern analysis. 6 sub-tasks. |

### Module F — Attendance Management (20% done, 27 sub-tasks pending)

| Sub-Module | Status | Gap Details |
|-----------|--------|------------|
| F1 — Student Daily (40%) | PARTIAL | Missing: Bulk CSV upload, correction request workflow, admin approval with audit. |
| **F2 — Period/Subject** (0%) | NOT STARTED | Need: Period-wise attendance marking per subject, auto-fill, sync with daily. |
| **F3 — Attendance Analytics** (0%) | NOT STARTED | Need: Reports (daily/monthly/term), absentee pattern detection, absence streak alerts, SMS/email alerts to parents. |
| F4 — Staff Attendance (25%) | PARTIAL | Have: LeaveConfig. Missing: Biometric sync, anomaly detection, check-in/out recording. |
| **F5 — Staff Analytics** (0%) | NOT STARTED | Need: Daily staff report, department stats, late/early alerts. |

### Module I — Examination & Gradebook (25% done, 34 sub-tasks pending)

| Sub-Module | Status | Gap Details |
|-----------|--------|------------|
| I1 — Exam Structure (83%) | MOSTLY DONE | Minor: grade calculation formula setup missing. |
| **I2 — Exam Timetable** (0%) | NOT STARTED | Need: Exam slot assignment, room/invigilator allocation, student clash detection. |
| **I3 — Marks Entry** (0%) | NOT STARTED | Need: Per-student marks entry UI, grade-only mode, bulk Excel upload, marks verification. |
| **I4 — Moderation** (0%) | NOT STARTED | Need: Borderline review, moderation approval workflow. |
| **I5 — Gradebook** (0%) | NOT STARTED | Need: Grade formula engine, GPA/CGPA calculation, absent/grace marks handling. |
| **I6 — Report Cards** (0%) | NOT STARTED | Need: PDF report card generation, school branding, bilingual support, publishing to parent portal. |
| **I7 — Promotion Rules** (0%) | NOT STARTED | Need: Promotion criteria, detention workflow, parent notification. |
| **I8 — Board Patterns** (0%) | NOT STARTED | Need: CBSE/ICSE/IB/Cambridge report templates, subject-board mapping. |
| **I9 — Custom Report Designer** (0%) | NOT STARTED | Need: Drag-drop template designer, version management. |
| **I10 — AI Analytics** (0%) | NOT STARTED | Need: Skill gap identification, performance risk prediction. |

### Module P — HR & Staff Management (12% done, 41 sub-tasks pending)

| Sub-Module | Status | Gap Details |
|-----------|--------|------------|
| P1 — Staff Master (55%) | PARTIAL | Have: Teacher/Employee profile CRUD. Missing: Document renewal tracking, employment contract management. |
| P2 — Attendance & Leave (28%) | PARTIAL | Have: Leave config. Missing: Leave application workflow, biometric sync, auto-mark. |
| **P3 — Payroll** (0%) | NOT STARTED | Need: Salary structure, CTC breakdown, monthly payroll generation, LOP calculation, ad-hoc adjustments. 8 sub-tasks. |
| **P4 — Compliance** (0%) | NOT STARTED | Need: PF/ESI setup, statutory reports. |
| **P5 — Performance Appraisal** (0%) | NOT STARTED | Need: KPI templates, appraisal cycles, self-assessment, manager review. |
| **P6 — Training** (0%) | NOT STARTED | Need: Training programs, enrollment, feedback collection. |
| **P7 — HR Reports** (0%) | NOT STARTED | Need: Staff register, department strength, attrition analysis. |

### Module S — LMS (30% done, 37 sub-tasks pending)

| Sub-Module | Status | Gap Details |
|-----------|--------|------------|
| **S1 — Course Mgmt** (0%) | NOT STARTED | Need: Course CRUD, unit/lesson structure, publishing. No course-based LMS architecture. |
| S2 — Content (50%) | PARTIAL | SyllabusBooks exists. Missing: Drag-drop ordering, content-to-lesson assignment. |
| S3 — Assessments (50%) | PARTIAL | Quiz CRUD works. Missing: Student-facing quiz taking, auto-grading, assignment grading. |
| S4 — Question Bank (100%) | DONE | QuestionBank module fully functional. |
| **S5 — Progress Tracking** (0%) | NOT STARTED | Need: Lesson completion tracking, time spent, performance analytics. |
| **S6 — LMS Certificates** (0%) | NOT STARTED | Need: Course completion criteria, certificate auto-generation. |
| **S7 — LMS Reports** (0%) | NOT STARTED | Need: Course completion reports, participation analytics. |
| S8 — Adaptive Learning (33%) | PARTIAL | Recommendation module exists but buggy (~65%). Missing: ML-based suggestions. |
| S9 — Competency Assessment (25%) | PARTIAL | HPC has rubric-style assessment. Missing: Evidence submission, peer evaluation. |
| **S10 — Digital Badges** (0%) | NOT STARTED | Need: Badge design, auto-issuance, Open Badges export. |
| **S11 — Offline Content** (0%) | NOT STARTED | Need: Offline download, encrypted storage, auto-sync. |

### Module Z — Parent Portal & Mobile App (8% done, 22 sub-tasks pending)

| Sub-Module | Status | Gap Details |
|-----------|--------|------------|
| Z1 — Dashboard (25%) | PARTIAL | Have: StudentPortalController. Missing: Child overview, academic snapshot, fee dues. |
| Z2 — Notifications (25%) | PARTIAL | NotificationController exists. Missing: Preference config, quiet hours, reliable push. |
| **Z3 — Teacher Messaging** (0%) | NOT STARTED | Need: Parent→teacher messaging, file attachments, message history/search. |
| **Z4 — Fee Management** (0%) | NOT STARTED | Need: Online fee payment, payment history, receipt download. |
| **Z5 — Events & Volunteer** (0%) | NOT STARTED | Need: Event calendar, RSVP, volunteer sign-up. |
| **Z6 — Document Vault** (0%) | NOT STARTED | Need: Report card/certificate download, official copy requests. |

### Module M — Library (30% done, code built but NOT wired)

**CRITICAL BLOCKER:** 26 controllers, 35 models, 9 services, 140 views, 36 migrations all exist BUT the module is NOT registered in `tenant.php`. All Library features are completely inaccessible.

| Gap | Priority |
|-----|---------|
| Wire all Library routes into `tenant.php` with tenancy middleware | P0 |
| Add `Gate::authorize()` to 7 controllers with zero auth | P0 |
| Fix `Modules\Prime\Models\Setting` cross-layer import | P1 |
| Fix N+1 in LibReservationController | P2 |
| Add LibraryReportController proper auth and implementation | P2 |

---

## CATEGORY 3 — Modules Functional but Incomplete (50-80%)

### Module G — SmartTimetable (45% done, 26 sub-tasks pending)

**Full gap analysis:** See `6-Module-In-Progress/8-Smart_Timetable/Claude_Context/2026Mar14_GapAnalysis_Updated_v2.md`
**Development plan:** See `6-Module-In-Progress/8-Smart_Timetable/Claude_Context/2026Mar14_DevelopmentPlan_v2.md`
**Execution prompts:** 21 prompt files in `6-Module-In-Progress/8-Smart_Timetable/Claude_Prompt/`

| Key Gap Area | RBS Mapping | Effort |
|-------------|------------|--------|
| Manual Editing (G6) — drag-drop, swap, lock | F.G6.1, F.G6.2 | 4 days |
| Substitution (G7) — absence, auto-suggest | F.G7.1, F.G7.2 | 5 days |
| Publishing (G8) — PDF export, ICS calendar | F.G8.1, F.G8.2 | 3 days |
| Analytics (G9) — workload, utilization, AI | F.G9.1, F.G9.2 | 5 days |
| Room Allocation — room_id always NULL | F.G3.2 | 3 days |
| Constraint Engine — 125+ rules missing | F.G4.1, F.G4.2 | 31 days |
| Security — 17/28 controllers zero auth | Cross-cutting | 3 days |
| 6 runtime crash bugs | Cross-cutting | 0.5 day |

### Module J — Fees & Finance (35% done, 37 sub-tasks pending)

| Key Gap Area | RBS Mapping | Impact |
|-------------|------------|--------|
| Fee Reports & Analytics (J8) — 0% | F.J8.1, F.J8.2 | No fee collection summaries or outstanding reports |
| Dynamic Fee Engine (J10) — 0% | F.J10.1 | No rule-based fee calculation |
| Scholarship workflow (J9) — 25% | F.J9.1, F.J9.2 | Application form, review committee, disbursement absent |
| Outstanding & Dues (J7) — 25% | F.J7.1 | No auto-reminders or escalation |
| FeeConcessionController doesn't exist (BUG-FEE-001) | F.J4.1 | Fatal on route:cache |
| Seeder route exposed in prod (SEC-FEE-001) | Security | Data corruption risk |
| Payment webhook broken (SEC-004) | F.J3.2 | Razorpay payments never confirm |

### Module V — SaaS Billing (50% done, 27 sub-tasks pending)

| Key Gap Area | RBS Mapping | Impact |
|-------------|------------|--------|
| Metering & Usage (V4) — 0% | F.V4.1, F.V4.2 | No API/storage usage tracking |
| Multi-currency (V5) — 0% | F.V5.2 | Single currency only |
| Tenant Self-Service Portal (V6) — 25% | F.V6.1, F.V6.2 | Tenants can't pay online or download invoices |
| GST/Tax compliance (V7) — 33% | F.V7.2 | No GST return preparation |
| Auto-reconciliation — 0% | F.V3.2 | Manual payment matching only |

### Module H — Academics (40% done, 32 sub-tasks pending)

| Key Gap Area | RBS Mapping | Impact |
|-------------|------------|--------|
| Academic Calendar (H4) — 0% | F.H4.1, F.H4.2 | No event management or holiday calendar |
| Co-Curricular Activities (H7) — 0% | F.H7.1, F.H7.2 | No sports/club/competition tracking |
| Teacher Workload Distribution (H5) — 50% | F.H5.1, F.H5.2 | Calculation exists but redistribution absent |
| Homework evaluation (H3) — 44% | F.H3.2 | Fatal crash bug, no auth on review, grading incomplete |
| Skill/Competency Framework (H6) — 37% | F.H6.1, F.H6.2 | HPC module has partial implementation |

---

## CATEGORY 4 — Cross-Cutting Gaps (Affect Multiple Modules)

### Security Gaps

| Issue | Modules Affected | RBS Impact |
|-------|-----------------|------------|
| Missing `EnsureTenantHasModule` middleware | SmartTimetable, LmsExam, LmsHomework, LmsQuiz, LmsQuests, Hpc, StudentFee, Recommendation | Unpaid tenants access all features |
| Zero auth on controllers | SmartTimetable (17), Library (7), StudentFee (8 views), Hpc (13 methods) | Any user can perform any action |
| `dd($e)` in production code | LmsExam | Stack trace exposure |
| `$request->all()` in logs | SmartTimetable, ClassSubjectSubgroup | Sensitive data in logs |
| `is_super_admin` in $fillable | User model | Privilege escalation |

### Performance Gaps

| Issue | Modules Affected | Impact |
|-------|-----------------|--------|
| Zero application-level caching | All controllers | 16+ DB queries per request |
| `::all()` unbounded queries | SmartTimetable, Library, LmsExam | Memory pressure on large datasets |
| N+1 query patterns | Library, StudentFee, SmartTimetable | 500+ queries for bulk operations |
| Per-row updateOrCreate in loops | SmartTimetable (Activity, TeacherAvailability) | 500+ individual queries |

### Infrastructure Gaps

| Issue | RBS Reference | Impact |
|-------|--------------|--------|
| No Redis queue driver | Module SYS | DB queue limits concurrency |
| No background job for timetable generation | Module G, G5 | Blocks HTTP request for minutes |
| No system health monitoring | Module SYS1 | No alerting for production issues |
| No bulk import/export wizards | Module SYS3 | School onboarding is manual |

---

## Priority-Ordered Recommendations

### Phase 1 — Fix What's Broken (Weeks 1-2)

1. Fix all security gaps (EnsureTenantHasModule, Gate::authorize on all controllers)
2. Fix runtime crash bugs (SmartTimetable 6 bugs, LmsHomework fatal, LmsExam dd())
3. Wire Library module into tenant.php
4. Fix Razorpay webhook (SEC-004)

### Phase 2 — Complete Core Modules (Weeks 3-8)

1. SmartTimetable → Execute P01-P08 prompts (bugs, security, constraints, performance, rooms)
2. StudentFee → Fix missing controller, seeder route, permission mismatch
3. LMS modules → Uncomment Gate calls, add student-facing features
4. Examination → Marks entry, Gradebook, Report Cards (I3-I6)

### Phase 3 — Build Missing Core Modules (Weeks 9-16)

1. **Admission Enquiry** (C1-C3) — Critical for new academic year
2. **HR & Payroll** (P3-P7) — Required for staff management
3. **Attendance Management** (F2-F5) — Period-wise + analytics
4. **Academic Calendar** (H4) — Events, holidays
5. **Certificate Management** (R1-R7) — TC generation, ID cards

### Phase 4 — Build Enhancement Modules (Weeks 17-30)

1. Finance & Accounting (K) — Double-entry, GST compliance
2. Inventory (L) — Stock management
3. Hostel (O) — Room allocation, mess
4. Parent Portal (Z) — Mobile app integration
5. SmartTimetable Phases P09-P21 — Full constraint system + analytics

### Phase 5 — Build AI/Advanced Modules (Weeks 31-40+)

1. LXP (T) — Personalized learning paths
2. Predictive Analytics (U) — ML models
3. Cafeteria (W), Visitor (X), Helpdesk (Y) — Operations

---

## Module Development Effort Estimates

| Module | Sub-Tasks Pending | Estimated Effort (dev-days) |
|--------|-------------------|----------------------------|
| K — Accounting | 70 | 80-100 |
| L — Inventory | 50 | 50-60 |
| R — Certificates | 52 | 40-50 |
| T — LXP | 47 | 60-80 |
| U — Analytics/ML | 51 | 80-100 |
| O — Hostel | 36 | 30-40 |
| G — Timetable (remaining) | 26 | 69 (detailed plan exists) |
| P — HR & Staff | 41 | 50-60 |
| I — Exam & Gradebook | 34 | 40-50 |
| C — Admissions | 42 | 35-45 |
| S — LMS | 37 | 40-50 |
| F — Attendance | 27 | 25-30 |
| J — Fees (remaining) | 37 | 30-40 |
| Z — Parent Portal | 22 | 25-30 |
| Others (D, Q, H, M fixes) | ~50 | 40-50 |
| **Total** | **~762** | **~700-850 dev-days** |
