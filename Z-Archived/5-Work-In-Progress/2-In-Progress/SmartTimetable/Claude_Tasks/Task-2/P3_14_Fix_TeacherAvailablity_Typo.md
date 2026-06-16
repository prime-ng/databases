# Fix TeacherAvailablity Class Name Typo

| Field              | Value                          |
|--------------------|--------------------------------|
| **Task ID**        | P3_14                          |
| **Issue IDs**      | Class name typo                |
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

The model class is named `TeacherAvailablity` (missing the second 'i' — should be `TeacherAvailability`). The filename is also `TeacherAvailablity.php`. This causes confusion when searching, importing, and auto-completing. Every developer who encounters this class has to remember the non-standard spelling, and IDE auto-imports may fail silently.

---

## PRE-READ

- `{MODULE_PATH}/app/Models/TeacherAvailablity.php` — the misspelled model file
- Search results for `TeacherAvailablity` across the entire `{LARAVEL_REPO}` — to find all references

---

## STEPS

### Step 1 — Rename the File

Rename the model file from `TeacherAvailablity.php` to `TeacherAvailability.php`:

```bash
cd {MODULE_PATH}/app/Models
mv TeacherAvailablity.php TeacherAvailability.php
```

### Step 2 — Rename the Class Inside

Open `TeacherAvailability.php` and change:

```php
# OLD
class TeacherAvailablity extends Model

# NEW
class TeacherAvailability extends Model
```

### Step 3 — Search Entire Codebase for All References

```bash
cd {LARAVEL_REPO}
grep -rn "TeacherAvailablity" --include="*.php" .
```

Update every match:
- `use` import statements
- Type hints in method signatures
- Relationship return types
- Service class references
- Controller references
- Any `::class` references

Common locations to check:
- Controllers in `{MODULE_PATH}/app/Http/Controllers/`
- Services in `{MODULE_PATH}/app/Services/`
- Other models that reference this via relationships
- Config files, seeders, factories

### Step 4 — Verify

```bash
# Syntax check the renamed file
php -l {MODULE_PATH}/app/Models/TeacherAvailability.php

# Confirm no references to the old spelling remain
grep -rn "TeacherAvailablity" --include="*.php" {LARAVEL_REPO}
# Expected: 0 results
```

---

## ACCEPTANCE CRITERIA

- [ ] File renamed from `TeacherAvailablity.php` to `TeacherAvailability.php`
- [ ] Class name inside updated to `TeacherAvailability`
- [ ] Zero results from `grep -rn "TeacherAvailablity" --include="*.php"` across entire repo
- [ ] `php -l` passes on the renamed file
- [ ] No runtime errors — class loads correctly via autoload

---

## DO NOT

- Don't change `$table` or `$fillable` properties in the model
- Don't modify the database table name (the table `tt_teacher_availabilities` is already correct)
- Don't rename any other classes in this task
- Don't change any column names or relationships beyond updating the class name reference
