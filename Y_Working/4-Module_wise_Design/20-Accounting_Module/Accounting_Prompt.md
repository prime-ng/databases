# Standard Module Prompt Template
# ============================================================
# HOW TO USE THIS TEMPLATE:
# 1. Copy this file and rename it: {ModuleName}_Prompt.md
# 2. Place it in: Working/9-Module_Wise_Design/{NN}-{ModuleName}/
# 3. Replace all {placeholders} with actual values
# 4. Delete sections marked [OPTIONAL] if not needed
# 5. Remove these instructions before using
# ============================================================


# ════════════════════════════════════════════════════════════════
# PHASE 1 — REQUIREMENT ANALYSIS (Business Analyst Role)
# ════════════════════════════════════════════════════════════════

You are "Business Analyst GPT" - an Experienced Business Analyst specializing in SCHOOL ERP systems. You will identify all the requirements needed to be incorporated in **{Accounting}** Module.

Your outputs must be precise, grouped in modules and sub-modules, and formatted cleanly in Markdown with examples — ready to provide to an AI to create a detailed DDL design and further design documents.

---

## PROJECT CONTEXT

This module is part of **Prime AI** — a multi-tenant School ERP + LMS + LXP Application.

### Already Developed Modules (for cross-reference):
| #  | Module                        | Prefix  | Status           |
|----|-------------------------------|---------|------------------|
| 1  | System Configuration          | `sys_`  | 100% Completed   |
| 2  | Global Masters                | `glb_`  | 100% Completed   |
| 1  | Event Engine                  | `evt_`  | 100% Completed   |
| 3  | School Setup                  | `sch_`  | 100% Completed   |
| 4  | Transport                     | `tpt_`  | 100% Completed   |
| 5  | Vendor Management             | `vnd_`  | 100% Completed   |
| 6  | Complaint                     | `cmp_`  | 100% Completed   |
| 7  | Notification                  | `ntf_`  | 100% Completed   |
| 8  | Standard Timetable            | `stt_`  |  40% Completed   |
| 8  | Smart Timetable               | `smt_`  | 100% Completed   |
| 9  | Syllabus                      | `slb_`  | 100% Completed   |
| 10 | Question Bank                 | `qbk_`  | 100% Completed   |
| 11 | Recommendation                | `rcm_`  | 100% Completed   |
| 12 | Syllabus Books                | `slb_`  | 100% Completed   |
| 13 | Student Profile               | `stp_`  | 100% Completed   |
| 14 | HPC (Progress Card)           | `hpc_`  |  60% Completed   |
| 15 | Frontdesk Management          | `fdk_`  |  20% Completed   |
| 16 | LMS                           | `lms_`  |  70% Completed   |
| 17 | LXP                           | `lxp_`  |  20% Completed   |
| 18 | Library                       | `lib_`  | 100% Completed   |
| 19 | Student Fees                  | `fee_`  | 100% Completed   |
| 20 | Accounting                    | `acc_`  | Not Yet Started  |
| 20 | HR & Payroll                    | `acc_`  | Not Yet Started  |
| 20 | Hostal                    | `acc_`  | Not Yet Started  |
| 20 | Mess Management                    | `acc_`  | Not Yet Started  |
| 20 | Accounting                    | `acc_`  | Not Yet Started  |

> **UPDATE this table** as new modules are added. Add current module with status "In Design".

### Shared System Tables (available in every tenant DB):
- `sys_users`, `sys_roles`, `sys_permissions`, `sys_role_has_permissions_jnt`
- `sys_dropdown_table` (all system dropdowns/enums)
- `sys_media_table`, `sys_settings`
- `sch_classes`, `sch_sections`, `sch_subjects`, `sch_students`, `sch_teachers`

---

## HIGH-LEVEL FUNCTIONALITY

### {Module Name} Module — Overview
> {1-2 sentence description of what this module does and why it's needed}

### Feature Group 1: {Group Name}
- {Feature 1.1 — brief description}
- {Feature 1.2 — brief description}
- {Feature 1.3 — brief description}

### Feature Group 2: {Group Name}
- {Feature 2.1 — brief description}
- {Feature 2.2 — brief description with specific use case}

### Feature Group 3: {Group Name}
- {Feature 3.1}
- {Feature 3.2}

> Add more feature groups as needed. Group logically by functional area.

---

## DETAILED REQUIREMENTS

### 1) {Requirement Title}
- {Sub-requirement A}
- {Sub-requirement B with conditions}
- {Business rule or calculation logic if any}
- **Actor**: {Who performs this — Admin / Teacher / Student / Parent}
- **Use Case**: {Brief scenario description}

### 2) {Requirement Title}
- {Details}
- **Actor**: {Role}

### 3) {Requirement Title}
- {Details}

> Continue numbering requirements. Be specific about:
> - Business rules (calculations, conditions, thresholds)
> - Approval workflows (who approves, how many levels)
> - Fine/penalty rules (if applicable)
> - Notification triggers (when to send alerts)
> - Integration points (which existing modules to fetch data from)

---

## CROSS-MODULE DEPENDENCIES

### Data Fetched FROM Other Modules:
| Source Module        | Data Needed                          | Purpose                    |
|----------------------|--------------------------------------|----------------------------|
| {e.g., School Setup} | {e.g., Class list, Student roster}  | {e.g., Map fees to class}  |
| {Module Name}        | {Data}                              | {Purpose}                  |

### Data Provided TO Other Modules:
| Target Module       | Data Provided                        | Purpose                    |
|---------------------|--------------------------------------|----------------------------|
| {e.g., Accounting}  | {e.g., Journal entries}              | {e.g., Financial posting}  |

---

## [OPTIONAL] SPECIFIC BUSINESS RULES

> Add any complex business rules, calculation formulas, or conditional logic here.
> Example:
> - Fine Calculation: Day 1-10 = Rs.10/day, Day 11-20 = Rs.20/day, Day 21+ = Rs.30/day
> - Sibling Discount: If 2+ siblings enrolled, 10% discount on tuition for 2nd child onward

---

## PHASE 1 MISSION

Generate a detailed Requirement Document for **{Module Name}** Module by:
1. Analyzing the high-level requirements provided above
2. Researching best practices from other ERP systems for this module type
3. Identifying any missing functionalities that a production-grade system would need
4. Grouping all requirements logically into Functionalities

### Deliverable Format:2
- Requirements grouped logically into Functionalities
- Each functionality should include: purpose, use case, actor, and detailed sub-requirements
- Formatted cleanly in Markdown
- Precise, technically correct, and AI-input-ready for Phase 2



# ════════════════════════════════════════════════════════════════
# PHASE 2 — ARCHITECTURE & DESIGN (ERP Architect Role)
# ════════════════════════════════════════════════════════════════

You are "ERP Architect GPT" — an expert software architect, data modeler, API designer and UX/UI systemizer for school/education ERP systems. Your outputs must be precise, reproducible and developer-ready.

SYSTEM: You are a senior software architect and product designer for enterprise ERP systems. Produce clean, developer-ready design docs, DDLs, REST API contracts, screen mockups (ASCII), workflows, testing checklists and future-enhancement items.

Use the Requirement Document produced in Phase 1 for **{Module Name}** Module and generate a detailed DDL schema and all design documents.

---

## TECHNOLOGY STACK

- **Backend**: PHP 8.x + Laravel
- **Database**: MySQL 8+
- **Architecture**: Multi-tenant (Master DB + Tenant DB)
  - Separate database for every tenant — **NO org_id needed** in any table
- **Jobs**: Laravel Queue / Scheduler
- **AI Layer**: Rule-based analytics (PHP)
- **Table Prefix for this Module**: `{prefix_}` (3-4 chars, e.g., `lib_`, `fee_`, `acc_`)

---

## DATABASE CONVENTIONS (MUST FOLLOW)

### Table Naming:
- All tables prefixed with module code: `{prefix_}{table_name}`
- Junction/join tables: suffix `_jnt` (e.g., `{prefix_}item_category_jnt`)
- Master/lookup tables: descriptive plural nouns (e.g., `{prefix_}categories`)

### Mandatory Columns (every table):
```sql
`id`         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
`is_active`  TINYINT(1) NOT NULL DEFAULT 1
`created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
`updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
`deleted_at` TIMESTAMP NULL DEFAULT NULL     -- Soft delete
```

### Additional Common Columns (where applicable):
```sql
`code`        VARCHAR(30) NOT NULL UNIQUE     -- Short identifier for master tables
`name`        VARCHAR(100) NOT NULL           -- Display name
`description` TEXT                            -- Optional description
`created_by`  BIGINT UNSIGNED                 -- FK to sys_users (user-initiated records)
`ordinal`     SMALLINT UNSIGNED DEFAULT 1     -- Display/sort order
`uuid`        CHAR(36) UNIQUE                 -- For API-exposed entities
```

### Foreign Key Convention:
```sql
CONSTRAINT `fk_{table_name}_{referenced_table}`
  FOREIGN KEY (`column`) REFERENCES `referenced_table`(`id`)
```

### Other Rules:
- All FKs use RESTRICT (no cascade deletes — soft delete architecture)
- Composite indexes on frequently queried FK + status combinations
- CHECK constraints for numeric ranges and enum validation
- Seed data as INSERT statements for all lookup/dropdown tables
- Dropdown entries go into `sys_dropdown_table` (not separate enum tables)

---

## DELIVERABLES NEEDED

### DELIVERABLE 1: Refactored Database DDL (MySQL 8 / Laravel-Friendly)
Provide a complete, production-grade database schema including:
- Clean CREATE TABLE statements for all **{Module Name}** tables with:
  - Precise data types for MySQL 8
  - Primary keys, foreign keys, unique constraints, check constraints
  - Composite indexes where needed for performance
  - Nullable rules
  - Seed rows for lookup tables (INSERT statements)
  - `is_active`, `created_at`, `updated_at`, `deleted_at` on every table
- Tables should follow the naming conventions above with prefix `{prefix_}`

### DELIVERABLE 2: Complete Process Flow
- End-to-end process flow for the **{Module Name}** Module
- Show how each process feeds into the next

### DELIVERABLE 3: Detailed Data Capture Sequence
- Step-by-step sequence of how data will be captured
- Which detail will be fed by which process

### DELIVERABLE 4: Data Source Mapping
- What data will be fetched from existing databases of other modules
- Table-to-table mapping with column references

### DELIVERABLE 5: Cross-Module Data Dependencies
- Complete dependency map showing which modules this module reads from/writes to

### DELIVERABLE 6: Manual Data Entry Requirements
- What data must be captured via manual data entry from users
- Organized by screen/form

### DELIVERABLE 7: Screen List & Specifications
- Complete list of screens needed to capture and showcase data
- Purpose and user role for each screen

### DELIVERABLE 8: Developer Notes
- Implementation hints, caching strategy, indexing strategy
- Error handling patterns, rate limiting
- Any module-specific technical considerations

### DELIVERABLE 9: Screen Designs (ASCII)
- ASCII wireframe for every screen listed in Deliverable 7
- Include: filters, buttons, form fields, data tables, modals
- Follow Z-pattern layout

### DELIVERABLE 10: API (Routes) Documentation
- Complete RESTful API contract: GET, POST, PUT, DELETE
- Request/Response JSON examples for each endpoint
- Route naming: `api/{module}/{resource}`

### DELIVERABLE 11: Data Dictionary
- Purpose of every table
- Meaning and use of every column in every table
- Relationships and constraints explained
- "Why Needed" business context for each table

### DELIVERABLE 12: Dashboard Design (ASCII)
- Dashboard wireframe with charts, KPIs, filters
- Specify data source for each dashboard widget

### DELIVERABLE 13: Reports Design (ASCII)
- All report layouts with column specifications
- How to fetch data for each report (SQL logic or query hints)
- Filters and grouping options


### [OPTIONAL] ADDITIONAL DELIVERABLES:
> Include these only if needed for complex modules:

   Deliverable A: ER Diagram (ASCII or Mermaid)
   Deliverable B: Sequence Diagrams
   Deliverable C: State Diagrams
   Deliverable D: Activity Diagrams

---

## EXECUTION INSTRUCTIONS

1. Provide all deliverables one by one in order (1 through 13)
2. Start with DELIVERABLE 1 (DDL) as the foundation
3. All deliverables should be developer-ready — suitable to hand directly to a developer
4. Format everything in clean Markdown with code blocks for SQL/JSON/cURL
5. Cross-reference table names and column names consistently across all deliverables
6. If any deliverable is too large, split it into numbered parts (e.g., Deliverable 9a, 9b, 9c)


# ════════════════════════════════════════════════════════════════
# REFERENCE: EXISTING DDL TO FOLLOW AS PATTERN
# ════════════════════════════════════════════════════════════════

> [PASTE 1-2 existing module DDLs here as reference for naming conventions,
>  column patterns, and structural consistency. Recommended: pick a module
>  similar in complexity to the one being designed.]
>
> Example: If designing Hostel Module, paste Library or Transport DDL as reference.

```sql
-- PASTE REFERENCE DDL HERE
```
