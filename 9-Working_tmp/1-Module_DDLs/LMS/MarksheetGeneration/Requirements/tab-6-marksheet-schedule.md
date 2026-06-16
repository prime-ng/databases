# MarksheetGeneration Tab 6: Marksheet Schedule & Attendance

This screen covers the creation and management of marksheet schedules — each schedule represents a single marksheet generation event for a specific set of class-sections. The admin defines when a marksheet is to be issued, which class-sections it covers, and which config template drives the computation. This screen also includes attendance entry, where the class teacher records working days and days present for each student.

---

## How It Works

**Schedule Creation (SC-MSG-10):** The admin creates a schedule by selecting a config template (which brings in the marksheet type, exam group, and all weightages), an academic session, and one or more class-sections from the school's master data. A schedule date can be set to indicate when the marksheet is intended to be issued. The schedule starts in Draft status. Once created, the admin can edit the class-section list but cannot change the template after the first computation.

**Schedule Dashboard (SC-MSG-09):** All schedules are listed here with their status, linked configuration, covered class-sections, and student count. From this list, the admin can trigger computation, navigate to the review grid, publish results, or unlock and recompute. Each row shows action buttons that are context-sensitive based on the current status.

**Attendance Entry (SC-MSG-09a):** For each class-section in a schedule, the class teacher can enter attendance summary data — total working days in the period and days the student was present. These numbers appear on the printed marksheet. In Phase 1, data is entered manually. In Phase 2, the system will auto-populate from the Attendance module if available, with a flag indicating the source. Teachers can enter attendance for all students in a class-section using a simple grid.

---

## Important Business Rules

- A schedule cannot be computed until a config template is assigned and all class-sections in the schedule have a template resolution.
- Once a schedule is computed for the first time, the config_template_id cannot be changed.
- A schedule can be deleted only while it is in Draft status. Computed or published schedules are locked against deletion.
- Attendance entries are optional. If no attendance data exists for a student, the marksheet shows dashes or "N/A".
- For the same schedule, a student can have only one attendance record. The unique constraint on (schedule_id, student_id) enforces this.
- Total working days and days present are stored as small integers. Present days cannot exceed working days; the system validates this on save.

---

## Database Columns & Behavior

### msh_marksheet_schedules
- `id` — Primary key. INT UNSIGNED, auto-increment.
- `config_template_id` — FK to msh_config_templates. INT UNSIGNED. Restrict delete.
- `academic_session_id` — FK to sch_org_academic_sessions_jnt. SMALLINT UNSIGNED.
- `code` — Unique schedule code within session. VARCHAR(50).
- `name` — Display name. VARCHAR(150).
- `schedule_date` — Intended issuance date. DATE, nullable.
- `status_id` — Lifecycle status. FK to sys_dropdowns. DRAFT/COMPUTED/REVIEWED/PUBLISHED/LOCKED.
- `last_computed_at` — Last successful computation timestamp. DATETIME, nullable.
- `total_students` — Populated after computation. INT UNSIGNED, nullable.
- `is_locked` — Publication lock. TINYINT(1), default 0.
- `locked_at` — When locked. DATETIME, nullable.
- `locked_by` — FK to sys_users. INT UNSIGNED, nullable.
- `unlock_reason` — Mandatory text when unlocking. TEXT, nullable.
- `unlocked_at` — DATETIME, nullable.
- `unlocked_by` — FK to sys_users. INT UNSIGNED, nullable.

### msh_schedule_class_jnt
- `id` — Primary key. INT UNSIGNED, auto-increment.
- `schedule_id` — FK to msh_marksheet_schedules. Cascade delete.
- `class_section_id` — FK to sch_class_section_jnt. Restrict delete.
- Unique constraint on (schedule_id, class_section_id).

### msh_student_attendance
- `id` — Primary key. INT UNSIGNED, auto-increment.
- `schedule_id` — FK to msh_marksheet_schedules. Cascade delete.
- `student_id` — FK to std_students. Restrict delete.
- `total_working_days` — Total school days in the period. SMALLINT UNSIGNED, nullable.
- `days_present` — Days the student attended. SMALLINT UNSIGNED, nullable.
- `entered_by` — FK to sys_users (teacher). INT UNSIGNED, nullable. NULL if auto-populated.
- `is_auto_populated` — Flag if from Attendance module. TINYINT(1), default 0.
- Unique constraint on (schedule_id, student_id).

---

## Deep Analysis

### Business Workflows & State Machines
The schedule follows the core lifecycle: **Draft → Computed → Reviewed → Published → Locked**.
- **Draft**: Editable — admin can add/remove class-sections and change template. Deletable.
- **Computed** (first computation): Template locks; class-section list locks. Attendance can be entered.
- **Reviewed**: Admin confirms results.
- **Published**: Results visible to students/parents. All marks become read-only.
- **Locked**: Final state. Only super admin/principal can unlock by providing a mandatory reason (≥10 chars), which reverts status to Computed and allows recomputation.

Attendance entry is a parallel sub-workflow: the class teacher records `total_working_days` and `days_present` per student. In Phase 1, this is manual; Phase 2 adds auto-population from the Attendance module with an `is_auto_populated` flag.

### Validation Rules & Edge Cases
- A schedule cannot be computed if any class-section in `msh_schedule_class_jnt` lacks a resolved config template (either direct or group-level).
- Template cannot be changed after first computation (`last_computed_at IS NOT NULL`). Enforce at application layer.
- Schedule deletion is only allowed in Draft status. Computed+ schedules use soft delete or block entirely.
- Attendance: `days_present <= total_working_days`. Validate on save. If null, marksheet shows "N/A".
- One attendance record per (schedule_id, student_id). Re-entry updates the existing record.
- `schedule_date` is optional — if null, the marksheet shows "Date of Issue" as blank.
- `unlock_reason` is mandatory when unlocking; min 10 characters.

### Integration Points
- **msh_config_templates**: The template driving computation. FK restrict delete after first compute.
- **sch_class_section_jnt**: Class-sections covered by this schedule.
- **sch_org_academic_sessions_jnt**: Session scoping.
- **sys_users**: Creator, locker, unlocker, attendance enterer.
- **std_students**: Students with attendance records.
- **Attendance module** (Phase 2): Auto-population source for attendance data.

### Permissions Matrix
| Role | Create Schedule | Edit Draft | Delete Draft | Compute | Enter Attendance | Unlock |
|---|---|---|---|---|---|---|
| Super Admin | Yes | Yes | Yes | Yes | Yes | Yes |
| School Admin | Yes | Yes | Yes | Yes | Yes | Yes |
| Principal | Yes | Yes | Yes | Yes | Yes | Yes |
| Coordinator | Yes | Yes | Yes | Yes | No | No |
| Class Teacher | No | No | No | No | Own class-sections only | No |
| Subject Teacher | No | No | No | No | No | No |
| Student/Parent | No | No | No | No | No | No |
