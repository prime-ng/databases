# Tab 2: Question Tags

This tab lets teachers create and manage tags — short labels that help organize questions so they can be found easily later. Tags are things like "Important," "Exam Focus," "Chapter 5," or "Easy Revision." A question can have many tags, and a tag can be used on many questions.

---

## How It Works

When a teacher opens this tab, they see a list of all tags that have been created. Each tag has a display name — the name everyone sees — and a short name, which is a shorter code used internally. The teacher can search for tags by either name.

Creating a new tag is simple. The teacher types a name like "Important for Final Exam" and a short name like "IMP-FINAL." The system checks that the short name is unique — no two tags can have the same short name. If someone already used "IMP-FINAL," the system says "This short name is already in use. Please choose a different one." This uniqueness rule exists because the short name is used behind the scenes for quick lookups, and duplicates would cause confusion.

Tags can have the same display name. So two teachers could both create a tag called "Important" — that is allowed. Only the short name must be unique.

When a teacher edits a tag, they can change either the display name or the short name. If they change the short name to one that is already taken, the same uniqueness rule applies — they get an error and must pick something else. The change takes effect everywhere the tag is used. So if a tag called "IMP" is renamed to "IMPORTANT," all questions that had the "IMP" tag now show "IMPORTANT."

Deleting a tag works in two ways. Soft delete hides the tag but keeps its connections to questions. This means if a soft-deleted tag is later restored, all the questions that used it still have the tag. Force delete removes the tag permanently and also removes it from every question that was using it. The system warns the teacher how many questions are affected before letting them force delete.

When a teacher is creating or editing a question, they can select tags from this library. The tags they pick get linked to the question. Later, when searching for questions, the teacher can filter by tag — showing only questions that have, say, the "Exam Focus" tag.

---

## Important Business Rules

- The short name must always be unique. If a teacher tries to create or edit a tag and gives it a short name that matches another tag — even a deleted one — the system will reject it. The display name has no such restriction.
- When a tag is used by many questions and the teacher wants to delete it, the system does not block the deletion. It just warns the teacher how many questions will lose this tag. The teacher can proceed if they want, understanding that all those questions will no longer have this label.
- If a question is deleted, its links to tags are also deleted. But the tags themselves stay in the library, untouched. They can still be used on other questions.
- Soft deletion preserves all tag-question relationships. Restoring a soft-deleted tag brings back the relationships exactly as they were.
- Force deletion removes the tag from every question. Those relationships are permanently lost.
- The system does not limit how many tags a question can have. However, the question creation interface shows a scrollable selector if there are many tags.
- Tags are school-specific. Tags created by teachers in one school are not visible in another school.

---

## Deep Analysis

### Business Workflows & State Machines

| State | Trigger | Next State | Notes |
|---|---|---|---|
| Idle | Teacher opens Tags tab | Tag List | All active tags displayed with search |
| Tag List | Teacher clicks "Add New" | Create Form | Name + short name fields |
| Create Form | Teacher submits | Validating | Short name uniqueness check |
| Validating | Short name is unique | Tag Created | Record added to `qns_question_tags` |
| Validating | Short name already exists | Validation Error | "This short name is already in use." |
| Active | Teacher clicks "Edit" | Edit Form | Name and/or short name changeable |
| Edit Form | Teacher submits change | Validating | Short name uniqueness re-checked |
| Active | Teacher clicks "Delete" | Delete Confirmation | Warning: "X questions will be affected" |
| Delete Confirmation | Teacher confirms soft delete | Soft Deleted | Tag hidden; relationships preserved |
| Delete Confirmation | Admin confirms force delete | Force Deleted | Tag + all relationships removed permanently |
| Soft Deleted | Admin clicks "Restore" | Active | Tag + all relationships restored |

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|---|---|---|
| Short name uniqueness | Must be unique across all tags (including deleted) | "This short name is already in use. Please choose a different one." |
| Display name uniqueness | No restriction | Duplicate display names allowed |
| Short name length | VARCHAR(100) | Truncated or validated at application level |
| Name length | VARCHAR(255) | Truncated or validated at application level |
| Soft delete with relationships | Relationships preserved | Warning: "[n] questions will lose this tag if force deleted." |
| Force delete | Admin only | "You do not have permission to force delete tags." |
| Restore soft-deleted tag | Admin only | "You do not have permission to restore tags." |
| Edit to duplicate short name | Same uniqueness check as create | "This short name is already in use." |
| Delete tag referenced by questions | Not blocked; warning shown | "[n] questions are currently using this tag. Proceed?" |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|---|---|---|---|
| Question Bank | `qns_question_tags` | – | Tag definitions |
| Question Bank | `qns_question_questiontag_jnt` | question_bank_id / tag_id | Many-to-many relationship between questions and tags |
| Question Bank | `qns_questions_bank` | id | Referenced through junction for tag filtering |
| Multi-tenant | School context | school_id | Tags are isolated per school |

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| View tag list | Teacher | `question-tags.viewAny` |
| Create tag | Teacher | `question-tags.create` |
| Edit tag | Teacher | `question-tags.update` |
| Delete tag (soft) | Teacher | `question-tags.delete` |
| Force delete tag | Admin | `question-tags.force-delete` |
| Restore tag | Admin | `question-tags.restore` |
| View deleted tags | Admin | `question-tags.view-deleted` |

---

## Database Columns & Behavior

### qns_question_tags

| Column | Type | FK | Nullable | Default | Behavior |
|---|---|---|---|---|---|
| id | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| short_name | VARCHAR(100) | No | No | – | Unique short code for internal lookups (UNIQUE constraint) |
| name | VARCHAR(255) | No | No | – | Display name visible to users (no uniqueness constraint) |
| is_active | TINYINT(1) | No | No | 1 | Soft delete flag |
| created_at | TIMESTAMP | No | No | CURRENT_TIMESTAMP | Record creation timestamp |
| updated_at | TIMESTAMP | No | No | CURRENT_TIMESTAMP ON UPDATE | Last update timestamp |
| deleted_at | TIMESTAMP | No | Yes | NULL | Soft delete timestamp |

### qns_question_questiontag_jnt

| Column | Type | FK | Nullable | Default | Behavior |
|---|---|---|---|---|---|
| id | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| question_bank_id | INT UNSIGNED | qns_questions_bank.id | No | – | Question FK (CASCADE delete) |
| tag_id | INT UNSIGNED | qns_question_tags.id | No | – | Tag FK (CASCADE delete) |
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
| content_format | ENUM('TEXT','HTML','MARKDOWN','LATEX','JSON') | No | No | 'TEXT' | Content format specification |
| media_required_for_question | TINYINT(1) | No | No | 0 | Whether media is mandatory for this question |
| media_location_for_question | ENUM('Above Text','Below Text','Left','Right') | No | Yes | 'Below Text' | Media placement relative to question text |
| teacher_explanation | TEXT | No | Yes | NULL | Explanation shown to students after answering |
| media_required_for_teacher_explanation | TINYINT(1) | No | No | 0 | Whether media is mandatory for explanation |
| media_location_for_teacher_explanation | ENUM('Above Text','Below Text','Left','Right') | No | Yes | 'Below Text' | Media placement for explanation |
| bloom_id | INT UNSIGNED | slb_bloom_taxonomy.id | No | – | Bloom's taxonomy level FK |
| cognitive_skill_id | INT UNSIGNED | slb_cognitive_skill.id | No | – | Cognitive skill taxonomy FK |
| ques_type_specificity_id | INT UNSIGNED | slb_ques_type_specificity.id | No | – | Question type specificity FK |
| complexity_level_id | INT UNSIGNED | slb_complexity_level.id | No | – | Complexity level FK |
| question_type_id | INT UNSIGNED | slb_question_types.id | No | – | Question type FK (RESTRICT on delete) |
| expected_time_to_answer_seconds | INT UNSIGNED | No | Yes | NULL | Expected answer time for students |
| marks | DECIMAL(5,2) | No | No | 1.00 | Marks for correct answer |
| negative_marks | DECIMAL(5,2) | No | No | 0.00 | Penalty marks for wrong answer |
| current_version | TINYINT UNSIGNED | No | No | 1 | Current version counter for history |
| for_quiz | TINYINT(1) | No | No | 1 | Usable in Quiz assessments |
| for_quest | TINYINT(1) | No | No | 0 | Usable in Quest assessments |
| for_exam | TINYINT(1) | No | No | 0 | Usable in Exam assessments |
| for_offline_exam | TINYINT(1) | No | No | 0 | Usable in Offline Exam assessments |
| ques_owner | ENUM('PrimeGurukul','School') | No | No | 'PrimeGurukul' | Ownership scope |
| created_by_AI | TINYINT(1) | No | No | 0 | Flag: 1 = AI-generated, 0 = manual |
| created_by | INT UNSIGNED | sch_users.id | Yes | NULL | Creator user FK |
| is_school_specific | TINYINT(1) | No | No | 0 | Restrict to current school only |
| availability | ENUM('GLOBAL','SCHOOL_ONLY','CLASS_ONLY','SECTION_ONLY','ENTITY_ONLY','STUDENT_ONLY') | No | No | 'GLOBAL' | Visibility scope |
| selected_entity_group_id | INT UNSIGNED | slb_entity_groups.id | Yes | NULL | Entity group for ENTITY_ONLY visibility |
| selected_section_id | INT UNSIGNED | sch_sections.id | Yes | NULL | Section for SECTION_ONLY visibility |
| selected_student_id | INT UNSIGNED | sch_students.id | Yes | NULL | Student for STUDENT_ONLY visibility |
| book_id | INT UNSIGNED | slb_books.id | Yes | NULL | Textbook reference FK |
| book_page_ref | VARCHAR(50) | No | Yes | NULL | Page number in textbook |
| external_ref | VARCHAR(100) | No | Yes | NULL | External bank mapping reference |
| reference_material | TEXT | No | Yes | NULL | Additional reference material |
| status | ENUM('DRAFT','IN_REVIEW','APPROVED','REJECTED','PUBLISHED','ARCHIVED') | No | No | 'DRAFT' | Question lifecycle status |
| is_active | TINYINT(1) | No | No | 1 | Active flag for soft delete |
| created_at | TIMESTAMP | No | No | CURRENT_TIMESTAMP | Record creation timestamp |
| updated_at | TIMESTAMP | No | No | CURRENT_TIMESTAMP ON UPDATE | Last update timestamp |
| deleted_at | TIMESTAMP | No | Yes | NULL | Soft delete timestamp |
