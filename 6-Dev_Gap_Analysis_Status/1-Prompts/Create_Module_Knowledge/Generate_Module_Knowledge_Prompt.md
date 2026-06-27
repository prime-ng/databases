# Prompt: Generate Module Knowledge for All Pending Modules
# =========================================================
# PURPOSE  : Automate the "seed module knowledge" process for every module
#            that does not yet have "Done" in the Module Knowledge column.
# SAVE AT  : 6-Dev_Gap_Analysis_Status/1-Prompts/Create_Module_Knowledge/Generate_Module_Knowledge_Prompt.md
# USAGE    : Paste this entire prompt into Claude Code (with Business Analyst role active).
#            Adjust PARALLEL_LIMIT before running.
# =========================================================

---

## ⚙️ Configuration

```
PARALLEL_LIMIT = 2
```

> **PARALLEL_LIMIT** controls how many modules are seeded at the same time.
> Set to `1` for sequential (safe, easier to debug).
> Set to `2` or `3` for faster parallel processing.
> Do NOT exceed `3` — each seed operation reads 2 large files and writes 1 large file;
> running too many in parallel risks context overload and file write conflicts.

---

## 📋 Instructions for Claude

You are acting as **Business Analyst**. Read `AI_Brain/agents/business-analyst.md` and adopt that role before proceeding.

Follow these steps exactly:

---

### STEP 0 — Read the Status File

Read the file at:
```
/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/6-Dev_Gap_Analysis_Status/1-Prompts/0-FRD_Audit_Status.md
```

Extract every row from the table. For each row, note:
- `MODULE_NAME` (column 1)
- `MODULE_CODE` (column 2)
- `Module Knowledge` status (column 4)

Build a list of **pending modules** = rows where `Module Knowledge` column is blank or not `Done`.

---

### STEP 1 — Verify Source Files Exist

Before seeding any module, verify that the required source files exist for that module. For each pending module, check:

1. **V2 Requirement Doc** at:
   ```
   4-Requirement_Module_wise/4-Initial_Requirements/V2/{MODULE_CODE}_{MODULE_NAME}_Requirement.md
   ```
   Example: `V2/CAF_Cafeteria_Requirement.md`

2. **Consolidated DDL** at:
   ```
   2-DDL_Tenant_Consolidated/{MODULE_NAME}_ddl_v*.sql
   ```
   OR any matching file for that module in the `2-DDL_Tenant_Consolidated/` folder.

If either file is missing for a module, **skip that module**, log it as `⚠️ SKIPPED — source files not found`, and continue to the next module.

---

### STEP 2 — Seed Module Knowledge (Respecting PARALLEL_LIMIT)

Process the pending modules in batches of `PARALLEL_LIMIT`.

**For each module in the batch, execute:**

```
seed module knowledge for {MODULE_NAME}
```

This follows the standard BA seeding process:
1. Read the V2 requirement doc (`4-Requirement_Module_wise/4-Initial_Requirements/V2/`)
2. Read the consolidated DDL (`2-DDL_Tenant_Consolidated/`)
3. Create `AI_Brain/module-knowledge/{MODULE_CODE}_{MODULE_NAME}.md`

When running multiple modules in parallel (PARALLEL_LIMIT > 1), initiate all modules in the batch simultaneously, then wait for all to complete before proceeding.

---

### STEP 3 — Mark Done in Status File

After each module's knowledge file is successfully created, update the status file:

File: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/6-Dev_Gap_Analysis_Status/1-Prompts/0-FRD_Audit_Status.md`

Change the `Module Knowledge` column for that module from blank → `Done`.

**Important:** Update the status file immediately after each module completes — do not batch the status updates. If Claude is interrupted mid-run, the status file reflects exactly what was completed.

---

### STEP 4 — Repeat Until All Modules Are Done

After completing a batch:
- Check the updated status file
- If any modules still show blank `Module Knowledge`, go back to STEP 2 with the next batch
- If all modules show `Done` or `⚠️ SKIPPED`, the process is complete

---

### STEP 5 — Final Summary

Once all modules are processed, output a summary table:

```
| MODULE_NAME | MODULE_CODE | Result             |
|-------------|-------------|-------------------|
| Accounting  | ACC         | ✅ Done           |
| Admission   | ADM         | ✅ Done           |
| EventEngine | EVT         | ⚠️ SKIPPED        |
| ...         | ...         | ...               |
```

List count of: `✅ Completed`, `⏭️ Already Done (skipped)`, `⚠️ Skipped (no source files)`.

---

## 📌 Reference — Modules Pending as of 2026-06-27

Based on the current status file, these modules do NOT yet have Module Knowledge (Done):

```
Accounting          (ACC)
Admission Mgmt.     (ADM)
BehaviouralAssessment (BHA)
Billing             (BIL)
Certificate         (CRT)
CommonChat          (COM)
Dashboard           (DSH)
Documentation       (DOC)
EventEngine         (EVT)
Feedback            (FBK)
GlobalMaster        (GLB)
Hpc                 (HPC)
HrStaff             (HRS)
LmsExam             (EXM)
LmsHomework         (HMW)
LmsQuests           (QST)
LmsQuiz             (QUZ)
MarksheetGeneration (MSH)
Notification        (NTF)
ParentPortal        (PPT)
Payment             (PAY)
Prime               (PRM)
PTM                 (PTM)
QuestionBank        (QNS)
Recommendation      (REC)
Scheduler           (SDL)
SchoolSetup_ClassSetup    (SCC)
SchoolSetup_CoreSetup     (SCO)
SchoolSetup_EmployeeSetup (SCE)
SchoolSetup_InfraSetup    (SCI)
SmartTimetable      (STT)
StandardTimetable   (TTS)
StudentFee          (FIN)
StudentPortal       (STP)
StudentProfile      (STD)
Syllabus            (SLB)
SyllabusBooks       (SLK)
SystemConfig        (SYS)
Template            (TMP)
TimetableFoundation (TTF)
Transport           (TPT)
Vendor              (VND)
```

> This list is for reference only. Always read the actual status file at runtime —
> it may have been updated since this prompt was written.

---

## ⚠️ Rules & Guardrails

1. **Never skip the source file check (STEP 1).** Some modules may not have V2 requirement docs or DDLs yet. Attempting to seed without sources produces an empty or wrong knowledge file.

2. **Always update the status file immediately after each successful seed** — before moving to the next module. This makes the process resumable if interrupted.

3. **If a knowledge file already exists** at `AI_Brain/module-knowledge/{CODE}_{MODULE}.md` but the status column is blank, re-read both source files and overwrite the knowledge file (the existing file may be outdated or from an earlier format).

4. **Do not create documentation files or READMEs** as a byproduct of this process. The only output files are:
   - The knowledge files in `AI_Brain/module-knowledge/`
   - Status updates in `0-FRD_Audit_Status.md`

5. **Respect the PARALLEL_LIMIT.** Do not run more modules simultaneously than this value.

6. **File naming convention** for knowledge files:
   ```
   AI_Brain/module-knowledge/{MODULE_CODE}_{MODULE_NAME}.md
   ```
   Use the exact `MODULE_NAME` from the status file (no spaces — convert spaces to underscores if needed). Examples: `ACC_Accounting.md`, `STD_StudentProfile.md`, `SCC_SchoolSetup_ClassSetup.md`.

---

## 🚀 Quick Start

To run this prompt:

1. Open Claude Code in the `old_db` repository
2. Type: `act as Business Analyst`
3. Paste this entire prompt OR type:
   ```
   Run the prompt at: 6-Dev_Gap_Analysis_Status/1-Prompts/Create_Module_Knowledge/Generate_Module_Knowledge_Prompt.md
   ```

To adjust parallelism, edit `PARALLEL_LIMIT` at the top of this file before running.

---

*Prompt Version: 1.0 | Created: 2026-06-27 | Author: Business Analyst Agent*
