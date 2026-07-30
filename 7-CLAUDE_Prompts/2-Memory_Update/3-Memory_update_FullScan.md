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
Read: /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/config/paths.md
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
Read: /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/config/paths.md
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
  