# PROMPT: Fix TimetableCell scopeForClass — SmartTimetable DDL Gap Fix
**Task ID:** P0_03
**Issue IDs:** BUG-DDL-003
**Priority:** P0-Critical
**Estimated Effort:** 10 minutes
**Prerequisites:** None — this is a P0 task, do it first

---

## CONFIGURATION
```
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai_tarun
MODULE_PATH    = {LARAVEL_REPO}/Modules/SmartTimetable
BRANCH         = Brijesh_SmartTimetable
```

---

## CONTEXT

The `TimetableCell` model has a `scopeForClass($query, $classId, $sectionId)` method that directly queries `->where('class_id', $classId)->where('section_id', $sectionId)` on the `tt_timetable_cells` table. However, `class_id` and `section_id` columns do NOT exist on `tt_timetable_cells` — neither in the DDL nor in the migration. These columns exist on `tt_activities`, and a cell links to an activity via `activity_id` FK.

Any code calling `TimetableCell::forClass(...)` will crash with "Unknown column 'class_id'".

See `05_Real_Bugs_Found.md` — BUG-DDL-003.

---

## PRE-READ (Mandatory)

1. `{MODULE_PATH}/app/Models/TimetableCell.php` — the model with the broken scope
2. `{MODULE_PATH}/app/Models/Activity.php` — confirm `class_id` and `section_id` exist here
3. Search for `scopeForClass` or `forClass` usage across SmartTimetable controllers/services

---

## STEPS

1. Open `{MODULE_PATH}/app/Models/TimetableCell.php`
2. Find the `scopeForClass` method
3. Replace the direct column queries with a `whereHas` through the activity relationship:
   ```php
   public function scopeForClass($query, $classId, $sectionId = null)
   {
       return $query->whereHas('activity', function ($q) use ($classId, $sectionId) {
           $q->where('class_id', $classId);
           if ($sectionId) {
               $q->where('section_id', $sectionId);
           }
       });
   }
   ```
4. Verify the `activity()` BelongsTo relationship exists on `TimetableCell`
5. Search for any other direct `class_id` or `section_id` references on `TimetableCell` queries across the module and fix them similarly
6. Run `php -l {MODULE_PATH}/app/Models/TimetableCell.php`

---

## ACCEPTANCE CRITERIA

- `TimetableCell::forClass($classId, $sectionId)->get()` executes without "Unknown column" error
- The query correctly filters cells by their associated activity's class/section
- No direct `class_id`/`section_id` queries remain on the `TimetableCell` model or its scopes

---

## DO NOT

- Do NOT add `class_id`/`section_id` columns to `tt_timetable_cells` via migration
- Do NOT modify the `Activity` model
- Do NOT change any controller logic beyond fixing the scope usage
