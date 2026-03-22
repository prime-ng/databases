# P21 — Code Quality & Cleanup

**Phase:** 19 | **Priority:** P3 | **Effort:** 3 days
**Skill:** Cleanup + Schema + Backend | **Model:** Sonnet
**Branch:** Tarun_SmartTimetable
**Dependencies:** P08 (Phase 6 — stubs/views done first)

---

## Pre-Requisites

Read before starting:
1. `Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php` — 3,160 lines
2. `Modules/SmartTimetable/app/Models/` — list all models
3. `AI_Brain/rules/smart-timetable.md`

---

## Task 19.1 — Split SmartTimetableController (2 days)

**CRITICAL:** This is the biggest refactoring task. The controller is 3,160 lines (god controller).

**Extract into 4 new controllers:**

### 19.1.1 — GenerationController

**File:** `Modules/SmartTimetable/app/Http/Controllers/GenerationController.php` (NEW)

Move these methods:
- `generateWithFET()`
- `storeTimetable()`
- `previewTimetable()`
- `saveGeneratedTimetable()` (if not already deleted by P01)
- Any helper methods used only by generation

### 19.1.2 — TimetableMasterController

**File:** `Modules/SmartTimetable/app/Http/Controllers/TimetableMasterController.php` (NEW)

Move:
- `timetableMaster()`
- Tab view methods (class timetable, teacher timetable, room timetable views)
- Any data-loading methods for the master view

### 19.1.3 — ConstraintManagementController

**File:** `Modules/SmartTimetable/app/Http/Controllers/ConstraintManagementController.php` (NEW)

Move:
- `constraintManagement()`
- Related constraint view methods

### 19.1.4 — SmartTimetableReportController

**File:** `Modules/SmartTimetable/app/Http/Controllers/SmartTimetableReportController.php` (NEW)

Move:
- Report/export methods
- Print-related methods

### 19.1.5 — Keep SmartTimetableController thin

SmartTimetableController becomes an index-only controller:
```php
class SmartTimetableController extends Controller
{
    public function index()
    {
        Gate::authorize('smart-timetable.timetable.viewAny');
        // Load dashboard data
        return view('smarttimetable::index', compact(...));
    }
}
```

### 19.1.6 — Update routes

**File:** `routes/tenant.php`
Update all route references from `SmartTimetableController` to the appropriate new controller.

**WARNING:** This will change many route references. Make sure to:
- Update all `Route::get/post/put/delete` calls
- Keep the same route names
- Test `php artisan route:list --path=smart-timetable` after changes

---

## Task 19.2 — Convert inline validation to FormRequests (0.5 day)

**16 controllers** use `$request->validate()` instead of FormRequests.

For each controller with inline validation:
1. Create a FormRequest: `Modules/SmartTimetable/app/Http/Requests/{Resource}StoreRequest.php`
2. Move validation rules from controller to FormRequest `rules()` method
3. Add `authorize()` method returning `true` (Gate check is already in controller)
4. Update controller method signature: `store(ResourceStoreRequest $request)`

**Priority controllers** (most validation logic):
- ActivityController (6 validate calls)
- TeacherAvailabilityController
- RequirementConsolidationController
- SmartTimetableController (or its extracted controllers)

---

## Task 19.3 — Add SoftDeletes to 40 models (0.5 day)

**Skill: Schema**

### 19.3.1 — Create migration

**File:** `database/migrations/tenant/2026_03_XX_add_soft_deletes_to_tt_tables.php`

```php
Schema::table('tt_activities', function (Blueprint $table) {
    if (!Schema::hasColumn('tt_activities', 'deleted_at')) {
        $table->softDeletes();
    }
});
// Repeat for each table that lacks deleted_at
```

### 19.3.2 — Add trait to models

For each model in `Modules/SmartTimetable/app/Models/`:
1. Add `use Illuminate\Database\Eloquent\SoftDeletes;`
2. Add `use SoftDeletes;` trait
3. Ensure `deleted_at` is in `$dates` if using older Laravel style

**Check first:** `grep -r "SoftDeletes" Modules/SmartTimetable/app/Models/ | wc -l` — how many already have it?

Only add to models that DON'T already have SoftDeletes.

---

## Task 19.4 — Delete dead code and cleanup (2 hrs)

### 19.4.1 — Remove debug methods from SmartTimetableController (~550 lines)

Search for methods that are:
- Only used for debugging (contain `dd()`, `dump()`, `var_dump()`)
- Have `debug` or `test` in their name
- Are not referenced by any route

### 19.4.2 — Clean up imports

For each controller/service file:
- Remove unused `use` statements
- Sort remaining imports

### 19.4.3 — Remove commented-out code blocks

Search for large blocks of commented code (10+ lines) and remove them. The code is in git history.

---

## Post-Execution Checklist

1. Run: `/lint Modules/SmartTimetable/` — all files pass
2. Run: `/test SmartTimetable` — all tests pass
3. Run: `php artisan route:list --path=smart-timetable` — all routes resolve correctly
4. If migration added: `php artisan tenants:migrate` on test tenant
5. Count SmartTimetableController lines: should be < 200 (was 3,160)
6. Update AI Brain:
   - `progress.md` → Phase 19 done, Module at ~98% complete
   - `known-issues.md` → Mark QUAL-NEW-01 (god controller), QUAL-NEW-02 (inline validation), MODEL-NEW-01 (SoftDeletes) as RESOLVED
   - `modules-map.md` → Update SmartTimetable completion to ~98%
