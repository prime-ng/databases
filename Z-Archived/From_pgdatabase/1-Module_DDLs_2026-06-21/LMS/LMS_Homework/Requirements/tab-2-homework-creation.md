# Homework Tab 2: Homework (Main List & CRUD)

This is the main tab where teachers create, view, and manage homework. It is the central hub of the Homework module. Building a homework task involves setting up the details, attaching files, setting grading rules, defining the release condition, and publishing.

---

## Section 1: Viewing the Homework List

The teacher sees a table of all homework they have access to. Each row shows the title, topic, class and subject as badges, assignment and due dates, maximum and passing marks, release condition, status (Draft/Published/Archived), and action buttons.

Filters at the top allow narrowing by search (title/description), Class, Section, Subject, and Date Range. A toggle switches between showing Active and Inactive homework.

---

## Section 2: Creating a New Homework

When the teacher clicks "Add Homework," they are taken to a multi-step creation form. The form does not auto-save — all data must be completed and submitted in one go.

**Basic Information:** The teacher selects the class and optionally a section. If no section is selected, the homework applies to all sections in that class. They then select the subject. The system loads available lessons and topics based on the selected class and subject. They can link the homework to a specific lesson and topic — this links it to the syllabus for release-condition tracking.

**Homework Details:** The teacher enters a title and a detailed description with a rich text editor supporting HTML. They choose a submission type from a dropdown — TEXT (students type their response), FILE (students upload a file), HYBRID (both text and file), or OFFLINE_CHECK (submitted physically, only graded online). They can attach supporting files like question sheets, reference material, or handwritten scans.

**Grading Settings:** The teacher toggles whether the homework is gradable. If gradable, they set the maximum marks and passing marks. The passing marks must be less than or equal to the maximum marks. They select a difficulty level (Easy, Medium, Hard). They toggle whether scores are auto-published to students immediately upon grading.

**Scheduling and Release:** The teacher sets the assignment date (when the homework becomes active) and the due date. They choose a release condition — IMMEDIATE (homework is visible as soon as it is published), ON_TOPIC_COMPLETE (homework is released when the linked topic is marked complete in the syllabus planner), or ON_SCHEDULED_DATE (homework is released on a specific scheduled date). They toggle whether late submissions are allowed.

The teacher can write instructions that students will see when they open the homework.

When they click Save, the homework is created in Draft status. The teacher must manually publish it for students to see it.

---

## Section 3: Homework Lifecycle States

A homework moves through three states. Draft means the teacher is still building or reviewing it. Published means it has been released to students — assignment records are created for all enrolled students. Archived means the homework has been retired and no further submissions are accepted.

The teacher can change the status from the list using a dropdown or the Publish button. Publishing triggers the creation of assignment records for every active student in the selected class and section. The release condition determines when those assignments become visible to students.

---

## Section 4: Editing and Deleting

Editing is allowed freely while the homework is in Draft. Once published, some fields are locked. The class, section, and subject cannot be changed after publishing because assignments have already been created for those students. The title, description, dates, marks, and settings can still be changed.

If the teacher deletes a homework, what happens depends on whether it has submissions. A Draft homework can be hard-deleted entirely. A published homework with no submissions can be soft-deleted. A homework with submissions cannot be deleted at all — the teacher gets an error message.

Cloning creates a copy of the homework for a different section within the same class. The clone starts as Draft. The teacher selects a target section from a modal, and the system duplicates the homework with all settings and attachments.

---

## Important Business Rules

- The class and subject are locked once the homework is saved. They cannot be changed after first save.
- Publishing requires the homework to be in Draft status. If already Published or Archived, the publish button is hidden.
- When published, assignment records are created for every active student in the class (and section if specified). This happens in a database transaction.
- The release condition determines when students can see the homework. IMMEDIATE makes it visible right after publishing. ON_TOPIC_COMPLETE waits for the syllabus topic to be marked complete. ON_SCHEDULED_DATE waits for the scheduled date.
- Only Draft homework can be deleted without restrictions. Published homework with submissions cannot be deleted at all.
- Cloning is only allowed within the same class. The target section must be different from the source section.
- Attached files are carried over during cloning using the Spatie Media Library.
- The homework title can be changed at any time, even after publishing.
- The creation form does not auto-save. Navigating away mid-way loses all unsaved data.
- The academic session is automatically set to the current active session. If no current session exists, the save is blocked.

---

## Database Columns & Behavior

### lms_homework
- `id` — Primary key. INT UNSIGNED, auto-increment.
- `academic_session_id` — Current academic session. INT UNSIGNED, FK to sch_org_academic_sessions_jnt. RESTRICT on delete. Set automatically to the current session.
- `class_id` — Target class. INT UNSIGNED, FK to sch_classes. RESTRICT on delete. Locked after first save.
- `section_id` — Target section (optional). INT UNSIGNED, FK to sch_sections. SET NULL on delete. NULL means all sections.
- `subject_id` — Target subject. INT UNSIGNED, FK to sch_subjects. RESTRICT on delete. Locked after first save.
- `lesson_id` — Linked lesson from syllabus. INT UNSIGNED, FK to slb_lessons. SET NULL on delete. Optional.
- `topic_id` — Linked topic from syllabus. INT UNSIGNED, FK to slb_topics. SET NULL on delete. Optional.
- `schedule_id` — Syllabus schedule entry for ON_TOPIC_COMPLETE release. INT UNSIGNED, FK to slb_syllabus_schedule. SET NULL on delete. Required if release_condition = ON_TOPIC_COMPLETE.
- `title` — Homework title. VARCHAR(255), NOT NULL. Can be changed anytime.
- `description` — Full homework description. LONGTEXT, NOT NULL. Supports HTML.
- `hw_attachment_media_id` — JSON array of attached file metadata. JSON, DEFAULT NULL. Stores file_name, file_path, file_size, mime_type, uploaded_at for each attachment.
- `submission_type_id` — How students submit. INT UNSIGNED, FK to sys_dropdown_table. RESTRICT on delete. Values: TEXT, FILE, HYBRID, OFFLINE_CHECK.
- `is_gradable` — Whether homework is graded. TINYINT(1), default 1. 0 = not gradable (no marks). 1 = gradable.
- `max_marks` — Maximum marks if gradable. DECIMAL(5,2), DEFAULT NULL. Required if is_gradable = 1.
- `passing_marks` — Minimum passing marks. DECIMAL(5,2), DEFAULT NULL. Required if is_gradable = 1. Must be ≤ max_marks.
- `difficulty_level_id` — Difficulty level. INT UNSIGNED, FK to slb_complexity_level. SET NULL on delete. Values: EASY, MEDIUM, HARD.
- `auto_publish_score` — Auto-publish scores to students. TINYINT(1), default 0. 1 = score visible immediately on grading.
- `assign_date` — When homework becomes active. DATETIME, NOT NULL.
- `due_date` — Default due date for all students. DATETIME, NOT NULL. Can be overridden per-student in assignments.
- `allow_late_submission` — Default late submission policy. TINYINT(1), default 0. 0 = deny, 1 = allow. Can be overridden per-student.
- `realease_condition` — Release trigger. ENUM('IMMEDIATE', 'ON_TOPIC_COMPLETE', 'ON_SCHEDULED_DATE'), default 'ON_TOPIC_COMPLETE'. Controls when assignment becomes visible.
- `release_scheduled_date` — Specific release date for ON_SCHEDULED_DATE. DATETIME, DEFAULT NULL. Required if release_condition = ON_SCHEDULED_DATE.
- `status_id` — Homework status. INT UNSIGNED, FK to sys_dropdown_table. RESTRICT on delete. Values: DRAFT, PUBLISHED, ARCHIVED.
- `is_active` — Soft enable/disable. TINYINT(1), default 1. Can be toggled from list.
- `created_by` — Teacher who created. INT UNSIGNED, FK to sys_users. RESTRICT on delete.
- `updated_by` — Last modifier. INT UNSIGNED, FK to sys_users. SET NULL on delete.
- `created_at` — Creation timestamp. TIMESTAMP, NULLABLE.
- `updated_at` — Last update timestamp. TIMESTAMP, NULLABLE.
- `deleted_at` — Soft delete timestamp. TIMESTAMP, NULLABLE.

---

## Deep Analysis

### Business Workflows & State Machines

The homework lifecycle has three explicit states: **DRAFT → PUBLISHED → ARCHIVED**. Publishing triggers bulk assignment creation. Draft is editable; Published has locked fields (class, section, subject); Archived is read-only terminal.

| Transition | Trigger | Side Effects |
|---|---|---|
| DRAFT → PUBLISHED | Teacher clicks Publish | Creates `lms_homework_assignment` rows for all active students. Assignment records inherit release_condition. Notifications sent if IMMEDIATE. |
| PUBLISHED → DRAFT | Teacher unpublishes | Soft-deletes assignment records (restored on re-publish). |
| PUBLISHED → ARCHIVED | Teacher archives | No further submissions accepted. Existing data preserved. |
| DRAFT → (delete) | Hard delete | No submissions exist → full removal. |
| PUBLISHED (no submissions) → (delete) | Soft delete | `deleted_at` set. Can be restored. |
| PUBLISHED (with submissions) → (delete) | Blocked | Error: "Cannot delete homework with existing submissions." |

Cloning creates a new DRAFT copy with identical settings but for a different section in the same class.

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|---|---|---|
| Create/Update — class | Required. Locked after first save | "Class cannot be changed after the homework is saved." |
| Create/Update — subject | Required. Locked after first save | "Subject cannot be changed after the homework is saved." |
| Create/Update — passing_marks | Must be ≤ max_marks | "Passing marks must be less than or equal to maximum marks." |
| Create/Update — max_marks | Required if is_gradable = 1 | "Maximum marks are required when homework is gradable." |
| Create/Update — passing_marks | Required if is_gradable = 1 | "Passing marks are required when homework is gradable." |
| Create/Update — release_scheduled_date | Required if release_condition = ON_SCHEDULED_DATE | "Scheduled release date is required for this release condition." |
| Create/Update — schedule_id | Required if release_condition = ON_TOPIC_COMPLETE | "Syllabus schedule link is required for topic-based release." |
| Create/Update — academic_session_id | Must be an active session | "No active academic session found. Homework cannot be saved." |
| Publish — status | Must be DRAFT | "Only draft homework can be published." |
| Delete — with submissions | Blocked | "This homework has existing submissions and cannot be deleted." |
| Clone — target section | Must differ from source section | "Target section must be different from the source section." |
| Clone — target section | Must be within same class | "Cloning is only allowed within the same class." |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|---|---|---|---|
| School Management | `sch_classes`, `sch_sections`, `sch_subjects` | `lms_homework.{class_id,section_id,subject_id}` | Target audience for homework |
| Syllabus | `slb_lessons`, `slb_topics`, `slb_syllabus_schedule` | `lms_homework.{lesson_id,topic_id,schedule_id}` | Content alignment + release trigger |
| Syllabus | `slb_complexity_level` | `lms_homework.difficulty_level_id` | Difficulty classification |
| Organization | `sch_org_academic_sessions_jnt` | `lms_homework.academic_session_id` | Academic session scoping |
| Common/Dropdown | `sys_dropdown_table` | `lms_homework.{submission_type_id,status_id}` | Submission types and statuses |
| Media | `sys_media` | `lms_homework.hw_attachment_media_id` (JSON) | Teacher file attachments |
| Users | `sys_users` | `lms_homework.{created_by,updated_by}` | Creator/modifier tracking |

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| View homework list | Teacher | `lms.homework.list` |
| Create homework | Teacher | `lms.homework.create` |
| Edit homework (Draft) | Teacher | `lms.homework.edit` |
| Edit homework (Published) | Teacher | `lms.homework.edit_published` |
| Publish homework | Teacher | `lms.homework.publish` |
| Archive homework | Teacher | `lms.homework.archive` |
| Delete homework (Draft) | Teacher | `lms.homework.delete` |
| Clone homework | Teacher | `lms.homework.clone` |
| View all homework (cross-class) | Admin | `lms.homework.view_all` |
