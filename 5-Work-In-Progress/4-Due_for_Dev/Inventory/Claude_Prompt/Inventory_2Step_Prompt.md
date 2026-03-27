# PRL — Payroll Module Development Lifecycle Prompt

**Purpose:** This is a single consolidated prompt to build the "Feature Specification", "Complete Development Plan" & "Database Schema Design" for Payroll module for Prime-AI. Execute this file in Claude and work through each phase sequentially. Claude will stop after each phase for your review and confirmation.

**Developer:** Brijesh

---

## CONFIGURATION :

```
MODULE_CODE       = PRL
MODULE            = Payroll
MODULE_DIR        = Modules/Payroll/
APP_REPO          = prime_ai_tarun
BRANCH            = Brijesh_Finance
DEVELOPER         = Brijesh
RBS_MODULE_CODE   = L
DB_TABLE_PREFIX   = prl_
DATABASE_NAME     = tenant_db
DDL_OUTPUT_DIR    = databases/1-Work-In-Progress/21-Payroll/DDL
OTHER_OUTPUT_DIR  = databases/5-Work-In-Progress/21-Payroll/2-Claude_Plan
MIGRATION_DIR     = prime_ai_tarun/database/migrations/tenant
REQUIREMENT_FILE  = databases/1-DDL_Tenant_Modules/21-Payroll/Claude_Plan/Payroll_Requirement_v4.md
PLAN_FILE         = databases/1-DDL_Tenant_Modules/20-Account/Claude_Plan/Initial_Plan_v4.md
RBS_FILE          = 3-Project_Planning/1-RBS/PrimeAI_RBS_Menu_Mapping_v2.0.md
DDL_DIR           = databases/1-DDL_Tenant_Modules/21-Payroll/DDL
PERMISSION_GATE   = payroll.resource.action
FEATURE_FILE      = `PRL_FeatureSpec.md`
DEV_PLAN_FILE     = `PRL_Dev_Plan.md`
DDL_FILE_NAME     = `prl_DDL_v1.sql`
```

---

## HOW TO USE THIS PROMPT

1. Execute this document into a new Claude conversation
2. Tell Claude: **"Start Phase 1"**
3. Claude will read the required files, generate the output, and STOP
4. You review the output, give feedback or confirm: **"Approved. Proceed to Phase 2"**
5. Repeat for all the phases
6. For Phase 3 (Screen Planning): YOU provide your layout decisions, then Claude confirms

---

## PHASE 1 — Requirements, Feature Specification & Development Plan
### Phase 1 Input Files
Read these files BEFORE generating output:
1. `{REQUIREMENT_FILE}` — Complete {MODULE} Module requirement
2. `{PLAN_FILE}` — Initial plan with architecture and table summary
3. `{RBS_FILE}` — Find Module {RBS_MODULE_CODE} section
4. `AI_Brain/memory/project-context.md` — Project context
5. `AI_Brain/memory/modules-map.md` — Existing modules (avoid duplication)
6. `AI_Brain/agents/business-analyst.md` — BA agent instructions

### Phase 1 Tasks:
- Generate a comprehensive Feature Specification for the {MODULE} Module.
- Generate a Detailed Development Plan for {MODULE} Module.

**Module:** {MODULE}
**RBS Module Code:** {RBS_MODULE_CODE}
**Table Prefix:** {DB_TABLE_PREFIX}
**Database:** tenant_db
**Description:** Payroll Module will cover entire Slary payment System for the School including Attendance management of the Staff, Leave Management, Apprisal Process, Rating, etc.

**No wireframes.** Generate the feature specification from:
- 1-DDL_Tenant_Modules/21-Payroll/Claude_Plan/Payroll_Requirement_v4.md
- Initial_Plan_v4.md (architecture, integration points)
- RBS Module {RBS_MODULE_CODE} sub-tasks
- Indian K-12 school domain knowledge
- Patterns from existing Prime-AI modules

**Generate:**
1. Entity list — all the tables with columns, types, relationships
2. Entity Relationship Diagram (text-based)
3. Business rules — validation rules, cascade behaviors, status workflows
4. Permission list — all Gate permissions needed {PERMISSION_GATE} format
5. Dependencies — which existing modules this connects to
6. Integration events — with other Modules

Do NOT generate screen layouts yet — that comes in Phase 3.

### Phase 1 Output Files
| File | Location |
|------|----------|
| {FEATURE_FILE} | `{OTHER_OUTPUT_DIR}/{FEATURE_FILE}` |
| {DEV_PLAN_FILE} | `{OTHER_OUTPUT_DIR}/{DEV_PLAN_FILE}` |


### Phase 1 Quality Gate
- [ ] Every RBS sub-task maps to at least one entity/column
- [ ] All the table relationships (FK) are defined
- [ ] Table names use `{DB_TABLE_PREFIX}` prefix convention
- [ ] All cross-module integration events listed

**After completing Phase 1, STOP and say:** "Phase 1 (Feature Specification) complete. Output: {FEATURE_FILE} & {DEV_PLAN_FILE}. Please review and confirm to proceed to Phase 2 (DDL Design)."

---

## PHASE 2 — Database Schema Design (DDL + Seeders)
### Phase 2 Input Files
1. `{OTHER_OUTPUT_DIR}/{FEATURE_FILE}` — Feature spec from Phase 1
2. `{REQUIREMENT_FILE}` — Required Table schemas
3. `AI_Brain/agents/db-architect.md` — DB Architect agent instructions
4. `databases/0-DDL_Masters/tenant_db_v2.sql` — Existing schema for reference

### Phase 2A Task — Generate DDL
Generate the DDL SQL for all the tables in the {MODULE} Module.

**Rules (MUST follow):**
1. Table prefix: `{DB_TABLE_PREFIX}`
2. Every table MUST have: `id` (BIGINT UNSIGNED AUTO_INCREMENT), `is_active`, `created_by`, `created_at`, `updated_at`, `deleted_at`
3. Index ALL foreign keys
4. Junction tables suffix: `_jnt`
5. JSON columns suffix: `_json`
6. Boolean columns prefix: `is_` or `has_`
7. Use `BIGINT UNSIGNED` for all IDs
8. Add `COMMENT` on every column
9. Use InnoDB, utf8mb4_unicode_ci

**Generate:**
1. DDL SQL file — all CREATE TABLE statements with comments
2. Laravel Migration file — for `database/migrations/tenant/`
3. Table summary — one-line description of each table, which clude what this will be used for

### Phase 2B Task — Generate Seeders
Generate Laravel seeders for all the Tables.

### Phase 2 Output Files
| File | Location |
|------|----------|
| `{DDL_FILE_NAME}` | `{DDL_OUTPUT_DIR}/{DDL_FILE_NAME}` |
| `{DB_TABLE_PREFIX}Migration.php` | `{DDL_OUTPUT_DIR}/{DB_TABLE_PREFIX}Migration.php` |
| `{DB_TABLE_PREFIX}Seeders/` | `{DDL_OUTPUT_DIR}/{DB_TABLE_PREFIX}Seeders/` |
| `{DB_TABLE_PREFIX}TableSummary.md` | `{DDL_OUTPUT_DIR}/{DB_TABLE_PREFIX}TableSummary.md` |

### Phase 2 Quality Gate
- [ ] All 21 tables from requirement exist in DDL
- [ ] Foreign keys match referenced tables with correct `acc_` prefix
- [ ] Required columns (id, is_active, created_by, timestamps, deleted_at) on ALL tables
- [ ] `acc_vouchers` has source_module + source_type + source_id (polymorphic)
- [ ] `acc_ledgers` has student_id→std_students, employee_id→sch_employees, vendor_id→vnd_vendors
- [ ] sch_employees ALTER TABLE adds 14 columns with Schema::hasColumn() guard