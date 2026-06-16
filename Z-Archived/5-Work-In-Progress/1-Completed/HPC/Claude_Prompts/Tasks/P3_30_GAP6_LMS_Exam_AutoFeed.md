# PROMPT: Build LMS/Exam Auto-Feed Integration — HPC Module
**Task ID:** P3_30
**Issue IDs:** GAP-6
**Priority:** P3-Low
**Estimated Effort:** 3 days
**Prerequisites:** All P2 tasks must be complete

---

## CONFIGURATION
```
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai
MODULE_PATH    = {LARAVEL_REPO}/Modules/Hpc
```

---

## CONTEXT

Teachers currently re-enter exam scores, quiz results, and homework completion data into HPC reports manually. The LmsExam, LmsQuiz, and LmsHomework modules already store this data. An integration service should auto-fetch and populate relevant HPC fields.

---

## PRE-READ (Mandatory)

1. `{LARAVEL_REPO}/Modules/LmsExam/app/Models/` — exam result models
2. `{LARAVEL_REPO}/Modules/LmsQuiz/app/Models/` — quiz attempt models
3. `{LARAVEL_REPO}/Modules/LmsHomework/app/Models/` — homework submission models
4. `{MODULE_PATH}/app/Services/HpcPdfDataService.php` — where to add integration

---

## STEPS

1. Create `HpcLmsIntegrationService` with methods:
   - `getExamScores($studentId, $termId)` — fetch from LmsExam
   - `getQuizScores($studentId, $termId)` — fetch from LmsQuiz
   - `getHomeworkCompletion($studentId, $termId)` — fetch from LmsHomework
2. Map LMS data to HPC report fields (subject scores → subject assessment pages)
3. Integrate into form loading: auto-populate academic performance fields
4. Integrate into PDF generation: include LMS data in report
5. Add "Refresh from LMS" button on form

---

## ACCEPTANCE CRITERIA

- Exam, quiz, and homework data auto-populates into HPC report
- Data mapping is documented (which LMS field → which HPC field)
- Teachers can override auto-populated values
- Works even if LMS modules have no data (graceful empty defaults)

---

## DO NOT

- Do NOT modify LMS module code
- Do NOT create API endpoints in LMS modules — query their models directly
- Do NOT make HPC depend on LMS modules being active
