# lms_Summary_TcList

## Module: LmsQuests → Quest Management → Summary, Paper Check, Report & Attempt Detail

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsQuests |
| Tab Group | Quest Management (Tabbed Interface) |
| Features | Quest Summary Grid (REQ-QST-010, RPT-QST-002), Paper Check & Grade Submission (REQ-QST-011/012), Performance Report (REQ-QST-013, RPT-QST-003), Attempt Detail (REQ-QST-014, RPT-QST-004) |
| URL(s) | `/lms-quests/quest` (index — summary tab), `/lms-quests/quest/{id}/paper-check`, `/lms-quests/quest/{questId}/get-student-attempt-data`, `/lms-quests/quest/{questId}/grade-submission`, `/lms-quests/quest/{questId}/save-answer-grade`, `/lms-quests/quest/{quest_id}/report`, `/lms-quests/quest/attempt/{attempt_id}/detail`, `/lms-quests/quest/{questId}/get-student-questions-with-attachments` |
| Controller | `Modules\LmsQuests\Http\Controllers\LmsQuestController` |
| Model(s) | `Quest`, `QuestAllocation`, `QuestQuestion`, `QuizQuestAttempt`, `QuizQuestAttemptAnswer`, `QuizQuestResult`, `StudentAcademicSession` |
| Validation | Inline in `gradeSubmission()` — 9 fields; inline in `saveAnswerGrade()` — 4 fields |
| Permission Gates | `tenant.quest.viewAny` (summary/report/detail), `tenant.quest.update` (grade submission), `tenant.quest-question.update` (saveAnswerGrade) |
| Soft Deletes | N/A for these features (read-intensive, write is grading) |
| Events | `QuizQuestResultPublished` — dispatched on result publish |

---

## 2. Pre-conditions

- Required permissions: `tenant.quest.viewAny`, `tenant.quest.update`, `tenant.quest-question.update`
- At least one active Quest must exist (`is_active=1`) with questions and allocations
- At least one student must be allocated and have submitted an attempt (for grading/Paper Check tests)
- Master data: `sch_classes`, `sch_class_sections`, `sch_subjects`, `std_student_academic_sessions` must be populated

---

## 3. Default Data Load

### Summary Tab Data (when active_tab=quest_summary)

| Data | Source | Notes |
|------|--------|-------|
| Allocations (paginated) | `QuestAllocation::with(['quest.subject','quest.class','assigner'])` | With submitted/in_progress/checked withCount |
| Submitted Count | `attempts` where status IN ('SUBMITTED','EVALUATED','RESULT_PUBLISHED','TIMEOUT') | `attempts as submitted_count` |
| In Progress Count | `attempts` where status = 'IN_PROGRESS' | `attempts as in_progress_count` |
| Checked Count | `attempts` where `answers.evaluated_by IS NOT NULL` | `attempts as checked_count` via whereHas |
| Assigned Count | CLASS→`SchoolClass::withCount(studentAcademicSessions)`; SECTION→`ClassSection::withCount(studentAcademicSessions)`; STUDENT→1 | Calculated per allocation on page |
| Class+Section Map | `ClassSection::with(['class','section'])` | For SECTION-type allocation display |
| Pagination | 10 per page, `summary_page` parameter | Independent from other tabs |

### Paper Check Tab Data (GET /lms-quests/quest/{id}/paper-check)

| Data | Source | Notes |
|------|--------|-------|
| Quest (with relations) | `Quest::with(['class','subject','questQuestions.question'])` | Questions ordered by ordinal |
| All Attempts | `QuizQuestAttempt::with(['student'])` | assessment_type=QUEST, ordered by student_id |
| Results (keyed by attempt_id) | `QuizQuestResult::whereIn('attempt_id',...)` | Keyed by attempt_id for quick lookup |

### Performance Report (GET /lms-quests/quest/{quest_id}/report)

| Data | Source | Notes |
|------|--------|-------|
| Quest | `Quest::with(['class','subject','allocations'])` | Quest with allocations |
| Students (paginated) | `StudentAcademicSession` resolved from all allocations | Deduplicated across allocation types |
| Attempts (grouped by student_id) | `QuizQuestAttempt::with(['student','result'])` | assessment_type=QUEST |
| Status Counts | Calculated: NOT_STARTED, IN_PROGRESS, SUBMITTED | Per student, latest attempt |
| Avg Score | `QuizQuestResult::avg('percentage')` | assessment_id=quest_id |
| Score Bins | 5 bins from results | Same as dashboard |
| Pagination | 25 per page | Manual LengthAwarePaginator |

### Attempt Detail (GET /lms-quests/quest/attempt/{attempt_id}/detail)

| Data | Source | Notes |
|------|--------|-------|
| Attempt | `QuizQuestAttempt::with(['student','result','quest'])` | Single attempt |
| Questions | `QuestQuestion::with(['question.options','question.questionType'])` | Ordered by ordinal |
| Answers | `QuizQuestAttemptAnswer::where('attempt_id',...)` | Keyed by question_id with file resolution |

---

## 4. Database Schema (BC-DB)

### Table: `lms_quests`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| uuid | BINARY(16) | UNIQUE, NOT NULL | |
| academic_session_id | INT UNSIGNED | FK→glb_academic_sessions.id, NOT NULL | |
| class_id | INT UNSIGNED | FK→sch_classes.id, NOT NULL | |
| subject_id | INT UNSIGNED | FK→sch_subjects.id, NOT NULL | |
| quest_type_id | INT UNSIGNED | FK→lms_assessment_types.id, NOT NULL | Challenge/Enrichment etc. |
| quest_code | VARCHAR(50) | UNIQUE, NOT NULL | Auto-generated |
| title | VARCHAR(255) | NOT NULL | |
| description | TEXT | NULLABLE | |
| instructions | TEXT | NULLABLE | |
| status | VARCHAR(20) | NOT NULL, DEFAULT 'DRAFT' | DRAFT/PUBLISHED/ARCHIVED |
| duration_minutes | INT UNSIGNED | NULLABLE | |
| total_marks | DECIMAL(8,2) | NOT NULL, DEFAULT 0.00 | |
| total_questions | INT UNSIGNED | NOT NULL, DEFAULT 0 | |
| passing_percentage | DECIMAL(5,2) | NOT NULL, DEFAULT 33.00 | |
| allow_multiple_attempts | TINYINT(1) | NOT NULL, DEFAULT 0 | |
| max_attempts | TINYINT UNSIGNED | NOT NULL, DEFAULT 1 | |
| negative_marks | DECIMAL(4,2) | NOT NULL, DEFAULT 0.00 | |
| is_randomized | TINYINT(1) | NOT NULL, DEFAULT 0 | |
| question_marks_shown | TINYINT(1) | NOT NULL, DEFAULT 0 | |
| auto_publish_result | TINYINT(1) | NOT NULL, DEFAULT 0 | |
| timer_enforced | TINYINT(1) | NOT NULL, DEFAULT 1 | |
| show_correct_answer | TINYINT(1) | NOT NULL, DEFAULT 0 | |
| show_explanation | TINYINT(1) | NOT NULL, DEFAULT 0 | |
| difficulty_config_id | INT UNSIGNED | FK→lms_difficulty_distribution_configs.id, NULLABLE | |
| ignore_difficulty_config | TINYINT(1) | NOT NULL, DEFAULT 0 | |
| is_system_generated | TINYINT(1) | NOT NULL, DEFAULT 0 | |
| only_unused_questions | TINYINT(1) | NOT NULL, DEFAULT 0 | |
| only_authorised_questions | TINYINT(1) | NOT NULL, DEFAULT 0 | |
| created_by | INT UNSIGNED | FK→sys_users.id, NULLABLE | |
| is_active | TINYINT(1) | NOT NULL, DEFAULT 1 | |
| created_at | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP ON UPDATE | |
| deleted_at | TIMESTAMP | NULLABLE | Soft delete |

### Table: `lms_quest_allocations`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| quest_id | INT UNSIGNED | FK→lms_quests.id, NOT NULL | |
| allocation_type | ENUM('CLASS','SECTION','GROUP','STUDENT') | NOT NULL | |
| target_table_name | VARCHAR(60) | NOT NULL | Polymorphic target table name |
| target_id | INT UNSIGNED | NOT NULL | Polymorphic target ID |
| assigned_by | INT UNSIGNED | FK→sys_users.id, NULLABLE | |
| published_at | DATETIME | NULLABLE | |
| due_date | DATETIME | NULLABLE | |
| cut_off_date | DATETIME | NULLABLE | |
| is_auto_publish_result | TINYINT(1) | NOT NULL, DEFAULT 0 | |
| result_publish_date | DATETIME | NULLABLE | |
| is_active | TINYINT(1) | NOT NULL, DEFAULT 1 | |
| created_at | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP ON UPDATE | |
| deleted_at | TIMESTAMP | NULLABLE | Soft delete |

### Table: `lms_quest_questions`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| quest_id | INT UNSIGNED | FK→lms_quests.id, NOT NULL | |
| question_id | INT UNSIGNED | FK→qns_questions_bank.id, NOT NULL | |
| ordinal | INT UNSIGNED | NOT NULL, DEFAULT 0 | Display sequence |
| marks_override | DECIMAL(5,2) | NULLABLE | |
| is_active | TINYINT(1) | NOT NULL, DEFAULT 1 | |
| created_at | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP ON UPDATE | |
| deleted_at | TIMESTAMP | NULLABLE | Soft delete |

### Table: `lms_quiz_quest_attempts`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | BIGINT(20) UNSIGNED | PK, AUTO_INCREMENT | |
| student_id | BIGINT(20) UNSIGNED | NOT NULL | |
| assessment_type | VARCHAR(20) | NOT NULL | 'QUEST' |
| quiz_id | BIGINT(20) UNSIGNED | NULLABLE | For quiz reuse |
| quest_id | BIGINT(20) UNSIGNED | NOT NULL | |
| quiz_allocation_id | BIGINT(20) UNSIGNED | NULLABLE | |
| quest_allocation_id | BIGINT(20) UNSIGNED | FK→lms_quest_allocations.id, NULLABLE | |
| attempt_number | INT | NOT NULL | |
| started_at | DATETIME | NULLABLE | |
| submitted_at | DATETIME | NULLABLE | |
| auto_submitted_at | DATETIME | NULLABLE | |
| time_taken_seconds | INT | NULLABLE | |
| status | VARCHAR(20) | NOT NULL | IN_PROGRESS/SUBMITTED/EVALUATED/RESULT_PUBLISHED/TIMEOUT |
| score_obtained | DECIMAL(8,2) | NULLABLE | |
| max_score | DECIMAL(8,2) | NULLABLE | |
| percentage | DECIMAL(5,2) | NULLABLE | |
| is_passed | TINYINT(1) | NULLABLE | |
| teacher_feedback | TEXT | NULLABLE | |
| ip_address | VARCHAR(45) | NULLABLE | |
| browser_agent | TEXT | NULLABLE | |
| device_info | JSON | NULLABLE | |
| violation_count | INT | NOT NULL, DEFAULT 0 | |
| is_active | TINYINT(1) | NOT NULL, DEFAULT 1 | |
| created_by | BIGINT(20) UNSIGNED | NULLABLE | |
| created_at | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP ON UPDATE | |
| deleted_at | TIMESTAMP | NULLABLE | Soft delete |

### Table: `lms_quiz_quest_attempt_answers`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | BIGINT(20) UNSIGNED | PK, AUTO_INCREMENT | |
| attempt_id | BIGINT(20) UNSIGNED | FK→lms_quiz_quest_attempts.id, NOT NULL | |
| question_id | BIGINT(20) UNSIGNED | NOT NULL | FK→qns_questions_bank.id |
| question_type_id | BIGINT(20) UNSIGNED | NULLABLE | |
| selected_option_id | BIGINT(20) UNSIGNED | NULLABLE | MCQ selected option |
| selected_option_ids | JSON | NULLABLE | Multi-select MCQ |
| answer_text | TEXT | NULLABLE | Descriptive answer |
| attachment_data | JSON | NULLABLE | File uploads |
| marks_obtained | DECIMAL(8,2) | NULLABLE | |
| max_marks | DECIMAL(8,2) | NULLABLE | |
| is_correct | TINYINT(1) | NULLABLE | |
| is_evaluated | TINYINT(1) | NULLABLE | |
| evaluated_by | BIGINT(20) UNSIGNED | NULLABLE | FK→sys_users.id |
| evaluation_remarks | TEXT | NULLABLE | |
| evaluated_at | TIMESTAMP | NULLABLE | |
| time_spent_seconds | INT | NULLABLE | |
| change_count | INT | NULLABLE | |
| is_active | TINYINT(1) | NOT NULL, DEFAULT 1 | |
| created_at | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP ON UPDATE | |
| deleted_at | TIMESTAMP | NULLABLE | Soft delete |

### Table: `lms_quiz_quest_results`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | BIGINT(20) UNSIGNED | PK, AUTO_INCREMENT | |
| attempt_id | BIGINT(20) UNSIGNED | FK→lms_quiz_quest_attempts.id, NOT NULL | |
| student_id | BIGINT(20) UNSIGNED | NOT NULL | |
| assessment_type | VARCHAR(20) | NOT NULL | 'QUEST' |
| assessment_id | BIGINT(20) UNSIGNED | NOT NULL | quest_id |
| total_marks_obtained | DECIMAL(8,2) | NULLABLE | |
| max_marks | DECIMAL(8,2) | NULLABLE | |
| percentage | DECIMAL(5,2) | NULLABLE | |
| grade_obtained | VARCHAR(5) | NULLABLE | A1/A2/B1/B2/C1/C2/D/E |
| is_passed | TINYINT(1) | NULLABLE | |
| rank_in_class | INT | NULLABLE | |
| percentile | DECIMAL(5,2) | NULLABLE | |
| is_published | TINYINT(1) | NULLABLE | |
| published_at | TIMESTAMP | NULLABLE | |
| teacher_remarks | TEXT | NULLABLE | |
| is_active | TINYINT(1) | NOT NULL, DEFAULT 1 | |
| created_by | BIGINT(20) UNSIGNED | NULLABLE | |
| created_at | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP ON UPDATE | |
| deleted_at | TIMESTAMP | NULLABLE | Soft delete |

---

## 5. Validation Rules (BC-VAL)

### `gradeSubmission()` Validation

| Field | Rule | Error Message |
|-------|------|---------------|
| attempt_id | required, integer, findOrFail | "The selected attempt id is invalid." |
| marks_obtained | required, numeric, min:0 | "The marks obtained must be at least 0." |
| max_marks | required, numeric, min:0 | "The max marks must be at least 0." |
| teacher_remarks | nullable, string, max:2000 | "The teacher remarks must not be greater than 2000 characters." |
| is_published | boolean | "The is published field must be true or false." |
| annotated_pdf | nullable, file, mimes:pdf, max:51200 | "The annotated pdf must be a file of type: pdf." / "The annotated pdf must not be greater than 51200 kilobytes." |
| question_id | nullable, integer | "The question id must be an integer." |
| ordinal | nullable, integer, min:1 | "The ordinal must be at least 1." |
| answers_json | nullable, string | "The answers json must be a string." |

### `saveAnswerGrade()` Validation

| Field | Rule | Error Message |
|-------|------|---------------|
| attempt_id | required, exists:lms_quiz_quest_attempts,id | "The selected attempt id is invalid." |
| marks_obtained | required, numeric, min:0 | "The marks obtained must be at least 0." |
| ordinal | required, integer | "The ordinal is required." |
| evaluation_remarks | nullable, string | |
| question_id | nullable, integer | Resolves the quest question (virtual FK) |

### Custom Validation (in code)

| Validation Location | Condition | Error Message |
|---------------------|-----------|---------------|
| `saveAnswerGrade()` | `$marksObtained > $maxAllowed` (where `$maxAllowed > 0`) | "Marks cannot exceed max marks for this question." |
| `getStudentAttemptData()` | No attempt found for quest+student | "No attempt found." |

---

## 6. Authorization (BC-AUTH)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.quest.viewAny | summary tab, paper-check, report, detail pages | Without → 403 |
| BC-AUTH-02 | tenant.quest.update | gradeSubmission() | Without → 403 |
| BC-AUTH-03 | tenant.quest-question.update | saveAnswerGrade() | Without → 403 |

---

## 7. Business Logic (BC-BIZ)

### Summary Grid Business Logic

| BC-BIZ ID | Original BC ID | Rule | Description |
|-----------|----------------|------|-------------|
| BC-BIZ-01 | BC-SUM-01 | Summary is Per-Allocation | Grid rows are `lms_quest_allocations`, not individual students |
| BC-BIZ-02 | BC-SUM-02 | Assigned Count Resolution | CLASS→`SchoolClass::withCount(studentAcademicSessions)`; SECTION→`ClassSection::withCount(studentAcademicSessions)`; STUDENT→1 |
| BC-BIZ-03 | BC-SUM-03 | Checked Count = Answer-Level | Attempt considered checked if ANY answer has `evaluated_by IS NOT NULL` |
| BC-BIZ-04 | BC-SUM-04 | Submitted Count Includes Multiple Statuses | SUBMITTED, EVALUATED, RESULT_PUBLISHED, TIMEOUT all count as submitted |
| BC-BIZ-05 | BC-SUM-05 | SECTION Filter OR for Summary | Three OR conditions for CLASS/SECTION/STUDENT allocation types |
| BC-BIZ-06 | BC-SUM-06 | Summary Pagination = 10 | Uses `summary_page` query parameter, independent offset |
| BC-BIZ-07 | BC-SUM-07 | Subject Filter on Summary | Filters through `quest.subject_id` on the allocation's related quest |

### Paper Check Business Logic

| BC-BIZ ID | Original BC ID | Rule | Description |
|-----------|----------------|------|-------------|
| BC-BIZ-08 | BC-PCK-01 | Paper Check Uses Quest ID | `questPaperCheck($id)` takes Quest ID, not allocation ID |
| BC-BIZ-09 | BC-PCK-02 | All Attempts for Quest | Shows ALL attempts across all allocations for the given quest |
| BC-BIZ-10 | BC-PCK-03 | Student List = All Attemptors | Students who have attempted (not all allocated); filtered by student_id param |
| BC-BIZ-11 | BC-PCK-04 | Marks ≤ Max Marks | `saveAnswerGrade` validates `marks_obtained <= max_marks` at question level |
| BC-BIZ-12 | BC-PCK-05 | Grade Submission Validation | 9 fields validated: attempt_id, marks_obtained, max_marks, teacher_remarks, is_published, annotated_pdf, answers_json, question_id, ordinal |
| BC-BIZ-13 | BC-PCK-06 | Percentage Calculation | `percentage = round((obtained / max) * 100, 2)` |
| BC-BIZ-14 | BC-PCK-07 | Grade Letter via calculateGrade() | ≥91=A1, ≥81=A2, ≥71=B1, ≥61=B2, ≥51=C1, ≥41=C2, ≥33=D, <33=E |
| BC-BIZ-15 | BC-PCK-08 | Pass/Fail = percentage ≥ passing_percentage | Quest's `passing_percentage` field; default 33% if null |
| BC-BIZ-16 | BC-PCK-09 | Result Upsert on attempt_id+assessment_type+assessment_id | `updateOrCreate` on composite key |
| BC-BIZ-17 | BC-PCK-10 | Answer Sync via answers_json | `updateOrCreate` on (attempt_id, question_id) with marks/status/remarks |
| BC-BIZ-18 | BC-PCK-11 | Annotated PDF Upload | File stored via `LmsStorageService::storeFile()` in dynamic path; URL returned in response |
| BC-BIZ-19 | BC-PCK-12 | Event Dispatch on Publish | `QuizQuestResultPublished::dispatch($result)` when is_published=true |
| BC-BIZ-20 | BC-PCK-13 | saveAnswerGrade Permission | Uses `tenant.quest-question.update` (known inconsistency) |
| BC-BIZ-21 | BC-PCK-14 | Individual Question Grading | `saveAnswerGrade` resolves question by `question_id` or `ordinal`; validates marks ≤ max |
| BC-BIZ-22 | BC-PCK-15 | Attempt Update on saveAnswerGrade | Recalculates total_obtained from all answer marks, updates percentage and is_passed on attempt and result |
| BC-BIZ-36 | BC-PCK-16 | Attachments Only for Attemptors | `getStudentQuestionsWithAttachments` returns questions only for students who have attempted (no attempt → error) |
| BC-BIZ-37 | BC-PCK-17 | Attachment Filter = Non-null attachment_data | Only answers with `attachment_data IS NOT NULL` returned |
| BC-BIZ-38 | BC-PCK-18 | Media URL Resolved by Numeric ID | `getMediaUrl` uses Spatie Media `find(id)` with fallback error |

### Performance Report Business Logic

| BC-BIZ ID | Original BC ID | Rule | Description |
|-----------|----------------|------|-------------|
| BC-BIZ-23 | BC-RPT-01 | Students Deduplicated Across Allocations | `array_unique()` on student IDs from all allocation types |
| BC-BIZ-24 | BC-RPT-02 | Student Resolution per Allocation Type | SECTION→StudentAcademicSession; CLASS→all sections→StudentAcademicSession; STUDENT→single; GROUP→EntityGroupMember |
| BC-BIZ-25 | BC-RPT-03 | Status Counts Per Student | NOT_STARTED (no attempt), IN_PROGRESS (latest=IN_PROGRESS), SUBMITTED (latest in SUBMITTED/EVALUATED/RESULT_PUBLISHED/TIMEOUT) |
| BC-BIZ-26 | BC-RPT-04 | Average Score from Results | `QuizQuestResult::where('assessment_id', $quest_id)->avg('percentage')` |
| BC-BIZ-27 | BC-RPT-05 | Score Bins from Results | Same 5-bin distribution as dashboard |
| BC-BIZ-28 | BC-RPT-06 | Student Search | Filters by `student.first_name`, `last_name`, `admission_no` LIKE |
| BC-BIZ-29 | BC-RPT-07 | Pagination = 25 | Manual `LengthAwarePaginator` with 25 per page |
| BC-BIZ-30 | BC-RPT-08 | Latest Session per Student | Uses `MAX(id)` subquery on `std_student_academic_sessions` to get latest session |

### Attempt Detail Business Logic

| BC-BIZ ID | Original BC ID | Rule | Description |
|-----------|----------------|------|-------------|
| BC-BIZ-31 | BC-ADT-01 | Result Prepared Only When Not IN_PROGRESS | If attempt status is IN_PROGRESS, result data is null |
| BC-BIZ-32 | BC-ADT-02 | Correct/Wrong Counts from Answers | `is_correct=1` → correct_count; `is_correct=0 AND selected_option_id>0` → wrong_count |
| BC-BIZ-33 | BC-ADT-03 | File Resolution Priority | attachment_data (JSON) → Spatie MediaLibrary → legacy attachment_id → annotated PDF |
| BC-BIZ-34 | BC-ADT-04 | Time Taken Formatted | `gmdate("H:i:s", $time_taken_seconds)` or '—' if null |
| BC-BIZ-35 | BC-ADT-05 | Questions Include Options and Explanation | Each question returns options array and teacher_explanation |
| BC-BIZ-36 | BC-ADT-06 | Fallback Quest Lookup | If attempt->quest relation fails, fallback to Quest::find(attempt->quest_id) |

---

## 8. Referential Integrity (BC-REF)

| FK Name | Source Table | Source Column | Target Table | Target Column | On Delete |
|---------|-------------|---------------|--------------|---------------|-----------|
| fk_quest_academic_session | lms_quests | academic_session_id | glb_academic_sessions | id | CASCADE |
| fk_quest_class | lms_quests | class_id | sch_classes | id | CASCADE |
| fk_quest_subject | lms_quests | subject_id | sch_subjects | id | CASCADE |
| fk_quest_type | lms_quests | quest_type_id | lms_assessment_types | id | CASCADE |
| fk_quest_diff | lms_quests | difficulty_config_id | lms_difficulty_distribution_configs | id | SET NULL |
| fk_quest_creator | lms_quests | created_by | sys_users | id | SET NULL |
| fk_qs_quest | lms_quest_scopes | quest_id | lms_quests | id | CASCADE |
| fk_qs_topic | lms_quest_scopes | topic_id | slb_topics | id | CASCADE |
| fk_qs_lesson | lms_quest_scopes | lesson_id | slb_lessons | id | CASCADE |
| fk_qst_q_quest | lms_quest_questions | quest_id | lms_quests | id | CASCADE |
| fk_qst_q_question | lms_quest_questions | question_id | qns_questions_bank | id | CASCADE |
| fk_qsta_quest | lms_quest_allocations | quest_id | lms_quests | id | CASCADE |
| fk_qsta_assigner | lms_quest_allocations | assigned_by | sys_users | id | SET NULL |
| (implicit) | lms_quiz_quest_attempts | quest_allocation_id | lms_quest_allocations | id | CASCADE (via model) |
| (implicit) | lms_quiz_quest_attempt_answers | attempt_id | lms_quiz_quest_attempts | id | CASCADE (via model) |
| (implicit) | lms_quiz_quest_attempt_answers | evaluated_by | sys_users | id | SET NULL |
| (implicit) | lms_quiz_quest_results | attempt_id | lms_quiz_quest_attempts | id | CASCADE (via model) |

---

## 9. Test Case Summary

### 9.1 Summary Grid TC Summary

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-SUM-P01 | Summary Grid | Positive | Summary grid loads with per-allocation counts | 11 |
| TC-SUM-P02 | Summary Grid | Positive | Assigned count resolved for SECTION type | 5 |
| TC-SUM-P03 | Summary Grid | Positive | Assigned count = 1 for STUDENT type | 3 |
| TC-SUM-P04 | Summary Grid | Positive | SECTION filter OR conditions | 8 |
| TC-SUM-P05 | Summary Grid | Positive | Subject filter | 4 |
| TC-SUM-P06 | Summary Grid | Positive | Date range filter | 3 |
| TC-SUM-P07 | Summary Grid | Positive | Search by quest title/code | 7 |
| TC-SUM-P08 | Summary Grid | Positive | Pagination (10 per page) | 4 |
| TC-SUM-N01 | Summary Grid | Negative | No allocations exist | 3 |
| TC-SUM-N02 | Summary Grid | Negative | Invalid search returns empty | 2 |

### 9.2 Paper Check TC Summary

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-PCK-P01 | Paper Check | Positive | Paper Check page loads with quest data and student list | 8 |
| TC-PCK-P02 | Paper Check | Positive | getStudentAttemptData — Load student attempt with answers | 8 |
| TC-PCK-P03 | Paper Check | Positive | getStudentAttemptData — No attempt returns error | 3 |
| TC-PCK-P04 | Paper Check | Positive | gradeSubmission — Grade and publish entire submission | 9 |
| TC-PCK-P05 | Paper Check | Positive | gradeSubmission — Grade without publishing | 5 |
| TC-PCK-P06 | Paper Check | Positive | gradeSubmission — Fail when percentage below passing threshold | 6 |
| TC-PCK-P07 | Paper Check | Positive | gradeSubmission — Grade letter mapping (all tiers) | 16 |
| TC-PCK-P08 | Paper Check | Positive | gradeSubmission — Sync answers via answers_json | 6 |
| TC-PCK-P09 | Paper Check | Positive | gradeSubmission — Annotated PDF upload | 5 |
| TC-PCK-P10 | Paper Check | Positive | saveAnswerGrade — Grade single question (AJAX) | 6 |
| TC-PCK-P11 | Paper Check | Positive | saveAnswerGrade — Resolves question by question_id | 2 |
| TC-PCK-P12 | Paper Check | Positive | saveAnswerGrade — Marks ≤ max marks validation | 3 |
| TC-PCK-P13 | Paper Check | Positive | gradeSubmission — Teacher remarks (max 2000 chars) | 4 |
| TC-PCK-P14 | Paper Check | Positive | gradeSubmission — Result upsert (update existing result) | 3 |
| TC-PCK-P15 | Paper Check | Positive | getStudentAttemptData — Returns file_url for answers with attachments | 3 |
| TC-PCK-P16 | Paper Check | Positive | getStudentQuestionsWithAttachments — Returns questions with file attachments | 6 |
| TC-PCK-P17 | Paper Check | Positive | getMediaUrl — Returns media URL by numeric ID | 3 |
| TC-PCK-N01 | Paper Check | Negative | gradeSubmission — Missing required fields | 3 |
| TC-PCK-N02 | Paper Check | Negative | gradeSubmission — Invalid attempt_id | 2 |
| TC-PCK-N03 | Paper Check | Negative | gradeSubmission — Negative marks_obtained | 1 |
| TC-PCK-N04 | Paper Check | Negative | gradeSubmission — Annotated PDF too large | 1 |
| TC-PCK-N05 | Paper Check | Negative | gradeSubmission — Annotated PDF wrong type | 1 |
| TC-PCK-N06 | Paper Check | Negative | saveAnswerGrade — Marks exceed max marks | 4 |
| TC-PCK-N07 | Paper Check | Negative | saveAnswerGrade — Invalid attempt_id | 1 |
| TC-PCK-N08 | Paper Check | Negative | saveAnswerGrade — Negative marks | 1 |
| TC-PCK-N09 | Paper Check | Negative | Permission — gradeSubmission without tenant.quest.update | 2 |
| TC-PCK-N10 | Paper Check | Negative | Permission — Paper Check view without tenant.quest.viewAny | 2 |
| TC-PCK-N11 | Paper Check | Negative | Permission — Summary view without tenant.quest.viewAny | 2 |
| TC-PCK-N12 | Paper Check | Negative | saveAnswerGrade permission uses wrong namespace | 2 |
| TC-PCK-N13 | Paper Check | Negative | getStudentQuestionsWithAttachments — No attempt found | 3 |
| TC-PCK-N14 | Paper Check | Negative | getMediaUrl — Invalid media ID | 3 |

### 9.3 Performance Report TC Summary

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-RPT-P01 | Performance Report | Positive | Performance report loads with all students and stats | 8 |
| TC-RPT-P02 | Performance Report | Positive | Students deduplicated across allocations | 3 |
| TC-RPT-P03 | Performance Report | Positive | Student search | 5 |
| TC-RPT-P04 | Performance Report | Positive | Pagination (25 per page) | 3 |
| TC-RPT-N01 | Performance Report | Negative | No quest found | 1 |
| TC-RPT-N02 | Performance Report | Negative | No allocations for quest | 3 |

### 9.4 Attempt Detail TC Summary

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-ADT-P01 | Attempt Detail | Positive | Attempt detail page for submitted/evaluated attempt | 12 |
| TC-ADT-P02 | Attempt Detail | Positive | Attempt detail for IN_PROGRESS attempt | 3 |
| TC-ADT-P03 | Attempt Detail | Positive | File resolution (attachment_data JSON) | 3 |
| TC-ADT-P04 | Attempt Detail | Positive | No attempt found falls back to Quest::find | 3 |
| TC-ADT-N01 | Attempt Detail | Negative | Invalid attempt_id | 1 |

### 9.5 Code Review & Dependency TC Summary

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-CR06 | Code Review | Review | questSummary index() — Assigned count calculation | 4 |
| TC-CR07 | Code Review | Review | questSummary index() — Checked count definition | 2 |
| TC-CR08 | Code Review | Review | gradeSubmission() — Full grading flow | 8 |
| TC-CR09 | Code Review | Review | gradeSubmission() — Annotated PDF upload flow | 5 |
| TC-CR10 | Code Review | Review | saveAnswerGrade() — Single question grading flow | 8 |
| TC-CR11 | Code Review | Review | report() — Student aggregation across allocation types | 5 |
| TC-CR12 | Code Review | Review | report() — Status count logic | 3 |
| TC-CR13 | Code Review | Review | attemptDetail() — Result data structure | 4 |
| TC-CR14 | Code Review | Review | attemptDetail() — Multi-source file resolution | 5 |
| TC-CR18 | Code Review | Review | questPaperCheck() — Page load queries | 3 |
| TC-CR19 | Code Review | Review | getStudentAttemptData() — Data structure | 4 |
| TC-CR20 | Code Review | Review | getStudentQuestionsWithAttachments() — Attachments query and response | 6 |
| TC-CR25 | Code Review | Review | getMediaUrl() — Media resolution logic | 4 |
| TC-D02 | Dependency | Dependency | Summary checked_count vs Paper Check evaluation | 3 |
| TC-D05 | Dependency | Dependency | Result publish cascades to Recommendation event | 4 |
| TC-D06 | Dependency | Dependency | gradeSubmission with answers_json syncs per-question marks | 3 |
| TC-D07 | Dependency | Dependency | In-progress attempt can be graded (no guard) | 3 |

---

## 10. Test Data Strategy

- **Unique Suffix**: Use `now()->format('His') . random_int(100, 999)` for test data uniqueness
- **Summary Tests**: Require allocations of all three types (CLASS, SECTION, STUDENT) with varying attempt statuses
- **Paper Check Tests**: Require a Quest with at least one question, one allocation, and one student attempt with answers (both MCQ and descriptive)
- **Performance Report Tests**: Require a Quest with multiple allocations of different types to test student deduplication
- **Attempt Detail Tests**: Require a submitted/evaluated attempt with answers (MCQ selected_option_id, descriptive answer_text, file attachments)
- **Grade Letter Mapping**: `calculateGrade()` maps percentage→letter: ≥91=A1, ≥81=A2, ≥71=B1, ≥61=B2, ≥51=C1, ≥41=C2, ≥33=D, <33=E
- **Pass/Fail Threshold**: Quest's `passing_percentage` field (default 33%)
- **Score Bins**: 0–20, 21–40, 41–60, 61–80, 81–100

---

## 11. Test Case Steps

### 11.1 Positive TC Steps — Summary Grid

#### TC-SUM-P01: Summary grid loads with per-allocation counts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with Subject=S1, Class=C1 | Quest exists |
| 2 | Create Allocation A1 (TYPE=CLASS, target=C1) for Q1 | Allocation exists |
| 3 | Enroll 5 students in Class C1 (via is_current=1) | Students exist |
| 4 | Create attempts: 2 SUBMITTED, 1 IN_PROGRESS, 1 EVALUATED for Q1 | Attempts exist |
| 5 | Create answer evaluation for 2 attempts (evaluated_by set) | 2 checked |
| 6 | Load Summary tab (`active_tab=quest_summary`) | Summary loads |
| 7 | Verify A1 row shows: quest title, subject name, assigner name | Fields displayed |
| 8 | Verify assigned_count = 5 (students in class) | Assigned count correct |
| 9 | Verify submitted_count = 4 (2 SUBMITTED + 1 EVALUATED + 0 TIMEOUT + 1 more) | Submitted count correct |
| 10 | Verify in_progress_count = 1 | In progress correct |
| 11 | Verify checked_count = 2 (attempts with evaluated answers) | Checked count correct |

---

#### TC-SUM-P02: Summary — Assigned count resolved for SECTION type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Class C1, Section SecA (belongs to C1) | Class+Section exist |
| 2 | Create Allocation A1 (TYPE=SECTION, target=SecA) | Allocation exists |
| 3 | Enroll 3 students in SecA (is_current=1) | Students exist |
| 4 | Load Summary tab | Page loads |
| 5 | Verify A1.assigned_count = 3 | Section count correct |

---

#### TC-SUM-P03: Summary — Assigned count = 1 for STUDENT type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Allocation A1 (TYPE=STUDENT, target=S1) | Allocation exists |
| 2 | Load Summary tab | Page loads |
| 3 | Verify A1.assigned_count = 1 | Single student correct |

---

#### TC-SUM-P04: Summary — SECTION filter OR conditions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Class C1, Section SecA | C1, SecA exist |
| 2 | Create Quest Q1 (class=C1) | Quest exists |
| 3 | Allocations: A1(TYPE=SECTION, target=SecA), A2(TYPE=CLASS, target=C1), A3(TYPE=STUDENT, target=S1 where S1 in SecA) | 3 allocations |
| 4 | Load Summary with `class_section_id=SecA` | Summary loads |
| 5 | Verify A1 included | SECTION match |
| 6 | Verify A2 included | CLASS match |
| 7 | Verify A3 included | STUDENT match |
| 8 | Verify other allocations excluded | No unrelated rows |

---

#### TC-SUM-P05: Summary — Subject filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 in Subject=S1, Quest Q2 in Subject=S2 | Quests exist |
| 2 | Allocation A1→Q1, A2→Q2 | Allocations exist |
| 3 | Load Summary with `subject_id=S1` | Summary loads |
| 4 | Verify A1 shown, A2 not shown | Filter applied |

---

#### TC-SUM-P06: Summary — Date range filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Allocation A1 published 10 days ago, A2 published 2 days ago | Allocations exist |
| 2 | Load Summary with `date_from=5_days_ago&date_to=today` | Page loads |
| 3 | Verify A2 shown, A1 not shown | Date filter applied |

---

#### TC-SUM-P07: Summary — Search by quest title/code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 title="Physics Challenge", quest_code="QUEST_PHY_001" | Quest exists |
| 2 | Quest Q2 title="Math Quest", quest_code="QUEST_MATH_001" | Quest exists |
| 3 | Allocations A1→Q1, A2→Q2 | Allocations exist |
| 4 | Load Summary with `search=Physics` | Summary loads |
| 5 | Verify A1 shown, A2 not shown | Search by title works |
| 6 | Load Summary with `search=QUEST_PHY` | Summary loads |
| 7 | Verify A1 shown | Search by code works |

---

#### TC-SUM-P08: Summary — Pagination (10 per page)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 12 allocations | 12 allocations exist |
| 2 | Load Summary tab | Page 1 loads |
| 3 | Verify 10 allocations on page 1 | Page size correct |
| 4 | Click page 2 or add `&summary_page=2` | Remaining 2 allocations shown |

---

### 11.2 Positive TC Steps — Paper Check

#### TC-PCK-P01: Paper Check page loads with quest data and student list

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with 3 questions (ordinals 1,2,3) | Quest with questions |
| 2 | Create Allocation A1 (TYPE=CLASS, target=C1) with 2 students enrolled | Allocation exists |
| 3 | Create attempts: Student S1 (SUBMITTED), Student S2 (IN_PROGRESS) | Attempts exist |
| 4 | Open Paper Check: GET `/lms-quests/quest/{Q1}/paper-check` | Page loads |
| 5 | Verify quest title, subject, class displayed | Quest info shown |
| 6 | Verify 3 questions displayed with ordinals | Questions listed |
| 7 | Verify 2 students in list: S1 and S2 | All attempts shown |
| 8 | Verify results keyed by attempt_id | Result data available |

---

#### TC-PCK-P02: getStudentAttemptData — Load student attempt with answers (AJAX)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 with 2 questions (Qa marks=5, Qb marks=10) | Questions exist |
| 2 | Student S1 has attempt A1 (SUBMITTED, score=0, max=15) | Attempt exists |
| 3 | Answers: Qa → marks_obtained=0, Qb → marks_obtained=0 | Answers exist |
| 4 | Send AJAX GET to getStudentAttemptData: quest_id=Q1, student_id=S1 | AJAX call |
| 5 | Verify response.success = true | Success |
| 6 | Verify attempt.id = A1, attempt.status = SUBMITTED | Attempt data correct |
| 7 | Verify answers array has 2 entries | All questions returned |
| 8 | Verify each answer has: question_id, question_text, marks_obtained, marks_max, ordinal | Answer fields present |

---

#### TC-PCK-P03: getStudentAttemptData — No attempt returns error

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student S3 has no attempt for Quest Q1 | No attempt |
| 2 | Send AJAX GET: quest_id=Q1, student_id=S3 | AJAX call |
| 3 | Verify response.success = false, message = "No attempt found." | Error returned |

---

#### TC-PCK-P04: gradeSubmission — Grade and publish entire submission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1: total_marks=100, passing_percentage=40 | Quest configured |
| 2 | Attempt A1: SUBMITTED, student=S1 | Attempt exists |
| 3 | AJAX POST gradeSubmission: quest_id=Q1, attempt_id=A1, marks_obtained=75, max_marks=100, is_published=true | AJAX call |
| 4 | Verify response.success = true | Grading succeeded |
| 5 | Verify response.percentage = 75.00 | Percentage correct |
| 6 | Verify response.is_passed = true (75 ≥ 40) | Passed |
| 7 | DB check: QuizQuestAttempt A1.percentage = 75.00, is_passed=true | Attempt updated |
| 8 | DB check: QuizQuestResult exists for A1: total_marks_obtained=75, max_marks=100, percentage=75.00, grade_obtained='B1' (≥71), is_passed=true, is_published=true, published_at not null | Result upserted |
| 9 | DB check: QuizQuestResultPublished event was dispatched | Event dispatched |

---

#### TC-PCK-P05: gradeSubmission — Grade without publishing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt A1: SUBMITTED, student=S1 | Attempt exists |
| 2 | AJAX POST gradeSubmission: attempt_id=A1, marks_obtained=45, max_marks=100, is_published=false | AJAX call |
| 3 | Verify response.success = true, percentage = 45.00 | Success |
| 4 | DB check: QuizQuestResult.is_published = false, published_at = null | Not published |
| 5 | DB check: QuizQuestResultPublished event NOT dispatched | No event |

---

#### TC-PCK-P06: gradeSubmission — Fail when percentage below passing threshold

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1: passing_percentage=40 | Threshold=40% |
| 2 | Attempt A1: SUBMITTED | Attempt exists |
| 3 | AJAX POST gradeSubmission: marks_obtained=25, max_marks=100 | AJAX call |
| 4 | Verify response.percentage = 25.00 | Percentage correct |
| 5 | Verify response.is_passed = false (25 < 40) | Failed |
| 6 | DB check: QuizQuestResult.is_passed = false | Result reflects fail |

---

#### TC-PCK-P07: gradeSubmission — Grade letter mapping (all tiers)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Grade submission with marks_obtained=95/100 (95%) | Grade=A1 |
| 2 | DB check: grade_obtained='A1' | ≥91 |
| 3 | Grade submission with marks_obtained=85/100 (85%) | Grade=A2 |
| 4 | DB check: grade_obtained='A2' | ≥81 |
| 5 | Grade submission with marks_obtained=75/100 (75%) | Grade=B1 |
| 6 | DB check: grade_obtained='B1' | ≥71 |
| 7 | Grade submission with marks_obtained=65/100 (65%) | Grade=B2 |
| 8 | DB check: grade_obtained='B2' | ≥61 |
| 9 | Grade submission with marks_obtained=55/100 (55%) | Grade=C1 |
| 10 | DB check: grade_obtained='C1' | ≥51 |
| 11 | Grade submission with marks_obtained=45/100 (45%) | Grade=C2 |
| 12 | DB check: grade_obtained='C2' | ≥41 |
| 13 | Grade submission with marks_obtained=35/100 (35%) | Grade=D |
| 14 | DB check: grade_obtained='D' | ≥33 |
| 15 | Grade submission with marks_obtained=20/100 (20%) | Grade=E |
| 16 | DB check: grade_obtained='E' | <33 |

---

#### TC-PCK-P08: gradeSubmission — Sync answers via answers_json

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 with 2 questions: Qa(max=5), Qb(max=10) | Questions exist |
| 2 | Attempt A1 has answer records for Qa, Qb | Answers exist |
| 3 | AJAX POST gradeSubmission with answers_json: `[{"id": Qa, "awardedMarks": 4, "maxMarks": 5, "status": "correct", "comment": "Good"}, {"id": Qb, "awardedMarks": 8, "maxMarks": 10, "status": "partial", "comment": "Almost"}]` | AJAX call |
| 4 | DB check: QuizQuestAttemptAnswer for Qa: marks_obtained=4, is_evaluated=true, evaluated_by=current_user, evaluation_remarks="Good" | Qa synced |
| 5 | DB check: QuizQuestAttemptAnswer for Qb: marks_obtained=8, is_evaluated=true, evaluated_by=current_user, evaluation_remarks="Almost" | Qb synced |
| 6 | Verify total marks in response = 12 (4+8) | Marks sum matches |

---

#### TC-PCK-P09: gradeSubmission — Annotated PDF upload

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1, Attempt A1, Question Qa | Preconditions met |
| 2 | AJAX POST gradeSubmission with annotated_pdf (valid PDF file, < 50MB) | AJAX call |
| 3 | Verify response.success = true | Upload succeeded |
| 4 | Verify response.annotated_pdf_url is not null | URL returned |
| 5 | DB check: QuizQuestAttemptAnswer has attachment_data populated with file info | File stored |

---

#### TC-PCK-P10: saveAnswerGrade — Grade single question (AJAX)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1, QuestQuestion QQ1 (ordinal=1, question=Qa, marks_override=5) | Question exists |
| 2 | Attempt A1, existing answer for Qa with marks=0 | Answer exists |
| 3 | AJAX POST saveAnswerGrade: quest_id=Q1, attempt_id=A1, ordinal=1, marks_obtained=4, evaluation_remarks="Good work" | AJAX call |
| 4 | Verify response.success = true | Saved |
| 5 | DB check: QuizQuestAttemptAnswer for (attempt=A1, question=Qa): marks_obtained=4, is_evaluated=true, evaluated_by set, evaluation_remarks="Good work" | Answer graded |
| 6 | DB check: Attempt A1 percentage recalculated (total_obtained / max) | Attempt updated |

---

#### TC-PCK-P11: saveAnswerGrade — Resolves question by question_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | AJAX POST saveAnswerGrade with question_id=Qa (instead of ordinal) | AJAX call |
| 2 | Verify same question resolved by question_id | Correct resolution |

---

#### TC-PCK-P12: saveAnswerGrade — Marks ≤ max marks validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | QuestQuestion: ordinal=1, max_marks=5 | Max=5 |
| 2 | AJAX POST: ordinal=1, marks_obtained=7 (>5) | Exceeds max |
| 3 | Verify response: success=false, status=422, message="Marks cannot exceed max marks for this question." | Validation error |

---

#### TC-PCK-P13: gradeSubmission — Teacher remarks (max 2000 chars)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | AJAX POST gradeSubmission with teacher_remarks = "Excellent work! Keep it up." | Remarks sent |
| 2 | DB check: QuizQuestResult.teacher_remarks = "Excellent work! Keep it up." | Stored |
| 3 | AJAX POST with teacher_remarks = null | Null remarks |
| 4 | DB check: teacher_remarks = null (or existing cleared) | Handles null |

---

#### TC-PCK-P14: gradeSubmission — Result upsert (update existing result)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | QuizQuestResult already exists for attempt A1 (is_published=false, percentage=50) | Existing result |
| 2 | AJAX POST gradeSubmission: marks_obtained=80, max_marks=100, is_published=true | Update call |
| 3 | DB check: Same result record updated (not duplicated): percentage=80, is_published=true | Upsert correct |

---

#### TC-PCK-P15: getStudentAttemptData — Returns file_url for answers with attachments

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student answer has attachment_data JSON with file info | Attachment exists |
| 2 | Send AJAX GET to getStudentAttemptData | AJAX call |
| 3 | Verify answer.file_url is not null for that question | URL resolved |

---

#### TC-PCK-P16: getStudentQuestionsWithAttachments — Returns questions with file attachments

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student S1 has attempt A1 with 2 answers: Qa (attachment_data set), Qb (attachment_data null) | Mixed attachments |
| 2 | AJAX GET `/lms-quests/quest/{Q1}/get-student-questions-with-attachments?student_id={S1}` | AJAX call |
| 3 | Verify `success=true`, `attempt_id=A1` | Request succeeds |
| 4 | Verify only Qa returned (Qb excluded — has no attachment_data) | Correct filter |
| 5 | Verify Qa response: question_id, ordinal, marks_obtained, max_marks, file_url | Full data |
| 6 | Verify `file_url` is resolved URL (not null) | URL resolved |

---

#### TC-PCK-P17: getMediaUrl — Returns media URL by numeric ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Media record exists with id=101, file_name='answer.pdf' | Media exists |
| 2 | AJAX GET `/lms-quests/quest/{Q1}/media/101` | AJAX call |
| 3 | Verify `success=true`, `url` is non-empty string, `name='answer.pdf'` | Full media data |

---

### 11.3 Positive TC Steps — Performance Report

#### TC-RPT-P01: Performance report loads with all students and stats

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 with 2 allocations: A1(TYPE=CLASS→C1, 3 students), A2(TYPE=STUDENT→S4) | Allocations exist |
| 2 | Attempts: S1→SUBMITTED(evaluated, 75%), S2→IN_PROGRESS, S3→no attempt, S4→SUBMITTED(evaluated, 45%) | Attempts/Results exist |
| 3 | GET `/lms-quests/quest/{Q1}/report` | Report loads |
| 4 | Verify totalStudents = 4 (3 from C1 + 1 individual) | Count correct |
| 5 | Verify statusCounts: NOT_STARTED=1 (S3), IN_PROGRESS=1 (S2), SUBMITTED=2 (S1, S4) | Status counts match |
| 6 | Verify averageScore = 60.0 ((75+45)/2) | Avg correct |
| 7 | Verify scoreBins: '81-100%'=0, '61-80%'=1, '41-60%'=1, '21-40%'=0, '0-20%'=0 | Bins match |
| 8 | Verify student list includes S1,S2,S3,S4 with attempt status | All students shown |

---

#### TC-RPT-P02: Performance report — Students deduplicated across allocations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | S1 in both A1(TYPE=CLASS→C1) and A2(TYPE=SECTION→SecA where S1 is enrolled) | S1 in 2 allocations |
| 2 | Load report | Report loads |
| 3 | Verify totalStudents includes S1 only once | Deduplicated |

---

#### TC-RPT-P03: Performance report — Student search

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Students: "Rahul Kumar", "Priya Sharma", "Ankit Singh" | Students exist |
| 2 | Load report with `search=Rahul` | Report loads |
| 3 | Verify only Rahul Kumar shown | Search by first_name |
| 4 | Load report with `search=Sharma` | Only Priya shown |
| 5 | Search by admission_no | Works |

---

#### TC-RPT-P04: Performance report — Pagination (25 per page)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest with 30 assigned students | 30 students |
| 2 | Load report | Page 1 with 25 students |
| 3 | Navigate to page 2 | Remaining 5 students |

---

### 11.4 Positive TC Steps — Attempt Detail

#### TC-ADT-P01: Attempt detail page for submitted/evaluated attempt

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 with questions Q1(ord=1, MCQ, marks=5), Q2(ord=2, Descriptive, marks=10) | Questions exist |
| 2 | Attempt A1: SUBMITTED, student=S1, score=12, max=15, percentage=80, is_passed=true, time_taken_seconds=1800, submitted_at=2026-07-15 10:30:00 | Attempt exists |
| 3 | Answer for Q1: selected_option_id=opt1, is_correct=true | MCQ answer |
| 4 | Answer for Q2: answer_text="Great answer", marks_obtained=7, is_correct=true | Descriptive answer |
| 5 | Result: total_marks=12, max=15, percentage=80, is_passed=true | Result exists |
| 6 | GET `/lms-quests/quest/attempt/{A1}/detail` | Detail page loads |
| 7 | Verify quest title, student name displayed | Header info correct |
| 8 | Verify result.is_pass = true, result.percentage = 80, result.attempt_number, result.time_taken = "00:30:00", result.submitted_at = "15 Jul 2026, 10:30 AM", result.marks_obtained = 12, result.total_marks = 15 | Summary correct |
| 9 | Verify result.correct_count = 2, result.wrong_count = 0 | Counts correct |
| 10 | Verify questions array has 2 entries with text, type, marks, options, explanation | Questions complete |
| 11 | Verify descriptiveAnswers[Q1].selected_option_id = opt1, is_correct=true | MCQ answer shown |
| 12 | Verify descriptiveAnswers[Q2].answer_text = "Great answer", marks_obtained=7, is_correct=true | Descriptive answer shown |

---

#### TC-ADT-P02: Attempt detail for IN_PROGRESS attempt

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt A1: IN_PROGRESS, no submitted_at | In-progress |
| 2 | GET attempt detail | Page loads |
| 3 | Verify result = null (no result data for in-progress) | Result null |

---

#### TC-ADT-P03: Attempt detail — File resolution (attachment_data JSON)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Answer for Q2 has attachment_data = `{"file_name":"essay.pdf","file_path":"...","url":"..."}` | JSON file |
| 2 | GET attempt detail | Page loads |
| 3 | Verify descriptiveAnswers[Q2].files has 1 entry with name="essay.pdf", url resolved | File shown |

---

#### TC-ADT-P04: Attempt detail — No attempt found falls back to Quest::find

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt has quest_id set but no quest() relation loaded | Relation fails |
| 2 | GET attempt detail | Fallback: Quest::find(attempt->quest_id) used |
| 3 | Verify page loads without 404 | Fallback works |

---

### 11.5 Negative TC Steps

#### TC-SUM-N01: Summary — No allocations exist

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No allocations in database | Empty |
| 2 | Load Summary tab | Empty grid, no error |
| 3 | Verify pagination shows 0 results | Empty state |

---

#### TC-SUM-N02: Summary — Invalid search returns empty

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search with `search=NonExistentQuestXYZ` | No match |
| 2 | Verify empty grid | No results |

---

#### TC-PCK-N01: gradeSubmission — Missing required fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | AJAX POST gradeSubmission without attempt_id | Validation error |
| 2 | AJAX POST gradeSubmission without marks_obtained | Validation error |
| 3 | AJAX POST gradeSubmission without max_marks | Validation error |

---

#### TC-PCK-N02: gradeSubmission — Invalid attempt_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | AJAX POST gradeSubmission with attempt_id=99999 | 404 (findOrFail) |
| 2 | Verify response error: ModelNotFoundException or 404 | Not found |

---

#### TC-PCK-N03: gradeSubmission — Negative marks_obtained

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | AJAX POST gradeSubmission with marks_obtained=-5 | Validation error (min:0) |

---

#### TC-PCK-N04: gradeSubmission — Annotated PDF too large

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | AJAX POST gradeSubmission with annotated_pdf > 51200 KB (>50MB) | Validation error: "The annotated pdf must not be greater than 51200 kilobytes." |

---

#### TC-PCK-N05: gradeSubmission — Annotated PDF wrong type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | AJAX POST gradeSubmission with non-PDF file (e.g., .jpg) | Validation error: "The annotated pdf must be a file of type: pdf." |

---

#### TC-PCK-N06: saveAnswerGrade — Marks exceed max marks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | QuestQuestion: max_marks=5 | Max=5 |
| 2 | AJAX POST saveAnswerGrade: marks_obtained=7 | 7 > 5 |
| 3 | Verify 422 response: "Marks cannot exceed max marks for this question." | Rejected |
| 4 | DB check: marks_obtained NOT updated | Record unchanged |

---

#### TC-PCK-N07: saveAnswerGrade — Invalid attempt_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | AJAX POST saveAnswerGrade with attempt_id=99999 | Validation error: "The selected attempt id is invalid." |

---

#### TC-PCK-N08: saveAnswerGrade — Negative marks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | AJAX POST saveAnswerGrade with marks_obtained=-1 | Validation error (min:0) |

---

#### TC-PCK-N09: Permission — gradeSubmission without tenant.quest.update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.quest.update` permission | Authenticated |
| 2 | AJAX POST gradeSubmission | 403 Forbidden |

---

#### TC-PCK-N10: Permission — Paper Check view without tenant.quest.viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.quest.viewAny` permission | Authenticated |
| 2 | GET `/lms-quests/quest/{Q1}/paper-check` | 403 Forbidden |

---

#### TC-PCK-N11: Permission — Summary view without tenant.quest.viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.quest.viewAny` permission | Authenticated |
| 2 | GET `/lms-quests/quest` | 403 Forbidden |

---

#### TC-PCK-N12: saveAnswerGrade permission uses wrong namespace (known inconsistency)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.quest.update` but WITHOUT `tenant.quest-question.update` | 403 Forbidden (known gap — should use tenant.quest.update) |
| 2 | User with `tenant.quest-question.update` | Succeeds |

---

#### TC-PCK-N13: getStudentQuestionsWithAttachments — No attempt found

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student S99 has no attempt for quest Q1 | No attempt |
| 2 | AJAX GET `/lms-quests/quest/{Q1}/get-student-questions-with-attachments?student_id={S99}` | AJAX call |
| 3 | Verify `success=false`, `message='No attempt found.'` | Error response |

---

#### TC-PCK-N14: getMediaUrl — Invalid media ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Media ID 99999 does not exist | No media |
| 2 | AJAX GET `/lms-quests/quest/{Q1}/media/99999` | AJAX call |
| 3 | Verify `success=false`, `message='Media not found or invalid format.'` | Error response |

---

#### TC-RPT-N01: Report — No quest found

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/lms-quests/quest/99999/report` | 404 |

---

#### TC-RPT-N02: Report — No allocations for quest

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Quest Q1 with 0 allocations | No allocations |
| 2 | Load report | totalStudents = 0, statusCounts all 0, averageScore = 0 |

---

#### TC-ADT-N01: Attempt detail — Invalid attempt_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/lms-quests/quest/attempt/99999/detail` | 404 |

---

### 11.6 Code Review TC Steps

#### TC-CR06: questSummary index() — Assigned count calculation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review CLASS count: `SchoolClass::withCount(['studentAcademicSessions' => fn=>where('is_current',1)])` | Correct count |
| 2 | Review SECTION count: `ClassSection::withCount(['studentAcademicSessions' => fn=>where('is_current',1)])` | Correct count |
| 3 | Review STUDENT count: returns 1 | Correct |
| 4 | Verify alloc->total_assigned_count set after loop | Set on allocation objects |

---

#### TC-CR07: questSummary index() — Checked count definition

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review checked_count withCount | `whereHas('answers', fn=>whereNotNull('evaluated_by'))` |
| 2 | Verify ANY answer evaluated = checked | Correct — partial grading counts as checked |

---

#### TC-CR08: gradeSubmission() — Full grading flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review marks validation | `$obtained = (float)$validated['marks_obtained']`, `$max = (float)$validated['max_marks']` |
| 2 | Review percentage calculation | `$max>0 ? round(($obtained/$max)*100,2) : 0` |
| 3 | Review grade letter | `$this->calculateGrade($percentage)` |
| 4 | Review pass/fail | `$percentage >= (float)($quest->passing_percentage ?? 33)` |
| 5 | Review attempt update | `score_obtained`, `max_score`, `percentage`, `is_passed`, `teacher_feedback` |
| 6 | Review result upsert | `updateOrCreate` on (attempt_id, assessment_type, assessment_id) |
| 7 | Review answers_json sync | Loops through decoded array, `updateOrCreate` on (attempt_id, question_id) |
| 8 | Review event dispatch | Conditional on `$isPublished` |

---

#### TC-CR09: gradeSubmission() — Annotated PDF upload flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review file upload detection | `$request->hasFile('annotated_pdf') && $request->file('annotated_pdf')->isValid()` |
| 2 | Review answer query | `QuizQuestAttemptAnswer::where('attempt_id', ...)` optionally filtered by question_id |
| 3 | Review path building | `$this->storageService->buildPath('lms_quest_upload_path', $pathParams)` |
| 4 | Review file storage | `$this->storageService->storeFile($request->file('annotated_pdf'), $targetFolder)` |
| 5 | Review URL generation | `$this->storageService->getFileUrl($fileInfo)` returned in response |

---

#### TC-CR10: saveAnswerGrade() — Single question grading flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review question resolution | By question_id or ordinal (whichever provided) |
| 2 | Review max_marks resolution | `marks_override ?? question->marks ?? 0` |
| 3 | Review marks validation | `if ($maxAllowed > 0 && $marksObtained > $maxAllowed)` → reject 422 |
| 4 | Review answer upsert | `updateOrCreate` on (attempt_id, question_id) |
| 5 | Review totals recalculation | `QuizQuestAttemptAnswer::where('attempt_id', $id)->sum('marks_obtained')` |
| 6 | Review max_score fallback | `attempt->max_score ?? QuestQuestion sum ?? quest->total_marks ?? 100` |
| 7 | Review attempt update | Updates score_obtained, percentage, is_passed |
| 8 | Review result sync | `QuizQuestResult::where('attempt_id', $id)->update(...)` |

---

#### TC-CR11: report() — Student aggregation across allocation types

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review SECTION resolution | `StudentAcademicSession::where('class_section_id', $target_id)` |
| 2 | Review CLASS resolution | `ClassSection::where('class_id')->pluck('id')` then `StudentAcademicSession::whereIn` |
| 3 | Review STUDENT resolution | Direct `$allocation->target_id` |
| 4 | Review GROUP resolution | `EntityGroupMember::where('entity_group_id', $target_id)` |
| 5 | Verify deduplication | `array_unique(array_filter($studentIds))` |

---

#### TC-CR12: report() — Status count logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review NOT_STARTED detection | No attempt found for student_id |
| 2 | Review IN_PROGRESS detection | Latest attempt status = 'IN_PROGRESS' |
| 3 | Review SUBMITTED detection | Latest in ['SUBMITTED','EVALUATED','RESULT_PUBLISHED','TIMEOUT'] |

---

#### TC-CR13: attemptDetail() — Result data structure

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review result gate: `if ($attempt->status !== 'IN_PROGRESS')` | Result only for non-in-progress |
| 2 | Review correct_count / wrong_count | `is_correct=1` → correct; `is_correct=0 AND selected_option_id>0` → wrong |
| 3 | Review time_taken format | `gmdate("H:i:s", (int)$attempt->time_taken_seconds)` |
| 4 | Review submitted_at format | `$attempt->submitted_at->format('d M Y, h:i A')` |

---

#### TC-CR14: attemptDetail() — Multi-source file resolution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review attachment_data (JSON) handling | Parse JSON, iterate files, getFileUrl |
| 2 | Review Spatie MediaLibrary fallback | `getMedia('descriptive_answer_files')` |
| 3 | Review legacy attachment_id fallback | `Modules\Prime\Models\Media::find($ans->attachment_id)` |
| 4 | Review annotated PDF inclusion | `getMedia('annotated_answer_pdf')` |
| 5 | Review deduplication | Checks existing URLs before adding |

---

#### TC-CR18: questPaperCheck() — Page load queries

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review quest load | `Quest::with(['class','subject','questQuestions' => fn=>orderBy('ordinal'), 'questQuestions.question'])->findOrFail($id)` |
| 2 | Review attempts load | `QuizQuestAttempt::with(['student'])->where('assessment_type','QUEST')->where('quest_id',$id)->orderBy('student_id')` |
| 3 | Review results load | `QuizQuestResult::whereIn('attempt_id', $attempts->pluck('id'))->get()->keyBy('attempt_id')` |

---

#### TC-CR19: getStudentAttemptData() — Data structure

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review attempt resolution | Latest attempt for quest+student |
| 2 | Review answer mapping | All quest questions, keyed by question_id for join |
| 3 | Review file URL resolution | `attachment_data` JSON → `storageService->getFileUrl` |
| 4 | Review response structure | `{success, attempt{id,status,score_obtained,...}, result{...}, answer(s)}` |

---

#### TC-CR20: getStudentQuestionsWithAttachments() — Attachments query and response

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review Gate check | `Gate::authorize('tenant.quest.viewAny')` |
| 2 | Review attempt resolution | `QuizQuestAttempt::where('assessment_type','QUEST')->where('quest_id',$questId)->where('student_id',$studentId)->latest()->first()` |
| 3 | Review attachment filter | `QuizQuestAttemptAnswer::where('attempt_id',$attempt->id)->whereNotNull('attachment_data')->get()->keyBy('question_id')` |
| 4 | Review question join | `QuestQuestion::where('quest_id',$questId)->whereIn('question_id',$answers->keys())->orderBy('ordinal')` |
| 5 | Review file URL resolution | `$this->storageService->getFileUrl($data)` from parsed attachment_data JSON |
| 6 | Review response structure | `{success, attempt_id, questions[{question_id, ordinal, marks_obtained, max_marks, file_url}]}` |

---

#### TC-CR25: getMediaUrl() — Media resolution logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review numeric ID detection | `is_numeric($mediaId)` branch |
| 2 | Review Spatie Media query | `$this->mediaModelPath::find($mediaId)` |
| 3 | Review success response | `{success: true, url: ..., name: $media->file_name}` |
| 4 | Review fallback | If media not found → `{success: false, message: 'Media not found or invalid format.'}` |

---

#### TC-CR21: Blade @can Directives

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `tab_module/tab.blade.php` — tab visibility | Tabs wrapped in `@can('tenant.quest.viewAny')`, `@can('tenant.quest-scope.viewAny')`, `@can('tenant.quest-question.viewAny')`, `@can('tenant.quest-allocation.viewAny')`, `@can('tenant.quest-summary.viewAny')`, `@can('tenant.quest-activity-log.viewAny')` |
| 2 | Review `summary/index.blade.php` — action column | `@can('tenant.quest-summary.update')` wraps Report/Check action buttons |
| 3 | Review `quest/index.blade.php` — action buttons | `@can('tenant.quest.status')`, `@canany(['tenant.quest.view', 'tenant.quest.update', 'tenant.quest.delete'])` |
| 4 | Review `quest-allocation/index.blade.php` | `@can('tenant.quest-allocation.status')`, `@canany(['tenant.quest-allocation.view', 'tenant.quest-allocation.update', 'tenant.quest-allocation.delete'])` |
| 5 | Review `quest-question/index.blade.php` | `@can('tenant.quest-question.status')`, `@canany(['tenant.quest-question.view', 'tenant.quest-question.update', 'tenant.quest-question.delete'])` |
| 6 | Review `quest-scope/index.blade.php` | `@can('tenant.quest-scope.status')`, `@canany(['tenant.quest-scope.view', 'tenant.quest-scope.update', 'tenant.quest-scope.delete'])` |

---

#### TC-CR22: Breadcrumb Config

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `tab_module/tab.blade.php` breadcrumb | `<x-backend.components.breadcrum title="Quest Management" :links="[]"/>` — no breadcrumb links for main tab view |
| 2 | Review `summary/report.blade.php` breadcrumb | Links: Quest Index → Summary → Report; URLs: `lms-quests.quest.index` with params |
| 3 | Review `summary/student_result.blade.php` breadcrumb | Links: Quest Summary → Quest Report → Student Result |
| 4 | Review `paper-check/index.blade.php` breadcrumb | Links: Quests → `$quest->title`; URL: `lms-quests.quest.index` |
| 5 | Review `quest/show.blade.php` breadcrumb | Links: Quests → Quest Details |
| 6 | Review all trash views breadcrumb consistency | `quest/trash`, `quest-question/trash`, `quest-allocation/trash`, `quest-scope/trash` all use `{{-- ================= Breadcrumb ================= --}}` pattern |

---

#### TC-CR23: View isset()/null-safe checks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `summary/index.blade.php` null safety | `$allocation->quest->title ?? '—'`, `$quest->quest_code ?? '—'`, `$classSectionMap[$allocation->target_id] ?? null`, `$studyFormatMap[$quest->subject_id ?? 0] ?? null` |
| 2 | Review `summary/report.blade.php` null safety | `$quest->class->name ?? '—'`, `$quest->subject->name ?? '—'`, `$quest->allocations->count()` |
| 3 | Review `summary/student_result.blade.php` null safety | `$descriptiveAnswers[$question['id']] ?? null`, `$result['correct_count'] ?? 0`, `$result['wrong_count'] ?? 0` |
| 4 | Review `paper-check/index.blade.php` null safety | `$quest->title ?? 'Paper Check'`, `$quest->class->name ?? 'N/A'`, `$quest->subject->name ?? 'N/A'`, `$quest->duration_minutes ?? '—'` |
| 5 | Verify `student.blade` files use `isset()` or `??` for optional relations | No undefined index/property errors on missing data |

---

#### TC-CR24: View success flash messages

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `LmsQuestController::store()` flash message | `->with('success', flash('created.quest'))` — on quest creation |
| 2 | Review `LmsQuestController::update()` flash message | `->with('success', flash('updated.quest'))` — on quest update |
| 3 | Review `LmsQuestController::destroy()` flash message | `->with('success', flash('trashed.quest'))` — on soft delete |
| 4 | Review `LmsQuestController::restore()` flash message | `->with('success', flash('restored.quest'))` — on restore |
| 5 | Review `LmsQuestController::forceDelete()` flash message | `->with('success', flash('force_deleted.quest'))` — on permanent delete |
| 6 | Review `toggleStatus()` flash message | `flash('status_updated.quest')` / `flash('status_switch_failed.quest')` — AJAX response |
| 7 | Verify all redirects have consistent flash key | `'success'` for success, `'error'` for failure |
| 8 | Verify error messages use appropriate key | `back()->with('error', flash('error.quest', ...))` |

---

### 11.7 Dependency TC Steps

#### TC-D02: Summary checked_count vs Paper Check evaluation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create attempt with 2 answers; one graded (evaluated_by set), one not | Partial grade |
| 2 | Load Summary tab | checked_count = 1 (attempt has any evaluated answer) |
| 3 | Open Paper Check for the same quest | Student shows with partial grading visible |

---

#### TC-D05: Result publish cascades to Recommendation event

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Grade submission with is_published=true | Grade saved |
| 2 | Verify `QuizQuestResultPublished` event dispatched | Event fired |
| 3 | Grade submission with is_published=false | Grade saved |
| 4 | Verify no event dispatched | Event not fired |

---

#### TC-D06: gradeSubmission with answers_json syncs per-question marks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit answers_json with Qa→4 marks, Qb→8 marks | JSON submitted |
| 2 | DB check: Qa marks_obtained=4, Qb marks_obtained=8 | Answers synced |
| 3 | Verify QuizQuestAttempt.total after gradeSubmission | Recalculated correctly |

---

#### TC-D07: In-progress attempt can be graded (no guard)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt A1 status = IN_PROGRESS | In-progress |
| 2 | AJAX POST gradeSubmission | Succeeds (no validation prevents grading in-progress) |
| 3 | Verify this is a known concern | Partially completed assessment can be published |

---

## 12. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|--------|-----|------|-------------------|---------------------|
| GET | `/lms-quests/quest` | lms-quests.quest.index | index() (summary tab) | tenant.quest.viewAny |
| GET | `/lms-quests/quest/{quest}/paper-check` | lms-quests.quest.paperCheck | questPaperCheck() | tenant.quest.viewAny |
| GET | `/lms-quests/quest/{questId}/get-student-attempt-data` | lms-quests.getStudentAttemptData | getStudentAttemptData() | tenant.quest.viewAny |
| POST | `/lms-quests/quest/{questId}/grade-submission` | lms-quests.gradeSubmission | gradeSubmission() | tenant.quest.update |
| POST | `/lms-quests/quest/{questId}/save-answer-grade` | lms-quests.saveAnswerGrade | saveAnswerGrade() | tenant.quest-question.update |
| GET | `/lms-quests/quest/{quest_id}/report` | lms-quests.quest.report | report() | tenant.quest.viewAny |
| GET | `/lms-quests/quest/attempt/{attempt_id}/detail` | lms-quests.quest.attemptDetail | attemptDetail() | tenant.quest.viewAny |
| GET | `/lms-quests/quest/{questId}/get-student-questions-with-attachments` | lms-quests.getStudentQuestionsWithAttachments | getStudentQuestionsWithAttachments() | tenant.quest.viewAny |

---

## 13. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-01 | `saveAnswerGrade()` uses wrong permission namespace | **Medium** | Uses `tenant.quest-question.update` instead of `tenant.quest.update` |
| KI-02 | No validation prevents grading/publishing an IN_PROGRESS attempt | **Medium** | Can publish partially-completed assessments |
| KI-03 | `report()` fetches all results without filter on report page status counts | **Low** | Cross-allocation context may cause inconsistencies |
| KI-04 | Assigned count calculation for SECTION type uses class_id from quest relation | **Low** | Assumes quest's class matches section's parent class |
| KI-05 | `gradeSubmission()` passes marks directly without question-level validation | **Low** | Overall marks not validated against sum of per-question max marks |

---

## 14. Feature Summary Matrix

| Feature | REQ ID | RPT ID | Controller Method(s) | Key Models | Pagination |
|---------|--------|--------|---------------------|------------|------------|
| Summary Grid | REQ-QST-010 | RPT-QST-002 | index() (questSummary section) | QuestAllocation, QuizQuestAttempt, ClassSection | 10 per page |
| Paper Check | REQ-QST-011 | — | questPaperCheck(), getStudentAttemptData() | Quest, QuizQuestAttempt, QuizQuestResult | None |
| Grade Submission | REQ-QST-011/012 | — | gradeSubmission(), saveAnswerGrade() | QuizQuestAttempt, QuizQuestAttemptAnswer, QuizQuestResult | None (AJAX) |
| Performance Report | REQ-QST-013 | RPT-QST-003 | report() | Quest, QuestAllocation, QuizQuestAttempt, QuizQuestResult, StudentAcademicSession | 25 per page |
| Attempt Detail | REQ-QST-014 | RPT-QST-004 | attemptDetail() | QuizQuestAttempt, QuizQuestAttemptAnswer, QuestQuestion | None |

(End of file - total 997 lines)
