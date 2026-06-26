# Tab 1: Question Media

This tab lets teachers upload and manage media files — images, audio clips, videos, and PDFs — that can be attached to questions and their answer options. Think of it as a shared media library where all files live, and any question can pull from it.

---

## How It Works

When a teacher opens this tab, they see a list of every media file that has been uploaded. They can filter the list by file type — for example, show only images or only PDFs — or search for a file by name. Each file shows its name, what type it is, how big it is, who uploaded it, and when.

To add a new file, the teacher clicks "Add New," picks a file from their computer, and tells the system what type of file it is. The system checks that the file type matches what the teacher said — for example, if the teacher says it is an image but uploads a PDF, the system will warn them. If everything looks good, the file is saved to the library and becomes available for attaching to questions.

If the teacher clicks on any file, they can see a preview. Images show up directly on the screen. Audio and video files have play buttons so the teacher can listen or watch. PDFs open in a built-in viewer. The teacher can also see which questions are currently using this file.

The teacher can change the file's name or description whenever they want. They can even replace the file with a new version — for example, swapping out a low-resolution image with a high-resolution one. Any question that uses this file will automatically see the new version.

Deleting a file is where the rules get strict. The system will not let a teacher delete any file that is currently attached to a question. If they try, they get a message saying "This file is being used by X questions. Remove all references before deleting." The teacher must first go to each question, remove the media link, and then come back to delete the file. This rule exists because deleting a file that a question depends on would break that question — students would see a broken image or missing video.

There are two kinds of deletion. Soft delete hides the file but keeps it on the server so it can be restored later. Force delete removes it permanently from both the database and the server. Only admins can force delete. Restoring a soft-deleted file brings it back exactly as it was, including any links to questions that still exist.

---

## Important Business Rules

- Viewing the file list requires the "question-media-store.viewAny" permission. Uploading requires "create." Editing and deleting require "update" and "delete" respectively.
- The person who uploaded a file is considered its owner and has more control over it than other teachers.
- Only admins can force delete or restore files.
- A file cannot be deleted if it is attached to any question. The teacher must remove all question references first.
- When a file is replaced, all questions using that file automatically see the new version. The system does not keep the old version.
- The system validates file type during upload. If the declared type does not match the actual file content, a warning is shown but the upload is not blocked.
- Soft-deleted files are hidden from the main list but can be viewed by filtering to show deleted files. Admins can restore them.
- Force-deleted files cannot be recovered. The physical file is removed from the server storage.

---

## Deep Analysis

### Business Workflows & State Machines

| State | Trigger | Next State | Notes |
|---|---|---|---|
| Idle | Teacher opens Media tab | File List | Displays all active media files |
| File List | Teacher clicks "Add New" | Upload Form | File picker opens |
| Upload Form | Teacher selects file + declares type | Validating | MIME type checked against declared type |
| Validating | Type matches / mismatch warning | File Saved / Warning Shown | Warning does not block upload |
| File Saved | Upload to storage + DB record | Stored | File written to disk, record in `qns_media_store` |
| Active (Stored) | Teacher clicks "Edit" name/desc | Edit Mode | Metadata update only |
| Active (Stored) | Teacher clicks "Replace File" | File Replacement | New file uploaded; old file replaced on disk |
| Active (Stored) | Teacher clicks "Delete" | Delete Check | System checks if file is attached to any question |
| Delete Check | File in use by 1+ questions | Blocked | "Remove all references before deleting" |
| Delete Check | File not in use | Soft Delete / Force Delete | Role-dependent: soft for teachers, force for admins |
| Soft Deleted | Admin clicks "Restore" | Active | All relationships restored |

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|---|---|---|
| File type declaration | Declared type must match actual MIME | "The file type you selected does not match the actual file content." (warning only) |
| File deletion | File attached to active questions | "This file is being used by [n] questions. Remove all references before deleting." |
| Force delete | Only admins can force delete | "You do not have permission to force delete files." |
| Restore file | Only admins can restore | "You do not have permission to restore deleted files." |
| File replacement | Old file replaced permanently | No rollback; old version is lost |
| File size | No explicit limit mentioned | Validated at upload by server configuration |
| Delete with ongoing assessments | File in use by active assessment | Blocked with same "in use" message |
| Delete own vs others' files | Owner has more control | Teachers cannot delete files uploaded by others (unless admin) |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|---|---|---|---|
| Question Bank | `qns_media_store` | owner_type / owner_id | Stores media file metadata |
| Question Bank | `qns_question_media_jnt` | question_bank_id / media_id | Junction linking media to questions/options |
| Question Bank | `qns_questions_bank` | id | Referenced by junction table for usage checking |
| Question Bank | `qns_question_options` | id | Option-level media attachments |
| Storage | File system / cloud disk | – | Physical file storage (disk config in `disk` column) |

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| View media list | Teacher | `question-media-store.viewAny` |
| Upload new media | Teacher | `question-media-store.create` |
| Edit media metadata | Teacher (owner) | `question-media-store.update` |
| Delete media (soft) | Teacher (owner) | `question-media-store.delete` |
| Force delete media | Admin | `question-media-store.force-delete` |
| Restore media | Admin | `question-media-store.restore` |
| Replace media file | Teacher (owner) | `question-media-store.replace` |
| View all media (incl. deleted) | Admin | `question-media-store.view-deleted` |

---

## Database Columns & Behavior

### qns_media_store

| Column | Type | FK | Nullable | Default | Behavior |
|---|---|---|---|---|---|
| id | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| uuid | BINARY(16) | No | No | – | Unique identifier using UUID_TO_BIN |
| owner_type | ENUM('QUESTION','OPTION','EXPLANATION','RECOMMENDATION') | No | No | – | Identifies what this media belongs to |
| class_id | INT UNSIGNED | sch_classes.id | Yes | NULL | Denormalized FK for easier querying |
| subject_id | INT UNSIGNED | sch_subjects.id | Yes | NULL | Denormalized FK for easier querying |
| lesson_id | INT UNSIGNED | slb_lessons.id | Yes | NULL | Denormalized FK for easier querying |
| topic_id | INT UNSIGNED | slb_topics.id | Yes | NULL | Denormalized FK for easier querying |
| media_type | ENUM('IMAGE','AUDIO','VIDEO','PDF') | No | No | – | Type of media file |
| file_name | VARCHAR(255) | No | Yes | NULL | Original file name |
| file_path | VARCHAR(255) | No | Yes | NULL | Storage path to file |
| mime_type | VARCHAR(100) | No | Yes | NULL | MIME type of the file |
| disk | VARCHAR(50) | No | Yes | NULL | Storage disk identifier (local/s3/etc.) |
| size | INT UNSIGNED | No | Yes | NULL | File size in bytes |
| checksum | CHAR(64) | No | Yes | NULL | SHA-256 checksum for integrity |
| ordinal | SMALLINT UNSIGNED | No | No | 1 | Display order |
| is_active | TINYINT(1) | No | No | 1 | Soft delete flag |
| created_at | TIMESTAMP | No | No | CURRENT_TIMESTAMP | Record creation timestamp |
| updated_at | TIMESTAMP | No | No | CURRENT_TIMESTAMP ON UPDATE | Last update timestamp |
| deleted_at | TIMESTAMP | No | Yes | NULL | Soft delete timestamp |

### qns_question_media_jnt

| Column | Type | FK | Nullable | Default | Behavior |
|---|---|---|---|---|---|
| id | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| question_bank_id | INT UNSIGNED | qns_questions_bank.id | No | – | Question FK (CASCADE delete) |
| question_option_id | INT UNSIGNED | qns_question_options.id | Yes | NULL | Option FK (CASCADE delete); NULL when media is for the question itself |
| media_purpose | ENUM('QUESTION','OPTION','QUES_EXPLANATION','OPT_EXPLANATION','RECOMMENDATION') | No | No | 'QUESTION' | Purpose of the media attachment |
| media_id | INT UNSIGNED | qns_media_store.id | No | – | Media FK (CASCADE delete) |
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

### qns_question_options

| Column | Type | FK | Nullable | Default | Behavior |
|---|---|---|---|---|---|
| id | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| question_bank_id | INT UNSIGNED | qns_questions_bank.id | No | – | Parent question FK (CASCADE delete) |
| ordinal | SMALLINT UNSIGNED | No | Yes | NULL | Display order position |
| option_text | TEXT | No | No | – | Option content text |
| media_required_for_question_option | TINYINT(1) | No | No | 0 | Whether media is mandatory for this option |
| media_location_for_question_option | ENUM('Above Text','Below Text','Left','Right') | No | Yes | 'Below Text' | Media placement for option |
| is_correct | TINYINT(1) | No | No | 0 | 1 = correct answer, 0 = distractor |
| explanation | TEXT | No | Yes | NULL | Per-option explanation (why correct/incorrect) |
| media_required_for_question_option_explanation | TINYINT(1) | No | No | 0 | Whether media is mandatory for option explanation |
| media_location_for_question_option_explanation | ENUM('Above Text','Below Text','Left','Right') | No | Yes | 'Below Text' | Media placement for option explanation |
| is_active | TINYINT(1) | No | No | 1 | Soft delete flag |
| created_at | TIMESTAMP | No | No | CURRENT_TIMESTAMP | Record creation timestamp |
| updated_at | TIMESTAMP | No | No | CURRENT_TIMESTAMP ON UPDATE | Last update timestamp |
| deleted_at | TIMESTAMP | No | Yes | NULL | Soft delete timestamp |
