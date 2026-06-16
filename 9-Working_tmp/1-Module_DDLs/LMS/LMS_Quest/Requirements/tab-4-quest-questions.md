# Quest Tab 4: Quest Questions

This tab is where teachers add questions from the Question Bank to their quest, organized under the scope types they created. It has a search interface called the Difficulty Builder that lets teachers find the right questions, preview them, and add them in bulk to specific scope types.

---

## How It Works

When the teacher opens this tab, they first select a quest from a dropdown. They then see the scope types they created in the previous tab, with each scope type acting as a section header. Under each scope type, they see the questions currently assigned to it, along with their marks, display order, and difficulty level.

To add new questions, the teacher clicks "Add Questions" under the scope type they want. The Difficulty Builder opens. This is a search interface that connects directly to the Question Bank. The system automatically filters to show only questions that match the quest's class and subject. The teacher can further narrow the search by lesson, topic, difficulty level, question type, Bloom's taxonomy level, keywords, or the teacher who created the question. They can also filter by whether the question has media attached.

Only questions with "Published" status appear in the search results. Draft, In Review, and Approved questions are hidden. Only questions that have "Quest" checked in their usage types appear. Questions that are already in the quest show as "Already Added" and cannot be selected again.

The teacher selects the questions they want — either individually, all on the current page, or all matching the current filters across all pages. They also pick which scope type to assign them to. When they click "Add Selected," the system adds all valid questions to that scope type. Any questions that were already in the quest are silently skipped.

---

## Managing the Selected Questions

After adding questions, the teacher can fine-tune them within each scope type. They can drag questions up or down within a scope type to change the order. They can also move questions from one scope type to another using a move action.

The teacher can override the marks for any question. For example, if a question is worth 1 mark in the Question Bank but the teacher wants it to be 3 marks in this particular quest, they can change it. This override only affects this quest — the original question in the bank is unchanged. If the teacher clears the override, the question reverts to its original marks.

Bulk operations are supported. The teacher can select multiple questions and set their marks all at once, or remove them all at once.

Removing questions is blocked once students have started the quest. The teacher gets an error: "Cannot remove questions while students are taking this quest." Instead, they can set the unwanted question's marks to 0.

---

## Important Business Rules

- A quest must have at least one question to be published. If the teacher tries to publish with zero questions, the system blocks it.
- Questions come exclusively from the Question Bank. There is no way to type a question directly into a quest. The teacher must create the question in the Question Bank first, then select it here.
- Once a student has started the quest, the question list is locked. No additions, removals, or reordering is allowed. The only thing the teacher can still change is the marks override.
- Every question must be assigned to a scope type. There is no "unscoped" bucket. If a quest has scope types defined, each question belongs to exactly one scope type. The scope types themselves become locked once students start taking the quest — teachers cannot delete or rename them.
- Only Published questions with the "Quest" usage type checked appear in the Difficulty Builder. Questions with Draft, In Review, or Approved status are excluded regardless of their usage type.
- Marks overrides affect only this quest. The original question in the Question Bank retains its original marks. Clearing the override reverts to the bank's value.
- Setting marks to 0 means the question is displayed but contributes nothing to the score. This is useful for including practice or survey questions.
- If a question has media attachments (images, audio, video), those attachments are carried over when added to the quest. The teacher cannot add or remove media at the quest level.
- Moving a question from one scope type to another is allowed as long as no student has started the quest. Once an attempt exists, the scope assignment is locked.

---

## Deep Analysis

### Business Workflows & State Machines

**Question Assignment Lifecycle:**
```
QUESTION BANK ──→ Add to Quest ──→ SCOPED ──→ (locked when attempts exist)
                                              │
                                              └── Marks override → RECALCULATE total
```

**Source Rules:**
- Questions must have `status = 'Published'` in `qns_questions_bank`
- Questions must have `for_quest = 1` (or equivalent usage type flag)
- Questions must match the quest's `class_id` and `subject_id`
- Already-added questions are shown as "Already Added" and cannot be re-selected (the `uq_quest_ques` unique key enforces this at DB level)

**Locking Rules by Quest Status:**
| Quest Status | Can Add? | Can Remove? | Can Reorder? | Can Change Marks? |
|-------------|----------|-------------|--------------|-------------------|
| DRAFT | Yes | Yes | Yes | Yes |
| PENDING | Yes | Yes | Yes | Yes |
| PUBLISHED (no attempts) | Yes | Yes | Yes | Yes |
| PUBLISHED (with attempts) | No | No (set marks to 0 instead) | No | Yes |
| ONGOING | No | No (set marks to 0 instead) | No | Yes |
| COMPLETED | No | No | No | No |
| ARCHIVED | No | No | No | No |

### Validation Rules & Edge Cases

| Operation | Rule | Error Message |
|-----------|------|---------------|
| Add question | Question must be Published and match quest class/subject | "Question is not available for this quest" |
| Add duplicate | Unique constraint on (quest_id, question_id) | "This question is already in the quest" |
| Remove question | No student attempts on this quest | "Cannot remove questions while students are taking this quest" |
| Marks override | Decimal 0-999.99, or NULL to use bank default | "Marks must be between 0 and 999.99" |
| Add question to inactive scope | Blocked | "Cannot add questions to an inactive scope type" |
| Move question between scopes | Both scopes must be active | "Both source and target scope types must be active" |

**Edge Cases:**
- Setting marks_override to NULL reverts to the question bank's original marks value.
- Setting marks_override to 0 displays the question but contributes nothing to the score.
- If a question is deleted from the Question Bank, the `lms_quest_questions` record remains but the question_id becomes orphaned. The UI shows "(Deleted Question)".
- The Difficulty Builder search uses server-side pagination. For large Question Banks (10,000+ questions), search filters should be indexed on `class_id`, `subject_id`, and `status`.

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|--------|----------|-------------|---------|
| QuestionBank | `qns_questions_bank` | `question_id` | Source of all quest questions |
| QuestionBank | `qns_question_types` | (via questions) | Question type filtering |
| Syllabus | `slb_lessons`, `slb_topics` | (via scopes) | Scope-based organization |
| Quest (self) | `lms_quests`, `lms_quest_scopes` | `quest_id` | Parent quest and scope containers |

**Events to consider:**
- `QuestionAddedToQuest` — could trigger recalculation of total_marks and total_questions.
- `QuestionRemovedFromQuest` — could log removal and recalculate totals.

### Permissions Matrix

| Action | Role | Permission Key |
|--------|------|----------------|
| View questions in quest | Teacher, Admin | `tenant.lms.quest.view` |
| Add questions from bank | Teacher (own), Admin | `tenant.lms.quest.update` |
| Remove questions | Teacher (own), Admin | `tenant.lms.quest.update` |
| Override marks | Teacher (own), Admin | `tenant.lms.quest.update` |
| Reorder questions | Teacher (own), Admin | `tenant.lms.quest.update` |
| Move between scopes | Teacher (own), Admin | `tenant.lms.quest.update` |
| Bulk operations | Teacher (own), Admin | `tenant.lms.quest.update` |
