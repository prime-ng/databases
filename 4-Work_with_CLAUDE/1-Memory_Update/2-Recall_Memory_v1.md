# AI Brain Memory Recall Prompts — v1
# Prime-AI ERP/LMS/LXP Project
# ============================================================
# PURPOSE : Prompts to RECALL/REFRESH context from AI Brain into a session.
#           This file does NOT update any AI Brain files — read only.
#
# HOW TO USE:
#   1. Find the right Tier for your situation (see Quick Reference at bottom)
#   2. Edit CONFIGURATION values at the top of that Tier
#   3. Copy-paste the prompt block into Claude Code
#
# PATHS SOURCED FROM: AI_Brain/config/paths.md (single source of truth)
# ============================================================


=====================================================================================================================
## RESOLVED PATHS  (sourced from AI_Brain/config/paths.md — DO NOT hardcode elsewhere)
=====================================================================================================================

  OLD_REPO      = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases
  DB_REPO       = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase
  AI_BRAIN      = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain
  LARAVEL_REPO  = /Users/bkwork/Herd/prime_ai

  # Schema / DDL
  DDL_DIR       = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase/1-Master_DDLs
  GLOBAL_DDL    = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase/1-Master_DDLs/global_db_v2.sql
  PRIME_DDL     = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase/1-Master_DDLs/prime_db_v2.sql
  TENANT_DDL    = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase/1-Master_DDLs/tenant_db_v2.sql
  MODULE_DDL    = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase/1-Module_DDLs

  # Planning & Design
  PROJECT_PLAN  = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/3-Project_Planning
  DESIGN_ARCH   = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/3-Design_Architecture
  RBS_DIR       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/3-Project_Planning/1-RBS
  GAP_ANALYSIS  = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/3-Project_Planning/2-Gap_Analysis
  WORK_STATUS   = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/3-Project_Planning/9-Work_Status
  WORK_IN_PROG  = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/5-Work-In-Progress
  TEMP_OUTPUT   = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/8-Temp_Output

  # AI Brain sub-folders
  BRAIN_MEMORY  = AI_BRAIN/memory/      # project-context, modules-map, tenancy-map, db-schema, architecture, conventions…
  BRAIN_STATE   = AI_BRAIN/state/       # progress.md, decisions.md  (living state — always prefer over memory/ copies)
  BRAIN_LESSONS = AI_BRAIN/lessons/     # known-issues.md
  BRAIN_RULES   = AI_BRAIN/rules/       # tenancy, module, security, laravel, code-style, school rules
  BRAIN_AGENTS  = AI_BRAIN/agents/      # role guides: developer, db-architect, module-agent, debugger …
  BRAIN_TMPL    = AI_BRAIN/templates/   # code boilerplates: model, controller, service, migration, tests …
  BRAIN_CONFIG  = AI_BRAIN/config/      # paths.md (path config)
  BRAIN_TASKS   = AI_BRAIN/tasks/       # active/, backlog/, completed/



=====================================================================================================================
## Tier 0 — Mid-Session Quick Refresh                             Model: claude-sonnet-4-6 | ~30 sec
=====================================================================================================================
When: Context was compressed (/compact) mid-session and Claude lost the working thread.
      You are still in the same session — do NOT reload the full brain. Reload just enough.

---

### CONFIGURATION
  MODULE         = HPC           # Module being worked on right now
  TASK_IN_HAND   = [1-line description of what we were doing before /compact]

  AI_BRAIN       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain

---

Context was compressed. Reload working state for: {{MODULE}}

Read ONLY these files — do not read anything else:
  1. AI_Brain/state/progress.md            → find the {{MODULE}} entry only
  2. AI_Brain/lessons/known-issues.md      → find the {{MODULE}} section only
  3. AI_Brain/memory/modules-map.md        → find the {{MODULE}} row only

Task in hand before compact: {{TASK_IN_HAND}}

After reading, confirm:
  - Current completion % for {{MODULE}}
  - What has been done vs what is pending
  - Resume: pick up exactly where we left off

Do NOT generate any code yet — just confirm you have context and are ready to continue.

---



=====================================================================================================================
## Tier 1 — Start My Day                                          Model: claude-sonnet-4-6 | ~3-5 min
=====================================================================================================================
When: Beginning of a new work session. Load yesterday's state and plan today's work.
      Use this every morning before touching any code.

---

### CONFIGURATION
  PRIMARY_MODULE  = HPC          # Main module to work on today
  MODULE_DIR      = Hpc          # File path: Modules/Hpc/
  BRANCH          = Brijesh_HPC
  DEVELOPER       = Shailesh
  TODAY_DATE      = 26 Mar 2026

  AI_BRAIN        = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain
  LARAVEL_REPO    = /Users/bkwork/Herd/prime_ai
  WORK_IN_PROG    = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/5-Work-In-Progress

---

### Morning Context Load — {{TODAY_DATE}}

  Module: {{PRIMARY_MODULE}} | Branch: {{BRANCH}} | Developer: {{DEVELOPER}}
  AI Brain: {{AI_BRAIN}}

  You are Claude Code working on Prime-AI, a multi-tenant school ERP + LMS + LXP (Laravel + MySQL).
  Load context from AI Brain and prepare for today's session. Do NOT write or update any files.

### Step 1 — Load project identity (read in order)
  1. AI_Brain/config/paths.md              ← resolve all path variables
  2. AI_Brain/memory/project-context.md    ← project overview and goals
  3. AI_Brain/memory/tenancy-map.md        ← 3-layer DB architecture (CRITICAL)
  4. AI_Brain/memory/conventions.md        ← naming rules and code patterns

### Step 2 — Load current state
  5. AI_Brain/state/progress.md            ← find {{PRIMARY_MODULE}} entry + overall project status
  6. AI_Brain/memory/modules-map.md        ← find {{PRIMARY_MODULE}} row (counts, completion %)
  7. AI_Brain/lessons/known-issues.md      ← find {{PRIMARY_MODULE}} section (open bugs)
  8. AI_Brain/state/decisions.md           ← find any {{PRIMARY_MODULE}} decisions

### Step 3 — Load yesterday's context (if exists)
  Check: {{WORK_IN_PROG}}/{{MODULE_DIR}}/Claude_Context/
  Read the most recently modified context file in that folder (if any).
  Also check: {{WORK_IN_PROG}}/0-CLAUDE_Session_Log/ for any session logs from yesterday.

### Step 4 — Check recent git changes
  Run: git -C {{LARAVEL_REPO}} log --oneline --since="yesterday" --author="{{DEVELOPER}}" -- Modules/{{MODULE_DIR}}/
  This shows what was committed yesterday.

### Step 5 — Morning briefing
  Output a structured briefing:

  ## Morning Briefing — {{TODAY_DATE}}
  **Module:** {{PRIMARY_MODULE}} | **Completion:** [X]%
  **Branch:** {{BRANCH}}

  ### Where We Left Off
  [What was in progress / resume-from note from progress.md]

  ### Open Issues ({{PRIMARY_MODULE}})
  [List open bugs/gaps from known-issues.md — top 3 only]

  ### Yesterday's Commits
  [From git log output]

  ### Suggested First Task Today
  [Based on progress.md + open issues — recommend what to tackle first]

  ### Rules Reminder
  [1-2 critical rules from tenancy-rules.md most relevant to today's work]

---



=====================================================================================================================
## Tier 2 — Start a Brand New Module                              Model: claude-opus-4-6 | ~5-8 min
=====================================================================================================================
When: Beginning development of a module that has NOT been touched before.
      Load full project context + all rules + templates before writing a single line of code.

---

### CONFIGURATION
  MODULE         = Hostel        # New module name (as it appears in modules-map)
  MODULE_DIR     = Hostel        # Directory name: Modules/Hostel/
  TABLE_PREFIX   = hos           # DB table prefix
  BRANCH         = Brijesh_Hostel
  DEVELOPER      = Shailesh
  AGENT_ROLE     = module-agent  # Options: developer | module-agent | db-architect | api-builder

  AI_BRAIN       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain
  LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai
  DDL_DIR        = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase/1-Master_DDLs
  TENANT_DDL     = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase/1-Master_DDLs/tenant_db_v2.sql
  GAP_ANALYSIS   = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/3-Project_Planning/2-Gap_Analysis
  RBS_DIR        = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/3-Project_Planning/1-RBS

---

### New Module Context Load — {{MODULE}}

  Module: {{MODULE}} | Directory: Modules/{{MODULE_DIR}}/ | Table prefix: {{TABLE_PREFIX}}
  Branch: {{BRANCH}} | Developer: {{DEVELOPER}}
  AI Brain: {{AI_BRAIN}} | Code: {{LARAVEL_REPO}}

  You are Claude Code working on Prime-AI. Load ALL context before we write anything.
  This is a new module — no prior session context exists. Do NOT write or update any files.

### Step 1 — Project identity & architecture (read ALL)
  1. AI_Brain/config/paths.md              ← path resolution
  2. AI_Brain/memory/project-context.md    ← project overview
  3. AI_Brain/memory/tenancy-map.md        ← 3-layer DB (CRITICAL — read carefully)
  4. AI_Brain/memory/architecture.md       ← system architecture and patterns
  5. AI_Brain/memory/conventions.md        ← naming conventions (tables, files, routes)
  6. AI_Brain/memory/school-domain.md      ← school business rules (Indian K-12 context)

### Step 2 — Rules (read ALL — these are mandatory)
  7.  AI_Brain/rules/tenancy-rules.md      ← NEVER cross DB layers
  8.  AI_Brain/rules/module-rules.md       ← module structure rules
  9.  AI_Brain/rules/security-rules.md     ← auth, Gate, policy requirements
  10. AI_Brain/rules/laravel-rules.md      ← Laravel conventions
  11. AI_Brain/rules/code-style.md         ← PSR-12 + project style

### Step 3 — Role guide & templates
  12. AI_Brain/agents/{{AGENT_ROLE}}.md          ← role-specific instructions
  13. AI_Brain/templates/module-structure.md     ← new module scaffold
  14. AI_Brain/templates/module-controller.md    ← controller boilerplate
  15. AI_Brain/templates/module-service.md       ← service boilerplate
  16. AI_Brain/templates/model.md                ← Eloquent model boilerplate
  17. AI_Brain/templates/form-request.md         ← validation request boilerplate
  18. AI_Brain/templates/tenant-migration.md     ← migration boilerplate

### Step 4 — Module-specific context
  19. AI_Brain/memory/modules-map.md       ← find {{MODULE}} row: scope, planned tables, status
  20. AI_Brain/state/progress.md           ← find {{MODULE}} entry: any prior notes
  21. AI_Brain/lessons/known-issues.md     ← find {{MODULE}} section: known gotchas

  Then scan for requirements:
  22. Read {{TENANT_DDL}} → grep for `CREATE TABLE {{TABLE_PREFIX}}_` → list all tables for this module
  23. Read {{GAP_ANALYSIS}}/ → find any gap analysis file for {{MODULE}} (if exists)
  24. Read {{RBS_DIR}}/ → find any RBS file for {{MODULE}} (if exists)

### Step 5 — Existing code check
  25. Run: ls {{LARAVEL_REPO}}/Modules/{{MODULE_DIR}}/ 2>/dev/null || echo "Module directory not created yet"
  (If directory exists, list contents — do not read files yet, just inventory what's there)

### Step 6 — Ready report
  Output before writing any code:

  ## Module Context Loaded — {{MODULE}}
  **Table prefix:** {{TABLE_PREFIX}} | **Tables found in DDL:** [count + names]
  **Requirements docs found:** [yes/no — list files]
  **Prior progress notes:** [from progress.md]
  **Open issues:** [from known-issues.md — or "none recorded"]
  **Existing code:** [list of existing files — or "directory not created yet"]

  ### Key Rules for This Module
  [3-5 most relevant rules from the rules files for this specific module type]

  ### Suggested Implementation Order
  [Based on templates + module scope — proposed sequence of what to build first]

  Ready to start. Awaiting your instruction.

---



=====================================================================================================================
## Tier 3 — Resume Work on In-Progress Module                     Model: claude-sonnet-4-6 | ~3-5 min
=====================================================================================================================
When: Picking up a module that was partially built in a previous session.
      The module has existing code, open tasks, and prior Claude context files.

---

### CONFIGURATION
  MODULE         = HPC
  MODULE_DIR     = Hpc
  TABLE_PREFIX   = hpc
  BRANCH         = Brijesh_HPC
  DEVELOPER      = Shailesh

  AI_BRAIN       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain
  LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai
  WORK_IN_PROG   = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/5-Work-In-Progress

---

### Resume Module Context — {{MODULE}}

  Module: {{MODULE}} | Directory: Modules/{{MODULE_DIR}}/ | Branch: {{BRANCH}}
  Developer: {{DEVELOPER}}
  AI Brain: {{AI_BRAIN}} | Code: {{LARAVEL_REPO}}

  You are Claude Code working on Prime-AI. Load context to resume in-progress work.
  Do NOT write or update any files during this context load.

### Step 1 — Core context (read in order)
  1. AI_Brain/config/paths.md
  2. AI_Brain/memory/tenancy-map.md        ← 3-layer DB (CRITICAL)
  3. AI_Brain/memory/conventions.md        ← naming conventions
  4. AI_Brain/rules/tenancy-rules.md       ← tenancy isolation rules
  5. AI_Brain/rules/module-rules.md        ← module rules

### Step 2 — Module-specific state
  6. AI_Brain/state/progress.md            ← find {{MODULE}} entry: what's done, what's pending, resume note
  7. AI_Brain/memory/modules-map.md        ← find {{MODULE}} row: counts, completion %, scope
  8. AI_Brain/lessons/known-issues.md      ← find {{MODULE}} section: open bugs and gaps
  9. AI_Brain/state/decisions.md           ← find {{MODULE}} decisions: architectural choices made

### Step 3 — Prior Claude context (most important for continuity)
  Check {{WORK_IN_PROG}}/{{MODULE_DIR}}/Claude_Context/
  Read the latest context file (highest date in filename).
  If multiple files, read the most recent one first; read earlier ones only if the latest references them.

### Step 4 — Existing code inventory
  Run: find {{LARAVEL_REPO}}/Modules/{{MODULE_DIR}}/ -name "*.php" | sort
  (List only — do not read files yet)

  Then read ONLY:
  - The routes file: Modules/{{MODULE_DIR}}/routes/
  - The main controller: (identify from routes, read only that one)

### Step 5 — Recent commits
  Run: git -C {{LARAVEL_REPO}} log --oneline -15 -- Modules/{{MODULE_DIR}}/

### Step 6 — Resume briefing
  Output:

  ## Resuming: {{MODULE}} ({{BRANCH}})
  **Completion:** [X]% | **Last updated:** [date from progress.md]

  ### What's Done
  [Tick list from progress.md + modules-map.md]

  ### Where We Left Off
  [Resume-from note from progress.md or Claude context file]

  ### Open Issues
  [From known-issues.md — open bugs/gaps only, top 5]

  ### Next Tasks
  [Pending items from progress.md — ordered by priority]

  ### Key Decisions Already Made
  [From state/decisions.md — {{MODULE}} entries]

  Ready to continue. What would you like to work on?

---



=====================================================================================================================
## Tier 4 — Recall Completed Module for Enhancement               Model: claude-sonnet-4-6 | ~5-8 min
=====================================================================================================================
When: A module that was previously marked complete now needs an enhancement, new feature, or change.
      You need full context of what exists before adding to it — avoid breaking working code.

---

### CONFIGURATION
  MODULE         = Syllabus
  MODULE_DIR     = Syllabus
  TABLE_PREFIX   = slb
  BRANCH         = main          # or the feature branch for the enhancement
  ENHANCEMENT    = [1-line description of what needs to be added/changed]

  AI_BRAIN       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain
  LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai
  TENANT_DDL     = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase/1-Master_DDLs/tenant_db_v2.sql
  GAP_ANALYSIS   = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/3-Project_Planning/2-Gap_Analysis

---

### Enhancement Context Load — {{MODULE}}

  Module: {{MODULE}} (COMPLETED) | Enhancement: {{ENHANCEMENT}}
  Branch: {{BRANCH}} | Code: {{LARAVEL_REPO}}
  AI Brain: {{AI_BRAIN}}

  This module was previously completed. Load full context before making any changes.
  Do NOT write or update any files during this load.

### Step 1 — Core context
  1. AI_Brain/config/paths.md
  2. AI_Brain/memory/tenancy-map.md        ← 3-layer DB (CRITICAL)
  3. AI_Brain/memory/conventions.md        ← naming conventions (must follow existing patterns)
  4. AI_Brain/rules/tenancy-rules.md
  5. AI_Brain/rules/security-rules.md      ← auth rules for new endpoints
  6. AI_Brain/rules/module-rules.md

### Step 2 — Module knowledge from AI Brain
  7.  AI_Brain/state/progress.md           ← find {{MODULE}} entry: what was completed
  8.  AI_Brain/memory/modules-map.md       ← find {{MODULE}} row: scope, counts, table prefix
  9.  AI_Brain/lessons/known-issues.md     ← find {{MODULE}} section: known issues + resolved bugs
  10. AI_Brain/state/decisions.md          ← find {{MODULE}} decisions: why things were built a certain way
  11. AI_Brain/memory/db-schema.md         ← find {{TABLE_PREFIX}} section: table structure summary

### Step 3 — Load existing code (read the module as-built)
  12. Read routes file: {{LARAVEL_REPO}}/Modules/{{MODULE_DIR}}/routes/
      → Map all existing routes (method, URI, controller@method, name)

  13. List controllers: {{LARAVEL_REPO}}/Modules/{{MODULE_DIR}}/app/Http/Controllers/
      → Read ONLY the controller most relevant to {{ENHANCEMENT}}

  14. List models: {{LARAVEL_REPO}}/Modules/{{MODULE_DIR}}/app/Models/
      → Read ONLY the models most relevant to {{ENHANCEMENT}}

### Step 4 — Schema check
  15. Read {{TENANT_DDL}} → grep for `CREATE TABLE {{TABLE_PREFIX}}_`
      → Understand actual column names before writing any queries or migrations

### Step 5 — Requirements check
  16. Scan {{GAP_ANALYSIS}}/ for any gap analysis mentioning {{MODULE}} + {{ENHANCEMENT}}
      (If found, read it — it may define expected behaviour for this enhancement)

### Step 6 — Enhancement briefing
  Output:

  ## Enhancement Context: {{MODULE}} → {{ENHANCEMENT}}

  ### What Exists (as built)
  **Routes:** [count + key endpoints]
  **Controllers:** [list with method counts]
  **Models:** [list + key relationships]
  **Tables:** [from DDL — {{TABLE_PREFIX}}_* tables with key columns]

  ### Existing Decisions That Apply
  [From state/decisions.md — anything that constrains how the enhancement should be built]

  ### Known Issues to Avoid Touching
  [From known-issues.md — bugs or known fragile areas]

  ### Impact Assessment
  [What existing code will be affected by {{ENHANCEMENT}}? Which routes/controllers/models?]

  ### Recommended Approach
  [How to add {{ENHANCEMENT}} without breaking what's working — based on existing patterns]

  Ready to proceed. Confirm approach before writing code.

---



=====================================================================================================================
## Tier 5 — Architecture & Design Recall                          Model: claude-sonnet-4-6 | ~5 min
=====================================================================================================================
When: About to make a significant architectural change, or need to understand the big picture
      before deciding how to build something. Also useful before PR reviews.

---

### CONFIGURATION
  FOCUS_MODULE   = HPC           # or ALL for project-wide architecture
  CONCERN        = [what architectural question/concern you're investigating]
                  # e.g. "how should cross-module events work", "where should shared logic go",
                  #      "how to handle multi-currency in a new module"

  AI_BRAIN       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain
  DESIGN_ARCH    = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/3-Design_Architecture

---

### Architecture Context Load

  Module: {{FOCUS_MODULE}} | Concern: {{CONCERN}}
  AI Brain: {{AI_BRAIN}}

  Load architectural context. Do NOT write or update any files.

### Step 1 — Core architecture files
  1. AI_Brain/config/paths.md
  2. AI_Brain/memory/architecture.md       ← system architecture, patterns, design decisions
  3. AI_Brain/memory/tenancy-map.md        ← 3-layer DB (global/prime/tenant isolation)
  4. AI_Brain/memory/conventions.md        ← naming and structural conventions
  5. AI_Brain/state/decisions.md           ← all architectural decisions (D001+)
  6. AI_Brain/memory/decisions.md          ← stable/historic decisions (D1-D17)

### Step 2 — Rules relevant to the concern
  7. AI_Brain/rules/tenancy-rules.md       ← always read (most critical rules)
  8. AI_Brain/rules/module-rules.md
  9. AI_Brain/rules/security-rules.md      ← if concern touches auth/permissions

### Step 3 — Design docs (if exist)
  Scan {{DESIGN_ARCH}}/ for files related to {{FOCUS_MODULE}} or {{CONCERN}}:
  - Dev_BluePrint/
  - Module_Wise_Dev_Prompt/
  - Dev_Phase_Wise_Prompt/
  Read any relevant files found.

### Step 4 — Related known issues
  10. AI_Brain/lessons/known-issues.md     ← scan for architectural gotchas across all modules

### Step 5 — Architectural briefing
  Output:

  ## Architecture Context: {{FOCUS_MODULE}} — {{CONCERN}}

  ### Relevant Decisions Already Made
  [From decisions.md — list all that touch {{CONCERN}} or {{FOCUS_MODULE}}]

  ### Design Patterns in Use
  [From architecture.md — patterns relevant to the concern]

  ### Tenancy Constraints
  [From tenancy-map.md + tenancy-rules.md — what the 3-layer split means for this concern]

  ### Known Pitfalls
  [From known-issues.md — anything architectural to avoid]

  ### Recommendation
  [Based on all above — how the concern should be approached to stay consistent with existing decisions]

---



=====================================================================================================================
## Tier 6 — DB Schema Recall                                      Model: claude-sonnet-4-6 | ~3-5 min
=====================================================================================================================
When: About to write queries, create migrations, add relationships, or design new tables.
      Load schema context before touching any DB-related code.

---

### CONFIGURATION
  MODULE         = HPC
  TABLE_PREFIX   = hpc           # e.g. hpc, tt, qns, std, fin — or ALL for full schema
  RELATED_PREFIX = std           # Optional: a related module's prefix (for FKs), or NONE

  AI_BRAIN       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain
  GLOBAL_DDL     = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase/1-Master_DDLs/global_db_v2.sql
  PRIME_DDL      = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase/1-Master_DDLs/prime_db_v2.sql
  TENANT_DDL     = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase/1-Master_DDLs/tenant_db_v2.sql

---

### DB Schema Context Load — {{TABLE_PREFIX}}_*

  Module: {{MODULE}} | Prefix: {{TABLE_PREFIX}} | Related: {{RELATED_PREFIX}}
  AI Brain: {{AI_BRAIN}}

  Load schema context. Do NOT write or update any files.

### Step 1 — Schema knowledge from AI Brain
  1. AI_Brain/config/paths.md
  2. AI_Brain/memory/tenancy-map.md        ← which DB layer each prefix belongs to
  3. AI_Brain/memory/conventions.md        ← column naming conventions
  4. AI_Brain/memory/db-schema.md          ← find {{TABLE_PREFIX}} section: tables and key columns
  5. AI_Brain/rules/tenancy-rules.md       ← DB isolation rules (NEVER query across layers)
  6. AI_Brain/agents/db-architect.md       ← DB design rules and patterns

### Step 2 — Read actual DDL (source of truth)
  Read {{TENANT_DDL}} and grep for `CREATE TABLE {{TABLE_PREFIX}}_`
  For each table found, capture:
  - Column names and types
  - Nullable vs NOT NULL
  - DEFAULT values
  - Foreign keys (especially: which table + column it references)
  - Unique constraints and indexes
  - Generated columns (if any)
  - `is_active`, `deleted_at`, `created_by` presence

  If {{RELATED_PREFIX}} is not NONE:
  Also grep for `CREATE TABLE {{RELATED_PREFIX}}_` — load related tables that will be JOINed.

  If prefix is from global_db (e.g. glb_): read {{GLOBAL_DDL}} instead.
  If prefix is from prime_db (e.g. prm_, bil_): read {{PRIME_DDL}} instead.

### Step 3 — Schema briefing
  Output:

  ## Schema Context: {{TABLE_PREFIX}}_* Tables

  ### Tables Found
  | Table Name | PK | FK references | Soft Delete? | Key columns |
  |------------|----|-----------    |--------------|-------------|
  [one row per table]

  ### Cross-Table Relationships
  [Which tables reference which — draw the join map]

  ### Missing Conventions (flag only if found)
  [Tables missing is_active, deleted_at, created_by — flag clearly]

  ### DB Layer
  [Which DB layer: global_db / prime_db / tenant_db — and what that means for queries]

  Ready. Describe what you need to build.

---



=====================================================================================================================
## Tier 7 — Cross-Module / Integration Work                       Model: claude-sonnet-4-6 | ~5-8 min
=====================================================================================================================
When: A change in one module will affect one or more other modules.
      Examples: Finance changes that affect Fee module, Timetable changes that affect Exam,
      User module changes that affect all auth flows.

---

### CONFIGURATION
  PRIMARY_MODULE  = Finance
  PRIMARY_DIR     = Finance
  PRIMARY_PREFIX  = fin
  AFFECTED_MODULE = Fees
  AFFECTED_DIR    = Fees
  AFFECTED_PREFIX = fee
  CHANGE_SUMMARY  = [1-line description of the cross-module change]

  AI_BRAIN        = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain
  LARAVEL_REPO    = /Users/bkwork/Herd/prime_ai
  TENANT_DDL      = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase/1-Master_DDLs/tenant_db_v2.sql

---

### Cross-Module Context Load — {{PRIMARY_MODULE}} ↔ {{AFFECTED_MODULE}}

  Change: {{CHANGE_SUMMARY}}
  AI Brain: {{AI_BRAIN}} | Code: {{LARAVEL_REPO}}

  Load context for both modules before making any changes. Do NOT write or update any files.

### Step 1 — Architecture & tenancy (critical for cross-module work)
  1. AI_Brain/config/paths.md
  2. AI_Brain/memory/architecture.md       ← module communication patterns (events, services, shared)
  3. AI_Brain/memory/tenancy-map.md        ← which DB layer each module uses
  4. AI_Brain/rules/tenancy-rules.md       ← NEVER import across DB layers
  5. AI_Brain/rules/module-rules.md        ← module boundary rules
  6. AI_Brain/state/decisions.md           ← prior decisions on cross-module patterns

### Step 2 — Both modules from AI Brain
  7. AI_Brain/memory/modules-map.md        ← find BOTH {{PRIMARY_MODULE}} and {{AFFECTED_MODULE}} rows
  8. AI_Brain/state/progress.md            ← completion status of both modules
  9. AI_Brain/lessons/known-issues.md      ← open issues in BOTH modules

### Step 3 — Schema for both
  Read {{TENANT_DDL}}:
  - Grep `CREATE TABLE {{PRIMARY_PREFIX}}_` → list primary module tables
  - Grep `CREATE TABLE {{AFFECTED_PREFIX}}_` → list affected module tables
  - Identify shared FKs or shared reference tables (e.g. sys_users, sch_classes)

### Step 4 — Code boundary check
  Run: grep -r "{{AFFECTED_DIR}}" {{LARAVEL_REPO}}/Modules/{{PRIMARY_DIR}}/ --include="*.php" -l
  Run: grep -r "{{PRIMARY_DIR}}" {{LARAVEL_REPO}}/Modules/{{AFFECTED_DIR}}/ --include="*.php" -l
  (Shows if there are already cross-module imports — flag as tenancy violation if found)

### Step 5 — Integration briefing
  Output:

  ## Cross-Module Context: {{PRIMARY_MODULE}} ↔ {{AFFECTED_MODULE}}
  **Change:** {{CHANGE_SUMMARY}}

  ### Module Boundaries
  [What each module owns: tables, controllers, key logic]

  ### Shared Data Points
  [Tables/columns referenced by both modules — FK relationships]

  ### Existing Cross-Module References (flag violations)
  [From grep output — are there any direct imports across modules? These must be removed]

  ### Safe Integration Patterns Available
  [From architecture.md decisions — events? shared services? API calls?]

  ### Impact of Change
  [What in {{AFFECTED_MODULE}} will break or need updating when {{PRIMARY_MODULE}} changes]

  ### Recommended Approach
  [How to implement {{CHANGE_SUMMARY}} without violating module boundaries]

---



=====================================================================================================================
## Tier 8 — Bug Investigation Context Load                        Model: claude-sonnet-4-6 | ~3-5 min
=====================================================================================================================
When: A bug was reported and you need full context before investigating.
      Loads the relevant module, known issues, and recent changes.

---

### CONFIGURATION
  MODULE         = HPC
  MODULE_DIR     = Hpc
  BUG_REPORT     = [describe the bug: what fails, what error, what steps to reproduce]
  ISSUE_CODE     = BUG-HPC-003   # Known issue code, or UNKNOWN if not yet coded
  REPORTED_BY    = [name or "user"]

  AI_BRAIN       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain
  LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai

---

### Bug Investigation Context — {{MODULE}} / {{ISSUE_CODE}}

  Module: {{MODULE}} | Bug: {{BUG_REPORT}}
  Issue code: {{ISSUE_CODE}} | Reported by: {{REPORTED_BY}}
  AI Brain: {{AI_BRAIN}} | Code: {{LARAVEL_REPO}}

  Load context for bug investigation. Do NOT modify any files yet.

### Step 1 — Core context (minimal load)
  1. AI_Brain/config/paths.md
  2. AI_Brain/memory/tenancy-map.md        ← DB layer context
  3. AI_Brain/agents/debugger.md           ← debugging approach guide

### Step 2 — Module state
  4. AI_Brain/lessons/known-issues.md      ← find {{ISSUE_CODE}} or {{MODULE}} section
     → Is this a known issue? What was the prior fix attempt?
  5. AI_Brain/state/progress.md            ← find {{MODULE}} entry: current state
  6. AI_Brain/state/decisions.md           ← find {{MODULE}} decisions: architectural choices that may cause this

### Step 3 — Recent changes (what changed before the bug appeared)
  Run: git -C {{LARAVEL_REPO}} log --oneline -20 -- Modules/{{MODULE_DIR}}/
  Run: git -C {{LARAVEL_REPO}} diff HEAD~5..HEAD -- Modules/{{MODULE_DIR}}/
  → Look for recent changes that could have introduced the bug

### Step 4 — Locate the failing code
  Read: {{LARAVEL_REPO}}/Modules/{{MODULE_DIR}}/routes/
  → Find the route related to the bug
  → Read only the controller method that handles that route
  → Read the relevant model(s) and service(s) used by that method

### Step 5 — Investigation briefing
  Output:

  ## Bug Investigation: {{MODULE}} — {{ISSUE_CODE}}
  **Report:** {{BUG_REPORT}}

  ### Is This a Known Issue?
  [From known-issues.md — prior occurrences, previous fix attempts]

  ### Recent Changes (possible cause)
  [From git log — commits in the last 20 that touched relevant files]

  ### Code Path
  Route → Controller → Service → Model chain for the failing flow

  ### Likely Root Cause
  [Based on code + known issues + recent changes — ranked hypotheses]

  ### Recommended Investigation Steps
  [What to check / test first]

---



=====================================================================================================================
## Tier 9 — Full Project Status Overview                          Model: claude-sonnet-4-6 | ~8-10 min
=====================================================================================================================
When: Sprint planning, weekly review, demo prep, or stakeholder update.
      Need a complete picture of where the project stands across ALL modules.

---

### CONFIGURATION
  AI_BRAIN       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain
  LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai
  WORK_STATUS    = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/3-Project_Planning/9-Work_Status

---

### Full Project Status Load

  AI Brain: {{AI_BRAIN}}

  Load complete project context. Do NOT write or update any files.

### Step 1 — Read ALL AI Brain files
  1.  AI_Brain/config/paths.md
  2.  AI_Brain/memory/project-context.md
  3.  AI_Brain/memory/modules-map.md         ← all 29+ modules, counts, completion %
  4.  AI_Brain/memory/tenancy-map.md
  5.  AI_Brain/memory/architecture.md
  6.  AI_Brain/state/progress.md             ← per-module status tracker
  7.  AI_Brain/state/decisions.md            ← all architectural decisions
  8.  AI_Brain/memory/decisions.md           ← stable decisions (D1-D17)
  9.  AI_Brain/lessons/known-issues.md       ← all open bugs across all modules
  10. AI_Brain/memory/known-bugs-and-roadmap.md

### Step 2 — Planning docs
  11. Scan {{WORK_STATUS}}/ → read the most recent work status file
  12. Check {{AI_BRAIN}}/tasks/active/ → list any active tasks
  13. Check {{AI_BRAIN}}/tasks/backlog/ → list backlog items

### Step 3 — Quick code verification
  Run: ls {{LARAVEL_REPO}}/Modules/ | sort
  (Verify modules that are claimed complete actually have a directory)

### Step 4 — Project status report
  Output a structured report:

  ## Project Status Report — [TODAY'S DATE]

  ### Overall Completion
  **Completed modules (100%):** [list]
  **In-progress modules (50-99%):** [list with %]
  **Partially done (10-49%):** [list with %]
  **Pending / not started:** [list]

  ### Critical Open Issues
  [From known-issues.md + known-bugs-and-roadmap.md — top 5 by severity]

  ### Blocked Items
  [Any module blocked on a dependency or decision]

  ### Recent Architectural Decisions
  [Last 3-5 from decisions.md]

  ### Recommended Sprint Focus
  [Based on progress + issues — what to prioritise next]

  ### Modules Not in AI Brain Yet
  [From ls Modules/ — any directories not recorded in modules-map.md]

---



=====================================================================================================================
## Tier 10 — New Developer / Team Handover                        Model: claude-opus-4-6 | ~15-20 min
=====================================================================================================================
When: A new developer joins the project, or handing over a module to another developer.
      Full onboarding — loads everything a new person needs to understand the system.

---

### CONFIGURATION
  NEW_DEVELOPER   = [name of new developer]
  ASSIGNED_MODULE = HPC          # Module they'll be working on first
  ASSIGNED_DIR    = Hpc
  THEIR_BRANCH    = Brijesh_HPC  # Branch they'll be working on
  HAND_FROM       = Shailesh     # Developer handing over

  AI_BRAIN        = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain
  LARAVEL_REPO    = /Users/bkwork/Herd/prime_ai
  DDL_DIR         = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase/1-Master_DDLs
  TENANT_DDL      = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase/1-Master_DDLs/tenant_db_v2.sql
  GAP_ANALYSIS    = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/3-Project_Planning/2-Gap_Analysis
  DESIGN_ARCH     = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/3-Design_Architecture

---

### Team Handover / Onboarding — {{ASSIGNED_MODULE}} → {{NEW_DEVELOPER}}

  New developer: {{NEW_DEVELOPER}} | Module: {{ASSIGNED_MODULE}} | Branch: {{THEIR_BRANCH}}
  Handed from: {{HAND_FROM}}
  AI Brain: {{AI_BRAIN}} | Code: {{LARAVEL_REPO}}

  Load FULL context for onboarding. This is a comprehensive read — do NOT skip anything.
  Do NOT write or update any files.

### Step 1 — Project identity (foundation)
  1.  AI_Brain/README.md                    ← AI Brain overview and how to use it
  2.  AI_Brain/config/paths.md              ← all path variables
  3.  AI_Brain/memory/project-context.md    ← project overview, goals, tech stack
  4.  AI_Brain/memory/tenancy-map.md        ← 3-layer DB architecture (CRITICAL)
  5.  AI_Brain/memory/architecture.md       ← system design and patterns
  6.  AI_Brain/memory/school-domain.md      ← Indian K-12 school domain (business context)
  7.  AI_Brain/memory/conventions.md        ← all naming and coding conventions

### Step 2 — All mandatory rules
  8.  AI_Brain/rules/tenancy-rules.md       ← NEVER violate these
  9.  AI_Brain/rules/module-rules.md
  10. AI_Brain/rules/security-rules.md
  11. AI_Brain/rules/laravel-rules.md
  12. AI_Brain/rules/code-style.md
  13. AI_Brain/rules/school-rules.md        ← Indian school business rules

### Step 3 — Project state
  14. AI_Brain/memory/modules-map.md        ← all modules, counts, status
  15. AI_Brain/state/progress.md            ← per-module completion
  16. AI_Brain/state/decisions.md           ← architectural decisions already made
  17. AI_Brain/lessons/known-issues.md      ← known bugs + gotchas (what NOT to repeat)

### Step 4 — Assigned module deep dive
  18. AI_Brain/memory/modules-map.md        ← find {{ASSIGNED_MODULE}} row in detail
  19. AI_Brain/lessons/known-issues.md      ← find {{ASSIGNED_MODULE}} section

  Read existing code for {{ASSIGNED_MODULE}}:
  20. Routes: {{LARAVEL_REPO}}/Modules/{{ASSIGNED_DIR}}/routes/
  21. List all controllers (do not read yet)
  22. Read the most important controller (largest or most central one)

  Schema:
  23. Read {{TENANT_DDL}} → grep `CREATE TABLE {{ASSIGNED_DIR[:3]|lower}}_` → list all tables

  Requirements:
  24. Scan {{GAP_ANALYSIS}}/ → find {{ASSIGNED_MODULE}} gap analysis
  25. Scan {{DESIGN_ARCH}}/Module_Wise_Dev_Prompt/ → find {{ASSIGNED_MODULE}} dev prompt (if exists)

### Step 5 — Templates (so they know the boilerplates)
  26. AI_Brain/templates/module-controller.md
  27. AI_Brain/templates/model.md
  28. AI_Brain/templates/form-request.md
  29. AI_Brain/templates/tenant-migration.md

### Step 6 — Onboarding briefing
  Output a complete handover document:

  ## Onboarding: {{NEW_DEVELOPER}} → {{ASSIGNED_MODULE}}
  **Handed over from:** {{HAND_FROM}} | **Branch:** {{THEIR_BRANCH}}

  ### Project in One Paragraph
  [From project-context.md — elevator pitch for {{NEW_DEVELOPER}}]

  ### The 3-Layer DB Rule (CRITICAL)
  [Explain global_db / prime_db / tenant_db in plain English — and what they must NEVER do]

  ### Module Assignment: {{ASSIGNED_MODULE}}
  **Status:** [X]% | **Tables:** [list] | **Open issues:** [list from known-issues]
  **What's built:** [tick list from progress.md]
  **What's pending:** [pending list from progress.md]

  ### Top 5 Rules to Never Break
  [Most critical rules from tenancy-rules + security-rules — framed for a new developer]

  ### Top 3 Gotchas (Learn from our mistakes)
  [From known-issues.md — most instructive past bugs]

  ### Key Architectural Decisions (non-obvious choices)
  [From decisions.md — decisions that a new developer might otherwise contradict]

  ### First Week Task Suggestions
  [Based on pending items + open issues — what to start with]

  ### How to Use AI Brain
  [Quick guide: what to read at session start, how to run memory update prompts]
  Reference: databases/4-Work_with_CLAUDE/1-Memory_Update/1-Memory_Update_v3.md

---



=====================================================================================================================
## Quick Reference — Tier Selection Guide
=====================================================================================================================

+----------+----------------------------------------------+-----------------------------+----------+----------+
| Tier     | Situation                                    | Files Read                  | Model    | Time     |
+----------+----------------------------------------------+-----------------------------+----------+----------+
| Tier 0   | Mid-session context lost after /compact      | 3 files (module only)       | Sonnet   | ~30 sec  |
+----------+----------------------------------------------+-----------------------------+----------+----------+
| Tier 1   | Start of day — what was I doing?             | Core brain + module +       | Sonnet   | ~3-5 min |
|          |                                              | git log + session log       |          |          |
+----------+----------------------------------------------+-----------------------------+----------+----------+
| Tier 2   | Starting a brand new module (no code yet)    | ALL brain + ALL rules +     | Opus     | ~5-8 min |
|          |                                              | templates + DDL + reqs      |          |          |
+----------+----------------------------------------------+-----------------------------+----------+----------+
| Tier 3   | Resuming an in-progress module               | Core + module state +       | Sonnet   | ~3-5 min |
|          |                                              | Claude context files        |          |          |
+----------+----------------------------------------------+-----------------------------+----------+----------+
| Tier 4   | Enhancement to a completed module            | Core + module + full code   | Sonnet   | ~5-8 min |
|          |                                              | read + DDL + gap analysis   |          |          |
+----------+----------------------------------------------+-----------------------------+----------+----------+
| Tier 5   | Architecture / design question               | Architecture + decisions +  | Sonnet   | ~5 min   |
|          |                                              | rules + design docs         |          |          |
+----------+----------------------------------------------+-----------------------------+----------+----------+
| Tier 6   | Writing queries / migrations / relationships | Tenancy + DDL + db-schema   | Sonnet   | ~3-5 min |
+----------+----------------------------------------------+-----------------------------+----------+----------+
| Tier 7   | Change touches 2+ modules                   | Both modules + architecture | Sonnet   | ~5-8 min |
|          |                                              | + cross-module grep         |          |          |
+----------+----------------------------------------------+-----------------------------+----------+----------+
| Tier 8   | Bug reported — need to investigate           | Module + known-issues +     | Sonnet   | ~3-5 min |
|          |                                              | git diff + failing code     |          |          |
+----------+----------------------------------------------+-----------------------------+----------+----------+
| Tier 9   | Sprint planning / weekly review / demo       | ALL brain files +           | Sonnet   | ~8-10min |
|          |                                              | work status + tasks         |          |          |
+----------+----------------------------------------------+-----------------------------+----------+----------+
| Tier 10  | New developer joining / module handover      | EVERYTHING                  | Opus     | ~15-20min|
+----------+----------------------------------------------+-----------------------------+----------+----------+

Practical rules:
  - After /compact, always use Tier 0 first — never re-read the whole brain mid-session
  - Every morning: always run Tier 1 before touching code
  - New module: always Tier 2 — no exceptions
  - Resuming yesterday's work: Tier 3 (not Tier 1 — Tier 3 is more focused)
  - Completed module needs a change: Tier 4 — read what exists before adding
  - Cross-module change: Tier 7 first, then start coding
  - Never investigate a bug without running Tier 8 first



=====================================================================================================================
## AI Brain Files — Quick Lookup
=====================================================================================================================

  Base path: /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain

  config/paths.md                    ← Path variables — always read first in any new session

  memory/ (stable facts)
    project-context.md               ← Project overview, goals, team, tech stack
    modules-map.md                   ← All modules: scope, prefix, counts, completion %
    tenancy-map.md                   ← 3-layer DB: global/prime/tenant (CRITICAL)
    architecture.md                  ← System design, patterns, module communication
    conventions.md                   ← Naming: tables, columns, files, routes, classes
    db-schema.md                     ← Table summary by prefix (what's in each module's DB)
    school-domain.md                 ← School entity map, Indian K-12 business rules
    decisions.md                     ← Stable architectural decisions (D1-D17)
    known-bugs-and-roadmap.md        ← Project-wide bugs, tech debt, roadmap items
    testing-strategy.md              ← Pest 4.x approach and coverage expectations
    lms-modules.md                   ← LMS context (Quiz, Homework, Exam modules)
    student-parent-portal.md         ← Portal-specific context

  state/ (living state — changes as work progresses)
    progress.md                      ← Per-module completion % and task status
    decisions.md                     ← Architectural decisions log (ongoing)

  lessons/
    known-issues.md                  ← All bugs, gaps, security issues (BUG-XXX-001 format)

  rules/ (MANDATORY — always follow)
    tenancy-rules.md                 ← NEVER cross DB layers
    module-rules.md                  ← Module structure and boundaries
    security-rules.md                ← Auth, Gate, policies
    laravel-rules.md                 ← Laravel conventions
    code-style.md                    ← PSR-12 + project style
    school-rules.md                  ← School domain business rules

  agents/ (role guides — pick the right one for your task)
    developer.md                     ← General Laravel + modular dev
    db-architect.md                  ← DB design specialist
    module-agent.md                  ← New module creation
    tenancy-agent.md                 ← Tenancy isolation specialist
    api-builder.md                   ← REST API endpoints
    debugger.md                      ← Bug investigation
    school-agent.md                  ← School domain expert
    test-agent.md                    ← Pest 4.x testing

  templates/ (boilerplates — use for all new code)
    module-structure.md              ← New module scaffold
    module-controller.md             ← Controller (web + API)
    module-service.md                ← Service class
    model.md                         ← Eloquent model
    form-request.md                  ← Validation (Store + Update)
    policy.md                        ← Authorization policy
    tenant-migration.md              ← Tenant DB migration
    test-unit.md / test-feature-*.md ← Test boilerplates

  tasks/
    active/                          ← Currently in-progress tasks
    backlog/                         ← Planned, not started
    completed/                       ← Done (reference archive)
