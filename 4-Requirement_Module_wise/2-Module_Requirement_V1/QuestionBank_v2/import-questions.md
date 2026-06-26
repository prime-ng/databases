# Import Questions from Excel or CSV

This feature lets teachers upload a spreadsheet containing multiple questions and import them all at once, rather than creating each question one by one through the form.

---

## How It Works

**Step 1 — The teacher downloads a template.** The system provides a sample Excel file showing the exact format required. The columns include: question title, question content, class, subject, lesson, topic, question type, complexity, marks, options (pipe-separated), correct option number, and explanation. The teacher fills in their questions following this format.

**Step 2 — The teacher uploads the file.** They click "Import" from the question list, select their file, and click "Upload & Validate."

**Step 3 — The system validates everything.** It checks the file format first — only .xlsx and .csv are accepted, and the file must be under 10 MB. It checks that all required columns are present. Then it goes row by row, checking that each class name exists, each subject belongs to that class, each question has valid options, each correct option number points to an existing option, and so on.

It also checks for duplicates. If a row has the same title and content as an existing question, a warning is shown. If two rows in the same file are identical to each other, that is flagged as an error.

**Step 4 — The teacher sees the results.** The system shows a summary: "120 rows valid, 5 rows with errors." The teacher can download a report listing exactly which rows had errors and what those errors were. They can either fix the errors in their spreadsheet and re-upload, or go ahead and import just the valid rows, skipping the problematic ones.

**Step 5 — The import runs.** The valid rows are imported one by one. Each becomes a new question in the Question Bank, created as Draft. If a row fails mid-import, it is skipped but the other rows continue — there is no global rollback. After the import finishes, the teacher sees the final count of how many questions were successfully created.

---

## Important Business Rules

- Each file can contain up to 500 questions. If there are more, the teacher must split them into multiple files.
- Imported questions are always created as Draft. The teacher needs to review and publish them separately. There is no way to import directly into Published status.
- The import checks for duplicates but does not block duplicates entirely. If a row is flagged as a potential duplicate, the teacher can choose to import it anyway. The duplicate detection is a warning, not a hard block.
- If the teacher uploads the same file twice, all questions are imported again as new questions unless the duplicate detection catches them. There is no "skip if already imported" logic.
- If the system crashes during import, the rows that were already processed are committed. The teacher must re-upload the file and restart — the duplicate detection will catch the already-imported rows and skip them.
- Only .xlsx and .csv file formats are accepted. Other formats are rejected with an error message.
- The file size limit is 10 MB. Files larger than this are rejected before any validation is performed.
- The import template is downloadable from the import page. It includes example data in the first row to guide the teacher.
- Required columns in the template are marked with an asterisk. If any required column is missing, the system rejects the entire file without processing any rows.
- The error report is downloadable as a separate Excel file that lists each problematic row with the error description and the original row data.
- All imported questions are created with the importing teacher listed as the creator. The audit flag does not distinguish between manually created and imported questions.

---

## Deep Analysis

### Business Workflows & State Machines

| State | Trigger | Next State | Notes |
|---|---|---|---|
| Idle | Teacher clicks "Import" | File Selection | Upload dialog opens |
| File Selection | Teacher chooses .xlsx/.csv file | File Uploaded | File size and format checked immediately |
| File Uploaded | System validates format/size | Validating | Rejected if >10 MB or wrong format |
| Validating | Per-row validation complete | Validation Results | Summary: valid rows vs error rows |
| Validation Results | Teacher clicks "Import Valid Rows" | Importing | Only rows without errors are processed |
| Validation Results | Teacher clicks "Download Error Report" | Report Downloaded | Excel file with error details |
| Importing | Each row processed individually | Row Created / Row Skipped | No global rollback; per-row commit |
| Importing | All rows processed | Import Complete | Final count displayed to teacher |

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|---|---|---|
| File format | Only .xlsx and .csv accepted | "Invalid file format. Only .xlsx and .csv files are accepted." |
| File size | Must be under 10 MB | "File size exceeds the 10 MB limit." |
| Max questions per file | Maximum 500 rows | "File contains more than 500 questions. Please split into multiple files." |
| Required columns | All required columns must be present | "Required column '[column_name]' is missing from the file." |
| Class validation | Class name must exist in system | "Row [n]: Class '[class_name]' not found." |
| Subject validation | Subject must belong to selected class | "Row [n]: Subject '[subject_name]' does not belong to class '[class_name]'." |
| Option validation | Options must be pipe-separated with valid data | "Row [n]: Options are missing or invalid." |
| Correct option index | Must point to an existing option | "Row [n]: Correct option number [x] exceeds the number of options provided." |
| Duplicate within file | Two identical rows in same file | "Row [n] is a duplicate of Row [m]." |
| Duplicate with existing | Same title+content as existing question | "Row [n]: This question appears to be a duplicate of existing question ID [id]." |
| Mid-import failure | Row fails during insert | Row skipped; other rows continue processing |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|---|---|---|---|
| Question Bank | `qns_questions_bank` | class_id, subject_id, lesson_id, topic_id | Question creation during import |
| Question Bank | `qns_question_options` | question_bank_id | Option creation for each imported question |
| Question Bank | `qns_question_questiontag_jnt` | question_bank_id / tag_id | Tag linking for imported questions |
| Question Bank | `qns_question_topic_jnt` | question_bank_id / topic_id | Additional topic mapping |
| School | `sch_classes` | class_id | Class validation during import |
| School | `sch_subjects` | subject_id | Subject validation during import |
| Curriculum | `slb_lessons` | lesson_id | Lesson validation |
| Curriculum | `slb_topics` | topic_id | Topic validation |
| Taxonomy | `slb_question_types` | question_type_id | Question type validation |
| Taxonomy | `slb_complexity_level` | complexity_level_id | Complexity level validation |

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| Download import template | Teacher | `import-questions.download-template` |
| Upload file for import | Teacher | `import-questions.upload` |
| Validate uploaded file | Teacher | `import-questions.validate` |
| Execute import | Teacher | `import-questions.execute` |
| Download error report | Teacher | `import-questions.download-report` |
| View import history | Admin | `import-questions.view-history` |

---

## Database Columns & Behavior

### qns_questions_bank

| Column | Type | FK | Nullable | Default | Behavior |
|---|---|---|---|---|---|
| id | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| uuid | BINARY(16) | No | No | – | Globally unique identifier via UUID_TO_BIN |
| class_id | INT UNSIGNED | sch_classes.id | No | – | Denormalized FK to class |
| subject_id | INT UNSIGNED | sch_subjects.id | No | – | Denormalized FK to subject |
| lesson_id | INT UNSIGNED | slb_lessons.id | No | – | Denormalized FK to lesson |
| topic_id | INT UNSIGNED | slb_topics.id | No | – | FK to topic (root or sub-topic depending on level) |
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
| is_active | TINYINT(1) | No | No | 1 | Active flag for soft delete |
| created_at | TIMESTAMP | No | No | CURRENT_TIMESTAMP | Record creation timestamp |
| updated_at | TIMESTAMP | No | No | CURRENT_TIMESTAMP ON UPDATE | Last update timestamp |
| deleted_at | TIMESTAMP | No | Yes | NULL | Soft delete timestamp |
