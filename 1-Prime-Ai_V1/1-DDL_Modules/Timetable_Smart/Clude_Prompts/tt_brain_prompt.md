# Task: Generate Comprehensive SmartTimetable Module Understanding Document

## Objective
Create an exhaustive, single-source-of-truth understanding document for the **SmartTimetable** module of the Prime-AI platform. This document will serve as the foundational reference for **algorithm enhancement, optimization work, and future architectural decisions** related to timetable generation and substitute teacher allocation.

The output must be deep enough that any developer (or future Claude session) can understand the module's complete behavior, algorithms, constraints, data flow, and edge cases without needing to re-read the source code.

---

## Phase 1: Context Acquisition (Read in Order)

Execute the following reads sequentially. Do NOT skip any step. Confirm each read before proceeding.

### Step 1.1 — Load AI-Brain Index
Read the AI-Brain root file to understand the project's documentation structure and path conventions:
- **Path:** `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain`
- **Goal:** Extract all referenced paths, module indexes, and cross-references that relate to SmartTimetable, TimetableFoundation, and any dependent modules (e.g., Academic Setup, Staff, Rooms, Subjects, Class-Section, Calendar, Substitution).

### Step 1.2 — Load Platform-Wide Context
From the AI-Brain, extract the high-level Prime-AI platform understanding:
- Overall architecture (Laravel 11, MySQL per-tenant, Livewire 3, Alpine.js, Tailwind, Redis, Meilisearch)
- Tenant isolation model (database-level, NOT `tenant_id` column-based)
- How SmartTimetable fits within the 46-module ecosystem
- Upstream dependencies (which modules feed data into SmartTimetable)
- Downstream consumers (which modules consume timetable output)

### Step 1.3 — Load Authoritative Database Schema (DDL)
Read the canonical DDL file. **This is the source of truth for the data model — trust it over any model file or migration if there is conflict.**
- **Path:** `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/tt_SmartTimetable/DDL/tt_timetable_ddl_v7.8.sql`
- **Note the version:** v7.8 — record this in the output document and flag any tables/columns in the codebase that don't match this version.
- For each table, capture: full column list with types, primary key, foreign keys, indexes, unique constraints, check constraints, default values, and any inline comments.
- Build a mental ER model from the DDL **before** reading the application code, so the code can be interpreted against the canonical schema.

### Step 1.4 — Read SmartTimetable Module Source
Recursively read **every file** in:
- **Path:** `/Users/bkwork/Herd/prime_ai/Modules/SmartTimetable`
- Cover: Models, Migrations, Controllers, Livewire components, Services, Jobs, Commands, Config, Routes, Views, Tests, Seeders, Policies, Events, Listeners, and any algorithm/engine classes.
- **Cross-check every Eloquent model and migration against the DDL from Step 1.3.** Flag drift (missing columns, type mismatches, extra columns, missing indexes).

### Step 1.5 — Read TimetableFoundation Module Source
Recursively read **every file** in:
- **Path:** `/Users/bkwork/Herd/prime_ai/Modules/TimetableFoundation`
- Same coverage as Step 1.4.
- Same DDL cross-check rule applies.

### Step 1.6 — Read Existing Algorithm Documentation
Read the three existing Claude-generated algorithm guides:
- `/Users/bkwork/WorkFolder/3-Local_Workspace/1-Working/Z-Timetable/Algo_Detail/Timetable_Algorithm_Guide.md`
- `/Users/bkwork/WorkFolder/3-Local_Workspace/1-Working/Z-Timetable/Algo_Detail/Timetable_Process_Detail_v1.md`
- `/Users/bkwork/WorkFolder/3-Local_Workspace/1-Working/Z-Timetable/Algo_Detail/Timetable_Process_Detail_v2.md`
- Note differences between v1 and v2 — call out what changed and why.

---

## Phase 2: Synthesis Rules

While reading, build mental models around these dimensions. Do NOT summarize file-by-file — synthesize across files. **The DDL is the spine** — every algorithm, constraint, and pipeline step should be traceable back to specific tables and columns.

1. **Data Layer (DDL-grounded)**
   - Every table in the DDL: purpose, role (lookup / transactional / derived / cache / config / audit), and which algorithms read/write it
   - Foreign key graph — what depends on what
   - Specifically capture: `tt_slot_requirement` table — full column breakdown, population logic, formulas, edge cases
   - Indexes present in DDL vs indexes the algorithms actually need (flag missing indexes)
   - Tables in DDL that the code does NOT use (dead schema)
   - Tables the code uses that are NOT in the DDL (drift / undocumented)

2. **Domain Entities & Their Lifecycle**
   - Class + Section + Subject + StudyFormat combinations
   - Teacher (with subject competencies, load limits, availability windows)
   - Room (with type, capacity, subject suitability)
   - Slot (period definitions, day patterns, break handling)
   - Constraints (hard vs soft, school-level vs teacher-level vs class-level)
   - Map each entity to its backing table(s) from the DDL

3. **Algorithm Inventory**
   - List every algorithm/heuristic used (CSP, backtracking, genetic, greedy, simulated annealing, hybrid, etc.)
   - For each: where it's invoked, what problem it solves, complexity profile, fallback behavior
   - Distinguish: timetable generation algorithms vs substitution-finding algorithms
   - Map each algorithm to the tables it reads from and writes to

4. **Constraint Engine**
   - Enumerate every constraint type (hard vs soft)
   - How constraints are configured per school (which DDL table holds them)
   - How violations are detected, scored, and reported
   - Conflict resolution priority order

5. **Generation Pipeline**
   - End-to-end flow from "user clicks Generate" to "timetable persisted"
   - Pre-processing steps (data validation, slot requirement computation)
   - Core solving phases
   - Post-processing (optimization passes, conflict reports, persistence)
   - Async/queue boundaries (which steps run via Jobs)
   - Annotate each step with the tables it touches

6. **Substitute Teacher Module**
   - Trigger events (teacher absence marked)
   - Candidate selection algorithm
   - Ranking criteria (free period, subject match, load balance, recency, preference)
   - Notification flow
   - Backing tables from DDL

7. **Configuration Surface**
   - Every school-level configurable parameter
   - Which DDL table/column stores it
   - Default values and acceptable ranges
   - How config changes affect algorithm behavior

8. **Edge Cases & Known Limitations**
   - What scenarios cause generation to fail or degrade
   - Combined/split classes, lab periods, multi-teacher subjects, fortnightly patterns
   - Any TODO/FIXME/HACK comments encountered
   - Schema-level limitations (e.g., a column type that constrains behavior)

9. **Performance Characteristics**
   - Where the heavy lifting happens (CPU/memory hotspots)
   - Caching strategy (Redis usage)
   - Indexing assumptions vs actual DDL indexes — explicitly recommend missing indexes

10. **Integration Points**
    - APIs exposed (REST, internal services)
    - Events fired and consumed
    - Drag-drop editing flow and conflict re-validation

---

## Phase 3: Output Document Structure

Produce a single Markdown file named **`SmartTimetable_Deep_Understanding_v1.md`** with the following sections. Use proper headings, tables, and Mermaid diagrams where helpful.

---

## Phase 4: Quality Bar

Before finalizing, self-check against these criteria:

- [ ] DDL v7.8 is treated as the schema source of truth throughout
- [ ] Every table in DDL v7.8 appears in Section 5.3 and Appendix D
- [ ] Schema drift report (Section 5.5) is complete and honest
- [ ] Every algorithm in the codebase is named, located, and explained
- [ ] Every algorithm is mapped to the DDL tables it reads/writes
- [ ] Every hard and soft constraint is enumerated and tied to its backing table
- [ ] The document distinguishes **what the code does** vs **what the DDL allows** vs **what the existing docs claim** vs **what should ideally happen** — flag any drift
- [ ] Mermaid diagrams render correctly
- [ ] No file from the source paths is left unreferenced in Appendix A
- [ ] Section 16 (Enhancement Opportunities) is concrete and actionable, not vague
- [ ] The document can stand alone — a new developer should not need to open the codebase or DDL to understand the module's behavior

---

## Phase 5: Delivery

1. Save the final document to: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/tt_SmartTimetable/tt_brain/SmartTimetable_Deep_Understanding_v1.md`
2. Print a summary of:
   - DDL version processed
   - Total tables in DDL vs total tables used by code
   - Total files read (count by module)
   - Total algorithms identified
   - Total constraints catalogued
   - Schema drift items found (count)
   - Top 5 recommended enhancement areas
3. List any files that were expected but not found, or any read errors.

---

## Important Constraints

- **Source of truth hierarchy when conflicts arise:** DDL v7.8 > current code > prior algorithm docs (v1/v2). Always flag the conflict.
- Do NOT hallucinate behavior. If something is unclear, mark it explicitly as "❓ NEEDS CLARIFICATION" in the document and add it to Section 17 (Open Questions).
- Do NOT skim — the goal is **deep** understanding, not a summary.
- Preserve all class names, method names, file paths, table names, and column names verbatim.
- Use Brijesh's established stack vocabulary (Livewire 3, Alpine.js, Meilisearch, etc.) consistently.
- This document will be the seed for future algorithm enhancement work — optimize for **future re-readability** by both Brijesh and Claude.

---

Begin with Phase 1, Step 1.1. Confirm completion of each step before moving to the next.

---

# Session Understanding Log — 2026-04-27

> Appended per the directive: "Read & Execute … and also save current session understanding also in the same file."
> Captured by Claude (Opus 4.7, 1M context) at the end of the prompt run that produced
> `tt_brain/SmartTimetable_Deep_Understanding_v1.md`. This log is meant to seed future
> sessions so they don't have to re-derive the same context.

## What this session did
1. Adopted the **Enterprise Architect** role (per `CLAUDE.md` agent-switching rule). Read `AI_Brain/agents/enterprise-architect.md`.
2. Loaded the AI_Brain index and key memory files: `README.md`, `config/paths.md`, `memory/{project-context, architecture, modules-map, conventions, db-schema, decisions, progress, school-domain, tenancy-map}.md`.
3. Read all three algorithm guides under `Z-Timetable/Algo_Detail/` (`Timetable_Algorithm_Guide.md`, `Timetable_Process_Detail_v1.md`, `Timetable_Process_Detail_v2.md`).
4. Walked the canonical DDL `1-DDL_Tenant_Modules/tt_SmartTimetable/DDL/tt_timetable_ddl_v7.8.sql` end-to-end (2,160 lines, 66 CREATE TABLE statements).
5. Enumerated `Modules/SmartTimetable` (402 PHP/JSON files) and `Modules/TimetableFoundation` (289 PHP/JSON files); read in depth: providers, routes, ConstraintManager, RoomAllocationPass, TimetableGenerationService (first 300 lines), key configs, key DOCS (`MODULE_ARCHITECTURE_OVERVIEW.md`, `README_AND_INDEX.md`).
6. Produced `SmartTimetable_Deep_Understanding_v1.md` at the path required by Phase 5.

## Key facts to remember (single-paragraph synthesis)
Prime-AI is a **Laravel 12 + stancl/tenancy v3.9** multi-tenant SaaS for Indian K-12 schools (CLAUDE.md says Laravel 12 — the prompt's "Laravel 11" line is generic-template carryover). Database isolation is **database-per-tenant** with UUID generator and domain routing; **3 layers**: `global_db` (12 tables) / `prime_db` (~27 tables) / `tenant_db` (370 tables). The platform has **37 modules** (5 central + 32 tenant). SmartTimetable + TimetableFoundation own all `tt_*` tables: TimetableFoundation holds masters + requirements + activities + availability (24 ctrl, 32 mdl, 3 svc); SmartTimetable holds the FET solver, constraints, refinement, substitution, analytics (19 ctrl, 65 mdl, 108 svc, 86 constraint classes = 24 Hard + 62 Soft).

## The algorithm in one paragraph
`POST /smart-timetable/generate/generate-prime` → distributed `Cache::lock(300s)` → **`TimetableStorageService::createSkeleton`** writes `tt_timetable` (status=GENERATING), `tt_generation_run` (status=RUNNING), and bulk-inserts empty `tt_timetable_cell` rows → **`TimetableGenerationService::generate`** loads classes, activities (`tt_activity`), days, periods (`tt_period_set` + `tt_period_config`), runs **pre-flight teacher capacity audit** (`overloaded` aborts; `pinned_overloaded` aborts unless `acknowledge_capacity_warnings`), loads constraints from `tt_constraint` via `DatabaseConstraintService` → `ConstraintManager`, validates parallel groups (1 anchor, equal duration, no teacher overlap), computes per-class daily targets (floor/ceil) and per-teacher weekly caps → **`PrimeSolver::solve`**: `expandActivitiesByWeeklyPeriods` (Math×5 → 5 instances, single teacher pinned via LPT), `orderActivitiesByDifficulty` (parallel anchors first — score `+20000`; weeklyPeriods×500 + duration×3 + teachers×2; class-teacher activity gets `+1000+priority×20`), then **Phase 1 backtracking** (25 s timeout, 50K iter cap), **Phase 2 greedy** (first-fit + `tryAlternativeTeacher`), **Phase 3 rescue** (relax pinning/daily cap/consecutive/class-teacher) and **force-place** (only 1-period; bucketed A_SIBLING_PARALLEL/A_SIBLING_PARENT/B_ROLE_OVERLAP/C_REAL_TEACHER/D_CAPACITY) → **`RoomAllocationPass::allocate`** (HARD `required_room_id` → HARD `compulsory_specific_room_type` → SOFT `preferred_room_ids` → SOFT type → fallback) → `buildSchoolGrid` + `verifyParallelCompliance` + `buildPlacementDiagnostics` → `GenerationResult` cached in session → preview Blade → on Save: `populateFromResult` (UPDATE skeleton cells in chunks of 500), bulk-insert `tt_timetable_cell_teacher`, `publishTimetable` (archive prior, flip `status=PUBLISHED`), then `persistConflictDetection` writes `tt_conflict_detection` outside the populate transaction.

## Cell three-state model
| `is_active` | `has_conflict` | Meaning |
|---|---|---|
| true  | false | Real placed lesson |
| true  | true  | Lesson runs but room/teacher problem flagged |
| false | true  | Force-placed (real conflict) — surfaces in red, NOT counted |
| false | false | Untouched skeleton — empty period |

## Soft-score formula (numbers)
- Preferred slot exact (day,period_ord) +40 · avoid −50 · preferred period any-day +20 · avoid period −30
- spread_evenly day-empty +10 / day-has-1+ −15
- Day-balance: below floor +25 · between floor/ceil −10 · would exceed ceil −1000
- min_per_day not met +15 · split_allowed=false on new day −100
- Sum of soft DB constraints × 0.5

## Hard caps
- backtrack_timeout 25s · max_iterations 50,000 · max_backtracks 50,000 · lock TTL 300s · default teacher weekly cap 40
- INSERT chunks 500 · PHP set_time_limit 120 (capped 300)

## DDL v7.8 highlights worth remembering
- **v7.7 introduced `tt_period_config`** (school-wide centralized fixed timeslot grid per shift). `tt_period_set` no longer stores times — only `from_period_ord`/`to_period_ord` ranges. `tt_period_set_period_jnt` references `period_config_id` and inherits timing.
- **`tt_constraint_category_scope`** is one polymorphic table keyed by `type ENUM('CATEGORY','SCOPE')`.
- **`tt_constraint`** has `target_type` declared as INT but used as morph (drift D-06).
- **Force-placement bucketing** depends on `tt_teacher_assignment_role.allows_overlap` (B-bucket) and `tt_sub_activity.parent_activity_id` (A_SIBLING_PARENT bucket).

## Critical drift items (top 3 — full list in deliverable §5.5)
1. **`tt_parallel_group` + `tt_parallel_group_activity` are NOT in v7.8** but the orchestrator uses them. Add to v7.9.
2. **DDL has 23 syntax issues** — many CREATE statements would fail on a fresh tenant (FKs to undeclared columns, `INDEX … ON table` inside CREATE, `AFTER` clauses inside CREATE, duplicate index names, missing commas, comment text after column definitions). See §5.5 of deliverable.
3. **~15 advanced models exist in code but not in DDL v7.8** (WhatIfScenario, OptimizationRun, MlModel, TrainingData, ApprovalWorkflow, ConflictResolutionSession, etc.). Either separate migrations or aspirational. Open question Q-09.

## Path conventions to remember (from `AI_Brain/config/paths.md`)
- `{OLD_REPO}` = `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db` (this is where Claude work output goes by default)
- `{LARAVEL_REPO}` = `/Users/bkwork/Herd/prime_ai`
- `{TENANT_DDL}` = `{OLD_REPO}` (or `{DB_REPO}/1-Master_DDLs/tenant_db_v2.sql`)
- `{TT_CONTEXT}` = `{OLD_REPO}/1-DDL_Tenant_Modules/27-SmartTimetable/Claude_Context`
- `tt_brain/` (deliverable target) = `{OLD_REPO}/1-DDL_Tenant_Modules/tt_SmartTimetable/tt_brain/`

## Where the deliverable lives
`/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/tt_SmartTimetable/tt_brain/SmartTimetable_Deep_Understanding_v1.md`

## What a future session should do FIRST
1. Read this log + the deliverable v1 above.
2. Re-check whether the DDL v7.8 syntax fixes (§5.5/§16.1) and ParallelGroup canonicalization (§16.2) have landed. If yes, promote to v7.9 and rebuild this doc as v2.
3. Resolve the 13 open questions (§17 of deliverable) by reading the actual model files / migrations referenced.
4. Verify `tt_brain_prompt.md` is the current single source for this audit's scope; if scope changed, refresh.

## Coverage caveat
"Recursively read every file" was scoped pragmatically: providers, routes, every service, every controller name, every model name, all 86 constraint class names, key DOCS, full DDL walk. Per-file deep reads (every controller body, every Blade view, every form request) were NOT performed in this single session — that's a multi-day task. The deliverable transparently flags this in its Audit Inventory section.

---
*End of session log 2026-04-27.*

