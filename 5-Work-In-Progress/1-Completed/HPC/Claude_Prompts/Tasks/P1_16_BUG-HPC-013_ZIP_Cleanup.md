# PROMPT: Fix ZIP File Cleanup — HPC Module
**Task ID:** P1_16
**Issue IDs:** BUG-HPC-013
**Priority:** P1-High
**Estimated Effort:** 5 minutes
**Prerequisites:** None

---

## CONFIGURATION
```
MODULE_PATH    = /Users/bkwork/Herd/prime_ai/Modules/Hpc
```

---

## CONTEXT

`HpcController::downloadZip()` uses `deleteFileAfterSend(false)`, meaning ZIP files generated for bulk PDF downloads are never cleaned up. Over time, `storage/app/public/hpc-reports/zip/` fills with stale ZIP files causing storage bloat.

---

## PRE-READ (Mandatory)

1. `{MODULE_PATH}/app/Http/Controllers/HpcController.php` — Find the `downloadZip()` method

---

## STEPS

1. Find `downloadZip()` method in HpcController
2. Change `deleteFileAfterSend(false)` to `deleteFileAfterSend(true)`
3. Also check `generateReportPdf()` for individual PDF cleanup — if individual PDFs are kept after ZIP creation, consider cleaning those too

---

## ACCEPTANCE CRITERIA

- `deleteFileAfterSend(true)` is set on the ZIP download response
- ZIP files are automatically deleted after successful download

---

## DO NOT

- Do NOT change the PDF generation logic
- Do NOT modify the email attachment flow (Job may need the ZIP temporarily)
