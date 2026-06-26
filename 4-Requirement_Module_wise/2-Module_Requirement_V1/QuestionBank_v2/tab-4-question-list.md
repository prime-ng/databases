# Tab 4: List of Questions (Main Question Bank)

This is the heart of the Question Bank module. From here, teachers do everything — create new questions, edit existing ones, clone them, change their status, view details, delete them, and import or export them. Every other tab supports this main one.

---

## Section 1: Viewing the Question List

When a teacher opens this tab, they see a table of all questions they have access to. Each row shows the question title, its current status (Draft, In Review, Approved, Published, or Archived), the class and subject it belongs to, the question type, complexity level, marks, who created it, and when.

The teacher can narrow down the list using filters. They can pick a class to see only questions for that class, then a subject within that class, then a lesson, then a topic — each filter narrowing the results further. They can also filter by question type (show only MCQs), complexity (show only Difficult questions), status (show only Published), creator, or date range. There is also a search box that looks through question titles and the question content itself.

The teacher can click on any question title to open its full details, or use the action buttons to edit, clone, or delete it directly from the list.

---

## Section 2: Creating a New Question

When the teacher clicks "Add Question," they go through a creation form that has four sections. The form does not auto-save, so if the teacher navigates away mid-way, everything they typed is lost. They must complete and submit the form in one go.

### Section A: Basic Information

The teacher starts by giving the question a title. This is mainly for the teacher's own reference — they can choose whether students will see it or not using a toggle. They pick which class, subject, lesson, and topic the question belongs to. The topic can go up to four levels deep (main topic, sub-topic, mini-topic, micro-topic). The teacher chooses how deep they want to go, and the system shows the appropriate number of dropdowns.

The teacher picks a question type — MCQ Single (one correct answer), MCQ Multi (multiple correct answers), True/False, Short Answer, Long Answer, Fill in the Blanks, or Matching. They also pick a complexity level (Easy, Medium, or Difficult) and set how many marks the question is worth. They can also set negative marks — a penalty for wrong answers — though most teachers set this to zero.

The actual question content goes into a rich text editor. Teachers can format text, add tables, insert math formulas using LaTeX notation, and more. They can also write an explanation that students will see after answering, explaining why the correct answer is right. There is an option to attach media — images, audio, or video — and position it above, below, left, or right of the question text.

### Section B: Settings and Ownership

Here the teacher decides who owns the question. If ownership is set to PrimeGurukul, the question is available across all schools on the platform. If set to School, only the creating school can use it. There is also a "School Specific" checkbox that restricts visibility even further — useful if a question should only be seen within the teacher's own school.

The teacher chooses which usage types are allowed for this question — Quiz, Quest, Exam, Offline Exam, or any combination. If none are checked, the question defaults to being available everywhere. This is important: when another teacher searches for questions while building a quiz, they will only see questions that have the "Quiz" usage type checked.

Next comes availability — who can see this question. There are six levels. Global means every school can see it. School Only means only the creating school. Class Only restricts it to teachers teaching that class. Section Only narrows it to a specific section. Entity Only limits it to a specific student group. Student Only makes it visible only to the teachers of one specific student. The teacher must pick one — if they pick Section Only, a section dropdown appears and they must select one.

There is an optional reviewer assignment section. The teacher can name another teacher to review this question before it goes live. If they set a reviewer and also give an approval decision at this point, the system records it as a fast-track review — the question can be published immediately with the reviewer's blessing. This is useful when the creator and reviewer are working together.

Finally, the teacher can optionally reference a textbook. They select a book and enter a page number. The system checks that the page number does not exceed the book's total pages. If it does, an error says "Page reference cannot exceed the book's total pages."

### Section C: Answer Options

For MCQ questions, the teacher adds between 2 and 5 answer options. Each option has text, an optional explanation, and a checkbox marking it as correct or incorrect. At least one option must be correct — if the teacher tries to submit without marking any correct, the system stops them with "At least one option must be marked as correct."

For MCQ Single questions, only one option can be correct. For MCQ Multi, multiple options can be correct — the student must select all of them to get full marks. True/False questions automatically have exactly two options. For Short Answer, Long Answer, and Fill in the Blanks questions, the options section is hidden entirely, since students type their answers instead.

Each option can also have its own media — an image next to that specific answer choice, for example. And each option's explanation can have media too.

### Section D: Tags and Additional Topics

The teacher can attach tags from the tag library to help organize the question. They can also link the question to additional topics beyond the primary one selected in Section A. This is useful when a question spans multiple topics — for example, a question about photosynthesis might relate to both Biology and Environmental Science.

Teachers can also map the question to performance categories. This enables the recommendation engine later: if a student fails a question in a certain category, the system can suggest other questions in the same category for practice.

### What Happens When the Teacher Saves

Once the teacher clicks Save, the system validates everything. If any required field is missing, it shows an error and returns the teacher to Section A with all their data preserved — nothing is lost. If everything is valid, the question is created with all its options, tags, media links, topic links, and performance category mappings.

The question starts in whatever status the teacher chose — Draft, In Review, Approved, or Published. If they chose Draft, only they can see it. If they chose Published, it becomes immediately available for use in assessments (subject to availability and usage type restrictions).

---

## Section 3: Viewing Question Details

Clicking any question in the list opens a detail view with five sub-tabs. The Overview tab shows a summary — the question's status, marks, complexity, class, subject, who created it, when, and how many assessments currently use it. The Question tab shows the full question content as students would see it. The Options tab shows all answer choices with the correct one highlighted. The Media tab shows any files attached. The History tab shows every review decision ever made on this question — who approved or rejected it, when, and what they said.

---

## Section 4: Editing a Question

Editing is where the rules get strict. The system checks whether the question has ever been used in any assessment. Three scenarios exist.

If the question has never been used anywhere, editing is wide open. The teacher can change anything — the content, the options, the marks, the topic, everything. A new version snapshot is saved before the changes are applied.

If the question is in some assessments but no student has answered it yet, editing is allowed but with a warning. The teacher sees "This question is currently used in X assessments. Editing may affect these assessments." They can proceed if they want.

If even one student has ever answered this question, editing is completely blocked. The teacher gets an error: "This question cannot be edited because it has been used in assessments by students. Clone this question to create a variant." The reason is simple: changing a question that students have already answered would mess up their scores. If the question was used in a quiz and 30 students answered it, changing the correct answer would make those 30 students' results wrong.

The only exception is if the teacher set a question's marks to override in a specific quiz — those overrides are set at the quiz level, not at the question level, so they don't count as editing the question itself.

When an edit is allowed and the teacher saves, the system does what is called a "clean slate update." It deletes all existing options, media links, tags, and topic links, then recreates everything from the form data. This ensures there are no orphaned or conflicting records. The entire operation is wrapped in a transaction — if anything fails, everything is rolled back to how it was before.

---

## Section 5: Cloning a Question

Cloning creates an exact copy of a question. The teacher clicks "Clone," and the system opens the creation form with every field pre-filled from the original. The teacher makes changes and saves it as a brand new question.

The clone has its own identity — a new ID, a new version counter starting at 1, and no usage history. The original question is completely unaffected. The system records which question the clone came from, but this is for reference only.

Cloning is the intended solution when a question is locked due to student attempts. Instead of editing the locked question, the teacher clones it, makes the changes they need, and uses the clone going forward. The original question stays in the system for historical accuracy.

The only rule about cloning is that the clone must differ from the original in some way — either the question content or the options. If the teacher tries to save an identical copy, the system says "The cloned question must differ from the original."

---

## Section 6: Changing Question Status

A question moves through several states during its life. Draft means the question is being built and only the creator can see it. In Review means it has been submitted for quality checking. Approved means the reviewer said it is good but it is not yet available for use. Published means it is live and can be used in assessments. Archived means it has been retired.

The teacher can change the status from the question list using a dropdown. Going from Draft to In Review submits the question for review. Going from Draft to Published skips review entirely — useful for experienced teachers creating questions for their own classes. Going from Approved to Published makes the question available. Going from Published to Archived retires it.

Some transitions are blocked. A question cannot go from In Review directly to Published — it must first be approved by a reviewer. A question cannot go from Published back to Draft if students have already answered it. A question cannot go from Archived back to Published directly — it must go back to Draft first, then through the normal flow.

---

## Section 7: Deleting a Question

Deleting a question follows the same logic as editing. If no student has ever answered the question, it can be deleted. If students have answered it, deletion is blocked. The reasoning is the same — deleting a question that was part of a quiz would break the historical record.

Soft delete hides the question but keeps everything in the database so it can be restored. Force delete removes everything permanently. Only admins can force delete. Restoring a soft-deleted question brings back all its options, media links, tags, and topic links.

If the question was used in assessments but no one answered it yet, deletion is allowed with a warning. If the question is in assessments that are currently ongoing — students are taking them right now — deletion is also blocked.

---

## Section 8: Importing Questions

Teachers can import questions in bulk from an Excel or CSV file. They download a template, fill it in with as many questions as they want (up to 500 per file), and upload it.

The system first validates the file — checking that the format is correct, that all required columns exist, that each row has valid data. If a row has a class name that doesn't exist, an error is reported. If a row is missing the question content, an error is reported. If a row appears to be a duplicate of an existing question, a warning is shown.

After validation, the system shows a summary — "120 rows valid, 5 rows with errors." The teacher can either fix the errors and re-upload, or import only the valid rows, skipping the problematic ones. All imported questions are created as Draft.

---

## Section 9: Exporting and Printing Questions

Teachers can print questions as a formatted document. They pick which questions to include using the same filters from the list view, and the system generates a print-friendly page with each question starting on a new page. The correct answer is marked, and any teacher explanation is shown. This is useful for creating physical question papers for offline exams.

---

## Important Business Rules

- The question creation form does not auto-save. If the teacher navigates away mid-way, all unsaved data is lost.
- At least one answer option must be marked correct for MCQ questions. The system blocks submission otherwise.
- For MCQ Single, exactly one option must be correct. For MCQ Multi, at least one option must be correct.
- Questions can only be fully edited (all fields) if no student has ever answered them. Once answered, only cloning is allowed.
- Editing a question that is used in assessments but not yet answered by students shows a warning but is allowed.
- The clean slate update on edit means all existing options, tags, and links are deleted and recreated. This is done in a transaction.
- A question status cannot change from In Review directly to Published. It must go through Approved first.
- Archived questions must go back to Draft before they can be Published again. They cannot go directly from Archived to Published.
- Deletion follows the same attempt-based logic as editing. If any student answered the question, deletion is blocked.
- Imported questions are always Draft. They cannot skip the review and publishing process.
- Each import file can contain up to 500 questions. Larger files must be split.
- Duplicate detection during import is a warning, not a block. The teacher can choose to import duplicates.
- Only admins can force delete. Regular teachers can only soft delete.
- The textbook page reference is validated against the book's total pages. If the page number exceeds the total, the save is blocked with an error.
- Performance category mappings feed the recommendation engine. If a student struggles with questions in a category, the engine suggests similar questions for practice.

---

## Deep Analysis

### Business Workflows & State Machines

| State | Trigger | Next State | Notes |
|---|---|---|---|
| Draft | Teacher clicks "Submit for Review" | In Review | Question enters review queue |
| Draft | Teacher sets status to Published | Published | Skips review entirely |
| In Review | Reviewer approves | Approved | Awaiting publishing step |
| In Review | Reviewer rejects | Draft | Returns to creator with rejection reason |
| In Review | Creator cancels review | Draft | Creator withdraws review request |
| Approved | Teacher clicks "Publish" | Published | Question becomes available for assessments |
| Published | Teacher clicks "Archive" | Archived | Question retired from active use |
| Archived | Teacher changes status to Draft | Draft | Must go through normal flow again |
| Any (no attempts) | Teacher clicks "Edit" | Edit Mode | Full edit allowed (clean slate update) |
| Any (with attempts) | Teacher clicks "Edit" | Blocked | "Clone this question to create a variant." |
| Any (no attempts) | Teacher clicks "Delete" | Soft Delete / Force Delete | Role-dependent |
| Any (with attempts) | Teacher clicks "Delete" | Blocked | Deletion blocked due to student data |
| Any | Teacher clicks "Clone" | Clone Form | Pre-filled copy of original question |
| Clone Form | Teacher saves (with changes) | Draft | New question with its own identity |

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|---|---|---|
| Question title | Required field | "Question title is required." |
| Question content | Required field | "Question content is required." |
| MCQ options count | Between 2 and 5 | "MCQ questions must have between 2 and 5 options." |
| MCQ correct option | At least one must be correct | "At least one option must be marked as correct." |
| MCQ Single correct | Exactly one must be correct | "MCQ Single questions must have exactly one correct option." |
| Edit with student attempts | Blocked entirely | "This question cannot be edited because it has been used in assessments by students. Clone this question to create a variant." |
| Edit with usage (no attempts) | Warning then allowed | "This question is currently used in [n] assessments. Editing may affect these assessments." |
| Status: In Review → Published | Blocked | "Questions in Review must be approved before publishing." |
| Status: Archived → Published | Blocked | "Archived questions must return to Draft before publishing." |
| Status: Published → Draft | Blocked if students answered | "Cannot return to Draft because students have answered this question." |
| Delete with student attempts | Blocked | "This question cannot be deleted because it has been answered by students." |
| Delete during active assessment | Blocked | "This question is part of an ongoing assessment and cannot be deleted." |
| Textbook page reference | Must not exceed total pages | "Page reference cannot exceed the book's total pages." |
| Clone identical to original | Blocked | "The cloned question must differ from the original." |
| Topic hierarchy | Up to 4 levels | Form shows appropriate number of dropdowns based on depth |
| Form navigation | No auto-save | Navigating away causes data loss |
| Clean slate update | Transactional | All or nothing; rollback on failure |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|---|---|---|---|
| Question Bank | `qns_questions_bank` | – | Main question records |
| Question Bank | `qns_question_options` | question_bank_id | Answer options for MCQ questions |
| Question Bank | `qns_question_questiontag_jnt` | question_bank_id / tag_id | Tag-to-question linking |
| Question Bank | `qns_question_topic_jnt` | question_bank_id / topic_id | Additional topic mapping |
| Question Bank | `qns_question_performance_category_jnt` | question_bank_id / performance_category_id | Performance category mapping |
| Question Bank | `qns_question_versions` | question_bank_id | Version snapshots on edit |
| Question Bank | `qns_question_usage_log` | question_bank_id | Edit/delete protection checks |
| Question Bank | `qns_question_review_log` | question_id | Review history |
| Question Bank | `qns_question_usage_type` | (referenced via for_quiz/for_quest/for_exam/for_offline_exam) | Usage type definitions |
| School | `sch_classes` | class_id | Class selection/filtering |
| School | `sch_subjects` | subject_id | Subject selection/filtering |
| Curriculum | `slb_lessons` | lesson_id | Lesson selection |
| Curriculum | `slb_topics` | topic_id | Topic selection (up to 4 levels) |
| Taxonomy | `slb_question_types` | question_type_id | Question type selection |
| Taxonomy | `slb_complexity_level` | complexity_level_id | Complexity level selection |
| Taxonomy | `slb_bloom_taxonomy` | bloom_id | Bloom's taxonomy |
| Taxonomy | `slb_cognitive_skill` | cognitive_skill_id | Cognitive skill selection |
| Taxonomy | `slb_ques_type_specificity` | ques_type_specificity_id | Question type specificity |
| Curriculum | `slb_books` | book_id | Textbook reference |
| Curriculum | `slb_performance_categories` | performance_category_id | Recommendation engine input |
| Users | `sch_users` | created_by | Creator tracking |

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| View question list | Teacher | `question-bank.viewAny` |
| Create question | Teacher | `question-bank.create` |
| Edit question (no attempts) | Teacher | `question-bank.update` |
| Edit question (with attempts) | Blocked (all roles) | – |
| Clone question | Teacher | `question-bank.clone` |
| Delete question (soft) | Teacher | `question-bank.delete` |
| Delete question (force) | Admin | `question-bank.force-delete` |
| Change status | Teacher | `question-bank.change-status` |
| Publish question | Teacher | `question-bank.publish` |
| Archive question | Teacher | `question-bank.archive` |
| Import questions | Teacher | `question-bank.import` |
| Export/print questions | Teacher | `question-bank.export` |
| View question details | Teacher | `question-bank.view-details` |
| Restore deleted question | Admin | `question-bank.restore` |
| View all questions (incl. deleted) | Admin | `question-bank.view-deleted` |

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
| is_active | TINYINT(1) | No | No | 1 | Soft delete flag |
| created_at | TIMESTAMP | No | No | CURRENT_TIMESTAMP | Record creation timestamp |
| updated_at | TIMESTAMP | No | No | CURRENT_TIMESTAMP ON UPDATE | Last update timestamp |
| deleted_at | TIMESTAMP | No | Yes | NULL | Soft delete timestamp |

### qns_question_tags

| Column | Type | FK | Nullable | Default | Behavior |
|---|---|---|---|---|---|
| id | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| short_name | VARCHAR(100) | No | No | – | Unique short code for internal lookups |
| name | VARCHAR(255) | No | No | – | Display name visible to users |
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

### qns_question_topic_jnt

| Column | Type | FK | Nullable | Default | Behavior |
|---|---|---|---|---|---|
| id | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| question_bank_id | INT UNSIGNED | qns_questions_bank.id | No | – | Question FK (CASCADE delete) |
| topic_id | INT UNSIGNED | slb_topics.id | No | – | Topic FK (CASCADE delete) |
| is_active | TINYINT(1) | No | No | 1 | Soft delete flag |
| created_at | TIMESTAMP | No | No | CURRENT_TIMESTAMP | Record creation timestamp |
| updated_at | TIMESTAMP | No | No | CURRENT_TIMESTAMP ON UPDATE | Last update timestamp |
| deleted_at | TIMESTAMP | No | Yes | NULL | Soft delete timestamp |

### qns_question_performance_category_jnt

| Column | Type | FK | Nullable | Default | Behavior |
|---|---|---|---|---|---|
| id | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| question_bank_id | INT UNSIGNED | qns_questions_bank.id | No | – | Question FK (CASCADE delete) |
| performance_category_id | INT UNSIGNED | slb_performance_categories.id | No | – | Performance category FK |
| recommendation_type | INT UNSIGNED | lms_assessment_types.id | No | – | Type of recommendation (REVISION/PRACTICE/CHALLENGE) |
| priority | SMALLINT UNSIGNED | No | No | 1 | Priority within the performance category |
| is_active | TINYINT(1) | No | No | 1 | Soft delete flag |
| created_at | TIMESTAMP | No | No | CURRENT_TIMESTAMP | Record creation timestamp |
| updated_at | TIMESTAMP | No | No | CURRENT_TIMESTAMP ON UPDATE | Last update timestamp |
| deleted_at | TIMESTAMP | No | Yes | NULL | Soft delete timestamp |

### qns_question_usage_log

| Column | Type | FK | Nullable | Default | Behavior |
|---|---|---|---|---|---|
| id | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| question_bank_id | INT UNSIGNED | qns_questions_bank.id | No | – | Question FK (CASCADE delete) |
| question_usage_type | ENUM('QUIZ','QUEST','ONLINE_EXAM','OFFLINE_EXAM') | No | No | – | Which assessment type used the question |
| context_id | INT UNSIGNED | sys_dropdowns.id | No | – | ID of the specific quiz/quest/exam instance |
| used_at | TIMESTAMP | No | No | CURRENT_TIMESTAMP | When the question was used |
| is_active | TINYINT(1) | No | No | 1 | Active/inactive toggle for edit protection override |
| created_at | TIMESTAMP | No | No | CURRENT_TIMESTAMP | Record creation timestamp |
| updated_at | TIMESTAMP | No | No | CURRENT_TIMESTAMP ON UPDATE | Last update timestamp |
| deleted_at | TIMESTAMP | No | Yes | NULL | Soft delete timestamp |
