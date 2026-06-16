# Quest Tab 8: Paper Check

Some assessments involve subjective or offline questions that cannot be auto-graded. This tab handles that workflow — it is where teachers manually evaluate student responses that require human judgment. This is the only tab that does not appear for fully auto-graded quests.

---

## How It Works

When the teacher opens this tab, they first select a quest. If the quest has no subjective questions or questions that require manual checking, a message appears: "This quest has no questions requiring manual evaluation." Otherwise, they see a list of students who have submitted answers that need checking.

Each pending submission shows the student's name, the date they submitted, and how many questions need manual evaluation out of the total. The teacher clicks on a student to begin checking.

The checking interface shows each question that needs manual evaluation, one at a time. For each question, the teacher sees the question text, the student's written or uploaded answer, and the correct answer or rubric provided by the teacher during quest creation. The teacher can assign a score for that question — either a partial score or full marks. They can also leave comments explaining the score.

After scoring all pending questions for a student, the teacher clicks "Submit Evaluation." The student's score is updated, and the student can see the result and feedback if the quest settings allow result viewing.

---

## Re-Evaluation

If a student or parent disputes a score, the teacher can reopen a checked submission for re-evaluation. This sets the student's status back to "Pending" for those specific questions, and the teacher re-evaluates them. The system keeps a log of the original score and the revised score, along with the teacher's reason for the change.

---

## Important Business Rules

- The teacher can only score questions that require manual evaluation. Auto-graded questions within the same quest are already scored and are not shown on this tab.
- Partial scoring is allowed — the teacher can assign any score from 0 up to the question's maximum marks. They cannot exceed the maximum marks.
- The teacher can save their progress mid-way through checking a student and come back later. The scores they have already assigned are preserved as a draft.
- If the teacher does not evaluate a submission within 30 days, the system sends a reminder notification. There is no auto-approval mechanism — human evaluation is always required.
- An audit trail is maintained for every evaluation and re-evaluation. The system records who evaluated, when, the original score, the revised score (if any), and the reason for changes.
- Re-evaluation requires a reason to be provided. The reason is stored in the audit log and visible to administrators.
- Students are not notified immediately when the teacher saves a draft evaluation. They are only notified when the evaluation is fully submitted.
- Once an evaluation is submitted, the teacher can still reopen it for re-evaluation, but the original evaluation record is preserved in the log.
- If the quest has multiple attempts, each attempt is evaluated independently. A teacher might need to check different attempts of the same student separately.

---

## Deep Analysis

### Business Workflows & State Machines

**Paper Check Lifecycle:**
```
Student submits quest with subjective questions
         │
         ▼
PENDING CHECK ──→ Teacher opens evaluation ──→ IN PROGRESS
         │                                            │
         │                                   (save draft / continue)
         │                                            │
         │                                            ▼
         │                                       SUBMITTED
         │                                            │
         │                                   ┌────────┴────────┐
         │                                   ▼                 ▼
         │                              Score Applied    Student Notified
         │
         └──→ RE-EVALUATION REQUESTED ──→ PENDING (re-opened for re-check)
```

**State Definitions:**
| Status | Meaning |
|--------|---------|
| PENDING CHECK | Student submitted, subjective questions not yet evaluated |
| IN PROGRESS | Teacher has started but not submitted evaluation |
| EVALUATED | Teacher submitted evaluation, score applied |
| RE-EVALUATED | Teacher re-opened and revised the evaluation |

**Submission vs Draft:**
- Draft saves: Teacher's partial scores are saved but student is not notified. Teacher can leave and return.
- Final submit: Scores are applied, student is notified (if quest settings allow), and score is reflected in reports.

### Validation Rules & Edge Cases

| Operation | Rule | Error Message |
|-----------|------|---------------|
| Score assignment | 0 ≤ score ≤ question's max marks | "Score cannot exceed maximum marks for this question" |
| Score assignment (subjective) | Required for each unchecked question | "All pending questions must be scored before submitting" |
| Re-evaluation reason | Required, max 500 chars | "A reason is required for re-evaluation" |
| Submit evaluation | All pending questions scored | "You have X unanswered questions remaining" |
| Re-open for re-evaluation | Only after initial evaluation is submitted | "This submission has not been evaluated yet" |

**Edge Cases:**
- 30-day reminder: If a teacher hasn't evaluated within 30 days, a notification is sent. No auto-approval — human evaluation is mandatory.
- Teacher leaves mid-evaluation: Draft scores are saved in a `paper_check_drafts` table (or equivalent). Teacher can resume from the same position.
- Multiple subjective questions: Each question is evaluated independently. Teacher can score them in any order.
- Score override via Paper Check: If a teacher previously auto-graded an objective question that was incorrectly flagged as subjective, they can still score it but a warning shows "This question may be auto-gradable."
- Audit trail: Every evaluation and re-evaluation records `evaluated_by`, `evaluated_at`, `original_score`, `revised_score`, and `reason`.

### Integration Points

| Module | Table(s) | Purpose |
|--------|----------|---------|
| Quest (self) | `lms_quest_questions` | Question marks and metadata |
| QuestionBank | `qns_questions_bank` | Question type (subjective vs objective) |
| (Attempt tables) | Student response records | Student answers for evaluation |
| User | `sys_users` | Evaluator identity |
| Notification | (via event) | 30-day reminder, evaluation submitted alert |

**Events to consider:**
- `SubmissionEvaluated` — triggers notification to student and score recalculation.
- `SubmissionReEvaluated` — triggers notification and audit log entry.
- `EvaluationReminder` — 30-day reminder to teacher about pending evaluations.

### Permissions Matrix

| Action | Role | Permission Key |
|--------|------|----------------|
| View pending evaluations | Teacher (own class), Admin | `tenant.lms.quest.papercheck.view` |
| Evaluate submission | Teacher (own class), Admin | `tenant.lms.quest.papercheck.evaluate` |
| Save draft evaluation | Teacher, Admin | `tenant.lms.quest.papercheck.evaluate` |
| Re-open for re-evaluation | Teacher, Admin | `tenant.lms.quest.papercheck.reevaluate` |
| View audit trail | Admin only | `tenant.lms.quest.papercheck.audit` |
| Export evaluation report | Teacher, Admin | `tenant.lms.quest.results.export` |

- Tab is hidden entirely for quests with no subjective questions.
- Students cannot access this tab — it is teacher-facing only.
