# Question Bank (Quests) — Business Requirements

## What This Screen Does

The Question Bank screen is where teachers build and manage their collection of questions. Think of it as a master library: teachers create questions with all their details (the question text, answer options, marks, taxonomy tags, media attachments), organise them by class/subject/lesson/topic, and prepare them for use in quizzes, quests, and exams.

The main list view shows all questions with filters to narrow down by class, subject, lesson, topic, question type, Bloom level, complexity, status, marks range, and availability. Teachers can create new questions, edit existing ones, view details, clone variants, print question papers, import questions from Excel, and manage question status (DRAFT → IN_REVIEW → APPROVED → PUBLISHED → ARCHIVED).

---

## When This Screen Is Used

- **Creating a New Question** — When a teacher wants to add a question to the bank for future assessments
- **Editing a Question** — When a teacher needs to fix or improve a question's content, options, marks, or taxonomy
- **Viewing Question Details** — To review the full question with options, media, and review history
- **Cloning a Question** — To create a variant of an existing question (especially for platform-owned questions that cannot be directly edited)
- **Printing Question Papers** — To generate a printable version of filtered questions for offline exams
- **Bulk Import** — To upload multiple questions at once from an Excel file
- **Soft-Deleting and Restoring** — To temporarily remove a question or bring it back from trash
- **Force-Deleting** — To permanently remove a question (only if no student attempts exist)

---

## Who Can Access This Screen

- **Teacher** — Can create, edit, and manage their own questions
- **Head of Department** — Full access for their department's subjects
- **Academic Coordinator** — Full access for managing the question bank
- **Principal** — Read-only access to view questions
- **School Admin** — Full access including bulk approve, bulk archive

All access is controlled by permissions like `tenant.question-bank.create`, `tenant.question-bank.view`, `tenant.question-bank.update`, `tenant.question-bank.delete`, `tenant.question-bank.print`, `tenant.question-bank.import`, `tenant.question-bank.status`, `tenant.question-bank.restore`, `tenant.question-bank.forceDelete`. The server checks these permissions on every action.

**Note:** Some AJAX lookup endpoints (getSubjectsByClass, getLessonsBySubject, getTopicsByLesson, etc.) do not have permission gates, relying on the fact that they are called from within already-authorised pages.

---

## How This Screen Works — Logic Flow (Non-Technical)

### The Question List

When a teacher opens the Question Bank, the system shows a paginated list of questions (10 per page) with columns: #, Question (title + truncated content), Class/Subject, Topic, Type, Marks, Status, Active toggle, and Actions. A filter panel above the table lets teachers narrow down by Class, Section, Subject, Lesson, Topic (with 4-level hierarchy), Question Type, Bloom Level, Complexity, Cognitive Skill, Question Type Specificity, Status, Active/Inactive, Availability, and Marks range (via a dual slider).

The teacher can also access the AI Question Generator (magic wand button), the Import modal (upload button), and the Print button from the filter bar.

### Creating a Question

When the teacher clicks "Add Question," they see a form with all fields organized in sections:

**Basic Information section:** The teacher fills in the question title (optional display toggle), selects Class→Subject→Lesson→Topic (4-level cascading dropdowns), Competency, Complexity Level, Bloom's Taxonomy, Cognitive Skill, Question Specificity, Question Type, Content Format (Plain Text, HTML, Markdown, LaTeX, JSON), Status, Marks, Negative Marks, Expected Time, and the question content itself (via a rich text editor with LaTeX/MathJax support). The teacher can also add media to the question or teacher explanation.

**Settings & Audit section:** The teacher sets the question ownership (PrimeGurukul or School), School-Specific toggle, usage flags (Quiz, Quest, Exam, Offline Exam), availability scope (GLOBAL, SCHOOL_ONLY, CLASS_ONLY, SECTION_ONLY, ENTITY_ONLY, STUDENT_ONLY), book reference, external reference, and review metadata (review status, reviewer, comment).

**Options section:** For MCQ questions, the teacher adds at least 2 options, marks the correct one(s), sets ordinals, and optionally adds explanations and media per option.

**Tags, Topics & Performance section:** The teacher can attach tags, link additional topics (multi-topic mapping), and set performance category recommendations.

When the teacher clicks "Save," the system validates all fields, creates the question record, saves options, tags, topic mappings, performance categories, and media associations. The teacher is redirected to the question list with a success message.

### Editing a Question

When editing, the system first checks if any student has answered this question. If students have answered, editing is blocked — the teacher can only clone the question to create a variant. If no attempts exist, the same form loads with existing values filled in, and existing options/tags/topics/media are pre-populated.

### Viewing a Question

The detail view shows 5 tabs:
- **Overview:** Status badge, basic info (Class, Subject, Type, Difficulty, Bloom), meta info (Marks, Time, Negative Marks, Cognitive Level, Created By, AI-Generated flag, Usage Allowed badges), and usage in modules (if any)
- **Question:** Full question content with media layout (Above Text, Below Text, Left, Right) and teacher explanation
- **Options:** All options displayed in a 2-column grid with correct/incorrect badges and explanations
- **Media:** All attached media files (images, videos, audio, PDFs)
- **History:** Review log entries with reviewer, status, comment, and date

### Cloning a Question

Teachers can clone any question to create a variant. The clone form pre-fills all inherited fields (class, subject, lesson, topic, taxonomy, usage flags, ownership, availability) and copies all options. Platform-owned questions (ques_owner = 'PrimeGurukul') cannot be edited but can be cloned — the clone becomes school-owned.

### Printing Question Papers

The print feature generates a printable HTML document with the filtered questions. Each page shows 5 questions with their options, marks, and teacher explanations (if any). The document includes MathJax for LaTeX rendering and auto-triggers the browser print dialog.

### Bulk Import via Excel

Teachers can upload an Excel file (.xlsx or .csv) with question data. The system first validates the file format and content, showing errors in a downloadable report if any rows fail. On successful validation, the file is stored in the session, and the teacher can start the import. The import processes each row, creating questions and options while skipping invalid rows.

### Soft-Deleting and Restoring

When a teacher deletes a question, the system first checks if the question has been used in any LMS assessment (quiz, quest, or exam). If it has been used, deletion is blocked. If allowed, the question is soft-deleted (hidden but not permanently removed). The teacher can restore it from the Trash page.

### Force-Deleting

When a teacher permanently deletes a question from the Trash, the system checks for student attempts. If no attempts exist, the question is permanently deleted along with all its options, media associations, tags, topic mappings, and performance categories. If student attempts exist, force-delete is blocked.

### Toggle Status

Teachers can toggle the `is_active` flag on a question directly from the list view. This activates or deactivates the question without changing its workflow status. An activity log entry is created for each toggle.

### AJAX Lookup Endpoints

The system provides several AJAX endpoints that are called from the question form to populate cascading dropdowns without page reload:
- getSubjectsByClass — Loads subjects when a class is selected
- getLessonsBySubject — Loads lessons when a subject is selected
- getTopicsByLesson — Loads topics when a lesson is selected
- getTopicHierarchy — Loads topic tree by level and parent
- getTopicAncestors — Loads the ancestor chain for a selected topic
- getCognitiveSkillsByBloom — Loads cognitive skills when Bloom level is selected
- getSpecificityByCognitiveSkill — Loads question type specificities when cognitive skill is selected
- getCompetenciesBySubject — Loads competencies for the selected class/subject
- getSectionsByClass — Loads sections for a class
- getStudentsBySection — Loads students for a class/section
- getBookDetails — Loads book metadata including total pages
- getMediaByFilters — Loads media files by filter criteria
- getMediaDetails — Loads full details of a specific media file
- getTopicDetails — Loads details for a specific topic

---

## Validate Before Save

### Question Bank Request — Validation Rules

The system checks these fields before saving a question:

**Basic Info:**
- **ques_title** — Required, text, max 255 characters
- **ques_title_display** — Optional, yes/no
- **is_active** — Optional, yes/no
- **class_id** — Required, must exist in the classes table
- **subject_id** — Required, must exist in the subjects table
- **lesson_id** — Required, must exist in the lessons table
- **topic_level_id** — Required, whole number
- **topic_id** — Required, whole number
- **competency_id** — Required, whole number
- **question_type_id** — Required, must exist in the question types table
- **content_format** — Required, must be one of: TEXT, HTML, MARKDOWN, LATEX, JSON
- **status** — Required, must be one of: DRAFT, IN_REVIEW, APPROVED, REJECTED, PUBLISHED, ARCHIVED
- **complexity_level_id** — Required, must exist in the complexity levels table
- **bloom_id** — Required, must exist in the Bloom taxonomy table
- **cognitive_skill_id** — Required, must exist in the cognitive skills table
- **ques_type_specificity_id** — Required, must exist in the question type specificity table
- **marks** — Required, number, minimum 0, maximum 999.99
- **negative_marks** — Required, number, minimum 0, maximum 999.99
- **expected_time_to_answer_seconds** — Required, whole number, minimum 1, maximum 3600
- **question_content** — Required, text
- **teacher_explanation** — Optional, text
- **media_required_for_question** — Optional, yes/no
- **media_location_for_question** — Optional, must be one of: Above Text, Below Text, Left, Right
- **media_required_for_teacher_explanation** — Optional, yes/no
- **media_location_for_teacher_explanation** — Optional, must be one of: Above Text, Below Text, Left, Right

**Settings:**
- **ques_owner** — Required, must be one of: PrimeGurukul, School
- **is_school_specific** — Optional, yes/no
- **for_quiz** — Optional, yes/no
- **for_quest** — Optional, yes/no
- **for_exam** — Optional, yes/no
- **for_offline_exam** — Optional, yes/no
- **availability** — Required, must be one of: GLOBAL, SCHOOL_ONLY, CLASS_ONLY, SECTION_ONLY, ENTITY_ONLY, STUDENT_ONLY
- **selected_entity_group_id** — Required if availability is ENTITY_ONLY, must exist in entity groups table
- **selected_section_id** — Required if availability is SECTION_ONLY, must exist in sections table
- **selected_student_id** — Required if availability is STUDENT_ONLY, must exist in students table
- **current_version** — Optional, whole number, minimum 1
- **book_id** — Optional, must exist in the books table
- **book_page_ref** — Optional, whole number, minimum 1
- **external_ref** — Optional, text, max 100 characters
- **reference_material** — Optional, text
- **review_status_id** — Optional, whole number
- **ques_reviewed_by** — Required if review_status_id is provided, must exist in users table
- **review_comment** — Optional, text, max 1000 characters

**Options (array, minimum 2):**
- **options.*.text** — Required, text
- **options.*.is_correct** — Optional, yes/no (at least one must be true)
- **options.*.id** — Optional, whole number
- **options.*.display_title** — Optional, yes/no
- **options.*.explanation** — Optional, text
- **options.*.media_required_for_question_option** — Optional, yes/no
- **options.*.media_location_for_question_option** — Optional, must be one of: Above Text, Below Text, Left, Right
- **options.*.media_required_for_question_option_explanation** — Optional, yes/no
- **options.*.media_location_for_question_option_explanation** — Optional, must be one of: Above Text, Below Text, Left, Right
- **options.*.is_active** — Optional, yes/no
- **options.*.ordinal** — Optional, whole number, minimum 1

**Tags (optional array):**
- **tags.*.is_active** — Optional, yes/no
- **tags.*.tag_ids** — Optional array of tag IDs, each must exist in the question tags table

**Topic Weightage (optional array):**
- **topic_weightage.*.is_active** — Optional, yes/no
- **topic_weightage.*.topic_ids** — Optional array of topic IDs, each must exist in the topics table

**Performance Categories (optional array):**
- **performance.*.is_active** — Optional, yes/no
- **performance.*.category_ids** — Optional array of performance category IDs
- **performance.*.recommendation_type** — Optional, whole number
- **performance.*.priority** — Optional, whole number, minimum 1, maximum 10

**Media Data (optional):**
- **media_data.question** — Optional array for question media
- **media_data.teacher_explanation** — Optional array for teacher explanation media
- **media_data.option** — Optional array for option media
- **media_data.option_explanation** — Optional array for option explanation media

### Clone Request — Validation Rules

When cloning a question, the system validates a simpler set of fields:
- **ques_title** — Required, text, max 255
- **class_id, subject_id, lesson_id** — Required, must exist
- **topic_id, competency_id** — Required
- **question_content** — Required
- **content_format** — Required, must be one of TEXT/HTML/MARKDOWN/LATEX/JSON
- **status** — Required, must be one of DRAFT/IN_REVIEW/APPROVED/REJECTED/PUBLISHED/ARCHIVED
- **question_type_id, bloom_id, cognitive_skill_id, ques_type_specificity_id, complexity_level_id** — Required, must exist
- **marks** — Required, numeric, min 0, max 999.99
- **negative_marks** — Optional, numeric, min -100, max 0 (in the clone request; note this differs from the create/update request which uses min 0, max 999.99)
- **expected_time_to_answer_seconds** — Required, numeric, min 1, max 3600
- **ques_owner** — Required, must be PrimeGurukul or School
- **availability** — Required, must be one of GLOBAL/SCHOOL_ONLY/CLASS_ONLY/SECTION_ONLY/ENTITY_ONLY/STUDENT_ONLY

---

## Business Rules and Conditions

### Rule 1: Form Sections
The question form is organized into sections: Basic Information (curriculum, taxonomy, content, marks, time), Settings & Audit (ownership, usage flags, availability, book reference, review metadata), Options (answer options), and Tags, Topics & Performance (tags, multi-topic mapping, performance recommendations). All sections are submitted as a single form.

### Rule 2: Cascading Dropdowns
When the teacher selects a Class, the system automatically loads subjects for that class. Selecting a Subject loads lessons, and selecting a Lesson loads topics. Topic hierarchy supports 4 levels (Topic Level 1 → Sub-Topic → Mini-Topic → Micro-Topic) with cascading enabled based on the selected topic level.

### Rule 3: MCQ Option Validation
MCQ questions must have at least 2 options and at least one option marked as correct. The system blocks saving if these conditions are not met.

### Rule 4: Negative Marks Validation
Negative marks must be greater than or equal to 0.

### Rule 5: Platform Content Protection
Questions owned by the Platform (ques_owner = 'PrimeGurukul') cannot be edited or deleted by school teachers. A school teacher may only clone such a question to create their own school-owned copy.

### Rule 6: Immutability After Student Attempts
If any student has answered a question (checked via quiz, quest, and exam answer tables), the system blocks:
- Editing the question content, options, marks, or taxonomy
- Force-deleting the question
Only cloning is allowed to create a variant.

### Rule 7: Version Snapshot on Every Update
A version snapshot of the question's full prior state is created on every update, regardless of which fields changed.

### Rule 8: Availability Scope Filtering
The availability field determines who can see and use the question:
- GLOBAL — All teachers on the platform
- SCHOOL_ONLY — Teachers within this school
- CLASS_ONLY — Teachers who teach this class
- SECTION_ONLY — Teachers in the named section
- ENTITY_ONLY — Teachers for the named student group
- STUDENT_ONLY — Teachers of the named student
Question list queries apply this filter based on the requesting user's context.

### Rule 9: Question Lifecycle Status
Questions have a status field that can be set to one of: DRAFT, IN_REVIEW, APPROVED, REJECTED, PUBLISHED, ARCHIVED. The system accepts any status value during save without enforcing transition rules.

### Rule 10: Cascade on Force Delete
When a question is force-deleted, the system also permanently deletes all related data: options, media associations (junction records), tags (junction records), topic mappings, performance category mappings, version history records, usage log entries, and review log entries — all in a single database transaction.

### Rule 11: Usage Check Before Delete
Before soft-deleting or force-deleting a question, the system checks the QuestionUsageCheckService to see if the question is used in any LMS (quiz, quest, or exam). If it is used, the operation is blocked with a message explaining which assessments use the question.

### Rule 12: Privacy & Security Gate Gaps
Several AJAX lookup endpoints (getSubjectsByClass, getLessonsBySubject, getTopicsByLesson, getTopicHierarchy, getTopicAncestors, getCognitiveSkillsByBloom, getSpecificityByCognitiveSkill, getCompetenciesBySubject, getSectionsByClass, getStudentsBySection, getMediaByFilters, getTopicDetails, getBookDetails) do not have permission gates. They rely on being called from already-authorised pages.

### Rule 13: Import File Validation
The import validates the file extension (.xlsx or .csv only), then processes each row through QuestionImportService. If errors are found, a downloadable error report is generated. On success, the import creates questions and options from the validated data.

### Rule 14: Print Format
The print view renders 5 questions per page with a header showing the school organisation name, question title, class/subject, and page number. Each question card shows: Q-number, question content (with LaTeX rendering), marks badge, teacher explanation (if any), and options in a 2-column grid with letter prefixes (A, B, C, D).

---

## Business Rules Summary (Quick Reference)

| Rule | What It Means |
|------|--------------|
| Single Form | Basic Info + Settings + Options + Tags/Topics in one submission |
| Cascading Dropdowns | Class → Subject → Lesson → Topic (4-level hierarchy) |
| MCQ Options | Minimum 2 options, at least 1 correct |
| Negative Marks | Must be 0 or more |
| Platform Content | PrimeGurukul-owned questions cannot be edited/deleted — only cloned |
| Student Attempt Lock | Once a student answers, the question cannot be edited or force-deleted |
| Version Snapshots | A full snapshot is created on every update |
| Availability Scope | GLOBAL/SCHOOL/CLASS/SECTION/ENTITY/STUDENT filtering |
| Status Field | DRAFT, IN_REVIEW, APPROVED, REJECTED, PUBLISHED, ARCHIVED (no transition enforcement) |
| Force Delete Cascade | Deletes question + all related data in one transaction |
| Usage Check | Questions used in LMS assessments cannot be deleted |
| Print Format | 5 questions per page with options in 2-column grid |
| Import Validation | .xlsx/.csv only; error report on failure |

---

## Validate Before Save — Error Messages

| Scenario | Error Message |
|----------|--------------|
| Missing question title | "The ques title field is required." |
| Class not selected | "The class id field is required." |
| Marks exceeds max | "marks must not exceed 999.99" |
| Negative marks exceeds max | "negative marks must not exceed 999.99" |
| No correct option | "At least one option must be marked as correct." |
| Only 1 option for MCQ | "MCQ questions must have between 2 and 5 options" |
| Invalid content format | "The selected content format is invalid." |
| Question type not selected | "The question type id field is required." |
| Bloom level not selected | "The bloom id field is required." |
| Expected time out of range | "expected time to answer seconds must be between 1 and 3600." |
| Invalid availability | "The selected availability is invalid." |
| Entity group missing for ENTITY_ONLY | "The selected entity group id field is required when availability is ENTITY_ONLY." |
| Section missing for SECTION_ONLY | "The selected section id field is required when availability is SECTION_ONLY." |
| Student missing for STUDENT_ONLY | "The selected student id field is required when availability is STUDENT_ONLY." |
| Book not found | "Book not found" (from AJAX endpoint) |
| Topic not found | "Topic not found" (from AJAX endpoint) |
| Media not found | "Media not found" (from getMediaDetails) |
| Edit blocked — student attempts | "This question cannot be edited because it has been answered by students. Clone to create a variant." |
| Delete blocked — used in LMS | "[usage message] Therefore cannot be deleted." |
| Force-delete blocked — attempted | "[usage message] Therefore cannot be permanently deleted." |
| Import file missing | "The file field is required." |
| Import file wrong type | "The file must be a file of type: xlsx, csv." |
| Import — no validated file | "No validated file found" |

---

## Success Scenarios

- A teacher creates a new MCQ question: Title = "Photosynthesis Process", Class = 10, Subject = Biology, Lesson = "Plant Life", Topic = "Photosynthesis", Question Type = MCQ Single, Content Format = HTML, Marks = 4.00, Negative Marks = 1.00, Status = DRAFT, with 4 options (C marked correct). The system saves the question with all 4 options and shows it in the question list.

- A teacher clones a PrimeGurukul-owned question. The clone form pre-fills all fields. The teacher changes the title to "Algebra Basics (Variant)" and modifies the numbers. The clone is saved with ques_owner = School.

- A teacher prints filtered questions for Class 10, Subject = Physics. The browser opens a print dialog with 10 questions arranged 5 per page, each showing the question content, options, marks, and teacher explanation.

- A teacher imports 50 questions from an Excel file. The system validates all rows (48 pass, 2 have errors). The error report is downloaded. The 48 valid questions are created. The teacher corrects the 2 errors and re-imports.

---

## Failure Scenarios

- A teacher tries to edit a question that has been answered by 15 students. The usage check blocks the edit with "This question cannot be edited because it has been answered by students. Clone to create a variant."

- A teacher tries to set negative_marks = -1.00. The system rejects with a validation error because negative_marks must be between 0 and 999.99.

- A teacher creates an MCQ question with only 1 option. The system rejects with "MCQ questions must have between 2 and 5 options."

- A teacher tries to delete a question used in 3 quizzes. The usage check blocks deletion with "[Quiz: Science Quiz, Math Test, ...] Therefore cannot be deleted."

- A teacher uploads a .pdf file for import. The system rejects with "The file must be a file of type: xlsx, csv."

---

## Example Scenario

Ms. Sharma, a Grade 10 Biology teacher, wants to create a new MCQ question for her upcoming quiz.

She navigates to Question Bank and clicks "Add Question":
1. **Basic Information:** She enters Title = "Photosynthesis — Light Reaction", selects Class = 10, Subject = Biology, Lesson = "Plant Physiology", Topic Level = 1, Topic = "Photosynthesis", Competency = "Understanding", Complexity = Medium, Bloom = "Understand", Cognitive Skill = "Interpretation", Question Type = MCQ Single, Content Format = HTML, Status = DRAFT, Marks = 4.00, Negative Marks = 1.00, Expected Time = 60 seconds. She types the question in the editor: "What is the primary pigment involved in photosynthesis?" and clicks "Media Required?" → Yes with location "Below Text".

2. **Settings:** She selects Ownership = School, enables "Usable in Quiz" and "Usable in Quest", sets Availability = GLOBAL, leaves book reference empty.

3. **Options:** She adds 4 options:
   - Option A: "Chlorophyll" (Correct = Yes)
   - Option B: "Hemoglobin"
   - Option C: "Melanin"
   - Option D: "Carotene"
   She adds an explanation for Option A: "Chlorophyll is the green pigment that captures light energy."

4. **Tags:** She adds tag "Photosynthesis" from the tag dropdown.

5. She clicks "Save". The system validates all fields, creates the question with ID = 102, saves all 4 options, and redirects to the question list.

Later, she realises the marks should be 5.00 instead of 4.00. Since no student has attempted this question, she opens it for edit, changes marks to 5.00, and saves the update. A version snapshot is created before the save.

After a month, the question has been used in 2 quizzes. She tries to delete it but the system blocks the deletion because it is in use.

---

## Related Screens

- **Question Tags** — Where tag master data is managed for categorising questions
- **Question Usage Type** — Where assessment usage types (Quiz, Quest, Exam, Offline Exam) are defined
- **Question Versions** — Where version history snapshots are viewed
- **Question Statistics** — Where question performance metrics are displayed
- **Question Media Store** — Where media files are managed
- **Question Review** — Where the review/approval workflow is managed
- **Question Usage Log** — Where question usage in assessments is tracked
- **AI Question Generator** — Where teachers generate questions using AI
- **LmsQuiz / LmsQuests / LmsExam** — Consuming modules that use questions from this bank

---

## Dependencies module and tables

| Module | Tables |
|--------|--------|
| QuestionBank Core | `qns_questions_bank` (primary table), `qns_question_options`, `qns_question_media_jnt`, `qns_question_questiontag_jnt`, `qns_question_topic_jnt`, `qns_question_performance_category_jnt` |
| Syllabus | `slb_bloom_taxonomy`, `slb_cognitive_skill`, `slb_complexity_level`, `slb_question_types`, `slb_ques_type_specificity`, `slb_lessons`, `slb_topics`, `slb_competencies`, `slb_books`, `slb_entity_groups`, `slb_performance_categories` |
| School Setup | `sch_classes`, `sch_subjects`, `sch_sections`, `sch_class_sections`, `sch_subject_group_subject_jnt` |
| Student Profile | `std_students`, `std_student_academic_sessions` |
| System Config | `sys_users`, `sys_dropdown_table` |
| Media Store | `qns_media_store`, `qns_question_media_jnt` |
| Version History | `qns_question_versions` |
| Review Log | `qns_question_review_log` |
| Usage Log | `qns_question_usage_log`, `qns_question_usage_type` |
| LmsQuiz | `quz_quiz_attempt_answers` (usage check) |
| LmsQuests | `lms_quest_questions` (usage check) |
| LmsExam | `exm_exam_attempt_answers` (usage check) |
