# PROMPT: Refactor SendHpcReportEmail Job to Use Service — HPC Module
**Task ID:** P2_26
**Issue IDs:** Refactor
**Priority:** P2-Medium
**Estimated Effort:** 1 day
**Prerequisites:** P2_25 (God Controller Refactor)

---

## CONFIGURATION
```
MODULE_PATH    = /Users/bkwork/Herd/prime_ai/Modules/Hpc
```

---

## CONTEXT

The `SendHpcReportEmail` Job currently calls `buildPdf()` and `minifyHtml()` as public methods on HpcController (they were changed from private to public specifically for this). After the god controller refactor (P2_25), these methods will be in `HpcReportService`. The Job should be updated to use the service instead of the controller.

---

## PRE-READ (Mandatory)

1. `{MODULE_PATH}/app/Jobs/SendHpcReportEmail.php`
2. `{MODULE_PATH}/app/Services/HpcReportService.php` (after P2_25 refactor)

---

## STEPS

1. Read the Job to understand how it currently calls controller methods
2. Update the Job to inject `HpcReportService` instead of instantiating HpcController
3. Replace `$controller->buildPdf(...)` with `$reportService->buildPdf(...)`
4. Replace `$controller->minifyHtml(...)` with `$reportService->minifyHtml(...)`
5. Remove any `use HpcController` import from the Job
6. Test: dispatch a report email Job and verify PDF is generated correctly

---

## ACCEPTANCE CRITERIA

- Job uses HpcReportService, not HpcController
- Email with PDF attachment sends correctly
- No `use HpcController` in the Job file
- Job handles tenancy context correctly (existing behavior)

---

## DO NOT

- Do NOT change the email sending logic
- Do NOT change the Mailable
- Do NOT modify queue configuration
