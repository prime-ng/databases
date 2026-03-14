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
> **Audited:** 2026-03-14. Counts are actual filesystem counts from `Modules/` directory.
> Services count includes all .php files under `app/Services/**`. Controllers include subdirectories.

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
| **SchoolSetup** | 40 | 42 | 0 | 27 | 35 | 100% | Core infrastructure: classes, sections, subjects, teachers, rooms, buildings |
| **SmartTimetable** | 28 | 86 | 22 | 12 | 29 | 100% | AI timetable: FET solver, constraints, parallel periods, generation, analytics |
| **Transport** | 31 | 36 | 0 | 18 | 31 | 100% | Vehicles, routes, trips, driver attendance, student boarding, fees |
| **StudentProfile** | 5 | 14 | 0 | 0 | 4 | 100% | Student data, health profiles, documents, attendance, guardians |
| **Syllabus** | 15 | 22 | 0 | 14 | 14 | 100% | Lessons, topics, competencies, Bloom taxonomy, cognitive skills |
| **SyllabusBooks** | 4 | 6 | 0 | 3 | 4 | 100% | Textbooks, authors, topic mappings |
| **QuestionBank** | 7 | 17 | 0 | 6 | 7 | 100% | Questions, tags, versions, statistics, AI generation |
| **Notification** | 12 | 14 | 2 | 10 | 14 | 100% | Multi-channel notifications, templates, delivery logs |
| **Complaint** | 8 | 6 | 2 | 0 | 8 | 100% | Categories, SLA, actions, AI insights, medical checks |
| **Vendor** | 7 | 8 | 0 | 3 | 7 | 100% | Vendors, agreements, items, invoices, payments, usage logs |
| **Payment** | 4 | 5 | 2 | 0 | 3 | 100% | Razorpay integration, payment processing |
| **Dashboard** | 1 | 0 | 0 | 0 | 1 | 100% | Admin dashboards |
| **Scheduler** | 1 | 2 | 2 | 1 | 0* | 100% | Job scheduling (*uses module-level routing, not tenant.php) |
| **LmsQuiz** | 5 | 6 | 0 | 5 | 5 | **~72%** | Quiz CRUD works; Gate commented out in index; student attempt tracking absent |
| **LmsQuests** | 4 | 4 | 0 | 4 | 4 | **~68%** | Quest CRUD works; Gate commented out in index; progress tracking absent |
| **Recommendation** | 10 | 11 | 0 | 0 | 10 | **~65%** | 3 empty stubs; wrong perms 8/9 routes; broken validation; no FormRequests |
| **LmsExam** | 11 | 11 | 0 | 11 | 11 | **~65%** | dd($e) in prod; 2 controllers Gate disabled; no EnsureTenantHasModule |
| **StudentFee** | 15 | 23 | 0 | 0 | 16 | **~60%** | Missing controller; seeder route exposed; perm prefix mismatch; no FormRequests |
| **LmsHomework** | 5 | 5 | 0 | 5 | 5 | **~60%** | Fatal crash missing $request param; review() no auth; no EnsureTenantHasModule |
| **Hpc** | 15 | 26 | 1 | 14 | ~100+ | **~68%** | All 4 PDF templates DomPDF-fixed + ZIP download feature. **Still open:** 4 template controller imports missing (500s); zero auth on 13/14 HpcController methods; 7/14 FormRequests `return true`; 3 routes to non-existent methods; no EnsureTenantHasModule; cross-layer AcademicSession; case-sensitive class refs; ZIP cleanup missing |
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

### Module Completion Detail (deep-audited 2026-03-14)

| Module | What's Complete | What's Missing / Broken |
|--------|----------------|------------------------|
| LmsQuiz (~72%) | CRUD for quizzes, questions, allocations, assessment types, difficulty distribution; Form Requests exist | Gate commented out in index(); student attempt tracking absent; auto-grading absent; no EnsureTenantHasModule |
| LmsQuests (~68%) | CRUD for quests, questions, allocations, scopes; Form Requests exist | Gate commented out in index(); student progress tracking absent; completion awards absent; no EnsureTenantHasModule |
| Recommendation (~65%) | 8 of 10 controllers fully working CRUD with activity logging | RecommendationController has 3 empty stubs + 3 non-functional read methods; wrong Gate permission on 8/9 StudentRecommendation write routes (`create` used for all); broken `exists:users` validation (should be `sys_users`); inconsistent permission namespace (`recommendation.*` vs `tenant.*`); no Form Requests (0 in module); no EnsureTenantHasModule; `complexity_level` table name mismatch between store/update |
| LmsExam (~65%) | Exam CRUD, types, blueprints, papers, student groups, scopes, allocations; Form Requests exist | **`dd($e)` in LmsExamController::store()** exposes stack traces; ExamBlueprintController + ExamScopeController have ALL Gate calls commented out; ExamStudentGroupMemberController::store() uses raw $request without validation; no EnsureTenantHasModule; student answer submission & grading absent |
| StudentFee (~60%) | Invoice create/edit/cancel/pay, fine rules, scholarships, concessions, assignment workflows | **FeeConcessionController imported but doesn't exist** (fatal on route:cache); **GET /student-fee/seeder exposed in prod** with no auth (creates fake data); permission prefix mismatch on 3 controllers (`student-fee.*` vs `studentfee.*`); StudentFeeManagementController has zero auth on all 8 view methods + 3 empty stubs; `update()` trusts frontend `total_fee_amount`; no Form Requests (0 in module); N+1 in bulk invoice gen + assignment gen; non-tenant-scoped invoice PDF storage; no EnsureTenantHasModule |
| LmsHomework (~60%) | Homework CRUD, submissions, action types; Form Requests exist | **Fatal crash: `HoemworkData()` missing `$request` parameter** — all filter logic is dead code; `HomeworkSubmissionController::review()` has no Gate check or validation — any user can overwrite grades; `HomeworkSubmissionController::show()` no Gate check; no EnsureTenantHasModule; grading workflow incomplete |
| Hpc (~60%) | CRUD for 10 resource controllers (circular goals, outcomes, evaluations, snapshots, parameters, descriptors, equivalencies, activities, question mappings, knowledge graph); HpcReportService (788 lines, real save/load/delete logic); 4 PDF templates (first/second/third/fourth_pdf — Grades 3-12); Core HPC form rendering + saving + bulk PDF generation with ZIP; HpcController index/hpc_form/formStore/generateReportPdf/viewPdfPage/generateSingleStudentPdf all routed | **4 template controller class imports missing in tenant.php** (routes exist but 500 on access — HpcTemplates, Parts, Sections, Rubrics); **HpcController: zero authorization on 12/13 methods** (only index has Gate::any); **10 controllers missing Gate on store/update** (rely on FormRequest which has `return true`); 7/14 FormRequests hardcoded authorize `return true`; garbled permission string in HpcTemplatesController::show(); **3 routes point to non-existent methods** (hpcSecondForm, hpcThredForm, hpcFourthForm → 500); global AcademicSession cross-layer violation in 2 controllers; **No EnsureTenantHasModule** middleware; module web.php/api.php routes bypass tenancy; HpcTemplates model uses uppercase class refs (breaks Linux); all trash/view routes shadowed by resource show; orphan import LearningActivityController; zero tests |
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
