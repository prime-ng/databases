# Tab 7: Question Usage Log

This tab shows every place a question has been used — which quizzes, quests, or exams reference it. This log exists for one main reason: to determine whether a question can be edited or deleted. It is a permanent, unchangeable record of where each question appears.

---

## How It Works

When a teacher adds a question to a quiz, the system automatically creates a usage log entry. It records which question was added, which assessment it was added to (the quiz, quest, or exam), and when. These entries cannot be edited or deleted by anyone. They are permanent.

The log becomes the deciding factor for editing. When a teacher tries to edit a question, the system checks the usage log. If there are no entries at all — the question has never been used anywhere — editing is fully allowed. If there are entries but none of those assessments have any student attempts yet — the question was added to quizzes but nobody has answered it — editing is allowed with a warning. The teacher sees "This question is used in X assessments. Editing may affect these assessments."

But if there are entries AND students have attempted the question in any of those assessments, editing is completely blocked. The system says "This question cannot be edited because it has been answered by students in existing assessments. Clone this question to create a variant."

The same logic applies to deletion. A question can be deleted only if it has never been used. If it has usage log entries but no attempts, soft deletion is allowed with a warning. If any attempts exist, deletion is blocked entirely — both soft and hard.

There is one special feature: each usage log entry has an active/inactive toggle. A teacher can deactivate a log entry, which means the system will no longer consider it when checking edit protection. However, if the deactivated entry has associated student attempts, a warning is shown: "This usage log is associated with student attempt data. Deactivating it may affect data integrity." The teacher can proceed, but this is not recommended in normal practice.

---

## Important Business Rules

- Usage log entries are permanent and cannot be edited or deleted by anyone, including administrators.
- When a question is added to an assessment, a usage log entry is created automatically. No manual entry is needed.
- The usage log determines edit and delete permissions. A question cannot be edited or deleted if the usage log shows any assessment where students have answered it.
- The active/inactive toggle on a usage log entry allows a teacher to override the edit protection. This is intended for exceptional cases and is not recommended for regular use.
- If a usage log entry is deactivated, the system treats the question as if it was never used in that assessment for the purpose of edit checks.
- Deactivating a usage log entry with student attempts triggers a warning. The teacher must acknowledge the warning before proceeding.
- The usage log does not track how many times a question was answered or the scores. It only tracks which assessments the question was added to. Student attempt data is stored separately.
- When an assessment (quiz, quest, or exam) is deleted, the corresponding usage log entries remain. The assessment name is replaced with "(Deleted Assessment)."
- The usage log is visible to all teachers for questions they have access to. Admins can see all usage logs across the school.

---

## Deep Analysis

### Business Workflows & State Machines

| State | Trigger | Next State | Notes |
|---|---|---|---|
| No usage | Question created | Fully Editable / Deletable | No restrictions |
| Question Added to Assessment | Teacher adds question to quiz/quest/exam | Usage Log Entry Created | Automatic; entry is permanent |
| Has Usage (No Attempts) | Teacher attempts edit | Warning + Allowed | "This question is used in [n] assessments. Editing may affect these assessments." |
| Has Usage (No Attempts) | Teacher attempts delete | Warning + Soft Delete Allowed | Same warning logic |
| Has Attempts | Teacher attempts edit | Blocked | "Clone this question to create a variant." |
| Has Attempts | Teacher attempts delete | Blocked | Deletion blocked entirely |
| Has Attempts | Teacher toggles entry to inactive | Warning + Deactivated | "This usage log is associated with student attempt data. Deactivating it may affect data integrity." |
| Inactive Entry | Teacher attempts edit | Allowed (bypass) | System ignores deactivated entries for edit checks |
| Assessment Deleted | System removes assessment | Usage Entry Remains | Assessment name replaced with "(Deleted Assessment)" |

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|---|---|---|
| Edit usage log entry | Not allowed (any role) | "Usage log entries are permanent and cannot be edited." |
| Delete usage log entry | Not allowed (any role) | "Usage log entries are permanent and cannot be deleted." |
| Edit question with attempts | Blocked | "This question cannot be edited because it has been answered by students in existing assessments. Clone this question to create a variant." |
| Delete question with attempts | Blocked | "This question cannot be deleted because it has been answered by students." |
| Deactivate entry with attempts | Warning required | "This usage log is associated with student attempt data. Deactivating it may affect data integrity." |
| Assessment deleted | Log entry persists | Assessment name shown as "(Deleted Assessment)" |
| No usage log entries | Question is fully editable | No warning or block |
| Usage with no attempts | Warning but allowed | "This question is used in [n] assessments. Editing may affect these assessments." |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|---|---|---|---|
| Question Bank | qns_question_usage_log | question_bank_id | Tracks all assessment usage per question |
| Question Bank | qns_questions_bank | id | Source question for edit/delete protection checks |
| Question Bank | qns_question_usage_type | question_usage_type | Identifies whether usage is Quiz/Quest/Exam |
| Quiz Module | quz_* tables | context_id | Assessment context when quiz adds a question |
| Exam Module | exm_* tables | context_id | Assessment context when exam adds a question |
| Quest Module | qst_* tables | context_id | Assessment context when quest adds a question |
| Student Attempts | Various response tables | – | Separate storage; usage log only tracks assessment membership |

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| View usage log | Teacher | question-usage-log.viewAny |
| Toggle active/inactive | Teacher | question-usage-log.toggle-active |
| View all usage logs (cross-school) | Admin | question-usage-log.view-all |
| Edit/delete usage log entries | Not available (any role) | – |

---

## Database Columns & Behavior

### qns_question_usage_log

| Column | Type | FK | Nullable | Default | Behavior |
|---|---|---|---|---|---|
| id | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| question_bank_id | INT UNSIGNED | qns_questions_bank.id | No | – | Question FK (CASCADE delete) |
| question_usage_type | ENUM('QUIZ','QUEST','ONLINE_EXAM','OFFLINE_EXAM') | No | No | – | Assessment type that used this question |
| context_id | INT UNSIGNED | sys_dropdowns.id | No | – | ID of the specific quiz/quest/exam instance |
| used_at | TIMESTAMP | No | No | CURRENT_TIMESTAMP | When the question was added to the assessment |
| is_active | TINYINT(1) | No | No | 1 | Active/inactive toggle for edit protection override |
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
