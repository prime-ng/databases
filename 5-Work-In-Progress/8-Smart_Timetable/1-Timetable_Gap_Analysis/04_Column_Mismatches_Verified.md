# Column Mismatches — Verified Analysis

**Tarun's claim:** 15+ tables with column drift, `tt_activities` has "~30 extra columns"
**Reality:** Constraint tables confirmed drifted; `tt_activities` claim is FALSE (only 3 extra columns)

---

## 1. tt_constraints — CONFIRMED DRIFTED (Tarun Correct)

The DDL and migration use different column names for the same concepts:

| Concept | DDL Column | Migration Column | Model Uses | Fix Migration Added |
|---|---|---|---|---|
| Academic term FK | `academic_term_id` | `academic_session_id` | `academic_session_id` | Alias `academic_term_id` added (dead weight) |
| Applicable days | `applicable_days` (JSON) | `applies_to_days_json` | `applies_to_days_json` | Alias `applicable_days_json` added (dead weight) |
| Apply for all days | `apply_for_all_days` (BOOLEAN) | NOT in migration | In model `$fillable` | NO — model references non-existent column! |
| Status | NOT in DDL | `status` (ENUM) | `status` | NO — DDL needs update |
| UUID | NOT in DDL | `uuid` (binary 16) | `uuid` | NO — DDL needs update |

**Active Bugs:**
- Model has `apply_for_all_days` in `$fillable` but no migration creates this column → silent mass-assignment failure
- Fix migration (2026_03_12_100002) added 5 alias columns that nothing uses → dead columns in DB

---

## 2. tt_constraint_types — CONFIRMED DRIFTED (Tarun Correct)

| Concept | DDL Column | Migration Column | Model Uses | Fix Migration Added |
|---|---|---|---|---|
| Hard constraint flag | `is_hard_constraint` | `is_hard_constraint` | `is_hard_capable` | YES — `is_hard_capable` added alongside old |
| Soft constraint flag | NOT in DDL | NOT in original migration | `is_soft_capable` | YES — added |
| Parameter schema | `param_schema` | `param_schema` | `parameter_schema` | YES — `parameter_schema` added alongside old |
| Applicable to | `applicable_to` (ENUM) | NOT in migration | `applicable_target_types` | YES — added |
| Constraint level | NOT in DDL | NOT in original migration | `constraint_level` | YES — added |

**Active Bugs:**
- Model has `conflict_detection_logic`, `validation_logic`, `resolution_priority` in `$fillable` — these columns exist in **neither** DDL nor any migration → silent data loss on insert
- Table now has duplicate columns (old + new names) with no sync logic

---

## 3. tt_activities — TARUN'S CLAIM IS FALSE

**Tarun claimed:** "Migration has ~30 extra columns not in DDL" and listed 30 column names.

**Reality:** The DDL's `tt_activity` has 52 columns. The migration's `tt_activities` also has ~52 columns. They are **nearly identical**.

| Difference | Count | Details |
|---|---|---|
| Columns in migration but NOT in DDL | **3** | `uuid`, `class_subject_group_id`, `class_subject_subgroup_id` |
| Columns in DDL but NOT in migration | **0** | All DDL columns exist in migration (under same or similar names) |
| Column name differences | **2** | DDL `class_group_id` → migration `class_subject_group_id`; DDL `class_subgroup_id` → migration `class_subject_subgroup_id` |

**DDL Bug:** DDL references `class_group_id` and `class_subgroup_id` in INDEX and CHECK constraint definitions but never declares these columns in the CREATE TABLE statement. This is a syntax error in the DDL itself.

**Why Tarun saw "~30 extra":** He likely compared against a different/older version of the DDL, or misread the column lists. The 30 columns he listed (`min_periods_per_week`, `max_per_day`, `spread_evenly`, etc.) ALL exist in both DDL and migration.

---

## 4. tt_timetable_cells — MOSTLY ALIGNED

Migration and DDL columns match. However:

**Model Bug:** `TimetableCell` model has `scopeForClass()` that queries `class_id` and `section_id` directly on `tt_timetable_cells` — these columns do NOT exist in either DDL or migration. This scope will crash at runtime.

---

## 5. tt_timetable — Minor Drift (Tarun Correct)

| In DDL | In Migration | Issue |
|---|---|---|
| `generation_strategy_id` | Commented out | FK to non-existent `tt_generation_strategy` table |
| NOT in DDL | `uuid`, `total_activities`, `placed_activities`, `failed_activities`, `hard_violations`, `soft_violations`, `settings_json`, `generated_at`, `validated_at`, `validation_status` | 10 extra columns in migration |

---

## 6. Other Tables — Minor Discrepancies (Tarun Correct)

These are confirmed as stated in Tarun's audit (minor fillable extras, type mismatches):
- `tt_teacher_unavailables`: `day_of_week` ENUM in DDL vs tinyInteger in migration
- `tt_slot_requirements`: DDL has `academic_term_id`, `class_house_room_id`, `activity_id` — migration doesn't
- `tt_period_set_period_jnt`: DDL has GENERATED column for `duration_minutes` — migration has regular column
- Various models have extra `$fillable` fields not in any migration

---

## Fix Migration Status (D17 from decisions.md)

All three fix migrations from 2026-03-12 exist and were verified:

| Migration | What It Does | Assessment |
|---|---|---|
| `2026_03_12_100001_fix_constraint_types_column_names` | Adds `is_hard_capable`, `is_soft_capable`, `parameter_schema`, `applicable_target_types`, `constraint_level` to `tt_constraint_types` | **Correct but creates duplicates** — old columns kept |
| `2026_03_12_100002_fix_constraints_column_names` | Adds `academic_term_id`, `effective_from_date`, `effective_to_date`, `applicable_days_json`, `target_type_id` to `tt_constraints` | **Dead weight** — model uses original names, aliases unused |
| `2026_03_12_100003_add_missing_columns_to_constraint_category_scope` | Adds `ordinal`, `icon` to `tt_constraint_category_scope` | **Clean** — genuinely needed |

---

## Summary of Active Column-Level Bugs

| # | Table | Bug | Impact |
|---|---|---|---|
| 1 | `tt_constraints` | `apply_for_all_days` in model fillable, no column in DB | Silent data loss |
| 2 | `tt_constraint_types` | `conflict_detection_logic`, `validation_logic`, `resolution_priority` in fillable, no columns | Silent data loss |
| 3 | `tt_timetable_cells` | `scopeForClass()` queries `class_id`/`section_id` — columns don't exist | Runtime crash |
| 4 | `tt_constraints` | 5 alias columns from fix migration are dead weight | DB bloat, confusion |
| 5 | DDL `tt_activity` | References `class_group_id` in INDEX/FK but never declares it | DDL syntax error |
