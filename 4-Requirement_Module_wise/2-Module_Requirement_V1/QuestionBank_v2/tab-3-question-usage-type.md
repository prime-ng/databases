# Tab 3: Question Usage Type

This tab lets teachers define the different kinds of assessments where questions can be used. The standard types are Quiz, Quest, Exam, and Offline Exam. Teachers can also create custom types if needed.

---

## How It Works

When a teacher opens this tab, they see a list of all usage types. Each type has a name — like "Quiz" or "Exam" — and a short code like "QUIZ" or "EXAM." The code is what the system uses internally to recognize each type.

To create a new type, the teacher gives it a name and a code. Both must be unique — no two types can share the same name or code. If the teacher tries to create a type called "Quiz" when one already exists, the system says "A usage type with this name already exists." Same for the code.

The real power of usage types shows up when teachers create questions. During question creation, the teacher checks which usage types are allowed for that question. For example, a teacher might say a question can be used in Quiz and Exam but not in Quest. Later, when another teacher is building a quiz and searches for questions to add, they will only see questions that have the "Quiz" usage type checked. Questions that don't allow "Quiz" usage simply do not appear in the search results.

This filtering happens across all modules. The Quiz module only shows questions that allow "Quiz" usage. The Exam module only shows questions that allow "Exam" usage. And so on. This gives teachers fine control over where their questions appear.

Deleting a usage type is heavily restricted. If even one question has this type checked, the system blocks deletion entirely. The teacher sees "Cannot delete. This usage type is currently selected by X questions." They must first edit each question to remove this usage type before they can delete it. This rule exists because deleting a type that questions depend on would break the filtering logic — questions would suddenly become invisible in certain modules without anyone understanding why.

There is no force delete override for this restriction. Even admins cannot delete a usage type that is in use.

---

## Important Business Rules

- When a question is created, all four usage types are unchecked by default. The teacher must explicitly check which ones they want. If they do not check any, the question defaults to allowing all types — it will appear everywhere. This is the safest default because it means a question the teacher forgot to configure will still be findable.
- If a teacher changes a question's usage types after it has already been added to quizzes, those existing quizzes are not affected. The question stays in those quizzes. But new quizzes will follow the new usage type settings.
- A usage type can be made inactive, which hides it from the dropdown when creating questions. But existing quizzes that used this type are not affected.
- Even admin users cannot force-delete a usage type that is in use. The restriction is absolute.
- The standard types (Quiz, Quest, Exam, Offline Exam) cannot be deleted. They are system-defined. Only custom types created by teachers can be deleted.
- A question's usage type selection is stored at the question level, not at the assessment level. When the question is added to a quiz, the usage type check has already been done at search time.

---

## Deep Analysis

### Business Workflows & State Machines

| State | Trigger | Next State | Notes |
|---|---|---|---|
| Idle | Teacher opens Usage Types tab | Type List | Shows all active usage types |
| Type List | Teacher clicks "Add New" | Create Form | Name + code fields |
| Create Form | Teacher submits | Validating | Name and code uniqueness check |
| Validating | Name + code are unique | Type Created | Record added to `qns_question_usage_type` |
| Validating | Name or code already exists | Validation Error | "A usage type with this name/code already exists." |
| Active | Teacher toggles "Inactive" | Inactive | Hidden from question creation dropdown |
| Inactive | Teacher toggles "Active" | Active | Available again for selection |
| Active / Inactive | Teacher clicks "Delete" | Delete Check | System checks if any question uses this type |
| Delete Check | 0 questions use this type | Deleted | Type removed (custom only; system types blocked) |
| Delete Check | 1+ questions use this type | Blocked | "Cannot delete. This usage type is currently selected by X questions." |

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|---|---|---|
| Name uniqueness | Must be unique across all usage types | "A usage type with this name already exists." |
| Code uniqueness | Must be unique across all usage types | "A usage type with this code already exists." |
| Delete system type | Cannot delete Quiz, Quest, Exam, Offline Exam | "System-defined usage types cannot be deleted." |
| Delete type in use | Cannot delete if any question references it | "Cannot delete. This usage type is currently selected by [n] questions." |
| Force delete | Not available even for admins | "This usage type is in use and cannot be deleted." |
| Make inactive | Allowed regardless of usage | Existing assessments using this type are unaffected |
| Edit standard type | Name/code of system types may be locked | System types may be read-only for certain fields |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|---|---|---|---|
| Question Bank | `qns_question_usage_type` | – | Defines all usage type records |
| Question Bank | `qns_questions_bank` | (for_quiz, for_quest, for_exam, for_offline_exam columns) | Individual question usage flags |
| Question Bank | `qns_question_usage_log` | question_usage_type | Logs which usage type context a question was used in |
| Quiz Module | `quz_*` tables | – | Consumes usage type filter when searching questions |
| Exam Module | `exm_*` tables | – | Consumes usage type filter when searching questions |
| Quest Module | `qst_*` tables | – | Consumes usage type filter when searching questions |

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| View usage types | Teacher | `question-usage-type.viewAny` |
| Create custom usage type | Teacher | `question-usage-type.create` |
| Edit usage type | Teacher | `question-usage-type.update` |
| Toggle active/inactive | Teacher | `question-usage-type.toggle-active` |
| Delete custom usage type | Teacher | `question-usage-type.delete` |
| View system usage types | Teacher | `question-usage-type.view-system` |

---

## Database Columns & Behavior

### qns_question_usage_type

| Column | Type | FK | Nullable | Default | Behavior |
|---|---|---|---|---|---|
| id | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| code | VARCHAR(50) | No | No | – | Unique code (e.g. 'QUIZ', 'QUEST') |
| name | VARCHAR(100) | No | No | – | Unique display name (e.g. 'Quiz', 'Quest') |
| description | TEXT | No | Yes | NULL | Optional description of the usage type |
| is_active | TINYINT(1) | No | No | 1 | Toggle to show/hide in dropdowns |
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
