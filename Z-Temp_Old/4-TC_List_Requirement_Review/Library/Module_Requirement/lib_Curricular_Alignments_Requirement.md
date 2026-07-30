# Curricular Alignments — Business Requirements

## What This Screen Does

The Curricular Alignments screen maps library books to specific curriculum subjects, classes, and academic sessions. It allows librarians and academic coordinators to define which books are aligned to which part of the taught curriculum, including alignment scoring, faculty recommendations, and priority levels. This screen lives as a tab within the Library Operations hub alongside other operational sub-modules.

---

## When This Screen Is Used

- When a new book is added to the library and needs to be linked to a specific subject, class, and academic session
- When curriculum standards change and existing book mappings need to be updated or deprecated
- When faculty want to recommend books for specific curriculum units or terms
- When librarians need to see which books are aligned to which subjects for collection gap analysis

## Default Data Load

This screen displays as a tab within the Library Operations hub (tab id `curricular-alignments`). When the user navigates to Library Operations, `LibraryController@transactionIndex()` loads all tab data simultaneously. Curricular alignments are loaded with eager-loaded `book`, `class`, `subject`, and `academicYear` relationships, ordered by `alignment_score` descending, paginated at 15 per page. Search filters on book title, class name, and subject name are available when the tab is active.

---

---

## Key Fields at a Glance

**Core Identity**
Every alignment links a single book to one class, one subject, and one academic session. This quadruple constraint (academic year + class + subject + book) must be unique — a book can appear only once per class-subject-year combination. The academic year references the `academic_years` table, class references `sch_classes`, subject references `sch_subjects`, and book references `lib_books_master`.

**Alignment Scoring**
An alignment score from 0 to 100 measures how well the book matches the curriculum. Faculty can provide a 1-to-5 rating, and a boolean flag indicates whether the book is faculty-recommended. Usage tracking counters — `student_usage_count`, `exam_reference_count`, and `assignment_citations` — track how often the book has been referenced by students, in exams, and in assignments.

**Curriculum Context**
The curriculum unit field captures the specific unit or chapter this book supports (e.g., "Unit 3: Algebra"). The term recommendation restricts usage to a specific academic term (Term1, Term2, Term3, or All). The priority level classifies the book as Essential, Recommended, Supplementary, or Optional (defaulting to Supplementary). Free-text notes allow librarians to record additional context.

---

## Business Rules and Conditions

**Unique Constraint**
One book cannot be aligned to the same academic year + class + subject combination more than once. The unique key `uq_lib_CurrAlign_yesr_class_subject_book` enforces this at the database level.

**Deletion Protection**
If a curricular alignment is referenced by other records (e.g., reports, analytics), the database foreign key constraint will prevent hard deletion. The `forceDelete()` method catches `QueryException` with code `23000` and returns a user-friendly message.

**Soft Deletes**
Alignments use soft deletes — records are moved to trash rather than permanently removed. The trashed view lists soft-deleted records with restore and force-delete options.

---

## Workflow Steps

**Adding a New Alignment**
The librarian navigates to the Operations hub and selects the Curricular Alignments tab. They click Add Alignment, which opens a standalone create form. They select a book from the active books dropdown, choose the academic session, class, and subject. They optionally enter an alignment score, faculty rating, term recommendation, priority level, curriculum unit, and notes. On save, the system validates uniqueness and creates the record, redirecting back to the operations tab.

**Editing and Deleting**
The librarian clicks Edit on any alignment row, which opens the edit form pre-populated with existing values. Changes are saved via a PUT request. Deletion moves the record to trash; restore and force-delete are available from the dedicated trash page.

---

## Example Scenario

A Grade 10 Science teacher recommends a new Physics textbook for the "Light and Optics" unit. The librarian opens Books Master, adds the book, then navigates to Curricular Alignments. They select Academic Year 2025–26, Class 10, Subject Science, and the new book. They set alignment score to 92, mark it as faculty-recommended, set priority to Essential, and select term Term1. The system stores the alignment. Later, when generating the collection gap analysis report, this alignment contributes to the Science curriculum coverage metric.

---

## Related Screens

- **Books Master** — The book catalog from which books are selected for alignment
- **Members** — Member records used in other operations tabs
- **Transactions** — Check-out/check-in history visible in the same operations hub

---

## Requirements

**Controller:** `Modules\Library\Http\Controllers\LibCurricularAlignmentController`
**Model:** `Modules\Library\Models\LibCurricularAlignment` (table: `lib_curricular_alignment`)
**Requests:** Inline `$request->validate()` in store/update — no dedicated FormRequest
**Policy:** No dedicated policy; uses string-based `Gate::authorize()` with `tenant.lib-curricular-alignments.*`
**Route:** Resource route `Route::resource('lib-curricular-alignments', LibCurricularAlignmentController::class)` + trashed/restore/forceDelete under library prefix
**Tab:** `curricular-alignments` under `library.transactionsIndex`

Key controller methods:
- `index()` — Redirects to `library.transactionsIndex?tab=curricular-alignments`
- `create()` — Loads active books, classes, subjects, academic years dropdowns; returns create view
- `store(Request)` — Validates and creates alignment; logs activity; redirects to operations tab
- `edit($id)` — Loads single alignment + dropdowns; returns edit view
- `update(Request, $id)` — Validates and updates alignment; logs activity
- `destroy($id)` — Soft-deletes alignment
- `trashed()` — Lists soft-deleted alignments with book/class/subject eager-loaded
- `restore($id)` — Restores a soft-deleted alignment
- `forceDelete($id)` — Force-deletes with FK constraint check and user-friendly error
- **No `toggleStatus`** — This controller does NOT have a toggleStatus method

---

## Who Can Access This Screen

| Role | Access Level |
|---|---|
| Super Admin | Full access — all CRUD + trash operations |
| Librarian Admin | Full access — create, edit, delete, restore, force-delete |
| Librarian Operator | Create, edit, view |
| Librarian (view only) | View only |

All access is gated by `Gate::authorize('tenant.lib-curricular-alignments.{action}')`.

---

## How This Screen Works — Logic Flow (Non-Technical)

The user navigates to the Library Operations hub and clicks the Curricular Alignments tab. The system loads a paginated table of all alignments showing the book title, class, subject, academic year, alignment score, priority level, and action buttons. A search bar allows filtering by book title, class name, or subject name. To add a new alignment, the user clicks Add Alignment, which opens a standalone form where they select the book, class, subject, and academic year, then optionally fill in scoring, term, priority, and notes. On save, the system checks that no duplicate alignment exists for the same book+class+subject+year combination, then persists the record. Editing follows a similar flow. Deleting moves the record to trash, from which it can be restored or permanently removed.

---

## Validate Before Save

**Create (`store()` method):**
1. **`book_id`:** required, must exist in `lib_books_master.id`
2. **`class_id`:** required, must exist in `sch_classes.id`
3. **`subject_id`:** required, must exist in `sch_subjects.id`
4. **`academic_year_id`:** required, must exist in `sch_org_academic_sessions_jnt.academic_session_id`
5. **`alignment_score`:** nullable, numeric, min:0, max:100
6. **`recommended_by_faculty`:** nullable, boolean
7. **`faculty_rating`:** nullable, numeric, min:0, max:5
8. **`curriculum_unit`:** nullable, string, max:200
9. **`term_recommended`:** nullable, in: Term1, Term2, Term3, All
10. **`priority_level`:** nullable, in: Essential, Recommended, Supplementary, Optional
11. **`notes`:** nullable, string, max:2000

**Unique Constraint (DB level):** The unique key `uq_lib_CurrAlign_yesr_class_subject_book` (`academic_year_id`, `class_id`, `subject_id`, `book_id`) prevents duplicate alignments.

---

## Error Handling and Validation Messages

| Condition | Message |
|---|---|
| Book not found | "The selected book is invalid." (from `exists` validation) |
| Class/Subject not found | "The selected class/subject is invalid." |
| Duplicate alignment | Duplicate entry error from MySQL unique key constraint |
| FK constraint on force delete | "Cannot delete: referenced by other records." |
| Missing required field | Validation error summary with field-specific messages |

---

## Success Scenarios

1. A librarian creates a new alignment linking an Algebra textbook to Grade 9 Mathematics for Academic Year 2025–26 with alignment score 85 and priority "Essential". The system saves the record and returns the user to the operations tab with a success message.
2. A librarian edits an existing alignment to change its priority from "Supplementary" to "Recommended" after receiving faculty feedback. The system updates the record and logs the change.
3. A librarian deletes an outdated alignment, then restores it from trash when the subject is reinstated in the next academic year.

---

## Failure Scenarios

1. A librarian attempts to create a duplicate alignment for the same book, class, subject, and academic year. The database unique key constraint blocks the save, and the system returns a database error.
2. A librarian attempts to force-delete an alignment that is referenced by other records (e.g., in a report snapshot). The `QueryException` handler catches the FK error and displays a user-friendly message.
3. A librarian enters an alignment score of 150 (exceeding the 100 max). The validation rejects the input and shows the numeric range error.

---

## Dependencies module and tables

| Module | Tables |
|---|---|
| Library Core | `lib_curricular_alignment` (primary, with soft-deletes via `deleted_at`) |
| Library Books | `lib_books_master` (FK `book_id`) |
| Academic Setup | `sch_classes` (FK `class_id`), `sch_subjects` (FK `subject_id`), `academic_years` (via `sch_org_academic_sessions_jnt` FK `academic_year_id`) |
