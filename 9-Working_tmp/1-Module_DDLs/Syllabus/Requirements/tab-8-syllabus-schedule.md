# Syllabus Tab 8: Syllabus Schedule

This tab handles lesson and topic scheduling — assigning specific topics to teachers, sections, and time periods. It acts as the bridge between the syllabus structure and the actual classroom timetable.

---

## How It Works

The user first selects an academic session, class, section, and subject. A calendar-style or list view displays all scheduled syllabus entries for that selection. Each entry shows the lesson name, topic name, topic level type, assigned teacher, scheduled start and end dates, planned periods, and priority.

To schedule a topic, the user selects a lesson and then drills down to the specific topic (at any level — Topic, Sub-topic, Mini-topic, etc.). The user then picks a teacher from the staff list, sets a start date and end date, enters the number of planned periods, selects a priority (High, Medium, Low), and optionally adds notes. The system also records who created the schedule entry.

The schedule can show entries in a timeline view, where the user can see how teaching is distributed across the academic term. Teachers can see their assigned topics in their own dashboard. When a teacher actually teaches a topic, the system can optionally record the taught-by teacher ID separately from the assigned teacher ID, allowing for substitute teacher tracking.

Entries can be rescheduled by editing the dates. Bulk rescheduling is supported when moving multiple topics forward or backward by a certain number of days.

---

## Important Business Rules

- A topic can be scheduled multiple times for different sections but can only have one active schedule per section at any given time.
- The `assigned_teacher_id` records who is supposed to teach the topic. The `taught_by_teacher_id` records who actually taught it. These can differ when a substitute takes the class.
- Scheduled start date must be before or equal to the scheduled end date. The application enforces this validation.
- The `planned_periods` field indicates how many class periods are allocated. It does not need to match the topic's `duration_minutes` from the topics table — it is a separate planning estimate.
- Priority levels (HIGH, MEDIUM, LOW) help teachers decide which topics to focus on when time is limited.
- When a lesson is deleted, all its schedule entries are cascaded. When a topic is deleted, its schedule entries are cascaded.
- The schedule is scoped to academic session. Entries from a different session are not visible.
- The `section_id` can be NULL, meaning the schedule applies to all sections of the class.
- Deleting a teacher from the system sets `assigned_teacher_id` to NULL (SET NULL) but preserves the schedule entry.

---

## Database Columns & Behavior

### slb_syllabus_schedule
- `id` — Primary key. INT UNSIGNED AUTO_INCREMENT.
- `academic_session_id` — Academic session. INT UNSIGNED FK to sch_org_academic_sessions_jnt. CASCADE on delete.
- `class_id` — Target class. INT UNSIGNED FK to sch_classes. CASCADE on delete.
- `section_id` — Target section (NULL = all sections). INT UNSIGNED FK to sch_sections. CASCADE on delete. Nullable.
- `subject_id` — Target subject. INT UNSIGNED FK to sch_subjects. CASCADE on delete.
- `lesson_id` — Lesson being scheduled. INT UNSIGNED FK to slb_lessons.
- `topic_id` — Specific topic being scheduled. INT UNSIGNED FK to slb_topics. CASCADE on delete.
- `topic_level_type_id` — Level type of the scheduled topic. INT UNSIGNED FK to slb_topic_level_types.
- `scheduled_start_date` — Planned start date. DATE NOT NULL.
- `scheduled_end_date` — Planned end date. DATE NOT NULL.
- `assigned_teacher_id` — Teacher assigned to teach. INT UNSIGNED FK to sch_teachers. SET NULL on delete. Nullable.
- `taught_by_teacher_id` — Teacher who actually taught. INT UNSIGNED FK to sch_teachers. Nullable.
- `planned_periods` — Number of periods planned. SMALLINT UNSIGNED, nullable.
- `priority` — Teaching priority. ENUM('HIGH','MEDIUM','LOW'). Default MEDIUM.
- `notes` — Free-text planning notes. VARCHAR(500), nullable.
- `is_active` — Active flag. TINYINT(1), default 1.
- `created_by` — User who created the schedule entry. INT UNSIGNED, nullable.
- `created_at`, `updated_at` — Standard timestamps. No soft delete (deleted_at not present).

---

## Deep Analysis

### Business Workflows & State Machines
- **Schedule Topic** → select class, section, subject, lesson → drill to topic → pick teacher → set start/end dates, planned periods, priority, notes → INSERT.
- **Reschedule** → edit dates for a single entry or bulk move (shift by N days) → UPDATE `scheduled_start_date`, `scheduled_end_date`.
- **Teacher reassignment** → change `assigned_teacher_id` → optionally record `taught_by_teacher_id` separately (substitute tracking).
- **Delete Schedule** → hard delete (no soft delete; `deleted_at` not present) → user must confirm.
- **State machine**: Entry is ACTIVE (is_active = 1) or INACTIVE (is_active = 0); no workflow states; no soft delete on this table.

### Validation Rules & Edge Cases
- **Date ordering** — `scheduled_start_date <= scheduled_end_date` enforced at application layer (no DB CHECK).
- **Section scoping** — `section_id = NULL` means "all sections"; application must handle this when displaying per-section views.
- **Duplicate scheduling** — a topic can have multiple schedules for different sections, but only one active schedule per `(topic_id, section_id)` at any time; enforced at app layer.
- **Teacher deletion** — `assigned_teacher_id` FK with SET NULL; deleting a teacher nullifies the reference but preserves the schedule.
- **Lesson/Topic deletion** — CASCADE from `slb_lessons`/`slb_topics` removes all linked schedules; must warn user before deleting a lesson with active schedules.
- **Missing `deleted_at`** — hard delete only; no recovery; consider app-level audit trigger for compliance.
- **Bulk reschedule** — shift by ±N days; must validate no dates become invalid (e.g. crossing session boundaries).
- **Planned periods** — independent of `slb_topics.duration_minutes`; no consistency validation required.

### Integration Points
- `slb_lessons` — lesson FK; CASCADE delete removes schedule entries.
- `slb_topics` — topic FK; CASCADE delete.
- `slb_topic_level_types` — topic level type badge display.
- `sch_classes` / `sch_sections` / `sch_subjects` — scope filters.
- `sch_teachers` — assigned teacher and taught-by teacher.
- **Timetable module** — reads schedule entries for calendar display.
- **Teacher dashboard** — shows assigned topics for the current week.
- **Attendance module** — substitute teacher tracking via `taught_by_teacher_id`.

### Permissions Matrix
| Role | Schedule Topic | Reschedule | Reassign Teacher | Delete Entry | View Calendar |
|---|---|---|---|---|---|
| Super Admin | ✅ | ✅ | ✅ | ✅ | ✅ |
| School Admin | ✅ | ✅ | ✅ | ✅ | ✅ |
| Curriculum Coordinator | ✅ | ✅ | ✅ | ✅ | ✅ |
| Teacher | ❌ | ❌ | ❌ | ❌ | ✅ (own) |
| Student/Parent | ❌ | ❌ | ❌ | ❌ | ❌ |
