# PROMPT: Add Authorization to All HpcController Methods — HPC Module
**Task ID:** P0_01
**Issue IDs:** SEC-HPC-001
**Priority:** P0-Critical
**Estimated Effort:** 2 hours
**Prerequisites:** None — this is a P0 task, do it first

---

## CONFIGURATION
```
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai
MODULE_PATH    = {LARAVEL_REPO}/Modules/Hpc
ROUTES_FILE    = {LARAVEL_REPO}/routes/tenant.php
```

---

## CONTEXT

HpcController (~2297 lines) has 15 public methods but only 2 have authorization: `index()` uses `Gate::any()` and `sendReportEmail()` uses `Gate::authorize()`. The remaining 13 methods have ZERO authorization — any authenticated tenant user can view any student's HPC form, save evaluations, generate PDFs, download ZIP archives, and access single-student reports. This is a critical security vulnerability affecting student data privacy.

---

## PRE-READ (Mandatory)

1. `{MODULE_PATH}/app/Http/Controllers/HpcController.php` — The main controller (~2297 lines)
2. `{ROUTES_FILE}` — Search for HPC route group (around line 2498) to understand route-to-method mapping

---

## STEPS

1. Read HpcController.php completely to identify all 15 public methods
2. For each of the following 13 unprotected methods, add appropriate `Gate::authorize()` at the start:
   - `hpcTemplates()` → `Gate::authorize('tenant.hpc.viewAny')`
   - `create()` → `Gate::authorize('tenant.hpc.create')`
   - `store()` → `Gate::authorize('tenant.hpc.create')`
   - `show($id)` → `Gate::authorize('tenant.hpc.view')`
   - `edit($id)` → `Gate::authorize('tenant.hpc.update')`
   - `update($id)` → `Gate::authorize('tenant.hpc.update')`
   - `destroy($id)` → `Gate::authorize('tenant.hpc.delete')`
   - `hpc_form()` → `Gate::authorize('tenant.hpc.view')`
   - `formStore()` → `Gate::authorize('tenant.hpc.update')`
   - `generateReportPdf()` → `Gate::authorize('tenant.hpc.viewAny')`
   - `viewPdfPage()` → `Gate::authorize('tenant.hpc.view')`
   - `generateSingleStudentPdf()` → `Gate::authorize('tenant.hpc.view')`
   - `downloadZip()` → `Gate::authorize('tenant.hpc.viewAny')`
3. Ensure `use Illuminate\Support\Facades\Gate;` is imported at the top of the file
4. Do NOT change the existing `index()` Gate::any or `sendReportEmail()` Gate::authorize — they are already working

---

## ACCEPTANCE CRITERIA

- All 15 public methods in HpcController have Gate authorization
- `Gate::authorize()` is used (not `Gate::allows()`) so it throws 403 on failure
- Permission strings follow the existing `tenant.hpc.*` pattern
- No other code changes made to the controller
- File still parses without syntax errors

---

## DO NOT

- Do NOT refactor the controller structure or extract methods
- Do NOT change the existing index() or sendReportEmail() authorization
- Do NOT add Policy classes — just use Gate::authorize() inline
- Do NOT modify any business logic or views
