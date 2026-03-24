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

## All Modules (30)
> **Audited:** 2026-03-22 against `prime_ai_tarun` / branch `Brijesh_SmartTimetable`.
> Controllers exclude backup files (`*_backup*.php`, `*.bk`, `*copy*`).
> Services count = unique .php files under `app/Services/` (recursive).

### Global Statistics
| Metric | Count |
|--------|-------|
| Total Modules | 30 (5 central + 25 tenant) |
| Total Models | 464 |
| Total Controllers | 339 |
| Total Services | 137 (SmartTimetable: 106, Hpc: 10, Library: 9, TimetableFoundation: 3, others) |
| Total Views | 2,036 blade files |
| Total FormRequests | 190 |
| Total Policies | 230 (in `app/Policies/`) |
| Tenant Migrations | 319 files in `database/migrations/tenant/` |
| Tenant Route Lines | 3,176 (1,613 Route:: calls) |
| Central Route Lines | 954 (404 Route:: calls) |
| Total Test Files | 134 |
| EnsureTenantHasModule usage | 1 (across entire tenant.php) |

### Central-Scoped Modules (run on central domain, access prime_db/global_db)
| Module | Controllers | Models | Services | Requests | Views | Seeders | Route Lines | Tests | Description |
|--------|-------------|--------|----------|----------|-------|---------|-------------|-------|-------------|
| **Prime** | 21 | 27 | 1 | 7 | 84 | 2 | 244 | 9 | Tenant CRUD, plans, billing, users, roles, modules, menus, geography |
| **GlobalMaster** | 15 | 12 | 0 | 10 | 48 | 3 | 27 | 4 | Countries, states, cities, boards, languages, plans, dropdowns |
| **SystemConfig** | 4 | 3 | 0 | 1 | 8 | 2 | 16 | 1 | Settings, menus, translations |
| **Billing** | 6 | 6 | 0 | 3 | 40 | 1 | 18 | 1 | Invoice generation, payment tracking, billing cycles |
| **Documentation** | 3 | 2 | 0 | 2 | 15 | 3 | 16 | 1 | Knowledge base, help docs |

### Tenant-Scoped Modules (run on tenant domain, access tenant_db)
| Module | Controllers | Models | Services | Requests | Views | Jobs | Events | Listeners | Seeders | Route Lines | Tests | Description |
|--------|-------------|--------|----------|----------|-------|------|--------|-----------|---------|-------------|-------|-------------|
| **SchoolSetup** | 40 | 42 | 0 | 27 | 220 | 0 | 1 | 0 | 7 | 523 | 0 | School structure, classes, sections, subjects, teachers, rooms, buildings |
| **SmartTimetable** | 12 | 62 | 106 | 7 | 218 | 1 | 0 | 0 | 14 | 41 | 7† | AI timetable: FET solver, 22 Hard + 55+ Soft constraint classes, analytics, refinement, substitution |
| **TimetableFoundation** | 24 | 32 | 3 | 4 | 148 | 0 | 0 | 0 | 1 | 262 | 7 | Shared timetable config: period sets, day types, configurations, academic terms |
| **Transport** | 31 | 36 | 0 | 18 | 151 | 0 | 0 | 0 | 1 | 32 | 0 | Vehicles, routes, trips, drivers, pickup points, student allocation, inspections |
| **Hpc** | 22 | 32 | 10 | 14 | 242 | 1 | 0 | 0 | 0 | 8 | 8† | Holistic Progress Card: 4 PDF templates, approval workflow, student/parent/peer portals |
| **Library** | 26 | 35 | 9 | 19 | 140 | 0 | 0 | 0 | 1 | 35 | 15† | Book catalog, members, transactions, fines, reservations, digital resources, reports |
| **StudentProfile** | 5 | 14 | 0 | 0 | 45 | 0 | 0 | 0 | 1 | 16 | 6† | Student CRUD, guardians, attendance, medical incidents |
| **StudentFee** | 15 | 23 | 0 | 0 | 88 | 0 | 0 | 0 | 1 | 16 | 24 | Fee heads, invoices, receipts, concessions, scholarships, fines, assignments |
| **Syllabus** | 15 | 22 | 0 | 14 | 78 | 0 | 0 | 0 | 1 | 16 | 0 | Lessons, topics, competencies, bloom taxonomy, cognitive skills, schedules |
| **QuestionBank** | 7 | 17 | 0 | 6 | 38 | 0 | 0 | 0 | 1 | 16 | 0 | Questions with bloom/cognitive/complexity tagging, AI generation, search |
| **LmsExam** | 11 | 11 | 0 | 11 | 58 | 0 | 0 | 0 | 1 | 17 | 0 | Exam blueprints, paper sets, allocations, scopes, student groups |
| **LmsQuiz** | 5 | 6 | 0 | 5 | 29 | 0 | 0 | 0 | 1 | 16 | 0 | Quizzes, questions, allocations, assessment types, difficulty distribution |
| **LmsHomework** | 5 | 5 | 0 | 5 | 28 | 0 | 0 | 0 | 1 | 16 | 0 | Homework, submissions, action types, trigger events, rule engine |
| **LmsQuests** | 4 | 4 | 0 | 4 | 23 | 0 | 0 | 0 | 1 | 16 | 0 | Quests, questions, scopes, allocations |
| **Notification** | 12 | 14 | 2 | 10 | 64 | 0 | 1 | 1 | 1 | 16 | 0 | Channels, templates, targets, delivery; routes currently COMMENTED OUT |
| **Complaint** | 8 | 6 | 2 | 0 | 34 | 0 | 1 | 1 | 1 | 16 | 4† | Complaints, categories, actions, SLA, AI insights, dashboard |
| **Vendor** | 7 | 8 | 0 | 3 | 35 | 1 | 0 | 0 | 1 | 16 | 0 | Vendors, agreements, invoices, payments, inspections |
| **Payment** | 2 | 5 | 2 | 1 | 9 | 0 | 2 | 0 | 1 | 16 | 8 | Payment gateway (Razorpay), processing, callbacks |
| **Recommendation** | 10 | 11 | 0 | 0 | 53 | 0 | 0 | 0 | 1 | 16 | 0 | Rules, materials, student recommendations |
| **SyllabusBooks** | 4 | 6 | 0 | 3 | 17 | 0 | 0 | 0 | 1 | 16 | 0 | Books, book-topic mapping, authors |
| **Accounting** | 18 | 21 | 0 | 15 | 79 | 0 | 0 | 0 | 2 | 152 | 14 | **NEW** — Tally-inspired voucher engine, chart of accounts, ledgers, journal entries |
| **StandardTimetable** | 1 | 0 | 0 | 0 | 3 | 0 | 0 | 0 | 1 | 30 | 0 | Standard timetable views (skeleton) |
| **StudentPortal** | 3 | 0 | 0 | 0 | 27 | 0 | 0 | 0 | 1 | 16 | 7 | Student-facing interface: dashboard, complaints, notifications |
| **Dashboard** | 1 | 0 | 0 | 0 | 8 | 0 | 0 | 0 | 1 | 16 | 0 | Admin dashboards |
| **Scheduler** | 1 | 2 | 2 | 1 | 6 | 0 | 0 | 0 | 1 | 16 | 1 | Job scheduling (uses module-level routing) |

> † Test locations: SmartTimetable tests in `tests/Feature/SmartTimetable/` (1) + `tests/Unit/SmartTimetable/` (6). Hpc in `tests/Feature/Hpc/` (1) + `tests/Unit/Hpc/` (6) + `tests/Browser/Modules/HPC/` (1). Library in `tests/Browser/Modules/Library/` (15). StudentProfile in `tests/Browser/Modules/StudentProfile/` (5) + `tests/Unit/StudentProfile/` (1). Complaint in `tests/Browser/Modules/Complaint/` (4). Also: `tests/Browser/Modules/Class&SubjectMgmt/` (9 files — SchoolSetup related).

### Key Module Routes

| Module | Route Prefix | Key Endpoints |
|--------|-------------|---------------|
| Prime (Central) | `/prime/*` | tenants, users, roles, billing, boards, academic-sessions, dropdowns |
| GlobalMaster (Central) | `/global-master/*` | countries, states, cities, boards, languages, modules, plans |
| Billing (Central) | `/billing/*` | billing-management, subscription, invoicing-payment, billing-cycle |
| Accounting | `/accounting/*` | chart-of-accounts, ledgers, vouchers, journal-entries, reports |
| SchoolSetup | `/school-setup/*` | organization, class, section, subject, teacher, room, building, department, designation |
| SmartTimetable | `/smart-timetable/*` | timetable, activity, period-set, constraint, teacher-availability, school-day, tt-config |
| TimetableFoundation | `/timetable-foundation/*` | period-sets, day-types, configurations, academic-terms, generation-strategies |
| StudentProfile | `/student/*` | students, attendance, medical-incident, reports |
| StudentFee | `/student-fee/*` | fee-head-master, fee-invoice, fee-receipt, concession, scholarship, fine |
| Transport | `/transport/*` | vehicle, route, trip, driver-helper, pickup-point, student-allocation, vehicle-inspection |
| Syllabus | `/syllabus/*` | lesson, topic, competency, bloom-taxonomy, cognitive-skill, study-material |
| QuestionBank | `/question-bank/*` | questions, tags, statistics, AI generation |
| LmsExam | `/exam/*` | exams, papers, allocations, blueprints |
| LmsQuiz | `/quiz/*` | quizzes, questions, allocations |
| LmsHomework | `/homework/*` | homework, submissions, rules |
| LmsQuests | `/quests/*` | quests, questions, scopes |
| HPC | `/hpc/*` | hpc, templates, hpc-form, generate-report, circular-goals, learning-outcomes, hpc-parameters, student-hpc-evaluation, learning-activities |
| Complaint | `/complaint/*` | complaints, categories, actions, sla, dashboard |
| Notification | `/notification/*` | channels, templates, targets, delivery |
| Vendor | `/vendor/*` | vendors, agreements, invoices, payments |
| Payment | `/payment/*` | payment processing, gateway config |
| Recommendation | `/recommendation/*` | rules, materials, student-recommendations |
| StudentPortal | `/student-portal/*` | dashboard, academic-info, payments |
| SystemConfig | `/system-config/*` | settings, menus |

### Planned Modules (Requirements Complete, Development Pending)
| Prefix | Module | Laravel Module | Tables | Status | Requirement Doc |
|--------|--------|---------------|--------|--------|-----------------|
| `prl_` | **Payroll** | `Modules/Payroll/` (not yet created) | 19 new + sch_employees ALTER | Requirements v4 done. 11 controllers, 6 services planned. | `1-DDL_Tenant_Modules/21-Payroll/Claude_Plan/Payroll_Requirement_v4.md` |
| `inv_` | **Inventory** | `Modules/Inventory/` (not yet created) | 19 new | Requirements v4 done. 14 controllers, 6 services planned. | `1-DDL_Tenant_Modules/22-Inventory/Claude_Plan/Inventory_Requirement_v4.md` |

### Key Architecture: Voucher Engine (shared by Accounting, Payroll, Inventory)
- Accounting owns `acc_vouchers` + `acc_voucher_items` (double-entry Dr/Cr)
- Payroll fires `PayrollApproved` event → Accounting creates Payroll Journal Voucher
- Inventory fires `GrnAccepted`/`StockIssued` events → Accounting creates Purchase/Stock Journal Vouchers
- StudentFee fires `FeePaymentReceived` → Accounting creates Receipt Voucher
- Transport fires `TransportFeeCharged` → Accounting creates Sales Voucher
- Shared contract: `VoucherServiceInterface` in Accounting module

### Missing Modules (Reserved Prefixes)
| Prefix | Module | Status |
|--------|--------|--------|
| `hos_` | Hostel Management | Not started |
| `mes_` | Canteen/Mess Management | Not started |
| `beh_` | Behaviour Tracking | Not started |

### API Endpoints
All module APIs follow: `auth:sanctum` + `/v1/{module_plural}` + standard apiResource CRUD (index, store, show, update, destroy)
Modules WITHOUT active API routes: Billing, Notification, Vendor, LmsExam, LmsHomework, LmsQuests, Recommendation, SyllabusBooks, Documentation, Scheduler, SystemConfig
