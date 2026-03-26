# AI Brain Memory Update Prompts — v4
# Prime-AI ERP/LMS/LXP Project
# ============================================================
# PURPOSE : Prompts to WRITE/UPDATE AI Brain memory.
#           This file is NOT for recalling memory — only writing/updating.
#
# HOW TO USE — 3 steps only:
#   1. Pick the right Tier for your situation (Quick Reference at bottom)
#   2. Edit the CONFIGURATION block — task-specific values ONLY (3-5 values, no paths)
#   3. Copy the entire tier block (CONFIGURATION + prompt) → paste into Claude Code
#
# PATHS: Every prompt reads AI_Brain/config/paths.md as Step 0.
#        All {VARIABLE} references are resolved from that file automatically.
#        You NEVER need to edit or copy any paths — paths.md is the single source.
#
# PATHS.MD LOCATION (the only hardcoded path in this entire file):
#   /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/config/paths.md
# ============================================================


=====================================================================================================================
## Tier 0 — After Each Small Task  (within same session)         Model: claude-sonnet-4-6 | ~30 sec | Zero cost
=====================================================================================================================
# WHEN: Finished one small task — fixed a bug, added a method, wired a route, resolved one issue.
#       Claude still has full context from this session. Zero extra reading needed.
# COPY: Everything below the dashed line
# ─────────────────────────────────────────────────────────────────────────────────────────────

### CONFIGURATION  ← edit these 4 values only
  MODULE         = HRS                       # e.g. HPC, Timetable, QuestionBank
  TASK_DONE      = [Generted Feature Specification, DDL & Development Plan for "HR & Payroll" Module]
  BUG_RESOLVED   = NONE                      # BUG-XXX-00N  or  NONE
  DECISION_MADE  = NONE                      # one-line architectural decision  or  NONE

---

Update AI Brain for what we just completed.
Do NOT re-read the codebase — use context already loaded in this session.
Do NOT read paths.md — AI Brain files are referenced by relative path below.

  Task done     : {{TASK_DONE}}
  Module        : {{MODULE}}
  Bug resolved  : {{BUG_RESOLVED}}
  Decision made : {{DECISION_MADE}}

Update ONLY the files that need changing:

  1. AI_Brain/state/progress.md
     → Mark {{TASK_DONE}} as done under {{MODULE}}; update date to today.

  2. AI_Brain/lessons/known-issues.md  (skip if BUG_RESOLVED = NONE)
     → Mark {{BUG_RESOLVED}} as RESOLVED with today's date.

  3. AI_Brain/state/decisions.md  (skip if DECISION_MADE = NONE)
     → Append {{DECISION_MADE}} under {{MODULE}} with today's date.

No report needed. Confirm which lines changed.


=====================================================================================================================
## Tier 1 — After Completing a Bigger Task                       Model: claude-sonnet-4-6 | ~2-3 min
=====================================================================================================================
# WHEN: Finished something meaningful — a controller, service, set of views, a major bug fix.
#       Same session OR fresh session with module context loaded.
# COPY: Everything below the dashed line
# ─────────────────────────────────────────────────────────────────────────────────────────────

### CONFIGURATION  ← edit these 5 values only
  MODULE         = HRS & PRL
  MODULE_DIR     = Hpc                       # Laravel path: Modules/Hpc/
  DEVELOPER      = Shailesh
  TASK_SUMMARY   = [1-2 sentence description of what was built/fixed]
  NEW_ISSUES     = NONE                      # comma-separated new issues found  or  NONE

---

### Step 0 — Load path variables
Read: /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/config/paths.md
Load ALL variables. Every {VARIABLE} below is resolved from that file.

### Update AI Brain — Task Completion: {{MODULE}}

  Module   : {{MODULE}} | Code: {LARAVEL_REPO}/Modules/{{MODULE_DIR}}/
  Developer: {{DEVELOPER}} | Done: {{TASK_SUMMARY}}

### Step 1 — Read current state (do NOT skip)
  1. {AI_BRAIN}/state/progress.md         → find {{MODULE}} entry
  2. {AI_BRAIN}/memory/modules-map.md     → find {{MODULE}} row
  3. {AI_BRAIN}/lessons/known-issues.md   → find {{MODULE}} section

### Step 2 — Scan only changed files
  Run: git -C {LARAVEL_REPO} log --oneline -10 -- Modules/{{MODULE_DIR}}/
  Read only files changed in the last 10 commits for this module.

### Step 3 — Update AI Brain
  A. {AI_BRAIN}/state/progress.md
     → Mark completed items; update % complete; add today's date.

  B. {AI_BRAIN}/memory/modules-map.md
     → Update controller/model/service/route counts if anything was added.
     → Adjust completion % if it changed meaningfully.

  C. {AI_BRAIN}/lessons/known-issues.md
     → Mark resolved issues as RESOLVED [today's date].
     → Add new issues from NEW_ISSUES: codes BUG-{{MODULE}}-00N, SEC-..., PERF-...
     → Skip if NEW_ISSUES = NONE.

  D. {AI_BRAIN}/state/decisions.md  (skip if no architectural decisions were made)
     → Append new decision with module, description, today's date.

### Step 4 — Report
  3-line delta: what was completed | new issues (if any) | updated completion %


=====================================================================================================================
## Tier 2 — Closing for the Day                                  Model: claude-sonnet-4-6 | ~5 min
=====================================================================================================================
# WHEN: End of work session — before closing terminal/IDE.
#       Captures day's progress, partial work state, and what to pick up next.
# COPY: Everything below the dashed line
# ─────────────────────────────────────────────────────────────────────────────────────────────

### CONFIGURATION  ← edit these 5 values only
  MODULE         = HPC                       # Primary module worked on today
  MODULE_DIR     = Hpc
  DEVELOPER      = Shailesh
  ALSO_WORKED_ON = NONE                      # other module names  or  NONE  (e.g. "QuestionBank, Timetable")
  TODAY_DATE     = 26 Mar 2026

---

### Step 0 — Load path variables
Read: /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/config/paths.md
Load ALL variables. Every {VARIABLE} below is resolved from that file.

### End-of-Day AI Brain Update

  Primary module: {{MODULE}} | Also worked on: {{ALSO_WORKED_ON}}
  Developer: {{DEVELOPER}} | Date: {{TODAY_DATE}}

### Step 1 — Load today's git activity
  Run: git -C {LARAVEL_REPO} log --oneline --since="{{TODAY_DATE}} 00:00" --all
  Run: git -C {LARAVEL_REPO} diff HEAD~5..HEAD -- Modules/{{MODULE_DIR}}/
  If ALSO_WORKED_ON is not NONE: run git diff for those module dirs too.

### Step 2 — Reconcile AI Brain with actual changes
  Read:
  1. {AI_BRAIN}/state/progress.md       → check if today's work was logged
  2. {AI_BRAIN}/lessons/known-issues.md → check if resolved bugs were marked
  3. {AI_BRAIN}/memory/modules-map.md   → check if counts are still accurate

  For each module worked on:
  - Were completed items reflected in progress.md?
  - Were resolved bugs marked RESOLVED?
  - Were new issues (if any) logged?

### Step 3 — Update AI Brain
  A. {AI_BRAIN}/state/progress.md
     → Add/update all modules touched today.
     → Mark IN-PROGRESS items clearly (not "done" if not done).
     → Add "Resume from:" note for any task left mid-way.

  B. {AI_BRAIN}/lessons/known-issues.md
     → Resolve closed bugs; log any newly discovered issues.

  C. {AI_BRAIN}/state/decisions.md
     → Log any architectural decisions made today.

  D. {AI_BRAIN}/memory/modules-map.md
     → Update counts and % if any new files were added today.

### Step 4 — End-of-Day Summary
  Output:
  ✓ COMPLETED today (tick list)
  ⏸ IN-PROGRESS / left mid-way (with "resume from" note)
  ⚠ New blockers or issues found
  → Suggested first task for next session


=====================================================================================================================
## Tier 3 — After Module Completion / PR Merge                   Model: claude-opus-4-6 | ~10-15 min
=====================================================================================================================
# WHEN: A module is declared complete or a major PR is merged to main.
#       Full re-audit — validates AI Brain is accurate after all changes.
# COPY: Everything below the dashed line
# ─────────────────────────────────────────────────────────────────────────────────────────────

### CONFIGURATION  ← edit these 4 values only
  MODULE          = HPC
  MODULE_DIR      = Hpc
  DEVELOPER       = Shailesh
  LAST_AUDIT_DATE = 14 Mar 2026              # date of previous full audit

---

### Step 0 — Load path variables
Read: /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/config/paths.md
Load ALL variables. Every {VARIABLE} below is resolved from that file.

### Module Completion Audit: {{MODULE}}

  Module: {{MODULE}} | Directory: {LARAVEL_REPO}/Modules/{{MODULE_DIR}}/
  Developer: {{DEVELOPER}} | Last Audit: {{LAST_AUDIT_DATE}}

### Step 1 — Load full context (read ALL before doing anything)
  1.  {AI_BRAIN}/README.md
  2.  {AI_BRAIN}/memory/project-context.md
  3.  {AI_BRAIN}/memory/modules-map.md
  4.  {AI_BRAIN}/memory/tenancy-map.md
  5.  {AI_BRAIN}/rules/tenancy-rules.md
  6.  {AI_BRAIN}/rules/module-rules.md
  7.  {AI_BRAIN}/rules/security-rules.md
  8.  {AI_BRAIN}/lessons/known-issues.md
  9.  {AI_BRAIN}/state/progress.md
  10. {AI_BRAIN}/state/decisions.md

### Step 2 — Deep Audit of Modules/{{MODULE_DIR}}/
  Count and verify:
  - Controllers (including subdirs) — flag empty stubs, zero-auth methods
  - Models — flag missing soft deletes, missing required columns
  - Services — flag empty or stub implementations
  - FormRequests — flag controllers that lack them
  - Routes — count wired vs unwired in {LARAVEL_REPO}/Modules/{{MODULE_DIR}}/routes/

  For each controller method, check:
  1. Auth       — Gate::authorize() or $this->authorize() on every public method?
  2. Validation — FormRequest or $request->validate() on every write method?
  3. Tenancy    — No cross-layer imports (e.g. Modules\Prime\* inside tenant module)?
  4. Middleware — EnsureTenantHasModule applied on the route group?
  5. N+1        — No eager-loading gaps in index/list methods?
  6. Dead code  — No dd(), var_dump(), hardcoded return true, commented Gate calls?
  7. Stubs      — No empty store()/update() bodies?

### Step 3 — Update AI Brain (ALL files below)
  A. {AI_BRAIN}/memory/modules-map.md
     → Accurate counts: controllers, models, services, form requests, routes.
     → Accurate completion %.
     → Update "What's Complete / What's Missing" for {{MODULE}}.

  B. {AI_BRAIN}/lessons/known-issues.md
     → Add `## {{MODULE}} Post-Completion Audit` section.
     → List every bug/gap: BUG-{{MODULE}}-00N, SEC-{{MODULE}}-00N, PERF-{{MODULE}}-00N.
     → Mark previously listed issues RESOLVED if confirmed fixed.

  C. {AI_BRAIN}/state/progress.md
     → Mark {{MODULE}} with accurate status, %, today's date.
     → If 100% — add to the "Completed Modules" list.

  D. {AI_BRAIN}/state/decisions.md
     → Log any architectural decisions discovered or confirmed.

### Step 4 — Report
  - Final completion % (justify with findings)
  - Top 3 critical issues remaining (security/crash risk) — if any
  - Top 3 functional gaps — if any
  - Verdict: Ready to ship? / What must be fixed first?


=====================================================================================================================
## Tier 4 — DB Schema Scan & Update                              Model: claude-sonnet-4-6 | ~5-10 min
=====================================================================================================================
# WHEN: DB schema changed significantly (new tables, renamed columns, added indexes).
#       AI Brain's db-schema.md is stale or a new module's tables were added.
# COPY: Everything below the dashed line
# ─────────────────────────────────────────────────────────────────────────────────────────────

### CONFIGURATION  ← edit these 3 values only
  MODULE         = HPC                       # module name  or  ALL
  TABLE_PREFIX   = hpc                       # table prefix (e.g. hpc, tt, qns)  or  ALL
  CHANGED_SINCE  = 20 Mar 2026               # date of last schema update

---

### Step 0 — Load path variables
Read: /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/config/paths.md
Load ALL variables. Every {VARIABLE} below is resolved from that file.

### DB Schema Update — {{MODULE}} (prefix: {{TABLE_PREFIX}})

### Step 1 — Read current AI Brain schema knowledge
  1. {AI_BRAIN}/memory/db-schema.md       → current schema summary
  2. {AI_BRAIN}/memory/modules-map.md     → module → table prefix mapping
  3. {AI_BRAIN}/memory/conventions.md     → column naming conventions

### Step 2 — Scan DDL files for {{TABLE_PREFIX}} tables
  If MODULE = ALL:
    Read: {GLOBAL_DDL}, {PRIME_DDL}, {TENANT_DDL} — scan ALL table definitions.

  If MODULE is specific:
    Read: {TENANT_DDL}  (or {PRIME_DDL} / {GLOBAL_DDL} if that module lives there)
    Grep: CREATE TABLE {{TABLE_PREFIX}}_
    Also check: {MODULE_DDL}/{{MODULE}}/ for any module-specific DDL files.

  For each table found, record:
  - Table name, primary key, foreign keys, soft delete columns, unique constraints
  - Generated columns, JSON columns, indexes
  - Flag: any table missing deleted_at, is_active, or created_by

### Step 3 — Update AI Brain
  A. {AI_BRAIN}/memory/db-schema.md
     → Update the {{MODULE}} / {{TABLE_PREFIX}} section with accurate table list.
     → Add/update column notes for key tables.
     → Note schema patterns: polymorphic FKs, generated cols, JSON cols.

  B. {AI_BRAIN}/memory/modules-map.md
     → Update table count for {{MODULE}}.
     → Verify TABLE_PREFIX is correctly recorded.

  C. {AI_BRAIN}/lessons/known-issues.md
     → Add schema issues found: SCHEMA-{{MODULE}}-00N
     → (e.g. missing index on FK, nullable without default, missing soft-delete)

### Step 4 — Report
  - Tables found under prefix {{TABLE_PREFIX}}
  - Schema issues flagged (if any)
  - Changes made to db-schema.md


=====================================================================================================================
## Tier 5 — Requirements Scan & AI Brain Update                  Model: claude-sonnet-4-6 | ~8-12 min
=====================================================================================================================
# WHEN: New requirement docs were written, OR existing docs were updated,
#       OR you want AI Brain to reflect the full project requirement picture.
#       Covers: High-Level Requirements, Detailed Requirements (Dev Done + Pending),
#               Requirement Conditions, Gap Analysis, RBS, Design/Architecture docs.
# COPY: Everything below the dashed line
# ─────────────────────────────────────────────────────────────────────────────────────────────

### CONFIGURATION  ← edit these 2 values only
  MODULE         = ALL                       # specific module name  or  ALL
  FOCUS          = ALL                       # REQUIREMENTS | GAP_ANALYSIS | RBS | DESIGN | ALL

---

### Step 0 — Load path variables
Read: /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/config/paths.md
Load ALL variables. Every {VARIABLE} below is resolved from that file.

### Requirements & Docs Scan — {{MODULE}} | Focus: {{FOCUS}}

### Step 1 — Read current AI Brain knowledge (before scanning docs)
  1. {AI_BRAIN}/memory/project-context.md       → current project scope understanding
  2. {AI_BRAIN}/memory/known-bugs-and-roadmap.md → known gaps and roadmap
  3. {AI_BRAIN}/state/progress.md               → current completion status per module
  4. {AI_BRAIN}/state/decisions.md              → design decisions already recorded
  5. {AI_BRAIN}/memory/modules-map.md           → module scope and status

### Step 2 — Scan High-Level Requirements
  (Run if FOCUS = REQUIREMENTS or ALL)

  Location: {REQUIREMENT_HIGH_level}/
  Action: List all files in that folder.
  If MODULE = ALL: read ALL files found.
  If MODULE is specific: read only the file matching {{MODULE}} (if exists).

  For each file, extract:
  - Module name and scope summary
  - Key features and functional areas listed
  - Any out-of-scope items explicitly stated
  - Priority or phase information (if present)

### Step 3 — Scan Detailed Requirements
  (Run if FOCUS = REQUIREMENTS or ALL)

  Dev-Done requirements — already developed:
    Location: {REQUIRE_DETAIL_DEV_DONE}/
    If MODULE = ALL: read ALL files.
    If MODULE is specific: read matching file only.
    Extract: features confirmed built, acceptance criteria, edge cases covered.

  Dev-Pending requirements — not yet built:
    Location: {REQUIRE_DETAIL_DEV_PEND}/
    If MODULE = ALL: read ALL files.
    If MODULE is specific: read matching file only.
    Extract: features not yet built, priority, dependencies, special conditions.

  Requirement Conditions (cross-cutting rules):
    Location: {REQUIREMENT_CONDITIONS}/
    Read ALL files here (these apply across modules).
    Extract: business rules, validations, constraints that apply to multiple modules.

### Step 4 — Scan Gap Analysis
  (Run if FOCUS = GAP_ANALYSIS or ALL)

  Location: {GAP_ANALYSIS}/
  If MODULE = ALL: list and read all gap analysis files.
  If MODULE is specific: read only matching file.
  Extract: features listed as gaps/missing, severity ratings, priority.

### Step 5 — Scan RBS (Requirements Breakdown Structure)
  (Run if FOCUS = RBS or ALL)

  Location: {RBS_DIR}/
  If MODULE = ALL: list and read all RBS files.
  If MODULE is specific: read only matching file.
  Extract: scope items, requirement IDs, parent-child relationships.

### Step 6 — Scan Design & Architecture Docs
  (Run if FOCUS = DESIGN or ALL)

  Location: {DESIGN_ARCH}/
  Scan sub-folders: Dev_BluePrint/, Module_Wise_Dev_Prompt/, Dev_Phase_Wise_Prompt/
  If MODULE = ALL: list all files; read files most relevant to pending/in-progress modules.
  If MODULE is specific: read only files matching {{MODULE}}.
  Extract: architectural decisions, data flow, integration points, phase planning.

### Step 7 — Compare: Requirements vs AI Brain (find the gaps in knowledge)
  Cross-reference what you read against what was in AI Brain (Step 1):

  A. Features in requirements that are NOT recorded in project-context.md
     → These are missing scope items — add them.

  B. Features in Dev-Pending requirements that are NOT in progress.md as pending tasks
     → These are untracked tasks — add them.

  C. Requirement Conditions that are NOT reflected in any rules/ file or decisions.md
     → These are unrecorded business rules — add them.

  D. Progress.md shows a module as X% complete but detailed requirements reveal more features missing
     → Completion % needs to be revised downward.

  E. Gap analysis items that are already implemented (per progress.md)
     → Mark those gaps as RESOLVED.

### Step 8 — Update AI Brain
  A. {AI_BRAIN}/memory/project-context.md
     → Add/update module scope sections with features from high-level requirements.
     → Update overall project scope if new modules or features were discovered.

  B. {AI_BRAIN}/memory/known-bugs-and-roadmap.md
     → Add gaps from gap analysis docs (not yet recorded).
     → Mark gaps as RESOLVED if already implemented.
     → Add pending requirement features as roadmap items.

  C. {AI_BRAIN}/state/progress.md
     → Adjust completion % for any module where requirements reveal missing work.
     → Add untracked pending tasks from Dev-Pending requirement docs.
     → Add note per module: "Requirements doc: [filename] — [date]"

  D. {AI_BRAIN}/state/decisions.md
     → Log any business rules or architectural decisions found in design docs
        that are not yet recorded in decisions.md.

  E. {AI_BRAIN}/memory/modules-map.md
     → Update "scope" column for modules where high-level req doc clarifies scope.

### Step 9 — Report
  Output:
  - New requirements found (not previously in AI Brain)
  - Completion % changes (module name: old% → new%)
  - New pending tasks added to progress.md
  - Business rules now recorded in decisions.md
  - Gaps resolved (if any gap analysis items were marked done)


=====================================================================================================================
## Tier 6 — Full Codebase Scan (All Modules)                     Model: see phases | ~20-30 min
=====================================================================================================================
# WHEN: AI Brain is stale across multiple modules, after a long gap, or after major refactor.
#       Run in TWO PHASES — do NOT combine. Use /compact between phases.
# COPY: One phase at a time — copy Phase 1 block first, then Phase 2 after Phase 1 completes.
# ─────────────────────────────────────────────────────────────────────────────────────────────

### CONFIGURATION  ← no task-specific values needed — leave as-is

  (none — this tier scans everything)

---

### ═══ PHASE 1 — Structure Count Scan ═══                       Model: claude-sonnet-4-6

### Step 0 — Load path variables
Read: /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/config/paths.md
Load ALL variables. Every {VARIABLE} below is resolved from that file.

Audit the entire codebase and update module counts in AI Brain.

### Step 1 — Read current AI Brain state
  1. {AI_BRAIN}/memory/modules-map.md
  2. {AI_BRAIN}/state/progress.md

### Step 2 — Scan all modules in {LARAVEL_REPO}/Modules/
  For each module directory:
  - Read module.json → get name, enabled/disabled status
  - Count Models:       Modules/{Name}/app/Models/*.php
  - Count Controllers:  Modules/{Name}/app/Http/Controllers/**/*.php
  - Count Services:     Modules/{Name}/app/Services/**/*.php
  - Count FormRequests: Modules/{Name}/app/Http/Requests/**/*.php
  - Count route lines:  Modules/{Name}/routes/*.php
  - Count migrations:   database/migrations/tenant/ files with module prefix

### Step 3 — Update AI Brain
  - {AI_BRAIN}/memory/modules-map.md → accurate counts per module
  - {AI_BRAIN}/state/progress.md     → accurate completion % (code-based only — do NOT guess)

  RULE: Do NOT guess % — derive only from what routes, models, and controllers actually exist.

--- USE /compact NOW — then run Phase 2 below ---


### ═══ PHASE 2 — Deep Quality Audit ═══                         Model: claude-opus-4-6
### (Run ONLY after Phase 1 is fully complete and /compact was run)

### Step 0 — Load path variables
Read: /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/config/paths.md
Load ALL variables. Every {VARIABLE} below is resolved from that file.

Deep audit of each module for bugs, gaps, and security issues.

### Step 1 — Read Phase 1 output (already updated)
  1. {AI_BRAIN}/memory/modules-map.md
  2. {AI_BRAIN}/state/progress.md
  3. {AI_BRAIN}/lessons/known-issues.md

### Step 2 — For each module (prioritise 80-95% complete ones first)
  1. Read routes → identify routes pointing to non-existent controller methods
  2. Read each controller → identify stub/TODO/empty responses
  3. Check SEC: missing auth middleware, missing policy checks
  4. Check PERF: N+1 queries, missing eager loading in index methods
  5. Check VAL: store/update without Form Request validation
  6. Check DEAD: dd(), var_dump(), commented Gate calls, hardcoded return true

### Step 3 — Update AI Brain
  - {AI_BRAIN}/lessons/known-issues.md → new bugs/gaps per module (BUG-XXX-00N codes)
  - {AI_BRAIN}/state/progress.md       → adjust % if gaps were found
  - {AI_BRAIN}/state/decisions.md      → log any architectural decisions discovered

### Step 4 — Final report
  - Modules with hidden gaps (claimed % vs actual %)
  - Top 5 security issues across all modules
  - Top 5 N+1 / performance issues
  - Overall project completion % (recalculated)


=====================================================================================================================
## Tier 7 — Complete AI Brain Rebuild (Nuclear)                  Model: mixed | ~45-60 min
=====================================================================================================================
# WHEN: AI Brain is severely out of date, after major restructuring, or starting fresh.
#       Runs ALL update types in sequence: schema + requirements + codebase + integrity check.
#       Run ONE PHASE AT A TIME. Use /compact between every phase.
# COPY: One phase block at a time.
# ─────────────────────────────────────────────────────────────────────────────────────────────

### CONFIGURATION  ← no task-specific values needed — leave as-is

  (none — this rebuilds everything)

---

### ═══ PHASE A — Brain Staleness Audit ═══                      Model: claude-sonnet-4-6 | ~2 min

### Step 0 — Load path variables
Read: /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/config/paths.md
Load ALL variables. Every {VARIABLE} below is resolved from that file.

Read ALL AI Brain files:
  {AI_BRAIN}/README.md
  {AI_BRAIN}/config/paths.md
  {AI_BRAIN}/memory/*.md          (all files)
  {AI_BRAIN}/state/*.md           (progress.md, decisions.md)
  {AI_BRAIN}/lessons/known-issues.md
  {AI_BRAIN}/rules/*.md           (all files)

Output a "staleness report": which brain files need updating and why.
Do NOT update anything yet.

→ USE /compact THEN RUN PHASE B


### ═══ PHASE B — DB Schema Rebuild ═══                          Model: claude-sonnet-4-6 | ~10 min
# Use Tier 4 prompt above with MODULE=ALL, TABLE_PREFIX=ALL
# Updates: db-schema.md, modules-map.md (table counts)

### Step 0 — Load path variables
Read: /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/config/paths.md
Load ALL variables.

Run the Tier 4 prompt with MODULE=ALL, TABLE_PREFIX=ALL.

→ USE /compact THEN RUN PHASE C


### ═══ PHASE C — Requirements & Docs Rebuild ═══                Model: claude-sonnet-4-6 | ~10 min
# Use Tier 5 prompt above with MODULE=ALL, FOCUS=ALL
# Updates: project-context.md, known-bugs-and-roadmap.md, progress.md, decisions.md, modules-map.md

### Step 0 — Load path variables
Read: /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/config/paths.md
Load ALL variables.

Run the Tier 5 prompt with MODULE=ALL, FOCUS=ALL.

→ USE /compact THEN RUN PHASE D


### ═══ PHASE D — Codebase Structure Scan ═══                    Model: claude-sonnet-4-6 | ~10 min
# Use Tier 6 Phase 1 prompt
# Updates: modules-map.md (controller/model/service counts), progress.md

### Step 0 — Load path variables
Read: /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/config/paths.md
Load ALL variables.

Run the Tier 6 Phase 1 prompt.

→ USE /compact THEN RUN PHASE E


### ═══ PHASE E — Deep Quality Audit ═══                         Model: claude-opus-4-6 | ~15-20 min
# Use Tier 6 Phase 2 prompt
# Updates: known-issues.md, progress.md, decisions.md

### Step 0 — Load path variables
Read: /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/config/paths.md
Load ALL variables.

Run the Tier 6 Phase 2 prompt.

→ USE /compact THEN RUN FINAL PHASE


### ═══ FINAL — AI Brain Integrity Check ═══                     Model: claude-sonnet-4-6 | ~3 min

### Step 0 — Load path variables
Read: /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/config/paths.md
Load ALL variables.

Read all updated brain files and cross-check for consistency:
  1. {AI_BRAIN}/memory/modules-map.md    → counts match what code has
  2. {AI_BRAIN}/state/progress.md        → % consistent with modules-map
  3. {AI_BRAIN}/lessons/known-issues.md  → no duplicate issue codes
  4. {AI_BRAIN}/state/decisions.md       → no duplicate entries

Fix any inconsistencies found:
  - Module in modules-map but NOT in progress.md → add it
  - Completion % in progress.md ≠ modules-map → fix both to match code reality
  - Duplicate issue codes → deduplicate (keep the more detailed entry)
  - Duplicate decision entries → merge into one

Output: Final integrity report with overall project health and completion %.


=====================================================================================================================
## Quick Reference — Tier Selection Guide
=====================================================================================================================

+--------+------------------------------------------+--------------------+----------+----------------+
| Tier   | Situation                                | Files Updated      | Model    | Time           |
+--------+------------------------------------------+--------------------+----------+----------------+
| Tier 0 | Just finished one small task             | progress,          | Sonnet   | ~30 sec        |
|        | (within same session — no paths needed)  | issues, decisions  |          |                |
+--------+------------------------------------------+--------------------+----------+----------------+
| Tier 1 | Finished a bigger task (controller,      | progress,          | Sonnet   | ~2-3 min       |
|        | service, set of views, major bug fix)    | modules-map,       |          |                |
|        |                                          | issues, decisions  |          |                |
+--------+------------------------------------------+--------------------+----------+----------------+
| Tier 2 | Closing for the day                      | progress,          | Sonnet   | ~5 min         |
|        | (always run before shutting down)        | modules-map,       |          |                |
|        |                                          | issues, decisions  |          |                |
+--------+------------------------------------------+--------------------+----------+----------------+
| Tier 3 | Module declared complete / PR merged     | ALL brain files    | Opus     | ~10-15 min     |
|        | to main                                  | for that module    |          |                |
+--------+------------------------------------------+--------------------+----------+----------------+
| Tier 4 | DB schema changed significantly          | db-schema.md,      | Sonnet   | ~5-10 min      |
|        | (new tables, renamed columns, indexes)   | modules-map.md     |          |                |
+--------+------------------------------------------+--------------------+----------+----------------+
| Tier 5 | Requirement docs created or updated      | project-context,   | Sonnet   | ~8-12 min      |
|        | (high-level, detailed, conditions, gaps) | roadmap, progress, |          |                |
|        |                                          | decisions,         |          |                |
|        |                                          | modules-map        |          |                |
+--------+------------------------------------------+--------------------+----------+----------------+
| Tier 6 | Brain stale across many modules          | ALL brain files    | Ph1:     | ~20-30 min     |
|        | (2 phases — use /compact between)        | across all modules | Sonnet   |                |
|        |                                          |                    | Ph2: Opus|                |
+--------+------------------------------------------+--------------------+----------+----------------+
| Tier 7 | Nuclear rebuild — brain severely stale  | ALL brain files,   | Mixed    | ~45-60 min     |
|        | or after major restructuring             | full rebuild       | Sonnet + |                |
|        | (5 phases + final — use /compact each)   |                    | Opus     |                |
+--------+------------------------------------------+--------------------+----------+----------------+

Practical rules:
  - Same session, small task done?                → Tier 0 (always — it's free, 30 seconds)
  - Still in session, bigger feature done?        → Tier 1
  - End of day?                                   → Tier 2 (always before closing)
  - Module shipped to main?                       → Tier 3
  - Schema changed?                               → Tier 4 (run alongside Tier 1/2)
  - Requirement doc created or updated?           → Tier 5
  - Starting after a long break (>1 week)?        → Tier 6 Phase 1 first, then verify
  - Brain needs full reset?                       → Tier 7


=====================================================================================================================
## How Paths Work in This File (v4 design)
=====================================================================================================================

  Every prompt in this file reads ONE file as Step 0:
    /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/config/paths.md

  Claude loads ALL variables from that file and uses them throughout the prompt.
  Variables used in prompts ({AI_BRAIN}, {LARAVEL_REPO}, {TENANT_DDL}, etc.) are resolved from paths.md.

  You never need to update paths in this file.
  If a path changes → update AI_Brain/config/paths.md → all prompts pick it up automatically.

  Variables used in prompts (resolved from paths.md):
    {AI_BRAIN}                  = databases/AI_Brain/
    {LARAVEL_REPO}              = /Users/bkwork/Herd/prime_ai
    {DB_REPO}                   = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase
    {DDL_DIR}                   = {DB_REPO}/1-Master_DDLs
    {GLOBAL_DDL}                = {DDL_DIR}/global_db_v2.sql
    {PRIME_DDL}                 = {DDL_DIR}/prime_db_v2.sql
    {TENANT_DDL}                = {DDL_DIR}/tenant_db_v2.sql
    {MODULE_DDL}                = {DB_REPO}/1-Module_DDLs
    {REQUIREMENT_HIGH_level}    = {OLD_REPO}/2-Requirement_Module_wise/1-HighLevel_Requirements
    {REQUIRE_DETAIL_DEV_DONE}   = {OLD_REPO}/2-Requirement_Module_wise/2-Detailed_Requirements/V1/Dev_Done
    {REQUIRE_DETAIL_DEV_PEND}   = {OLD_REPO}/2-Requirement_Module_wise/2-Detailed_Requirements/V1/Dev_Pending
    {REQUIREMENT_CONDITIONS}    = {OLD_REPO}/2-Requirement_Module_wise/3-Requirement_Conditions
    {GAP_ANALYSIS}              = {OLD_REPO}/3-Project_Planning/2-Gap_Analysis
    {RBS_DIR}                   = {OLD_REPO}/3-Project_Planning/1-RBS
    {DESIGN_ARCH}               = {OLD_REPO}/3-Design_Architecture
    {WORK_STATUS}               = {OLD_REPO}/3-Project_Planning/9-Work_Status
    {WORK_IN_PROG}              = {OLD_REPO}/5-Work-In-Progress
