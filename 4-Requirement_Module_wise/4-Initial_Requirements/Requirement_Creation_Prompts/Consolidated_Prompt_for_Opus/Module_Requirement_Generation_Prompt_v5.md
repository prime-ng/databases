# ╔════════════════════════════════════════════════════════════════════════╗
# ║   MODULE REQUIREMENT DOCUMENT — BATCH GENERATION PROMPT v5             ║
# ║   Prime-AI Academic Intelligence Platform                              ║
# ║   46 Modules · 10 Batches · User-Confirmed Execution Flow             ║
# ╚════════════════════════════════════════════════════════════════════════╝
#
# HOW TO USE:
#   1. Set START_BATCH below (default 1 = fresh start, or any number to resume)
#   2. Set APP_BRANCH and DATE
#   3. Copy entire file → Paste into Claude Code (Sonnet 4.6 recommended)
#   4. Claude will run Batch 1, then STOP and ask:
#        "Batch 1 done. Run Batch 2 now? (yes / later)"
#   5. Reply "yes" to continue, or "later" to stop.
#      Next time you resume, set START_BATCH = {next batch number}.
#
# WHAT'S NEW in v5 (vs v4):
#   - 46 modules split into 10 logical batches (~4-5 modules each)
#   - PAUSE after every batch → asks user before running next batch
#   - START_BATCH variable → resume from any batch without restarting
#   - Batch progress saved to {OUTPUT_DIR}/_batch_progress.md after each batch
#   - Batch Summary printed after each batch (files written, time estimate)
#   - AI Brain loaded ONCE at start; retained for the entire session
#   - All output, quality rules, and document template identical to v4
# ═════════════════════════════════════════════════════════════════════════

---

## ▶ SESSION VARIABLES — CHANGE THESE BEFORE RUNNING

```
APP_BRANCH     = Brijesh
DATE           = 2026-03-26
START_BATCH    = 1
```

> **START_BATCH:** Set to 1 for a fresh start.
> To resume after a pause, set this to the batch number printed in the last
> "BATCH COMPLETE" message. Example: if Batch 3 was the last completed,
> set START_BATCH = 4.

---

## ▶ BATCH DEFINITIONS (10 Batches · 46 Modules + 3 Summary Files)

> Claude will process ONLY batches numbered ≥ START_BATCH.
> Batches are ordered to process related modules together and
> heavier (code-heavy) modules early when context is freshest.

---

### BATCH 1 — Prime / Global Core  (5 modules)
> These are the foundational SaaS and global-config modules. No tenant code.

| Seq | # | MODULE_NAME | MODULE_CODE | MODULE_TYPE | MODE |
|-----|---|-------------|-------------|-------------|------|
| 1 | 14 | Prime | PRM | Prime | FULL |
| 2 | 1 | Billing | BIL | Prime | FULL |
| 3 | 5 | GlobalMaster | GLB | Global | FULL |
| 4 | 26 | SystemConfig | SYS | Prime | FULL |
| 5 | 17 | Scheduler | SCH_JOB | Other | FULL |

---

### BATCH 2 — School Foundation & Timetable  (5 modules)
> Core school setup and timetable modules. Heavily interdependent.

| Seq | # | MODULE_NAME | MODULE_CODE | MODULE_TYPE | MODE |
|-----|---|-------------|-------------|-------------|------|
| 6 | 18 | SchoolSetup | SCH | Tenant | FULL |
| 7 | 27 | TimetableFoundation | TTF | Prime | FULL |
| 8 | 19 | SmartTimetable | STT | Tenant | FULL |
| 9 | 20 | StandardTimetable | TTS | Tenant | FULL |
| 10 | 3 | Dashboard | DSH | Other | FULL |

---

### BATCH 3 — Student Core & Syllabus  (5 modules)
> Student information, portal, syllabus, and syllabus books.

| Seq | # | MODULE_NAME | MODULE_CODE | MODULE_TYPE | MODE |
|-----|---|-------------|-------------|-------------|------|
| 11 | 23 | StudentProfile | STD | Tenant | FULL |
| 12 | 22 | StudentPortal | STP | Tenant | FULL |
| 13 | 24 | Syllabus | SLB | Tenant | FULL |
| 14 | 25 | SyllabusBooks | SLK | Prime | FULL |
| 15 | 4 | Documentation | DOC | Other | FULL |

---

### BATCH 4 — LMS Suite  (5 modules)
> Full Learning Management System: homework, quiz, quests, exam, question bank.

| Seq | # | MODULE_NAME | MODULE_CODE | MODULE_TYPE | MODE |
|-----|---|-------------|-------------|-------------|------|
| 16 | 9 | LmsHomework | HMW | Tenant | FULL |
| 17 | 11 | LmsQuiz | QUZ | Tenant | FULL |
| 18 | 10 | LmsQuests | QST | Tenant | FULL |
| 19 | 8 | LmsExam | EXM | Tenant | FULL |
| 20 | 15 | QuestionBank | QNS | Tenant | FULL |

---

### BATCH 5 — Finance, Notification & Communication  (5 modules)
> Fee management, payment, notifications, complaints, recommendations.

| Seq | # | MODULE_NAME | MODULE_CODE | MODULE_TYPE | MODE |
|-----|---|-------------|-------------|-------------|------|
| 21 | 21 | StudentFee | FIN | Tenant | FULL |
| 22 | 13 | Payment | PAY | Tenant | FULL |
| 23 | 12 | Notification | NTF | Tenant | FULL |
| 24 | 2 | Complaint | CMP | Tenant | FULL |
| 25 | 16 | Recommendation | REC | Tenant | FULL |

---

### BATCH 6 — Operational Services  (4 modules)
> Transport, library, vendor, and HPC — operational tenant modules.

| Seq | # | MODULE_NAME | MODULE_CODE | MODULE_TYPE | MODE |
|-----|---|-------------|-------------|-------------|------|
| 26 | 28 | Transport | TPT | Tenant | FULL |
| 27 | 7 | Library | LIB | Tenant | FULL |
| 28 | 29 | Vendor | VND | Tenant | FULL |
| 29 | 6 | Hpc | HPC | Tenant | FULL |

> ━━━ LIST A COMPLETE AFTER BATCH 6 ━━━ LIST B BEGINS WITH BATCH 7 ━━━

---

### BATCH 7 — New: Admissions & Academics  (5 modules)
> Greenfield modules: admissions, attendance, academics, examinations, front office.

| Seq | # | MODULE_NAME | MODULE_CODE | PROPOSED_PREFIX | MODE |
|-----|---|-------------|-------------|-----------------|------|
| 30 | 30 | Admission | ADM | `adm_*` | RBS_ONLY |
| 31 | 32 | Attendance | ATT | `att_*` | RBS_ONLY |
| 32 | 33 | Academics | ACD | `acd_*` | RBS_ONLY |
| 33 | 34 | Examination | EXA | `exa_*` | RBS_ONLY |
| 34 | 31 | FrontOffice | FOF | `fof_*` | RBS_ONLY |

---

### BATCH 8 — New: HR, Finance & Facilities  (5 modules)
> Greenfield modules: HR/staff, accounting, inventory, hostel, communication.

| Seq | # | MODULE_NAME | MODULE_CODE | PROPOSED_PREFIX | MODE |
|-----|---|-------------|-------------|-----------------|------|
| 35 | 38 | HrStaff | HRS | `hrs_*` | RBS_ONLY |
| 36 | 35 | FinanceAccounting | FAC | `fac_*` | RBS_ONLY |
| 37 | 36 | Inventory | INV | `inv_*` | RBS_ONLY |
| 38 | 37 | Hostel | HST | `hst_*` | RBS_ONLY |
| 39 | 39 | Communication | COM | `com_*` | RBS_ONLY |

---

### BATCH 9 — New: Learning Experience, AI & Portals  (5 modules)
> Greenfield modules: LXP, predictive analytics, certificates, parent portal, cafeteria.

| Seq | # | MODULE_NAME | MODULE_CODE | PROPOSED_PREFIX | MODE |
|-----|---|-------------|-------------|-----------------|------|
| 40 | 41 | Lxp | LXP | `lxp_*` | RBS_ONLY |
| 41 | 42 | PredictiveAnalytics | PAN | `pan_*` | RBS_ONLY |
| 42 | 40 | Certificate | CRT | `crt_*` | RBS_ONLY |
| 43 | 46 | ParentPortal | PPT | `ppt_*` | RBS_ONLY |
| 44 | 43 | Cafeteria | CAF | `caf_*` | RBS_ONLY |

---

### BATCH 10 — New: Safety & Facility + Summary Files  (2 modules + 3 summaries)
> Final two greenfield modules, then the three master summary files.

| Seq | # | MODULE_NAME | MODULE_CODE | PROPOSED_PREFIX | MODE |
|-----|---|-------------|-------------|-----------------|------|
| 45 | 44 | VisitorSecurity | VSM | `vsm_*` | RBS_ONLY |
| 46 | 45 | Maintenance | MNT | `mnt_*` | RBS_ONLY |
| — | — | **_00_Master_Requirement_Index** | — | — | SUMMARY |
| — | — | **_01_Cross_Module_Dependencies** | — | — | SUMMARY |
| — | — | **_02_RBS_Coverage_Report** | — | — | SUMMARY |

---

## ▶ RBS-TO-MODULE CROSS-REFERENCE

| RBS Module | RBS Ref | Maps to Code Module(s) |
|-----------|---------|------------------------|
| Tenant & System Management | A | Prime, GlobalMaster, SystemConfig, SchoolSetup |
| User, Roles & Security | B | SchoolSetup (tenant users), Prime (prime users) |
| Admissions & Student Lifecycle | C | StudentProfile (partial) + Admission (NEW) |
| Front Office & Communication | D | Complaint (partial) + FrontOffice (NEW) |
| Student Information System | E | StudentProfile, StudentPortal |
| Attendance Management | F | Attendance (NEW) |
| Advanced Timetable Management | G | SmartTimetable, StandardTimetable, TimetableFoundation |
| Academics Management | H | SchoolSetup (partial), Syllabus, SyllabusBooks + Academics (NEW) |
| Examination & Gradebook | I | Hpc, QuestionBank + Examination (NEW) |
| Fees & Finance Management | J | StudentFee, Payment |
| Finance & Accounting | K | Vendor (partial) + FinanceAccounting (NEW) |
| Inventory & Stock Management | L | Inventory (NEW) |
| Library Management | M | Library |
| Transport Management | N | Transport |
| Hostel Management | O | Hostel (NEW) |
| HR & Staff Management | P | HrStaff (NEW) |
| Communication & Messaging | Q | Notification (partial) + Communication (NEW) |
| Certificates & Identity | R | Certificate (NEW) |
| Learning Management System | S | LmsExam, LmsHomework, LmsQuests, LmsQuiz |
| System Administration | SYS | SystemConfig, Scheduler |
| Learner Experience Platform | T | Lxp (NEW) |
| Predictive Analytics & ML | U | Recommendation (partial) + PredictiveAnalytics (NEW) |
| SaaS Billing & Subscription | V | Billing |
| Cafeteria & Mess | W | Cafeteria (NEW) |
| Visitor & Security | X | VisitorSecurity (NEW) |
| Maintenance & Facility | Y | Maintenance (NEW) |
| Parent Portal & Mobile App | Z | StudentPortal (partial) + ParentPortal (NEW) |

---

## ▶ CONFIGURATION

### Step 0 — Load Paths
Read `/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/config/paths.md`
Variables from `paths.md` take precedence over the defaults below.

### Default Path Variables
```
DB_REPO         = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase
OLD_REPO        = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases
AI_BRAIN        = {OLD_REPO}/AI_Brain
LARAVEL_REPO    = /Users/bkwork/Herd/prime_ai

RBS_FILE        = {OLD_REPO}/3-Project_Planning/1-RBS/PrimeAI_Complete_Spec_v2.md

MODULE_PATH     = {LARAVEL_REPO}/Modules/{MODULE_NAME}
BROWSER_TESTS   = {LARAVEL_REPO}/tests/Browser/Modules/{MODULE_NAME}
FEATURE_TESTS   = {LARAVEL_REPO}/tests/Feature/{MODULE_NAME}
UNIT_TESTS      = {LARAVEL_REPO}/tests/Unit/{MODULE_NAME}
MODULE_TESTS    = {LARAVEL_REPO}/Modules/{MODULE_NAME}/tests
ROUTES_FILE     = {LARAVEL_REPO}/routes/tenant.php
POLICIES_DIR    = {LARAVEL_REPO}/app/Policies
TENANT_MIGS     = {LARAVEL_REPO}/database/migrations/tenant
ACTIVITY_LOG    = {LARAVEL_REPO}/app/Helpers/activityLog.php

V1_DEV_DONE     = {OLD_REPO}/2-Requirement_Module_wise/2-Detailed_Requirements/V1/Dev_Done
V1_DEV_PENDING  = {OLD_REPO}/2-Requirement_Module_wise/2-Detailed_Requirements/V1/Dev_Pending
GAP_ANALYSIS    = {OLD_REPO}/3-Project_Planning/2-Gap_Analysis/2-Modules_Wise/2026Mar22

OUTPUT_DIR      = {OLD_REPO}/2-Requirement_Module_wise/2-Detailed_Requirements/V2
PROGRESS_FILE   = {OUTPUT_DIR}/_batch_progress.md
```

### DATABASE_FILE Resolution
```
MODULE_TYPE = "Tenant"  → DATABASE_FILE = {TENANT_DDL}   (from paths.md)
MODULE_TYPE = "Prime"   → DATABASE_FILE = {PRIME_DDL}    (from paths.md)
MODULE_TYPE = "Global"  → DATABASE_FILE = {GLOBAL_DDL}   (from paths.md)
MODULE_TYPE = "Other"   → DATABASE_FILE = NONE
```

### V1 File Resolution
```
List A (developed):   V1_FILE = {V1_DEV_DONE}/{MODULE_CODE}_{MODULE_NAME}_Requirement.md
List B (undeveloped): V1_FILE = {V1_DEV_PENDING}/{MODULE_CODE}_{MODULE_NAME}_Requirement.md
```

### Gap Analysis File Resolution
```
GAP_FILE = {GAP_ANALYSIS}/{MODULE_NAME}_Deep_Gap_Analysis.md
(Skip silently if file does not exist)
```

### Table Prefix Reference
| Module | MODULE_CODE | Table Prefix | Module | MODULE_CODE | Table Prefix |
|--------|-------------|-------------|--------|-------------|-------------|
| Billing | BIL | `bil_*` | Admission | ADM | `adm_*` |
| Complaint | CMP | `cmp_*` | FrontOffice | FOF | `fof_*` |
| Dashboard | DSH | — | Attendance | ATT | `att_*` |
| Documentation | DOC | — | Academics | ACD | `acd_*` |
| GlobalMaster | GLB | `glb_*` | Examination | EXA | `exa_*` |
| Hpc | HPC | `hpc_*` | FinanceAccounting | FAC | `fac_*` |
| Library | LIB | `bok_*` | Inventory | INV | `inv_*` |
| LmsExam | EXM | `exm_*` | Hostel | HST | `hst_*` |
| LmsHomework | HMW | `hmw_*` | HrStaff | HRS | `hrs_*` |
| LmsQuests | QST | `qst_*` | Communication | COM | `com_*` |
| LmsQuiz | QUZ | `quz_*` | Certificate | CRT | `crt_*` |
| Notification | NTF | `ntf_*` | Lxp | LXP | `lxp_*` |
| Payment | PAY | `pay_*` | PredictiveAnalytics | PAN | `pan_*` |
| Prime | PRM | `prm_*` | Cafeteria | CAF | `caf_*` |
| QuestionBank | QNS | `qns_*` | VisitorSecurity | VSM | `vsm_*` |
| Recommendation | REC | `rec_*` | Maintenance | MNT | `mnt_*` |
| Scheduler | SCH_JOB | — | ParentPortal | PPT | `ppt_*` |
| SchoolSetup | SCH | `sch_*` | | | |
| SmartTimetable | STT | `tt_*` | | | |
| StandardTimetable | TTS | `tt_*` | | | |
| StudentFee | FIN | `fin_*` | | | |
| StudentPortal | STP | `std_*` | | | |
| StudentProfile | STD | `std_*` | | | |
| Syllabus | SLB | `slb_*` | | | |
| SyllabusBooks | SLK | `slb_*` | | | |
| SystemConfig | SYS | `sys_*` | | | |
| TimetableFoundation | TTF | `tt_*` | | | |
| Transport | TPT | `tpt_*` | | | |
| Vendor | VND | `vnd_*` | | | |

---

## ▶ ROLE & OBJECTIVE

You are a **Senior Business Analyst + Solution Architect** for a Laravel multi-tenant SaaS platform serving Indian schools.

**Your job:** For each module — read RBS v4.0 + V1 Requirement + Gap Analysis (where available) + code (List A) + DB schemas (List A) + AI Brain → produce an **exhaustive V2 Module Requirement Document** that is STRICTLY MORE COMPLETE than the V1 document.

**Two Modes:**
- **FULL (List A):** RBS v4.0 + V1 + Gap Analysis + Code + DDL + Tests all read. Mark every feature ✅/🟡/❌. All confirmed gaps become ❌ FR items.
- **RBS_ONLY (List B):** RBS v4.0 + V1 + AI Brain only. V2 must propose richer data models, APIs, and screens than V1 based on improved RBS v4.0 details. Mark everything 📐.

---

## ▶ EXECUTION FLOW — READ THIS CAREFULLY

```
╔══════════════════════════════════════════════════════════════╗
║  EXECUTION FLOW                                              ║
║                                                              ║
║  START                                                       ║
║    │                                                         ║
║    ├─ Step 0: Load paths.md (once)                          ║
║    ├─ Step 1: Load AI Brain files (ONCE — all 13 files)     ║
║    ├─ Read RBS v4.0 (ONCE — full file scan)                 ║
║    │                                                         ║
║    └─ FOR BATCH = START_BATCH TO 10:                        ║
║           │                                                  ║
║           ├─ Print: "▶ STARTING BATCH {N}/10..."            ║
║           ├─ FOR EACH MODULE in this batch:                  ║
║           │      ├─ Steps 2 → 2B → 3 → 4 → 5 → 6 → 7 → 8 → 9║
║           │      ├─ Write output file                        ║
║           │      └─ Print: "✅ [{seq}/46] {CODE}_{NAME}"    ║
║           │                                                  ║
║           ├─ Update {PROGRESS_FILE}                         ║
║           ├─ Print: BATCH COMPLETE SUMMARY (see format)     ║
║           │                                                  ║
║           └─ IF BATCH < 10:                                  ║
║                  ╔══════════════════════════════════════╗    ║
║                  ║  ⏸ PAUSE — ASK USER:                ║    ║
║                  ║  "Batch {N} done. Ready for          ║    ║
║                  ║   Batch {N+1}? (yes / later)"        ║    ║
║                  ╚══════════════════════════════════════╝    ║
║                  ── IF "yes"  → continue to next batch       ║
║                  ── IF "later"→ STOP. Print resume tip.      ║
╚══════════════════════════════════════════════════════════════╝
```

### Pause Behaviour

**On "yes" / "continue" / "next":** Immediately start the next batch. No preamble needed.

**On "later" / "stop" / "pause":** Print this and stop:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⏸  SESSION PAUSED after Batch {N}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Modules completed: {seq_start}–{seq_end} of 46
Files written to: {OUTPUT_DIR}

▶ TO RESUME: Start a new Claude session, paste this
  prompt again, and set:
     START_BATCH = {N+1}

Progress saved to: {PROGRESS_FILE}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Batch Complete Summary Format

Print this after EVERY batch (before asking to continue):

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ BATCH {N}/10 COMPLETE — {Batch Name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Modules processed this batch:
  {seq}. ✅ {CODE}_{NAME} → {filename}
  {seq}. ✅ {CODE}_{NAME} → {filename}
  ...

Cumulative progress: {total_done}/46 modules ({pct}%)
Batches remaining: {10-N} (Batches {N+1}–10)

Next batch preview — Batch {N+1}: {Batch Name}
  Will process: {list of module names}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⏸  Run Batch {N+1} now, or check quota and resume later?
   Reply: "yes" to continue · "later" to pause
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Batch 10 Special — Summary Files

After the two modules in Batch 10, do NOT ask to continue. Instead generate the three summary files automatically, then print:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎉 ALL 46 MODULES + 3 SUMMARY FILES COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total files written: 49 (46 modules + 3 summaries)
Output directory: {OUTPUT_DIR}

Summary files:
  ✅ _00_Master_Requirement_Index_{DATE}.md
  ✅ _01_Cross_Module_Dependencies_{DATE}.md
  ✅ _02_RBS_Coverage_Report_{DATE}.md

Progress file: {PROGRESS_FILE}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Progress File Format

After each batch, write/update `{PROGRESS_FILE}`:

```markdown
# V2 Requirement Generation — Batch Progress

**Run Date:** {DATE}
**RBS Version:** v4.0
**Output Dir:** {OUTPUT_DIR}

| Batch | Name | Modules | Status | Completed At |
|-------|------|---------|--------|-------------|
| 1 | Prime / Global Core | PRM, BIL, GLB, SYS, SCH_JOB | ✅ Done | {timestamp} |
| 2 | School Foundation | SCH, TTF, STT, TTS, DSH | ⏳ Next | — |
| 3 | Student Core | STD, STP, SLB, SLK, DOC | ⏳ | — |
| ... | | | | |

## Files Written
| # | File | Batch | Mode |
|---|------|-------|------|
| 1 | PRM_Prime_Requirement.md | 1 | FULL |
| 2 | BIL_Billing_Requirement.md | 1 | FULL |
...
```

---

## ═══ STEP 1 — LOAD AI BRAIN CONTEXT (ONCE at session start) ═══

Read ALL files below before processing the first module of START_BATCH.
Retain this context for every module across all batches in this session.

| # | File | Extract What |
|---|------|-------------|
| 1 | `{AI_BRAIN}/memory/project-context.md` | Tech stack, services, business goals |
| 2 | `{AI_BRAIN}/memory/tenancy-map.md` | Multi-tenancy isolation rules, DB architecture |
| 3 | `{AI_BRAIN}/memory/modules-map.md` | Module inventory, dependencies, current status |
| 4 | `{AI_BRAIN}/memory/conventions.md` | Naming conventions, code patterns |
| 5 | `{AI_BRAIN}/memory/architecture.md` | System architecture, request flow |
| 6 | `{AI_BRAIN}/memory/school-domain.md` | School domain rules (NEP 2020, Bloom's) |
| 7 | `{AI_BRAIN}/memory/decisions.md` | Architectural decisions and rationale |
| 8 | `{AI_BRAIN}/state/progress.md` | What is done / in-progress / planned |
| 9 | `{AI_BRAIN}/rules/tenancy-rules.md` | Tenancy isolation constraints |
| 10 | `{AI_BRAIN}/rules/module-rules.md` | Module development standards |
| 11 | `{AI_BRAIN}/rules/security-rules.md` | Security requirements |
| 12 | `{AI_BRAIN}/rules/laravel-rules.md` | Laravel conventions |
| 13 | `{AI_BRAIN}/lessons/known-issues.md` | Known bugs, domain edge cases |

Also scan `{RBS_FILE}` in full once to understand the complete module hierarchy
before processing individual modules.

---

## ═══ PER-MODULE PROCESSING STEPS ═══

Run Steps 2–9 for EVERY module. Steps 3–5 are FULL mode only (skip for RBS_ONLY).

---

## ═══ STEP 2 — EXTRACT RBS v4.0 SPECIFICATION ═══

Extract ALL entries for this module's `RBS_MODULE_REF` from `{RBS_FILE}`.

### 2A — RBS Summary Table
| # | Screen/Tab | Table (if mentioned) | DB | Functionalities | Tasks | Sub-Tasks |
|---|-----------|---------------------|-----|-----------------|-------|-----------|
| **TOTAL** | | | | **X** | **X** | **X** |

### 2B — Full Feature Hierarchy
List every Functionality (F.XX.X) → Task (T.XX.X.X) → Sub-Task (ST.XX.X.X.X).

### 2C — Screen Inventory from RBS Menu
Each screen: menu path, tables referenced, associated tasks.

---

## ═══ STEP 2B — READ V1 REQUIREMENT & GAP ANALYSIS ═══

### 2B-1: Read V1 Requirement Document (`{V1_FILE}`)
Extract: feature count, entity count, API count, all FR items with status,
all proposed/existing entities, all proposed/existing routes, Section 14 suggestions.

Build V1 Baseline Summary:
| Metric | V1 Value |
|--------|---------|
| Functionalities | X |
| Tasks | X |
| Entities | X |
| API Endpoints | X |
| UI Screens | X |
| Implemented ✅ | X% |
| Partial 🟡 | X% |
| Not Started ❌ | X% |

### 2B-2: Read Gap Analysis (`{GAP_FILE}`, skip if missing)
Extract all confirmed gaps: schema gaps, API gaps, business logic gaps, test gaps.

Gap Summary:
| # | Gap Category | Description | Severity | V1 Captured? |
|---|-------------|------------|---------|-------------|

**Rule:** Every confirmed gap MUST become an ❌ FR item in Step 6 / Section 4.

---

## ═══ STEP 3 — EXTRACT DATABASE SCHEMA [FULL only] ═══

Read `{DATABASE_FILE}` and extract ALL tables matching this module's Table Prefix.

For each table: name, purpose, all columns (type/nullable/default/constraints),
PKs, FKs, indexes, ENUMs, JSON columns, audit columns.

Build Entity Relationship Summary:
| Entity | Related To | Relationship Type | FK Column | Junction Table |
|--------|-----------|-------------------|-----------|----------------|

Cross-reference `{TENANT_MIGS}/` for DDL vs migration discrepancies.
List schema gaps identified in gap analysis not yet reflected in DDL.

---

## ═══ STEP 4 — EXTRACT CODEBASE [FULL only] ═══

Read every `.php` file inside `{MODULE_PATH}/`.

Extract from: Controllers (methods, FormRequests, Services, Gates, Views),
Models (table, $fillable, $casts, relationships, scopes), Services (business logic),
FormRequests (validation), Policies (permissions), Views (screens, fields, filters),
Routes (method/URI/controller/name/middleware), Jobs, Events, Listeners, Seeders.

Build Code Inventory Summary:
| Layer | Count | Details |
|-------|-------|---------|
| Controllers | X | |
| Models | X | |
| Services | X | |
| FormRequests | X | |
| Policies | X | |
| Views | X | |
| Routes | X | GET/POST/PUT/DELETE counts |
| Jobs | X | |
| Migrations | X | |
| Seeders | X | |

---

## ═══ STEP 5 — EXTRACT TEST CASES [FULL only] ═══

Check: `{BROWSER_TESTS}/`, `{FEATURE_TESTS}/`, `{UNIT_TESTS}/`, `{MODULE_TESTS}/`

For each test file: path, type, test method names, coverage summary.
Map tests to RBS features. Build coverage matrix.

---

## ═══ STEP 6 — SYNTHESIZE: BUILD V2 REQUIREMENT DOCUMENT ═══

### FULL Mode Rules (List A):
1. RBS v4.0 is PRIMARY — every Feature/Task/Sub-Task MUST appear
2. V1 Requirement is baseline — V2 retains all valid V1 content, expanded
3. Gap Analysis is MANDATORY — every confirmed gap → ❌ FR item with gap reference
4. Code fills implementation details — status ✅/🟡/❌
5. DB Schema defines data model — existing entities + schema gaps
6. V2 must be MORE COMPLETE than V1

### RBS_ONLY Mode Rules (List B):
1. RBS v4.0 is the ONLY functional source
2. V1 is the baseline — V2 expands on V1 using RBS v4.0 improvements
3. All features are ❌ Not Started — produce complete greenfield specs
4. PROPOSE improved data models, APIs, screens, tests vs V1
5. Mark proposed items with 📐

---

## ═══ STEP 7 — CROSS-MODULE DEPENDENCY ANALYSIS ═══

### 7A — Modules THIS Module Depends On
| Dep Module | Type | What It Needs | Tables/Models Referenced |
|-----------|------|---------------|--------------------------|

### 7B — Modules That Depend on THIS Module
| Dependent Module | What It Uses |
|-----------------|-------------|

### 7C — New Dependencies vs V1

---

## ═══ STEP 8 — QUALITY CHECKLIST ═══

- [ ] Every RBS v4.0 Feature captured as FR
- [ ] All confirmed gaps from Gap Analysis present as ❌ FR items
- [ ] V2 has ≥ V1 feature count (no regression)
- [ ] Data model complete
- [ ] API endpoints cover all CRUD + custom operations
- [ ] UI screens match RBS v4.0
- [ ] Test scenarios exist for every feature
- [ ] Cross-module dependencies mapped
- [ ] Non-functional requirements specified
- [ ] Section 14 = suggestions only
- [ ] Section 16 = V1→V2 delta documented

---

## ═══ STEP 9 — V1 TO V2 DELTA ANALYSIS ═══

| Category | V1 Count | V2 Count | New | Removed | Changed |
|----------|---------|---------|-----|---------|---------|
| Functionalities | X | X | X | X | X |
| Tasks | X | X | X | X | X |
| Sub-Tasks | X | X | X | X | X |
| Entities | X | X | X | X | X |
| API Endpoints | X | X | X | X | X |
| UI Screens | X | X | X | X | X |

Gap Coverage:
| Gap Category | Gaps in Analysis | Captured in V2 | Resolved (✅/🟡) |
|-------------|-----------------|----------------|-----------------|

RBS v4.0 New Content (features present in v4.0 not in v2.0):
- {list}

---

## ═══ OUTPUT — V2 MODULE REQUIREMENT DOCUMENT TEMPLATE ═══

**Write to:** `{OUTPUT_DIR}/{MODULE_CODE}_{MODULE_NAME}_Requirement.md`

---

```markdown
# {MODULE_NAME} Module — Requirement Specification Document v2
**Version:** 2.0  |  **Date:** {DATE}  |  **Author:** Claude Code (Automated)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** {MODULE_CODE}  |  **Module Path:** `{MODULE_PATH or "N/A — New Module"}`
**Module Type:** {MODULE_TYPE}  |  **Database:** `{DATABASE_FILE or "Proposed: tenant_db"}`
**Table Prefix:** `{TABLE_PREFIX}`  |  **Processing Mode:** {FULL or RBS_ONLY}
**RBS Reference:** {RBS_MODULE_REF}  |  **RBS Version:** v4.0
**V1 Baseline:** `{V1_FILE}`  |  **Gap Analysis:** `{GAP_FILE or "N/A"}`
**Generation Batch:** {N}/10

---

## TABLE OF CONTENTS

1. [Executive Summary](#1-executive-summary)
2. [Module Overview](#2-module-overview)
3. [Stakeholders & Actors](#3-stakeholders--actors)
4. [Functional Requirements](#4-functional-requirements)
5. [Data Model & Entity Specification](#5-data-model--entity-specification)
6. [API & Route Specification](#6-api--route-specification)
7. [UI Screen Inventory & Field Mapping](#7-ui-screen-inventory--field-mapping)
8. [Business Rules & Domain Constraints](#8-business-rules--domain-constraints)
9. [Workflow & State Machine Definitions](#9-workflow--state-machine-definitions)
10. [Non-Functional Requirements](#10-non-functional-requirements)
11. [Cross-Module Dependencies](#11-cross-module-dependencies)
12. [Test Case Reference & Coverage](#12-test-case-reference--coverage)
13. [Glossary & Terminology](#13-glossary--terminology)
14. [Additional Suggestions](#14-additional-suggestions)
15. [Appendices](#15-appendices)
16. [V1 → V2 Delta Summary](#16-v1--v2-delta-summary)

---

## 1. EXECUTIVE SUMMARY

### 1.1 Purpose
{What this module does — from RBS v4.0 + AI Brain school-domain.md}

### 1.2 Scope
- **In Scope:** {list}
- **Out of Scope:** {list}

### 1.3 Module Statistics
| Metric | V1 Count | V2 Count | Delta |
|--------|---------|---------|-------|
| RBS Functionalities (F.XX.X) | X | X | +X |
| RBS Tasks (T.XX.X.X) | X | X | +X |
| RBS Sub-Tasks (ST.XX.X.X.X) | X | X | +X |
| Database Tables | X | X | +X |
| API Endpoints | X | X | +X |
| UI Screens / Tabs | X | X | +X |
| Existing Controllers | X | X | — |
| Existing Models | X | X | — |
| Existing Tests | X | X | — |
| Cross-Module Dependencies | X | X | +X |
| Gaps Incorporated | — | X | NEW |

### 1.4 Implementation Status
| Status | Feature Count | Percentage |
|--------|--------------|------------|
| ✅ Implemented | X | X% |
| 🟡 Partial | X | X% |
| ❌ Not Started | X | X% |
| **Total** | **X** | **100%** |

### 1.5 Gap Analysis Summary (List A only)
| Gap Category | Total Gaps | In V2 | Coverage |
|-------------|-----------|-------|---------|
| Schema Gaps | X | X | X% |
| API Gaps | X | X | X% |
| Business Logic Gaps | X | X | X% |
| Test Gaps | X | X | X% |

### 1.6 Implementation Prerequisites (List B only)
| # | Prerequisite Module | Must Be Ready | Reason |
|---|---------------------|---------------|--------|

---

## 2. MODULE OVERVIEW

### 2.1 Business Purpose
{From RBS v4.0 + AI Brain school-domain.md}

### 2.2 Key Features Summary
| # | Feature Area | Description | RBS Ref | Status | V1 Status |
|---|-------------|-------------|---------|--------|-----------|

### 2.3 Menu Navigation Path
{All menu paths from RBS v4.0}

### 2.4 Module Architecture
**For List A:**
```
{Actual folder structure from MODULE_PATH}
```
**For List B — 📐 PROPOSED:**
```
Modules/{MODULE_NAME}/
├── app/Http/Controllers/  → 📐 {proposed}
├── app/Http/Requests/     → 📐 {proposed}
├── app/Models/            → 📐 {proposed}
├── app/Services/          → 📐 {proposed}
├── app/Policies/          → 📐 {proposed}
├── app/Jobs/              → 📐 {proposed}
├── database/seeders/      → 📐 {proposed}
├── resources/views/       → 📐 {proposed}
├── routes/web.php
├── routes/api.php
└── tests/
```

---

## 3. STAKEHOLDERS & ACTORS

| # | Actor | Role | Access Level | Screens |
|---|-------|------|-------------|---------|

---

## 4. FUNCTIONAL REQUIREMENTS

> Source: RBS v4.0 (primary) + Gap Analysis (confirmed gaps) + Code (FULL) + AI Brain

### FR-{MODULE_CODE}-001: {Functionality Name} (F.XX.X)

**RBS Reference:** F.XX.X  |  **Priority:** 🔴/🟡/🟢/⚪
**Status:** ✅/🟡/❌  |  **V1 Status:** ✅/🟡/❌
**Gap Analysis:** ⚠️ Confirmed Gap / ✅ No Gap
**Owner Screen:** {Screen/Tab}
**Table(s):** `{table}` or `📐 Proposed: {prefix}_{name}`

#### Description
{From RBS v4.0. Note any change from V1.}

#### Requirements

**REQ-{MODULE_CODE}-001.1: {Task Name} (T.XX.X.X)**
| Attribute | Detail |
|-----------|--------|
| Description | {from RBS v4.0} |
| Actors | {roles} |
| Preconditions | {what must exist} |
| Trigger | {user action / system event} |
| Input | {form fields / parameters} |
| Processing | {business logic steps} |
| Output | {success result} |
| Error Handling | {failure scenarios} |
| V1 Status | ✅/🟡/❌/🆕 New in V2 |
| Gap Reference | {gap ID or "—"} |

**Acceptance Criteria:**
- [ ] `ST.XX.X.X.1` — {sub-task} → **Status:** ✅/❌

**Current Implementation (FULL only):**
| Layer | File | Method | Notes |
|-------|------|--------|-------|

**📐 Proposed Implementation (RBS_ONLY):**
| Layer | Proposed File | Proposed Method | Responsibility |
|-------|-------------|-----------------|----------------|

**Required Test Cases:**
| # | Scenario | Type | Status | Priority |
|---|---------|------|--------|----------|

---

> Repeat for EVERY Functionality in RBS v4.0.
> Include ALL gaps from Gap Analysis as ❌ FR items with Gap Reference.

---

## 5. DATA MODEL & ENTITY SPECIFICATION

### 5.1 Entity Overview
| # | Entity (Table) | Status | Purpose | Cols | FKs | Idx | Prefix | V1 Status |
|---|----------------|--------|---------|------|-----|-----|--------|-----------|

### 5.2 Detailed Entity Specification

#### ENTITY: {prefix}_{table_name}  [✅/📐/🆕]

**Purpose:** {description}  |  **Model:** `Modules\{MODULE_NAME}\Models\{Model}`

| # | Column | Type | Nullable | Default | Constraints | Business Rule |
|---|--------|------|----------|---------|-------------|--------------|
| 1 | id | BIGINT UNSIGNED | NO | AI | PK | — |
| N | is_active | TINYINT(1) | NO | 1 | — | Soft visibility |
| N+1 | created_by | BIGINT UNSIGNED | YES | NULL | FK→sys_users | Audit |
| N+2 | created_at | TIMESTAMP | YES | NULL | — | Audit |
| N+3 | updated_at | TIMESTAMP | YES | NULL | — | Audit |
| N+4 | deleted_at | TIMESTAMP | YES | NULL | — | Soft delete |

**Foreign Keys, Indexes, ENUMs, JSON Columns, Relationships** — per entity.

---

### 5.3 Entity Relationship Summary
```
{table_a} 1──* {table_b}  (via {fk})
{table_c} *──* {table_d}  (via {jnt})
```

### 5.4 Schema Reconciliation Notes (FULL only)
### 5.5 Schema Gaps from Gap Analysis (FULL only)
### 5.6 📐 Proposed Migration Order (RBS_ONLY)

---

## 6. API & ROUTE SPECIFICATION

### 6.1 Route Summary
| # | Method | URI | Controller@Method | Route Name | Middleware | Status | V1 Status |
|---|--------|-----|-------------------|------------|------------|--------|-----------|

### 6.2 Detailed Endpoint Specification
{Request body, response payload, HTTP codes, business rules, authorization per endpoint}

### 6.3 API Gaps from Gap Analysis (FULL only)
### 6.4 📐 Proposed Route Group Structure (RBS_ONLY)

```php
Route::middleware(['auth', 'EnsureTenantHasModule:{module-slug}'])
    ->prefix('{module-slug}')->name('{module-slug}.')
    ->group(function () {
        Route::resource('{resource}', {Resource}Controller::class);
    });
```

---

## 7. UI SCREEN INVENTORY & FIELD MAPPING

### 7.1 Screen Overview
| # | Screen Name | Menu Path | RBS Ref | Status | V1 Status |
|---|------------|-----------|---------|--------|-----------|

### 7.2 Detailed Screen Specification
{Purpose, route, controller, view file, fields, actions, filters, table columns, tabs per screen}

---

## 8. BUSINESS RULES & DOMAIN CONSTRAINTS

| # | Rule ID | Description | Source | Enforcement Layer |
|---|---------|-------------|--------|-------------------|

---

## 9. WORKFLOW & STATE MACHINE DEFINITIONS

{States, transitions, guards, side effects per workflow}

---

## 10. NON-FUNCTIONAL REQUIREMENTS

| # | Category | Requirement | Priority |
|---|----------|-------------|----------|
| 1 | Performance | List views < 2s (≤500 records) | 🔴 |
| 2 | Security | Tenant isolation — no cross-tenant leakage | 🔴 |
| 3 | Security | All routes: auth + EnsureTenantHasModule | 🔴 |
| 4 | Scalability | 1,000 concurrent tenant users | 🟡 |
| 5 | Audit | All CUD operations → sys_activity_logs | 🟡 |
| 6 | Localization | Multi-language via glb_translations | 🟢 |
| 7 | Soft Delete | deleted_at on all records | 🔴 |

---

## 11. CROSS-MODULE DEPENDENCIES

### 11.1 This Module Depends On
| # | Module | CODE | Status | Dep Type | What It Needs |
|---|--------|------|--------|---------|--------------|

### 11.2 Modules That Depend on This
| # | Module | CODE | Status | What It Uses |
|---|--------|------|--------|-------------|

### 11.3 New Dependencies vs V1

### 11.4 Implementation Order (RBS_ONLY)

---

## 12. TEST CASE REFERENCE & COVERAGE

### 12.1 Existing Tests (FULL only)
### 12.2 Test Plan (V2 Complete)

| # | Test Scenario | Type | Feature Ref | Status | Priority |
|---|--------------|------|-------------|--------|----------|
| 1 | Unauthenticated → 401 | Feature | All | ✅/📐 | 🔴 |
| 2 | Wrong role → 403 | Feature | All | ✅/📐 | 🔴 |
| 3 | Tenant isolation | Feature | All | ✅/📐 | 🔴 |
| 4 | CRUD create → success | Feature | FR-001 | ✅/📐 | 🔴 |
| 5 | Validation failure | Feature | FR-001 | ✅/📐 | 🟡 |

### 12.3 Coverage Summary

---

## 13. GLOSSARY & TERMINOLOGY

| Term | Definition | Context |
|------|-----------|---------|

---

## 14. ADDITIONAL SUGGESTIONS

> Section 14 = Claude's recommendations ONLY. Not from RBS, code, or gap analysis.

### 14.1 Feature Enhancements  |  14.2 Technical Improvements
### 14.3 UX/UI Improvements  |  14.4 Integration Opportunities
### 14.5 Indian Education Domain / NEP 2020

---

## 15. APPENDICES

- **A** — Full RBS v4.0 Extract (this module)
- **B** — Complete Route Table
- **C** — Code Inventory (FULL) or Proposed File List (RBS_ONLY)
- **D** — Test Listing
- **E** — Entity-Relationship Mapping
- **F** — AI Brain References Used
- **G** — Gap Analysis Source (if applicable)

---

## 16. V1 → V2 DELTA SUMMARY

### 16.1 Feature Count Changes
| Category | V1 | V2 | Delta | Reason |
|----------|----|----|-------|--------|
| Functionalities | X | X | +X | {new in RBS v4.0 / gaps added} |

### 16.2 New in V2 (not in V1)
### 16.3 Improved in V2
### 16.4 Gaps Now Addressed

| Gap | Severity | V1 Status | V2 Status |
|-----|---------|-----------|-----------|

### 16.5 V1 → V2 Quality Score
| Dimension | V1 | V2 | Δ |
|-----------|----|----|---|
| RBS Coverage | X% | X% | +X% |
| Gap Incorporation | 0% | X% | +X% |
| Data Model Completeness | X% | X% | +X% |
| API Completeness | X% | X% | +X% |
| Test Plan Coverage | X% | X% | +X% |
```

---

## ▶ SUMMARY FILE SPECIFICATIONS (Batch 10 — after modules 45 & 46)

### a) `{OUTPUT_DIR}/_00_Master_Requirement_Index_{DATE}.md`
- Table of all 46 modules: Code, Name, Batch#, Mode, Type, RBS Ref, Feature Count, Entity Count, API Count, Status, V1→V2 Delta%
- Aggregate statistics across all modules

### b) `{OUTPUT_DIR}/_01_Cross_Module_Dependencies_{DATE}.md`
- 46×46 NxN dependency matrix
- Dependency clusters and groups
- Recommended implementation order (phases)
- Critical path analysis

### c) `{OUTPUT_DIR}/_02_RBS_Coverage_Report_{DATE}.md`
- Every RBS v4.0 Feature (F.XX.X) mapped to requirement document
- Coverage %, orphan features (in RBS but not captured), coverage by module

---

## ▶ ANALYSIS RULES

### All Modules:
1. **RBS v4.0 is authoritative** — every Feature/Task/Sub-Task MUST appear.
2. **V1 is baseline** — V2 must always be MORE complete. Never drop coverage.
3. **Gaps are requirements** — every confirmed gap → ❌ FR item in Section 4.
4. **Be specific** — every requirement has testable acceptance criteria.
5. **No hallucination** — missing file = say it's missing (FULL) or mark 📐 (RBS_ONLY).
6. **Facts vs suggestions** — Sections 1–13, 15–16 = sources only. Section 14 = suggestions.
7. **Think downstream** — every section usable for DDL, API spec, test, wireframe, sprint.
8. **Tenancy awareness** — always capture tenancy scope and isolation requirements.
9. **Convention compliance** — AI Brain naming for all proposed entities.
10. **Count everything** — summary tables need accurate V1/V2/delta counts.
11. **Mark status** — ✅ / 🟡 / ❌ / 📐 / 🆕 (new in V2).
12. **Cross-reference** — RBS v4.0 ↔ V1 ↔ Gap Analysis ↔ Code ↔ DB ↔ Tests.

### List A (FULL) Additional:
13. **Open every file** — read actual code, don't guess.
14. **Check the real DB** — cross-reference DDL, not just model definitions.
15. **No false positives** — only report features confirmed in code.
16. **ALL gaps must appear** — as ❌ FRs with gap reference and severity.

### List B (RBS_ONLY) Additional:
17. **Expand V1, don't just copy it** — V2 must add depth from RBS v4.0.
18. **PROPOSE complete data models** — improve on V1's proposed tables.
19. **PROPOSE complete API** — expand V1's proposed routes.
20. **PROPOSE complete screens** — expand V1's UI specs.
21. **PROPOSE complete tests** — expand V1's test scenarios.
22. **Use PROPOSED_TABLE_PREFIX** — all table names use the assigned prefix.
23. **Mark EVERYTHING 📐** — never imply something exists when it doesn't.
24. **List implementation prerequisites** — which existing modules must be ready first.

---
