# MarksheetGeneration Tab 5: Class Group & Template Assignment

This screen combines two related tasks: creating marksheet-specific class groups and assigning config templates to classes or groups. Class groups let the school organise classes into categories like Primary (1-5), Middle (6-8), and Secondary (9-12) purely for marksheet configuration purposes. Template assignment then links a config template to individual classes or to an entire class group at once.

---

## How It Works

**Class Group Management (SC-MSG-07a):** The admin creates class groups that are independent from timetable groups. Each group has a name (e.g. "Primary"), a code (e.g. PRIMARY), and a list of classes assigned to it. Any class can belong to only one group. This grouping is used solely within the MarksheetGeneration module to apply the same template configuration across multiple classes.

**Template Assignment (SC-MSG-07):** The assignment screen shows two panels. The left panel lists all class groups and individual classes. The right panel shows available config templates. The admin selects a target (group or individual class) and assigns a template. If a template is assigned to a class group, all classes within that group inherit it. However, if a template is assigned directly to an individual class, that direct assignment overrides the group-level inheritance.

**Practical Configuration (SC-MSG-08):** For subjects that have a theory-practical split — such as Science where theory is 70 marks and practical is 30 marks — the coordinator configures this per class-subject combination. Only subjects with practicals need a row here. Non-practical subjects simply have no configuration and are treated as fully theory.

---

## Important Business Rules

- Marksheet class groups are separate from timetable `sch_class_groups_jnt`. The timetable groups are not reused here.
- A class can belong to at most one marksheet class group. The unique constraint on `msh_class_group_items_jnt` enforces this.
- Direct class assignment in `msh_class_config_jnt` takes priority over group-level assignment. When resolving the template for a class, the system first checks for a direct assignment; if none exists, it checks the class's group assignment.
- Exactly one target must be specified in `msh_class_config_jnt` — either class_id or class_group_id, never both, never neither. This is enforced by a CHECK constraint.
- A template can be assigned to multiple classes and multiple groups simultaneously.
- Practical config is per academic session, class, and subject. The theory_max_marks plus practical_max_marks should equal the exam paper total for that subject.
- Subjects without a practical config row are assumed to have no practical component (100% theory).

---

## Database Columns & Behavior

### msh_class_groups
- `id` — Primary key. INT UNSIGNED, auto-increment.
- `code` — Unique group code. VARCHAR(30). E.g. PRIMARY, MIDDLE, SECONDARY.
- `name` — Display name. VARCHAR(100). E.g. "Primary (1-5)".
- `description` — Optional. VARCHAR(255), nullable.
- `display_order` — SMALLINT UNSIGNED, default 1.
- `is_active` — TINYINT(1), default 1.

### msh_class_group_items_jnt
- `id` — Primary key. INT UNSIGNED, auto-increment.
- `class_group_id` — FK to msh_class_groups. Cascade delete.
- `class_id` — FK to sch_classes. Restrict delete.
- Unique constraint on (class_group_id, class_id) — a class appears in a group only once.

### msh_class_config_jnt
- `id` — Primary key. INT UNSIGNED, auto-increment.
- `config_template_id` — FK to msh_config_templates. Cascade delete.
- `class_id` — Direct class assignment. INT UNSIGNED, nullable. FK to sch_classes.
- `class_group_id` — Group-level assignment. INT UNSIGNED, nullable. FK to msh_class_groups.
- CHECK constraint: exactly one of class_id or class_group_id must be set (not null).
- Indexed on template_id, class_id, and class_group_id for fast resolution.

### msh_subject_practical_configs
- `id` — Primary key. INT UNSIGNED, auto-increment.
- `academic_session_id` — FK to sch_org_academic_sessions_jnt. SMALLINT UNSIGNED.
- `class_id` — FK to sch_classes. INT UNSIGNED. Cascade delete.
- `subject_id` — FK to sch_subjects. INT UNSIGNED. Cascade delete.
- `has_practical` — Flag. TINYINT(1), default 1.
- `theory_max_marks` — Theory portion max. DECIMAL(5,2). E.g. 70.00.
- `practical_max_marks` — Practical portion max. DECIMAL(5,2). E.g. 30.00.
- Unique constraint on (academic_session_id, class_id, subject_id).

---

## Deep Analysis

### Business Workflows & State Machines
Two distinct workflows coexist here:
1. **Class Group Management**: CRUD for `msh_class_groups` and their child class assignments (`msh_class_group_items_jnt`). A class can belong to at most one group.
2. **Template Assignment**: The resolution chain is: check `msh_class_config_jnt` for direct class assignment first; if none exists, check the class's group-level assignment. This is evaluated at computation time, not at assignment time.
3. **Practical Config**: Per class-subject-session, coordinators set theory/practical mark splits for subjects like Science.

### Validation Rules & Edge Cases
- **One-target invariant**: `msh_class_config_jnt` must have exactly one of `class_id` or `class_group_id` set, enforced by CHECK constraint. Application layer must enforce this.
- **Override precedence**: Direct class assignment always beats group-level. If a class is in Group A but has a direct template assignment, the direct template is used. Reassigning the group does not override the direct assignment.
- A class cannot belong to more than one class group. Enforced by UNIQUE on `class_group_items_jnt.class_id`.
- Deleting a class group cascades to `msh_class_group_items_jnt` but does NOT delete `msh_class_config_jnt` group-level rows (they have ON DELETE CASCADE on `class_group_id` so those specific assignments are cleaned up).
- Practical config: `theory_max_marks + practical_max_marks` should equal the exam paper total for the subject. The system should validate but not enforce if the exam paper total varies across sections.
- Subjects without a practical config row are treated as 100% theory.

### Integration Points
- **sch_classes**: Source of classes for grouping and assignment.
- **sch_class_section_jnt**: Not directly used here (class-level, not section-level).
- **sch_subjects**: For practical config.
- **msh_config_templates**: The templates being assigned.
- **msh_class_groups** / **msh_class_group_items_jnt**: Marksheet-specific groupings.
- **msh_marksheet_schedules** (indirect): Computation engine reads `msh_class_config_jnt` to resolve templates per class.

### Permissions Matrix
| Role | View Groups/Assignments | Create/Edit Groups | Assign Templates | Configure Practical Splits |
|---|---|---|---|---|
| Super Admin | Yes | Yes | Yes | Yes |
| School Admin | Yes | Yes | Yes | Yes |
| Principal | Yes | Yes | Yes | Yes |
| Coordinator | Yes | Yes (own school) | Yes (own school) | Yes |
| Class Teacher | Yes (read-only) | No | No | No |
| Subject Teacher | No | No | No | No |
| Student/Parent | No | No | No | No |
