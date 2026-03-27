# Document Duplicate Constraint Columns — Tech Debt Plan

| Field              | Value                          |
|--------------------|--------------------------------|
| **Task ID**        | P3_15                          |
| **Issue IDs**      | Tech debt                      |
| **Priority**       | P3-Low                         |
| **Estimated Effort** | 30 min                       |
| **Prerequisites**  | All P2                         |

---

## CONFIGURATION

```
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai_tarun
MODULE_PATH    = /Users/bkwork/Herd/prime_ai_tarun/Modules/SmartTimetable
DDL_FILE       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/0-DDL_Masters/tenant_db_v2.sql
BRANCH         = Brijesh_SmartTimetable
```

---

## CONTEXT

The fix migration `2026_03_12_100001` added new columns to `tt_constraint_types` and `tt_constraints` without dropping the old columns they replaced. This means both tables now have duplicate pairs of columns serving the same purpose:

**tt_constraint_types:**
| Old Column (dead) | New Column (active) |
|---|---|
| `is_hard_constraint` | `is_hard_capable` |
| `param_schema` | `parameter_schema` |

**tt_constraints:**
| Old Column (dead) | New Column (active) |
|---|---|
| Various alias columns | Corresponding renamed columns |

This creates confusion (which column to read/write?) and data consistency risk (old column may have stale data while new column has current data).

---

## PRE-READ

- `{MODULE_PATH}/database/migrations/2026_03_12_100001_*.php` — the fix migration that added new columns
- `{MODULE_PATH}/app/Models/ConstraintType.php` — to verify which columns the model reads
- `{MODULE_PATH}/app/Models/Constraint.php` — to verify which columns the model reads
- `{DDL_FILE}` — to see the canonical DDL definition

---

## STEPS

### Step 1 — Document Old vs New Columns

Create a tech debt documentation section (in this file or a linked file) listing:

For each affected table (`tt_constraint_types`, `tt_constraints`):
- Column name (old)
- Column name (new)
- Data type of each
- Which one the model's `$fillable` / `$casts` references
- Whether the old column has any data

### Step 2 — Verify Models Only Use New Columns

Check the following model files and confirm they reference ONLY the new column names:

```bash
grep -n "is_hard_constraint\|param_schema" {MODULE_PATH}/app/Models/ConstraintType.php
# Expected: 0 results (model should only use is_hard_capable, parameter_schema)

grep -n "is_hard_constraint\|param_schema" {MODULE_PATH}/app/Models/Constraint.php
# Expected: 0 results
```

Also search services and controllers:

```bash
grep -rn "is_hard_constraint\|param_schema" {MODULE_PATH}/app/ --include="*.php"
# Expected: 0 results (only new column names should appear)
```

If any results found, document them as separate bugs.

### Step 3 — Document Future Cleanup Plan

Write a cleanup plan with two options:

**Option A — Drop old columns (recommended):**
- Create a migration that drops old columns after confirming no code references them
- Timing: after all P0-P2 tasks are complete and tested

**Option B — Sync via trigger (if old columns cannot be dropped yet):**
- Create BEFORE INSERT/UPDATE triggers to copy new → old
- Only if external tools or reports read old columns directly

### Step 4 — Record the Documentation

Add the tech debt documentation to:
`5-Work-In-Progress/8-Smart_Timetable/Claude_Tasks/Task-2/tech_debt_duplicate_columns.md`

---

## ACCEPTANCE CRITERIA

- [ ] Clear documentation exists listing all old vs new column pairs per table
- [ ] Verification performed that models only read/write new columns
- [ ] Any active usage of old columns documented as separate bugs
- [ ] Future cleanup plan documented with recommended approach and timing
- [ ] No code changes made — this is documentation only

---

## DO NOT

- Don't drop any columns from the database
- Don't create any migrations
- Don't modify any model files
- Don't modify any service or controller files
- This is a **documentation-only** task — no functional changes
