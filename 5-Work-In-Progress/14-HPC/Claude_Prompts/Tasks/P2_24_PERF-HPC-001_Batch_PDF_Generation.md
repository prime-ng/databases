# PROMPT: Optimize Batch PDF Generation — HPC Module
**Task ID:** P2_24
**Issue IDs:** PERF-HPC-001
**Priority:** P2-Medium
**Estimated Effort:** 1 day
**Prerequisites:** All P0 and P1 tasks must be complete

---

## CONFIGURATION
```
MODULE_PATH    = /Users/bkwork/Herd/prime_ai/Modules/Hpc
```

---

## CONTEXT

`generateReportPdf()` loops over student IDs loading each student individually. Attendance and sibling queries repeat per student without batching. For a class of 40 students, this results in 120+ individual queries. Pre-loading all data before the loop would reduce this to ~5 queries.

---

## PRE-READ (Mandatory)

1. `{MODULE_PATH}/app/Http/Controllers/HpcController.php` — `generateReportPdf()` method
2. `{MODULE_PATH}/app/Services/HpcPdfDataService.php` — data fetching per student

---

## STEPS

1. Read `generateReportPdf()` and identify all per-student queries inside the loop
2. Before the loop, eager-load all students with relationships: `Student::with(['guardians', 'details', 'academicSessions'])->whereIn('id', $studentIds)->get()`
3. Pre-load attendance data for all students in one query
4. Pre-load sibling data for all students in one query
5. Inside the loop, use the pre-loaded collections instead of individual queries
6. Consider using `HpcPdfDataService::getDataForStudents($studentIds)` (batch version)

---

## ACCEPTANCE CRITERIA

- Bulk PDF generation for 40 students uses fewer than 20 total queries (down from 120+)
- PDF output is identical to before (no visual changes)
- Memory usage stays reasonable (no loading 1000 students at once)
- Individual student PDF still works

---

## DO NOT

- Do NOT change the PDF template rendering logic
- Do NOT modify DomPDF configuration
- Do NOT change the ZIP creation logic
