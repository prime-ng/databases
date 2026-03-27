Read # PROMPT: Generate Task & Sub-Task Prompts from SmartTimetable DDL Gap Analysis

## Mode
Standard mode. This is a **PROMPT GENERATION** task — read source files, generate task prompt files. **No code changes.**

---

## CONFIGURATION
```
AI_BRAIN       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain
SOURCE_DIR     = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/5-Work-In-Progress/8-Smart_Timetable/1-Timetable_Gap_Analysis
OUTPUT_DIR     = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/5-Work-In-Progress/8-Smart_Timetable/Claude_Tasks/Task-2
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai_tarun
MODULE_PATH    = {LARAVEL_REPO}/Modules/SmartTimetable
ROUTES_FILE    = {LARAVEL_REPO}/routes/tenant.php
DDL_FILE       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/0-DDL_Masters/tenant_db_v2.sql
BRANCH         = Brijesh_SmartTimetable
DATE           = 2026-03-17
```

---

## TASK

Read ALL 6 gap analysis files from `{SOURCE_DIR}` and generate **one prompt file per task** for every action item identified. Each prompt must be a self-contained, ready-to-execute Claude prompt that a developer (Tarun) can paste into Claude to complete that specific task.

---

## PRE-READ (Mandatory — Read ALL before generating anything)

1. `{SOURCE_DIR}/00_Verification_Summary.md` — Overview and verdict on Tarun's original audit
2. `{SOURCE_DIR}/01_Table_Names_Corrected.md` — Table name inventory: DDL-only, Migration-only, Name conflicts
3. `{SOURCE_DIR}/02_Missing_Migrations_Corrected.md` — 10 DDL tables needing migrations (prioritized)
4. `{SOURCE_DIR}/03_Phantom_Models_Confirmed.md` — 37 phantom models, 12 actively referenced (will crash)
5. `{SOURCE_DIR}/04_Column_Mismatches_Verified.md` — Column drift in constraint/activity/cell tables + active bugs
6. `{SOURCE_DIR}/05_Real_Bugs_Found.md` — 9 confirmed runtime bugs (BUG-DDL-001 through BUG-DDL-009)
7. `{SOURCE_DIR}/06_Corrected_Action_Plan.md` — Prioritized action plan with effort estimates

Also read for context:
8. `{AI_BRAIN}/state/progress.md` — SmartTimetable section (current state ~72%)
9. `{AI_BRAIN}/lessons/known-issues.md` — SmartTimetable sections (existing + new issues from P01-P21 audit)
10. `{DDL_FILE}` — Scan the `tt_*` table definitions (for migration column references)

---

## OUTPUT STRUCTURE

Create the folder `{OUTPUT_DIR}/` and generate files using this naming convention:

```
{OUTPUT_DIR}/
├── 00_MASTER_TASK_INDEX.md
│
│   ── P0: CRITICAL — Runtime Crash Fixes ──
├── P0_01_BUG-DDL-001_Fix_ClassWorkingDay_Table.md
├── P0_02_BUG-DDL-002_Fix_TeacherAvailabilityLog_Table.md
├── P0_03_BUG-DDL-003_Fix_TimetableCell_ScopeForClass.md
├── P0_04_BUG-DDL-005_Create_10_DDL_Migrations.md
├── P0_05_BUG-DDL-004_Create_12_Phantom_Migrations.md
│
│   ── P1: HIGH — Silent Bugs & Data Issues ──
├── P1_06_BUG-DDL-006_Fix_Constraint_Model_Fillable.md
├── P1_07_BUG-DDL-007_Clean_Dead_Alias_Columns.md
├── P1_08_Annotate_25_Dormant_Phantom_Models.md
│
│   ── P2: MEDIUM — DDL Reconciliation ──
├── P2_09_DDL_Update_Table_Names_Plural.md
├── P2_10_DDL_Update_Constraint_Columns.md
├── P2_11_DDL_Add_Missing_Columns.md
├── P2_12_DDL_Add_PostDDL_Tables.md
├── P2_13_DDL_Add_Phantom_Table_Definitions.md
│
│   ── P3: LOW — Cleanup & Backlog ──
├── P3_14_Fix_TeacherAvailablity_Typo.md
├── P3_15_Clean_Duplicate_Constraint_Columns.md
├── P3_16_Mark_Legacy_Tables_Deprecated.md
└── P3_17_DDL_Add_Standard_Columns.md
```

> **Note:** P0_04 and P0_05 are large tasks. Split them into sub-task sections within the prompt (one section per migration), but keep them as single prompt files for atomic execution.

---

## PROMPT TEMPLATE (use for EVERY task prompt)

Each generated prompt file MUST follow this exact structure:

```markdown
# PROMPT: [Task Title] — SmartTimetable DDL Gap Fix
**Task ID:** [P0_01 / P1_06 / P2_09 / P3_14 etc.]
**Issue IDs:** [BUG-DDL-001 / BUG-DDL-006 etc.]
**Priority:** [P0-Critical / P1-High / P2-Medium / P3-Low]
**Estimated Effort:** [from corrected action plan]
**Prerequisites:** [list any tasks that MUST be done first, by Task ID]

---

## CONFIGURATION
\```
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai_tarun
MODULE_PATH    = {LARAVEL_REPO}/Modules/SmartTimetable
ROUTES_FILE    = {LARAVEL_REPO}/routes/tenant.php
DDL_FILE       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/0-DDL_Masters/tenant_db_v2.sql
BRANCH         = Brijesh_SmartTimetable
\```

---

## CONTEXT

[2-5 sentences explaining WHAT is wrong, WHY it matters, and WHAT the fix should achieve.
Pull exact details from the gap analysis — file names, table names, column names, current vs expected behavior.
Reference the specific gap analysis file (e.g., "See 05_Real_Bugs_Found.md BUG-DDL-001")]

---

## PRE-READ (Mandatory)

[List the specific files Claude must read BEFORE making any changes. Be precise:
- The exact model/migration/route file(s) that need modification
- The DDL file section for column reference (when creating migrations)
- NOT the entire codebase — only files relevant to THIS task]

---

## STEPS

[Numbered step-by-step instructions. Each step should be:
1. Specific — name the file, model, table, column
2. Actionable — "Change", "Create", "Remove", "Add"
3. Verifiable — "Run php artisan migrate to confirm"]

---

## ACCEPTANCE CRITERIA

[Bullet list of what "done" looks like. Examples:
- ClassWorkingDay model queries succeed without "table not found"
- `php artisan migrate` runs without errors
- All 22 new tables exist in tenant database]

---

## DO NOT

[List 2-4 things Claude should NOT do for this task. Examples:
- Do NOT drop existing columns (additive-only migration policy)
- Do NOT rename existing tables
- Do NOT modify controller logic — this task is schema-only
- Do NOT change models outside SmartTimetable module]
\```

---

## SPECIAL INSTRUCTIONS PER PRIORITY

### P0 Tasks (01-05): Critical Runtime Fixes
- These **unblock all P14-P17 features** (Analytics, Refinement, Substitution, API)
- P0_01, P0_02, P0_03 are **surgical model fixes** — change 1-2 lines each
- P0_04 (10 DDL migrations) and P0_05 (12 phantom migrations) are **bulk migration tasks**:
  - For each migration, include: table name, all columns with types, indexes, FKs
  - Reference the DDL for column definitions where available (DDL tables)
  - For phantom tables (no DDL), reference the model's `$fillable` + `$casts` to infer columns
  - ALL migrations must include: `id`, `is_active`, `created_by`, `created_at`, `updated_at`, `deleted_at`
  - Use **plural table names** matching model `$table` values
- Include verification step: `php artisan migrate --pretend` to dry-run
- Prerequisites: None — these are P0, do them first

### P1 Tasks (06-08): Silent Bugs & Annotations
- P1_06 is a **model fillable cleanup** — remove non-existent columns or add migrations for them
  - Include decision: "If the column is needed, create migration. If not, remove from fillable."
- P1_07 addresses **dead alias columns** from fix migration 2026_03_12_100002
  - Default recommendation: document as tech debt, do NOT drop (additive-only policy)
- P1_08 is **bulk annotation** of 25 phantom models with `@phase2` docblock
  - List ALL 25 model file paths in PRE-READ section
- Prerequisites: All P0 tasks complete

### P2 Tasks (09-13): DDL File Updates
- These are **DDL-only changes** — modify `tenant_db_v2.sql`, NO code changes
- P2_09: Rename 28 singular table names to plural (massive but mechanical)
- P2_10: Update constraint table columns to match actual migration columns
- P2_11: Add ~30 missing columns across various tables (from migration extras)
- P2_12: Add `tt_parallel_group`, `tt_parallel_group_activity`, `tt_class_subject_groups`, `tt_class_subject_subgroups` definitions
- P2_13: Add definitions for the 12 phantom tables that got migrations in P0_05
- Include a "Validation" step: compare updated DDL table count against expected total
- Prerequisites: All P0 and P1 tasks complete

### P3 Tasks (14-17): Cleanup & Backlog
- P3_14: Class + file rename (TeacherAvailablity → TeacherAvailability) + update all imports
- P3_15: Document or plan cleanup of duplicate columns in `tt_constraint_types` and `tt_constraints`
- P3_16: Add `@deprecated` annotation to 6 legacy models (Day, Period, TimingProfile, etc.)
- P3_17: Add `created_by`, `deleted_at`, `is_active` to all DDL tables missing them (DDL-only)
- Prerequisites: All P0, P1, and P2 tasks complete

---

## MASTER INDEX FILE (00_MASTER_TASK_INDEX.md)

Generate this file as a table of all tasks:

```markdown
# SmartTimetable DDL Gap Fix — Task Index
**Generated:** {DATE}
**Source:** Gap Analysis at `5-Work-In-Progress/8-Smart_Timetable/1-Timetable_Gap_Analysis/`
**Total Tasks:** 17 (5 P0 + 3 P1 + 5 P2 + 4 P3)
**Total Estimated Effort:** ~10-13 hours
**Assigned To:** Tarun (code tasks P0-P1), Brijesh (DDL tasks P2-P3)

## Execution Order

> **RULE:** Complete ALL P0 tasks before starting ANY P1 task.
> Complete ALL P1 tasks before starting ANY P2 task.
> Complete ALL P2 tasks before starting ANY P3 task.
> Within a priority level, tasks can be done in any order unless prerequisites say otherwise.

## Task Index

| # | File | Issue ID(s) | Priority | Est. | Owner | Prerequisites | Status |
|---|------|------------|----------|------|-------|---------------|--------|
| 01 | P0_01_... | BUG-DDL-001 | P0 | 5m | Tarun | None | ⬜ |
| 02 | P0_02_... | BUG-DDL-002 | P0 | 5m | Tarun | None | ⬜ |
| ... | ... | ... | ... | ... | ... | ... | ⬜ |
| 17 | P3_17_... | DDL standard cols | P3 | 2h | Brijesh | All P2 | ⬜ |

## Sprint Plan

| Sprint | Tasks | Duration | Focus |
|--------|-------|----------|-------|
| Sprint 1 | #01-#08 | 1 day | P0 crash fixes + P1 silent bugs |
| Sprint 2 | #09-#13 | 1-2 days | P2 DDL reconciliation |
| Sprint 3 | #14-#17 | 0.5 day | P3 cleanup & backlog |

## Dependency Graph

\```
P0_01 (ClassWorkingDay) ──┐
P0_02 (AvailabilityLog) ──┤
P0_03 (ScopeForClass)   ──┼──► P1_06 (Fillable cleanup) ──► P2_09 (DDL names)
P0_04 (10 DDL migrations)─┤                                  P2_10 (DDL columns)
P0_05 (12 phantom migr.) ─┘──► P1_07 (Dead aliases)     ──► P2_11 (DDL add cols)
                               P1_08 (Annotate phantoms) ──► P2_12 (DDL add tables)
                                                              P2_13 (DDL phantoms)
                                                              ──► P3_14-17 (Cleanup)
\```
```

---

## RULES

1. **Read ALL 6 gap analysis files COMPLETELY** before generating any prompt — every detail matters
2. **Each prompt must be SELF-CONTAINED** — a developer should execute it without reading other prompts
3. **Use EXACT file paths** from the gap analysis (model names, table names, column names)
4. **Include ALL affected files** in PRE-READ — don't assume Claude will know what to read
5. **Be specific in Steps** — "Change `$table = 'tt_class_working_day_jnt'` to `$table = 'tt_class_working_days'`" not "Fix the table name"
6. **Cross-reference issue IDs** — every prompt must reference the BUG-DDL-XXX IDs from the gap analysis
7. **Prerequisites must be accurate** — if a task depends on another being complete, say so explicitly
8. **Estimates from the corrected action plan** — use estimates from `06_Corrected_Action_Plan.md`
9. **DO NOT generate migration code** in the prompts — the prompts tell Claude what to do, Claude generates the code when the prompt is executed. But DO specify exact column names, types, and constraints.
10. **Keep each prompt under 150 lines** — concise and actionable
11. **Additive-only migration policy** — never drop columns or rename tables in migrations (Decision D17)
12. **Plural table names** — all new migrations must use plural names matching model `$table` values
