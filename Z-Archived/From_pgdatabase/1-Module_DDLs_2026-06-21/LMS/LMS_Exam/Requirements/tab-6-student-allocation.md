# LMS Exam Tab 6: Student Allocation

This tab is used to assign students to exam papers and paper sets. It supports allocating entire classes, sections, exam-specific groups, or individual students to a particular paper set. This ensures each student knows exactly which paper variant they need to take.

---

## How It Works

The user selects a paper from the exam. They then choose an allocation type: Class, Section, Exam Group, or Individual Student. For Class allocation, the system populates all students enrolled in that class. For Section allocation, it filters further by section. For Exam Group, it uses ad-hoc groups created from the student group management section. For Individual, the user picks specific students from a list.

Once the target group is selected, the user assigns a paper set (e.g., Set A) to them. They can also override scheduling details — date, start time, end time, room, and location — for this allocation if it differs from the paper defaults.

The screen shows a summary table of all allocations for the selected paper: the allocation type, target name, assigned set, scheduled date/time, and room.

The user can create custom student groups directly from this tab by selecting a class and section, giving the group a name, and optionally adding or removing individual students.

---

## Important Business Rules

- A student can be allocated to only one paper set per paper. If a student is already allocated via class/section and then individually allocated, the individual allocation takes precedence.
- Allocation types follow a precedence hierarchy: STUDENT overrides EXAM_GROUP overrides SECTION overrides CLASS.
- When a class is allocated, all students in that class are automatically included. New students added to the class later are not auto-allocated — the allocation must be refreshed.
- Exam groups are reusable across different exams but are created per class-section combination.
- A paper set must have at least one allocation before it can be published for student access.
- Room selection is mandatory if the paper is conducted in school (`conducted_in_school = 1`).
- Scheduled start time must be before end time, and both must fall within the exam's date range.

---

## Database Columns & Behavior

### lms_exam_student_groups
- `id` — INT UNSIGNED PK. Auto-increment.
- `class_id` — INT UNSIGNED FK to sch_classes.id. Source class.
- `section_id` — INT UNSIGNED FK to sch_sections.id. Source section.
- `code` — VARCHAR(50), unique per class+section. Business code e.g., "9th-A_SET-A".
- `name` — VARCHAR(100). Display name e.g., "Class 9th-A, Group SET-A".
- `description` — VARCHAR(255), nullable.
- `is_active` — TINYINT(1), default 1.

### lms_exam_student_group_members
- `id` — INT UNSIGNED PK.
- `group_id` — INT UNSIGNED FK to lms_exam_student_groups.id. Parent group.
- `student_id` — INT UNSIGNED FK to std_students.id. Student included in the group.
- Unique constraint on (group_id, student_id) — a student cannot be in the same group twice.

### lms_exam_allocations
- `id` — INT UNSIGNED PK.
- `exam_paper_id` — INT UNSIGNED FK to lms_exam_papers.id. Target paper.
- `paper_set_id` — INT UNSIGNED FK to lms_exam_paper_sets.id. Assigned set variant.
- `allocation_type` — ENUM('CLASS','SECTION','EXAM_GROUP','STUDENT'). Defines the allocation scope.
- `class_id` — INT UNSIGNED FK to sch_classes.id. Always required.
- `section_id` — INT UNSIGNED FK to sch_sections.id, nullable.
- `exam_group_id` — INT UNSIGNED FK to lms_exam_student_groups.id, nullable.
- `student_id` — INT UNSIGNED FK to std_students.id, nullable.
- `scheduled_date` — DATE, nullable. Override for paper's default schedule.
- `scheduled_start_time` — TIME. Start time of the exam for this allocation.
- `scheduled_end_time` — TIME. End time of the exam for this allocation.
- `conducted_in_school` — TINYINT(1), default 1. Whether exam happens on school premises.
- `room_id` — INT UNSIGNED FK to sch_rooms.id, nullable. Required if conducted_in_school is 1.
- `location` — VARCHAR(100), nullable. Free-text location if conducted outside school.

---

## Deep Analysis

### Business Workflows & State Machines

Student allocation follows a precedence-based assignment workflow. The allocation types form a hierarchy:

```
CLASS (broadest) ──► SECTION ──► EXAM_GROUP ──► STUDENT (most specific)
```

When computing a student's final paper set assignment, the system resolves in order:
1. If a STUDENT-level allocation exists for the student → use that set.
2. Else if an EXAM_GROUP allocation exists that includes the student → use that set.
3. Else if a SECTION allocation exists matching the student's section → use that set.
4. Else if a CLASS allocation exists matching the student's class → use that set.
5. Else → student is not allocated (cannot access the exam).

Allocations can be bulk-created (via class/section/group) or individually created. Refreshing a class-level allocation re-imports the current class roster without removing existing individual overrides.

### Validation Rules & Edge Cases

- **Single-set constraint:** A student can be allocated to only ONE paper set per paper. The system resolves this via the precedence hierarchy, not by rejecting new allocations. If a STUDENT-level allocation conflicts with a CLASS-level one, the STUDENT-level wins and the CLASS-level is ignored for that student.
- **Precedence enforcement:** The application must implement the precedence resolution logic. The database enforces no cross-type uniqueness — it is purely application-level.
- **New student edge case:** When a new student joins a class after a CLASS-level allocation has been created, they are NOT auto-allocated. The allocation must be manually "refreshed" or a new STUDENT-level allocation created.
- **Minimum allocation requirement:** A paper set must have at least one allocation before it can be published. This is a business rule check, not a DB constraint.
- **Room mandatory for in-school:** If `conducted_in_school = 1`, the `room_id` is required. If 0, `room_id` must be NULL and `location` becomes a free-text field.
- **Scheduling time validation:** `scheduled_start_time` must be before `scheduled_end_time`. Both must fall within the exam's `start_date` and `end_date` range.
- **Exam group reuse:** `lms_exam_student_groups` are created per class-section combination but can be reused across different exams for that same class-section.

### Integration Points

- **FKs:** `lms_exam_allocations.exam_paper_id` → `lms_exam_papers.id`, `paper_set_id` → `lms_exam_paper_sets.id`, `class_id` → `sch_classes.id`, `section_id` → `sch_sections.id`, `exam_group_id` → `lms_exam_student_groups.id`, `student_id` → `std_students.id`, `room_id` → `sch_rooms.id`; `lms_exam_student_groups.class_id` → `sch_classes.id`, `section_id` → `sch_sections.id`; `lms_exam_student_group_members.group_id` → `lms_exam_student_groups.id`, `student_id` → `std_students.id`.
- **Module dependencies:** LMS (papers, paper sets), SCH (classes, sections, rooms, students).
- **Events emitted:** Allocation created/updated events for timetable refresh (Tab 7) and student portal notification.

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| Create class allocation | Teacher, Admin | `lms.exam.allocate.class` |
| Create section allocation | Teacher, Admin | `lms.exam.allocate.section` |
| Create exam group allocation | Teacher, Admin | `lms.exam.allocate.group` |
| Create individual allocation | Teacher, Admin | `lms.exam.allocate.student` |
| Refresh class allocation | Teacher, Admin | `lms.exam.allocate.refresh` |
| Create student group | Teacher, Admin | `lms.exam.studentgroup.create` |
| Edit student group | Teacher, Admin | `lms.exam.studentgroup.edit` |
| Override scheduling per allocation | Admin | `lms.exam.allocate.schedule.override` |
| View allocations | Teacher, Admin, Principal | `lms.exam.allocate.view` |
