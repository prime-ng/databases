# 02 — Project Structure

## Root Directory Layout

```
/Users/bkwork/Herd/laravel/
│
├── .ai/                            ← AI Brain: persistent knowledge base (rules, templates, agents)
├── .env.example                    ← Environment template
├── CLAUDE.md                       ← Project guidelines (MUST READ)
│
├── app/                            ← Core application code (non-module)
│   ├── Console/Commands/           ← Artisan commands (RunSchedules.php)
│   ├── Helpers/                    ← Global utilities (helpers.php, PermissionHelper.php, activityLog.php)
│   ├── Http/
│   │   ├── Controllers/            ← Central controllers (Auth, V1 API, Profile, Seeder)
│   │   ├── Middleware/             ← Custom middleware (3 files)
│   │   └── Requests/              ← Validation requests (Auth, V1 API)
│   ├── Jobs/                       ← Queued jobs (Prime/ and Tenant/ subdirectories)
│   ├── Mail/                       ← Mailable classes (Prime/)
│   ├── Models/                     ← Core User model + V1 deprecated models
│   ├── Notifications/              ← Notification classes
│   ├── Policies/                   ← 195+ authorization policy files
│   ├── Providers/                  ← Service providers (5 providers)
│   ├── Rules/                      ← Custom validation rules
│   ├── Services/                   ← Breadcrumb services
│   └── View/Components/            ← Blade components (Backend, Frontend, Prime)
│
├── bootstrap/                      ← Framework bootstrapping
│   ├── app.php                     ← Application instance
│   └── providers.php               ← Provider registration
│
├── config/                         ← 24 configuration files
│   ├── app.php                     ← App name, locale, timezone
│   ├── auth.php                    ← Auth guards (web, sanctum)
│   ├── database.php                ← DB connections (central, tenant)
│   ├── tenancy.php                 ← Stancl Tenancy config (CRITICAL)
│   ├── permission.php              ← Spatie Permission tables/cache
│   ├── permissionslist.php         ← All defined permissions (prime + tenant)
│   ├── sanctum.php                 ← API token config
│   ├── modules.php                 ← Module discovery settings
│   ├── excel.php                   ← Excel import/export settings
│   ├── media-library.php           ← Media handling config
│   ├── backup.php                  ← Backup configuration
│   ├── telescope.php               ← Debug profiler config
│   └── [11 more standard Laravel configs]
│
├── database/
│   ├── migrations/                 ← Central migrations (6 files)
│   │   └── tenant/                 ← Tenant migrations (216 files)
│   └── seeders/                    ← Data seeders (roles, permissions, reference data)
│
├── Modules/                        ← 29 feature modules (nwidart/laravel-modules)
│   ├── Prime/                      ← Central SaaS management
│   ├── GlobalMaster/               ← Shared reference data
│   ├── SystemConfig/               ← System settings
│   ├── Billing/                    ← Invoice & payment tracking
│   ├── SchoolSetup/                ← School infrastructure
│   ├── StudentProfile/             ← Student management
│   ├── SmartTimetable/             ← AI timetable generation
│   ├── Transport/                  ← Vehicle & route management
│   ├── Syllabus/                   ← Curriculum management
│   ├── SyllabusBooks/              ← Textbook management
│   ├── QuestionBank/               ← Question management
│   ├── Notification/               ← Multi-channel notifications
│   ├── Complaint/                  ← Issue tracking
│   ├── Vendor/                     ← Vendor management
│   ├── Payment/                    ← Razorpay integration
│   ├── Dashboard/                  ← Admin dashboards
│   ├── Hpc/                        ← Holistic Progress Card
│   ├── LmsExam/                    ← Examination system
│   ├── LmsQuiz/                    ← Quiz/assessment
│   ├── LmsHomework/                ← Homework management
│   ├── LmsQuests/                  ← Learning quests
│   ├── StudentFee/                 ← Fee management
│   ├── Recommendation/             ← AI recommendations
│   ├── Scheduler/                  ← Job scheduling
│   ├── Documentation/              ← Help articles
│   ├── StudentPortal/              ← Student-facing portal
│   └── Library/                    ← Library management (pending)
│
├── resources/
│   ├── views/                      ← Blade templates
│   │   ├── auth/                   ← Login, register, password reset
│   │   ├── prime/v1/               ← Central admin layouts
│   │   ├── backend/v1/             ← Backend admin views
│   │   ├── frontend/v1/            ← Public-facing templates
│   │   └── layouts/                ← Master layout files
│   ├── css/app.css                 ← Main stylesheet
│   ├── js/app.js                   ← Alpine.js + Axios initialization
│   └── lang/                       ← Translation files
│
├── routes/
│   ├── web.php                     ← Central admin routes (973 lines)
│   ├── tenant.php                  ← Tenant feature routes (2,628 lines)
│   ├── api.php                     ← Minimal central API (auth:sanctum)
│   ├── auth.php                    ← Authentication routes
│   └── console.php                 ← Artisan command routes
│
├── public/
│   ├── backend/css/                ← AdminLTE CSS (light, dark, RTL variants)
│   ├── frontend/assets/            ← Frontend theme assets
│   └── index.php                   ← Application entry point
│
├── storage/
│   ├── app/private/                ← Private file storage
│   ├── app/public/                 ← Public file storage
│   ├── framework/cache/            ← Cache storage
│   └── logs/                       ← Application logs
│
├── tests/
│   ├── Feature/                    ← Integration tests
│   ├── Unit/                       ← Unit tests
│   └── Pest.php                    ← Pest configuration
│
├── lang/                           ← Multi-language translations
├── composer.json                   ← PHP dependencies
├── package.json                    ← NPM dependencies (Vite, Tailwind, Alpine, Bootstrap)
├── vite.config.js                  ← Vite build configuration
├── tailwind.config.js              ← Tailwind CSS configuration
└── phpunit.xml                     ← Test configuration
```

---

## Module Internal Structure (Standard Template)

Every module follows a consistent structure:

```
Modules/{ModuleName}/
├── app/
│   ├── Http/
│   │   ├── Controllers/            ← Module controllers
│   │   └── Requests/               ← Form request validation
│   ├── Models/                     ← Eloquent models
│   ├── Services/                   ← Business logic services
│   ├── Jobs/                       ← Queued async tasks
│   ├── Events/                     ← Domain events
│   ├── Listeners/                  ← Event handlers
│   ├── Emails/ or Mail/            ← Email templates
│   └── Providers/                  ← Module service provider
├── config/
│   └── config.php                  ← Module configuration
├── database/
│   ├── migrations/                 ← Module-specific migrations
│   └── seeders/                    ← Module seeders
├── resources/
│   ├── views/                      ← Blade templates
│   ├── assets/                     ← JS, CSS, images
│   └── lang/                       ← Translations
├── routes/
│   ├── web.php                     ← Web routes
│   └── api.php                     ← API routes
├── tests/
│   ├── Feature/                    ← Module feature tests
│   └── Unit/                       ← Module unit tests
├── module.json                     ← Module metadata
├── composer.json                   ← Module dependencies
└── vite.config.js                  ← Module build config
```

---

## AI Brain Structure (.ai/)

```
.ai/
├── README.md                       ← Entry point and navigation guide
├── memory/                         ← Stable project knowledge
│   ├── project-context.md          ← Full project context
│   ├── tenancy-map.md              ← Multi-tenancy architecture (CRITICAL)
│   ├── modules-map.md              ← Module inventory and structure
│   ├── school-domain.md            ← School entity relationships
│   ├── conventions.md              ← Naming and coding standards
│   └── testing-strategy.md         ← Pest 4.x testing approach
├── rules/                          ← Mandatory development rules
│   ├── tenancy-rules.md            ← Tenancy isolation rules (MOST CRITICAL)
│   ├── module-rules.md             ← Module development patterns
│   ├── laravel-rules.md            ← Laravel conventions
│   ├── security-rules.md           ← Security requirements
│   ├── code-style.md               ← PSR-12 style guide
│   └── school-rules.md             ← School domain business rules
├── agents/                         ← Role-specific AI instructions (8 agents)
│   ├── developer.md, db-architect.md, module-agent.md, tenancy-agent.md
│   ├── api-builder.md, debugger.md, school-agent.md, test-agent.md
├── templates/                      ← 18 code boilerplate templates
├── state/                          ← Living project state
│   ├── progress.md                 ← Module completion tracker
│   └── decisions.md                ← Architectural decision log
├── lessons/
│   └── known-issues.md             ← Known bugs, gotchas, fixes
└── tasks/                          ← Task tracking (active, backlog, completed)
```

---

## Service Providers (5 Total)

| Provider | Purpose |
|----------|---------|
| **AppServiceProvider** | Gate policies registration (195+), pagination, breadcrumb binding |
| **TenancyServiceProvider** | Tenancy events, bootstrappers (DB, Cache, FS, Queue) |
| **TelescopeServiceProvider** | Debug toolbar configuration |
| **HelperServiceProvider** | Global helper function loading |
| **MenuServiceProvider** | Menu configuration and resolution |

---

## Key Configuration Files

| File | Purpose | Notable Settings |
|------|---------|-----------------|
| `config/tenancy.php` | Multi-tenancy | Tenant model, UUID generator, DB prefix: `tenant_`, bootstrappers |
| `config/permission.php` | RBAC | Tables: sys_roles, sys_permissions; Cache: 24h |
| `config/permissionslist.php` | Permission definitions | All prime + tenant permissions by module |
| `config/database.php` | DB connections | Central MySQL + tenant template |
| `config/sanctum.php` | API auth | Stateful domains, web guard |
| `config/excel.php` | Excel processing | Chunk: 1000, CSV delimiter, DomPDF driver |
| `config/modules.php` | Module discovery | Namespace: Modules, auto-discovery enabled |
