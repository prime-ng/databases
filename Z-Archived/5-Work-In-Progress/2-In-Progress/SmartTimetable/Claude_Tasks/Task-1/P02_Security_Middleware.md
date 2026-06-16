# P02 — Security: Middleware & Truncate Protection

**Phase:** 2 (Tasks 2.1–2.2) | **Priority:** P0 | **Effort:** 0.75 day
**Skill:** Backend | **Model:** Sonnet
**Branch:** Tarun_SmartTimetable
**Dependencies:** None (can run parallel with P01)

---

## Pre-Requisites

Read these files before starting:
1. `AI_Brain/rules/tenancy-rules.md` — EnsureTenantHasModule pattern
2. `AI_Brain/rules/smart-timetable.md`
3. `routes/tenant.php` — find the SmartTimetable route group (~line 1766)
4. `app/Http/Middleware/EnsureTenantHasModule.php` — verify it exists

---

## Task 2.1 — Add `EnsureTenantHasModule` middleware (15 min)

**File:** `routes/tenant.php`
**Line:** ~1766 (the SmartTimetable route group)

**Change:** Add `'module:SmartTimetable'` to the middleware array on the SmartTimetable route group.

Find the route group that looks like:
```php
Route::prefix('smart-timetable')->group(function () {
```
Or:
```php
Route::middleware([...])->prefix('smart-timetable')->group(function () {
```

Change to:
```php
Route::middleware(['module:SmartTimetable'])->prefix('smart-timetable')->group(function () {
```

**Also verify:**
1. `EnsureTenantHasModule` middleware exists at `app/Http/Middleware/EnsureTenantHasModule.php`
2. It is registered in `bootstrap/app.php` or `app/Http/Kernel.php` with alias `module`
3. The `module_slug` or module key used matches how SmartTimetable is stored in the tenant's enabled modules

**Why:** Without this middleware, tenants who haven't purchased the SmartTimetable module can still access all its routes.
**Verify:** Check `php artisan route:list --path=smart-timetable` — middleware column should show `module:SmartTimetable`.

---

## Task 2.2 — Protect destructive `truncate()` operations (30 min)

There are 3 controllers with unprotected `truncate()` calls that disable foreign key checks:

### 2.2.1 — ActivityController

**File:** `Modules/SmartTimetable/app/Http/Controllers/ActivityController.php`
**Line:** ~73

Find the truncate block (likely in a `generate` or `regenerate` method):
```php
DB::statement('SET FOREIGN_KEY_CHECKS=0');
Activity::truncate();  // or similar
DB::statement('SET FOREIGN_KEY_CHECKS=1');
```

**Change:** Add authorization before the truncate:
```php
Gate::authorize('smart-timetable.activity.generate');

// Add confirmation check
if (!$request->boolean('confirm_truncate')) {
    return back()->with('warning', 'This will delete all existing activities. Please confirm.');
}

DB::statement('SET FOREIGN_KEY_CHECKS=0');
Activity::truncate();
DB::statement('SET FOREIGN_KEY_CHECKS=1');
```

Add `use Illuminate\Support\Facades\Gate;` at the top of the file.

### 2.2.2 — TeacherAvailabilityController

**File:** `Modules/SmartTimetable/app/Http/Controllers/TeacherAvailabilityController.php`
**Line:** ~74

Same pattern — add Gate authorization:
```php
Gate::authorize('smart-timetable.teacher-availability.generate');
```

### 2.2.3 — RequirementConsolidationController

**File:** `Modules/SmartTimetable/app/Http/Controllers/RequirementConsolidationController.php`
**Line:** ~848

Same pattern — add Gate authorization:
```php
Gate::authorize('smart-timetable.requirement.generate');
```

**Why:** Any authenticated user can currently wipe all activities, teacher availability, or requirements with no authorization check.

**Verify for all 3:**
- `grep -n "Gate::authorize" ActivityController.php` — should have entries
- `grep -n "truncate" ActivityController.php` — each should be preceded by Gate check

---

## Post-Execution Checklist

1. Run: `/lint Modules/SmartTimetable/app/Http/Controllers/ActivityController.php`
2. Run: `/lint Modules/SmartTimetable/app/Http/Controllers/TeacherAvailabilityController.php`
3. Run: `/lint Modules/SmartTimetable/app/Http/Controllers/RequirementConsolidationController.php`
4. Run: `/test SmartTimetable` — existing tests should pass
5. Run: `php artisan route:list --path=smart-timetable` — verify no errors
6. Update AI Brain:
   - `known-issues.md` → Mark SEC-NEW-01 (truncate) and SEC-NEW-03 (EnsureTenantHasModule) as RESOLVED
   - `progress.md` → Phase 2 Tasks 2.1-2.2 done
