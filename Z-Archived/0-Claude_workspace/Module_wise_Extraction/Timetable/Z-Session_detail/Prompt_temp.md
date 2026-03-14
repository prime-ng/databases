You are analyzing a Laravel-based timetable generation system.
Your task is to review and understand the implementation of the timetable generation pipeline.
Focus specifically on the following:
1. Controller
## File:
Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php
Pay special attention to the function:
generateWithFET()
2. Documentation
## Directory:
Apps/laravel/Modules/SmartTimetable/DOCS
Review all files and folders inside this directory to understand the latest architectural design, data flow, and solver logic of the timetable engine.

## Objectives:
1. Understand how generateWithFET() works within the overall timetable generation architecture.
2. Identify the data flow from:
    - requirement generation
    - activity creation
    - constraint processing
    - FET solver integration
3. Verify whether the controller implementation aligns with the documented architecture.
4. Identify potential issues such as:
    - inefficient queries
    - unnecessary loops
    - redundant data loading
    - architectural inconsistencies
5. Suggest improvements without changing existing function names, file structure, or core architecture.

## Constraints:
    - Do NOT rename functions, files, models, or variables.
    - Do NOT propose breaking changes to the architecture unless absolutely necessary.
    - Focus primarily on performance optimization, clarity, and maintainability.

## Expected Output:
Provide a detailed plan on the basis of your analysis which include but limited to the following structure:
1. High-Level Architecture Summary
    - How the timetable generation pipeline works.
2. generateWithFET() Deep Analysis
    - Step-by-step explanation of what the function does.
3. Data Flow Mapping
    - Requirements → Activities → Constraints → Solver → Timetable
4. Performance Observations
    - Potential bottlenecks.
5. Query Optimization Opportunities
    - Specific queries that could be improved.
6. Code Quality Improvements
    - Refactoring suggestions that keep the same structure.
7. Risk Areas
    - Parts of the system that could cause timetable generation failures.

Your goal should include to help improve the performance and robustness of the timetable generation system while keeping the existing design intact.

Store your understanding with detailed plan in the folder "2-Tenant_Modules/8-Smart_Timetable/Claude_Context"


--------------------------------------------------------------------------------------------------------

Please analyze the Activity model located at:
    - Modules/SmartTimetable/app/Models/Activity.php

This model represents the primary input entity for the timetable generator.

Currently, the timetable generator does not fully consider several constraints defined at the activity level when selecting slots. I have already given you reference of file which has List of Contraints "2-Tenant_Modules/8-Smart_Timetable/Input/5-Constraints_v1.csv".
These constraints include (but may not be limited to):
    - constraint_count
    - preferred_time_slots_json
    - avoid_time_slots_json

Room-related constraints:
    - required_room_type_id
    - required_room_id
    - requires_room
    - preferred_room_type_id
    - preferred_room_ids

Your Tasks
1. Analyze the Activity model
    - Identify all fields related to time-slot constraints and room constraints.
    - Verify their data types, casts, and expected data structure (especially JSON fields).
2. Understand how these fields should influence scheduling
    - Determine how preferred_time_slots_json and avoid_time_slots_json should affect slot evaluation.
    - Determine how room constraints (required_room_type_id, required_room_id, etc.) should affect room allocation during scheduling.
3. Review how the generator currently assigns slots
    - Identify where slot selection happens.
    - Determine why these activity-level constraints are currently ignored.
4. Design an approach to integrate these constraints
    - These should be treated as soft constraints, not hard blockers.
    - They should influence slot scoring or preference ranking rather than completely preventing placement.
5. Provide recommendations
    - Where in the generator pipeline these constraints should be evaluated.
    - How they should influence slot scoring or filtering logic.
    - Ensure the implementation remains efficient and compatible with the current architecture.

Important Constraints
    - Do not rename existing models, functions, or variables.
    - Do not change the current architecture drastically.
    - Focus on integrating activity-level soft constraints into slot evaluation.

Expected Output
    - Summary of activity-level constraints in the model.
    - Explanation of their intended scheduling behavior.
    - Recommended changes to the slot evaluation logic.
    - Pseudocode or code suggestions for integrating these constraints safely.

Create or update an appropriate .md file inside the 'Claude_Context' folder located at: "2-Tenant_Modules/8-Smart_Timetable/Claude_Context"

---------------------------------------------------

❯ Give me detailed prompt to provide you to get detailed document about the Timetable Generation Process in Timetable Module. This detail should include but limited to all below points: 
  - What all Algoritham has been implemented and in which sequence                                                                                                                                       
  - Whether one Algorithm passing its' output to the next Algo or not.                                                                                                                                   
  - How all Priority Parameters     


---------------------------------------------------------

I am developing an Acedemic Intelligence Plateform for Schools where I am covering ERP + LMS + LXp with advance Analytics to provide personalise learning to the student. Technology stack is PHP + Laravel + MySql. Currently I am working on 'Smart Timetable Generator' Module.

One of the most important parts of the system is the Constraint Architecture, which defines the rules that the timetable must follow during generation.

## Please carefully analyze the following models in my project:
    - Modules/SmartTimetable/app/Models/Constraint.php
    - Modules/SmartTimetable/app/Models/ConstraintCategory.php
    - Modules/SmartTimetable/app/Models/ConstraintCategoryScope.php
    - Modules/SmartTimetable/app/Models/ConstraintGroup.php
    - Modules/SmartTimetable/app/Models/ConstraintGroupMember.php
    - Modules/SmartTimetable/app/Models/ConstraintScope.php
    - Modules/SmartTimetable/app/Models/ConstraintTargetType.php
    - Modules/SmartTimetable/app/Models/ConstraintTemplate.php
    - Modules/SmartTimetable/app/Models/ConstraintType.php
    - Modules/SmartTimetable/app/Models/ConstraintViolation.php
Your Tasks
1. Understand the Constraint System
Analyze these models and explain clearly:
    - The role of each model
    - The relationships between them
    - How constraints are organized using:
        - Categories
        - Groups
        - Templates
        - Scopes
        - Target types
        - Violations

Provide a conceptual architecture diagram (text-based) showing how all these models interact.

2. Identify the Constraint Lifecycle
    - Explain the full lifecycle of a constraint, including:
    - How a constraint is defined (types/templates)
    - How it is assigned to entities (teacher/class/room/activity/etc.)
    - How it should be evaluated during timetable generation
    - How violations are detected and stored

3. Design a Plug-and-Play Constraint Engine
My goal is to integrate these constraints into the Timetable Generator Engine in a plug-and-play architecture.
Requirements:
    - The generator should not contain hardcoded constraint logic
    - Constraints should be modular
    - New constraints should be added without modifying the generator
    - Constraints should work like plugins

Please propose an architecture using something like:
    - ConstraintInterface
    - ConstraintManager
    - ConstraintRegistry
    - ConstraintEvaluator
    - ConstraintContext

Explain how the generator should call these constraints during slot evaluation.
Example flow:
Activity -> Candidate Slot -> Constraint Manager -> All Active Constraints -> Validation Result

4. Integration with Timetable Generator
Explain how constraints should be passed into the generator, including:
    - Loading constraints from database
    - Mapping them to runtime objects
    - Passing them into the generator
    - Evaluating them during placement
Example pseudo-flow:
```
    $constraints = ConstraintLoader::loadActiveConstraints();
    $generator = new TimetableGenerator(
        activities: $activities,
        slots: $slots,
        teachers: $teachers,
        rooms: $rooms,
        constraints: $constraints
    );
```

5. Provide a Recommended Architecture
Provide example class structure like:
```
Services/
    Constraints/
        Contracts/
            ConstraintInterface.php
        Core/
            ConstraintManager.php
            ConstraintContext.php
            ConstraintRegistry.php
        Constraints/
            TeacherAvailabilityConstraint.php
            RoomCapacityConstraint.php
            SubjectGapConstraint.php
```

Explain how this integrates with:
    ImprovedTimetableGenerator
    SlotEvaluator
    Slot
    Activity

6. Output Expectations
Your response should include:
    - Constraint model relationship explanation
    - Constraint architecture diagram
    - Plug-and-play constraint engine design
    - Integration flow with the timetable generator
    - Example PHP interfaces and class skeletons
    - Best practices for scalable constraint systems

Important Context
This is part of a large school timetable system, where constraints may include things like:
    - Teacher availability
    - Room requirements
    - Subject distribution rules
    - Consecutive period requirements
    - Lunch break protection
    - Max periods per day
    - Preferred/avoid time slots
The goal is to build a scalable, maintainable constraint architecture that can support dozens of constraint types without making the generator complex.
 
-----------------------------------------------------------------------------------------------------------------------------
I am developing an Acedemic Intelligence Plateform for Schools where I am covering ERP + LMS + LXp with advance Analytics to provide personalise learning to the student. Technology stack is PHP + Laravel + MySql. Location of the Project Application is "/Users/bkwork/Herd/laravel" and location of DB Schema is "/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases". 

Please set up a complete AI Agent system for this Laravel project by doing the following:
 
1. Read the current project structure first to understand what we're working with.
   - Run: find . -type f -name "*.php" | head -80
   - Read: composer.json, .env.example
   - Read: config/tenancy.php if it exists
   - Read: Modules/ directory structure if it exists
   - Read: all existing migrations, models, controllers, routes
 
2. Create the following folder and file structure inside the project root:
 
CLAUDE.md (at root level)
 
.ai/agents/developer.md
.ai/agents/debugger.md
.ai/agents/api-builder.md
.ai/agents/db-architect.md
.ai/agents/tenancy-agent.md
.ai/agents/module-agent.md
.ai/agents/school-agent.md
 
.ai/tasks/active/.gitkeep
.ai/tasks/completed/.gitkeep
.ai/tasks/backlog/.gitkeep
 
.ai/memory/project-context.md
.ai/memory/conventions.md
.ai/memory/decisions.md
.ai/memory/progress.md
.ai/memory/tenancy-map.md
.ai/memory/modules-map.md
.ai/memory/school-domain.md
 
.ai/rules/laravel-rules.md
.ai/rules/security-rules.md
.ai/rules/code-style.md
.ai/rules/tenancy-rules.md
.ai/rules/module-rules.md
.ai/rules/school-rules.md
 
.ai/templates/controller.md
.ai/templates/service.md
.ai/templates/repository.md
.ai/templates/api-response.md
.ai/templates/tenant-migration.md
.ai/templates/system-migration.md
.ai/templates/module-structure.md
.ai/templates/module-controller.md
.ai/templates/module-service.md
 
3. Scan the entire project and auto-fill every file with real, project-specific content:
 
   DETECTION CHECKLIST:
   - Read composer.json → detect Laravel version, stancl/tenancy version, nwidart/laravel-modules version, and ALL other packages
   - Read .env.example → detect DB setup, Redis, mail, storage, queue driver
   - Read config/tenancy.php → detect tenant model, central domains, tenant DB strategy (separate DB or same DB with tenant_id)
   - Read Modules/ directory → list all existing modules and their internal structure
   - Read all migrations in database/migrations/ → central/system tables
   - Read all migrations inside Modules/*/Database/Migrations/ → module-level tables
   - Read all Models → relationships, traits (HasTenantDatabaseConnection, BelongsToTenant, etc.)
   - Read all Controllers → patterns used, response formats
   - Read routes/api.php, routes/web.php, and Modules/*/Routes/ → all route groups
   - Detect if central routes and tenant routes are separated
   - Detect school-domain models: School, Student, Teacher, Staff, Parent, Grade, Class, Subject, Attendance, Exam, Fee, Timetable, etc.
 
4. Fill each file with intelligent, project-specific content:
 
---
 
CLAUDE.md (root level) must contain:
- Project name: Multi-Tenant School Management System
- Purpose: SaaS school platform where each school/institution is a tenant
- Tech stack detected from composer.json
- Multi-tenancy strategy detected (separate DB per tenant OR shared DB with tenant_id)
- Modules list detected from Modules/ directory
- Critical instruction: "Before starting ANY task, always read:
    1. .ai/memory/project-context.md
    2. .ai/memory/tenancy-map.md
    3. .ai/memory/modules-map.md
    4. .ai/rules/tenancy-rules.md
    5. .ai/rules/module-rules.md
    6. The relevant agent file for the task type"
- Critical warning: "NEVER mix central and tenant scoped code. Always know which context you are working in before writing any query or route."
- Instruction: Follow all rules in .ai/rules/ without exception
- Instruction: Use templates in .ai/templates/ for all new code
- Instruction: Update .ai/memory/progress.md after every completed task
- Instruction: Save every architectural decision to .ai/memory/decisions.md
 
---
 
.ai/memory/project-context.md must contain:
- App purpose: SaaS platform for managing schools, where each school is a tenant
- Tenancy strategy detected (separate DB per tenant OR shared DB)
- Central database tables (system-level: tenants, plans, subscriptions, domains, etc.)
- Tenant database tables (school-level: students, teachers, classes, etc.)
- All modules detected from Modules/ directory with a short description of each
- All Models found with their relationships mapped out
- External services detected (mail, payment, storage, SMS, etc.)
 
---
 
.ai/memory/tenancy-map.md must contain:
- Which tenancy package version is installed (stancl/tenancy v2 or v3)
- Tenancy initialization strategy (domain-based, subdomain-based, path-based)
- Central domains list from config
- Tenant model location and its fillable fields
- Which models are central (belong to system DB)
- Which models are tenant-scoped (belong to tenant DB)
- How tenancy is bootstrapped (middleware, automatic, manual)
- JobPipeline and bootstrappers detected from config/tenancy.php
- Any custom TenancyServiceProvider logic found
- How to correctly run tenant migrations: php artisan tenants:migrate
- How to correctly seed tenant data: php artisan tenants:seed
- How to run something inside a tenant context in code:
    tenancy()->initialize($tenant);
    // or
    $tenant->run(function() { ... });
 
---
 
.ai/memory/modules-map.md must contain:
- Full list of all modules detected inside Modules/ directory
- For each module: name, detected routes, controllers, models, migrations, services
- Which modules are tenant-scoped vs central-scoped
- How to create a new module: php artisan module:make ModuleName
- How module autoloading works in this project
- Module folder structure pattern used in this project
 
---
 
.ai/memory/school-domain.md must contain:
- All school-domain entities detected: School, Tenant, Student, Teacher, Staff, Parent, Grade, Classroom, Subject, Attendance, Exam, Result, Fee, Payment, Timetable, Notice, Event, etc.
- Relationships between entities as detected from Models
- Which entities are central (e.g. Tenant/School registration)
- Which entities are tenant-scoped (e.g. Students, Teachers, Classes)
- Academic year and term/semester structure if detected
- Role structure detected (SuperAdmin, SchoolAdmin, Teacher, Student, Parent, etc.)
 
---
 
.ai/memory/conventions.md must contain:
- Coding patterns found in existing controllers
- How modules structure their internal files
- Naming conventions used across the project
- How API responses are currently returned
- Service and Repository pattern usage found
 
---
 
.ai/memory/decisions.md must contain:
- Why stancl/tenancy was chosen and which strategy is being used
- Why nwidart/laravel-modules was chosen
- Any architectural decisions visible in the code
- Placeholder sections for future decisions
 
---
 
.ai/memory/progress.md must contain:
- List of all modules already built
- List of features detected as complete based on routes and controllers
- Placeholder for ongoing work
- Placeholder for upcoming modules
 
---
 
.ai/rules/tenancy-rules.md must contain:
- NEVER query tenant-scoped models from a central context without initializing tenancy first
- NEVER query central models from inside a tenant context without switching back
- ALWAYS use the correct migration path: central migrations go in database/migrations/, tenant migrations go in Modules/*/Database/Migrations/ or the configured tenant migration path
- ALWAYS use tenancy()->initialize($tenant) or $tenant->run() when running tenant-scoped operations from central context
- NEVER hardcode tenant IDs — always resolve from current tenancy context
- ALWAYS use tenant-aware queues when dispatching jobs that involve tenant data
- Route rule: central routes go in routes/web.php or routes/api.php — tenant routes go in the designated tenant route file or inside module routes with tenancy middleware
- When creating a new tenant migration: php artisan module:make-migration MigrationName ModuleName OR place in the configured tenant migrations path
- When creating a new central migration: php artisan make:migration migration_name
- Always test both central and tenant contexts when touching shared code
 
---
 
.ai/rules/module-rules.md must contain:
- Every new feature MUST be built as a module inside Modules/
- NEVER put new business logic directly in app/ — only shared core utilities belong there
- Each module must have its own: routes, controllers, models, migrations, services, requests, resources, tests
- Module service providers must be registered properly
- Modules must be self-contained — avoid tight coupling between modules
- Use module facade or service container to share functionality between modules
- Always run php artisan module:enable ModuleName after creating a new module
- Module naming convention: PascalCase singular (e.g. Student, Attendance, Examination)
- Internal module folder structure to always follow:
    Modules/ModuleName/
    ├── Http/Controllers/
    ├── Http/Requests/
    ├── Http/Resources/
    ├── Models/
    ├── Services/
    ├── Repositories/
    ├── Database/Migrations/
    ├── Database/Seeders/
    ├── Routes/api.php
    ├── Routes/web.php
    └── Providers/ModuleNameServiceProvider.php
 
---
 
.ai/rules/school-rules.md must contain:
- Students, Teachers, Staff are always tenant-scoped — never accessible across tenants
- Academic Year must always be resolved before creating term-related data (attendance, exams, timetable)
- Fee structures are school-specific — never share fee configs across tenants
- Roles and permissions are tenant-scoped — a Teacher in one school cannot access another school
- Attendance must always be tied to: Student + Classroom + Subject + Date + AcademicYear
- Exam results must always be tied to: Student + Exam + Subject + AcademicYear
- Timetable conflicts must be validated: same Teacher cannot have two classes at the same time slot
- Parent accounts must be linked to their children (students) within the same tenant only
- SuperAdmin is central-scoped — can manage tenants but cannot access tenant data directly
- SchoolAdmin is tenant-scoped — manages their own school only
 
---
 
.ai/rules/laravel-rules.md must contain:
- Laravel version detected and its specific best practices
- Always use Service classes for all business logic — controllers must stay thin
- Always use Form Requests for all input validation
- Always use API Resources for all JSON responses
- Always use Repository pattern for all database queries
- Never modify existing migrations — always create new ones
- Use specific rules for detected packages (Sanctum, Spatie, etc.)
- Queue all heavy operations (report generation, bulk imports, notifications)
- Use Events and Listeners for cross-module communication instead of direct coupling
 
---
 
.ai/rules/security-rules.md must contain:
- Always validate every user input through Form Requests
- Always scope queries to the current tenant — never allow cross-tenant data access
- Never expose internal IDs in API responses — use UUIDs or route model binding
- Always use authenticated + tenant-aware middleware on protected routes
- Always use mass assignment protection ($fillable) on every Model
- Never store sensitive data (passwords, tokens) in logs
- Spatie permission checks must always be performed at both route (middleware) and controller level
- File uploads must be validated for type and size — store in tenant-specific storage paths
- API rate limiting must be applied to all public endpoints
 
---
 
.ai/rules/code-style.md must contain:
- PSR-12 coding standard
- Naming: Controllers (StudentController), Services (StudentService), Repositories (StudentRepository), Requests (StoreStudentRequest), Resources (StudentResource)
- Methods must be small and single-purpose
- All public methods must have docblocks
- No business logic in controllers, models, or routes
- Use meaningful variable names — no abbreviations
- Match the naming and style already seen in the existing codebase
 
---
 
.ai/agents/developer.md must contain:
- Role: General Laravel + Modular + Multi-tenant feature developer
- Before starting any task, read: CLAUDE.md, project-context.md, tenancy-map.md, modules-map.md, conventions.md
- Determine: Is this feature central-scoped or tenant-scoped?
- Determine: Which module does this belong to?
- Feature building checklist:
    [ ] Identify correct module (or create new one)
    [ ] Identify tenancy scope (central vs tenant)
    [ ] Create migration in correct location
    [ ] Create Model with correct relationships and traits
    [ ] Create Repository
    [ ] Create Service
    [ ] Create Form Request
    [ ] Create API Resource
    [ ] Create Controller (thin)
    [ ] Register routes in correct route file with correct middleware
    [ ] Write tests
    [ ] Update .ai/memory/progress.md
 
---
 
.ai/agents/tenancy-agent.md must contain:
- Role: Specialist in stancl/tenancy — handles all tenancy-related tasks
- Before starting, always read: tenancy-map.md and tenancy-rules.md
- Responsibilities: creating new tenants, tenant migrations, tenant seeding, fixing tenancy context bugs, managing domains
- Always confirm tenancy strategy before writing any query
- Template for creating a new tenant programmatically
- Template for running code inside tenant context
- How to debug "tenant not initialized" errors
 
---
 
.ai/agents/module-agent.md must contain:
- Role: Specialist in nwidart/laravel-modules — handles module creation and structure
- Before starting, always read: modules-map.md and module-rules.md
- Responsibilities: creating new modules, ensuring correct internal structure, registering providers
- Step-by-step workflow for creating a new school module from scratch
- Checklist for ensuring a module is complete and properly registered
 
---
 
.ai/agents/school-agent.md must contain:
- Role: Domain expert for school management business logic
- Before starting, always read: school-domain.md and school-rules.md
- Responsibilities: implementing school-specific features (attendance, exams, fees, timetables, reports)
- Business rules to always enforce (from school-rules.md)
- Common school management workflows: enrollment, attendance tracking, exam management, fee collection, report card generation
 
---
 
.ai/agents/api-builder.md must contain:
- Role: Builds RESTful API endpoints inside the correct module
- Always confirm tenant vs central scope before building
- Always use API Resources, Form Requests, and Services
- Standard API response format to use consistently
- RESTful route naming convention
- How to register routes in module route files with correct middleware stack
 
---
 
.ai/agents/db-architect.md must contain:
- Role: Database design and migrations specialist
- Always determine: is this a central migration or a tenant migration?
- Central migrations: database/migrations/
- Tenant migrations: configured tenant migration path or Modules/*/Database/Migrations/
- Never modify existing migrations
- Always add indexes for foreign keys and frequently queried columns
- Use UUIDs as primary keys for tenant-scoped models
- Use soft deletes for all student, teacher, staff, fee, and exam records
- Document every schema decision in .ai/memory/decisions.md
 
---
 
.ai/agents/debugger.md must contain:
- Role: Debugging specialist
- Before debugging, always read: tenancy-map.md to check if the bug is tenancy-context related
- Common multi-tenant bugs to check first:
    - Tenancy not initialized before query
    - Central model queried inside tenant context
    - Wrong DB connection used
    - Migration run against wrong database
- Workflow: reproduce → check logs in storage/logs/ → isolate scope (central vs tenant) → fix → test both contexts → document in decisions.md
 
---
 
.ai/templates/tenant-migration.md must contain:
- Complete boilerplate for a tenant-scoped migration
- Correct location to place it
- Example with UUID primary key, foreign keys, indexes, timestamps, soft deletes
 
---
 
.ai/templates/system-migration.md must contain:
- Complete boilerplate for a central/system-level migration
- Correct location to place it
- Example for a system-level table like plans, subscriptions, or tenant registry
 
---
 
.ai/templates/module-structure.md must contain:
- Full folder and file structure for a new module
- Commands to generate it: php artisan module:make ModuleName
- Post-generation checklist
 
---
 
.ai/templates/module-controller.md must contain:
- Complete thin Controller template inside a module
- Using module namespace
- Using Form Request, Service, Resource
- index, show, store, update, destroy methods
 
---
 
.ai/templates/module-service.md must contain:
- Complete Service class template inside a module
- Constructor injection of Repository
- Methods for each operation with try/catch and proper exception handling
- Tenant-aware note: always ensure tenancy is initialized before querying
 
---
 
.ai/templates/controller.md must contain:
- Thin controller template (non-module version for central app/ usage)
 
---
 
.ai/templates/service.md must contain:
- Service class template for central app/ usage
 
---
 
.ai/templates/repository.md must contain:
- Repository class template
- Constructor injection of Model
- Methods: all, find, create, update, delete, paginate
- Eloquent only — no raw SQL
 
---
 
.ai/templates/api-response.md must contain:
- Standard JSON response structure for this project
- Success response format
- Error response format
- Validation error format
- Paginated response format
- Example using Laravel API Resource with tenant context note
 
---
 
5. Once all files are created and filled:
- Print a full summary of everything created
- Print what was detected: Laravel version, tenancy version, modules version, packages, existing modules, tenancy strategy
- Print a School Domain Map: which entities are central vs tenant-scoped
- Print a "Next Steps" guide:
    - How to start a new work session with Claude Code
    - How to create a new module
    - How to create a tenant migration vs central migration
    - How to run tenant migrations
    - How to assign tasks to the right agent

You have collected lots of information already, use that as well. 
Do all of this now without asking any questions. Use your best judgment based on everything found in the codebase.
