# Development Progress Tracker

## Completed Modules (100%)

### Core Platform
- [x] **Prime** — Tenant management, plans, billing, users, roles, modules, menus, geography
- [x] **GlobalMaster** — Countries, states, cities, boards, languages, plans, dropdowns
- [x] **SystemConfig** — Settings, menus, translations
- [x] **Billing** — Invoice generation, payment tracking, billing cycles
- [x] **Dashboard** — Admin dashboards
- [x] **Documentation** — Knowledge base, help docs

### School Administration
- [x] **SchoolSetup** — Classes, sections, subjects, teachers, rooms, buildings, departments, designations
- [x] **StudentProfile** — Student data, health profiles, documents, attendance, guardians
- [x] **Transport** — Vehicles, routes, trips, driver attendance, student boarding, fees, maintenance
- [x] **Vendor** — Vendor management, agreements, items, invoices, payments
- [x] **Complaint** — Categories, SLA, actions, AI insights, medical checks
- [x] **Notification** — Multi-channel notifications, templates, delivery logs
- [x] **Payment** — Razorpay integration, payment processing
- [x] **Scheduler** — Job scheduling

### Academic & Curriculum
- [x] **Syllabus** — Lessons, topics, competencies, Bloom taxonomy, cognitive skills
- [x] **SyllabusBooks** — Textbooks, authors, topic mappings
- [x] **QuestionBank** — Questions, tags, versions, statistics, AI generation

### Timetable
- [x] **SmartTimetable** — All 10 stages complete:
  - Stage 1: Schema & Foundation (28 table renames, 47 models)
  - Stage 2: Seeders (9 config seeders)
  - Stage 3: Validation Framework
  - Stage 4: Activity & Generation Updates (v7.6 column renames)
  - Stage 5: Advanced Generation (TabuSearch, SimulatedAnnealing, ConflictDetection)
  - Stage 6: Post-Generation Analytics (AnalyticsService, CSV exports)
  - Stage 7: Manual Refinement (RefinementService, swap/move/lock)
  - Stage 8: Substitution Management (SubstitutionService, pattern learning)
  - Stage 9: API & Integration (REST API, Standard Timetable views)
  - Stage 10: Testing & Cleanup (Form Requests, Pest tests)

## Near Complete (60-95%)

- [ ] **Hpc** (~78%) — Holistic Progress Card (updated 2026-03-21). 22 controllers, 32 models, 10 services, 14 FormRequests, 1 Trait, 55 tests. PDF blade pages 1+2 redesigned for all 4 templates. Seeder page1 fixed for T2/T3/T4. SendHpcReportEmail rewritten (link-based, no PDF attachment). Hybrid bg-image for decorative pages. PDF: 95% (was 90%). Seeder: 100%. Remaining: god controller refactor, 8 blueprint screens, hybrid page pixel fine-tuning.
- [ ] **LmsExam** (~90%, updated 2026-03-20) — Full flow: Blueprint → PaperSet → PaperSetQuestion → ExamAllocation. Student grading absent.
- [ ] **LmsQuiz** (~90%, updated 2026-03-20) — Full CRUD with difficulty engine. Student attempt tracking absent.
- [ ] **LmsHomework** (~80%, updated 2026-03-20) — CRUD done. Critical: no HomeworkPolicy, `review()` no auth.
- [ ] **LmsQuests** (~85%, updated 2026-03-20) — Full CRUD with `canPublish()` guards. Student progress tracking absent.
- [ ] **Syllabus** (~100% CRUD, updated 2026-03-20) — Full entity set. Critical schema facts documented.
- [ ] **QuestionBank** (~85%, updated 2026-03-20) — Full CRUD. API keys hardcoded — REVOKE NOW.
- [ ] **StudentFee** (~60%) — Fee management (missing controller, exposed seeder, permission mismatch)
- [ ] **Recommendation** (~65%) — Wrong permissions, empty stubs, broken validation

## In Progress

- [ ] **StudentPortal** (~55%, updated 2026-04-02) — 35 screens (22 ✅ | 8 🟡 | 5 ❌), 7 controllers, 55+ routes, 57 blade views. Dashboard fully live. Key gaps: Online Exam/Quiz/Quest player screens (FR-STP-30, stubs only), IDOR in proceedPayment(), zero Gate::authorize(). StudentAttempt DDL v2 created (10 tables). Full architecture in `student-parent-portal.md`. Requirement: `databases/2-Requirement_Module_wise/2-Detailed_Requirements/V2/STP_StudentPortal_Requirement.md`
- [ ] **ParentPortal** (~5%) — 23 screens designed (P1-P23), none wired yet. Architecture in `student-parent-portal.md`
- [ ] **Standard Timetable** (~70%) — Standard views and scheduling
- [ ] **Event Engine** (~20%) — Cross-module event system

## Pending Modules

- [ ] **Behavioral Assessment** — Student behavior tracking and analysis
- [ ] **Analytical Reports** — Cross-module analytics and reporting
- [ ] **Student/Parent Portal** — Student and parent facing portal
- [ ] **Accounting** — Double-entry bookkeeping, financial reports
- [ ] **HR & Payroll** — Staff payroll, leave management
- [ ] **Inventory Management** — School inventory tracking
- [ ] **Hostel Management** — Hostel rooms, allocation, fees
- [ ] **Mess/Canteen** — Meal planning, attendance, billing
- [ ] **Admission Enquiry** — Online admission process
- [ ] **Visitor Management** — Visitor registration, tracking
- [ ] **FrontDesk** — Reception management
- [ ] **Template & Certificate** — Dynamic certificate generation
- [ ] **Help Desk** — Support ticket system
- [ ] **Library** — Book circulation, fines (module exists, features pending)

## Current Work
- StudentPortal — StudentAttempt DDL schema (Branch: Brijesh, 2026-04-02)
- HPC module enhancements (Branch: Brijesh_HPC, Developer: Shailesh)

## Recently Completed
- [x] **HPC: Queued Email Report to Guardians** (2026-03-16) — `SendHpcReportEmail` Job, `HpcReportMail` Mailable, email button + AJAX on student-list, `POST /hpc/send-report-email` route. Job re-initializes tenancy, generates PDF via DomPDF, emails all guardians with PDF attachment. 3 retries, 300s timeout, `emails` queue.
- [x] **HPC: CRUD Data Auto-Mapping into PDFs** (2026-03-16) — `HpcPdfDataService` fetches 10 CRUD modules (evaluations, coverage, goals, outcomes, activities, parameters, descriptors, question mappings, knowledge graph, topic equivalencies). Data passed as `$hpcData` to all 4 PDF templates. Shared `_crud_sections.blade.php` partial renders tables/bars after existing form sections. Refactored `generateReportPdf()` and `generateSingleStudentPdf()` to use `$viewMap`/`$viewData` pattern.
