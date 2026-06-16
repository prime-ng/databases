# Syllabus Tab 2: Lesson Management

This tab allows curriculum coordinators and teachers to create, edit, and manage lessons (chapters/units) within each class and subject. A lesson is the top-level container in the syllabus hierarchy and maps directly to textbook chapters.

---

## How It Works

The user first selects a class, subject, and academic session from dropdown filters. Once selected, a list of all lessons for that class-subject combination appears, sorted by their ordinal sequence number. Each row shows the lesson code (auto-generated), name, short name, estimated periods, and weightage percentage.

The user can create a new lesson by clicking the Add Lesson button. A form opens asking for the lesson name, short name, ordinal position, description, learning objectives (as a list of items), prerequisites (which other lessons should be completed first), estimated periods, weightage in the subject, NEP alignment reference, resources (links to videos, PDFs, and other materials), and the book chapter reference. The system auto-generates a unique lesson code combining the class code, subject code, and a sequential number.

Users can reorder lessons by changing the ordinal value. Editing an existing lesson opens the same form pre-filled. Deleting a lesson is a soft delete — the lesson and all its child topics are hidden but preserved in the database.

Learning objectives are displayed as a formatted list on the lesson detail view. Resources are shown as clickable links grouped by type (video, PDF, etc.).

---

## Important Business Rules

- Lesson names must be unique within the same class and subject combination. Duplicate names are rejected.
- The lesson code is auto-generated and cannot be edited manually. Format: `{CLASS_CODE}_{SUBJECT_CODE}_L{NN}`.
- The ordinal value must be unique within a class-subject pair. When inserting at an existing position, higher ordinals are shifted up automatically.
- Deleting a lesson cascades to all child topics (soft delete on both tables).
- A lesson cannot be deleted if it has syllabus schedule entries referencing it. The user must first remove all scheduled entries.
- Learning objectives are stored as a JSON array of objects: `[{"objective": "Understand algebraic expressions"}]`.
- Prerequisites reference other lesson IDs stored as a JSON array: `[1, 5, 12]`.
- Resources are stored as a JSON array of objects: `[{"type": "video", "url": "...", "title": "..."}]`.
- The book chapter reference is a free-text field (e.g., "Chapter 1" or "Section 1.1") that maps the digital lesson to the physical textbook.
- The scheduled year week field accepts a YYYYWW format (e.g., 202426) indicating the target teaching week.

---

## Database Columns & Behavior

### slb_lessons
- `id` — Primary key. INT UNSIGNED AUTO_INCREMENT.
- `uuid` — Unique binary identifier for analytics tracking. BINARY(16). Has a unique constraint.
- `academic_session_id` — Academic session this lesson belongs to. INT UNSIGNED FK to sch_org_academic_sessions_jnt. RESTRICT on delete.
- `class_id` — Class this lesson belongs to. INT UNSIGNED FK to sch_classes. CASCADE on delete.
- `subject_id` — Subject this lesson belongs to. INT UNSIGNED FK to sch_subjects. CASCADE on delete.
- `bok_books_id` — Reference book from the book master. INT UNSIGNED FK to bok_books.
- `code` — Auto-generated unique code. VARCHAR(20). Unique constraint.
- `name` — Display name. VARCHAR(150). Unique per class-subject combination (composite unique key with class_id, subject_id).
- `short_name` — Abbreviated name for compact displays. VARCHAR(50), nullable.
- `ordinal` — Sort order within the subject. SMALLINT UNSIGNED NOT NULL.
- `description` — Brief explanation of the lesson. VARCHAR(255), nullable.
- `learning_objectives` — JSON array of objectives. JSON, nullable.
- `prerequisites` — JSON array of prerequisite lesson IDs. JSON, nullable.
- `estimated_periods` — Number of teaching periods estimated. SMALLINT UNSIGNED, nullable.
- `weightage_in_subject` — Percentage weightage in the subject's final assessment. DECIMAL(5,2), nullable.
- `nep_alignment` — NEP 2020 reference code. VARCHAR(100), nullable.
- `resources_json` — JSON array of resource objects (type, url, title). JSON, nullable.
- `book_chapter_ref` — Textbook chapter reference. VARCHAR(100), nullable.
- `scheduled_year_week` — Target teaching week in YYYYWW format. INT UNSIGNED, nullable.
- `is_active` — Soft delete flag. TINYINT(1), default 1.
- `created_at`, `updated_at`, `deleted_at` — Standard timestamps.

---

## Deep Analysis

### Business Workflows & State Machines
- **Create Lesson** → form opens (name, short_name, ordinal, description, objectives, prerequisites, periods, weightage, NEP, resources, chapter_ref) → validate → auto-generate code → INSERT → shift higher ordinals up.
- **Edit Lesson** → form pre-filled → validate name uniqueness (exclude own id) → UPDATE.
- **Delete Lesson** → soft delete on `slb_lessons.is_active = 0` → cascade soft-delete child `slb_topics` → reject if any `slb_syllabus_schedule` references exist.
- **Reorder** → user changes ordinal → system detects gap/overlap → shifts affected siblings.
- **State machine**: Lesson exists only as ACTIVE or SOFT-DELETED; no intermediate states.

### Validation Rules & Edge Cases
- **Name uniqueness** — composite unique key `(class_id, subject_id, name)`; reject on duplicate within same class-subject.
- **Code** — auto-generated `{CLASS_CODE}_{SUBJECT_CODE}_L{NN}`; UNIQUE constraint; cannot be changed.
- **Ordinal** — UNIQUE per `(class_id, subject_id)`; inserting at occupied position shifts higher ordinals up by 1.
- **Prerequisites** — JSON array of lesson IDs; must reference existing, active lessons; cycles must be avoided at application layer.
- **Resources** — JSON array with `type`, `url`, `title`; validate `url` format per type.
- **Weightage** — `DECIMAL(5,2)`; subject-level sum is advisory (not enforced at DB level).
- **Delete guard** — query `slb_syllabus_schedule` for any reference; if found, block with message "Remove schedule entries first."
- **Lesson with children** — deleting cascades soft-delete; restore also cascades.

### Integration Points
- `sch_classes` / `sch_subjects` — class/subject selection filters.
- `slb_topics` — child topics cascade on soft delete.
- `slb_syllabus_schedule` — delete guard reference.
- `sch_org_academic_sessions_jnt` — academic session filter.
- `bok_books` — optional book reference.

### Permissions Matrix
| Role | Create | Edit | Delete | View | Reorder |
|---|---|---|---|---|---|
| Super Admin | ✅ | ✅ | ✅ | ✅ | ✅ |
| School Admin | ✅ | ✅ | ✅ | ✅ | ✅ |
| Curriculum Coordinator | ✅ | ✅ | ✅ | ✅ | ✅ |
| Teacher | ✅ (own) | ✅ (own) | ❌ | ✅ | ❌ |
| Student/Parent | ❌ | ❌ | ❌ | ❌ | ❌ |
