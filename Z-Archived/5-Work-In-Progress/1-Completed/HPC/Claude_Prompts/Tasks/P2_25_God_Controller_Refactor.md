# PROMPT: Refactor HpcController God Controller — HPC Module
**Task ID:** P2_25
**Issue IDs:** Refactor
**Priority:** P2-Medium
**Estimated Effort:** 3 days
**Prerequisites:** All P0 and P1 tasks must be complete

---

## CONFIGURATION
```
MODULE_PATH    = /Users/bkwork/Herd/prime_ai/Modules/Hpc
```

---

## CONTEXT

HpcController is ~2297 lines — a "god controller" handling form display, form storage, PDF generation, ZIP download, email dispatch, template listing, and CRUD stubs. Business logic should be extracted into services. The controller should be thin — only handling HTTP request/response, delegating to services.

---

## DESIGN

Extract into services:
1. **HpcFormService** — `loadForm()`, `saveForm()`, `getFormData()`, `getSavedValues()`
2. **HpcReportService** (already exists, 788 lines) — extend with `generateBulkPdf()`, `generateSinglePdf()`, `buildZip()`
3. **HpcPdfDataService** (already exists, 165 lines) — keep as-is
4. Move `buildPdf()`, `minifyHtml()`, `resolveTemplateId()` from controller to HpcReportService

Controller methods become thin wrappers:
```php
public function hpc_form($studentId) {
    $data = $this->formService->loadForm($studentId);
    return view('hpc::hpc_form.index', $data);
}
```

---

## PRE-READ (Mandatory)

1. `{MODULE_PATH}/app/Http/Controllers/HpcController.php` — full read (~2297 lines)
2. `{MODULE_PATH}/app/Services/HpcReportService.php` — existing service
3. `{MODULE_PATH}/app/Services/HpcPdfDataService.php` — existing service

---

## STEPS

1. Read HpcController completely and categorize methods by concern:
   - Form handling: hpc_form, formStore
   - Report generation: generateReportPdf, generateSingleStudentPdf, buildPdf, minifyHtml
   - File management: downloadZip
   - Email: sendReportEmail
   - CRUD stubs: create, store, show, edit, update, destroy
   - Listing: index, hpcTemplates
2. Create `HpcFormService` in `{MODULE_PATH}/app/Services/`
3. Move form logic (data loading, saving, template resolution) into HpcFormService
4. Move PDF generation logic (buildPdf, minifyHtml, resolveTemplateId) into HpcReportService
5. Update HpcController to inject services and delegate
6. Verify all routes still work after refactor

---

## ACCEPTANCE CRITERIA

- HpcController is under 500 lines
- HpcFormService handles all form data logic
- HpcReportService handles all PDF/ZIP generation
- All existing functionality works identically
- No new routes or views needed
- `php artisan route:cache` succeeds

---

## DO NOT

- Do NOT change business logic — only reorganize code location
- Do NOT modify blade templates
- Do NOT change the PDF output
- Do NOT modify routes
