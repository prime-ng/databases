# Module Gap Analysis Prompt
# Usage: Fill in the CONFIGURATION block, then paste the full prompt to Claude Code with db-analyzer agent.

---

## CONFIGURATION (edit these values before running)

```
MODULE_NAME       = "Accounting"           # e.g. StudentFee, SmartTimetable, SchoolSetup
MODULE_CODE_PATH  = "/Users/bkwork/Herd/prime_ai/Modules/Accounting"
DDL_FILE          = "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/40-Accounting/DDL/ACC_DDL_v2.sql"
MIGRATION_PATH    = "/Users/bkwork/Herd/prime_ai/database/migrations/tenant"
TABLE_PREFIX      = "acc_"                 # e.g. fin_, sch_, tt_, std_
```

---

## PROMPT (paste this to Claude Code after filling configuration above)

```
You are a db-analyzer agent. Perform a full gap analysis for the **{MODULE_NAME}** module.

## Inputs
- DDL file: `{DDL_FILE}`
- Module code: `{MODULE_CODE_PATH}`
- Tenant migrations: `{MIGRATION_PATH}` (filter files containing `{TABLE_PREFIX}`)
- Table prefix: `{TABLE_PREFIX}`

## Analysis Steps

### Step 1 — DDL Inventory
Read `{DDL_FILE}` and extract ALL tables with prefix `{TABLE_PREFIX}`. For each table list every column with: name, type, nullable, default, constraints (PK/FK/UNIQUE/INDEX).

### Step 2 — Migration Analysis
Read all migration files in `{MIGRATION_PATH}` that create or alter `{TABLE_PREFIX}*` tables. For each migration:
- List columns defined
- Compare against DDL: flag MISSING columns (in DDL but not in migration) and EXTRA columns (in migration but not in DDL)
- Flag wrong types, wrong nullability, missing indexes

### Step 3 — Model Analysis
Read all Model files under `{MODULE_CODE_PATH}/app/Models/`. For each model mapped to a `{TABLE_PREFIX}*` table:
- Check `$fillable` — flag DDL columns missing from fillable
- Check `$casts` — flag columns that should be cast (JSON, boolean, decimal, date) but aren't
- Check `$hidden` — note any sensitive columns not hidden
- Check relationships — flag FKs in DDL that have no corresponding relationship method
- Flag `$table` if model uses a non-standard table name

### Step 4 — Form Request Analysis
Read all FormRequest files under `{MODULE_CODE_PATH}/app/Http/Requests/`. For each request:
- Compare validated fields against DDL columns for the target table
- Flag DDL columns with NOT NULL + no default that are absent from validation rules
- Flag fields validated but not present in DDL

### Step 5 — Controller Analysis
Read all Controllers under `{MODULE_CODE_PATH}/app/Http/Controllers/`. For each controller:
- Check store/update methods: flag DDL columns being silently ignored (not in request, not defaulted)
- Flag hardcoded values that should come from DDL defaults
- Flag missing `is_active`, `created_by`, `deleted_at` handling

### Step 6 — Cross-Reference Summary
Produce a consolidated report with these sections:

#### 6a. DDL vs Migration
| Table | Column | Issue | Severity |
|-------|--------|-------|----------|
| ...   | ...    | MISSING in migration / EXTRA in migration / Wrong type / Missing index | P0/P1/P2 |

#### 6b. DDL vs Models
| Table | Model | Column/Relationship | Issue | Severity |
|-------|-------|---------------------|-------|----------|

#### 6c. DDL vs Form Requests
| Table | Request File | Field | Issue | Severity |
|-------|-------------|-------|-------|----------|

#### 6d. DDL vs Controllers
| Table | Controller | Issue | Severity |
|-------|-----------|-------|----------|

#### 6e. Overall Discrepancy Count
- P0 (data loss risk / security): X
- P1 (functional bug): X
- P2 (code quality / incomplete): X
- Total: X

## Severity Definitions
- **P0** — Missing NOT NULL column with no default (will crash on insert), missing FK index, security field absent
- **P1** — Column in DDL missing from fillable/validation (data silently dropped), wrong cast causing data corruption
- **P2** — Extra field in code not in DDL, missing relationship method, missing cast for non-critical column

## Output Format
- Use the tables above for each section
- After each section table add a **Key Findings** bullet list (most critical first)
- End with a **Recommended Fix Order** numbered list
- Be precise: include file path + line number for every issue found
```

---

## Notes
- Use `subagent_type: "db-analyzer"` and `model: "sonnet"` when spawning via Agent tool
- For large modules (SmartTimetable 84 models), split into sub-tasks per controller group
- Always run against v2 DDL files only — never use non-v2 or subfolder DDL files if not specificly asked to do so
