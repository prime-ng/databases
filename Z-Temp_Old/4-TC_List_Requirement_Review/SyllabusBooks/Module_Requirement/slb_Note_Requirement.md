# slb_Note — Business Requirements

## What This Screen Does

The Notes Master is the third CRUD tab in the Syllabus Books module, managing the complete lifecycle of study notes. It provides a rich list view under `/syllabus-books?tab=notes` with search and filter capabilities, an approval workflow (PENDING_APPROVAL → APPROVED/REJECTED), inline status toggling, permission-gated actions, pagination, and trash management. The feature also includes sub-features for note files (multiple file attachments per note) and note ratings (user ratings with automatic average recalculation).

Notes are content items (lecture notes, revision notes, worksheets, etc.) uploaded by teachers, students, or admins. They can be associated with specific books and chapters, tagged with topics, classified by type (9 enum values), and scoped by visibility (class-only, subject-wide, school-wide). The approval workflow is driven by module configuration settings that determine whether student or teacher uploads require administrative approval.

---

## When This Screen Is Used

- **Creating Study Notes** when a teacher or student uploads notes for a specific class, subject, and academic session
- **Approving Pending Notes** when an administrator reviews and approves/rejects notes submitted by teachers or students
- **Managing Note Files** when attaching multiple file formats (PDF, DOCX, images) to a note
- **Rating Notes** when users rate notes (1-5 stars) with optional reviews
- **Updating Note Metadata** when note title, description, type, visibility, or file attachments need modification
- **Deactivating Outdated Notes** when a note should no longer be available without full deletion

## Default Data Load

The notes tab loads with:
- All active and inactive notes ordered by `created_at DESC`
- Loaded relationships: schoolClass, subject, book, chapter, uploader
- `withCount('ratings')` for rating count display
- Pagination (10 per page, `notes_page` param)
- 4 filters: search (title LIKE), type (exact), class (exact), status (exact)
- Create form loads: classes, subjects, academic sessions, active books, topics, and an AJAX endpoint (`getChaptersByBook`) for book→chapter cascade

---

## Key Fields at a Glance

**`title`** (VARCHAR 150, NOT NULL): Note title, max 150 chars.

**`description`** (VARCHAR 1000, NULLABLE): Optional description, max 1000 chars.

**`notes_type`** (ENUM): 9 values including LECTURE_NOTES, REVISION_NOTES, WORKSHEET, etc. Required.

**`uploader_role`** (ENUM: ADMIN/TEACHER/STUDENT): Identifies who uploaded the note.

**`status`** (ENUM: DRAFT/PENDING_APPROVAL/APPROVED/REJECTED/ARCHIVED): Workflow state. Default PENDING_APPROVAL or APPROVED based on config.

**`visibility`** (ENUM: CLASS_ONLY/SUBJECT_WIDE/SCHOOL_WIDE): Access scope.

**`tags`** (JSON, NULLABLE): Comma-separated tags stored as JSON array.

**`is_downloadable`** / **`is_active`** (BOOLEAN): Flags forced via `prepareForValidation`.

**`class_id`**, **`subject_id`**, **`academic_session_id`**: Required FK references for the target class/subject/session.

**`book_id`**, **`chapter_id`**, **`topic_id`**: Optional FK references for book/chapter/topic association.

---

## Business Rules and Conditions

**Approval Workflow**
The note's initial status depends on the module configuration:
- If the corresponding config setting (`student_notes_require_approval` or `teacher_notes_require_approval`) is true, new notes are created with `status = PENDING_APPROVAL`
- If approval is not required, notes are created with `status = APPROVED`
- When a note is approved, `approved_by_user_id` (current user) and `approved_at` (current timestamp) are set
- When a note is rejected, approval fields are cleared and `rejection_reason` should be provided

**Student Upload Control**
Student uploads can be completely disabled via the module config (`allow_student_notes_upload = false`). If disabled, the store controller returns HTTP 403 for student-role uploaders.

**Auto-Created UUID**
Each note gets an auto-generated UUID (BINARY 16) on creation.

**Rating Recalculation**
Each time a rating is created, updated, or deleted, the system recalculates the note's `avg_rating` as `AVG(rating)` → `round(2)` → stored on `SlbNote.avg_rating`.

**File Management**
Each note can have one main note file (via media library) plus multiple additional files via `slb_notes_files` table (PDF, DOCX, JPG, PNG, EPUB formats, max 20MB each).

**Unique Rating Per User**
The `slb_notes_ratings` table enforces `UNIQUE(notes_id, user_id)` — one rating per user per note. Use `updateOrCreate` to upsert.

---

## Workflow Steps

**Creating a Note**
The user navigates to the Notes tab and clicks "Add Note". The create form loads with all fields. The user selects class (which loads subjects via cascade), selects subject and session, optionally selects a book (which loads chapters via AJAX), chooses note type, uploader role, visibility, and optionally uploads a note file. On submit, the system checks config for approval requirement, creates the note with the appropriate status, attaches the file if provided, logs "Created" activity, and redirects with success.

**Approving/Rejecting a Note**
The user edits a note with PENDING_APPROVAL status and changes status to APPROVED (which sets approval metadata) or REJECTED (which clears approval metadata). The update logs "Updated" activity.

**Rating a Note**
A user submits a rating (1-5) with an optional review via the note's show page. The system uses `updateOrCreate` on `(notes_id, user_id)`, then recalculates the note's `avg_rating`. Ratings are listed on the note show page.

---

## Example Scenario

Teacher Ms. Sharma creates revision notes for Class 10 Mathematics Chapter "Quadratic Equations."

She navigates to the Notes tab and clicks "Add Note." She selects:
- Title: "Quadratic Equations — Revision Notes"
- Type: REVISION_NOTES
- Class: 10, Subject: Mathematics, Session: 2025-26
- Book: "Mathematics Textbook for Class X", Chapter: "Quadratic Equations"
- Uploader Role: TEACHER
- Visibility: SUBJECT_WIDE
- Note File: uploads a PDF (5MB)

Since the module config has `teacher_notes_require_approval = false`, the note is created as APPROVED. Students in Class 10 Mathematics can immediately view, download, and rate the notes. After a week, students rate it 4.5/5 on average.

---

## Related Screens

- **Note Ratings Tab** — Standalone admin list for managing all note ratings
- **Note Files** — Sub-feature for managing additional file attachments per note
- **Book/Chapter Selection** — Cascading dropdowns from book→chapter
- **Module Configuration (Settings)** — Controls approval workflow behavior
- **Note Trash** — Soft-deleted note management

---

## Requirements

- The system MUST expose a full RESTful resource controller for notes with 13 routes.
- The system MUST route all note endpoints under `/syllabus-books/notes`.
- The system MUST wrap all routes with `module:SYLLABUS_BOOKS` middleware.
- The system MUST authorize each action via `Gate::authorize()` with 7 permission gates plus a config-driven student upload gate.
- The system MUST validate input via `NoteRequest` with 18 validation rules.
- The system MUST enforce approval workflow based on module configuration settings.
- The system MUST support 9 notes_type enum values, 5 status enum values, and 3 visibility enum values.
- The system MUST support file upload (PDF/DOCX/PPTX/JPG/PNG, max 20MB) via media library.
- The system MUST support AJAX endpoint for fetching chapters by book ID.
- The system MUST support soft deletes and full trash lifecycle.
- The system MUST auto-calculate and store `avg_rating` on the note after rating changes.
- The system MUST enforce unique rating per user per note (UNIQUE constraint + updateOrCreate).
- The system MUST block student uploads when config `allow_student_notes_upload = false`.
- The system MUST log activity entries for all CRUD operations.

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|------|-----------|--------------|
| Super Admin | All `tenant.note.*` permissions | Full CRUD + Approval + Trash |
| Teacher | `tenant.note.create` (self-upload), `tenant.note.viewAny` | Create notes, view all |
| Academic Admin | `tenant.note.viewAny`, `tenant.note.update` | View and approve notes |
| Student | None (unless config allows student uploads) | No direct access |
| Guest (unauthenticated) | None | Redirected to `/login` |

---

## Validate Before Save (Multiple Conditions)

1. **Title Required** — Error: "The title field is required."
2. **Title Max Length** (150) — Error: "The title must not be greater than 150 characters."
3. **Class ID Required** — Error: "The class id field is required."
4. **Subject ID Required** — Error: "The subject id field is required."
5. **Notes Type Required** — Error: "The notes type field is required."
6. **Visibility Required** — Error: "The visibility field is required."
7. **Uploader Role Required** — Error: "The uploader role field is required."
8. **Note File Max 20MB** — Error: "The note file must not be greater than 20480 kilobytes."
9. **Student Upload Blocked by Config** — Returns 403 with appropriate message.

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|----------|--------------|-------------|
| title empty | "The title field is required." | 422 |
| class_id invalid FK | "The selected class id is invalid." | 422 |
| note_file > 20MB | "The note file must not be greater than 20480 kilobytes." | 422 |
| note_file invalid mime | "The note file must be a file of type: pdf, docx, pptx, jpg, jpeg, png." | 422 |
| student upload blocked | "Student notes upload is not allowed." | 403 |
| unauthorized | "This action is unauthorized." | 403 |
| module disabled | 404 Not Found | 404 |
| guest access | Redirect to /login | 302 |

---

## Success Scenarios

**SC-001: Teacher Creates an Approved Note**
1. Teacher creates a note with title, class, subject, type REVISION_NOTES, uploader_role TEACHER.
2. Config has `teacher_notes_require_approval = false`.
3. Note is created with status APPROVED, file attached, activity logged.
4. Note is immediately visible to students.

**SC-002: Student Creates a Note Pending Approval**
1. Student creates a note (config allows student uploads).
2. Config has `student_notes_require_approval = true`.
3. Note is created with status PENDING_APPROVAL.
4. Admin reviews and approves the note. Status changes to APPROVED, approval metadata set.

---

## Failure Scenarios

**FC-001: Student Upload Blocked by Config**
1. Student attempts to create a note.
2. Config `allow_student_notes_upload = false`.
3. System returns 403: "Student notes upload is not allowed."

**FC-002: Note File Exceeds Size Limit**
1. User uploads a file of 25MB (exceeds 20MB limit).
2. Validation fails with 422: "The note file must not be greater than 20480 kilobytes."

---

## Dependencies module and tables

| Type | Name | Details |
|------|------|---------|
| Primary Table | `slb_notes` | `id`, `uuid`, `title`, `description`, `notes_type` ENUM, `status` ENUM, `visibility` ENUM, `tags` JSON, flags, 6 FKs, timestamps, soft deletes |
| Related Table | `slb_notes_downloads` | `notes_id` FK, `user_id` FK, `downloaded_at`, `ip_address`, `user_agent` |
| Related Table | `slb_notes_files` | `notes_id` FK, `media_id` FK, `file_format`, `file_size_kb`, `ordinal` |
| Related Table | `slb_notes_ratings` | `notes_id` FK, `user_id` FK, `rating` TINYINT(1-5), `review` VARCHAR(500), UNIQUE(notes_id, user_id) |
| Module Dependency | SyllabusBooks Module | Core module |
| Module Dependency | User & Permission Module | Auth and gates |
| Module Dependency | Syllabus Module | Provides classes, subjects, sessions |
| Module Dependency | Media Library | File uploads |
| Module Dependency | Activity Log Module | Activity logging |
