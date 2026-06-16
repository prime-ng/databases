# SmartTimetable Module — Comprehensive Documentation Generation Prompt v2

## 📋 RESOLVED PATH CONFIGURATION (Do NOT edit — paths are final)

```yaml
# ──────────────────────────────────────────────────────
# ALL PATHS ARE FULLY RESOLVED — Use exactly as-is
# ──────────────────────────────────────────────────────

# Laravel Application (where code lives)
LARAVEL_REPO:        /Users/bkwork/Herd/prime_ai
MODULE_ROOT:         /Users/bkwork/Herd/prime_ai/Modules/SmartTimetable

# Module Sub-paths
CONTROLLERS_PATH:    Modules/SmartTimetable/app/Http/Controllers
MODELS_PATH:         Modules/SmartTimetable/app/Models
SERVICES_PATH:       Modules/SmartTimetable/app/Services
JOBS_PATH:           Modules/SmartTimetable/app/Jobs
POLICIES_PATH:       Modules/SmartTimetable/app/Policies
PROVIDERS_PATH:      Modules/SmartTimetable/app/Providers
REQUESTS_PATH:       Modules/SmartTimetable/app/Http/Requests
EXCEPTIONS_PATH:     Modules/SmartTimetable/app/Exceptions
MIGRATIONS_PATH:     Modules/SmartTimetable/database/migrations
SEEDERS_PATH:        Modules/SmartTimetable/database/seeders
FACTORIES_PATH:      Modules/SmartTimetable/database/factories
VIEWS_PATH:          Modules/SmartTimetable/resources/views
ASSETS_PATH:         Modules/SmartTimetable/resources/assets
TESTS_PATH:          Modules/SmartTimetable/tests
CONFIG_PATH:         Modules/SmartTimetable/config
ROUTES_WEB:          Modules/SmartTimetable/routes/web.php
ROUTES_API:          Modules/SmartTimetable/routes/api.php
MODULE_JSON:         Modules/SmartTimetable/module.json
COMPOSER_JSON:       Modules/SmartTimetable/composer.json

# Also read these app-level route files for SmartTimetable routes:
APP_ROUTES_TENANT:   routes/tenant.php                          # tenant-scoped web routes
APP_ROUTES_API:      routes/api.php                             # tenant-scoped API routes

# Databases Repo (design docs and DDL reference)
DB_DESIGN_ROOT:      /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/1-DDL_Tenant_Modules/27-SmartTimetable

# Latest DDL (authoritative schema)
DDL_LATEST:          /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/1-DDL_Tenant_Modules/27-SmartTimetable/DDL/tt_timetable_ddl_v7.6.sql

# Design & Requirement Docs (read ALL of these in Phase 0)
DESIGN_DOCS:         /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/1-DDL_Tenant_Modules/27-SmartTimetable/Design_docs/
INPUT_DOCS:          /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/1-DDL_Tenant_Modules/27-SmartTimetable/Input/
V6_DOCS:             /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/1-DDL_Tenant_Modules/27-SmartTimetable/V6/
CONTEXT_DOCS:        /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/1-DDL_Tenant_Modules/27-SmartTimetable/Claude_Context/

# Output Location
OUTPUT_FILE:         /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/5-Work-In-Progress/2-In-Progress/SmartTimetable/SmartTimetable_Module_Documentation.md
```

---

## 🎯 MASTER PROMPT — Provide everything below to Claude Agent

---

You are a senior software architect performing a **complete reverse-engineering documentation** of the SmartTimetable Laravel module. Your goal is to produce an exhaustive, human-readable document that allows any developer or AI agent to fully understand what this module does, how it does it, and why — without reading source code.

This module is part of a **multi-tenant SaaS ERP for Indian schools** built on PHP + Laravel + MySQL. It uses a 3-database architecture:
- `global_db` — shared masters (boards, standards, subjects)
- `prime_db` — SaaS management (tenants, plans)
- `tenant_db` — per-school isolated data (all `tt_` tables belong here)

The SmartTimetable module is a **Nwidart Laravel Module** (`module.json` defines it) with full self-contained Controllers, Models, Services, Jobs, Views, Migrations, Seeders, and Routes.

---

### PHASE 0: PRE-READING CONTEXT — Read Design Documents First

**Before reading any code**, read all of the following design and reference documents to build a mental model of the intended design:

**Step 0.1 — Read the DDL (Database Schema)**
Read the complete file:
`/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/1-DDL_Tenant_Modules/27-SmartTimetable/DDL/tt_timetable_ddl_v7.6.sql`

Note every table, its columns, indexes, foreign keys, and any inline comments. This is the **authoritative schema**. All code must be cross-referenced against it.

**Step 0.2 — Read Requirement and Design Documents**

Read each of these files completely — they document the intended behaviour before implementation:

| File | Purpose |
|------|---------|
| `Design_docs/Timetable_Requirement_v2.md` | Original requirement spec v2 |
| `databases/5-Work-In-Progress/2-In-Progress/SmartTimetable/Input/0-tt_Requirement_v3.md` | Requirement spec v3 (most recent) |
| `Input/3-Process_Flow_v3.md` | Process flow v3 |
| `V6/3-Process_Flow_v4.md` | Process flow v4 (latest) |
| `V6/1-tt_Table_Detail.md` | Table-level design detail |
| `V6/2-tt_Generation_Flow.md` | Generation algorithm design intent |
| `V6/4-tt_Validation.md` | Validation design |
| `Design_docs/tt_Algoritham.md` | Algorithm design document |
| `Design_docs/Constraint_list.md` | Full list of all constraints |
| `Design_docs/Constraint_evaluation_engine.md` | Constraint engine design |
| `Design_docs/contraint_ProcessPoint.md` | Constraint application process points |
| `Design_docs/Priority_Config.md` | Priority configuration design |
| `Design_docs/tt_Checklist.md` | Implementation checklist |
| `Design_docs/1-Current_App_Processflow.md` | Current app process flow |
| `Input/4-Process_execution_v1.md` | Process execution flow |
| `Input/5-Constraints_v1.csv` | Full constraint list in CSV |
| `Claude_Context/2026Mar10_GapAnalysis_and_CompletionPlan.md` | Gap analysis |
| `Claude_Context/2026Mar14_GapAnalysis_Updated.md` | Updated gap analysis |
| `Claude_Context/tt_Constraint_detail.md` | Constraint detail notes |

After reading these, document:
- The **intended design** as the designers envisioned it
- Key terminology specific to this module (Activity, PeriodSet, Slot, SchoolDay, TeacherAvailability, GenerationRun, etc.)
- The high-level workflow the user is supposed to follow step-by-step

---

### PHASE 1: DISCOVERY — Read & Index All Module Files

**Step 1.1 — Module Metadata**

Read these files first to understand the module's registration and dependencies:
- `Modules/SmartTimetable/module.json` — module name, alias, providers, autoload namespaces
- `Modules/SmartTimetable/composer.json` — PHP dependencies
- `Modules/SmartTimetable/config/smarttimetable.php` (if exists) — module configuration

**Step 1.2 — Complete Directory Tree**

Read the full directory tree under `Modules/SmartTimetable/`. Categorize every file:

- **Controllers** (including `Api/` subdirectory)
- **Models** (list table name, fillable, relationships, casts, scopes, accessors for each)
- **Services** (one paragraph per service describing its responsibility)
- **Jobs** (queued background jobs)
- **Form Requests** (validation rules)
- **Policies** (authorization rules)
- **Providers** (service container bindings)
- **Exceptions** (custom exception types)
- **Views / Blade templates** (grouped by feature area — note any `_old` views that indicate deprecated screens)
- **Assets** (JS files, Alpine.js, CSS)
- **Migrations** (chronological order — note what each migration creates/alters)
- **Seeders** (what reference data each seeder creates)
- **Factories** (test data factories)
- **Tests** (Feature and Unit test files)
- **Route files** (`web.php`, `api.php`)
- **Config files**
- **Other** (DOCS/, Claude_Context/, any markdown files)

**Step 1.3 — Read Every File Completely**

For each file discovered, read its **full content**. Do not skip or summarize at this stage. You need complete understanding before writing documentation.

Pay special attention to:
- Any files with `_old` in their name or path — these are deprecated/replaced views; document what they contained and why they were deprecated
- Backup files (`.backup`, `_copy`) — note their existence; do not document them as active code
- Any TODO/FIXME/HACK comments in code — collect these in a list for Section 19 (Known Gaps)
- Any `dd()`, `dump()`, or `Log::debug()` calls left in production code — flag as cleanup needed

**Step 1.4 — Cross-Reference: App-Level Files**

After reading the module, check these app-level locations for any related code:
- `app/Models/` — models used by SmartTimetable but defined outside the module (e.g., Staff, Student, ClassSection, Subject, Room)
- `app/Http/Middleware/` — middleware applied to SmartTimetable routes (especially tenant resolution, auth)
- `routes/tenant.php` — SmartTimetable routes registered at app level
- `routes/api.php` — SmartTimetable API routes registered at app level
- `config/` — any config keys referenced in SmartTimetable (`queue.php` for job configuration, etc.)

---

### PHASE 2: ANALYSIS — Understand Every Screen and Operation

**Step 2.1 — Menu & Navigation Mapping**

Document every menu item and navigation link under the Timetable module:
- Menu label as shown to user (read from menu seeder or `sys_menus` table structure)
- Route name and URL pattern
- Controller@method it maps to
- Permission/role guard
- Sidebar group it belongs to
- Whether the corresponding screen is active or deprecated (`_old` suffix)

**Step 2.2 — Screen-by-Screen Walkthrough**

For every active Blade view (skip `_old` views but mention them), document:

```
SCREEN: [Screen name / title as shown to user]
VIEW FILE: [resources/views/path/to/file.blade.php]
URL PATTERN: [e.g., /smart-timetable/{timetable}/refinement]
ROUTE NAME: [e.g., smart-timetable.refinement.index]
CONTROLLER: [ClassName@methodName]
PURPOSE: [What the user accomplishes on this screen]
UI ELEMENTS:
  - [Form fields, dropdowns, buttons, modals, tables, tabs — describe what each does]
DATA LOADED ON PAGE LOAD:
  - Table: [table_name] → Columns: [list] → Where: [conditions] → Eager loads: [relations]
USER ACTIONS:
  - [Action name]: [What happens — validation → processing → DB writes → response]
AJAX / FETCH CALLS: [Any async calls made from this view]
JAVASCRIPT BEHAVIOUR: [Alpine.js directives, event listeners, dynamic behaviour]
```

**Step 2.3 — Data Flow Tracing (CRITICAL — Be Exhaustive)**

For every operation that reads or writes data, document in this exact format:

```
OPERATION: [Name — e.g., "Generate Timetable (Queued)", "Swap Two Cells", "Record Teacher Absence"]
TRIGGER: [Button click / form submit / scheduled job / AJAX call / event listener]
INPUT SOURCE:
  - Table: [table_name] → Columns: [col1, col2] → Filter: [conditions]
  - User Input: [field names and what they contain]
PROCESSING:
  - Step 1: [Describe transformation or logic]
  - Step 2: [...]
CALCULATIONS:
  - [Variable] = [Formula in plain English]
  - Example: periods_assigned = COUNT(tt_timetable_cells) WHERE timetable_id = X AND class_id = Y
OUTPUT TARGET:
  - Table: [table_name] → Columns Written: [col = source, ...]
VALIDATION / CONSTRAINTS:
  - [Constraint description]
ERROR HANDLING:
  - [What happens if X fails — exception type, user-facing message, DB rollback?]
EVENTS DISPATCHED: [If any Laravel events are fired]
JOBS QUEUED: [If any jobs are dispatched]
```

Trace every single operation — CRUD, bulk operations, generation triggers, AJAX endpoints, import/export, and every API endpoint.

---

### PHASE 3: DATABASE SCHEMA DOCUMENTATION

**Step 3.1 — Complete Table Inventory**

For every table in `tt_timetable_ddl_v7.6.sql` AND any additional tables in migrations not yet in the DDL:

```
TABLE: [table_name]
DATABASE: tenant_db
CREATED BY: [migration filename + date]
PURPOSE: [What this table stores — 1-2 sentences]
COLUMNS:
  - id            (bigint unsigned, PK, AUTO_INCREMENT)
  - [col_name]    ([type], [NULL/NOT NULL], DEFAULT [val], [index type]) — [description]
  ...
RELATIONSHIPS:
  - belongsTo: [table] via [fk_col]
  - hasMany: [table] via [fk_col]
  - belongsToMany: [table] via [junction_table] (extra cols: [...])
INDEXES: [All indexes including composites]
JSON COLUMNS:
  - [col_name]: Expected structure: { key: type, ... }
SOFT DELETES: [Yes — deleted_at / No]
TIMESTAMPS: [Yes — created_at, updated_at / No]
TENANT SCOPED: Yes (all tt_ tables are per-tenant)
```

**Step 3.2 — Table Groupings**

Group all tables by functional area and document the purpose of each group:
- **Master / Config tables** (school days, period types, shifts, day types, constraints config)
- **Period Structure tables** (period sets, period set periods)
- **Activity tables** (activities, sub-activities, activity teachers, parallel groups)
- **Teacher Resource tables** (teacher availability, teacher unavailability, teacher workloads)
- **Room Resource tables** (room unavailability, room availability, room utilizations)
- **Constraint tables** (constraint types, categories, scopes, groups, templates, constraints, violations)
- **Generation tables** (generation runs, generation queues, optimization runs/iterations/moves)
- **Timetable Output tables** (timetables, timetable cells, timetable cell teachers, resource bookings)
- **Analytics tables** (analytics daily snapshots, workloads, utilizations, conflict detections)
- **Refinement / Change Management tables** (change logs, batch operations, impact analysis sessions/details)
- **Substitution tables** (substitution patterns, feature importance, ML models, prediction logs, pattern results)
- **Approval Workflow tables** (approval workflows, levels, requests, decisions, notifications, escalation logs, escalation rules)
- **Conflict Resolution tables** (conflict resolution sessions, options, revalidation schedules, triggers)

**Step 3.3 — Entity-Relationship Summary**

After documenting all tables, provide a textual ER map showing how SmartTimetable tables relate to each other and to external tables from other modules:
- Which `sch_` tables (School Setup module) are referenced?
- Which `std_` tables (Student module) are referenced?
- Which staff/teacher tables are referenced (likely from `sys_` or a staff module)?
- Which subject/syllabus tables are referenced?
- Which room/infrastructure tables are referenced?

**Step 3.4 — Junction Tables**

For every `_jnt` table or bridge table, document:
- Which two entities it connects
- Additional columns beyond the two FKs
- How it is populated (manually vs auto-generated)

---

### PHASE 4: ALGORITHM & LOGIC DOCUMENTATION

**Step 4.1 — Timetable Generation Algorithm (CRITICAL)**

This is the most important section. Read `SmartTimetableController.php`, `GenerateTimetableJob.php`, and all Services in full. Then document:

**4.1.1 — Algorithm Architecture**
- What is the overall approach? (Backtracking + Greedy? Constraint Satisfaction? Hybrid?)
- Is this inspired by the FET (Free Timetabling Software) algorithm? Document specifically what was borrowed vs custom.
- How many passes/phases does generation have? Describe each phase.

**4.1.2 — Pre-Generation Setup**
- What master data must exist before generation can run?
- What validation happens in `ValidationService` before generation starts?
- How are activities built from subject-teacher-class assignments?
- How is the "slot matrix" (days × periods) constructed?
- How is teacher availability pre-processed into a lookup structure?
- How is room availability pre-processed?

**4.1.3 — Core Generation Algorithm (Step-by-Step)**
Walk through the algorithm as implemented in code:
- What is the outer loop? (class-by-class? activity-by-activity? slot-by-slot?)
- What is the inner loop?
- How is the "next activity to schedule" selected? (by priority? by constraint difficulty? random?)
- How is the "best slot" selected for an activity?
- What scoring/heuristic is used when multiple slots are available?
- What happens when no valid slot exists for an activity?
- Does it backtrack? If so, how deep and how does it choose what to un-schedule?
- Is there a randomization component? Where?
- What is the termination condition? (all activities placed? max iterations? time limit?)

**4.1.4 — Tabu Search Optimizer** (`TabuSearchOptimizer.php`)
- What does the Tabu Search phase do (post-generation optimization)?
- What constitutes a "move" in the search space?
- What is the tabu tenure?
- What is the objective function / scoring?
- When does it stop?

**4.1.5 — Simulated Annealing Optimizer** (`SimulatedAnnealingOptimizer.php`)
- What does the SA phase do?
- What is the temperature schedule?
- How are neighbour solutions generated?
- When does SA run vs Tabu Search? Are they alternatives or sequential?

**4.1.6 — Solution Evaluator** (`SolutionEvaluator.php`)
- What metrics does it compute?
- How are hard vs soft constraint violations weighted?
- What is the final score output format?

**4.1.7 — Post-Generation Steps**
- What cleanup/validation runs after generation completes?
- How are `tt_resource_bookings` populated?
- What does `ConflictDetectionService` check after generation?
- How is the generation run status updated?

**4.1.8 — Output**
- Exactly which tables and columns are written as the result of generation?
- What is the structure of `tt_timetable_cells` — one row per period-slot per class? Per teacher?
- How are multi-period (double/triple period) activities stored?

**Step 4.2 — Constraint Engine (Document EVERY Constraint)**

For each constraint found in the code and in `Input/5-Constraints_v1.csv`:

```
CONSTRAINT: [Name]
CATEGORY: [e.g., Teacher Time, Room Availability, Subject Distribution, etc.]
TYPE: Hard (must never be violated) | Soft (preferred, can be relaxed)
IS_HARD (db): [true/false — from tt_constraint_types.is_hard column]
SCOPE: [Teacher / Class / Room / Activity / Global / Inter-Activity]
APPLIED AT: [Pre-generation validation / During backtracking / Post-generation validation / UI-only]
LOGIC: [Exact condition in plain English]
CODE LOCATION: [File::methodName line ~N]
PARAMETER: [Any configurable value — e.g., max_consecutive_periods = 3]
EXAMPLE: [Concrete example]
ON VIOLATION: [Skip slot / Backtrack / Flag in tt_conflict_detections / Block publish / Warn user]
```

Ensure you document **all constraints** from these sources:
- Constraints seeded by `ConstraintTypeSeeder` or similar
- Constraint logic in `ConstraintManager` or equivalent service
- Any hardcoded constraint checks in generation code
- Any soft constraints applied during optimization passes

Common constraints to explicitly verify and document:
- Teacher double-booking (same teacher, same slot, two different classes)
- Class double-booking (same class, same slot, two different subjects)
- Room double-booking (same room, same slot)
- Teacher max periods per day
- Teacher max consecutive periods
- Subject minimum/maximum periods per week per class
- Subject distribution (no two Math periods on same day)
- Lab subject: requires double/triple period block
- Lab subject: requires lab-type room
- Part-time teacher: only available in specified windows
- Teacher day-off preference
- Room capacity vs class strength
- Break/lunch period: no teaching activity in break slots
- Assembly/zero-period rules
- Co-curricular activity placement rules
- Parallel group: same subject taught simultaneously by different teachers to different sections
- Inter-activity constraints (A must come before B, A and B cannot be on same day, etc.)
- Any custom school-defined constraints stored in `tt_constraints` table

**Step 4.3 — Conflict Detection & Resolution**

Document `ConflictDetectionService.php` completely:
- `detectFromGrid()` vs `detectFromCells()` — when each is used and what they check
- All conflict types: TEACHER_CLASH, ROOM_CLASH, CLASS_CLASH, CONSTRAINT_VIOLATION, etc.
- How conflicts are written to `tt_conflict_detections`
- How conflicts are displayed to the user
- Manual resolution flow: `ConflictResolutionSession`, `ConflictResolutionOption`, how user selects and applies
- Auto-resolution: does any conflict type have an automatic fix?
- `RevalidationSchedule` and `RevalidationTrigger` — what triggers automatic revalidation?

**Step 4.4 — Manual Refinement (Swap, Move, Lock)**

Document `RefinementService.php` completely:
- `lockCell()` / `unlockCell()` — what does locking prevent?
- `analyseSwapImpact()` — what does it check and return?
- `swapCells()` — how are two cells exchanged; what validation runs?
- `moveCell()` — move to empty slot; validation?
- `batchSwap()` — how does batch operation work?
- `rollbackBatch()` — how far can it roll back?
- `getChangeLogs()` — what is tracked in `tt_change_logs`?
- `revalidate()` — what services are called after a manual edit?
- UI interaction: two-click swap pattern, impact modal, drag-drop (if implemented)

**Step 4.5 — Parallel Group Handling**

Document `ParallelGroup`, `ParallelGroupActivity`, `ParallelGroupController`:
- What is a parallel group? (Multiple sections taught the same subject simultaneously by different teachers)
- How is a parallel group configured?
- How does the generation algorithm handle parallel groups differently from regular activities?
- How are parallel constraints enforced (same period, potentially same/different rooms)?

**Step 4.6 — ML / Prediction Features**

The module contains `MlModel`, `FeatureImportance`, `PredictionLog`, `PatternResult` models. Document:
- What does the ML model predict or classify?
- How is it trained (if at all within the app)?
- Where is it used — substitution recommendation, constraint violation prediction, or generation guidance?
- How does `SubstitutionService` use pattern learning (`tt_substitution_patterns`, `tt_feature_importance`)?
- Is the ML feature active in current implementation or a future stub?

---

### PHASE 5: BUSINESS LOGIC & WORKFLOW

**Step 5.1 — Complete User Workflow (Step-by-Step)**

Document the full end-to-end workflow a school administrator follows to create a timetable:

```
Step 1: [What the user does first — e.g., "Create Academic Term / Timetable record"]
  - Screen: [screen name]
  - Required: [prerequisite data that must exist]
  - Output: [what is created/configured]

Step 2: [Next step]
  ...

Step N: [Final step — e.g., "Publish Timetable"]
  - What changes on publish?
  - Who gets notified?
  - Can it be un-published?
```

Map each step to the actual screens and routes in the application.

**Step 5.2 — Timetable Lifecycle States**

Document all states a timetable record (`tt_timetables`) can be in:
- All possible `status` values (DRAFT, GENERATING, GENERATED, PUBLISHED, ARCHIVED, FAILED, etc.)
- All transitions between states
- Who/what triggers each transition (user action, background job, system event)
- What is locked/unlocked at each state transition
- What happens to dependent records (cells, bookings, analytics) on each transition

**Step 5.3 — Generation Run Lifecycle**

Document the complete flow of a queued generation:
- User triggers generation → what is created in `tt_generation_runs`?
- How is `GenerateTimetableJob` dispatched (sync or queued, which queue)?
- What does the status polling endpoint return? (`generation-status/{run}` route)
- What does the progress view (`generation/progress.blade.php`) show?
- How are partial results streamed or polled?
- What happens on job failure? How is the error captured?
- Can generation be cancelled mid-run?
- What is `tt_generation_queues` used for vs `tt_generation_runs`?

**Step 5.4 — Substitution Logic**

Document `SubstitutionController.php` and `SubstitutionService.php` completely:
- Absence recording: who records it, what data is entered, what table is written
- Candidate selection: how are substitute teachers found (query details — which tables, which conditions)
- Scoring formula: exact point weights for subject match, availability, workload, past patterns
- Pattern learning: when does `tt_substitution_patterns` get updated? What running averages are computed?
- Approval flow: is there a manager approval step?
- Notification: who is notified when a substitute is assigned?
- History: what is tracked in `tt_substitution_history` or similar?

**Step 5.5 — Approval Workflow**

The module has `ApprovalWorkflow`, `ApprovalLevel`, `ApprovalRequest`, `ApprovalDecision`, `ApprovalNotification`, `EscalationLog`, `EscalationRule` models. Document:
- What entities require approval? (Timetable publish? Substitution assignment? Manual change?)
- How are approval levels configured?
- Who are the approvers at each level?
- What happens when someone approves/rejects?
- Escalation rules: when and to whom does it escalate?
- What notifications are sent and through what channel?

**Step 5.6 — Reports & Exports**

Document every report in the module:

```
REPORT: [Name — e.g., "Teacher Workload Analysis"]
SCREEN: [View file]
ROUTE: [route name]
DATA SOURCE: [Tables and queries]
FILTERS: [Available filter options]
OUTPUT FORMAT: [On-screen table / PDF / CSV / Excel]
EXPORT METHOD: [If CSV — fputcsv to php://temp, etc.]
```

Reports to document:
- Class Timetable (grid view — days × periods)
- Teacher Timetable
- Room Utilization Report
- Teacher Workload Analysis
- Constraint Violation Report
- Generation Quality Report (class coverage %, unplaced activities)
- Activity/Teacher Capacity Report
- Analytics Daily Snapshot
- Any others found in views

**Step 5.7 — Multi-Tenancy Enforcement**

Document how tenant isolation is enforced:
- What middleware resolves the tenant database connection?
- Are `tt_` tables accessed via a `tenant_db` connection or default connection?
- Is there a `tenant_id` column on `tt_` tables, or is isolation by database?
- What happens if a cross-tenant access attempt is made?

**Step 5.8 — Role & Permission Matrix**

For each role that interacts with SmartTimetable, document screens accessible and actions allowed:

| Role | Can View | Can Create | Can Generate | Can Publish | Can Manage Substitutions |
|------|----------|-----------|-------------|-------------|--------------------------|
| Super Admin | All | All | Yes | Yes | Yes |
| School Admin | ... | ... | ... | ... | ... |
| Teacher | Own timetable | No | No | No | (View only) |
| ... | ... | ... | ... | ... | ... |

---

### PHASE 6: TECHNICAL DETAILS

**Step 6.1 — API Endpoints (TimetableApiController)**

For each endpoint in `Api/TimetableApiController.php`:

```
METHOD: GET/POST/PUT/DELETE
URL: /api/v1/timetable/...
ROUTE NAME: [if named]
AUTH: auth:sanctum
REQUEST: { parameter: type, description }
RESPONSE (success): { success: true, data: { structure } }
RESPONSE (error): { success: false, message: "..." }
CONTROLLER METHOD: TimetableApiController::methodName()
PURPOSE: [What this endpoint does]
```

**Step 6.2 — Standard Timetable Views (StandardTimetableController)**

Document the `StandardTimetableController` and its views:
- What is a "Standard Timetable" vs a "Smart Timetable"?
- Which screens does it provide (class view, teacher view, room view)?
- How does it reuse AnalyticsService methods?
- What is the `_grid` partial and how is it rendered?

**Step 6.3 — Validation Service**

Document `ValidationService.php` completely:
- Every validation check it performs (one bullet per check)
- The order in which checks run
- Whether validation is blocking (stops generation) or advisory (warns but allows)
- How validation results are presented in the `validation/index.blade.php` view

**Step 6.4 — Resource Booking Service**

Document `ResourceBookingService.php`:
- What is a resource booking (`tt_resource_bookings`)?
- What resource types are booked (ROOM, TEACHER)?
- When are bookings created? (During generation? On cell creation? On publish?)
- `refreshForCell()` — when is this called and what does it do?
- How do bookings interact with conflict detection?

**Step 6.5 — Queued Jobs & Background Processing**

For each Job in `app/Jobs/`:

```
JOB: [ClassName]
QUEUE: [which queue name]
TIMEOUT: [seconds]
TRIES: [retry count]
TRIGGERED BY: [controller method / event / schedule]
DOES: [what it processes]
SUCCESS: [what is written on success]
FAILURE: [what happens on failure — is_failed flag? exception stored?]
```

**Step 6.6 — Events & Listeners**

Document any Laravel events dispatched and their listeners, including:
- Events related to timetable state transitions
- Events related to generation completion/failure
- Events related to substitution assignment

**Step 6.7 — Caching**

Document any caching used:
- Redis cache keys (if any)
- Cache duration
- What invalidates the cache

**Step 6.8 — Configuration Options**

Document every configurable setting:
- Values in `Modules/SmartTimetable/config/smarttimetable.php`
- Settings stored in `sys_settings` or similar settings table
- `.env` variables referenced
- `tt_generation_strategies` table — what strategies are configurable?
- `tt_priority_configs` table — what priorities are configurable?

---

### PHASE 7: GAP ANALYSIS — Design vs Implementation

This section is unique to this module because development was done iteratively and not all designed features were fully implemented.

**Step 7.1 — Design vs Implementation Comparison**

For each feature defined in the design documents (Phase 0), document:
```
FEATURE: [Feature name from design doc]
DESIGNED IN: [Which design doc mentioned it]
IMPLEMENTATION STATUS:
  - [ ] Not started
  - [~] Partially implemented — [what's done and what's missing]
  - [x] Fully implemented
EVIDENCE: [File/method where implementation was found, or "Not found in codebase"]
GAP DESCRIPTION: [If partial/missing — exactly what is missing]
```

**Step 7.2 — Dead Code / Stub Methods**

List every method that is:
- Defined but never called (dead code)
- A stub returning `// TODO` or empty array
- A backup/old version that should be deleted
- An `_old` view with no active route pointing to it

**Step 7.3 — Debug Code Still Present**

List any remaining:
- `dd()`, `dump()`, `var_dump()` calls
- `Log::debug()` calls that appear to be temporary dev logging
- `debugXxx()` methods in controllers
- Test/seeder methods accidentally left in production controllers

**Step 7.4 — Inconsistencies**

Flag any inconsistencies found:
- A constraint checked in one place but not another
- Column names in code that don't match the DDL (`v7.6`)
- Relationship names in code that differ from the Model definition
- Routes registered but no corresponding view/controller method
- Models defined but not used anywhere

---

### PHASE 8: OUTPUT FORMAT

Compile everything into a single Markdown document saved at:
`/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/5-Work-In-Progress/2-In-Progress/SmartTimetable/SmartTimetable_Module_Documentation.md`

Use this exact structure:

```
# SmartTimetable Module — Complete Technical Documentation
## Generated: [date]
## Source: /Users/bkwork/Herd/prime_ai/Modules/SmartTimetable
## DDL Reference: tt_timetable_ddl_v7.6.sql

---

### 1. Module Overview & Terminology
### 2. Intended Design (from Design Documents)
### 3. File Inventory & Structure
   #### 3.1 Controllers
   #### 3.2 Models (with relationships and table map)
   #### 3.3 Services
   #### 3.4 Jobs
   #### 3.5 Form Requests
   #### 3.6 Policies
   #### 3.7 Migrations (chronological)
   #### 3.8 Seeders
   #### 3.9 Views (active)
   #### 3.10 Views (deprecated — _old)
   #### 3.11 Assets / JS
   #### 3.12 Tests
### 4. Menu & Navigation Map
### 5. User Workflow (End-to-End Steps)
### 6. Screen-by-Screen Walkthrough
   #### 6.1 [Screen Name]
   ... (one section per screen)
### 7. Database Schema
   #### 7.1 Table Definitions (one subsection per table)
   #### 7.2 Table Groups & Functional Areas
   #### 7.3 Entity-Relationship Summary
   #### 7.4 Junction Tables
   #### 7.5 Cross-Module Table Dependencies
### 8. Data Flow — Operation by Operation
   #### 8.1 [Operation Name]
   ... (one section per operation)
### 9. Timetable Generation Algorithm
   #### 9.1 Algorithm Architecture & FET Influence
   #### 9.2 Pre-Generation Setup
   #### 9.3 Core Algorithm Step-by-Step
   #### 9.4 Tabu Search Optimizer
   #### 9.5 Simulated Annealing Optimizer
   #### 9.6 Solution Evaluator & Scoring
   #### 9.7 Post-Generation Processing
   #### 9.8 Generation Pseudocode
### 10. Constraint Engine
   #### 10.1 Hard Constraints (Full List)
   #### 10.2 Soft Constraints (Full List)
   #### 10.3 Constraint Application Matrix (Stage × Constraint)
   #### 10.4 ConstraintManager / ConstraintFactory Implementation
### 11. Conflict Detection & Resolution
### 12. Manual Refinement & Drag-Drop Logic
### 13. Parallel Group Handling
### 14. Timetable Lifecycle & States
### 15. Generation Run Lifecycle & Job Queue
### 16. Substitution Management
### 17. Approval Workflow
### 18. ML / Prediction Features
### 19. Validation Service
### 20. Resource Booking Service
### 21. Reporting & Exports
### 22. API Endpoints
### 23. Standard Timetable Views
### 24. Multi-Tenancy Enforcement
### 25. Role & Permission Matrix
### 26. Events, Jobs & Caching
### 27. Configuration Options
### 28. Cross-Module Dependencies
### 29. Gap Analysis: Design vs Implementation
   #### 29.1 Feature Implementation Status
   #### 29.2 Dead Code / Stubs
   #### 29.3 Debug Code Still Present
   #### 29.4 Inconsistencies Found
### 30. Appendix A — Method Reference Index
    (Format: ClassName::methodName(params): returnType — one line description)
### 31. Appendix B — Table × Operation Matrix
    (Which operations read/write which tables — rows=tables, cols=operations)
```

---

### CRITICAL INSTRUCTIONS FOR CLAUDE AGENT:

1. **Read FIRST, Write LATER.** Do not start writing the document until you have completed ALL reading (Phases 0–1). Use the first pass purely for reading and mental model building.

2. **Design docs first.** Phase 0 (design documents) must be read BEFORE Phase 1 (code). This gives you the intended design to compare against the actual implementation.

3. **Do NOT skip files.** Every `.php`, `.blade.php`, `.js`, `.json`, `.sql`, `.csv`, and `.md` file must be read. No exceptions.

4. **Do NOT assume or guess.** If something cannot be determined from the code, write: `⚠️ UNDETERMINED: Could not confirm from code — needs developer clarification.`

5. **Trace every query.** For every `DB::table()`, Eloquent query, or raw SQL — document the exact table, columns, and where conditions.

6. **Document every column.** Don't say "fetches teacher data" — say "fetches `id`, `name` from `staff_profiles` table where `is_active = 1` and tenant connection."

7. **Include method signatures.** For every important method: `ClassName::methodName(Type $param, ...): ReturnType`

8. **Flag `_old` views.** For every view file or folder suffixed with `_old`, note: what it contained, which new view replaced it, and whether the old code is still referenced anywhere.

9. **Flag dead code.** Any method defined but never called should be listed in Section 29.2.

10. **Prefer specific over general.** Section 9 (Algorithm) should be the longest section. Include pseudocode. Show the actual PHP logic in plain English. Do not write a generic "backtracking algorithm" description — describe THIS specific implementation.

11. **Output length is unlimited.** Expect 8,000–20,000+ lines. Do not truncate or summarize. Every table, every method, every constraint must be individually documented.

12. **Cross-reference DDL vs Models.** For every Model, verify its fillable and relationship definitions match the `tt_timetable_ddl_v7.6.sql` schema. Flag any mismatches.

13. **Track section completeness.** If you cannot complete a section in one run, write `⚠️ SECTION INCOMPLETE — continue in next run.` at the end of the section so the next run knows where to resume.

---

### EXECUTION PLAN FOR CLAUDE AGENT:

Execute in this strict order across multiple runs if needed:

**Run 1 — Context & Discovery**
1. Read all design documents (Phase 0: all files in `Design_docs/`, `Input/`, `V6/`, `Claude_Context/`)
2. Read `tt_timetable_ddl_v7.6.sql` completely
3. Read `module.json`, `composer.json`, route files (`routes/web.php`, `routes/api.php`, app-level `routes/tenant.php`)
4. Scan and list all files in the module (Phase 1.2)
5. Write Sections 1 (Overview & Terminology), 2 (Intended Design), 3 (File Inventory), 4 (Menu Map)

**Run 2 — Screens & Database**
1. Read all Blade views (active views first, then `_old` views)
2. Read all Models
3. Write Sections 5 (User Workflow), 6 (Screen-by-Screen), 7 (Database Schema)

**Run 3 — Data Flows**
1. Read all Controllers + Form Requests
2. Write Section 8 (Data Flow — every operation, every controller method)

**Run 4 — Algorithm & Constraints**
1. Read `SmartTimetableController.php`, `GenerateTimetableJob.php`, all Services
2. Write Sections 9 (Algorithm), 10 (Constraints), 11 (Conflict Detection)

**Run 5 — Advanced Features**
1. Read `RefinementService.php`, `SubstitutionService.php`, `AnalyticsService.php`, `ValidationService.php`, `ResourceBookingService.php`
2. Read all Approval Workflow models and any related controllers
3. Write Sections 12–26

**Run 6 — Gap Analysis & Appendices**
1. Compare design docs (Phase 0 notes) against implemented features
2. Write Sections 27–29 (Configuration, Dependencies, Gap Analysis)
3. Write Appendix A (Method Index) and Appendix B (Table × Operation Matrix)

**Run 7 — Review Pass**
1. Re-read the complete output document
2. Cross-check every claim against source files
3. Fill any `⚠️ UNDETERMINED` markers
4. Verify all method signatures are correct
5. Verify all table names match the DDL

Save progress after each run to `{{OUTPUT_FILE}}`. Append in subsequent runs — do not overwrite.

---

*End of Prompt v2*
