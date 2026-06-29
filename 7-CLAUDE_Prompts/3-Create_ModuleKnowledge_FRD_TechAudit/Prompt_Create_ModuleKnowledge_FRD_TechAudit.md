# PROMPT — Per-Module Pipeline: Module Knowledge → Complete FRD → Complete Technical Audit (ALL MODULES)

> Paste/run this entire prompt in Claude Code from the Prime-AI workspace. It processes **every module**
> in `module_list.md`, one at a time, running 3 phases per module in the exact sequence below, fully
> autonomously, and is **safely resumable** (re-running skips already-completed work).

---

## OBJECTIVE
For each module listed in `module_list.md`, run **Phase 1 → Phase 2 → Phase 3 in that exact order**, then
move to the next module, until the last module. Each phase is **idempotent**: it does the work only if the
expected output does not already exist.

---

## OPERATING MODE (read first — non-negotiable)

1. **Fully autonomous.** Do **not** stop, summarise-and-ask, or wait for any confirmation between phases or
   between modules. Process every module from the first row to the last in one continuous run.
2. **Read anywhere; write almost nowhere.** You may *read* any file needed for grounding. You may *create or
   modify* files **ONLY** inside the four Allowed Write Folders listed below. **Any write, move, rename, or
   delete outside those four folders is forbidden** — this includes `5-Requirement_Conditions/`, 
   `5-Project_Planning/`, `6-Dev_Gap_Analysis_Status/`, config, and all application code.
3. **Any Change (write, move, rename, or delete)** in application code is strictly prohibited.
4. **Resumable & quota-safe.** The *existence of the output files is the only progress state* — there is no
   external progress log (writing one is forbidden). If the Claude usage/quota limit is reached, finish the
   file currently being written if possible, then stop. **When the quota resets, simply run this prompt
   again** — every completed module's outputs already exist, so its phases are skipped and work resumes at
   the first incomplete module. Do not abandon the run; resume until all modules are complete.
5. **No questions.** If something is ambiguous, choose the most reasonable interpretation consistent with
   these rules and continue. Never block waiting for the user.
6. You need to update AI_Brain files to enhance it's knowledge incluyding `known-issues.md`, `state/progress.md`,
   `state/decisions.md`.

---

## ALLOWED WRITE FOLDERS (the ONLY places you may create/modify files)

```
1.  /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/module-knowledge
2.  /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/0-FRD_Documents
3.  /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/3-Audit_Reports/V1_Jun-2026
4.  /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/9-Working_tmp/2-Create_ModuleKnowledge_FRD_TechAudit
```

---

## WRITE-RESTRICTION OVERRIDE (applies to every agent/mode invoked below)

The Business Analyst and Technical Auditor roles normally produce extra side-deliverables. **For this run,
suppress all of them.** Each phase may write ONLY the files named in its step, all of which fall inside the
four Allowed Write Folders:

- **Module-knowledge seed/update** → write ONLY `…/module-knowledge/{MODULE_CODE}_{MODULE_NAME}.md`.
  Do **not** create a "BA Module Summary" or anything outside folder 1.
- **Complete analysis (BA)** → write ONLY, in folder 2:
  `{MODULE_CODE}_FRD_Complete_{YYYY-MM-DD}.md` (the consolidated complete file, all artifacts as `## Section`s),
  **plus** the module-knowledge update in folder 1.
  Do **not** write a Requirement-Conditions file, Sprint-Tasks file, analysis-pack folder, or anything else.
- **Complete audit (Technical Auditor — Mode X)** → write ONLY, in folder 3:
  `{MODULE_NAME}_Complete_Audit_{YYYY-MM-DD}.md`, **plus** the module-knowledge update in folder 1.
  **Do append** to `known-issues.md`, `progress.md`, or `decisions.md`. Assign issue codes **inside the
  report**".

`{YYYY-MM-DD}` = the date the file is generated (today, at run time).

---

## IDENTIFIER SOURCE

Read every module row from:
```
/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/0-Prime_Ai_Detail/module_list.md
```
From each row collect **MODULE_NAME**, **MODULE_CODE**, **MODULE_PREFIX**. Process rows **top to bottom**.

> **Filename convention (resolved):** the module-knowledge file is `{MODULE_CODE}_{MODULE_NAME}.md`
> (e.g. `CMP_Complaint.md`, `HST_Hostel.md`, `TPT_Transport.md`) — this corrects the literal
> `{MODULE_CODE}_{MODULE_CODE}.md` in the original spec, which does not match the files on disk.

---

## PER-MODULE ALGORITHM (run for EVERY module row, in this exact order)

### PHASE 1 — Module Knowledge
1. Check whether a file matching `{MODULE_CODE}_{MODULE_NAME}.md` exists in
   `…/AI_Brain/module-knowledge/` (a `{MODULE_CODE}_*.md` match is sufficient).
2. **If it exists** → run, as the Business Analyst: **`update module knowledge for {MODULE_NAME}`**
   (verify every count/status against the live tree before writing — snapshots are often stale).
   **Else** → run, as the Business Analyst: **`seed module knowledge for {MODULE_NAME}`**.
3. Write ONLY the module-knowledge file (folder 1).

### PHASE 2 — Complete FRD
1. Check whether a file matching `{MODULE_CODE}_FRD_Complete_{YYYY-MM-DD}.md` (for today's date only) exists in
   `…/4-Requirement_Module_wise/0-FRD_Documents/`.
2. **If it exists** → do nothing (skip).
   **Else** → run: **`use pa-business-analyst` → "Complete analysis of {MODULE_NAME} Module"**
   (Complete Analysis Pack Mode). This generates the FRD first (if absent) and then the single
   consolidated `{MODULE_CODE}_FRD_Complete_{YYYY-MM-DD}.md`. Write ONLY into folders 1 & 2 per the override.

### PHASE 3 — Complete Technical Audit
1. Check whether a file matching `{MODULE_NAME}_Complete_Audit_{YYYY-MM-DD}.md` (for today's date only) exists in
   `…/3-Audit_Reports/V1_Jun-2026/`.
2. **If it exists** → do nothing (skip).
   **Else** → run: **`use pa-technical-auditor` → "Complete audit of {MODULE_NAME} Module"** (Mode X:
   A+B+C+G+scoped-D, one unified report). Use the Phase-2 FRD-Complete as the B/C baseline. Save the report
   as `…/3-Audit_Reports/V1_Jun-2026/{MODULE_NAME}_Complete_Audit_{YYYY-MM-DD}.md`. Write ONLY into folders 1 & 3 per the override.

### THEN
Move to the **next row** of `module_list.md` and repeat Phase 1 → 2 → 3.
**Continue until the last module** in the list.

---

## REQUIRED DISCIPLINE INSIDE EACH AGENT RUN
- **STEP 1 reading discipline (both agents):** module-knowledge files are HINTS — verify every count,
  status, and gap against live code/DDL/migrations before writing. Three-way reconcile DDL ↔ migration ↔
  model for any schema claim.
- **FRD is the single source of truth:** the Complete file and the audit's B/C pass reuse the FRD's
  `REQ-/BR-/RPT-` IDs — never renumber.
- **Business-language discipline** in the FRD/Complete sections; technical register only in the audit and
  the explicitly-technical sections (data dictionary technical view, dependency map).

---

## COMPLETION
When the last module's Phase 3 is done (or skipped), **print a summary to chat & Save into File** Write it as 
(old_db/9-Working_tmp/2-Create_ModuleKnowledge_FRD_TechAudit/Summary_ModKnow_FRD_TechAud_{YYYY-MM-DD}):

```
| Module (CODE) | Phase 1 (knowledge) | Phase 2 (FRD-Complete) | Phase 3 (Audit) |
|---------------|---------------------|------------------------|-----------------|
| …             | seeded / updated    | created / skipped      | created / skipped |
```
Plus: total modules processed, how many of each action, and any module that errored (with the reason) so it
can be retried on the next run.

---

## RESUME CHECKLIST (when re-running after a quota reset or interruption)
1. Re-run this exact prompt — no edits needed.
2. For each module, the three existence checks skip whatever is already done.
3. The first module with a missing output is where work resumes.
4. Stop only when every module has all three outputs (or has been reported as errored).
