# SmartTimetable DDL Audit — Verification Report

**Date:** 2026-03-17
**Verified by:** Brijesh (via Claude Code cross-reference against actual DDL + codebase)
**Original Audit by:** Tarun (via Claude Code, 2026-03-17)
**Audit Location:** `pgdatabase/8-Team_Work/Tarun/SmartTimetable_DDL_Audit_2026-03-17/`

---

## Purpose

Tarun's audit compared DDL (`tenant_db_v2.sql`) vs Models (86 files) vs Migrations (47 files). This verification cross-checks every claim against the actual files to determine which gaps are **real** vs which stem from **Tarun's local DB being out of sync** or **audit methodology errors**.

---

## Verdict Summary

| Audit File | Tarun's Claim | Verification Result |
|---|---|---|
| 01_Executive_Summary | 37 phantom models, 14 missing migrations | **Partially correct** — phantoms confirmed, migration count wrong |
| 02_Table_Name_Mismatches | 32 singular/plural mismatches, 10 matching | **Wrong counts** — actual is 39 singular, 3 plural; parallel tables missing from DDL |
| 03_Missing_Migrations | 14 DDL tables without migration | **Overcounted** — actual is 10 (not 14); 2 tables DO have migrations under plural names |
| 04_Orphan_Tables | 8 migration tables not in DDL | **Correct** — 6 legacy + 2 naming conflicts confirmed |
| 05_Phantom_Models | 37 models with no table | **Confirmed correct** — all 37 verified as true phantoms |
| 06_Column_Mismatches | 15+ tables with column drift | **Partially correct** — constraint tables confirmed; `tt_activities` "~30 extra columns" claim is **FALSE** (only 3 extra) |
| 07_Missing_Standard_Columns | 36/42 missing `created_by` | **Correct** — DDL-level issue only, migrations have them |
| 08_Model_Issues | 1 model missing SoftDeletes + typo | **Partially correct** — ClassWorkingDay SoftDeletes was added in P21; typo is real |
| 09_Action_Plan | Prioritized recommendations | **Mostly sound** — some corrections needed |

---

## Report Files

| File | Description |
|---|---|
| `00_Verification_Summary.md` | This file — overview and verdict |
| `01_Table_Names_Corrected.md` | Corrected table name mismatch analysis |
| `02_Missing_Migrations_Corrected.md` | Corrected missing migration analysis |
| `03_Phantom_Models_Confirmed.md` | Phantom model verification + code path impact |
| `04_Column_Mismatches_Verified.md` | Detailed column-by-column truth |
| `05_Real_Bugs_Found.md` | Actual runtime bugs discovered during verification |
| `06_Corrected_Action_Plan.md` | Updated recommendations with corrections |

---

## Key Corrections to Tarun's Audit

### 1. Table Name Counts Are Wrong
- Tarun said: "32 singular, 10 matching"
- Reality: **39 singular, 3 plural** in DDL
- `tt_parallel_group` and `tt_parallel_group_activity` do **NOT EXIST** in the DDL — Tarun incorrectly assumed they did
- `tt_config`, `tt_generation_strategy`, `tt_working_day`, etc. are **singular**, not "matching"

### 2. Missing Migrations Count Is Wrong (14 → 10)
- `tt_teacher_availability` (DDL) **HAS** a migration → creates `tt_teacher_availabilities`
- `tt_class_requirement_groups` and `tt_class_requirement_subgroups` (DDL) have **NO migration** — Tarun missed these
- `tt_requirement_consolidation` (DDL) **HAS** a migration → creates `tt_requirement_consolidations`
- Net: 10 DDL tables truly have no migration, not 14

### 3. Activity Table "~30 Extra Columns" Claim Is FALSE
- Tarun claimed: "migration has ~30 extra columns not in DDL"
- Reality: Migration has only **3 extra columns** (`uuid`, `class_subject_group_id`, `class_subject_subgroup_id`)
- DDL's `tt_activity` has 52 columns; migration's `tt_activities` also has ~52 columns — they are nearly identical
- The DDL has a bug: references `class_group_id` and `class_subgroup_id` in indexes/FKs but never declares these columns

### 4. ClassWorkingDay SoftDeletes — Already Fixed
- Tarun flagged: "ClassWorkingDay missing SoftDeletes"
- Reality: This was **already fixed in P21** (the same session Tarun ran) — all 86 models now have SoftDeletes

### 5. Root Cause of Discrepancies
Most of Tarun's errors come from:
- Running the audit **before** fully loading the latest DDL into context (the `00_README.md` says "42 tables" which is correct, but the detailed table lists have errors)
- Confusing singular DDL names with "matching" when they're actually mismatched
- Not verifying migration existence by searching for both singular AND plural table names
- The `tt_activity` analysis appears to have compared against an older DDL version or incorrect column list
