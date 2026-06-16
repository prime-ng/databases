# Feedback Tab 5: Question Bank

This screen manages the individual questions that make up a feedback template. Questions are grouped by feedback category (theme) and can be of various types including ratings, Likert scales, emojis, yes/no, multiple choice, and free text.

---

## How It Works

When the administrator opens a specific template in edit mode, they see all its questions listed in order, grouped by category. Each question shows its display order number, question text, type icon, required status, weight, and respondent kind filter. The administrator can add, edit, reorder, or delete questions within the template.

Adding a question requires selecting the question type, writing the question text, optionally adding help text, and choosing which respondent kinds should see this question. For multiple choice questions, the administrator defines the options as a set of key-value pairs with codes, labels, and numeric values for scoring. Questions can be marked as required or optional, and can be flagged for reverse scoring where a higher rating indicates worse performance.

Questions are weighted for overall rating calculation. A question with weight 2.00 contributes twice as much to the overall score as a question with weight 1.00. Free text and yes/no questions do not contribute to the overall rating regardless of their weight setting.

---

## Important Business Rules

- Questions cannot be added, edited, reordered, or deleted from a template that is locked (is_locked = 1). The template must be unlocked or cloned first.
- Each question must have a unique code within its template. The combination of template_id and code must be unique across active records.
- Reverse-scored questions have their values inverted before aggregation. For a 5-point scale, a raw rating of 1 becomes 5, 2 becomes 4, and so on. This is used for negatively worded questions.
- The respondent kind filter on a question can restrict which respondent types see it. For example, a question about "How was your child's homework?" might only appear for Parent respondents even within a template that also supports Students.
- Free text and yes/no question types are excluded from overall rating calculation. Their purpose is qualitative feedback or simple binary questions.
- Multi-choice options are stored as JSON with code, label, and value for each option. The value is used in numeric aggregations when the option is selected.
- Questions with weight set to 0.00 are treated as informational and do not contribute to any score calculation.
- Deleting a question that has existing answers is blocked to preserve data integrity. The question must be deactivated instead.

---

## Database Columns & Behavior

### fbk_questions
- `id` — Primary key. INT UNSIGNED, auto-increment.
- `template_id` — FK to fbk_templates.id. Which template this question belongs to. INT UNSIGNED. Cascade delete.
- `category_id` — FK to fbk_categories.id. Which theme this question belongs to. INT UNSIGNED, nullable. Set null on delete.
- `code` — Unique code within the template. VARCHAR(60). Unique with template_id and soft-delete.
- `question_text` — The question as displayed to the respondent. TEXT.
- `help_text` — Additional guidance for respondents. VARCHAR(500), nullable.
- `display_order` — Sort position within template and category. SMALLINT UNSIGNED, default 1.
- `question_type_id` — FK to sys_dropdown_table.id (key: fbk_questions.question_type). Rating_5, Rating_10, Likert_5, Emoji_5, Yes_No, Multi_Choice, Free_Text. INT UNSIGNED.
- `is_required` — 1 = respondent must answer. TINYINT(1), default 1.
- `is_reverse_scored` — 1 = higher rating is worse, invert before aggregation. TINYINT(1), default 0.
- `weight` — Contribution weight for weighted average. DECIMAL(4,2), default 1.00.
- `options_json` — Multi_Choice options as JSON array with code, label, value. JSON, nullable.
- `respondent_kind_id` — FK to sys_dropdown_table.id (key: fbk_questions.respondent_kind). Controls visibility by respondent type. INT UNSIGNED.
- `is_active` — Soft delete flag. TINYINT(1), default 1.

---

## Deep Analysis

### Business Workflows & State Machines

Questions are child entities of templates. Their lifecycle is entirely dependent on the template's lock state:

- **Template unlocked**: Questions can be created, edited, reordered, deactivated, and (if no answers exist) hard-deleted.
- **Template locked**: All question mutations are blocked.

No independent state machine on questions — the is_active flag serves as soft-delete. When a question is deactivated (is_active=0), it is hidden from the feedback form but existing answers remain in fbk_answers for historical analytics.

The display_order workflow: administrators drag-and-drop questions to reorder. On save, the system renumbers display_order values (e.g., 10, 20, 30 → 1, 2, 3). Bulk reorder is a single transaction.

### Validation Rules & Edge Cases

- **Lock check on every mutation**: Before any question CRUD operation, the system MUST check fbk_templates.is_locked for the parent template. This is the single most important validation.
- **Unique code per template**: UNIQUE KEY (`template_id`, `code`, `deleted_at`). Code must be unique within a template, including soft-deleted questions.
- **question_type_id validation per template**: If template.rating_scale_max = 5, only Rating_5, Likert_5, Emoji_5 are allowed for numeric types. Rating_10 must be disallowed when max is 5.
- **options_json for Multi_Choice**: Must validate that options_json is a non-empty array when question_type_id = Multi_Choice. Each option must have code (VARCHAR), label (VARCHAR), and value (DECIMAL). Duplicate codes within the array are not allowed.
- **options_json for non-Multi_Choice**: Must be null. System should clear it when question type is changed away from Multi_Choice.
- **Reverse scoring for non-numeric types**: is_reverse_scored should only be allowed for Rating_5, Rating_10, Likert_5, Emoji_5, and Multi_Choice types. Setting it on Yes_No or Free_Text makes no logical sense — the system should warn or reject.
- **Weight 0.00**: Questions with weight 0.00 do not contribute to weighted average. The system should exclude them from the Σ(rating × weight) / Σ(weight) calculation entirely (both numerator and denominator).
- **Free_Text / Yes_No exclusion from rating**: The system must ensure these question types never contribute to overall_rating, regardless of their weight value.
- **Deletion with existing answers**: If any fbk_answers row references this question_id, hard DELETE is blocked. The UI must offer "Deactivate" instead, which sets is_active=0.
- **Category deletion**: If a category is deleted while questions reference it, the ON DELETE SET NULL FK will set category_id to NULL. The questions remain visible but uncategorised.
- **Display order gaps**: After reordering, the system should compact display_order to sequential values (1, 2, 3, ...) to prevent integer overflow on large templates.
- **Bulk operations**: When cloning a template, all questions are deep-copied. The clone's questions must get new IDs but preserve display_order, weights, and all other metadata.

### Integration Points

- **fbk_templates** via template_id — cascade delete; questions are removed when a template is hard-deleted.
- **fbk_categories** via category_id — set null on category delete.
- **sys_dropdown_table** via question_type_id (key: fbk_questions.question_type) and respondent_kind_id (key: fbk_questions.respondent_kind).
- **fbk_answers** via question_id — RESTRICT on delete when answers exist.
- **Rating calculation engine**: The application's rating pipeline reads fbk_questions.weight, is_reverse_scored, and question_type_id to compute overall_rating on response submission.

### Permissions Matrix

| Action | Admin | Principal | Teacher | Student | Parent | Staff |
|---|---|---|---|---|---|---|
| View questions | Yes | Yes | Yes (read-only) | No | No | No |
| Create question | Yes (if unlocked) | No | No | No | No | No |
| Edit question | Yes (if unlocked) | No | No | No | No | No |
| Reorder questions | Yes (if unlocked) | No | No | No | No | No |
| Deactivate question | Yes (if unlocked) | No | No | No | No | No |
| Delete question (no answers) | Yes (if unlocked) | No | No | No | No | No |
