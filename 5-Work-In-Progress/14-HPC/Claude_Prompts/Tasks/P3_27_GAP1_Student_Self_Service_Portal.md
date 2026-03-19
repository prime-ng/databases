# PROMPT: Build Student Self-Service Portal for HPC — HPC Module
**Task ID:** P3_27
**Issue IDs:** GAP-1, SC-11, SC-12
**Priority:** P3-Low
**Estimated Effort:** 5 days
**Prerequisites:** All P2 tasks must be complete (especially P2_20 role-based locking)

---

## CONFIGURATION
```
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai
MODULE_PATH    = {LARAVEL_REPO}/Modules/Hpc
ROUTES_FILE    = {LARAVEL_REPO}/routes/tenant.php
```

---

## CONTEXT

35 sections across all 4 HPC templates are intended for student self-input (self-assessment emojis, "About Me" pages, self-reflection, goals, time management, skills for life). Currently teachers fill these as proxy. A student-facing portal is needed where students log in, see only their own sections, fill them with appropriate UI (emoji selectors, drawing uploads, text areas), and track completion.

### Schema Changes
- New table: `hpc_student_form_submissions` — tracks per-student, per-section completion status
- New columns on `hpc_reports`: `student_sections_complete` (boolean), `student_submitted_at` (timestamp)

### Routes (add to tenant.php)
- `GET /hpc/student/dashboard` — Student HPC dashboard (list reports needing input)
- `GET /hpc/student/form/{report_id}` — Student form view (filtered to student sections only)
- `POST /hpc/student/form/{report_id}` — Student form save
- `POST /hpc/student/submit/{report_id}` — Mark student sections as complete

### Views
- `resources/views/student/dashboard.blade.php` — List of pending HPC reports
- `resources/views/student/form.blade.php` — Student-only sections form
- `resources/views/student/components/emoji-selector.blade.php` — Emoji input component

---

## PRE-READ (Mandatory)

1. `{MODULE_PATH}/app/Http/Controllers/HpcController.php` — `hpc_form()` and `formStore()` for reference
2. `{MODULE_PATH}/resources/views/hpc_form/` — existing form partials to understand section structure
3. Gap analysis data provider mapping (T1 pages 2,4,6,8,10,12,14; T2 pages 2-3,10,13,16,19,22,25; T3 pages 2-3,6,10,14,18,22,26,30,34,38; T4 pages 2-9,11,15,19,23,27,31,35,39)

---

## STEPS

1. Create migration for `hpc_student_form_submissions` table
2. Create `StudentHpcFormController` with dashboard, form, save, submit methods
3. Create `StudentHpcFormService` to filter template sections by `owner_role = 'student'`
4. Create student dashboard view showing pending reports with progress bars
5. Create student form view that renders only student sections with appropriate inputs
6. Add emoji selector component (reuse existing emoji assets from `public/emoji/`)
7. Add routes to tenant.php under a student-accessible middleware group
8. Add Gate permissions: `tenant.hpc-student.view`, `tenant.hpc-student.submit`
9. When student submits, update `hpc_reports.student_sections_complete = true`
10. Notify teacher when student completes their sections

---

## ACCEPTANCE CRITERIA

- Students see only their own reports on the dashboard
- Students can only edit sections tagged as `owner_role = 'student'`
- Teacher sections appear read-only in student view
- Emoji selectors work for self-assessment pages
- Student completion tracked per report
- Teacher is notified when student completes

---

## DO NOT

- Do NOT modify teacher form views
- Do NOT change existing PDF generation
- Do NOT build the parent or peer portals in this task
