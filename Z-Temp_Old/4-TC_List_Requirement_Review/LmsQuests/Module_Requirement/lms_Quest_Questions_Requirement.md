# Quest Questions — Business Requirements

## What This Screen Does

The Quest Questions screen is where teachers pick questions from the school's Question Bank and attach them to a Quest. Think of it like building a test paper: you have a big pool of questions (the Question Bank), and you need to choose the right ones for your Quest. You must make sure you do not go over the Quest's total marks or question count, and that you follow the difficulty rules (like a recipe saying "30% Easy, 50% Medium, 20% Hard") that were set up when the Quest was created.

This screen has three tabs that teachers move through:

1. **Selection Tab** — Search and find questions using filters like class, subject, topic, question type, difficulty level
2. **Review Tab** — See all selected questions, change their order, and remove unwanted ones
3. **Validation Tab** — Check if the selection meets all the Quest's rules before saving

The system also has an automatic "Difficulty Builder" that can suggest a balanced set of questions based on the Quest's difficulty rules.

**Important:** The Quest Questions screen uses a temporary workspace (stored in the browser's memory, not the database) to hold the teacher's selections before they are finally saved. This means the teacher can work across multiple tabs, change filters, search again, and come back to the Review tab — and their selections remain. Nothing is saved permanently until the teacher clicks "Save Quest to Database" on the Validation tab.

---

## When This Screen Is Used

- **Building a New Quest** — After a teacher creates a Quest (sets its name, duration, total marks, etc.), they come here to fill it with actual questions
- **Editing an Existing Quest** — If the Quest has not been attempted by any student yet, the teacher can add or remove questions
- **After Scopes Are Defined** — If the Quest has Scopes (specific topics/lessons that must be covered), the system checks that the selected questions match those Scopes
- **Bulk Operations** — Teachers can add or remove multiple questions at once using the search results
- **Single Question Management** — Teachers can also add, edit, or delete individual question links from the main Quest Question list page

---

## Who Can Access This Screen

- **Teacher** — Can create, view, and manage question links for Quests they have permission for
- **Head of Department** — Full access for their department's subjects
- **Academic Coordinator** — Full access for setting up Quest questions
- **Principal** — Read-only access to review question links

All access is controlled by permissions in the system (like `tenant.quest-question.create`, `tenant.quest-question.update`, etc.). The server checks these permissions every time an action happens.

**Note:** The authorization method inside the request file returns `true` unconditionally, meaning permission checking relies entirely on the controller-level permission gates. If a developer forgets to add a permission check in a controller, no security check runs.

---

## How This Screen Works — Logic Flow (Non-Technical)

### The Three-Tab Workflow

The teacher opens the Quest Questions section and first selects a Quest from a dropdown list. The system immediately shows the Quest's limits (like a container that can hold up to 20 questions worth 100 marks total) and locks the class to match the Quest.

**Tab 1 — Question Selection:** The teacher sees a two-panel layout. On the left is a filter panel with three collapsible sections: Academic Details (class, section, subject group, subject, lesson, topic), Question Properties (question type, difficulty, bloom level, etc.), and Usage Settings (only unused questions, only authorised questions, usage type). On the right is a search results area. The teacher applies filters and the system searches the Question Bank for matching questions that are published and active. They appear in a table with checkboxes. The teacher ticks the ones they want, and each ticked question is added to a temporary "shopping cart" stored in the browser's memory.

**Tab 2 — Review Selected:** The teacher sees all the questions they have ticked, displayed in a table. They can change the display order by editing numbers, change marks by typing new values, or remove questions using checkboxes and the "Remove Selected" button. All changes are immediate but still temporary.

**Tab 3 — Validation & Stats:** The system shows a live dashboard. It combines the questions already saved in the database (if any) with the questions in the temporary selection and shows:
- How many questions have been selected vs the limit (with a progress bar)
- How many marks have been accumulated vs the target
- Whether each difficulty rule is being met (e.g., "Easy MCQ: target 3-6 questions, currently have 4 — Pass")
- Whether each scope limit is being met (e.g., "Mechanics topic: limit 10, have 10 — Full")

**Save to Database:** When the teacher clicks "Save Quest to Database," the system sends all selected questions to the server. The server performs strict validation:
- The total question count must exactly match the Quest's limit
- The total marks must exactly match the Quest's target
- If the Quest requires unused questions, none of the selected questions can have been used before
- If the Quest requires authorised questions, all selected questions must be marked as authorised
- If the Quest has a difficulty configuration, each question must match a rule and no rule's maximum is exceeded
- If the Quest has scopes, no scope's limit can be exceeded

If all checks pass, everything is saved in a single go. If any check fails, nothing is saved and an error message is shown.

### The Single Question Add Workflow

The teacher can also add questions one at a time through a simpler form. They select a Quest and a single question, optionally set an order number and marks override, and click Save. The system checks four conditions: the question count will not exceed the limit, the marks will not exceed the limit, the question matches the difficulty configuration (if any), and the question has not been added to this Quest before. If OK, it saves and redirects.

### Marks Calculation Logic

When calculating total marks, the system always uses the effective marks for each question. Effective marks means: if a marks override is set, use that value; otherwise, use the question's default marks from the Question Bank.

- For single add: `current total marks + new question's effective marks ≤ total_marks`
- For edit: `current total marks - old effective marks + new effective marks ≤ total_marks`
- For marks update: same recalculate logic as edit
- For bulk add: the total resulting marks must exactly equal total_marks (the system uses a simple division: total_marks ÷ total_questions per question)

### Search Filter Logic

The question search endpoint applies filters in this order:
1. Start with all published and active questions
2. Apply performance category filters (recommendation type, category, priority) if provided
3. Apply academic filters (class, section, subject, lesson, topic)
4. Apply property filters (question type, complexity, bloom, cognitive skill, type specificity)
5. Apply usage filters: if "only unused" is checked (or the Quest requires it), exclude questions with existing Quest usage logs; if "only authorised" is checked (or the Quest requires it), filter to questions marked as authorised for assessment; also filter by usage type checkboxes
6. Exclude questions already added to the current Quest (even soft-deleted ones)
7. Apply text search on question title and content if provided
8. Limit results to the configured quantity (default 50)

---

## Validate Before Save

### Single Add — Four Checks After Validation

The system first checks the basic rules (Quest ID exists, Question ID exists, ordinal is a number, marks override is a number if provided, active flag is yes/no). Then it runs four additional checks in order:

**Check 1 — Question Count Limit:**
Count how many questions are already attached to this Quest (ignoring the current record if editing). If the count is already at or above the Quest's total_questions limit, reject: "You can add only {N} questions to this quest." If this check fails, the system stops here and skips checks 2-4.

**Check 2 — Marks Limit:**
Add up the effective marks of all existing questions (ignoring the current record if editing), then add the new question's effective marks. If the total exceeds the Quest's total_marks limit, reject: "Total marks limit exceeded. Max allowed: {N}. Current used: {N}"

**Check 3 — Difficulty Configuration Matching:**
If the Quest has a difficulty config attached and the "ignore difficulty config" flag is OFF, the system checks:
- Does the new question's type and complexity match any rule in the difficulty config?
- If no matching rule found, reject: "This question does not match quest difficulty configuration."
- If a matching rule is found, calculate the maximum questions allowed for that rule: `total_questions × max_percentage ÷ 100` (rounded up). Count how many existing questions already match that rule (ignoring the current record). If the count is already at or above the max, reject: "Max {N} questions allowed for this difficulty level."

**Check 4 — Duplicate Question:**
Check if the same question is already attached to this Quest (ignoring the current record if editing). If yes, reject: "This question is already added to the quest."

**Important:** If the Quest or Question is not found in the database (maybe it was deleted), all four checks are skipped entirely and the save proceeds without validation.

### Bulk Add — Strict Validation

When adding questions in bulk through the three-tab workflow, the system does its own validation (not using the single-add request):

1. **Exact Count and Marks Check:** The total number of questions after adding must exactly equal the Quest's total_questions. The total marks after adding must exactly equal the Quest's total_marks. The system calculates marks per question as `total_marks ÷ total_questions`. If either does not match exactly, the whole batch is rejected.

2. **Unused Questions Check:** If the Quest requires only unused questions, the system checks each selected question against the usage log. If any question has been used before in another Quest, the batch is rejected (listing up to 3 example titles).

3. **Authorised Questions Check:** If the Quest requires only authorised questions, the system checks each selected question has the authorised flag turned on. If any is not authorised, the batch is rejected (listing up to 3 example titles).

4. **Difficulty Distribution Check:** If the Quest has a difficulty config and the "ignore" flag is OFF, the system groups the new questions by type + complexity and checks each group against a matching rule's maximum percentage. For complex rules (with optional bloom/cognitive/type-specificity fields), each question is matched individually. If a question does not match any rule, or if adding would exceed a rule's max, the batch is rejected.

5. **Scope Check:** If the Quest has scopes defined, the system checks each scope's target count against the existing + new questions matching that scope's type/lesson/topic. If any scope would be exceeded, the batch is rejected.

6. **Transaction:** If all checks pass, each question is saved individually in a single database transaction. If any save fails, everything is rolled back (no partial saves).

---

## Business Rules and Conditions

### Rule 1: Question Count Limit
A Quest has a `total_questions` limit set during creation. The system blocks adding a question if it would exceed this limit. This applies to both single add and bulk add.

### Rule 2: Marks Limit
A Quest has a `total_marks` limit. The system calculates the current total marks by checking each question's effective marks (override if set, otherwise the question's default marks from the bank), and blocks adding a question if the new total would exceed the limit.

### Rule 3: No Duplicate Questions
The same question cannot be added to the same Quest twice. If a teacher tries to add a question that is already in the Quest, the system rejects it. This check also considers soft-deleted question links (they still count as duplicates).

### Rule 4: Difficulty Configuration Matching
If the Quest has a difficulty config (and "ignore difficulty config" is OFF), every added question must match a rule in that config. A rule is like a recipe instruction — for example: "Allow up to 30% of questions to be Easy MCQs." A rule matches by question type (e.g., MCQ) and complexity (e.g., Easy), and optionally by bloom taxonomy, cognitive skill, or type specificity. Adding a question must not push that rule's count above its maximum allowance. The system calculates max allowed as: `total_questions × max_percentage ÷ 100` (rounded up).

### Rule 5: Scope Limits
If the Quest has Scopes (e.g., "10 MCQ questions from Mechanics topic"), adding a question must not exceed any Scope's target count. The system checks existing questions + new questions against each Scope.

### Rule 6: Unused Questions Constraint
If the Quest has `only_unused_questions = true`, the system rejects any question that already has a usage log entry for 'QUEST' type. This prevents reusing questions across multiple Quests.

### Rule 7: Authorised Questions Constraint
If the Quest has `only_authorised_questions = true`, all added questions must be flagged as authorised for assessment in the Question Bank.

### Rule 8: Bulk Add Exact Match
When adding questions in bulk, the system requires that the total count and total marks EXACTLY match the Quest's configured values. For example, if the Quest has total_questions = 20 and total_marks = 100, the bulk add will only succeed if after adding, the count is exactly 20 and marks are exactly 100. If the Quest already has 5 questions (25 marks), the teacher must add exactly 15 more questions (75 marks) to match. This is stricter than single add (which only checks "not exceeding").

### Rule 9: Usage Tracking
Every time a question is added to a Quest, it is logged in the question usage log with the question's ID, usage type = 'QUEST', the Quest's ID, and a timestamp. When a question is removed, the usage log entry is also removed (soft-deleted for single removal, permanently deleted for bulk removal).

### Rule 10: Protection Against Modification (Usage Check)
If students have already attempted the Quest, the system blocks editing the question link, deleting it, restoring it, and force-deleting it. This preserves the integrity of existing student attempt data.

### Rule 11: Session-Based Temporary Selection
All questions selected in the three-tab workflow are held in the browser's memory (sessionStorage), not the database. This means the teacher can close the page and come back (within the same browser session) and their selections remain. If the teacher selects a different Quest, the previous selections are cleared. Nothing is saved permanently until the teacher clicks "Save Quest to Database."

### Rule 12: Only Published Questions Can Be Selected
The question search only returns questions with status = 'PUBLISHED' and is_active = 1. Draft or inactive questions are hidden from the search results.

---

## Business Rules Summary (Quick Reference)

| Rule | What It Means |
|------|--------------|
| Question Count Limit | Cannot add more questions than the Quest's total_questions |
| Marks Limit | Cannot exceed the Quest's total_marks |
| No Duplicates | Same question cannot be added twice to the same Quest |
| Difficulty Config | Each question must match a rule in the difficulty config (Easy/Medium/Hard recipe) |
| Scope Limits | Cannot exceed any scope's target question count |
| Unused Only | Questions used in other Quests cannot be added |
| Authorised Only | Questions must be flagged as authorised for assessment |
| Bulk Exact Match | In bulk add, questions and marks must exactly match the Quest's limits |
| Usage Tracking | Adding/removing questions updates the usage log |
| Modification Lock | Once students attempt, question links cannot be changed |

---

## Validate Before Save — Error Messages

| Scenario | Error Message |
|----------|--------------|
| Question count exceeded (single add) | "You can add only {N} questions to this quest." |
| Marks limit exceeded (single add) | "Total marks limit exceeded. Max allowed: {N}. Current used: {N}" |
| No matching difficulty rule (single add) | "This question does not match quest difficulty configuration." |
| Difficulty rule max exceeded (single add) | "Max {N} questions allowed for this difficulty level." |
| Duplicate question (single add) | "This question is already added to the quest." |
| Bulk add exact match failure | "Exact match required. Questions: {N}/{N}, Marks: {N}/{N}" |
| Bulk add unused question found | "This quest requires unused questions only. The following questions have been used before: {titles}..." |
| Bulk add unauthorised question found | "This quest requires authorised questions only. The following questions are not authorised: {titles}..." |
| Bulk add no matching difficulty rule | "Questions with Type ID: {N} and Complexity ID: {N} do not match any rule in the selected difficulty configuration." |
| Bulk add difficulty limit exceeded | "Cannot add {N} questions of this type/complexity. Max allowed: {N}. Limit exceeded for complexity rule." |
| Bulk add scope limit exceeded | "Cannot add questions. Limit exceeded for Scope: {typeName} (Limit: {N})." |
| Edit blocked by usage | "Cannot edit this quest question because students have already started attempts." |
| Delete blocked by usage | "Cannot delete this quest question because students have already started attempts." |
| Marks update exceeds limit (AJAX) | "Cannot update marks. Total marks limit ({N}) would be exceeded. Potential total: {N}" |
| No questions selected (bulk add) | "No questions selected." |

---

## Success Scenarios

- A teacher creates a new Quest with total_questions = 20, total_marks = 100, attaches a difficulty config. They use the 3-tab workflow to search for 20 MCQs from the Question Bank, verify the validation tab shows green across difficulty rules and scope limits, and save all 20 questions in one click. Each question gets the correct order number, marks from the difficulty rules, and a usage log entry.

- A teacher wants to add one extra question to an existing Quest that has 5 questions (25 marks so far, 100 marks total limit). They use the single add form, select the Quest, pick a question worth 5 marks, enter order number 6, and save. The system checks that 6 ≤ 20 (count OK), 30 ≤ 100 (marks OK), the question matches the difficulty config, and it is not a duplicate — all pass, and the question is added.

- A teacher edits a question link to change the marks from 5 to 8. The system recalculates: previous total was 50 marks, removing 5 leaves 45, adding 8 makes 53. Since 53 ≤ 100, the update succeeds.

- A teacher soft-deletes a question link from a Quest that has no student attempts. The question link and its usage log entry are both soft-deleted. Later, the teacher restores it from the trash — both records are restored and the question reappears in the Quest.

---

## Failure Scenarios

- A teacher tries to add 21 questions to a Quest with total_questions = 20. The system blocks with "You can add only 20 questions to this quest."

- A teacher tries to bulk-add 15 questions (worth 60 marks) to a Quest that already has 5 questions (worth 25 marks). The Quest has total_questions = 20 and total_marks = 100. After adding, the count would be 20 (exact match) but marks would be 85 (not 100). The system rejects the entire batch.

- A teacher tries to edit a question link in a Quest that 30 students have already attempted. The usage check fires and blocks editing: "Cannot edit this quest question because students have already started attempts."

- A teacher tries to delete a question link. The system checks usage and finds one student has started an attempt. The delete is blocked.

- A teacher selects a question whose type + complexity does not match any rule in the Quest's difficulty configuration. The single add fails with "This question does not match quest difficulty configuration."

---

## Example Scenario

Mrs. Sharma, a Grade 10 Science teacher, has created a Quest titled "Physics Challenge" with:
- Total Questions: 20
- Total Marks: 100
- Difficulty Config: Standard Balanced (30% Easy, 50% Medium, 20% Hard)
- Scopes: 10 questions from "Mechanics" topic, 10 from "Optics" topic

She opens the Quest Questions screen and:
1. Selects "Physics Challenge" from the Quest dropdown
2. The header shows: 0/20 Questions, 0/100 Marks, and the class is auto-locked
3. In the Selection tab, she expands Academic Filters and selects: Subject = Science (auto-filled from the Quest), Lesson = Mechanics
4. She clicks "Apply Filters" — the system searches published questions matching these criteria
5. She sees 15 matching questions in the results panel
6. She ticks 10 questions — they move into the temporary selection
7. She switches to Tab 2 (Review), sees the 10 questions with their order and marks
8. She adjusts the marks for one question from 5 to 6 using the inline editor
9. She goes back to Tab 1, changes the lesson filter to Optics, applies filters, and selects 10 more questions
10. She switches to Tab 3 (Validation):
    - Progress bar shows 20/20 questions (100%)
    - Total marks show 100/100
    - Difficulty rules: 6 Easy (30% ✓), 10 Medium (50% ✓), 4 Hard (20% ✓)
    - Scope limits: Mechanics 10/10 (Full), Optics 10/10 (Full)
11. She clicks "Save Quest to Database"
12. The system validates everything server-side and saves all 20 questions in one go

Later, Mrs. Sharma realizes one question has the wrong marks. Since no student has attempted the Quest yet, she edits the question link and changes the marks override. The system checks that the new total does not exceed 100 marks.

---

## Related Screens

- **Quest Creation** — Where the Quest master record is created with total_questions, total_marks, and difficulty config
- **Quest Scopes** — Where topic/lesson scope limits are defined
- **Difficulty Config** — Where the difficulty distribution rules (Easy/Medium/Hard percentages) are set up
- **Quest Allocation** — After questions are added, the Quest is allocated to students
- **Quest Dashboard** — Where teachers can view Quest statistics after questions are added and allocated
- **Student Portal (Quest Attempt)** — Where students see the questions (in order) and attempt the Quest

---

---

## Dependencies module and tables

| Module | Tables |
|--------|--------|
| LmsQuests Core | `lms_quest_questions` (primary table; stores quest_id, question_id, ordinal, marks_override, is_active; supports soft-deletes) |
| LmsQuests Parent | `lms_quests` (holds total_questions, total_marks, difficulty_config_id, ignore_difficulty_config, only_unused_questions, only_authorised_questions) |
| LmsQuests Scopes | `lms_quest_scopes` (used for scope validation in bulk add) |
| Question Bank | `qns_questions_bank` (the pool of questions; fields include marks, question_type_id, complexity_level_id, for_quiz, status, class_id, subject_id) |
| Question Usage Log | `qns_question_usage_log` (tracks which questions have been used in which Quest) |
| Difficulty Config | `lms_difficulty_distribution_configs` and `lms_difficulty_distribution_details` (the recipe rules: question_type_id, complexity_level_id, min_percentage, max_percentage, marks_per_question) |
| Syllabus (Filters) | `sch_classes`, `sch_subjects`, `sch_sections`, `sch_subject_groups`, `slb_lessons`, `slb_topics`, `slb_question_types`, `slb_complexity_levels`, `slb_bloom_taxonomies`, `slb_cognitive_skills`, `slb_ques_type_specificities`, `slb_performance_categories`, `qns_question_tags` |
| Student Portal (Usage Check) | `sp_quiz_quest_attempts` (checked to see if any student has attempted the Quest; blocks modification if attempts exist) |
| Prime Core | `prime_dropdowns` (for recommendation type filters) |
