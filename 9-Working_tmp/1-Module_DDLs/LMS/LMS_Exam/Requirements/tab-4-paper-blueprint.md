# LMS Exam Tab 4: Paper & Blueprint Design

This tab is where the user defines the subject papers for an exam and designs their structure — sections, question types, marks distribution, and syllabus scope. A single exam can have multiple papers (one per subject), and each paper can be offered in online or offline mode with optional multiple sets.

---

## How It Works

After creating an exam in Tab 3, the user opens Tab 4 to add papers. They click "Add Paper" and select a subject, choose the mode (Online or Offline), enter the total marks, passing percentage, and duration in minutes. They configure paper-level settings like negative marking, calculator allowance, randomization, and whether to show marks per question. For online papers, they can enable proctoring, browser lock, fullscreen mode, and timer enforcement. For offline papers, they choose how marks will be entered — question-wise or bulk total.

Once a paper is created, the user can design its blueprint by adding sections. Each section has a name (e.g., Section A - Objective, Section B - Short Answer), a question type, total number of questions, marks per question, and total section marks. Sections are ordered by ordinal number.

The user can also define the exam scope — which lessons, topics, and question types are covered, and their weightage percentage. This helps in curriculum mapping and ensures the paper covers the intended syllabus.

For papers with multiple variants, the user can create paper sets (e.g., Set A, Set B) so that different groups of students receive different question combinations.

---

## Important Business Rules

- A paper's total_marks must equal the sum of all its blueprint section total_marks.
- Passing percentage is stored at the paper level, not the exam level.
- Online and offline modes cannot be mixed within the same paper, but different papers in the same exam can use different modes.
- If `only_unused_questions` is enabled, the system will only allow questions from the question bank that have never appeared in any previous exam.
- If `only_authorised_questions` is enabled, only questions marked `for_quiz = 1` are eligible.
- Difficulty configuration can be optionally enforced or ignored per paper.
- Paper set codes (e.g., SET_A, SET_B) must be unique within a paper.
- Blueprint section names must be unique within a paper (e.g., you cannot have two "Section A" entries).

---

## Database Columns & Behavior

### lms_exam_papers
- `id` — INT UNSIGNED PK. Auto-increment.
- `exam_id` — INT UNSIGNED FK to lms_exams.id. Parent exam.
- `class_id` — INT UNSIGNED FK to sch_classes.id. Denormalized from exam.
- `subject_id` — INT UNSIGNED FK to sch_subjects.id. Subject of this paper.
- `paper_code` — VARCHAR(50), unique per exam. Business code.
- `title` — VARCHAR(150). Display name.
- `mode` — ENUM('ONLINE','OFFLINE'). Delivery mode.
- `total_marks` — DECIMAL(8,2). Maximum marks for the paper.
- `passing_percentage` — DECIMAL(5,2). Percentage required to pass.
- `duration_minutes` — INT UNSIGNED, nullable. Time limit.
- `total_questions` — INT UNSIGNED. Aggregated count from blueprint or question setup.
- `negative_marks` — DECIMAL(5,2), default 0. Negative marking per wrong answer.
- `instructions` — TEXT, nullable. Custom instructions displayed to students.
- `offline_entry_mode` — ENUM('BULK_TOTAL','QUESTION_WISE'), default 'QUESTION_WISE'. How marks are entered for offline.

### lms_exam_paper_sets
- `id` — INT UNSIGNED PK.
- `exam_paper_id` — INT UNSIGNED FK to lms_exam_papers.id.
- `set_code` — VARCHAR(20), unique per paper. E.g., 'SET_A'.
- `set_name` — VARCHAR(50). E.g., 'Paper Set A'.

### lms_exam_blueprints
- `id` — INT UNSIGNED PK.
- `exam_paper_id` — INT UNSIGNED FK to lms_exam_papers.id.
- `section_name` — VARCHAR(50), default 'Section A'. Unique per paper.
- `question_type_id` — INT UNSIGNED FK to slb_question_types.id, nullable.
- `instruction_text` — TEXT, nullable. Section-specific instructions.
- `total_questions` — INT UNSIGNED. Number of questions in this section.
- `marks_per_question` — DECIMAL(5,2), nullable. Fixed marks if uniform.
- `total_marks` — DECIMAL(8,2). Total marks for this section.
- `ordinal` — TINYINT UNSIGNED, default 1. Display order.

### lms_exam_scopes
- `id` — INT UNSIGNED PK.
- `exam_paper_id` — INT UNSIGNED FK to lms_exam_papers.id.
- `lesson_id` — INT UNSIGNED FK to slb_lessons, nullable.
- `topic_id` — INT UNSIGNED FK to slb_topics, nullable.
- `question_type_id` — INT UNSIGNED FK to slb_question_types, nullable.
- `target_question_count` — INT UNSIGNED, default 0. 0 means all.
- `weightage_percent` — DECIMAL(5,2), nullable. Contribution percentage.

---

## Deep Analysis

### Business Workflows & State Machines

Each paper follows its own status lifecycle (independent of the parent exam):

```
NOT_STARTED ──► IN_PROGRESS ──► SUBMITTED ──► EVALUATION_PENDING ──► EVALUATED ──► RESULT_PUBLISHED
                                                                                        │
                                                                                   CANCELLED / ABSENT
```

The blueprint and scope are designed while the paper is in NOT_STARTED or IN_PROGRESS status. Once paper sets are allocated to students (Tab 6), the blueprint becomes read-only to preserve assessment integrity. The scope (lessons, topics, weightage) can be adjusted until questions are assigned (Tab 5). Paper sets are created as variants of the same paper; each set can have its own question assignment but shares the same blueprint structure.

### Validation Rules & Edge Cases

- **Marks consistency:** `total_marks` of the paper must equal the SUM of all blueprint section `total_marks`. A validation error is raised on save if they differ. The database does not enforce this via constraint — it is application-level logic.
- **Section name uniqueness:** The UNIQUE KEY on `(exam_paper_id, section_name)` prevents duplicate section names within a paper. Error message: "Section name already exists in this paper."
- **Paper set code uniqueness:** The UNIQUE KEY on `(exam_paper_id, set_code)` ensures no duplicate set codes within a paper.
- **Mode consistency:** Online/offline mode is set per paper and cannot be changed once questions are assigned or allocations exist.
- **Difficulty config:** If `ignore_difficulty_config = 1`, the `difficulty_config_id` is ignored entirely. If 0 and `difficulty_config_id` is NULL, no difficulty filtering is applied.
- **Negative marks:** `negative_marks` defaults to 0. If set > 0, the system deducts this amount per wrong answer during result computation.
- **Edge case — single-section blueprint:** Papers with only one section still require a blueprint entry. The system auto-creates a "Section A" default on paper creation.
- **Zero-weightage scope:** A scope entry with `weightage_percent = 0` is allowed and treated as "included but not weighted" for curriculum mapping purposes only.

### Integration Points

- **FKs:** `lms_exam_papers.exam_id` → `lms_exams.id`, `subject_id` → `sch_subjects.id`, `status_id` → `lms_exam_status_events.id`; `lms_exam_blueprints.exam_paper_id` → `lms_exam_papers.id`, `question_type_id` → `slb_question_types.id`; `lms_exam_scopes.exam_paper_id` → `lms_exam_papers.id`, `lesson_id` → `slb_lessons.id`, `topic_id` → `slb_topics.id`; `lms_exam_paper_sets.exam_paper_id` → `lms_exam_papers.id`.
- **Module dependencies:** LMS (exams, status events), SCH (subjects), SLB (question types, lessons, topics).
- **Events emitted:** Paper created/updated events for audit logging. Blueprint change events for cache invalidation on question assignment screens.

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| Add paper to exam | Teacher, Admin | `lms.exam.paper.create` |
| Edit paper details | Teacher, Admin | `lms.exam.paper.edit` |
| Delete paper (no allocations) | Teacher, Admin | `lms.exam.paper.delete` |
| Design blueprint | Teacher, Admin | `lms.exam.blueprint.design` |
| Define scope (lessons/topics) | Teacher, Admin | `lms.exam.scope.define` |
| Create paper sets | Teacher, Admin | `lms.exam.paperset.create` |
| Change paper mode (online/offline) | Admin only | `lms.exam.paper.mode.change` |
| View paper details | Teacher, Admin, Principal | `lms.exam.paper.view` |
