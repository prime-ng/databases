# Mark Legacy Models as Deprecated

| Field              | Value                          |
|--------------------|--------------------------------|
| **Task ID**        | P3_16                          |
| **Issue IDs**      | Legacy cleanup                 |
| **Priority**       | P3-Low                         |
| **Estimated Effort** | 15 min                       |
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

6 models correspond to legacy tables that were superseded by newer, more capable tables during the schema evolution. These models still exist in the codebase and may still be referenced, but the tables they map to are effectively dead. They should be annotated so developers don't accidentally build new features on top of them.

| Legacy Model | Legacy Table | Replaced By |
|---|---|---|
| `Day.php` | `tt_days` | `tt_school_days` |
| `Period.php` | `tt_periods` | `tt_period_types` + `tt_period_sets` |
| `TimingProfile.php` | `tt_timing_profiles` | `tt_period_sets` |
| `TimingProfilePeriod.php` | `tt_timing_profile_periods` | `tt_period_set_periods` |
| `TimetableMode.php` | `tt_timetable_modes` | `tt_timetable_types` |
| `ClassModeRule.php` | `tt_class_mode_rules` | `tt_class_timetable_type_jnt` |

---

## PRE-READ

- `{MODULE_PATH}/app/Models/Day.php`
- `{MODULE_PATH}/app/Models/Period.php`
- `{MODULE_PATH}/app/Models/TimingProfile.php`
- `{MODULE_PATH}/app/Models/TimingProfilePeriod.php`
- `{MODULE_PATH}/app/Models/TimetableMode.php`
- `{MODULE_PATH}/app/Models/ClassModeRule.php`

---

## STEPS

### Step 1 — Add @deprecated Docblock to Each Model

For each of the 6 model files, add a `@deprecated` PHPDoc block above the class declaration. Example for `Day.php`:

```php
/**
 * @deprecated This model maps to the legacy tt_days table.
 *             Use SchoolDay (tt_school_days) instead.
 *             Retained for migration compatibility — do NOT use in new code.
 */
class Day extends Model
```

Apply the same pattern to all 6 models with the correct replacement noted:

| Model | Deprecation Note |
|---|---|
| `Day` | Use `SchoolDay` (`tt_school_days`) instead |
| `Period` | Use `PeriodType` (`tt_period_types`) + `PeriodSet` (`tt_period_sets`) instead |
| `TimingProfile` | Use `PeriodSet` (`tt_period_sets`) instead |
| `TimingProfilePeriod` | Use `PeriodSetPeriod` (`tt_period_set_periods`) instead |
| `TimetableMode` | Use `TimetableType` (`tt_timetable_types`) instead |
| `ClassModeRule` | Use `ClassTimetableTypeJnt` (`tt_class_timetable_type_jnt`) instead |

### Step 2 — Search for Active Usage

```bash
cd {LARAVEL_REPO}
grep -rn "use.*Models\\Day;" --include="*.php" Modules/SmartTimetable/app/
grep -rn "use.*Models\\Period;" --include="*.php" Modules/SmartTimetable/app/
grep -rn "use.*Models\\TimingProfile;" --include="*.php" Modules/SmartTimetable/app/
grep -rn "use.*Models\\TimingProfilePeriod;" --include="*.php" Modules/SmartTimetable/app/
grep -rn "use.*Models\\TimetableMode;" --include="*.php" Modules/SmartTimetable/app/
grep -rn "use.*Models\\ClassModeRule;" --include="*.php" Modules/SmartTimetable/app/
```

Also check controllers and services specifically:

```bash
grep -rn "Day::\|Period::\|TimingProfile::\|TimingProfilePeriod::\|TimetableMode::\|ClassModeRule::" \
  --include="*.php" Modules/SmartTimetable/app/Http/ Modules/SmartTimetable/app/Services/
```

### Step 3 — Document Any Active Usage Found

If any controller, service, or other non-model file actively uses these legacy models, document each occurrence as a separate bug with:
- File path and line number
- What the code does with the legacy model
- What the replacement should be

Record findings in this task's completion notes.

---

## ACCEPTANCE CRITERIA

- [ ] All 6 model files have `@deprecated` PHPDoc annotation above the class declaration
- [ ] Each annotation includes the replacement model/table name
- [ ] Each annotation includes "do NOT use in new code" guidance
- [ ] Search for active usage completed and results documented
- [ ] Any active usage of deprecated models in controllers/services logged as separate bugs
- [ ] No functional code changes — annotations only

---

## DO NOT

- Don't delete any of the 6 model files
- Don't delete any migration files (migration immutability principle)
- Don't modify any routes
- Don't change any `$table`, `$fillable`, or relationship definitions in these models
- Don't modify any controllers or services in this task — only annotate the models
