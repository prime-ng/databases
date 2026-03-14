❯ I am developing an Acedemic Intelligence Plateform for Schools where I am covering ERP + LMS + LXp with advance Analytics to provide personalise learning to the student. 
Technology stack is PHP + Laravel + MySql. 
Location of the Project Application is "/Users/bkwork/Herd/laravel" and 
location of DB Schema is "/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases".                           
                                                                                                                                                                                                               
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
                                                                                                                                                                                                               

⏺ I'll start by scanning the project structure to gather all the information needed, then create everything.
                                                                                                                                  
⏺ 2 Explore agents finished (ctrl+o to expand)
   ├─ Scan Laravel project structure · 61 tool uses · 59.2k tokens                                                                                                                                             
   │  ⎿  Done                                                                                         
   └─ Scan DB schema and modules · 41 tool uses · 72.8k tokens                                                                                                                                                 
      ⎿  Done                                                                                                                     
                                                                                                                                                                                                               
⏺ Now I have all project details. Let me create the directory structure and all files.                                                                                                                         
                                                                                                                                                                                                               
⏺ Bash(cd /Users/bkwork/Herd/laravel && mkdir -p .ai/agents .ai/tasks/active .ai/tasks/completed .ai/tasks/backlog .ai/memory .ai/rules .ai/templates && touch .ai/task…)                                      
  ⎿  Directory structure created                                                                                                                                                                               
  ⎿  Shell cwd was reset to /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases                                                                                                            
                                                                                                                                                                                                               
⏺ Good. Now I'll create all the files in parallel batches. Starting with CLAUDE.md and memory files.                                                                                                           
                                                                                                                                                                                                               
⏺ Write(~/Herd/laravel/CLAUDE.md)                                                                                                                                                                              
  ⎿  Wrote 124 lines to ../../../../../Herd/laravel/CLAUDE.md                                                                                                                                                  
       1 # Prime-AI: Academic Intelligence Platform                                                                                                                                                            
       2                                                                                                                                                                                                       
       3 ## Project Overview                                                                                                                                                                                   
       4 **Name:** Prime-AI ERP + LMS + LXP                                                                                                                                                                    
       5 **Purpose:** Multi-Tenant SaaS Academic Intelligence Platform for Indian Schools — covering ERP, LMS, LXP with advanced analytics for personalized student learning.                                  
       6 **Domain:** K-12 School Management (Class 2-12)                                                                                                                                                       
       7                                                                                                                                                                                                       
       8 ## Tech Stack                                                                                                                                                                                         
       9 - **Backend:** PHP 8.2+ / Laravel 12.0                                                                                                                                                              
      10 - **Database:** MySQL 8.x (InnoDB, UTF8MB4)                                                                                                                                                           
     … +114 lines (ctrl+o to expand)                                                                                                                                                                           
                                                                                                                                                                                                               
⏺ Write(~/Herd/laravel/.ai/memory/project-context.md)                                                                                                                                                          
  ⎿  Wrote 71 lines to ../../../../../Herd/laravel/.ai/memory/project-context.md                                                                                                                               
       1 # Project Context — Prime-AI Academic Intelligence Platform
       2
       3 ## Application Purpose
       4 SaaS platform for managing Indian K-12 schools (Class 2-12). Each school is an isolated tenant with its own database. The platform covers:
       5 - **ERP:** School administration, staff, students, fees, transport, vendors, complaints
       6 - **LMS:** Homework, quizzes, exams, question bank, syllabus management
       7 - **LXP:** Personalized learning paths, recommendations, analytics, HPC (Holistic Progress Card)
       8
       9 ## Tenancy Strategy
      10 - **Package:** stancl/tenancy v3.9
     … +61 lines (ctrl+o to expand)

⏺ Write(~/Herd/laravel/.ai/memory/tenancy-map.md)                                                                                                                                                              
  ⎿  Wrote 115 lines to ../../../../../Herd/laravel/.ai/memory/tenancy-map.md             
       1 # Tenancy Architecture Map                                                                                                                                                                            
       2                                                                                                                                                                                                       
       3 ## Package Details
       4 - **Package:** stancl/tenancy v3.9                                                                                                                                                                    
       5 - **Laravel:** 12.0                                
       6 - **Config:** `config/tenancy.php`                                                                                                                                                                    
       7                                                                                                                                                                                                     
       8 ## Tenancy Strategy                                                                                                                                                                                   
       9 - **Type:** Database-per-tenant isolation                                                                                                                                                             
      10 - **ID Generator:** `Stancl\Tenancy\UUIDGenerator` (UUID primary keys for tenants)                                                                                                                    
     … +105 lines (ctrl+o to expand)                                                                                                                                                                           
                                                                                                                                                                                                               
⏺ Write(~/Herd/laravel/.ai/memory/modules-map.md)
  ⎿  Wrote 113 lines to ../../../../../Herd/laravel/.ai/memory/modules-map.md             
       1 # Modules Map — nwidart/laravel-modules v12.0
       2                                                                                                                                                                                                       
       3 ## Module Management Commands
       4 ```bash                                                                                                                                                                                               
       5 # Create new module                                                                                                                                                                                 
       6 php artisan module:make ModuleName
       7
       8 # Enable/disable
       9 php artisan module:enable ModuleName
      10 php artisan module:disable ModuleName
     … +103 lines (ctrl+o to expand)

⏺ Write(~/Herd/laravel/.ai/memory/school-domain.md)
  ⎿  Wrote 136 lines to ../../../../../Herd/laravel/.ai/memory/school-domain.md           
       1 # School Domain Map           
       2                                                                                                                                                                                                       
       3 ## Entity Classification
       4                                                                                                                                                                                                       
       5 ### Central-Scoped Entities (prime_db / global_db) 
       6 These exist at the platform level, shared across all tenants:                                                                                                                                         
       7                                                    
       8 | Entity | Model | Table | Module |
       9 |--------|-------|-------|--------|
      10 | Tenant (School) | `Prime\Tenant` | `prm_tenant` | Prime |
     … +126 lines (ctrl+o to expand)

⏺ Write(~/Herd/laravel/.ai/memory/conventions.md)
  ⎿  Wrote 155 lines to ../../../../../Herd/laravel/.ai/memory/conventions.md             
      1 # Coding Conventions & Patterns
      2                                                                                                                                                                                                        
      3 ## Naming Conventions
      4                                                                                                                                                                                                        
      5 ### Tables                                          
      6 - Prefixed by module: `tt_`, `std_`, `sch_`, `slb_`, etc.
      7 - Junction tables suffixed with `_jnt`
      8 - Snake_case, plural for main tables (e.g., `tt_activities`, `std_students`)
      9 - Singular for junction targets (e.g., `tt_activity_teacher`)
     … +145 lines (ctrl+o to expand)

⏺ Write(~/Herd/laravel/.ai/memory/decisions.md)
  ⎿  Wrote 78 lines to ../../../../../Herd/laravel/.ai/memory/decisions.md                
       1 # Architectural Decisions Log 
       2                                                                                                                                                                                                       
       3 ## Confirmed Decisions
       4                                                                                                                                                                                                       
       5 ### D1: Multi-Tenancy — stancl/tenancy v3.9 with Database-per-Tenant
       6 - **Why:** Complete data isolation for each school. Regulatory compliance for Indian schools (data sovereignty). Simpler backup/restore per tenant. No risk of cross-tenant data leakage.             
       7 - **Trade-off:** Higher infrastructure cost (one DB per school), more complex migration management.
       8 - **Alternative considered:** Shared DB with `tenant_id` column — rejected due to data isolation requirements.
       9
      10 ### D2: Modular Architecture — nwidart/laravel-modules v12.0
     … +68 lines (ctrl+o to expand)

⏺ Write(~/Herd/laravel/.ai/memory/progress.md)
  ⎿  Wrote 77 lines to ../../../../../Herd/laravel/.ai/memory/progress.md                 
       1 # Development Progress Tracker
       2                                                                                                                                                                                                       
       3 ## Completed Modules (100%)
       4                                                                                                                                                                                                       
       5 ### Core Platform                                  
       6 - [x] **Prime** — Tenant management, plans, billing, users, roles, modules, menus, geography
       7 - [x] **GlobalMaster** — Countries, states, cities, boards, languages, plans, dropdowns
       8 - [x] **SystemConfig** — Settings, menus, translations
       9 - [x] **Billing** — Invoice generation, payment tracking, billing cycles
      10 - [x] **Dashboard** — Admin dashboards
     … +67 lines (ctrl+o to expand)

⏺ Now creating all rules files.        
                                                                                          
⏺ Write(~/Herd/laravel/.ai/rules/tenancy-rules.md)                                                                                                                                                             
  ⎿  Wrote 111 lines to ../../../../../Herd/laravel/.ai/rules/tenancy-rules.md                                                                                                                                 
       1 # Tenancy Rules — MANDATORY                                                                                                                                                                           
       2                                                                                                                                                                                                       
       3 ## Database Context Rules                          
       4                                                                                                                                                                                                       
       5 1. **NEVER query tenant-scoped models from a central context without initializing tenancy first.**
       6    ```php                                                                                                                                                                                             
       7    // WRONG — will query central DB                                                                                                                                                                 
       8    $students = Student::all();                                                                                                                                                                        
       9                                                                                                                                                                                                       
      10    // CORRECT — initialize tenant first                                                                                                                                                               
     … +101 lines (ctrl+o to expand)                                                                                                                                                                           
                                                                                                                                                                                                               
⏺ Write(~/Herd/laravel/.ai/rules/module-rules.md)
  ⎿  Wrote 123 lines to ../../../../../Herd/laravel/.ai/rules/module-rules.md             
       1 # Module Development Rules — MANDATORY
       2                                                                                                                                                                                                       
       3 ## Core Principles
       4                                                                                                                                                                                                       
       5 1. **Every new feature MUST be built as a module inside `Modules/`.**
       6    - NEVER put new business logic directly in `app/` — only shared core utilities belong there.                                                                                                       
       7    - The only exceptions: `app/Models/User.php`, `app/Helpers/`, `app/Providers/`, `app/Policies/`.
       8
       9 2. **Each module must be self-contained** with its own:
      10    - Routes (`routes/web.php`, `routes/api.php`)
     … +113 lines (ctrl+o to expand)

⏺ Write(~/Herd/laravel/.ai/rules/school-rules.md)
  ⎿  Wrote 94 lines to ../../../../../Herd/laravel/.ai/rules/school-rules.md              
      1 # School Domain Rules — MANDATORY
      2                                                                                                                                                                                                        
      3 ## Data Isolation
      4                                                                                                                                                                                                        
      5 1. **Students, Teachers, Staff are ALWAYS tenant-scoped.** They must never be accessible across tenants. Every query involving these entities must run within an initialized tenant context.
      6
      7 2. **Parent accounts must be linked to their children (students) within the same tenant only.** A parent in School A cannot see students in School B.
      8
      9 3. **SuperAdmin is central-scoped** — can manage tenants but cannot directly access tenant data without explicitly initializing tenancy.
     … +84 lines (ctrl+o to expand)

⏺ Write(~/Herd/laravel/.ai/rules/laravel-rules.md)
  ⎿  Wrote 123 lines to ../../../../../Herd/laravel/.ai/rules/laravel-rules.md            
       1 # Laravel Development Rules — MANDATORY
       2                                                                                                                                                                                                       
       3 ## Framework: Laravel 12.0 / PHP 8.2+
       4                                                                                                                                                                                                       
       5 ## Architecture Rules                              
       6                                                                                                                                                                                                       
       7 1. **Always use Service classes for business logic.** Controllers must stay thin — receive request, call service, return response.
       8
       9 2. **Always use Form Requests for input validation.** Never validate directly in controllers.
      10    ```php
     … +113 lines (ctrl+o to expand)

⏺ Write(~/Herd/laravel/.ai/rules/security-rules.md)
  ⎿  Wrote 89 lines to ../../../../../Herd/laravel/.ai/rules/security-rules.md            
      1 # Security Rules — MANDATORY
      2                                                                                                                                                                                                        
      3 ## Input Validation
      4                                                                                                                                                                                                        
      5 1. **Always validate every user input through Form Requests.** No raw `$request->input()` without validation.
      6                                                                                                                                                                                                        
      7 2. **Always use `$request->validated()`** to get only validated fields — never pass unvalidated data to models.
      8
      9 3. **Always use mass assignment protection** (`$fillable`) on every Model. Never use `$guarded = []`.
     … +79 lines (ctrl+o to expand)

⏺ Write(~/Herd/laravel/.ai/rules/code-style.md)
  ⎿  Wrote 111 lines to ../../../../../Herd/laravel/.ai/rules/code-style.md               
       1 # Code Style Rules          
       2                                                                                                                                                                                                       
       3 ## Standard: PSR-12
       4                                                                                                                                                                                                       
       5 ## Naming Conventions                              
       6                                                                                                                                                                                                       
       7 | Element | Convention | Example |                 
       8 |---------|-----------|---------|
       9 | Controller | PascalCase + `Controller` | `StudentController` |
      10 | Service | PascalCase + `Service` | `StudentService` |
     … +101 lines (ctrl+o to expand)

⏺ Now creating all agent files.      
                                                                                          
⏺ Write(~/Herd/laravel/.ai/agents/developer.md)                                                                                                                                                                
  ⎿  Wrote 83 lines to ../../../../../Herd/laravel/.ai/agents/developer.md                                                                                                                                     
       1 # Agent: Developer                                                                                                                                                                                    
       2                                                                                                                                                                                                       
       3 ## Role                                            
       4 General Laravel + Modular + Multi-tenant feature developer for the Prime-AI Academic Intelligence Platform.                                                                                           
       5                                                    
       6 ## Before Starting Any Task                                                                                                                                                                           
       7 1. Read `CLAUDE.md` — Project overview and critical instructions                                                                                                                                    
       8 2. Read `.ai/memory/project-context.md` — Full project context                                                                                                                                        
       9 3. Read `.ai/memory/tenancy-map.md` — Multi-tenancy architecture                                                                                                                                      
      10 4. Read `.ai/memory/modules-map.md` — Module structure                                                                                                                                                
     … +73 lines (ctrl+o to expand)                                                                                                                                                                            
                                                                                                                                                                                                               
⏺ Write(~/Herd/laravel/.ai/agents/debugger.md)
  ⎿  Wrote 100 lines to ../../../../../Herd/laravel/.ai/agents/debugger.md                
      1 # Agent: Debugger              
      2                                                                                                                                                                                                        
      3 ## Role
      4 Debugging specialist for the Prime-AI multi-tenant Laravel application.                                                                                                                                
      5                                                     
      6 ## Before Debugging                                                                                                                                                                                    
      7 1. Read `.ai/memory/tenancy-map.md` — Check if the bug is tenancy-context related
      8 2. Read `.ai/memory/conventions.md` — Understand expected patterns
      9 3. Check `storage/logs/laravel.log` for error details
     … +90 lines (ctrl+o to expand)

⏺ Write(~/Herd/laravel/.ai/agents/api-builder.md)
  ⎿  Wrote 99 lines to ../../../../../Herd/laravel/.ai/agents/api-builder.md              
      1 # Agent: API Builder          
      2                                                                                                                                                                                                        
      3 ## Role
      4 Builds RESTful API endpoints inside the correct module for the Prime-AI platform.                                                                                                                      
      5                                                     
      6 ## Before Building                                                                                                                                                                                     
      7 1. Read `.ai/memory/tenancy-map.md` — Is this a central or tenant API?
      8 2. Read `.ai/memory/modules-map.md` — Which module does this belong to?
      9 3. Read `.ai/templates/api-response.md` — Standard response format
     … +89 lines (ctrl+o to expand)

⏺ Write(~/Herd/laravel/.ai/agents/db-architect.md)
  ⎿  Wrote 103 lines to ../../../../../Herd/laravel/.ai/agents/db-architect.md            
       1 # Agent: Database Architect   
       2                                                                                                                                                                                                       
       3 ## Role
       4 Database design and migration specialist for the Prime-AI 3-layer multi-tenant architecture.                                                                                                          
       5                                                    
       6 ## Before Designing                                                                                                                                                                                   
       7 1. Read `.ai/memory/tenancy-map.md` — Understand the 3-layer DB architecture
       8 2. Read `.ai/memory/project-context.md` — Review existing table counts and prefixes
       9 3. Read `.ai/memory/conventions.md` — Naming conventions
      10 4. Check existing schema: `/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/1-master_dbs/1-DDL_schema/`
     … +93 lines (ctrl+o to expand)

⏺ Write(~/Herd/laravel/.ai/agents/tenancy-agent.md)
  ⎿  Wrote 134 lines to ../../../../../Herd/laravel/.ai/agents/tenancy-agent.md           
       1 # Agent: Tenancy Specialist   
       2                                                                                                                                                                                                       
       3 ## Role
       4 Expert in stancl/tenancy v3.9 — handles all tenancy-related tasks for the Prime-AI platform.                                                                                                          
       5                                                    
       6 ## Before Starting                                                                                                                                                                                    
       7 1. Read `.ai/memory/tenancy-map.md` — Full tenancy configuration
       8 2. Read `.ai/rules/tenancy-rules.md` — Mandatory tenancy rules
       9
      10 ## Responsibilities
     … +124 lines (ctrl+o to expand)

⏺ Write(~/Herd/laravel/.ai/agents/module-agent.md)
  ⎿  Wrote 105 lines to ../../../../../Herd/laravel/.ai/agents/module-agent.md            
       1 # Agent: Module Specialist    
       2                                                                                                                                                                                                       
       3 ## Role
       4 Expert in nwidart/laravel-modules v12.0 — handles module creation, structure, and registration.                                                                                                       
       5                                                    
       6 ## Before Starting                                                                                                                                                                                    
       7 1. Read `.ai/memory/modules-map.md` — All existing modules
       8 2. Read `.ai/rules/module-rules.md` — Mandatory module rules
       9
      10 ## Creating a New Module — Step by Step
     … +95 lines (ctrl+o to expand)

⏺ Write(~/Herd/laravel/.ai/agents/school-agent.md)
  ⎿  Wrote 101 lines to ../../../../../Herd/laravel/.ai/agents/school-agent.md            
       1 # Agent: School Domain Expert
       2                                                                                                                                                                                                       
       3 ## Role
       4 Domain expert for school management business logic in the Prime-AI platform. Ensures all school-specific features follow educational domain rules.                                                    
       5                                                    
       6 ## Before Starting
       7 1. Read `.ai/memory/school-domain.md` — All school entities and relationships
       8 2. Read `.ai/rules/school-rules.md` — Mandatory school domain rules
       9
      10 ## Key Business Rules
     … +91 lines (ctrl+o to expand)

⏺ Now creating all template files.     
                                                                                          
⏺ Write(~/Herd/laravel/.ai/templates/tenant-migration.md)                                                                                                                                                      
  ⎿  Wrote 89 lines to ../../../../../Herd/laravel/.ai/templates/tenant-migration.md                                                                                                                           
      1 # Template: Tenant Migration                                                                                                                                                                           
      2                                                                                                                                                                                                        
      3 ## Location                                                                                                                                                                                            
      4 `database/migrations/tenant/` or via `php artisan module:make-migration migration_name ModuleName`                                                                                                     
      5                                                     
      6 ## Boilerplate                                                                                                                                                                                         
      7   
      8 ```php                                                                                                                                                                                                 
      9 <?php                                                                                                                                                                                                
     … +79 lines (ctrl+o to expand)                                                                                                                                                                            
                                                                                                                                                                                                               
⏺ Write(~/Herd/laravel/.ai/templates/system-migration.md)                                                                                                                                                      
  ⎿  Wrote 68 lines to ../../../../../Herd/laravel/.ai/templates/system-migration.md                                                                                                                           
      1 # Template: Central/System Migration                                                                                                                                                                   
      2
      3 ## Location
      4 `database/migrations/`
      5
      6 ## Command
      7 ```bash
      8 php artisan make:migration create_table_name
      9 ```
     … +58 lines (ctrl+o to expand)

⏺ Write(~/Herd/laravel/.ai/templates/module-structure.md)
  ⎿  Wrote 77 lines to ../../../../../Herd/laravel/.ai/templates/module-structure.md      
       1 # Template: New Module Structure
       2                                                                                                                                                                                                       
       3 ## Step 1: Create Module
       4 ```bash                                                                                                                                                                                               
       5 php artisan module:make ModuleName                 
       6 php artisan module:enable ModuleName                                                                                                                                                                  
       7 ```                                                
       8
       9 ## Step 2: Generated Structure
      10 ```
     … +67 lines (ctrl+o to expand)

⏺ Write(~/Herd/laravel/.ai/templates/module-controller.md)
  ⎿  Wrote 152 lines to ../../../../../Herd/laravel/.ai/templates/module-controller.md    
      1 # Template: Module Controller 
      2                                                                                                                                                                                                        
      3 ## Location
      4 `Modules/{ModuleName}/app/Http/Controllers/`                                                                                                                                                           
      5                                                     
      6 ## Boilerplate                                                                                                                                                                                         
      7                                                     
      8 ```php
      9 <?php
     … +142 lines (ctrl+o to expand)

⏺ Write(~/Herd/laravel/.ai/templates/module-service.md)
  ⎿  Wrote 131 lines to ../../../../../Herd/laravel/.ai/templates/module-service.md       
      1 # Template: Module Service    
      2                                                                                                                                                                                                        
      3 ## Location
      4 `Modules/{ModuleName}/app/Services/`                                                                                                                                                                   
      5                                                     
      6 ## Boilerplate                                                                                                                                                                                         
      7                                                     
      8 ```php
      9 <?php
     … +121 lines (ctrl+o to expand)

⏺ Write(~/Herd/laravel/.ai/templates/controller.md)
  ⎿  Wrote 65 lines to ../../../../../Herd/laravel/.ai/templates/controller.md            
      1 # Template: Central Controller (Non-Module)
      2                                                                                                                                                                                                        
      3 ## Location
      4 `app/Http/Controllers/`                                                                                                                                                                                
      5                                                     
      6 ## Use Case                                                                                                                                                                                            
      7 For central/system-level controllers that don't belong to a specific module. Rare — most controllers should be in modules.
      8
      9 ## Boilerplate
     … +55 lines (ctrl+o to expand)

⏺ Write(~/Herd/laravel/.ai/templates/service.md)
  ⎿  Wrote 47 lines to ../../../../../Herd/laravel/.ai/templates/service.md               
      1 # Template: Central Service (Non-Module)
      2                                                                                                                                                                                                        
      3 ## Location
      4 `app/Services/`                                                                                                                                                                                        
      5                                                     
      6 ## Use Case                                                                                                                                                                                            
      7 For shared services used across multiple modules. Most services should be in modules.
      8
      9 ## Boilerplate
     … +37 lines (ctrl+o to expand)

⏺ Write(~/Herd/laravel/.ai/templates/repository.md)
  ⎿  Wrote 105 lines to ../../../../../Herd/laravel/.ai/templates/repository.md           
      1 # Template: Repository         
      2                                                                                                                                                                                                        
      3 ## Location
      4 `Modules/{ModuleName}/app/Repositories/` or `app/Repositories/`                                                                                                                                        
      5                                                     
      6 ## Use Case                                                                                                                                                                                            
      7 Optional pattern for complex query logic. In this project, most data access is done directly through Eloquent in Services. Use repositories when query complexity warrants separation.
      8
      9 ## Boilerplate
     … +95 lines (ctrl+o to expand)

⏺ Write(~/Herd/laravel/.ai/templates/api-response.md)
  ⎿  Wrote 152 lines to ../../../../../Herd/laravel/.ai/templates/api-response.md         
       1 # Template: API Response Format
       2                                                                                                                                                                                                       
       3 ## Standard JSON Response Structure
       4                                                                                                                                                                                                       
       5 ### Success — Single Resource                      
       6 ```json
       7 {
       8     "success": true,
       9     "data": {
      10         "id": 1,
     … +142 lines (ctrl+o to expand)

⏺ All files created. Let me verify the complete structure.
                                                                                          
⏺ Bash(cd /Users/bkwork/Herd/laravel && find CLAUDE.md .ai -type f | sort)
  ⎿  .ai/agents/api-builder.md                                                                                                                                                                                 
     .ai/agents/db-architect.md
     .ai/agents/debugger.md                                                                                                                                                                                    
     … +30 lines (ctrl+o to expand)                                                       
  ⎿  Shell cwd was reset to /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases                                                                                                            
                                                                                                                                                                                                               
⏺ All 32 files created. Here's the complete summary:
                                                                                                                                                                                                               
  ---                                                       
  Summary of Everything Created                                                                                                                                                                                
   
  Files Created: 32                                                                                                                                                                                            
                                                            
  ┌───────────┬───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┬───────┐
  │ Category  │                                                                               Files                                                                               │ Count │
  ├───────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼───────┤
  │ Root      │ CLAUDE.md                                                                                                                                                         │ 1     │
  ├───────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼───────┤
  │ Agents    │ developer.md, debugger.md, api-builder.md, db-architect.md, tenancy-agent.md, module-agent.md, school-agent.md                                                    │ 7     │
  ├───────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼───────┤
  │ Memory    │ project-context.md, tenancy-map.md, modules-map.md, school-domain.md, conventions.md, decisions.md, progress.md                                                   │ 7     │
  ├───────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼───────┤
  │ Rules     │ tenancy-rules.md, module-rules.md, school-rules.md, laravel-rules.md, security-rules.md, code-style.md                                                            │ 6     │
  ├───────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼───────┤
  │ Templates │ tenant-migration.md, system-migration.md, module-structure.md, module-controller.md, module-service.md, controller.md, service.md, repository.md, api-response.md │ 9     │
  ├───────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼───────┤
  │ Tasks     │ active/.gitkeep, completed/.gitkeep, backlog/.gitkeep                                                                                                             │ 3     │
  └───────────┴───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┴───────┘

  ---
  What Was Detected

  ┌─────────────────────────────┬───────────────────────────────────────────────┐
  │          Attribute          │                     Value                     │
  ├─────────────────────────────┼───────────────────────────────────────────────┤
  │ Laravel                     │ 12.0                                          │
  ├─────────────────────────────┼───────────────────────────────────────────────┤
  │ PHP                         │ 8.2+                                          │
  ├─────────────────────────────┼───────────────────────────────────────────────┤
  │ stancl/tenancy              │ 3.9 (database-per-tenant, UUID, domain-based) │
  ├─────────────────────────────┼───────────────────────────────────────────────┤
  │ nwidart/laravel-modules     │ 12.0                                          │
  ├─────────────────────────────┼───────────────────────────────────────────────┤
  │ spatie/laravel-permission   │ 6.21                                          │
  ├─────────────────────────────┼───────────────────────────────────────────────┤
  │ spatie/laravel-medialibrary │ 11.17                                         │
  ├─────────────────────────────┼───────────────────────────────────────────────┤
  │ spatie/laravel-backup       │ 9.3                                           │
  ├─────────────────────────────┼───────────────────────────────────────────────┤
  │ laravel/sanctum             │ 4.0                                           │
  ├─────────────────────────────┼───────────────────────────────────────────────┤
  │ Modules                     │ 29 total                                      │
  ├─────────────────────────────┼───────────────────────────────────────────────┤
  │ Models                      │ ~400+ across all modules                      │
  ├─────────────────────────────┼───────────────────────────────────────────────┤
  │ Controllers                 │ 273+                                          │
  ├─────────────────────────────┼───────────────────────────────────────────────┤
  │ DB Tables                   │ 198 (12 global + 27 prime + 159 tenant)       │
  ├─────────────────────────────┼───────────────────────────────────────────────┤
  │ Tenant Migrations           │ 216 files                                     │
  ├─────────────────────────────┼───────────────────────────────────────────────┤
  │ Policies                    │ 195+                                          │
  ├─────────────────────────────┼───────────────────────────────────────────────┤
  │ Tenancy Strategy            │ Separate DB per tenant (prefix: tenant_)      │
  ├─────────────────────────────┼───────────────────────────────────────────────┤
  │ Queue/Cache/Session         │ Database driver                               │
  └─────────────────────────────┴───────────────────────────────────────────────┘

  ---
  School Domain Map — Central vs Tenant

  Central: Tenant, Domain, TenantGroup, Plan, Module, Menu, Country, State, City, Board, Language, BillingInvoice, Central User/Roles

  Tenant: Organization, SchoolClass, Section, Subject, StudyFormat, Teacher, Student, Guardian, Employee, Room, Building, Activity, Timetable, Constraint, FeeHead, FeeInvoice, Payment, Attendance, Exam,
  Quiz, Homework, Question, Lesson, Topic, Competency, Vehicle, Route, Trip, Vendor, Complaint, Notification, HPC Evaluation, Recommendation

  ---
  Next Steps Guide

  Starting a New Work Session

  1. Claude reads CLAUDE.md automatically
  2. For specific tasks, reference the relevant agent:
     - Building a feature? → .ai/agents/developer.md
     - Fixing a bug? → .ai/agents/debugger.md
     - Creating an API? → .ai/agents/api-builder.md
     - Designing schema? → .ai/agents/db-architect.md
     - Tenancy issue? → .ai/agents/tenancy-agent.md
     - New module? → .ai/agents/module-agent.md
     - School logic? → .ai/agents/school-agent.md

  Creating a New Module

  php artisan module:make ModuleName
  php artisan module:enable ModuleName
  # Then follow .ai/templates/module-structure.md

  Tenant vs Central Migration

  # Central (prime_db)
  php artisan make:migration create_table_name
  php artisan migrate

  # Tenant (tenant_db)
  php artisan make:migration create_table_name --path=database/migrations/tenant
  php artisan tenants:migrate

  Assigning Tasks to the Right Agent

  ┌─────────────────────────┬─────────────────────────────┐
  │        Task Type        │         Agent File          │
  ├─────────────────────────┼─────────────────────────────┤
  │ New feature/CRUD        │ .ai/agents/developer.md     │
  ├─────────────────────────┼─────────────────────────────┤
  │ Bug fix                 │ .ai/agents/debugger.md      │
  ├─────────────────────────┼─────────────────────────────┤
  │ REST API endpoint       │ .ai/agents/api-builder.md   │
  ├─────────────────────────┼─────────────────────────────┤
  │ Schema design/migration │ .ai/agents/db-architect.md  │
  ├─────────────────────────┼─────────────────────────────┤
  │ Tenancy setup/fix       │ .ai/agents/tenancy-agent.md │
  ├─────────────────────────┼─────────────────────────────┤
  │ New module scaffold     │ .ai/agents/module-agent.md  │
  ├─────────────────────────┼─────────────────────────────┤
  │ School business logic   │ .ai/agents/school-agent.md  │
  └─────────────────────────┴─────────────────────────────┘

✻ Baked for 10m 52s