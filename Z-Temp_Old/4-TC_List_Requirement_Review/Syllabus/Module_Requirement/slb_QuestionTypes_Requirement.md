# Question Types Master — Business Requirements

## What This Screen Does

The Question Types screen defines the foundational mechanical formats or structures of questions that can be added to the system's Question Bank, such as Multiple Choice, Fill in the Blanks, Long Answer, or File Upload. 

This is arguably the most critical configuration table for the Assessment Engine. It acts as the command center that tells the user interface how to display a question to a student, and tells the backend engine whether a specific question can be auto-graded by algorithms or if it requires manual checking by a human teacher.

---

## When This Screen Is Used

- System Initialization primarily during system setup by the software provider or top-level Admin to define standard testing formats
- New Assessment Modalities when the school wants to introduce a completely new assessment format like adding Coding Snippet, Audio Transcription, or Match the Following as supported question types

## Default Data Load

This screen displays within the Syllabus Bloom tab group. When the user navigates to Syllabus → Bloom, SyllabusController@bloom() loads all 5 bloom/grid screens simultaneously (Bloom Taxonomy, Cognitive Skills, Question Types, Question Type Specificity, Complexity Levels), each independently paginated at 10 rows per page. A shared Cognitive Skills dropdown is also loaded for filter purposes.

---

---

## Key Fields at a Glance

**Identity and Definition**
A System Code acts as the strict identifier, such as MCQ_SINGLE or LONG_ANSWER. This code is often linked directly to the software's code to trigger specific visual layouts. A Display Name provides the human-readable name for teachers, like 'Multiple Choice (Single Answer)' or 'Descriptive Essay'.

**Core Behavioral Settings**
A Requires Options Toggle dictates that if enabled, the system will forcibly display option input fields when creating the question. If disabled, it provides a text area or file upload zone instead. An Auto-Gradable Toggle dictates that if enabled, the system's algorithm can automatically check the student's submitted answer against the stored correct answer and award marks instantly. If disabled, the question is flagged and routed to a teacher's pending evaluations dashboard for manual marking.

**Control and Governance**
A System Lock Toggle acts as a safeguard. If enabled, this indicates a core architectural type required by the software. It absolutely cannot be edited, deactivated, or deleted by the school admin, preventing them from breaking the Question Bank interface.

---

## Business Rules and Conditions

**Visual Rendering Dependency**
The System Code and the Requires Options toggle dictate the visual layout. If a teacher selects a Multiple Choice type, the interface reads the toggle and displays checkbox inputs. If they select a Long Answer type, the interface provides a rich-text editor. 

**Auto-Grading Strict Enforcement**
If a Question Type is marked as Auto-Gradable, the system must enforce that the teacher provides a definitive correct answer when creating a question of this type. The system will block saving an auto-gradable question without an answer key. Conversely, if it is not Auto-Gradable, the correct answer field becomes an optional evaluation rubric intended only as a reference for the evaluating teacher.

**System Data Integrity**
Records that are locked by the System Lock toggle must trigger an immediate error if a school administrator attempts to alter their core settings or delete them. Only the software provider can alter these core types.

---

## Workflow Steps

**Adding a New Question Format**
The Admin navigates to Question Types to support a new language curriculum. They click Add Question Type and set the Name to "Audio Transcription". They disable the Requires Options toggle since students will type what they hear into a blank box. They disable the Auto-Gradable toggle because a teacher needs to listen to the audio and read the text to grade nuances properly. They leave the System Lock disabled since this is a custom school addition. They submit the form, and teachers can now select "Audio Transcription" when adding questions to the bank.

---

## Example Scenario

During a sudden school closure, the administration decides to conduct online subjective exams. The Admin verifies that the Long Answer question type exists. 

Because Long Answer is configured with Requires Options disabled and Auto-Gradable disabled, when students log into the exam portal, they are presented with a blank text box to type their essays instead of radio buttons. Furthermore, when the 2-hour exam concludes, the students do not get an instant result. Instead, the system automatically batches these specific questions and routes them into the English teacher's Pending Manual Evaluations queue. The results are only published after the teacher manually inputs the marks.

---

## Related Screens

- **Question Type Specificity** — Links these broad Question Types to specific cognitive goals
- **Question Bank Module** — This master configuration populates the primary dropdown when teachers create new questions

---

## Requirements

- This screen loads exclusively via the Syllabus Bloom tab view at GET /syllabus/bloom (route: syllabus.bloom.index). The individual controller index route is internal and not directly accessible.bloom.index`).
- The system MUST authorize access via `Gate::authorize()` using the `tenant.question-type.viewAny` permission.
- The system MUST allow users with appropriate permissions to perform CRUD operations: create, store, edit, update, show (`withTrashed()->findOrFail`), destroy (soft-delete: sets `is_active = false` then calls `delete()`), restore, forceDelete, and toggleStatus.
- The system MUST enforce validation rules via FormRequest:
  - `code`: required, string, max:20, unique on `slb_question_types` (ignoring self on update)
  - `name`: required, string, max:100
  - `has_options`: nullable, boolean
  - `auto_gradable`: nullable, boolean
  - `description`: nullable, string, max:255
  - `is_system`: nullable, boolean
  - `is_active`: nullable, boolean
- The system MUST protect system-defined records (`is_system = true`) with guards:
  - `update()`: if `$questionType->is_system`, redirect with error "System-defined question types cannot be modified."
  - `destroy()`: if `$questionType->is_system`, redirect with error "System-defined question types cannot be deleted."
  - `forceDelete()`: if `$questionType->is_system`, redirect with error "System-defined question types cannot be permanently deleted."
  - `toggleStatus()`: if `$questionType->is_system`, return JSON 403 with "System-defined question types status cannot be changed."
- The system MUST apply `prepareForValidation()` to uppercase `code` via `strtoupper()` and cast `is_active` and other boolean fields.
- The system MUST paginate results at 10 per page.
- The system MUST log activities for: Stored, Updated, Trashed, Restored, Deleted, Toggled.
- The system MUST support soft deletes via the `SoftDeletes` trait.
- The system MUST redirect to route `syllabus.bloom.index` with tab `question_types` after any CRUD operation.

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|---|---|---|
| Super Admin | `tenant.question-type.*` (all permissions) | Full CRUD + restore + forceDelete + toggleStatus (system-defined records protected) |
| Academic Director | `tenant.question-type.viewAny` + `.view` | Read-only (view, show) |
| HOD | `tenant.question-type.viewAny` + `.view` + `.create` + `.update` | Create and Edit (cannot delete/toggle; system-defined records read-only) |
| Teacher | No explicit permission | No access |

---

## How This Screen Works — Logic Flow (Non-Technical)

1. The user navigates to the aggregate Syllabus page; the Question Types tab triggers the `index()` controller.
2. The screen loads as a tab within the Syllabus Bloom tab view. Then `Gate::authorize()` checks the user's permission.
3. The system fetches all Question Type records (including soft-deleted) paginated at 10 per page.
4. The user clicks "Add New" to open the creation form with fields: Code, Name, Has Options (boolean), Auto-Gradable (boolean), System-Defined (boolean), Description, and Status.
5. The system pre-processes the input via `prepareForValidation()` — uppercasing the code and casting boolean fields.
6. On submit, the FormRequest validates: code (required, unique, max:20), name (required, max:100), has_options (boolean), auto_gradable (boolean), description (nullable, max:255), is_system (boolean), is_active (boolean).
7. If valid, the record is saved and an activity log entry "Stored" is created. The system redirects to the Question Types tab.
8. Existing records can be edited via the edit form. If `is_system` is true, the update is blocked with an error message.
9. Deleting a record triggers soft delete: `is_active` is set to `false`, then `delete()` is called. If `is_system` is true, deletion is blocked.
10. The "Trashed" view shows soft-deleted records. System-defined records cannot be force-deleted; only non-system records can be permanently removed.
11. The `toggleStatus()` action checks `is_system`. If true, returns JSON 403 `{success: false, message: "System-defined question types status cannot be changed."}`. Otherwise flips `is_active` and returns `{success, is_active, message}`.
12. The `show()` view uses `withTrashed()->findOrFail($id)` to display both active and trashed records.

---

## Validate Before Save (Multiple Conditions)

1. **Code Required** — `code` field must not be empty. Error: "Question type code is required."
2. **Code Max Length** — `code` must not exceed 20 characters. Error: "Code must not exceed 20 characters."
3. **Code Uniqueness** — `code` must be unique in `slb_question_types` table (ignoring the current record on update). Error: "This question type code already exists."
4. **Code Uppercase** — `code` is automatically uppercased via `strtoupper()` in `prepareForValidation()`.
5. **Name Required** — `name` field must not be empty. Error: "Question type name is required."
6. **Name Max Length** — `name` must not exceed 100 characters. Error: "Name must not exceed 100 characters."
7. **Boolean Fields** — `has_options`, `auto_gradable`, `is_system`, `is_active` are cast to boolean automatically.
8. **System Record Guard (Update)** — If `is_system` is true, update is rejected with: "System-defined question types cannot be modified."
9. **System Record Guard (Delete)** — If `is_system` is true, delete is rejected with: "System-defined question types cannot be deleted."
10. **System Record Guard (Force Delete)** — If `is_system` is true, forceDelete is rejected with: "System-defined question types cannot be permanently deleted."
11. **System Record Guard (Toggle Status)** — If `is_system` is true, toggleStatus returns HTTP 403 with: "System-defined question types status cannot be changed."
12. **Authorization** — `Gate::authorize()` checks the user has the required permission before any operation.

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|---|---|---|
| Code is empty | "Question type code is required." | 500 |
| Code exceeds 20 characters | "Code must not exceed 20 characters." | 500 |
| Duplicate code (already exists) | "This question type code already exists." | 500 |
| Name is empty | "Question type name is required." | 500 |
| Name exceeds 100 characters | "Name must not exceed 100 characters." | 500 |
| Edit system-defined type | "System-defined question types cannot be modified." | 403 |
| Delete system-defined type | "System-defined question types cannot be deleted." | 403 |
| Force-delete system-defined type | "System-defined question types cannot be permanently deleted." | 403 |
| Toggle status on system-defined type | "System-defined question types status cannot be changed." | 403 |
| Unauthorized access (missing permission) | "This action is unauthorized." | 403 |


---

## Success Scenarios

**SC-001: Creating a New Question Type**
1. Admin navigates to the Syllabus page → Question Types tab → clicks "Add New".
2. Enters Code: "AUDIO_TRANSCRIPTION", Name: "Audio Transcription", Has Options: No, Auto-Gradable: No, Is System: No, Status: Active.
3. System uppercases code, validates all rules, saves the record.
4. Activity log records "Stored". Teachers can now select "Audio Transcription" when adding questions to the Question Bank.

**SC-002: Deactivating a Non-System Question Type**
1. Admin finds an existing active non-system type and clicks the toggle status button.
2. System checks `is_system` is false, flips `is_active`, returns JSON `{success: true, is_active: false, message: "Status updated successfully"}`.
3. The type is removed from the Question Bank dropdown. Existing questions retain their type for historical data integrity.

**SC-003: Restoring a Soft-Deleted Question Type**
1. Admin navigates to the "Trashed" view and clicks "Restore" on a deleted non-system record.
2. System sets `deleted_at` to `null` and `is_active` to `true`.
3. Activity log records "Restored". The record reappears in the active list.

---

## Failure Scenarios

**FC-001: Editing a System-Defined Type**
1. Admin attempts to modify the Auto-Gradable toggle of a system-defined type (is_system = true).
2. The `update()` controller checks `$questionType->is_system` and redirects with error: "System-defined question types cannot be modified."
3. Admin can only view the record; changes require software provider intervention.

**FC-002: Deleting a System-Defined Type**
1. Admin attempts to delete a system-defined type.
2. The `destroy()` controller checks `$questionType->is_system`, redirects with error: "System-defined question types cannot be deleted."
3. Admin can only deactivate the type if it needs to be hidden.

**FC-003: Toggling Status on a System-Defined Type**
1. Admin attempts to toggle the status of a system-defined type.
2. The `toggleStatus()` controller checks `$questionType->is_system`, returns JSON 403 with `{success: false, message: "System-defined question types status cannot be changed."}`.
3. The status remains unchanged.

---

## Dependencies module and tables

| Type | Name | Details |
|---|---|---|
| Primary Table | `slb_question_types` | `id`, `code` VARCHAR(20) UNIQUE, `name` VARCHAR(100), `has_options` TINYINT(1), `auto_gradable` TINYINT(1), `description` VARCHAR(255), `is_system` TINYINT(1), `is_active` TINYINT(1), `created_at`, `updated_at`, `deleted_at` (SoftDeletes) |
| Related Table | `slb_question_bank` | Each question references `slb_question_types.id` for its format |
| Related Table | `slb_ques_type_specificity` | Links question types to cognitive skills |
| Module Dependency | Syllabus Module | Core module where this master data is configured via `syllabus.bloom.index` route |
| Module Dependency | Assessment Module | Exam engine uses `auto_gradable` flag to route answers for evaluation |
| Module Dependency | User & Permission Module | `Gate::authorize()` checks `tenant.question-type.*` permissions |
