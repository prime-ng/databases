# SyllabusBooks (SLK) — Requirement Conditions Catalog
**Date:** 2026-06-30 | **Source:** SLK_FRD_Complete_2026-06-30.md Section 3.2
**Module:** SyllabusBooks | **Code:** SLK | **Prefix:** `slb_*` / `bok_*`

> This file is the canonical location for SLK requirement conditions.
> Full context for each condition is in the Complete Analysis Pack:
> `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/0-FRD_Documents/SLK_FRD_Complete_2026-06-30.md`

---

| Condition ID | Entity / Field | Condition (Business) | Type | Trigger | On-Violation Behaviour |
|---|---|---|---|---|---|
| BR-SLK-001 | Author — Name | Must be unique within the school's catalog | Validation | Create or Edit author | Return "Author name already exists" error; do not save |
| BR-SLK-002 | Book — ISBN | Must be unique within the school's catalog when provided | Validation | Create or Edit book | Return "ISBN already in use" error; do not save |
| BR-SLK-003 | Book — Permanent Deletion | Must have zero active lesson-plan references | Workflow | Force-delete book | Return "Book is in use by N lesson plans; cannot be permanently deleted" |
| BR-SLK-004 | Book — Permanent Deletion | Must have zero active question-bank references | Workflow | Force-delete book | Return "Book is referenced by N questions; cannot be permanently deleted" |
| BR-SLK-005 | Author — Permanent Deletion | Must have zero active book-author links | Workflow | Force-delete author | Block with error OR cascade after confirmation (school policy) |
| BR-SLK-006 | Book-Class Assignment — Primary Flag | At most one primary textbook per class-subject-session | Concurrency | Create or Edit assignment with is_primary = true | Demote existing primary assignment to false before inserting new primary |
| BR-SLK-007 | Book-Author Junction — Author Role | Must be one of: Primary Author, Co-Author, Editor, Contributor | Validation | Create or Edit book (author section) | Return "Invalid author role" validation error |
| BR-SLK-008 | Book-Author Junction — (book, author, role) | No duplicate (book, author, role) triplet allowed | Validation | Create or Edit book (author section) | Return "This author is already assigned with this role" |
| BR-SLK-009 | Assignment — Academic Session | Session must belong to the school's own session list | Validation | Create or Edit class assignment | Return "Invalid session" error; use OrganizationAcademicSession model not global AcademicSession |
| BR-SLK-010a | Book-Topic Mapping — Page Range | Start page must be less than or equal to end page | Validation | Create or Edit mapping | Return "End page must be greater than or equal to start page" |
| BR-SLK-010b | Book-Topic Mapping — Page Range | End page must not exceed book's total pages (when total_pages is set) | Validation | Create or Edit mapping | Return "End page exceeds book's total page count" |
| BR-SLK-011 | Note — Class and Subject | Both class and subject are required on every note | Validation | Create note | Return "Class and subject are required" validation error |
| BR-SLK-012 | Note — Student Upload Gate | Students cannot upload notes when Allow Student Uploads setting is disabled | Permission | Create note (student role) | Return 403 or hide upload functionality entirely |
| BR-SLK-013 | Note — Student Approval | Student-uploaded note starts in Pending Approval when Require Approval setting is enabled | Workflow | Create note (student role, require-approval ON) | Auto-set status = pending_approval; trigger teacher notification |
| BR-SLK-014 | Note — Teacher Auto-Approval | Teacher-uploaded note is Approved immediately when Teacher Approval Required setting is disabled | Workflow | Create note (teacher role, teacher-approval OFF) | Auto-set status = approved; note visible immediately |
| BR-SLK-015 | Note Rating — Uniqueness | One rating per student per note (second rating updates the first) | Concurrency | Submit rating | Upsert: update existing rating row if present; do not insert duplicate |
| BR-SLK-016 | Note Rating — Privacy | Individual rater identity must not be shown in any public view | Permission | Note list, Note detail views | Display average score and total count only; never expose rater name |
| BR-SLK-017 | Download Log — Immutability | Download records are created automatically; no user may create, edit, or delete them | Workflow | File download event | System creates entry automatically; application provides no manual CRUD for download logs |
| BR-SLK-018 | Book File Upload — Format and Size | Uploaded book files must match Settings format whitelist and not exceed Settings size limit | Validation | Upload book file | Return "File format not allowed" or "File size exceeds limit" |
| BR-SLK-019 | Note File Upload — Format and Size | Uploaded note files must match Settings format whitelist and not exceed Settings size limit | Validation | Upload note file | Return "File format not allowed" or "File size exceeds limit" |
| BR-SLK-020 | All CRUD Operations — Activity Log | Every create, edit, soft-delete, restore, and permanent-delete must generate an activity log entry | Workflow | Every mutation on any SLK entity | Write activityLog() helper entry; mutation is not rolled back if logging fails |
| BR-SLK-021 | All Data — Tenant Isolation | All books, authors, notes, configs, and logs belong to one school and are inaccessible from other schools | Permission | Every request | Enforced by database-per-tenant architecture; no explicit row filter needed |
