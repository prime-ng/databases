# AI Brain Memory Update Prompts — v3
# Prime-AI ERP/LMS/LXP Project
# ===================================================================================
# PURPOSE : Prompts to WRITE/UPDATE AI Brain memory.
#           This file is NOT for recalling memory — only writing/updating.
#
# HOW TO USE:
#   1. Find the right Tier for your situation (see Quick Reference at bottom)
#   2. Edit CONFIGURATION values at the top of that Tier
#   3. Copy-paste the prompt block into Claude Code
#
# PATHS SOURCED FROM: AI_Brain/config/paths.md (single source of truth)
# If any path changes, update paths.md first — then update this file.
# ===================================================================================


=====================================================================================================================
## RESOLVED PATHS  (sourced from AI_Brain/config/paths.md — DO NOT hardcode elsewhere)
=====================================================================================================================

  OLD_REPO      = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases
  DB_REPO       = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase
  AI_BRAIN      = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain
  LARAVEL_REPO  = /Users/bkwork/Herd/prime_ai

  # Schema / DDL
  DDL_DIR       = {DB_REPO}/1-Master_DDLs
  GLOBAL_DDL    = {DB_REPO}/1-Master_DDLs/global_db_v2.sql
  PRIME_DDL     = {DB_REPO}/1-Master_DDLs/prime_db_v2.sql
  TENANT_DDL    = {DB_REPO}/1-Master_DDLs/tenant_db_v2.sql
  MODULE_DDL    = {DB_REPO}/1-Module_DDLs

  # Planning & Design (OLD_REPO)
  PROJECT_PLAN              = {OLD_REPO}/3-Project_Planning
  DESIGN_ARCH               = {OLD_REPO}/3-Design_Architecture
  RBS_DIR                   = {PROJECT_PLAN}/1-RBS
  REQUIREMENT_HIGH_level    = {OLD_REPO}/2-Requirement_Module_wise/1-HighLevel_Requirements
  REQUIRE_DETAIL_DEV_DONE   = {OLD_REPO}/2-Requirement_Module_wise/2-Detailed_Requirements/V1/Dev_Done
  REQUIRE_DETAIL_DEV_PEND   = {OLD_REPO}/2-Requirement_Module_wise/2-Detailed_Requirements/V1/Dev_Pending
  REQUIREMENT_CONDITIONS    = {OLD_REPO}/2-Requirement_Module_wise/3-Requirement_Conditions
  GAP_ANALYSIS              = {OLD_REPO}/3-Project_Planning/2-Gap_Analysis
  WORK_STATUS               = {OLD_REPO}/3-Project_Planning/9-Work_Status
  WORK_IN_PROG              = {OLD_REPO}/5-Work-In-Progress
  TEMP_OUTPUT               = {OLD_REPO}/8-Temp_Output

  # AI Brain sub-folders (all under AI_BRAIN)
  BRAIN_MEMORY  = AI_BRAIN/memory/          # project-context, modules-map, tenancy-map, db-schema, architecture, conventions …
  BRAIN_STATE   = AI_BRAIN/state/           # progress.md, decisions.md
  BRAIN_LESSONS = AI_BRAIN/lessons/         # known-issues.md
  BRAIN_RULES   = AI_BRAIN/rules/           # tenancy, module, security, laravel, code-style, school rules
  BRAIN_CONFIG  = AI_BRAIN/config/          # paths.md



=====================================================================================================================
## Tier 0 — After Each Small Task  (within same session)          Model: claude-sonnet-4-6 | ~30 sec | Zero cost
=====================================================================================================================
When: You just finished one small task and Claude still has full context.
      Examples: fixed a bug, added one method, wired a route, resolved one issue.

---

### CONFIGURATION
  MODULE         = HPC           # e.g. HPC, Timetable, QuestionBank
  TASK_DONE      = [describe what was just completed in 1 line]
  BUG_RESOLVED   = [BUG-XXX-00N or NONE]
  DECISION_MADE  = [one-line architectural decision, or NONE]

  AI_BRAIN = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain

---

Update AI Brain for what we just completed. Do NOT re-read the codebase — use context already in this session.

  Task done     : {{TASK_DONE}}
  Module        : {{MODULE}}
  Bug resolved  : {{BUG_RESOLVED}}
  Decision made : {{DECISION_MADE}}

Update only the files that need changing:

  1. AI_Brain/state/progress.md
     → Mark {{TASK_DONE}} as done under {{MODULE}}; update date to today.

  2. AI_Brain/lessons/known-issues.md  (only if {{BUG_RESOLVED}} is not NONE)
     → Mark {{BUG_RESOLVED}} as RESOLVED with today's date.

  3. AI_Brain/state/decisions.md  (only if {{DECISION_MADE}} is not NONE)
     → Append {{DECISION_MADE}} under {{MODULE}} with today's date.

No report needed. Just update and confirm which lines changed.

---



=====================================================================================================================
## Tier 1 — After Completing a Bigger Task                        Model: claude-sonnet-4-6 | ~2-3 min
=====================================================================================================================
When: You finished something meaningful within a module — a controller, a service, a set of views, a major bug fix.
      You are still in the same session OR starting a fresh one with full context.

---

### CONFIGURATION
  MODULE         = HPC
  MODULE_DIR     = Hpc           # Used in file paths: Modules/Hpc/
  BRANCH         = Brijesh_HPC
  DEVELOPER      = Brijesh
  TASK_SUMMARY   = [1-2 sentence description of what was built/fixed]
  NEW_ISSUES     = [comma-separated list of new issues found, or NONE]

  AI_BRAIN       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain
  LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai

---

### Update AI Brain — Task Completion: {{MODULE}}

  Module: {{MODULE}} | Branch: {{BRANCH}} | Developer: {{DEVELOPER}}
  What was done: {{TASK_SUMMARY}}

  AI Brain: {{AI_BRAIN}}
  Code: {{LARAVEL_REPO}}/Modules/{{MODULE_DIR}}/

### Step 1 — Read current state (do NOT skip)
  1. AI_Brain/state/progress.md         ← find the {{MODULE}} entry
  2. AI_Brain/memory/modules-map.md     ← find the {{MODULE}} row
  3. AI_Brain/lessons/known-issues.md   ← find the {{MODULE}} section

### Step 2 — Scan only changed files
  Run: git log --oneline -10 -- Modules/{{MODULE_DIR}}/
  Read only the files changed in the last 10 commits for this module.

### Step 3 — Update AI Brain
  A. AI_Brain/state/progress.md
     → Mark completed items; update % complete; add date [TODAY'S DATE]

  B. AI_Brain/memory/modules-map.md
     → Update controller/model/service/route counts if anything was added
     → Adjust completion % if it changed meaningfully

  C. AI_Brain/lessons/known-issues.md
     → Mark any resolved issues as RESOLVED [TODAY'S DATE]
     → Add new issues from {{NEW_ISSUES}} with codes BUG-{{MODULE}}-00N, SEC-..., PERF-...

  D. AI_Brain/state/decisions.md  (only if architectural decisions were made)
     → Append new decision with module, description, date

### Step 4 — Report
  Output a 3-line delta:
  - What was completed
  - Any new issues introduced
  - Updated completion %

---



=====================================================================================================================
## Tier 2 — Closing for the Day                                   Model: claude-sonnet-4-6 | ~5 min
=====================================================================================================================
When: End of work session. Captures day's progress, open threads, and what to pick up next.
      Run this BEFORE closing the terminal/IDE.

---

### CONFIGURATION
  MODULE         = HPC           # Primary module worked on today (add others in ALSO_WORKED_ON)
  MODULE_DIR     = Hpc
  BRANCH         = Brijesh_HPC
  DEVELOPER      = Shailesh
  ALSO_WORKED_ON = [other module names, or NONE]   # e.g. "QuestionBank, Timetable"
  TODAY_DATE     = 26 Mar 2026

  AI_BRAIN       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain
  LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai

---

### End-of-Day AI Brain Update

  Primary module: {{MODULE}} | Also worked on: {{ALSO_WORKED_ON}}
  Branch: {{BRANCH}} | Developer: {{DEVELOPER}} | Date: {{TODAY_DATE}}

  AI Brain: {{AI_BRAIN}}
  Code: {{LARAVEL_REPO}}

### Step 1 — Load today's git diff
  Run: git log --oneline --since="{{TODAY_DATE}} 00:00" --all
  Run: git diff HEAD~5..HEAD -- Modules/{{MODULE_DIR}}/
  (If {{ALSO_WORKED_ON}} is not NONE, run git diff for those module dirs too)

### Step 2 — Reconcile AI Brain with actual changes
  Read:
  1. AI_Brain/state/progress.md      ← check if today's work was logged
  2. AI_Brain/lessons/known-issues.md ← check if any resolved bugs were marked
  3. AI_Brain/memory/modules-map.md  ← check if counts are still accurate

  For each module worked on:
  - Were all completed items reflected in progress.md?
  - Were all resolved bugs marked RESOLVED?
  - Were new issues (if any) logged?

### Step 3 — Update AI Brain
  A. AI_Brain/state/progress.md
     → Add/update all modules touched today
     → Note what is IN-PROGRESS but NOT done (capture partial state clearly)
     → Add a "Resume from:" note for any task left mid-way

  B. AI_Brain/lessons/known-issues.md
     → Resolve closed bugs; add any newly discovered issues

  C. AI_Brain/state/decisions.md
     → Log any architectural decisions made today

  D. AI_Brain/memory/modules-map.md
     → Update counts and % if any new files were added today

### Step 4 — End-of-Day Summary Report
  Output:
  - What was COMPLETED today (tick list)
  - What is IN-PROGRESS / left mid-way (with "resume from" note)
  - Any new blockers or issues found
  - Suggested first task for next session

---



=====================================================================================================================
## Tier 3 — After Module Completion / PR Merge                    Model: claude-opus-4-6 | ~10-15 min
=====================================================================================================================
When: A module is declared complete, or a major PR is merged to main.
      Full module re-audit — validates AI Brain is accurate.

---

### CONFIGURATION
  MODULE         = HPC
  MODULE_DIR     = Hpc
  BRANCH         = main          # or the merged branch name
  DEVELOPER      = Shailesh
  LAST_AUDIT_DATE = 14 Mar 2026  # date of previous full audit

  AI_BRAIN       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain
  LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai

---

### Module Completion Audit: {{MODULE}}

  Module: {{MODULE}} | Directory: Modules/{{MODULE_DIR}}/ | Branch: {{BRANCH}}
  Developer: {{DEVELOPER}} | Last Audit: {{LAST_AUDIT_DATE}}

  AI Brain: {{AI_BRAIN}}
  Code: {{LARAVEL_REPO}}

### Step 1 — Load full context (read ALL before doing anything)
  1. AI_Brain/README.md
  2. AI_Brain/memory/project-context.md
  3. AI_Brain/memory/modules-map.md
  4. AI_Brain/memory/tenancy-map.md
  5. AI_Brain/rules/tenancy-rules.md
  6. AI_Brain/rules/module-rules.md
  7. AI_Brain/rules/security-rules.md
  8. AI_Brain/lessons/known-issues.md
  9. AI_Brain/state/progress.md
  10. AI_Brain/state/decisions.md

### Step 2 — Deep Audit of Modules/{{MODULE_DIR}}/
  Count and verify:
  - Controllers (including subdirs) — flag empty stubs, zero-auth methods
  - Models — flag missing soft deletes, missing required columns
  - Services — flag empty or stub implementations
  - FormRequests — flag controllers that lack them
  - Routes — count wired vs unwired (in LARAVEL_REPO/Modules/{{MODULE_DIR}}/routes/)

  For each controller method, verify:
  1. Auth       — `Gate::authorize()` or `$this->authorize()` on every public method
  2. Validation — `FormRequest` or `$request->validate()` on every write method
  3. Tenancy    — No cross-layer imports (e.g., Modules\Prime\* inside tenant module)
  4. Middleware — `EnsureTenantHasModule` applied on the route group
  5. N+1        — No eager-loading gaps in index/list methods
  6. Dead code  — No `dd()`, `var_dump()`, hardcoded `return true`, commented Gate calls
  7. Stubs      — No empty `store()` / `update()` bodies

### Step 3 — Update AI Brain (ALL files below)
  A. AI_Brain/memory/modules-map.md
     → Accurate counts: controllers, models, services, form requests, routes
     → Accurate completion %
     → Update "What's Complete / What's Missing" for {{MODULE}}

  B. AI_Brain/lessons/known-issues.md
     → Add `## {{MODULE}} Post-Completion Audit` section
     → List every bug/gap: BUG-{{MODULE}}-00N, SEC-{{MODULE}}-00N, PERF-{{MODULE}}-00N
     → Mark previously listed issues RESOLVED if confirmed fixed

  C. AI_Brain/state/progress.md
     → Mark {{MODULE}} with accurate status, %, and today's date
     → If 100% — add it to the "Completed Modules" list

  D. AI_Brain/state/decisions.md
     → Log any architectural decisions discovered or confirmed

### Step 4 — Report
  Output:
  - Final completion % (justify with findings)
  - Top 3 critical issues (security/crash risk) — if any remain
  - Top 3 functional gaps — if any remain
  - Verdict: Ready to ship? / What must be fixed first?

---



=====================================================================================================================
## Tier 4 — DB Schema Scan & Update                               Model: claude-sonnet-4-6 | ~5-10 min
=====================================================================================================================
When: DB schema was significantly changed (new tables, renamed columns, added indexes).
      AI Brain's db-schema.md is stale or a new module's tables were added.

---

### CONFIGURATION
  MODULE         = HPC           # or ALL (for full schema scan)
  TABLE_PREFIX   = hpc           # e.g. hpc, tt, qns, std — or ALL
  CHANGED_SINCE  = 20 Mar 2026   # date of last schema update

  AI_BRAIN       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain
  DDL_DIR        = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase/1-Master_DDLs
  GLOBAL_DDL     = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase/1-Master_DDLs/global_db_v2.sql
  PRIME_DDL      = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase/1-Master_DDLs/prime_db_v2.sql
  TENANT_DDL     = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase/1-Master_DDLs/tenant_db_v2.sql
  MODULE_DDL     = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase/1-Module_DDLs

---

### DB Schema Update — {{MODULE}} (prefix: {{TABLE_PREFIX}})

  AI Brain: {{AI_BRAIN}}
  DDL files: {{DDL_DIR}}

### Step 1 — Read current AI Brain schema knowledge
  1. AI_Brain/memory/db-schema.md          ← current schema summary
  2. AI_Brain/memory/modules-map.md        ← module → table prefix mapping
  3. AI_Brain/memory/conventions.md        ← naming conventions

### Step 2 — Scan DDL files for {{TABLE_PREFIX}} tables
  If MODULE = ALL:
    Read: {{GLOBAL_DDL}}, {{PRIME_DDL}}, {{TENANT_DDL}}
    Scan ALL table definitions.

  If MODULE is specific:
    Read: {{TENANT_DDL}} (or {{PRIME_DDL}} / {{GLOBAL_DDL}} if applicable)
    Grep for: `CREATE TABLE {{TABLE_PREFIX}}_`
    Also check: {{MODULE_DDL}}/{{MODULE}}/ for any module-specific DDL files

  For each table found:
  - List: table name, primary key, foreign keys, soft delete columns, unique constraints
  - Note: generated columns, JSON columns, indexes
  - Flag: any table missing `deleted_at`, `is_active`, or `created_by`

### Step 3 — Update AI Brain
  A. AI_Brain/memory/db-schema.md
     → Update the {{MODULE}} / {{TABLE_PREFIX}} section with accurate table list
     → Add/update column notes for key tables
     → Note any schema patterns specific to this module (e.g., polymorphic FKs, generated cols)

  B. AI_Brain/memory/modules-map.md
     → Update the table count for {{MODULE}}
     → Verify TABLE_PREFIX is correctly recorded

  C. AI_Brain/lessons/known-issues.md
     → Add any schema issues found: SCHEMA-{{MODULE}}-00N
     → Examples: missing index on FK, nullable column without default, missing soft-delete

### Step 4 — Report
  Output:
  - Tables found under prefix {{TABLE_PREFIX}}
  - Schema issues flagged (if any)
  - Changes made to db-schema.md

---



=====================================================================================================================
## Tier 5 — Requirements & Planning Docs Update                   Model: claude-sonnet-4-6 | ~5-8 min
=====================================================================================================================
When: Requirements, gap analysis, or planning docs were updated.
      AI Brain's project-context.md or known-bugs-and-roadmap.md is out of date.

---

### CONFIGURATION
  MODULE         = ALL           # or ALL
  FOCUS          = GAP_ANALYSIS  # GAP_ANALYSIS | RBS | DESIGN | PLANNING | ALL

  AI_BRAIN       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain
  PROJECT_PLAN   = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/3-Project_Planning
  DESIGN_ARCH    = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/3-Design_Architecture
  RBS_DIR                   = {PROJECT_PLAN}/1-RBS
  REQUIREMENT_HIGH_level    = {OLD_REPO}/2-Requirement_Module_wise/1-HighLevel_Requirements
  REQUIRE_DETAIL_DEV_DONE   = {OLD_REPO}/2-Requirement_Module_wise/2-Detailed_Requirements/V1/Dev_Done
  REQUIRE_DETAIL_DEV_PEND   = {OLD_REPO}/2-Requirement_Module_wise/2-Detailed_Requirements/V1/Dev_Pending
  REQUIREMENT_CONDITIONS    = {OLD_REPO}/2-Requirement_Module_wise/3-Requirement_Conditions
  GAP_ANALYSIS   = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/3-Project_Planning/2-Gap_Analysis
  WORK_STATUS    = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/3-Project_Planning/9-Work_Status
  WORK_IN_PROG   = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/5-Work-In-Progress

---

### Requirements & Docs Scan — {{MODULE}} | Focus: {{FOCUS}}

  AI Brain: {{AI_BRAIN}}

### Step 1 — Read current AI Brain project knowledge
  1. AI_Brain/memory/project-context.md
  2. AI_Brain/memory/known-bugs-and-roadmap.md
  3. AI_Brain/state/progress.md            ← current status per module
  4. AI_Brain/state/decisions.md           ← design decisions already recorded

### Step 2 — Scan planning/requirements docs for {{MODULE}}

  If FOCUS = GAP_ANALYSIS or ALL:
    Read: {{GAP_ANALYSIS}}/  — scan for {{MODULE}} gap analysis files
    Extract: features listed as gaps/missing, severity ratings

  If FOCUS = RBS or ALL:
    Read: {{RBS_DIR}}/  — scan for {{MODULE}} RBS file
    Extract: scope items, requirement IDs

  If FOCUS = REQUIREMENT or ALL:
    Read: {{REQUIREMENT_HIGH_level}}/  — scan for {{MODULE}} RBS file
    Extract: scope items, requirement IDs

  If FOCUS = DESIGN or ALL:
    Read: {{DESIGN_ARCH}}/  — scan for {{MODULE}} design/architecture docs
    Extract: architectural decisions, data flow, integration points

  If FOCUS = PLANNING or ALL:
    Read: {{WORK_STATUS}}/  — scan for {{MODULE}} work status
    Read: {{WORK_IN_PROG}}/  — scan for {{MODULE}} Claude context files
    Extract: in-progress items, blockers, context notes

### Step 3 — Update AI Brain
  A. AI_Brain/memory/project-context.md
     → Update {{MODULE}} section with any new scope items or requirement changes
     → Update overall project status if changed

  B. AI_Brain/memory/known-bugs-and-roadmap.md
     → Add new gaps discovered from gap analysis docs
     → Mark resolved gaps if corresponding code was already built

  C. AI_Brain/state/progress.md
     → Adjust {{MODULE}} completion % if new requirements reveal work was missing
     → Add newly discovered tasks to the pending list

  D. AI_Brain/state/decisions.md
     → Log any design decisions found in architecture docs that aren't yet recorded

### Step 4 — Report
  Output:
  - New requirements/gaps found (not in AI Brain before)
  - Resolved items now confirmed complete
  - Revised completion % if changed
  - Any decisions now formally recorded

---



=====================================================================================================================
## Tier 6 — Full Codebase Scan (All Modules)                      Model: see phases | ~20-30 min
=====================================================================================================================
When: AI Brain is stale across multiple modules, after a long gap, or after major refactor.
      Run in two phases — do NOT combine into one prompt.

---

### CONFIGURATION
  AI_BRAIN       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain
  LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai

---

### PHASE 1 — Structure Count Scan                                Model: claude-sonnet-4-6

  AI Brain: {{AI_BRAIN}}
  Code: {{LARAVEL_REPO}}

  Audit the entire codebase and update module counts in AI Brain.

  Step 1 — Read current AI Brain state:
  1. AI_Brain/memory/modules-map.md
  2. AI_Brain/state/progress.md

  Step 2 — Scan all modules in {{LARAVEL_REPO}}/Modules/:
  For each module directory:
    - Read module.json → get name, enabled/disabled status
    - Count Models:      Modules/{Name}/app/Models/*.php
    - Count Controllers: Modules/{Name}/app/Http/Controllers/**/*.php
    - Count Services:    Modules/{Name}/app/Services/**/*.php
    - Count FormRequests:Modules/{Name}/app/Http/Requests/**/*.php
    - Count route lines: Modules/{Name}/routes/*.php
    - Count migrations:  database/migrations/tenant/ files with module prefix

  Step 3 — Update AI Brain:
    - AI_Brain/memory/modules-map.md → accurate counts per module
    - AI_Brain/state/progress.md     → accurate completion % (code-based only, not guessed)

  IMPORTANT: Do NOT guess % — derive it only from what routes, models, and controllers exist.

---

### PHASE 2 — Deep Quality Audit                                  Model: claude-opus-4-6
### (Run AFTER Phase 1 is fully complete. Use /compact between phases if needed.)

  AI Brain: {{AI_BRAIN}}
  Code: {{LARAVEL_REPO}}

  Deep audit of each module for bugs, gaps, and security issues.

  Step 1 — Read Phase 1 output (already updated):
  1. AI_Brain/memory/modules-map.md
  2. AI_Brain/state/progress.md
  3. AI_Brain/lessons/known-issues.md

  Step 2 — For each module (prioritise 80-95% complete ones):
  1. Read routes → identify routes pointing to non-existent controller methods
  2. Read each controller → identify stub/TODO/empty responses
  3. Check SEC: missing auth middleware, missing policy checks
  4. Check PERF: N+1 queries, missing eager loading in index methods
  5. Check VAL: store/update methods without Form Request validation
  6. Check DEAD: dd(), var_dump(), commented Gate calls, hardcoded return true

  Step 3 — Update AI Brain:
    - AI_Brain/lessons/known-issues.md → new bugs/gaps per module (BUG-XXX-00N codes)
    - AI_Brain/state/progress.md       → adjust % if gaps were found
    - AI_Brain/state/decisions.md      → log any architectural decisions discovered

  Step 4 — Final report:
    - Modules with hidden gaps (claimed % vs actual %)
    - Top 5 security issues across all modules
    - Top 5 N+1 / performance issues
    - Overall project completion % (recalculated)

---



=====================================================================================================================
## Tier 7 — Complete AI Brain Rebuild (Nuclear)                   Model: opus all phases | ~45-60 min
=====================================================================================================================
When: AI Brain is severely out of date, after major restructuring, or starting fresh.
      Combines Tier 4 (schema) + Tier 5 (docs) + Tier 6 (codebase) in sequence.
      Run one phase at a time. Use /compact between phases.

---

### CONFIGURATION
  AI_BRAIN       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain
  LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai
  DDL_DIR        = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase/1-Master_DDLs
  GLOBAL_DDL     = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase/1-Master_DDLs/global_db_v2.sql
  PRIME_DDL      = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase/1-Master_DDLs/prime_db_v2.sql
  TENANT_DDL     = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase/1-Master_DDLs/tenant_db_v2.sql
  PROJECT_PLAN   = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/3-Project_Planning
  DESIGN_ARCH    = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/3-Design_Architecture

---

### Run in this ORDER — never skip a phase:

  PHASE A — Read AI Brain config and all current brain files
             → Understand what the brain currently knows
             → Identify which files are stale or empty
             → Model: Sonnet | ~2 min

  Read all AI Brain files:
    AI_Brain/README.md
    AI_Brain/config/paths.md
    AI_Brain/memory/*.md  (all files in memory/)
    AI_Brain/state/*.md   (progress.md, decisions.md)
    AI_Brain/lessons/known-issues.md
    AI_Brain/rules/*.md   (all rules files)

  Output a "staleness report": which brain files need updating and why.
  Then use /compact and proceed to Phase B.

  ---

  PHASE B — DB Schema Rebuild
             → Use Tier 4 prompt with MODULE=ALL, TABLE_PREFIX=ALL
             → Updates: db-schema.md, modules-map.md (table counts)
             → Model: Sonnet | ~10 min

  Use the Tier 4 prompt above with MODULE=ALL.
  Then use /compact and proceed to Phase C.

  ---

  PHASE C — Requirements & Docs Rebuild
             → Use Tier 5 prompt with MODULE=ALL, FOCUS=ALL
             → Updates: project-context.md, known-bugs-and-roadmap.md, progress.md, decisions.md
             → Model: Sonnet | ~8 min

  Use the Tier 5 prompt above with MODULE=ALL, FOCUS=ALL.
  Then use /compact and proceed to Phase D.

  ---

  PHASE D — Codebase Structure Scan
             → Use Tier 6 Phase 1 prompt (structure count)
             → Updates: modules-map.md (controller/model/service counts), progress.md
             → Model: Sonnet | ~10 min

  Use the Tier 6 Phase 1 prompt above.
  Then use /compact and proceed to Phase E.

  ---

  PHASE E — Deep Quality Audit
             → Use Tier 6 Phase 2 prompt (deep audit)
             → Updates: known-issues.md, progress.md, decisions.md
             → Model: Opus | ~15-20 min

  Use the Tier 6 Phase 2 prompt above.
  Then use /compact.

  ---

  FINAL — Verify AI Brain integrity
             → Read all updated brain files and cross-check for consistency
             → Model: Sonnet | ~3 min

  Read:
  1. AI_Brain/memory/modules-map.md  ← counts match what code has
  2. AI_Brain/state/progress.md      ← % consistent with modules-map
  3. AI_Brain/lessons/known-issues.md ← no duplicate issue codes
  4. AI_Brain/state/decisions.md     ← no duplicate entries

  Check for:
  - Module in modules-map.md but NOT in progress.md → add it
  - Completion % in progress.md doesn't match modules-map.md → fix both
  - Issue codes that are duplicated → deduplicate
  - Decision codes that are duplicated → deduplicate

  Output: Final integrity report with overall project health.

---



=====================================================================================================================
## Quick Reference — Tier Selection Guide
=====================================================================================================================

+--------+------------------------------------------+--------------------+---------------+----------------+
| Tier   | Situation                                | Files Updated      | Model         | Time Est.      |
+--------+------------------------------------------+--------------------+---------------+----------------+
| Tier 0 | Just finished one small task             | progress, issues,  | Sonnet        | ~30 sec        |
|        | (within same session)                    | decisions          |               |                |
+--------+------------------------------------------+--------------------+---------------+----------------+
| Tier 1 | Finished a bigger task (controller,      | progress, modules- | Sonnet        | ~2-3 min       |
|        | service, set of views, major bug fix)    | map, issues,       |               |                |
|        |                                          | decisions          |               |                |
+--------+------------------------------------------+--------------------+---------------+----------------+
| Tier 2 | Closing for the day                      | progress, modules- | Sonnet        | ~5 min         |
|        | (before shutting down)                   | map, issues,       |               |                |
|        |                                          | decisions          |               |                |
+--------+------------------------------------------+--------------------+---------------+----------------+
| Tier 3 | Module declared complete / PR merged     | ALL brain files    | Opus          | ~10-15 min     |
|        | to main                                  | for that module    |               |                |
+--------+------------------------------------------+--------------------+---------------+----------------+
| Tier 4 | DB schema changed significantly          | db-schema.md,      | Sonnet        | ~5-10 min      |
|        | (new tables, renamed columns)            | modules-map.md     |               |                |
+--------+------------------------------------------+--------------------+---------------+----------------+
| Tier 5 | Requirements / gap analysis / planning   | project-context,   | Sonnet        | ~5-8 min       |
|        | docs were updated                        | roadmap, progress, |               |                |
|        |                                          | decisions          |               |                |
+--------+------------------------------------------+--------------------+---------------+----------------+
| Tier 6 | Brain stale across many modules          | ALL brain files    | Sonnet (Ph1)  | ~20-30 min     |
|        | (multi-phase, use /compact between)      | across all modules | Opus (Ph2)    |                |
+--------+------------------------------------------+--------------------+---------------+----------------+
| Tier 7 | Nuclear rebuild — brain severely stale  | ALL brain files,   | Mixed         | ~45-60 min     |
|        | or after major restructuring             | full rebuild       | Sonnet+Opus   |                |
+--------+------------------------------------------+--------------------+---------------+----------------+

Practical rules:
  - Same session, small task done?          → Tier 0 (always — it's free)
  - Still in session, bigger feature done?  → Tier 1
  - End of day?                             → Tier 2 (always before closing)
  - Module shipped to main?                 → Tier 3
  - Schema changed?                         → Tier 4 (run alongside Tier 1/2)
  - Requirements doc updated?               → Tier 5
  - Starting after a long break?            → Tier 6 Phase 1 first, then verify
  - Brain is garbage and needs full reset?  → Tier 7



=====================================================================================================================
## AI Brain Files — Reference Map
=====================================================================================================================

  All paths relative to: AI_BRAIN = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain

  config/
    paths.md                  ← SINGLE SOURCE OF TRUTH for all paths (read this first in any session)

  memory/
    project-context.md        ← Project overview, goals, tech stack, key decisions
    modules-map.md            ← All modules: controller/model/service counts, completion %, prefixes
    tenancy-map.md            ← 3-layer DB architecture: global_db, prime_db, tenant_db
    db-schema.md              ← Table summary per module (prefix → tables → key columns)
    architecture.md           ← System architecture, module communication, design patterns
    conventions.md            ← Naming conventions: tables, columns, routes, files
    known-bugs-and-roadmap.md ← Project-wide bugs and planned improvements
    lms-modules.md            ← LMS-specific context (Quiz, Homework, Exam)
    school-domain.md          ← School domain knowledge (terms, academic cycles, Indian ERP context)
    student-parent-portal.md  ← Portal-specific context
    testing-strategy.md       ← Testing approach and coverage expectations

  state/
    progress.md               ← Per-module completion % and task status (most frequently updated)
    decisions.md              ← Architectural decisions log (D001, D002 … format)

  lessons/
    known-issues.md           ← Bug/gap/security issue log (BUG-XXX-001 codes)

  rules/
    tenancy-rules.md          ← Multi-tenant rules (NEVER cross layers, etc.)
    module-rules.md           ← Module structure rules
    security-rules.md         ← Auth, Gate, policy rules
    laravel-rules.md          ← Laravel-specific patterns to follow
    code-style.md             ← Code style conventions
    school-rules.md           ← School domain business rules
