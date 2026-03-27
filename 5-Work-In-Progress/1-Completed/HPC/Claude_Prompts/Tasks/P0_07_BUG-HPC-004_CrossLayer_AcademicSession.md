# PROMPT: Replace Cross-Layer AcademicSession Imports — HPC Module
**Task ID:** P0_07
**Issue IDs:** BUG-HPC-004
**Priority:** P0-Critical
**Estimated Effort:** 1 hour
**Prerequisites:** None — this is a P0 task, do it first

---

## CONFIGURATION
```
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai
MODULE_PATH    = {LARAVEL_REPO}/Modules/Hpc
```

---

## CONTEXT

Three HPC controllers import `Modules\Prime\Models\AcademicSession` (a central/prime DB model) and query it in tenant context. This is a cross-layer violation — tenant controllers should never directly query prime_db/global_db tables. It causes data leakage and will break under strict tenancy isolation. Also `App\Models\User` is imported in StudentHpcEvaluationController for an assessor dropdown — should use tenant-scoped staff model.

Affected controllers:
- `StudentHpcEvaluationController`
- `SyllabusCoverageSnapshotController`
- `HpcController`

---

## PRE-READ (Mandatory)

1. `{MODULE_PATH}/app/Http/Controllers/StudentHpcEvaluationController.php`
2. `{MODULE_PATH}/app/Http/Controllers/SyllabusCoverageSnapshotController.php`
3. `{MODULE_PATH}/app/Http/Controllers/HpcController.php`
4. Check what tenant-side academic session model exists: `{LARAVEL_REPO}/Modules/SchoolSetup/app/Models/` — look for OrganizationAcademicSession or similar

---

## STEPS

1. Find the tenant-side academic session model (likely `OrganizationAcademicSession` in SchoolSetup module or `AcademicTerm` in tenant context)
2. In each of the 3 controllers, replace:
   - `use Modules\Prime\Models\AcademicSession;` → `use Modules\SchoolSetup\Models\OrganizationAcademicSession;` (or correct tenant model)
   - Update all `AcademicSession::` queries to use the tenant model
3. In StudentHpcEvaluationController, replace `use App\Models\User;` with the tenant-scoped user model (`Modules\SchoolSetup\Models\...` or `App\Models\TenantUser`)
4. Verify no other `Modules\Prime\Models\*` imports remain in any HPC controller

---

## ACCEPTANCE CRITERIA

- Zero `Modules\Prime\Models\*` imports in any HPC controller
- Zero `App\Models\User` imports in any HPC controller (use tenant-scoped models)
- Academic session queries return tenant-specific data
- All existing functionality still works (form load, evaluation CRUD, coverage snapshots)

---

## DO NOT

- Do NOT change the Prime module models
- Do NOT create new models — use existing tenant-scoped alternatives
- Do NOT modify business logic — only swap the model imports and adjust queries
