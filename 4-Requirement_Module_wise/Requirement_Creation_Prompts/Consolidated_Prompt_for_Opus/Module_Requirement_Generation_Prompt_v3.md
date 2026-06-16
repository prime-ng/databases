# ╔════════════════════════════════════════════════════════════════════════╗
# ║   MODULE REQUIREMENT DOCUMENT — BATCH GENERATION PROMPT v2             ║
# ║   Prime-AI Academic Intelligence Platform                              ║
# ║   Covers ALL modules: Developed (codebase) + Undeveloped (RBS-only)    ║
# ╚════════════════════════════════════════════════════════════════════════╝
#
# HOW TO USE:
#   1. Change only below 2 lines : APP_BRANCH, DATE
#   2. No need to change any Path — Everything will derive automatically
#   3. Copy entire file → Paste it into Claude Code
#   4. Claude will iterate through ALL modules in BOTH lists below,
#      gather all available inputs, and write a comprehensive Requirement
#      Document per module into {OUTPUT_DIR}.
#
# WHAT'S NEW in v2:
#   - Added LIST B: 16 undeveloped modules that exist ONLY in RBS
#   - Each undeveloped module has a 3-char MODULE_CODE for table prefix
#   - Prompt handles TWO processing modes:
#       Mode A (Developed)   → RBS + Code + DDL + Tests + AI Brain
#       Mode B (Undeveloped) → RBS + AI Brain ONLY (no code/DDL/tests)
#   - Output filenames use MODULE_CODE prefix: e.g., ADM_Admission_Requirement.md
# ═════════════════════════════════════════════════════════════════════════

---

## List of Modules

### ━━━ LIST A — DEVELOPED MODULES (Code + DDL + Tests exist) ━━━

> **Processing Mode:** FULL — Read RBS + Code + DDL + Migrations + Tests + AI Brain

| # | MODULE_NAME | MODULE_CODE | MODULE_TYPE | DATABASE_FILE (auto-resolved) | RBS_MODULE_REF |
|---|-------------|-------------|-------------|-------------------------------|----------------|
| 1 | Billing | BIL | Prime | {PRIME_DDL} | Module V (partial) |
| 2 | Complaint | CMP | Tenant | {TENANT_DDL} | Module D (partial) |
| 3 | Dashboard | DSH | Other | — (No DDL) | — (Cross-module) |
| 4 | Documentation | DOC | Other | — (No DDL) | — (Internal) |
| 5 | GlobalMaster | GLB | Global | {GLOBAL_DDL} | Module A (partial) |
| 6 | Hpc | HPC | Tenant | {TENANT_DDL} | Module I (partial) |
| 7 | Library | LIB | Tenant | {TENANT_DDL} | Module M (partial) |
| 8 | LmsExam | EXM | Tenant | {TENANT_DDL} | Module S (partial) |
| 9 | LmsHomework | HMW | Tenant | {TENANT_DDL} | Module S (partial) |
| 10 | LmsQuests | QST | Tenant | {TENANT_DDL} | Module S (partial) |
| 11 | LmsQuiz | QUZ | Tenant | {TENANT_DDL} | Module S (partial) |
| 12 | Notification | NTF | Tenant | {TENANT_DDL} | Module Q (partial) |
| 13 | Payment | PAY | Tenant | {TENANT_DDL} | Module J (partial) |
| 14 | Prime | PRM | Prime | {PRIME_DDL} | Module A (partial) |
| 15 | QuestionBank | QNS | Tenant | {TENANT_DDL} | Module I (partial) |
| 16 | Recommendation | REC | Tenant | {TENANT_DDL} | Module U (partial) |
| 17 | Scheduler | SCH_JOB | Other | — (No DDL) | Module SYS (partial) |
| 18 | SchoolSetup | SCH | Tenant | {TENANT_DDL} | Module A (partial), H (partial) |
| 19 | SmartTimetable | STT | Tenant | {TENANT_DDL} | Module G (partial) |
| 20 | StandardTimetable | TTS | Tenant | {TENANT_DDL} | Module G (partial) |
| 21 | StudentFee | FIN | Tenant | {TENANT_DDL} | Module J (partial) |
| 22 | StudentPortal | STP | Tenant | {TENANT_DDL} | Module E (partial), Z (partial) |
| 23 | StudentProfile | STD | Tenant | {TENANT_DDL} | Module C (partial), E (partial) |
| 24 | Syllabus | SLB | Tenant | {TENANT_DDL} | Module H (partial) |
| 25 | SyllabusBooks | SLK | Prime | {PRIME_DDL} | Module H (partial) |
| 26 | SystemConfig | SYS | Prime | {PRIME_DDL} | Module A (partial), SYS |
| 27 | TimetableFoundation | TTF | Prime | {PRIME_DDL} | Module G (partial) |
| 28 | Transport | TPT | Tenant | {TENANT_DDL} | Module N (partial) |
| 29 | Vendor | VND | Tenant | {TENANT_DDL} | Module K (partial) |

---

### ━━━ LIST B — UNDEVELOPED MODULES (RBS-only, No code exists yet) ━━━

> **Processing Mode:** RBS-ONLY — Read RBS + AI Brain. No code, DDL, migrations, or tests to read.
> These modules exist in the RBS document but have NO corresponding Laravel module, DDL, or test files.
> Claude will generate a **greenfield requirement** spec based purely on RBS features + domain knowledge.

| # | MODULE_NAME | MODULE_CODE | PROPOSED_TYPE | PROPOSED_TABLE_PREFIX | RBS_MODULE_REF | RBS Sub-Tasks |
|---|-------------|-------------|---------------|----------------------|----------------|---------------|
| 30 | Admission | ADM | Tenant | `adm_*` | Module C — Admissions & Student Lifecycle | 56 |
| 31 | FrontOffice | FOF | Tenant | `fof_*` | Module D — Front Office & Communication | 31 |
| 32 | Attendance | ATT | Tenant | `att_*` | Module F — Attendance Management | 34 |
| 33 | Academics | ACD | Tenant | `acd_*` | Module H — Academics Management | 54 |
| 34 | Examination | EXA | Tenant | `exa_*` | Module I — Examination & Gradebook | 46 |
| 35 | FinanceAccounting | FAC | Tenant | `fac_*` | Module K — Finance & Accounting | 70 |
| 36 | Inventory | INV | Tenant | `inv_*` | Module L — Inventory & Stock Management | 50 |
| 37 | Hostel | HST | Tenant | `hst_*` | Module O — Hostel Management | 36 |
| 38 | HrStaff | HRS | Tenant | `hrs_*` | Module P — HR & Staff Management | 46 |
| 39 | Communication | COM | Tenant | `com_*` | Module Q — Communication & Messaging | 44 |
| 40 | Certificate | CRT | Tenant | `crt_*` | Module R — Certificates & Identity Management | 52 |
| 41 | Lxp | LXP | Tenant | `lxp_*` | Module T — Learner Experience Platform | 47 |
| 42 | PredictiveAnalytics | PAN | Tenant | `pan_*` | Module U — Predictive Analytics & ML Engine | 51 |
| 43 | Cafeteria | CAF | Tenant | `caf_*` | Module W — Cafeteria & Mess Management | 12 |
| 44 | VisitorSecurity | VSM | Tenant | `vsm_*` | Module X — Visitor & Security Management | 12 |
| 45 | Maintenance | MNT | Tenant | `mnt_*` | Module Y — Maintenance & Facility Helpdesk | 12 |
| 46 | ParentPortal | PPT | Tenant | `ppt_*` | Module Z — Parent Portal & Mobile App | 24 |

---

### ━━━ RBS-TO-MODULE CROSS-REFERENCE (How RBS Modules map to Code Modules) ━━━

> Some RBS modules are split across multiple code modules, and some code modules map to
> multiple RBS modules. This table is the authoritative mapping for requirement extraction.

| RBS Module | RBS Ref | Sub-Tasks | Maps to Code Module(s) | Coverage |
|-----------|---------|-----------|----------------------|----------|
| Tenant & System Management | A | 51 | Prime, GlobalMaster, SystemConfig, SchoolSetup | Partial — capture remaining in respective modules |
| User, Roles & Security | B | 52 | SchoolSetup (tenant users), Prime (prime users) | Partial — RBAC features split across modules |
| Admissions & Student Lifecycle | C | 56 | StudentProfile (partial) + **Admission (NEW)** | Most features undeveloped |
| Front Office & Communication | D | 31 | Complaint (partial) + **FrontOffice (NEW)** | Most features undeveloped |
| Student Information System | E | 35 | StudentProfile, StudentPortal | Partial |
| Attendance Management | F | 34 | **Attendance (NEW)** | Not developed |
| Advanced Timetable Management | G | 47 | SmartTimetable, StandardTimetable, TimetableFoundation | Partial |
| Academics Management | H | 54 | SchoolSetup (partial), Syllabus, SyllabusBooks + **Academics (NEW)** | Partial |
| Examination & Gradebook | I | 46 | Hpc, QuestionBank + **Examination (NEW)** | Partial |
| Fees & Finance Management | J | 57 | StudentFee, Payment | Partial |
| Finance & Accounting | K | 70 | Vendor (partial) + **FinanceAccounting (NEW)** | Mostly undeveloped |
| Inventory & Stock Management | L | 50 | **Inventory (NEW)** | Not developed |
| Library Management | M | 37 | Library | Partial |
| Transport Management | N | 37 | Transport | Partial |
| Hostel Management | O | 36 | **Hostel (NEW)** | Not developed |
| HR & Staff Management | P | 46 | **HrStaff (NEW)** | Not developed |
| Communication & Messaging | Q | 44 | Notification (partial) + **Communication (NEW)** | Partial |
| Certificates & Identity | R | 52 | **Certificate (NEW)** | Not developed |
| Learning Management System | S | 53 | LmsExam, LmsHomework, LmsQuests, LmsQuiz | Partial |
| System Administration | SYS | 12 | SystemConfig, Scheduler | Partial |
| Learner Experience Platform | T | 47 | **Lxp (NEW)** | Not developed |
| Predictive Analytics & ML | U | 51 | Recommendation (partial) + **PredictiveAnalytics (NEW)** | Mostly undeveloped |
| SaaS Billing & Subscription | V | 54 | Billing | Partial |
| Cafeteria & Mess | W | 12 | **Cafeteria (NEW)** | Not developed |
| Visitor & Security | X | 12 | **VisitorSecurity (NEW)** | Not developed |
| Maintenance & Facility | Y | 12 | **Maintenance (NEW)** | Not developed |
| Parent Portal & Mobile App | Z | 24 | StudentPortal (partial) + **ParentPortal (NEW)** | Mostly undeveloped |

---

## ▶ GLOBAL VARIABLES (set once, apply to all modules):

```
APP_REPO       = prime_ai_tarun
APP_BRANCH     = Brijesh_SmartTimetable
DATE           = 2026-03-24
```

---

## ▶ BATCH EXECUTION INSTRUCTIONS

### Processing Order
1. **First:** Process all LIST A modules (1–29) — these have code + DDL + tests.
2. **Then:** Process all LIST B modules (30–46) — these are RBS-only greenfield specs.

### For EACH module (from either list), do the following:

1. Set the current module's variables:
   ```
   MODULE_NAME    = {current module from the list}
   MODULE_CODE    = {3-char code from the list}
   MODULE_TYPE    = {corresponding MODULE_TYPE / PROPOSED_TYPE from the list}
   DATABASE_FILE  = {resolved based on MODULE_TYPE — see CONFIGURATION section}
   PROCESSING_MODE = "FULL" (List A) or "RBS_ONLY" (List B)
   RBS_MODULE_REF = {which RBS Module section(s) to extract from}
   ```

2. Execute the appropriate **analysis steps** based on PROCESSING_MODE:
   - **FULL (List A):** Steps 0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → OUTPUT
   - **RBS_ONLY (List B):** Steps 0 → 1 → 2 → (SKIP 3,4,5) → 6 → 7 → 8 → OUTPUT

3. Write the output document to a **separate file** using MODULE_CODE prefix:
   ```
   {OUTPUT_DIR}/{MODULE_CODE}_{MODULE_NAME}_Requirement.md
   ```
   Examples:
   - List A: `{OUTPUT_DIR}/HPC_Hpc_Requirement.md`
   - List B: `{OUTPUT_DIR}/ADM_Admission_Requirement.md`
   - List B: `{OUTPUT_DIR}/INV_Inventory_Requirement.md`

4. After writing the file, print a one-line status:
   ```
   ✅ [{current #}/46] {MODULE_CODE}_{MODULE_NAME} — Requirement Document complete [{PROCESSING_MODE}] → {output file path}
   ```

5. Move to the **next module** in the list and repeat from step 1.

6. After ALL 46 modules are done, write THREE summary files:

   **a) Master Requirement Index:**
   ```
   {OUTPUT_DIR}/_00_Master_Requirement_Index_{DATE}.md
   ```
   Contains:
   - Complete table of all 46 modules with: Module Code, Module Name, Processing Mode, Module Type, RBS Ref, Feature Count, Entity Count, API Endpoint Count, Status (Developed/Undeveloped).
   - Aggregate statistics.

   **b) Cross-Module Dependency Matrix:**
   ```
   {OUTPUT_DIR}/_01_Cross_Module_Dependencies_{DATE}.md
   ```
   Contains:
   - Full NxN dependency matrix (46 × 46).
   - Dependency clusters / groups.
   - Suggested implementation order based on dependencies.

   **c) RBS Coverage Report:**
   ```
   {OUTPUT_DIR}/_02_RBS_Coverage_Report_{DATE}.md
   ```
   Contains:
   - For EVERY RBS Feature (F.XX.X) across all 27 RBS modules: which requirement document captures it, implementation status, and any orphan features not covered by any module.

---

## ▶ ROLE & OBJECTIVE

You are a **Senior Business Analyst + Solution Architect** specializing in Laravel-based multi-tenant SaaS platforms for the education domain.

**Your job:** Read the RBS specification, existing code (where available), DB schemas (where available), test cases (where available), and AI Brain knowledge — then produce an **exhaustive Module Requirement Document** per module that serves as the **single source of truth** for:

- **Design & Architecture** generation (system design, component diagrams, sequence diagrams)
- **DDL / Database Schema** generation (CREATE TABLE scripts, migrations, indexes, constraints)
- **API Specification** generation (OpenAPI / Swagger docs, request/response contracts)
- **Test Case** generation (unit, feature, browser, integration tests)
- **UI/UX Wireframe** generation (screen inventory, field mapping, workflow flows)
- **Sprint Task Breakdown** (developer-ready tasks with acceptance criteria)
- **Deployment Checklist** (environment, config, data seeding requirements)

### TWO Processing Modes:

**Mode A — FULL (List A Developed Modules):**
You have code, DDL, migrations, tests. The requirement captures BOTH what IS built and what SHOULD be built.
Mark every feature as: ✅ Implemented / 🟡 Partial / ❌ Not Started.

**Mode B — RBS_ONLY (List B Undeveloped Modules):**
You have ONLY the RBS and AI Brain. There is NO code, NO DDL, NO migrations, NO tests.
The requirement is a **greenfield specification** — everything is ❌ Not Started.
You MUST still produce complete data model proposals, API proposals, screen specs, and test scenarios.
Use the PROPOSED_TABLE_PREFIX and PROPOSED_TYPE from LIST B for all entity naming.

**CRITICAL:** For undeveloped modules, DO NOT say "no code found" and produce a thin document.
These greenfield specs should be EQUALLY detailed as developed module specs — propose complete
entity structures, API designs, screen layouts, and business rules based on the RBS + domain knowledge.

---

## ═══ STEP 0 — LOAD DEFAULT PATHS & CONFIGURATION ═══

### DEFAULT PATHS
Read "/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/config/paths.md"

### Rules
- If any Path is missing in `paths.md` then find that in `CONFIGURATION` section below.
- If any variable exists at both places, in `paths.md` & in `CONFIGURATION` section also, then consider `CONFIGURATION` section Variable.

---

### CONFIGURATION
```
DB_REPO         = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase
OLD_REPO        = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases
AI_BRAIN        = {OLD_REPO}/AI_Brain
RBS_FILE        = {OLD_REPO}/3-Project_Planning/1-RBS/PrimeAI_RBS_Menu_Mapping_v2.0.md
MODULE_PATH     = {LARAVEL_REPO}/Modules/{MODULE_NAME}
BROWSER_TESTS   = {LARAVEL_REPO}/tests/Browser/Modules/{MODULE_NAME}
FEATURE_TESTS   = {LARAVEL_REPO}/tests/Feature/{MODULE_NAME}
UNIT_TESTS      = {LARAVEL_REPO}/tests/Unit/{MODULE_NAME}
MODULE_TESTS    = {LARAVEL_REPO}/Modules/{MODULE_NAME}/tests
ROUTES_FILE     = {LARAVEL_REPO}/routes/tenant.php
POLICIES_DIR    = {LARAVEL_REPO}/app/Policies
APP_PROVIDERS   = {LARAVEL_REPO}/app/Providers/AppServiceProvider.php
TENANT_MIGS     = {LARAVEL_REPO}/database/migrations/tenant
ACTIVITY_LOG    = {LARAVEL_REPO}/app/Helpers/activityLog.php

OUTPUT_REPO     = {OLD_REPO}
OUTPUT_DIR      = {OUTPUT_REPO}/2-Requirement_Module_wise/2-Detailed_Requirements/Requirement_V1/Development_Done
OUTPUT_DIR_A    = {OUTPUT_REPO}/2-Requirement_Module_wise/2-Detailed_Requirements/Requirement_V1/Development_Pending
```

### DATABASE_FILE Resolution (based on MODULE_TYPE / PROPOSED_TYPE)
```
If MODULE_TYPE = "Tenant"  → DATABASE_FILE = {TENANT_DDL}
If MODULE_TYPE = "Prime"   → DATABASE_FILE = {PRIME_DDL}
If MODULE_TYPE = "Global"  → DATABASE_FILE = {GLOBAL_DDL}
If MODULE_TYPE = "Other"   → DATABASE_FILE = NONE (skip DDL-related sections)
```

### Table Prefix Resolution

#### List A — Developed Module Prefixes (existing in DDL)
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

#### List B — Undeveloped Module Prefixes (PROPOSED — no DDL exists yet)
| Module | MODULE_CODE | Proposed Table Prefix | Proposed DB |
|--------|-------------|----------------------|-------------|
| Admission | ADM | `adm_*` | tenant_db |
| FrontOffice | FOF | `fof_*` | tenant_db |
| Attendance | ATT | `att_*` | tenant_db |
| Academics | ACD | `acd_*` | tenant_db |
| Examination | EXA | `exa_*` | tenant_db |
| FinanceAccounting | FAC | `fac_*` | tenant_db |
| Inventory | INV | `inv_*` | tenant_db |
| Hostel | HST | `hst_*` | tenant_db |
| HrStaff | HRS | `hrs_*` | tenant_db |
| Communication | COM | `com_*` | tenant_db |
| Certificate | CRT | `crt_*` | tenant_db |
| Lxp | LXP | `lxp_*` | tenant_db |
| PredictiveAnalytics | PAN | `pan_*` | tenant_db |
| Cafeteria | CAF | `caf_*` | tenant_db |
| VisitorSecurity | VSM | `vsm_*` | tenant_db |
| Maintenance | MNT | `mnt_*` | tenant_db |
| ParentPortal | PPT | `ppt_*` | tenant_db |

---

## ═══ STEP 1 — LOAD AI BRAIN CONTEXT (Read ONCE, Retain for All Modules) ═══

> These files define the project's architectural rules, domain knowledge, conventions, and current state.
> **Read these ONCE for the first module. Retain this context for all 46 modules.**

### 1A — Core Memory Files
| # | File | Extract What |
|---|------|-------------|
| 1 | `{AI_BRAIN}/memory/project-context.md` | Tech stack, external services, key workflows, business goals |
| 2 | `{AI_BRAIN}/memory/tenancy-map.md` | **CRITICAL** — multi-tenancy isolation rules, DB architecture |
| 3 | `{AI_BRAIN}/memory/modules-map.md` | Module inventory, inter-module dependencies, current status |
| 4 | `{AI_BRAIN}/memory/conventions.md` | Naming conventions, code patterns, file structure standards |
| 5 | `{AI_BRAIN}/memory/architecture.md` | System architecture, request flow, middleware pipeline |
| 6 | `{AI_BRAIN}/memory/school-domain.md` | School business domain rules (NEP 2020, Bloom's, sessions) |
| 7 | `{AI_BRAIN}/memory/decisions.md` | All architectural decisions (D1–D20+) and their rationale |
| 8 | `{AI_BRAIN}/state/progress.md` | What is done / in-progress / planned per module |
| 9 | `{AI_BRAIN}/state/decisions.md` | Latest architectural decisions |

### 1B — Rules Files (MANDATORY constraints)
| # | File | Extract What |
|---|------|-------------|
| 10 | `{AI_BRAIN}/rules/tenancy-rules.md` | Tenancy isolation constraints |
| 11 | `{AI_BRAIN}/rules/module-rules.md` | Module development standards |
| 12 | `{AI_BRAIN}/rules/security-rules.md` | Security requirements |
| 13 | `{AI_BRAIN}/rules/laravel-rules.md` | Laravel conventions |
| 14 | `{AI_BRAIN}/rules/code-style.md` | PSR-12, project-specific style |

### 1C — Lessons & Known Issues
| # | File | Extract What |
|---|------|-------------|
| 15 | `{AI_BRAIN}/lessons/known-issues.md` | Known bugs, domain edge cases, gotchas |

**After reading, build a mental model for BOTH developed and undeveloped module specs:**
- Platform architecture, multi-tenant SaaS patterns
- Domain rules (NEP 2020, academic sessions, school hierarchy)
- Security constraints (RBAC, tenant isolation, policies)
- Naming & structural conventions (essential for greenfield module specs)

---

## ═══ STEP 2 — EXTRACT RBS SPECIFICATION FOR MODULE ═══

> **Applies to: BOTH List A and List B modules**

Read `{RBS_FILE}` and extract **ALL entries** belonging to the module's `RBS_MODULE_REF`.

### 2A — For List A (Developed) Modules:
- Extract the RBS section(s) listed in `RBS_MODULE_REF` column
- Map each RBS Feature/Task/Sub-Task to the existing code (will be done in Steps 3–5)
- Some RBS features may be in a DIFFERENT code module — note this as a cross-reference

### 2B — For List B (Undeveloped) Modules:
- Extract the ENTIRE RBS Module section referenced in `RBS_MODULE_REF`
- This is the PRIMARY input — capture every Feature, Task, Sub-Task exhaustively
- Also scan the RBS Part 2 (Tenant App) menu structure for screens belonging to this module

### 2C — Build RBS Summary:
| # | Screen/Tab | Table (if mentioned) | DB | Functionalities | Tasks | Sub-Tasks |
|---|-----------|---------------------|-----|-----------------|-------|-----------|
| 1 | {Screen} | {tbl or "TBD"} | {db} | {count} | {count} | {count} |
| **TOTAL** | | | | **X** | **X** | **X** |

### 2D — Extract Full Feature Hierarchy:
List every Functionality → Task → Sub-Task in hierarchical form.

### 2E — For Undeveloped Modules: Extract Screen Inventory from RBS Menu Structure
Scan Part 2 menu structure for screens that logically belong to this module.
Record each screen's menu path, referenced tables, and associated tasks.

---

## ═══ STEP 3 — EXTRACT DATABASE SCHEMA (Current State) ═══

> **Applies to: List A ONLY** (Skip entirely for List B modules)
> For List B modules: You will PROPOSE a schema in the output (Section 5) based on RBS.

### 3A — Read DDL File
Read `{DATABASE_FILE}` and extract ALL tables matching the module's Table Prefix.

### 3B — For Each Table, Record:
- Table Name, Purpose, All Columns (name, type, nullable, default, constraints)
- Primary Key, Foreign Keys, Indexes, ENUMs, JSON columns, Boolean columns
- Audit columns (created_by, created_at, updated_at, deleted_at)

### 3C — Build Entity Relationship Summary
| Entity | Related To | Relationship Type | FK Column | Junction Table |
|--------|-----------|-------------------|-----------|----------------|

### 3D — Cross-Reference with Migrations
Check `{TENANT_MIGS}/` for schema discrepancies.

---

## ═══ STEP 4 — EXTRACT EXISTING CODEBASE (Current Implementation) ═══

> **Applies to: List A ONLY** (Skip entirely for List B modules)

Read EVERY .php file inside `{MODULE_PATH}/`.

### 4A — Controllers: Class names, public methods, FormRequests, Services, Gates, Views, Routes
### 4B — Models: Table, $fillable, $casts, relationships, scopes, traits
### 4C — Services: Business logic methods, transactions, external integrations
### 4D — Form Requests: Validation rules, authorization
### 4E — Policies: Permission methods, registration status
### 4F — Views: Screens, form fields, data tables, action buttons, filters, tabs
### 4G — Routes: Method, URI, Controller@Method, Route Name, Middleware
### 4H — Jobs, Events, Listeners, Emails
### 4I — Seeders

### 4J — Build Code Inventory Summary
| Layer | Count | Details |
|-------|-------|---------|
| Controllers | X | {list} |
| Models | X | {list} |
| Services | X | {list} |
| FormRequests | X | {list} |
| Policies | X | {list} |
| Views | X | {list} |
| Routes | X | GET: X, POST: X, PUT: X, DELETE: X |
| Jobs | X | {list} |
| Events | X | {list} |
| Migrations | X | {list} |
| Seeders | X | {list} |

---

## ═══ STEP 5 — EXTRACT TEST CASES (Existing Coverage) ═══

> **Applies to: List A ONLY** (Skip entirely for List B modules)

Check: `{BROWSER_TESTS}/`, `{FEATURE_TESTS}/`, `{UNIT_TESTS}/`, `{MODULE_TESTS}/`

### 5A — For each test file: path, type, test method names, coverage summary
### 5B — Map tests to RBS features
### 5C — Build coverage matrix

---

## ═══ STEP 6 — SYNTHESIZE: BUILD THE REQUIREMENT DOCUMENT ═══

> **Applies to: BOTH List A and List B modules**

### For List A (Developed) Modules — Synthesis Rules:
1. **RBS is PRIMARY** — every Feature/Task/Sub-Task from RBS MUST appear
2. **Code fills implementation details** — mark status as ✅/🟡/❌
3. **DB Schema defines data model** — capture existing entities
4. **AI Brain provides domain context** — business rules, constraints
5. **Tests validate coverage** — map existing tests, identify gaps
6. **Suggestions in Section 14 ONLY**

### For List B (Undeveloped) Modules — Synthesis Rules:
1. **RBS is the ONLY functional source** — extract every Feature/Task/Sub-Task
2. **All features are ❌ Not Started** — but still produce full specifications
3. **PROPOSE complete data model** — design tables, columns, FKs, indexes using:
   - The PROPOSED_TABLE_PREFIX from List B
   - Column naming conventions from AI Brain (conventions.md)
   - Standard audit columns: `id`, `is_active`, `created_by`, `created_at`, `updated_at`, `deleted_at`
   - FKs to existing tables where applicable (e.g., `sch_classes.id`, `std_students.id`, `sys_users.id`)
   - Proper prefixed table names for junction tables (ending with `_jnt`)
   - JSON columns (ending with `_json`), boolean columns (prefix `is_` / `has_`)
4. **PROPOSE complete API routes** — design RESTful endpoints following Laravel conventions
5. **PROPOSE UI screens** — design screen specs based on RBS screen descriptions
6. **PROPOSE test scenarios** — design test cases for every feature
7. **AI Brain provides architectural constraints** — tenancy rules, naming conventions
8. **Clearly mark everything as PROPOSED** — use 📐 emoji for proposed items

---

## ═══ STEP 7 — CROSS-MODULE DEPENDENCY ANALYSIS ═══

> **Applies to: BOTH List A and List B modules**

### 7A — Modules THIS Module Depends On
| Dependency Module | Type | What It Needs | Tables/Models Referenced |
|-------------------|------|---------------|--------------------------|

### 7B — Modules That Depend on THIS Module
| Dependent Module | What It Uses |
|------------------|-------------|

### 7C — For Undeveloped Modules: Identify Dependencies on EXISTING Modules
This is critical for implementation planning — which existing modules must be ready
before this new module can be built?

---

## ═══ STEP 8 — QUALITY CHECKLIST ═══

> **Applies to: BOTH List A and List B modules**

- [ ] Every RBS Feature (F.XX.X) is captured as a Functional Requirement
- [ ] Every RBS Task (T.XX.X.X) has acceptance criteria
- [ ] Every RBS Sub-Task (ST.XX.X.X.X) has a testable description
- [ ] Data model covers all entities (existing or proposed)
- [ ] API endpoints cover all CRUD + custom operations
- [ ] UI screens match RBS screen definitions
- [ ] Test scenarios exist for every feature
- [ ] Cross-module dependencies are mapped
- [ ] Non-functional requirements specified
- [ ] Suggestions in Section 14 only

**Additional checks for List B (Undeveloped) modules:**
- [ ] Every proposed table follows naming conventions (prefix + snake_case)
- [ ] Every proposed table has standard audit columns
- [ ] Every proposed FK references an existing or proposed table
- [ ] Proposed routes follow `{module-kebab}.{resource-kebab}.{action}` naming
- [ ] Proposed data model is sufficient to support ALL RBS features
- [ ] Implementation prerequisites (existing modules needed) are listed

---

## ═══ OUTPUT — MODULE REQUIREMENT DOCUMENT TEMPLATE ═══

Write to: **`{OUTPUT_DIR}/{MODULE_CODE}_{MODULE_NAME}_Requirement.md`**

---

```markdown
# {MODULE_NAME} Module — Requirement Specification Document
**Version:** 1.0  |  **Date:** {DATE}  |  **Author:** Claude Code (Automated Extraction)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** {MODULE_CODE}  |  **Module Path:** `{MODULE_PATH or "N/A — New Module"}`
**Module Type:** {MODULE_TYPE}  |  **Database:** {DATABASE_FILE or "Proposed: tenant_db"}
**Table Prefix:** `{TABLE_PREFIX}`  |  **Processing Mode:** {FULL or RBS_ONLY}
**RBS Reference:** {RBS_MODULE_REF}

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

---

## 1. EXECUTIVE SUMMARY

### 1.1 Purpose
{What this module does — from RBS + AI Brain domain knowledge}

### 1.2 Scope
- **In Scope:** {list}
- **Out of Scope:** {list}

### 1.3 Module Statistics
| Metric | Count | Source |
|--------|-------|--------|
| RBS Functionalities (F.XX.X) | X | RBS |
| RBS Tasks (T.XX.X.X) | X | RBS |
| RBS Sub-Tasks (ST.XX.X.X.X) | X | RBS |
| Database Tables | X | DDL (existing) or Proposed |
| API Endpoints (Routes) | X | Routes (existing) or Proposed |
| UI Screens / Tabs | X | Views (existing) or Proposed |
| Existing Controllers | X | Code (0 for List B) |
| Existing Models | X | Code (0 for List B) |
| Existing Tests | X | Tests (0 for List B) |
| Cross-Module Dependencies | X | Analysis |

### 1.4 Implementation Status
| Status | Feature Count | Percentage |
|--------|--------------|------------|
| ✅ Implemented | X | X% |
| 🟡 Partial | X | X% |
| ❌ Not Started | X | X% |
| **Total** | **X** | **100%** |

> **For List B modules:** All features will be ❌ Not Started (0% implemented).

### 1.5 Implementation Prerequisites (List B modules only)
| # | Prerequisite Module | Must Be Ready | Reason |
|---|---------------------|---------------|--------|
| 1 | SchoolSetup | Classes, Sections | {why needed} |
| 2 | StudentProfile | Student records | {why needed} |
| ... | | | |

---

## 2. MODULE OVERVIEW

### 2.1 Business Purpose
{Detailed description from RBS + AI Brain school-domain.md}

### 2.2 Key Features Summary
| # | Feature Area | Description | RBS Ref | Status |
|---|-------------|-------------|---------|--------|
| 1 | {feature} | {desc} | F.XX.X | ✅/🟡/❌ |

### 2.3 Menu Navigation Path
{All menu paths from RBS}

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
│   ├── Listeners/           → 📐 {proposed listeners}
│   └── Providers/
│       ├── {MODULE_NAME}ServiceProvider.php
│       ├── RouteServiceProvider.php
│       └── EventServiceProvider.php
├── database/
│   └── seeders/             → 📐 {proposed seeders}
├── resources/
│   └── views/               → 📐 {proposed view directories}
├── routes/
│   ├── web.php
│   └── api.php
├── tests/
├── module.json
└── composer.json
```

---

## 3. STAKEHOLDERS & ACTORS

{Same structure as v1 — roles, system actors}

---

## 4. FUNCTIONAL REQUIREMENTS

> **Source:** RBS (primary) + Code (List A) + AI Brain (both)

### FR-{MODULE_CODE}-001: {Functionality Name} (F.XX.X)

**RBS Reference:** F.XX.X
**Priority:** 🔴 Critical / 🟡 High / 🟢 Medium / ⚪ Low
**Status:** ✅ Implemented / 🟡 Partial / ❌ Not Started
**Owner Screen:** {Screen/Tab from RBS}
**Table(s):** {existing table or "📐 Proposed: {prefix}_{table_name}"}

#### Description
{From RBS + domain knowledge}

#### Requirements

**REQ-{MODULE_CODE}-001.1: {Task Name} (T.XX.X.X)**
| Attribute | Detail |
|-----------|--------|
| Description | {task description from RBS} |
| Actors | {roles} |
| Preconditions | {what must exist} |
| Trigger | {user action / system event} |
| Input | {form fields / parameters} |
| Processing | {business logic steps} |
| Output | {success result} |
| Error Handling | {failure handling} |
| Status | ✅ / 🟡 / ❌ |

**Acceptance Criteria:**
- [ ] `ST.XX.X.X.1` — {sub-task} → **Status:** ✅/❌
- [ ] `ST.XX.X.X.2` — {sub-task} → **Status:** ✅/❌

**Current Implementation (List A only):**
| Layer | File | Method | Notes |
|-------|------|--------|-------|
| Controller | {name} | {method} | {what it does} |
| ... | | | |

**📐 Proposed Implementation (List B only):**
| Layer | Proposed File | Proposed Method | Responsibility |
|-------|-------------|-----------------|----------------|
| Controller | {MODULE_NAME}{Feature}Controller | index/create/store/edit/update/destroy | CRUD operations |
| Service | {MODULE_NAME}{Feature}Service | {method} | Business logic |
| FormRequest | Store{Entity}Request | rules() | Validation |
| Policy | {Entity}Policy | viewAny/view/create/update/delete | Authorization |
| View | {module-slug}/{feature}/index.blade.php | — | List view |

**Required Test Cases:**
| # | Scenario | Type | Existing (List A) / Proposed (List B) | Priority |
|---|---------|------|---------------------------------------|----------|
| 1 | {scenario} | Feature | ✅/❌ / 📐 | High |

---

> **Repeat for EVERY Functionality in the RBS for this module.**

---

## 5. DATA MODEL & ENTITY SPECIFICATION

### For List A (Developed) — Document EXISTING + MISSING entities
### For List B (Undeveloped) — 📐 PROPOSE COMPLETE data model

### 5.1 Entity Overview
| # | Entity (Table) | Status | Purpose | Columns | FKs | Indexes | Prefix |
|---|----------------|--------|---------|---------|-----|---------|--------|
| 1 | {table} | ✅ Existing / 📐 Proposed | {purpose} | X | X | X | {prefix} |

### 5.2 Detailed Entity Specification

#### ENTITY: {prefix}_{table_name}  [✅ Existing / 📐 Proposed]

**Purpose:** {what this table stores}
**Model Class:** `Modules\{MODULE_NAME}\Models\{ModelName}`

##### Columns
| # | Column | Data Type | Nullable | Default | Constraints | Business Rule |
|---|--------|-----------|----------|---------|-------------|--------------|
| 1 | id | BIGINT UNSIGNED | NO | AI | PK | — |
| 2 | {col} | {type} | {null} | {def} | {FK/UQ/IDX} | {rule} |
| ... | | | | | | |
| N | is_active | TINYINT(1) | NO | 1 | — | Soft visibility |
| N+1 | created_by | BIGINT UNSIGNED | YES | NULL | FK → sys_users(id) | Audit |
| N+2 | created_at | TIMESTAMP | YES | NULL | — | Audit |
| N+3 | updated_at | TIMESTAMP | YES | NULL | — | Audit |
| N+4 | deleted_at | TIMESTAMP | YES | NULL | — | Soft delete |

##### Foreign Keys
| FK Column | References | On Delete | On Update |
|-----------|-----------|-----------|-----------|

##### Indexes
| Index Name | Column(s) | Type | Purpose |
|-----------|-----------|------|---------|

##### ENUM Definitions
| Column | Values | Default | Meaning |
|--------|--------|---------|---------|

##### JSON Column Structures
| Column | Structure | Example |
|--------|----------|---------|

##### Model Specification
| Attribute | Value |
|-----------|-------|
| $table | `{prefix}_{name}` |
| $fillable | `[...]` |
| $casts | `[...]` |
| Traits | SoftDeletes, HasFactory |
| Scopes | scopeActive(), scopeForSession() |

##### Relationships
| Method | Type | Related Model | FK | Notes |
|--------|------|--------------|-----|-------|

---

> **Repeat for EVERY entity (existing + proposed).**

---

### 5.3 Entity Relationship Summary
```
{table_a} 1 ──── * {table_b}  (via {fk})
{table_c} * ──── * {table_d}  (via {jnt})
```

### 5.4 Schema Reconciliation Notes (List A only)
| Issue | Source | Details | Resolution |
|-------|--------|---------|------------|

### 5.5 📐 Proposed Migration Order (List B only)
| # | Migration File Name | Table | Depends On |
|---|---------------------|-------|-----------|
| 1 | `create_{prefix}_{table}_table` | {table} | — |
| 2 | `create_{prefix}_{table}_table` | {table} | Migration #1 |

---

## 6. API & ROUTE SPECIFICATION

### For List A — Document EXISTING + MISSING routes
### For List B — 📐 PROPOSE COMPLETE route structure

### 6.1 Route Summary
| # | Method | URI | Controller@Method | Route Name | Middleware | Status |
|---|--------|-----|-------------------|------------|------------|--------|
| 1 | GET | /{resource} | {Ctrl}@index | {module-slug}.{resource}.index | auth, tenant | ✅/📐 |

### 6.2 Detailed Endpoint Specification
{Same as v1 — request/response/errors for each endpoint}

### 6.3 📐 Proposed Route Group Structure (List B)
```php
// routes/tenant.php additions for {MODULE_NAME}
Route::middleware(['auth', 'EnsureTenantHasModule:{module-slug}'])
    ->prefix('{module-slug}')
    ->name('{module-slug}.')
    ->group(function () {
        Route::resource('{resource}', {Resource}Controller::class);
        // ... additional routes
    });
```

---

## 7. UI SCREEN INVENTORY & FIELD MAPPING
{Same as v1 — existing screens for List A, proposed screens for List B}

---

## 8. BUSINESS RULES & DOMAIN CONSTRAINTS
{Same as v1 — from AI Brain + RBS}

---

## 9. WORKFLOW & STATE MACHINE DEFINITIONS
{Same as v1 — capture from RBS workflow descriptions}

---

## 10. NON-FUNCTIONAL REQUIREMENTS
{Same as v1 — performance, security, scalability, localization, audit}

---

## 11. CROSS-MODULE DEPENDENCIES

### 11.1 This Module Depends On
| # | Module | MODULE_CODE | Status | Dependency Type | What It Needs |
|---|--------|-------------|--------|----------------|---------------|
| 1 | SchoolSetup | SCH | ✅ Developed | Data | Classes, Sections |
| 2 | {module} | {code} | ✅/❌ | {type} | {what} |

### 11.2 Modules That Depend on This
| # | Module | MODULE_CODE | Status | What It Uses |
|---|--------|-------------|--------|-------------|

### 11.3 Implementation Order Recommendation (List B only)
```
Phase 1 (Prerequisites exist): Can build NOW
Phase 2 (After X module is ready): Can build AFTER
Phase 3 (After multiple modules): Requires X, Y, Z first
```

---

## 12. TEST CASE REFERENCE & COVERAGE

### For List A — existing tests + gaps
### For List B — 📐 PROPOSED complete test plan

### 12.1 Existing Tests (List A only)
| # | Test File | Type | Tests | Covers |
|---|-----------|------|-------|--------|

### 12.2 📐 Proposed Test Plan
| # | Test Scenario | Type | Feature Ref | Priority | Test File |
|---|--------------|------|-------------|----------|-----------|
| 1 | Unauthenticated → 401 on all routes | Feature | All | 🔴 | `tests/Feature/{MODULE_NAME}/AuthTest.php` |
| 2 | Wrong role → 403 | Feature | All | 🔴 | `tests/Feature/{MODULE_NAME}/AuthorizationTest.php` |
| 3 | Tenant isolation | Feature | All | 🔴 | `tests/Feature/{MODULE_NAME}/TenantIsolationTest.php` |
| 4 | CRUD create → success | Feature | FR-{CODE}-001 | 🔴 | `tests/Feature/{MODULE_NAME}/{Entity}CrudTest.php` |
| 5 | Validation failure → errors | Feature | FR-{CODE}-001 | 🟡 | `tests/Feature/{MODULE_NAME}/{Entity}ValidationTest.php` |
| ... | | | | | |

### 12.3 Coverage Summary
| Category | Required | Existing | Gap | Coverage % |
|----------|---------|----------|-----|------------|
| Authentication | X | X (0 for List B) | X | X% |
| Authorization | X | X | X | X% |
| CRUD | X | X | X | X% |
| Business Logic | X | X | X | X% |
| **TOTAL** | **X** | **X** | **X** | **X%** |

---

## 13. GLOSSARY & TERMINOLOGY
{Module-specific terms}

---

## 14. ADDITIONAL SUGGESTIONS

> **IMPORTANT:** These are Claude's recommendations. NOT from RBS or existing code.

### 14.1 Feature Enhancement Suggestions
| # | Suggestion | Rationale | Impact | Effort |
|---|-----------|-----------|--------|--------|

### 14.2 Technical Improvement Suggestions
| # | Suggestion | Rationale | Impact | Effort |
|---|-----------|-----------|--------|--------|

### 14.3 UX/UI Improvement Suggestions
| # | Suggestion | Rationale | Impact | Effort |
|---|-----------|-----------|--------|--------|

### 14.4 Integration Opportunities
| # | Integration | With Module | Benefit | Effort |
|---|------------|-------------|---------|--------|

### 14.5 Indian Education Domain Suggestions (NEP 2020)
| # | NEP Requirement | How This Module Can Address It | Priority |
|---|----------------|-------------------------------|----------|

---

## 15. APPENDICES

### Appendix A — Full RBS Extract
### Appendix B — Complete Route Table (existing or proposed)
### Appendix C — Complete Code Inventory (List A) or Proposed File List (List B)
### Appendix D — Test Listing (existing or proposed)
### Appendix E — Entity-Relationship Mapping
### Appendix F — AI Brain References Used
```

---

## ▶ ANALYSIS RULES — READ BEFORE STARTING

### Rules for ALL Modules (List A + List B):
1. **RBS is authoritative** — every Feature/Task/Sub-Task MUST appear in the requirement.
2. **Be specific** — every requirement has clear, testable acceptance criteria.
3. **No hallucination** — if a file doesn't exist, say it's missing (List A) or mark as proposed (List B).
4. **Separate facts from suggestions** — Sections 1–13 from RBS/Code/DB/AI Brain. Section 14 is suggestions only.
5. **Think downstream** — every section must be usable for DDL, API spec, test, wireframe, sprint generation.
6. **Tenancy awareness** — always capture tenancy scope and isolation requirements.
7. **Convention compliance** — use AI Brain naming conventions for ALL proposed entities.
8. **Count everything** — summary tables must have accurate counts.
9. **Mark status** — ✅ Implemented / 🟡 Partial / ❌ Not Started / 📐 Proposed.
10. **Cross-reference constantly** — RBS ↔ Code ↔ DB ↔ Tests.

### Additional Rules for List A (Developed) Modules:
11. **Open every file** — read actual code, don't guess.
12. **Check the real DB** — cross-reference DDL, not just model definitions.
13. **No false positives** — only report existing features you've confirmed in code.

### Additional Rules for List B (Undeveloped) Modules:
14. **DO NOT produce thin documents** — greenfield specs must be equally detailed.
15. **PROPOSE complete data models** — design all tables, columns, FKs, indexes.
16. **PROPOSE complete API** — design all RESTful endpoints.
17. **PROPOSE complete screens** — design all UI specs from RBS screen descriptions.
18. **PROPOSE complete tests** — design test scenarios for every feature.
19. **Follow existing patterns** — look at how developed modules are structured and mirror that pattern.
20. **Use PROPOSED_TABLE_PREFIX** — all proposed table names must use the 3-char prefix from List B.
21. **Mark EVERYTHING as 📐 Proposed** — never imply something exists when it doesn't.
22. **List implementation prerequisites** — which existing modules must be ready first.

---

## ▶ START NOW — EXECUTION ORDER

```
Step 0-A → Read this prompt file → Derive DB_REPO from the path
Step 0-B → Read {DB_REPO}/AI_Brain/config/paths.md
           → Get LARAVEL_REPO, TENANT_DDL, PRIME_DDL, GLOBAL_DDL, AI_BRAIN from there
Step 0-C → Build all derived paths

Step 1   → Read AI Brain (15 files — memory + rules + lessons)
           → Do this ONCE. Retain for all 46 modules.

─── BEGIN LIST A LOOP (Modules 1–29: Developed — FULL mode) ───

  Set MODULE_NAME, MODULE_CODE, MODULE_TYPE, PROCESSING_MODE = "FULL"
  Resolve DATABASE_FILE, RBS_MODULE_REF

  Step 2   → Extract RBS specification for this module
  Step 3   → Extract DB schema (existing tables from DDL)
  Step 4   → Read all code in MODULE_PATH
  Step 5   → Read all test files
  Step 6   → Synthesize requirement document (existing + missing)
  Step 7   → Cross-module dependency analysis
  Step 8   → Quality checklist

  OUTPUT   → Write to: {OUTPUT_DIR}/{MODULE_CODE}_{MODULE_NAME}_Requirement.md
  STATUS   → ✅ [X/46] {MODULE_CODE}_{MODULE_NAME} — complete [FULL]

─── END LIST A LOOP ───

─── BEGIN LIST B LOOP (Modules 30–46: Undeveloped — RBS_ONLY mode) ───

  Set MODULE_NAME, MODULE_CODE, MODULE_TYPE = PROPOSED_TYPE, PROCESSING_MODE = "RBS_ONLY"
  Set TABLE_PREFIX = PROPOSED_TABLE_PREFIX

  Step 2   → Extract FULL RBS Module section
  Step 3   → SKIP (no DDL exists)
  Step 4   → SKIP (no code exists)
  Step 5   → SKIP (no tests exist)
  Step 6   → Synthesize greenfield requirement (RBS + AI Brain + proposed designs)
  Step 7   → Cross-module dependency analysis (focus on prerequisites)
  Step 8   → Quality checklist (including proposed design validation)

  OUTPUT   → Write to: {OUTPUT_DIR_A}/{MODULE_CODE}_{MODULE_NAME}_Requirement.md
  STATUS   → ✅ [X/46] {MODULE_CODE}_{MODULE_NAME} — complete [RBS_ONLY]

─── END LIST B LOOP ───

─── FINAL SUMMARY FILES ───

  SUMMARY 1 → {OUTPUT_DIR}/_00_Master_Requirement_Index_{DATE}.md
              (All 46 modules: code, name, mode, type, RBS ref, counts, links)

  SUMMARY 2 → {OUTPUT_DIR}/_01_Cross_Module_Dependencies_{DATE}.md
              (46×46 dependency matrix, clusters, implementation order)

  SUMMARY 3 → {OUTPUT_DIR}/_02_RBS_Coverage_Report_{DATE}.md
              (Every F.XX.X across all 27 RBS modules → which requirement doc covers it)
```

**Start from Step 0-A. Do not skip any step. Process all 46 modules sequentially. List A first, then List B.**
