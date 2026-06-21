# MarksheetGeneration Tab 7: Marks Entry Grid

This screen provides three data-entry interfaces for marks that are owned by the MarksheetGeneration module itself — Internal Assessment marks, Co-Scholastic grades, and any teacher-entered scores that are not fetched from other modules. The exam marks themselves are not entered here; they are read-only from the LmsExam module. This screen is where subject teachers and class teachers contribute their assessments.

---

## How It Works

**Internal Assessment Marks Entry (SC-MSG-12a):** The subject teacher selects a schedule, a class-section, and a subject. The screen shows a grid with students as rows and IA components (Notebook, Subject Enrichment, Periodic Assessment, Participation) as columns. The teacher enters a numeric mark for each student in each component. The system validates that the entered mark does not exceed the component's max_marks as defined in the template. Teachers can save partial entries and return later.

**Co-Scholastic Entry (SC-MSG-06a):** The class teacher selects a schedule and a class-section. The screen shows students as rows and co-scholastic areas (Work Education, Art Education, Health & PE, Discipline) as columns. The teacher enters a grade letter (A, B, C, D, or E depending on the configured grading scale) for each student in each area. For areas linked to BehaviouralAssessment (typically Discipline), the grade may be auto-populated and read-only.

**IA Entry Validation:** Teachers cannot enter marks for a schedule that has already been published. They can edit IA marks freely while the schedule is in Draft or Computed status. Once published, IA marks become read-only. If the schedule is unlocked, teachers can re-enter marks and the schedule must be recomputed.

---

## Important Business Rules

- IA marks are entered per student, per subject, per IA component, per schedule. Each combination is unique.
- The entered mark cannot exceed the max_marks defined in msh_template_ia_components for that component type.
- Co-Scholastic grades follow the grading scale defined in the template (3_POINT = A/B/C or 5_POINT = A/B/C/D/E). The system validates grade values on save.
- For BA-linked co-scholastic areas, the grade is auto-populated from BehaviouralAssessment and is read-only unless the admin explicitly overrides it.
- Marks and grades can be entered in any order — the teacher does not need to complete all subjects or all components in one session.
- Both entry grids support bulk upload via CSV (future enhancement, not in Phase 1).
- Once marks are entered, they persist even if the template configuration changes. Re-entry is only needed after an unlock and recompute cycle.

---

## Database Columns & Behavior

### msh_student_ia_marks
- `id` — Primary key. INT UNSIGNED, auto-increment.
- `schedule_id` — FK to msh_marksheet_schedules. Cascade delete.
- `student_id` — FK to std_students. Restrict delete.
- `subject_id` — FK to sch_subjects. Restrict delete.
- `ia_component_id` — FK to msh_template_ia_components. Restrict delete.
- `marks_obtained` — Entered mark. DECIMAL(5,2), nullable. NULL = not yet entered.
- `max_marks` — Copied from template at entry time. DECIMAL(5,2), NOT NULL.
- `entered_by` — FK to sys_users (teacher). INT UNSIGNED, nullable.
- `entered_at` — When marks were entered. DATETIME, nullable.
- Unique constraint on (schedule_id, student_id, subject_id, ia_component_id).

### msh_student_coscholastic_results
- `id` — Primary key. INT UNSIGNED, auto-increment.
- `schedule_id` — FK to msh_marksheet_schedules. Cascade delete.
- `student_id` — FK to std_students. Restrict delete.
- `coscholastic_component_id` — FK to msh_template_coscholastic_components. Restrict delete.
- `grade` — Grade letter. VARCHAR(10), nullable. E.g. A, B, C.
- `remarks` — Optional text note. VARCHAR(255), nullable.
- `entered_by` — FK to sys_users. INT UNSIGNED, nullable. NULL if auto from BA.
- `entered_at` — DATETIME, nullable.
- `is_auto_from_ba` — 1 if grade was auto-populated from BehaviouralAssessment. TINYINT(1), default 0.
- Unique constraint on (schedule_id, student_id, coscholastic_component_id).

---

## Deep Analysis

### Business Workflows & State Machines
Two independent data-entry sub-workflows:
1. **IA Marks Entry**: Subject teacher selects schedule → class-section → subject → enters numeric marks per student per IA component. Data is saved per cell; partial saves allowed. Editable while schedule is Draft or Computed; read-only once Published. If unlocked and recomputed, marks can be re-entered.
2. **Co-Scholastic Entry**: Class teacher selects schedule → class-section → enters grade letters per student per co-scholastic area. BA-linked areas auto-populate and are read-only unless explicitly overridden.

Both sub-workflows share the same status gate: **Draft/Computed = Editable, Published/Locked = Read-Only**.

### Validation Rules & Edge Cases
- IA `marks_obtained` must not exceed `max_marks` from `msh_template_ia_components`. Enforce per cell.
- IA marks entry is per (schedule_id, student_id, subject_id, ia_component_id) — unique constraint prevents duplicates.
- Co-Scholastic grades must match the template's `grading_scale`: 3_POINT allows A/B/C only; 5_POINT allows A/B/C/D/E. Reject invalid grade letters.
- For BA-linked areas, `is_auto_from_ba = 1` and `entered_by = NULL`. If the admin explicitly overrides, set `is_auto_from_ba = 0` and record `entered_by`.
- Marks can be entered in any order — no requirement to complete all subjects or components in one session.
- Bulk CSV upload is a future enhancement (Phase 2). In Phase 1, only manual grid entry.
- Marks persist across template configuration changes. Only an unlock+recompute cycle forces re-entry.

### Integration Points
- **msh_marksheet_schedules**: Schedule context and status gating.
- **msh_template_ia_components**: Defines which IA components exist and their max marks.
- **msh_template_coscholastic_components**: Defines co-scholastic areas and grading scales.
- **std_students**: Student roster for the grid.
- **sch_subjects**: Subject filter for IA entry.
- **sys_users**: Records who entered marks/grades.
- **BehaviouralAssessment module**: Auto-population source for BA-linked co-scholastic grades.

### Permissions Matrix
| Role | Enter IA Marks | Edit IA Marks | Enter Co-Scholastic | Edit Co-Scholastic | View (Published schedule) |
|---|---|---|---|---|---|
| Super Admin | Yes | Yes | Yes | Yes | Yes |
| School Admin | Yes | Yes | Yes | Yes | Yes |
| Principal | Yes | Yes | Yes | Yes | Yes |
| Coordinator | Yes | Yes | No | No | Yes |
| Class Teacher | No | No | Own class-section only | Own class-section only | Own class-section only |
| Subject Teacher | Own subject & class-section | Own subject & class-section | No | No | Own subject & class-section |
| Student/Parent | No | No | No | No | Yes (read-only) |
