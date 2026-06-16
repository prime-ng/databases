# PROMPT: Create 12 Phantom Model Table Migrations — SmartTimetable DDL Gap Fix
**Task ID:** P0_05
**Issue IDs:** BUG-DDL-004
**Priority:** P0-Critical
**Estimated Effort:** 2-3 hours
**Prerequisites:** P0_04 (some FKs reference tables created in P0_04)

---

## CONFIGURATION
```
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai_tarun
MODULE_PATH    = {LARAVEL_REPO}/Modules/SmartTimetable
BRANCH         = Brijesh_SmartTimetable
```

---

## CONTEXT

12 phantom models are actively referenced in services written during P14-P17 (AnalyticsService, RefinementService, SubstitutionService, GenerateTimetableJob). These models point to tables that don't exist — no DDL definition, no migration. Every feature from P14-P17 will crash when it touches these models.

The models exist in `{MODULE_PATH}/app/Models/` with `$table`, `$fillable`, `$casts`, and relationships defined, but the corresponding database tables were never created. This task creates one migration per table — 12 migrations total.

---

## PRE-READ (Mandatory)

Read all 12 model files to confirm `$fillable`, `$casts`, relationships, and any custom `UPDATED_AT` overrides before writing migrations:

1. `{MODULE_PATH}/app/Models/AnalyticsDailySnapshot.php`
2. `{MODULE_PATH}/app/Models/RoomUtilization.php`
3. `{MODULE_PATH}/app/Models/ConstraintTargetType.php`
4. `{MODULE_PATH}/app/Models/ConflictResolutionSession.php`
5. `{MODULE_PATH}/app/Models/ConflictResolutionOption.php`
6. `{MODULE_PATH}/app/Models/ImpactAnalysisSession.php`
7. `{MODULE_PATH}/app/Models/ImpactAnalysisDetail.php`
8. `{MODULE_PATH}/app/Models/BatchOperation.php`
9. `{MODULE_PATH}/app/Models/BatchOperationItem.php`
10. `{MODULE_PATH}/app/Models/SubstitutionPattern.php`
11. `{MODULE_PATH}/app/Models/SubstitutionRecommendation.php`
12. `{MODULE_PATH}/app/Models/GenerationQueue.php`

Also read:
- `{LARAVEL_REPO}/database/migrations/tenant/` — list existing migrations to determine the next timestamp prefix and naming convention
- `{MODULE_PATH}/app/Services/AnalyticsService.php` — confirm which models it touches
- `{MODULE_PATH}/app/Services/SubstitutionService.php` — confirm which models it touches
- `{MODULE_PATH}/app/Services/RefinementService.php` — confirm which models it touches

---

## STEPS

Create one migration file per table in `{LARAVEL_REPO}/database/migrations/tenant/`. Use timestamps that are sequential (increment by 1 second each). Follow the existing naming convention: `YYYY_MM_DD_HHMMSS_create_<table_name>_table.php`.

All migrations must use `Schema::create()` inside `up()` and `Schema::dropIfExists()` inside `down()`.

Standard columns used across all tables (unless noted otherwise):
- `is_active` — `$table->boolean('is_active')->default(true);`
- `created_by` — `$table->unsignedInteger('created_by')->nullable();`
- `created_at` — `$table->timestamp('created_at')->nullable();`
- `updated_at` — `$table->timestamp('updated_at')->nullable();` (OMIT where model sets `const UPDATED_AT = null`)
- `deleted_at` — `$table->softDeletes();`

---

### Sub-Task 5.1: `tt_analytics_daily_snapshots`

**Migration file:** `create_tt_analytics_daily_snapshots_table.php`

| Column | Type | Constraints |
|--------|------|-------------|
| id | `unsignedInteger` | AUTO_INCREMENT, PRIMARY KEY |
| snapshot_date | `date` | NOT NULL |
| academic_session_id | `unsignedInteger` | NOT NULL |
| academic_term_id | `unsignedInteger` | NOT NULL |
| timetable_id | `unsignedInteger` | NOT NULL, FK -> `tt_timetables(id)` |
| total_teachers_present | `unsignedInteger` | DEFAULT 0 |
| total_teachers_absent | `unsignedInteger` | DEFAULT 0 |
| total_classes_conducted | `unsignedInteger` | DEFAULT 0 |
| total_periods_scheduled | `unsignedInteger` | DEFAULT 0 |
| total_substitutions | `unsignedInteger` | DEFAULT 0 |
| violations_detected | `unsignedInteger` | DEFAULT 0 |
| hard_violations | `unsignedInteger` | DEFAULT 0 |
| soft_violations | `unsignedInteger` | DEFAULT 0 |
| snapshot_data_json | `json` | NULLABLE |
| is_active | `boolean` | DEFAULT true |
| created_by | `unsignedInteger` | NULLABLE |
| created_at | `timestamp` | NULLABLE |
| deleted_at | `timestamp` | NULLABLE (softDeletes) |

**Note:** No `updated_at` column — model sets `const UPDATED_AT = null`.

**Indexes:**
- `INDEX (timetable_id, snapshot_date)` — analytics queries filter by timetable + date range
- `FK (timetable_id)` -> `tt_timetables(id)` ON DELETE CASCADE

---

### Sub-Task 5.2: `tt_room_utilizations`

**Migration file:** `create_tt_room_utilizations_table.php`

| Column | Type | Constraints |
|--------|------|-------------|
| id | `unsignedInteger` | AUTO_INCREMENT, PRIMARY KEY |
| timetable_id | `unsignedInteger` | NOT NULL, FK -> `tt_timetables(id)` |
| room_id | `unsignedInteger` | NOT NULL |
| room_type_id | `unsignedInteger` | NULLABLE |
| total_available_periods | `unsignedInteger` | DEFAULT 0 |
| total_booked_periods | `unsignedInteger` | DEFAULT 0 |
| utilization_percentage | `DECIMAL(5,2)` | GENERATED ALWAYS AS (see below), STORED |
| peak_hours_count | `unsignedInteger` | DEFAULT 0 |
| off_peak_hours_count | `unsignedInteger` | DEFAULT 0 |
| average_class_size | `DECIMAL(5,1)` | NULLABLE |
| max_class_size | `unsignedInteger` | NULLABLE |
| concurrent_bookings_count | `unsignedInteger` | DEFAULT 0 |
| analysis_date | `datetime` | NULLABLE |
| snapshot_json | `json` | NULLABLE |
| is_active | `boolean` | DEFAULT true |
| created_by | `unsignedInteger` | NULLABLE |
| created_at | `timestamp` | NULLABLE |
| updated_at | `timestamp` | NULLABLE |
| deleted_at | `timestamp` | NULLABLE (softDeletes) |

**Generated column (use raw SQL after Schema::create or via DB::statement):**
```sql
ALTER TABLE tt_room_utilizations
MODIFY COLUMN utilization_percentage DECIMAL(5,2)
GENERATED ALWAYS AS (
    CASE WHEN total_available_periods > 0
         THEN (total_booked_periods * 100.0 / total_available_periods)
         ELSE 0
    END
) STORED;
```

**Alternative approach — define within Schema::create using `virtualAs`/`storedAs`:**
```php
$table->decimal('utilization_percentage', 5, 2)
      ->storedAs('CASE WHEN total_available_periods > 0 THEN (total_booked_periods * 100.0 / total_available_periods) ELSE 0 END')
      ->nullable();
```

**Indexes:**
- `INDEX (timetable_id, room_id)` — analytics queries filter by timetable + room
- `FK (timetable_id)` -> `tt_timetables(id)` ON DELETE CASCADE

---

### Sub-Task 5.3: `tt_constraint_target_types`

**Migration file:** `create_tt_constraint_target_types_table.php`

| Column | Type | Constraints |
|--------|------|-------------|
| id | `unsignedInteger` | AUTO_INCREMENT, PRIMARY KEY |
| code | `VARCHAR(50)` | NOT NULL, UNIQUE |
| name | `VARCHAR(100)` | NOT NULL |
| table_name | `VARCHAR(100)` | NULLABLE |
| is_active | `boolean` | DEFAULT true |
| created_by | `unsignedInteger` | NULLABLE |
| created_at | `timestamp` | NULLABLE |
| updated_at | `timestamp` | NULLABLE |
| deleted_at | `timestamp` | NULLABLE (softDeletes) |

**Indexes:**
- `UNIQUE (code)`

---

### Sub-Task 5.4: `tt_conflict_resolution_sessions`

**Migration file:** `create_tt_conflict_resolution_sessions_table.php`

| Column | Type | Constraints |
|--------|------|-------------|
| id | `unsignedInteger` | AUTO_INCREMENT, PRIMARY KEY |
| uuid | `BINARY(16)` | UNIQUE |
| timetable_id | `unsignedInteger` | NOT NULL, FK -> `tt_timetables(id)` |
| conflict_type | `VARCHAR(100)` | NOT NULL |
| conflict_description | `text` | NULLABLE |
| affected_cells_json | `json` | NULLABLE |
| status | `VARCHAR(20)` | DEFAULT 'OPEN' |
| priority | `VARCHAR(20)` | DEFAULT 'MEDIUM' |
| assigned_to | `unsignedInteger` | NULLABLE, FK -> `sys_users(id)` |
| resolved_by | `unsignedInteger` | NULLABLE, FK -> `sys_users(id)` |
| resolved_at | `datetime` | NULLABLE |
| resolution_notes | `text` | NULLABLE |
| is_active | `boolean` | DEFAULT true |
| created_by | `unsignedInteger` | NULLABLE |
| created_at | `timestamp` | NULLABLE |
| updated_at | `timestamp` | NULLABLE |
| deleted_at | `timestamp` | NULLABLE (softDeletes) |

**Indexes:**
- `UNIQUE (uuid)`
- `INDEX (timetable_id, status)` — conflict queries filter by timetable + status
- `FK (timetable_id)` -> `tt_timetables(id)` ON DELETE CASCADE
- `FK (assigned_to)` -> `sys_users(id)` ON DELETE SET NULL
- `FK (resolved_by)` -> `sys_users(id)` ON DELETE SET NULL

---

### Sub-Task 5.5: `tt_conflict_resolution_options`

**Migration file:** `create_tt_conflict_resolution_options_table.php`

| Column | Type | Constraints |
|--------|------|-------------|
| id | `unsignedInteger` | AUTO_INCREMENT, PRIMARY KEY |
| conflict_id | `unsignedInteger` | NOT NULL, FK -> `tt_conflict_resolution_sessions(id)` |
| option_type | `VARCHAR(100)` | NOT NULL |
| description | `text` | NULLABLE |
| impact_summary | `text` | NULLABLE |
| affected_entities_json | `json` | NULLABLE |
| score_impact | `DECIMAL(10,4)` | NULLABLE |
| is_recommended | `boolean` | DEFAULT false |
| is_selected | `boolean` | DEFAULT false |
| selected_by | `unsignedInteger` | NULLABLE, FK -> `sys_users(id)` |
| selected_at | `datetime` | NULLABLE |
| execution_result_json | `json` | NULLABLE |
| is_active | `boolean` | DEFAULT true |
| created_by | `unsignedInteger` | NULLABLE |
| created_at | `timestamp` | NULLABLE |
| updated_at | `timestamp` | NULLABLE |
| deleted_at | `timestamp` | NULLABLE (softDeletes) |

**Indexes:**
- `INDEX (conflict_id)` — options are queried by conflict session
- `FK (conflict_id)` -> `tt_conflict_resolution_sessions(id)` ON DELETE CASCADE
- `FK (selected_by)` -> `sys_users(id)` ON DELETE SET NULL

---

### Sub-Task 5.6: `tt_impact_analysis_sessions`

**Migration file:** `create_tt_impact_analysis_sessions_table.php`

| Column | Type | Constraints |
|--------|------|-------------|
| id | `unsignedInteger` | AUTO_INCREMENT, PRIMARY KEY |
| uuid | `BINARY(16)` | UNIQUE |
| timetable_id | `unsignedInteger` | NOT NULL, FK -> `tt_timetables(id)` |
| analysis_type | `VARCHAR(50)` | NOT NULL |
| source_cell_id | `unsignedInteger` | NULLABLE, FK -> `tt_timetable_cells(id)` |
| target_cell_id | `unsignedInteger` | NULLABLE, FK -> `tt_timetable_cells(id)` |
| status | `VARCHAR(20)` | DEFAULT 'PENDING' |
| total_affected | `unsignedInteger` | DEFAULT 0 |
| risk_level | `VARCHAR(20)` | NULLABLE |
| summary_json | `json` | NULLABLE |
| initiated_by | `unsignedInteger` | NULLABLE, FK -> `sys_users(id)` |
| is_active | `boolean` | DEFAULT true |
| created_by | `unsignedInteger` | NULLABLE |
| created_at | `timestamp` | NULLABLE |
| updated_at | `timestamp` | NULLABLE |
| deleted_at | `timestamp` | NULLABLE (softDeletes) |

**Indexes:**
- `UNIQUE (uuid)`
- `INDEX (timetable_id, status)` — queries filter by timetable + status
- `FK (timetable_id)` -> `tt_timetables(id)` ON DELETE CASCADE
- `FK (source_cell_id)` -> `tt_timetable_cells(id)` ON DELETE SET NULL
- `FK (target_cell_id)` -> `tt_timetable_cells(id)` ON DELETE SET NULL
- `FK (initiated_by)` -> `sys_users(id)` ON DELETE SET NULL

---

### Sub-Task 5.7: `tt_impact_analysis_details`

**Migration file:** `create_tt_impact_analysis_details_table.php`

| Column | Type | Constraints |
|--------|------|-------------|
| id | `unsignedInteger` | AUTO_INCREMENT, PRIMARY KEY |
| session_id | `unsignedInteger` | NOT NULL, FK -> `tt_impact_analysis_sessions(id)` |
| affected_entity_type | `VARCHAR(50)` | NOT NULL |
| affected_entity_id | `unsignedInteger` | NOT NULL |
| impact_type | `VARCHAR(50)` | NOT NULL |
| impact_severity | `VARCHAR(20)` | NULLABLE |
| description | `text` | NULLABLE |
| current_state_json | `json` | NULLABLE |
| projected_state_json | `json` | NULLABLE |
| is_active | `boolean` | DEFAULT true |
| created_by | `unsignedInteger` | NULLABLE |
| created_at | `timestamp` | NULLABLE |
| deleted_at | `timestamp` | NULLABLE (softDeletes) |

**Note:** No `updated_at` column — model sets `const UPDATED_AT = null`.

**Indexes:**
- `INDEX (session_id)` — details are queried by session
- `INDEX (affected_entity_type, affected_entity_id)` — polymorphic-style lookup
- `FK (session_id)` -> `tt_impact_analysis_sessions(id)` ON DELETE CASCADE

---

### Sub-Task 5.8: `tt_batch_operations`

**Migration file:** `create_tt_batch_operations_table.php`

| Column | Type | Constraints |
|--------|------|-------------|
| id | `unsignedInteger` | AUTO_INCREMENT, PRIMARY KEY |
| uuid | `BINARY(16)` | UNIQUE |
| timetable_id | `unsignedInteger` | NOT NULL, FK -> `tt_timetables(id)` |
| operation_type | `VARCHAR(50)` | NOT NULL |
| status | `VARCHAR(20)` | DEFAULT 'PENDING' |
| total_items | `unsignedInteger` | DEFAULT 0 |
| processed_items | `unsignedInteger` | DEFAULT 0 |
| failed_items | `unsignedInteger` | DEFAULT 0 |
| started_at | `datetime` | NULLABLE |
| completed_at | `datetime` | NULLABLE |
| error_message | `text` | NULLABLE |
| rollback_data_json | `json` | NULLABLE |
| initiated_by | `unsignedInteger` | NULLABLE, FK -> `sys_users(id)` |
| is_active | `boolean` | DEFAULT true |
| created_by | `unsignedInteger` | NULLABLE |
| created_at | `timestamp` | NULLABLE |
| updated_at | `timestamp` | NULLABLE |
| deleted_at | `timestamp` | NULLABLE (softDeletes) |

**Indexes:**
- `UNIQUE (uuid)`
- `INDEX (timetable_id, status)` — batch queries filter by timetable + status
- `FK (timetable_id)` -> `tt_timetables(id)` ON DELETE CASCADE
- `FK (initiated_by)` -> `sys_users(id)` ON DELETE SET NULL

---

### Sub-Task 5.9: `tt_batch_operation_items`

**Migration file:** `create_tt_batch_operation_items_table.php`

| Column | Type | Constraints |
|--------|------|-------------|
| id | `unsignedInteger` | AUTO_INCREMENT, PRIMARY KEY |
| batch_operation_id | `unsignedInteger` | NOT NULL, FK -> `tt_batch_operations(id)` |
| cell_id | `unsignedInteger` | NULLABLE, FK -> `tt_timetable_cells(id)` |
| action | `VARCHAR(50)` | NOT NULL |
| before_state_json | `json` | NULLABLE |
| after_state_json | `json` | NULLABLE |
| status | `VARCHAR(20)` | DEFAULT 'PENDING' |
| error_message | `text` | NULLABLE |
| processed_at | `datetime` | NULLABLE |
| is_active | `boolean` | DEFAULT true |
| created_by | `unsignedInteger` | NULLABLE |
| created_at | `timestamp` | NULLABLE |
| deleted_at | `timestamp` | NULLABLE (softDeletes) |

**Note:** No `updated_at` column — model sets `const UPDATED_AT = null`.

**Indexes:**
- `INDEX (batch_operation_id, status)` — item queries filter by batch + status
- `FK (batch_operation_id)` -> `tt_batch_operations(id)` ON DELETE CASCADE
- `FK (cell_id)` -> `tt_timetable_cells(id)` ON DELETE SET NULL

---

### Sub-Task 5.10: `tt_substitution_patterns`

**Migration file:** `create_tt_substitution_patterns_table.php`

| Column | Type | Constraints |
|--------|------|-------------|
| id | `unsignedInteger` | AUTO_INCREMENT, PRIMARY KEY |
| subject_study_format_id | `unsignedInteger` | NULLABLE |
| class_id | `unsignedInteger` | NULLABLE |
| section_id | `unsignedInteger` | NULLABLE |
| original_teacher_id | `unsignedInteger` | NULLABLE |
| substitute_teacher_id | `unsignedInteger` | NULLABLE |
| success_count | `unsignedInteger` | DEFAULT 0 |
| total_count | `unsignedInteger` | DEFAULT 0 |
| success_rate | `DECIMAL(5,2)` | GENERATED ALWAYS AS (see below), STORED |
| avg_effectiveness_rating | `DECIMAL(5,2)` | NULLABLE |
| common_reasons_json | `json` | NULLABLE |
| best_fit_scenarios_json | `json` | NULLABLE |
| confidence_score | `unsignedInteger` | DEFAULT 0 |
| last_used_at | `datetime` | NULLABLE |
| is_active | `boolean` | DEFAULT true |
| created_by | `unsignedInteger` | NULLABLE |
| created_at | `timestamp` | NULLABLE |
| updated_at | `timestamp` | NULLABLE |
| deleted_at | `timestamp` | NULLABLE (softDeletes) |

**Generated column:**
```php
$table->decimal('success_rate', 5, 2)
      ->storedAs('CASE WHEN total_count > 0 THEN (success_count * 100.0 / total_count) ELSE 0 END')
      ->nullable();
```

**Indexes:**
- `INDEX (original_teacher_id, substitute_teacher_id)` — pattern lookup by teacher pair
- `INDEX (subject_study_format_id, class_id)` — pattern lookup by subject + class

---

### Sub-Task 5.11: `tt_substitution_recommendations`

**Migration file:** `create_tt_substitution_recommendations_table.php`

| Column | Type | Constraints |
|--------|------|-------------|
| id | `unsignedInteger` | AUTO_INCREMENT, PRIMARY KEY |
| teacher_absence_id | `unsignedInteger` | NULLABLE, FK -> `tt_teacher_absences(id)` |
| cell_id | `unsignedInteger` | NULLABLE, FK -> `tt_timetable_cells(id)` |
| recommended_teacher_id | `unsignedInteger` | NULLABLE |
| recommendation_score | `DECIMAL(5,2)` | NULLABLE |
| recommendation_reason | `text` | NULLABLE |
| ranking | `unsignedInteger` | NULLABLE |
| status | `VARCHAR(20)` | DEFAULT 'PENDING' |
| is_active | `boolean` | DEFAULT true |
| created_by | `unsignedInteger` | NULLABLE |
| created_at | `timestamp` | NULLABLE |
| updated_at | `timestamp` | NULLABLE |
| deleted_at | `timestamp` | NULLABLE (softDeletes) |

**Indexes:**
- `INDEX (teacher_absence_id, ranking)` — recommendations queried by absence, ordered by rank
- `FK (teacher_absence_id)` -> `tt_teacher_absences(id)` ON DELETE CASCADE
- `FK (cell_id)` -> `tt_timetable_cells(id)` ON DELETE SET NULL

---

### Sub-Task 5.12: `tt_generation_queues`

**Migration file:** `create_tt_generation_queues_table.php`

| Column | Type | Constraints |
|--------|------|-------------|
| id | `unsignedInteger` | AUTO_INCREMENT, PRIMARY KEY |
| uuid | `BINARY(16)` | UNIQUE |
| timetable_id | `unsignedInteger` | NOT NULL, FK -> `tt_timetables(id)` |
| generation_strategy_id | `unsignedInteger` | NULLABLE, FK -> `tt_generation_strategy(id)` |
| priority | `unsignedInteger` | DEFAULT 0 |
| status | `VARCHAR(20)` | DEFAULT 'QUEUED' |
| attempts | `unsignedInteger` | DEFAULT 0 |
| max_attempts | `unsignedInteger` | DEFAULT 3 |
| scheduled_at | `datetime` | NULLABLE |
| started_at | `datetime` | NULLABLE |
| completed_at | `datetime` | NULLABLE |
| error_message | `text` | NULLABLE |
| queue_metadata | `json` | NULLABLE |
| is_active | `boolean` | DEFAULT true |
| created_by | `unsignedInteger` | NULLABLE |
| created_at | `timestamp` | NULLABLE |
| updated_at | `timestamp` | NULLABLE |
| deleted_at | `timestamp` | NULLABLE (softDeletes) |

**Indexes:**
- `UNIQUE (uuid)`
- `INDEX (status, priority)` — queue processing picks by status + priority
- `FK (timetable_id)` -> `tt_timetables(id)` ON DELETE CASCADE
- `FK (generation_strategy_id)` -> `tt_generation_strategy(id)` ON DELETE SET NULL

---

## MIGRATION ORDER

The migrations must be created in this order due to FK dependencies:

1. `tt_constraint_target_types` (Sub-Task 5.3) — no FK dependencies
2. `tt_analytics_daily_snapshots` (Sub-Task 5.1) — FK to `tt_timetables`
3. `tt_room_utilizations` (Sub-Task 5.2) — FK to `tt_timetables`
4. `tt_conflict_resolution_sessions` (Sub-Task 5.4) — FK to `tt_timetables`, `sys_users`
5. `tt_conflict_resolution_options` (Sub-Task 5.5) — FK to `tt_conflict_resolution_sessions`
6. `tt_impact_analysis_sessions` (Sub-Task 5.6) — FK to `tt_timetables`, `tt_timetable_cells`
7. `tt_impact_analysis_details` (Sub-Task 5.7) — FK to `tt_impact_analysis_sessions`
8. `tt_batch_operations` (Sub-Task 5.8) — FK to `tt_timetables`
9. `tt_batch_operation_items` (Sub-Task 5.9) — FK to `tt_batch_operations`, `tt_timetable_cells`
10. `tt_substitution_patterns` (Sub-Task 5.10) — no strict FK (soft references only)
11. `tt_substitution_recommendations` (Sub-Task 5.11) — FK to `tt_teacher_absences`, `tt_timetable_cells`
12. `tt_generation_queues` (Sub-Task 5.12) — FK to `tt_timetables`, `tt_generation_strategy`

---

## VERIFICATION

After all 12 migrations are created, run:

```bash
# Step 1: Dry-run to see SQL without executing
cd {LARAVEL_REPO}
php artisan migrate --pretend --path=database/migrations/tenant

# Step 2: Run the actual migrations
php artisan migrate --path=database/migrations/tenant

# Step 3: Verify each table exists and models can query it
php artisan tinker --execute="
    \$models = [
        'Modules\\\\SmartTimetable\\\\Models\\\\AnalyticsDailySnapshot',
        'Modules\\\\SmartTimetable\\\\Models\\\\RoomUtilization',
        'Modules\\\\SmartTimetable\\\\Models\\\\ConstraintTargetType',
        'Modules\\\\SmartTimetable\\\\Models\\\\ConflictResolutionSession',
        'Modules\\\\SmartTimetable\\\\Models\\\\ConflictResolutionOption',
        'Modules\\\\SmartTimetable\\\\Models\\\\ImpactAnalysisSession',
        'Modules\\\\SmartTimetable\\\\Models\\\\ImpactAnalysisDetail',
        'Modules\\\\SmartTimetable\\\\Models\\\\BatchOperation',
        'Modules\\\\SmartTimetable\\\\Models\\\\BatchOperationItem',
        'Modules\\\\SmartTimetable\\\\Models\\\\SubstitutionPattern',
        'Modules\\\\SmartTimetable\\\\Models\\\\SubstitutionRecommendation',
        'Modules\\\\SmartTimetable\\\\Models\\\\GenerationQueue',
    ];
    foreach (\$models as \$model) {
        try {
            \$model::first();
            echo \"OK: \$model\\n\";
        } catch (\\Exception \$e) {
            echo \"FAIL: \$model - \" . \$e->getMessage() . \"\\n\";
        }
    }
"

# Step 4: Verify GENERATED columns work (insert test row, check computed value)
php artisan tinker --execute="
    use Modules\\SmartTimetable\\Models\\RoomUtilization;
    \$r = RoomUtilization::create([
        'timetable_id' => 1,
        'room_id' => 1,
        'total_available_periods' => 40,
        'total_booked_periods' => 30,
        'created_by' => 1,
    ]);
    \$r->refresh();
    echo 'utilization_percentage: ' . \$r->utilization_percentage . ' (expected 75.00)' . PHP_EOL;
    \$r->forceDelete();

    use Modules\\SmartTimetable\\Models\\SubstitutionPattern;
    \$s = SubstitutionPattern::create([
        'success_count' => 8,
        'total_count' => 10,
        'confidence_score' => 50,
        'created_by' => 1,
    ]);
    \$s->refresh();
    echo 'success_rate: ' . \$s->success_rate . ' (expected 80.00)' . PHP_EOL;
    \$s->forceDelete();
"
```

---

## ACCEPTANCE CRITERIA

- [ ] All 12 migration files exist in `{LARAVEL_REPO}/database/migrations/tenant/`
- [ ] All 12 tables are created successfully by `php artisan migrate`
- [ ] All 12 models are queryable — `Model::first()` returns null (empty) without throwing
- [ ] GENERATED columns on `tt_room_utilizations.utilization_percentage` compute correctly
- [ ] GENERATED columns on `tt_substitution_patterns.success_rate` compute correctly
- [ ] All FK constraints are valid and enforced
- [ ] No migration errors on fresh migrate or rollback + re-migrate
- [ ] `php artisan migrate:rollback` drops all 12 tables cleanly

---

## DO NOT

- Do NOT drop or modify any existing tables — additive-only policy
- Do NOT modify any model files — the models are correct, only the tables are missing
- Do NOT use singular table names — follow existing `tt_` prefix + plural convention
- Do NOT add columns not listed in the model's `$fillable` / `$casts` — match the model exactly
- Do NOT change any service or controller code
- Do NOT skip FK constraints for tables that already exist (e.g., `tt_timetables`, `tt_timetable_cells`)
