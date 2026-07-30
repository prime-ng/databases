# Quiz Creation — Business Requirements

## What This Screen Does

The Quiz Creation screen is the core data entry interface for defining quizzes. It allows teachers and coordinators to create quizzes scoped to the academic hierarchy (session → class → subject → lesson → topic) with detailed configuration settings covering timing, scoring, randomization, proctoring, and result visibility.

The create/edit form is a 2-tab wizard:
- **Tab 1: Basic Information** — Academic hierarchy, title, assessment type, topic scope
- **Tab 2: Quiz Configuration** — Duration, marks, passing percentage, attempts, randomization, difficulty config, visibility toggles

---

## When This Screen Is Used

- Creating Quizzes by teachers for their assigned classes
- Bulk Quiz Setup by academic coordinators at the start of a term
- Quiz Modification when updating settings or re-scoping existing quizzes
- Publishing Quizzes after question assignment is complete

## Default Data Load

The **Quiz Creation tab** (`active_tab=quiz`) loads a paginated list of existing quizzes via `QuizQueryService@quizzesQuery()`. Each row shows: code, title, assessment type, status, class/subject/lesson, total questions, total marks, duration, and action buttons (View, Edit, Delete, Publish, Toggle Status). Pagination: 15 per page with search and filter support.

The **create form** (`create()` method) loads: current academic session (`is_current=1`), active classes, assessment types, difficulty configs, question types, and topic level types.

The **edit form** (`edit()` method) additionally loads:
- Cascaded subjects (via `SubjectGroup` for the quiz's `class_id`)
- Cascaded lessons (via `Lesson::where('class_id', quiz.class_id)->where('subject_id', quiz.subject_id)`)
- Topic ancestor chain (walks parent_id recursively to build a breadcrumb)
- All values pre-filled from the existing quiz record

---

## Key Fields at a Glance

**Basic Information (Tab 1)**
- Academic Session — Auto-filled with current session (read-only)
- Class — Required, cascades to subject via `SubjectGroup`
- Subject — Cascaded from class+section via `SubjectGroup`
- Lesson — Cascaded from class+subject selection
- Topic Level — Filters available topics by hierarchy depth (`TopicLevelType.level`)
- Topic / Sub-Topic / Mini-Topic / Micro-Topic — Cascaded 4-level hierarchy via `parent_id`
- Quiz Type (Assessment Type) — From `lms_assessment_types` dropdown
- Title — Required, max 100 characters
- Description — Optional, max 255 characters
- Instructions — Optional, supports HTML/Markdown/JSON/Latex

**Quiz Configuration (Tab 2)**
- Duration — Minutes (1-600, nullable = Unlimited)
- Total Marks — Required, decimal `min:0`
- Total Questions — Required, integer `min:0`
- Passing Percentage — Required, 0-100, default 33%
- Allow Multiple Attempts — Boolean toggle (default: false)
- Max Attempts — 1-10, shown when multiple attempts enabled
- Negative Marks — 0-99.99, decimal (0 = no negative marking)
- Is Randomized — Boolean (default: false)
- Timer Enforced — Boolean (default: false)
- Question Marks Shown — Boolean (default: false)
- Show Result Immediately — Boolean (default: false)
- Auto Publish Result — Boolean (default: false)
- Show Correct Answer — Boolean (default: false)
- Show Explanation — Boolean (default: false)
- Difficulty Config — Optional, from `lms_difficulty_distribution_configs`
- Ignore Difficulty Config — Boolean (default: false)
- Is System Generated — Boolean (default: false)
- Only Unused Questions — Boolean (default: false)
- Only Authorised Questions — Boolean (default: false)

---

## Complete Validation Flow Before Save

This section explains every check the system performs — in plain language — for each operation on a Quiz. A quiz is the "container" that holds all settings — timing, scoring, difficulty rules, and visibility.

---

### [A] Creating a New Quiz (Save)

When a teacher fills the form and clicks Save, the system runs through these steps:

**Step 1 — Permission Check**
Does the user have permission to create quizzes?
- If No → Access Denied
- If Yes → Proceed

**Step 2 — Form Validation**
Did the teacher fill in everything correctly?
- Basic Info: academic_session, class, subject, lesson, title (required), description (optional)
- Assessment Type: Must select a valid type (Practice, Diagnostic, etc.)
- Duration: Optional (1-600 minutes, or leave empty for unlimited)
- Total Marks: Required, must be 0 or more
- Total Questions: Required, must be 0 or more
- Passing Percentage: Required, 0-100, defaults to 33%
- All checkboxes are auto-converted (if checked = true, if unchecked = false)
If anything wrong → Show validation error and stop

**Step 3 — Generate Unique Code**
The system automatically creates a quiz code like: `QUIZ_2425_9_SCI_MOTION_A3B2C4`
- Format: `QUIZ_{Session}_{Class}_{Subject}_{Lesson}_{6 random characters}`
- If any part is missing (e.g., no lesson code), it shows "GEN" instead
- This happens at TWO places (controller + model), but only one actually runs

**Step 4 — Generate Unique UUID**
Each quiz gets a hidden unique ID (UUID) stored in binary format

**Step 5 — Save + Log**
Quiz is created with all settings. System logs: "A new quiz was created" with the academic hierarchy

**Step 6 — Commit + Redirect**
If everything succeeds → redirect to quiz list with success. If error → rollback, show error.

**Real Example:**
> Ravi, Grade 9 Science teacher, creates a quiz:
> - Title: "Motion - Chapter Quiz"
> - Class: 9, Subject: Science, Lesson: Motion
> - Total Questions: 10, Total Marks: 20
> - Duration: 30 minutes, Passing: 33%
> - Difficulty Config: "Balanced" (selected)
> - Ignore Difficulty Config: OFF (strict mode)
> - System generates: QUIZ_2425_9_SCI_MOTION_A3B2C4
> - Redirects to quiz list with success

---

### [B] Opening a Quiz for Editing (Edit Load)

When teacher clicks Edit on an existing quiz:

**Step 1 — Permission Check**

**Step 2 — Usage Check (Critical!)**
The system asks: "Has this quiz been allocated to any students?"
- If YES → **BLOCKED**: *"This quiz is used in: Quiz Allocations (20 students allocated). Therefore cannot be edited."*
- **Why?** If students are already assigned, changing settings (like marks, questions, duration) would be unfair or inconsistent
- The teacher must first remove all allocations, then edit

**Step 3 — Load the Form**
If not used → Load the edit form with all current values pre-filled:
- Subject and lesson dropdowns are cascaded to match the quiz's class
- Topic ancestry chain is loaded (walks up the topic tree)
- All settings pre-populated

---

### [C] Saving Changes to a Quiz (Update)

When teacher clicks Update:

**Step 1 — Usage Check** (same as Edit)
If allocated → BLOCKED

**Step 2 — Save + Detect Changes**
- System saves the updated fields
- Checks what changed (e.g., passing_percentage went from 33 to 40, negative_marks from 0 to 2)
- Records all meaningful changes in the activity log

**Step 3 — Commit + Redirect**
Redirect with success. On error → rollback.

---

### [D] Publishing a Quiz (Publish)

When teacher clicks "Publish" on a DRAFT quiz:

**Step 1 — Already Published Check**
If the quiz is already PUBLISHED → Just informational message: *"Quiz is already published."*

**Step 2 — Questions Check**
If the quiz has `total_questions = 0` or empty → **BLOCKED**: *"Cannot publish a quiz with no questions."*
- **Why?** A quiz must have questions before students can take it

**Step 3 — Publish**
- Status changes from DRAFT to PUBLISHED
- Quiz now appears in allocation dropdowns (teachers can assign it to students)
- Activity logged

---

### [E] Soft Deleting a Quiz (Delete)

When teacher clicks Delete:

**Step 1 — Usage Check**
If quiz is allocated to any students → **BLOCKED**

**Step 2 — Pre-Delete**
- Sets `is_active = false` (quiz is disabled)
- Sets status to `ARCHIVED`
- Soft deletes (can be restored)

**What happens to existing data?** Nothing. If students had already started the quiz, their progress is preserved. The quiz just won't appear for new students.

---

### [F] Permanently Deleting a Quiz (Force Delete)

When coordinator force-deletes from trash:

**Step 1 — Dependency Check**
The system checks: "Are there any allocations, student attempts, or results for this quiz?"
- If YES → **BLOCKED**: *"Cannot permanently delete quiz because it has associated allocations or student attempts."*

**Step 2 — Force Delete**
If no student data → System:
1. Permanently removes ALL question-quiz links
2. Permanently deletes the quiz
3. Logs: "Quiz was permanently deleted along with its questions"
4. **Cannot be undone**

---

### [G] Restoring a Deleted Quiz (Restore)

When coordinator restores from trash:
- System finds the soft-deleted quiz
- Restores it + sets `is_active = true`

---

### [H] Toggling Active/Inactive (AJAX Toggle)

When coordinator clicks the toggle:
- System flips `is_active` flag
- Works even on trashed quizzes (can enable/disable from trash)
- No usage check — you can disable a quiz even if students are using it

---

## How Quiz Settings Affect Question Adding (Non-Technical Explanation)

The settings you choose on this screen directly control what happens later when a teacher adds questions to the quiz. Here's a plain-language guide to which settings matter and what they do:

### Settings That Control Which Questions Can Be Added

| Quiz Setting | If You Set It... | What Happens When Adding Questions |
|-------------|------------------|-----------------------------------|
| **Total Questions** (e.g., 10) | System knows the quiz should have exactly 10 questions | In Bulk Add: You MUST add questions that bring the total to exactly 10. Can't add 5 if 3 already exist (would be 8, not 10). In Single Add: You can add one at a time up to 10, but can't exceed 10 |
| **Total Marks** (e.g., 20) | System knows the quiz should be worth exactly 20 marks | Marks are divided by total questions. If 20 marks ÷ 10 questions = 2 marks each. Bulk Add requires exact match. Single Add checks you don't exceed |
| **Difficulty Config** (pick "Balanced") | System activates difficulty validation rules | When adding questions, the system checks if your selection fits the rules (e.g., at most 40% Easy, 40% Medium, 20% Difficult). Read the full explanation in the Difficulty Config doc |
| **Ignore Difficulty Config** (checkbox) | Changes how violations are handled | **OFF (Strict):** If you violate a difficulty rule, questions are BLOCKED. **ON (Warning):** Violations just show a warning but questions are added |
| **Only Unused Questions** (checkbox) | Only fresh questions allowed | System checks if each question was used in ANY other quiz before. If it was, it's blocked |
| **Only Authorised Questions** (checkbox) | Only approved questions allowed | Questions must have the "for_quiz" flag set to 1 (approved for quiz use). Unauthorised questions are blocked |
| **Topic Scope** (pick a topic like "Velocity") | Questions must belong to this topic | System checks each question's topic. If it doesn't match "Velocity", it's blocked |

### Real Example — Putting It All Together

> Ravi creates a quiz and sets:
> - Total Questions = 10
> - Total Marks = 20
> - Difficulty Config = "Balanced" (Easy: max 40%, Medium: max 40%, Difficult: max 20%)
> - Ignore Difficulty Config = OFF (strict mode)
> - Only Unused Questions = ON
> - Topic Scope = "Velocity"
>
> Later, Ravi goes to add questions using the Difficulty Builder (bulk add):
> 1. He selects 10 questions from the question bank — all about "Velocity"
> 2. System checks: All 10 unused? ✓ All about Velocity? ✓ 
> 3. System checks difficulty: 4 Easy (40%) ✓, 4 Medium (40%) ✓, 2 Difficult (20%) ✓
> 4. System checks marks: 4×2 + 4×3 + 2×5 = 8+12+10 = 20 ✓
> 5. All pass → 10 questions added successfully

### Real Example — Getting Blocked

> Ravi tries to add 6 Easy + 4 Medium questions (no Difficult)
> - Difficulty rule says: Difficult max = 20%, you have 0%
> - Wait — the system only enforces MAX, not MIN. So 0% Difficult is below min but... actually looking at the code, min percentage is calculated but not enforced. Only max is checked.
> - But if Ravi tries 5 Easy (50%) when max is 40% → **BLOCKED**: "Cannot add 5 questions. Max allowed: 4, Existing: 0. Limit exceeded for rule: MCQ_SINGLE - Easy"
>
> Ravi must remove 1 Easy and add a Different or Medium question instead.

---

## Quiz Code Generation — Dual Path Detail

| Path | Where | Pattern | Random Length | Topic Included |
|------|-------|---------|---------------|----------------|
| Controller | `store()` / `update()` | `QUIZ_{SESSION}_{CLASS}_{SUBJECT}_{LESSON}_{RANDOM6}` | 6 chars | No |
| Model Boot | `Quiz::creating()` event | `QUIZ_{SESSION}_{CLASS}_{SUBJECT}_{LESSON}_{TOPIC}_{RANDOM4}` | 4 chars | Yes |

**Runtime behavior:** Both paths can fire. If the controller sets `quiz_code` (Path 1), the model boot's `if (empty($model->quiz_code))` check skips generation. Only one path executes per creation.

**Fallback:** If any code (session/class/subject/lesson/topic) is null, the segment defaults to `'GEN'`.

---

## AJAX Cascade Endpoints

### getSubjectsByClass(Request)
| Parameter | Required | Description |
|-----------|----------|-------------|
| `class_section_id` | No* | Resolves to class_id + section_id via `ClassSection` |
| `class_id` | No* | Direct class_id lookup |
*\*One of the two is required*

- Loads subjects via `SubjectGroup → subjectGroupSubjects → subject` chain
- Filters by `class_id` and optionally `section_id`
- Returns `{ success: bool, subjects: [{id, name, code}] }`

### getLessons(Request)
| Parameter | Required |
|-----------|----------|
| `class_id` | Yes |
| `subject_id` | Yes |

- Returns `{ success: bool, lessons: [{id, name, code}] }`

### getTopics(Request)
| Parameter | Required | Behavior |
|-----------|----------|----------|
| `lesson_id` | Yes | Filter by lesson |
| `level_id` | No | Filter by topic level type ID |

- Returns `{ success: bool, topics: [{id, name, code}] }`

### getTopicHierarchy(Request)
| Parameter | Required | Behavior |
|-----------|----------|----------|
| `lesson_id` | Yes | Filter by lesson |
| `level` | No | Filter by `TopicLevelType.level` (numeric) |
| `parent_id` | No | If set → get children of this parent; if null → get root topics (parent_id IS NULL) |

- Loads with `topicLevelType` relation
- Ordered by ordinal then name
- Returns `{ topics: [{id, name, level_id, level, parent_id}] }`

### getTopicAncestors(Request)
| Parameter | Required |
|-----------|----------|
| `topic_id` | Yes |

- Walks parent_id chain up to root (with visited-cycle guard)
- Returns `{ ancestors: [...], chain: [...] }` (both contain the same data)

---

## QuizRequest — Validation Rules

| Field | Rules | Notes |
|-------|-------|-------|
| `academic_session_id` | required | — |
| `class_id` | required, exists:sch_classes,id | — |
| `subject_id` | required, exists:sch_subjects,id | — |
| `lesson_id` | required, exists:slb_lessons,id | — |
| `title` | required, string, max:100 | — |
| `description` | nullable, string, max:255 | — |
| `instructions` | nullable, string | HTML/Markdown permitted |
| `quiz_type_id` | required, exists:lms_assessment_types,id | Assessment type FK |
| `scope_topic_id` | nullable, exists:slb_topics,id | Topic scope FK |
| `status` | required, in:DRAFT,PUBLISHED,ARCHIVED | Default: DRAFT |
| `duration_minutes` | nullable, integer, min:1, max:600 | Null = unlimited |
| `total_marks` | required, numeric, min:0 | — |
| `total_questions` | required, integer, min:0 | — |
| `passing_percentage` | required, numeric, min:0, max:100 | Default: 33 |
| `allow_multiple_attempts` | boolean | — |
| `max_attempts` | required_if:allow_multiple_attempts,true, integer, min:1, max:10 | — |
| `negative_marks` | required, numeric, min:0, max:99.99 | — |
| `is_randomized` | boolean | — |
| `question_marks_shown` | boolean | — |
| `show_result_immediately` | boolean | — |
| `auto_publish_result` | boolean | — |
| `timer_enforced` | boolean | — |
| `show_correct_answer` | boolean | — |
| `show_explanation` | boolean | — |
| `difficulty_config_id` | nullable, exists:lms_difficulty_distribution_configs,id | — |
| `ignore_difficulty_config` | boolean | — |
| `is_system_generated` | boolean | — |
| `only_unused_questions` | boolean | — |
| `only_authorised_questions` | boolean | — |
| `created_by` | nullable, exists:sys_users,id | Auto-set in controller |
| `is_active` | boolean | Default: true via prepareForValidation |

**prepareForValidation() auto-converts:** `allow_multiple_attempts`, `is_randomized`, `question_marks_shown`, `show_result_immediately`, `auto_publish_result`, `timer_enforced`, `show_correct_answer`, `show_explanation`, `ignore_difficulty_config`, `is_system_generated`, `only_unused_questions`, `only_authorised_questions`, `is_active` (default true).

---

## Business Rules Summary

| # | Rule | Where Enforced | Behavior |
|---|------|---------------|----------|
| 1 | Unique quiz code | Model boot + Controller store/update | Auto-generated; no explicit DB unique constraint in code but guaranteed unique via random segment |
| 2 | UUID as BINARY(16) | Model `creating()` boot | Auto-generated on creation only |
| 3 | Edit/Update blocked if allocated | `edit()` + `update()` | `QuizUsageCheckService@isUsed()` checks `QuizAllocation` count > 0 |
| 4 | Delete blocked if allocated | `destroy()` | Same usage check |
| 5 | Force delete blocked if any student data | `forceDelete()` | Checks allocations, attempts, results |
| 6 | Publish requires questions | `publish()` | `total_questions` must be >= 1 |
| 7 | Cannot publish already published quiz | `publish()` | Redirect with info message |
| 8 | Soft delete sets is_active=false + ARCHIVED | `destroy()` | Before calling `->delete()` |
| 9 | Restore sets is_active=true | `restore()` | After calling `->restore()` |
| 10 | Force delete cascades to quiz questions | `forceDelete()` | `quizQuestions()->forceDelete()` before `$quiz->forceDelete()` |
| 11 | All booleans default to false (except is_active) | `prepareForValidation()` | `is_active` defaults to true |
| 12 | Topic ancestors walked with cycle guard | `edit()` + `getTopicAncestors()` | Prevents infinite loops from corrupted data |
| 13 | Subject cascade via SubjectGroup not direct | `edit()` + `getSubjectsByClass()` | Class+section determines available subjects |
| 14 | Active quiz scope for create form dropdown | `create()` | Only `is_active=1` classes, assessment types, difficulty configs |
| 15 | Change detection on update | `update()` | `getChanges()` excludes `updated_at` |

---

## Workflow Steps

**Creating a Quiz (Full Flow)**
1. Navigate to Quiz Management → Quiz Creation tab → Click "Add New Quiz"
2. Fill Basic Information (Tab 1): Select Class → AJAX loads subjects via `getSubjectsByClass` → Select Subject → AJAX loads lessons via `getLessons` → Select Lesson
3. Optionally select Topic Level → AJAX loads topics via `getTopicHierarchy` → Select topic
4. Select Quiz Type and enter Title
5. Switch to Quiz Configuration (Tab 2): Fill duration, marks, percentage, toggles
6. Optionally select Difficulty Config
7. Click Save:
   - QuizRequest validates all fields
   - `prepareForValidation()` converts checkboxes to booleans
   - Controller generates quiz_code (4-segment + random6)
   - `Quiz::create()` fires model boot → generates UUID + potentially overwrites code (5-segment + random4)
   - Transaction commits → success redirect

**Editing a Quiz (Full Flow)**
1. Click "Edit" on any row in the quiz list
2. System checks `QuizUsageCheckService@isUsed()`
3. If used → redirects to index with error message listing allocation count
4. If unused → loads edit form with:
   - All current quiz values pre-filled
   - Subject dropdown cascaded to quiz's class
   - Lesson dropdown cascaded to quiz's class+subject
   - Topic hierarchy pre-loaded with ancestor chain
5. Modify fields, click Update
6. System detects changes via `getChanges()` and logs them

**Publishing a Quiz**
1. From the Quiz Creation list, click "Publish" on a DRAFT quiz
2. System checks: status !== 'PUBLISHED', total_questions >= 1
3. If valid: status changes to PUBLISHED, activity logged
4. Quiz now appears in allocation dropdowns

**Soft Deleting a Quiz**
1. Click "Delete" on any row
2. System checks usage → if allocated, blocks
3. If unused: sets is_active=false, status=ARCHIVED, soft deletes

**Restoring a Trashed Quiz**
1. Navigate to Trash via "View Trash" button
2. Click "Restore" on a trashed quiz
3. System restores and sets is_active=true

---

## Example Scenarios

**SC-001 — Create Draft Quiz**
A Grade 9 Science teacher creates a quiz named "Motion - Chapter Quiz" for Class 9 (code: 9), Subject Science (code: SCI), Lesson "Motion" (code: MOTION). System generates quiz_code: `QUIZ_2425_9_SCI_MOTION_A3B2C4`. Quiz appears in the list with status DRAFT. UUID stored as BINARY 16.

**SC-002 — Publish Quiz**
Teacher clicks Publish on a quiz that has `total_questions=10`. System changes status to PUBLISHED. Quiz now appears in allocation dropdowns.

**SC-003 — Edit Blocked by Usage**
Teacher tries to edit a PUBLISHED quiz that has 20 student allocations. `QuizUsageCheckService@isUsed()` returns true. System redirects back with: "This quiz is used in: Quiz Allocations (20 students allocated). Therefore cannot be edited."

**SC-004 — Quiz Code Format Variations**
- Controller generation: `QUIZ_2425_9_SCI_MOTION_A3B2C4D5E6` (4 segments + 6 random)
- Model boot generation: `QUIZ_2425_9_SCI_MOTION_VELOCITY_F1G2` (5 segments + 4 random)
- With missing codes: `QUIZ_GEN_GEN_GEN_GEN_X7Y8Z9`

**SC-005 — Publish Already Published Quiz**
Teacher clicks Publish on a quiz already in PUBLISHED status. System shows: "Quiz is already published." No status change.

**SC-006 — Publish Quiz Without Questions**
Teacher clicks Publish on a DRAFT quiz where `total_questions=0` or is null. System returns: "Cannot publish a quiz with no questions."

**SC-007 — Force Delete Blocked with Student Data**
Coordinator tries to permanently delete a quiz that has allocations. System blocks: "Cannot permanently delete quiz because it has associated allocations or student attempts."

**SC-008 — Force Delete Unused Quiz**
Coordinator force-deletes a DRAFT quiz with no allocations, attempts, or results. System force-deletes all QuizQuestion junctions, then force-deletes the quiz, logs "Quiz was permanently deleted along with its questions."

**SC-009 — Restore Trashed Quiz**
Teacher restores a deleted quiz. System restores the soft-deleted record, sets `is_active=true`, logs "Quiz was restored."

**SC-010 — Toggle Active Status (AJAX)**
Teacher clicks the active/inactive toggle. AJAX sends `{is_active: false}`. System finds quiz (even if trashed via `withTrashed()`), updates `is_active`, returns `{success: true, is_active: false}`.

**SC-011 — Update with Change Detection**
Teacher edits a DRAFT quiz, changes `passing_percentage` from 33 to 40 and `negative_marks` from 0 to 2, and saves. System detects two changes: passing_percentage (33→40), negative_marks (0→2). Activity log records both changes.

**SC-012 — AJAX Cascade: Full Topic Hierarchy**
Teacher selects Class 9 → System loads subjects via SubjectGroup → Teacher selects Science → System loads lessons → Teacher selects "Motion" → System loads root topics via `getTopicHierarchy(lesson_id, parent_id=null)` → Teacher selects level → System loads topics at that level → Teacher clicks a topic → System loads ancestors via `getTopicAncestors` for the topic chain display.

---

## Error Messages Reference

| Scenario | Message | HTTP Flow |
|----------|---------|-----------|
| Edit blocked by usage | "[Usage message] Therefore cannot be edited." | Redirect back |
| Update blocked by usage | "[Usage message] Therefore cannot be updated." | Redirect back |
| Delete blocked by usage | "[Usage message] Therefore cannot be deleted." | Redirect back |
| Force delete blocked | "Cannot permanently delete quiz because it has associated allocations or student attempts." | Redirect back |
| Publish with no questions | "Cannot publish a quiz with no questions." | Redirect back |
| Already published | "Quiz is already published." | Redirect back with info |
| Store exception | "Failed to create quiz. Please try again." | Redirect back with input |
| Update exception | "Failed to update quiz. Please try again." | Redirect back with input |
| Force delete exception | "Failed to permanently delete quiz. [error message]" | Redirect back |
| AJAX cascade error | "Error loading subjects/lessons/topics: [message]" | JSON 500 |

---

## Requirements

**Controller:** `Modules\LmsQuiz\Http\Controllers\LmsQuizController`
**Model:** `Quiz` (table: `lms_quizzes`, soft deletes)
**Requests:** `QuizRequest`
**Policy:** `QuizPolicy` (permissions: `tenant.quiz.viewAny`, `.view`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete`, `.status`, `.publish`)
**Usage Service:** `QuizUsageCheckService` — checks `QuizAllocation` existence

**Controller Methods:**

| Method | Type | Gate | Key Behavior |
|--------|------|------|-------------|
| `index()` | GET | viewAny | Multi-tab view: quiz list + dashboard + summary + questions + allocations + difficulty configs + assessment types + activity log |
| `create()` | GET | create | Loads form with academic sessions, classes, assessment types, difficulty configs, question types, topic level types |
| `store()` | POST | create | Transactional create with dual-path code generation, UUID, activity log |
| `show($id)` | GET | view | Loads quiz + relations + usage details for detail view |
| `report($quiz_id)` | GET | view | Aggregated report: assigned students, attempt status counts, score bins, average score |
| `attemptDetail($attemptId)` | GET | view | Single student attempt detail with questions, options, answers, result |
| `edit($id)` | GET | update | Loads form with topic chain, cascaded dropdowns; blocks if used |
| `update()` | PUT | update | Transactional update with change detection, activity log; blocks if used |
| `destroy($id)` | DELETE | delete | Pre-sets is_active=false + ARCHIVED, then soft delete; blocks if used |
| `trashed()` | GET | restore | Lists onlyTrashed quizzes |
| `restore($id)` | GET | restore | Restores + sets is_active=true |
| `forceDelete($id)` | DELETE | forceDelete | Blocks if allocations/attempts/results exist; force deletes child questions first |
| `publish($id)` | GET | update | Validates questions >= 1, sets PUBLISHED status |
| `toggleStatus()` | AJAX POST | update | JSON toggle of is_active (works on trashed records too) |
| `getSubjectsByClass()` | AJAX GET | viewAny | Subject cascade via SubjectGroup |
| `getLessons()` | AJAX GET | viewAny | Lesson cascade |
| `getTopics()` | AJAX GET | viewAny | Topic cascade |
| `getTopicHierarchy()` | AJAX GET | viewAny | Multi-level topic tree with parent_id |
| `getTopicAncestors()` | AJAX GET | viewAny | Topic breadcrumb chain |

---

## Dependencies

| Dependency | Type | Details |
|-----------|------|---------|
| `lms_quizzes` | Primary table | All quiz settings with soft deletes |
| `glb_academic_sessions` | FK | academic_session_id |
| `sch_classes` | FK | class_id |
| `sch_subjects` | FK | subject_id |
| `slb_lessons` | FK | lesson_id |
| `slb_topics` | FK | scope_topic_id (optional) + topic hierarchy |
| `slb_topic_level_types` | Reference | Multi-level topic depth |
| `lms_assessment_types` | FK | quiz_type_id |
| `lms_difficulty_distribution_configs` | FK | difficulty_config_id |
| `lms_quiz_questions` | Child table | Force-deleted on quiz forceDelete |
| `lms_quiz_allocations` | Usage check | Prevents edit/delete when present |
| `sch_subject_groups` | Cascade lookup | Subject availability per class+section |
| `sch_class_sections` | Cascade lookup | Resolves class_section_id → class_id |
| `std_student_academic_sessions` | Report/cascade | Student population lookups |
| `qns_question_usage_log` | Usage tracking | Via QuizQuestion controller |
| `sys_users` | FK | created_by (creator reference) |
