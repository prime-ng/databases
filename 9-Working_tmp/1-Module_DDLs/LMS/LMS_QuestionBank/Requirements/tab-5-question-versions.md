# Tab 5: Question Versions

This tab shows the complete edit history of every question. Every time a teacher edits a question, a snapshot of how it looked before the edit is saved here. Think of it as an automatic backup that captures the question at every stage of its life.

---

## How It Works

When a teacher opens this tab, they see a list of all version records sorted newest first. Each entry shows which question was changed, what version number it was (1, 2, 3, etc.), who made the change, and when. If the teacher provided a reason for the edit — like "Fixed a typo in option B" — that shows up too.

Clicking any version entry opens a detailed view showing the question exactly as it was at that point in time. The question content, all options with their correct/wrong markings, every media link, every tag, every topic link — everything is captured in the snapshot. The teacher can scroll through this historical view to see what the question used to look like.

The key thing to understand is that versions are created automatically, not manually. When a teacher edits a question and clicks Save, the system first takes a snapshot of the question in its current state — before applying the changes — and saves that as a new version. Then it applies the edits. This means version 1 captures the question as it was originally created. Version 2 captures it after the first edit. And so on.

Only edits create versions. Cloning does not create a version. Importing does not create versions for each imported question. The version counter on a freshly created question starts at 1 without a corresponding version record — the first version record is created when the question is first edited.

---

## Important Business Rules

- Versions are permanent. They cannot be deleted by teachers. Even if the question itself is deleted, the version records remain as historical artifacts. If someone tries to view a version of a deleted question, they see a note saying "The original question has been deleted" but the snapshot data is still visible.
- The version snapshot is a complete copy, not just a list of what changed. This means if a question has 5 options, 10 media files, and 15 tags, all of that is captured in full each time. A question that gets edited 50 times will have 50 complete copies. This uses more storage, but it means the history is always fully recoverable — you never lose data because a change wasn't tracked.
- There is no way to compare two versions side by side in the current system. The teacher can only view one version at a time. If they want to see what changed, they must manually switch between versions.
- If a question is force-deleted, the version records become orphaned. They still exist in the system but reference a question ID that no longer exists. Viewing them still works but shows the deleted question warning.
- Version numbers are sequential per question. The first edit creates version 1, the second creates version 2, and so on. There is no way to skip or reset version numbers.
- The edit reason is optional. If the teacher does not provide a reason, the version record shows "(No reason provided)."
- Version records include a timestamp accurate to the second, so teachers can see the exact order of changes even if multiple edits were made in quick succession.
- Only question content changes create versions. Changes to question metadata (like filters, media links that don't change the question text) may or may not create a version depending on the system configuration.

---

## Deep Analysis

### Business Workflows & State Machines

| State | Trigger | Next State | Notes |
|---|---|---|---|
| No versions | Question created | Version 0 (implied) | Counter starts at 1; no snapshot yet |
| Current Version N | Teacher edits question | Snapshot Taken (Version N) | Pre-edit snapshot saved; question updated |
| Snapshot Taken | System saves JSON snapshot | Version N created in qns_question_versions | Full copy of question, options, links |
| Post-save | Version counter incremented | Current Version N+1 | qns_questions_bank.current_version updated |
| Viewing Version List | Teacher clicks a version entry | Snapshot Detail View | JSON decoded and rendered for display |
| Question Deleted | System checks version records | Versions remain orphaned | "The original question has been deleted" message shown |

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|---|---|---|
| Version creation | Only on question edit (not clone, not import) | N/A (system-generated) |
| Version deletion | Not possible by any user | "Version records are permanent and cannot be deleted." |
| Version data storage | Full JSON snapshot (not diff) | Storage-intensive but fully recoverable |
| Orphaned versions | Survive question force-deletion | "The original question has been deleted." |
| Version numbers | Sequential per question, starting at 1 | Cannot skip or reset |
| Edit reason | Optional field | Displayed as "(No reason provided)" if empty |
| Snapshot contents | Includes all options, media links, tags, topic links | Complete historical capture |
| Version comparison | Not available | Teachers must manually switch between versions |
| Metadata-only changes | May or may not create a version | Configurable behavior |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|---|---|---|---|
| Question Bank | qns_question_versions | question_bank_id | Version snapshot storage |
| Question Bank | qns_questions_bank | id | Source of version data and current_version tracking |
| Question Bank | qns_question_options | question_bank_id | Option data captured in JSON snapshot |
| Question Bank | qns_question_media_jnt | question_bank_id | Media links captured in JSON snapshot |
| Question Bank | qns_question_questiontag_jnt | question_bank_id | Tag links captured in JSON snapshot |
| Question Bank | qns_question_topic_jnt | question_bank_id | Topic links captured in JSON snapshot |
| Question Bank | qns_question_performance_category_jnt | question_bank_id | Performance category links captured in JSON snapshot |
| Users | sch_users | version_created_by | Tracks who made the edit that created the version |

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| View version history | Teacher | question-versions.viewAny |
| View version details/snapshot | Teacher | question-versions.view-details |
| View versions of deleted questions | Admin | question-versions.view-deleted |
| Delete versions | Not available (any role) | – |

---

## Database Columns & Behavior

### qns_question_versions

| Column | Type | FK | Nullable | Default | Behavior |
|---|---|---|---|---|---|
| id | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| question_bank_id | INT UNSIGNED | qns_questions_bank.id | No | – | Question FK (CASCADE delete; records survive force-delete as orphaned) |
| version | INT UNSIGNED | No | No | – | Sequential version number per question |
| data | JSON | No | No | – | Full JSON snapshot of question content, options, media, tags, topics |
| version_created_by | INT UNSIGNED | sch_users.id | Yes | NULL | User who performed the edit |
| change_reason | VARCHAR(255) | No | Yes | NULL | Optional edit reason |
| is_active | TINYINT(1) | No | No | 1 | Soft delete flag |
| created_at | TIMESTAMP | No | No | CURRENT_TIMESTAMP | Record creation timestamp |
| updated_at | TIMESTAMP | No | No | CURRENT_TIMESTAMP ON UPDATE | Last update timestamp |
| deleted_at | TIMESTAMP | No | Yes | NULL | Soft delete timestamp |

### qns_questions_bank

| Column | Type | FK | Nullable | Default | Behavior |
|---|---|---|---|---|---|
| id | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| uuid | BINARY(16) | No | No | – | Globally unique identifier via UUID_TO_BIN |
| class_id | INT UNSIGNED | sch_classes.id | No | – | Denormalized FK to class |
| subject_id | INT UNSIGNED | sch_subjects.id | No | – | Denormalized FK to subject |
| lesson_id | INT UNSIGNED | slb_lessons.id | No | – | Denormalized FK to lesson |
| topic_id | INT UNSIGNED | slb_topics.id | No | – | FK to topic |
| competency_id | INT UNSIGNED | slb_competencies.id | No | – | FK to competency |
| ques_title | VARCHAR(255) | No | No | – | Internal title for system use |
| ques_title_display | TINYINT(1) | No | No | 0 | Whether title is shown to students |
| question_content | TEXT | No | No | – | Question text displayed to users |
| content_format | ENUM | No | No | 'TEXT' | Content format specification |
| media_required_for_question | TINYINT(1) | No | No | 0 | Whether media is mandatory |
| media_location_for_question | ENUM | No | Yes | 'Below Text' | Media placement |
| teacher_explanation | TEXT | No | Yes | NULL | Explanation shown to students |
| media_required_for_teacher_explanation | TINYINT(1) | No | No | 0 | Whether media is mandatory for explanation |
| media_location_for_teacher_explanation | ENUM | No | Yes | 'Below Text' | Media placement for explanation |
| bloom_id | INT UNSIGNED | slb_bloom_taxonomy.id | No | – | Bloom's taxonomy level FK |
| cognitive_skill_id | INT UNSIGNED | slb_cognitive_skill.id | No | – | Cognitive skill taxonomy FK |
| ques_type_specificity_id | INT UNSIGNED | slb_ques_type_specificity.id | No | – | Question type specificity FK |
| complexity_level_id | INT UNSIGNED | slb_complexity_level.id | No | – | Complexity level FK |
| question_type_id | INT UNSIGNED | slb_question_types.id | No | – | Question type FK |
| expected_time_to_answer_seconds | INT UNSIGNED | No | Yes | NULL | Expected answer time |
| marks | DECIMAL(5,2) | No | No | 1.00 | Marks for correct answer |
| negative_marks | DECIMAL(5,2) | No | No | 0.00 | Penalty marks |
| current_version | TINYINT UNSIGNED | No | No | 1 | Current version counter |
| for_quiz | TINYINT(1) | No | No | 1 | Usable in Quiz |
| for_quest | TINYINT(1) | No | No | 0 | Usable in Quest |
| for_exam | TINYINT(1) | No | No | 0 | Usable in Exam |
| for_offline_exam | TINYINT(1) | No | No | 0 | Usable in Offline Exam |
| ques_owner | ENUM | No | No | 'PrimeGurukul' | Ownership scope |
| created_by_AI | TINYINT(1) | No | No | 0 | AI-generated flag |
| created_by | INT UNSIGNED | sch_users.id | Yes | NULL | Creator user FK |
| is_school_specific | TINYINT(1) | No | No | 0 | School-specific flag |
| availability | ENUM | No | No | 'GLOBAL' | Visibility scope |
| selected_entity_group_id | INT UNSIGNED | slb_entity_groups.id | Yes | NULL | Entity group |
| selected_section_id | INT UNSIGNED | sch_sections.id | Yes | NULL | Section |
| selected_student_id | INT UNSIGNED | sch_students.id | Yes | NULL | Student |
| book_id | INT UNSIGNED | slb_books.id | Yes | NULL | Textbook reference |
| book_page_ref | VARCHAR(50) | No | Yes | NULL | Page number |
| external_ref | VARCHAR(100) | No | Yes | NULL | External mapping |
| reference_material | TEXT | No | Yes | NULL | Reference material |
| status | ENUM | No | No | 'DRAFT' | Lifecycle status |
| is_active | TINYINT(1) | No | No | 1 | Active flag |
| created_at | TIMESTAMP | No | No | CURRENT_TIMESTAMP | Creation timestamp |
| updated_at | TIMESTAMP | No | No | CURRENT_TIMESTAMP ON UPDATE | Update timestamp |
| deleted_at | TIMESTAMP | No | Yes | NULL | Soft delete timestamp |
