# AI Question Generator

This is a separate page where teachers can use artificial intelligence to create questions automatically. Instead of typing each question from scratch, the teacher describes what they need, and the AI generates the content, options, and explanations.

---

## How It Works

**Step 1 — The teacher fills out a form.** They specify the class, subject, lesson, and topic for the questions. They pick the question type (MCQ works best), difficulty level, how many questions they want (1 to 10), and the Bloom's taxonomy level. They can choose English, Hindi, or both languages. There is also an optional field for extra instructions — things like "Focus on chemical equations" or "Make them application-based."

**Step 2 — The AI generates the questions.** The teacher clicks "Generate," and the system sends their requirements to the AI service — either ChatGPT or Gemini, depending on what is configured. Within a few seconds, the AI returns the questions. Each question includes the question text, four answer options (for MCQ), the correct answer marked, and an explanation.

**Step 3 — The teacher reviews the results.** The generated questions appear in a preview panel. For each question, the teacher can edit the text or options directly, ask the AI to try again (regenerate), or discard the question entirely. They can accept the ones they like and reject the ones they do not.

**Step 4 — The teacher saves the accepted questions.** When they click "Save Selected," each accepted question is created in the Question Bank as a Draft. The teacher must still go through the normal process of reviewing and publishing before students see them.

---

## Important Business Rules

- The teacher is responsible for the AI output. The AI can make mistakes — wrong answers, factual errors, inappropriate difficulty levels. The system records that a question was AI-generated (an audit flag), but the teacher who saved it is listed as the creator and is responsible for its content. The explanation the AI generates becomes the teacher explanation shown to students.
- AI-generated questions always start as Draft. They cannot skip the review process. This is intentional — AI content must be verified by a human before it reaches students.
- The maximum is 10 questions per generation request. If the teacher needs more, they can make multiple requests. Each request is logged for tracking purposes — how many questions, which AI provider was used, how many tokens were consumed.
- If the AI service is unavailable — for example, the API is down or the school has not configured an AI provider — the teacher sees an error message. If no provider is configured at all, the system can run in "demo mode," returning pre-written sample questions so the teacher can still see how the interface works.
- The teacher can switch between ChatGPT and Gemini if both are configured. Each may give slightly different results, so the teacher can try both and compare.
- AI-generated questions are tagged with a system flag indicating they were AI-generated. This flag is visible in the question's metadata but does not affect how the question behaves.
- Each generation request is logged with the teacher's identity, the AI provider used, the number of questions requested, and the number actually returned. This log is accessible to administrators for usage tracking.
- The teacher can edit AI-generated questions in the preview panel before saving them. The edits are applied before the question is created in the Question Bank.
- The AI provider configuration is set at the school level. Teachers cannot choose a provider that is not configured by the school administrator.

---

## Deep Analysis

### Business Workflows & State Machines

| State | Trigger | Next State | Notes |
|---|---|---|---|
| Form Entry | Teacher fills class, subject, topic, difficulty, count | Ready to Generate | All required fields must be filled |
| Ready to Generate | Teacher clicks "Generate" | Awaiting API Response | Request sent to ChatGPT or Gemini |
| Awaiting API Response | API returns successfully | Preview Panel | Questions displayed for review |
| Awaiting API Response | API fails / timeout | Error State | Error message shown; teacher can retry |
| Preview Panel | Teacher accepts a question | Ready to Save | Teacher can edit before accepting |
| Preview Panel | Teacher rejects a question | Discarded | Question is removed from the batch |
| Preview Panel | Teacher clicks "Regenerate" | Awaiting API Response | Same parameters, new API call |
| Ready to Save | Teacher clicks "Save Selected" | Draft (DB record) | Each accepted question becomes a Draft in `qns_questions_bank` |
| No provider configured | System detects missing config | Demo Mode | Pre-written sample questions returned instead |

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|---|---|---|
| Question count | Must be between 1 and 10 | "Number of questions must be between 1 and 10." |
| AI provider | Must be configured at school level | "No AI provider is configured. Please contact your school administrator." |
| API failure | Timeout or HTTP error response | "The AI service is currently unavailable. Please try again later." |
| Demo mode | No provider configured | "Running in demo mode with sample questions." |
| Question type | Only supported types can be AI-generated | "AI generation is currently only available for MCQ question types." |
| Language selection | Must be 'English', 'Hindi', or 'Both' | "Invalid language selection provided." |
| Bloom's taxonomy level | Must be a valid level ID | "Please select a valid Bloom's taxonomy level." |
| Save without accepting | No questions accepted | "Please accept at least one question before saving." |
| Edit before save | Teacher modifies preview text | Edits are applied client-side before Save operation |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|---|---|---|---|
| School Settings | `school_settings` | school_id | AI provider configuration per school |
| Taxonomy | `slb_bloom_taxonomy` | bloom_id | Bloom's level selection in generation form |
| Taxonomy | `slb_complexity_level` | complexity_level_id | Difficulty selection |
| Taxonomy | `slb_question_types` | question_type_id | Question type selection |
| Question Bank | `qns_questions_bank` | created_by = NULL, created_by_AI = 1 | Question marked as AI-generated |
| Question Bank | `qns_question_options` | question_bank_id | AI-generated options saved here |
| Question Bank | `qns_question_questiontag_jnt` | question_bank_id / tag_id | Tags attached to AI-generated questions |
| Audit Log | `qns_question_usage_log` | question_bank_id | Each generation request logged for audit |
| External API | N/A | N/A | HTTP calls to ChatGPT/Gemini API |

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| View AI generator page | Teacher | `ai-question-generator.view` |
| Generate questions | Teacher | `ai-question-generator.generate` |
| Edit AI-generated preview | Teacher | `ai-question-generator.edit-preview` |
| Save accepted questions | Teacher | `ai-question-generator.save` |
| Regenerate questions | Teacher | `ai-question-generator.regenerate` |
| Configure AI providers | Admin | `ai-question-generator.configure` |
| View generation audit logs | Admin | `ai-question-generator.view-logs` |

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
| created_by | INT UNSIGNED | sch_users.id | Yes | NULL | Creator user FK (NULL when AI-generated) |
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

### qns_question_tags

| Column | Type | FK | Nullable | Default | Behavior |
|---|---|---|---|---|---|
| id | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| short_name | VARCHAR(100) | No | No | – | Unique short code for internal lookups |
| name | VARCHAR(255) | No | No | – | Display name visible to users |
| is_active | TINYINT(1) | No | No | 1 | Active flag for soft delete |
| created_at | TIMESTAMP | No | No | CURRENT_TIMESTAMP | Record creation timestamp |
| updated_at | TIMESTAMP | No | No | CURRENT_TIMESTAMP ON UPDATE | Last update timestamp |
| deleted_at | TIMESTAMP | No | Yes | NULL | Soft delete timestamp |

### qns_question_questiontag_jnt

| Column | Type | FK | Nullable | Default | Behavior |
|---|---|---|---|---|---|
| id | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| question_bank_id | INT UNSIGNED | qns_questions_bank.id | No | – | Question FK (CASCADE delete) |
| tag_id | INT UNSIGNED | qns_question_tags.id | No | – | Tag FK (CASCADE delete) |
| is_active | TINYINT(1) | No | No | 1 | Active flag for soft delete |
| created_at | TIMESTAMP | No | No | CURRENT_TIMESTAMP | Record creation timestamp |
| updated_at | TIMESTAMP | No | No | CURRENT_TIMESTAMP ON UPDATE | Last update timestamp |
| deleted_at | TIMESTAMP | No | Yes | NULL | Soft delete timestamp |
