# LMS Exam Tab 9: Result Publishing

This tab handles the final step of the exam lifecycle — computing, reviewing, and publishing results. Depending on the exam's configuration, results can be published immediately after evaluation, on a scheduled date, or manually by an authorized user.

---

## How It Works

The screen shows a list of all papers under the selected exam that have completed evaluation. For each paper, it displays the subject, number of students evaluated, marks range, and current publish status.

The user clicks "Compute Results" to trigger the calculation engine. The system calculates each student's total marks (summing per-question scores), computes the percentage against the paper's total_marks, determines pass/fail based on passing_percentage, and assigns a grade using the exam's grading schema. Results are stored in a staging table and shown in a preview grid before publishing.

The preview grid shows each student's name, admission number, total marks, percentage, grade, and pass/fail status. The user can review and, if needed, manually override individual marks or grades with proper audit logging.

When the user clicks "Publish Results," the system executes the configured publishing mode:
- **Immediate**: Results are made visible to students and parents immediately.
- **Scheduled**: Results are queued to be published at the configured date/time. The system publishes them automatically at that time.
- **Manual**: The screen shows a "Publish" button. Results remain hidden until explicitly published.

After publishing, students and parents can view results in their respective portals (marks card view).

---

## Important Business Rules

- Results can only be published after all papers under the exam have been evaluated (all non-absent students have marks).
- Partial publishing is not allowed — either all papers of an exam are published together, or none.
- If a paper has no evaluated students (all absent), the system still allows result computation with zero scores.
- Manual mark overrides before publishing are allowed but logged. After publishing, overrides require reopening the result via a grievance process.
- Grade assignment follows the grading schema linked to the exam. If no schema is set, the system uses a default percentage-to-grade mapping.
- Once results are published, the exam status transitions to RESULT_PUBLISHED. The result cannot be unpublished, but it can be "reopened" for corrections (which is logged).
- Students see only their own results. Parents see results linked to their children. Teachers see results for their assigned classes.
- A notification (email/SMS/in-app) is optionally sent to students and parents when results are published.

---

## Database Columns & Behavior

### lms_exams (publishing control)
- `result_published` — ENUM('IMMEDIATE','SCHEDULED','MANUAL'), default 'MANUAL'. Controls the publishing mechanism.
- `scheduled_result_at` — DATETIME, nullable. Used when result_published is SCHEDULED.
- `is_result_published` — TINYINT(1), default 0. Set to 1 by the system when results are released.
- `status_id` — INT UNSIGNED FK to lms_exam_status_events.id. Updated upon publishing.
- `grading_schema_id` — INT UNSIGNED FK to slb_grade_division_master, nullable. Defines grade boundaries.

### lms_exam_papers (per-paper result data)
- `total_marks` — DECIMAL(8,2). Used for percentage calculation.
- `passing_percentage` — DECIMAL(5,2). Threshold for pass/fail determination.
- `status_id` — Evaluated status is a prerequisite for computing results for this paper.

---

## Deep Analysis

### Business Workflows & State Machines

Result publishing is the terminal workflow of the exam lifecycle. The state machine for result processing is:

```
NOT_STARTED ──► COMPUTED (preview) ──► PUBLISHED ──► REOPENED (grievance)
                                              │
                                         (final for most exams)
```

- **NOT_STARTED:** Evaluation is still in progress. Result computation is blocked until all papers are EVALUATED.
- **COMPUTED (Preview):** Results are calculated but not visible to students. The admin reviews the preview grid and can override individual marks (logged).
- **PUBLISHED:** Results are visible to students/parents according to the `result_published` mode:
  - **IMMEDIATE:** Visible as soon as computation completes.
  - **SCHEDULED:** Queued for publication at `scheduled_result_at`. A cron job/worker publishes at the scheduled time.
  - **MANUAL:** Hidden until the admin clicks "Publish."
- **REOPENED:** After publication, if corrections are needed, an authorized user can "reopen" the result. This transitions the status back to a special review state and logs the action. Changes require re-publication.

All papers in an exam must be EVALUATED before result computation. Partial publishing (publishing only some papers) is not allowed.

### Validation Rules & Edge Cases

- **All-papers-evaluated prerequisite:** Result computation is blocked unless ALL papers under the exam have `status_id` = EVALUATED. The UI shows a checklist of papers and their evaluation status.
- **All-absent paper edge case:** If a paper has no evaluated students (all marked Absent), computation proceeds with zero scores for all students in that paper.
- **Grade assignment:** Uses the exam's `grading_schema_id`. If NULL, falls back to the school's default grading schema (a percentage-to-grade mapping). The fallback must be configured; if not, result computation is blocked.
- **Pass/fail logic:** A student passes a paper if their percentage >= `passing_percentage`. Overall exam pass/fail is determined by passing ALL papers (AND logic, configurable).
- **Override audit trail:** Every manual override of marks or grades is logged with: who, what (old value, new value), when, and why. Overrides after publication additionally require a grievance ticket reference.
- **Scheduled publication:** If `result_published = SCHEDULED` and `scheduled_result_at` is in the past when computation happens, the system publishes immediately and logs a warning.
- **Notification trigger:** On publish, the system optionally sends email/SMS/in-app notifications to students and parents. Notification failures are logged but do not block the publish operation.
- **No un-publish:** Once published, results cannot be "un-published." The only way to correct is to reopen (which logs the action, hides results temporarily, and requires re-publication).

### Integration Points

- **FKs:** `lms_exams.result_published` / `scheduled_result_at` / `is_result_published` / `status_id` → `lms_exam_status_events.id`, `grading_schema_id` → `slb_grade_division_master.id`; `lms_exam_papers.total_marks`, `passing_percentage`, `status_id` (referenced during computation).
- **Module dependencies:** LMS (exams, papers), SLB (grading schemas), SYS (users for audits), NOT (notifications for email/SMS).
- **Events emitted:** `result.published` event triggers student/parent notifications. `result.reopened` event for audit/compliance. Status transitions logged in `lms_exam_status_events`.

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| Compute results | Teacher, Admin | `lms.exam.result.compute` |
| Preview results | Teacher, Admin, Principal | `lms.exam.result.preview` |
| Override marks/grades (pre-publish) | Admin | `lms.exam.result.override` |
| Publish results (manual mode) | Admin, Principal | `lms.exam.result.publish` |
| Schedule result publication | Admin | `lms.exam.result.schedule` |
| Reopen results (post-publish) | Admin, Principal | `lms.exam.result.reopen` |
| View published results | Teacher, Admin, Principal | `lms.exam.result.view` |
| View own results | Student | `lms.exam.result.view.own` |
| View child results | Parent | `lms.exam.result.view.child` |
- `status_id` — Evaluated status is a prerequisite for computing results for this paper.
