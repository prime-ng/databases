# Development Progress Tracker

## Completed Modules (100%)

### Core Platform
- [x] **Prime** — Tenant management, plans, billing, users, roles, modules, menus, geography
- [x] **GlobalMaster** — Countries, states, cities, boards, languages, plans, dropdowns
- [x] **SystemConfig** — Settings, menus, translations
- [ ] **Billing** (~55%) — PRIME module (prime_db). 7 controllers, 43 views. 7 P0 critical: silent auth bypass (duplicate policy registrations), audit log FK mismatch, open DB transactions, 9 unauth'd methods. 0 services, 0 migrations. Knowledge: `AI_Brain/module-knowledge/BIL_Billing.md`
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

## In Progress / Code Scaffold Present (features incomplete)

- [ ] **BehaviouralAssessment** (~50–55%) — 12 ctrl, 16 models, 1 service (BehaviouralScoreService only), 5 FormRequests, 17 policies, 65 views. 0 tests (critical — immutable audit log + CBSE CCE compliance). ComputeSchoolScoresJob missing. 3 FormRequests missing (Assessment, Incident, ClassCategory). Knowledge: `AI_Brain/module-knowledge/BHA_BehaviouralAssessment.md`
- [ ] **Accounting** (~60–70%) — 21 ctrl, 25 models, **7 services** (corrected from 10), 17 FormRequests, 19 policies, 141 views, 220 route lines. 28 tables (DDL v3, 6 domains). Generic event engine (4 tables D6) confirmed implemented: ModuleEventController + EventVoucherConfigController + RemoteEntryService (not in V2 req). FAC7/FAC8/FAC10 (GST/TDS/YearEnd) not built — also absent from DDL v3. 0 migrations. Old module code was FAC. Knowledge: `AI_Brain/module-knowledge/ACC_Accounting.md`
- [ ] **HrStaff** — 22 ctrl, 15 services. PF/ESI/TDS, leave FSM, payroll integration
- [ ] **Inventory** (~55–65%) — 20 ctrl, 28 models, **14 services** (corrected from 7 proposed; includes StockLedgerService + StockValuationService not in V2 req), 18 FormRequests, 16 policies, 77 views, 221 route lines, 35 seeders (incl. 5 cross-module ACC/VND placeholders). 4 of 8 domain events implemented. 0 Listeners. 1 Job (ReorderAlertJob), 1 Artisan command (MaintenanceOverdue). 0 tests (critical — SELECT...FOR UPDATE on stock_balances). 0 migrations. FK constraints for ACC/VND/SCH commented out in DDL. Knowledge: `AI_Brain/module-knowledge/INV_Inventory.md`
- [ ] **Hostel** (~70–75%) — **53 ctrl** (proposed 20), **41 models** (proposed 20; modules-map 44 — 3 unresolved), **22 services** (proposed 7; 15 are report services), **38 FormRequests**, **20 policies** (in module's own Policies/), **278 views**, 573 route lines, 41 migrations deployed, 7 events, 2 jobs, 1 Artisan command (hst:escalate-complaints), 1 middleware (WardenScopeMiddleware ✓). 0 tests (critical). Gaps: 0 Listeners, BedType+HstBedType duplicate models, duplicate controller names. FRD not yet generated. Knowledge: `AI_Brain/module-knowledge/HST_Hostel.md`
- [ ] **Cafeteria** (~60–65%) — 16 ctrl, 21 models, 6 services, 19 FormRequests, 14 policies, 95 views. POS + FSSAI + meal cards + subscriptions scaffolded. 1 test file only (critical — concurrency/cutoff untest'd). 0 jobs (NTF dispatch, FSSAI expiry alerts all unqueued). 0 migrations. Knowledge: `AI_Brain/module-knowledge/CAF_Cafeteria.md`
- [ ] **Certificate** (~55–60%) — 10 ctrl, 10 models, 3 services, 10 FormRequests, 7 policies, 39 views, 4 seeders, 1 job. HMAC-SHA256 QR verification, SELECT...FOR UPDATE serial counters, DomPDF. 0 tests (30 proposed — critical). DmsService never created (P0). 2 DDL gaps (crt_verification_logs, crt_id_card_issued). std_students.tc_issued ALTER needed. Knowledge: `AI_Brain/module-knowledge/CRT_Certificate.md`
- [ ] **FrontOffice** (~55–65%) — 21 ctrl, 22 models, **4 services** (corrected from 6; FeedbackService + CertificateIssuanceService missing), 10 FormRequests, **13 policies** (corrected from 4 proposed — 3× undercount), 118 views, 302 route lines. 1 test (AppointmentControllerTest). 1 Job (EarlyDepartureAttSyncJob — queued). `fof:flag-overstay` Artisan command NOT found. 0 Events, 0 migrations. Knowledge: `AI_Brain/module-knowledge/FOF_FrontOffice.md`
- [ ] **Admission** (~60–65%) — 18 ctrl, 20 models, 6 services, 24 FormRequests, 13 policies, 84 views. Full pipeline scaffolded (enquiry→application→shortlist→enroll→promotion→TC). 0 tests (critical), PromoteExpiredOffersJob missing, 0 migrations. Knowledge: `AI_Brain/module-knowledge/ADM_Admission.md`
- [ ] **ParentPortal** — 28 ctrl, ~5% done. OTP login, multi-child context
- [ ] **Library** — Book circulation, fines, reservations (39 ctrl, 12 services — features pending)
- [ ] **StudentPortal** — ~55% (see student-parent-portal.md)

## Not Yet Started (no code scaffold)

- [ ] **Communication** — DLT-compliant SMS, 7-state delivery FSM
- [ ] **LearningExperience** — Personalized paths, gamification
- [ ] **PredictiveAnalytics** — Dropout/fee/attendance prediction, PAN→REC pipeline
- [ ] **VisitorSecurity** — Gate security, contractor access, lockdown mode
- [ ] **Maintenance** — Ticketed facility helpdesk + PM + AMC contracts
- [ ] **Attendance** — Full attendance module (supersedes STD's zero-auth AttendanceController)
- [ ] **Academics** — Lesson plans, teaching diary, academic alerts
- [ ] **Examination** — Offline exams, mark entry, report cards (distinct from LmsExam)

## Current Work
- Template Output Configuration — DDL schema complete, migration pending (Branch: Brijesh, 2026-04-16)
- MarksheetGeneration — DDL schema complete (MSG_DDL_v1.sql, 23 tables), code pending (Branch: Brijesh, 2026-04-13)
- StudentPortal — StudentAttempt DDL schema (Branch: Brijesh, 2026-04-02)
- HPC module enhancements (Branch: Brijesh_HPC, Developer: Shailesh)

## Recently Completed
- [x] **Template Output Configuration DDL** (2026-04-16) — `Template_Config_DDL_v1.sql`: 2 new tables (`tmp_template_purposes`, `tmp_template_assignments`) + dependency on existing `tmp_templates`. Scope-based assignment (class/class-group/school-wide) with generated `scope_hash` uniqueness. 7 seeded purposes. Cross-module FK to `msh_class_groups` (D-TMP-001). Decisions D-TMP-001 through D-TMP-004 documented.
- [x] **MarksheetGeneration DDL** (2026-04-13) — `MSG_DDL_v1.sql`: 23 tables (3 master, 10 config, 2 schedule, 7 result, 1 audit). Full data dictionary in `MSG_DataDictionary.md`. Decisions D-MSG-001 through D-MSG-007.
- [x] **HPC: Queued Email Report to Guardians** (2026-03-16) — `SendHpcReportEmail` Job, `HpcReportMail` Mailable, email button + AJAX on student-list, `POST /hpc/send-report-email` route. Job re-initializes tenancy, generates PDF via DomPDF, emails all guardians with PDF attachment. 3 retries, 300s timeout, `emails` queue.
- [x] **HPC: CRUD Data Auto-Mapping into PDFs** (2026-03-16) — `HpcPdfDataService` fetches 10 CRUD modules (evaluations, coverage, goals, outcomes, activities, parameters, descriptors, question mappings, knowledge graph, topic equivalencies). Data passed as `$hpcData` to all 4 PDF templates. Shared `_crud_sections.blade.php` partial renders tables/bars after existing form sections. Refactored `generateReportPdf()` and `generateSingleStudentPdf()` to use `$viewMap`/`$viewData` pattern.
