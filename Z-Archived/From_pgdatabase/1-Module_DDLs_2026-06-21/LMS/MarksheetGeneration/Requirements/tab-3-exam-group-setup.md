# MarksheetGeneration Tab 3: Exam Group Setup

This screen allows the admin to group individual exam types into logical collections called exam groups. An exam group represents a term or a reporting period — for example, Term-1 might include Unit Test 1, Unit Test 2, and the Half-Yearly Exam. These groups are then linked to config templates so the computation engine knows which exams to include when calculating marksheet results.

---

## How It Works

The admin first creates an exam group by giving it a code and name (e.g. code = TERM1, name = "Term-1") within a specific academic session. Each exam group belongs to exactly one academic session. Optional start and end dates can be set for the term, which later serve as the date range filter for aggregating homework, quiz, and quest scores.

Once the group is created, the admin selects which exam types from the LmsExam module belong to this group. The exam types available for selection come from the lms_exam_types table — these are the types already defined in the school's exam system, such as UT-1, UT-2, HY-EXAM, and ANNUAL-EXAM. The admin chooses the types and sets their display order, which determines the column sequence on the marksheet.

A typical school might have 2 to 4 exam groups per session: Term-1, Term-2, Annual, and possibly a Pre-Board group.

---

## Important Business Rules

- Each exam group is scoped to a single academic session. An exam type can belong to multiple exam groups (e.g. HY-EXAM could be in both Term-1 and Annual groups).
- An exam group must contain at least one exam type. The system validates this on save.
- An exam group cannot be deleted if any config templates reference it.
- The display_order field on group items controls the column order on the marksheet. Lower numbers appear first (leftmost).
- The start_date and end_date on the exam group are used as the default date range for homework/quiz/quest score aggregation. Individual schedules can override this range.

---

## Database Columns & Behavior

### msh_exam_groups
- `id` — Primary key. INT UNSIGNED, auto-increment.
- `academic_session_id` — FK to sch_org_academic_sessions_jnt. SMALLINT UNSIGNED. Scopes the group to a session.
- `code` — Unique code within the session. VARCHAR(30). UNIQUE with academic_session_id.
- `name` — Display name. VARCHAR(100). E.g. "Term-1".
- `description` — Optional. VARCHAR(255), nullable.
- `start_date` — Term start date. DATE, nullable. Used for HW/Quiz/Quest date range filtering.
- `end_date` — Term end date. DATE, nullable.
- `is_active` — TINYINT(1), default 1.
- `created_by` — FK to sys_users. INT UNSIGNED.
- `updated_by` — FK to sys_users. INT UNSIGNED, nullable.

### msh_exam_group_items_jnt
- `id` — Primary key. INT UNSIGNED, auto-increment.
- `exam_group_id` — FK to msh_exam_groups.id. INT UNSIGNED. Cascade delete.
- `exam_type_id` — FK to lms_exam_types.id. INT UNSIGNED. Restrict delete.
- `display_order` — Column order on the marksheet. SMALLINT UNSIGNED, default 1.
- Unique constraint on (exam_group_id, exam_type_id) — each exam type appears once per group.

---

## Deep Analysis

### Business Workflows & State Machines
Simple CRUD lifecycle: **Active → Inactive** (toggle `is_active`) or **Active → Deleted** (soft delete, blocked when templates reference the group). Exam group items (exam types) are maintained as a child collection — the admin adds/removes exam types and sets display order. The exam group's `start_date` / `end_date` serve as the default date range for homework/quiz/quest aggregation but can be overridden per schedule.

### Validation Rules & Edge Cases
- An exam group must contain at least one exam type before saving. Validate at both client and server.
- The same `exam_type_id` can appear in multiple exam groups (e.g., HY-EXAM in both Term-1 and Annual). No cross-group uniqueness constraint.
- Changing `academic_session_id` on an existing group is forbidden if any config templates reference it (enforced by FK restrict).
- Delete guard: if `msh_config_templates.exam_group_id` references this group, deletion is blocked. Show dependent templates.
- `display_order` on `msh_exam_group_items_jnt` controls marksheet column order. Gaps allowed.
- Soft delete filters must be applied consistently across all downstream queries.

### Integration Points
- **lms_exam_types**: Source exam types selected into the group (READ only — MSG never writes here).
- **sch_org_academic_sessions_jnt**: Session scoping.
- **msh_config_templates.exam_group_id**: Downstream FK blocking deletion.
- **msh_exam_group_items_jnt**: Junction with cascade delete from parent.
- **sys_users**: Creator/updater.

### Permissions Matrix
| Role | View Groups | Create/Edit Group | Delete Group | Manage Exam Types in Group |
|---|---|---|---|---|
| Super Admin | Yes | Yes | Yes (if unused) | Yes |
| School Admin | Yes | Yes | Yes (if unused) | Yes |
| Principal | Yes | No | No | No |
| Class Teacher | Yes (read-only) | No | No | No |
| Subject Teacher | No | No | No | No |
| Student/Parent | No | No | No | No |
