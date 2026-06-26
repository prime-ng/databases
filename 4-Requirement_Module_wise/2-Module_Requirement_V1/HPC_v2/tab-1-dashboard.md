# HPC Tab 1: HPC Dashboard (Student Snapshot Overview)

This is the landing tab for the Holistic Progress Card module. It gives teachers, administrators, and school leaders a bird's-eye view of all HPC activity across classes, subjects, and students. The dashboard surfaces summary metrics, coverage status, and recent evaluation activity in one place.

---

## How It Works

When a user opens the HPC Dashboard, they see a set of summary cards at the top. One card shows the total number of students who have been evaluated so far in the current academic session. Another card shows the syllabus coverage percentage — how much of the planned syllabus has been taught across all subjects. A third card shows the number of HPC reports already generated, broken down by status (Draft, Final, Published, Archived). A fourth card shows the count of unique learning activities logged.

Below the summary cards, a table lists the most recently evaluated students. Each row shows the student name, class, section, the subject evaluated, the date of last assessment, and the current overall performance level. The user can click any row to drill into that student's full evaluation details.

On the right side, a mini chart shows the distribution of performance descriptors across all evaluated students — how many are at Beginner, Proficient, and Advanced levels. This gives a quick sense of overall cohort performance.

The user can filter the entire dashboard by Academic Session, Class, Section, and Subject. All cards, tables, and charts update instantly when filters change.

---

## Important Business Rules

- The dashboard is read-only. No create, edit, or delete actions are permitted here.
- If no evaluations exist for the selected filters, all cards show zero values and a message is displayed: "No HPC data found for the selected criteria."
- Syllabus coverage percentage is pulled from the latest snapshot date for each combination of class, subject, and academic session.
- The performance distribution chart counts only the most recent evaluation per student per subject.
- The recent evaluations list shows the last 20 evaluated records, ordered by most recent assessment date.
- Users with Principal or Admin roles see data across all classes and sections. Teachers see data only for the classes and subjects they teach.
- The dashboard auto-refreshes when the academic session filter changes.

---

## Database Columns & Behavior

### hpc_student_hpc_snapshot
- `id` — Primary key. Used for counting total snapshots generated. INT UNSIGNED AUTO_INCREMENT.
- `academic_session_id` — FK to slb_academic_sessions. Used as a filter. INT UNSIGNED.
- `student_id` — FK to slb_students. Used for student-level drill-down. INT UNSIGNED.
- `snapshot_json` — Full JSON payload of the student's HPC data. Used for display on the dashboard cards. JSON NOT NULL.
- `generated_at` — Used to determine the most recent snapshot. TIMESTAMP.

### hpc_syllabus_coverage_snapshot
- `id` — Primary key. INT UNSIGNED AUTO_INCREMENT.
- `academic_session_id` — Used as a filter. FK to slb_academic_sessions. INT UNSIGNED.
- `class_id` — Used as a filter. FK to sch_classes. INT UNSIGNED.
- `subject_id` — Used as a filter. FK to slb_subjects. INT UNSIGNED.
- `coverage_percentage` — The syllabus coverage value displayed on the card. DECIMAL(5,2).
- `snapshot_date` — Only the latest snapshot date is used for display. DATE NOT NULL.

### hpc_reports
- `id` — Primary key. Used for counting reports by status. INT AUTO_INCREMENT.
- `status` — ENUM('Draft','Final','Published','Archived'). Counted per status for the status breakdown card.
- `student_id` — FK to std_students. Used to link to student details. INT UNSIGNED.
- `class_id` — FK to sch_classes. Used as a filter. INT UNSIGNED.
- `report_date` — Used for date-range filtering. DATE NOT NULL.

---

## Deep Analysis

### Business Workflows & State Machines
- **Aggregation-as-a-Service workflow:** Snapshot tables (`hpc_student_hpc_snapshot`, `hpc_syllabus_coverage_snapshot`) are materialized views populated by backend jobs, not live queries. A scheduled or event-driven job regenerates snapshots when evaluations are saved or syllabus is updated.
- **No write-back state machine:** This tab is entirely read-only. There is no state to transition through — it is a pure query-and-display surface.
- **Filter-driven reactive rendering:** Every filter change (Academic Session, Class, Section, Subject) triggers a re-query of all four snapshot/report tables simultaneously. The UI must handle partial loading states per card.

### Validation Rules & Edge Cases
- **Zero-data state:** When no evaluations exist, four cards, one table, and one chart must all gracefully degrade to zero values and a single "No HPC data found" message. Partial data (e.g., reports exist but no snapshot) must still render correctly.
- **Syllabus coverage staleness:** If the latest snapshot is older than a configurable threshold (e.g., 30 days), a warning indicator should be shown next to the percentage.
- **Boundary on recent evaluations list:** Hard-coded limit of 20 rows. If fewer than 20 exist, the full list is shown. If a filter combination yields exactly zero matching rows, the table is empty.
- **Chart precision:** Performance distribution counts only the *most recent* evaluation per student per subject. If a student has evaluations in two subjects, both count — but duplicate subjects for the same student are deduplicated by recency.

### Integration Points
- **`slb_academic_sessions`** — All four filter dropdowns and snapshot tables FK here.
- **`hpc_reports`** — Provides per-status counts. Changes in Tab 8 (status transitions) immediately affect dashboard card values.
- **`hpc_student_hpc_snapshot`** — JSON payload is consumed by the dashboard for per-student drill-down rows.
- **`hpc_syllabus_coverage_snapshot`** — Populated by syllabus planner (external to HPC). If the syllabus module is missing, this card returns zero.
- **Role system (`slb_users`, class-teacher mapping)** — Dashboard must filter visible data based on the current user's assigned classes/sections.

### Permissions Matrix
| Action | Teacher | Class Teacher | Principal | Admin |
|---|---|---|---|---|
| View dashboard | Own classes only | Own class only | All classes | All classes |
| Filter by class | Assigned only | Own class only | All | All |
| Filter by subject | Assigned only | All in class | All | All |
| Drill into student | Evaluated by them | In their class | Any | Any |
| Export data | ❌ | ❌ | ✅ | ✅ |
