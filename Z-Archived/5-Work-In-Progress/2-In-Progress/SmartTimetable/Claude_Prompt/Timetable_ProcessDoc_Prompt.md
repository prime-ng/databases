# SmartTimetable Module — Comprehensive Documentation Generation Prompt

## 📋 CONFIGURATION SECTION (Edit paths before running)

```yaml
# ──────────────────────────────────────────────────────
# CONFIGURE THESE PATHS BEFORE PROVIDING TO CLAUDE AGENT
# ──────────────────────────────────────────────────────

MODULE_ROOT: "modules/SmartTimetable"
ROUTES_FILE: "routes/web.php"                    # Or module-specific: "modules/SmartTimetable/routes/web.php"
API_ROUTES_FILE: "routes/api.php"                # If API routes exist separately
MIGRATION_PATH: "database/migrations"            # Or module-specific migration path
SEEDERS_PATH: "database/seeders"                 # If seeders exist
CONFIG_PATH: "config"                            # App-level config files
SERVICES_PATH: "modules/SmartTimetable/Services" # If services are in a subfolder
HELPERS_PATH: "modules/SmartTimetable/Helpers"   # If helper classes exist
TRAITS_PATH: "modules/SmartTimetable/Traits"     # If traits are used
MIDDLEWARE_PATH: "app/Http/Middleware"            # Relevant middleware
LIVEWIRE_PATH: "modules/SmartTimetable/Livewire" # If Livewire components exist
JS_ASSETS_PATH: "resources/js"                   # Alpine.js / JS files if relevant
TENANT_DB_PREFIX: "tenant_"                      # Tenant database prefix if applicable
OUTPUT_FILE: "docs/SmartTimetable_Module_Documentation.md"
```

---

## 🎯 MASTER PROMPT — Provide everything below (including config above) to Claude Agent

---

You are a senior software architect performing a **complete reverse-engineering documentation** of a Laravel module. Your goal is to produce an exhaustive, human-readable document that allows any developer (or AI agent) to fully understand what the SmartTimetable module does, how it does it, and why — without needing to read the source code.

### PHASE 1: DISCOVERY — Read & Index All Files

**Step 1.1 — Module Structure Scan**

Read the complete directory tree under `{{MODULE_ROOT}}`. List every file and folder. Categorize each file into:
- Controllers
- Models (with table names, fillable fields, relationships, casts, accessors, mutators, scopes)
- Views / Blade templates / Livewire components
- Migrations (in chronological order)
- Services / Actions / Jobs / Events / Listeners
- Requests (Form Requests with validation rules)
- Traits
- Helpers / Utility classes
- Config files
- Route definitions (read `{{ROUTES_FILE}}` and `{{API_ROUTES_FILE}}` — extract only routes belonging to this module)
- Seeders / Factories
- JavaScript / Alpine.js files
- Any other files (enums, interfaces, DTOs, etc.)

**Step 1.2 — Read Every File Completely**

For each file discovered above, read its **full content**. Do not skip or summarize code at this stage. You need complete understanding before writing documentation.

**Step 1.3 — Cross-Reference Check**

After reading the module files, also check these locations for any related code:
- `app/Models/` — for any models used by SmartTimetable but defined outside the module
- `app/Http/Middleware/` — for middleware applied to SmartTimetable routes
- `{{LIVEWIRE_PATH}}` — for Livewire components
- `{{JS_ASSETS_PATH}}` — for Alpine.js or vanilla JS used by SmartTimetable views
- `config/` — for any config keys referenced in SmartTimetable code
- `database/migrations/` — for migrations outside the module folder that create tables used by SmartTimetable

---

### PHASE 2: ANALYSIS — Understand Every Operation

For each Controller method, Service method, Livewire action, and Job, trace the **complete data flow**:

**Step 2.1 — Menu & Navigation Mapping**

Document every menu item, sub-menu item, tab, and navigation link that falls under the Timetable module:
- Menu label as shown to user
- Route name and URL
- Controller@method or Livewire component it maps to
- Permission/role guard (if any)
- Which sidebar/nav group it belongs to

**Step 2.2 — Screen-by-Screen Walkthrough**

For every unique screen (Blade view or Livewire component):
- **Screen Name / Title** as displayed to the user
- **URL Pattern** and route name
- **Purpose** — what the user does on this screen
- **UI Elements** — forms, tables, dropdowns, buttons, tabs, modals (describe what each does)
- **Data Loaded on Page Load** — which tables/columns are queried, any eager loading, any computed values
- **User Actions Available** — what buttons/links the user can click, what form fields they fill
- **On Submit / On Action** — trace exactly what happens: validation → processing → DB writes → response

**Step 2.3 — Data Flow Tracing (CRITICAL — Be Exhaustive)**

For every operation that reads or writes data, document in this exact format:

```
OPERATION: [Name of the operation, e.g., "Generate Period Structure"]
TRIGGER: [What triggers it — button click, form submit, scheduled job, etc.]
INPUT SOURCE:
  - Table: [table_name] → Columns: [col1, col2, col3] → Filter/Where: [conditions]
  - Table: [table_name] → Columns: [...] → Join with: [other_table on condition]
  - User Input: [form field names and what they contain]
PROCESSING:
  - Step 1: [Describe transformation, calculation, or logic]
  - Step 2: [Next step...]
  - ...
CALCULATIONS (if any):
  - [Variable/Column] = [Formula or logic in plain English]
  - Example: periods_per_day = (end_time - start_time - total_break_duration) / period_duration
OUTPUT TARGET:
  - Table: [table_name] → Columns Written: [col1 = value_source, col2 = value_source, ...]
  - Table: [table_name] → Columns Written: [...]
VALIDATION/CONSTRAINTS AT THIS STAGE:
  - [Constraint 1]
  - [Constraint 2]
ERROR HANDLING:
  - [What happens if X fails]
```

Repeat this for **every single operation** — no matter how small. Include CRUD operations, bulk operations, import/export, AJAX calls, everything.

---

### PHASE 3: DATABASE SCHEMA DOCUMENTATION

**Step 3.1 — Complete Table Inventory**

For every table used by the SmartTimetable module (including tables from other modules it reads/writes):

```
TABLE: [table_name]
DATABASE: [tenant_db / prime_db / global_db]
CREATED BY MIGRATION: [migration filename]
PURPOSE: [What this table stores]
COLUMNS:
  - id (bigint, PK, auto-increment)
  - [column_name] ([type], [nullable?], [default], [index?]) — [purpose/description]
  - ...
RELATIONSHIPS:
  - belongsTo: [related_table] via [foreign_key]
  - hasMany: [related_table] via [foreign_key]
  - belongsToMany: [related_table] via [junction_table] (junction columns: [...])
  - ...
INDEXES: [List all indexes including composite indexes]
JSON COLUMNS: [If any _json columns exist, document their expected structure]
SOFT DELETES: [Yes/No]
TIMESTAMPS: [Yes/No]
TENANT-SCOPED: [Yes/No — is this table per-tenant or global?]
```

**Step 3.2 — Entity-Relationship Summary**

After documenting all tables, provide a textual ER summary showing how all SmartTimetable tables relate to each other and to external tables (from other modules like Students, Teachers, Classes, Subjects, Rooms, etc.).

**Step 3.3 — Junction Tables**

For every junction table (especially those suffixed `_jnt`), document:
- Which two (or more) entities it connects
- Any additional columns beyond the two FKs (e.g., is_primary, priority, effective_from)
- How it is populated (manually by user, auto-generated, or derived)

---

### PHASE 4: ALGORITHM & LOGIC DOCUMENTATION

**Step 4.1 — Timetable Generation Algorithm**

This is the most critical section. Document the **complete algorithm** used to generate timetables:

1. **Algorithm Name/Type** — Is it constraint-satisfaction, backtracking, greedy, genetic algorithm, simulated annealing, or a custom hybrid? Identify the approach.
2. **Input Data Required** — What master data must exist before generation can run? (Teachers, Subjects, Classes, Rooms, Period structure, Constraints, etc.)
3. **Pre-Processing Steps** — Any data preparation, slot creation, availability matrix building, etc.
4. **Core Algorithm Steps** — Walk through the algorithm step-by-step:
   - What is the order of assignment? (e.g., does it assign class-by-class, period-by-period, or subject-by-subject?)
   - How does it pick the next slot to fill?
   - How does it pick the next teacher/subject/room to assign?
   - What happens when a conflict is detected?
   - Does it backtrack? If so, how deep?
   - Is there randomization? If so, where and why?
   - What is the termination condition?
5. **Post-Processing Steps** — Any cleanup, optimization pass, gap filling, or validation after initial generation.
6. **Output** — What tables/columns are populated as the final result of generation?

**Step 4.2 — Constraint Engine**

Document every constraint the system enforces. For each constraint:

```
CONSTRAINT: [Name/Description]
TYPE: [Hard constraint (must never be violated) / Soft constraint (preferred but can be relaxed)]
APPLIED AT: [Pre-processing / During generation / Post-validation / UI-level only]
LOGIC: [Exact condition in plain English]
CODE LOCATION: [File and method where this is enforced]
EXAMPLE: [A concrete example of this constraint in action]
WHAT HAPPENS ON VIOLATION: [Error message / Skipped / Flagged for manual review / etc.]
```

Common constraints to look for (document all you find, plus any others):
- Teacher cannot be in two places at the same time
- Class cannot have two subjects at the same time
- Room capacity vs. class strength
- Teacher maximum periods per day / per week
- Subject minimum/maximum periods per week per class
- Consecutive period limits (e.g., no more than 2 consecutive periods for a teacher)
- Break/lunch period enforcement
- Lab subjects requiring double/triple periods
- Teacher day-off preferences
- Subject distribution across the week (e.g., no two Math periods on same day)
- Room type matching (lab subjects need lab rooms)
- Part-time teacher availability windows
- Substitute teacher constraints
- Section-specific vs. shared teacher constraints
- Co-curricular / activity period placement rules
- Assembly / zero-period rules
- Any custom constraints defined by school administrators

**Step 4.3 — Conflict Detection & Resolution**

- How does the system detect conflicts?
- What types of conflicts exist? (Teacher clash, Room clash, Subject clash, etc.)
- How are conflicts reported to the user?
- Can the user manually resolve conflicts? If so, through which screen and what actions?
- Is there an automatic conflict resolution mechanism?

**Step 4.4 — Manual Adjustments & Drag-Drop Logic**

If the module supports manual timetable editing (drag-drop, swap, manual assignment):
- What UI is used? (Grid, calendar, Kanban-style?)
- What validations run on manual placement?
- What happens if a manual placement creates a conflict?
- Is there an undo mechanism?
- How are manual overrides persisted vs. auto-generated entries?

---

### PHASE 5: BUSINESS LOGIC & WORKFLOW

**Step 5.1 — Workflow States**

If the timetable has lifecycle states (Draft → Published → Active → Archived), document:
- All possible states
- Transitions between states
- Who can trigger each transition
- What happens on each transition (data changes, notifications, locks, etc.)

**Step 5.2 — Multi-Tenancy Behavior**

- How does the module behave in a multi-tenant setup?
- Which data is tenant-specific vs. shared?
- How is tenant isolation enforced?

**Step 5.3 — Role & Permission Matrix**

For each role that interacts with the Timetable module, document:
- What screens they can access
- What actions they can perform (view, create, edit, delete, generate, publish, etc.)
- Any data-level restrictions (e.g., teacher can only see their own timetable)

**Step 5.4 — Substitution Logic (if present)**

- How does the system handle teacher absence?
- How are substitute teachers selected?
- What constraints apply to substitution?
- How is substitution recorded and displayed?

**Step 5.5 — Reports & Exports**

Document every report or export feature:
- Report name and purpose
- Data source (tables, queries)
- Filters available
- Output format (PDF, Excel, on-screen)

---

### PHASE 6: TECHNICAL DETAILS

**Step 6.1 — API Endpoints**

For each API endpoint (if any):
- HTTP Method + URL
- Request parameters / body
- Response structure
- Authentication/authorization

**Step 6.2 — Events & Listeners**

Document any events dispatched and their listeners.

**Step 6.3 — Queued Jobs**

Document any jobs that run in the background (e.g., timetable generation as a queued job).

**Step 6.4 — Caching**

Document any caching used (Redis keys, cache duration, invalidation triggers).

**Step 6.5 — Configuration Options**

Document any configurable settings (from config files, database settings table, or .env).

---

### PHASE 7: OUTPUT FORMAT

Compile everything into a single Markdown document saved at `{{OUTPUT_FILE}}` with this structure:

```
# SmartTimetable Module — Complete Technical Documentation
## Generated on: [date]
## Source: {{MODULE_ROOT}}

### 1. Module Overview
### 2. File Inventory & Structure
### 3. Menu & Navigation Map
### 4. Screen-by-Screen Walkthrough
   #### 4.1 [Screen Name 1]
   #### 4.2 [Screen Name 2]
   ...
### 5. Database Schema
   #### 5.1 Table Definitions
   #### 5.2 Entity-Relationship Summary
   #### 5.3 Junction Tables
### 6. Data Flow — Operation by Operation
   #### 6.1 [Operation Name 1]
   #### 6.2 [Operation Name 2]
   ...
### 7. Timetable Generation Algorithm
   #### 7.1 Algorithm Overview
   #### 7.2 Step-by-Step Walkthrough
   #### 7.3 Pseudocode
### 8. Constraint Engine
   #### 8.1 Hard Constraints
   #### 8.2 Soft Constraints
   #### 8.3 Constraint Application Matrix (which constraint at which stage)
### 9. Conflict Detection & Resolution
### 10. Manual Editing & Drag-Drop Logic
### 11. Workflow States & Lifecycle
### 12. Substitution Logic
### 13. Role & Permission Matrix
### 14. Reports & Exports
### 15. API Endpoints
### 16. Events, Jobs & Caching
### 17. Configuration Options
### 18. Cross-Module Dependencies
### 19. Known Gaps / TODOs / Incomplete Implementations
### 20. Appendix — Method Reference Index
```

### IMPORTANT INSTRUCTIONS FOR CLAUDE AGENT:

1. **Read FIRST, Write LATER.** Do not start writing the document until you have read and understood ALL files in the module. Use the first pass purely for reading and building a mental model.
2. **Do NOT skip files.** Every `.php`, `.blade.php`, `.js`, `.json`, `.yaml`, and migration file must be read.
3. **Do NOT assume or guess.** If you cannot determine something from the code, explicitly state: "⚠️ Could not determine from code — needs developer clarification."
4. **Trace every query.** If you see `DB::table()`, Eloquent calls, or raw SQL, document the exact table and columns involved.
5. **Document calculated fields.** If a value is computed (not directly from a DB column), show the calculation formula.
6. **Be specific about column names.** Don't say "fetches teacher data" — say "fetches `id`, `name`, `email` from `teachers` table where `is_active` = 1 and `tenant_id` = current tenant."
7. **Include method signatures.** For every important method, include: `ClassName::methodName(parameters) : returnType`
8. **Flag dead code.** If you find methods that are defined but never called, flag them as potentially dead code.
9. **Flag inconsistencies.** If you find conflicting logic (e.g., a constraint checked in one place but not another), flag it.
10. **Output file size is unlimited.** This document should be as long as it needs to be. Expect 5,000–15,000+ lines for a complex module. Do not truncate.

---

### EXECUTION PLAN FOR CLAUDE AGENT:

Given the size of this task, execute in this order:
1. **Run 1:** Read all files, produce Sections 1–3 (Overview, File Inventory, Menu Map)
2. **Run 2:** Produce Sections 4–5 (Screens, Database Schema)
3. **Run 3:** Produce Section 6 (Data Flow — all operations)
4. **Run 4:** Produce Sections 7–9 (Algorithm, Constraints, Conflicts)
5. **Run 5:** Produce Sections 10–20 (Everything else, Appendix)
6. **Run 6:** Review pass — read the full output document, cross-check against source files, fix any gaps or errors.

If you hit token/quota limits, save progress to `{{OUTPUT_FILE}}` after each run and continue appending in the next run.

---

*End of Prompt*
