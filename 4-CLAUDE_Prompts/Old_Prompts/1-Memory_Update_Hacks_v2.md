# Daily Commands for Memory Update (Enhanced — Single Config)
# ============================================================
#
# HOW TO USE:
# 1. Edit ONLY the CONFIGURATION section below (5 values)
# 2. Select the Tier you need + copy/paste into Claude Code
# 3. Claude will substitute {{MODULE}}, {{MODULE_DIR}}, etc. automatically
#
# To switch modules: change the 5 values below. Everything else adapts.
# ============================================================


=====================================================================================================================
## CONFIGURATION  (Edit ONLY these 5 values — they flow into every tier below)
=====================================================================================================================

  MODULE         = HPC                    # Used in: issue codes (BUG-HPC-001), section headers, AI Brain lookups
  MODULE_DIR     = Hpc                    # Used in: file paths (Modules/Hpc/), git commands
  BRANCH         = Brijesh_HPC            # Used in: context for the prompt
  DEVELOPER      = Shailesh               # Used in: context for the prompt
  LAST_AUDIT_DATE = 15th Mar 2026         # Used in: git --since filter (Tier 3)

  AI_BRAIN = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/



=====================================================================================================================
## Tier 1 — First-Time Full Module Audit                                  (Model: claude-opus-4-6)
=====================================================================================================================
When: Starting a new module for the first time, or first documentation of an existing module.


---

### CONFIGURATION
  MODULE         = HPC                    # Used in: issue codes (BUG-HPC-001), section headers, AI Brain lookups
  MODULE_DIR     = Hpc                    # Used in: file paths (Modules/Hpc/), git commands
  BRANCH         = Brijesh_HPC            # Used in: context for the prompt
  DEVELOPER      = Shailesh               # Used in: context for the prompt
  LAST_AUDIT_DATE = 14th Mar 2026         # Used in: git --since filter (Tier 3)

  AI_BRAIN = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/
  ---

### Module First-Time Audit
  **Module:** {{MODULE}}
  **Module Directory:** Modules/{{MODULE_DIR}}/
  **Branch:** {{BRANCH}}
  **Developer:** {{DEVELOPER}}

  You are Claude Code working on the Prime-AI multi-tenant school ERP.
  AI Brain is at: {{AI_BRAIN}}

### Step 1 — Load Context (read ALL before doing anything)
  1. AI_Brain/README.md
  2. AI_Brain/memory/project-context.md
  3. AI_Brain/memory/tenancy-map.md
  4. AI_Brain/memory/modules-map.md
  5. AI_Brain/rules/tenancy-rules.md
  6. AI_Brain/rules/module-rules.md
  7. AI_Brain/lessons/known-issues.md
  8. AI_Brain/state/progress.md

### Step 2 — Deep Audit of `Modules/{{MODULE_DIR}}/`
  Count and verify:
  - Controllers (including subdirs) — note any with empty stubs or zero auth
  - Models — note any missing soft deletes or required columns
  - Services — note empty or incomplete ones
  - FormRequests — note controllers that lack them
  - Routes (in tenant.php or central routes) — count wired vs unwired

  For each controller, check:
  1. **Auth:** Does every public method have `Gate::authorize()` or `$this->authorize()`?
  2. **Validation:** Does every write method use a FormRequest or explicit `$request->validate()`?
  3. **Tenancy:** Any cross-layer imports (e.g., Modules\Prime\* inside a tenant module)?
  4. **EnsureTenantHasModule:** Is it applied on the route group?
  5. **N+1:** Any loops with un-eager-loaded relationships?
  6. **Dead code:** `dd()`, `var_dump()`, commented-out Gate calls, hardcoded `return true` in authorize()?
  7. **Stubs:** Any store()/update() that are completely empty?

### Step 3 — Update AI Brain
  After the audit, update ALL of the following:

  **A. AI_Brain/memory/modules-map.md**
  - Update the row for {{MODULE}} with accurate controller/model/service/request counts
  - Update completion % based on findings
  - Update the "What's Complete / What's Missing" row in the detail table

  **B. AI_Brain/lessons/known-issues.md**
  - Add a `## {{MODULE}} Specific` section (or append to existing)
  - List every bug/gap found with a code like BUG-{{MODULE}}-001, SEC-{{MODULE}}-001, PERF-{{MODULE}}-001

  **C. AI_Brain/state/progress.md**
  - Update the {{MODULE}} entry with current status, % complete, and date [TODAY'S DATE]

  **D. AI_Brain/state/decisions.md**
  - Add any architectural decisions discovered (naming patterns, design choices, workarounds)

### Step 4 — Report
  Output a concise summary:
  - Completion % (justify with findings)
  - Top 3 critical issues (security/crashes)
  - Top 3 functional gaps (missing features)
  - Recommended fix order



=====================================================================================================================
## Tier 2 — After Each Task (within same Claude session)                  (Model: claude-sonnet-4-6)
=====================================================================================================================
When: You just finished a task and Claude still has full context. Zero extra cost.

---

### CONFIGURATION
  MODULE         = HPC                    # Used in: issue codes (BUG-HPC-001), section headers, AI Brain lookups
  MODULE_DIR     = Hpc                    # Used in: file paths (Modules/Hpc/), git commands
  BRANCH         = Brijesh_HPC            # Used in: context for the prompt
  DEVELOPER      = Shailesh               # Used in: context for the prompt
  LAST_AUDIT_DATE = 14th Mar 2026         # Used in: git --since filter (Tier 3)

  AI_BRAIN = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/
---

Update AI Brain for what we just completed:
- progress.md   -> mark [TASK NAME] as done
- known-issues.md -> mark [BUG-XXX-00N] as RESOLVED if fixed
- decisions.md  -> add D[N] if any architectural decision was made

---

This takes 30 seconds and costs almost nothing (context already loaded).



=====================================================================================================================
## Tier 3 — End of Day / After PR Merge                                  (Model: claude-sonnet-4-6)
=====================================================================================================================
When: End of work day, or after merging a PR. Catches anything missed in Tier 2 quick updates.

---

### CONFIGURATION
  MODULE         = HPC                    # Used in: issue codes (BUG-HPC-001), section headers, AI Brain lookups
  MODULE_DIR     = Hpc                    # Used in: file paths (Modules/Hpc/), git commands
  BRANCH         = Brijesh_HPC            # Used in: context for the prompt
  DEVELOPER      = Shailesh               # Used in: context for the prompt
  LAST_AUDIT_DATE = 14th Mar 2026         # Used in: git --since filter (Tier 3)

  AI_BRAIN = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/
---

### Module Incremental Memory Update
  **Module:** {{MODULE}}
  **Module Directory:** Modules/{{MODULE_DIR}}/
  **Branch:** {{BRANCH}}
  **Developer:** {{DEVELOPER}}

  You are Claude Code working on the Prime-AI multi-tenant school ERP.
  AI Brain is at: {{AI_BRAIN}}

### Step 1 — Load Existing State (read ALL before doing anything)
  1. AI_Brain/state/progress.md         <- find the {{MODULE}} entry
  2. AI_Brain/lessons/known-issues.md   <- find the {{MODULE}} section
  3. AI_Brain/memory/modules-map.md     <- find the {{MODULE}} row
  4. AI_Brain/state/decisions.md        <- find any {{MODULE}} decisions

### Step 2 — Identify What Changed
  Run these to find what has changed since the last audit date (from progress.md):

  ```bash
  git log --oneline --since="{{LAST_AUDIT_DATE}}" -- Modules/{{MODULE_DIR}}/
  git diff HEAD~10..HEAD -- Modules/{{MODULE_DIR}}/
  ```
  Focus only on files that were added, changed, or deleted in this branch.

### Step 3 — Targeted Re-Audit
  For each changed file:
  1. If a new controller was added — check auth, validation, stubs, N+1
  2. If an existing controller was modified — re-check only the changed methods
  3. If a new model was added — check soft deletes, required columns, relationships
  4. If a new route was added — check it is covered by EnsureTenantHasModule and Gate
  5. If a bug was fixed — verify the fix is complete, not partial

### Step 4 — Update AI Brain (only changed items)
  A. AI_Brain/lessons/known-issues.md
  - Mark resolved issues as RESOLVED with date
  - Add any NEW issues found with next available code (BUG-{{MODULE}}-00N)

  B. AI_Brain/state/progress.md
  - Update {{MODULE}} entry: new % complete, what was done, date [TODAY'S DATE]

  C. AI_Brain/memory/modules-map.md
  - Update controller/model/service counts if any were added
  - Update completion % if meaningfully changed

  D. AI_Brain/state/decisions.md
  - Add any new architectural decisions made in this branch

### Step 5 — Report
  Output a concise delta summary:
  - What was completed since last audit
  - What new issues (if any) were introduced
  - Updated completion %
  - Remaining top priorities



=====================================================================================================================
## Tier 4 — New Sprint / Major Feature Complete (Full Re-Audit)           (Model: claude-opus-4-6)
=====================================================================================================================
When: Start of new sprint, or when handing a module to a new developer.
This is the same as Tier 1 — validates the AI Brain is still accurate after many changes.

---

### CONFIGURATION
  MODULE         = HPC                    # Used in: issue codes (BUG-HPC-001), section headers, AI Brain lookups
  MODULE_DIR     = Hpc                    # Used in: file paths (Modules/Hpc/), git commands
  BRANCH         = Brijesh_HPC            # Used in: context for the prompt
  DEVELOPER      = Shailesh               # Used in: context for the prompt
  LAST_AUDIT_DATE = 14th Mar 2026         # Used in: git --since filter (Tier 3)

  AI_BRAIN = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/
---

### CONFIGURATION
  MODULE         = HPC                    # Used in: issue codes (BUG-HPC-001), section headers, AI Brain lookups
  MODULE_DIR     = Hpc                    # Used in: file paths (Modules/Hpc/), git commands
  BRANCH         = Brijesh_HPC            # Used in: context for the prompt
  DEVELOPER      = Shailesh               # Used in: context for the prompt
  LAST_AUDIT_DATE = 14th Mar 2026         # Used in: git --since filter (Tier 3)

  AI_BRAIN = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/
---

### Module Full Re-Audit
  **Module:** {{MODULE}}
  **Module Directory:** Modules/{{MODULE_DIR}}/
  **Branch:** {{BRANCH}}
  **Developer:** {{DEVELOPER}}

  You are Claude Code working on the Prime-AI multi-tenant school ERP.
  AI Brain is at: {{AI_BRAIN}}

### Step 1 — Load Context (read ALL before doing anything)
  1. AI_Brain/README.md
  2. AI_Brain/memory/project-context.md
  3. AI_Brain/memory/tenancy-map.md
  4. AI_Brain/memory/modules-map.md
  5. AI_Brain/rules/tenancy-rules.md
  6. AI_Brain/rules/module-rules.md
  7. AI_Brain/lessons/known-issues.md
  8. AI_Brain/state/progress.md

### Step 2 — Deep Audit of `Modules/{{MODULE_DIR}}/`
  Count and verify:
  - Controllers (including subdirs) — note any with empty stubs or zero auth
  - Models — note any missing soft deletes or required columns
  - Services — note empty or incomplete ones
  - FormRequests — note controllers that lack them
  - Routes (in tenant.php or central routes) — count wired vs unwired

  For each controller, check:
  1. **Auth:** Does every public method have `Gate::authorize()` or `$this->authorize()`?
  2. **Validation:** Does every write method use a FormRequest or explicit `$request->validate()`?
  3. **Tenancy:** Any cross-layer imports (e.g., Modules\Prime\* inside a tenant module)?
  4. **EnsureTenantHasModule:** Is it applied on the route group?
  5. **N+1:** Any loops with un-eager-loaded relationships?
  6. **Dead code:** `dd()`, `var_dump()`, commented-out Gate calls, hardcoded `return true` in authorize()?
  7. **Stubs:** Any store()/update() that are completely empty?

### Step 3 — Update AI Brain
  After the audit, update ALL of the following:

  **A. AI_Brain/memory/modules-map.md**
  - Update the row for {{MODULE}} with accurate controller/model/service/request counts
  - Update completion % based on findings
  - Update the "What's Complete / What's Missing" row in the detail table

  **B. AI_Brain/lessons/known-issues.md**
  - Add a `## {{MODULE}} Specific` section (or append to existing)
  - List every bug/gap found with a code like BUG-{{MODULE}}-001, SEC-{{MODULE}}-001, PERF-{{MODULE}}-001

  **C. AI_Brain/state/progress.md**
  - Update the {{MODULE}} entry with current status, % complete, and date [TODAY'S DATE]

  **D. AI_Brain/state/decisions.md**
  - Add any architectural decisions discovered (naming patterns, design choices, workarounds)

### Step 4 — Report
  Output a concise summary:
  - Completion % (justify with findings)
  - Top 3 critical issues (security/crashes)
  - Top 3 functional gaps (missing features)
  - Recommended fix order



=====================================================================================================================
## Quick Reference — Tier Summary
=====================================================================================================================

+----------+-------------------------------------------+----------------+----------------------+--------------+
| Tier     |         When                              |    Action      | Model & Effort       |    Time      |
+----------+-------------------------------------------+----------------+----------------------+--------------+
| Tier 1   | Start a New Module (first time)           | Full Audit     | Claude Opus High     | ~10-15 min   |
+----------+-------------------------------------------+----------------+----------------------+--------------+
| Tier 2   | After Each Task (within same session)     | Quick Update   | Claude Sonnet Low    | ~30s         |
+----------+-------------------------------------------+----------------+----------------------+--------------+
| Tier 3   | End of day / After PR merged              | Incremental    | Claude Sonnet High   | ~3-5 min     |
+----------+-------------------------------------------+----------------+----------------------+--------------+
| Tier 4   | New Sprint / Major Feature Complete       | Full Re-Audit  | Claude Opus High     | ~10-15 min   |
+----------+-------------------------------------------+----------------+----------------------+--------------+

Practical rule: If you're still in the same VS Code Claude session — use Tier 2.
Never open a new session just to update the brain for one task.



=====================================================================================================================
## Tier 5 — Recreate / Full Scan Memory Update of AI Brain
=====================================================================================================================
When: AI Brain is stale or missing. Full codebase audit across ALL modules (not module-specific).


---

AI_BRAIN = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/

### Phase 1 — Codebase Structure Audit (run first)

I need you to audit the entire codebase and update the AI Brain with accurate information about all merged modules.

**AI Brain location:** {{AI_BRAIN}}
**Code location:** /Users/bkwork/Herd/prime_ai_main/

Read these AI Brain files first to understand current state:
- `AI_Brain/memory/modules-map.md`
- `AI_Brain/state/progress.md`

Then scan the codebase:
1. List all directories in `Modules/` — these are the modules
2. For each module, count:
    - Models: `Modules/{Name}/app/Models/*.php`
    - Controllers: `Modules/{Name}/app/Http/Controllers/*.php`
    - Services: `Modules/{Name}/app/Services/**/*.php`
    - Routes: lines in `Modules/{Name}/routes/`
    - Migrations (tenant): `database/migrations/tenant/` files containing the module's table prefix
3. Read each module's `module.json` for enabled/disabled status

Then update:
- `AI_Brain/memory/modules-map.md` — accurate model/controller/service counts per module
- `AI_Brain/state/progress.md` — accurate completion % based on what's actually in the code

Do NOT guess completion % — base it only on what routes, models, and controllers actually exist.


### Phase 2 — Deep Module Audit (run after Phase 1)

---

AI_BRAIN = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/

Now do a deep audit of each tenant module for known issues, bugs, and gaps.

For each module in `Modules/`:
1. Read the module's route file — identify any routes pointing to non-existent controller methods
2. Read each controller — identify any method that returns a stub/TODO/empty response
3. Check for SEC issues: missing auth middleware, missing policy checks
4. Check for N+1 queries: eager loading missing in index methods
5. Check for missing validation: store/update methods without Form Requests

Record findings in:
- `AI_Brain/lessons/known-issues.md` — new bugs/gaps discovered per module
- `AI_Brain/state/progress.md` — adjust completion % if gaps found

Focus on modules marked 80-95% complete — these are most likely to have hidden gaps.

---


Tips for running Tier 5:
- Run Phase 1 first, let it finish completely before Phase 2
- Phase 1 takes ~5-10 min (reading ~29 modules)
- Phase 2 is heavy — if context fills up, run it one module at a time
- Use /compact between phases to free context
- After both phases, run Tier 2 to save a session summary

+-------------------------------------+---------+--------+--------------------------------------------------------------+
|               Phase                 |  Model  | Effort |                            Reason                            |
+-------------------------------------+---------+--------+--------------------------------------------------------------+
| Phase 1 (structure scan — count     | Sonnet  | High   | Mechanical task — reading files and counting.                |
| files, read module.json)            | 4.6     |        |                                                              |
+-------------------------------------+---------+--------+--------------------------------------------------------------+
| Phase 2 (deep audit — spot bugs,    | Opus    | High   | Requires real judgment: recognizing missing auth checks,     |
| judge completion %, read ctrls)     | 4.6     |        | N+1s, stub methods. Opus is significantly better at this.    |
+-------------------------------------+---------+--------+--------------------------------------------------------------+

The most critical file to get right is AI_Brain/memory/modules-map.md — that's what gets
referenced at the start of every session to know what's in each module.
