# Migration Guide

## Two Migration Types

| Type | File Location | Command | Example |
|------|--------------|---------|---------|
| Central/Prime | `database/migrations/` | `php artisan migrate` | Users, cache, sessions |
| Central/Prime module | `Modules/<Name>/database/migrations/` | `php artisan migrate` | Tenants, plans, billing |
| **Tenant** | **`database/migrations/tenant/`** | **`php artisan tenants:migrate`** | All school data (278 files) |

**CRITICAL RULE: Tenant migrations ALWAYS go in `database/migrations/tenant/`. NEVER inside any module folder.**

## Create Migration Commands

```bash
# Tenant migration (MOST COMMON for feature work):
php artisan make:migration create_hpc_learning_outcomes_table --path=database/migrations/tenant

# Central migration:
php artisan make:migration create_prm_boards_table

# Run all tenant migrations (all schools):
php artisan tenants:migrate

# Run for specific tenant:
php artisan tenants:migrate --tenants=<tenant-uuid>

# Run central migrations:
php artisan migrate

# Rollback tenant:
php artisan tenants:migrate-rollback
```

## Required Columns on EVERY Table

```php
Schema::create('prefix_table_name', function (Blueprint $table) {
    $table->id();                                    // REQUIRED
    // ... your columns ...
    $table->boolean('is_active')->default(true);     // REQUIRED
    $table->unsignedBigInteger('created_by')->nullable(); // REQUIRED
    $table->timestamps();                            // REQUIRED (created_at, updated_at)
    $table->softDeletes();                           // REQUIRED (deleted_at)
});
```

## Column Naming Rules

| Rule | Convention | Example |
|------|-----------|---------|
| Boolean columns | prefix `is_` or `has_` | `is_active`, `has_attachment` |
| JSON columns | suffix `_json` | `config_json`, `applies_to_days_json` |
| Junction tables | suffix `_jnt` | `hpc_circular_goal_competency_jnt` |
| Foreign keys | Always index | `$table->index('teacher_id')` |
| IDs | `BIGINT UNSIGNED` | `$table->unsignedBigInteger('teacher_id')` |
| Names | `VARCHAR(255)` | `$table->string('name', 255)` |
| Descriptions | `TEXT` | `$table->text('description')->nullable()` |

## Table Prefix by Module

```
Prime/GlobalMaster  -> prm_*, glb_*, sys_*, bil_*
SchoolSetup         -> sch_*
SmartTimetable      -> tt_*
StudentProfile      -> std_*
StudentFee          -> fin_*
Hpc                 -> hpc_*
Transport           -> tpt_*
Syllabus            -> slb_*
QuestionBank        -> qns_*
Notification        -> ntf_*
Complaint           -> cmp_*
Vendor              -> vnd_*
Library             -> lib_*
LmsExam             -> exm_*
LmsQuiz             -> quz_*
Recommendation      -> rec_*
```

## Migration File Naming

```
YYYY_MM_DD_HHMMSS_create_<prefix>_<table>_table.php
Example: 2026_03_15_100000_create_hpc_new_feature_table.php
```

## NEVER modify existing migrations — always create new additive ones.

```bash
# WRONG: Editing 2025_10_09_042528_create_countries_table.php
# RIGHT: Creating 2026_03_15_100000_add_column_to_countries_table.php
```
