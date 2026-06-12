# Prime-AI — DDL Gap Analysis & Enhancement Prompt

## How to Use This Prompt

1. Open the target module's DDL file in VS Code
2. Start a new Claude Agent session
3. Paste this prompt, replacing `[MODULE_NAME]` and the `<DDL_CONTENT>` section
4. Claude will produce a structured enhancement report as a separate file

---

## THE PROMPT (copy from here)

---

You are a **Senior Database Architect** with deep expertise in **Laravel 12 multi-tenant SaaS platforms** for K-12 education. You are reviewing the DDL schema for the **[LIBRARY]** module of **Prime-AI** — an advanced ERP + LMS + LXP + ML-analytics platform for Indian schools.

## Platform Architecture Context

Before analysis, internalize these platform-wide constraints:

**Stack & ORM**
- Laravel 12, Eloquent ORM, MySQL 8.x
- Soft deletes (`deleted_at`) required on all major entity tables
- Timestamps (`created_at`, `updated_at`) required on all tables

**Multi-Tenancy Model**
- **Database-per-tenant** isolation (NOT column-based `tenant_id`)
- Three databases: `tenant_db` (school data), `prime_db` (platform admin), `global_db` (shared lookups)
- Cross-database queries must use fully qualified table names
- All tenant tables live in `tenant_db`; no `tenant_id` columns needed

**Naming Conventions (strictly enforced)**
- Junction/pivot tables: `_jnt` suffix (e.g., `student_subject_jnt`)
- JSON columns: `_json` suffix (e.g., `config_json`, `metadata_json`)
- Boolean columns: `is_` or `has_` prefix (e.g., `is_active`, `has_passed`)
- Soft-delete columns: always named `deleted_at`
- Foreign keys: `fk_{table}_{column(s)}` pattern
- Indexes: `idx_{table}_{column(s)}` pattern
- Unique constraints: `uq_{table}_{column(s)}` pattern

**Performance Baselines**
- Schools range from 200 to 5,000 students per tenant
- Peak concurrent users: ~300 during result publication or fee payment windows
- Redis used for caching; Meilisearch for full-text search
- N+1 queries are a known risk — composite indexes on FK + status/date columns are critical

**Module Integration Points (common)**
- `academic_years` — every module ties records to an academic year
- `classes`, `sections`, `students`, `staff` — core entity tables
- `fee_structures`, `fee_payments` — Finance module
- `attendance_records` — Attendance module
- `exam_schedules`, `results` — Examination module
- `notifications_log` — central notification registry


---
## CONFIGURATION
  MODULE_NAME         = LIBRARY
  MODULE_SHORT_NAME   = Lib
  DB_REPO             = /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db
  OUTPUT_PATH         = {DB_REPO}/1-DDL_Tenant_Modules/Library/Design
  OUTPUT_FILE_NAME    = {OUTPUT_PATH}/{MODULE_SHORT_NAME}_DDL_Enhancement_Report.md
  CURRENT_DDL         = {DB_REPO}/1-DDL_Tenant_Modules/Library/DDL/Library_ddl_v4.sql

---

## Your Task

Perform a **comprehensive DDL Gap Analysis** for the **{MODULE_NAME}** module schema provided below. Your output must be **a separate Markdown file** saved as:

```
{OUTPUT_FILE_NAME}
```

---

## Analysis Dimensions

Evaluate the DDL across **all 10 dimensions** below. For each finding, assign:
- **Severity**: `CRITICAL` | `HIGH` | `MEDIUM` | `LOW`
- **Type**: `Missing` | `Incorrect` | `Suboptimal` | `Enhancement`
- **Effort**: `Quick-fix` | `Minor refactor` | `Significant change`

---

### Dimension 1 — Naming Convention Compliance
- Verify all table names, column names, index names, and constraint names against Prime-AI conventions
- Flag any `is_`/`has_` violations (non-boolean columns using these prefixes, or boolean columns missing them)
- Check `_jnt` suffix on all pivot/junction tables
- Check `_json` suffix on all JSON-type columns
- Flag any abbreviations that reduce readability

### Dimension 2 — Missing Standard Columns
- `created_at`, `updated_at` — required on ALL tables
- `deleted_at` — required on all major entity tables; flag if missing
- `created_by`, `updated_by` — required only for tables where we must showcase to created.updated the transactional/event in tables. Mostly not required.
- `academic_year_id` — flag if module logic is academic-year-scoped but FK is absent
- `is_active` — flag if table represents a manageable entity without an active/inactive toggle

### Dimension 3 — Foreign Key & Referential Integrity
- Identify all implied relationships that lack explicit FK constraints
- Flag missing `ON DELETE` / `ON UPDATE` rules
- Identify orphan-risk scenarios (child records that could survive parent deletion)
- Check if cascade vs. restrict vs. set-null choices are appropriate for each relationship
- Flag missing FKs to core entities (`academic_years`, `classes`, `sections`, `students`, `staff`)
- Flag missing reference table used in FKs.

### Dimension 4 — Index Coverage & Query Performance
- Identify high-cardinality columns used in WHERE, ORDER BY, or JOIN clauses that lack indexes
- Flag missing **composite indexes** on common query patterns:
  - `(student_id, academic_year_id)`
  - `(class_id, section_id, academic_year_id)`
  - `(staff_id, academic_year_id)`
  - `(created_at)` or `(date)` columns for date-range queries
- Flag indexes that are redundant or duplicated
- Identify columns suitable for **covering indexes** to avoid table lookups
- Flag full-text search candidates that should be indexed in Meilisearch

### Dimension 5 — Data Type Appropriateness
- Flag required id limit, do not use BIGINT everywhere
- Flag `VARCHAR` lengths that are too short (truncation risk) or unnecessarily large
- Flag numeric types that should be `DECIMAL` vs `FLOAT`/`DOUBLE` (financial/score data)
- Flag `TEXT` columns that should be `VARCHAR` (no index support on TEXT)
- Flag `ENUM` columns that should be lookup-table FKs (extensibility risk)
- Flag columns storing arrays/objects as plain strings instead of JSON
- Check `DATE` vs `DATETIME` vs `TIMESTAMP` appropriateness
- Check `TINYINT(1)` for all boolean columns

### Dimension 6 — Normalization & Data Integrity
- Identify denormalization risks (data duplicated across tables that will drift)
- Flag columns that store computed values which should be derived at query time
- Identify missing junction tables (many-to-many relationships flattened into comma-separated strings or JSON arrays)
- Flag missing `UNIQUE` constraints on columns that have business-level uniqueness rules
- Flag `NOT NULL` missing on columns that should never be null
- Check for DEFAULT values that should be set but aren't

### Dimension 7 — Module-Specific Business Logic Gaps
Based on the module name and tables present, identify:
- Missing tables for workflows implied by existing tables (e.g., approval tables, history/log tables, status-transition tables)
- Missing columns for audit trails on sensitive operations
- Missing `status` or `workflow_stage` columns on tables representing processes
- Missing `remarks`/`notes` columns on tables where human annotation is expected
- Configuration tables that are missing but implied (e.g., `{module}_settings`, `{module}_templates`)

### Dimension 8 — AI/ML & Analytics Readiness
- Identify tables that should have `metadata_json` columns for ML feature storage
- Flag missing columns for time-series analytics (trend data, historical snapshots)
- Identify missing aggregation-friendly structures (pre-computed summary tables)
- Flag where event-sourcing patterns would benefit the module (immutable event log tables)
- Check if prediction/recommendation output tables exist where the module implies ML usage

### Dimension 9 — Localization & Indian Education Compliance
- Flag missing support for multi-language content (Indian regional languages) where applicable
- Check compliance with:
  - CBSE/ICSE/State Board marking scheme structures
  - CCE (Continuous & Comprehensive Evaluation) requirements
  - NEP 2020 competency-based assessment fields
  - RTE Act compliance fields (where relevant)
- Flag missing fields for govt-mandated data collection (UDISE+, APAAR ID, etc.)
- Check if medium of instruction (English/Hindi/Regional) is captured where needed

### Dimension 10 — Security & Access Control
- Flag sensitive PII columns missing encryption markers or comments
- Identify tables where row-level access control would require additional columns (`visible_to_roles_json`, `access_level`, etc.)
- Flag missing `is_confidential` or `is_restricted` flags on sensitive record types
- Check if attachment/document reference columns follow a consistent pattern for secure file storage

---

## Output Format

Generate the report as {OUTPUT_FILE_NAME} with this exact structure:

```markdown
# {MODULE_NAME} Module — DDL Gap Analysis & Enhancement Report

**Module:** [MODULE_NAME]  
**Analysis Date:** [DATE]  
**Analyst:** Claude Agent (Prime-AI DDL Review)  
**DDL Version:** [extracted from file header or "unversioned"]  
**Tables Reviewed:** [count]  
**Total Findings:** [count]  

---

## Executive Summary

[3–5 sentence summary of the schema's overall quality, the most critical gaps,
and the highest-value enhancements. Include a readiness score: PRODUCTION-READY /
NEEDS-MINOR-FIXES / NEEDS-SIGNIFICANT-WORK / REQUIRES-REDESIGN]

---

## Finding Summary Table

| # | Table | Column/Element | Dimension | Severity | Type | Effort | Short Description |
|---|-------|---------------|-----------|----------|------|--------|-------------------|
| 1 | ... | ... | ... | CRITICAL | Missing | Quick-fix | ... |
...

---

## Detailed Findings

### F-001 | [Short Title]
**Table:** `table_name`  
**Element:** `column_or_index_name` (or "Table-level")  
**Dimension:** [Dimension name]  
**Severity:** CRITICAL / HIGH / MEDIUM / LOW  
**Type:** Missing / Incorrect / Suboptimal / Enhancement  
**Effort:** Quick-fix / Minor refactor / Significant change  

**Issue:**  
[Clear description of what is wrong or missing and why it matters in Prime-AI's context]

**Risk:**  
[What breaks, degrades, or becomes impossible without this fix]

**Recommended Fix:**
\`\`\`sql
-- Exact DDL change(s) to apply
ALTER TABLE `table_name` ADD COLUMN ...;
CREATE INDEX ...;
\`\`\`

**Laravel Migration Snippet:**
\`\`\`php
// Equivalent Laravel migration code
$table->unsignedBigInteger('column_name')->after('other_column');
$table->foreign('column_name')->references('id')->on('other_table')->onDelete('restrict');
\`\`\`

---

[Repeat for each finding]

---

## Recommended New Tables

[For each missing table identified:]

### NT-001 | `suggested_table_name`
**Rationale:** [Why this table is needed]  
**Triggered By:** Finding F-XXX  

\`\`\`sql
CREATE TABLE `suggested_table_name` (
  -- Full DDL for the recommended table
);
\`\`\`

---

## Priority Implementation Roadmap

### Phase 1 — Critical Fixes (Before Production)
[List CRITICAL findings with migration order respecting FK dependencies]

### Phase 2 — High Priority (Next Sprint)
[List HIGH findings]

### Phase 3 — Enhancements (Backlog)
[List MEDIUM and LOW findings, grouped by theme]

---

## Naming Convention Violations Summary

| Current Name | Corrected Name | Rule Violated |
|-------------|----------------|---------------|
| ... | ... | ... |

---

## Cross-Module Integration Gaps

[List any missing FK relationships to other Prime-AI modules, with the target table
and suggested FK column to add]

| This Table | Missing FK Column | Target Module | Target Table |
|------------|------------------|---------------|--------------|
| ... | ... | ... | ... |

---

## Notes for Development Team

[Any additional architectural observations, migration sequencing warnings,
or decisions requiring human judgment before implementation]
```

---

## Source DDL

Analyze the following DDL:

```sql
{CURRENT_DDL}
```

---

## Output Instructions

1. **Save the report** to the same directory as the DDL file, named {OUTPUT_FILE_NAME}
2. **Do not modify** the original DDL file
3. All SQL in the report must be **MySQL 8.x compatible**
4. All PHP must be **Laravel 11 migration syntax**
5. If the DDL file has a version header or comment block, extract and reference it in the report
6. Flag any finding where the fix requires **data migration** (not just schema change) with a ⚠️ DATA MIGRATION WARNING

---
*Prompt Version: 1.0 | Prime-AI DDL Review System | PrimeGurukul*
