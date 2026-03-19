# PROMPT: Create 15 Missing Migration Files for Schema-2 Tables — HPC Module
**Task ID:** P1_19
**Issue IDs:** Schema gap
**Priority:** P1-High
**Estimated Effort:** 4 hours
**Prerequisites:** None

---

## CONFIGURATION
```
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai
MODULE_PATH    = {LARAVEL_REPO}/Modules/Hpc
MIGRATIONS_DIR = {LARAVEL_REPO}/database/migrations/tenant
```

---

## CONTEXT

15 of 26 HPC tables have Eloquent models but NO migration files in `database/migrations/tenant/`. These Schema-2 tables (NEP 2020 / PARAKH features) were likely created via raw SQL or seeders. Without versioned migration files, deployments to new tenants will fail — the tables won't be created.

Missing migrations for:
1. `hpc_circular_goals`
2. `hpc_circular_goal_competency_jnt`
3. `hpc_learning_outcomes`
4. `hpc_outcome_entity_jnt`
5. `hpc_outcome_question_jnt`
6. `hpc_knowledge_graph_validation`
7. `hpc_topic_equivalency`
8. `hpc_syllabus_coverage_snapshot`
9. `hpc_ability_parameters`
10. `hpc_performance_descriptors`
11. `hpc_student_evaluation`
12. `hpc_learning_activities`
13. `hpc_learning_activity_type`
14. `hpc_student_hpc_snapshot`
15. `hpc_hpc_levels`

---

## PRE-READ (Mandatory)

1. Each model's `$fillable` and `$casts` arrays in `{MODULE_PATH}/app/Models/` — these define the columns
2. Existing HPC migrations in `{MIGRATIONS_DIR}/` (prefixed with `hpc_`) to match the style
3. The tenant_db_v2.sql DDL if available for exact column types: `/Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase/1-Master_DDLs/tenant_db_v2.sql`

---

## STEPS

1. Read ALL 15 model files to extract column definitions from `$fillable`, `$casts`, and relationship methods
2. Read existing HPC migrations (11 files) to match the naming/style convention
3. For each missing table, create a migration file in `{MIGRATIONS_DIR}/`:
   - Naming: `2026_03_17_NNNNNN_create_hpc_table_name_table.php` (sequential NNNNNN)
   - Include ALL columns from model `$fillable` + `$casts`
   - Include standard columns: `id`, `is_active`, `created_by`, `created_at`, `updated_at`, `deleted_at`
   - Include foreign key indexes on all `_id` columns
   - Include any unique constraints implied by the model
4. Verify column types match the DDL if available, or infer from `$casts`

---

## ACCEPTANCE CRITERIA

- 15 new migration files created in `{MIGRATIONS_DIR}/`
- Each migration creates the correct table with all columns from the model
- `php artisan tenants:migrate --pretend` shows all 15 CREATE TABLE statements
- Standard columns (id, is_active, created_by, timestamps, soft deletes) present in all tables
- Foreign key indexes on all `_id` columns

---

## DO NOT

- Do NOT drop or alter existing tables
- Do NOT modify existing migration files
- Do NOT modify any model files
- Do NOT run the migrations on production — pretend only
