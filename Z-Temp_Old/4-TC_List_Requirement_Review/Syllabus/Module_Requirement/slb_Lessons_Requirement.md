# Lessons Master — Business Requirements

## What This Screen Does

The Lessons Master screen is the structural foundation of the school's curriculum. It defines the major chapters, units, or modules taught within a specific subject for a specific class. 

This screen connects the school's internal teaching structure directly to physical or digital textbooks. It mandates the definition of learning objectives, prerequisites, and resource planning right at the top level, ensuring teachers have a clear roadmap before they step into the classroom. It also integrates with the school's version control system to track curriculum changes year-over-year.

---

## When This Screen Is Used

- Start of Academic Year Setup by Academic Coordinators when defining the curriculum for a new academic session
- Curriculum Redesign when a school changes its core textbook and needs to re-map existing lessons to the new textbook's chapters
- Pre-requisite Mapping when HODs decide that students cannot begin "Advanced Mechanics" without first completing "Basic Algebra"

## Default Data Load

This screen displays within the Syllabus Master tab group. When the user navigates to Syllabus → Master, SyllabusController@master() loads all master tab data simultaneously (Lessons, Topics, Competencies, etc.), each independently paginated at 10 rows per page. Shared dropdowns (Class, Section, Subject, Academic Session, Book) are fetched as active records with no pagination.

---

---

## Key Fields at a Glance

**Core Identity**
Every lesson must have a name, such as "Chapter 1: Matter in Our Surroundings". A shorter version of the name is also captured to be used for mobile app displays and report card printing. A system-generated tracking ID and auto-generated code are automatically assigned in the background to ensure standardized sorting and long-term analytics tracking, even if the lesson's name changes in the future. The sequence or ordinal value determines the display order, and changing this automatically shifts the sequence of other lessons.

**Relational Mapping**
The lesson is locked to a specific academic session, class, and subject, which defines the exact student group this lesson belongs to. The lesson is also linked to a specific physical or digital book from the Library. An additional field captures the exact book chapter detail, explaining exactly where in the book this lesson is found, such as "Page 14, Section 2.1".

**Academic and Planning Details**
The estimated periods field captures the expected number of classes required to complete the lesson, acting as the baseline for planning accuracy reports. The weightage percentage represents how much this chapter contributes to the final exam marks. A scheduled timeframe defines the macro-level target week or month for completion.

**Advanced Requirements**
Multiple learning objectives are defined to clearly state what the student should achieve. Prerequisites link to other lessons that must be completed first. Study resources allow attaching multimedia links like videos or reference documents directly to the lesson.

---

## Business Rules and Conditions

**Unique Constraints**
A school cannot have two lessons with the exact same name in the same class and subject. The system must block duplicate entries to prevent confusion in reports and planning.

**Immutability and Version Control**
If a lesson is imported from a master board repository like CBSE or NCERT, it is marked as a System Standard. In this state, the school cannot edit its core name or weightage. If the school wishes to alter the lesson, the system creates a "Derived" custom copy, leaving the original intact. Once an academic term begins, the lesson is locked. No structural changes can be made without generating a formal Curriculum Change Request.

**Deletion Restrictions**
You cannot delete a Lesson if it already contains smaller Topics inside it. The user must delete or move the topics first. Additionally, changing the academic year is prohibited once student progress is recorded against the lesson.

---

## Workflow Steps

**Adding a New Custom Lesson**
The Academic Coordinator navigates to Syllabus Master and selects Lessons. They choose the target Class and Subject, then click Add Lesson. They select the physical textbook from a searchable dropdown, enter the Lesson Name and Short Name, and add the estimated periods and weightage percentage. They define learning objectives and click Save. The system checks for duplicates and saves the record.

**Adding Prerequisites and Resources**
While editing a lesson, the HOD selects other existing lessons from a dropdown to mark them as prerequisites. They also paste web links or attach documents into the Study Resources section, which instantly become available to the teachers assigned to this lesson.

---

## Example Scenario

At the start of the academic year, the school adopts a new Computer Science curriculum for Grade 8. The HOD creates a new Lesson named "Introduction to Machine Learning". 

Because this is a difficult topic, the HOD adds a prerequisite, selecting a Grade 7 lesson called "Basic Algorithms". They also attach a reference video link. 

When a Grade 8 student attempts to open "Introduction to Machine Learning" on their student portal, the system checks the prerequisites. If the student failed the quiz for "Basic Algorithms" last year, the system displays a warning message advising them to clear the basics first. Meanwhile, the teacher sees the attached reference video on their dashboard, ready to be played in class.

---

## Related Screens

- **Topics** — Defines the granular breakdown of this lesson
- **Lesson Date Planning** — Where the macro schedule is overridden by specific classroom dates

---

## Requirements

**Controller:** `Modules\Syllabus\Http\Controllers\LessonController`
**Model:** `Modules\Syllabus\Models\Lesson` (table: `slb_lessons`)
**Requests:** `LessonRequest` (bulk create), `UpdateLessonRequest` (single update)
**Policy:** `LessonPolicy` (permissions: `tenant.lesson.viewAny`, `.view`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete`, `.status`)
**Route:** Resource route `Route::resource('lesson', LessonController::class)->names('lesson')` under module prefix
**Tab:** `lesson` under `syllabus.master.index`

Key controller methods:
- `index()` — Lists lessons with filterable, paginated table; loads class/subject/book/academic session dropdowns
- `create()` — Returns lesson creation form view
- `store(LessonRequest)` — Bulk-creates lessons in a transaction; iterates `$request->lessons` array
- `edit($id)` — Loads single lesson for editing with existing lessons in same class+subject
- `update(UpdateLessonRequest, $id)` — Updates single lesson in a transaction
- `destroy($id)` — Soft-deletes lesson; logs activity
- `trashed()` — Lists soft-deleted lessons
- `restore($id)` — Restores a soft-deleted lesson
- `forceDelete($id)` — Force-deletes with checks for exam scopes and question bank references
- `toggleStatus($id)` — Toggles `is_active` boolean via AJAX
- `updateOrder(Request)` — Bulk-updates ordinal values via AJAX
- `checkDuplicate(Request)` — Validates uniqueness of ordinal/name/code via AJAX
- `getSubject(Request)` — Returns subjects by class (via SubjectGroup relationship)
- `getBooks(Request)` — Returns books by class and subject (via BookClassSubject)
- `getClassTeachers(Request)` — Returns teachers by class/section (via TeacherProfile capabilities)
- `validateImportFile(Request)` — Validates XLSX/CSV import, returns error report or stores for import
- `startImport(Request)` — Executes import from stored validated file using LessonImport

---

## Who Can Access This Screen

- **Academic Coordinator** — Full CRUD access for setting up the curriculum at the start of the year
- **Head of Department** — Full CRUD access limited to their department's subjects
- **Principal** — Read-only access to review lesson structure across the school
- **Teacher** — Read-only access to view lesson details, prerequisites, and attached resources

All access is gated by `LessonPolicy` methods which map to `tenant.lesson.*` permissions.

---

## How This Screen Works — Logic Flow (Non-Technical)

The user navigates to the Syllabus Master section and selects the Lessons sub-module. They first choose the Academic Session, then the Class, and finally the Subject to set the context. The system loads an existing lesson list or shows an empty state if none exist. To add a lesson, the user clicks Add Lesson, which opens a form. They fill in the lesson name, short name, select a textbook from the Library, specify the book chapter detail, enter estimated periods, weightage percentage, and scheduled timeframe. They define learning objectives and optionally select prerequisite lessons from a dropdown of existing lessons. Study resources can be attached via URL or file upload. On save, the system validates uniqueness, checks immutability rules for system-standard lessons, and persists the record. Editing and deletion follow similar validation paths. If a lesson is marked as a system standard, edit buttons are disabled and a "Create Derived Copy" option is shown instead.

---

## Validate Before Save

**Bulk Create (`LessonRequest`):**
1. **lessons array required:** `lessons` must be a non-empty array
2. **Context required:** `academic_session_id`, `class_id`, `subject_id`, `bok_books_id` all required with `exists` validations
3. **name required+unique scoped:** Each lesson name is required (string, max:150) and checked for uniqueness within the same academic_session_id + class_id + subject_id combination using custom closure that ignores the current lesson's own ID on update
4. **code required+unique global:** Each lesson code is required (string, max:20) and checked for global uniqueness across all lessons in the database using custom closure
5. **ordinal required+unique scoped:** Each ordinal is required (integer, min:1) and checked for uniqueness within the same academic_session_id + class_id + subject_id combination using custom closure
6. **short_name:** nullable, string, max:50
7. **description:** nullable, string, max:255
8. **learning_objectives:** nullable, string (newline-separated, converted to JSON array in `prepareForValidation`)
9. **prerequisites:** nullable, string (comma-separated IDs, converted to JSON array in `prepareForValidation`)
10. **estimated_periods:** nullable, integer, min:1
11. **weightage_in_subject:** nullable, numeric, min:0, max:100
12. **nep_alignment:** nullable, string, max:100
13. **book_chapter_ref:** nullable, string, max:100
14. **scheduled_year_week:** nullable, integer, min:202001, max:210052
15. **is_active:** nullable, boolean
16. **resources array:** nullable, array; each resource requires `type` (in: video,pdf,link,document,image,audio,ppt), `title` (string, max:200), `url` (valid URL, max:500), `description` (nullable, max:500)

**Single Update (`UpdateLessonRequest`):**
1. **Context required:** `academic_session_id`, `class_id`, `subject_id`, `bok_books_id` all required with `exists` validations
2. **name required+unique scoped:** required, string, max:150; uses `Rule::unique` on `slb_lessons` scoped to `academic_session_id + class_id + subject_id + deleted_at IS NULL`, ignoring current lesson ID
3. **code required+unique global:** required, string, max:20; uses `Rule::unique` on `slb_lessons` scoped to `deleted_at IS NULL`, ignoring current lesson ID
4. **ordinal required+unique scoped:** required, integer, min:1; uses `Rule::unique` scoped same as name, ignoring current lesson ID
5. **short_name:** nullable, string, max:50
6. **description:** nullable, string, max:255
7. **learning_objectives:** nullable, string (newline-separated → JSON array via `prepareForValidation`)
8. **prerequisites:** nullable, array; each element must be integer and exist in `slb_lessons.id`
9. **estimated_periods:** nullable, integer, min:1
10. **weightage_in_subject:** nullable, numeric, min:0, max:100
11. **nep_alignment:** nullable, string, max:100
12. **book_chapter_ref:** nullable, string, max:100
13. **scheduled_year_week:** nullable, integer, min:202001, max:210052
14. **is_active:** nullable, boolean (default: false via `prepareForValidation`)

**Duplicate Check (AJAX — `checkDuplicate`):**
- Validates `class_id` (required|numeric), `subject_id` (required|numeric), `field` (required|in:ordinal,name,code), `value` (required)
- Queries `Lesson::where('class_id', $classId)->where('subject_id', $subjectId)` with field-specific WHERE clause
- Returns JSON: `{ success: true, exists: bool, message: string }`

**Import File Validation (`validateImportFile`):**
- Validates: `file` (required|mimes:xlsx,csv), `academic_session_id` (required), `class_id` (required|exists), `subject_id` (required|exists), `bok_books_id` (nullable|exists)
- For each non-empty row, validates: `lesson_number` (required|numeric|min:1), `lesson_name` required, `periods` (optional|numeric|min:1), `weightage_percent` (optional|numeric|0-100), `year_week` (optional|numeric|len>=6), `active` (optional|in:0,1,true,false,yes,no,y,n)
- Checks duplicate ordinal for session+class+subject and duplicate code globally

**Import Execution (`startImport`):**
- Reads stored file path from session, imports via `LessonImport` (Maatwebsite/Excel)
- Returns JSON: `{ status: 'completed', created: int, skipped: int, errors: array }`

---

## Error Handling and Validation Messages

- **Duplicate Name:** "A lesson with this name already exists in [Class] - [Subject]. Please use a different name."
- **System Standard Blocked:** "This lesson is a System Standard and cannot be modified. Click 'Create Derived Copy' to create a custom version."
- **Active Term Lock:** "This lesson is locked because the academic term is active and student progress exists. Submit a Curriculum Change Request to modify."
- **Deletion Blocked:** "Cannot delete this lesson because it contains [N] topic(s). Delete or reassign the topics first."
- **Missing Required Fields:** "Lesson Name, Class, Subject, and Academic Session are required fields. Please fill in all mandatory fields."
- **Invalid Weightage:** "Weightage must be a number between 0 and 100. Please enter a valid percentage."
- **Invalid Periods:** "Estimated periods must be a positive whole number."
- **Code Duplicate (Validation):** "The code '{$value}' already exists in the database." (from `LessonRequest`)
- **Ordinal Conflict (Validation):** "The order number '{$value}' is already used by '{$conflictLesson->name}' for this academic session, class and subject." (from `LessonRequest`)
- **Code Unique (Update):** "This lesson code is already in use." (from `UpdateLessonRequest`)
- **Ordinal Unique (Update):** "This order number is already assigned to another lesson for the selected session/class/subject." (from `UpdateLessonRequest`)
- **Book Required:** "The Book selection is required." (from `UpdateLessonRequest`)
- **Resource Type Invalid:** "Invalid resource type. Allowed: video, pdf, link, document, image, audio, ppt." (from `LessonRequest`)

---

## Success Scenarios

- At the start of the academic year, an Academic Coordinator creates 15 lessons for Class 8 Computer Science, links each to the prescribed NCERT textbook, sets weightage percentages, and attaches video resources — all within a single session. The system saves each lesson successfully and displays them in the sorted sequence.
- An HOD edits an existing lesson to add two prerequisite lessons from the previous grade. The system validates the prerequisites exist and saves the changes, enabling the student portal to display prerequisite warnings automatically.
- A teacher opens a lesson to view its attached resources and learning objectives before class, using the read-only view to prepare their daily lesson plan.

---

## Failure Scenarios

- An HOD attempts to create a lesson with the name "Chapter 1: Matter" for Class 9 Science, but a lesson with the same name already exists. The system blocks the save and displays the duplicate name error. The HOD renames it to "Chapter 1: Matter and Its Properties" and saves successfully.
- A teacher accidentally deletes a lesson that has 8 topics and 3 weeks of student progress data. The system blocks the deletion because of child topics and existing progress records, preventing accidental data loss.
- An Academic Coordinator tries to edit a System Standard NCERT lesson to change its weightage from 15% to 20%. The save fails because system-standard fields are immutable. The Coordinator creates a derived copy, changes the weightage there, and saves successfully.

---

## Dependencies module and tables

| Module | Tables |
|--------|--------|
| Syllabus Core | `slb_lessons` (primary, with `uuid BINARY(16) UNIQUE`, soft-deletes via `deleted_at`) |
| Syllabus Children | `slb_topics` (FK → `slb_lessons.id` CASCADE), `slb_syllabus_schedule` (FK → `slb_lessons.id`) |
| LMS Exam | `lms_exam_scopes` (FK → `slb_lessons.id`) |
| Academic Setup | `sch_org_academic_sessions_jnt`, `sch_classes`, `sch_subjects` |
| Library | `slb_books` (via `bok_books_id` FK), `slb_book_class_subjects` |
| Teacher Management | `sch_teacher_profiles`, `sch_employees` |
| Question Bank | `qbank_question_banks` (FK → `lesson_id`, checked on forceDelete) |
| Resource Management | `slb_lesson_resources` (via resources_json JSON column on slb_lessons) |
