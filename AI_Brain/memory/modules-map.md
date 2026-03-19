# Modules Map — nwidart/laravel-modules v12.0

## Module Management Commands
```bash
# Create new module
php artisan module:make ModuleName

# Enable/disable
php artisan module:enable ModuleName
php artisan module:disable ModuleName

# Generate components
php artisan module:make-controller ControllerName ModuleName
php artisan module:make-model ModelName ModuleName
php artisan module:make-migration migration_name ModuleName
php artisan module:make-seeder SeederName ModuleName
php artisan module:make-request RequestName ModuleName
php artisan module:make-resource ResourceName ModuleName
php artisan module:make-policy PolicyName ModuleName
php artisan module:make-provider ProviderName ModuleName
php artisan module:make-middleware MiddlewareName ModuleName

# Run module migrations
php artisan module:migrate ModuleName
php artisan module:migrate-rollback ModuleName

# Seed
php artisan module:seed ModuleName
```

## Module Autoloading
- PSR-4 autoloading via each module's `composer.json`
- Service providers registered in `module.json`
- Each module has: `ModuleServiceProvider`, `RouteServiceProvider`, `EventServiceProvider`

## Standard Module Folder Structure
```
Modules/ModuleName/
├── app/
│   ├── Exceptions/
│   ├── Http/
│   │   ├── Controllers/
│   │   ├── Requests/
│   │   └── Middleware/
│   ├── Models/
│   ├── Services/
│   ├── Jobs/
│   ├── Providers/
│   │   ├── ModuleNameServiceProvider.php
│   │   ├── RouteServiceProvider.php
│   │   └── EventServiceProvider.php
│   └── Emails/
├── database/
│   ├── migrations/
│   └── seeders/
├── resources/
│   └── views/
├── routes/
│   ├── api.php
│   └── web.php
├── tests/
├── config/
├── composer.json
├── module.json
└── vite.config.js
```

## All Modules (27)
> **Audited:** 2026-03-15 (re-audited against `prime_ai_shailesh` / branch `Brijesh_HPC`).
> Previous audit: 2026-03-14 against `prime_ai_tarun` / branch `Tarun_SmartTimetable`.
> Controllers exclude backup files (`*_YYYY*.php`, `*_backup*.php`) and misplaced non-PHP files.
> Services count = unique .php files under `app/Services/` (deduplicated).

### Central-Scoped Modules (run on central domain, access prime_db/global_db)
| Module | Controllers | Models | Services | Requests | Route refs (web.php) | Description |
|--------|-------------|--------|----------|----------|----------------------|-------------|
| **Prime** | 22 | 27 | 1 | 7 | 20 (central) | Tenant CRUD, plans, billing, users, roles, modules, menus, geography |
| **GlobalMaster** | 15 | 12 | 0 | 10 | 8 (central) | Countries, states, cities, boards, languages, plans, dropdowns |
| **SystemConfig** | 3 | 3 | 0 | 1 | 0 (via Prime) | Settings, menus, translations |
| **Billing** | 6 | 6 | 0 | 3 | 5 (central) | Invoice generation, payment tracking, billing cycles |
| **Documentation** | 3 | 2 | 0 | 2 | 3 (central) | Knowledge base, help docs |

### Tenant-Scoped Modules (run on tenant domain, access tenant_db)
| Module | Controllers | Models | Services | Requests | Tenant route refs | Status | Description |
|--------|-------------|--------|----------|----------|-------------------|--------|-------------|
| **SchoolSetup** | 34 | 42 | 0 | 27 | 46 | **~80%** | 5 stub controllers; is_super_admin settable; PHP concat crash; assignSubjects route broken; 15+ unprotected methods; inconsistent permission naming (19 SEC, 13 BUG) |
| **SmartTimetable** | 31 | 86 | 25 | 12 | 42+ | **~72%** | AI timetable: FET solver, full constraint architecture (22 Hard + 55+ Soft classes, 212 seeded types, Registry+Evaluator+Context). New: AnalyticsController+Service, RefinementController+Service, SubstitutionController+Service, TimetableApiController (6 REST), GenerateTimetableJob, SmartTimetableServiceProvider, RoomChangeTrackingService. 40+ models now have SoftDeletes. All 21 prompts (P01–P21) done. **But:** 12 new bugs found (BUG-TT-001–012), 3 security issues (SEC-TT-001–003), 3 perf issues. FETConstraintBridge context broken, gap calcs wrong, SubstitutionService crashes, inter-activity silently passes. Structure ~90% but runtime correctness needs bug-fix pass. |
| **Transport** | 31 | 36 | 0 | 18 | 36 | **~82%** | 5 controllers zero auth; AttendanceDevice `tested.*` typo; undefined $request crash; double-delete race; 5 stub controllers (22 SEC, 10 BUG) |
| **StudentProfile** | 5 | 14 | 0 | 0 | 45 | **~80%** | is_super_admin writable from student login; AttendanceController zero auth; StudentProfileController empty stub |
| **Syllabus** | 15 | 22 | 0 | 14 | 41 | **~78%** | CompetencieController + TopicController zero auth; SyllabusController empty stub; $request->all() mass assignment |
| **SyllabusBooks** | 4 | 6 | 0 | 3 | 4 | **~65%** | SyllabusBooksController empty stub; BookTopicMappingController zero auth; undefined var crash; central AcademicSession cross-layer |
| **QuestionBank** | 7 | 17 | 0 | 6 | 17 | **~75%** | **API KEYS HARDCODED**; AIQuestionGenerator zero auth; generateQuestions() always returns demo data |
| **Notification** | 12 | 14 | 2 | 10 | 63 | **~55%** | ALL routes commented out (inaccessible); stub target types; 7 controllers duplicate index queries |
| **Complaint** | 8 | 6 | 2 | 0 | 58 | **~70%** | dd() in store catch + filter; 3 stub controllers; show/edit/store/update no auth |
| **Vendor** | 7 | 8 | 0 | 3 | 58 | **~60%** | 6/7 controllers NOT registered in routes; VendorInvoiceController zero auth on 14 financial methods |
| **Payment** | 4 | 5 | 2 | 0 | 26 | **~45%** | Razorpay keys hardcoded; 2 stub controllers; webhook behind auth; PaymentController copy.php collision |
| **Dashboard** | 1 | 0 | 0 | 0 | 1 | 100% | Admin dashboards |
| **Scheduler** | 1 | 2 | 2 | 1 | 0* | 100% | Job scheduling (*uses module-level routing, not tenant.php) |
| **LmsQuiz** | 5 | 6 | 0 | 5 | 23 | **~72%** | Quiz CRUD works; Gate commented out in index; student attempt tracking absent |
| **LmsQuests** | 4 | 4 | 0 | 4 | 4 | **~68%** | Quest CRUD works; Gate commented out in index; progress tracking absent |
| **Recommendation** | 10 | 11 | 0 | 0 | 40 | **~65%** | 3 empty stubs; wrong perms 8/9 routes; broken validation; no FormRequests |
| **LmsExam** | 11 | 11 | 0 | 11 | 59 | **~65%** | dd($e) in prod; 2 controllers Gate disabled; no EnsureTenantHasModule |
| **StudentFee** | 15 | 23 | 0 | 0 | 29 | **~60%** | Missing controller; seeder route exposed; perm prefix mismatch; no FormRequests |
| **LmsHomework** | 5 | 5 | 0 | 5 | 16 | **~60%** | Fatal crash missing $request param; review() no auth; no EnsureTenantHasModule |
| **Hpc** | 22 | 32 | 10 | 14 | 133 | **~75%** | HpcController ~2483 lines. 4 PDF templates (138 pages total) + ZIP + queued email. 10 CRUD resource controllers + 6 new feature controllers (Student/Parent/Peer portals, Attendance, ActivityAssessment, CreditConfig, Goals). 1 Trait (HpcIndexDataTrait). Template structure 100%, web form 90%, PDF gen 90%, CRUD admin 85%, Email/ZIP 95%, Auth 95%, Role-based locking done, Approval workflow done, Student portal done, Parent portal done, Peer workflow done, Credit calculator done, Tests 55. **Remaining:** God controller still 2483 lines (partial refactor done), 12/20 blueprint screens done (was 4/20). |
| **Library** | 26 | 35 | 9 | 19 | 0† | **~45%** | NOT in tenant.php; 7 controllers zero auth; 5 stubs; cross-layer import (†see below) |
| **StudentPortal** | 3 | 0 | 0 | 0 | 3 | ~25% | Student-facing interface (dashboard, complaints, notifications only) |

### Key Module Routes

| Module | Route Prefix | Key Endpoints |
|--------|-------------|---------------|
| Prime (Central) | `/prime/*` | tenants, users, roles, billing, boards, academic-sessions, dropdowns |
| GlobalMaster (Central) | `/global-master/*` | countries, states, cities, boards, languages, modules, plans |
| Billing (Central) | `/billing/*` | billing-management, subscription, invoicing-payment, billing-cycle |
| SchoolSetup | `/school-setup/*` | organization, class, section, subject, teacher, room, building, department, designation |
| SmartTimetable | `/smart-timetable/*` | timetable, activity, period-set, constraint, teacher-availability, school-day, tt-config |
| StudentProfile | `/student/*` | students, attendance, medical-incident, reports |
| StudentFee | `/student-fee/*` | fee-head-master, fee-invoice, fee-receipt, concession, scholarship, fine |
| Transport | `/transport/*` | vehicle, route, trip, driver-helper, pickup-point, student-allocation, vehicle-inspection |
| Syllabus | `/syllabus/*` | lesson, topic, competency, bloom-taxonomy, cognitive-skill, study-material |
| QuestionBank | `/question-bank/*` | questions, tags, statistics, AI generation |
| LmsExam | `/exam/*` | exams, papers, allocations, blueprints |
| LmsQuiz | `/quiz/*` | quizzes, questions, allocations |
| LmsHomework | `/homework/*` | homework, submissions, rules |
| LmsQuests | `/quests/*` | quests, questions, scopes |
| HPC | `/hpc/*` | hpc (index), templates, hpc-form, form/store, generate-report, hpc-view, hpc-single, circular-goals, learning-outcomes, question-mapping, knowledge-graph-validation, topic-equivalency, syllabus-coverage-snapshot, hpc-parameters, hpc-performance-descriptor, student-hpc-evaluation, learning-activities, hpc-templates*, hpc-template-parts*, hpc-template-sections*, hpc-template-rubrics* (*broken — missing imports) |
| Complaint | `/complaint/*` | complaints, categories, actions, sla, dashboard |
| Notification | `/notification/*` | channels, templates, targets, delivery |
| Vendor | `/vendor/*` | vendors, agreements, invoices, payments |
| Payment | `/payment/*` | payment processing, gateway config |
| Recommendation | `/recommendation/*` | rules, materials, student-recommendations |
| StudentPortal | `/student-portal/*` | dashboard, academic-info, payments |
| SystemConfig | `/system-config/*` | settings, menus |

### Module Completion Detail (re-audited 2026-03-15 against `prime_ai_shailesh` branch `Brijesh_HPC`)

| Module | What's Complete | What's Missing / Broken |
|--------|----------------|------------------------|
| SmartTimetable (~72%) | 31 controllers, 86+ models (40+ with SoftDeletes), 25 services. All P01–P21 prompts executed. FET solver with backtracking+greedy+rescue; full constraint architecture (Registry, Evaluator, Context, Factory, 22 Hard + 55+ Soft constraint classes, 212 seeded types); Constraint CRUD (6-tab); Parallel Periods (anchor/sibling+9 tests); AnalyticsController+Service (5 views, CSV); RefinementController+Service (swap/move/lock); SubstitutionController+Service (absence/find/assign); TimetableApiController (6 REST); GenerateTimetableJob; SmartTimetableServiceProvider; RoomChangeTrackingService; API routes with auth:sanctum | **12 new bugs (BUG-TT-001–012):** API zero auth; FETConstraintBridge bare context (all constraints silently pass); gap/span period_id vs index mismatch; SubstitutionService `now()->parse()` crash; no timetable_id scope; Job no tenant context; stale cache; static/instance mismatch; inter-activity checks silently pass; stub/scoping/scoring bugs. **3 security:** no EnsureTenantHasModule; cross-tenant API; stub POST routes. **3 perf:** Teacher::all+N+1; uncached analytics; N+1 teachers.user. **Structure ~90% but runtime correctness needs bug-fix pass.** |
| LmsQuiz (~72%) | CRUD for quizzes, questions, allocations, assessment types, difficulty distribution; Form Requests exist | Gate commented out in index(); student attempt tracking absent; auto-grading absent; no EnsureTenantHasModule |
| LmsQuests (~68%) | CRUD for quests, questions, allocations, scopes; Form Requests exist | Gate commented out in index(); student progress tracking absent; completion awards absent; no EnsureTenantHasModule |
| Recommendation (~65%) | 8 of 10 controllers fully working CRUD with activity logging | RecommendationController has 3 empty stubs + 3 non-functional read methods; wrong Gate permission on 8/9 StudentRecommendation write routes (`create` used for all); broken `exists:users` validation (should be `sys_users`); inconsistent permission namespace (`recommendation.*` vs `tenant.*`); no Form Requests (0 in module); no EnsureTenantHasModule; `complexity_level` table name mismatch between store/update |
| LmsExam (~65%) | Exam CRUD, types, blueprints, papers, student groups, scopes, allocations; Form Requests exist | **`dd($e)` in LmsExamController::store()** exposes stack traces; ExamBlueprintController + ExamScopeController have ALL Gate calls commented out; ExamStudentGroupMemberController::store() uses raw $request without validation; no EnsureTenantHasModule; student answer submission & grading absent |
| StudentFee (~60%) | Invoice create/edit/cancel/pay, fine rules, scholarships, concessions, assignment workflows | **FeeConcessionController imported but doesn't exist** (fatal on route:cache); **GET /student-fee/seeder exposed in prod** with no auth (creates fake data); permission prefix mismatch on 3 controllers (`student-fee.*` vs `studentfee.*`); StudentFeeManagementController has zero auth on all 8 view methods + 3 empty stubs; `update()` trusts frontend `total_fee_amount`; no Form Requests (0 in module); N+1 in bulk invoice gen + assignment gen; non-tenant-scoped invoice PDF storage; no EnsureTenantHasModule |
| LmsHomework (~60%) | Homework CRUD, submissions, action types; Form Requests exist | **Fatal crash: `HoemworkData()` missing `$request` parameter** — all filter logic is dead code; `HomeworkSubmissionController::review()` has no Gate check or validation — any user can overwrite grades; `HomeworkSubmissionController::show()` no Gate check; no EnsureTenantHasModule; grading workflow incomplete |
| Hpc (~75%) | 22 controllers (was 15), 32 models (was 26), 10 services (was 2: HpcReportService, HpcPdfDataService → now +HpcSectionRoleService, HpcWorkflowService, HpcDataMappingService, HpcAttendanceService, HpcLmsIntegrationService, StudentHpcFormService, ParentHpcFormService, PeerAssignmentService, HpcCreditCalculatorService), 14 FormRequests (all with Gate::allows), 1 Trait (HpcIndexDataTrait), 242 views, 1 Job (SendHpcReportEmail), 1 Mailable (HpcReportMail), 55 tests. Template structure: 100%. Web form: 90%. PDF: 90%. Auth: 95% (all 22 controllers gated). EnsureTenantHasModule: ✅. Role-based section locking: ✅. Approval workflow (6-state): ✅. Student self-service portal: ✅. Parent token-based portal: ✅. Peer assessment workflow: ✅. LMS auto-feed: ✅. Credit calculator (NCrF): ✅. Attendance manager: ✅. Activity assessment 4-panel: ✅. Student goals wizard (T4): ✅. | **Remaining gaps:** HpcController still 2483 lines (god controller — partial refactor: utility methods moved to service, constructor injection, but form/PDF methods still inline). No full HpcFormService extraction yet. 8/20 blueprint screens not started. Student answer submission/grading (LMS dependency). 0% complete: MOOC integration, full parent account system. Tests: 55 written but not yet run against DB (need RefreshDatabase tenant setup). |
| Library (~45%) | 26 controllers, 35 models, 9 services, 19 requests, 140 views, 36 migrations — book catalog, members, transactions, fines, reservations, digital resources, reports, audits | **NOT wired into tenant.php** (zero tenancy middleware); 7 controllers with zero authorization (LibraryController, LibFineController, 5 report/dashboard controllers); 5 stub methods on only registered resource route; `$request->all()` in 5 controllers bypassing Form Requests; `Modules\Prime\Models\Setting` cross-layer import; N+1 in LibReservationController::create(); User::all() unbounded in 10+ index methods; 20+ duplicate queries per page load (God-controller pattern) |
| StudentPortal (~25%) | Dashboard, complaints, notifications controllers wired (3 refs in tenant.php) | Academic transcript, timetable view, homework submission, quiz taking, grade reports, parent portal, fee view |

### Missing Modules (Reserved Prefixes)
| Prefix | Module | Status |
|--------|--------|--------|
| `hos_` | Hostel Management | Not started |
| `mes_` | Canteen/Mess Management | Not started |
| `acc_` | Accounting | DB tables exist, no module |
| `beh_` | Behaviour Tracking | Not started |

### API Endpoints
All module APIs follow: `auth:sanctum` + `/v1/{module_plural}` + standard apiResource CRUD (index, store, show, update, destroy)
Modules WITHOUT active API routes: Billing, Notification, Vendor, LmsExam, LmsHomework, LmsQuests, Recommendation, SyllabusBooks, Documentation, Scheduler, SystemConfig
