# PROMPT: Generate Individual Task Prompts for ALL HPC Gap Analysis Items

## Mode
Standard mode. This is a **PROMPT GENERATION** task — read source, generate prompt files. **No code changes.**

---

## CONFIGURATION
```
AI_BRAIN       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain
SOURCE_DIR     = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/5-Work-In-Progress/8-Smart_Timetable/1-Timetable_Gap_Analysis
OUTPUT_DIR     = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/5-Work-In-Progress/8-Smart_Timetable/Claude_Tasks/Task-2
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai
MODULE_PATH    = {LARAVEL_REPO}/Modules/SmartTimetable
ROUTES_FILE    = {LARAVEL_REPO}/routes/tenant.php
DATE           = 2026-03-17
```

---

## TASK

Read the SmartTimetable Complete Gap Analysis files from (`{SOURCE_DIR}`) and generate **one prompt file per task** for all 37 action items identified in Sections 9-10 of the gap analysis. Each prompt must be a self-contained, ready-to-execute Claude prompt that a developer can paste into Claude to complete that specific task.

---

## PRE-READ (Mandatory)

1. `{SOURCE_FILE}` — Full gap analysis (761 lines). Read ALL of it.
2. `{AI_BRAIN}/config/paths.md` — Path variables
3. `{AI_BRAIN}/claude-config/rules/hpc.md` — HPC module rules and current state
4. `{AI_BRAIN}/memory/known-bugs-and-roadmap.md` — HPC issues section (lines 205-251)

---

## OUTPUT STRUCTURE

Create the folder `{OUTPUT_DIR}/` and generate files using this naming convention:

```
{OUTPUT_DIR}/
├── P0_01_SEC-HPC-001_Auth_HpcController.md
├── P0_02_SEC-HPC-002_Fix_FormRequest_Authorize.md
├── P0_03_BUG-HPC-001_Missing_Imports_TenantPHP.md
├── P0_04_BUG-HPC-003_Garbled_Permission_String.md
├── P0_05_SEC-HPC-003_EnsureTenantHasModule.md
├── P0_06_BUG-HPC-009_Trash_Route_Shadowing.md
├── P0_07_BUG-HPC-004_CrossLayer_AcademicSession.md
├── P0_08_FormStore_MassAssignment_Fix.md
├── P1_09_SEC-HPC-004_Remove_Module_Routes_Bypass.md
├── P1_10_BUG-HPC-005_Dead_Routes.md
├── P1_11_BUG-HPC-006_Case_Sensitivity_Linux.md
├── P1_12_BUG-HPC-007_Wrong_Student_Import.md
├── P1_13_BUG-HPC-008_Orphan_Import.md
├── P1_14_BUG-HPC-011_Created_By_Fillable.md
├── P1_15_BUG-HPC-012_CrossLayer_Dropdown.md
├── P1_16_BUG-HPC-013_ZIP_Cleanup.md
├── P1_17_PERF-HPC-002_Shared_Index_Query.md
├── P1_18_Permission_Typo_TopicEquivalency.md
├── P1_19_Missing_15_Migrations.md
├── P2_20_GAP4_Role_Based_Section_Locking.md
├── P2_21_GAP5_Approval_Workflow.md
├── P2_22_GAP7_Eval_To_Report_AutoFeed.md
├── P2_23_GAP8_Attendance_Data_Complete.md
├── P2_24_PERF-HPC-001_Batch_PDF_Generation.md
├── P2_25_God_Controller_Refactor.md
├── P2_26_Job_Refactor_BuildPdf_To_Service.md
├── P3_27_GAP1_Student_Self_Service_Portal.md
├── P3_28_GAP2_Parent_Data_Collection.md
├── P3_29_GAP3_Peer_Assessment_Workflow.md
├── P3_30_GAP6_LMS_Exam_AutoFeed.md
├── P3_31_SC07_Attendance_Manager_Screen.md
├── P3_32_SC09_Activity_Assessment_Screen.md
├── P3_33_SC14_Student_Goals_Aspirations.md
├── P3_34_SC15-17_Parent_Portal_Screens.md
├── P3_35_SC20_Credit_Calculator.md
├── P3_36_Test_Suite_Basic_Coverage.md
├── P3_37_Cosmetic_Fixes_BUG010_BUG014.md
└── 00_MASTER_TASK_INDEX.md
```

---

## PROMPT TEMPLATE (use for EVERY task prompt)

Each generated prompt file MUST follow this exact structure:

```markdown
# PROMPT: [Task Title] — HPC Module
**Task ID:** [P0_01 / P1_09 / P2_20 / P3_27 etc.]
**Issue IDs:** [SEC-HPC-001 / BUG-HPC-003 / GAP-4 / SC-07 etc.]
**Priority:** [P0-Critical / P1-High / P2-Medium / P3-Low]
**Estimated Effort:** [from gap analysis]
**Prerequisites:** [list any tasks that MUST be done first, by Task ID]

---

## CONFIGURATION
\```
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai
MODULE_PATH    = {LARAVEL_REPO}/Modules/Hpc
ROUTES_FILE    = {LARAVEL_REPO}/routes/tenant.php
\```

---

## CONTEXT

[2-5 sentences explaining WHAT is wrong, WHY it matters, and WHAT the fix should achieve.
Pull exact details from the gap analysis — file names, line numbers, method names, current vs expected behavior.]

---

## PRE-READ (Mandatory)

[List the specific files Claude must read BEFORE making any changes. Be precise — include:
- The exact controller/model/route file(s) that need modification
- Any related files for context (e.g., the FormRequest if fixing authorization)
- NOT the entire codebase — only files relevant to THIS task]

---

## STEPS

[Numbered step-by-step instructions. Each step should be:
1. Specific — name the file, method, line (when known from gap analysis)
2. Actionable — "Add", "Remove", "Replace", "Create"
3. Verifiable — "Confirm that X now returns Y"

For P0/P1 (bug fixes): Steps should be precise surgical fixes.
For P2 (workflows): Steps should include design decisions + implementation.
For P3 (new features): Steps should include schema, controller, views, routes.]

---

## ACCEPTANCE CRITERIA

[Bullet list of what "done" looks like. Examples:
- All 15 HpcController methods have Gate::authorize()
- `php artisan route:cache` runs without errors
- Trash routes are accessible at /hpc/{resource}/trash/view
- No cross-layer imports remain in Hpc module]

---

## DO NOT

[List 2-4 things Claude should NOT do for this task. Examples:
- Do NOT refactor unrelated code
- Do NOT change the database schema
- Do NOT modify PDF templates
- Do NOT add new routes beyond what this task requires]
\```

---

## SPECIAL INSTRUCTIONS PER PRIORITY

### P0 Tasks (01-08): Security & Critical Bugs
- These are **surgical fixes** — change as few lines as possible
- Always include the EXACT file path and method name
- Include a "Verify" step (e.g., "Run `php artisan route:cache` to confirm no errors")
- Add prerequisite: "None — this is a P0 task, do it first"
- In CONTEXT section, emphasize the **security risk** if not fixed

### P1 Tasks (09-19): Bug Fixes & Migrations
- These are **focused fixes** — may touch multiple files but within a narrow scope
- For migration tasks (P1_19), generate the migration file contents inline in the prompt
- Include prerequisite P0 tasks where applicable (e.g., P1_09 depends on P0_03)
- For BUG-HPC-011 (18 models), list ALL 18 model file paths in PRE-READ

### P2 Tasks (20-26): Workflows & Refactoring
- These require **design decisions** — include a "Design" section before Steps
- Include acceptance criteria for both the happy path and edge cases
- For refactoring tasks (P2_25, P2_26), include before/after code structure
- Add prerequisite: "All P0 and P1 tasks must be complete"

### P3 Tasks (27-37): New Features & Screens
- These require **full implementation** — schema + controller + views + routes
- Include a "Schema Changes" subsection listing any new tables/columns
- Include a "Routes" subsection listing new routes to add
- Include a "Views" subsection listing new blade files to create
- Reference the blueprint screen specs (SC-XX) from the gap analysis
- Add prerequisite: "All P0, P1, and P2 tasks must be complete"

---

## MASTER INDEX FILE (00_MASTER_TASK_INDEX.md)

Generate this file as a table of all 37 tasks with:

```markdown
# HPC Module — Task Prompt Index
**Generated:** 2026-03-17
**Source:** HPC_Gap_Analysis_Complete.md (2026-03-16)
**Total Tasks:** 37 (8 P0 + 11 P1 + 7 P2 + 11 P3)
**Total Estimated Effort:** ~13 developer-weeks

## Execution Order

> **RULE:** Complete ALL P0 tasks before starting ANY P1 task.
> Complete ALL P1 tasks before starting ANY P2 task.
> Complete ALL P2 tasks before starting ANY P3 task.
> Within a priority level, tasks can be done in any order unless prerequisites say otherwise.

## Task Index

| # | File | Issue ID(s) | Priority | Est. | Prerequisites | Status |
|---|------|------------|----------|------|---------------|--------|
| 01 | P0_01_SEC-HPC-001_Auth_HpcController.md | SEC-HPC-001 | P0 | 2h | None | ⬜ |
| 02 | P0_02_SEC-HPC-002_Fix_FormRequest_Authorize.md | SEC-HPC-002 | P0 | 1h | None | ⬜ |
| ... | ... | ... | ... | ... | ... | ⬜ |
| 37 | P3_37_Cosmetic_Fixes_BUG010_BUG014.md | BUG-HPC-010, BUG-HPC-014 | P3 | 1d | All P2 | ⬜ |

## Sprint Plan

| Sprint | Tasks | Duration | Focus |
|--------|-------|----------|-------|
| Sprint 1 | #01-#19 | ~2 days | P0 security + P1 bug fixes |
| Sprint 2 | #20-#26 | ~3 weeks | P2 workflows & refactoring |
| Sprint 3 | #27-#30 | ~3 weeks | P3 multi-actor portals |
| Sprint 4 | #31-#37 | ~3 weeks | P3 screens, integration, tests |
```

---

## RULES

1. **Read the gap analysis COMPLETELY** before generating any prompt — every detail matters
2. **Each prompt must be SELF-CONTAINED** — a developer should be able to execute it without reading other prompts
3. **Use EXACT file paths** from the gap analysis (controller names, model names, line numbers when available)
4. **Include ALL affected files** in PRE-READ — don't assume Claude will know what to read
5. **Be specific in Steps** — "Add `Gate::authorize('tenant.hpc.view')` to the `show()` method" not "Add authorization"
6. **Cross-reference issue IDs** — every prompt must reference the SEC/BUG/PERF/GAP IDs from the gap analysis
7. **Prerequisites must be accurate** — if Task 20 depends on Task 01 being complete, say so
8. **Estimates from gap analysis** — use the exact estimates from Section 10 of the gap analysis
9. **DO NOT generate code** in the prompts — the prompts tell Claude what to do, Claude generates the code when the prompt is executed
10. **Keep each prompt under 150 lines** — concise and actionable, not a novel
