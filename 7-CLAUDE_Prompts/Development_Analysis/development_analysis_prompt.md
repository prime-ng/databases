# Module Development Gap Analysis Prompt
# Usage: Fill in the CONFIGURATION block, then paste the full PROMPT section to Claude Code (db-analyzer agent, Sonnet model).

---

## CONFIGURATION (edit these values before running)

```
MODULE_NAME       = "Accounting"
MODULE_CODE_PATH  = "/Users/bkwork/Herd/prime_ai/Modules/Accounting"
DDL_FILE          = "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/40-Accounting/DDL/ACC_DDL_v2.sql"
MIGRATION_PATH    = "/Users/bkwork/Herd/prime_ai/database/migrations/tenant"
TABLE_PREFIX      = "acc_"
OUTPUT_FILE       = "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/3-Project_Planning/4-Development_Analysis/2-Modules_Wise_Analysis/Accounting_gap_report.md"
```

---

## PROMPT (paste this to Claude Code after substituting the configuration values above)

```
You are a db-analyzer agent. Perform a full gap analysis for the **{MODULE_NAME}** module and save the complete report to `{OUTPUT_FILE}`.

---

## Inputs
- DDL file:           `{DDL_FILE}`
- Module code:        `{MODULE_CODE_PATH}`
- Tenant migrations:  `{MIGRATION_PATH}` (only files whose name contains `{TABLE_PREFIX}`)
- Table prefix:       `{TABLE_PREFIX}`
- Output report file: `{OUTPUT_FILE}`

---

## Analysis Steps

### Step 1 — DDL Inventory
Read `{DDL_FILE}` and extract ALL tables whose name starts with `{TABLE_PREFIX}`.
For each table record:
- Table name + purpose (inferred from name)
- Every column: name, data type, nullable (YES/NO), default value, constraints (PK / FK / UNIQUE / INDEX)
- All foreign key references (source column → target table.column)
- All indexes (name, columns covered, type: PRIMARY / UNIQUE / INDEX)

### Step 2 — Migration Analysis
Read every migration file in `{MIGRATION_PATH}` that creates or alters a `{TABLE_PREFIX}*` table.
For each migration file:
- Record: file name, table name, operation (create / alter / drop)
- List every column it defines (name, type, nullable, default)
- Compare column-by-column against DDL and flag:
  - **MISSING** — column exists in DDL but is absent from migration
  - **EXTRA** — column exists in migration but is absent from DDL
  - **TYPE MISMATCH** — column exists in both but data type differs
  - **NULLABLE MISMATCH** — DDL says NOT NULL but migration allows null (or vice versa)
  - **DEFAULT MISMATCH** — default value differs between DDL and migration
  - **MISSING INDEX** — FK or frequently queried column in DDL has no index in migration
  - **MISSING STANDARD COLUMN** — any of `id`, `is_active`, `created_by`, `created_at`, `updated_at`, `deleted_at` absent

### Step 3 — Model Analysis
Read every Model file under `{MODULE_CODE_PATH}/app/Models/`.
For each model that maps to a `{TABLE_PREFIX}*` table:
- Confirm `$table` property matches the DDL table name
- Check `$fillable` — flag DDL columns that are absent (data will be silently dropped on mass-assignment)
- Check `$guarded` — if `$guarded = []` flag it as a security concern
- Check `$casts` — flag columns that need casting but lack it:
  - `*_json` columns → should be cast to `array`
  - `is_*` / `has_*` columns → should be cast to `boolean`
  - `decimal` / `numeric` columns → should be cast to `decimal:2` or `float`
  - `date` / `datetime` / `timestamp` columns → should be cast to `datetime` or `date`
- Check `$hidden` — flag sensitive columns (password, token, pin, secret) not in `$hidden`
- Check `$dates` / `$appends` for stale patterns (Laravel 10+ uses `$casts` for dates)
- Check relationships — for every FK in DDL, confirm a `belongsTo` / `hasMany` / `belongsToMany` method exists; flag missing ones
- Flag any hardcoded tenant IDs or session IDs in model scopes

### Step 4 — Form Request Analysis
Read every FormRequest file under `{MODULE_CODE_PATH}/app/Http/Requests/`.
For each request (map it to a table by controller/method name):
- Flag DDL columns that are NOT NULL with no default but are absent from `rules()` (will cause DB error)
- Flag DDL columns present in `rules()` with no corresponding column in DDL (phantom validation)
- Flag columns that exist in DDL and in `rules()` but whose validation type contradicts the DDL type
  (e.g. DDL says `TINYINT(1)` but rule is `string`)
- Flag missing `sometimes` / `nullable` on truly optional columns
- Flag `authorize()` returning `true` without any policy check (security gap)

### Step 5 — Controller Analysis
Read every Controller under `{MODULE_CODE_PATH}/app/Http/Controllers/`.
For each `store()` and `update()` method:
- Flag DDL columns that are NOT NULL + no default but are neither in the request nor set explicitly in the method (will crash on insert)
- Flag columns set by hardcoded literals that should come from the authenticated user (`created_by`, `tenant_id`)
- Flag missing soft-delete guard (`withTrashed` / `onlyTrashed` misuse)
- Flag missing `is_active` default on create
- Flag `$request->all()` usage without explicit column filtering (mass-assignment risk)
- Flag missing authorization (`$this->authorize(...)` or `Gate::authorize(...)`) on any CRUD method

### Step 6 — Views / Blade Analysis (optional but recommended)
Read Blade view files under `{MODULE_CODE_PATH}/resources/views/`.
For each `<form>` that submits to a store/update route:
- Flag DDL columns that are NOT NULL + no default but have no corresponding `<input>` / `<select>` / hidden field
- Flag `<input name="...">` fields whose name does not match any DDL column (phantom POST fields)

---

## Output Report Structure

Produce the report in Markdown. Include ALL sections below exactly as specified.

---

### Report Header

```
# {MODULE_NAME} Module — Gap Analysis Report
**Generated:** {current date}
**DDL Source:** {DDL_FILE}
**Module Code:** {MODULE_CODE_PATH}
**Migration Path:** {MIGRATION_PATH}
**Table Prefix:** {TABLE_PREFIX}
```

---

### Section 1 — DDL Table Inventory

For EACH table:

#### `{table_name}`
| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| ...    | ...  | ...      | ...     | ...         |

**Indexes:**
| Index Name | Columns | Type |
|------------|---------|------|

**Foreign Keys:**
| Column | References |
|--------|-----------|

---

### Section 2 — Migration vs DDL

#### 2a. Migration File Coverage
| Migration File | Table | Operation | Status |
|---------------|-------|-----------|--------|
| ...           | ...   | create/alter | OK / HAS ISSUES |

#### 2b. Column-Level Discrepancies
| Table | Column | Migration Value | DDL Value | Issue Type | Severity |
|-------|--------|----------------|-----------|------------|----------|
| ...   | ...    | ...            | ...       | MISSING / EXTRA / TYPE MISMATCH / etc. | P0 / P1 / P2 |

**Key Findings (Migration):**
- (bullet list, most critical first)

---

### Section 3 — Model vs DDL

#### 3a. Model Coverage
| Model File | Mapped Table | $table Correct? |
|-----------|-------------|-----------------|

#### 3b. $fillable Gaps
| Model | Missing Column | DDL Type | Impact |
|-------|---------------|----------|--------|

#### 3c. $casts Gaps
| Model | Column | DDL Type | Required Cast | Current Cast |
|-------|--------|----------|--------------|-------------|

#### 3d. Missing Relationships
| Model | FK Column | Should Have | Missing Method |
|-------|-----------|------------|----------------|

#### 3e. Security Concerns
| Model | Issue | Detail |
|-------|-------|--------|

**Key Findings (Models):**
- (bullet list, most critical first)

---

### Section 4 — Form Request vs DDL

#### 4a. Missing Required Field Validation
| Request File | Table | Column | DDL Constraint | Issue |
|-------------|-------|--------|---------------|-------|

#### 4b. Phantom Validated Fields
| Request File | Field | Not in DDL | Note |
|-------------|-------|-----------|------|

#### 4c. Type Contradiction
| Request File | Field | Rule | DDL Type | Issue |
|-------------|-------|------|----------|-------|

#### 4d. Authorization Gaps
| Request File | authorize() Returns | Issue |
|-------------|---------------------|-------|

**Key Findings (Form Requests):**
- (bullet list, most critical first)

---

### Section 5 — Controller vs DDL

#### 5a. Unhandled Required Columns
| Controller | Method | Table | Column | DDL Constraint | Risk |
|-----------|--------|-------|--------|---------------|------|

#### 5b. Mass-Assignment Risks
| Controller | Method | Issue |
|-----------|--------|-------|

#### 5c. Missing Authorization
| Controller | Method | Issue |
|-----------|--------|-------|

**Key Findings (Controllers):**
- (bullet list, most critical first)

---

### Section 6 — View vs DDL (if views exist)

#### 6a. Missing Form Inputs for Required Columns
| View File | Form Action | Missing Input | DDL Constraint |
|----------|------------|--------------|---------------|

#### 6b. Phantom Form Inputs
| View File | Input Name | Not in DDL |
|----------|-----------|-----------|

**Key Findings (Views):**
- (bullet list, most critical first)

---

### Section 7 — Overall Discrepancy Summary

#### 7a. Counts by Layer and Severity
| Layer | P0 | P1 | P2 | Total |
|-------|----|----|----|-------|
| Migration vs DDL | | | | |
| Model vs DDL     | | | | |
| Form Request vs DDL | | | | |
| Controller vs DDL | | | | |
| View vs DDL      | | | | |
| **TOTAL**        | | | | |

#### 7b. Tables with Zero Coverage
List any DDL tables that have NO migration file, NO model, and NO controller:
- `{table_name}` — completely unimplemented

#### 7c. Severity Definitions Used
| Severity | Meaning |
|----------|---------|
| P0 | Data loss / crash risk: NOT NULL column missing from migration or fillable; missing FK index; security field absent; authorize() always returns true |
| P1 | Functional bug: column silently dropped (missing fillable/validation); wrong cast causing data corruption; missing required relationship |
| P2 | Code quality / incomplete: extra phantom field; missing optional cast; missing soft-delete handling; minor type mismatch |

---

### Section 8 — Recommended Fix Order

Numbered list ordered by severity (P0 first), then by layer (Migration → Model → Request → Controller → View).
Each item must include:
- Severity badge: `[P0]` / `[P1]` / `[P2]`
- File path and line number (if applicable)
- Exact fix description (e.g. "Add column `account_type` VARCHAR(50) NOT NULL to migration `2024_01_15_create_acc_ledgers_table.php`")

Example format:
1. [P0] `database/migrations/tenant/2024_xx_xx_create_acc_ledgers_table.php` — Add missing column `balance_type` ENUM('Dr','Cr') NOT NULL
2. [P1] `Modules/Accounting/app/Models/Ledger.php:34` — Add `balance_type` to `$fillable`
3. ...

---

## Final Instruction

After completing all analysis steps and building the full report in memory, use the **Write tool** to save the complete report to:

`{OUTPUT_FILE}`

The file must contain the full Markdown report from "Report Header" through "Recommended Fix Order". Do not truncate any section. If a section has no issues, write "No issues found." under it — do not omit the section header.

Confirm the save by outputting:
`Report saved to: {OUTPUT_FILE}`
```

---

## Notes
- Use `subagent_type: "db-analyzer"` and `model: "sonnet"` when spawning via Agent tool
- Ensure the output Reports folder exists before running — create it if needed
- For large modules (SmartTimetable — 84 models), split Step 3 and Step 5 across multiple sub-tasks
- Always use v2 DDL files only — never reference non-v2 files or files from subfolders
- The OUTPUT_FILE name should follow the convention: `{ModuleName}_gap_report.md`
