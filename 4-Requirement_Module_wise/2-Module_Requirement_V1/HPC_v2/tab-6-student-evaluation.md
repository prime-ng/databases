# HPC Tab 6: Student Evaluation

This tab is where teachers perform the actual student evaluations that feed into the Holistic Progress Card. Each evaluation assesses a student on a specific subject and competency, using the three HPC ability parameters (Awareness, Sensitivity, Creativity) and three performance descriptors (Beginner, Proficient, Advanced) as defined by the NEP framework.

---

## How It Works

The teacher selects an academic session, class, section, and subject from the filters at the top. The screen then shows a list of students enrolled in that class. Next to each student name, there is an evaluation grid. The grid columns are the competencies available for that subject, and the rows are the three ability parameters (Awareness, Sensitivity, Creativity). Each cell is a dropdown where the teacher selects a performance descriptor — Beginner, Proficient, or Advanced.

When the teacher selects a performance descriptor for a cell, they can also add an evidence type (such as Activity, Assessment, or Observation), link to a specific activity or assessment as evidence, and add optional remarks. The teacher's identity is automatically recorded as the assessor along with the assessment timestamp.

The teacher can save individual evaluations as they go, or use a "Save All" button to save all changes on the current student's grid at once. Previously saved values are pre-populated when the teacher returns to the screen.

A summary panel shows the student's current overall HPC snapshot status and the date of their last evaluation.

---

## Important Business Rules

- A student can have only one evaluation per combination of academic session, student, subject, competency, and ability parameter. Duplicate entries are prevented by a unique constraint. If the teacher re-evaluates, the existing record is updated.
- All three ability parameters (Awareness, Sensitivity, Creativity) must be assessed for each competency. The system enforces this before allowing the evaluation to be marked complete.
- Evidence type is required unless the evaluation is marked as "Observation" type, which allows remarks-only entry.
- If evidence_type is provided, evidence_id is required. The evidence_id must reference a valid entry in the activities or assessments table depending on the evidence type.
- The assessed_by field automatically captures the logged-in user. This cannot be changed manually.
- Evaluations can be saved in an incomplete state (draft). A separate "Mark Complete" action changes the status.
- Teachers can only evaluate students in classes and subjects they are assigned to. Admin and Principal roles can evaluate any student.
- Performance descriptors are system-defined (Beginner, Proficient, Advanced) and cannot be modified per evaluation.

---

## Database Columns & Behavior

### hpc_student_evaluation
- `id` — Primary key. INT UNSIGNED AUTO_INCREMENT.
- `academic_session_id` — FK to slb_academic_sessions. Identifies the session. INT UNSIGNED NOT NULL.
- `student_id` — FK to slb_students. Identifies the student being evaluated. INT UNSIGNED NOT NULL.
- `subject_id` — FK to slb_subjects. The subject this evaluation applies to. INT UNSIGNED NOT NULL.
- `competency_id` — FK to slb_competencies. The specific competency being assessed. INT UNSIGNED NOT NULL.
- `hpc_ability_parameter_id` — FK to hpc_ability_parameters. Which ability is being evaluated (Awareness, Sensitivity, Creativity). INT UNSIGNED NOT NULL.
- `hpc_performance_descriptor_id` — FK to hpc_performance_descriptors. The assigned level (Beginner, Proficient, Advanced). INT UNSIGNED NOT NULL.
- `evidence_type` — FK to sys_dropdown_table. Type of evidence: 'ACTIVITY', 'ASSESSMENT', 'OBSERVATION'. INT UNSIGNED NOT NULL.
- `evidence_id` — FK to slb_activities or related table. The specific evidence record. INT UNSIGNED. NULL allowed.
- `remarks` — Optional teacher remarks. VARCHAR(500). NULL allowed.
- `assessed_by` — FK to slb_users. Auto-captured from logged-in user. INT UNSIGNED. NULL allowed.
- `assessed_at` — Auto-captured timestamp of assessment. TIMESTAMP, default CURRENT_TIMESTAMP.
- `is_active` — Soft enable/disable flag. TINYINT(1), default 1.

---

## Deep Analysis

### Business Workflows & State Machines
- **Evaluation grid workflow:** Teacher selects session → class → section → subject. The screen loads a student list with an evaluation grid where columns are competencies and rows are the three ability parameters (Awareness, Sensitivity, Creativity). Each cell is a dropdown with Beginner/Proficient/Advanced.
- **Draft-vs-Complete state:** Evaluations can be saved in an incomplete (draft) state. The system allows partial saves per row. A separate "Mark Complete" action validates that all three ability parameters are assessed for every competency before transitioning to complete status.
- **Upsert semantics:** The unique constraint on (session, student, subject, competency, ability parameter) means every save is an upsert. If a record exists, it is updated; if not, it is inserted. The UI must communicate this overwrite behavior to the teacher.
- **Evidence linking workflow:** For each evaluation cell, the teacher can optionally attach evidence (Activity, Assessment, or Observation). Selecting an evidence type filters the evidence_id dropdown to the relevant source table.

### Validation Rules & Edge Cases
- **Completeness enforcement:** All three ability parameters (Awareness, Sensitivity, Creativity) must be assessed for each competency before "Mark Complete" succeeds. The system checks this per student per subject. Partial evaluation (some cells empty) is allowed only in draft state.
- **Evidence requirement rules:** If evidence_type is "Activity" or "Assessment", evidence_id is required. If evidence_type is "Observation", remarks-only is allowed and evidence_id can be NULL.
- **Duplicate assessment prevention:** The unique constraint on (`academic_session_id`, `student_id`, `subject_id`, `competency_id`, `hpc_ability_parameter_id`) prevents duplicate entries. If a teacher tries to evaluate the same cell twice, the previous value is overwritten (upsert).
- **Teacher-subject assignment boundary:** A teacher can only evaluate subjects they are assigned to. The subject filter dropdown must be pre-filtered to the teacher's assigned subjects. Admin/Principal sees all subjects.
- **Empty grid edge case:** If no competencies are mapped to the selected subject, the grid has zero columns. The UI should show a message: "No competencies found for this subject. Please configure competencies in the syllabus module."

### Integration Points
- **`hpc_ability_parameters`** — Provides the three fixed rows. Must have exactly AWARENESS, SENSITIVITY, CREATIVITY seeded.
- **`hpc_performance_descriptors`** — Provides the three dropdown values. Must have BEGINNER, PROFICIENT, ADVANCED seeded.
- **`slb_competencies`** — Columns in the grid. Only active competencies for the selected subject are shown.
- **`slb_students`** — Student list filtered by class-section.
- **`hpc_learning_activities`** (Tab 7) — Populates the evidence_id dropdown when evidence_type is "Activity".
- **`slb_users`** — Captures `assessed_by` automatically from the logged-in user.
- **`hpc_student_hpc_snapshot`** — Regenerated when evaluations are marked complete.

### Permissions Matrix
| Action | Teacher | Class Teacher | Principal | Admin |
|---|---|---|---|---|
| View evaluation grid | Own classes only | Own class only | All | All |
| Enter evaluation values | Own subjects only | All subjects in class | All | All |
| Add evidence | Own evaluations only | Own class only | All | All |
| Save draft | ✅ | ✅ | ✅ | ✅ |
| Mark complete | ❌ | ✅ | ✅ | ✅ |
| Edit locked (complete) eval | ❌ | ❌ | ✅ | ✅ |
| View all evaluations | Own only | Own class only | All | All |
