# Quiz Questions — Business Requirements

## What This Screen Does

The Quiz Questions screen manages the junction between quizzes and the Question Bank. It provides three distinct workflows:

1. **Manual Single Add** — Add one question at a time via a create form
2. **Bulk Add via Search** — Search/filter questions from the Question Bank and add multiple at once
3. **Difficulty Builder** — Add questions to a quiz while validating against the quiz's assigned difficulty distribution config

The screen also supports: reordering via ordinal updates, marks override per question, bulk removal, and usage logging.

---

## When This Screen Is Used

- After Creating a Quiz to populate it with questions
- Quiz Revision to add, remove, or reorder questions before publishing
- Difficulty Balancing when the teacher wants the system to suggest questions that match the difficulty config
- Marks Adjustment when overriding per-question marks for a specific quiz

## Default Data Load

The "Quiz Questions" tab loads a paginated list via `QuizQueryService@quizQuestionsQuery()`. Each row shows: quiz title, question content, ordinal, marks override, active status, and action buttons. Pagination is 10 rows per page with search and quiz_id filters.

The view loads all active quizzes and all active questions for dropdown selectors.

---

## Key Fields at a Glance

**Quiz Question Junction (`lms_quiz_questions`)**
- `quiz_id` — FK to `lms_quizzes.id`
- `question_id` — FK to `qns_questions_bank.id`
- `ordinal` — Sequence position (auto-assigned, can be manually adjusted)
- `marks_override` — Optional override of the question's default marks (null = use question default)
- `is_active` — Soft-enable/disable toggle

**Question Bank Filters (Search/AJAX)**
- Academic: Class, Section, Subject, Topic (via lesson or direct)
- Taxonomy: Question Type, Complexity Level, Bloom Taxonomy, Cognitive Skill, Question Type Specificity
- Performance: Performance Category, Recommendation Type, Priority
- Usage: Only Unused, Only Authorised (for_quiz), For Quiz/Exam/Quest flags
- Quiz Context: Topic Scope (auto-filtered if quiz has scope_topic_id)
- Text Search: `search_text` on ques_title / question_content
- Tags: Filter by question tag IDs
- Default Limit: 50 questions per search

---

## Complete Validation Flow Before Saving

This section explains every single check the system performs — in plain language — before it saves a question to a quiz. Understanding these checks is critical for creating question papers because the system will BLOCK or ALLOW your question selection based on rules you set on the quiz.

---

### [A] Adding ONE Question at a Time (Single Add)

When a teacher picks ONE question from the dropdown and clicks Save, the system runs these checks in order. If ANY check fails, the process stops immediately and shows an error.

---

**Step 1 — Permission Check**
The system first asks: "Does this user have permission to add questions to quizzes?"
- If No → Access Denied (user will never see this screen)
- If Yes → Move to Step 2

**Step 2 — Basic Field Validation**
The system checks: "Did the user fill in the required fields correctly?"
- `quiz_id`: Must select a quiz that exists in the database
- `question_id`: Must select a question that exists in the question bank
- `marks_override`: Optional — if filled, must be a positive number (like 2, 5, 10)
- `is_active`: Optional — defaults to active
If anything is wrong → Show validation error and stop

**Step 3 — Duplicate Check**
The system asks: "Is this question already in this quiz?"
- Looks at the quiz's existing question list
- If the same question is found → BLOCK with error: *"This question already exists in the quiz."*
- **Why?** A quiz cannot have the same question twice

**Step 4 — "Only Unused Questions" Check**
The quiz might have a setting: **"Only Unused Questions"** (only_unused_questions = Yes)
- If Yes, the system checks: "Has this question been used in ANY other quiz before?"
- It looks at the Question Usage Log to see if this question has been used in a QUIZ before
- If the question WAS used before → BLOCK with error: *"This quiz requires unused questions only."*
- **Why?** Some quizzes (like diagnostic tests) need fresh questions that students haven't seen

**Step 5 — "Only Authorised Questions" Check**
The quiz might have a setting: **"Only Authorised Questions"** (only_authorised_questions = Yes)
- If Yes, the system checks: "Is this question marked as 'for_quiz'?"
- Each question in the bank has a flag called `for_quiz`. If `for_quiz = 0`, the question was NOT approved for quiz use
- If not authorised → BLOCK with error: *"This quiz requires authorised questions only (for_quiz=1)."*
- **Why?** Schools may restrict which questions are allowed in quizzes vs exams

**Step 6 — Topic Scope Check**
The quiz might be scoped to a specific topic (scope_topic_id is set)
- The system checks: "Does this question belong to the quiz's selected topic?"
- Compares: question's topic_id vs quiz's scope_topic_id
- If they don't match → BLOCK with error: *"This question is out of the quiz topic scope."*
- **Why?** If the quiz is about "Velocity", questions from "Photosynthesis" shouldn't appear

**Step 7 — Total Questions Limit Check**
The quiz has a setting: **Total Questions** (e.g., 10)
- The system asks: "If I add this 1 question, will the total EXCEED the limit?"
- Counts existing questions in the quiz
- If (existing + 1) > total_questions limit → BLOCK with error: *"Cannot add question. Total questions limit (10) reached."*
- **Why?** The question paper should not have more questions than planned

**Step 8 — Total Marks Limit Check**
The quiz has a setting: **Total Marks** (e.g., 20)
- The system asks: "If I add this question's marks, will the total marks EXCEED the limit?"
- Calculates: current total marks + this question's marks (or marks_override if set)
- If new total > total_marks limit → BLOCK with error: *"Cannot add question. Total marks limit (20) would be exceeded."*
- **Why?** The question paper's total marks must not exceed what was planned

**Step 9 — All Checks Passed!**
The system:
- Creates the quiz-question link
- Logs this question as "used" in the Question Usage Log (so other "unused only" quizzes know it's been used)
- Records the activity (who added which question to which quiz)

**Step 10 — Done**
Redirects back to Quiz Management with success message: "Question added successfully."

---

### [B] Adding MULTIPLE Questions at Once (Bulk Add via Search)

This is the main flow for creating question papers. The teacher searches the question bank, selects several questions, and clicks "Add Selected." This flow has the **MOST VALIDATIONS** including the critical **Difficulty Distribution Validation**.

---

**Step 1 — Permission Check** (same as Single Add)
- If user doesn't have permission → Access Denied

**Step 2 — Basic Validation**
- `quiz_id`: Must select a valid quiz
- `questions_data`: Array of selected questions with their IDs

**Step 3 — Read the Selected Questions**
System reads the list of question IDs the teacher selected

**Step 4 — Empty Check**
- If teacher clicked "Add Selected" but didn't select any questions → BLOCK: *"No questions selected."*

---

### Step 5 — THE EXACT MATCH RULE (Critical - Question Paper Creation)

This is the most important check in bulk add. The system requires that the TOTAL number of questions after adding MUST EXACTLY MATCH the quiz's `total_questions` setting. Same for total marks.

**How it works — Simple Example:**

> Ravi creates a quiz and sets: **Total Questions = 10, Total Marks = 20**
> Ravi already added 3 questions earlier
> Now Ravi goes to Bulk Add and selects 7 questions from the search
> System calculates: 3 existing + 7 new = 10 total ⟹ 10 matches total_questions ✓
> System calculates: 10 questions × 2 marks each = 20 total marks ⟹ 20 matches total_marks ✓
> **PASS → Questions are added**

**How it can fail — Example:**

> Ravi creates a quiz with Total Questions = 10, Total Marks = 20
> 3 questions already exist
> Ravi selects only 5 questions in bulk add
> System calculates: 3 + 5 = 8 ≠ 10 ⟹ **BLOCKED**
> Error: *"Exact match required. Questions: 8/10, Marks: 16/20"*
> Ravi must select EXACTLY 7 questions (not 5, not 9)

**Why does this rule exist?**
Because the quiz was planned for exactly 10 questions and 20 marks. The Bulk Add flow is meant to fill ALL remaining slots at once. If you want to add questions one by one, use the Single Add flow (which only checks "not exceed" not "exact match").

**What about marks?**
The system divides total_marks by total_questions to get per-question marks:
> 20 marks ÷ 10 questions = **2 marks per question**
> If existing 3 questions have 6 marks total, new 7 questions should have 14 marks
> 6 + 14 = 20 ✓ If this doesn't match exactly → BLOCKED

---

### Step 6 — Fetch the Selected Questions

System loads the full details of all selected questions from the Question Bank (their type, complexity, topic, marks, etc.)

---

### Step 7 — "Only Unused Questions" Check

If the quiz has this setting ON, the system checks EVERY selected question:
- Has this question been used in ANY quiz before? (checks Question Usage Log)
- If ANY of the selected questions were used before → BLOCK with list of their names
- Error: *"This quiz requires unused questions only. The following questions have been used before: [Question 1], [Question 2]..."*

**Real Example:**
> Quiz "Diagnostic Test 2026" has only_unused_questions = Yes
> Teacher selects 10 questions. 3 of them were used in last year's quiz
> System blocks with: "This quiz requires unused questions only. The following questions have been used before: Velocity Basics, Force Diagrams, Newton's Laws"
> Teacher must remove those 3 and pick unused ones

---

### Step 8 — "Only Authorised Questions" Check

If the quiz has this setting ON, the system checks:
- Is EVERY selected question marked as `for_quiz = 1`?
- If ANY question has `for_quiz = 0` → BLOCK with list
- Error: *"This quiz requires authorised questions only (for_quiz=1). The following questions are not authorised: [names]"*

**Real Example:**
> Teacher selects a question that was created for exam use only (for_quiz = 0)
> System blocks and lists it

---

### Step 9 — Topic Scope Check

If the quiz is scoped to a specific topic (e.g., "Velocity"):
- Does EVERY selected question belong to that topic?
- If ANY question is from a different topic → BLOCK with list
- Error: *"This quiz is scoped to topic: Velocity. The following questions are out of scope: [names]"*

---

### Step 10 — MCQ-Only Check (Hardcoded Rule)

The system ALWAYS checks: "Are ALL selected questions MCQ type?"
- Allowed types: **MCQ_SINGLE** (single correct answer) and **MCQ_MULTI** (multiple correct answers)
- If ANY selected question is SHORT_ANSWER, LONG_ANSWER, FILL_IN_THE_BLANKS, etc. → BLOCK
- Error: *"Only MCQ questions are allowed in the quiz. The following questions are not MCQ type: [names]"*

**Why?** The quiz module currently supports only MCQ-type questions for auto-evaluation. Subjective questions require manual grading which is not yet supported in this flow.

---

### Step 11 — DIFFICULTY DISTRIBUTION VALIDATION (THE MOST IMPORTANT CHECK)

This is the most complex validation. It only runs if the quiz has a **Difficulty Config** assigned.

**What is a Difficulty Config?**
A Difficulty Config is a set of rules that define how many Easy, Medium, and Difficult questions should be in the quiz. For example:
- Easy questions: Min 30%, Max 40% of total
- Medium questions: Min 30%, Max 40% of total
- Difficult questions: Min 20%, Max 30% of total

**Two Ways This Validation Works:**

---

#### SIMPLE MODE — Rules have NO Taxonomy Fields

Rules just group by (Question Type × Complexity Level):

Example Config Rules:
| Rule # | Question Type | Complexity | Min % | Max % |
|--------|---------------|------------|-------|-------|
| 1 | MCQ_SINGLE | EASY | 30% | 40% |
| 2 | MCQ_SINGLE | MEDIUM | 30% | 40% |
| 3 | MCQ_SINGLE | DIFFICULT | 20% | 30% |

When teacher adds questions, the system:
1. Groups the new questions by (type × complexity)
2. For each group, finds the matching rule
3. Calculates the max allowed: **ceil(total_questions × max_percentage ÷ 100)**
4. Checks: existing_count in this group + new_count > max_allowed?

**Real Example — How Calculation Works:**

> Quiz "Science Test" has total_questions = 10
> Difficulty Config "Balanced" has: Easy max = 40%, Medium max = 40%, Difficult max = 20%
>
> **Step A:** System calculates max allowed for each level:
> - Easy: ceil(10 × 40 ÷ 100) = ceil(4.0) = **max 4 questions**
> - Medium: ceil(10 × 40 ÷ 100) = ceil(4.0) = **max 4 questions**
> - Difficult: ceil(10 × 20 ÷ 100) = ceil(2.0) = **max 2 questions**
>
> **Step B:** Quiz already has:
> - 2 Easy questions (existing)
> - 2 Medium questions (existing)
> - 1 Difficult question (existing)
>
> **Step C:** Teacher tries to add 3 more Easy MCQ_SINGLE questions
> - Existing Easy: 2, New Easy: 3
> - Total would be: 2 + 3 = **5**
> - Max allowed: **4**
> - 5 > 4 → **BLOCKED!**
> - Error: *"Cannot add 3 questions. Max allowed: 4, Existing: 2. Limit exceeded for rule: MCQ_SINGLE - Easy"*
>
> **Step D:** Teacher instead tries to add 2 Easy and 1 Medium
> - Easy: 2 existing + 2 new = 4. Max 4. 4 ≤ 4 ✓ PASS
> - Medium: 2 existing + 1 new = 3. Max 4. 3 ≤ 4 ✓ PASS
> - Questions added successfully!

---

#### COMPLEX MODE — Rules HAVE Taxonomy Fields

Rules include optional fields: Bloom's Taxonomy, Cognitive Skill, Question Type Specificity:
| Rule | Q Type | Complexity | Bloom | Cognitive Skill | Min% | Max% |
|------|--------|------------|-------|-----------------|------|------|
| 1 | MCQ_SINGLE | EASY | Remember | Recall | 15% | 25% |
| 2 | MCQ_SINGLE | EASY | Understand | Explain | 15% | 25% |
| 3 | MCQ_SINGLE | MEDIUM | Apply | Solve | 20% | 30% |

The system matches each question against rules more strictly:
- Question Type + Complexity + Bloom + Cognitive Skill + Specificity must ALL match
- **Null fields act as wildcards** — if a rule doesn't specify Bloom, any Bloom level matches

**Real Example — Complex Matching:**

> Rule says: MCQ_SINGLE + EASY + Bloom=Remember + Cognitive Skill=Recall
> Question has: MCQ_SINGLE + EASY + Bloom=Remember + Cognitive Skill=Recall
> **MATCH ✓**
>
> Rule says: MCQ_SINGLE + MEDIUM + (Bloom=null) + (Cog Skill=null)
> Question has: MCQ_SINGLE + MEDIUM + Bloom=Apply + Cog Skill=Solve
> **MATCH ✓** (because null fields act as wildcards — they match ANY value)
>
> Rule says: MCQ_SINGLE + EASY + Bloom=Understand + Cog Skill=Explain
> Question has: MCQ_SINGLE + EASY + Bloom=Remember + Cog Skill=Recall
> **NO MATCH ✗** (Bloom and Cog Skill don't match)
> Error: *"Question with Type ID: 1 and Complexity ID: 1 does not match any rule in the selected difficulty configuration."*

---

#### What Happens When Validation Fails?

The quiz has a setting: **Ignore Difficulty Config** (ignore_difficulty_config)

| ignore_difficulty_config | Behavior |
|--------------------------|----------|
| **NO (false)** — Strict Mode | Question addition is **BLOCKED**. Error message shown. Teacher must adjust selection. |
| **YES (true)** — Warning Mode | Question addition is **ALLOWED** but a **WARNING** message is shown: "Question added. However, difficulty rule was violated: [message]" |

**Real Example — Strict vs Warning:**

> Ravi creates quiz, selects "Balanced" difficulty config
> He sets **Ignore Difficulty Config = NO** (strict mode)
> Tries to add 5 Easy questions but max is 4
> **BLOCKED** — must remove 1 Easy question

> Priya creates quiz, selects same config
> She sets **Ignore Difficulty Config = YES** (warning mode)
> Tries to add 5 Easy questions but max is 4
> **ALLOWED WITH WARNING** — questions added but system shows warning

---

### Step 12 — Setting Marks for Each Question

For each question being added, the system decides its marks:
1. If teacher provided a **marks_override** for this question → use that
2. If difficulty rules exist → look up the rule's `marks_per_question` for matching rule
3. Otherwise → marks = 0 (needs manual update later)

**Real Example — Marks from Difficulty Rules:**
> Difficulty Config says: MCQ_SINGLE + EASY → marks_per_question = 2
> MCQ_SINGLE + MEDIUM → marks_per_question = 3
> MCQ_SINGLE + DIFFICULT → marks_per_question = 5
>
> Teacher adds 4 Easy, 4 Medium, 2 Difficult questions
> System auto-assigns: 4×2 + 4×3 + 2×5 = 8 + 12 + 10 = **30 total marks**

---

### Step 13 — Final Duplicate Check + Save

Before saving EACH question, the system double-checks:
- Is this question already in this quiz? (duplicate guard)
- If not → create the QuizQuestion record with ordinal and marks
- Create a Question Usage Log entry marking this question as "used in a QUIZ"

---

### Step 14 — Response

- **Success:** "10 questions added successfully."
- **Success with Warning:** "10 questions added successfully. However, difficulty rule was violated: [message]"
- **Failure:** Error message explaining what was blocked and why

---

### [C] Difficulty Distribution Validation — Full Technical Details

This section explains exactly how the system's `validateDifficultyDistribution()` function works internally for developers and testers.

**Purpose:** Ensures the questions being added to a quiz do not exceed the maximum percentage allowed by the difficulty config rules, considering questions already in the quiz.

**Calculation Base:**
```
$calculationBase = $quiz->total_questions (if > 0) ?? current total count of questions in quiz
```
The system uses the quiz's planned `total_questions` if set. Otherwise, it uses the current count.

**Max Allowed Formula:**
```
$maxAllowed = ceil($calculationBase × rule.max_percentage ÷ 100)
```
- Uses `ceil()` — rounds UP. So if max is 3.1, max allowed is 4.
- This ensures at least 1 question if percentage > 0.

**Min Allowed Formula** (calculated but not enforced in current code):
```
$minAllowed = floor($calculationBase × rule.min_percentage ÷ 100)
```

**Validation Logic for Simple Mode:**
```
For each unique (question_type_id, complexity_level_id) combination among new questions:

1. Find matching rule where:
   rule.question_type_id = new_question.question_type_id
   AND rule.complexity_level_id = new_question.complexity_level_id

2. IF no matching rule found → FAIL
   Error: "Questions with Type ID: X and Complexity ID: Y do not match any rule"

3. Count EXISTING questions in the quiz matching this rule

4. Count NEW questions in this group

5. IF (existing_count + new_count) > max_allowed → FAIL
   Error: "Cannot add N questions. Max allowed: M, Existing: E. Limit exceeded for rule: [Type - Complexity]"

6. IF pass → continue to next group
```

**Validation Logic for Complex Mode (with Taxonomy):**
```
For each new question:

1. Find matching rule via findDifficultyRuleMatch():
   rule.question_type_id = question.question_type_id
   AND rule.complexity_level_id = question.complexity_level_id
   AND (rule.bloom_id IS NULL OR rule.bloom_id = question.bloom_id)
   AND (rule.cognitive_skill_id IS NULL OR rule.cognitive_skill_id = question.cognitive_skill_id)
   AND (rule.ques_type_specificity_id IS NULL OR rule.ques_type_specificity_id = question.ques_type_specificity_id)

2. IF no matching rule → FAIL
   Error: "Question with Type ID: X and Complexity ID: Y does not match any rule"

3. Group all new questions by the matched rule's ID

4. For each rule group:
   max_allowed = ceil(calculationBase × rule.max_percentage ÷ 100)
   IF (existing_count + group_count) > max_allowed → FAIL
```

### [D] Bulk Remove (`bulkDestroy()`)

```
Step 1: Gate → tenant.quiz-question.delete
Step 2: Validate → quiz_id required, question_ids required|array
Step 3: Transaction:
    a. Find QuizQuestion records matching (quiz_id + question_ids)
    b. FORCE DELETE associated QuestionUsageLogs
       → WHERE context_id = quiz_id, question_bank_id IN question_ids, usage_type = 'QUIZ'
    c. FORCE DELETE QuizQuestion records
    d. recalculateOrdinals(quiz_id) → re-sequence remaining questions 1,2,3...
    e. activityLog
Step 4: Return success
```

### [E] Update Ordinal (`updateOrdinal()`) — AJAX

```
Step 1: Validate → quiz_question_id required|exists, ordinal required|integer|min:1
Step 2: Find QuizQuestion record
Step 3: IF $oldOrdinal !== $newOrdinal:
    → If moving DOWN ($newOrdinal > $oldOrdinal):
        → DECREMENT ordinal for questions between old+1 and new (shift up)
    → If moving UP ($newOrdinal < $oldOrdinal):
        → INCREMENT ordinal for questions between new and old-1 (shift down)
    → Update the moved question to $newOrdinal
Step 4: Return success
```

### [F] Update Marks (`updateMarks()`) — AJAX

```
Step 1: Validate → quiz_question_id required|exists, marks_override nullable|numeric|min:0
Step 2: Find QuizQuestion record
Step 3: If marks_override is empty or same as original question marks → set to null
Step 4: Calculate potential new total marks:
    $currentTotal = SUM of effective_marks for all questions in quiz
    $potentialNewTotal = $currentTotal - $oldMarks + $newMarks
Step 5: IF $quiz->total_marks > 0 AND $potentialNewTotal > $quiz->total_marks:
    → return 422: "Cannot update marks. Total marks limit (X) would be exceeded. Potential total: Y"
Step 6: Update marks_override
Step 7: Return success with new marks value
```

---

## Search Question Filters (`search()` AJAX)

The search endpoint restricts results to **PUBLISHED + ACTIVE** questions from the Question Bank. Default filters applied automatically:

| Filter | Condition | Behavior |
|--------|-----------|----------|
| `is_active` | Always | `WHERE is_active = 1 AND status = 'PUBLISHED'` |
| Question Type (default) | Always | **Restricted to MCQ_SINGLE + MCQ_MULTI only** (hardcoded, not overridable via filter) |
| `recommendation_type` | If provided | Filters via `performanceCategories` relation |
| `performance_category` | If provided | Filters via `performanceCategories` relation |
| `priority` | If provided | Filters via `performanceCategories` relation |
| `class_id` | If provided | `WHERE class_id = X` |
| `section_id` | If provided | `WHERE selected_section_id = X` |
| `subject_id` | If provided | `WHERE subject_id = X` |
| `tag_ids` | If provided | Filters via `tags` relation |
| `topic_id` | If provided | `WHERE topic_id = X OR questionTopics.topic_id = X` |
| `complexity_level_id` | If provided | `WHERE complexity_level_id = X` |
| `bloom_id` / `cognitive_skill_id` / `question_type_specificity_id` | If provided | Direct WHERE |
| `only_unused` | Boolean | Excludes questions already used in QUIZ type (checks `qns_question_usage_log`) — can be forced by quiz's `only_unused_questions` flag |
| `only_authorised` | Boolean | `WHERE for_quiz = 1` — can be forced by quiz's `only_authorised_questions` flag |
| `for_quiz` / `for_exam` / `for_quest` | Boolean | Direct WHERE on usage flags |
| Quiz Context | If `quiz_id` | Auto-excludes questions already linked to this quiz |
| Topic Scope | If quiz has `scope_topic_id` | Auto-filters `WHERE topic_id = quiz.scope_topic_id` |
| `search_text` | If provided | LIKE search on `ques_title` + `question_content` |
| `quantity` | Default 50 | Limits result set |

---

## Existing Questions Endpoint (`existing()` AJAX)

Returns all questions currently linked to a quiz, along with:

**Stats:**
- `added_questions` — Count of linked questions
- `added_marks` — Sum of effective marks
- `required_marks` — Quiz's `total_marks` setting
- `total_questions_limit` — Quiz's `total_questions` setting
- `quiz_title`, `quiz_code`
- `ignore_difficulty_config` — Boolean
- `difficulty_config_id` — ID or null
- `scope_topic_id`, `scope_topic_name`

**Difficulty Rules (if `difficulty_config_id` set):**
Each rule includes: question_type, complexity, bloom, cognitive_skill, type_specificity, min_percent, max_percent, marks_per_question

---

## Workflow Steps

**Manual Single Question Add**
1. Navigate to Quiz Questions tab → Click "Add New"
2. Select Quiz from dropdown
3. Select Question from dropdown
4. Optionally set Ordinal and Marks Override
5. Click Save
6. System runs Steps 1-11 from [A] above
7. Success → redirected to Quiz Management

**Bulk Add via Search**
1. Click "Add Questions" button
2. Quiz context is auto-set (or select quiz)
3. Use filters to narrow questions: class, subject, topic, question type, complexity, etc.
4. System shows matching questions (if `scope_topic_id` set on quiz, scope is auto-applied)
5. Select desired questions, optionally set marks override per question
6. Click "Add Selected"
7. System runs Steps 1-14 from [B] above
8. If exact match required → user must select correct number of questions
9. If distribution violation and `ignore_difficulty_config` is OFF → blocked
10. If distribution violation and `ignore_difficulty_config` is ON → allowed with warning

**Using the Difficulty Builder**
1. Click "Difficulty Builder" button
2. Select the target quiz
3. System loads quiz's difficulty config (if assigned) + shows current distribution
4. Filter by complexity/type/taxonomy to find questions for specific bucket
5. System shows available questions + current distribution status per rule
6. Select questions and add → system validates distribution
7. If distribution violated → blocked (unless `ignore_difficulty_config` is ON)

**Reordering Questions**
1. Click ordinal edit button on any row
2. Enter new ordinal value
3. System shifts other questions up/down automatically
4. All ordinals remain sequential (no gaps)

**Updating Marks Override**
1. Click marks edit button on any row
2. Enter new marks value (or clear to use question default)
3. System checks total marks limit for the quiz
4. If limit would be exceeded → blocked with message

**Removing Questions**
1. Select questions to remove (checkboxes)
2. Click "Remove Selected"
3. System deletes QuizQuestion records + cleans up QuestionUsageLogs
4. Remaining questions are re-ordered sequentially

---

## Example Scenarios

**SC-001 — Bulk Add Exact Match Required**
Quiz "Motion" has settings: `total_questions=10, total_marks=20`. It already has 3 questions added. The teacher searches for MCQ questions and selects 7 questions. System calculates: 3+7=10✓ questions, and 10×2=20✓ marks. All constraints pass. Questions added successfully.

**SC-002 — Bulk Add Exceeds Limit (Blocked)**
Same quiz with 3 existing questions. Teacher selects 5 questions. System calculates: 3+5=8≠10. Blocks with: "Exact match required. Questions: 8/10, Marks: 16/20". Teacher must select exactly 7 questions.

**SC-003 — Only Unused Constraint Blocks**
Quiz has `only_unused_questions=true`. Teacher selects a question that was already used in another quiz (logged in `qns_question_usage_log`). System detects and blocks with: "This quiz requires unused questions only. The following questions have been used before: [Question Title]".

**SC-004 — Topic Scope Mismatch (Blocked)**
Quiz is scoped to Topic ID 5 ("Velocity"). Teacher selects a question whose `topic_id` is 8 ("Acceleration"). System blocks: "This quiz is scoped to topic: Velocity. The following questions are out of scope: [Question Title]".

**SC-005 — Non-MCQ Question Blocked**
Teacher selects a SHORT_ANSWER type question. System checks MCQ-only constraint. Blocks with: "Only MCQ questions are allowed in the quiz. The following questions are not MCQ type: [Question Title]".

**SC-006 — Difficulty Distribution Strict Mode (Blocked)**
Quiz has `difficulty_config_id=1` (Balanced: Easy max=40%, Medium max=40%, Difficult max=20%) and `ignore_difficulty_config=false`. Quiz has `total_questions=10`. Currently: 2 Easy questions (20%). Teacher tries to add 3 more Easy questions. System calculates: existing 2 + new 3 = 5. Max allowed = ceil(10 × 40%) = 4. 5 > 4. Blocks with: "Cannot add 3 questions of this type/complexity. Max allowed: 4, Existing: 2. Limit exceeded for rule: MCQ_SINGLE - Easy".

**SC-007 — Difficulty Distribution Warning Mode (Allowed with Warning)**
Same quiz but `ignore_difficulty_config=true`. Same violation occurs but system allows the addition and returns: "3 questions added successfully. However, difficulty rule was violated: Cannot add 3 questions... Limit exceeded..."

**SC-008 — Marks Override Exceeds Total (Blocked)**
Quiz has `total_marks=20`. Current questions sum to 18 marks. Teacher tries to override a 2-mark question to 5 marks. System calculates: 18 - 2 + 5 = 21 > 20. Blocks with: "Cannot update marks. Total marks limit (20) would be exceeded. Potential total: 21".

**SC-009 — Ordinal Reorder with Shift**
Quiz has questions at ordinals 1,2,3,4,5. Teacher moves question at ordinal 5 to position 2. System increments ordinals 2→3, 3→4, 4→5, then sets moved question to 2. Result: 1,[moved],2,3,4 → ordinals now 1,2,3,4,5.

**SC-010 — Difficulty Distribution with Taxonomy Rules**
Quiz has complex difficulty rules with bloom taxonomy and cognitive skill specified. A question with question_type_id=1, complexity_level_id=2, bloom_id=3, cognitive_skill_id=4 must match a rule that has ALL these exact values (null fields act as wildcards). If no matching rule found → blocked with "does not match any rule" message.

**SC-011 — Single Add with Usage Check on Edit**
Teacher tries to edit a quiz question that has student attempt data. `QuizQuestionUsageCheckService@isUsed()` returns true. System blocks: "Cannot edit this quiz question because students have already started attempts."

**SC-012 — Bulk Remove Cleans Up Usage Logs**
Teacher removes 3 questions from a quiz. System force-deletes the QuizQuestion records AND force-deletes the associated QuestionUsageLog records (where context_id=quiz_id, usage_type='QUIZ'). Remaining questions are re-ordered 1,2,3... sequentially.

---

## Business Rules Summary

| # | Rule | Where Enforced | Behavior on Violation |
|---|------|---------------|----------------------|
| 1 | Unique (quiz_id + question_id) | DB UNIQUE + Controller duplicate check | Block with error |
| 2 | Total questions exact match (bulk) | `bulkStore()` | Block with required count |
| 3 | Total marks within limit (single) | `store()` | Block with limit exceeded |
| 4 | Total marks exact match (bulk) | `bulkStore()` | Block with required marks |
| 5 | Total marks limit (marks update) | `updateMarks()` | Block with limit exceeded |
| 6 | Total marks limit (question update) | `update()` | Block with limit exceeded |
| 7 | Only unused questions | `store()` + `bulkStore()` | Block with used list |
| 8 | Only authorised questions (for_quiz=1) | `store()` + `bulkStore()` | Block with unauthorised list |
| 9 | Topic scope match | `store()` + `bulkStore()` | Block with out-of-scope list |
| 10 | MCQ-only constraint | `bulkStore()` | Block with non-MCQ list |
| 11 | Difficulty distribution | `validateDifficultyDistribution()` | Strict: Block / Warning: Allow with warning |
| 12 | No student usage (edit/delete) | `QuizQuestionUsageCheckService` | Block with student attempt message |
| 13 | Ordinal sequential on reorder | `updateOrdinal()` | Shift neighboring questions |
| 14 | Marks override null if same as default | `updateMarks()` | Auto-set to null |
| 15 | Usage logging on add | `store()` + `bulkStore()` | Creates QuestionUsageLog |
| 16 | Usage log cleanup on remove | `bulkDestroy()` | Force-deletes QuestionUsageLog |

---

## Related Screens

- **Quiz Creation** — Where `total_questions`, `total_marks`, `only_unused_questions`, `only_authorised_questions`, `scope_topic_id`, `difficulty_config_id`, `ignore_difficulty_config` are defined
- **Difficulty Distribution Config** — Where the distribution rules (min/max percentages per type×complexity) are defined
- **Question Bank** — Source of all questions with their metadata (type, complexity, topic, marks, for_quiz flag)

---

## Requirements

**Controller:** `Modules\LmsQuiz\Http\Controllers\QuizQuestionController`
**Model:** `QuizQuestion` (table: `lms_quiz_questions`)
**Requests:** `QuizQuestionRequest`
**Policy:** `QuizQuestionPolicy` (permissions: `tenant.quiz-question.viewAny`, `.view`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete`, `.status`)

**Key Methods & Their Validation Depth:**

| Method | Type | Validation Checks Count | Key Constraints Checked |
|--------|------|------------------------|------------------------|
| `store()` | POST (single) | 6 checks | Duplicate, Unused, Authorised, Topic Scope, Total Questions, Total Marks |
| `bulkStore()` | AJAX POST (multiple) | 9 checks | Exact count+marks, Unused, Authorised, Topic Scope, MCQ-only, Difficulty Distribution, Duplicate |
| `update()` | PUT (single) | 3 checks | Student usage, Duplicate (if changed), Total Marks |
| `updateOrdinal()` | AJAX POST | 1 check | Ordinal shift logic |
| `updateMarks()` | AJAX POST | 2 checks | Total marks limit, Auto-null if same as default |
| `destroy()` | DELETE (single) | 1 check | Student usage |
| `bulkDestroy()` | AJAX POST (multiple) | 0 checks (usage log cleanup) | — |
| `search()` | AJAX GET | Filters only | Default MCQ-only restriction |
| `existing()` | AJAX GET | Read-only | Returns stats + difficulty rules |

---

## Error Messages Reference

| Scenario | Message | HTTP Code |
|----------|---------|-----------|
| Duplicate question | "This question already exists in the quiz." | 302 back |
| No questions selected | "No questions selected." | 422 |
| Exact match required | "Exact match required. Questions: X/Y, Marks: X/Y" | 422 |
| Unused constraint | "This quiz requires unused questions only. The following questions have been used before: [titles]..." | 422 |
| Unauthorised | "This quiz requires authorised questions only (for_quiz=1). The following questions are not authorised: [titles]..." | 422 |
| Out of scope | "This quiz is scoped to topic: [Name]. The following questions are out of scope: [titles]..." | 422 |
| Non-MCQ blocked | "Only MCQ questions are allowed in the quiz. The following questions are not MCQ type: [titles]..." | 422 |
| Total questions limit | "Cannot add question. Total questions limit (X) reached." | 302 back |
| Total marks limit (add) | "Cannot add question. Total marks limit (X) would be exceeded." | 302 back |
| Total marks limit (update) | "Cannot update marks. Total marks limit (X) would be exceeded. Potential total: Y" | 422 |
| Distribution violation (strict) | "Cannot add N questions of this type/complexity. Max allowed: M, Existing: E. Limit exceeded for rule: [Rule]" | 422 |
| No matching difficulty rule | "Questions with Type ID: X and Complexity ID: Y do not match any rule in the selected difficulty configuration." | 422 |
| Student usage (edit) | "Cannot edit this quiz question because students have already started attempts." | 302 back |
| Student usage (delete) | "Cannot delete this quiz question because students have already started attempts." | 302 back |

---

## Dependencies

| Dependency | Type | Details |
|-----------|------|---------|
| `lms_quiz_questions` | Primary table | Quiz-question junction with soft-deletes |
| `lms_quizzes` | FK Table | `quiz_id` (CASCADE delete) — provides `total_questions`, `total_marks`, `only_unused_questions`, `only_authorised_questions`, `scope_topic_id`, `difficulty_config_id`, `ignore_difficulty_config` |
| `qns_questions_bank` | FK Table | `question_id` (CASCADE delete) — provides `marks`, `for_quiz`, `topic_id`, `question_type_id`, `complexity_level_id`, taxonomy fields |
| `qns_question_usage_log` | Usage tracking | Logged on add, cleaned on remove |
| `lms_difficulty_distribution_configs` | Reference | `difficulty_config_id` on quiz |
| `lms_difficulty_distribution_details` | Reference | Per-bucket min/max percentages, marks_per_question |
| `slb_question_types` | FK/Filter | MCQ_SINGLE (1), MCQ_MULTI (2) — hardcoded MCQ restriction |
| `slb_complexity_level` | Filter | EASY/MEDIUM/DIFFICULT |
| `slb_bloom_taxonomy` / `slb_cognitive_skill` / `slb_ques_type_specificity` | Optional taxonomy | Used in difficulty distribution matching |
| `qns_question_performance_category_jnt` | Filter | Performance category, recommendation type, priority |
| `qns_question_tags` | Filter | Tag-based question search |
