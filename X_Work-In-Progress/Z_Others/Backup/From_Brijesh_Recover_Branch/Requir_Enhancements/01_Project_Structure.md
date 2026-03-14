# 01 — Project Structure Analysis

## Technology Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| Language | PHP | 8.2+ |
| Framework | Laravel | 12.0 |
| Database | MySQL | 8.x (InnoDB, UTF8MB4) |
| Multi-Tenancy | stancl/tenancy | 3.9 |
| Modules | nwidart/laravel-modules | 12.0 |
| Auth (API) | Laravel Sanctum | 4.0 |
| Auth (RBAC) | Spatie Laravel Permission | 6.21 |
| Media | Spatie Laravel MediaLibrary | 11.17 |
| Backup | Spatie Laravel Backup | 9.3 |
| PDF | barryvdh/laravel-dompdf | 3.1 |
| Excel | maatwebsite/excel | 3.1 |
| QR | simplesoftwareio/simple-qrcode | 4.2 |
| Payment | razorpay/razorpay | 2.9 |
| Testing | Pest | 4.1 |
| Debug | Telescope 5.18, Debugbar 3.16 |
| CSS | Bootstrap 5 + AdminLTE 4 + Tailwind 3 |
| JS | Alpine.js 3.4 |
| Build | Vite 7.0 |

---

## Root Directory Structure

```
/Users/bkwork/Herd/laravel/
├── .ai/                            ← AI Brain: rules, templates, agents, memory
├── app/                            ← Core application (non-module code)
│   ├── Console/Commands/           ← Artisan commands (1: RunSchedules)
│   ├── Helpers/                    ← 3 helpers: helpers.php, PermissionHelper.php, activityLog.php
│   ├── Http/
│   │   ├── Controllers/            ← 13 central controllers (Auth, V1 API, Profile, Seeder)
│   │   ├── Middleware/             ← 3 custom: EnsureTenantIsActive, EnsureTenantHasModule, PreventBackHistory
│   │   └── Requests/              ← Auth + V1 API validation requests
│   ├── Jobs/                       ← 3 central jobs (CreateRootUser, StorageSymlink, Org Details)
│   ├── Mail/                       ← Prime email templates
│   ├── Models/                     ← User.php + deprecated V1/ models
│   ├── Notifications/              ← Notification classes
│   ├── Policies/                   ← 195+ authorization policies
│   ├── Providers/                  ← 5 providers (App, Tenancy, Telescope, Helper, Menu)
│   ├── Rules/                      ← Custom validation rules
│   ├── Services/                   ← Breadcrumb services
│   └── View/Components/            ← Blade components (Backend, Frontend, Prime)
│
├── bootstrap/                      ← app.php, providers.php
├── config/                         ← 24 configuration files
├── database/
│   ├── migrations/                 ← 6 central migrations
│   │   └── tenant/                 ← 216 tenant migrations
│   └── seeders/                    ← Role/permission, reference data seeders
│
├── Modules/                        ← 29 feature modules (nwidart)
│   ├── Prime/                      ← Central SaaS management (27 models, 20 controllers)
│   ├── GlobalMaster/               ← Reference data (12 models, 12 controllers)
│   ├── SystemConfig/               ← Settings (3 models, 3 controllers)
│   ├── Billing/                    ← Invoicing (6 models, 6 controllers)
│   ├── SchoolSetup/                ← School infrastructure (59 models, 32 controllers)
│   ├── StudentProfile/             ← Student management (13 models, 5 controllers)
│   ├── SmartTimetable/             ← AI timetable (94 models, 23 controllers, 5 services)
│   ├── Transport/                  ← Vehicle/route mgmt (39 models, 29 controllers)
│   ├── Syllabus/                   ← Curriculum (21 models, 16 controllers)
│   ├── SyllabusBooks/              ← Textbooks (6 models, 4 controllers)
│   ├── QuestionBank/               ← Questions (17 models, 7 controllers)
│   ├── Notification/               ← Multi-channel (13 models, 12 controllers)
│   ├── Complaint/                  ← Issue tracking (6 models, 8 controllers)
│   ├── Vendor/                     ← Vendor mgmt (8 models, 7 controllers)
│   ├── Payment/                    ← Razorpay (5 models, 4 controllers)
│   ├── Dashboard/                  ← Admin dashboards (0 models, 1 controller)
│   ├── Hpc/                        ← Progress card (14 models, 10 controllers)
│   ├── LmsExam/                    ← Exams (11 models, 11 controllers)
│   ├── LmsQuiz/                    ← Quizzes (6 models, 5 controllers)
│   ├── LmsHomework/                ← Homework (5 models, 5 controllers)
│   ├── LmsQuests/                  ← Quests (4 models, 4 controllers)
│   ├── StudentFee/                 ← Fee mgmt (19 models, 10 controllers)
│   ├── Recommendation/             ← AI recommendations (11 models, 10 controllers)
│   ├── Scheduler/                  ← Job scheduling (2 models, 1 controller)
│   ├── Documentation/              ← Help articles (2 models, 3 controllers)
│   ├── StudentPortal/              ← Student portal (0 models, 3 controllers)
│   └── Library/                    ← Library (0 models, 1 controller) [Pending]
│
├── resources/
│   ├── views/                      ← 500+ Blade templates
│   │   ├── auth/                   ← Login, register, password reset
│   │   ├── prime/v1/               ← Central admin layout
│   │   ├── backend/v1/             ← Backend admin views
│   │   └── frontend/v1/            ← Public-facing templates
│   ├── css/                        ← Stylesheets
│   └── js/                         ← Alpine.js + Axios
│
├── routes/
│   ├── web.php                     ← 973 lines — Central admin routes
│   ├── tenant.php                  ← 2,628 lines — Tenant feature routes
│   ├── api.php                     ← 9 lines — Minimal API
│   ├── auth.php                    ← Auth routes
│   └── console.php                 ← Artisan routes
│
├── public/
│   ├── backend/css/                ← AdminLTE CSS
│   └── frontend/assets/            ← Frontend theme
│
├── storage/                        ← Logs, cache, uploads
├── tests/                          ← Pest 4.1 tests (~5 active)
├── lang/                           ← Translations
├── composer.json                   ← 50+ PHP dependencies
├── package.json                    ← NPM (Vite, Tailwind, Alpine, Bootstrap)
└── CLAUDE.md                       ← Project guidelines
```

---

## Module Internal Structure (Standard Template)

```
Modules/{ModuleName}/
├── app/
│   ├── Http/Controllers/           ← Module controllers
│   ├── Http/Requests/              ← Form request validation
│   ├── Models/                     ← Eloquent models
│   ├── Services/                   ← Business logic (when present)
│   ├── Jobs/                       ← Async tasks
│   ├── Events/                     ← Domain events
│   ├── Listeners/                  ← Event handlers
│   ├── Gateways/                   ← External integrations (Payment)
│   └── Providers/                  ← Module service provider
├── config/config.php               ← Module config
├── database/migrations/            ← Module-specific migrations
├── database/seeders/               ← Module seeders
├── resources/views/                ← Blade templates
├── routes/web.php                  ← Web routes
├── routes/api.php                  ← API routes
├── tests/                          ← Module tests
└── module.json                     ← Module metadata
```

---

## Key Statistics

| Metric | Count |
|--------|-------|
| Total Modules | 29 (27 active + 2 pending) |
| Total Models | 381 |
| Total Controllers | 283 (13 central + 270 module) |
| Total Migrations | 280 (6 central + 216 tenant + 58 module) |
| Authorization Policies | 195+ |
| Form Requests | 168 |
| Services | 12 |
| Jobs | 9 |
| Events | 3 |
| Listeners | 2 |
| Custom Middleware | 3 |
| Config Files | 24 |
| Blade Views | 500+ |
| DB Tables (Total) | 407 (12 global + 27 prime + 368 tenant) |
| Roles | 15 (6 central + 9 tenant) |
| Service Providers | 5 (app-level) |

---

## Three-Layer Database Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Application Layer                     │
│           Laravel 12.0 + 29 Modules + Sanctum           │
└────────────┬──────────────┬──────────────┬──────────────┘
             │              │              │
    ┌────────▼────────┐ ┌───▼────┐ ┌──────▼──────────┐
    │   global_db     │ │prime_db│ │ tenant_{uuid}   │
    │   12 tables     │ │27 tbls │ │ 368 tables      │
    │   (glb_*)       │ │(prm_*, │ │ (sch_*,tt_*,    │
    │   Read-only     │ │ bil_*, │ │  std_*,slb_*,   │
    │   shared data   │ │ sys_*) │ │  tpt_*,vnd_*,   │
    │                 │ │        │ │  fin_*,qns_*...) │
    └─────────────────┘ └────────┘ └─────────────────┘
```

---

## Configuration Overview

| Config File | Key Settings |
|-------------|-------------|
| `tenancy.php` | Tenant model (Modules\Prime\Models\Tenant), UUID generator, DB prefix: tenant_, bootstrappers: DB/Cache/FS/Queue |
| `permission.php` | Tables: sys_roles/sys_permissions/jnt tables, Cache: 24h |
| `permissionslist.php` | All prime + tenant permissions by module |
| `sanctum.php` | Stateful domains, web guard, no token expiry |
| `database.php` | Central MySQL + tenant DB template |
| `excel.php` | Chunk: 1000, DomPDF driver |
| `modules.php` | Namespace: Modules, auto-discovery |
| `backup.php` | Spatie backup configuration |
