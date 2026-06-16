# MarksheetGeneration Tab 4: Config Template Builder

This screen is the heart of marksheet configuration. It lets the admin build a reusable blueprint that defines exactly how marks are combined, weighted, and graded to produce a subject-wise marksheet. A template specifies which assessment sources contribute (Exam, Homework, Quiz, Quest), what weightage each source carries, how individual exams within the Exam source are weighted, which Internal Assessment components apply, which Co-Scholastic areas are graded, and which grading schema to use.

---

## How It Works

The admin starts by creating a new template for a specific academic session. They select the marksheet type (e.g. Term-1 Report Card), the exam group (e.g. Term-1), the grading schema from the Syllabus module (e.g. CBSE 9-point or ICSE Division), and the board code (CBSE, ICSE, STATE, CUSTOM) as an informational guide.

In the Scholastic Components section, the admin selects which source modules contribute. Exam is always mandatory. For each selected source (Homework, Quiz, Quest), the admin sets a weightage percentage, and the sum across all sources must equal exactly 100%. For example, Exam = 80%, Homework = 5%, Quiz = 5%, Quest = 10%.

Within the Exam component, the admin configures per-exam weightage. Each exam type in the linked exam group gets a percentage, and these must also sum to 100%. For example, UT-1 = 10%, UT-2 = 10%, HY-EXAM = 80%.

The admin can then define Internal Assessment components — such as Notebook (5 marks), Subject Enrichment (5 marks), Periodic Assessment (10 marks) — and set the maximum marks for each. These IA components appear as separate columns on the marksheet.

In the Co-Scholastic section, the admin defines areas like Work Education, Art Education, Health & Physical Education, and Discipline. Each area has a grading scale (3-point or 5-point). If the BehaviouralAssessment module is active, the Discipline area can be linked to automatically pull the grade from BA.

The admin also sets promotion criteria: the minimum passing percentage (default 33%) and the maximum number of subject failures allowed before a student is detained instead of placed in compartment.

---

## Important Business Rules

- Exam must always be included in every template (is_mandatory = 1 in msh_source_components).
- The sum of weightage_percent across all scholastic components must equal exactly 100%.
- The sum of weightage_percent across all exam types in the exam weightage section must equal exactly 100%.
- Template is immutable once it is linked to a published schedule. To change configuration, the admin must create a new template version.
- Best-of-N is optional and off by default. When enabled, the admin sets how many of the top-scoring unit tests count.
- The grading schema is optional but recommended. If not set, marksheet grades display as percentages only.
- Changing the exam group on an existing template clears all previously configured exam weightages.

---

## Database Columns & Behavior

### msh_config_templates
- `id` — Primary key. INT UNSIGNED, auto-increment.
- `academic_session_id` — FK to sch_org_academic_sessions_jnt. SMALLINT UNSIGNED.
- `marksheet_type_id` — FK to msh_marksheet_types. INT UNSIGNED.
- `exam_group_id` — FK to msh_exam_groups. INT UNSIGNED.
- `grading_schema_id` — FK to slb_grade_division_master. INT UNSIGNED, nullable.
- `code` — Unique template code within the session. VARCHAR(50).
- `name` — Display name. VARCHAR(150).
- `board_code` — Board affiliation hint. VARCHAR(50). CBSE, ICSE, STATE, CUSTOM.
- `passing_percentage` — Minimum to pass a subject. DECIMAL(5,2), default 33.00.
- `compartment_max_failures` — Max failures before detention. TINYINT UNSIGNED, default 2.
- `is_best_of_n_enabled` — Toggle for best-of-N. TINYINT(1), default 0.
- `best_of_n_count` — How many to count when best-of-N is on. TINYINT UNSIGNED, nullable.
- `is_locked` — Immutable flag after publication. TINYINT(1), default 0.

### msh_template_scholastic_components
- `id` — Primary key. INT UNSIGNED, auto-increment.
- `config_template_id` — FK to msh_config_templates. Cascade delete.
- `source_component_id` — FK to msh_source_components. Restrict delete.
- `weightage_percent` — Contribution percentage. DECIMAL(5,2). Sums to 100 across all rows for a template.
- `max_marks` — Optional max marks for this component. DECIMAL(8,2), nullable.
- Unique constraint on (config_template_id, source_component_id).

### msh_source_components
- `id` — Primary key. INT UNSIGNED, auto-increment. Seeded: 1=EXAM, 2=HOMEWORK, 3=QUIZ, 4=QUEST.
- `code` — Component code. VARCHAR(30). EXAM, HOMEWORK, QUIZ, QUEST.
- `name` — Display name. VARCHAR(100).
- `is_mandatory` — 1 for Exam (always required). TINYINT(1).

### msh_template_exam_weightages
- `id` — Primary key. INT UNSIGNED, auto-increment.
- `config_template_id` — FK to msh_config_templates. Cascade delete.
- `exam_type_id` — FK to lms_exam_types. Restrict delete.
- `weightage_percent` — Percentage contribution of this exam type. DECIMAL(5,2).
- `max_marks` — Max marks for this exam type. DECIMAL(8,2), nullable.
- Unique constraint on (config_template_id, exam_type_id).

### msh_template_ia_components
- `id` — Primary key. INT UNSIGNED, auto-increment.
- `config_template_id` — FK to msh_config_templates. Cascade delete.
- `ia_component_type_id` — FK to msh_ia_component_types. Restrict delete.
- `max_marks` — Max marks for this IA component per subject. DECIMAL(5,2).
- `display_order` — Column order on marksheet. SMALLINT UNSIGNED, default 1.
- Unique constraint on (config_template_id, ia_component_type_id).

### msh_ia_component_types
- `id` — Primary key. INT UNSIGNED, auto-increment. Seeded: NOTEBOOK, SUB_ENRICHMENT, PERIODIC_ASSESS, PARTICIPATION.
- `code` — Component type code. VARCHAR(30). UNIQUE.
- `name` — Display name. VARCHAR(100).
- `display_order` — SMALLINT UNSIGNED, default 1.

### msh_template_coscholastic_components
- `id` — Primary key. INT UNSIGNED, auto-increment.
- `config_template_id` — FK to msh_config_templates. Cascade delete.
- `name` — Area name. VARCHAR(100). E.g. Work Education, Art Education.
- `code` — Area code. VARCHAR(30). E.g. WORK_ED, ART_ED, HEALTH_PE, DISCIPLINE.
- `grading_scale` — 3_POINT or 5_POINT. VARCHAR(50), default '3_POINT'.
- `is_ba_linked` — 1 if area auto-populates from BehaviouralAssessment. TINYINT(1), default 0.
- `display_order` — SMALLINT UNSIGNED, default 1.
- Unique constraint on (config_template_id, code).

---

## Deep Analysis

### Business Workflows & State Machines
The template starts as **Editable → Locked** (immutable once linked to a published schedule). The `is_locked` flag flips from 0→1 and is never reversed. Until locked, the admin can freely modify scholastic component weightages, exam weightages, IA components, co-scholastic areas, and promotion criteria. Locked templates cannot be edited — the admin must create a new template version instead. Best-of-N toggle is configurable only while editable. Changing the exam group clears all exam weightages (must re-enter).

### Validation Rules & Edge Cases
- **Sum-to-100 invariant**: `msh_template_scholastic_components.weightage_percent` must total exactly 100.00 per template. Enforce on save.
- **Sum-to-100 (exam)**: `msh_template_exam_weightages.weightage_percent` across all exam types in the group must total exactly 100.00.
- Exam component is always mandatory — cannot be removed from the template.
- If best-of-N is enabled, `best_of_n_count` must be at least 1 and at most the number of unit-type exams in the exam group.
- Changing `exam_group_id` triggers a cascading clear of all `msh_template_exam_weightages` rows — warn the admin before proceeding.
- `grading_schema_id` is optional; if null, the marksheet displays percentages only for grades.
- `is_locked` prevents any INSERT/UPDATE/DELETE on child tables (`msh_template_scholastic_components`, `msh_template_exam_weightages`, `msh_template_ia_components`, `msh_template_coscholastic_components`).
- Co-Scholastic `is_ba_linked` flag: if true, the Discipline grade auto-populates from BehaviouralAssessment only if that module is active in the school.

### Integration Points
- **msh_marksheet_types**: Links template to a report card format.
- **msh_exam_groups**: Defines which exam types contribute.
- **slb_grade_division_master**: Grading schema for grade computation.
- **lms_exam_types**: Per-exam weightage targets.
- **msh_source_components**: Fixed seed data (EXAM, HOMEWORK, QUIZ, QUEST).
- **msh_ia_component_types**: Lookup for IA component types.
- **BehaviouralAssessment module**: Optional auto-population source for Discipline grade.
- **msh_marksheet_schedules**: Once a schedule using this template is published, `is_locked` becomes 1.

### Permissions Matrix
| Role | View Templates | Create/Edit Template | Delete Template (unused) | Lock/Unlock Template |
|---|---|---|---|---|
| Super Admin | Yes | Yes | Yes | Yes |
| School Admin | Yes | Yes | Yes (if unpublished) | Yes (via publish) |
| Principal | Yes | Yes | No | No |
| Coordinator | Yes | Yes (own school) | Yes (own, if unused) | No |
| Class Teacher | Yes (read-only) | No | No | No |
| Subject Teacher | No | No | No | No |
| Student/Parent | No | No | No | No |
