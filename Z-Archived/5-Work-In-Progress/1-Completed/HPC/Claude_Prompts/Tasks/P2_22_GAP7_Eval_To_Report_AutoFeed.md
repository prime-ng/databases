# PROMPT: Auto-Feed Evaluation Data to Report — HPC Module
**Task ID:** P2_22
**Issue IDs:** GAP-7
**Priority:** P2-Medium
**Estimated Effort:** 2 days
**Prerequisites:** All P0 and P1 tasks must be complete

---

## CONFIGURATION
```
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai
MODULE_PATH    = {LARAVEL_REPO}/Modules/Hpc
```

---

## CONTEXT

The `StudentHpcEvaluation` CRUD works and data is saved to the database. However, the HPC report pages (credit pages, summary pages) completely ignore this evaluation data — teachers manually re-enter the same information. The evaluation data should auto-populate into report items when a report is generated or loaded.

---

## DESIGN

1. `HpcPdfDataService` already fetches CRUD data including evaluations
2. When loading the HPC form (`hpc_form()`), pre-populate evaluation-derived fields into `$savedValues` if not already set
3. When generating PDF (`generateReportPdf()`), merge evaluation data into the report data
4. Mapping: evaluation scores → credit page fields, evaluation competency levels → summary descriptors

---

## PRE-READ (Mandatory)

1. `{MODULE_PATH}/app/Services/HpcPdfDataService.php` — existing data fetch
2. `{MODULE_PATH}/app/Http/Controllers/HpcController.php` — `hpc_form()` and `generateReportPdf()`
3. `{MODULE_PATH}/app/Http/Controllers/StudentHpcEvaluationController.php` — evaluation data structure
4. `{MODULE_PATH}/app/Models/StudentHpcEvaluation.php` — fields available

---

## STEPS

1. Map evaluation fields to report form fields (document the mapping)
2. Create `HpcDataMappingService::mapEvaluationToReport($studentId, $templateId)` that returns pre-populated field values
3. In `hpc_form()`, after loading `$savedValues`, merge evaluation-derived values for empty fields
4. In PDF generation, include evaluation data via `HpcPdfDataService` (already partially done)
5. Add a "Refresh from Evaluations" button on the form that re-pulls latest evaluation data

---

## ACCEPTANCE CRITERIA

- Evaluation scores auto-appear in credit pages when loading the HPC form
- Teachers can still override auto-populated values
- PDF renders evaluation data correctly
- No data duplication — auto-feed fills empty fields, doesn't overwrite manual entries

---

## DO NOT

- Do NOT modify the evaluation CRUD controllers
- Do NOT change the database schema for evaluations
- Do NOT remove the manual entry capability
