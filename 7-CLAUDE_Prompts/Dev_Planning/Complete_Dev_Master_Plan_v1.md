# PRIME-AI — Complete Development Master Plan

### Academic Intelligence Platform | From Requirements to Production Deployment

**RBS → Documentation → Architecture → Code → Testing → Deployment**

PrimeGurukul | Confidential | March 2026

---

## Table of Contents

1. [Executive Overview](#1-executive-overview)
2. [Phase 1: Requirements & Platform Architecture](#phase-1-requirements--platform-architecture)
3. [Phase 2: Module Design (Per Module)](#phase-2-module-design-repeat-per-module)
4. [Phase 3: Backend Development (Per Module)](#phase-3-backend-development-repeat-per-module)
5. [Phase 4: Frontend Development (Per Module)](#phase-4-frontend-development-repeat-per-module)
6. [Phase 5: Testing & Quality Assurance (Per Module)](#phase-5-testing--quality-assurance-repeat-per-module)
7. [Phase 6: Module Documentation (Per Module)](#phase-6-module-documentation-repeat-per-module)
8. [Phase 7: Integration, Deployment & Operations](#phase-7-integration-deployment--operations)
9. [Quick Reference: Input-Output Chaining Map](#quick-reference-inputoutput-chaining-map)
10. [Execution Workflow Summary](#execution-workflow-summary)

---

## 1. Executive Overview

This document is the single master plan for building **Prime-AI** from your Requirements Breakdown Structure (RBS) through to a production-deployed, tested, documented platform. It covers every phase of the software development lifecycle and is designed so that each phase's output becomes the input for the next phase.

The plan is structured as a **7-phase pipeline with 33 discrete steps**. Each step specifies exactly what to ask Claude, what files to provide as input, and what output to expect. The outputs are not just documents — they include **working Laravel code, database migrations, API implementations, frontend components, test suites, and deployment configurations**.

### How This Pipeline Works

**Input Chaining:** Every step lists its required inputs (files from previous steps) and its outputs. You upload the inputs to Claude, give the prompt, and save the output. That output then becomes input for downstream steps.

**Module-by-Module Execution:** After Phase 1 (which is done once for the whole platform), Phases 2–6 are executed per module. Start with Student Management (the most depended-upon module), complete the full pipeline, then move to the next module.

**Iterative Refinement:** Each step can be re-run with corrections. If testing reveals a bug, you feed the test failure back into the code generation step.

### Technology Stack Reference

| Layer | Technology | Notes |
|-------|-----------|-------|
| Backend | PHP 8.2+ / Laravel 11 | Multi-tenant with tenant_db / global_db |
| Database | MySQL 8.0+ | One DB per tenant + one global DB |
| Frontend | Blade + Livewire / Alpine.js | Progressive enhancement, AJAX-heavy |
| CSS | Tailwind CSS | Utility-first, component library |
| API | RESTful JSON API | Versioned, role-gated, rate-limited |
| Auth | Laravel Sanctum / Spatie Permissions | RBAC with 12+ role types |
| Queue | Redis + Laravel Horizon | Background jobs, notifications |
| AI/ML | Python microservices / Laravel bridge | Recommendation engine, analytics |
| DevOps | Docker + CI/CD | Automated testing and deployment |

### Module Build Order

Based on dependency analysis, modules should be built in this sequence:

| Priority | Module Group | Reason |
|----------|-------------|--------|
| P0 — Foundation | Tenant Core, Auth, RBAC, Academic Session, Config | Everything depends on these |
| P1 — Core ERP | Staff Mgmt, Student Mgmt, Class/Section, Subjects | User entities all modules reference |
| P2 — Daily Ops | Attendance, Timetable, Communication | High daily usage, feeds analytics |
| P3 — Finance | Fees, Payroll, Accounting, Inventory | Revenue-critical modules |
| P4 — Services | Transport, Hostel, Library, Visitor/Reception | Operational modules |
| P5 — LMS | Question Bank, Homework, Online Exam, Syllabus | Teaching and assessment |
| P6 — LXP | Learning Paths, HPC, AI Analytics, Recommendations | Requires data from P2–P5 |
| P7 — Cross-cutting | Reports, Dashboards, Complaints, Audit Logs | Aggregation across all modules |

---

## PHASE 1: Requirements & Platform Architecture

> **Scope:** Execute once for the entire platform. Transforms your RBS into structured specifications and establishes the architectural foundation.

---

### Step 1.1: Software Requirements Specification (SRS)

| Parameter | Detail |
|-----------|--------|
| **Input** | Your RBS document (Excel/PDF) |
| **Output** | SRS document (Markdown, ~50–100 pages) |
| **Format** | One SRS covering all modules, organized by module |

#### What to Ask Claude

Upload your RBS and prompt:

> *"Convert this RBS into a full Software Requirements Specification. For each module, generate: (a) functional requirements with unique IDs like FR-STU-001, (b) non-functional requirements, (c) user stories in 'As a [role], I want [action], so that [benefit]' format for each role that interacts with the module, (d) acceptance criteria for each user story, (e) business rules, (f) NEP 2020 / CBSE compliance requirements where applicable. Use the module groupings from the RBS. Include a traceability matrix mapping each requirement back to the RBS line item."*

#### Key Content to Ensure

- Unique requirement IDs that will be referenced in all downstream documents
- Multi-tenant requirements explicitly called out (tenant isolation, cross-tenant prohibition)
- Role matrix per module showing which of the 12+ roles can perform which actions
- Data volume assumptions (e.g., max students per tenant, concurrent users)

---

### Step 1.2: Module Dependency Map & Build Sequence

| Parameter | Detail |
|-----------|--------|
| **Input** | SRS document from Step 1.1 |
| **Output** | Dependency graph (Mermaid diagram) + ordered build sequence document |
| **Format** | Markdown with embedded Mermaid + priority table |

#### What to Ask Claude

Upload the SRS and prompt:

> *"Analyze all module dependencies in this SRS. Produce: (a) a Mermaid dependency graph showing which modules depend on which, (b) a topologically sorted build order with the rationale for each position, (c) identification of circular dependencies with resolution strategies, (d) a critical path analysis showing which modules block the most downstream work."*

#### Why This Matters

This determines the order you execute Phases 2–6. Building Fees before Student Management wastes time. Building HPC before Exam and Attendance produces a module with no data to analyze.

---

### Step 1.3: Data Dictionary & Domain Glossary

| Parameter | Detail |
|-----------|--------|
| **Input** | SRS document from Step 1.1 |
| **Output** | Data dictionary with every domain term, entity, and enumeration |
| **Format** | Markdown table or spreadsheet |

Upload the SRS and prompt Claude to extract every domain term (tenant, academic_session, section, house, HPC dimension, SCORM package, Bloom's level, etc.) with precise definitions, valid values, and relationships. This prevents ambiguity in all downstream artifacts.

---

### Step 1.4: System Architecture Document (SAD)

| Parameter | Detail |
|-----------|--------|
| **Input** | SRS + Dependency Map + Data Dictionary |
| **Output** | Architecture document with diagrams |
| **Format** | Markdown with Mermaid diagrams |

#### What to Ask Claude

Upload all three prior documents and prompt:

> *"Design the system architecture for Prime-AI covering: (a) multi-tenant architecture — global_db vs tenant_db schemas, tenant resolution middleware, connection switching; (b) application layer architecture — Laravel service pattern, repository pattern, event-driven design; (c) API architecture — versioning, authentication, rate limiting, pagination; (d) caching strategy — Redis, query cache, tenant-scoped cache keys; (e) queue architecture — job types, failure handling, Horizon config; (f) file storage — tenant-isolated storage, S3-compatible; (g) security architecture — RBAC model, data encryption, audit logging; (h) deployment architecture — containerization, load balancing, database-per-tenant scaling."*

---

### Step 1.5: Coding Standards & Project Conventions

| Parameter | Detail |
|-----------|--------|
| **Input** | System Architecture Document from Step 1.4 |
| **Output** | Coding standards document + Laravel project scaffold |
| **Format** | Markdown + generated boilerplate code |

#### What to Ask Claude

> *"Based on this architecture, create a comprehensive coding standards document for Prime-AI covering: naming conventions (models, controllers, services, traits, migrations, routes, API endpoints), folder structure, tenant context handling patterns, API response envelope format, error code registry, validation pattern, event naming conventions, and a base service class template. Also generate the Laravel project skeleton with base classes, middleware, traits, and config files."*

#### Outputs to Save

- `coding-standards.md` — referenced by every developer and every Claude prompt going forward
- Base class files: `BaseService.php`, `BaseController.php`, `ApiResponse` trait, `TenantScope` trait
- Middleware: `TenantResolver`, `RoleGate`, `AuditLog`
- `.editorconfig`, `phpstan.neon`, `pint.json` for code quality enforcement

---

## PHASE 2: Module Design (Repeat Per Module)

> **Scope:** From this phase onward, you execute the pipeline for one module at a time. Complete all phases (2–6) for one module before starting the next. This ensures each module is fully functional and tested before building modules that depend on it.

---

### Step 2.1: Entity-Relationship Diagram (ERD)

| Parameter | Detail |
|-----------|--------|
| **Input** | Module's SRS section + Data Dictionary + Architecture Doc (DB patterns) |
| **Output** | Complete ERD with all tables, columns, types, relationships |
| **Format** | Mermaid ER diagram + detailed table specification in Markdown |

#### What to Ask Claude

Upload the three input documents and prompt:

> *"Design the complete database schema for the [Module Name] module. Include: (a) Mermaid ER diagram, (b) detailed table spec with column name, data type, nullable, default, index, foreign key for every column, (c) tenant isolation pattern (tenant_id column + scoping), (d) soft deletes where appropriate, (e) audit columns (created_by, updated_by), (f) indexes for expected query patterns from the SRS, (g) enum/lookup tables with seed values, (h) cross-module foreign keys to already-built modules."*

#### Quality Checks

- Every foreign key references either global_db or current tenant_db tables
- No direct cross-tenant references exist
- Indexes cover the WHERE clauses implied by the SRS user stories
- Soft deletes are used for user-facing data, hard deletes for system logs

---

### Step 2.2: API Specification (OpenAPI)

| Parameter | Detail |
|-----------|--------|
| **Input** | Module's SRS section + ERD from Step 2.1 + Coding Standards |
| **Output** | Complete API spec in OpenAPI 3.0 format |
| **Format** | YAML file + Markdown summary |

#### What to Ask Claude

> *"Create an OpenAPI 3.0 specification for the [Module Name] module's REST API. For every endpoint include: HTTP method, URL pattern following our conventions, request body schema (JSON), response schema with our standard envelope format, query parameters for filtering/sorting/pagination, required authentication and role permissions, validation rules matching our SRS acceptance criteria, error responses with codes from our error registry, and example request/response pairs."*

#### Standard Endpoints Per Resource

- `GET /api/v1/{resource}` — List with filters, sorting, pagination
- `POST /api/v1/{resource}` — Create
- `GET /api/v1/{resource}/{id}` — Show with relationships
- `PUT /api/v1/{resource}/{id}` — Update
- `DELETE /api/v1/{resource}/{id}` — Soft delete
- Plus module-specific action endpoints (e.g., `POST /api/v1/fees/{id}/pay`)

---

### Step 2.3: UI/UX Wireframes & Screen Specifications

| Parameter | Detail |
|-----------|--------|
| **Input** | Module's SRS + API Spec + Role Matrix |
| **Output** | Screen inventory, wireframe descriptions, component specs |
| **Format** | Markdown + optional HTML/React wireframe artifacts |

#### What to Ask Claude

> *"Design the UI screens for [Module Name]. For each screen provide: (a) screen name and URL route, (b) which roles can access it, (c) layout description (columns, cards, tables, forms), (d) every form field with type, validation, and data source, (e) table columns with sort/filter capabilities, (f) action buttons and what API endpoint each triggers, (g) navigation flow between screens, (h) dashboard widgets this module contributes to role-based dashboards. Optionally generate a Tailwind/Blade wireframe."*

---

## PHASE 3: Backend Development (Repeat Per Module)

> **Scope:** This is where specifications become working Laravel code. Each step produces actual files you commit to your repository.

---

### Step 3.1: Database Migrations

| Parameter | Detail |
|-----------|--------|
| **Input** | ERD from Step 2.1 + Coding Standards |
| **Output** | Laravel migration files for every table in the module |
| **Format** | PHP files (`database/migrations/`) |

#### What to Ask Claude

Upload the ERD and coding standards. Prompt:

> *"Generate Laravel migration files for every table in the [Module Name] ERD. Follow our coding standards for: naming conventions, tenant_id handling, index naming, foreign key constraints with cascading rules, soft deletes, audit columns (created_by, updated_by as unsignedBigInteger nullable), and timestamps. Include a seeder file with realistic Indian school data (Indian names, CBSE/ICSE boards, Indian phone formats, INR currency values)."*

#### Files Generated

- `database/migrations/YYYY_MM_DD_HHMMSS_create_{table}_table.php` (one per table)
- `database/seeders/{Module}Seeder.php`
- `database/factories/{Model}Factory.php` (for testing)

---

### Step 3.2: Eloquent Models

| Parameter | Detail |
|-----------|--------|
| **Input** | ERD + Migration files from Step 3.1 + Coding Standards |
| **Output** | Laravel Eloquent model classes |
| **Format** | PHP files (`app/Models/`) |

#### What to Ask Claude

> *"Generate Eloquent models for every table in [Module Name]. Each model must include: (a) $fillable array matching migration columns, (b) $casts for dates, booleans, decimals, JSON columns, (c) all relationships (belongsTo, hasMany, belongsToMany, morphMany) matching the ERD, (d) TenantScope global scope for tenant isolation, (e) scopes for common query patterns from the SRS (e.g., scopeActive, scopeByAcademicSession), (f) accessors/mutators where business logic requires transformation, (g) boot method with creating/updating events for audit columns, (h) PHPDoc blocks for IDE autocompletion."*

---

### Step 3.3: Form Requests (Validation)

| Parameter | Detail |
|-----------|--------|
| **Input** | API Spec from Step 2.2 + Models from Step 3.2 |
| **Output** | Laravel FormRequest classes for every API endpoint |
| **Format** | PHP files (`app/Http/Requests/`) |

Prompt Claude to generate FormRequest classes with: validation rules matching the API spec, custom error messages in English, authorization method checking role permissions, conditional rules (e.g., `required_if`, `required_without`), custom validation rules for domain-specific logic (e.g., fee amount must not exceed configured maximum), and `prepareForValidation()` for data sanitization.

---

### Step 3.4: Service Classes (Business Logic)

| Parameter | Detail |
|-----------|--------|
| **Input** | SRS (business rules) + API Spec + Models + Coding Standards |
| **Output** | Service classes encapsulating all business logic |
| **Format** | PHP files (`app/Services/`) |

#### What to Ask Claude

> *"Generate service classes for [Module Name] following our architecture pattern (thin controllers, fat services). Each service must: (a) extend BaseService, (b) handle all business logic from the SRS business rules, (c) use database transactions for multi-step operations, (d) fire domain events (e.g., StudentEnrolled, FeePaymentReceived), (e) return DTOs or arrays (never Eloquent models) from public methods, (f) include comprehensive PHPDoc with @throws annotations, (g) implement logging for critical operations, (h) handle edge cases documented in the SRS acceptance criteria."*

#### Architecture Pattern

- **Controller** → calls Service method with validated data
- **Service** → orchestrates Models, fires Events, returns result
- **Service** → never accesses Request object directly (receives array from Controller)
- **Service** → wraps multi-model operations in `DB::transaction()`

---

### Step 3.5: Controllers & API Routes

| Parameter | Detail |
|-----------|--------|
| **Input** | API Spec + Service Classes + Form Requests + Coding Standards |
| **Output** | Controller classes + route definitions |
| **Format** | PHP files (`app/Http/Controllers/`, `routes/api.php`) |

#### What to Ask Claude

> *"Generate API controllers for [Module Name]. Each controller must: (a) use constructor injection for the service class, (b) type-hint FormRequest for validation, (c) return JSON responses using our ApiResponse trait with correct HTTP status codes, (d) include Spatie Permission middleware annotations, (e) handle pagination with configurable page size, (f) support includes/relationships via query parameters, (g) implement resource transformers (API Resources) for response shaping. Also generate the route file with proper grouping, middleware, and versioning prefix."*

#### Files Generated

- `app/Http/Controllers/Api/V1/{Module}Controller.php`
- `app/Http/Resources/{Model}Resource.php` and `{Model}Collection.php`
- `routes/api/v1/{module}.php`
- `app/Policies/{Model}Policy.php`

---

### Step 3.6: Events, Listeners & Notifications

| Parameter | Detail |
|-----------|--------|
| **Input** | SRS (notification requirements) + Service Classes (events fired) |
| **Output** | Event classes, Listener classes, Notification classes |
| **Format** | PHP files (`app/Events/`, `app/Listeners/`, `app/Notifications/`) |

Prompt Claude to generate the event-driven layer: event classes carrying the relevant data, listeners that react to events (e.g., send notification when fee is paid, update analytics when attendance is marked), notification classes with SMS, email, and in-app database channels, and the EventServiceProvider registration.

---

### Step 3.7: Queue Jobs & Scheduled Tasks

| Parameter | Detail |
|-----------|--------|
| **Input** | SRS (background processing needs) + Architecture Doc (queue config) |
| **Output** | Job classes + Kernel schedule configuration |
| **Format** | PHP files (`app/Jobs/`, `app/Console/Kernel.php`) |

Generate queued jobs for heavy operations: bulk SMS dispatch, report PDF generation, fee reminder scheduling, attendance aggregation, timetable auto-generation solver, and data export jobs. Include retry logic, failure handling, and rate limiting.

---

## PHASE 4: Frontend Development (Repeat Per Module)

> **Scope:** Frontend development uses the API spec and wireframes as input and produces Blade templates, Livewire components, and Alpine.js interactions.

---

### Step 4.1: Blade Layout & Component Templates

| Parameter | Detail |
|-----------|--------|
| **Input** | UI/UX Wireframes (Step 2.3) + Coding Standards |
| **Output** | Blade template files for all screens in the module |
| **Format** | Blade files (`resources/views/`) |

#### What to Ask Claude

> *"Generate Blade templates for [Module Name] screens. Use: (a) Tailwind CSS for all styling (no custom CSS unless essential), (b) our master layout extending app.blade.php with sidebar navigation, (c) reusable Blade components for tables (sortable, filterable), forms, modals, cards, stats widgets, (d) responsive design (mobile-first), (e) Alpine.js for client-side interactivity (dropdowns, toggles, confirmations), (f) Livewire for dynamic server interactions (search, filter, inline edit), (g) proper ARIA labels and semantic HTML for accessibility, (h) RTL-ready structure for future Urdu/Hindi support."*

#### Screen Types to Generate

- List/Index view with DataTable (search, filter, sort, paginate, bulk actions)
- Create/Edit form with validation feedback
- Detail/Show view with related data tabs
- Dashboard widgets for this module
- Print-friendly views (report cards, fee receipts, ID cards)

---

### Step 4.2: Livewire Components

| Parameter | Detail |
|-----------|--------|
| **Input** | Blade templates (Step 4.1) + API endpoints + Service classes |
| **Output** | Livewire component classes + updated Blade views |
| **Format** | PHP + Blade files (`app/Http/Livewire/`, `resources/views/livewire/`) |

Prompt Claude to build Livewire components for dynamic behaviors: real-time search and filtering on list pages, dependent dropdown cascades (Board → Class → Section → Subject), inline editing for quick updates, modal forms for create/edit without page reload, file upload with progress, and drag-drop interfaces (e.g., timetable manual editing).

---

### Step 4.3: JavaScript & Alpine.js Interactions

| Parameter | Detail |
|-----------|--------|
| **Input** | Blade templates + API spec for AJAX endpoints |
| **Output** | Alpine.js components + utility JavaScript |
| **Format** | JS files (`resources/js/`) |

Generate Alpine.js components for client-side logic: form validation with real-time feedback, confirmation dialogs, notification toasts, print handlers, chart initialization (Chart.js for dashboards), calendar widgets (attendance, timetable views), and data export triggers (CSV/PDF download).

---

### Step 4.4: Role-Based Dashboard Widgets

| Parameter | Detail |
|-----------|--------|
| **Input** | SRS dashboard requirements + All module controllers built so far |
| **Output** | Dashboard widget components with API data sources |
| **Format** | Blade + Livewire + JS chart components |

For each role (Management, Principal, Teacher, Accountant, etc.), generate the dashboard widgets that this module contributes. Examples: Attendance module contributes an attendance percentage widget to the Principal dashboard and a "mark attendance" quick-action to the Teacher dashboard. Each widget should be a self-contained Livewire component with its own data query.

---

## PHASE 5: Testing & Quality Assurance (Repeat Per Module)

> **Scope:** Every module gets a full test suite before moving to the next module. Tests are written after code, but test cases are derived from the SRS acceptance criteria (Phase 1).

---

### Step 5.1: Unit Tests

| Parameter | Detail |
|-----------|--------|
| **Input** | Service classes (Step 3.4) + Models (Step 3.2) + SRS business rules |
| **Output** | PHPUnit test classes for services and models |
| **Format** | PHP files (`tests/Unit/`) |

#### What to Ask Claude

Upload service classes and SRS section. Prompt:

> *"Generate PHPUnit unit tests for [Module Name] service classes. Test every public method with: (a) happy path tests, (b) validation boundary tests, (c) business rule enforcement tests matching SRS acceptance criteria, (d) edge cases (empty data, maximum values, concurrent operations), (e) mock external dependencies (other services, event dispatcher), (f) data provider methods for parameterized tests. Use factories for test data. Ensure tenant isolation by testing that operations never leak across tenants."*

#### Test Categories

- **Model relationship tests** — verify all relationships return correct types
- **Model scope tests** — verify scopeActive, scopeBySession, etc. filter correctly
- **Service logic tests** — verify business rules from SRS
- **Tenant isolation tests** — verify Tenant A cannot access Tenant B data

---

### Step 5.2: Feature / Integration Tests

| Parameter | Detail |
|-----------|--------|
| **Input** | API Spec (Step 2.2) + Controllers (Step 3.5) + SRS acceptance criteria |
| **Output** | PHPUnit feature tests for API endpoints |
| **Format** | PHP files (`tests/Feature/`) |

#### What to Ask Claude

> *"Generate feature tests for every API endpoint in [Module Name]. Each test class must: (a) test full HTTP request/response cycle (actingAs authenticated user), (b) test RBAC — verify each role gets correct access/denial, (c) test validation — send invalid data and verify 422 responses, (d) test pagination, sorting, and filtering, (e) test cascading effects (e.g., deleting a student cascades to attendance records), (f) test tenant isolation at the HTTP level (User from Tenant A cannot access Tenant B endpoints), (g) use RefreshDatabase trait and factories, (h) verify response structure matches our API envelope format."*

---

### Step 5.3: Browser / E2E Tests

| Parameter | Detail |
|-----------|--------|
| **Input** | UI/UX Wireframes (Step 2.3) + Blade/Livewire components (Phase 4) |
| **Output** | Laravel Dusk test classes |
| **Format** | PHP files (`tests/Browser/`) |

Generate Dusk tests for critical user flows: login → navigate to module → perform CRUD operations → verify UI state. Focus on role-based flows (e.g., Teacher logging in sees only their classes). Include tests for Livewire interactions, modal workflows, and print views.

---

### Step 5.4: Bug Fixing Loop

| Parameter | Detail |
|-----------|--------|
| **Input** | Test failure output + relevant source code file |
| **Output** | Fixed code files |
| **Format** | Updated PHP/Blade/JS files |

#### How to Use Claude for Bug Fixing

This is an iterative loop. Run your tests, and for each failure:

- Copy the full test failure output (including stack trace)
- Upload the failing test file + the source file it tests
- Prompt: *"Here is a test failure. The test file is [X], the source file is [Y]. Analyze the failure, identify the root cause, and provide the corrected code. Explain what was wrong and why the fix resolves it."*
- Apply the fix, re-run the test, repeat if needed

#### Systematic Debugging Prompts

- *"This migration fails with [error]. Here is the migration file and the DB state. Fix it."*
- *"This API endpoint returns 500. Here are the controller, service, and the error log. Diagnose and fix."*
- *"This Livewire component shows stale data after an action. Here is the component class and Blade view. Fix the reactivity issue."*
- *"Tenant A can see Tenant B's records through this endpoint. Here is the controller and model. Fix the tenant isolation."*

---

### Step 5.5: Code Review & Refactoring

| Parameter | Detail |
|-----------|--------|
| **Input** | All module code from Phases 3–4 + Coding Standards |
| **Output** | Refactored code + review report |
| **Format** | Updated PHP files + Markdown review document |

After all tests pass, upload the complete module code to Claude for review. Prompt:

> *"Review this Laravel module code for: (a) coding standards compliance, (b) security vulnerabilities (SQL injection, mass assignment, IDOR), (c) performance issues (N+1 queries, missing indexes, unoptimized queries), (d) tenant isolation completeness, (e) error handling gaps, (f) dead code, (g) naming consistency, (h) opportunity for design pattern improvements. Provide a review report and refactored files."*

---

## PHASE 6: Module Documentation (Repeat Per Module)

> **Scope:** Documentation is generated after code is stable and tested. Each module gets three documentation deliverables.

---

### Step 6.1: API Documentation

| Parameter | Detail |
|-----------|--------|
| **Input** | Final API Spec (Step 2.2, updated during development) + Controllers |
| **Output** | Developer-facing API documentation |
| **Format** | OpenAPI YAML + Markdown guide with examples |

Upload the final controllers and route files. Prompt Claude to generate updated OpenAPI documentation reflecting any changes made during development, with curl examples, Postman collection export, authentication setup guide, error code reference, and webhook/event documentation.

---

### Step 6.2: Technical Documentation

| Parameter | Detail |
|-----------|--------|
| **Input** | All module source code + ERD + Architecture Doc |
| **Output** | Technical reference for developers |
| **Format** | Markdown (`docs/technical/`) |

Generate: module architecture overview, class diagrams, database schema documentation with migration guide, service class method reference, event/listener map, queue job documentation, configuration options, and troubleshooting guide.

---

### Step 6.3: User Manual (Role-Based)

| Parameter | Detail |
|-----------|--------|
| **Input** | UI/UX Wireframes + SRS user stories + final Blade templates |
| **Output** | End-user documentation per role |
| **Format** | Markdown or HTML (`docs/user-guide/`) |

For each role that uses this module, generate a user guide with: step-by-step instructions with screen references, common workflow walkthroughs, FAQ section, and troubleshooting steps. Write in simple English suitable for school administrators who may not be tech-savvy.

---

## PHASE 7: Integration, Deployment & Operations

> **Scope:** This phase is executed after all (or a significant group of) modules are complete. It covers cross-module integration, deployment infrastructure, and operational readiness.

---

### Step 7.1: Cross-Module Integration Testing

| Parameter | Detail |
|-----------|--------|
| **Input** | All completed modules + SRS cross-module requirements |
| **Output** | Integration test suite + data flow verification report |
| **Format** | PHP test files + Markdown report |

Prompt Claude to generate tests that verify data flows correctly across modules: Student enrollment triggers fee structure assignment; Attendance data feeds into HPC calculations; Exam scores flow from LMS into LXP analytics; Timetable references Staff, Subject, and Classroom from their respective modules.

---

### Step 7.2: Performance Testing & Optimization

| Parameter | Detail |
|-----------|--------|
| **Input** | Complete codebase + SRS performance requirements |
| **Output** | Performance test scripts + optimization recommendations + updated code |
| **Format** | Artillery/k6 test configs + Markdown report + optimized PHP files |

Generate load test configurations simulating realistic usage: 500 concurrent users across 10 tenants, peak login times, bulk attendance marking, fee payment spikes. Have Claude analyze slow queries and generate database index optimizations, eager loading fixes, and caching layer implementation.

---

### Step 7.3: Security Audit

| Parameter | Detail |
|-----------|--------|
| **Input** | Complete codebase + Architecture Doc |
| **Output** | Security audit report + fixed code |
| **Format** | Markdown report + updated PHP files |

Upload the full codebase module by module. Prompt:

> *"Perform a security audit on this code. Check for: SQL injection, XSS, CSRF, mass assignment, IDOR (especially cross-tenant access), insecure file uploads, sensitive data exposure in API responses, missing rate limiting, broken authentication, and privilege escalation paths. Provide OWASP-categorized findings with severity levels and fixed code."*

---

### Step 7.4: DevOps & CI/CD Pipeline

| Parameter | Detail |
|-----------|--------|
| **Input** | Architecture Doc + Technology Stack |
| **Output** | Docker configs, CI/CD pipeline definitions, environment configs |
| **Format** | Dockerfile, docker-compose.yml, GitHub Actions / GitLab CI YAML, .env templates |

#### What to Ask Claude

> *"Generate the complete DevOps setup for Prime-AI: (a) Dockerfile and docker-compose.yml for local development (PHP-FPM, Nginx, MySQL, Redis, Horizon, Mailpit), (b) CI/CD pipeline that runs PHPStan, Pint, PHPUnit tests, builds assets, and deploys, (c) staging and production environment configurations, (d) tenant database provisioning automation script, (e) database backup and restore scripts with tenant isolation, (f) SSL/TLS configuration, (g) Horizon supervisor configuration."*

---

### Step 7.5: Deployment Plan & Runbook

| Parameter | Detail |
|-----------|--------|
| **Input** | CI/CD Pipeline (Step 7.4) + Sprint Plan (Phase 1) |
| **Output** | Deployment checklist, rollback procedures, tenant onboarding runbook |
| **Format** | Markdown operational documents |

Generate: pre-deployment checklist (migrations verified, assets built, cache cleared), deployment step-by-step for both initial launch and subsequent updates, rollback procedure with database migration rollback, new tenant onboarding script (create DB, run migrations, seed default data, create admin user), and data migration guide for schools moving from legacy systems.

---

### Step 7.6: Monitoring & Maintenance

| Parameter | Detail |
|-----------|--------|
| **Input** | Architecture Doc + Deployment Config |
| **Output** | Monitoring configuration + maintenance playbook |
| **Format** | Config files + Markdown playbook |

Generate: Laravel Telescope configuration for development debugging, error tracking setup (Sentry/Flare integration), health check endpoint implementation, database monitoring queries (slow query log, table size tracking per tenant), queue monitoring alerts (failed jobs, backed-up queues), uptime monitoring configuration, and scheduled maintenance playbook (cache clearing, log rotation, temporary file cleanup).

---

### Step 7.7: Platform Documentation

| Parameter | Detail |
|-----------|--------|
| **Input** | All technical docs from Phase 6 + DevOps configs |
| **Output** | Platform-level documentation |
| **Format** | Markdown (`docs/`) |

Generate the overarching documentation: system administration guide (server setup, scaling, backup), tenant management guide (onboarding, configuration, data export), platform API documentation (aggregating all module APIs), developer onboarding guide (setting up local environment, running tests, code contribution workflow), and release notes template.

---

## Quick Reference: Input-Output Chaining Map

This table shows exactly which outputs feed into which steps. When you start a step, upload only the files listed in the Input column.

| Step | Input (Upload These) | Output (Save This) |
|------|---------------------|-------------------|
| **1.1** SRS | RBS (your file) | SRS document |
| **1.2** Dependency Map | SRS | Dependency graph + build order |
| **1.3** Data Dictionary | SRS | Domain glossary |
| **1.4** Architecture | SRS + 1.2 + 1.3 | SAD document |
| **1.5** Coding Standards | SAD | Standards doc + base code |
| **2.1** ERD | SRS (module) + 1.3 + 1.4 | ERD + table specs |
| **2.2** API Spec | SRS (module) + 2.1 + 1.5 | OpenAPI YAML |
| **2.3** UI/UX | SRS (module) + 2.2 | Screen specs + wireframes |
| **3.1** Migrations | 2.1 + 1.5 | Migration PHP files |
| **3.2** Models | 2.1 + 3.1 + 1.5 | Model PHP files |
| **3.3** Form Requests | 2.2 + 3.2 | FormRequest PHP files |
| **3.4** Services | SRS (rules) + 2.2 + 3.2 + 1.5 | Service PHP files |
| **3.5** Controllers | 2.2 + 3.3 + 3.4 + 1.5 | Controller + Route files |
| **3.6** Events | SRS (notifications) + 3.4 | Event/Listener/Notification files |
| **3.7** Jobs | SRS + 1.4 | Job + Scheduler files |
| **4.1** Blade Templates | 2.3 + 1.5 | Blade view files |
| **4.2** Livewire | 4.1 + 3.5 + 3.4 | Livewire component files |
| **4.3** Alpine.js | 4.1 + 2.2 | JS files |
| **4.4** Dashboard Widgets | SRS (dashboards) + 3.5 | Widget components |
| **5.1** Unit Tests | 3.4 + 3.2 + SRS | Test PHP files |
| **5.2** Feature Tests | 2.2 + 3.5 + SRS | Test PHP files |
| **5.3** Browser Tests | 2.3 + Phase 4 code | Dusk test files |
| **5.4** Bug Fixes | Test failures + source code | Fixed code files |
| **5.5** Code Review | All module code + 1.5 | Refactored code |
| **6.1** API Docs | Final 2.2 + 3.5 | OpenAPI + Markdown |
| **6.2** Tech Docs | All code + 2.1 + 1.4 | Markdown docs |
| **6.3** User Manual | 2.3 + SRS + Blade templates | User guide |
| **7.1** Integration Tests | All modules + SRS | Integration test files |
| **7.2** Perf Tests | Codebase + SRS (NFRs) | Test configs + optimized code |
| **7.3** Security Audit | Codebase + 1.4 | Audit report + fixes |
| **7.4** DevOps | 1.4 + Tech stack | Docker/CI-CD configs |
| **7.5** Deployment Plan | 7.4 + Sprint plan | Runbook + checklists |
| **7.6** Monitoring | 1.4 + 7.4 | Config files + playbook |
| **7.7** Platform Docs | All Phase 6 docs + 7.4 | Platform documentation |

---

## Execution Workflow Summary

### One-Time Setup (Weeks 1–2)

Execute Phase 1 (Steps 1.1 through 1.5) once. These establish the foundation that all module development builds upon. Save every output file in a dedicated `/docs/foundation/` directory.

### Per-Module Cycle (Weeks 3+)

For each module in build-order sequence:

| Day | Activity | Steps |
|-----|---------|-------|
| Day 1 | Design: ERD + API Spec + UI/UX | 2.1, 2.2, 2.3 |
| Day 2–3 | Backend: Migrations through Jobs | 3.1 – 3.7 |
| Day 4–5 | Frontend: Blade, Livewire, Alpine, Widgets | 4.1 – 4.4 |
| Day 6–7 | Testing: Unit + Feature + Browser + Bug Fixes | 5.1 – 5.4 |
| Day 8 | Review + Documentation | 5.5, 6.1, 6.2, 6.3 |

**Estimated pace:** 1 simple module per 5–8 working days, 1 complex module (Timetable, Fees, HPC) per 10–15 working days. With 28 modules, plan for 6–8 months of active development.

### Integration & Launch (Final Weeks)

After all modules (or a viable release group) are complete, execute Phase 7 once. This covers integration testing, performance optimization, security hardening, and deployment setup. Plan 2–3 weeks for this phase.

### Tips for Maximum Efficiency with Claude

- **Keep a `/docs/` folder** mirroring this plan's structure. Every file Claude produces goes into the corresponding folder.
- **Start each Claude conversation** by uploading the coding standards document (Step 1.5). This ensures consistent code across all sessions.
- **For large modules**, split Phase 3 across multiple conversations — one for migrations+models, another for services+controllers.
- **Save Claude's outputs as files immediately.** Don't rely on conversation history for code.
- **When fixing bugs**, always upload both the test file and the source file. Context matters.
- **After completing each module**, upload the module's code to a new conversation for the code review step (5.5). Fresh context gives better review quality.

---

*Prime-AI Development Master Plan — PrimeGurukul — March 2026*
