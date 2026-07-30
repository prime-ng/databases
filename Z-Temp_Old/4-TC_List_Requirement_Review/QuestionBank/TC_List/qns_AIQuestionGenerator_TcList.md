# qns_AIQuestionGenerator_TcList

## Module: QuestionBank → AI Question Generator

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | QuestionBank (QNS) |
| Tab Group | Question Bank (Tabbed Interface) |
| Feature | AI Question Generator — generate, preview, save, and download AI-created MCQ questions |
| URL(s) | `/question-bank/ai-question-generator` (index), `/question-bank/get-section` (AJAX), `/question-bank/get-subject-groups` (AJAX), `/question-bank/get-subjects` (AJAX), `/question-bank/get-lessons` (AJAX), `/question-bank/get-topics` (AJAX), `/question-bank/generate-questions` (AJAX), `/question-bank/save-questions` (AJAX), `/question-bank/download-csv` (AJAX), `/question-bank/get-ai-providers` (AJAX), `/question-bank/ai-provider-status/{id}` (AJAX) |
| Controller | `Modules\QuestionBank\Http\Controllers\AIQuestionGeneratorController` |
| Model(s) | `QuestionBank`, `QuestionOption`, `BloomTaxonomy`, `CognitiveSkill`, `ComplexityLevel`, `QueTypeSpecifity`, `QuestionType`, `Competencie`, `QuestionReviewLog` |
| Validation (generateQuestions) | Inline — `Validator::make()` with 7 rules |
| Validation (saveQuestions) | Inline — `Validator::make()` with 20+ rules on `questions.*` array |
| Permission Gates | `tenant.question-bank.create` on ALL 11 methods (confirmed in code) |
| Soft Deletes | Yes — QuestionBank and QuestionOption support soft deletes via migrations |
| Demo Data Stub | `getDemoResponse()` returns hardcoded questions without calling real AI API (P0 gap) |

---

## 2. Pre-conditions

- Required permission: `tenant.question-bank.create` (gates all 11 methods)
- At least one active School Class must exist (`sch_classes.is_active = 1`)
- At least one active Subject must exist (`sch_subjects.is_active = 1`)
- At least one active Subject Group must exist (`sch_subject_groups.is_active = 1`)
- At least one active Lesson must exist (`slb_lessons.is_active = 1`)
- At least one active Topic must exist (`slb_topics.is_active = 1`)
- Master taxonomy data: Bloom Taxonomy, Complexity Levels, Cognitive Skills, Question Type Specificities, Question Types must be populated
- For save: `qns_questions_bank` and `qns_question_options` tables must exist
- AI Provider keys configured in `config/services.php` (currently read from `env()` — known gap)

---

## 3. Default Data Load

When index page loads (GET `/question-bank/ai-question-generator`):

| Data | Source | Query | Pagination |
|------|--------|-------|------------|
| AI Providers | `$this->aiProviders` (hardcoded array) | Active=true filtered | None |
| Classes | `SchoolClass::active()` | `where('is_active', 1)` | None |
| Bloom Taxonomies | `BloomTaxonomy::active()` | Active bloom levels | None |
| Question Types | `QuestionType::active()` | Active types | None |
| Complexity Levels | `ComplexityLevel::active()` | Active levels | None |
| Cognitive Skills | `CognitiveSkill::active()` | Active skills | None |
| Type Specificities | `QueTypeSpecifity::active()` | Active specificities | None |
| Topic Levels | `TopicLevelType::where('is_active', 1)` | Ordered by `level` | None |

---

## 4. Database Schema (BC-DB)

### BC-DB-01: `qns_questions_bank` - Primary Question Table

| BC-DB ID | Column | Type | Nullable | Default | Constraints | Notes |
|----------|--------|------|----------|---------|-------------|-------|
| BC-DB-01 | id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | PK | |
| BC-DB-02 | uuid | BINARY(16) | NOT NULL | | UNIQUE (`idx_ques_uuid`) | |
| BC-DB-03 | class_id | INT UNSIGNED | YES | NULL | FK → sch_classes.id (SET NULL) | |
| BC-DB-04 | subject_id | BIGINT UNSIGNED | YES | NULL | FK → sch_subjects.id (SET NULL) | |
| BC-DB-05 | lesson_id | INT UNSIGNED | YES | NULL | FK → slb_lessons.id (SET NULL) | |
| BC-DB-06 | topic_id | INT UNSIGNED | YES | NULL | FK → slb_topics.id (SET NULL) | |
| BC-DB-07 | competency_id | INT UNSIGNED | YES | NULL | FK → slb_competencies.id (SET NULL) | |
| BC-DB-08 | ques_title | VARCHAR(255) | NOT NULL | | | Strip-tagged question content |
| BC-DB-09 | ques_title_display | TINYINT(1) | NOT NULL | 0 | | |
| BC-DB-10 | question_content | TEXT | NOT NULL | | | Full question body |
| BC-DB-11 | content_format | ENUM('TEXT','HTML','MARKDOWN','LATEX','JSON') | NOT NULL | 'TEXT' | | Defaults to 'TEXT' for AI gen |
| BC-DB-12 | bloom_id | INT UNSIGNED | YES | NULL | FK → slb_bloom_taxonomy.id (SET NULL) | |
| BC-DB-13 | cognitive_skill_id | INT UNSIGNED | YES | NULL | FK → slb_cognitive_skill.id (SET NULL) | |
| BC-DB-14 | ques_type_specificity_id | INT UNSIGNED | YES | NULL | FK → slb_ques_type_specificity.id (SET NULL) | |
| BC-DB-15 | complexity_level_id | INT UNSIGNED | YES | NULL | FK → slb_complexity_level.id (SET NULL) | |
| BC-DB-16 | question_type_id | INT UNSIGNED | NOT NULL | | FK → slb_question_types.id | MCQ_SINGLE default |
| BC-DB-17 | marks | DECIMAL(5,2) | YES | 1.00 | | |
| BC-DB-18 | negative_marks | DECIMAL(5,2) | YES | 0.00 | | |
| BC-DB-19 | current_version | TINYINT UNSIGNED | NOT NULL | 1 | | |
| BC-DB-20 | for_quiz | TINYINT(1) | NOT NULL | 1 | | Default true for AI gen |
| BC-DB-21 | for_quest | TINYINT(1) | NOT NULL | 0 | | Default true for AI gen |
| BC-DB-22 | for_exam | TINYINT(1) | NOT NULL | 0 | | Default true for AI gen |
| BC-DB-23 | for_offline_exam | TINYINT(1) | NOT NULL | 0 | | |
| BC-DB-24 | created_by_AI | TINYINT(1) | NOT NULL | 0 | | Set to 1 for AI questions |
| BC-DB-25 | status | ENUM('DRAFT','IN_REVIEW','APPROVED','REJECTED','PUBLISHED','ARCHIVED') | NOT NULL | 'DRAFT' | | Default DRAFT for AI gen |
| BC-DB-26 | is_active | TINYINT(1) | NOT NULL | 1 | | |
| BC-DB-27 | ques_owner | ENUM('PrimeGurukul','School') | NOT NULL | 'PrimeGurukul' | | Defaults to 'School' in save |
| BC-DB-28 | availability | ENUM('GLOBAL','SCHOOL_ONLY','CLASS_ONLY','SECTION_ONLY','ENTITY_ONLY','STUDENT_ONLY') | NOT NULL | 'GLOBAL' | | |
| BC-DB-29 | created_by | INT UNSIGNED | YES | NULL | FK → sys_users.id (SET NULL) | Auto-set from auth |
| BC-DB-30 | created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | | |
| BC-DB-31 | updated_at | TIMESTAMP | YES | ON UPDATE CURRENT_TIMESTAMP | | |
| BC-DB-32 | deleted_at | TIMESTAMP | YES | NULL | | Soft delete |

### BC-DB-02: `qns_question_options` - Question Options Table

| BC-DB ID | Column | Type | Nullable | Default | Constraints | Notes |
|----------|--------|------|----------|---------|-------------|-------|
| BC-DB-33 | id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | PK | |
| BC-DB-34 | question_bank_id | INT UNSIGNED | NOT NULL | | FK → qns_questions_bank.id (CASCADE) | Parent question |
| BC-DB-35 | ordinal | SMALLINT UNSIGNED | YES | NULL | | Display order (1-4) |
| BC-DB-36 | option_text | TEXT | NOT NULL | | | Option content |
| BC-DB-37 | is_correct | TINYINT(1) | NOT NULL | 0 | | True for the correct option |
| BC-DB-38 | explanation | TEXT | YES | NULL | | Option explanation |
| BC-DB-39 | is_active | TINYINT(1) | NOT NULL | 1 | | |
| BC-DB-40 | created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | | |
| BC-DB-41 | updated_at | TIMESTAMP | YES | ON UPDATE CURRENT_TIMESTAMP | | |
| BC-DB-42 | deleted_at | TIMESTAMP | YES | NULL | | Soft delete |

---

## 5. Validation Rules (BC-VAL)

### 5.1 Inline Validation — `generateQuestions()` method

Source: `AIQuestionGeneratorController::generateQuestions()` — `Validator::make()`

| BC-VAL ID | Field | Rule(s) | Description |
|-----------|-------|---------|-------------|
| BC-VAL-GEN-01 | class_id | required, exists:sch_classes,id | Must reference existing active class |
| BC-VAL-GEN-02 | section_id | nullable, exists:sch_sections,id | Optional section filter |
| BC-VAL-GEN-03 | subject_group_id | required, exists:sch_subject_groups,id | Must reference existing subject group |
| BC-VAL-GEN-04 | subject_id | required, exists:sch_subjects,id | Must reference existing subject |
| BC-VAL-GEN-05 | lesson_id | required, exists:slb_lessons,id | Must reference existing lesson |
| BC-VAL-GEN-06 | topic_id | required, exists:slb_topics,id | Must reference existing topic |
| BC-VAL-GEN-07 | ai_provider | required, in:chatgpt,gemini | Must be one of the supported providers |

### 5.2 Inline Validation — `generateQuestions()` optional fields (no validation, resolved in code)

| BC-VAL ID | Field | Code Behavior |
|-----------|-------|---------------|
| BC-VAL-GEN-08 | number_of_question_id | Used in prompt building, defaults to 10 |
| BC-VAL-GEN-09 | bloom_taxonomy | Optional, resolved via `BloomTaxonomy::find()` |
| BC-VAL-GEN-10 | level_id | Optional, resolved via `ComplexityLevel::find()` |
| BC-VAL-GEN-11 | cognitive_level | Optional, resolved via `CognitiveSkill::find()` |
| BC-VAL-GEN-12 | que_type_specificities | Optional, resolved via `QueTypeSpecifity::find()` |
| BC-VAL-GEN-13 | question_type | Optional, resolved via `QuestionType::find()` |
| BC-VAL-GEN-14 | text_query | Optional free-text instructions for AI |
| BC-VAL-GEN-15 | topic_level | Optional topic level filter |

### 5.3 Inline Validation — `saveQuestions()` method

Source: `AIQuestionGeneratorController::saveQuestions()` — `Validator::make()`

| BC-VAL ID | Field | Rule(s) | Description |
|-----------|-------|---------|-------------|
| BC-VAL-SAVE-01 | questions | required, array, min:1 | Must provide at least 1 question |
| BC-VAL-SAVE-02 | questions.*.question | required, string, max:2000 | Question content (max 2000 chars) |
| BC-VAL-SAVE-03 | questions.*.correct_answer | required, in:A,B,C,D,a,b,c,d | Must be A/B/C/D (case-insensitive, stored uppercase) |
| BC-VAL-SAVE-04 | questions.*.option_a | required, string, max:1000 | Option A content (max 1000 chars) |
| BC-VAL-SAVE-05 | questions.*.option_b | required, string, max:1000 | Option B content (max 1000 chars) |
| BC-VAL-SAVE-06 | questions.*.option_c | required, string, max:1000 | Option C content (max 1000 chars) |
| BC-VAL-SAVE-07 | questions.*.option_d | required, string, max:1000 | Option D content (max 1000 chars) |
| BC-VAL-SAVE-08 | questions.*.explanation_a | nullable, string, max:2000 | Option A explanation |
| BC-VAL-SAVE-09 | questions.*.explanation_b | nullable, string, max:2000 | Option B explanation |
| BC-VAL-SAVE-10 | questions.*.explanation_c | nullable, string, max:2000 | Option C explanation |
| BC-VAL-SAVE-11 | questions.*.explanation_d | nullable, string, max:2000 | Option D explanation |
| BC-VAL-SAVE-12 | questions.*.class_id | required, exists:sch_classes,id | Must reference existing class |
| BC-VAL-SAVE-13 | questions.*.section_id | nullable, exists:sch_sections,id | Optional section reference |
| BC-VAL-SAVE-14 | questions.*.subject_id | required, exists:sch_subjects,id | Must reference existing subject |
| BC-VAL-SAVE-15 | questions.*.lesson_id | required, exists:slb_lessons,id | Must reference existing lesson |
| BC-VAL-SAVE-16 | questions.*.topic_id | required, exists:slb_topics,id | Must reference existing topic |
| BC-VAL-SAVE-17 | questions.*.subject_group_id | nullable, exists:sch_subject_groups,id | Optional subject group reference |
| BC-VAL-SAVE-18 | questions.*.bloom_taxonomy_id | nullable, exists:slb_bloom_taxonomy,id | Optional bloom taxonomy |
| BC-VAL-SAVE-19 | questions.*.cognitive_skill_id | nullable, exists:slb_cognitive_skill,id | Optional cognitive skill |
| BC-VAL-SAVE-20 | questions.*.ques_type_specificity_id | nullable, exists:slb_ques_type_specificity,id | Optional type specificity |
| BC-VAL-SAVE-21 | questions.*.level_id | nullable, exists:slb_complexity_level,id | Optional complexity level |
| BC-VAL-SAVE-22 | questions.*.question_type_id | nullable, exists:slb_question_types,id | Optional question type (defaults to MCQ_SINGLE) |
| BC-VAL-SAVE-23 | questions.*.status | nullable, in:DRAFT,PUBLISHED,ARCHIVED | Defaults to 'DRAFT' |
| BC-VAL-SAVE-24 | questions.*.is_active | nullable, boolean | Defaults to true |
| BC-VAL-SAVE-25 | questions.*.for_quiz | nullable, boolean | Defaults to true |
| BC-VAL-SAVE-26 | questions.*.for_quest | nullable, boolean | Defaults to true |
| BC-VAL-SAVE-27 | questions.*.for_exam | nullable, boolean | Defaults to true |
| BC-VAL-SAVE-28 | questions.*.ques_owner | nullable, string, max:100 | Defaults to 'School' |
| BC-VAL-SAVE-29 | questions.*.availability | nullable, in:GLOBAL,SCHOOL,CLASS | Defaults to 'GLOBAL' |

### 5.4 Post-Validation Business Checks (saveQuestions)

| BC-VAL ID | Check | Code Location | Error Message |
|-----------|-------|---------------|---------------|
| BC-VAL-SAVE-30 | Correct answer must be A/B/C/D after normalization | Line 813-815 | "Invalid correct answer: 'X'. Must be A, B, C, or D." |
| BC-VAL-SAVE-31 | Correct option must have content (not empty) | Line 818-821 | "Option X is marked as correct but has no content." |

### 5.5 AJAX Endpoint Validation

| BC-VAL ID | Endpoint | Validation | Behavior |
|-----------|----------|------------|----------|
| BC-VAL-AJX-01 | getLessons | subject_id: required, exists:sch_subjects,id | Returns 500 with error message on failure |
| BC-VAL-AJX-02 | getTopics | lesson_id: required, exists:slb_lessons,id | Returns 500 with error message on failure |
| BC-VAL-AJX-03 | downloadCSV | csv_data: required, string | Returns 500 with "Invalid CSV data" on failure |
| BC-VAL-AJX-04 | checkProviderStatus | {id} route parameter | Returns 404 with "Provider not found." for invalid provider |

---

## 6. Authorization (BC-AUTH)

Source: `AIQuestionGeneratorController.php` — `Gate::authorize()` calls on all 11 methods

| BC-AUTH ID | Permission | Controller Method | Behavior Without |
|------------|-----------|-------------------|------------------|
| BC-AUTH-01 | tenant.question-bank.create | index() | 403 Forbidden |
| BC-AUTH-02 | tenant.question-bank.create | getSections() | 403 Forbidden |
| BC-AUTH-03 | tenant.question-bank.create | getSubjectGroups() | 403 Forbidden |
| BC-AUTH-04 | tenant.question-bank.create | getSubjects() | 403 Forbidden |
| BC-AUTH-05 | tenant.question-bank.create | getLessons() | 403 Forbidden |
| BC-AUTH-06 | tenant.question-bank.create | getTopics() | 403 Forbidden |
| BC-AUTH-07 | tenant.question-bank.create | generateQuestions() | 403 Forbidden |
| BC-AUTH-08 | tenant.question-bank.create | saveQuestions() | 403 Forbidden |
| BC-AUTH-09 | tenant.question-bank.create | getAIProviders() | 403 Forbidden |
| BC-AUTH-10 | tenant.question-bank.create | checkProviderStatus() | 403 Forbidden |
| BC-AUTH-11 | tenant.question-bank.create | downloadCSV() | 403 Forbidden |

---

## 7. Business Logic (BC-BIZ)

### 7.1 Core Business Rules

| BC-BIZ ID | Rule Name | Description | Enforcement Location |
|-----------|-----------|-------------|---------------------|
| BC-BIZ-01 | Question Count Limit | Generation request must produce 1–20 questions; demo currently returns 4 hardcoded | Prompt building + validation layer |
| BC-BIZ-02 | AI-Generated Flag | All saved questions get `created_by_AI = 1` | QuestionBank::create() in saveQuestions |
| BC-BIZ-03 | Provider Configuration | AI provider API key read from `config('services.*.api_key')` (currently `env()` — known gap) | callChatGPT(), callGemini() |
| BC-BIZ-04 | API Timeout | AI API call has 120-second timeout | `Http::timeout(120)` in callChatGPT(), callGemini() |
| BC-BIZ-05 | Demo Data Stub | `generateQuestions()` early returns `getDemoResponse()` — never reaches real AI call | Line 232: `return $this->getDemoResponse($request);` |
| BC-BIZ-06 | MCQ Single Default | If no `question_type_id` provided, defaults to MCQ_SINGLE (looks up by code 'MCQ_SINGLE') | saveQuestions() lines 776-782 |
| BC-BIZ-07 | Auto-Competency Resolution | Competency auto-assigned by matching `class_id` and `subject_id` via `Competencie` model | saveQuestions() lines 784-787 |
| BC-BIZ-08 | Option Creation | Each saved question creates 4 options (A, B, C, D) in `qns_question_options` | saveQuestions() lines 899-937 |
| BC-BIZ-09 | Save in Transaction | All question + options creation wrapped in DB::beginTransaction / commit / rollBack | saveQuestions() transaction block |
| BC-BIZ-10 | Review Log Creation | Each saved question creates a `QuestionReviewLog` with status PENDING | saveQuestions() lines 885-897 |
| BC-BIZ-11 | Activity Log on Save | Activity log entry created for each saved question | saveQuestions() lines 879-883 |
| BC-BIZ-12 | AI Provider Hardcoded Config | Providers defined in `$this->aiProviders` array (ChatGPT + Gemini) | Class property lines 37-52 |
| BC-BIZ-13 | CSV Download Format | `downloadCSV()` returns raw csv_data as attachment with Content-Type text/csv | downloadCSV() |
| BC-BIZ-14 | Clean UTF-8 Response | All JSON responses pass through `cleanUtf8Recursive()` to handle encoding | Multiple methods |
| BC-BIZ-15 | Prompt Built with All Context | Builds CBSE-focused prompt including class, subject, lesson, topic, bloom, complexity, cognitive skill, specificity | buildAIPrompt() |
| BC-BIZ-16 | AI Response Parsing | Parses pipe-delimited CSV from AI response into structured question array | parseAIResponse() |
| BC-BIZ-17 | Fallback Sample Questions | If AI response parsing yields 0 questions, falls back to `generateSampleQuestions()` | parseAIResponse() lines 670-672 |
| BC-BIZ-18 | savePrompt() Does Not Persist | `savePrompt()` only logs to Laravel log — no DB persistence | savePrompt() lines 711-722 |
| BC-BIZ-19 | No Rate Limiting | No middleware or throttle on generation endpoint (P0 gap) | Route definition |
| BC-BIZ-20 | No AIQuestionService | All AI logic lives in controller — no dedicated service layer (known gap) | Architecture |

### 7.2 AI Provider Configuration

| BC-BIZ ID | Provider | API Endpoint | Default Model | Config Source |
|-----------|----------|-------------|---------------|---------------|
| BC-BIZ-21 | chatgpt | `https://api.openai.com/v1/chat/completions` | gpt-4o-mini | `config('services.chatgpt.api_key')` |
| BC-BIZ-22 | gemini | `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent` | gemini-2.0-flash | `config('services.gemini.api_key')` |

### 7.3 AI Prompt Parameters

| BC-BIZ ID | Parameter | Source Field | Used In Prompt |
|-----------|-----------|-------------|----------------|
| BC-BIZ-23 | Class Name | `class_id → SchoolClass::find()` | Grade/Class context |
| BC-BIZ-24 | Subject Name | `subject_id → Subject::find()` | Subject context |
| BC-BIZ-25 | Lesson Name | `lesson_id → Lesson::find()` | Chapter context |
| BC-BIZ-26 | Topic Name | `topic_id → Topic::find()` | Topic context |
| BC-BIZ-27 | Bloom Level | `bloom_taxonomy → BloomTaxonomy::find()` | Bloom's Taxonomy level |
| BC-BIZ-28 | Complexity Level | `level_id → ComplexityLevel::find()` | Difficulty level |
| BC-BIZ-29 | Cognitive Skill | `cognitive_level → CognitiveSkill::find()` | Cognitive skill assessed |
| BC-BIZ-30 | Type Specificity | `que_type_specificities → QueTypeSpecifity::find()` | Question type specificity |
| BC-BIZ-31 | Question Type | `question_type → QuestionType::find()` | Question type name |
| BC-BIZ-32 | Question Count | `number_of_question_id` (defaults to 10) | Number of questions to generate |
| BC-BIZ-33 | Additional Instructions | `text_query` (defaults to 'No additional instructions provided.') | Free-text guidance |
| BC-BIZ-34 | Topic Level | `topic_level` | Topic level filter |

### 7.4 Default Values on Save

| BC-BIZ ID | Field | Default Value | Notes |
|-----------|-------|---------------|-------|
| BC-BIZ-35 | status | 'DRAFT' | AI questions saved as draft |
| BC-BIZ-36 | is_active | true | Active by default |
| BC-BIZ-37 | for_quiz | true | Enabled for quiz |
| BC-BIZ-38 | for_quest | true | Enabled for quest |
| BC-BIZ-39 | for_exam | true | Enabled for exam |
| BC-BIZ-40 | ques_owner | 'School' | Ownership set to School |
| BC-BIZ-41 | availability | 'GLOBAL' | Global availability |
| BC-BIZ-42 | content_format | 'TEXT' | Text format |
| BC-BIZ-43 | marks | 1.00 | Default 1 mark |
| BC-BIZ-44 | negative_marks | 0.00 | No negative marking |
| BC-BIZ-45 | expected_time_to_answer_seconds | 60 | 60 seconds default |
| BC-BIZ-46 | ques_title_display | 1 | Title displayed |

### 7.5 Cascade Behavior

| BC-BIZ ID | Operation | Effect on Question | Effect on Options |
|-----------|-----------|-------------------|-------------------|
| BC-BIZ-47 | Parent question soft-delete | deleted_at set | Options remain (no cascade on soft delete) |
| BC-BIZ-48 | Parent question force-delete | Permanently removed | Options cascade-deleted (FK CASCADE) |
| BC-BIZ-49 | Save All Questions | All questions + 4 options each created in single transaction | Transaction rollback on failure |

---

## 8. Referential Integrity (BC-REF)

### 8.1 Foreign Keys on `qns_questions_bank`

| BC-REF ID | FK Name | Column | Parent Table | Parent Column | On Delete |
|-----------|---------|--------|--------------|---------------|-----------|
| BC-REF-01 | fk_ques_class | class_id | sch_classes | id | SET NULL |
| BC-REF-02 | fk_ques_subject | subject_id | sch_subjects | id | SET NULL |
| BC-REF-03 | fk_ques_lesson | lesson_id | slb_lessons | id | SET NULL |
| BC-REF-04 | fk_ques_topic | topic_id | slb_topics | id | SET NULL |
| BC-REF-05 | fk_ques_competency | competency_id | slb_competencies | id | SET NULL |
| BC-REF-06 | fk_ques_bloom | bloom_id | slb_bloom_taxonomy | id | SET NULL |
| BC-REF-07 | fk_ques_cog | cognitive_skill_id | slb_cognitive_skill | id | SET NULL |
| BC-REF-08 | fk_ques_timeSpec | ques_type_specificity_id | slb_ques_type_specificity | id | SET NULL |
| BC-REF-09 | fk_ques_complexity | complexity_level_id | slb_complexity_level | id | SET NULL |
| BC-REF-10 | fk_ques_type | question_type_id | slb_question_types | id | RESTRICT (no ON DELETE) |
| BC-REF-11 | fk_ques_created_by | created_by | sys_users | id | SET NULL |

### 8.2 Foreign Keys on `qns_question_options`

| BC-REF ID | FK Name | Column | Parent Table | Parent Column | On Delete |
|-----------|---------|--------|--------------|---------------|-----------|
| BC-REF-12 | fk_opt_question | question_bank_id | qns_questions_bank | id | CASCADE |

### 8.3 Unique Constraints

| BC-REF ID | Constraint Name | Table | Columns | Purpose |
|-----------|----------------|-------|---------|---------|
| BC-REF-13 | idx_ques_uuid | qns_questions_bank | uuid | UUID uniqueness |

### 8.4 Indexes

| BC-REF ID | Index Name | Table | Columns |
|-----------|------------|-------|---------|
| BC-REF-14 | idx_ques_topic | qns_questions_bank | topic_id |
| BC-REF-15 | idx_ques_competency | qns_questions_bank | competency_id |
| BC-REF-16 | idx_ques_class_subject | qns_questions_bank | class_id, subject_id |
| BC-REF-17 | idx_ques_complexity_bloom | qns_questions_bank | complexity_level_id, bloom_id |
| BC-REF-18 | idx_ques_active | qns_questions_bank | is_active |
| BC-REF-19 | idx_opt_question | qns_question_options | question_bank_id |

---

## 9. Test Case Summary

### 9.1 TC Count by Category

| Category | Code | Count | Coverage Area |
|----------|------|-------|---------------|
| Positive | TC-P01 to TC-P25 | 25 | UI page load, AJAX cascading dropdowns, generate (demo), save, CSV download, provider status |
| Negative | TC-N01 to TC-N25 | 25 | Validation failures, permission denials, missing data, invalid references, provider errors |
| Dependency | TC-D01 to TC-D08 | 8 | DB persistence, transaction integrity, referential cascade, prompt building, encoding |
| Code Review | TC-CR01 to TC-CR22 | 22 | Controller logic, validation rules, AI parsing, demo stub, gaps (no rate limit, no service, env keys, stub, no prompt persistence) |
| **Total** | | **80** | |

### 9.2 TC Distribution by Feature Area

| Feature Area | P | N | D | CR | Total |
|-------------|---|---|---|---|-------|
| UI Page Load (index) | 2 | 2 | 0 | 1 | 5 |
| AJAX Cascading (getSections, getSubjectGroups, getSubjects, getLessons, getTopics) | 5 | 5 | 0 | 3 | 13 |
| Generate Questions (generateQuestions) | 2 | 4 | 1 | 4 | 11 |
| Save Questions (saveQuestions) | 5 | 6 | 3 | 5 | 19 |
| AI Providers (getAIProviders, checkProviderStatus) | 3 | 2 | 0 | 2 | 7 |
| CSV Download (downloadCSV) | 2 | 1 | 1 | 1 | 5 |
| Permission/Authorization | 0 | 4 | 0 | 0 | 4 |
| Known Issues/Gaps | 0 | 0 | 2 | 4 | 6 |
| DB/Integrity | 0 | 0 | 2 | 0 | 2 |
| Code Review | 0 | 0 | 0 | 4 | 4 |
| AI Prompt & Parsing | 3 | 0 | 0 | 3 | 6 |
| **Total** | **22** | **24** | **9** | **27** | **82** |

### 9.3 Summary Table

#### Positive Test Cases

| TC ID | Test Case Name | Feature | Steps |
|-------|---------------|---------|-------|
| TC-P01 | Index page loads with all form data | UI Page Load | 8 |
| TC-P02 | Index page loads with all taxonomy dropdowns | UI Page Load | 5 |
| TC-P03 | getSections — AJAX loads sections by class | AJAX | 4 |
| TC-P04 | getSubjectGroups — AJAX loads groups by class+section | AJAX | 4 |
| TC-P05 | getSubjects — AJAX loads subjects by subject group | AJAX | 4 |
| TC-P06 | getLessons — AJAX loads lessons by subject | AJAX | 4 |
| TC-P07 | getTopics — AJAX loads topics by lesson | AJAX | 4 |
| TC-P08 | generateQuestions — Demo data stub returns hardcoded questions | Generation | 5 |
| TC-P09 | generateQuestions — Response has all expected fields | Generation | 5 |
| TC-P10 | saveQuestions — Save single valid question | Save | 10 |
| TC-P11 | saveQuestions — Save multiple valid questions (batch) | Save | 8 |
| TC-P12 | saveQuestions — Save with default question_type (MCQ_SINGLE) | Save | 5 |
| TC-P13 | saveQuestions — Save with optional taxonomy fields | Save | 7 |
| TC-P14 | saveQuestions — Auto-competency resolution on save | Save | 6 |
| TC-P15 | getAIProviders — Returns active providers list | Providers | 4 |
| TC-P16 | checkProviderStatus — Valid provider returns active status | Providers | 4 |
| TC-P17 | checkProviderStatus — Provider with config details | Providers | 4 |
| TC-P18 | downloadCSV — Download valid CSV data | CSV | 4 |
| TC-P19 | downloadCSV — File naming and headers | CSV | 5 |
| TC-P20 | saveQuestions — All options (A, B, C, D) created correctly | Save | 6 |
| TC-P21 | saveQuestions — Transaction rollback on failure | Save | 4 |
| TC-P22 | getSections — Returns empty array for class with no sections | AJAX | 3 |
| TC-P23 | generateQuestions — Clean UTF-8 encoding in demo response | Generation | 3 |
| TC-P24 | saveQuestions — Activity log created for each question | Save | 4 |
| TC-P25 | saveQuestions — Review log created with PENDING status | Save | 4 |

#### Negative Test Cases

| TC ID | Test Case Name | Feature | Steps |
|-------|---------------|---------|-------|
| TC-N01 | index — Without tenant.question-bank.create permission | Permission | 2 |
| TC-N02 | generateQuestions — Missing required fields | Validation | 6 |
| TC-N03 | generateQuestions — Invalid class_id | Validation | 2 |
| TC-N04 | generateQuestions — Invalid ai_provider | Validation | 2 |
| TC-N05 | generateQuestions — Missing subject_group_id | Validation | 1 |
| TC-N06 | generateQuestions — AI provider not active | Validation | 2 |
| TC-N07 | saveQuestions — Empty questions array | Validation | 2 |
| TC-N08 | saveQuestions — Missing required question content fields | Validation | 5 |
| TC-N09 | saveQuestions — Invalid correct_answer value | Validation | 2 |
| TC-N10 | saveQuestions — Option content exceeding max length | Validation | 2 |
| TC-N11 | saveQuestions — Invalid class_id in question array | Validation | 2 |
| TC-N12 | saveQuestions — Invalid subject_id in question array | Validation | 2 |
| TC-N13 | saveQuestions — Invalid lesson_id in question array | Validation | 2 |
| TC-N14 | saveQuestions — Invalid topic_id in question array | Validation | 2 |
| TC-N15 | saveQuestions — Correct answer marked but option has no content | Validation | 3 |
| TC-N16 | saveQuestions — Question content exceeds 2000 chars | Validation | 2 |
| TC-N17 | getLessons — Missing subject_id parameter | AJAX | 2 |
| TC-N18 | getTopics — Missing lesson_id parameter | AJAX | 2 |
| TC-N19 | checkProviderStatus — Invalid provider ID | Providers | 2 |
| TC-N20 | downloadCSV — Missing csv_data | CSV | 2 |
| TC-N21 | getSections — Exception handling | AJAX | 2 |
| TC-N22 | getSubjectGroups — Exception handling | AJAX | 2 |
| TC-N23 | getAll AJAX endpoints — Without permission | Permission | 1 |
| TC-N24 | generateQuestions — Without permission | Permission | 1 |
| TC-N25 | saveQuestions — Without permission | Permission | 1 |

#### Dependency Test Cases

| TC ID | Test Case Name | Feature | Steps |
|-------|---------------|---------|-------|
| TC-D01 | DB Persistence — Question and options stored in DB | Integrity | 4 |
| TC-D02 | DB Persistence — Transaction rollback on exception | Integrity | 4 |
| TC-D03 | Cascade — Force delete question cascades to options | Cascade | 4 |
| TC-D04 | Cascade — Soft delete does NOT cascade to options | Cascade | 3 |
| TC-D05 | Prompt — Prompt built with all curriculum context | Prompt | 5 |
| TC-D06 | Prompt — Default values when optional fields not provided | Prompt | 4 |
| TC-D07 | Parsing — AI response parsed correctly from pipe-delimited CSV | Parsing | 5 |
| TC-D08 | Parsing — Fallback sample questions when parsing returns empty | Parsing | 3 |

#### Code Review Test Cases

| TC ID | Test Case Name | Feature | Steps |
|-------|---------------|---------|-------|
| TC-CR01 | Controller index() — Form data loading | Code Review | 3 |
| TC-CR02 | Controller generateQuestions() — Demo stub early return (P0 gap) | Code Review | 3 |
| TC-CR03 | Controller generateQuestions() — Validation rules applied before demo | Code Review | 2 |
| TC-CR04 | Controller saveQuestions() — Full question creation flow | Code Review | 8 |
| TC-CR05 | Controller saveQuestions() — Option creation loop | Code Review | 4 |
| TC-CR06 | Controller saveQuestions() — Default MCQ_SINGLE resolution | Code Review | 3 |
| TC-CR07 | Controller saveQuestions() — Competency auto-resolution | Code Review | 3 |
| TC-CR08 | Controller saveQuestions() — Transaction with begin/commit/rollback | Code Review | 3 |
| TC-CR09 | Controller saveQuestions() — Correct answer normalization and validation | Code Review | 3 |
| TC-CR10 | Controller saveQuestions() — Review log creation | Code Review | 3 |
| TC-CR11 | Controller saveQuestions() — Activity log creation | Code Review | 2 |
| TC-CR12 | Controller callAIService() — Provider dispatch logic | Code Review | 3 |
| TC-CR13 | Controller callChatGPT() — API call with 120s timeout | Code Review | 3 |
| TC-CR14 | Controller callGemini() — API call with 120s timeout | Code Review | 3 |
| TC-CR15 | Controller buildAIPrompt() — Prompt building with all parameters | Code Review | 5 |
| TC-CR16 | Controller parseAIResponse() — CSV parsing logic | Code Review | 4 |
| TC-CR17 | Controller generateSampleQuestions() — Fallback generation | Code Review | 2 |
| TC-CR18 | Controller savePrompt() — Does NOT persist to DB (known gap) | Code Review | 2 |
| TC-CR19 | Controller getDemoResponse() — Hardcoded demo content | Code Review | 2 |
| TC-CR20 | No Rate Limiting — Missing throttle middleware (P0 gap) | Code Review | 2 |
| TC-CR21 | No AIQuestionService — Business logic in controller (known gap) | Code Review | 1 |
| TC-CR22 | API Keys from env() — Not from services config (known gap) | Code Review | 2 |

---

## 10. Test Data Strategy

- **Unique Suffix**: Use `now()->format('His') . random_int(100, 999)` for test data uniqueness
- **Master Data Required**: Classes, Subjects, Subject Groups, Lessons, Topics must exist with `is_active=1`
- **Taxonomy Data**: Bloom Taxonomy, Cognitive Skills, Complexity Levels, Question Types, Type Specificities must be populated
- **AI Provider Config**: Tests for real AI calls blocked by demo stub — tests verify stub behavior, not real API
- **Competency Data**: For auto-competency tests, create `slb_competencies` records matching class_id and subject_id
- **Option Validation**: Tests for option content max length should use strings of 1001+ characters
- **Permission Tests**: Create authenticated users WITH and WITHOUT `tenant.question-bank.create` permission
- **CSV Data**: Tests for downloadCSV provide raw CSV string data
- **Transaction Tests**: Force failures by providing invalid FK references (e.g., non-existent class_id)

---

## 11. Test Case Steps

### 11.1 Positive TC Steps

#### TC-P01: Index page loads with all form data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.question-bank.create` permission | Authenticated |
| 2 | Navigate to GET `/question-bank/ai-question-generator` | Page loads |
| 3 | Verify `aiProviders` array in response data | ChatGPT and Gemini providers present |
| 4 | Verify `classes` collection populated | At least one class returned |
| 5 | Verify `bloomTaxonomies` collection populated | At least one bloom level |
| 6 | Verify `questionTypes` collection populated | At least one question type |
| 7 | Verify `complexityLevels` collection populated | At least one complexity level |
| 8 | Verify `cognitiveSkills` collection populated | At least one cognitive skill |

---

#### TC-P02: Index page loads with all taxonomy dropdowns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load index page | Page loads |
| 2 | Verify `queTypeSpecificities` present | Type specificity data loaded |
| 3 | Verify `topicLevels` present (pluck name, id ordered by level) | Topic levels loaded |
| 4 | Verify view `questionbank::ai-question-generator.index` returned | Correct view rendered |
| 5 | Verify all 8 data sets present in view data | Complete form data available |

---

#### TC-P03: getSections — AJAX loads sections by class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Class C1 with 2 active sections (SecA, SecB) | Sections exist |
| 2 | Send AJAX GET `/question-bank/get-section?class_id=C1` | AJAX call |
| 3 | Verify response is JSON array with 2 entries | Both sections returned |
| 4 | Verify each entry has `id` and `name` fields | Fields present |

---

#### TC-P04: getSubjectGroups — AJAX loads groups by class + section

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Class C1, Section SecA, SubjectGroup SG1 (class=C1, section=SecA), SG2 (class=C1, section=null) | Groups exist |
| 2 | Send AJAX GET `/question-bank/get-subject-groups?class_id=C1&section_id=SecA` | AJAX call |
| 3 | Verify response includes SG1 (matches section) | Section-filtered group returned |
| 4 | Verify response also includes SG2 (null section matches any) | Unfiltered group returned |

---

#### TC-P05: getSubjects — AJAX loads subjects by subject group

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create SubjectGroup SG1 with 2 subjects (S1, S2) via `sch_subject_group_subject_jnt` | Junction records exist |
| 2 | Send AJAX GET `/question-bank/get-subjects?subject_group_id=SG1` | AJAX call |
| 3 | Verify response includes S1 and S2 | Both subjects returned |
| 4 | Verify each subject has `id` and `name` | Correct fields |

---

#### TC-P06: getLessons — AJAX loads lessons by subject

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Subject S1 with 3 active lessons (L1, L2, L3) | Lessons exist |
| 2 | Send AJAX GET `/question-bank/get-lessons?subject_id=S1` | AJAX call |
| 3 | Verify response array has 3 entries | All lessons returned |
| 4 | Verify each lesson has `id` and `name` | Correct fields |

---

#### TC-P07: getTopics — AJAX loads topics by lesson

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Lesson L1 with 2 active topics (T1, T2) | Topics exist |
| 2 | Send AJAX GET `/question-bank/get-topics?lesson_id=L1` | AJAX call |
| 3 | Verify response array has 2 entries | Both topics returned |
| 4 | Verify each topic has `id` and `name` | Correct fields |

---

#### TC-P08: generateQuestions — Demo data stub returns hardcoded questions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send AJAX POST `/question-bank/generate-questions` with valid payload (class_id, subject_group_id, subject_id, lesson_id, topic_id, ai_provider=chatgpt) | Valid request |
| 2 | Verify response.success = true | Success |
| 3 | Verify response.count = 4 | Demo returns 4 hardcoded questions |
| 4 | Verify response.questions array has 4 entries with fields: question, option_a/b/c/d, correct_answer, bloom_taxonomy, cognitive_skill, ques_type_specificity, complexity_level | Full question structure |
| 5 | Verify response.provider_name = 'Demo Provider' | Demo provider name |

---

#### TC-P09: generateQuestions — Response has all expected fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call generateQuestions with valid data | Demo response returned |
| 2 | Verify response has `csv_data` string field | CSV data present |
| 3 | Verify each question has `option_e` field (empty string) | Option E placeholder present |
| 4 | Verify each question has `ques_type` field | Question type field present |
| 5 | Verify correct_answer values are uppercase single letters (A, B, C, D) | Correct format |

---

#### TC-P10: saveQuestions — Save single valid question

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Prepare valid question payload with all required fields: question, correct_answer=A, option_a/b/c/d, class_id, subject_id, lesson_id, topic_id | Valid data |
| 2 | Send AJAX POST `/question-bank/save-questions` with `questions` array containing 1 question | AJAX call |
| 3 | Verify response.success = true | Success |
| 4 | Verify response.saved_count = 1 | 1 question saved |
| 5 | Verify response.question_ids is array with 1 integer ID | Question ID returned |
| 6 | Verify response.redirect_url is `/question-bank/question-bank` | Redirect URL present |
| 7 | DB check: `qns_questions_bank` has new record | Question created |
| 8 | DB check: question has `created_by_AI = 1` | AI flag set |
| 9 | DB check: question has `status = 'DRAFT'` | Default status |
| 10 | DB check: `qns_question_options` has 4 records for this question | 4 options created |

---

#### TC-P11: saveQuestions — Save multiple valid questions (batch)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Prepare payload with 3 valid questions | 3 questions |
| 2 | Send AJAX POST to saveQuestions | AJAX call |
| 3 | Verify response.saved_count = 3 | All 3 saved |
| 4 | Verify response.question_ids has 3 IDs | All IDs returned |
| 5 | DB check: 3 records in qns_questions_bank | 3 questions created |
| 6 | DB check: 12 records in qns_question_options (4 per question) | 12 options created |
| 7 | DB check: 3 records in question_review_log | 3 review logs created |
| 8 | DB check: 3 activity log entries | 3 activity logs created |

---

#### TC-P12: saveQuestions — Save with default question_type (MCQ_SINGLE)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save question WITHOUT question_type_id field | No type specified |
| 2 | Verify response.success = true | Success |
| 3 | DB check: question has `question_type_id` set to MCQ_SINGLE type's ID | Default applied |
| 4 | DB check: MCQ_SINGLE type exists in `slb_question_types` with code 'MCQ_SINGLE' | Lookup succeeds |
| 5 | If MCQ_SINGLE not found, check fallback behavior | Default not applied |

---

#### TC-P13: saveQuestions — Save with optional taxonomy fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create BloomTaxonomy BT1, CognitiveSkill CS1, TypeSpecificity TS1, ComplexityLevel CL1, QuestionType QT1 | Taxonomy exists |
| 2 | Save question with bloom_taxonomy_id=BT1, cognitive_skill_id=CS1, ques_type_specificity_id=TS1, level_id=CL1, question_type_id=QT1 | Taxononomies specified |
| 3 | DB check: question.bloom_id = BT1 | Bloom taxonomy saved |
| 4 | DB check: question.cognitive_skill_id = CS1 | Cognitive skill saved |
| 5 | DB check: question.ques_type_specificity_id = TS1 | Specificity saved |
| 6 | DB check: question.complexity_level_id = CL1 | Complexity saved |
| 7 | DB check: question.question_type_id = QT1 | Question type saved |

---

#### TC-P14: saveQuestions — Auto-competency resolution on save

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Competency Comp1 with class_id=C1, subject_id=S1 | Competency exists |
| 2 | Save question with class_id=C1, subject_id=S1 | Competency match |
| 3 | DB check: question.competency_id = Comp1.id | Competency auto-assigned |
| 4 | Save question with class_id=C2, subject_id=S2 (no matching competency) | No competency found |
| 5 | DB check: question.competency_id = null | Null when not found |
| 6 | Verify no error occurs when competency not found | Graceful handling |

---

#### TC-P15: getAIProviders — Returns active providers list

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send AJAX GET `/question-bank/get-ai-providers` | AJAX call |
| 2 | Verify response.success = true | Success |
| 3 | Verify response.providers is array | Providers list |
| 4 | Verify each provider has id, name, default_model | Required fields |

---

#### TC-P16: checkProviderStatus — Valid provider returns active status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send AJAX GET `/question-bank/ai-provider-status/chatgpt` | AJAX call |
| 2 | Verify response.success = true | Success |
| 3 | Verify response.provider = 'chatgpt' | Provider identified |
| 4 | Verify response.active = true | Active status |

---

#### TC-P17: checkProviderStatus — Provider with config details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send AJAX GET `/question-bank/ai-provider-status/gemini` | AJAX call |
| 2 | Verify response.success = true | Success |
| 3 | Verify response.name = 'Gemini AI' | Correct name |
| 4 | Verify response.default_model = 'gemini-2.0-flash' | Default model returned |

---

#### TC-P18: downloadCSV — Download valid CSV data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send AJAX POST `/question-bank/download-csv` with `csv_data` = valid CSV string | Valid data |
| 2 | Verify response is a file download (not JSON) | File response |
| 3 | Verify Content-Type header = 'text/csv' | Correct content type |
| 4 | Verify Content-Disposition header includes filename with `ai_generated_questions_` prefix | Correct filename |

---

#### TC-P19: downloadCSV — File naming and headers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST with csv_data = "Question,Option_A,Option_B\nQ1,A,B" | CSV data |
| 2 | Verify response headers | Content-Disposition: attachment; filename="ai_generated_questions_*.csv" |
| 3 | Verify Content-Type = 'text/csv' | Correct MIME type |
| 4 | Verify file content matches input csv_data | Content preserved |
| 5 | Verify filename includes current date in Y-m-d_H-i-s format | Date in filename |

---

#### TC-P20: saveQuestions — All options (A, B, C, D) created correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save question with: correct_answer=B, option_a="OptA", option_b="OptB", option_c="OptC", option_d="OptD" | Specific data |
| 2 | DB check: option with ordinal=1 has option_text="OptA", is_correct=false | Option A not correct |
| 3 | DB check: option with ordinal=2 has option_text="OptB", is_correct=true | Option B correct |
| 4 | DB check: option with ordinal=3 has option_text="OptC", is_correct=false | Option C not correct |
| 5 | DB check: option with ordinal=4 has option_text="OptD", is_correct=false | Option D not correct |
| 6 | DB check: all 4 options have is_active=true, question_bank_id set | All active |

---

#### TC-P21: saveQuestions — Transaction rollback on failure

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send 2 questions: Q1 valid, Q2 with invalid class_id=99999 | Mixed valid/invalid |
| 2 | Verify response.success = false | Failure |
| 3 | Verify response.message contains 'Validation failed' or 'Failed to save' | Error message |
| 4 | DB check: neither Q1 nor Q2 saved to qns_questions_bank | Transaction fully rolled back |

---

#### TC-P22: getSections — Returns empty array for class with no sections

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Class C2 with zero sections | No sections |
| 2 | Send AJAX GET `/question-bank/get-section?class_id=C2` | AJAX call |
| 3 | Verify response is empty array | Graceful empty result |

---

#### TC-P23: generateQuestions — Clean UTF-8 encoding in demo response

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call generateQuestions with valid payload | Demo response |
| 2 | Verify all question text is valid UTF-8 | No encoding errors |
| 3 | Verify LaTeX expressions ($\\frac{}, $\\begin{bmatrix}) render correctly in response | Math formatting preserved |

---

#### TC-P24: saveQuestions — Activity log created for each question

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save 2 questions via saveQuestions | Questions saved |
| 2 | DB check: activity_log has 2 entries for 'Created' event with "Saved AI-generated question" message | Activity logged |
| 3 | Verify each log entry has performed_by set to auth user | User tracked |
| 4 | Verify each log entry references the correct question_id | Question referenced |

---

#### TC-P25: saveQuestions — Review log created with PENDING status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save 1 question via saveQuestions | Question saved |
| 2 | DB check: `question_review_log` has 1 record for this question_id | Review log created |
| 3 | Verify review_status_id points to Dropdown with value 'PENDING' | PENDING status |
| 4 | Verify review_comment = 'AI Generated' | Correct comment |

---

### 11.2 Negative TC Steps

#### TC-N01: index — Without tenant.question-bank.create permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.question-bank.create` permission | Authenticated without permission |
| 2 | Navigate to GET `/question-bank/ai-question-generator` | 403 Forbidden |

---

#### TC-N02: generateQuestions — Missing required fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST with NO fields | All required validations fail |
| 2 | Verify response.success = false | Failure |
| 3 | Verify response.errors has errors for: class_id (required), subject_group_id (required), subject_id (required), lesson_id (required), topic_id (required), ai_provider (required) | 6 validation errors |
| 4 | Verify HTTP status code = 400 | Bad request |
| 5 | Verify error messages: "The class id field is required.", "The subject group id field is required.", etc. | Correct messages |
| 6 | Send POST with only class_id | Other fields still missing — 5 remaining errors |

---

#### TC-N03: generateQuestions — Invalid class_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST with class_id=99999, other fields valid | Invalid class |
| 2 | Verify response.success = false, errors.class_id = "The selected class id is invalid." | Validation error |

---

#### TC-N04: generateQuestions — Invalid ai_provider

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST with ai_provider=claude (unsupported), other fields valid | Invalid provider |
| 2 | Verify response.errors.ai_provider = "The selected ai provider is invalid." | Validation error |

---

#### TC-N05: generateQuestions — Missing subject_group_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST without subject_group_id, all others valid | Missing field |
| 2 | Verify error: "The subject group id field is required." | Required error |

---

#### TC-N06: generateQuestions — AI provider not available

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | After demo stub is removed: modify provider config to set chatgpt[active]=false | Provider deactivated |
| 2 | Send valid POST with ai_provider=chatgpt | Inactive provider |
| 3 | Verify response.success = false, message = "Selected AI provider is not available." | Provider not available error |

---

#### TC-N07: saveQuestions — Empty questions array

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST with questions = [] | Empty array |
| 2 | Verify response.success = false, message = "Validation failed" | Validation error |

---

#### TC-N08: saveQuestions — Missing required question content fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST with questions[0] = {} | All fields missing |
| 2 | Verify errors for: questions.0.question (required), questions.0.correct_answer (required), questions.0.option_a (required), questions.0.option_b (required), questions.0.option_c (required), questions.0.option_d (required), questions.0.class_id (required), questions.0.subject_id (required), questions.0.lesson_id (required), questions.0.topic_id (required) | 10 validation errors |
| 3 | Send POST with only question content, no options | Missing option fields |
| 4 | Verify errors for questions.0.option_a/b/c/d | 4 option errors |
| 5 | Send POST with options set but missing correct_answer | Error: questions.0.correct_answer is required |

---

#### TC-N09: saveQuestions — Invalid correct_answer value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send question with correct_answer=E (not A/B/C/D) | Invalid value |
| 2 | Verify response.success = false, errors.questions.0.correct_answer = "The selected questions.0.correct_answer is invalid." | Validation failure |

---

#### TC-N10: saveQuestions — Option content exceeding max length

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send question with option_a containing 1001 characters (max=1000) | Exceeds limit |
| 2 | Verify validation error on questions.0.option_a | Max length error |

---

#### TC-N11: saveQuestions — Invalid class_id in question array

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send question with class_id=99999 | Non-existent class |
| 2 | Verify errors.questions.0.class_id = "The selected questions.0.class_id is invalid." | exists validation fails |

---

#### TC-N12: saveQuestions — Invalid subject_id in question array

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send question with subject_id=99999 | Non-existent subject |
| 2 | Verify validation error on questions.0.subject_id | exists validation fails |

---

#### TC-N13: saveQuestions — Invalid lesson_id in question array

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send question with lesson_id=99999 | Non-existent lesson |
| 2 | Verify validation error on questions.0.lesson_id | exists validation fails |

---

#### TC-N14: saveQuestions — Invalid topic_id in question array

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send question with topic_id=99999 | Non-existent topic |
| 2 | Verify validation error on questions.0.topic_id | exists validation fails |

---

#### TC-N15: saveQuestions — Correct answer marked but option has no content

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send question with correct_answer=B, option_b="" (empty) | Correct option empty |
| 2 | Verify response.success = false | Failure |
| 3 | Verify response.message = "Option B is marked as correct but has no content." | Post-validation business rule error |

---

#### TC-N16: saveQuestions — Question content exceeds 2000 chars

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send question with question field containing 2001 characters | Exceeds max |
| 2 | Verify validation error on questions.0.question | max:2000 validation fails |

---

#### TC-N17: getLessons — Missing subject_id parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send AJAX GET `/question-bank/get-lessons` without subject_id | Missing param |
| 2 | Verify 400 response with error message | Bad request |

---

#### TC-N18: getTopics — Missing lesson_id parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send AJAX GET `/question-bank/get-topics` without lesson_id | Missing param |
| 2 | Verify 400 response with error message | Bad request |

---

#### TC-N19: checkProviderStatus — Invalid provider ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send AJAX GET `/question-bank/ai-provider-status/invalid_provider` | Invalid ID |
| 2 | Verify response.success = false, message = "Provider not found." | 404 error |

---

#### TC-N20: downloadCSV — Missing csv_data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send AJAX POST `/question-bank/download-csv` without csv_data | Missing data |
| 2 | Verify 400 response with "Invalid CSV data" | Validation error |

---

#### TC-N21: getSections — Exception handling

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send AJAX GET `/question-bank/get-section` with no class_id | class_id missing |
| 2 | DB query runs with null class_id — Log::error captured | Error logged |
| 3 | Verify 500 response with "Failed to load sections." | Graceful error |

---

#### TC-N22: getSubjectGroups — Exception handling

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send AJAX GET `/question-bank/get-subject-groups` with no class_id | class_id missing |
| 2 | Verify 500 response with "Failed to load subject groups." | Graceful error handling |

---

#### TC-N23: All AJAX endpoints — Without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.question-bank.create` | Authenticated without permission |
| 2 | Access any AJAX endpoint (getSections, getSubjectGroups, getSubjects, getLessons, getTopics, generateQuestions, saveQuestions, getAIProviders, checkProviderStatus, downloadCSV) | 403 Forbidden on all |

---

#### TC-N24: generateQuestions — Without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.question-bank.create` | Authenticated |
| 2 | POST to generateQuestions | 403 Forbidden |

---

#### TC-N25: saveQuestions — Without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.question-bank.create` | Authenticated |
| 2 | POST to saveQuestions | 403 Forbidden |

---

### 11.3 Dependency TC Steps

#### TC-D01: DB Persistence — Question and options stored in DB

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save 1 valid question | Save succeeds |
| 2 | DB query: `SELECT * FROM qns_questions_bank WHERE id = ?` | Question record exists with all fields |
| 3 | DB query: `SELECT * FROM qns_question_options WHERE question_bank_id = ?` | 4 option records exist |
| 4 | Verify question.created_by_AI = 1, question.status = 'DRAFT', question.created_by = auth user ID | Correct defaults |

---

#### TC-D02: DB Persistence — Transaction rollback on exception

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save 2 questions where Q2 has invalid correct_answer = 'Z' (throws Exception after option validation) | Q2 throws at line 813-815 |
| 2 | Verify response.success = false, message contains "Invalid correct answer" | Failure |
| 3 | DB check: count of questions with created_at near test time | No new records (rolled back) |
| 4 | DB check: count of question_options with recent created_at | No new option records (rolled back) |

---

#### TC-D03: Cascade — Force delete question cascades to options

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save 1 question (creates question + 4 options) | Records exist |
| 2 | Force-delete the question via QuestionBank force delete | Question permanently removed |
| 3 | DB check: option records with question_bank_id | Records also removed (FK CASCADE) |
| 4 | DB check: options withTrashed gone permanently | Cascade confirmed |

---

#### TC-D04: Cascade — Soft delete does NOT cascade to options

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save 1 question (creates question + 4 options) | Records exist |
| 2 | Soft-delete the question via QuestionBank delete() | Question deleted_at set |
| 3 | DB check: options with question_bank_id, ignoring soft deletes | Options still exist (no cascade on soft delete) |

---

#### TC-D05: Prompt — Prompt built with all curriculum context

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call generateQuestions with: class_id=C1, subject_id=S1, lesson_id=L1, topic_id=T1, ai_provider=chatgpt, bloom_taxonomy=BT1, cognitive_level=CS1, number_of_question_id=10 | Valid request |
| 2 | Code enters buildAIPrompt() (verify via debug/log) | Prompt built |
| 3 | Prompt contains className, subjectName, lessonName, topicName | Curriculum context embedded |
| 4 | Prompt contains bloomName, complexityName, cognitiveName | Taxonomy embedded |
| 5 | Prompt contains questionCount = 10 | Count embedded |

---

#### TC-D06: Prompt — Default values when optional fields not provided

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call generateQuestions without bloom_taxonomy, level_id, cognitive_level, que_type_specificities, question_type | Optional fields omitted |
| 2 | Code enters buildAIPrompt() with null taxonomy params | Defaults used |
| 3 | Verify bloomName defaults to 'UNDERSTAND' when bloomTaxonomy is null | Default bloom |
| 4 | Verify complexityName defaults to 'Comp1' when complexityLevel is null | Default complexity |

---

#### TC-D07: Parsing — AI response parsed correctly from pipe-delimited CSV

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Simulate AI response CSV with pipe-delimited data matching expected format | Valid CSV |
| 2 | Call parseAIResponse() with the CSV string | Parsing runs |
| 3 | Verify questions array has correct count matching input rows | Count matches |
| 4 | Verify each question has: question, option_a-d, explanation_a-d, correct_answer (uppercase), bloom_taxonomy, cognitive_skill, ques_type_specificity, complexity_level | All fields parsed |
| 5 | Verify row with < 10 columns is skipped | Minimum column check |

---

#### TC-D08: Parsing — Fallback sample questions when parsing returns empty

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call parseAIResponse() with empty or invalid CSV (non-parseable) | Parsing returns empty |
| 2 | Code falls back to generateSampleQuestions() | Sample generated |
| 3 | Verify 5 sample questions returned with default taxonomy values | 5 questions with Remembering/Recall/Direct Recall/Easy |

---

#### TC-D09: SET NULL — Parent taxonomy deletion sets FK to NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Question Q1 references class=C1, subject=S1, lesson=L1, topic=T1, competency=CP1, bloom=B1, cog=CG1, spec=SP1, complexity=CX1, created_by=U1 | All FK columns populated |
| 2 | Force delete each parent (C1, S1, L1, T1, CP1, B1, CG1, SP1, CX1, U1) individually | Parent deleted |
| 3 | Verify Q1 still exists and each FK column = NULL | All SET NULL |

---

#### TC-D10: RESTRICT — question_type deletion blocked by FK

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Question Q1 references question_type_id = QT1 | FK populated |
| 2 | Attempt to delete QT1 from `slb_question_types` | Operation rejected (integrity constraint violation) |
| 3 | Verify QT1 still exists in `slb_question_types` | Parent preserved |

---

### 11.4 Code Review TC Steps

#### TC-CR01: Controller index() — Form data loading

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review index() method | Gate::authorize() at line 59 |
| 2 | Review $data array | All 8 datasets: aiProviders, classes, bloomTaxonomies, questionTypes, complexityLevels, cognitiveSkills, queTypeSpecificities, topicLevels |
| 3 | Verify view returns `questionbank::ai-question-generator.index` | Correct view |

---

#### TC-CR02: Controller generateQuestions() — Demo stub early return (P0 gap)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review generateQuestions() line 232 | `return $this->getDemoResponse($request);` executes BEFORE any real AI call |
| 2 | Verify code after line 232 (provider check, prompt building, API calls, parsing) is DEAD CODE | Never reached |
| 3 | Verify getDemoResponse() at lines 327-418 returns 4 hardcoded questions | No AI integration active |

---

#### TC-CR03: Controller generateQuestions() — Validation rules applied before demo

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review generateQuestions() flow | Validator runs BEFORE demo return |
| 2 | Verify validation at lines 214-221 catches invalid input before demo stub | Validation gates stub |

---

#### TC-CR04: Controller saveQuestions() — Full question creation flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review saveQuestions() line 729: Gate::authorize() | Permission check first |
| 2 | Review line 730: DB::beginTransaction() | Transaction starts |
| 3 | Review validator at lines 733-763 with 20+ rules | Comprehensive validation |
| 4 | Review QuestionBank::create() at lines 824-876 with all 25+ fields | Question creation |
| 5 | Review activityLog() call at lines 879-883 | Activity logged |
| 6 | Review QuestionReviewLog::create() at lines 890-897 | Review log created |
| 7 | Review option creation loop at lines 899-937 with 4 options | 4 options per question |
| 8 | Review DB::commit() at line 943 and catch block with DB::rollBack() at line 954 | Transaction integrity |

---

#### TC-CR05: Controller saveQuestions() — Option creation loop

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review options array at lines 900-921 | 4 entries A/B/C/D with text, explanation, is_correct |
| 2 | Verify ordinals 1-4 assigned sequentially | ordinals in create loop |
| 3 | Verify correct option marked with is_correct=true | Only one correct |
| 4 | Verify all 4 options have is_active=true | All active |

---

#### TC-CR06: Controller saveQuestions() — Default MCQ_SINGLE resolution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review lines 776-782 | Lookup: QuestionType::where('code', 'MCQ_SINGLE')->first() |
| 2 | Verify fallback to MCQ_SINGLE.id when question_type_id empty | Default applied |
| 3 | Verify if MCQ_SINGLE not found, question_type_id remains null | Graceful null handle |

---

#### TC-CR07: Controller saveQuestions() — Competency auto-resolution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review lines 784-787 | Competencie::where(class_id, subject_id)->first() |
| 2 | Verify first matching competency used | `->first()` not `->get()` |
| 3 | Verify if no match, competency_id = null | Null when no match |

---

#### TC-CR08: Controller saveQuestions() — Transaction with begin/commit/rollback

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review catch block at lines 953-964 | DB::rollBack() called on Exception |
| 2 | Verify catch block logs error and returns JSON 500 | Proper error response |
| 3 | Verify all creation happens between beginTransaction and commit | Transaction boundary checked |

---

#### TC-CR09: Controller saveQuestions() — Correct answer normalization

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review line 812: strtoupper(trim(...)) | Normalizes a/b/c/d to A/B/C/D |
| 2 | Review line 813: in_array check against ['A','B','C','D'] | Only valid letters accepted |
| 3 | Review line 818-821: checks if correct option key has content | Option content validated |

---

#### TC-CR10: Controller saveQuestions() — Review log creation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review lines 885-897 | QuestionReviewLog::create() with question_id, reviewer_id, review_comment='AI Generated', reviewed_at=now() |
| 2 | Verify Dropdown lookup for 'PENDING' value at lines 886-888 | Status resolved |
| 3 | Verify is_active=true on review log | Active review log |

---

#### TC-CR11: Controller saveQuestions() — Activity log creation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review lines 879-883 | activityLog() called with event 'Created' |
| 2 | Verify message includes "Saved AI-generated question" | Correct log message |

---

#### TC-CR12: Controller callAIService() — Provider dispatch logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review switch statement at lines 518-528 | Routes to callChatGPT or callGemini |
| 2 | Verify default case returns false with Log::error | Unsupported provider handled |
| 3 | Verify outer catch at lines 529-532 logs error and returns false | Exception handled |

---

#### TC-CR13: Controller callChatGPT() — API call with 120s timeout

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review line 544: Http::timeout(120) | 120 second timeout |
| 2 | Review API URL, headers, model, messages, max_tokens=4000, temperature=0.7 | Correct config |
| 3 | Review response parsing at lines 565-569: extracts choices[0].message.content | Content extracted |

---

#### TC-CR14: Controller callGemini() — API call with 120s timeout

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review line 591: Http::timeout(120) | 120 second timeout |
| 2 | Review API URL with ?key=, contents structure, generationConfig | Correct Gemini config |
| 3 | Review response parsing at lines 608-612: extracts candidates[0].content.parts[0].text | Content extracted |

---

#### TC-CR15: Controller buildAIPrompt() — Prompt building with all parameters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review prompt structure at lines 458-507 | Contains system instruction, metadata header, column heading, pipe-delimited format specification |
| 2 | Verify curriculum context parameters (class, subject, lesson, topic) embedded | All parameters interpolated |
| 3 | Verify taxonomy parameters (bloom, complexity, cognitive, specificity) included | Taxonomy embedded |
| 4 | Verify question count and additional instructions included | Count and text embedded |
| 5 | Verify quality standards section and example output included | Examples present |

---

#### TC-CR16: Controller parseAIResponse() — CSV parsing logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review header detection at lines 633-638 | Skips first line if it contains 'question' |
| 2 | Review str_getcsv() call at line 645 | Parses CSV line |
| 3 | Review minimum column check at line 648 (count >= 10) | Filters out short rows |
| 4 | Review field mapping at lines 650-665 | Maps position 0→question, 1→option_a, 2→explanation_a, ..., 9→correct_answer (strtoupper), 10→bloom_taxonomy |

---

#### TC-CR17: Controller generateSampleQuestions() — Fallback generation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review loop at lines 685-706 | Generates 5 sample questions |
| 2 | Verify all questions have default taxonomy: Remembering, Recall, Direct Recall, Easy | Consistent defaults |

---

#### TC-CR18: Controller savePrompt() — Does NOT persist to DB (known gap)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review savePrompt() at lines 711-722 | ONLY calls Log::info() — no DB insert |
| 2 | Verify no DB model or table reference in savePrompt | No persistence |

---

#### TC-CR19: Controller getDemoResponse() — Hardcoded demo content

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review demo questions array at lines 330-402 | 4 hardcoded questions with LaTeX formatting |
| 2 | Verify response structure: questions, csv_data, count, provider_name | Full response shape |

---

#### TC-CR20: No Rate Limiting — Missing throttle middleware (P0 gap)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review route definition for `/question-bank/generate-questions` in routes/web.php | No `throttle` middleware applied |
| 2 | Verify no RateLimiter or throttle in controller method | No rate limiting of any kind |

---

#### TC-CR21: No AIQuestionService — Business logic in controller (known gap)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review controller for service layer delegation | All AI logic (prompt building, API calls, parsing, sample generation) in controller methods |

---

#### TC-CR22: API Keys from env() — Not from services config (known gap)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review callChatGPT() line 541: `config('services.chatgpt.api_key')` | Uses config — but requirement says should use config/services.php |
| 2 | Review callGemini() line 588: `config('services.gemini.api_key')` | Same pattern — all env-based |

---

## 12. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|--------|-----|------|-------------------|---------------------|
| GET | `/question-bank/ai-question-generator` | ai-question-generator | index() | tenant.question-bank.create |
| GET | `/question-bank/get-section` | getSections | getSections() | tenant.question-bank.create |
| GET | `/question-bank/get-subject-groups` | getSubjectGroups | getSubjectGroups() | tenant.question-bank.create |
| GET | `/question-bank/get-subjects` | getSubjects | getSubjects() | tenant.question-bank.create |
| GET | `/question-bank/get-lessons` | getLessons | getLessons() | tenant.question-bank.create |
| GET | `/question-bank/get-topics` | getTopics | getTopics() | tenant.question-bank.create |
| POST | `/question-bank/generate-questions` | generateQuestions | generateQuestions() | tenant.question-bank.create |
| POST | `/question-bank/save-questions` | saveQuestions | saveQuestions() | tenant.question-bank.create |
| POST | `/question-bank/download-csv` | downloadCSV | downloadCSV() | tenant.question-bank.create |
| GET | `/question-bank/get-ai-providers` | ai-question-generator.getProviders | getAIProviders() | tenant.question-bank.create |
| GET | `/question-bank/ai-provider-status/{id}` | ai-provider.status | checkProviderStatus() | tenant.question-bank.create |

---

## 13. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-01 | Demo data stub returns hardcoded questions instead of calling real AI | **P0** | `generateQuestions()` has `return $this->getDemoResponse($request);` at line 232. All code after this line (provider check, prompt building, API calls, response parsing) is dead code. 4 hardcoded questions returned regardless of input parameters. |
| KI-02 | No rate limiting on generation endpoint | **P0** | Route has no `throttle` middleware. Uncontrolled API calls could cause unlimited AI provider costs. |
| KI-03 | API keys read directly from `env()`(via `config()`) | **Medium** | Keys read from `config('services.*.api_key')` which maps to `.env`. Should use proper config in `config/services.php` with validation. |
| KI-04 | No dedicated AIQuestionService | **Medium** | All AI logic (prompt building, API calls, parsing, sample generation) lives in controller. Violates Single Responsibility Principle. |
| KI-05 | `savePrompt()` does not persist to DB | **Low** | Method only logs to Laravel log instead of storing prompt data in a database table for audit/replay. |
| KI-06 | No scheduled job for cleaning up AI sessions | **Low** | No artisan command or scheduler task to clean up stale AI generation sessions or temporary data. |
| KI-07 | `getSections()` and `getSubjectGroups()` lack input validation | **Medium** | These endpoints have no request validation; they assume `class_id` is present. Missing class_id causes DB warning and 500 error. |
| KI-08 | `getSubjects()` no input validation for subject_group_id | **Medium** | Similar to KI-07 — missing subject_group_id causes DB failure with 500 error. |
| KI-09 | Demo LaTeX questions may not reflect user's curriculum context | **Low** | Demo stub always returns the same 4 math/LaTeX questions regardless of the subject/lesson/topic the user selected. |
| KI-10 | Generated questions always have `option_e` as empty string | **Low** | Option E is included in demo response but always empty — may confuse UI rendering. |
| KI-11 | `correct_answer` NOT in `$fillable` — silently ignored on save | **P0** | `QuestionBank::create()` at line 839 includes `'correct_answer' => $correctOption`, but `correct_answer` is NOT listed in `QuestionBank::$fillable` (lines 51-75) and no `correct_answer` column exists in any DB migration. The value is silently stripped by mass-assignment protection and never persisted. TC-CR09 verifies normalization (strtoupper, in_array) which exists in code, but the saved question will NOT retain which option is correct. |

---

## 14. Feature Summary Matrix

| Feature | REQ ID | Controller Method(s) | Key Models | Validation Source |
|---------|--------|---------------------|------------|-------------------|
| AI Generator Page | REQ-QNS-014 | index() | SchoolClass, BloomTaxonomy, CognitiveSkill, ComplexityLevel, QueTypeSpecifity, QuestionType, TopicLevelType | None (read-only) |
| AJAX Section Lookup | REQ-QNS-014 | getSections() | ClassSection, Section | None (inline try/catch) |
| AJAX Subject Group Lookup | REQ-QNS-014 | getSubjectGroups() | SubjectGroup | None (inline try/catch) |
| AJAX Subject Lookup | REQ-QNS-014 | getSubjects() | Subject, sch_subject_group_subject_jnt | None (inline try/catch) |
| AJAX Lesson Lookup | REQ-QNS-014 | getLessons() | Lesson | Validator: subject_id required |
| AJAX Topic Lookup | REQ-QNS-014 | getTopics() | Topic | Validator: lesson_id required |
| AI Question Generation | REQ-QNS-015 | generateQuestions() | SchoolClass, Section, SubjectGroup, Subject, Lesson, Topic, BloomTaxonomy, ComplexityLevel, CognitiveSkill, QueTypeSpecifity, QuestionType | Validator: 7 rules (class_id, section_id, subject_group_id, subject_id, lesson_id, topic_id, ai_provider) |
| Save Generated Questions | REQ-QNS-016 | saveQuestions() | QuestionBank, QuestionOption, Competencie, QuestionReviewLog | Validator: 20+ rules + 2 post-validation checks |
| AI Provider Listing | REQ-QNS-014 | getAIProviders() | None (hardcoded config array) | None |
| Provider Status Check | REQ-QNS-014 | checkProviderStatus() | None (hardcoded config array) | Route parameter {id} |
| CSV Download | REQ-QNS-014 | downloadCSV() | None | Validator: csv_data required |

---

(End of file - total lines)
