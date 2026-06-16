# MarksheetGeneration Tab 8: Computation & Results Review

This tab covers two critical workflows: triggering the marksheet computation engine and reviewing the computed results before publication. The computation engine aggregates marks from all source modules, applies weightages, computes subject totals, assigns grades, calculates ranks, and determines promotion status. Once computed, the results can be reviewed in a detailed matrix before the admin decides to publish.

---

## How It Works

**Trigger Computation (SC-MSG-11):** When the admin clicks "Compute Results" on a schedule, the system first validates that all pre-conditions are met — all exam results in the linked exam group must be published, every class-section in the schedule must have a config template assignment, and the schedule must not already be published. The computation is dispatched as a queued job that processes class-sections in chunks. A progress screen shows real-time status polling: which class-section is being processed, how many students have been computed, and whether any errors occurred. If computation fails, the error log shows detailed messages for each failure.

**Result Review Grid (SC-MSG-12):** After successful computation, the principal or class teacher opens the review grid. This is a matrix view with students listed as rows and subjects as columns. Each cell shows the exam-wise score breakdown, the total marks, and the grade for that subject. Colour highlighting draws attention to anomalies — absent students shown as "AB", withheld results shown as "WH", scores below passing threshold highlighted in red. The reviewer can filter by class-section and sort by student name or roll number.

**What the Computation Engine Does:** For each student in each class-section, the engine reads exam marks from LmsExam, applies per-exam weightage, then reads homework, quiz, and quest scores from their respective modules and applies component weightages. It adds IA marks entered by teachers, separates theory and practical marks for configured subjects, computes a subject total and grade, then aggregates across all subjects to produce the grand total, overall percentage, overall grade, division, rank, and promotion status.

---

## Important Business Rules

- A schedule can only be computed if its status is Draft or Computed. Published or Locked schedules reject computation.
- Computation is not allowed if any exam type in the linked exam group has unpublished results. The system checks `lms_exam_results.is_published = 1` for all students.
- If a class-section has no config template assignment, the computation skips it and logs an error.
- Absent students show NULL marks_obtained in the exam marks table, displayed as "AB" on the grid.
- Result withheld (`WITHHELD` status) is shown as "WH" on the grid. The overall result_status is also set to WITHHELD.
- When best-of-N is enabled, only the top N unit test scores are counted; the rest are discarded.
- If all source scores for a component are NULL (student has no graded items in the date range), the component score is set to NULL — treated as "not assessed".
- Ranks use dense ranking — students with the same total share the same rank, and the next rank follows consecutively.

---

## Database Columns & Behavior

### msh_student_subject_exam_marks
- `id` — Primary key. INT UNSIGNED, auto-increment.
- `schedule_id` — FK to msh_marksheet_schedules. Cascade delete.
- `student_id` — FK to std_students. Restrict delete.
- `subject_id` — FK to sch_subjects. Restrict delete.
- `exam_type_id` — FK to lms_exam_types. Restrict delete.
- `marks_obtained` — Marks from exam result. DECIMAL(8,2), nullable. NULL means absent.
- `max_marks` — Max possible. DECIMAL(8,2), nullable.
- `result_status` — PASS, FAIL, ABSENT, WITHHELD. VARCHAR(20), nullable.
- `exam_result_id` — Traceability FK to lms_exam_results. INT UNSIGNED, nullable.
- Unique constraint on (schedule_id, student_id, subject_id, exam_type_id).

### msh_student_subject_results
- `id` — Primary key. INT UNSIGNED, auto-increment.
- `schedule_id` — FK to msh_marksheet_schedules. Cascade delete.
- `student_id` — FK to std_students. Restrict delete.
- `subject_id` — FK to sch_subjects. Restrict delete.
- `exam_weighted_total` — Weighted sum of exam marks. DECIMAL(8,2), nullable.
- `theory_marks` — Theory portion. DECIMAL(8,2), nullable.
- `practical_marks` — Practical portion. DECIMAL(8,2), nullable.
- `homework_score` — Homework component. DECIMAL(8,2), nullable.
- `quiz_score` — Quiz component. DECIMAL(8,2), nullable.
- `quest_score` — Quest component. DECIMAL(8,2), nullable.
- `ia_total` — Sum of IA marks. DECIMAL(8,2), nullable.
- `subject_total` — All components combined. DECIMAL(8,2), nullable.
- `subject_max` — Maximum possible. DECIMAL(8,2), nullable.
- `subject_percentage` — Percentage score. DECIMAL(5,2), nullable.
- `subject_grade` — Grade from schema. VARCHAR(10), nullable.
- `is_passed` — Pass/fail flag. TINYINT(1), nullable.
- Unique constraint on (schedule_id, student_id, subject_id).

### msh_student_results
- `id` — Primary key. INT UNSIGNED, auto-increment.
- `schedule_id` — FK to msh_marksheet_schedules. Cascade delete.
- `student_id` — FK to std_students. Restrict delete.
- `class_section_id` — FK to sch_class_section_jnt. Denormalized for queries.
- `grand_total` — Sum of all subject totals. DECIMAL(8,2), nullable.
- `grand_max` — Sum of all subject max marks. DECIMAL(8,2), nullable.
- `overall_percentage` — DECIMAL(5,2), nullable.
- `overall_grade` — From grade schema. VARCHAR(10), nullable.
- `division` — First, Second, Third, Pass, Fail. VARCHAR(30), nullable.
- `rank_in_section` — Rank within class-section. INT UNSIGNED, nullable.
- `rank_in_class` — Rank across all sections. INT UNSIGNED, nullable.
- `total_subjects` — Subjects assessed. TINYINT UNSIGNED, nullable.
- `subjects_passed` — TINYINT UNSIGNED, nullable.
- `subjects_failed` — TINYINT UNSIGNED, nullable.
- `promotion_status` — PROMOTED, DETAINED, COMPARTMENT, PLACED. VARCHAR(30), nullable.
- `result_status` — DECLARED or WITHHELD. VARCHAR(20), nullable.
- `withheld_reason` — VARCHAR(255), nullable.
- Unique constraint on (schedule_id, student_id).

### msh_computation_logs
- `id` — Primary key. INT UNSIGNED, auto-increment. Immutable audit entry.
- `schedule_id` — FK to msh_marksheet_schedules. Cascade delete.
- `action` — COMPUTE, RECOMPUTE, etc. VARCHAR(30).
- `triggered_by` — FK to sys_users. INT UNSIGNED.
- `started_at` — DATETIME, NOT NULL.
- `completed_at` — DATETIME, nullable.
- `duration_seconds` — INT UNSIGNED, nullable.
- `total_students` — INT UNSIGNED, nullable.
- `total_errors` — INT UNSIGNED, default 0.
- `status` — IN_PROGRESS, SUCCESS, FAILED, PARTIAL. VARCHAR(20).
- `error_log` — JSON error messages. TEXT, nullable.
- `remarks` — Free text. TEXT, nullable.

---

## Deep Analysis

### Business Workflows & State Machines
The computation engine is a queued job with real-time progress polling:
1. **Pre-flight validation**: Check all exam types in group have published results; all class-sections have template resolution; schedule is in Draft/Computed status.
2. **Dispatch**: Job queued; log created with status IN_PROGRESS.
3. **Processing**: Iterates class-sections, then students, then subjects. For each student-subject: reads exam marks from `lms_exam_results`, applies weightages, adds IA marks, computes theory/practical split, applies best-of-N if enabled, calculates total, grade, and pass/fail. Aggregates into `msh_student_results` (grand total, percentage, rank, division, promotion status).
4. **Completion**: Log updated to SUCCESS/FAILED/PARTIAL. If PARTIAL, some class-sections succeeded but others errored.

The review grid is a read-only snapshot of computed results. The reviewer can filter by class-section, sort by name/roll number, and visually identify anomalies (red highlights for failures, "AB" for absent, "WH" for withheld).

### Validation Rules & Edge Cases
- Computation blocked if any exam type in the group has `lms_exam_results.is_published = 0` for any student. Check must be efficient.
- Absent students: `marks_obtained = NULL` → displayed as "AB". They are treated as 0 for weighted calculation.
- Withheld students: `result_status = WITHHELD` → overall `result_status = WITHHELD`. Marks are stored but hidden on the PDF until unwithheld.
- Best-of-N: only the top N unit-type exam scores count. Non-unit exam types (e.g., Half-Yearly, Annual) are always included.
- Dense ranking: students with equal totals share the same rank; next rank follows consecutively (1, 2, 2, 3, not 1, 2, 2, 4).
- Promotion status logic: `subjects_passed >= total_subjects` → PROMOTED; failures ≤ `compartment_max_failures` → COMPARTMENT; failures > `compartment_max_failures` → DETAINED.
- If all source scores for a component are NULL, component score = NULL → "Not Assessed" on marksheet.
- Computation is idempotent for the same schedule only if the schedule has been unlocked. Re-computation overwrites all result rows.

### Integration Points
- **lms_exam_results**: Primary marks source (READ only). Must check `is_published = 1`.
- **lms_exam_papers**: Max marks per subject-exam type.
- **LmsHomework**: Homework scores for configured date range.
- **LmsQuiz**: Quiz scores for configured date range.
- **LmsQuest**: Quest scores for configured date range.
- **msh_student_ia_marks**: IA marks entered by teachers.
- **msh_student_attendance**: Attendance data (included in marksheet display, not computation).
- **slb_grade_division_master**: Grading schema for grade boundaries.
- **msh_config_templates**: All weightages, best-of-N, pass criteria.
- **msh_class_config_jnt** + **msh_subject_practical_configs**: Template resolution and theory/practical splits.

### Permissions Matrix
| Role | Trigger Computation | View Review Grid | Filter/Sort Grid | Approve for Publication |
|---|---|---|---|---|
| Super Admin | Yes | Yes | Yes | Yes |
| School Admin | Yes | Yes | Yes | Yes |
| Principal | Yes | Yes | Yes | Yes |
| Coordinator | Yes | Yes | Yes | No |
| Class Teacher | No | Own class-section only | Own class-section only | No |
| Subject Teacher | No | Own subject only | Own subject only | No |
| Student/Parent | No | No | No | No |
