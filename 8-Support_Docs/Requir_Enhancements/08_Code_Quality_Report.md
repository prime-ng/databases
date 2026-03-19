# 08 — Code Quality Report

## Executive Summary

The codebase has significant code quality issues concentrated in a few key areas: widespread dead code (backup files, commented-out blocks, debug methods), duplicated boilerplate patterns, naming inconsistencies, and active `dd()` calls in production code that will crash the application.

---

## 1. Dead Code Detection

### DC-001: Backup/Copy Files (Should Be Deleted)

| File | Type |
|------|------|
| `Modules/Prime/app/Http/Controllers/TenantManagementController copy.php` | Copy file |
| `Modules/Payment/app/Http/Controllers/PaymentController copy.php` | Copy file |
| `Modules/GlobalMaster/database/seeders/DropdownSeeder copy.bk` | Backup file |
| `Modules/Prime/app/Models/Dropdown_old_4th_feb.bk` | Old model backup |
| `Modules/Prime/database/migrations/2025_11_18_114615_create_dropdown_needs_table_old.bk` | Old migration |
| `Modules/SmartTimetable/resources/views/smart-timetable/partials/teacher-availability/_list.blade copy.php` | View copy |

### DC-002: Date-Stamped Backup Controllers

These belong in git history, not in the codebase:

| File |
|------|
| `Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController_29_01_before_store.php` |
| `Modules/SchoolSetup/app/Http/Controllers/ClassGroupController_06_02_2026.php` |
| `Modules/SchoolSetup/app/Http/Controllers/ClassGroupController_02_02_2026.php` |
| `Modules/SchoolSetup/app/Http/Controllers/ClassGroupJntController_09_02_2026.php` |
| `Modules/SchoolSetup/app/Http/Controllers/StudentController_20_11_2025.php` |
| `Modules/SchoolSetup/app/Http/Controllers/StudentController_backup_04_12_2025.php` |
| `Modules/Notification/app/Services/NotificationService_25_02_2026.php` |

### DC-003: Deprecated Service Directory

The entire directory `Modules/SmartTimetable/app/Services/EXTRA_delete_10_02/` contains **14 files** tagged for deletion but still present.

### DC-004: Misplaced Files

| File | Problem |
|------|---------|
| `Modules/SchoolSetup/app/Http/Controllers/competency.blade.php` | Blade view in Controllers directory |
| `Modules/SmartTimetable/app/Http/Controllers/data_for_seeder.md` | Markdown file in Controllers directory |

### DC-005: Large Commented-Out Code Blocks

| File | Lines | Content |
|------|-------|---------|
| `StudentController.php` | 1818-1954 | Old `updatePreviousEducation` method (~136 lines) |
| `StudentController.php` | 2049-2106 | Old `updateStudentDocument` method (~57 lines) |
| `SmartTimetableController.php` | 252-292 | Commented-out constraint additions |

---

## 2. Active `dd()` Calls in Production Code (CRITICAL)

| File | Line | Impact |
|------|------|--------|
| `ComplaintController.php` | 393 | `dd($e->getMessage())` in catch block — crashes on error |
| `ComplaintController.php` | 819 | `dd('FILTER HIT')` — kills the filter endpoint for all users |
| `LmsExamController.php` | 565 | `dd($e)` in catch block after `DB::rollBack()` not called |

**These must be removed immediately.**

---

## 3. Code Quality Issues

### CQ-001: Hardcoded Route Names with localhost

Multiple controllers use `central-127.0.0.1` in route names:
```php
return redirect()->to(route('central-127.0.0.1.prime.user-role-prm.index') . '#tanent')
```
Found in: Prime, SchoolSetup, Billing, Scheduler, Documentation modules.

**Fix:** Replace with environment-agnostic route names using `config('app.domain')`.

### CQ-002: Hardcoded Dropdown IDs (Magic Numbers)

| File | Line | Value |
|------|------|-------|
| `ComplaintController.php` | 343 | `'status_id' => 124` |
| `ComplaintController.php` | 547 | `'action_type_id' => 197` |

**Fix:** Replace with named constants or config-based lookup.

### CQ-003: Faker Import in Production Controllers

| File | Problem |
|------|---------|
| `SmartTimetableController.php` | `use Faker\Factory as Faker;` — test dependency in production |
| `StudentFeeController.php` | Same issue |

### CQ-004: Duplicated Boilerplate Patterns

**Activity Log boilerplate** (identical in 15+ controllers):
```php
//begin::Activity Log
activityLog($model, 'Stored', ['message' => 'A new X was created.', 'other' => 'some other information']);
//end::Activity Log
```
The `'other' => 'some other information'` is a placeholder never replaced.

**Change tracking boilerplate** (identical in 5+ controllers):
```php
$original = $model->getOriginal();
$changes = $model->getChanges();
$changedAttributes = [];
foreach ($changes as $field => $newValue) {
    if ($field === 'updated_at') continue;
    // ...
}
```

**Toggle status boilerplate** — identical pattern in every controller with toggleStatus.

**Fix:** Extract into traits or a base controller method.

### CQ-005: Escalation Logic Duplicated

In `ComplaintController.php`, the escalation timeline calculation (levels 1-5 + Breached) appears **twice** — once in `index()` (lines 91-157) and identically in `getComplaintsWithEscalation()` (lines 619-691). The `index()` method even calls `getComplaintsWithEscalation()` but then **overwrites** the result by re-querying at line 87.

### CQ-006: Inconsistent Authorization Patterns

| Pattern | Used In |
|---------|---------|
| `Gate::authorize('prime.role-permission.create')` | Prime module |
| `Gate::authorize('tenant.complaint.viewAny')` | Complaint module |
| `Gate::any([...]) \|\| abort(403)` | Some controllers |
| No authorization at all | SmartTimetableController (all 22 methods) |

### CQ-007: Typo in Hardcoded Route

`'#tanent'` instead of `'#tenant'` in multiple redirect calls in Prime controllers.

---

## 4. Recommendations

### P0 — Immediate
1. Remove active `dd()` calls (DC-006)
2. Fix `LmsExamController` catch block where `dd($e)` runs before `DB::rollBack()`

### P1 — High Priority
3. Delete all backup/copy files (DC-001, DC-002)
4. Delete `EXTRA_delete_10_02/` directory
5. Remove Faker import from production controllers
6. Remove misplaced files from Controllers directories

### P2 — Medium Priority
7. Extract duplicated boilerplate into traits
8. Replace `central-127.0.0.1` hardcoded routes
9. Replace hardcoded dropdown IDs with constants
10. Standardize authorization patterns

### P3 — Low Priority
11. Remove commented-out code blocks
12. Fix `#tanent` typo
13. Clean up placeholder activity log messages
