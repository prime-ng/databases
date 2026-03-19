# PROMPT: Build Parent Data Collection Mechanism — HPC Module
**Task ID:** P3_28
**Issue IDs:** GAP-2, SC-15, SC-16
**Priority:** P3-Low
**Estimated Effort:** 4 days
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

9 sections across HPC templates require parent input (home resources, parent questions, support needs, parent feedback). Parents typically don't have login accounts. The solution is a token-based signed URL system: teacher generates a link per student, sends it via SMS/email to parents, parents fill the form without authentication, responses are validated and merged into the HPC report.

### Schema Changes
- New table: `hpc_parent_form_tokens` — token, student_id, report_id, expires_at, completed_at, ip_address
- New column on `hpc_reports`: `parent_sections_complete` (boolean)

### Routes
- `GET /hpc/parent/form/{token}` — Public (no auth) parent form via signed URL
- `POST /hpc/parent/form/{token}` — Parent form save
- `POST /hpc/teacher/generate-parent-link/{report_id}` — Teacher generates parent link
- `GET /hpc/teacher/parent-status/{report_id}` — Teacher checks parent completion

### Views
- `resources/views/parent/form.blade.php` — Standalone mobile-friendly parent form
- `resources/views/parent/thank-you.blade.php` — Submission confirmation
- `resources/views/parent/expired.blade.php` — Token expired page

---

## PRE-READ (Mandatory)

1. `{MODULE_PATH}/app/Http/Controllers/HpcController.php` — form data structure
2. Gap analysis parent sections: T1 pages 4,6,8,10,12,14 (embedded); T2 pages 6-7; T3 page 4
3. Existing guardian model: `{LARAVEL_REPO}/Modules/StudentProfile/app/Models/` for guardian email/phone

---

## STEPS

1. Create migration for `hpc_parent_form_tokens` table
2. Create `ParentHpcFormController` (no auth required for form view/save)
3. Create token generation service: generates unique token, sets 7-day expiry
4. Teacher UI: "Send to Parent" button on report detail → generates link, copies to clipboard or sends via email
5. Parent form: standalone page with school branding, mobile-responsive, emoji selectors for rating questions
6. On submission: validate token, save responses, mark `parent_sections_complete = true`
7. Rate limit parent form (max 3 submissions per token to prevent abuse)
8. Routes: parent form routes OUTSIDE auth middleware (signed URL auth only)

---

## ACCEPTANCE CRITERIA

- Teacher can generate a unique link per student's parent
- Parent opens link without login, sees only parent sections
- Parent form is mobile-friendly (most parents use phones)
- Token expires after 7 days
- Completed responses appear in the HPC report
- Teacher can see parent completion status

---

## DO NOT

- Do NOT require parent login/registration
- Do NOT modify existing authentication system
- Do NOT build SMS sending (just generate the URL; SMS integration is separate)
