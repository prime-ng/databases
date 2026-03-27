# P03 — Security: Auth on SmartTimetableController

**Phase:** 2 (Task 2.3) | **Priority:** P0 | **Effort:** 0.5 day (2 hrs)
**Skill:** Backend | **Model:** Sonnet
**Branch:** Tarun_SmartTimetable
**Dependencies:** None (can run parallel with P01, P02)

---

## Pre-Requisites

Read these files before starting:
1. `AI_Brain/rules/smart-timetable.md`
2. `Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php` — read ENTIRE file to identify all public methods
3. Check existing auth patterns in `Modules/SmartTimetable/app/Http/Controllers/TtConfigController.php` — use same Gate pattern

---

## Task 2.3 — Add authorization to SmartTimetableController (2 hrs)

**File:** `Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php` (3,160 lines)

**Rule:** Every public method must have a `Gate::authorize()` call as its FIRST line.

**Permission naming convention:** `smart-timetable.{resource}.{action}`

### Step 1 — Add Gate import

At top of file, add:
```php
use Illuminate\Support\Facades\Gate;
```

### Step 2 — Add Gate checks to all public methods

Use this mapping (apply to each method):

| Method | Permission | Notes |
|--------|-----------|-------|
| `index()` | `smart-timetable.timetable.viewAny` | Main dashboard |
| `generateWithFET()` | `smart-timetable.timetable.generate` | Most critical — generation |
| `storeTimetable()` | `smart-timetable.timetable.store` | Save generated timetable |
| `previewTimetable()` | `smart-timetable.timetable.view` | Preview before save |
| `timetableMaster()` | `smart-timetable.timetable.viewAny` | Master view |
| `constraintManagement()` | `smart-timetable.constraint.viewAny` | Constraint management page |
| All `*Index()` tab methods | `smart-timetable.{tab-resource}.viewAny` | Tab data views |
| All `store*()` methods | `smart-timetable.{resource}.create` | Create operations |
| All `update*()` methods | `smart-timetable.{resource}.update` | Update operations |
| All `destroy*()` methods | `smart-timetable.{resource}.delete` | Delete operations |
| All `get*()` AJAX methods | `smart-timetable.{resource}.viewAny` | AJAX data fetches |
| All `export*()` methods | `smart-timetable.report.export` | Export operations |

### Step 3 — Apply pattern to each method

For each public method, add as the FIRST line:
```php
public function methodName(Request $request)
{
    Gate::authorize('smart-timetable.resource.action');
    // ... existing code
}
```

### Step 4 — List all public methods and classify

Read through the controller and for EVERY public method:
1. Determine the resource it operates on (timetable, constraint, activity, etc.)
2. Determine the action (viewAny, view, create, update, delete, generate, export)
3. Add the Gate call

**Do NOT skip any public method.** Methods that seem harmless (like AJAX data getters) still need `viewAny` authorization.

### Step 5 — Also protect `saveGeneratedTimetable()` if it still exists

If P01 Task 1.2 hasn't run yet and this method still exists, add:
```php
Gate::authorize('smart-timetable.timetable.store');
```

---

## Post-Execution Checklist

1. Run: `/lint Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php`
2. Count Gate calls: `grep -c "Gate::authorize" SmartTimetableController.php` — should be 20+ (one per public method)
3. Run: `/test SmartTimetable` — existing tests should pass
4. Update AI Brain:
   - `known-issues.md` → Mark SEC-009 as partially resolved (main controller done)
   - `progress.md` → Phase 2 Task 2.3 done
