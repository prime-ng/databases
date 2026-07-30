# Paper Set Questions — Screen

---

## What Does This Screen Do?

This screen is where an administrator selects and assigns actual questions from the Question Bank to a specific paper set. This is the core content-definition step of exam creation. Without this screen, the paper set would just be an empty shell with no actual test content.

The admin picks a paper set, chooses a blueprint section (like "Section A" or "Section B"), searches for questions using many different filters, adds them to a temporary session, and finally saves them all at once. The system then checks whether the selected questions meet all the requirements of the exam paper — things like the right number of questions, correct total marks, difficulty distribution rules, syllabus coverage limits, and usage restrictions.

Additionally, the admin can later edit individual question properties (sequence order, marks, whether the question is compulsory, etc.) or remove questions from the set.

---

## Real-Life Example

Imagine a school is preparing the final exam for Class 10 Mathematics. The exam has two paper sets — Set A and Set B — to prevent cheating. A teacher, Ms. Sharma, is filling Set A.

She first selects "Set A" from the dropdown and picks the blueprint section "Section A — Multiple Choice Questions." The system tells her that Section A can have at most 10 questions worth 20 marks total. She then searches the question bank for "Algebra — Linear Equations" and finds 15 available MCQs. She picks 10 of them, adjusting their marks to 2 each.

Before saving, she looks at the review tab to double-check her selection, and the validation tab shows her that she has exactly 10 questions worth 20 marks — matching the blueprint limits. She also sees the difficulty distribution: 5 easy questions and 5 medium questions, which meets the exam's requirement of 40-60% easy and 40-60% medium.

She clicks "Save Paper Set." The system checks that the total matches the exam paper's requirement (exactly 35 questions per set, 70 marks), the difficulty rules are satisfied, and no scope limits are exceeded. Everything checks out, so the system saves her questions and logs that she added them.

Later, she realizes Question 5 should actually be worth 3 marks instead of 2. She edits the marks inline, and the system confirms the total marks haven't exceeded the limit.

---

## How It Works

When the admin opens this screen, they see a search bar and a table showing all questions currently assigned to paper sets, grouped by each paper set. The default view shows 10 records per page, newest first.

To begin working, the admin must first select a paper set from the dropdown and a blueprint section. The blueprint tells the system which section of the exam paper the questions belong to (e.g., "Section A", "Section B") and sets limits on how many questions and marks that section can contain.

Once a paper set and blueprint are selected, the admin can use an extensive filter panel to search the Question Bank. The filters are organized into three groups:

1. **Academic Details**: Class, Section, Subject Group, Subject, Lesson, Topic.
2. **Question Properties**: Question Type, Complexity Level, Bloom's Taxonomy Level, Cognitive Skill, Question Type Specificity, Recommendation Type, Performance Category, Question Tags, Priority.
3. **Usage & Settings**: Show Only Un-used Questions, Show Only Authorised Questions, Usage Type (For Quiz, For Exam, For Quest), Quantity Limit.

When the admin clicks "Apply Filters," the system searches for questions that match all criteria. The results exclude any questions already saved to this paper set (including soft-deleted ones) or already in the current session.

The admin can select individual questions or use "Select All" to pick multiple questions. Each question shows its title, type, complexity, Bloom's level, cognitive skill, type specificity, and default marks. The admin can adjust the ordinal (sequence number) for each question before adding.

When "Add Selected" is clicked, each question goes through these checks before being added to the session:
- The paper set must be selected.
- The question must not already exist in the session or the database for this paper set.
- A blueprint must be selected.
- The blueprint's question limit must not be exceeded.

The session is stored in the browser's sessionStorage, meaning questions are held temporarily until saved. The admin can switch between three tabs:

1. **Question Selection** (the search and filter view).
2. **Review Selected** (shows all questions in the current session plus any already saved to the database). Here the admin can change ordinals, adjust marks, modify negative marks, and remove questions.
3. **Validation & Stats** (shows progress toward blueprint limits and exam paper limits, difficulty distribution analysis, and summary stats).

When the admin clicks "Save Paper Set," the system sends all session questions to the server. Before saving, the admin sees a confirmation dialog showing the counts. The server then runs a series of validations:

1. No questions selected? Returns error "No questions selected."
2. Total questions must match the exam paper's exact question count. If not: "Exact selection required. This exam paper requires exactly X questions."
3. No duplicate questions are allowed (unique constraint silently skips them).
4. If the exam paper requires unused questions only, the system checks each question hasn't been used in a previous exam. If violated: "This exam paper requires unused questions only. The following questions have been used before: X"
5. If the exam paper requires authorised questions only (for_quiz = 1), the system checks each question. If violated: "This exam paper requires authorised questions only (for_quiz=1). The following questions are not authorised: X"
6. Difficulty distribution rules are checked if the exam paper has a difficulty config. If the distribution would be exceeded: In strict mode, the save is rejected with a message about which type/complexity combination exceeds the max allowed. In warning mode (ignore_difficulty_config = true), the save proceeds but a warning is appended to the success message.
7. Exam scope limits are checked — the system validates that adding these questions won't exceed the target question count for any scope (question type + lesson + topic combination). If violated: "Cannot add questions. Limit exceeded for Scope: X"
8. Marks from each question may be overridden by matching difficulty distribution rules (if a rule matches the question's type, complexity, Bloom, cognitive skill, and type specificity, the rule's marks_per_question value is used instead of the question's default marks).

If all validations pass, the system creates PaperSetQuestion records, logs usage for each question (with usage type ONLINE_EXAM or OFFLINE_EXAM based on the exam paper's mode), and returns success. The admin is then redirected back to the main screen.

If the admin wants to edit or remove questions after saving, they can do so from the main index screen. Individual operations include:
- Editing sequence order via AJAX (inline update).
- Editing marks override via AJAX (the system checks the total marks limit before applying the change).
- Toggling compulsory status via AJAX.
- Editing all fields on a dedicated edit form.
- Deleting a single question (soft delete, also removing its usage log).
- Bulk removing multiple questions (the system removes both the question records and their usage logs permanently).
- Restoring a soft-deleted question (also restores its usage log).
- Permanently deleting a question (force delete, also permanently removes usage logs).
- Toggling active/inactive status via AJAX.

When a question is added via the single "Create" form (not the bulk AJAX flow), the system separately checks:
- The total questions limit: If adding one more would exceed the limit, it rejects.
- The total marks limit: If the new marks would exceed the limit, it rejects.

When editing via the single "Edit" form, the system recalculates the total marks by subtracting the old effective marks and adding the new potential marks, then checks against the limit.

The index screen groups questions by paper set using a collapsible UI. Each group header shows the paper set name and question count. Rows show question ID, title, section name, ordinal, marks (including negative marks if applicable), and compulsory status.

---

## Key Fields

**Paper Set**: The paper set this question belongs to. Required.

**Question**: The actual question from the Question Bank. Required.

**Section Name**: The section grouping within the paper (e.g., "Section A", "Section B"). This defaults from the selected blueprint's section_name (not hardcoded to "Section A").

**Exam Blueprint**: Links this question to a specific blueprint section. Optional but required in the bulk add flow.

**Ordinal**: The sequence order of this question within the set. Required, must be 0 or greater.

**Override Marks**: The marks assigned to this question in this specific set. Can differ from the Question Bank's default marks. Required, cannot be negative, max 999.99.

**Negative Marks**: Marks deducted for a wrong answer. Defaults to 0.

**Is Compulsory**: Whether this question is compulsory (must be attempted). Default behaviour varies: the form request defaults it to false via boolean casting; the UI considers the global request parameter and per-question overrides.

---

## Business Rules

**Only Published Questions**: When searching the Question Bank, only questions with status "PUBLISHED" and active status are returned.

**Question Count Must Match Exactly**: If the exam paper has a total_questions limit, the total number of questions added to a set must exactly match this limit. Both underfilling and overfilling are rejected.

**Marks Limit Cannot Be Exceeded**: The sum of override_marks across all questions in a set must not exceed the exam paper's total_marks. This applies on individual add, bulk add, single update, and inline marks update.

**Difficulty Distribution Validation**: If the exam paper has a difficulty_config_id set, the system validates the question distribution against the difficulty rules. For each rule (question type + complexity level combination, with optional Bloom/cognitive skill/specificity matching), the number of questions must not exceed the max_percentage of the total target. The calculation base is the exam paper's total_questions if set, otherwise the current total count. If a question doesn't match any rule, it's rejected. In strict mode (ignore_difficulty_config = false), violations block the save. In warning mode (ignore_difficulty_config = true), violations are reported as warnings but the save proceeds.

**Difficulty Marks Override**: When a difficulty config is active, matching a question to a rule may override its marks. If a rule has marks_per_question set, that value is used instead of the question's default marks. This applies both to search display and actual save.

**Exam Scope Limits**: If the exam paper has scope definitions, each scope defines a target question count for a specific combination of question type + lesson + topic. The total existing questions plus newly added questions for each scope cannot exceed the scope's target_question_count.

**Unused Questions Only**: If the exam paper has only_unused_questions enabled, only questions that have never been used in any previous exam (no record in the usage log with type ONLINE_EXAM or OFFLINE_EXAM) can be selected. The search filter also forces this restriction automatically when the exam paper requires it.

**Authorised Questions Only**: If the exam paper has only_authorised_questions enabled, only questions with for_quiz = 1 can be selected. The search filter also forces this restriction automatically when the exam paper requires it.

**No Duplicate Questions**: A question can only be added once per paper set. The database enforces this with a unique constraint on (paper_set_id, question_id). The UI also checks for duplicates and warns the user.

**Excludes Soft-Deleted Questions**: When checking for existing questions in a paper set, the system includes soft-deleted records — meaning even a trashed question counts as "already in the set" and cannot be re-added.

**Usage Logging on Add**: When a question is added, a record is created in the question usage log with the appropriate type: ONLINE_EXAM if the exam paper mode is online, OFFLINE_EXAM if offline.

**Usage Log Removal on Delete**: When a question is removed, the corresponding usage log record is also removed (soft-deleted for single delete, permanently deleted for bulk remove and force delete).

**Usage Log Restoration on Restore**: When a soft-deleted question is restored, its usage log is also restored.

**Blueprint Required for Bulk Save**: The bulk save flow requires a blueprint to be selected. The section_name for each question is taken from the selected blueprint's section_name.

**Default Negative Marks**: If not overridden, negative marks default to the exam paper's negative_marks setting (which itself defaults to 0).

**Compulsory Priority**: The compulsory flag is determined in this order: per-question override (highest priority), then the global request parameter, then the default (false).

**Session-Based Workflow**: The create screen uses browser sessionStorage to hold temporarily selected questions. Switching paper sets warns about unsaved session questions. Refresh or navigation may lose unsaved session data.

**Blueprint Section Limits**: Before adding a question to the session, the system checks that the blueprint section's question limit and marks limit are not exceeded. The Review tab also shows whether each blueprint section is complete.

**Effective Marks Calculation**: The system uses an effective_marks attribute on the model for marks calculations. This is the override_marks value if set, otherwise falls back to the question's default marks.

**Multi-Type Usage Logs**: The system handles usage log types with two naming patterns: "ONLINE_EXAM"/"OFFLINE_EXAM" (used in bulk operations and new code) and "Online Exam"/"Offline Exam" (used in single operations and older code). Both are checked during deletion and restoration.

---

## Validation & Error Messages

| When | What Is Checked | Error Message |
|------|----------------|---------------|
| Bulk save, no questions | Request has empty question_ids or questions_data | "No questions selected." |
| Bulk save | Total questions must match exam paper total_questions exactly | "Exact selection required. This exam paper requires exactly X questions. (Current total after addition would be: Y)" |
| Bulk save | Difficulty distribution rules not matched | "Questions with Type ID: X and Complexity ID: Y do not match any rule in the selected difficulty configuration." |
| Bulk save | Difficulty distribution max % exceeded (strict mode) | "Cannot add X questions of this type/complexity. Max allowed: X, Existing: X. Limit exceeded for complexity rule." |
| Bulk save | Total questions limit exceeded (during difficulty check) | "Cannot add questions. Total questions limit (X) would be exceeded." |
| Bulk save | Unused questions constraint violated | "This exam paper requires unused questions only. The following questions have been used before: X" |
| Bulk save | Authorised questions constraint violated | "This exam paper requires authorised questions only (for_quiz=1). The following questions are not authorised: X" |
| Bulk save | Scope limit exceeded | "Cannot add questions. Limit exceeded for Scope: X (Limit: X, Current: X, Adding: X)." |
| Single store | Total questions would exceed limit | "Cannot add question. Total questions limit (X) reached." |
| Single store | Total marks would exceed limit | "Cannot add question. Total marks limit (X) would be exceeded." |
| Single update | Total marks would exceed limit after update | "Cannot update question. Total marks limit (X) would be exceeded." |
| Inline marks update | Total marks would exceed limit | "Cannot update marks. Total marks limit (X) would be exceeded. Potential total: X" |
| Form request | Paper set required | "Paper set is required" |
| Form request | Question required | "Question is required" |
| Form request | Duplicate question | "This question is already added to this paper set" |
| Form request | Ordinal required | "Sequence number is required" |
| Form request | Marks required | "Marks are required" |
| Form request | Negative marks | "Marks cannot be negative" |
| UI: Add to session | Duplicate in session or database | Warning toast: "This question is already added to this paper set (Session or Database)." |
| UI: Add to session | No blueprint selected | Warning toast: "Please select an exam blueprint first." |
| UI: Add to session | Blueprint limit exceeded | Warning toast: "Blueprint limit for \"X\": Only Y questions allowed." |
| UI: Save | No blueprint selected | "Please select an exam blueprint before saving." |
| UI: Save | Blueprint section incomplete | "Section \"X\" is incomplete. Required: Y questions, but total is Z." |
| UI: Save | Blueprint marks mismatch | "Section \"X\" marks do not match. Required: Y marks, but total is Z." |
| UI: Save | Overall questions mismatch | "Overall Paper requires exactly X questions, but total is Y." |
| UI: Save | Overall marks mismatch | "Overall Paper requires exactly X marks, but total is Y." |

---

## Permissions

- `tenant.paper-set-question.viewAny` — View the list of all paper set questions
- `tenant.paper-set-question.view` — View a specific paper set question
- `tenant.paper-set-question.create` — Add questions to a paper set
- `tenant.paper-set-question.update` — Edit question properties
- `tenant.paper-set-question.delete` — Remove questions from a paper set
- `tenant.paper-set-question.restore` — Restore soft-deleted questions
- `tenant.paper-set-question.forceDelete` — Permanently delete questions
- `tenant.paper-set-question.status` — Toggle active/inactive status

---

## Related Screens

- **Exam Paper Set (lms_PaperSet)**: The parent screen where paper set variants are created. Questions are assigned to these sets.
- **Exam Paper**: The parent entity that defines question limits, marks limits, difficulty config, and scope requirements.
- **Exam Blueprint**: Defines section structure within exam papers. Each question links to a blueprint section.
- **Exam Scope**: Defines syllabus coverage limits that the system validates when adding questions.
- **Question Bank**: The source of all questions available for selection.

**Trashed Questions View**: The system provides a separate trash view showing all soft-deleted paper set questions. From there, admins can restore or permanently delete them.

**Edge Cases and Important Behaviours**:

1. **Changing Paper Set During Session**: If the admin has unsaved questions in the session and tries to select a different paper set, the system warns them that switching will discard their unsaved changes. They can confirm to discard or cancel to keep working.

2. **Blueprint Selection Required for Save**: The save button on the create screen is disabled until a blueprint is selected. Blueprint selection determines the section_name for all questions in the session.

3. **Session Persistence**: Questions added to a session persist in browser sessionStorage until the save completes or the admin explicitly clears them. Refreshing the page will clear the session, but navigating between tabs within the page preserves it.

4. **Already-Saved Questions Display**: On the create screen, the Review tab shows both session questions (new, unsaved) and already-saved database questions. Database questions are marked with a "Saved" badge and cannot be modified or re-added.

5. **Ordinal Auto-Numbering**: When questions are added to the session, ordinal values are auto-assigned starting from 1. When a question is removed from the session, remaining questions are re-numbered sequentially.

6. **Marks Editing in Session**: The admin can adjust marks for each session question in the Review tab. The validation tab updates in real time showing whether the marks match the required limits.

7. **Negative Marks Editing**: Each session question has a separate negative marks field. Default is 0, but the admin can set different values per question.

8. **Bulk Select and Add**: The admin can use "Select All" to check all search results and add them in one click. Previously added, already-existing, and disabled questions are excluded from selection.

9. **Resetting Filters**: The Reset Filters button clears all filter values while preserving the selected paper set and class context. It reloads sections and subject groups from the server.

10. **Difficulty Analysis Display**: On the Validation tab, when the exam paper has difficulty configuration active, the system shows a breakdown of session questions by complexity level with counts and percentages. If the config is ignored, a yellow warning is shown. If no config exists, an informational blue message is shown.

11. **Difficulty Rules Table**: The Validation tab also loads and displays all difficulty distribution rules in a table, showing each rule's question type, complexity level, Bloom level, cognitive skill, type specificity, and min/max percentages. Rules are fetched from the existing() AJAX endpoint.

12. **Save Confirmation Dialog**: Before saving, the system shows a SweetAlert confirmation dialog with the total question count and marks compared to requirements. Only after the admin confirms does the AJAX save proceed.

13. **Save Error Handling**: If the server-side validation fails during save (e.g., questions don't meet difficulty distribution), the system shows the exact error message from the server in a SweetAlert error dialog.

14. **Duplicate Questions Silently Skipped**: During bulk save, if some selected questions already exist in the paper set (checked via withTrashed to include soft-deleted ones), they are silently skipped. The success message only counts the newly inserted questions, not the skipped duplicates. No error is shown for duplicates — they are simply ignored.

15. **Usage Log Type Inconsistency**: The system uses two naming conventions for usage log types across different code paths. The bulk store and existing methods use "ONLINE_EXAM" and "OFFLINE_EXAM" (uppercase). The single destroy method checks for both uppercase and title-case variants ("Online Exam", "Offline Exam"). This means usage logs created by one path may not be cleaned up correctly by the other path, depending on the exact string matching.

16. **AJAX Dropdown Cascading Logic**: The filter sidebar has AJAX-driven dropdowns that cascade: selecting a section loads subject groups for that section + class; selecting a subject group loads subjects; selecting a subject loads lessons; selecting a lesson loads topics. Each change clears downstream dropdowns. Additionally, selecting a Bloom level loads cognitive skills, and selecting a cognitive skill loads type specificities.

17. **Blueprint Filtering by Exam Paper**: When a paper set is selected, the blueprint dropdown filters to show only blueprints belonging to the same exam paper. Blueprints from other exam papers are hidden. Changing the paper set changes the available blueprint options.

18. **Session vs Database Count Separation**: Validation displays separate counts for database-saved items and session items. For each blueprint section, the system shows "Saved: X" and "New: Y" counts in error messages, helping the admin understand which questions are already saved and which are pending.

19. **Form Request Data Preparation**: The PaperSetQuestionRequest sanitizes incoming data during prepareForValidation: is_compulsory and is_active are cast to boolean, ordinal defaults to 0 if empty, negative_marks defaults to 0.00, and section_name defaults to "Section A" if not provided.

14. **Success Message with Warnings**: If the save succeeds but difficulty distribution rules were violated (with ignore_difficulty_config enabled), the success message includes the difficulty warning text appended.
