# Add Standard Columns to All DDL Tables

| Field              | Value                          |
|--------------------|--------------------------------|
| **Task ID**        | P3_17                          |
| **Issue IDs**      | DDL conventions                |
| **Priority**       | P3-Low                         |
| **Estimated Effort** | 2 hours                      |
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

36 of 42 DDL tables are missing the `created_by` column. Several tables are also missing `deleted_at`, `created_at`, and/or `updated_at`. The project convention requires every table to have the following standard columns:

```sql
id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY
is_active      TINYINT(1) NOT NULL DEFAULT 1
created_by     BIGINT UNSIGNED NULL
created_at     TIMESTAMP NULL DEFAULT NULL
updated_at     TIMESTAMP NULL DEFAULT NULL
deleted_at     TIMESTAMP NULL DEFAULT NULL
```

This task brings all `tt_*` tables in the DDL into compliance with that convention. This is a **DDL-only** task — no code changes, no migrations.

---

## PRE-READ

- `{DDL_FILE}` — the full DDL file to audit and update
- Any other `tt_*` table definitions in the DDL that may have been added by P2 tasks

---

## STEPS

### Step 1 — Read the Full DDL File

Read `{DDL_FILE}` and identify every `CREATE TABLE tt_*` statement.

### Step 2 — Audit Each Table

For each `tt_*` table, check which of the 6 standard columns are present:

| Column | Expected Type | Expected Default |
|---|---|---|
| `id` | `BIGINT UNSIGNED NOT NULL AUTO_INCREMENT` | PRIMARY KEY |
| `is_active` | `TINYINT(1) NOT NULL` | `DEFAULT 1` |
| `created_by` | `BIGINT UNSIGNED` | `NULL` |
| `created_at` | `TIMESTAMP` | `NULL DEFAULT NULL` |
| `updated_at` | `TIMESTAMP` | `NULL DEFAULT NULL` |
| `deleted_at` | `TIMESTAMP` | `NULL DEFAULT NULL` |

Create a checklist showing which columns are missing from which tables.

### Step 3 — Add Missing Standard Columns

For each table missing standard columns, add them in the DDL. Follow these placement conventions:

- `id` — first column (should already exist on all tables)
- `is_active` — after the last business column, before audit columns
- `created_by` — after `is_active`
- `created_at` — after `created_by`
- `updated_at` — after `created_at`
- `deleted_at` — last column before closing parenthesis

Example addition for a table missing `created_by` and `deleted_at`:

```sql
CREATE TABLE tt_example (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    -- ... business columns ...
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_by BIGINT UNSIGNED NULL,              -- ADDED
    created_at TIMESTAMP NULL DEFAULT NULL,
    updated_at TIMESTAMP NULL DEFAULT NULL,
    deleted_at TIMESTAMP NULL DEFAULT NULL,       -- ADDED
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Step 4 — Validate the DDL

After all additions, verify the DDL is still valid SQL:

- No trailing comma issues
- No duplicate column definitions
- Consistent data types across all tables
- PRIMARY KEY declaration intact on every table

### Step 5 — Document What Changed

At the top of the DDL file (or in a separate change log), add a comment listing how many tables were updated and what was added. Example:

```sql
-- 2026-03-17: P3_17 — Added standard columns (created_by, deleted_at, etc.) to 36 tables
```

---

## ACCEPTANCE CRITERIA

- [ ] Every `tt_*` table in the DDL has all 6 standard columns: `id`, `is_active`, `created_by`, `created_at`, `updated_at`, `deleted_at`
- [ ] Data types are consistent across all tables (no `INT` vs `BIGINT` inconsistencies for `created_by`)
- [ ] Column ordering follows the convention (business columns, then `is_active`, then audit columns)
- [ ] DDL remains valid SQL — no syntax errors introduced
- [ ] A comment or changelog entry documents what was changed and when

---

## DO NOT

- Don't change any code files (models, controllers, services)
- Don't create any Laravel migrations
- Don't change any business column names or types
- Don't change any existing column definitions that are already correct
- Don't add foreign key constraints for `created_by` (it references `sys_users.id` but the FK is managed at the application level)
- Don't modify tables outside the `tt_*` prefix
