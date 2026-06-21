# Quiz Tab 5: Quiz Questions

This tab is where teachers add questions from the Question Bank to their quiz. It has a search interface called the Difficulty Builder that lets teachers find the right questions, preview them, and add them in bulk.

---

## How It Works

When the teacher opens this tab, they first select a quiz from a dropdown. They then see all questions currently assigned to that quiz, along with their marks, display order, and difficulty level.

To add new questions, the teacher clicks "Add Questions" and the Difficulty Builder opens. This is a search interface that connects directly to the Question Bank. The system automatically filters to show only questions that match the quiz's class and subject. The teacher can further narrow the search by lesson, topic, difficulty level, question type, Bloom's taxonomy level, keywords, or the teacher who created the question. They can also filter by whether the question has media attached.

Only questions with "Published" status appear in the search results. Draft, In Review, and Approved questions are hidden. Only questions that have "Quiz" checked in their usage types appear. Questions that are already in the quiz show as "Already Added" and cannot be selected again.

The teacher selects the questions they want — either individually, all on the current page, or all matching the current filters across all pages. When they click "Add Selected," the system adds all valid questions to the quiz. Any questions that were already in the quiz are silently skipped.

---

## Managing the Selected Questions

After adding questions, the teacher can fine-tune them. They can drag questions up or down to change the order. If shuffling is enabled in the quiz settings, this order becomes the base order before randomization — each student sees the questions in a different random order, but the relative positions set here are preserved.

The teacher can override the marks for any question. For example, if a question is worth 1 mark in the Question Bank but the teacher wants it to be 3 marks in this particular quiz, they can change it. This override only affects this quiz — the original question in the bank is unchanged. If the teacher clears the override, the question reverts to its original marks. They can even set the override to 0, which means the question appears in the quiz but contributes nothing to the score — useful if the teacher wants to include a practice question without affecting grades.

Bulk operations are supported. The teacher can select multiple questions and set their marks all at once, or remove them all at once.

Removing questions is blocked once students have started the quiz. The teacher gets an error: "Cannot remove questions while students are taking this quiz." Instead, they can set the unwanted question's marks to 0.

---

## Difficulty Distribution Check

If the quiz has a linked difficulty configuration, the system shows a comparison after every add or remove action. It looks at the current question mix and checks it against the configuration's rules. For example, if the rules say "Easy questions should be 20-30% of the total" and only 10% of the added questions are Easy, the system shows a yellow warning.

This check is informational only. It does not block the teacher from publishing. The teacher can proceed with whatever question mix they think is appropriate.

---

## Important Business Rules

- A quiz must have at least one question to be published. If the teacher tries to publish with zero questions, the system blocks it.
- Questions come exclusively from the Question Bank. There is no way to type a question directly into a quiz. The teacher must create the question in the Question Bank first, then select it here.
- Once a student has started the quiz, the question list is locked. No additions, removals, or reordering is allowed. The only thing the teacher can still change is the marks override — but even that is questionable practice if students are mid-attempt.
- Only Published questions with the "Quiz" usage type checked appear in the Difficulty Builder. Questions with Draft, In Review, or Approved status are excluded regardless of their usage type.
- Marks overrides affect only this quiz. The original question in the Question Bank retains its original marks. Clearing the override reverts to the bank's value.
- Setting marks to 0 means the question is displayed but contributes nothing to the score. This is useful for including practice or survey questions.
- If a question has media attachments (images, audio, video), those attachments are carried over when added to the quiz. The teacher cannot add or remove media at the quiz level.
- The difficulty distribution check compares the current question mix against the linked configuration after every add or remove action. The check runs automatically — no manual refresh needed.
- A quiz without a linked difficulty configuration shows no difficulty check. The teacher can add any mix of questions freely.

---

## Deep Analysis

### Business Workflows & State Machines

**Question Assignment Workflow:**

1. Teacher selects a quiz (must exist and be in Draft/Pending/Published state with no active attempts).
2. Teacher opens Difficulty Builder (search interface).
3. System filters Question Bank: only Published questions with `for_quiz = 1`, matching quiz's class/subject.
4. Teacher applies additional filters (lesson, topic, difficulty, type, Bloom's, keywords, creator, media).
5. Teacher selects questions and clicks "Add Selected."
6. System inserts into `lms_quiz_questions`, skipping duplicates silently.
7. System recalculates `total_marks`, `total_questions` on `lms_quizzes`.
8. If difficulty config linked, system runs distribution check and shows result (green/yellow/red).
9. Teacher can reorder, override marks, or remove questions.
10. **Locked** once any student has started the quiz (state check at quiz level).

**State Machine for Question List:**

| Current State | Transition | Trigger | Next State | Conditions |
|---|---|---|---|---|
| Editable | Add Questions | Teacher adds via Difficulty Builder | Editable | Quiz has no active student attempts |
| Editable | Remove Questions | Teacher removes one/multiple | Editable | Quiz has no active student attempts |
| Editable | Reorder | Teacher drags to reorder | Editable | Quiz has no active student attempts |
| Editable | Override Marks | Teacher changes marks | Editable | Always allowed (even during attempts, though discouraged) |
| Editable | Student Starts | First student begins | Locked | No adds, removes, or reordering allowed |
| Locked | Override Marks | Teacher changes marks | Locked | Still allowed; affects future scoring |
| Locked | Quiz Completes | All students done | Locked (Permanent) | No further changes |

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|---|---|---|
| Add Questions – Quiz State | Quiz must not have active attempts | "Cannot modify questions while students are taking this quiz." |
| Add Questions – Duplicate | Question already in quiz | Silently skipped (no error) |
| Add Questions – Not Published | Question must be Published | "Only published questions can be added to a quiz." |
| Add Questions – Wrong Usage | Question must have Quiz usage type | "This question is not marked for quiz use." |
| Add Questions – Media | Media carries over automatically | No error |
| Remove Questions – Active Attempts | Cannot remove if students have started | "Cannot remove questions while students are taking this quiz." |
| Marks Override – Value | Must be ≥ 0 | "Marks override must be 0 or greater." |
| Marks Override – 0 Value | Question appears but scores 0 | No error — intentional design |
| Marks Override – Clear | Reverts to question bank default | No error |
| Publish – No Questions | Quiz must have ≥ 1 question | "Cannot publish. Add at least one question first." |
| Difficulty Config – Linked | Auto-check after every action | Green/yellow/red indicator shown |
| Difficulty Config – Not Linked | No check performed | No indicator shown |
| Reorder – Active Attempts | Cannot reorder if students started | "Cannot reorder questions while students are taking this quiz." |
| Bulk Select – All Pages | System adds all matching across pages | Silently skips already-added questions |
| Question Bank – Deleted Questions | Deleted questions hidden from search | Not returned in search results |
| Quiz – Deleted | Cannot manage questions for deleted quiz | "Quiz not found." |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|---|---|---|---|
| Quiz Core | `lms_quizzes` | `id` → `lms_quiz_questions.quiz_id` | Parent quiz for questions |
| Question Bank | `qns_questions_bank` | `id` → `lms_quiz_questions.question_id` | Source of question content, marks, type, complexity |
| Quiz Questions | `lms_quiz_questions` | — | Junction table connecting quiz to questions |
| Difficulty Config | `lms_difficulty_distribution_configs` | `difficulty_config_id` → `lms_quizzes.difficulty_config_id` | Used for distribution check |
| Difficulty Rules | `lms_difficulty_distribution_details` | `difficulty_config_id` → `lms_difficulty_distribution_configs.id` | Rules for distribution check |
| Question Types | `slb_question_types` | Via question bank | Type filter in Difficulty Builder |
| Complexity Levels | `slb_complexity_level` | Via question bank | Difficulty filter in Difficulty Builder |
| Bloom's Taxonomy | `slb_bloom_taxonomy` | Via question bank | Bloom's filter in Difficulty Builder |
| Topics | `slb_topics` | Via question bank | Topic filter in Difficulty Builder |

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| View Questions | Teacher | `quiz.questions.view` |
| Add Questions | Teacher | `quiz.questions.add` |
| Remove Questions | Teacher | `quiz.questions.remove` |
| Override Marks | Teacher | `quiz.questions.override-marks` |
| Reorder Questions | Teacher | `quiz.questions.reorder` |
| Bulk Add/Remove | Teacher | `quiz.questions.bulk` |
| View Difficulty Check | Teacher | `quiz.questions.difficulty-check` |

---

## Database Columns & Behavior

### Table: `lms_quiz_questions`

| Column | Type | FK | Nullable | Default | Behavior |
|---|---|---|---|---|---|
| `id` | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| `quiz_id` | INT UNSIGNED | Yes → `lms_quizzes.id` | No | — | FK to the quiz |
| `question_id` | INT UNSIGNED | Yes → `qns_questions_bank.id` | No | — | FK to question bank |
| `ordinal` | INT UNSIGNED | No | No | 0 | Display order in quiz |
| `marks_override` | DECIMAL(5,2) | No | Yes | NULL | Override question's default marks; NULL = use bank default |
| `is_active` | TINYINT(1) | No | No | 1 | Soft-delete flag |
| `created_at` | TIMESTAMP | No | No | CURRENT_TIMESTAMP | Record creation time |
| `updated_at` | TIMESTAMP | No | No | CURRENT_TIMESTAMP ON UPDATE | Last update time |
| `deleted_at` | TIMESTAMP | No | Yes | NULL | Soft-delete timestamp |

### Table: `lms_quizzes` (relevant columns only)

| Column | Type | FK | Nullable | Default | Behavior |
|---|---|---|---|---|---|
| `id` | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| `total_marks` | DECIMAL(8,2) | No | No | 0.00 | Recalculated when questions are added/removed |
| `total_questions` | INT UNSIGNED | No | No | 0 | Recalculated when questions are added/removed |
| `difficulty_config_id` | INT UNSIGNED | Yes → `lms_difficulty_distribution_configs.id` | Yes | NULL | Linked difficulty config for distribution check |
| `ignore_difficulty_config` | TINYINT(1) | No | No | 0 | If 1, difficulty config is ignored |
| `is_randomized` | TINYINT(1) | No | No | 0 | If 1, base order is randomized per student |
| `status` | VARCHAR(20) | No | No | 'DRAFT' | Determines whether question list is locked |
| `is_active` | TINYINT(1) | No | No | 1 | Soft-delete flag |
