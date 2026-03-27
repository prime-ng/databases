# PROMPT: Fix FormRequest authorize() Methods — HPC Module
**Task ID:** P0_02
**Issue IDs:** SEC-HPC-002
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

7 of 14 HPC FormRequests have `authorize()` returning `true` unconditionally, bypassing authorization on store/update operations. Four of these belong to controllers that ALSO lack Gate checks on store/update (CircularGoalsController, KnowledgeGraphValidationController, QuestionMappingController, SyllabusCoverageSnapshotController), meaning ~8 endpoints are completely unprotected. The other 7 FormRequests correctly use `Gate::allows()`.

---

## PRE-READ (Mandatory)

1. `{MODULE_PATH}/app/Http/Requests/CircularGoalsRequest.php`
2. `{MODULE_PATH}/app/Http/Requests/HpcTemplatePartsRequest.php`
3. `{MODULE_PATH}/app/Http/Requests/HpcTemplateRubricsRequest.php`
4. `{MODULE_PATH}/app/Http/Requests/HpcTemplateSectionsRequest.php`
5. `{MODULE_PATH}/app/Http/Requests/HpcTemplatesRequest.php`
6. `{MODULE_PATH}/app/Http/Requests/KnowledgeGraphValidationRequest.php`
7. `{MODULE_PATH}/app/Http/Requests/QuestionMappingRequest.php`
8. `{MODULE_PATH}/app/Http/Requests/SyllabusCoverageSnapshotRequest.php`
9. One working FormRequest for reference pattern (e.g., `HpcParametersRequest.php`)

---

## STEPS

1. Read one of the working FormRequests (e.g., HpcParametersRequest) to see the correct Gate::allows() pattern
2. For each of the 8 broken FormRequests listed above, replace `return true;` in `authorize()` with the correct `Gate::allows()` check:
   - `CircularGoalsRequest` → `Gate::allows('tenant.circular-goals.create')` (or `.update` based on route)
   - `HpcTemplatePartsRequest` → `Gate::allows('tenant.hpc-template-parts.create')`
   - `HpcTemplateRubricsRequest` → `Gate::allows('tenant.hpc-template-rubrics.create')`
   - `HpcTemplateSectionsRequest` → `Gate::allows('tenant.hpc-template-sections.create')`
   - `HpcTemplatesRequest` → `Gate::allows('tenant.hpc-templates.create')`
   - `KnowledgeGraphValidationRequest` → `Gate::allows('tenant.knowledge-graph-validation.create')`
   - `QuestionMappingRequest` → `Gate::allows('tenant.question-mapping.create')`
   - `SyllabusCoverageSnapshotRequest` → `Gate::allows('tenant.syllabus-coverage-snapshot.create')`
3. Use the same pattern as the working FormRequests — check if it differentiates create vs update based on route method
4. Ensure `use Illuminate\Support\Facades\Gate;` is imported in each file

---

## ACCEPTANCE CRITERIA

- All 14 FormRequests have proper Gate checks in authorize()
- Zero FormRequests return unconditional `true`
- Permission strings match the controller's resource name pattern
- Files parse without syntax errors

---

## DO NOT

- Do NOT modify the `rules()` method in any FormRequest
- Do NOT create new FormRequest classes
- Do NOT modify controllers in this task
- Do NOT change the 7 FormRequests that already work correctly
