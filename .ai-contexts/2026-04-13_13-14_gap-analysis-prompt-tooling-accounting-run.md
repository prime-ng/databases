# Context: Gap Analysis Prompt Tooling Setup & Accounting Module First Run
# Saved: 2026-04-13 13:14
# Session Duration: ~1 hour
# Project: PrimeAI

---

## 1. SESSION OBJECTIVE
Design a reusable, configurable gap analysis prompt that any db-analyzer agent can execute to compare a module's DDL schema against its code (migrations, models, form requests, controllers, views) and produce a structured discrepancy report saved to a file.

---

## 2. SUMMARY OF WORK DONE
- Discussed which agent to use for schema-model alignment → `db-analyzer` with `model: "sonnet"`
- Created initial gap analysis prompt template at `2-Gap_Analysis/module_gap_analysis_prompt.md`
- User pointed to file saved in `2-Development_Analysis/` folder (user has both folders — save new ones to `2-Development_Analysis/`)
- Enhanced the prompt into a full 12-section structured output format with:
  - 6 CONFIGURATION variables (including OUTPUT_FILE)
  - 8 analysis steps (DDL Inventory, Migration, Model, FormRequest, Controller, View, Summary, Fix Order)
  - Full Markdown report schema with specific table structures per section
  - Agent instruction to use Write tool to save the report automatically
- Saved enhanced prompt as `development_analysis_prompt.md`
- User updated OUTPUT_FILE path in CONFIGURATION to point to canonical reports folder
- Created `Reports/` subfolder under `2-Development_Analysis/` (later discovered canonical output is `3-Project_Planning/...`)
- Ran the db-analyzer agent (Sonnet) for the **Accounting module** — analysis completed successfully
- Report auto-saved by agent to the configured OUTPUT_FILE
- Saved auto-memory entry to Claude memory system (secondary, not the primary context save)

---

## 3. FILES TOUCHED

### Created:
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/7-Work_with_CLAUDE/2-Gap_Analysis/module_gap_analysis_prompt.md` — Initial simpler version of the gap analysis prompt (superseded)
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/7-Work_with_CLAUDE/2-Development_Analysis/development_analysis_prompt.md` — Enhanced, full 12-section gap analysis prompt (CANONICAL — use this going forward)
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/7-Work_with_CLAUDE/2-Development_Analysis/Reports/Accounting_gap_report.md` — Accounting gap report (initial save location, may have been moved — see Section 10)
- `/Users/bkwork/.claude/projects/-Users-bkwork-Herd-prime-ai/memory/reference_gap_analysis_tooling.md` — Claude auto-memory entry for the tooling

### Modified:
- `/Users/bkwork/.claude/projects/-Users-bkwork-Herd-prime-ai/memory/MEMORY.md` — Added pointer to gap analysis tooling memory

### Discussed/Reviewed (not modified):
- `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/40-Accounting/DDL/ACC_DDL_v2.sql` — Source DDL for Accounting analysis
- `/Users/bkwork/Herd/prime_ai/Modules/Accounting/` — Full module code reviewed by agent

---

## 4. KEY DECISIONS & RATIONALE

- **Decision:** Use `db-analyzer` agent with `model: "sonnet"` for gap analysis
  **Why:** Schema-model comparison is a structured pattern-matching task; Sonnet is fast, cost-effective, and sufficient. Opus is overkill.
  **Alternatives Considered:** Running analysis manually in main context

- **Decision:** Add OUTPUT_FILE as a CONFIGURATION variable and instruct agent to use Write tool to save
  **Why:** User noted the original prompt had no output persistence — the report would only exist in conversation context and be lost
  **Alternatives Considered:** User manually copy-pasting from conversation

- **Decision:** Canonical output path for gap reports is `3-Project_Planning/4-Development_Analysis/2-Modules_Wise_Analysis/`
  **Why:** User updated the CONFIGURATION block in `development_analysis_prompt.md` to point here — this is the authoritative location
  **Alternatives Considered:** `7-Work_with_CLAUDE/2-Development_Analysis/Reports/` (initial, now secondary)

---

## 5. TECHNICAL DETAILS & PATTERNS

### Gap Analysis Agent Invocation Pattern
```
Agent({
  description: "{Module} module gap analysis",
  subagent_type: "db-analyzer",
  model: "sonnet",
  prompt: "[full prompt from development_analysis_prompt.md with values substituted]"
})
```

### Report Severity Scale
- **P0** — crash/data-loss risk (missing NOT NULL col in migration, no model, authorize() always true)
- **P1** — functional bug (column silently dropped, wrong cast, race condition)
- **P2** — code quality (missing optional cast, phantom field, cosmetic index mismatch)

### 8 Analysis Sections in Each Report
1. DDL Table Inventory
2. Migration vs DDL
3. Model vs DDL ($fillable, $casts, relationships, $hidden)
4. Form Request vs DDL (validation gaps, phantom fields, authorize())
5. Controller vs DDL (unhandled required cols, mass-assignment, missing auth)
6. View vs DDL (missing inputs, phantom POST fields)
7. Overall Summary (P0/P1/P2 count table by layer + zero-coverage table list)
8. Recommended Fix Order (severity-ordered, with file:line per item)

---

## 6. DATABASE CHANGES
None — this session was about tooling setup and analysis, not code changes.

---

## 7. PROBLEMS ENCOUNTERED & SOLUTIONS

- **Problem:** Initial prompt had no output file saving — report existed only in conversation
  **Cause:** OUTPUT_FILE variable and Write tool instruction were not included
  **Solution:** Enhanced `development_analysis_prompt.md` to add OUTPUT_FILE variable and explicit Write tool instruction at end of prompt

- **Problem:** Context was saved to wrong location (Claude auto-memory instead of `.ai-contexts`)
  **Cause:** Did not read `Save_Context.md` before executing the save
  **Solution:** Read the prompt file and executed proper save procedure to `.ai-contexts`

---

## 8. CURRENT STATE OF WORK

### Completed:
- Gap analysis prompt tooling fully designed and saved
- Accounting module gap analysis completed and report saved

### In Progress:
- N/A

### Not Yet Started:
- Gap analysis for all other modules (see Section 9 for suggested order)
- Fixing the P0/P1 issues found in Accounting module

---

## 9. OPEN QUESTIONS & TODOS
- [ ] Verify Accounting report landed at canonical path: `3-Project_Planning/4-Development_Analysis/2-Modules_Wise_Analysis/Accounting_gap_report.md`
- [ ] Run gap analysis for remaining modules — suggested priority order: StudentFee, SchoolSetup, SmartTimetable, StudentProfile, HPC, LmsExam
- [ ] Fix Accounting P0: Create migrations for 4 unimplemented event engine tables (`acc_module_events`, `acc_event_voucher_configs`, `acc_event_voucher_line_templates`, `acc_event_processing_log`)
- [ ] Fix Accounting P1: Remove `is_system` from `$fillable` on Ledger, AccountGroup, VoucherType models
- [ ] Fix Accounting P1: Fix claim number race condition in `ExpenseClaimController::store()`
- [ ] Fix Accounting P1: Fix premature success logging in `TallyExportController`
- [ ] Fix Accounting P1: Add proper `authorize()` logic to all 15 FormRequests
- [?] Should the initial `module_gap_analysis_prompt.md` in `2-Gap_Analysis/` be deleted to avoid confusion?

---

## 10. IMPORTANT CONTEXT FOR FUTURE SESSIONS

### Prompt Template Location (CANONICAL)
`/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/7-Work_with_CLAUDE/2-Development_Analysis/development_analysis_prompt.md`

### Report Output Location (CANONICAL)
`/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/3-Project_Planning/4-Development_Analysis/2-Modules_Wise_Analysis/{ModuleName}_gap_report.md`
- This was set by the user updating the OUTPUT_FILE config in `development_analysis_prompt.md`

### How to Run Gap Analysis for a New Module
1. Open `development_analysis_prompt.md`
2. Fill in 6 CONFIGURATION values: MODULE_NAME, MODULE_CODE_PATH, DDL_FILE, MIGRATION_PATH, TABLE_PREFIX, OUTPUT_FILE
3. Paste the PROMPT section to Claude Code
4. Use db-analyzer agent + Sonnet model
5. Agent will read all code, run analysis, and Write the report to OUTPUT_FILE automatically

### DDL File Naming Convention
DDL files are at: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/{NN-ModuleName}/DDL/{PREFIX}_DDL_v2.sql`
Always use v2 files. Never use non-v2 or subfolder files.

---

## 11. DEPENDENCIES & CROSS-MODULE REFERENCES
- All gap analysis uses the OLD_REPO DDL files as the source of truth
- Accounting module DDL: `40-Accounting/DDL/ACC_DDL_v2.sql`
- Accounting module code: `/Users/bkwork/Herd/prime_ai/Modules/Accounting/`
- Tenant migrations: `/Users/bkwork/Herd/prime_ai/database/migrations/tenant/`

---

## 12. CONVERSATION HIGHLIGHTS — RAW NOTES

**On agent selection:**
> "For db-analyzer, go with Sonnet. Schema-model comparison is a structured, pattern-matching task. Sonnet handles this reliably and is faster and cheaper. Opus is overkill."

**Accounting module findings summary (from agent):**
```
25 DDL tables checked | 21 aligned | 4 with zero coverage

P0 (4): acc_module_events, acc_event_voucher_configs, acc_event_voucher_line_templates,
        acc_event_processing_log — no migration, no model, no controller, no routes

P1 (6):
  - is_system in $fillable on Ledger, AccountGroup, VoucherType (security: can elevate to system)
  - Ledger missing 'is_system' => 'boolean' cast
  - ExpenseClaimController::store() race condition on claim number (withTrashed()->count() + 1)
  - TallyExportController logs 'Success' before export completes
  - All 15 FormRequests authorize() returns true (no real auth check)
  - is_system absent from FormRequest rules() but present in fillable (injection gap)

P2 (36): Mostly index naming mismatches, minor cast omissions, optional view inputs missing
```

---
*End of Context Save*
