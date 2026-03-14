# P04 — Security: Auth on Remaining Controllers + Policy + Seeder

**Phase:** 2 (Tasks 2.4–2.7) | **Priority:** P0 | **Effort:** 1.5 days
**Skill:** Backend + Schema | **Model:** Sonnet
**Branch:** Tarun_SmartTimetable
**Dependencies:** P03 should be done first (pattern established)

---

## Pre-Requisites

Read these files before starting:
1. `AI_Brain/rules/smart-timetable.md`
2. `AI_Brain/rules/module-rules.md` — policy patterns
3. Any already-protected controller for reference: `Modules/SmartTimetable/app/Http/Controllers/TtConfigController.php`

---

## Task 2.4 — Add authorization to 14 unprotected controllers (3 hrs)

Apply `Gate::authorize()` to every public method in each of these controllers:

### Priority: CRITICAL (destructive operations)

**1. ActivityController** — `Modules/SmartTimetable/app/Http/Controllers/ActivityController.php`
```
index()           → Gate::authorize('smart-timetable.activity.viewAny')
create()          → Gate::authorize('smart-timetable.activity.create')
store()           → Gate::authorize('smart-timetable.activity.create')
show($id)         → Gate::authorize('smart-timetable.activity.view')
edit($id)         → Gate::authorize('smart-timetable.activity.update')
update($id)       → Gate::authorize('smart-timetable.activity.update')
destroy($id)      → Gate::authorize('smart-timetable.activity.delete')
generate*()       → Gate::authorize('smart-timetable.activity.generate')
```

**2. TeacherAvailabilityController** — same pattern with `smart-timetable.teacher-availability.*`

**3. RequirementConsolidationController** — same pattern with `smart-timetable.requirement.*`

### Priority: HIGH (CRUD exposed)

**4. ClassSubjectSubgroupController** — `smart-timetable.class-subject-subgroup.*`
**5. PeriodSetPeriodController** — `smart-timetable.period-set-period.*`
**6. RoomUnavailableController** — `smart-timetable.room-unavailable.*`
**7. SlotRequirementController** — `smart-timetable.slot-requirement.*`
**8. TeacherAssignmentRoleController** — `smart-timetable.teacher-assignment-role.*`
**9. TeacherUnavailableController** — `smart-timetable.teacher-unavailable.*`

### Priority: MEDIUM (stubs/crashes, still protect)

**10. TimetableController** — `smart-timetable.timetable.*`
**11. TimetableTypeController** — `smart-timetable.timetable-type.*`
**12. PeriodController** — `smart-timetable.period.*` (if kept; may be deleted by P01 Task 1.6)
**13. WorkingDayController** — `smart-timetable.working-day.*`

### Already has FormRequests (add Gate too)

**14. ParallelGroupController** — Already has FormRequests but no Gate:
```
index()           → Gate::authorize('smart-timetable.parallel-group.viewAny')
store()           → Gate::authorize('smart-timetable.parallel-group.create')
show($id)         → Gate::authorize('smart-timetable.parallel-group.view')
update($id)       → Gate::authorize('smart-timetable.parallel-group.update')
destroy($id)      → Gate::authorize('smart-timetable.parallel-group.delete')
addActivities()   → Gate::authorize('smart-timetable.parallel-group.update')
removeActivity()  → Gate::authorize('smart-timetable.parallel-group.update')
setAnchor()       → Gate::authorize('smart-timetable.parallel-group.update')
autoDetect()      → Gate::authorize('smart-timetable.parallel-group.create')
```

**Pattern for each controller:**
1. Add `use Illuminate\Support\Facades\Gate;` import
2. Add `Gate::authorize('smart-timetable.{resource}.{action}');` as first line of every public method
3. Do NOT add Gate to `__construct()` or private/protected methods

---

## Task 2.5 — Implement SmartTimetablePolicy (1 hr)

**File:** `app/Policies/SmartTimetablePolicy.php`

Read the existing file first — it may be an empty stub. Implement all standard methods:

```php
<?php

namespace App\Policies;

use App\Models\User;
use Illuminate\Auth\Access\HandlesAuthorization;

class SmartTimetablePolicy
{
    use HandlesAuthorization;

    public function viewAny(User $user): bool
    {
        return $user->hasPermissionTo('smart-timetable.timetable.viewAny');
    }

    public function view(User $user): bool
    {
        return $user->hasPermissionTo('smart-timetable.timetable.view');
    }

    public function create(User $user): bool
    {
        return $user->hasPermissionTo('smart-timetable.timetable.create');
    }

    public function update(User $user): bool
    {
        return $user->hasPermissionTo('smart-timetable.timetable.update');
    }

    public function delete(User $user): bool
    {
        return $user->hasPermissionTo('smart-timetable.timetable.delete');
    }

    public function generate(User $user): bool
    {
        return $user->hasPermissionTo('smart-timetable.timetable.generate');
    }

    public function export(User $user): bool
    {
        return $user->hasPermissionTo('smart-timetable.report.export');
    }
}
```

**Register in `app/Providers/AppServiceProvider.php`** (or `AuthServiceProvider`):
```php
Gate::policy(Modules\SmartTimetable\Models\Timetable::class, SmartTimetablePolicy::class);
```

---

## Task 2.6 — Register permissions in seeder (1 hr)

**File:** Create `Modules/SmartTimetable/database/seeders/SmartTimetablePermissionSeeder.php`

Generate all permissions for the RBAC system:

```php
<?php

namespace Modules\SmartTimetable\Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Permission;

class SmartTimetablePermissionSeeder extends Seeder
{
    public function run(): void
    {
        $resources = [
            'timetable', 'activity', 'constraint', 'parallel-group',
            'teacher-availability', 'requirement', 'class-subject-subgroup',
            'period-set', 'period-set-period', 'room-unavailable',
            'slot-requirement', 'teacher-assignment-role', 'teacher-unavailable',
            'timetable-type', 'working-day', 'school-day', 'school-shift',
            'day-type', 'period-type', 'timing-profile', 'tt-config',
            'generation-strategy', 'report', 'academic-term',
        ];

        $actions = ['viewAny', 'view', 'create', 'update', 'delete'];
        $specialActions = [
            'timetable' => ['generate', 'publish'],
            'activity' => ['generate'],
            'requirement' => ['generate'],
            'teacher-availability' => ['generate'],
            'report' => ['export'],
        ];

        foreach ($resources as $resource) {
            foreach ($actions as $action) {
                Permission::firstOrCreate([
                    'name' => "smart-timetable.{$resource}.{$action}",
                    'guard_name' => 'web',
                ]);
            }

            // Special actions for specific resources
            if (isset($specialActions[$resource])) {
                foreach ($specialActions[$resource] as $special) {
                    Permission::firstOrCreate([
                        'name' => "smart-timetable.{$resource}.{$special}",
                        'guard_name' => 'web',
                    ]);
                }
            }
        }
    }
}
```

**Register in `SmartTimetableDatabaseSeeder`** — add `$this->call(SmartTimetablePermissionSeeder::class);`

---

## Task 2.7 — Remove `$request->all()` from log statements (15 min)

### File 1: `ClassSubjectSubgroupController.php`
**Line:** ~203
**Change:** Replace `Log::info('...', $request->all())` with:
```php
Log::info('ClassSubjectSubgroup operation', [
    'user_id' => auth()->id(),
    'action' => 'store',  // or whatever action
]);
```

### File 2: `SmartTimetableController.php`
**Line:** ~2998
**Change:** Same pattern — log only specific fields:
```php
Log::info('Timetable operation', [
    'user_id' => auth()->id(),
    'academic_session_id' => $request->input('academic_session_id'),
]);
```

**Why:** `$request->all()` can contain sensitive data (passwords, tokens) that gets written to log files.

---

## Post-Execution Checklist

1. Run: `/lint Modules/SmartTimetable/` — all files should pass
2. Count total Gate calls across all controllers:
   ```bash
   grep -r "Gate::authorize" Modules/SmartTimetable/app/Http/Controllers/ | wc -l
   ```
   Should be 80+ (across all 28 controllers)
3. Run: `/test SmartTimetable` — existing tests should pass
4. Run: `php artisan db:seed --class="Modules\SmartTimetable\Database\Seeders\SmartTimetablePermissionSeeder"` (on a test tenant)
5. Update AI Brain:
   - `known-issues.md` → Mark SEC-009 as FULLY RESOLVED, SEC-NEW-02 RESOLVED, SEC-NEW-04 RESOLVED, QUAL-NEW-03 RESOLVED
   - `progress.md` → Phase 2 Tasks 2.4-2.7 done, Security category → 100%
