# How to Use AI Agents — Complete Guide

**Project:** Prime-AI Academic Intelligence Platform
**Agent Location:** `AI_Brain/agents/` (12 agent files)
**Last Updated:** 2026-03-15

---

## What Are AI Agents?

AI Agents are **instruction files** stored in `AI_Brain/agents/`. Each agent defines a specialized role with specific knowledge, rules, and deliverables. When you tell Claude to "use the Business Analyst agent" or "act as the Frontend Developer," Claude reads that agent file and follows its instructions — giving you expert-level output for that specific task.

**Think of agents as hiring specialists:** You wouldn't ask a database architect to write a sales pitch, and you wouldn't ask a frontend developer to design your database schema. Each agent knows its domain.

---

## How to Use an Agent — 3 Methods

### Method 1: Direct Reference in Your Prompt (Recommended)

```
Read AI_Brain/agents/business-analyst.md and follow its instructions.

Now create an RBS entry for the Hostel Management module with these screens:
- Hostel List
- Room Setup
- Student Allotment
...
```

### Method 2: Role-Based Instruction

```
You are acting as the Frontend Developer agent for Prime-AI.
Read AI_Brain/agents/frontend-developer.md first.

Now create the index view for the HPC Learning Outcomes page.
```

### Method 3: Combined Agents (for complex tasks)

```
Read these two agent files:
- AI_Brain/agents/business-analyst.md
- AI_Brain/agents/db-architect.md

First, create the feature specification for the Hostel module (BA role).
Then, design the database schema based on that specification (DB Architect role).
```

---

## All 12 Agents — Detailed Reference

---

### 1. Business Analyst

| Field | Detail |
|-------|--------|
| **Agent Name** | Business Analyst |
| **File** | `AI_Brain/agents/business-analyst.md` |
| **Role** | Translates business ideas into structured, developer-ready specifications. Bridges the gap between "I want a hostel module" and a detailed document that developers can code from. |

**When to Use:**
- Starting a **new module** from scratch — you have an idea but no specification
- Turning **wireframes/mockups** into field-level screen specifications
- Creating or expanding **RBS entries** (Requirements Breakdown Structure)
- Performing **gap analysis** — comparing what's required vs what's built
- Defining **business rules**, status workflows, and validation logic
- Planning **permissions** and who can access what
- Breaking features into **sprint-ready developer tasks** with effort estimates

**How to Use:**
```
Read AI_Brain/agents/business-analyst.md and follow its instructions.

Create a complete Feature Specification for the Hostel Management module.

Screens I need:
1. Hostel List — master CRUD for hostels
2. Room Setup — rooms with capacity, type, floor
3. Student Allotment — assign students to rooms
4. Mess Menu — weekly meal planning
5. Hostel Attendance — daily check-in/check-out
6. Hostel Fee — room + mess charges

Business Rules:
- Room capacity cannot be exceeded
- Gender-based room allocation (boys/girls hostels)
- Fee prorated for mid-session joins

Store output in: databases/3-Project_Planning/3-Feature_Specs/HostelManagement_FeatureSpec.md
```

**What It Produces:**
- RBS entries (Functionality → Task → Sub-task hierarchy)
- Feature specifications with field tables, validation rules, dropdown sources
- Entity relationship diagrams (text-based)
- Permission matrices (role × action)
- Sprint task breakdowns with effort estimates

**Special Knowledge:**
- Indian K-12 school domain (CBSE/ICSE, academic sessions, fee structures, HPC)
- School decision-maker roles (Principal, Trustee, Management Committee)
- Existing module dependencies in Prime-AI

---

### 2. Frontend Developer

| Field | Detail |
|-------|--------|
| **Agent Name** | Frontend Developer |
| **File** | `AI_Brain/agents/frontend-developer.md` |
| **Role** | Creates Blade views, forms, tables, and UI components matching the exact AdminLTE v4 + Bootstrap 5 patterns used in the project. |

**When to Use:**
- Creating **index/list views** (data tables with pagination, filters, action buttons)
- Creating **create/edit forms** (text inputs, selects, file uploads, checkboxes)
- Creating **show/detail pages** (read-only display with related data)
- Creating **tab-based master views** (multiple entities on one page)
- Creating **dashboard views** (charts, stats cards, widgets)
- Creating **PDF templates** (DomPDF for HPC, invoices, reports)
- Working with **shared components** (`<x-backend.layouts.app>`, breadcrumbs, card headers)

**How to Use:**
```
Read AI_Brain/agents/frontend-developer.md and follow its instructions.

Create the index view for HPC Learning Outcomes.

Columns to display: Name, Parameter, Status, Action
Filters: By parameter, by status
Actions: Edit, Delete, Toggle Status
Use the standard index pattern from the agent file.

File: Modules/Hpc/resources/views/learning-outcomes/index.blade.php
```

**What It Produces:**
- Complete Blade view files matching existing patterns exactly
- Consistent use of `<x-backend.layouts.app>`, `<x-backend.components.breadcrum>`, etc.
- Forms with proper `@csrf`, `@method`, `@error`, `old()` handling
- Tables with `@forelse`/`@empty`, pagination, status badges

**Key Rules It Follows:**
- Tenant pages use `<x-backend.layouts.app>`, Prime pages use `<x-prime.layouts.app>`
- PDF templates: NO Bootstrap, NO flexbox, NO JavaScript — only `<table>` layouts with inline styles
- Every `<table>` in DomPDF must have `width="100%"` HTML attribute (or it crashes)

---

### 3. Backend Developer

| Field | Detail |
|-------|--------|
| **Agent Name** | Backend Developer |
| **File** | `AI_Brain/agents/backend-developer.md` |
| **Role** | Creates controllers, models, FormRequests, services, routes, migrations, and seeders following the project's exact security and coding patterns. |

**When to Use:**
- Creating **controllers** with full CRUD (index, create, store, show, edit, update, destroy, trashed, restore, forceDelete, toggleStatus)
- Creating **models** with correct `$table`, `$fillable`, SoftDeletes, relationships
- Creating **FormRequests** with validation rules and proper `authorize()` (NOT `return true`)
- Creating **services** for complex business logic
- Creating **migrations** in the correct location (tenant/ vs central)
- Registering **routes** in the correct file (tenant.php vs web.php)
- Fixing **security issues** (adding Gate::authorize, replacing `$request->all()` with `$request->validated()`)

**How to Use:**
```
Read AI_Brain/agents/backend-developer.md and follow its instructions.

Create the full backend for HPC Learning Outcomes:
1. Controller with all 11 standard methods
2. StoreRequest + UpdateRequest FormRequests
3. Register routes in routes/tenant.php under the hpc prefix

Table: hpc_learning_outcomes
Fields: name (required, max 255), description (nullable), hpc_parameter_id (FK), is_active, created_by
```

**What It Produces:**
- Controllers with `Gate::authorize()` on every method
- FormRequests with validation rules and Gate-based `authorize()`
- Models with `$table`, `$fillable`, `$casts`, SoftDeletes, relationships
- Route registration with trash/restore/toggleStatus routes

**Non-Negotiable Security Rules:**
1. `Gate::authorize()` as FIRST line of every public method
2. `$request->validated()` — NEVER `$request->all()`
3. NEVER include `is_super_admin` in `$fillable`
4. FormRequest `authorize()` uses Gate — NEVER `return true`
5. Always paginate — NEVER `::all()` or unbounded `::get()`

---

### 4. DevOps & Deployment Engineer

| Field | Detail |
|-------|--------|
| **Agent Name** | DevOps & Deployment Engineer |
| **File** | `AI_Brain/agents/devops-deployer.md` |
| **Role** | Handles CI/CD pipelines, server setup, Docker, cloud deployment, SSL, wildcard domains, queue workers, backups, and monitoring for the multi-tenant platform. |

**When to Use:**
- Setting up **CI/CD pipelines** (GitHub Actions, GitLab CI)
- **Deploying** to cloud (AWS, DigitalOcean, Hetzner, Laravel Forge)
- Configuring **Docker/Docker Compose** for development or production
- Setting up **production server** (Nginx + PHP-FPM + MySQL + Redis + Supervisor)
- Configuring **wildcard DNS + SSL** for multi-tenant subdomains
- Setting up **queue workers** (Supervisor)
- Configuring **automated backups** (Spatie Backup + S3)
- Setting up **monitoring** (Telescope, Sentry, UptimeRobot)
- Estimating **hosting costs** per tenant count

**How to Use:**
```
Read AI_Brain/agents/devops-deployer.md and follow its instructions.

Create a GitHub Actions CI/CD pipeline that:
1. Runs Pest tests on every push
2. Deploys to staging on push to 'staging' branch
3. Deploys to production on push to 'main' branch with maintenance mode

Server: DigitalOcean Droplet, Ubuntu 22.04
Domain: primeai.in with wildcard subdomains
```

**What It Produces:**
- Complete CI/CD pipeline YAML files
- Nginx configuration with wildcard SSL
- Docker Compose files for local development
- Server setup scripts (PHP, MySQL, Redis, Supervisor, Certbot)
- Backup strategy configuration
- Production readiness checklist (16 items)

**Special Knowledge:**
- stancl/tenancy wildcard domain requirements
- MySQL user needs `CREATE DATABASE` privilege (for auto tenant DB creation)
- PHP `max_execution_time` must be 300+ for timetable generation
- Razorpay webhook route must be OUTSIDE auth middleware

---

### 5. Database Architect

| Field | Detail |
|-------|--------|
| **Agent Name** | Database Architect |
| **File** | `AI_Brain/agents/db-architect.md` |
| **Role** | Designs database schemas, creates migrations, and ensures proper table structure for the 3-layer multi-tenant architecture (global_db, prime_db, tenant_db). |

**When to Use:**
- Designing **new tables** for a feature
- Creating **Laravel migrations** (tenant vs central — correct path)
- Reviewing **existing schema** for issues
- Adding **columns or indexes** to existing tables (additive migrations only)
- Designing **junction tables** for many-to-many relationships
- Choosing **data types** (VARCHAR vs TEXT, DECIMAL precision, JSON columns)

**How to Use:**
```
Read AI_Brain/agents/db-architect.md and follow its instructions.

Design the database schema for Hostel Management module:
- Hostels (name, address, warden, capacity, type: boys/girls/co-ed)
- Rooms (hostel_id FK, number, floor, capacity, room_type)
- Student Allotment (student_id FK, room_id FK, bed_number, allotment_date)
- Mess Menu (day, meal_type, items_json)

Table prefix: hos_
Database: tenant_db
Migration path: database/migrations/tenant/
```

**What It Produces:**
- CREATE TABLE DDL statements
- Laravel migration files in the correct path
- Proper indexes on all foreign keys
- Required columns on every table (id, is_active, created_by, timestamps, deleted_at)

**Critical Rules:**
- Tenant migrations ALWAYS go in `database/migrations/tenant/`
- NEVER modify existing migrations — create new additive ones
- Junction tables suffix: `_jnt`
- JSON columns suffix: `_json`
- Boolean columns prefix: `is_` or `has_`

---

### 6. API Builder

| Field | Detail |
|-------|--------|
| **Agent Name** | API Builder |
| **File** | `AI_Brain/agents/api-builder.md` |
| **Role** | Builds RESTful API endpoints with Sanctum authentication, proper response formatting, and API Resources. |

**When to Use:**
- Creating **REST API endpoints** for mobile apps or third-party integrations
- Building **API Resources** (JSON response transformers)
- Setting up **Sanctum token authentication**
- Implementing **API versioning** (`/api/v1/...`)
- Building **webhook endpoints** (Razorpay, SMS providers)

**How to Use:**
```
Read AI_Brain/agents/api-builder.md and follow its instructions.

Create REST API endpoints for the Transport module:
- GET /api/v1/vehicles — list all vehicles (paginated)
- GET /api/v1/vehicles/{id} — vehicle details
- POST /api/v1/vehicles — create vehicle
- PUT /api/v1/vehicles/{id} — update vehicle

Auth: Sanctum token
Response format: { success: true, data: {...}, message: "..." }
```

**What It Produces:**
- API controller with consistent JSON response format
- API Resource classes for response transformation
- Route registration in `routes/api.php` with `auth:sanctum`
- Standard error response format with validation messages

**Response Format:**
```json
{
    "success": true,
    "data": { "id": 1, "name": "Vehicle 1" },
    "message": "Resource retrieved successfully"
}
```

---

### 7. General Developer

| Field | Detail |
|-------|--------|
| **Agent Name** | Developer (General) |
| **File** | `AI_Brain/agents/developer.md` |
| **Role** | General-purpose Laravel developer for full-stack feature development. Covers the entire flow from migration to testing. |

**When to Use:**
- Building a **complete feature end-to-end** (DB → Model → Controller → Views → Routes → Tests)
- When the task spans **multiple layers** and doesn't fit a specialist agent
- Quick **small features** that don't need the BA → Frontend → Backend pipeline
- When you're unsure **which specialist agent** to use — start here

**How to Use:**
```
Read AI_Brain/agents/developer.md and follow its instructions.

Add a "Study Material" feature to the Syllabus module:
- Table: slb_study_materials (title, description, file_path, topic_id FK, type: pdf/video/link)
- Full CRUD with views
- Registered in tenant.php under syllabus prefix
```

**What It Produces:**
- Complete feature: migration + model + controller + FormRequest + views + routes
- Follows the 10-step checklist (Planning → DB → Model → Service → Validation → Controller → Routes → Views → Testing → Documentation)

**When to Use a Specialist Instead:**
- If the task is purely UI work → use Frontend Developer
- If the task is purely backend logic → use Backend Developer
- If you need a specification first → use Business Analyst
- If you're fixing a bug → use Debugger

---

### 8. Module Specialist

| Field | Detail |
|-------|--------|
| **Agent Name** | Module Specialist |
| **File** | `AI_Brain/agents/module-agent.md` |
| **Role** | Expert in nwidart/laravel-modules v12.0. Handles creating new modules, configuring providers, and registering modules properly. |

**When to Use:**
- Creating a **brand new module** (e.g., Hostel, Accounting, HR)
- Fixing **module configuration** issues (module.json, composer.json, providers)
- Understanding **module autoloading** and service provider registration
- Moving code **between modules** or splitting a large module

**How to Use:**
```
Read AI_Brain/agents/module-agent.md and follow its instructions.

Create a new module called "HostelManagement" with:
- Table prefix: hos_
- Route prefix: /hostel
- Side: Tenant
- Initial entities: Hostel, Room, RoomType, StudentAllotment
```

**What It Produces:**
- Complete module folder structure (`Modules/HostelManagement/`)
- `module.json` with correct configuration
- `composer.json` with PSR-4 autoloading
- Service providers (ModuleServiceProvider, RouteServiceProvider)
- Route files (`web.php`, `api.php`)
- Model and controller stubs for initial entities

---

### 9. School Domain Expert

| Field | Detail |
|-------|--------|
| **Agent Name** | School Domain Expert |
| **File** | `AI_Brain/agents/school-agent.md` |
| **Role** | Ensures all school-specific features follow Indian K-12 educational domain rules and workflows. |

**When to Use:**
- When you need to understand **school business rules** before coding
- Designing features that involve **academic sessions, terms, promotions**
- Implementing **fee collection workflows** (invoices, concessions, fines)
- Implementing **timetable generation** workflows
- Understanding **student lifecycle** (enrollment → attendance → assessment → promotion)
- Understanding **teacher lifecycle** (assignment → availability → workload → substitution)
- When a developer asks "how does this work in a school?"

**How to Use:**
```
Read AI_Brain/agents/school-agent.md and follow its instructions.

Explain the complete workflow for:
1. How does a school set up fees at the beginning of the year?
2. What happens when a student joins mid-session?
3. How are transport fees different from tuition fees?
```

**What It Provides:**
- Academic structure hierarchy (Session → Term → Class → Section → Subject)
- Student lifecycle workflows (enrollment to promotion)
- Fee collection workflow (structure → invoice → payment → receipt)
- Timetable generation workflow (9-step process)
- Complaint resolution workflow
- New academic year setup checklist

**This agent does NOT write code** — it provides the business logic understanding that developers need before coding.

---

### 10. Tenancy Specialist

| Field | Detail |
|-------|--------|
| **Agent Name** | Tenancy Specialist |
| **File** | `AI_Brain/agents/tenancy-agent.md` |
| **Role** | Expert in stancl/tenancy v3.9. Handles tenant creation, DB switching, context management, and multi-tenancy debugging. |

**When to Use:**
- Creating **new tenants** programmatically
- Debugging **"Table not found"** errors (tenancy context not initialized)
- Running code **inside tenant context** (queries, jobs, commands)
- Querying **central data from within tenant context** (`tenancy()->central()`)
- Fixing **queue jobs** that lose tenant context
- Managing **tenant migrations** (run, rollback, seed)
- Understanding **bootstrappers** (Database, Cache, Filesystem, Queue)

**How to Use:**
```
Read AI_Brain/agents/tenancy-agent.md and follow its instructions.

I'm getting "SQLSTATE[42S02]: Base table or view not found: 1146 Table 'prime_db.std_students' doesn't exist"

This error happens when I try to access the student list from the tenant dashboard.
Help me debug and fix this.
```

**What It Provides:**
- Tenant creation code (Tenant::create + Domain + migrations)
- Three ways to run code in tenant context (initialize/end, $tenant->run(), tenancy()->central())
- Debugging checklist for tenancy errors (7 common issues)
- Migration management commands

**Critical Rules:**
- NEVER query central models (Plan, Module, Country) from tenant context without `tenancy()->central()`
- NEVER import `Modules\Prime\Models\*` in a tenant controller
- Queue jobs MUST run within tenant context (QueueTenancyBootstrapper)

---

### 11. Testing Specialist

| Field | Detail |
|-------|--------|
| **Agent Name** | Testing Specialist |
| **File** | `AI_Brain/agents/test-agent.md` |
| **Role** | Writes Pest 4.x tests for the multi-tenant Laravel application. Handles unit tests, feature tests, and tenant-scoped tests. |

**When to Use:**
- Writing **unit tests** (pure logic, no DB, no HTTP)
- Writing **feature tests** for central routes (auth, billing, admin)
- Writing **tenant feature tests** (school operations within tenant context)
- Testing **both success and failure paths**
- **Mocking** external services (Razorpay, email, SMS)

**How to Use:**
```
Read AI_Brain/agents/test-agent.md and follow its instructions.

Write Pest tests for the HPC LearningOutcomesController:
1. index returns 200 for authorized user
2. index returns 403 for unauthorized user
3. store creates a record with valid data
4. store returns 422 with invalid data
5. destroy soft-deletes the record
6. restore restores a soft-deleted record

Module: Hpc
Table: hpc_learning_outcomes
```

**What It Produces:**
- Pest 4.x test files using `it()` or `test()` syntax (NOT PHPUnit classes)
- Tests for success and failure paths
- Proper mocking of external services
- Database assertions with prefixed table names (`hpc_learning_outcomes`, not `learning_outcomes`)

**3 Test Types:**
| Type | Base Class | When |
|------|-----------|------|
| Unit | None | Pure logic, no DB/HTTP |
| Central Feature | `Tests\TestCase` | Central routes (admin panel) |
| Tenant Feature | `Tests\TenantTestCase` | School routes (within tenant context) |

---

### 12. Debugger

| Field | Detail |
|-------|--------|
| **Agent Name** | Debugger |
| **File** | `AI_Brain/agents/debugger.md` |
| **Role** | Investigates and fixes bugs in the multi-tenant Laravel application. Specializes in tenancy-related issues, route problems, and database errors. |

**When to Use:**
- Investigating **runtime errors** (500 errors, class not found, table not found)
- Debugging **tenancy context issues** (wrong DB, wrong data, tenant not initialized)
- Fixing **route conflicts** (wrong controller, shadowed routes)
- Investigating **queue job failures** (jobs that lose tenant context)
- Diagnosing **performance issues** (slow queries, N+1 problems)
- Debugging **authentication/authorization** failures (wrong permission string, wrong policy)

**How to Use:**
```
Read AI_Brain/agents/debugger.md and follow its instructions.

I'm getting this error when I visit /hpc/learning-outcomes:

"SQLSTATE[42S02]: Base table or view not found: 1146 Table 'prime_db.hpc_learning_outcomes' doesn't exist"

The route is registered in routes/tenant.php.
The model has $table = 'hpc_learning_outcomes'.
The tenant database has this table.
```

**What It Provides:**
- 7 common multi-tenant bug patterns with symptoms and fixes
- Step-by-step debugging workflow (Reproduce → Isolate → Check Context → Fix → Document)
- Useful debug commands (logs, tinker, route:list, DB context check)
- Instructions to document the fix in AI Brain after resolution

---

## Agent Selection Quick Reference

| I Want To... | Use This Agent |
|-------------|---------------|
| Start a new module from an idea | **Business Analyst** |
| Create a detailed feature specification | **Business Analyst** |
| Design database tables | **Database Architect** |
| Create a new module folder structure | **Module Specialist** |
| Write controllers, models, routes | **Backend Developer** |
| Create Blade views and forms | **Frontend Developer** |
| Build a complete feature end-to-end | **Developer** (General) |
| Build REST API endpoints | **API Builder** |
| Write Pest tests | **Testing Specialist** |
| Fix a bug or error | **Debugger** |
| Understand school business rules | **School Domain Expert** |
| Debug tenancy/multi-tenant issues | **Tenancy Specialist** |
| Set up CI/CD or deploy to cloud | **DevOps & Deployment Engineer** |

---

## Agent Combinations — Common Workflows

### Building a New Module from Scratch (5-Day Workflow)

```
Day 1: Business Analyst    → RBS + Feature Specification
Day 2: Database Architect  → DDL + Migrations
Day 2: Module Specialist   → Module scaffold + Models
Day 3: Backend Developer   → Controllers + FormRequests + Routes
Day 3: Frontend Developer  → Views (index, create, edit)
Day 4: Backend Developer   → Security hardening + Permission seeder
Day 4: Testing Specialist  → Unit + Feature tests
Day 5: DevOps Engineer     → Deploy + verify in staging
```

### Fixing Security Issues Across a Module

```
Step 1: Backend Developer  → Add Gate::authorize() to all methods
Step 2: Backend Developer  → Replace $request->all() with $request->validated()
Step 3: Backend Developer  → Add EnsureTenantHasModule middleware
Step 4: Testing Specialist → Write auth tests (403 for unauthorized)
```

### Debugging a Production Issue

```
Step 1: Debugger           → Investigate error, identify root cause
Step 2: Tenancy Specialist → If it's a tenancy context issue
Step 3: Backend Developer  → Implement the fix
Step 4: Testing Specialist → Write regression test
Step 5: DevOps Engineer    → Deploy the fix
```

---

## Tips for Best Results

1. **Always tell Claude which agent file to read** — don't assume it knows the agent's rules.
2. **Provide context:** module name, table prefix, entity names, field lists.
3. **Reference existing similar code:** "Follow the same pattern as Transport/VehicleController."
4. **One agent per task** — don't mix Business Analyst work with coding in the same prompt.
5. **Use the Business Analyst FIRST** for new features — it saves rework by catching gaps early.
6. **Always end backend work with the Testing Specialist** — write tests while the code is fresh.
7. **After any major work, ask Claude to update the AI Brain** — keeps the knowledge base current.
