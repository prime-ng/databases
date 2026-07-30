# qns_QuestionBank_Quests_TcList

## Module: QuestionBank → Question Management → Question CRUD

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | QuestionBank (QNS) |
| Tab Group | Question Bank (Tabbed Interface) |
| Features | Question List, Create/Edit/View/Clone/Delete/Restore, Import, Print, AJAX Lookups (REQ-QNS-001, 002, 003, 008, 009, 012, 013) |
| URL(s) | `/question-bank/question-bank`, `/question-bank/question-bank/create`, `/question-bank/question-bank/{id}/edit`, `/question-bank/question-bank/{id}`, `/question-bank/question-bank/{id}/clone`, `/question-bank/question-bank/clones`, `/question-bank/trash/view`, `/question-bank/{id}/restore`, `/question-bank/{id}/force-delete`, `/question-bank/{question_bank}/toggle-status`, `/question-bank/print`, `/question-bank/validate-file`, `/question-bank/start-import`, `/question-bank/get-subjects-by-class`, `/question-bank/get-lessons-by-subject`, `/question-bank/get-topics-by-lesson`, `/question-bank/get-topic-hierarchy`, `/question-bank/get-topic-ancestors`, `/question-bank/get-cognitive-skills-by-bloom`, `/question-bank/get-specificity-by-cognitive-skill`, `/question-bank/get-competencies-by-subject`, `/question-bank/get-sections-by-class`, `/question-bank/get-students-by-section`, `/question-bank/get-media-details`, `/question-bank/get-book-details`, `/question-bank/get-media-by-filters`, `/question-bank/get-topic-details` |
| Controller | `Modules\QuestionBank\Http\Controllers\QuestionBankController` |
| Model(s) | `QuestionBank`, `QuestionOption`, `QuestionQuestionTagJnt`, `QuestionTopicJnt`, `QuestionPerformanceCategoryJnt`, `QuestionMedia` |
| Validation | `QuestionBankRequest` (48+ rules), inline validation in `validateFile()`, `storeClone()`, AJAX endpoints |
| Permission Gates | `tenant.question-bank.viewAny`, `tenant.question-bank.view`, `tenant.question-bank.create`, `tenant.question-bank.update`, `tenant.question-bank.delete`, `tenant.question-bank.restore`, `tenant.question-bank.forceDelete`, `tenant.question-bank.status`, `tenant.question-bank.print` |
| Soft Deletes | Yes — all main entities support soft deletes |
| Events | Activity log on toggleStatus (`activityLog()`) |

---

## 2. Pre-conditions

- Required permissions: `tenant.question-bank.viewAny`, `tenant.question-bank.create`, `tenant.question-bank.update`, `tenant.question-bank.view`, `tenant.question-bank.delete`, `tenant.question-bank.restore`, `tenant.question-bank.forceDelete`, `tenant.question-bank.status`, `tenant.question-bank.print`
- At least one active Class, Subject, Lesson, Topic must exist in the Syllabus/School Setup modules
- At least one Question Type, Bloom Taxonomy, Complexity Level, Cognitive Skill, Question Type Specificity must exist
- For AJAX cascading tests: Classes with subjects, subjects with lessons, lessons with topics must be present
- For import tests: A valid .xlsx/.csv file with question data
- For clone tests: At least one existing question to clone from
- For usage-check tests: The question must be referenced in quiz/quest/exam answer tables

---

## 3. Default Data Load

### 3.1 Filter Data for Question List

The `QuestionLookupService::getFilterData()` method returns:
- `classes` — Active school classes
- `sections` — Active class sections
- `subjects` — Active subjects
- `lessons` — Active lessons
- `topics` — Active topics
- `topicLevels` — Topic hierarchy levels
- `questionTypes` — Active question types
- `bloomTaxonomies` — Active Bloom taxonomy levels
- `complexityLevels` — Active complexity levels
- `cognitiveSkills` — Active cognitive skills
- `questionSpecificities` — Active question type specificities
- `questionStatuses` — DRAFT, IN_REVIEW, APPROVED, REJECTED, PUBLISHED, ARCHIVED
- `availabilityOptions` — GLOBAL, SCHOOL_ONLY, CLASS_ONLY, SECTION_ONLY, ENTITY_ONLY, STUDENT_ONLY
- `questionTags` — Active question tags (note: `QuestionLookupService::getFilterData()` does NOT return questionTags; this data is loaded separately in the controller or view)

### 3.2 Create/Edit Form Data

The `QuestionCRUDService::getCreateData()` and `getEditData()` methods populate:
- All filter data above
- `performanceCategories` — Active performance categories
- `mediaItems` — Active media items from QuestionMediaStore
- `books` — Active books from Syllabus module (`slb_books`)
- `users` — System users with type TEACHER for reviewer assignment
- `recommendationType` — Dropdown values for performance category recommendation type
- `topicLevels` — Ordered topic level types
- Question data with relations (for edit)
- Existing options, tags, topics, performance categories (for edit)

---

## 4. BC-DB — Database Schema

### 4.1 `qns_questions_bank` — Primary Question Table

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| uuid | BINARY(16) | NOT NULL | — | Unique identifier, `UUID_TO_BIN(UUID())` |
| class_id | INT UNSIGNED | YES | NULL | FK → sch_classes.id |
| subject_id | INT UNSIGNED | YES | NULL | FK → sch_subjects.id |
| lesson_id | INT UNSIGNED | YES | NULL | FK → slb_lessons.id |
| topic_id | INT UNSIGNED | YES | NULL | FK → slb_topics.id |
| competency_id | INT UNSIGNED | YES | NULL | FK → slb_competencies.id |
| ques_title | VARCHAR(255) | NOT NULL | — | Question title (system use) |
| ques_title_display | TINYINT(1) | NOT NULL | 0 | Display title to students? |
| question_content | TEXT | NOT NULL | — | Question content (user display) |
| content_format | ENUM('TEXT','HTML','MARKDOWN','LATEX','JSON') | NOT NULL | 'TEXT' | Content format |
| media_required_for_question | TINYINT(1) | NOT NULL | 0 | Media required? |
| media_location_for_question | ENUM('Above Text','Below Text','Left','Right') | YES | 'Below Text' | Media location |
| teacher_explanation | TEXT | YES | NULL | Teacher explanation |
| media_required_for_teacher_explanation | TINYINT(1) | NOT NULL | 0 | Media for explanation? |
| media_location_for_teacher_explanation | ENUM('Above Text','Below Text','Left','Right') | YES | 'Below Text' | Media location for explanation |
| bloom_id | INT UNSIGNED | YES | NULL | FK → slb_bloom_taxonomy.id |
| cognitive_skill_id | INT UNSIGNED | YES | NULL | FK → slb_cognitive_skill.id |
| ques_type_specificity_id | INT UNSIGNED | YES | NULL | FK → slb_ques_type_specificity.id |
| complexity_level_id | INT UNSIGNED | YES | NULL | FK → slb_complexity_level.id |
| question_type_id | INT UNSIGNED | NOT NULL | — | FK → slb_question_types.id |
| expected_time_to_answer_seconds | INT UNSIGNED | YES | NULL | Expected answer time |
| marks | DECIMAL(5,2) | YES | 1.00 | Marks for correct answer |
| negative_marks | DECIMAL(5,2) | YES | 0.00 | Negative marking |
| current_version | TINYINT UNSIGNED | NOT NULL | 1 | Version number |
| for_quiz | TINYINT(1) | NOT NULL | 1 | Usable in quiz? |
| for_quest | TINYINT(1) | NOT NULL | 0 | Usable in quest? |
| for_exam | TINYINT(1) | NOT NULL | 0 | Usable in exam? |
| for_offline_exam | TINYINT(1) | NOT NULL | 0 | Usable in offline exam? |
| ques_owner | ENUM('PrimeGurukul','School') | NOT NULL | 'PrimeGurukul' | Content owner |
| created_by_AI | TINYINT(1) | YES | 0 | AI-generated? |
| created_by | INT UNSIGNED | YES | NULL | FK → sys_users.id |
| is_school_specific | TINYINT(1) | YES | 0 | School-specific? |
| availability | ENUM('GLOBAL','SCHOOL_ONLY','CLASS_ONLY','SECTION_ONLY','ENTITY_ONLY','STUDENT_ONLY') | YES | 'GLOBAL' | Visibility scope |
| selected_entity_group_id | INT UNSIGNED | YES | NULL | FK → slb_entity_groups.id |
| selected_section_id | INT UNSIGNED | YES | NULL | FK → sch_sections.id |
| selected_student_id | INT UNSIGNED | YES | NULL | FK → std_students.id |
| book_id | INT UNSIGNED | YES | NULL | FK → slb_books.id |
| book_page_ref | VARCHAR(50) | YES | NULL | Book page reference |
| external_ref | VARCHAR(100) | YES | NULL | External bank reference |
| reference_material | TEXT | YES | NULL | Reference material |
| status | ENUM('DRAFT','IN_REVIEW','APPROVED','REJECTED','PUBLISHED','ARCHIVED') | NOT NULL | 'DRAFT' | Lifecycle status |
| is_active | TINYINT(1) | YES | 1 | Active flag |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | Update time |
| deleted_at | TIMESTAMP | YES | NULL | Soft delete time |

**Indexes:**
- PRIMARY KEY (`id`)
- UNIQUE KEY `idx_ques_uuid` (`uuid`)
- KEY `idx_ques_topic` (`topic_id`)
- KEY `idx_ques_competency` (`competency_id`)
- KEY `idx_ques_class_subject` (`class_id`,`subject_id`)
- KEY `idx_ques_complexity_bloom` (`complexity_level_id`,`bloom_id`)
- KEY `idx_ques_active` (`is_active`)
- KEY `idx_ques_book` (`book_id`)
- KEY `idx_ques_availability` (`availability`)

### 4.2 `qns_question_options` — Question Options Table

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| question_bank_id | INT UNSIGNED | NOT NULL | — | FK → qns_questions_bank.id |
| ordinal | SMALLINT UNSIGNED | YES | NULL | Display order |
| option_text | TEXT | NOT NULL | — | Option content |
| media_required_for_question_option | TINYINT(1) | NOT NULL | 0 | Media required for option? |
| media_location_for_question_option | ENUM('Above Text','Below Text','Left','Right') | YES | 'Below Text' | Media location for option |
| is_correct | TINYINT(1) | NOT NULL | 0 | Is this the correct answer? |
| explanation | TEXT | YES | NULL | Option explanation |
| media_required_for_question_option_explanation | TINYINT(1) | NOT NULL | 0 | Media for option explanation? |
| media_location_for_question_option_explanation | ENUM('Above Text','Below Text','Left','Right') | YES | 'Below Text' | Media location for option explanation |
| is_active | TINYINT(1) | YES | 1 | Active flag |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | Update time |
| deleted_at | TIMESTAMP | YES | NULL | Soft delete time |

**Indexes:** KEY `idx_opt_question` (`question_bank_id`)

### 4.3 `qns_question_questiontag_jnt` — Question-Tag Junction

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| question_bank_id | INT UNSIGNED | NOT NULL | — | FK → qns_questions_bank.id |
| tag_id | INT UNSIGNED | NOT NULL | — | FK → qns_question_tags.id |
| is_active | TINYINT(1) | YES | 1 | Active flag |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | |
| deleted_at | TIMESTAMP | YES | NULL | |

**Indexes:** UNIQUE KEY `uq_qtag_q_t` (`question_bank_id`,`tag_id`)

### 4.4 `qns_question_topic_jnt` — Question-Topic Junction

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| question_bank_id | INT UNSIGNED | NOT NULL | — | FK → qns_questions_bank.id |
| topic_id | INT UNSIGNED | NOT NULL | — | FK → slb_topics.id |
| is_active | TINYINT(1) | YES | 1 | Active flag |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | |
| deleted_at | TIMESTAMP | YES | NULL | |

**Indexes:** UNIQUE KEY `uq_qt_q_t` (`question_bank_id`,`topic_id`)

### 4.5 `qns_question_performance_category_jnt` — Question-Performance Category Junction

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| question_bank_id | INT UNSIGNED | NOT NULL | — | FK → qns_questions_bank.id |
| performance_category_id | INT UNSIGNED | NOT NULL | — | FK → slb_performance_categories.id |
| recommendation_type | INT UNSIGNED | NOT NULL | — | FK to dropdown (REVISION/PRACTICE/CHALLENGE) |
| priority | SMALLINT UNSIGNED | YES | 1 | Priority 1-10 |
| is_active | TINYINT(1) | YES | 1 | |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | |
| deleted_at | TIMESTAMP | YES | NULL | |

**Indexes:** UNIQUE KEY `uq_qrec_q_p` (`question_bank_id`, `performance_category_id`)

### 4.6 `qns_question_media_jnt` — Question-Media Junction

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| question_bank_id | INT UNSIGNED | NOT NULL | — | FK → qns_questions_bank.id |
| question_option_id | INT UNSIGNED | YES | NULL | FK → qns_question_options.id |
| media_purpose | ENUM('QUESTION','OPTION','QUES_EXPLANATION','OPT_EXPLANATION','RECOMMENDATION') | YES | 'QUESTION' | Purpose of media |
| media_id | INT UNSIGNED | NOT NULL | — | FK → qns_media_store.id |
| is_active | TINYINT(1) | YES | 1 | |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | |
| deleted_at | TIMESTAMP | YES | NULL | |

**Indexes:** KEY `idx_qmedia_question` (`question_bank_id`), KEY `idx_qmedia_option` (`question_option_id`)

---

## 5. BC-VAL — Validation Rules

### 5.1 QuestionBankRequest Validation

| Field | Rules | Error Message |
|-------|-------|---------------|
| ques_title | required, string, max:255 | "The ques title field is required." |
| ques_title_display | nullable, boolean | — |
| is_active | nullable, boolean | — |
| class_id | required, integer, exists:sch_classes,id | "The class id field is required." |
| subject_id | required, integer, exists:sch_subjects,id | "The subject id field is required." |
| lesson_id | required, integer, exists:slb_lessons,id | "The lesson id field is required." |
| topic_level_id | required, integer | "The topic level id field is required." |
| topic_id | required, integer | "The topic id field is required." |
| competency_id | required, integer | "The competency id field is required." |
| question_type_id | required, integer, exists:slb_question_types,id | "The question type id field is required." |
| content_format | required, string, in:TEXT,HTML,MARKDOWN,LATEX,JSON | "The selected content format is invalid." |
| status | required, string, in:DRAFT,IN_REVIEW,APPROVED,REJECTED,PUBLISHED,ARCHIVED | "The selected status is invalid." |
| complexity_level_id | required, integer, exists:slb_complexity_level,id | "The complexity level id field is required." |
| bloom_id | required, integer, exists:slb_bloom_taxonomy,id | "The bloom id field is required." |
| cognitive_skill_id | required, integer, exists:slb_cognitive_skill,id | "The cognitive skill id field is required." |
| ques_type_specificity_id | required, integer, exists:slb_ques_type_specificity,id | "The ques type specificity id field is required." |
| marks | required, numeric, min:0, max:999.99 | "marks must not exceed 999.99" |
| negative_marks | required, numeric, min:0, max:999.99 | "negative marks must not exceed 999.99" |
| expected_time_to_answer_seconds | required, integer, min:1, max:3600 | "expected time to answer seconds must be between 1 and 3600." |
| question_content | required, string | "The question content field is required." |
| teacher_explanation | nullable, string | — |
| media_required_for_question | nullable, boolean | — |
| media_location_for_question | nullable, string, in:Above Text,Below Text,Left,Right | "The selected media location for question is invalid." |
| media_required_for_teacher_explanation | nullable, boolean | — |
| media_location_for_teacher_explanation | nullable, string, in:Above Text,Below Text,Left,Right | "The selected media location for teacher explanation is invalid." |
| ques_owner | required, string, in:PrimeGurukul,School | "The selected ques owner is invalid." |
| is_school_specific | nullable, boolean | — |
| for_quiz | nullable, boolean | — |
| for_quest | nullable, boolean | — |
| for_exam | nullable, boolean | — |
| for_offline_exam | nullable, boolean | — |
| availability | required, string, in:GLOBAL,SCHOOL_ONLY,CLASS_ONLY,SECTION_ONLY,ENTITY_ONLY,STUDENT_ONLY | "The selected availability is invalid." |
| selected_entity_group_id | nullable, required_if:availability,ENTITY_ONLY, integer, exists:slb_entity_groups,id | "The selected entity group id field is required when availability is ENTITY_ONLY." |
| selected_section_id | nullable, required_if:availability,SECTION_ONLY, integer, exists:sch_sections,id | "The selected section id field is required when availability is SECTION_ONLY." |
| selected_student_id | nullable, required_if:availability,STUDENT_ONLY, integer, exists:std_students,id | "The selected student id field is required when availability is STUDENT_ONLY." |
| current_version | nullable, integer, min:1, max:255 | — |
| book_id | nullable, integer, exists:slb_books,id | "The selected book id is invalid." |
| book_page_ref | nullable, integer, min:1 | — |
| external_ref | nullable, string, max:100 | — |
| reference_material | nullable, string | — |
| review_status_id | nullable, integer | — |
| ques_reviewed_by | nullable, required_with:review_status_id, integer, exists:sys_users,id | — |
| review_comment | nullable, string, max:1000 | — |
| options | required, array, min:2 | "options must contain at least 2 items." |
| options.*.text | required, string | "The options.0.text field is required." |
| options.*.id | nullable, integer | — |
| options.*.is_correct | nullable, boolean | — |
| options.*.display_title | nullable, boolean | — |
| options.*.explanation | nullable, string | — |
| options.*.media_required_for_question_option | nullable, boolean | — |
| options.*.media_location_for_question_option | nullable, string, in:Above Text,Below Text,Left,Right | — |
| options.*.media_required_for_question_option_explanation | nullable, boolean | — |
| options.*.media_location_for_question_option_explanation | nullable, string, in:Above Text,Below Text,Left,Right | — |
| options.*.is_active | nullable, boolean | — |
| options.*.ordinal | nullable, integer, min:1 | — |
| tags | nullable, array | — |
| tags.*.is_active | nullable, boolean | — |
| tags.*.tag_ids | nullable, array | — |
| tags.*.tag_ids.* | integer, exists:qns_question_tags,id | — |
| topic_weightage | nullable, array | — |
| topic_weightage.*.is_active | nullable, boolean | — |
| topic_weightage.*.topic_ids | nullable, array | — |
| topic_weightage.*.topic_ids.* | integer, exists:slb_topics,id | — |
| performance | nullable, array | — |
| performance.*.is_active | nullable, boolean | — |
| performance.*.category_ids | nullable, array | — |
| performance.*.category_ids.* | integer, exists:slb_performance_categories,id | — |
| performance.*.recommendation_type | nullable, integer | — |
| performance.*.priority | nullable, integer, min:1, max:10 | — |
| media_data | nullable, array | — |
| media_data.question | nullable, array | — |
| media_data.teacher_explanation | nullable, array | — |
| media_data.option | nullable, array | — |
| media_data.option_explanation | nullable, array | — |

### 5.2 Clone Request Validation (inline in storeClone)

| Field | Rules |
|-------|-------|
| ques_title | required, string, max:255 |
| class_id | required, integer, exists:sch_classes,id |
| subject_id | required, integer, exists:sch_subjects,id |
| lesson_id | required, integer, exists:slb_lessons,id |
| topic_id | required, integer |
| competency_id | required, integer |
| question_content | required, string |
| content_format | required, string, in:TEXT,HTML,MARKDOWN,LATEX,JSON |
| status | required, string, in:DRAFT,IN_REVIEW,APPROVED,REJECTED,PUBLISHED,ARCHIVED |
| question_type_id | required, integer, exists:slb_question_types,id |
| bloom_id | required, integer, exists:slb_bloom_taxonomy,id |
| cognitive_skill_id | required, integer, exists:slb_cognitive_skill,id |
| ques_type_specificity_id | required, integer, exists:slb_ques_type_specificity,id |
| complexity_level_id | required, integer, exists:slb_complexity_level,id |
| marks | required, numeric, min:0, max:999.99 |
| negative_marks | nullable, numeric, min:-100, max:0 |
| expected_time_to_answer_seconds | required, numeric, min:1, max:3600 |
| ques_owner | required, string, in:PrimeGurukul,School |
| availability | required, string, in:GLOBAL,SCHOOL_ONLY,CLASS_ONLY,SECTION_ONLY,ENTITY_ONLY,STUDENT_ONLY |

### 5.3 File Import Validation (inline)

| Field | Rules |
|-------|-------|
| file | required, mimes:xlsx,csv |

---

## 6. BC-AUTH — Authorization

| Permission Gate | Controller Method(s) | Model Policy |
|----------------|---------------------|-------------|
| tenant.question-bank.viewAny | index(), reviewIndex() | QuestionBankPolicy@viewAny |
| tenant.question-bank.view | show(), reviewShow(), getMediaDetails() | QuestionBankPolicy@view |
| tenant.question-bank.create | create(), store(), storeClone(), clone(), validateFile(), startImport() | QuestionBankPolicy@create |
| tenant.question-bank.update | edit(), update(), toggleStatus(), toggleStatusLog(), reviewApprove(), reviewReject() | QuestionBankPolicy@update |
| tenant.question-bank.delete | destroy() | QuestionBankPolicy@delete |
| tenant.question-bank.restore | trashed(), restore() | QuestionBankPolicy@restore |
| tenant.question-bank.forceDelete | forceDelete() | QuestionBankPolicy@forceDelete |
| tenant.question-bank.status | (used in Blade @can for status toggle column) | QuestionBankPolicy@status |
| tenant.question-bank.print | print() | QuestionBankPolicy@print |

**Ungated AJAX endpoints:** getSubjectsByClass, getLessonsBySubject, getTopicsByLesson, getTopicHierarchy, getTopicAncestors, getCognitiveSkillsByBloom, getSpecificityByCognitiveSkill, getCompetenciesBySubject, getSectionsByClass, getStudentsBySection, getMediaByFilters, getTopicDetails, getBookDetails

**Blade @can directives used in views:**
- `@can('tenant.question-bank.status')` — Status toggle column
- `@can('tenant.question-bank.view')` — View action button
- `@can('tenant.question-bank.edit')` / `@can('tenant.question-bank.update')` — Edit action button
- `@can('tenant.question-bank.delete')` — Delete action button
- `@can('tenant.question-bank.import')` — Import button
- `@can('tenant.question-bank.print')` — Print button
- `@can('tenant.ai-question-generator.viewAny')` — AI generator button
- `@canany(['tenant.question-bank.view', 'tenant.question-bank.edit', 'tenant.question-bank.delete'])` — Actions column

---

## 7. BC-BIZ — Business Logic

| BC-BIZ ID | Rule | Description |
|-----------|------|-------------|
| BC-BIZ-01 | 4-Step Wizard | Step 1: Basic Info → Step 2: Settings → Step 3: Options → Step 4: Tags/Topics; sidebar navigation |
| BC-BIZ-02 | Cascading Dropdowns | Class → Subject → Lesson → Topic (4-level); loaded via AJAX |
| BC-BIZ-03 | MCQ Option Validation | Min 2 options, at least 1 correct; `options` array validated with `min:2` |
| BC-BIZ-04 | Negative Marks < Marks | `negative_marks` must be < `marks`; validated in service logic (not in FormRequest) |
| BC-BIZ-05 | Platform Content Protection | `ques_owner = 'PrimeGurukul'` blocks edit/delete; cloning allowed |
| BC-BIZ-06 | Student Attempt Lock | Usage check via `QuestionUsageCheckService::isUsedInLms()` blocks edit/force-delete |
| BC-BIZ-07 | Version Snapshot | Content edits trigger snapshot before save (service logic in QuestionCRUDService) |
| BC-BIZ-08 | Availability Scope Filtering | 6 levels: GLOBAL, SCHOOL_ONLY, CLASS_ONLY, SECTION_ONLY, ENTITY_ONLY, STUDENT_ONLY |
| BC-BIZ-09 | Status FSM | DRAFT ↔ IN_REVIEW ↔ APPROVED/REJECTED → PUBLISHED → ARCHIVED (6 states) |
| BC-BIZ-10 | Force Delete Cascade | Deletes question + options + junctions + versions + usage logs + review logs in transaction |
| BC-BIZ-11 | Usage Check Before Delete | `QuestionUsageCheckService::isUsedInLms()` checks quiz/quest/exam answer tables |
| BC-BIZ-12 | Import File Validation | `.xlsx` or `.csv` only; error report on failure |
| BC-BIZ-13 | Print Format | 5 questions per page with options in 2-column grid (A,B,C,D) |
| BC-BIZ-14 | UUID Generation | Binary(16) UUID generated via `UUID_TO_BIN(UUID())` |
| BC-BIZ-15 | Clone Inherits from Source | Pre-fills curriculum, taxonomy, usage flags, ownership, availability; status defaults to IN_REVIEW |
| BC-BIZ-16 | AJAX Lookup Gate Gap | 13 AJAX endpoints have no Gate::authorize() — rely on page-level auth |
| BC-BIZ-17 | Soft Delete Sets Archived | `destroy()` via service; blocks if usage exists |
| BC-BIZ-18 | Toggle Status Logs Activity | `activityLog()` called on each toggleStatus |
| BC-BIZ-19 | Duplicate QuestionBankPolicy | Two `Gate::policy()` registrations exist for QuestionBank model (dead policy) — P0 gap |
| BC-BIZ-20 | Permission Seeder Missing | QNS permissions not seeded — all non-super-admin users get 403 — P0 gap |

---

## 8. BC-REF — Referential Integrity

| Foreign Key | Column | References Table | On Delete |
|-------------|--------|-----------------|-----------|
| fk_ques_class | class_id | sch_classes.id | SET NULL |
| fk_ques_subject | subject_id | sch_subjects.id | SET NULL |
| fk_ques_lesson | lesson_id | slb_lessons.id | SET NULL |
| fk_ques_topic | topic_id | slb_topics.id | SET NULL |
| fk_ques_competency | competency_id | slb_competencies.id | SET NULL |
| fk_ques_bloom | bloom_id | slb_bloom_taxonomy.id | SET NULL |
| fk_ques_cog | cognitive_skill_id | slb_cognitive_skill.id | SET NULL |
| fk_ques_timeSpec | ques_type_specificity_id | slb_ques_type_specificity.id | SET NULL |
| fk_ques_complexity | complexity_level_id | slb_complexity_level.id | SET NULL |
| fk_ques_type | question_type_id | slb_question_types.id | RESTRICT |
| fk_ques_created_by | created_by | sys_users.id | SET NULL |
| fk_ques_selected_entity_group | selected_entity_group_id | slb_entity_groups.id | SET NULL |
| fk_ques_selected_section | selected_section_id | sch_sections.id | SET NULL |
| fk_ques_selected_student | selected_student_id | std_students.id | SET NULL |
| fk_ques_book | book_id | slb_books.id | SET NULL |
| fk_opt_question | qns_question_options.question_bank_id | qns_questions_bank.id | CASCADE |
| fk_qtag_q | qns_question_questiontag_jnt.question_bank_id | qns_questions_bank.id | CASCADE |
| fk_qtag_tag | qns_question_questiontag_jnt.tag_id | qns_question_tags.id | CASCADE |
| fk_qt_question | qns_question_topic_jnt.question_bank_id | qns_questions_bank.id | CASCADE |
| fk_qt_topic | qns_question_topic_jnt.topic_id | slb_topics.id | CASCADE |
| fk_qrec_question | qns_question_performance_category_jnt.question_bank_id | qns_questions_bank.id | CASCADE |
| fk_qrec_perf | qns_question_performance_category_jnt.performance_category_id | slb_performance_categories.id | CASCADE |
| fk_qmedia_question | qns_question_media_jnt.question_bank_id | qns_questions_bank.id | CASCADE |
| fk_qmedia_option | qns_question_media_jnt.question_option_id | qns_question_options.id | CASCADE |
| fk_qmedia_media | qns_question_media_jnt.media_id | qns_media_store.id | CASCADE |
| fk_qqans_question | qns_questions_attempts.question_id | qns_questions_bank.id | RESTRICT | StudentAttempt — cannot force-delete question with quiz/quest answers |
| fk_exans_question | qns_exam_answers.question_id | qns_questions_bank.id | RESTRICT | StudentAttempt — cannot force-delete question with exam answers |
| fk_qq_question | lms_quiz_questions.question_id | qns_questions_bank.id | CASCADE | Quiz — force-deleting question cascades from quiz |
| fk_qst_q_question | lms_quiz_quest_attempts.question_id | qns_questions_bank.id | CASCADE | Quest — force-deleting question cascades from quest |

---

## 9. Test Case Summary

### 9.1 Question CRUD — Positive TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-QBN-P01 | Question CRUD | Positive | Question list loads with filter data and pagination | 5 |
| TC-QBN-P02 | Question CRUD | Positive | Create question — full 4-step wizard with all fields | 8 |
| TC-QBN-P03 | Question CRUD | Positive | Create question with MCQ options (2 options, 1 correct) | 6 |
| TC-QBN-P04 | Question CRUD | Positive | Create question with all four taxonomy fields | 5 |
| TC-QBN-P05 | Question CRUD | Positive | Create question with media attachments | 6 |
| TC-QBN-P06 | Question CRUD | Positive | Create question with tags | 5 |
| TC-QBN-P07 | Question CRUD | Positive | Create question with multi-topic mapping | 5 |
| TC-QBN-P08 | Question CRUD | Positive | Create question with performance categories | 5 |
| TC-QBN-P09 | Question CRUD | Positive | Create question — ENTITY_ONLY availability with entity group | 5 |
| TC-QBN-P10 | Question CRUD | Positive | Create question — SECTION_ONLY availability with section | 5 |
| TC-QBN-P11 | Question CRUD | Positive | Create question — STUDENT_ONLY availability with student | 5 |
| TC-QBN-P12 | Question CRUD | Positive | Edit question — update title, marks, content | 6 |
| TC-QBN-P13 | Question CRUD | Positive | View question detail — all 5 tabs load correctly | 6 |
| TC-QBN-P14 | Question CRUD | Positive | Clone question — creates variant with inherited fields | 7 |
| TC-QBN-P15 | Question CRUD | Positive | Print question paper — filtered output with print format | 4 |
| TC-QBN-P16 | Question CRUD | Positive | Import questions — valid .xlsx file | 5 |
| TC-QBN-P17 | Question CRUD | Positive | Toggle status — active/inactive | 4 |
| TC-QBN-P18 | Question CRUD | Positive | Soft-delete question — no usage | 5 |
| TC-QBN-P19 | Question CRUD | Positive | Restore question from trash | 4 |
| TC-QBN-P20 | Question CRUD | Positive | AJAX — getSubjectsByClass returns subjects | 3 |
| TC-QBN-P21 | Question CRUD | Positive | AJAX — getLessonsBySubject returns lessons | 3 |
| TC-QBN-P22 | Question CRUD | Positive | AJAX — getTopicsByLesson returns topics | 3 |
| TC-QBN-P23 | Question CRUD | Positive | AJAX — getTopicHierarchy returns topic tree | 3 |
| TC-QBN-P24 | Question CRUD | Positive | AJAX — getTopicAncestors returns ancestor chain | 3 |
| TC-QBN-P25 | Question CRUD | Positive | AJAX — getCognitiveSkillsByBloom returns skills | 3 |
| TC-QBN-P26 | Question CRUD | Positive | AJAX — getSpecificityByCognitiveSkill returns specificities | 3 |
| TC-QBN-P27 | Question CRUD | Positive | AJAX — getCompetenciesBySubject returns competencies | 3 |
| TC-QBN-P28 | Question CRUD | Positive | AJAX — getSectionsByClass returns sections | 3 |
| TC-QBN-P29 | Question CRUD | Positive | AJAX — getStudentsBySection returns students | 3 |
| TC-QBN-P30 | Question CRUD | Positive | AJAX — getBookDetails returns book metadata | 3 |
| TC-QBN-P31 | Question CRUD | Positive | AJAX — getMediaDetails returns media info | 4 |
| TC-QBN-P32 | Question CRUD | Positive | AJAX — getMediaByFilters returns filtered media | 3 |
| TC-QBN-P33 | Question CRUD | Positive | AJAX — getTopicDetails returns topic info | 3 |

### 9.2 Question CRUD — Negative TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-QBN-N01 | Question CRUD | Negative | Create — missing required title | 2 |
| TC-QBN-N02 | Question CRUD | Negative | Create — missing class_id | 2 |
| TC-QBN-N03 | Question CRUD | Negative | Create — marks exceeds max 999.99 | 2 |
| TC-QBN-N04 | Question CRUD | Negative | Create — negative_marks >= marks | 2 |
| TC-QBN-N05 | Question CRUD | Negative | Create — only 1 option for MCQ | 2 |
| TC-QBN-N06 | Question CRUD | Negative | Create — no option marked correct | 2 |
| TC-QBN-N07 | Question CRUD | Negative | Create — invalid content_format | 2 |
| TC-QBN-N08 | Question CRUD | Negative | Create — invalid status value | 2 |
| TC-QBN-N09 | Question CRUD | Negative | Create — availability ENTITY_ONLY without entity group | 2 |
| TC-QBN-N10 | Question CRUD | Negative | Create — availability SECTION_ONLY without section | 2 |
| TC-QBN-N11 | Question CRUD | Negative | Create — availability STUDENT_ONLY without student | 2 |
| TC-QBN-N12 | Question CRUD | Negative | Create — invalid question_type_id (non-existent) | 2 |
| TC-QBN-N13 | Question CRUD | Negative | Create — invalid class_id (non-existent) | 2 |
| TC-QBN-N14 | Question CRUD | Negative | Edit — question with student attempts (usage check blocks) | 3 |
| TC-QBN-N15 | Question CRUD | Negative | Delete — question used in LMS | 3 |
| TC-QBN-N16 | Question CRUD | Negative | Force delete — question with attempts | 3 |
| TC-QBN-N17 | Question CRUD | Negative | Permission — index without tenant.question-bank.viewAny | 2 |
| TC-QBN-N18 | Question CRUD | Negative | Permission — create without tenant.question-bank.create | 2 |
| TC-QBN-N19 | Question CRUD | Negative | Permission — edit without tenant.question-bank.update | 2 |
| TC-QBN-N20 | Question CRUD | Negative | Permission — delete without tenant.question-bank.delete | 2 |
| TC-QBN-N21 | Question CRUD | Negative | Permission — print without tenant.question-bank.print | 2 |
| TC-QBN-N22 | Question CRUD | Negative | Import — invalid file type (.pdf) | 2 |
| TC-QBN-N23 | Question CRUD | Negative | Import — no file uploaded | 2 |
| TC-QBN-N24 | Question CRUD | Negative | Import — no validated file in session | 2 |
| TC-QBN-N25 | Question CRUD | Negative | AJAX — getSubjectsByClass invalid class_id | 2 |
| TC-QBN-N26 | Question CRUD | Negative | AJAX — getMediaDetails missing media_id | 2 |
| TC-QBN-N27 | Question CRUD | Negative | AJAX — getTopicDetails non-existent topic | 2 |

### 9.3 Code Review TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-CR01 | Code Review | Review | index() — Gate check + tab routing | 4 |
| TC-CR02 | Code Review | Review | store() — Delegates to CRUD service + try-catch | 4 |
| TC-CR03 | Code Review | Review | edit() — Usage check via service | 3 |
| TC-CR04 | Code Review | Review | destroy() — Usage check before delete | 4 |
| TC-CR05 | Code Review | Review | forceDelete() — Usage check + cascade | 4 |
| TC-CR06 | Code Review | Review | storeClone() — Validation + try-catch | 5 |
| TC-CR07 | Code Review | Review | validateFile() — Gate + validation + session storage | 4 |
| TC-CR08 | Code Review | Review | toggleStatus() — Activity log call | 3 |
| TC-CR09 | Code Review | Review | QuestionCRUDService::store() — Full data sync flow | 6 |
| TC-CR10 | Code Review | Review | QuestionBankRequest — All field rules | 5 |
| TC-CR11 | Code Review | Review | Filter data from QuestionLookupService::getFilterData() | 3 |
| TC-CR12 | Code Review | Review | Blade @can directives in question-bank/index.blade.php | 5 |
| TC-CR13 | Code Review | Review | Breadcrumb config in tab_module/index.blade.php | 2 |
| TC-CR14 | Code Review | Review | View isset()/null-safe checks in index.blade.php | 4 |
| TC-CR15 | Code Review | Review | Flash messages on store/update/destroy/restore/forceDelete | 6 |

### 9.4 Dependency TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-D01 | Dependency | Dependency | Usage check — QuestionUsageCheckService reads from LmsQuiz/LmsQuests/LmsExam tables | 4 |
| TC-D02 | Dependency | Dependency | Import flow — validateFile + startImport sequential process | 3 |
| TC-D03 | Dependency | Dependency | Version snapshot created on content edit | 3 |
| TC-D04 | Dependency | Dependency | Force delete cascades to options, junctions, versions, usage logs, review logs | 4 |
| TC-D05 | Dependency | Dependency | Parent taxonomy deletion SET NULL — class/subject/lesson/topic/competency/bloom/cog/spec/complexity/created_by/entity/section/student/book FK set to NULL | 3 |
| TC-D06 | Dependency | Dependency | RESTRICT — question_type deletion blocked by FK when questions reference it | 3 |
| TC-D07 | Dependency | Dependency | Reverse cascade — tag/topic/performance_category/option/media deletion cascades to junction records | 4 |
| TC-D08 | Dependency | Dependency | Cross-module RESTRICT — Quiz/Exam attempt records block question force delete | 3 |
| TC-D09 | Dependency | Dependency | Cross-module CASCADE — Quiz/Quest question assignment cascades on question force delete | 3 |

---

## 10. Test Case Steps

### 10.1 Positive TC Steps — Question CRUD

#### TC-QBN-P01: Question list loads with filter data and pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.question-bank.viewAny` permission navigates to Question Bank | Page loads |
| 2 | Verify filter dropdowns: Class, Section, Subject, Lesson, Topic, Type, Bloom, Complexity, Cognitive, Specificity, Status, Availability, Marks range | All filters present |
| 3 | Verify table columns: #, Question, Class/Subject, Topic, Type, Marks, Status, Active toggle, Action | All columns present |
| 4 | Verify pagination (10 per page) | Paginated |
| 5 | Verify Import, Print, AI Generator buttons visible based on permissions | Conditional visibility |

#### TC-QBN-P02: Create question — full 4-step wizard with all fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.question-bank.create` permission clicks "Add Question" | Create form loads |
| 2 | Step 1: Enter ques_title, select class, subject, lesson, topic, competency, question_type, content_format, status, marks, negative_marks, expected_time, enter question_content | Step 1 complete |
| 3 | Step 2: Select ques_owner=School, enable for_quiz, for_quest, set availability=GLOBAL | Step 2 complete |
| 4 | Step 3: Add 2 options with text, mark first as correct | Step 3 complete |
| 5 | Step 4: Add a tag | Step 4 complete |
| 6 | Click Save | Redirected to list |
| 7 | Verify new question appears in the list with correct title, marks, status | Question created |
| 8 | Verify DB record: `qns_questions_bank` has the new row with all fields | DB verified |

#### TC-QBN-P03: Create question with MCQ options (2 options, 1 correct)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form, Step 3 | Options section visible |
| 2 | Add 2 options: Opt A = "Paris" (is_correct=true, ordinal=1), Opt B = "London" (is_correct=false, ordinal=2) | Options added |
| 3 | Fill mandatory fields and save | Success |
| 4 | Verify DB: `qns_question_options` has 2 rows linked to this question, one with is_correct=1 | Options saved |

#### TC-QBN-P04: Create question with all four taxonomy fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create question with bloom_id, cognitive_skill_id, ques_type_specificity_id, complexity_level_id all populated | All set |
| 2 | Save and verify | Question saved |
| 3 | DB check: All four fields have non-null values | Taxonomy saved |

#### TC-QBN-P05: Create question with media attachments

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create question, set media_required_for_question = Yes | Media fields enabled |
| 2 | Attach media via Media Attachment modal | Media selected |
| 3 | Save question | Success |
| 4 | Verify `qns_question_media_jnt` has record linking question to media | Media linked |

#### TC-QBN-P06: Create question with tags

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create question, Step 4, add tag from existing tags | Tag selected |
| 2 | Save question | Success |
| 3 | Verify `qns_question_questiontag_jnt` has record | Tag linked |

#### TC-QBN-P07: Create question with multi-topic mapping

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create question, Step 4, add additional topic | Topic selected |
| 2 | Save question | Success |
| 3 | Verify `qns_question_topic_jnt` has record for additional topic | Topic linked |

#### TC-QBN-P08: Create question with performance categories

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create question, Step 4, add performance category with recommendation type and priority | Performance data entered |
| 2 | Save question | Success |
| 3 | Verify `qns_question_performance_category_jnt` has record linking question to category | Performance linked |

#### TC-QBN-P09: Create question — ENTITY_ONLY availability with entity group

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create question, set availability = ENTITY_ONLY | Entity group field appears |
| 2 | Select an entity group | Entity group selected |
| 3 | Fill all required fields and save | Success |
| 4 | Verify DB: availability = ENTITY_ONLY, selected_entity_group_id populated | Entity saved |

#### TC-QBN-P10: Create question — SECTION_ONLY availability with section

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create question, set availability = SECTION_ONLY | Section field appears |
| 2 | Select a section | Section selected |
| 3 | Fill all required fields and save | Success |
| 4 | Verify DB: availability = SECTION_ONLY, selected_section_id populated | Section saved |

#### TC-QBN-P11: Create question — STUDENT_ONLY availability with student

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create question, set availability = STUDENT_ONLY | Student field appears |
| 2 | Select a student | Student selected |
| 3 | Fill all required fields and save | Success |
| 4 | Verify DB: availability = STUDENT_ONLY, selected_student_id populated | Student saved |

#### TC-QBN-P12: Edit question — update title, marks, content

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open edit for question with no student attempts | Edit form loads with pre-filled data |
| 2 | Change ques_title, marks, question_content | Fields updated |
| 3 | Save | Redirected to list |
| 4 | Verify question list shows updated title and marks | Updated |
| 5 | Verify DB: changes reflected | DB verified |
| 6 | Verify `qns_question_versions` has a snapshot before the edit | Version created |

#### TC-QBN-P13: View question detail — all 5 tabs load correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open view for a question with complete data | Show page loads |
| 2 | Verify Tab 1: Basic Info displays title, class, subject, lesson, topic, competency | Basic info tab ok |
| 3 | Verify Tab 2: Settings displays taxonomy, marks, time, availability, usage flags | Settings tab ok |
| 4 | Verify Tab 3: Options displays all question options with correct answer marked | Options tab ok |
| 5 | Verify Tab 4: Tags/Topics displays associated tags and topics | Tags/Topics tab ok |
| 6 | Verify Tab 5: Performance displays performance categories if assigned | Performance tab ok |

#### TC-QBN-P14: Clone question — creates variant with inherited fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open clone for a PrimeGurukul-owned question | Clone form loads with pre-filled fields |
| 2 | Verify ques_owner is School (clone becomes school-owned) | Ownership changed |
| 3 | Modify title (append " (Variant)"), modify content | Changes made |
| 4 | Click Save Clone | Redirected |
| 5 | Verify new question in list with modified title | Clone created |
| 6 | Verify all options copied from source | Options copied |
| 7 | Verify status = IN_REVIEW | Status correct |

#### TC-QBN-P15: Print question paper — filtered output with print format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.question-bank.print` permission clicks Print button | Print modal/options shown |
| 2 | Select filters (class, subject) for questions to print | Filters applied |
| 3 | Click Print | Print view opens |
| 4 | Verify output: 5 questions per page, options in 2-column grid (A,B,C,D) | Print format correct |

#### TC-QBN-P16: Import questions — valid .xlsx file

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Import button | Modal opens |
| 2 | Upload valid .xlsx file | File selected |
| 3 | Click Validate | Validation passes |
| 4 | Click Import | Import completes |
| 5 | Verify success JSON response with created/skipped/errors counts | Import done |

#### TC-QBN-P17: Toggle status — active/inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open question list, locate an active question | Active question visible |
| 2 | Click status toggle to deactivate | Toggle switches to inactive |
| 3 | Verify DB: is_active = 0 for the question | Deactivated |
| 4 | Click status toggle again to reactivate | Toggle switches to active, DB: is_active = 1 |

#### TC-QBN-P18: Soft-delete question — no usage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open delete for question with no usage | No usage block |
| 2 | Confirm delete | Question soft-deleted |
| 3 | Verify question in Trash view (`onlyTrashed()`) | In trash |
| 4 | Verify DB: `deleted_at` is not null | Soft-deleted |
| 5 | Verify question does not appear in active list | Hidden |

#### TC-QBN-P19: Restore question from trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.question-bank.restore` permission navigates to Trash view | Trash list loads |
| 2 | Locate a soft-deleted question | Question in trash |
| 3 | Click Restore | Question restored |
| 4 | Verify question appears in active list and deleted_at is NULL | Restored |

#### TC-QBN-P20: AJAX — getSubjectsByClass returns subjects

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call GET `/question-bank/get-subjects-by-class?class_id={valid_id}` | AJAX call |
| 2 | Verify JSON response with list of subjects for the given class | Subjects returned |
| 3 | Verify response contains id, name for each subject | Correct structure |

#### TC-QBN-P21: AJAX — getLessonsBySubject returns lessons

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call GET `/question-bank/get-lessons-by-subject?subject_id={valid_id}` | AJAX call |
| 2 | Verify JSON response with list of lessons for the given subject | Lessons returned |
| 3 | Verify response contains id, name for each lesson | Correct structure |

#### TC-QBN-P22: AJAX — getTopicsByLesson returns topics

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call GET `/question-bank/get-topics-by-lesson?lesson_id={valid_id}` | AJAX call |
| 2 | Verify JSON response with list of topics for the given lesson | Topics returned |
| 3 | Verify response contains id, name, level for each topic | Correct structure |

#### TC-QBN-P23: AJAX — getTopicHierarchy returns topic tree

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call GET `/question-bank/get-topic-hierarchy?topic_id={valid_id}` | AJAX call |
| 2 | Verify JSON response with topic tree (parent-child hierarchy) | Hierarchy returned |
| 3 | Verify response contains nested children structure | Nested structure |

#### TC-QBN-P24: AJAX — getTopicAncestors returns ancestor chain

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call GET `/question-bank/get-topic-ancestors?topic_id={valid_id}` | AJAX call |
| 2 | Verify JSON response with ancestor chain from root to topic | Ancestors returned |
| 3 | Verify response contains ordered list of ancestor topics | Ordered chain |

#### TC-QBN-P25: AJAX — getCognitiveSkillsByBloom returns skills

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call GET `/question-bank/get-cognitive-skills-by-bloom?bloom_id={valid_id}` | AJAX call |
| 2 | Verify JSON response with cognitive skills for the given bloom level | Skills returned |
| 3 | Verify response contains id, name for each skill | Correct structure |

#### TC-QBN-P26: AJAX — getSpecificityByCognitiveSkill returns specificities

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call GET `/question-bank/get-specificity-by-cognitive-skill?cognitive_skill_id={valid_id}` | AJAX call |
| 2 | Verify JSON response with specificities for the given cognitive skill | Specificities returned |
| 3 | Verify response contains id, name for each specificity | Correct structure |

#### TC-QBN-P27: AJAX — getCompetenciesBySubject returns competencies

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call GET `/question-bank/get-competencies-by-subject?subject_id={valid_id}` | AJAX call |
| 2 | Verify JSON response with competencies for the given subject | Competencies returned |
| 3 | Verify response contains id, name for each competency | Correct structure |

#### TC-QBN-P28: AJAX — getSectionsByClass returns sections

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call GET `/question-bank/get-sections-by-class?class_id={valid_id}` | AJAX call |
| 2 | Verify JSON response with sections for the given class | Sections returned |
| 3 | Verify response contains id, name for each section | Correct structure |

#### TC-QBN-P29: AJAX — getStudentsBySection returns students

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call GET `/question-bank/get-students-by-section?section_id={valid_id}` | AJAX call |
| 2 | Verify JSON response with students for the given section | Students returned |
| 3 | Verify response contains id, name for each student | Correct structure |

#### TC-QBN-P30: AJAX — getBookDetails returns book metadata

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call GET `/question-bank/get-book-details?book_id={valid_id}` | AJAX call |
| 2 | Verify JSON response with book metadata (title, author, publisher, etc.) | Book details returned |
| 3 | Verify response contains all expected book fields | Complete metadata |

#### TC-QBN-P31: AJAX — getMediaDetails returns media info

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call GET `/question-bank/get-media-details?media_id={valid_id}` | AJAX call |
| 2 | Verify Gate::authorize('tenant.question-bank.view') is called | Gate enforced |
| 3 | Verify JSON response with media metadata (filename, type, URL, dimensions) | Media details returned |
| 4 | Verify response contains all media fields | Complete info |

#### TC-QBN-P32: AJAX — getMediaByFilters returns filtered media

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call GET `/question-bank/get-media-by-filters?type=image&class_id={valid_id}` | AJAX call |
| 2 | Verify JSON response with filtered media list | Filtered media returned |
| 3 | Verify response respects filter parameters | Filters applied |

#### TC-QBN-P33: AJAX — getTopicDetails returns topic info

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call GET `/question-bank/get-topic-details?topic_id={valid_id}` | AJAX call |
| 2 | Verify JSON response with topic details (name, level, parent, path) | Topic details returned |
| 3 | Verify response contains full topic metadata | Complete info |

### 10.2 Negative TC Steps — Question CRUD

#### TC-QBN-N01: Create — missing required title

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form without ques_title | Validation error |
| 2 | Verify error: "The ques title field is required." | Error shown |

#### TC-QBN-N02: Create — missing class_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form without class_id | Validation error |
| 2 | Verify error: "The class id field is required." | Error shown |

#### TC-QBN-N03: Create — marks exceeds max 999.99

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set marks = 1000.00 | Exceeds max |
| 2 | Submit | Error: "marks must not exceed 999.99" |

#### TC-QBN-N04: Create — negative_marks >= marks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set marks = 5.00, negative_marks = 5.00 | Invalid values |
| 2 | Submit | Error (validated at service level) |

#### TC-QBN-N05: Create — only 1 option for MCQ

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add only 1 option in Step 3 | 1 option |
| 2 | Submit | Error: "options must contain at least 2 items." |

#### TC-QBN-N06: Create — no option marked correct

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add 2 options, neither marked is_correct | No correct option |
| 2 | Submit | Error (validated at service level) |

#### TC-QBN-N07: Create — invalid content_format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set content_format = "XML" (invalid value) | Invalid format |
| 2 | Submit | Error: "The selected content format is invalid." |

#### TC-QBN-N08: Create — invalid status value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set status = "PUBLISHING" (invalid value) | Invalid status |
| 2 | Submit | Error: "The selected status is invalid." |

#### TC-QBN-N09: Create — availability ENTITY_ONLY without entity group

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set availability = ENTITY_ONLY, leave selected_entity_group_id empty | Missing entity group |
| 2 | Submit | Error: "The selected entity group id field is required when availability is ENTITY_ONLY." |

#### TC-QBN-N10: Create — availability SECTION_ONLY without section

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set availability = SECTION_ONLY, leave selected_section_id empty | Missing section |
| 2 | Submit | Error: "The selected section id field is required when availability is SECTION_ONLY." |

#### TC-QBN-N11: Create — availability STUDENT_ONLY without student

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set availability = STUDENT_ONLY, leave selected_student_id empty | Missing student |
| 2 | Submit | Error: "The selected student id field is required when availability is STUDENT_ONLY." |

#### TC-QBN-N12: Create — invalid question_type_id (non-existent)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set question_type_id = 99999 (non-existent ID) | Invalid reference |
| 2 | Submit | Validation error: question_type_id does not exist |

#### TC-QBN-N13: Create — invalid class_id (non-existent)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set class_id = 99999 (non-existent ID) | Invalid reference |
| 2 | Submit | Validation error: class_id does not exist |

#### TC-QBN-N14: Edit — question with student attempts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt to edit question that has student attempts | Usage check triggers |
| 2 | Verify error: `[usage message] Therefore cannot be permanently edited.` (dynamic from QuestionUsageCheckService) | Error shown |

#### TC-QBN-N15: Delete — question used in LMS

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt to delete question used in quiz/quest/exam | Usage check triggers |
| 2 | Verify error: "[usage message] Therefore cannot be deleted." | Error shown |

#### TC-QBN-N16: Force delete — question with attempts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt to force delete question that has student attempts | Usage check triggers |
| 2 | Verify error: `[usage message] Therefore cannot be permanently deleted.` (dynamic from QuestionUsageCheckService) | Error shown |
| 3 | Verify DB record NOT deleted (force delete blocked) | Question preserved |

#### TC-QBN-N17: Permission — index without viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.question-bank.viewAny` accesses index | 403 Forbidden |

#### TC-QBN-N18: Permission — create without tenant.question-bank.create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.question-bank.create` accesses create page or POST store | 403 Forbidden |

#### TC-QBN-N19: Permission — edit without tenant.question-bank.update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.question-bank.update` accesses edit page or PUT update | 403 Forbidden |

#### TC-QBN-N20: Permission — delete without tenant.question-bank.delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.question-bank.delete` attempts DELETE destroy | 403 Forbidden |

#### TC-QBN-N21: Permission — print without tenant.question-bank.print

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.question-bank.print` accesses print page | 403 Forbidden |

#### TC-QBN-N22: Import — invalid file type (.pdf)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Upload .pdf file for import | Invalid type |
| 2 | Verify error: "The file must be a file of type: xlsx, csv." | Error shown |

#### TC-QBN-N23: Import — no file uploaded

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Validate without selecting a file | No file |
| 2 | Verify error: "The file field is required." | Error shown |

#### TC-QBN-N24: Import — no validated file in session

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call startImport without prior validateFile (no session data) | No validated data |
| 2 | Verify error: "No validated file found. Please validate first." | Error shown |

#### TC-QBN-N25: AJAX — getSubjectsByClass invalid class_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call GET `/question-bank/get-subjects-by-class?class_id=99999` | Non-existent class |
| 2 | Verify empty array or 404 response | Empty result |

#### TC-QBN-N26: AJAX — getMediaDetails missing media_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call GET `/question-bank/get-media-details` without media_id parameter | Missing param |
| 2 | Verify error response or empty result | Error/empty |

#### TC-QBN-N27: AJAX — getTopicDetails non-existent topic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call GET `/question-bank/get-topic-details?topic_id=99999` | Non-existent topic |
| 2 | Verify empty result or 404 | Empty response |

### 10.3 Code Review TC Steps

#### TC-CR01: index() — Gate check + tab routing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review Gate::authorize('tenant.question-bank.viewAny') at method start | Gate present |
| 2 | Review tab parameter handling: `$tab = $request->get('tab', 'question_bank')` | Default tab |
| 3 | Review lookup service calls for each tab type | 8 query methods called |
| 4 | Review compact() includes all variables for view | All passed |

#### TC-CR02: store() — Delegates to CRUD service + try-catch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `store()` calls `Gate::authorize('tenant.question-bank.create')` | Gate present |
| 2 | Review `QuestionCRUDService::store($request->validated())` call | Delegates to service |
| 3 | Review try-catch block wrapping service call | Exception handling |
| 4 | Review success response: `redirect()->route(...)->with('success', ...)` | Flash success |

#### TC-CR03: edit() — Usage check via service

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.question-bank.update')` | Gate present |
| 2 | Review `QuestionUsageCheckService::isUsedInLms($id)` call before returning edit view | Usage check present |
| 3 | Review error path returns `back()->with('error', ...)` if usage exists | Error on usage |

#### TC-CR04: destroy() — Usage check before delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review Gate::authorize('tenant.question-bank.delete') | Gate present |
| 2 | Review `QuestionUsageCheckService::isUsedInLms($id)` check | Usage check present |
| 3 | Review error path: `back()->with('error', ...)` | Error returned on usage |
| 4 | Review success path: `crudService->destroy($id)` + flash message | Success flow |

#### TC-CR05: forceDelete() — Usage check + cascade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.question-bank.forceDelete')` | Gate present |
| 2 | Review `QuestionUsageCheckService::isUsedInLms($id)` check | Usage check present |
| 3 | Review `QuestionCRUDService::forceDelete($id)` call | Force delete delegated |
| 4 | Review cascade logic: options, junctions, versions, logs all deleted in transaction | Cascade confirmed |

#### TC-CR06: storeClone() — Validation + try-catch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review inline validation rules (title, class, subject, lesson, topic, etc.) | Validation present |
| 2 | Review `QuestionCloneService::clone()` delegation (controller calls `$this->cloneService->clone()`) | Clone created via service layer |
| 3 | Review `syncOptions()` copies options from source | Options copied |
| 4 | Review try-catch wrapping the creation logic | Exception handling |
| 5 | Review success response with flash message | Flash success |

#### TC-CR07: validateFile() — Gate + validation + session storage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.question-bank.create')` | Gate present |
| 2 | Review file validation: `mimes:xlsx,csv` | File type validated |
| 3 | Review `QuestionImportService::validateFile()` parsing and error collection | Rows validated |
| 4 | Review validated data stored in session for `startImport()` to consume | Session stored |

#### TC-CR08: toggleStatus() — Activity log call

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.question-bank.update')` | Gate present |
| 2 | Review `activityLog()` call after status toggle | Activity logged |
| 3 | Review response: JSON with new status and success message | JSON response |

#### TC-CR09: QuestionCRUDService::store() — Full data sync flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `buildQuestionData()` transformation | Data prepared |
| 2 | Review `QuestionBank::create()` call | Question created |
| 3 | Review `syncOptions()` — option creation with media | Options synced |
| 4 | Review `syncTags()` — tag junction creation | Tags synced |
| 5 | Review `syncTopicWeightage()` — topic junction creation | Topics synced |
| 6 | Review `syncPerformanceCategories()` — performance junction | Performance synced |

#### TC-CR10: QuestionBankRequest — All field rules

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `rules()` method for field count and types | 40+ rules defined |
| 2 | Review `authorize()` returns `Auth::check()` (KI-05) | Auth check (not real Gate) |
| 3 | Review `messages()` method for custom error messages | Custom messages |
| 4 | Review conditional rules: `required_if` for availability-based fields | Conditional logic |
| 5 | Review options array validation: `min:2`, nested field rules | Nested validation |

#### TC-CR11: Filter data from QuestionLookupService::getFilterData()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review method returns classes, sections, subjects, lessons, topics | Curriculum data present |
| 2 | Review method returns question types, bloom, complexity, cognitive, specificity | Taxonomy data present |
| 3 | Review method returns statuses, availabilities, tags | Configuration data present |

#### TC-CR12: Blade @can directives in question-bank/index.blade.php

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `@can('tenant.question-bank.status')` wrapping status toggle column | Status toggle gated |
| 2 | Review `@can('tenant.question-bank.view')` for view action button | View action gated |
| 3 | Review `@can('tenant.question-bank.update')` / `@can('tenant.question-bank.edit')` for edit button | Edit action gated |
| 4 | Review `@can('tenant.question-bank.delete')` for delete button | Delete action gated |
| 5 | Review `@canany` for actions dropdown visibility | Actions column gated |

#### TC-CR13: Breadcrumb config in tab_module/index.blade.php

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review breadcrumb array defined in view data | Breadcrumb config present |
| 2 | Verify breadcrumb links to Question Bank index, create, edit, view pages | All routes mapped |

#### TC-CR14: View isset()/null-safe checks in index.blade.php

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `isset()` checks on filter data before rendering dropdowns | Filter null safety |
| 2 | Review `optional()` or null-safe operator on pagination data | Pagination null safety |
| 3 | Review `isset()` on question relations (options, tags) in table rows | Relation null safety |
| 4 | Review `isset()` on permission-based action buttons | Permission null safety |

#### TC-CR15: Flash messages on store/update/destroy/restore/forceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `store()` success: `->with('success', 'Question created successfully')` | Create flash |
| 2 | Review `update()` success: `->with('success', 'Question updated successfully')` | Update flash |
| 3 | Review `destroy()` success: `->with('success', 'Question moved to trash')` | Delete flash |
| 4 | Review `restore()` success: `->with('success', 'Question restored successfully')` | Restore flash |
| 5 | Review `forceDelete()` success: `->with('success', 'Question permanently deleted')` | Force delete flash |
| 6 | Review error flash on failure: `->with('error', ...)` | Error flash |

### 10.4 Dependency TC Steps

#### TC-D01: Usage check reads from LmsQuiz/LmsQuests/LmsExam tables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Question Q1 has answers in quiz_attempt_answers | Usage exists |
| 2 | Call `isUsedInLms(Q1)` | Returns true |
| 3 | Question Q2 has no answers anywhere | No usage |
| 4 | Call `isUsedInLms(Q2)` | Returns false |

#### TC-D02: Import flow — validateFile + startImport sequential process

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `validateFile()` — validates file format, parses rows, stores validated data in session | Validated data stored |
| 2 | Review `startImport()` — reads session data, calls `QuestionImport::executeImport()` for each row | Import executed |
| 3 | Verify two-step process: validation must complete before import can start | Sequential flow enforced |

#### TC-D03: Version snapshot created on content edit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `QuestionCRUDService::update()` — checks if `question_content` changed | Content diff detected |
| 2 | Review snapshot creation — existing data copied to `qns_question_versions` before update | Version record created |
| 3 | Verify `current_version` incremented after edit | Version incremented |

#### TC-D04: Force delete cascades to related data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Question Q1 has 3 options, 2 tags, 1 topic, 1 version, 1 usage log entry | Related data exists |
| 2 | Force delete Q1 | Deleted |
| 3 | Verify options deleted: `qns_question_options` where question_bank_id=Q1 are gone | Options cascade |
| 4 | Verify junctions deleted: tags, topics, media junctions all gone | Junctions cascade |

#### TC-D05: Parent taxonomy deletion SET NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Question Q1 references class=C1, subject=S1, lesson=L1, topic=T1, competency=CP1, bloom=B1, cog=CG1, spec=SP1, complexity=CX1, created_by=U1, entity=EG1, section=SC1, student=ST1, book=BK1 | All FK columns populated |
| 2 | Force delete each referenced parent record (C1, S1, L1, T1, CP1, B1, CG1, SP1, CX1, U1, EG1, SC1, ST1, BK1) individually | Parent deleted |
| 3 | Verify Q1 still exists and each FK column = NULL | All SET NULL |

#### TC-D06: RESTRICT — question_type deletion blocked by FK

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Question Q1 references question_type_id = QT1 | FK populated |
| 2 | Attempt to delete QT1 from `slb_question_types` | Operation rejected (integrity constraint violation) |
| 3 | Verify QT1 still exists in `slb_question_types` | Parent preserved |

#### TC-D07: Reverse cascade — tag/topic/perf_cat/option/media deletion cascades to junction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Question Q1 has junction records: tag T1 via `qns_question_questiontag_jnt`, topic TP1 via `qns_question_topic_jnt`, perf_cat PC1 via `qns_question_performance_category_jnt`, option O1 via `qns_question_media_jnt`, media M1 via `qns_question_media_jnt` | Junction records exist |
| 2 | Force delete each parent (T1, TP1, PC1, O1, M1) individually | Parent deleted |
| 3 | Verify corresponding junction records cascade-deleted | Junctions gone |
| 4 | Verify Q1 itself still exists | Question preserved |

#### TC-D08: Cross-module RESTRICT — Quiz/Exam attempt records block question force delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Question Q1 has student attempt records in `qns_questions_attempts` (quiz/quest) and `qns_exam_answers` (exam) | Attempt records exist |
| 2 | Attempt to force delete Q1 via `forceDelete()` | Operation blocked (integrity constraint violation from FK RESTRICT) |
| 3 | Verify Q1 still exists in `qns_questions_bank` with deleted_at = NULL | Question preserved |

#### TC-D09: Cross-module CASCADE — Quiz/Quest question assignment cascades on question force delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Question Q1 is assigned to Quiz Z1 via `lms_quiz_questions` and Quest QST1 via `lms_quiz_quest_attempts` | Assignment records exist |
| 2 | Force delete Q1 from `qns_questions_bank` | Q1 permanently removed |
| 3 | DB check: `lms_quiz_questions` where question_id = Q1 | 0 records (FK CASCADE) |
| 4 | DB check: `lms_quiz_quest_attempts` where question_id = Q1 | 0 records (FK CASCADE) |

---

## 11. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|--------|-----|------|-------------------|---------------------|
| GET | `/question-bank/question-bank` | question-bank.question-bank.index | index() | tenant.question-bank.viewAny |
| GET | `/question-bank/question-bank/create` | question-bank.question-bank.create | create() | tenant.question-bank.create |
| POST | `/question-bank/question-bank` | question-bank.question-bank.store | store() | tenant.question-bank.create |
| GET | `/question-bank/question-bank/{question_bank}` | question-bank.question-bank.show | show() | tenant.question-bank.view |
| GET | `/question-bank/question-bank/{question_bank}/edit` | question-bank.question-bank.edit | edit() | tenant.question-bank.update |
| PUT | `/question-bank/question-bank/{question_bank}` | question-bank.question-bank.update | update() | tenant.question-bank.update |
| DELETE | `/question-bank/question-bank/{question_bank}` | question-bank.question-bank.destroy | destroy() | tenant.question-bank.delete |
| GET | `/question-bank/{id}/clone` | question-bank.clone | clone() | tenant.question-bank.create |
| POST | `/question-bank/clones` | question-bank.cloneStore | storeClone() | tenant.question-bank.create |
| GET | `/question-bank/trash/view` | question-bank.trashed | trashed() | tenant.question-bank.restore |
| GET | `/question-bank/{id}/restore` | question-bank.restore | restore() | tenant.question-bank.restore |
| DELETE | `/question-bank/{id}/force-delete` | question-bank.forceDelete | forceDelete() | tenant.question-bank.forceDelete |
| POST | `/question-bank/{question_bank}/toggle-status` | question-bank.toggleStatus | toggleStatus() | tenant.question-bank.update |
| GET | `/question-bank/print` | question-bank.print | print() | tenant.question-bank.print |
| POST | `/question-bank/validate-file` | question-bank.validate-file | validateFile() | tenant.question-bank.create |
| POST | `/question-bank/start-import` | question-bank.start-import | startImport() | tenant.question-bank.create |
| GET | `/question-bank/get-subjects-by-class` | getSubjectsByClass | getSubjectsByClass() | None |
| GET | `/question-bank/get-lessons-by-subject` | getLessonsBySubject | getLessonsBySubject() | None |
| GET | `/question-bank/get-topics-by-lesson` | getTopicsByLesson | getTopicsByLesson() | None |
| GET | `/question-bank/get-topic-hierarchy` | get-topic-hierarchy | getTopicHierarchy() | None |
| GET | `/question-bank/get-topic-ancestors` | get-topic-ancestors | getTopicAncestors() | None |
| GET | `/question-bank/get-cognitive-skills-by-bloom` | getCognitiveSkillsByBloom | getCognitiveSkillsByBloom() | None |
| GET | `/question-bank/get-specificity-by-cognitive-skill` | getSpecificityByCognitiveSkill | getSpecificityByCognitiveSkill() | None |
| GET | `/question-bank/get-competencies-by-subject` | getCompetenciesBySubject | getCompetenciesBySubject() | None |
| GET | `/question-bank/get-sections-by-class` | getSectionsByClass | getSectionsByClass() | None |
| GET | `/question-bank/get-students-by-section` | getStudentsBySection | getStudentsBySection() | None |
| GET | `/question-bank/get-media-details` | getMediaDetails | getMediaDetails() | tenant.question-bank.view |
| GET | `/question-bank/get-book-details` | getBookDetails | getBookDetails() | None |
| GET | `/question-bank/get-media-by-filters` | question-bank.getMediaByFilters | getMediaByFilters() | None |
| GET | `/question-bank/get-topic-details` | question-bank.get-topic-details | getTopicDetails() | None |
| POST | `/question-bank/{question_bank}/toggle-status-log` | question-usage-log.toggleStatus | toggleStatusLog() | tenant.question-bank.update |

---

## 12. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-01 | Duplicate Gate::policy() registration for QuestionBank model | **P0** | Two `Gate::policy()` calls exist in ServiceProvider; QuestionBankPolicy dead |
| KI-02 | Permission seeder missing for QNS module | **P0** | No TenantPermissionSeeder → non-admin users get 403 on all screens |
| KI-03 | 13 AJAX endpoints lack Gate::authorize() | **Medium** | Ungated endpoints rely on page-level auth; defence-in-depth missing |
| KI-04 | QuestionTagController uses wrong permission namespace | **Medium** | Uses `tenant.question_bank.*` (underscore) instead of `tenant.question-tag.*` (hyphen) |
| KI-05 | FormRequest authorize() returns `Auth::check()` not real Gate | **Medium** | Defence-in-depth collapsed; all 6 FormRequests affected |
| KI-06 | scopeApproved() references wrong column | **P0** | References `ques_reviewed_status` which doesn't exist; actual column is `status` |
| KI-07 | `getFilterData()` availabilityOptions keys do NOT match DB ENUM | **P0** | `QuestionLookupService::getFilterData()` returns `GLOBAL/SCHOOL/CLASS/SECTION/INDIVIDUAL` but DB ENUM is `GLOBAL/SCHOOL_ONLY/CLASS_ONLY/SECTION_ONLY/ENTITY_ONLY/STUDENT_ONLY`. The query builder passes raw filter value as WHERE clause on `availability` column — selecting any non-GLOBAL filter yields zero results because no DB row matches the short keys. |

---

## 13. Feature Summary Matrix

| Feature | REQ ID | Controller Method(s) | Key Models | Pagination |
|---------|--------|---------------------|------------|------------|
| Question List | REQ-QNS-001 | index() | QuestionBank, QuestionOption | 10 per page |
| Create Question | REQ-QNS-001, 002, 003, 008, 009 | create(), store() | QuestionBank, QuestionOption, QuestionQuestionTagJnt, QuestionTopicJnt, QuestionPerformanceCategoryJnt | None (form) |
| Edit Question | REQ-QNS-001 | edit(), update() | QuestionBank + all relations | None (form) |
| View Question | REQ-QNS-001 | show() | QuestionBank + all relations | None |
| Clone Question | REQ-QNS-001 | clone(), storeClone() | QuestionBank + options | None (form) |
| Delete/Restore | REQ-QNS-001 | destroy(), trashed(), restore(), forceDelete() | QuestionBank | 10 per page (trash) |
| Print | REQ-QNS-013 | print() | QuestionBank | 5 per page |
| Import | REQ-QNS-012 | validateFile(), startImport() | QuestionImportService | None (batch) |
| AJAX Lookups | REQ-QNS-001 | getSubjectsByClass, getLessonsBySubject, etc. | Subject, Lesson, Topic, etc. | None |
