# PROMPT: Implement HPC Report Approval Workflow — HPC Module
**Task ID:** P2_21
**Issue IDs:** GAP-5
**Priority:** P2-Medium
**Estimated Effort:** 3 days
**Prerequisites:** All P0 and P1 tasks must be complete

---

## CONFIGURATION
```
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai
MODULE_PATH    = {LARAVEL_REPO}/Modules/Hpc
```

---

## CONTEXT

The `hpc_reports` table has a `status` ENUM (Draft/Final/Published/Archived) but there is no state machine enforcement. Anyone can set status to Published directly. There is no principal review step, no notification chain, and no completion tracking. The workflow should be: Draft → Submitted → Reviewed → Final → Published, with role-based transitions.

---

## DESIGN

1. **State Machine:** Expand status ENUM to `draft → submitted → under_review → final → published → archived`
2. **Transition Rules:**
   - Teacher: draft → submitted (when all required sections complete)
   - Principal: submitted → under_review → final (with comments)
   - Admin: final → published (triggers PDF generation + notification)
   - Any authorized: published → archived
3. **Schema Changes:** Add `submitted_at`, `reviewed_by`, `reviewed_at`, `review_comments`, `published_at` columns to `hpc_reports`
4. **Notification:** Trigger notification when report moves to `submitted` (notify principal) and `published` (notify parents)
5. **Completeness Check:** Before `submitted`, validate that all required teacher sections are filled

---

## PRE-READ (Mandatory)

1. `{MODULE_PATH}/app/Models/HpcReport.php` — current status field and model
2. `{MODULE_PATH}/app/Http/Controllers/HpcController.php` — any existing status-related logic
3. Existing migration for `hpc_reports` table

---

## STEPS

1. Create migration adding workflow columns to `hpc_reports`
2. Create `HpcWorkflowService` with transition methods: `submit()`, `startReview()`, `approve()`, `publish()`, `archive()`
3. Each transition method validates: current status is correct, user has required role, required data is present
4. Add controller methods: `submitReport()`, `reviewReport()`, `approveReport()`, `publishReport()`
5. Add routes for workflow actions
6. Create a simple status badge/timeline component for the report detail view
7. Add Gate permissions: `tenant.hpc.submit`, `tenant.hpc.review`, `tenant.hpc.publish`

---

## ACCEPTANCE CRITERIA

- Reports follow Draft → Submitted → Under Review → Final → Published flow
- Invalid transitions throw 422 with clear error message
- Only teachers can submit, only principals can review/approve, only admins can publish
- Workflow audit trail: who changed status, when, with comments
- Published reports trigger notification (stub — actual notification integration is separate)

---

## DO NOT

- Do NOT implement the full notification system (just trigger events)
- Do NOT modify PDF generation logic
- Do NOT change the existing form save/load flow
