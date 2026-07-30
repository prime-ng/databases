# Exam Scope — Screen

---

## What Does This Screen Do?

The Exam Scope screen defines the syllabus coverage for an exam paper. It specifies which lessons, topics, and question types will be included in the exam, along with the target number of questions and weightage percentage for each combination.

Think of exam scopes as the blueprint for what content the exam will cover. They tell the system: "For this exam paper, we want exactly 5 questions from Algebra — Linear Equations of type MCQ, worth 20% of the total marks, and 3 questions from Geometry — Triangles of type Short Answer, worth 15%."

These scopes are used during question selection (on the Paper Set Questions screen) to ensure the admin picks the right number and type of questions from each topic area. They are also used during validation to ensure all syllabus areas are adequately covered before the exam is published.

---

## Real-Life Example

A school is creating the Final Exam for Class 10 Science. The syllabus covers three units: Physics, Chemistry, and Biology. The exam controller, Dr. Gupta, decides the exam should have:
- Physics: 10 MCQ questions from the "Light" chapter (40% weightage)
- Chemistry: 8 Short Answer questions from "Chemical Reactions" (30% weightage)
- Biology: 7 Long Answer questions from "Life Processes" (30% weightage)

He opens the Exam Scope screen, selects the "Class 10 Science Final" exam paper, and adds three scope rows. After entering all values, the system shows total target questions: 25, total weightage: 100%. Since the exam paper requires exactly 25 questions, everything matches. He saves.

Later, when the teacher is adding questions to the paper set on the Paper Set Questions screen, the system will warn if they try to add more than 10 MCQ questions from "Light" or more than 8 from "Chemical Reactions." This ensures the final exam matches the planned syllabus coverage.

If Dr. Gupta returns to edit the scopes and tries to change the Biology scope to 10 questions (making the total 28 instead of 25), the system warns: "Total target questions (28) must match exam paper total questions (25)." He also cannot make the total weightage exceed 100%.

---

## How It Works

This is the fourth sub-tab inside the Creation & Allocation tab. When the admin opens it, all exam scopes are displayed in a table, 10 records per page. Each row shows the scope's ID, exam paper title, lesson name, topic name, target question count, weightage percentage, active status, and action buttons.

The admin can filter scopes by:
- Exam paper (select from all active exam papers).
- Lesson (select from all active lessons).
- Active/inactive status.
- Free-text search.

**Creating Scopes (Bulk)**

When the admin clicks "Add Exam Scope," a form opens. First, the admin must select an exam paper. Once selected, the system:
1. Loads the exam paper's total_questions and total_marks fields and displays them as reference limits.
2. Loads all lessons that belong to the exam paper's class and subject combination.
3. Shows an interactive table where the admin can add multiple scope rows.

Each scope row has these fields:
- Lesson (required): Selected from lessons filtered by the exam paper's class and subject.
- Topic Hierarchy: A cascading 4-level topic dropdown that loads dynamically based on the selected lesson. The levels are:
  - Level 1: Root topics (no parent or parent_id = 0).
  - Level 2: Topics whose parent is the selected Level 1 topic.
  - Level 3: Topics whose parent is the selected Level 2 topic.
  - Level 4: Topics whose parent is the selected Level 3 topic.
  Only the deepest selected level's topic_id is saved to the database.
- Question Type (optional): A dropdown of all active question types.
- Target Question Count (required): Integer, minimum 0.
- Weightage Percentage (optional): Decimal between 0 and 100.
- Active: Checkbox, default checked.

The admin can add as many rows as needed using "Add Scope Row" button and remove individual rows with the trash button.

As the admin fills in values, the table footer shows:
- Sum of all target question counts compared to the exam paper's total_questions limit.
- If the total questions don't match the limit, the submit button is disabled with a warning.
- If the total weightage exceeds 100%, the submit button is disabled with a warning.

When the admin clicks "Create Scopes," the system validates:
1. Exam paper must be selected.
2. At least one scope row must exist. If not: "No valid scope rows found. Please add at least one scope."
3. Each row must have a lesson selected, a valid target count (0 or more), and weightage between 0 and 100.
4. Total weightage across all rows must not exceed 100%. If it does: "Total weightage cannot exceed 100%. Current total: X%"
5. If the exam paper has a total_questions value greater than 0, the sum of target_question_count across all rows must exactly match it. If not: "Total target questions (X) must match exam paper total questions (Y)."

If all validations pass, all scope records are created in a single database transaction. Each scope creation is logged individually in the activity log with details of the lesson, topic, target count, and weightage.

**Editing Scopes (Bulk)**

When the admin clicks "Edit" for an exam paper (note: the edit is by exam paper, not by individual scope), the system loads all existing scopes for that exam paper.

The edit form is similar to the create form but:
- The exam paper selection is disabled (you're editing scopes for the pre-selected paper).
- All existing scopes are pre-loaded into rows with their current values.
- The topic hierarchy for each scope is restored: the system loads each level of the topic chain using AJAX, respecting the parent-child relationships in the saved topic's hierarchy.

The admin can:
- Modify existing scope rows (change lesson, topic, question type, target count, weightage, active status).
- Add new scope rows (which will be created).
- Remove existing scope rows (which will be permanently deleted from the database).

When the admin clicks "Update Scopes," the system:
1. Validates the same rules as create (at least one scope, weightage ≤ 100%, total questions match).
2. For each submitted row:
   - If it has an ID and belongs to the exam paper, it updates that existing scope.
   - If it has no ID, it creates a new scope.
3. For any existing scope IDs that were NOT in the submission, the system permanently deletes them (force delete).
4. After saving, the system automatically updates the parent exam paper's total_questions and total_weightage fields to match the new sums from the scopes.
5. Each change (create, update, delete) is counted and reported in the success message: "X created, Y updated, Z deleted successfully!"

**Viewing Scopes**

When the admin clicks "View" for an exam paper, the system shows a summary page with:
- Exam paper info.
- Summary statistics: total scopes, total target questions, total lessons covered, total topics covered, total weightage, minimum questions per scope, maximum questions per scope, average questions per scope, average weightage.
- A list of all individual scope records with their details.
- Usage information from the ExamScopeUsageCheckService: whether the exam paper has allocations, paper sets, blueprints, results, or student attempts.

**Deleting Scopes (Bulk Trash)**

When the admin clicks "Delete" for an exam paper, the system:
1. Finds all scopes belonging to that exam paper.
2. Sets is_active to false for each scope.
3. Soft-deletes each scope.
4. Logs each deletion in the activity log.

**Restoring Scopes (Bulk)**

When the admin clicks "Restore" for a trashed exam paper, the system:
1. Checks usage first via ExamScopeUsageCheckService. If the exam paper has any allocations, paper sets, blueprints, results, or student attempts, restoration is blocked: "Cannot restore this scope because the exam paper has allocations or student attempts."
2. Finds all soft-deleted scopes for that exam paper.
3. Restores each scope and sets is_active back to true.

**Permanently Deleting Scopes (Bulk)**

When the admin clicks "Permanent Delete," the system:
1. Checks usage (same check as restore). If used, blocks: "Cannot permanently delete this scope because the exam paper has allocations or student attempts."
2. Permanently deletes all scopes for that exam paper from the database.

**Toggling Active Status (Bulk)**

When the admin toggles the active status of any scope, the system updates ALL scopes for that entire exam paper to the same status. This is a bulk toggle — it affects all scopes belonging to the same exam paper, not just the individual scope clicked.

**AJAX Data Loading**

The screen uses several AJAX endpoints:
1. Get exam paper details: Returns the exam paper's total_questions, total_marks, class_id, and subject_id.
2. Get lessons by exam paper: Returns lessons filtered by the exam paper's class and subject. Also used for lessons filtered by subject only (from exam ID).
3. Get topic hierarchy: Returns topics for a specific lesson at a specific level (1-4). Topics are loaded level by level with parent_id filtering. The response includes each topic's ID, name, code, level, level_name, and parent_id. Topics are ordered by ordinal and then name.

---

## Key Fields

**Exam Paper**: The parent exam paper for which the scope is defined. Required.

**Lesson**: The specific lesson from the syllabus that this scope covers. Required at the form level (client-side validation). Optional in the database schema (nullable).

**Topic**: The specific topic from the syllabus. Can be hierarchical with up to 4 levels of parent-child relationships. Optional.

**Question Type**: The type of questions for this scope (e.g., MCQ, True/False, Short Answer, Long Answer). Optional.

**Target Question Count**: How many questions should be selected from this scope combination. Required, integer, minimum 0.

**Weightage Percentage**: The percentage weightage of this scope in the exam. Optional, decimal between 0 and 100.

**Is Active**: Whether this scope is active. Default true. Toggled in bulk for all scopes of an exam paper.

---

## Business Rules

**Scopes Are Managed in Bulk**: All scopes for a single exam paper are created, edited, and deleted together. You never manage a single scope in isolation. The create form accepts an array of scope rows. The edit form shows all existing scopes for the paper. The delete/restore actions affect all scopes for the paper simultaneously.

**Weightage Cannot Exceed 100%**: The total weightage percentage across all scopes for an exam paper must not exceed 100%. This is validated both client-side (disabling the submit button) and server-side (rejecting the save with an error message).

**Target Questions Must Match Exam Paper Total**: If the exam paper has a total_questions value set (greater than 0), the sum of target_question_count across all scope rows must exactly match that value. This is validated both client-side and server-side.

**Exam Paper Totals Auto-Sync**: When scopes are updated, the system automatically updates the parent exam paper's total_questions and total_weightage fields to match the new sums from the scopes. This keeps the exam paper in sync with its actual scope configuration.

**Lesson Is Required at Form Level**: On the client side, each scope row must have a lesson selected. This is enforced through JavaScript validation before form submission. If any row lacks a lesson, submission is blocked with a row-specific error message.

**Usage Protection for Restore/Force Delete**: Before restoring or permanently deleting scopes, the system checks whether the exam paper has any dependencies:
- ExamAllocation records (student allocations).
- ExamPaperSet records (paper sets).
- ExamBlueprint records (blueprints).
- ExamResult records (student results).
- ExamAttempt records (student attempts).
If any exist, the operation is blocked. This prevents modifying scopes for exam papers that are already in active use.

**No Usage Protection for Create/Edit/Delete**: Creating, editing, or soft-deleting scopes does NOT check usage protection. Only restore and force delete are blocked. This means the admin can freely add, modify, or trash scopes even for used exam papers, but cannot permanently remove or restore them.

**4-Level Topic Hierarchy**: Topics are loaded using a cascading 4-level dropdown system. Level 1 shows root topics (no parent). Each subsequent level loads topics whose parent matches the previously selected topic. Only the leaf-level topic ID (the deepest selected) is stored in the database.

**Lessons Filtered by Exam Paper**: When selecting an exam paper, the system loads only lessons that belong to that exam paper's class and subject. This ensures the admin only sees relevant syllabus content.

**Bulk Toggle Affects Entire Exam Paper**: When toggling the active status of any scope, ALL scopes for the same exam paper are toggled to the same status. This is intentional — you cannot have some scopes active and others inactive for the same paper.

**Transaction-Based Operations**: All create, update, delete, restore, and force-delete operations run inside database transactions. If anything fails, the entire operation is rolled back.

**Error Logging**: Database errors during create/update/delete are logged with full exception details and request data for debugging.

**Soft Delete on Individual Scopes**: While actions are bulk, each ExamScope record has its own soft delete. The trashed view groups records by exam_paper_id and shows the total scopes and last deleted timestamp per exam paper.

**Scope Show Page Provides Analytics**: The show page computes and displays summary statistics including total scopes, total questions, total lessons, total topics, total weightage, and min/max/avg values. This helps the admin understand the scope coverage at a glance.

---

## Validation & Error Messages

| When | What Is Checked | Error Message |
|------|----------------|---------------|
| Create/Update | No scope rows submitted | "No valid scope rows found. Please add at least one scope." |
| Create/Update | Total weightage exceeds 100% | "Total weightage cannot exceed 100%. Current total: X%" |
| Create/Update | Total questions don't match paper limit | "Total target questions (X) must match exam paper total questions (Y)" |
| Create/Update | Each row: missing lesson | "Row X: Please select a Lesson." |
| Create/Update | Each row: invalid target count | "Row X: Target quantity must be 0 or greater." |
| Create/Update | Each row: invalid weightage | "Row X: Weightage must be between 0 and 100." |
| Create/Update | exam_paper_id required | Laravel default |
| Restore | Exam paper has allocations/attempts/etc. | "Cannot restore this scope because the exam paper has allocations or student attempts." |
| Force Delete | Exam paper has allocations/attempts/etc. | "Cannot permanently delete this scope because the exam paper has allocations or student attempts." |
| Update validation | scopes.*.id (if provided) must exist | Laravel default |
| Update validation | scopes.*.lesson_id (if provided) must exist | Laravel default |
| Update validation | scopes.*.topic_id (if provided) must exist | Laravel default |
| Update validation | scopes.*.question_type_id (if provided) must exist | Laravel default |
| Update validation | scopes.*.target_question_count required, integer, min:0 | Laravel default |
| Update validation | scopes.*.weightage_percent numeric, min:0, max:100 | Laravel default |

---

## Permissions

- `tenant.exam-scope.viewAny` — View the list of all exam scopes
- `tenant.exam-scope.view` — View scope details for an exam paper
- `tenant.exam-scope.create` — Create new scopes
- `tenant.exam-scope.update` — Edit existing scopes
- `tenant.exam-scope.delete` — Soft-delete (trash) scopes
- `tenant.exam-scope.restore` — Restore trashed scopes
- `tenant.exam-scope.forceDelete` — Permanently delete scopes
- `tenant.exam-scope.status` — Toggle active/inactive status (bulk)

---

## Related Screens

- **Exam Paper**: The parent entity. All scopes belong to exactly one exam paper. Scopes also auto-update the exam paper's total_questions and total_weightage fields.
- **Paper Set Questions (lms_PaperQuestion)**: Uses exam scopes during question selection to validate that the admin does not exceed the target question count for any lesson/topic/type combination.
- **Lesson (slb_lessons)**: Reference table for lessons. Lessons shown are filtered by the exam paper's class and subject.
- **Topic (slb_topics)**: Reference table for topics with hierarchical parent-child relationships and level types (TopicLevelType).
- **Question Type (slb_question_types)**: Reference table for question types.
- **Exam Blueprint**: Also defines exam structure but is separate from scopes — blueprints handle section-level structure while scopes handle syllabus coverage.

**Edge Cases and Important Behaviours**:

1. **Exam Paper Must Be Selected First**: On the create screen, the submit button is disabled and no scope rows can be properly configured until an exam paper is selected. Selecting an exam paper loads its total_questions, total_marks, and lessons via AJAX. If no exam paper is selected, the system shows the message "Please select an Exam Paper first."

2. **Lesson Options Change Dynamically**: When the admin changes the exam paper selection, all existing scope rows' lesson dropdowns are refreshed with lessons specific to the new exam paper's class and subject. This may change or clear previously selected values.

3. **Topic Hierarchy Loading**: The topic hierarchy is loaded level by level. Level 1 topics are root topics (parent_id is null or 0). When a Level 1 topic is selected, the system loads Level 2 topics whose parent_id matches. This continues up to Level 4. Only the deepest selected topic ID is finally stored.

4. **Edit Restores Topic Chain**: On the edit screen, each existing scope's topic hierarchy is restored by sequentially loading each level of the parent chain. The system waits for each AJAX call to complete (with a 500ms delay between levels) before loading the next, ensuring proper cascading selection.

5. **Deleted Rows Are Permanently Removed**: During edit, if the admin removes a scope row that came from the database (has an ID), it is not just soft-deleted — it is permanently deleted (force delete) when the form is submitted. This means there is no way to recover removed scope rows through the trash.

6. **No Validation on Weightage When All Are Null**: If the admin leaves all weightage fields empty (null), the total weightage is 0, which does not exceed 100%, so the form can be submitted without any weightage values.

7. **Validation Runs on Client and Server**: The client-side validation provides immediate feedback and disables the submit button. However, the server also re-validates everything, so bypassing client-side checks (e.g., via browser developer tools) will still result in server-side rejection.

8. **Update Also Modifies Exam Paper**: When scopes are updated, the parent exam paper's total_questions and total_weightage are automatically synced to match the new sums. This is a side effect that the admin may not be explicitly aware of.

9. **Trashed Scopes Grouped by Exam Paper**: The trash view does not list individual trashed scopes. Instead, it groups them by exam_paper_id and shows the total count per exam paper along with the last deletion timestamp.

10. **Show Page Provides Analytics**: The show page computes and displays summary statistics including total scopes, total questions, total lessons, total topics, total weightage, min/max/avg questions, and avg weightage. This gives a comprehensive overview of the exam paper's scope coverage at a glance.
