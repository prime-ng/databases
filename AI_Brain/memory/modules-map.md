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

## All Modules (29)

### Central-Scoped Modules (run on central domain, access prime_db/global_db)
| Module | Controllers | Models | Description |
|--------|-------------|--------|-------------|
| **Prime** | 22 | 27 | Tenant CRUD, plans, billing, users, roles, modules, menus, geography |
| **GlobalMaster** | 15 | 12 | Countries, states, cities, boards, languages, plans, dropdowns |
| **SystemConfig** | 3 | 3 | Settings, menus, translations |
| **Billing** | 6 | 6 | Invoice generation, payment tracking, billing cycles |
| **Documentation** | 3 | 2 | Knowledge base, help docs |

### Tenant-Scoped Modules (run on tenant domain, access tenant_db)
| Module | Controllers | Models | Services | Status | Description |
|--------|-------------|--------|----------|--------|-------------|
| **SchoolSetup** | 40 | 42 | 0 | 100% | Core infrastructure: classes, sections, subjects, teachers, rooms, buildings |
| **SmartTimetable** | 27 | 84 | 35 | 100% | AI timetable: FET solver, constraints, generation, analytics, substitution |
| **Transport** | 31 | 36 | 0 | 100% | Vehicles, routes, trips, driver attendance, student boarding, fees |
| **StudentProfile** | 5 | 14 | 0 | 100% | Student data, health profiles, documents, attendance, guardians |
| **Syllabus** | 15 | 22 | 0 | 100% | Lessons, topics, competencies, Bloom taxonomy, cognitive skills |
| **SyllabusBooks** | 4 | 6 | 0 | 100% | Textbooks, authors, topic mappings |
| **QuestionBank** | 7 | 17 | 0 | 100% | Questions, tags, versions, statistics, AI generation |
| **Notification** | 12 | 14 | 2 | 100% | Multi-channel notifications, templates, delivery logs |
| **Complaint** | 8 | 6 | 2 | 100% | Categories, SLA, actions, AI insights, medical checks |
| **Vendor** | 7 | 8 | 0 | 100% | Vendors, agreements, items, invoices, payments, usage logs |
| **Payment** | 4 | 5 | 2 | 100% | Razorpay integration, payment processing |
| **Dashboard** | 1 | 0 | 0 | 100% | Admin dashboards |
| **Scheduler** | 1 | 2 | 2 | 100% | Job scheduling |
| **Hpc** | 11 | 15 | 0 | ~90% | Holistic Progress Card, learning outcomes, evaluations |
| **LmsExam** | 11 | 11 | 0 | ~80% | Examination system |
| **LmsQuiz** | 5 | 6 | 0 | ~80% | Quiz/assessment system |
| **LmsHomework** | 5 | 5 | 0 | ~80% | Homework assignment & submission |
| **LmsQuests** | 4 | 4 | 0 | ~80% | Learning paths |
| **StudentFee** | 9 | 20 | 0 | ~80% | Fee heads, invoices, receipts, concessions, scholarships, fines |
| **Recommendation** | 10 | 11 | 0 | ~90% | AI recommendations, trigger events, rule engine |
| **StudentPortal** | 3 | 0 | 0 | Pending | Student-facing interface |
| **Library** | 1 | 0 | 0 | Pending | Library management |

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
| HPC | `/hpc/*` | learning-outcomes, evaluations, parameters |
| Complaint | `/complaint/*` | complaints, categories, actions, sla, dashboard |
| Notification | `/notification/*` | channels, templates, targets, delivery |
| Vendor | `/vendor/*` | vendors, agreements, invoices, payments |
| Payment | `/payment/*` | payment processing, gateway config |
| Recommendation | `/recommendation/*` | rules, materials, student-recommendations |
| StudentPortal | `/student-portal/*` | dashboard, academic-info, payments |
| SystemConfig | `/system-config/*` | settings, menus |

### Module Completion Detail

| Module | What's Complete | What's Missing |
|--------|----------------|----------------|
| LmsExam (80%) | Exams, types, blueprints, papers, paper sets, questions, student groups, scopes, allocations | Student answer submission, grading, result generation, report cards |
| LmsQuiz (80%) | Quizzes, questions (from QB), allocations, assessment types, difficulty distribution | Student attempt tracking, auto-grading, analytics |
| LmsHomework (80%) | Homework creation, submissions, action types, trigger events, rule engine config | Grading workflow, feedback system, late submission handling |
| LmsQuests (80%) | Quests, questions, allocations, scopes | Student progress tracking, completion awards, adaptive path logic |
| StudentFee (80%) | Fee structures, heads, groups, installments, invoices, concessions, fines, scholarships | Payment gateway integration flow, bulk invoice generation, comprehensive reporting |
| Hpc (90%) | Learning outcomes, evaluations, snapshots, activities, parameters, descriptors, circular goals, knowledge graph | Syllabus coverage snapshot integration with actual class delivery data |
| Recommendation (90%) | Rules, materials, bundles, trigger events, assessment types, student recs, dynamic material types | Performance snapshot integration with actual student data |
| StudentPortal (20%) | 3 controllers exist (dashboard, academic info, notifications, complaints) | Full student UI, academic transcript, timetable view, homework submission, quiz taking, grade reports, parent portal |
| Library (5%) | 1 controller stub | Full library: book inventory, issue/return, catalog, fines, reservations |

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
