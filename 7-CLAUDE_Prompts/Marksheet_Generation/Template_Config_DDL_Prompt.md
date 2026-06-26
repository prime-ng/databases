# Template Output Configuration — DDL Schema Prompt

**Purpose:** Design a DDL schema for the **Template Output Configuration** feature — a configurable system that allows schools to assign which visual template (`tmp_templates`) to use for each output purpose (Marksheet Printing, Student ID Card, Staff ID Card, etc.), per class group, per class, or school-wide. This bridges the generic Template module with all consuming modules (MarksheetGeneration, StudentProfile, HPC, etc.).

**Developer:** Brijesh
**Date:** 2026-04-15

---

## DEFAULT PATHS

Read `{AI_BRAIN}/config/paths.md` — resolve all path variables from this file.

## Rules

- All paths come from `paths.md` unless overridden in CONFIGURATION below.
- If a variable exists in both `paths.md` and CONFIGURATION, the CONFIGURATION value wins.
- **NEVER use `tenant_id` columns** — this is a dedicated-database-per-tenant system (stancl/tenancy v3.9).
- **NEVER use ENUMs** — use `sys_dropdown_table` or a dedicated lookup table instead.
- Follow table naming conventions: prefix `tmp_*` for Template module tables, junction tables suffixed `_jnt`, JSON columns suffixed `_json`, boolean columns prefixed `is_` or `has_`.
- Every table MUST include: `id`, `is_active`, `created_by`, `created_at`, `updated_at`, `deleted_at`.
- **VALIDATION RULE:** Before referencing any column from an existing table, confirm the column exists in the DDL or migration. If it doesn't exist, flag it as a pre-development verification item.

---

## Repositories

```
DB_REPO        = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase
OLD_REPO       = /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db
AI_BRAIN       = {OLD_REPO}/AI_Brain
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai
LARAVEL_CLAUDE = {LARAVEL_REPO}/.claude/rules
```

## CONFIGURATION

```
MODULE_CODE       = MSG
MODULE            = MarksheetGeneration
MODULE_DIR        = Modules/MarksheetGeneration/
BRANCH            = Brijesh_Main
RBS_MODULE_CODE   = T                              # Tenant module
DB_TABLE_PREFIX   = msh_                           # Prefix for new tables
DATABASE_NAME     = tenant_db

OUTPUT_DIR        = {OLD_REPO}/1-DDL_Tenant_Modules/Template
MIGRATION_DIR     = {LARAVEL_REPO}/database/migrations/tenant
TENANT_DDL        = {DB_REPO}/1-Master_DDLs/tenant_db_v2.sql
```

---

## HOW TO USE THIS PROMPT

1. Paste this entire document into a new Claude conversation
2. Say: **"Execute"**
3. Claude reads all required files, analyses the architecture, and generates the DDL schema
4. Review the output; give feedback or approve

---

## FILES TO READ (MANDATORY — Read ALL before generating DDL)

### Template Module (current state)
1. **`{LARAVEL_REPO}/Modules/Template/app/Models/Template.php`**
   — Understand `tmp_templates` table structure (columns: name, type, canvas_json, html_content, variables, background_image, is_active)

2. **`{LARAVEL_REPO}/Modules/Template/app/Http/Controllers/TemplateController.php`**
   — Understand existing CRUD operations and how templates are managed

3. **`{LARAVEL_REPO}/Modules/Template/routes/web.php`**
   — Understand existing route structure

4. **`{LARAVEL_REPO}/Modules/Template/database/migrations/`**
   — Check if `tmp_templates` migration exists (it may NOT exist yet — if missing, the DDL must include it)
   **`{OLD_REPO}/1-DDL_Tenant_Modules/Template/tmp_Template_ddl.sql`**
   — Read and understand how marksheet template capture config information to use in Template Module.

### MarksheetGeneration Module (primary consumer)
5. **`{OLD_REPO}/1-DDL_Tenant_Modules/LMS_MarksheetGeneration/DDL/MSG_DDL_v1.sql`**
   — Read FULL DDL. Focus on: `msh_class_groups`, `msh_class_group_items_jnt`, `msh_config_templates`, `msh_class_config_jnt`
   — Understand how marksheet configs are already assigned to class groups

6. **`{OLD_REPO}/1-DDL_Tenant_Modules/LMS_MarksheetGeneration/MSG_DataDictionary.md`**
   — Understand class group and config assignment semantics

### SchoolSetup Module (shared infrastructure)
7. **`{TENANT_DDL}`** (tenant_db_v2.sql)
   — Read `sch_classes`, `sch_org_academic_sessions_jnt`, `sys_dropdown_table` table structures
   — Verify FK column types (sch_classes.id = INT UNSIGNED, sch_org_academic_sessions_jnt.id = SMALLINT UNSIGNED, sys_dropdown_table.id = INT UNSIGNED)

### HPC Module (another consumer of visual templates)
8. **`{LARAVEL_REPO}/database/migrations/tenant/2026_02_24_100001_create_hpc_templates_table.php`**
   — Understand how HPC templates are structured (for reference — HPC has its own template system, but may eventually use `tmp_templates` for PDF layouts)

### AI Brain Context
9. **`{AI_BRAIN}/memory/project-context.md`** — Full project context
10. **`{AI_BRAIN}/memory/tenancy-map.md`** — Multi-tenancy architecture
11. **`{AI_BRAIN}/rules/tenancy-rules.md`** — Tenancy rules (no tenant_id)
12. **`{AI_BRAIN}/rules/module-rules.md`** — Module development rules

---

## BUSINESS CONTEXT — Template Output Configuration

### The Problem

Prime-AI has a generic **Template module** (`Modules/Template`) with a canvas-based visual template builder (`tmp_templates`). Schools create visual templates for various outputs: Marksheet PDF, Student ID Card, Staff ID Card, Transfer Certificate, Admission Letter, etc.

Currently there is **NO configurable system** to say:
- "Use Template A for Marksheet Printing for Primary classes (1-5)"
- "Use Template B for Marksheet Printing for Secondary classes (6-12)"
- "Use Template C for Student ID Card printing for ALL classes"
- "Use Template D for Staff ID Card printing"

Each school may have **multiple templates for the same purpose** and needs to configure which template is active for which target audience.

### Requirements

1. **Template Purpose Registry:** A lookup table defining all output purposes a template can serve (e.g., MARKSHEET_PRINT, STUDENT_ID_CARD, STAFF_ID_CARD, TRANSFER_CERTIFICATE, ADMISSION_LETTER, CUSTOM). This should be extensible by schools.

2. **Template-to-Purpose Assignment:** Link a `tmp_templates` record to a specific purpose. One template can serve one purpose only (a marksheet template should not accidentally be used for ID cards).

3. **Scope-Based Configuration:** Schools can assign templates at different scopes:
   - **Class Group scope** — Use template X for all classes in `msh_class_groups` group "Primary (1-5)"
   - **Direct Class scope** — Use template Y for Class 9 specifically (overrides class group)
   - **School-wide scope** — Use template Z for all (no class filtering — applicable for Staff ID Card, etc.)
   - Direct class assignment takes **priority** over class group assignment.

4. **Academic Session Awareness:** Configuration should be tied to an academic session (`sch_org_academic_sessions_jnt.id`) so schools can change templates per year without losing history.

5. **Uniqueness Constraint:** For a given purpose + session + scope target, only ONE active template assignment should exist. Prevent duplicate assignments (e.g., two marksheet templates for the same class group in the same session).

6. **Integration with `msh_config_templates`:** The marksheet computation config (`msh_config_templates`) defines WHAT scores go into the marksheet. The template output config defines HOW the marksheet looks. These are separate concerns but linked at generation time:
   - `msh_config_templates` → computation rules (weightages, grading, pass criteria)
   - Template Output Config → visual layout (PDF template with canvas/HTML)
   - At marksheet generation time, the system resolves BOTH: the computation config AND the print template for a given class.

7. **Soft Delete + Audit:** All tables must use soft deletes. Track `created_by`, `updated_by`.

### Use Cases

| Actor | Use Case | Notes |
|---|---|---|
| School Admin | Define template purposes (if school needs custom purpose) | Rare — most purposes are seeded |
| School Admin | Assign a visual template to "Marksheet Printing" for class group "Primary" in session 2025-26 | Most common use case |
| School Admin | Assign a different visual template to "Marksheet Printing" for class group "Secondary" in same session | Different marksheet look per class group |
| School Admin | Override class group template for a specific class (e.g., Class 10 uses a special board-format template) | Direct class override |
| School Admin | Assign a visual template for "Student ID Card" school-wide (no class filter) | School-wide assignment |
| System | At marksheet generation time, resolve: for Class 5, Session 2025-26 → which print template? | Resolution: check direct class → then class group → then school-wide → error if none |
| System | At ID card generation time, resolve: for "Student ID Card" → which template? | Resolution: school-wide lookup |

### NOT In Scope

- Changes to `msh_config_templates` or any existing MSG DDL tables
- Changes to `hpc_templates` or any existing HPC tables
- Changes to `fbk_templates` or Feedback tables
- Template builder UI/UX (that already exists in Template module)
- The actual PDF rendering logic (DomPDF service)

---

## OUTPUT SPECIFICATION

Generate a **single DDL file** named `Template_Config_DDL_v1.sql` saved to `{OUTPUT_DIR}/` containing:

### Required Sections in Output:

1. **Header Comment Block** — Module name, version, author, date, purpose, table count, dependency summary

2. **Table: `tmp_template_purposes`** — Lookup/registry of output purposes
   - Consider columns: id, code, name, description, scope_type (determines what scope fields are applicable), display_order, is_system (seeded vs user-created), is_active, audit columns
   - Seed data (INSERT statements) for: MARKSHEET_PRINT, STUDENT_ID_CARD, STAFF_ID_CARD, TRANSFER_CERTIFICATE, ADMISSION_LETTER, FEE_RECEIPT, BONAFIDE_CERTIFICATE
   - `code` must be UNIQUE
   - Think about whether `scope_type` should indicate if this purpose supports class-level scoping, school-wide-only scoping, or both

3. **Table: `tmp_template_assignments`** — The main configuration table
   - Links: `tmp_templates.id` (which template), `tmp_template_purposes.id` (for what purpose), academic session, and scope target
   - Scope target: `class_id` (nullable), `class_group_id` (nullable), with CHECK constraint or a scope resolution strategy
   - School-wide = both `class_id` and `class_group_id` are NULL
   - Must handle: "for purpose X, in session Y, targeting scope Z, use template T"
   - Uniqueness constraint must prevent duplicate assignments for the same purpose + session + target
   - Consider: should this table also reference `msh_config_templates.id` for marksheet-specific linkage? (Evaluate — may be unnecessary coupling)

4. **Indexes** — All FKs indexed. Composite indexes for common lookup patterns (purpose + session + class, purpose + session + class_group).

5. **Foreign Keys** — With correct column types matching referenced tables:
   - `sch_classes.id` = INT UNSIGNED
   - `sch_org_academic_sessions_jnt.id` = SMALLINT UNSIGNED
   - `msh_class_groups.id` = INT UNSIGNED
   - `tmp_templates.id` = check model (likely INT UNSIGNED)
   - `sys_dropdown_table.id` = INT UNSIGNED (if used)

6. **CHECK Constraints** — Enforce data integrity (e.g., exactly one scope target, or NULL for school-wide)

7. **Resolution Logic Comment** — Add a SQL comment block documenting the template resolution algorithm:
   ```
   -- RESOLUTION PRIORITY (for class-scoped purposes like MARKSHEET_PRINT):
   -- 1. Direct class match: WHERE purpose_id = ? AND session_id = ? AND class_id = ?
   -- 2. Class group match: WHERE purpose_id = ? AND session_id = ? AND class_group_id = (SELECT class_group_id FROM msh_class_group_items_jnt WHERE class_id = ?)
   -- 3. School-wide fallback: WHERE purpose_id = ? AND session_id = ? AND class_id IS NULL AND class_group_id IS NULL
   -- 4. Not found → error (no template configured)
   ```

8. **Migration Note** — Note that `tmp_templates` migration may need to be created first if it doesn't exist. List the migration dependency order.

### Also Generate:

9. **Data Dictionary Section** — For each table and column:
   - Column name, type, nullable, default, description, FK reference
   - Sample data rows
   - Business rule references

### Evaluation Criteria (Self-Check Before Output):

- [ ] Every FK column type matches the referenced PK type exactly
- [ ] No ENUMs used — all status/type codes use lookup tables or `sys_dropdown_table`
- [ ] No `tenant_id` column anywhere
- [ ] Every table has: `id`, `is_active`, `created_by`, `created_at`, `updated_at`, `deleted_at`
- [ ] CHECK constraints enforce scope target rules
- [ ] Uniqueness constraints prevent duplicate assignments
- [ ] Seed data covers the 7 standard purposes
- [ ] Resolution logic is documented
- [ ] No changes to any existing tables (pure additive)
- [ ] `class_group_id` FK references `msh_class_groups.id` (MSG module's table), NOT `sch_class_groups_jnt`

---

## ARCHITECTURAL NOTES FOR CLAUDE

### Separation of Concerns

```
tmp_templates          → WHAT the template LOOKS LIKE (canvas, HTML, variables)
tmp_template_purposes  → WHAT KINDS of outputs exist (marksheet, ID card, TC, etc.)
tmp_template_assignments → WHO uses WHICH template for WHAT purpose in WHICH session

msh_config_templates   → HOW marksheet scores are COMPUTED (weightages, grading) [SEPARATE MODULE — DO NOT TOUCH]
msh_class_config_jnt   → WHICH computation config applies to WHICH class [SEPARATE MODULE — DO NOT TOUCH]
```

At marksheet generation time, the system needs BOTH:
- From MSG: `msh_config_templates` (via `msh_class_config_jnt`) → computation rules
- From Template: `tmp_template_assignments` (via this new DDL) → PDF visual layout

These are resolved independently and combined at render time. Do NOT create FK coupling between them.

### Class Group Reuse

`msh_class_groups` was deliberately created as a marksheet-specific grouping (Decision D-MSG-003). It is reusable for template assignment since the grouping concept is the same: "Primary (1-5)", "Secondary (6-12)", etc. The Template module should reference `msh_class_groups` directly rather than creating a duplicate grouping system.

If this creates an undesirable cross-module dependency (Template → MarksheetGeneration), consider whether a shared/generic `sch_class_groups` table should be proposed instead. Document this decision with rationale.

### `tmp_templates.type` Column

The existing `tmp_templates` model has a `type` column (VARCHAR). Evaluate whether this column serves the same purpose as `tmp_template_purposes.code`. If so, the assignment table may only need to link `tmp_templates.id` directly (where the purpose is already encoded in the template's `type`). If `type` is free-text and unreliable, the separate `tmp_template_purposes` table is warranted. Document this analysis.

---

*End of Prompt*
