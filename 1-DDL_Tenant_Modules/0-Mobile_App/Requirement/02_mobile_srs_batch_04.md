# Mobile SRS — Batch 04 (Homework)

> Index: `02_mobile_srs_index.md`. Features: F-040, F-041, F-042, F-043.

---

## F-040: Homework List & Detail (Student)

### 1. Overview
Browse homework assigned to me (current week + 30-day history). Filter by subject / status. Detail view shows description, due-date, attachments, submission state.

### 2. User Stories
- **US-040.1** *As a student, I want a clear "due today / overdue / upcoming" split, so I prioritise.*
- **US-040.2** *As a student, I tap any homework and see attachments.*
- **US-040.3** Edge — IDOR pre-fix: students must not be able to read another student's homework via `/homework/{id}` (SEC-HWK-003 — BG-18).

### 3. Functional Requirements
- **FR-040.1** Endpoint scopes to `auth student → class-section → assigned homework`.
- **FR-040.2** Status per homework: `NOT_SUBMITTED | SUBMITTED | GRADED`.
- **FR-040.3** List paginated `per_page=20`.
- **FR-040.4** Soft deletes filtered (D7).
- **FR-040.5** Attachments via signed URLs (BG-33).
- **FR-040.6** Sort: due-date ascending; overdue float to top with red badge.

### 4. Screen Specifications

#### S-040.1 — Homework list
```
┌──────────────────────────────────┐
│ Homework                  [Filter]│
│ ── Due today ─────────────────── │
│ Math · Algebra worksheet  ❗1d   │
│ Hindi · Essay              today │
│ ── Upcoming ─────────────────── │
│ Sci · Lab report           +3d   │
│ ...                              │
└──────────────────────────────────┘
```

#### S-040.2 — Detail
Title, subject, teacher, due-date countdown, description, attachments list (CC-05 viewer), submission CTA (→ F-041).

### 5. API Contracts

#### `GET /api/mobile/v1/homework?status=&subject_id=&page=`
- **Status:** MODIFY (BG-18 fix IDOR).
- **Response 200:** `{ data:[...], meta:{...} }`.

#### `GET /api/mobile/v1/homework/{id}`
- **Status:** MODIFY. Module: LmsHomework.
- **4xx:** `403 NOT_ASSIGNED_TO_YOU` (post-fix).

### 6. Data Model
```sql
cache_homework_list (page_key, payload_json, fetched_at)
cache_homework (id PRIMARY KEY, payload_json, fetched_at)
```

### 7. Offline Behavior
Read-only cached. Attachments downloaded on tap (cache_attachments).

### 8. Push Notifications
Consumes `HOMEWORK_PUBLISHED`, `HOMEWORK_DUE_SOON`, `HOMEWORK_GRADED`.

### 9. Permissions & Security
- **CRITICAL** — SEC-HWK-003 IDOR (BG-18) MUST be fixed.
- BUG-NEW-004 missing `lms_homework_assignment` migration (BG-19).
- Audit: read-only, not logged.
- `security-rules.md` §"IDOR".

### 10. Non-Functional Requirements
- Cached < 300 ms; network < 1.5 s.
- Localization: `f040.tab.{today,upcoming,overdue}`.

### 11. Acceptance Criteria
- **AC-040.1** Tampered `/homework/{other_id}` returns 403.
- **AC-040.2** Soft-deleted homework not in list.
- **AC-040.3** Pagination correctness verified at page 5.

### 12. Dependencies
- F-002, F-005 (parent variant). BG-18, BG-19, BG-33.

### 13. Out of Scope
- Subject-wise progress charts — v1.1.
- Homework chat with teacher — v1.2.

---

## F-041: Submit Homework — File / Photo / Text (Student)

### 1. Overview
Student submits a homework either as text, uploaded file, or one-tap photo capture. Multiple attachments. Queued upload when offline.

### 2. User Stories
- **US-041.1** *As a student, I take photos of my notebook pages and submit, so I don't email teachers.*
- **US-041.2** *As a student, I see upload progress and can retry on failure.*
- **US-041.3** Edge — submission after due-date: server may accept with `late=true` flag (per teacher's homework config).

### 3. Functional Requirements
- **FR-041.1** Multi-part upload `POST /homework/{id}/submission` with files + text.
- **FR-041.2** Image client-compressed to ≤ 1 MB.
- **FR-041.3** Resumable upload via `tus`-like chunking — Q-OQ; v1 single-shot per file with retry.
- **FR-041.4** Idempotency key per submission attempt; resubmit creates a new version (`std_homework_submissions.version`).
- **FR-041.5** File types whitelist: PDF, JPG, PNG, DOC, DOCX (per `lms_homework.allowed_formats`).
- **FR-041.6** Max total size per submission: 25 MB (configurable).
- **FR-041.7** Submission immutable once `status='GRADED'`.

### 4. Screen Specifications

#### S-041.1 — Submission composer
```
┌──────────────────────────────────┐
│ ← Submit · Algebra worksheet     │
│                                  │
│ [Add photo] [Add file]           │
│ ─ Attachments ──                  │
│ • IMG_001.jpg  920 KB    [×]    │
│ • notes.pdf    1.2 MB    [×]    │
│                                  │
│ Notes (optional)                 │
│ ┌────────────────────────────┐  │
│ │ ...                          │  │
│ └────────────────────────────┘  │
│ ☑ I confirm this is my work       │
│         [ Submit ➤ ]              │
└──────────────────────────────────┘
```

#### S-041.2 — Progress
Per-file progress bars; on success → "Submitted ✓" + receipt.

States: loading, error per-file (retry), offline (queue + banner).

### 5. API Contracts

#### `POST /api/mobile/v1/homework/{id}/submission`
- **Status:** NEW (BG-19 + BG-20). Module: LmsHomework.
- **Request:** multipart — `text`, `attachments[]`.
- **Response 201:** `{ data:{ submission_id, version, late, file_urls:[...] } }`.
- **4xx:** `403 NOT_ASSIGNED`, `409 ALREADY_GRADED`, `413 PAYLOAD_TOO_LARGE`, `415 UNSUPPORTED_MEDIA_TYPE`.
- **Backend gap:** BG-19 missing migration; BG-20 endpoint; BG-21 LMS storage paths (D28).

### 6. Data Model
```sql
pending_writes feature_id='F-041'  (multipart serialized JSON + paths)
cache_homework (id, payload) updated post-submit
```

### 7. Offline Behavior
- Capture text + select files → queue → upload on connectivity, with progress UI on next foreground.
- Drop-on-conflict (ALREADY_GRADED): notify user that submission window closed.

### 8. Push Notifications
- Server emits `HOMEWORK_SUBMITTED_TO_TEACHER` (informational, P1) — channel `academics`, recipient = homework owner teacher.
- Student receives `HOMEWORK_GRADED` later.

### 9. Permissions & Security
- OS: Camera, Photos.
- Server: SEC-HWK-003 (BG-18) hard pre-req on the read path used to look up the homework.
- Anti-tamper: server validates `id` belongs to student's class assignment.
- Audit: `HOMEWORK_SUBMITTED` row.

### 10. Non-Functional Requirements
- Submission perceived < 200 ms (queue write).
- 5 MB upload over 4G < 8 s p50.
- Localization: `f041.cta.*`, `f041.error.*`.
- Analytics: `homework_submit_attempt`, `_success`, `_failed{reason}`.

### 11. Acceptance Criteria
- **AC-041.1** 5-photo submission completes successfully and appears as version 1 in detail.
- **AC-041.2** Resubmit before grading creates version 2.
- **AC-041.3** File outside whitelist → 415 with clear UI message.
- **AC-041.4** Submission after `due_date` with school policy `allow_late=true` saves with `late=true`.

### 12. Dependencies
- F-040. BG-18, BG-19, BG-20, BG-21.

### 13. Out of Scope
- Plagiarism check / Turnitin — v1.2+.
- Voice-note submissions — v1.2.

---

## F-042: Grade Homework (Teacher, P1)

### 1. Overview
Teacher reviews submissions for a homework; grades each (marks + remark + optional rubric).

### 2. User Stories
- **US-042.1** *As a teacher, I want to swipe through submissions and grade quickly.*
- **US-042.2** *As a teacher, I can return work to the student for revision (sets status `RETURNED`).*

### 3. Functional Requirements
- **FR-042.1** List submissions by status (`SUBMITTED` first).
- **FR-042.2** Grade endpoint: `(submission_id, marks, max_marks, remark, status)` — `GRADED` or `RETURNED`.
- **FR-042.3** Grading concurrent-safe: optimistic via `If-Match: <version_etag>`.
- **FR-042.4** Bulk-grade not in v1.
- **FR-042.5** Soft delete protection (D7).

### 4. Screen Specifications
Submissions list → swipe view of attachments → grade form.

### 5. API Contracts

#### `POST /api/mobile/v1/homework/{id}/submissions/{sid}/grade`
- **Header:** `If-Match: <version_etag>`.
- **Request:** `{ marks, max_marks, remark, status:"GRADED|RETURNED" }`.
- **Response 200:** `{ data:{ submission_id, status, marks, etag } }`.
- **4xx:** `412 PRECONDITION_FAILED`, `404 NOT_FOUND`.

### 6. Data Model
`cache_submissions_for_hw` per homework.

### 7. Offline Behavior
Queued writes (rare, but supported); idempotency key per (sid, attempt-uuid).

### 8. Push Notifications
Emits `HOMEWORK_GRADED` to student + parent.

### 9. Permissions & Security
- Authorize: teacher owns homework (`lms_homework.created_by` or assigned).
- BG-18 IDOR fix on read path.
- Audit: `HOMEWORK_GRADED`.

### 10. Non-Functional Requirements
- Performance: list 50 submissions < 1.5 s.
- Localization: `f042.cta.{grade,return}`.
- Analytics: `homework_grade_attempt`, `_success`.

### 11. Acceptance Criteria
- **AC-042.1** Concurrent grading by two teachers → second receives 412 with current canonical record.
- **AC-042.2** Status `RETURNED` re-opens submission for the student to F-041.

### 12. Dependencies
- F-040, F-041. BG-18.

### 13. Out of Scope
- Rubric authoring — web-only.
- Grading analytics (class average, trend) — v1.1.

---

## F-043: Homework Monitoring (Parent, P1)

### 1. Overview
Parent views their child's homework list and submission status. Read-only — parent does not submit on child's behalf.

### 2. User Stories
- **US-043.1** *As a parent, I want a "what's pending for my child" list, so I can nudge.*
- **US-043.2** *As a parent of two children, switching child via F-005 must update this list.*

### 3. Functional Requirements
- **FR-043.1** Endpoint: `GET /parent/homework/{student_id}` (header `X-Active-Student-Id` must match path).
- **FR-043.2** Read-only: parent cannot upload submissions.
- **FR-043.3** Status filter: pending / submitted / graded.

### 4. Screen Specifications
Mirror of F-040 list with parent-voice strings ("Asha hasn't submitted Math worksheet").

### 5. API Contracts

#### `GET /api/mobile/v1/parent/homework/{student_id}`
- **Status:** NEW (BG-28 ParentPortal). Mirrors F-040 payload + `child` block.

### 6. Data Model
`cache_homework_for_child` keyed by student_uuid.

### 7. Offline Behavior
Read-only cached.

### 8. Push Notifications
Consumes `HOMEWORK_PUBLISHED`, `_DUE_SOON`, `_GRADED`.

### 9. Permissions & Security
- BR-PPT-012 enforced. SR-AUTH-001 fix prereq.

### 10. Non-Functional Requirements
- Cached < 300 ms.
- Localization: `f043.title`.

### 11. Acceptance Criteria
- **AC-043.1** Parent cannot submit (no S-041.1 entry from this surface).
- **AC-043.2** Tampered student_id → 403.

### 12. Dependencies
- F-005, F-040. BG-28.

### 13. Out of Scope
- Parent commenting on assignments — v1.2.

---

> End Batch 04. Continue to `02_mobile_srs_batch_05.md` (Assessments).
