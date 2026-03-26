# ╔════════════════════════════════════════════════════════════════════════╗
# ║   MODULE REQUIREMENT DOCUMENT — BATCH GENERATION PROMPT v4             ║
# ║   Prime-AI Academic Intelligence Platform                              ║
# ║   Based on: RBS v4.0 (enhanced) + V1 Requirements + Gap Analysis       ║
# ╚════════════════════════════════════════════════════════════════════════╝
#
# HOW TO USE:
#   1. Change only the 2 lines below: APP_BRANCH, DATE
#   2. No need to change any path — everything derives from paths.md
#   3. Copy entire file → Paste into Claude Code
#   4. Claude iterates through all 46 modules, reads all available inputs,
#      and writes a V2 Requirement Document per module into {OUTPUT_DIR}.
#
# WHAT'S NEW in v4 (vs v3):
#   - Primary RBS source upgraded to v4.0 (enhanced, more detailed)
#   - V1 Requirement Documents are now additional INPUT for each module
#     → Build on V1 rather than starting from scratch
#   - Gap Analysis reports (2026-03-22) are now additional INPUT
#     → Incorporate confirmed gaps into V2 specs
#   - Output goes to V2/ (single flat folder — no Dev_Done/Dev_Pending split)
#   - Paths updated to match current paths.md
#   - V2 documents must be STRICTLY MORE COMPLETE than their V1 counterpart
#   - New Section 16: "V1 → V2 Delta" — what changed / improved from V1
# ═════════════════════════════════════════════════════════════════════════

---

## ▶ GLOBAL VARIABLES (set once, apply to all modules):

```
APP_BRANCH     = Brijesh
DATE           = 2026-03-26
```

---

## ▶ MODULE LIST

### ━━━ LIST A — DEVELOPED MODULES (Code + DDL + V1 Req + Gap Analysis exist) ━━━

> **Processing Mode:** FULL — Read RBS v4.0 + V1 Req + Gap Analysis + Code + DDL + Migrations + Tests + AI Brain

| # | MODULE_NAME | MODULE_CODE | MODULE_TYPE | RBS_MODULE_REF |
|---|-------------|-------------|-------------|----------------|
| 1 | Billing | BIL | Prime | Module V (partial) |
| 2 | Complaint | CMP | Tenant | Module D (partial) |
| 3 | Dashboard | DSH | Other | — (Cross-module) |
| 4 | Documentation | DOC | Other | — (Internal) |
| 5 | GlobalMaster | GLB | Global | Module A (partial) |
| 6 | Hpc | HPC | Tenant | Module I (partial) |
| 7 | Library | LIB | Tenant | Module M (partial) |
| 8 | LmsExam | EXM | Tenant | Module S (partial) |
| 9 | LmsHomework | HMW | Tenant | Module S (partial) |
| 10 | LmsQuests | QST | Tenant | Module S (partial) |
| 11 | LmsQuiz | QUZ | Tenant | Module S (partial) |
| 12 | Notification | NTF | Tenant | Module Q (partial) |
| 13 | Payment | PAY | Tenant | Module J (partial) |
| 14 | Prime | PRM | Prime | Module A (partial) |
| 15 | QuestionBank | QNS | Tenant | Module I (partial) |
| 16 | Recommendation | REC | Tenant | Module U (partial) |
| 17 | Scheduler | SCH_JOB | Other | Module SYS (partial) |
| 18 | SchoolSetup | SCH | Tenant | Module A (partial), H (partial) |
| 19 | SmartTimetable | STT | Tenant | Module G (partial) |
| 20 | StandardTimetable | TTS | Tenant | Module G (partial) |
| 21 | StudentFee | FIN | Tenant | Module J (partial) |
| 22 | StudentPortal | STP | Tenant | Module E (partial), Z (partial) |
| 23 | StudentProfile | STD | Tenant | Module C (partial), E (partial) |
| 24 | Syllabus | SLB | Tenant | Module H (partial) |
| 25 | SyllabusBooks | SLK | Prime | Module H (partial) |
| 26 | SystemConfig | SYS | Prime | Module A (partial), SYS |
| 27 | TimetableFoundation | TTF | Prime | Module G (partial) |
| 28 | Transport | TPT | Tenant | Module N (partial) |
| 29 | Vendor | VND | Tenant | Module K (partial) |

---

### ━━━ LIST B — UNDEVELOPED MODULES (RBS v4.0 + V1 Req + AI Brain only) ━━━

> **Processing Mode:** RBS_ONLY — No code/DDL/tests to read.
> V1 Requirement Document exists as a greenfield spec baseline.
> V2 must expand upon V1 using the improved RBS v4.0 details.

| # | MODULE_NAME | MODULE_CODE | PROPOSED_TYPE | PROPOSED_TABLE_PREFIX | RBS_MODULE_REF |
|---|-------------|-------------|---------------|----------------------|----------------|
| 30 | Admission | ADM | Tenant | `adm_*` | Module C — Admissions & Student Lifecycle |
| 31 | FrontOffice | FOF | Tenant | `fof_*` | Module D — Front Office & Communication |
| 32 | Attendance | ATT | Tenant | `att_*` | Module F — Attendance Management |
| 33 | Academics | ACD | Tenant | `acd_*` | Module H — Academics Management |
| 34 | Examination | EXA | Tenant | `exa_*` | Module I — Examination & Gradebook |
| 35 | FinanceAccounting | FAC | Tenant | `fac_*` | Module K — Finance & Accounting |
| 36 | Inventory | INV | Tenant | `inv_*` | Module L — Inventory & Stock Management |
| 37 | Hostel | HST | Tenant | `hst_*` | Module O — Hostel Management |
| 38 | HrStaff | HRS | Tenant | `hrs_*` | Module P — HR & Staff Management |
| 39 | Communication | COM | Tenant | `com_*` | Module Q — Communication & Messaging |
| 40 | Certificate | CRT | Tenant | `crt_*` | Module R — Certificates & Identity Management |
| 41 | Lxp | LXP | Tenant | `lxp_*` | Module T — Learner Experience Platform |
| 42 | PredictiveAnalytics | PAN | Tenant | `pan_*` | Module U — Predictive Analytics & ML Engine |
| 43 | Cafeteria | CAF | Tenant | `caf_*` | Module W — Cafeteria & Mess Management |
| 44 | VisitorSecurity | VSM | Tenant | `vsm_*` | Module X — Visitor & Security Management |
| 45 | Maintenance | MNT | Tenant | `mnt_*` | Module Y — Maintenance & Facility Helpdesk |
| 46 | ParentPortal | PPT | Tenant | `ppt_*` | Module Z — Parent Portal & Mobile App |

---

### ━━━ RBS-TO-MODULE CROSS-REFERENCE ━━━

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

## ═══ STEP 0 — LOAD DEFAULT PATHS & CONFIGURATION ═══

### DEFAULT PATHS
Read `/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/config/paths.md`

### Rules
- Variables in `paths.md` take precedence over the CONFIGURATION section below.
- If a path is absent in `paths.md`, fall back to the CONFIGURATION section.

---

### CONFIGURATION

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
```

### DATABASE_FILE Resolution
```
If MODULE_TYPE = "Tenant"  → DATABASE_FILE = {TENANT_DDL}   (from paths.md)
If MODULE_TYPE = "Prime"   → DATABASE_FILE = {PRIME_DDL}    (from paths.md)
If MODULE_TYPE = "Global"  → DATABASE_FILE = {GLOBAL_DDL}   (from paths.md)
If MODULE_TYPE = "Other"   → DATABASE_FILE = NONE
```

### V1 Requirement File Resolution
```
If MODULE is in List A (developed):   V1_FILE = {V1_DEV_DONE}/{MODULE_CODE}_{MODULE_NAME}_Requirement.md
If MODULE is in List B (undeveloped): V1_FILE = {V1_DEV_PENDING}/{MODULE_CODE}_{MODULE_NAME}_Requirement.md
```

### Gap Analysis File Resolution
```
GAP_FILE = {GAP_ANALYSIS}/{MODULE_NAME}_Deep_Gap_Analysis.md
(Skip if file does not exist — not all modules had gap analysis done)
```

### Table Prefix Reference
| Module | MODULE_CODE | Table Prefix |
|--------|-------------|-------------|
| Billing | BIL | `bil_*` |
| Complaint | CMP | `cmp_*` |
| Dashboard | DSH | — (No tables) |
| Documentation | DOC | — (No tables) |
| GlobalMaster | GLB | `glb_*` |
| Hpc | HPC | `hpc_*` |
| Library | LIB | `bok_*` |
| LmsExam | EXM | `exm_*` |
| LmsHomework | HMW | `hmw_*` |
| LmsQuests | QST | `qst_*` |
| LmsQuiz | QUZ | `quz_*` |
| Notification | NTF | `ntf_*` |
| Payment | PAY | `pay_*` |
| Prime | PRM | `prm_*` |
| QuestionBank | QNS | `qns_*` |
| Recommendation | REC | `rec_*` |
| Scheduler | SCH_JOB | — (No tables) |
| SchoolSetup | SCH | `sch_*` |
| SmartTimetable | STT | `tt_*` |
| StandardTimetable | TTS | `tt_*` |
| StudentFee | FIN | `fin_*` |
| StudentPortal | STP | `std_*` |
| StudentProfile | STD | `std_*` |
| Syllabus | SLB | `slb_*` |
| SyllabusBooks | SLK | `slb_*` |
| SystemConfig | SYS | `sys_*` |
| TimetableFoundation | TTF | `tt_*` |
| Transport | TPT | `tpt_*` |
| Vendor | VND | `vnd_*` |
| Admission | ADM | `adm_*` |
| FrontOffice | FOF | `fof_*` |
| Attendance | ATT | `att_*` |
| Academics | ACD | `acd_*` |
| Examination | EXA | `exa_*` |
| FinanceAccounting | FAC | `fac_*` |
| Inventory | INV | `inv_*` |
| Hostel | HST | `hst_*` |
| HrStaff | HRS | `hrs_*` |
| Communication | COM | `com_*` |
| Certificate | CRT | `crt_*` |
| Lxp | LXP | `lxp_*` |
| PredictiveAnalytics | PAN | `pan_*` |
| Cafeteria | CAF | `caf_*` |
| VisitorSecurity | VSM | `vsm_*` |
| Maintenance | MNT | `mnt_*` |
| ParentPortal | PPT | `ppt_*` |

---

## ▶ BATCH EXECUTION INSTRUCTIONS

### Processing Order
1. Process all LIST A modules (1–29) first — code + DDL + V1 + gap analysis all available.
2. Then process all LIST B modules (30–46) — RBS v4.0 + V1 baseline only.

### For EACH module, do the following:

1. Set current module variables:
   ```
   MODULE_NAME     = {current module}
   MODULE_CODE     = {3-char code}
   MODULE_TYPE     = {FULL or RBS_ONLY}
   DATABASE_FILE   = {resolved from MODULE_TYPE}
   V1_FILE         = {resolved from V1 path rules}
   GAP_FILE        = {resolved from Gap Analysis path, or SKIP if missing}
   ```

2. Execute steps **0 → 1 → 2 → 2B → 3 → 4 → 5 → 6 → 7 → 8 → 9 → OUTPUT**
   - **FULL (List A):** Execute ALL steps
   - **RBS_ONLY (List B):** Skip Steps 4, 5 (no code/DDL/tests to read)

3. Write output to:
   ```
   {OUTPUT_DIR}/{MODULE_CODE}_{MODULE_NAME}_Requirement.md
   ```

4. Print one-line status after each module:
   ```
   ✅ [{#}/46] {MODULE_CODE}_{MODULE_NAME} — V2 complete [{MODE}] → {output path}
   ```

5. After ALL 46 modules, write three summary files:

   **a) Master Index:**  `{OUTPUT_DIR}/_00_Master_Requirement_Index_{DATE}.md`
   - Table: Module Code, Name, Mode, Type, RBS Ref, Feature Count, Entity Count, API Count, V1→V2 Delta summary

   **b) Cross-Module Dependency Matrix:**  `{OUTPUT_DIR}/_01_Cross_Module_Dependencies_{DATE}.md`
   - 46×46 NxN dependency matrix + clusters + suggested implementation order

   **c) RBS v4.0 Coverage Report:**  `{OUTPUT_DIR}/_02_RBS_Coverage_Report_{DATE}.md`
   - Every RBS Feature (F.XX.X) mapped to requirement document + coverage % + orphan features

---

## ▶ ROLE & OBJECTIVE

You are a **Senior Business Analyst + Solution Architect** for a Laravel multi-tenant SaaS platform serving Indian schools.

**Your job:** Read RBS v4.0 + V1 Requirement + Gap Analysis (where available) + existing code (List A) + DB schemas (List A) + AI Brain → produce an **exhaustive V2 Module Requirement Document** that:

- Is STRICTLY MORE COMPLETE than the V1 document
- Incorporates all gaps identified in the Gap Analysis
- Reflects the updated/enhanced RBS v4.0 structure
- Serves as the single source of truth for: DDL generation, API spec, test cases, UI wireframes, sprint tasks, deployment checklists

### Processing Modes

**Mode A — FULL (List A Developed Modules):**
RBS v4.0 + V1 Requirement + Gap Analysis + Code + DDL + Tests are all available.
Mark every feature: ✅ Implemented / 🟡 Partial / ❌ Not Started.
Every gap confirmed in the Gap Analysis must become a concrete ❌ requirement in V2.

**Mode B — RBS_ONLY (List B Undeveloped Modules):**
RBS v4.0 + V1 Requirement + AI Brain only. No code, DDL, or tests exist.
The V1 document is your greenfield baseline. V2 must propose more complete data models,
richer API specs, and more detailed screen specs based on the improved RBS v4.0.

**CRITICAL FOR LIST B:** Do not produce a thin document. V2 greenfield specs must be
at least as detailed as V1, and richer where RBS v4.0 provides additional content.

---

## ═══ STEP 1 — LOAD AI BRAIN CONTEXT (Read ONCE, Retain for All Modules) ═══

Read these files once. Retain context for all 46 modules.

| # | File | Extract What |
|---|------|-------------|
| 1 | `{AI_BRAIN}/memory/project-context.md` | Tech stack, services, business goals |
| 2 | `{AI_BRAIN}/memory/tenancy-map.md` | Multi-tenancy isolation rules, DB architecture |
| 3 | `{AI_BRAIN}/memory/modules-map.md` | Module inventory, dependencies, status |
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

---

## ═══ STEP 2 — EXTRACT RBS v4.0 SPECIFICATION ═══

Read `{RBS_FILE}` and extract ALL entries for this module's `RBS_MODULE_REF`.

### 2A — Build RBS Summary Table
| # | Screen/Tab | Table (if mentioned) | DB | Functionalities | Tasks | Sub-Tasks |
|---|-----------|---------------------|-----|-----------------|-------|-----------|
| **TOTAL** | | | | **X** | **X** | **X** |

### 2B — Full Feature Hierarchy
List every Functionality (F.XX.X) → Task (T.XX.X.X) → Sub-Task (ST.XX.X.X.X) in hierarchy form.

### 2C — Screen Inventory from RBS Menu
Record each screen: menu path, tables referenced, associated tasks.

---

## ═══ STEP 2B — READ V1 REQUIREMENT & GAP ANALYSIS ═══

> **Applies to: BOTH List A and List B modules**

### 2B-1: Read V1 Requirement Document
Read `{V1_FILE}` and extract:
- Section 1 (Executive Summary): feature count, entity count, API count, implementation status
- Section 4 (Functional Requirements): all FR items and their status
- Section 5 (Data Model): all existing/proposed entities
- Section 6 (API Routes): all existing/proposed routes
- Section 14 (Suggestions): improvement suggestions from V1

Build a **V1 Baseline Summary**:
| Metric | V1 Value |
|--------|---------|
| Functionalities captured | X |
| Tasks captured | X |
| Entities (tables) | X |
| API Endpoints | X |
| UI Screens | X |
| Implemented (✅) | X% |
| Partial (🟡) | X% |
| Not Started (❌) | X% |

### 2B-2: Read Gap Analysis (if available)
Read `{GAP_FILE}` if it exists, and extract:
- List of confirmed gaps (features missing from implementation)
- Schema gaps (missing columns, wrong types, missing indexes)
- API gaps (missing endpoints)
- Business logic gaps
- Test coverage gaps

Build a **Gap Summary**:
| # | Gap Category | Gap Description | Severity | V1 Captured? |
|---|-------------|----------------|----------|--------------|
| 1 | Schema | {gap} | 🔴/🟡/🟢 | ✅/❌ |

**All confirmed gaps MUST become ❌ requirements in V2 Section 4.**

---

## ═══ STEP 3 — EXTRACT DATABASE SCHEMA (List A Only) ═══

> Skip entirely for List B modules.

Read `{DATABASE_FILE}` and extract ALL tables matching this module's Table Prefix.

### 3A — For each table: name, purpose, all columns (type/nullable/default/constraints), PKs, FKs, indexes, ENUMs, JSON columns, audit columns.

### 3B — Entity Relationship Summary
| Entity | Related To | Relationship Type | FK Column | Junction Table |
|--------|-----------|-------------------|-----------|----------------|

### 3C — Cross-Reference with Migrations
Check `{TENANT_MIGS}/` for discrepancies between DDL and migrations.

### 3D — Schema Gaps vs V1 + Gap Analysis
List any schema issues identified in gap analysis that are NOT yet reflected in the DDL.

---

## ═══ STEP 4 — EXTRACT EXISTING CODEBASE (List A Only) ═══

> Skip entirely for List B modules.

Read every `.php` file inside `{MODULE_PATH}/`.

### 4A — Controllers: class names, public methods, FormRequests, Services, Gates, Views
### 4B — Models: table, $fillable, $casts, relationships, scopes, traits
### 4C — Services: business logic methods, transactions, integrations
### 4D — Form Requests: validation rules, authorization
### 4E — Policies: permission methods
### 4F — Views: screens, fields, datatables, action buttons, tabs
### 4G — Routes: method, URI, controller@method, route name, middleware
### 4H — Jobs, Events, Listeners
### 4I — Seeders

### 4J — Code Inventory Summary
| Layer | Count | Details |
|-------|-------|---------|
| Controllers | X | {list} |
| Models | X | {list} |
| Services | X | {list} |
| FormRequests | X | {list} |
| Policies | X | {list} |
| Views | X | {list} |
| Routes | X | GET/POST/PUT/DELETE counts |
| Jobs | X | {list} |
| Migrations | X | {list} |
| Seeders | X | {list} |

---

## ═══ STEP 5 — EXTRACT TEST CASES (List A Only) ═══

> Skip entirely for List B modules.

Check: `{BROWSER_TESTS}/`, `{FEATURE_TESTS}/`, `{UNIT_TESTS}/`, `{MODULE_TESTS}/`

### 5A — For each test file: path, type, test method names, coverage summary
### 5B — Map tests to RBS features (which features are covered / not covered)
### 5C — Build test coverage matrix

---

## ═══ STEP 6 — SYNTHESIZE: BUILD THE V2 REQUIREMENT DOCUMENT ═══

### For List A (Developed) — V2 Synthesis Rules:
1. **RBS v4.0 is PRIMARY** — every Feature/Task/Sub-Task MUST appear in V2
2. **V1 Requirement is the baseline** — retain all valid V1 content, improve and expand
3. **Gap Analysis is mandatory input** — every confirmed gap → concrete ❌ requirement
4. **Code fills implementation details** — mark status ✅/🟡/❌
5. **DB Schema defines data model** — capture existing entities + schema gaps
6. **AI Brain provides domain rules** — business constraints
7. **Tests validate coverage** — map existing tests, identify gaps
8. **V2 must be MORE COMPLETE than V1** — no regressions in coverage

### For List B (Undeveloped) — V2 Synthesis Rules:
1. **RBS v4.0 is the ONLY functional source** — extract every Feature/Task/Sub-Task
2. **V1 Requirement is the baseline** — V2 must expand on V1's data model + API proposals
3. **All features are ❌ Not Started** — but produce complete specifications
4. **PROPOSE complete data model** — improve on V1's proposed schema using new RBS v4.0 details
5. **PROPOSE complete API routes** — expand/refine V1's proposed routes
6. **PROPOSE complete UI screens** — expand/refine V1's proposed screens
7. **PROPOSE complete test plan** — expand/refine V1's proposed tests
8. **AI Brain conventions** — tenancy rules, naming conventions
9. **Mark proposed items with 📐**

---

## ═══ STEP 7 — CROSS-MODULE DEPENDENCY ANALYSIS ═══

### 7A — Modules THIS Module Depends On
| Dependency Module | Type | What It Needs | Tables/Models Referenced |
|-------------------|------|---------------|--------------------------|

### 7B — Modules That Depend on THIS Module
| Dependent Module | What It Uses |
|------------------|-------------|

### 7C — Changes from V1 Dependencies
List any new dependencies identified in V2 that were missing in V1.

---

## ═══ STEP 8 — QUALITY CHECKLIST ═══

- [ ] Every RBS v4.0 Feature (F.XX.X) captured as a Functional Requirement
- [ ] Every confirmed gap from Gap Analysis is a ❌ requirement in Section 4
- [ ] V2 has at least as many FRs as V1 (no regressions)
- [ ] Data model covers all entities (existing or proposed)
- [ ] API endpoints cover all CRUD + custom operations
- [ ] UI screens match RBS v4.0 screen definitions
- [ ] Test scenarios exist for every feature
- [ ] Cross-module dependencies mapped
- [ ] Non-functional requirements specified
- [ ] Section 14: suggestions only (no facts)
- [ ] Section 16: V1→V2 delta clearly documented

**Additional checks for List B:**
- [ ] Every proposed table follows naming conventions (prefix + snake_case)
- [ ] Every proposed table has standard audit columns
- [ ] Every proposed FK references existing or proposed table
- [ ] Proposed routes follow `{module-kebab}.{resource}.{action}` naming
- [ ] Proposed data model supports ALL RBS v4.0 features
- [ ] Implementation prerequisites listed

---

## ═══ STEP 9 — V1 TO V2 DELTA ANALYSIS ═══

Compare the V2 document you are producing to the V1 baseline read in Step 2B.

### 9A — Feature Count Delta
| Category | V1 Count | V2 Count | New in V2 | Removed from V2 | Changed in V2 |
|----------|---------|---------|-----------|-----------------|---------------|
| Functionalities | X | X | X | X | X |
| Tasks | X | X | X | X | X |
| Sub-Tasks | X | X | X | X | X |
| Entities | X | X | X | X | X |
| API Endpoints | X | X | X | X | X |
| UI Screens | X | X | X | X | X |

### 9B — Gap Coverage
| Gap Category | Gaps in Analysis | Gaps Now in V2 as ❌ | Gaps Resolved (✅/🟡) |
|-------------|-----------------|---------------------|----------------------|

### 9C — RBS v4.0 New Content
List features/screens/tasks that are NEW in RBS v4.0 (not present in v2.0).

---

## ═══ OUTPUT — V2 MODULE REQUIREMENT DOCUMENT TEMPLATE ═══

Write to: **`{OUTPUT_DIR}/{MODULE_CODE}_{MODULE_NAME}_Requirement.md`**

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
{What this module does — from RBS v4.0 + AI Brain domain knowledge}

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
| API Endpoints (Routes) | X | X | +X |
| UI Screens / Tabs | X | X | +X |
| Existing Controllers | X | X | — |
| Existing Models | X | X | — |
| Existing Tests | X | X | — |
| Cross-Module Dependencies | X | X | +X |
| Gaps from Gap Analysis | — | X | NEW |

### 1.4 Implementation Status
| Status | Feature Count | Percentage |
|--------|--------------|------------|
| ✅ Implemented | X | X% |
| 🟡 Partial | X | X% |
| ❌ Not Started | X | X% |
| **Total** | **X** | **100%** |

### 1.5 Gap Analysis Summary (List A only)
| Gap Category | Total Gaps | Incorporated in V2 | Coverage |
|-------------|-----------|---------------------|----------|
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
{Detailed description from RBS v4.0 + AI Brain school-domain.md}

### 2.2 Key Features Summary
| # | Feature Area | Description | RBS Ref | Status | V1 Status |
|---|-------------|-------------|---------|--------|-----------|
| 1 | {feature} | {desc} | F.XX.X | ✅/🟡/❌ | ✅/🟡/❌ |

### 2.3 Menu Navigation Path
{All menu paths from RBS v4.0}

### 2.4 Module Architecture
**For List A (Developed):**
```
{Actual folder structure from MODULE_PATH}
```

**For List B (Undeveloped) — 📐 PROPOSED Structure:**
```
Modules/{MODULE_NAME}/
├── app/
│   ├── Http/
│   │   ├── Controllers/     → 📐 {proposed controllers}
│   │   └── Requests/        → 📐 {proposed form requests}
│   ├── Models/              → 📐 {proposed models}
│   ├── Services/            → 📐 {proposed services}
│   ├── Policies/            → 📐 {proposed policies}
│   ├── Jobs/                → 📐 {proposed jobs}
│   ├── Events/              → 📐 {proposed events}
│   └── Providers/
├── database/
│   └── seeders/
├── resources/
│   └── views/
├── routes/
│   ├── web.php
│   └── api.php
├── tests/
├── module.json
└── composer.json
```

---

## 3. STAKEHOLDERS & ACTORS

| # | Actor | Role | Access Level | Screens |
|---|-------|------|-------------|---------|
| 1 | Super Admin | Platform administrator | Full | All |
| 2 | School Admin | Tenant administrator | Module scope | {list} |
| 3 | Teacher | Staff user | Assigned scope | {list} |
| 4 | Student | End user | Own data | {list} |
| 5 | Parent | Guardian user | Child data | {list} |
| 6 | System | Scheduler/background job | — | — |

---

## 4. FUNCTIONAL REQUIREMENTS

> **Source:** RBS v4.0 (primary) + Gap Analysis (confirmed gaps) + Code (List A) + AI Brain

### FR-{MODULE_CODE}-001: {Functionality Name} (F.XX.X)

**RBS Reference:** F.XX.X  |  **Priority:** 🔴 Critical / 🟡 High / 🟢 Medium / ⚪ Low
**Status:** ✅ Implemented / 🟡 Partial / ❌ Not Started
**V1 Status:** ✅ / 🟡 / ❌  |  **Gap Analysis:** ⚠️ Confirmed Gap / ✅ No Gap
**Owner Screen:** {Screen/Tab from RBS v4.0}
**Table(s):** `{existing table}` or `📐 Proposed: {prefix}_{table_name}`

#### Description
{From RBS v4.0 + domain knowledge. Note any expansion from V1.}

#### Requirements

**REQ-{MODULE_CODE}-001.1: {Task Name} (T.XX.X.X)**
| Attribute | Detail |
|-----------|--------|
| Description | {task description from RBS v4.0} |
| Actors | {roles} |
| Preconditions | {what must exist} |
| Trigger | {user action / system event} |
| Input | {form fields / parameters} |
| Processing | {business logic steps} |
| Output | {success result} |
| Error Handling | {failure scenarios} |
| V1 Status | ✅ / 🟡 / ❌ / NEW in V2 |
| Gap Reference | {gap ID if from gap analysis, else "—"} |

**Acceptance Criteria:**
- [ ] `ST.XX.X.X.1` — {sub-task} → **Status:** ✅/❌
- [ ] `ST.XX.X.X.2` — {sub-task} → **Status:** ✅/❌

**Current Implementation (List A only):**
| Layer | File | Method | Notes |
|-------|------|--------|-------|

**📐 Proposed Implementation (List B only):**
| Layer | Proposed File | Proposed Method | Responsibility |
|-------|-------------|-----------------|----------------|

**Required Test Cases:**
| # | Scenario | Type | Status | Priority |
|---|---------|------|--------|----------|

---

> Repeat for EVERY Functionality in RBS v4.0 for this module.
> Include ALL gaps from Gap Analysis as ❌ FR entries with Gap Reference.

---

## 5. DATA MODEL & ENTITY SPECIFICATION

### 5.1 Entity Overview
| # | Entity (Table) | Status | Purpose | Cols | FKs | Indexes | Prefix | V1 Status |
|---|----------------|--------|---------|------|-----|---------|--------|-----------|
| 1 | {table} | ✅/📐 | {purpose} | X | X | X | {prefix} | ✅/📐/NEW |

### 5.2 Detailed Entity Specification

#### ENTITY: {prefix}_{table_name}  [✅ Existing / 📐 Proposed / 🆕 New in V2]

**Purpose:** {what this table stores}
**Model Class:** `Modules\{MODULE_NAME}\Models\{ModelName}`

##### Columns
| # | Column | Data Type | Nullable | Default | Constraints | Business Rule |
|---|--------|-----------|----------|---------|-------------|--------------|
| 1 | id | BIGINT UNSIGNED | NO | AI | PK | — |
| N | is_active | TINYINT(1) | NO | 1 | — | Soft visibility |
| N+1 | created_by | BIGINT UNSIGNED | YES | NULL | FK → sys_users(id) | Audit |
| N+2 | created_at | TIMESTAMP | YES | NULL | — | Audit |
| N+3 | updated_at | TIMESTAMP | YES | NULL | — | Audit |
| N+4 | deleted_at | TIMESTAMP | YES | NULL | — | Soft delete |

##### Foreign Keys
| FK Column | References | On Delete | On Update |

##### Indexes
| Index Name | Column(s) | Type | Purpose |

##### ENUM Definitions
| Column | Values | Default | Meaning |

##### JSON Column Structures
| Column | Structure | Example |

##### Model Specification
| Attribute | Value |
|-----------|-------|
| $table | `{prefix}_{name}` |
| $fillable | `[...]` |
| $casts | `[...]` |
| Traits | SoftDeletes, HasFactory |
| Scopes | scopeActive() |

##### Relationships
| Method | Type | Related Model | FK | Notes |

---

### 5.3 Entity Relationship Summary
```
{table_a} 1 ──── * {table_b}  (via {fk})
{table_c} * ──── * {table_d}  (via {jnt})
```

### 5.4 Schema Reconciliation Notes (List A only)
| Issue | Source (DDL/Mig/Code) | Details | Resolution |

### 5.5 Schema Gaps from Gap Analysis (List A only)
| Gap | Description | V2 Resolution | Migration Needed |
|-----|-------------|---------------|-----------------|

### 5.6 📐 Proposed Migration Order (List B only)
| # | Migration File Name | Table | Depends On |
|---|---------------------|-------|-----------|

---

## 6. API & ROUTE SPECIFICATION

### 6.1 Route Summary
| # | Method | URI | Controller@Method | Route Name | Middleware | Status | V1 Status |
|---|--------|-----|-------------------|------------|------------|--------|-----------|

### 6.2 Detailed Endpoint Specification
For each endpoint:
- **Request:** Method, URI, Path Params, Query Params, Body (JSON schema)
- **Response:** HTTP code, success payload, error payload
- **Business Rules:** applied during processing
- **Authorization:** policy/gate checks

### 6.3 API Gaps from Gap Analysis (List A only)
| Missing Endpoint | Feature Ref | Priority | V2 Proposed Route |
|-----------------|------------|----------|-------------------|

### 6.4 📐 Proposed Route Group Structure (List B)
```php
// routes/tenant.php additions for {MODULE_NAME}
Route::middleware(['auth', 'EnsureTenantHasModule:{module-slug}'])
    ->prefix('{module-slug}')
    ->name('{module-slug}.')
    ->group(function () {
        Route::resource('{resource}', {Resource}Controller::class);
        // additional routes
    });
```

---

## 7. UI SCREEN INVENTORY & FIELD MAPPING

### 7.1 Screen Overview
| # | Screen Name | Menu Path | RBS Ref | Status | V1 Status |
|---|------------|-----------|---------|--------|-----------|

### 7.2 Detailed Screen Specification
For each screen:
- **Purpose, route, controller, view file**
- **Fields:** name, type, required, validation, source
- **Actions:** buttons, confirmation dialogs, permissions required
- **Filters / Search:** available filters
- **Table Columns:** for list views (sortable, visible by default)
- **Tabs / Sub-sections**

---

## 8. BUSINESS RULES & DOMAIN CONSTRAINTS

| # | Rule ID | Description | Source | Enforcement Layer |
|---|---------|-------------|--------|-------------------|
| 1 | BR-{CODE}-001 | {rule} | RBS v4.0 / AI Brain | DB / Service / Controller |

---

## 9. WORKFLOW & STATE MACHINE DEFINITIONS

For each workflow / state machine in this module:
- **States:** list all states
- **Transitions:** from_state → event → to_state
- **Guards:** conditions that block transitions
- **Side effects:** emails, notifications, audit logs triggered

---

## 10. NON-FUNCTIONAL REQUIREMENTS

| # | Category | Requirement | Priority |
|---|----------|-------------|----------|
| 1 | Performance | Page load < 2s for list views (≤500 records) | 🔴 |
| 2 | Security | Tenant isolation — no cross-tenant data leakage | 🔴 |
| 3 | Security | All routes require auth + EnsureTenantHasModule | 🔴 |
| 4 | Scalability | Supports 1,000 concurrent tenant users | 🟡 |
| 5 | Audit | All create/update/delete → sys_activity_logs | 🟡 |
| 6 | Localization | Multi-language support via glb_translations | 🟢 |
| 7 | Soft Delete | All records use deleted_at, not hard delete | 🔴 |
| 8 | Accessibility | WCAG 2.1 AA compliance for forms | 🟢 |

---

## 11. CROSS-MODULE DEPENDENCIES

### 11.1 This Module Depends On
| # | Module | MODULE_CODE | Status | Dependency Type | What It Needs |
|---|--------|-------------|--------|----------------|---------------|

### 11.2 Modules That Depend on This
| # | Module | MODULE_CODE | Status | What It Uses |
|---|--------|-------------|--------|-------------|

### 11.3 New Dependencies vs V1
| Module | Dependency Type | Reason Added in V2 |
|--------|----------------|-------------------|

### 11.4 Implementation Order Recommendation (List B only)
```
Phase 1 — Can build now (all prerequisites exist):
Phase 2 — After {X module} is ready:
Phase 3 — After multiple modules:
```

---

## 12. TEST CASE REFERENCE & COVERAGE

### 12.1 Existing Tests (List A only)
| # | Test File | Type | Tests | RBS Features Covered |

### 12.2 Test Plan (V2 — Complete)
| # | Test Scenario | Type | Feature Ref | Status (List A) / Proposed (List B) | Priority |
|---|--------------|------|-------------|--------------------------------------|----------|
| 1 | Unauthenticated → 401 | Feature | All | ✅/📐 | 🔴 |
| 2 | Wrong role → 403 | Feature | All | ✅/📐 | 🔴 |
| 3 | Tenant isolation | Feature | All | ✅/📐 | 🔴 |
| 4 | CRUD create → success | Feature | FR-{CODE}-001 | ✅/📐 | 🔴 |
| 5 | Validation failure → errors | Feature | FR-{CODE}-001 | ✅/📐 | 🟡 |
| 6 | Gap scenario: {gap} | Feature | FR-{CODE}-XXX | ❌/📐 | 🔴 |

### 12.3 Coverage Summary
| Category | Required | Existing | Gap | Coverage % |
|----------|---------|----------|-----|------------|

---

## 13. GLOSSARY & TERMINOLOGY

| Term | Definition | Context |
|------|-----------|---------|

---

## 14. ADDITIONAL SUGGESTIONS

> **IMPORTANT:** Section 14 is Claude's recommendations only. NOT from RBS, code, or gap analysis.

### 14.1 Feature Enhancement Suggestions
| # | Suggestion | Rationale | Impact | Effort |

### 14.2 Technical Improvement Suggestions
| # | Suggestion | Rationale | Impact | Effort |

### 14.3 UX/UI Improvement Suggestions
| # | Suggestion | Rationale | Impact | Effort |

### 14.4 Integration Opportunities
| # | Integration | With Module | Benefit | Effort |

### 14.5 Indian Education Domain Suggestions (NEP 2020)
| # | NEP Requirement | How This Module Can Address It | Priority |

---

## 15. APPENDICES

### Appendix A — Full RBS v4.0 Extract (this module)
### Appendix B — Complete Route Table (existing or proposed)
### Appendix C — Complete Code Inventory (List A) or Proposed File List (List B)
### Appendix D — Test Listing (existing or proposed)
### Appendix E — Entity-Relationship Mapping
### Appendix F — AI Brain References Used
### Appendix G — Gap Analysis Source (if applicable)

---

## 16. V1 → V2 DELTA SUMMARY

### 16.1 Feature Count Changes
| Category | V1 Count | V2 Count | Delta | Reason |
|----------|---------|---------|-------|--------|
| Functionalities | X | X | +X | {new in RBS v4.0 / gaps added} |
| Tasks | X | X | +X | |
| Sub-Tasks | X | X | +X | |
| Entities (tables) | X | X | +X | |
| API Endpoints | X | X | +X | |
| UI Screens | X | X | +X | |

### 16.2 New in V2 (not in V1)
- FR items added from RBS v4.0 new content
- FR items added from confirmed Gap Analysis gaps
- New proposed entities
- New proposed endpoints
- New proposed screens

### 16.3 Improved in V2
- Items that existed in V1 but with more detail/accuracy in V2

### 16.4 Gaps Now Addressed
| Gap | Severity | V1 Status | V2 Status |
|-----|---------|-----------|-----------|

### 16.5 V1 → V2 Quality Score
| Dimension | V1 | V2 | Improvement |
|-----------|----|----|------------|
| RBS Coverage | X% | X% | +X% |
| Gap Incorporation | 0% | X% | +X% |
| Data Model Completeness | X% | X% | +X% |
| API Completeness | X% | X% | +X% |
| Test Plan Coverage | X% | X% | +X% |
```

---

## ▶ ANALYSIS RULES — READ BEFORE STARTING

### Rules for ALL Modules:
1. **RBS v4.0 is authoritative** — every Feature/Task/Sub-Task MUST appear.
2. **V1 is the baseline** — V2 must always be MORE complete than V1. Never drop coverage.
3. **Gaps are requirements** — every confirmed gap from the Gap Analysis → ❌ FR item in Section 4.
4. **Be specific** — every requirement has clear, testable acceptance criteria.
5. **No hallucination** — if a file doesn't exist, say it's missing (List A) or mark 📐 (List B).
6. **Separate facts from suggestions** — Sections 1–13, 15–16 from sources. Section 14 = suggestions only.
7. **Think downstream** — every section usable for DDL generation, API spec, test, wireframe, sprint tasks.
8. **Tenancy awareness** — always capture tenancy scope and isolation requirements.
9. **Convention compliance** — use AI Brain naming conventions for all proposed entities.
10. **Count everything** — summary tables must have accurate counts with V1 delta column.
11. **Mark status** — ✅ Implemented / 🟡 Partial / ❌ Not Started / 📐 Proposed / 🆕 New in V2.
12. **Cross-reference constantly** — RBS v4.0 ↔ V1 ↔ Gap Analysis ↔ Code ↔ DB ↔ Tests.

### Additional Rules for List A (Developed) Modules:
13. **Open every file** — read actual code, don't guess.
14. **Check the real DB** — cross-reference DDL, not just model definitions.
15. **No false positives** — only report implemented features you have confirmed in code.
16. **ALL gap analysis gaps must appear** — as ❌ FR items with gap reference and severity.

### Additional Rules for List B (Undeveloped) Modules:
17. **DO NOT produce thin documents** — V2 greenfield specs must expand on V1.
18. **PROPOSE complete data models** — improve on V1's proposed tables using RBS v4.0 detail.
19. **PROPOSE complete API** — expand V1's proposed routes.
20. **PROPOSE complete screens** — expand V1's proposed UI specs.
21. **PROPOSE complete tests** — expand V1's proposed test scenarios.
22. **Follow existing patterns** — look at how developed modules are structured.
23. **Use PROPOSED_TABLE_PREFIX** — all proposed table names must use the prefix from List B.
24. **Mark EVERYTHING as 📐 Proposed** — never imply something exists when it doesn't.
25. **List implementation prerequisites** — which existing modules must be ready first.

---
