# ╔════════════════════════════════════════════════════════════════════════╗
# ║   MODULE REQUIREMENT DOCUMENT — BATCH GENERATION PROMPT              ║
# ║   Prime-AI Academic Intelligence Platform                            ║
# ╚════════════════════════════════════════════════════════════════════════╝
#
# HOW TO USE:
#   1. Change only below 2 lines : APP_BRANCH, DATE
#   2. No need to change any Path — Everything will derive automatically
#   3. Copy entire file → Paste it into Claude Code
#   4. Claude will iterate through ALL modules in the list below,
#      gather all inputs, and write a comprehensive Requirement Document
#      per module into {OUTPUT_DIR}.
# ═════════════════════════════════════════════════════════════════════════

---
## List of Modules

Below is the complete module inventory with their MODULE_TYPE.
Claude will process **every module** in this list, one by one, top to bottom.

| # | MODULE_NAME | MODULE_TYPE | DATABASE_FILE (auto-resolved) |
|---|-------------|-------------|-------------------------------|
| 1 | Billing | Prime | {PRIME_DDL} |
| 2 | Complaint | Tenant | {TENANT_DDL} |
| 3 | Dashboard | Other | — (No DDL) |
| 4 | Documentation | Other | — (No DDL) |
| 5 | GlobalMaster | Global | {GLOBAL_DDL} |
| 6 | Hpc | Tenant | {TENANT_DDL} |
| 7 | Library | Tenant | {TENANT_DDL} |
| 8 | LmsExam | Tenant | {TENANT_DDL} |
| 9 | LmsHomework | Tenant | {TENANT_DDL} |
| 10 | LmsQuests | Tenant | {TENANT_DDL} |
| 11 | LmsQuiz | Tenant | {TENANT_DDL} |
| 12 | Notification | Tenant | {TENANT_DDL} |
| 13 | Payment | Tenant | {TENANT_DDL} |
| 14 | Prime | Prime | {PRIME_DDL} |
| 15 | QuestionBank | Tenant | {TENANT_DDL} |
| 16 | Recommendation | Tenant | {TENANT_DDL} |
| 17 | Scheduler | Other | — (No DDL) |
| 18 | SchoolSetup | Tenant | {TENANT_DDL} |
| 19 | SmartTimetable | Tenant | {TENANT_DDL} |
| 20 | StandardTimetable | Tenant | {TENANT_DDL} |
| 21 | StudentFee | Tenant | {TENANT_DDL} |
| 22 | StudentPortal | Tenant | {TENANT_DDL} |
| 23 | StudentProfile | Tenant | {TENANT_DDL} |
| 24 | Syllabus | Tenant | {TENANT_DDL} |
| 25 | SyllabusBooks | Prime | {PRIME_DDL} |
| 26 | SystemConfig | Prime | {PRIME_DDL} |
| 27 | TimetableFoundation | Prime | {PRIME_DDL} |
| 28 | Transport | Tenant | {TENANT_DDL} |
| 29 | Vendor | Tenant | {TENANT_DDL} |

---

## ▶ GLOBAL VARIABLES (set once, apply to all modules):

```
APP_REPO       = prime_ai_tarun
APP_BRANCH     = Brijesh_SmartTimetable
DATE           = 2026-03-24
```

---

## ▶ BATCH EXECUTION INSTRUCTIONS

For **each module** in the "List of Modules" table above, do the following:

1. Set the current module's variables:
   ```
   MODULE_NAME   = {current module from the list}
   MODULE_TYPE   = {corresponding MODULE_TYPE from the list}
   DATABASE_FILE = {resolved based on MODULE_TYPE — see CONFIGURATION section}
   ```

2. Execute the **FULL requirement gathering** (Steps 0 through 8 + OUTPUT) described below for this module.

3. Write the output document to a **separate file**:
   ```
   {OUTPUT_DIR}/{MODULE_NAME}_Requirement.md
   ```
   For example: `{OUTPUT_DIR}/Hpc_Requirement.md`

4. After writing the file, print a one-line status:
   ```
   ✅ [{current #}/{total}] {MODULE_NAME} — Requirement Document complete → {output file path}
   ```

5. Move to the **next module** in the list and repeat from step 1.

6. After ALL modules are done, write a **Master Requirement Index** file:
   ```
   {OUTPUT_DIR}/_Module_Requirement_Index_{DATE}.md
   ```
   This index file should contain:
   - A table listing every module with: Module Name, Module Type, Sub-module Count, Feature Count, Entity Count, API Endpoint Count, Test Case Reference Count, and link to the detailed requirement file.
   - Aggregate counts across all modules.
   - Cross-module dependency matrix (which module depends on which).

---

## ▶ ROLE & OBJECTIVE

You are a **Senior Business Analyst + Solution Architect** specializing in Laravel-based multi-tenant SaaS platforms for the education domain.

**Your job:** Read the RBS specification, every line of existing code, every DB table, every route, every test, and every AI Brain knowledge document — then produce an **exhaustive Module Requirement Document** that serves as the **single source of truth** for:

- **Design & Architecture** generation (system design, component diagrams, sequence diagrams)
- **DDL / Database Schema** generation (CREATE TABLE scripts, migrations, indexes, constraints)
- **API Specification** generation (OpenAPI / Swagger docs, request/response contracts)
- **Test Case** generation (unit, feature, browser, integration tests)
- **UI/UX Wireframe** generation (screen inventory, field mapping, workflow flows)
- **Sprint Task Breakdown** (developer-ready tasks with acceptance criteria)
- **Deployment Checklist** (environment, config, data seeding requirements)

**This is a REQUIREMENTS GATHERING exercise, NOT a gap analysis or code audit.**
Focus on WHAT the module should do, not what's broken. Capture the complete functional and non-functional specification. Read the conditions written in DDL files also.

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
OUTPUT_DIR      = {OUTPUT_REPO}/2-Requirement_Module_wise/2-Detailed_Requirements
```

### DATABASE_FILE Resolution (based on MODULE_TYPE)
```
If MODULE_TYPE = "Tenant"  → DATABASE_FILE = {TENANT_DDL}
If MODULE_TYPE = "Prime"   → DATABASE_FILE = {PRIME_DDL}
If MODULE_TYPE = "Global"  → DATABASE_FILE = {GLOBAL_DDL}
If MODULE_TYPE = "Other"   → DATABASE_FILE = NONE (skip DDL-related sections — capture requirements from RBS + code only)
```

### Table Prefix Resolution

#### Tenant Modules
| Module | Table Prefix |
|--------|-------------|
| Hpc | `hpc_*` |
| SmartTimetable | `tt_*` |
| SchoolSetup | `sch_*` |
| StudentProfile | `std_*` |
| StudentFee | `fin_*` |
| Transport | `tpt_*` |
| Syllabus | `slb_*` |
| QuestionBank | `qns_*` |
| Complaint | `cmp_*` |
| Notification | `ntf_*` |
| Vendor | `vnd_*` |
| Recommendation | `rec_*` |
| LmsExam | `exm_*` |
| LmsQuiz | `quz_*` |
| LmsHomework | `hmw_*` |
| LmsQuests | `qst_*` |
| Library | `bok_*` |
| Payment | `pay_*` |
| TimetableFoundation | `tt_*` |
| StandardTimetable | `tt_*` |
| StudentPortal | `std_*` |
| SyllabusBooks | `slb_*` |
| Accounting | `acc_*` |

#### Prime Modules
| Module | Table Prefix |
|--------|-------------|
| Billing | `bil_*` |
| Prime | `prm_*` |
| SystemConfig | `sys_*` |

#### Global Modules
| Module | Table Prefix |
|--------|-------------|
| GlobalMaster | `glb_*` |

#### No-DDL Modules
| Module |
|--------|
| Dashboard |
| Documentation |
| Scheduler |

---

## ═══ STEP 1 — LOAD AI BRAIN CONTEXT (Read ONCE, Retain for All Modules) ═══

> These files define the project's architectural rules, domain knowledge, conventions, and current state.
> **Read these ONCE for the first module. Retain this context for all subsequent modules.**

### 1A — Core Memory Files
| # | File | Extract What |
|---|------|-------------|
| 1 | `{AI_BRAIN}/memory/project-context.md` | Tech stack, external services, key workflows, business goals |
| 2 | `{AI_BRAIN}/memory/tenancy-map.md` | **CRITICAL** — multi-tenancy isolation rules, DB architecture (tenant_db / prime_db / global_db) |
| 3 | `{AI_BRAIN}/memory/modules-map.md` | Module inventory, inter-module dependencies, current completion status |
| 4 | `{AI_BRAIN}/memory/conventions.md` | Naming conventions, code patterns, file structure standards |
| 5 | `{AI_BRAIN}/memory/architecture.md` | System architecture, request flow, middleware pipeline, patterns |
| 6 | `{AI_BRAIN}/memory/school-domain.md` | School business domain rules (academic year, sessions, NEP 2020, Bloom's taxonomy, etc.) |
| 7 | `{AI_BRAIN}/memory/decisions.md` | All architectural decisions (D1–D20+) and their rationale |
| 8 | `{AI_BRAIN}/state/progress.md` | What is done / in-progress / planned per module |
| 9 | `{AI_BRAIN}/state/decisions.md` | Latest architectural decisions not yet in main decisions.md |

### 1B — Rules Files (these define MANDATORY constraints for the requirement)
| # | File | Extract What |
|---|------|-------------|
| 10 | `{AI_BRAIN}/rules/tenancy-rules.md` | Tenancy isolation constraints — how data MUST be scoped |
| 11 | `{AI_BRAIN}/rules/module-rules.md` | Module development standards — folder structure, provider patterns |
| 12 | `{AI_BRAIN}/rules/security-rules.md` | Security requirements — auth, authorization, input validation |
| 13 | `{AI_BRAIN}/rules/laravel-rules.md` | Laravel conventions — routes, controllers, models, services |
| 14 | `{AI_BRAIN}/rules/code-style.md` | PSR-12, project-specific style rules |

### 1C — Lessons & Known Issues
| # | File | Extract What |
|---|------|-------------|
| 15 | `{AI_BRAIN}/lessons/known-issues.md` | Known bugs, domain edge cases, gotchas to capture as requirements |

**After reading all 15 files, build a mental model of:**
- Platform architecture (multi-tenant SaaS, 3 DB types, Laravel modules)
- Domain rules (NEP 2020 alignment, academic sessions, school hierarchy)
- Security constraints (RBAC, tenant isolation, policy patterns)
- Naming & structural conventions (for consistent requirement specification)

---

## ═══ STEP 2 — EXTRACT RBS SPECIFICATION FOR MODULE ═══

Read `{RBS_FILE}` and extract **ALL entries** where the module code maps to `{MODULE_NAME}`.

### 2A — Capture from RBS:
For each screen/tab/menu entry belonging to this module, record:
```
Category → Main Menu → Sub-Menu → Tab/Screen Name
  Table: {table_name} | DB: {database}
  Functionality Code: F.XX.X
    Task Code: T.XX.X.X — Task Name
      Sub-Task Code: ST.XX.X.X.X — Sub-Task Description
```

### 2B — Build RBS Summary for this Module:
| # | Screen/Tab | Table | DB | Functionalities | Tasks | Sub-Tasks |
|---|-----------|-------|----|-----------------|-------|-----------|
| 1 | {Screen} | {tbl} | {db} | {count} | {count} | {count} |
| ... | | | | | | |
| **TOTAL** | | | | **X** | **X** | **X** |

### 2C — Extract Full Feature Hierarchy:
List every Functionality → Task → Sub-Task in hierarchical form.
This becomes the backbone of the Functional Requirements section.

---

## ═══ STEP 3 — EXTRACT DATABASE SCHEMA (Current State) ═══

> Skip this step entirely if MODULE_TYPE = "Other"

### 3A — Read DDL File
Read `{DATABASE_FILE}` and extract ALL tables matching the module's Table Prefix.

### 3B — For Each Table, Record:
| Attribute | Details |
|-----------|---------|
| Table Name | Full prefixed name |
| Purpose | What this table stores (inferred from column names + RBS context) |
| Columns | Complete list with: name, data type, NULL/NOT NULL, DEFAULT, constraints |
| Primary Key | Column(s) |
| Foreign Keys | Column → references table(column) |
| Indexes | Column(s), type (UNIQUE / INDEX / COMPOSITE) |
| ENUM columns | Column → allowed values |
| JSON columns | Column → expected structure |
| Boolean columns | Column → business meaning |
| Audit columns | created_by, created_at, updated_at, deleted_at |
| Soft Delete | Yes/No |

### 3C — Build Entity Relationship Summary
| Entity (Table) | Related To | Relationship Type | FK Column | Junction Table |
|----------------|-----------|-------------------|-----------|----------------|
| {table_a} | {table_b} | belongsTo / hasMany / belongsToMany | {fk_col} | {jnt_table} |

### 3D — Cross-Reference with Migrations
Read `{TENANT_MIGS}/` (or appropriate migration dir) for this module's migrations.
Note any columns that exist in migrations but NOT in DDL, or vice versa.
Capture these as "Schema Reconciliation Notes" in the requirement.

---

## ═══ STEP 4 — EXTRACT EXISTING CODEBASE (Current Implementation) ═══

> Read EVERY .php file inside `{MODULE_PATH}/`. Do not skip any file.
> Purpose: Understand what is ALREADY built to write requirements that capture both existing and new features.

### 4A — Controllers (`{MODULE_PATH}/app/Http/Controllers/`)
For each controller, extract:
- Class name and all public methods
- What each method does (1-line summary)
- Which FormRequest it uses (if any)
- Which Service it calls (if any)
- Which Gate/Policy permission it checks
- Which views it returns
- Route it maps to

### 4B — Models (`{MODULE_PATH}/app/Models/`)
For each model, extract:
- Table name, $fillable columns, $casts, $hidden
- All relationships (belongsTo, hasMany, belongsToMany, etc.)
- Scopes (local and global)
- Accessors / Mutators
- Traits used (SoftDeletes, HasFactory, etc.)

### 4C — Services (`{MODULE_PATH}/app/Services/`)
For each service, extract:
- Class name and all public methods
- What business logic each method encapsulates
- DB transactions used
- External service integrations (Razorpay, email, SMS, etc.)

### 4D — Form Requests (`{MODULE_PATH}/app/Http/Requests/`)
For each FormRequest, extract:
- Which controller/method it serves
- Complete validation rules
- Custom error messages (if any)
- Authorization logic

### 4E — Policies (`{POLICIES_DIR}/`)
For each policy related to this module, extract:
- Model it governs
- All permission methods and their permission strings
- Registration status in `{APP_PROVIDERS}`

### 4F — Views (`{MODULE_PATH}/resources/views/`)
For each view directory/file, extract:
- Screen name / purpose
- Form fields with their types and labels
- Data tables with columns displayed
- Action buttons / links available
- Filters / search capabilities
- Tab structure (if tabbed interface)

### 4G — Routes
From `{ROUTES_FILE}`, extract all routes for this module:
```
Method | URI | Controller@Method | Route Name | Middleware
```

### 4H — Jobs, Events, Listeners, Emails
From `{MODULE_PATH}/app/Jobs/`, `Events/`, `Listeners/`, `Mail/`:
- List all background jobs and what they do
- List all events and when they fire
- List all listeners and what they handle
- List all mailables and their templates

### 4I — Seeders
From `{MODULE_PATH}/database/seeders/`:
- What master data is seeded
- What config defaults are set

### 4J — Build Code Inventory Summary
| Layer | Count | Details |
|-------|-------|---------|
| Controllers | X | {list names} |
| Models | X | {list names} |
| Services | X | {list names} |
| FormRequests | X | {list names} |
| Policies | X | {list names} |
| Views | X | {list dirs} |
| Routes | X | GET: X, POST: X, PUT: X, DELETE: X |
| Jobs | X | {list names} |
| Events | X | {list names} |
| Migrations | X | {list names} |
| Seeders | X | {list names} |

---

## ═══ STEP 5 — EXTRACT TEST CASES (Existing Coverage) ═══

### 5A — Read All Existing Tests
Check these 4 locations:
```
{BROWSER_TESTS}/
{FEATURE_TESTS}/
{UNIT_TESTS}/
{MODULE_TESTS}/
```

### 5B — For Each Test File, Record:
- File path
- Test type (Browser / Feature / Unit)
- Every `test()` / `it()` method name
- What scenario it covers (1-line summary)
- What assertions it makes

### 5C — Build Test Inventory
| # | Test File | Type | Test Count | Covers |
|---|-----------|------|------------|--------|
| 1 | {file} | Browser | X | {summary} |
| ... | | | | |

### 5D — Map Tests to Features
Create a matrix: which RBS features have test coverage?

| Feature (from RBS) | Browser | Feature | Unit | Coverage |
|---------------------|---------|---------|------|----------|
| F.XX.X — {name} | ✅/❌ | ✅/❌ | ✅/❌ | Full/Partial/None |

---

## ═══ STEP 6 — SYNTHESIZE: BUILD THE REQUIREMENT DOCUMENT ═══

Now combine ALL inputs from Steps 1–5 to produce the comprehensive requirement document.

### Synthesis Rules:

1. **RBS is the PRIMARY source** — every Feature, Task, and Sub-Task from the RBS MUST appear in the requirement document. If code exists for it, note "Implemented". If not, note "Planned".

2. **Code fills in implementation details** — existing controllers, models, services, and views tell you HOW the feature currently works. Capture this as the "Current Implementation" for each requirement.

3. **DB Schema defines the data model** — table structures, relationships, and constraints define the data requirements. Every table becomes an Entity in the requirement.

4. **AI Brain provides domain context** — business rules, tenancy constraints, architectural decisions, and conventions add the non-functional requirements and constraints.

5. **Test Cases validate coverage** — existing tests show what's been validated. Missing tests indicate gaps to document as "Required Test Cases".

6. **DO NOT INVENT requirements** — only capture what is evidenced by RBS, code, DB, AI Brain, or tests. Your suggestions go in a SEPARATE section (Section 12 — Additional Suggestions).

---

## ═══ STEP 7 — CROSS-MODULE DEPENDENCY ANALYSIS ═══

For the current module, identify:

### 7A — Modules THIS Module Depends On
| Dependency Module | Dependency Type | What It Needs | Tables/Models Referenced |
|-------------------|----------------|---------------|--------------------------|
| SchoolSetup | Data | Classes, Sections, Subjects | sch_classes, sch_sections |
| StudentProfile | Data | Student records | std_students |
| ... | | | |

### 7B — Modules That Depend on THIS Module
| Dependent Module | What It Uses From This Module |
|------------------|-------------------------------|
| ... | ... |

### 7C — Shared/Global Dependencies
| Dependency | Type | Source |
|------------|------|--------|
| Academic Session | Config | global_db / tenant settings |
| Roles & Permissions | Auth | Spatie permissions |
| Tenant Context | Middleware | EnsureTenantHasModule |
| ... | | |

---

## ═══ STEP 8 — GENERATE REQUIREMENT QUALITY CHECKLIST ═══

Before writing the output, validate your requirement document against this checklist:

- [ ] Every RBS Feature (F.XX.X) is captured as a Functional Requirement
- [ ] Every RBS Task (T.XX.X.X) is captured as a sub-requirement with acceptance criteria
- [ ] Every RBS Sub-Task (ST.XX.X.X.X) has a clear, testable description
- [ ] Every DB table is captured as an Entity with full column specification
- [ ] Every existing route is documented as an API endpoint
- [ ] Every existing controller method is mapped to a feature
- [ ] Every form (from views) is documented with field-level detail
- [ ] Existing test cases are referenced under their respective features
- [ ] Missing test cases are identified and listed
- [ ] Cross-module dependencies are fully mapped
- [ ] Non-functional requirements (performance, security, tenancy) are specified
- [ ] Business rules from AI Brain are captured as constraints
- [ ] Naming conventions from AI Brain are specified for new entities
- [ ] Suggestions are in a separate section, not mixed with core requirements

---

## ═══ OUTPUT — MODULE REQUIREMENT DOCUMENT TEMPLATE ═══

After completing ALL steps above for the current module, produce this document and write it to:
**`{OUTPUT_DIR}/{MODULE_NAME}_Requirement.md`**

---

```markdown
# {MODULE_NAME} Module — Requirement Specification Document
**Version:** 1.0  |  **Date:** {DATE}  |  **Author:** Claude Code (Automated Extraction)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Path:** `{MODULE_PATH}`
**Module Type:** {MODULE_TYPE}  |  **Database:** {DATABASE_FILE or "N/A"}

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
One paragraph describing what this module does in the Prime-AI platform.

### 1.2 Scope
- **In Scope:** List what this module covers
- **Out of Scope:** List what is explicitly NOT part of this module

### 1.3 Module Statistics
| Metric | Count |
|--------|-------|
| RBS Functionalities (F.XX.X) | X |
| RBS Tasks (T.XX.X.X) | X |
| RBS Sub-Tasks (ST.XX.X.X.X) | X |
| Database Tables | X |
| API Endpoints (Routes) | X |
| UI Screens / Tabs | X |
| Existing Controllers | X |
| Existing Models | X |
| Existing Services | X |
| Existing Test Files | X |
| Cross-Module Dependencies | X |

### 1.4 Implementation Status
| Status | Feature Count | Percentage |
|--------|--------------|------------|
| ✅ Implemented | X | X% |
| 🟡 Partial | X | X% |
| ❌ Not Started | X | X% |
| **Total** | **X** | **100%** |

---

## 2. MODULE OVERVIEW

### 2.1 Business Purpose
Describe the business need this module fulfills in the context of a school ERP/LMS/LXP platform.
Reference relevant AI Brain knowledge (school-domain.md, project-context.md).

### 2.2 Key Features Summary
| # | Feature Area | Description | Status |
|---|-------------|-------------|--------|
| 1 | {Feature} | {Description} | ✅/🟡/❌ |
| ... | | | |

### 2.3 Menu Navigation Path
```
{Category} → {Main Menu} → {Sub-Menu} → {Tab/Screen}
```
List all menu paths from RBS that lead to this module's screens.

### 2.4 Module Architecture
```
MODULE_PATH Structure:
├── app/
│   ├── Http/
│   │   ├── Controllers/     → {list controllers}
│   │   └── Requests/        → {list form requests}
│   ├── Models/              → {list models}
│   ├── Services/            → {list services}
│   ├── Policies/            → {list policies}
│   ├── Jobs/                → {list jobs}
│   ├── Events/              → {list events}
│   ├── Listeners/           → {list listeners}
│   ├── Mail/                → {list mailables}
│   ├── Observers/           → {list observers}
│   └── Providers/           → {list providers}
├── database/
│   └── seeders/             → {list seeders}
├── resources/
│   └── views/               → {list view directories}
├── routes/
│   ├── web.php
│   └── api.php
├── tests/                   → {list test files}
├── module.json
└── composer.json
```

---

## 3. STAKEHOLDERS & ACTORS

### 3.1 User Roles
| Role | Access Level | Key Capabilities in This Module |
|------|-------------|-------------------------------|
| Super Admin | Full | {describe} |
| School Admin | Full (within tenant) | {describe} |
| Principal | Read + Approve | {describe} |
| Teacher | Read + Create (own) | {describe} |
| Accountant | Read + Financial ops | {describe} |
| Student | Read (own data) | {describe} |
| Parent | Read (child's data) | {describe} |
| ... | | |

### 3.2 System Actors
| Actor | Role in This Module |
|-------|---------------------|
| Scheduler (Cron) | {describe if applicable} |
| Queue Worker | {describe if applicable} |
| External API (Razorpay, SMS, etc.) | {describe if applicable} |
| Notification Service | {describe if applicable} |

---

## 4. FUNCTIONAL REQUIREMENTS

> **Source:** RBS (primary) + Existing Code (current state) + AI Brain (domain rules)
> Each Functionality from RBS becomes a section. Each Task becomes a requirement. Each Sub-Task becomes an acceptance criterion.

---

### FR-{MODULE_CODE}-001: {Functionality Name} (F.XX.X)

**RBS Reference:** F.XX.X
**Priority:** 🔴 Critical / 🟡 High / 🟢 Medium / ⚪ Low
**Status:** ✅ Implemented / 🟡 Partial / ❌ Not Started
**Owner Screen:** {Screen/Tab name from RBS}
**Table(s):** {table_name(s)} | **DB:** {database}

#### Description
{What this functionality does — derived from RBS + AI Brain domain knowledge}

#### Requirements

**REQ-{MODULE_CODE}-001.1: {Task Name} (T.XX.X.X)**
| Attribute | Detail |
|-----------|--------|
| Description | {task description} |
| Actors | {which roles can perform this} |
| Preconditions | {what must be true before this task can execute} |
| Trigger | {what initiates this task — user action / system event / cron} |
| Input | {what data is needed — form fields, parameters, uploaded files} |
| Processing | {step-by-step business logic} |
| Output | {what happens on success — redirect, message, data change, notification} |
| Error Handling | {what happens on failure — validation errors, exceptions, rollback} |
| Status | ✅ / 🟡 / ❌ |

**Acceptance Criteria (from RBS Sub-Tasks):**
- [ ] `ST.XX.X.X.1` — {sub-task description} → **Status:** ✅/❌
- [ ] `ST.XX.X.X.2` — {sub-task description} → **Status:** ✅/❌
- [ ] ...

**Current Implementation (if any):**
| Layer | File | Method | Notes |
|-------|------|--------|-------|
| Controller | {ControllerName} | {method()} | {what it does now} |
| Service | {ServiceName} | {method()} | {business logic} |
| FormRequest | {RequestName} | rules() | {validation rules} |
| View | {view_path} | — | {what it renders} |
| Policy | {PolicyName} | {method()} | {permission string} |

**Required Test Cases:**
| # | Test Scenario | Type | Existing | Priority |
|---|--------------|------|----------|----------|
| 1 | {Scenario description} | Feature | ✅/❌ | High |
| 2 | {Scenario description} | Browser | ✅/❌ | Medium |
| ... | | | | |

---

> **Repeat the above block (FR-{MODULE_CODE}-XXX) for EVERY Functionality found in the RBS for this module.**

---

## 5. DATA MODEL & ENTITY SPECIFICATION

> **Source:** DDL file + Migrations + Models
> This section serves as the input for DDL generation, migration scripts, and ER diagram creation.

### 5.1 Entity Overview
| # | Entity (Table Name) | Purpose | Columns | FKs | Indexes | Soft Delete |
|---|---------------------|---------|---------|-----|---------|-------------|
| 1 | {table_name} | {purpose} | X | X | X | Yes/No |
| ... | | | | | | |

### 5.2 Detailed Entity Specification

#### ENTITY: {table_name}

**Purpose:** {What this table stores and why}
**Model Class:** `{Namespace}\Models\{ModelName}`
**Relationships:** {List parent/child relationships}

##### Columns
| # | Column | Data Type | Nullable | Default | Constraints | Business Rule |
|---|--------|-----------|----------|---------|-------------|--------------|
| 1 | id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PRIMARY KEY | — |
| 2 | {col} | {type} | YES/NO | {default} | {FK/UNIQUE/INDEX} | {rule from domain} |
| ... | | | | | | |
| N | is_active | TINYINT(1) | NO | 1 | — | Soft visibility toggle |
| N+1 | created_by | BIGINT UNSIGNED | YES | NULL | FK → users(id) | Audit: who created |
| N+2 | created_at | TIMESTAMP | YES | NULL | — | Audit: when created |
| N+3 | updated_at | TIMESTAMP | YES | NULL | — | Audit: when modified |
| N+4 | deleted_at | TIMESTAMP | YES | NULL | — | Soft delete marker |

##### Foreign Keys
| FK Column | References | On Delete | On Update |
|-----------|-----------|-----------|-----------|
| {fk_col} | {parent_table}(id) | CASCADE/SET NULL/RESTRICT | CASCADE |

##### Indexes
| Index Name | Column(s) | Type | Purpose |
|-----------|-----------|------|---------|
| {idx_name} | {col(s)} | UNIQUE/INDEX/COMPOSITE | {why} |

##### ENUM Definitions
| Column | Allowed Values | Default | Business Meaning |
|--------|---------------|---------|------------------|
| {col} | val1, val2, val3 | val1 | {what each value means} |

##### JSON Column Structures
| Column | Expected JSON Structure | Example |
|--------|------------------------|---------|
| {col}_json | `{ "key": "type", ... }` | `{"marks": [90, 85], "grade": "A"}` |

##### Model Specification
| Attribute | Value |
|-----------|-------|
| $table | `{table_name}` |
| $fillable | `[{list}]` |
| $casts | `[{column => type}]` |
| $hidden | `[{list}]` |
| Traits | SoftDeletes, HasFactory, {others} |
| Scopes | scopeActive(), {others} |
| Accessors | {list} |
| Mutators | {list} |

##### Relationships
| Method Name | Type | Related Model | FK | Notes |
|-------------|------|--------------|-----|-------|
| {method}() | belongsTo | {Model} | {fk_col} | {note} |
| {method}() | hasMany | {Model} | {fk_col} | {note} |
| {method}() | belongsToMany | {Model} | — | via {junction_table} |

---

> **Repeat for EVERY table belonging to this module.**

---

### 5.3 Entity Relationship Summary (for ER Diagram generation)
```
{table_a} 1 ──── * {table_b}  (via {fk_column})
{table_c} * ──── * {table_d}  (via {junction_table})
...
```

### 5.4 Schema Reconciliation Notes
| Issue | Source | Details | Resolution Needed |
|-------|--------|---------|-------------------|
| Column in migration but not in DDL | Migration {file} | {column_name} | Sync DDL or remove migration |
| Column in DDL but no migration | DDL | {column_name} | Create migration |
| ... | | | |

---

## 6. API & ROUTE SPECIFICATION

> **Source:** Routes file + Controllers
> This section serves as input for OpenAPI/Swagger generation.

### 6.1 Route Summary
| # | Method | URI | Controller@Method | Route Name | Middleware | Auth | Status |
|---|--------|-----|-------------------|------------|------------|------|--------|
| 1 | GET | /{resource} | {Ctrl}@index | {name} | auth, tenant | ✅ | ✅/❌ |
| 2 | POST | /{resource} | {Ctrl}@store | {name} | auth, tenant | ✅ | ✅/❌ |
| ... | | | | | | | |

### 6.2 Detailed Endpoint Specification

#### EP-{MODULE_CODE}-001: {Route Name}

| Attribute | Detail |
|-----------|--------|
| Method | GET / POST / PUT / DELETE |
| URI | `/{resource}/{parameter?}` |
| Controller | `{ControllerName}@{method}` |
| Middleware | `auth`, `EnsureTenantHasModule:{module}` |
| Permission | `tenant.{module-slug}.{action}` |
| Rate Limit | {if applicable} |

**Request:**
| Parameter | Location | Type | Required | Validation Rule | Description |
|-----------|----------|------|----------|-----------------|-------------|
| {param} | URL/Body/Query | string/int/file | Yes/No | {rule} | {desc} |

**Success Response (200/201):**
```json
{
  "success": true,
  "message": "...",
  "data": { ... }
}
```

**Error Responses:**
| HTTP Code | Condition | Response |
|-----------|-----------|----------|
| 401 | Unauthenticated | `{"message": "Unauthenticated."}` |
| 403 | Unauthorized | `{"message": "This action is unauthorized."}` |
| 422 | Validation failure | `{"message": "...", "errors": {...}}` |
| 500 | Server error | `{"message": "Server Error"}` |

---

> **Repeat for EVERY route/endpoint in this module.**

---

### 6.3 Missing Endpoints (Required by RBS but not yet implemented)
| # | Proposed Method | Proposed URI | For Feature | Priority |
|---|----------------|-------------|-------------|----------|
| 1 | {method} | {uri} | FR-{code}-XXX | High |
| ... | | | | |

---

## 7. UI SCREEN INVENTORY & FIELD MAPPING

> **Source:** Views + RBS screen definitions
> This section serves as input for wireframe and UI design generation.

### 7.1 Screen Inventory
| # | Screen Name | Type | Route | View File | Status |
|---|-----------|------|-------|-----------|--------|
| 1 | {name} | List/Form/Detail/Dashboard/Report | {route} | {view_path} | ✅/❌ |
| ... | | | | | |

### 7.2 Detailed Screen Specification

#### SCREEN-{MODULE_CODE}-001: {Screen Name}

| Attribute | Detail |
|-----------|--------|
| Menu Path | {Category → Menu → Sub-Menu → Tab} |
| Screen Type | List / Create Form / Edit Form / Detail View / Dashboard / Report |
| Route | {method} {URI} |
| Controller | {Ctrl}@{method} |
| Roles Allowed | {list of roles} |
| Permission | `tenant.{slug}.{action}` |

**Data Display (for List/Detail screens):**
| # | Column/Field | Source (Model.column) | Display Type | Sortable | Filterable |
|---|-------------|----------------------|-------------|----------|------------|
| 1 | {label} | {Model.column} | text/badge/date/link/image | Yes/No | Yes/No |
| ... | | | | | |

**Form Fields (for Create/Edit screens):**
| # | Field Label | Name Attribute | HTML Type | Required | Validation | Default | Source |
|---|-----------|----------------|-----------|----------|------------|---------|--------|
| 1 | {label} | {name} | text/select/date/file/textarea/checkbox | Yes/No | {rules} | {default} | {dropdown source if select} |
| ... | | | | | | | |

**Action Buttons:**
| Button | Action | Permission Required | Confirmation |
|--------|--------|---------------------|-------------|
| Save | Submit form → store/update | {permission} | No |
| Delete | Soft delete record | {permission} | Yes - "Are you sure?" |
| Export PDF | Generate PDF report | {permission} | No |
| ... | | | |

**Filters (for List screens):**
| Filter | Type | Options Source | Default |
|--------|------|---------------|---------|
| Academic Session | Dropdown | OrganizationAcademicSession | Current session |
| Class | Dropdown | sch_classes | All |
| Status | Dropdown | ENUM values | Active |
| Search | Text input | name, code columns | — |
| ... | | | |

**Pagination:**
| Attribute | Value |
|-----------|-------|
| Items per page | 20 (configurable) |
| Pagination style | Laravel default `->links()` |

**Tab Structure (if tabbed):**
| Tab Name | Content | Loaded via |
|----------|---------|-----------|
| {tab1} | {what it shows} | Eager / AJAX |
| {tab2} | {what it shows} | Eager / AJAX |

---

> **Repeat for EVERY screen/tab in this module.**

---

## 8. BUSINESS RULES & DOMAIN CONSTRAINTS

> **Source:** AI Brain (school-domain.md, decisions.md, tenancy-rules.md) + RBS logic

### 8.1 Domain Rules
| # | Rule ID | Rule Description | Enforced At | Source |
|---|---------|-----------------|-------------|--------|
| 1 | BR-{MOD}-001 | {rule description} | Controller/Service/Model/DB | {AI Brain file or RBS ref} |
| 2 | BR-{MOD}-002 | {rule description} | ... | ... |
| ... | | | | |

### 8.2 Tenancy Rules (CRITICAL)
| # | Constraint | How Enforced | Verification |
|---|-----------|-------------|-------------|
| 1 | All queries MUST be scoped to current tenant | Automatic tenant DB connection | Middleware + model scoping |
| 2 | No cross-tenant data leakage | Separate tenant databases | Query audit |
| 3 | Module access gated by subscription | EnsureTenantHasModule middleware | Route middleware |
| ... | | | |

### 8.3 Academic Year / Session Rules
| Rule | Description |
|------|-------------|
| {rule} | {description — e.g., "All student data is scoped to the current academic session"} |

### 8.4 NEP 2020 Alignment (if applicable)
| Requirement | How This Module Addresses It |
|-------------|------------------------------|
| {NEP req} | {implementation detail} |

### 8.5 Status / State Transition Rules
| Entity | States | Valid Transitions | Trigger |
|--------|--------|-------------------|---------|
| {entity} | draft → active → archived | draft→active: on publish; active→archived: on archive | User action / Cron |

---

## 9. WORKFLOW & STATE MACHINE DEFINITIONS

> For modules with multi-step workflows (approvals, publish flows, generation pipelines)

### 9.1 Workflow: {Workflow Name}

**Trigger:** {what starts this workflow}
**Actors involved:** {which roles participate at each step}

```
[Start] → (Step 1: {action}) → (Step 2: {action}) → ... → [End State]
                ↓ (on reject)
           (Step 1a: {alternate path})
```

**Step Details:**
| Step | Action | Actor | Input | Output | Next Step | Error Path |
|------|--------|-------|-------|--------|-----------|------------|
| 1 | {action} | {role} | {data} | {result} | Step 2 | {error handling} |
| ... | | | | | | |

**Events Fired:**
| Step | Event | Listener | Action |
|------|-------|----------|--------|
| 1 | {EventClass} | {ListenerClass} | {what it does — email, log, notification} |

---

## 10. NON-FUNCTIONAL REQUIREMENTS

### 10.1 Performance Requirements
| # | Requirement | Target | Measurement |
|---|------------|--------|-------------|
| 1 | Page load time for list screens | < 2 seconds | With 1000+ records |
| 2 | Form submission response | < 1 second | Including validation |
| 3 | PDF report generation | < 10 seconds | For 500 records; queue if larger |
| 4 | Bulk import | < 30 seconds for 500 rows | Chunked processing |
| 5 | Dropdown data caching | Cache for 1 hour | Tenant-scoped cache key |
| ... | | | |

### 10.2 Security Requirements
| # | Requirement | Implementation |
|---|------------|----------------|
| 1 | Every route must be authenticated | `auth` middleware on all routes |
| 2 | Every action must be authorized | Gate/Policy check in every controller method |
| 3 | Module access check | `EnsureTenantHasModule` middleware |
| 4 | Input validation | FormRequest classes for all store/update |
| 5 | CSRF protection | `@csrf` in all forms |
| 6 | Mass assignment protection | Explicit `$fillable` on all models |
| 7 | File upload validation | MIME type + size validation |
| 8 | SQL injection prevention | Eloquent ORM / parameterized queries |
| 9 | Tenant data isolation | Separate tenant databases |
| 10 | Activity logging | Log create/update/delete actions |

### 10.3 Scalability Requirements
| # | Requirement | Approach |
|---|------------|----------|
| 1 | Handle 500+ tenants | Multi-tenant DB architecture |
| 2 | Handle 10,000+ students per tenant | Paginated queries, eager loading |
| 3 | Concurrent user support | Queue heavy operations, cache dropdowns |

### 10.4 Accessibility & Localization
| # | Requirement |
|---|------------|
| 1 | Multi-language support (via glb_translations) |
| 2 | RTL support consideration |
| 3 | Mobile-responsive views |

### 10.5 Audit & Compliance
| # | Requirement |
|---|------------|
| 1 | All CRUD operations logged via activity log |
| 2 | Soft delete — no hard deletes in production |
| 3 | Created_by tracked on all records |

---

## 11. CROSS-MODULE DEPENDENCIES

### 11.1 This Module Depends On
| # | Module | Dependency Type | What It Needs | Tables/Models Used |
|---|--------|----------------|---------------|--------------------|
| 1 | {module} | Data / Auth / Config | {description} | {tables} |
| ... | | | | |

### 11.2 Modules That Depend on This
| # | Module | What It Uses From This Module |
|---|--------|-------------------------------|
| 1 | {module} | {description} |
| ... | | |

### 11.3 Shared Services / Helpers Used
| Service / Helper | Source | Purpose in This Module |
|------------------|--------|------------------------|
| activityLog() | app/Helpers | Audit logging |
| TenantScope | Middleware | Tenant isolation |
| {others} | | |

---

## 12. TEST CASE REFERENCE & COVERAGE

### 12.1 Existing Test Cases
| # | Test File | Type | Tests | Covers |
|---|-----------|------|-------|--------|
| 1 | {path} | Browser/Feature/Unit | X | {summary} |
| ... | | | | |

### 12.2 Required Test Scenarios (for complete coverage)

#### Critical Tests (must have before release)
| # | Scenario | Type | Feature Ref | Priority | Exists |
|---|----------|------|-------------|----------|--------|
| 1 | Unauthenticated user gets 401 on all routes | Feature | All | 🔴 | ✅/❌ |
| 2 | Wrong role gets 403 | Feature | All | 🔴 | ✅/❌ |
| 3 | Tenant isolation — cannot access other tenant's data | Feature | All | 🔴 | ✅/❌ |
| 4 | CRUD: create with valid data → success | Feature | FR-XXX-001 | 🔴 | ✅/❌ |
| 5 | CRUD: create with invalid data → validation errors | Feature | FR-XXX-001 | 🟡 | ✅/❌ |
| 6 | CRUD: update record → changes saved | Feature | FR-XXX-001 | 🟡 | ✅/❌ |
| 7 | CRUD: soft delete → record hidden from list | Feature | FR-XXX-001 | 🟡 | ✅/❌ |
| 8 | CRUD: restore soft-deleted record | Feature | FR-XXX-001 | 🟢 | ✅/❌ |
| ... | | | | | |

#### Feature-Specific Tests
| # | Scenario | Type | Feature Ref | Priority | Exists |
|---|----------|------|-------------|----------|--------|
| {Extracted from each FR section's "Required Test Cases"} |

### 12.3 Coverage Summary
| Category | Total Required | Existing | Gap | Coverage % |
|----------|---------------|----------|-----|------------|
| Authentication | X | X | X | X% |
| Authorization | X | X | X | X% |
| CRUD Operations | X | X | X | X% |
| Business Logic | X | X | X | X% |
| Validation | X | X | X | X% |
| Edge Cases | X | X | X | X% |
| **TOTAL** | **X** | **X** | **X** | **X%** |

---

## 13. GLOSSARY & TERMINOLOGY

| Term | Definition | Context |
|------|-----------|---------|
| Tenant | A school/organization using the Prime-AI platform | Multi-tenant SaaS |
| Academic Session | A school year period (e.g., 2025-2026) | Time-scoping all academic data |
| NEP 2020 | National Education Policy 2020 (India) | Curriculum alignment |
| HPC | Holistic Progress Card | Student assessment framework |
| {module-specific terms} | {definition} | {context} |

---

## 14. ADDITIONAL SUGGESTIONS

> **IMPORTANT:** These are Claude's suggestions based on industry best practices, domain expertise, and analysis of the existing codebase. These are NOT derived from the RBS or current implementation. Review and adopt selectively.

### 14.1 Feature Enhancement Suggestions
| # | Suggestion | Rationale | Impact | Effort |
|---|-----------|-----------|--------|--------|
| 1 | {suggestion} | {why this would help} | High/Medium/Low | S/M/L/XL |
| ... | | | | |

### 14.2 Technical Improvement Suggestions
| # | Suggestion | Rationale | Impact | Effort |
|---|-----------|-----------|--------|--------|
| 1 | {suggestion} | {why this would help} | High/Medium/Low | S/M/L/XL |
| ... | | | | |

### 14.3 UX/UI Improvement Suggestions
| # | Suggestion | Rationale | Impact | Effort |
|---|-----------|-----------|--------|--------|
| 1 | {suggestion} | {why this would help} | High/Medium/Low | S/M/L/XL |
| ... | | | | |

### 14.4 Performance Optimization Suggestions
| # | Suggestion | Rationale | Impact | Effort |
|---|-----------|-----------|--------|--------|
| 1 | {suggestion} | {why this would help} | High/Medium/Low | S/M/L/XL |
| ... | | | | |

### 14.5 Missing Module Capabilities (Industry Standard)
| # | Capability | Why Schools Need It | Priority | Effort |
|---|-----------|---------------------|----------|--------|
| 1 | {capability} | {business justification} | High/Medium/Low | S/M/L/XL |
| ... | | | | |

---

## 15. APPENDICES

### Appendix A — Full RBS Extract for This Module
{Paste the complete RBS hierarchy extracted in Step 2C}

### Appendix B — Complete Route Table
{Paste the full route inventory from Step 4G}

### Appendix C — Complete Code Inventory
{Paste the code inventory summary from Step 4J}

### Appendix D — Existing Test Case Listing
{Paste the full test listing from Step 5B}

### Appendix E — Raw Entity-Relationship Mapping
{Paste the ER summary from Step 5.3}

### Appendix F — AI Brain References Used
| File | Key Information Extracted |
|------|--------------------------|
| {file} | {what was relevant for this module} |
```

---

## ▶ ANALYSIS RULES — READ BEFORE STARTING

1. **Open every file** — do not guess or assume from filenames. Read actual code.
2. **Check the real DB** — always cross-reference with `{DATABASE_FILE}`, not just model definitions.
3. **RBS is authoritative** — every RBS Feature/Task/Sub-Task MUST appear in the requirement document, whether implemented or not.
4. **Be specific** — every requirement must have clear, testable acceptance criteria.
5. **No hallucination** — if a file doesn't exist, say it's missing. Do not invent content.
6. **Separate facts from suggestions** — core requirements (Sections 1–13) are ONLY from RBS + Code + DB + AI Brain. Suggestions go ONLY in Section 14.
7. **Think downstream** — every section should be usable as input for the next artifact (DDL, API spec, test cases, wireframes, sprint tasks).
8. **Tenancy awareness** — always capture tenancy scope, database type, and isolation requirements.
9. **Convention compliance** — use the naming conventions from AI Brain for all new proposed entities.
10. **Count everything** — all summary tables must have accurate counts from actual findings.
11. **Mark implementation status** — for every feature/entity/endpoint, clearly mark if it's ✅ Implemented, 🟡 Partial, or ❌ Not Started.
12. **Cross-reference constantly** — RBS ↔ Code ↔ DB ↔ Tests. If something exists in one but not the other, note it.

---

## ▶ START NOW — EXECUTION ORDER

```
Step 0-A → Read this prompt file → Derive DB_REPO from the path
Step 0-B → Read {DB_REPO}/AI_Brain/config/paths.md
           → Get LARAVEL_REPO, TENANT_DDL, PRIME_DDL, GLOBAL_DDL, AI_BRAIN from there
Step 0-C → Build all derived paths from MODULE_NAME and the configuration above

Step 1   → Read AI Brain (15 files — memory + rules + lessons)
           → This only needs to be done ONCE. Retain context for all modules.

─── BEGIN MODULE LOOP (for each module in the List of Modules table) ───

  Set MODULE_NAME and MODULE_TYPE from the current row in the list.
  Resolve DATABASE_FILE based on MODULE_TYPE.

  Step 2   → Extract RBS specification for this module from {RBS_FILE}
  Step 3   → Extract DB schema for this module from {DATABASE_FILE}
             (Skip if MODULE_TYPE = "Other")
  Step 4   → Read every PHP file inside {MODULE_PATH}
             Controllers → Models → Services → Requests →
             Policies → Views → Routes → Jobs → Events → Providers → Seeders
  Step 5   → Read tests (BROWSER_TESTS + MODULE_TESTS + FEATURE_TESTS + UNIT_TESTS)
  Step 6   → Synthesize: Combine all inputs into the requirement document
  Step 7   → Cross-module dependency analysis
  Step 8   → Quality checklist validation

  OUTPUT   → Write full requirement document to:
             {OUTPUT_DIR}/{MODULE_NAME}_Requirement.md
  STATUS   → Print: ✅ [X/29] {MODULE_NAME} — Requirement Document complete

─── END MODULE LOOP ───

FINAL    → Write Master Requirement Index to:
           {OUTPUT_DIR}/_Module_Requirement_Index_{DATE}.md
           (Table of all modules with counts, dependencies, and file links)
```

**Start from Step 0-A. Do not skip any step. Read all files before writing any output. Process every module in the list sequentially.**
