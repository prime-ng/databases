# STP — Quest Attempt (stp_QuestAttempt)

## 1. Module Code
`stp_QuestAttempt` — StudentPortal Quest Attempt Feature

## 2. Feature Name
Quest Attempt (Student Quest Player)

## 3. Feature Description
Provides an interactive quest attempt interface for students. Supports both MCQ (auto-graded) and descriptive (teacher-evaluated) question types with file uploads. Includes checkpoint-based crash recovery, timer enforcement, randomized question ordering, negative marking for MCQs, XP rewards, and recommendation engine dispatch. Descriptive answers require manual teacher evaluation before results are finalized.

## 4. FRD Reference / REQ Mapping
| REQ-ID | Priority | Description |
|--------|----------|-------------|
| REQ-STP-032 | P0 | Quest Player — Instructions → Start → Attempt → Submit → Result + PDF |
| BR-STP-028 | — | Quest max attempts: attempt_number < max_attempts enforced |
| BR-STP-020 | — | Quest allocation cut-off: Expired allocations excluded |

## 5. Route Structure

| # | Method | URI | Action | Name |
|---|--------|-----|--------|------|
| 1 | GET | `/my-quests` | `StudentQuestAttemptController@index` | `my-quests` |
| 2 | GET | `/quest/{id}/instructions` | `StudentQuestAttemptController@instructions` | `quest.instructions` |
| 3 | POST | `/quest/{id}/start` | `StudentQuestAttemptController@start` | `quest.start` |
| 4 | GET | `/quest/{id}/attempt` | `StudentQuestAttemptController@attempt` | `quest.attempt` |
| 5 | POST | `/quest/{id}/submit` | `StudentQuestAttemptController@submit` | `quest.submit` |
| 6 | POST | `/quest/{id}/save-answer` | `StudentQuestAttemptController@saveAnswer` | `quest.save-answer` |
| 7 | POST | `/quest/{id}/checkpoint` | `StudentQuestAttemptController@checkpoint` | `quest.checkpoint` |
| 8 | POST | `/quest/{id}/log` | `StudentQuestAttemptController@logActivity` | `quest.log` |
| 9 | GET | `/quest/{id}/result` | `StudentQuestAttemptController@result` | `quest.result` |
| 10 | GET | `/quest/{id}/result/pdf` | `StudentQuestAttemptController@resultPdf` | `quest.result.pdf` |

## 6. Database Tables Involved
| Table | Type | Purpose |
|-------|------|---------|
| `lms_quest_allocations` | Read | Quest visibility/allocation per CLASS/SECTION/STUDENT |
| `lms_quests` | Read | Quest config (duration, timer, randomization, passing %) |
| `lms_quest_questions` | Read | Quest-to-question mappings with marks override |
| `qns_questions_bank` | Read | Question content, type, marks |
| `qns_question_options` | Read | MCQ options with is_correct flag |
| `lms_quiz_quest_attempts` | Write | Core attempt record (assessment_type = 'QUEST') |
| `lms_quiz_quest_attempt_answers` | Write | Per-question answer rows (MCQ auto-graded + descriptive) |
| `lms_attempt_checkpoints` | Write | Crash-recovery checkpoint data |
| `lms_attempt_activity_logs` | Write | Security/activity events during attempt |
| `lms_attempt_activity_event_types` | Read | Event type codes |
| `lms_quiz_quest_results` | Write | Published result record |
| `sch_organizations` | Read | School info for PDF generation |
| `slb_question_types` | Read | Question type codes (MCQ_SINGLE, SHORT_ANSWER, LONG_ANSWER, TRUE_FALSE) |

## 7. Finite State Machine (FSM)

### Quest Attempt Status Transitions

| From State | Event | Guard | To State | Side Effects |
|-----------|-------|-------|---------|-------------|
| NOT_STARTED | Student opens quest | Allocation valid + attempts_used < max_attempts | NOT_STARTED | — |
| NOT_STARTED | POST /start | — | IN_PROGRESS | Attempt record created; attempt_number incremented; ATTEMPT_STARTED event logged |
| IN_PROGRESS | POST /submit (MCQ-only) | No descriptive questions | SUBMITTED | MCQ auto-grading complete; result published (is_published = shouldPublish); recommendation dispatched; XP awarded |
| IN_PROGRESS | POST /submit (has descriptive) | Has descriptive questions | SUBMITTED | MCQ auto-graded; descriptive saved with is_evaluated = false; result record created (is_published = false); status = SUBMITTED |
| IN_PROGRESS | Timer expires | elapsed > duration_minutes + 5 min grace | ABANDONED | Attempt marked ABANDONED; checkpoint cleared |
| IN_PROGRESS | Student closes browser | timeout detected on next request | ABANDONED | Same as timer expiry |
| SUBMITTED | — | — | SUBMITTED | Terminal state for student |

**Terminal states:** SUBMITTED, ABANDONED
**Key difference from Quiz:** Quest supports descriptive questions (SHORT_ANSWER/LONG_ANSWER) requiring teacher evaluation. MCQ-only quests behave identically to quiz auto-grading. Descriptive answers set `is_evaluated = false` and `marks_obtained = 0.0` pending teacher review.

## 8. Business Rules / Logic

### BR-STP-020: Allocation Cut-off
- Same pattern as Quiz: `cut_off_date` checked; expired allocations excluded
- `visibleAllocations()` includes `unique('quest_id')` deduplication for overlapping CLASS + SECTION allocations

### BR-STP-028: Max Attempts Enforcement
- Same cap logic as Quiz: `allow_multiple_attempts` flag + `max_attempts` value
- SUBMITTED/TIMEOUT count; IN_PROGRESS/ABANDONED do not count
- Hard lock prevents any new attempt if SUBMITTED/TIMEOUT exists

### Question Type Handling
| Question Type Code | Mapped Type | Auto-Graded? | Evaluation |
|-------------------|-------------|--------------|------------|
| MCQ_SINGLE, MCQ_MULTI | MCQ | Yes | Instant auto-grade |
| TRUE_FALSE | MCQ | Yes | Instant auto-grade |
| SHORT_ANSWER | SHORT_ANSWER | No | Teacher evaluation |
| LONG_ANSWER | LONG_ANSWER | No | Teacher evaluation |

### Descriptive Answer Handling
- **Text**: Provided via `text_answers[question_id]` input; stored in `answer_text` column
- **File Upload**: Per-question file via `descriptive_files[question_id]`; max 5MB; allowed: PDF, JPG, PNG
- **Storage**: Via `LmsStorageService::storeFile()` — builds path using session code, class-section, quest ID, student ID
- **Attachment metadata**: Stored as JSON in `attachment_data` column
- **Grading**: Descriptive rows are created with `marks_obtained = 0.0`, `is_evaluated = false`, `is_correct = null`

### Timer Enforcement
- Same grace-period logic as Quiz (5 minutes)
- `markAbandonedIfExpired()` called on every `attempt()` and `start()` access

### Auto-Grading (MCQ portion)
- Identical to Quiz: correct = full marks; wrong = `-negative_marks`; unattempted = 0
- Negative marks floored at 0.0

### XP Reward
- `xp_earned = 100` if `isPassed`; `xpEarned = 0` otherwise
- XP displayed in result view success message: "You earned 100 XP!"
- `xp_already_awarded` flag in result view prevents duplicate XP display on subsequent attempts

### Recommendation Dispatch
- Only dispatched for fully auto-graded quests (no descriptive questions)
- `QuizQuestResultPublished` event dispatched with `$shouldPublish` flag
- Descriptive quests skip dispatch — event fires on teacher grade publish

### Checkpoint & Save System
- Same pattern as Quiz: session + DB checkpoint dual persistence
- `saveAnswer()` AJAX stores answer in session + checkpoints to DB
- `checkpoint()` AJAX saves navigation state
- Descriptive answer text is also checkpointed via saveAnswer

## 9. Input / Payload Specifications

### POST /quest/{id}/submit
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `attempt_id` | integer | No | Client-resolved attempt ID (server falls back to session) |
| `answers` | array | No | `[question_id => option_id]` for MCQ selections |
| `text_answers` | array | No | `[question_id => string]` for descriptive answers |
| `descriptive_files` | file[] | No | `[question_id => UploadedFile]` file uploads per descriptive question |
| `started_at` | string (ISO) | No | Client-reported start time (server overrides with DB value) |

### POST /quest/{id}/save-answer
- Same structure as Quiz save-answer

### POST /quest/{id}/checkpoint
- Same structure as Quiz checkpoint

### POST /quest/{id}/log
- Same structure as Quiz log

## 10. Validation Rules

### Submit Validation
| Rule | Implementation | Error Handling |
|------|---------------|---------------|
| Hard submit lock (already completed) | `hasSubmittedAttempt()` check | Redirect to result with warning |
| Max attempts check | `attempts_used >= cap` | Redirect to result with warning |
| Timer enforcement | Server-side deadline check | Logged as late; still processed |
| File upload: max size | 5120 KB (5 MB) per file | 422 with field error: "Each file must be under 5 MB." |
| File upload: allowed MIME types | PDF, JPG, JPEG, PNG | 422 with field error: "Allowed: PDF, JPG, PNG." |

## 11. Error / Exception Handling

| Scenario | HTTP Code | Response |
|----------|-----------|----------|
| Missing student profile | 403 | `abort(403, 'Student profile not found.')` |
| No allocation for quest | 403 | `abort(403, 'You do not have access to this quest.')` |
| Already submitted (hard lock) | 302 | Redirect to result with warning |
| Max attempts reached | 302 | Redirect to result with warning |
| Attempt expired (abandoned) | 302 | Redirect to instructions with expiry warning |
| File upload too large | 422 | Validation error message |
| File type not allowed | 422 | Validation error message |
| Descriptive file upload failure | — | Logged as error; answer saved without file |
| No result for PDF download | 302 | Redirect with warning |
| Result not published for PDF | 302 | Redirect with warning |

## 12. Concurrency / Race Conditions

| Scenario | Mitigation |
|----------|-----------|
| Double submit (same attempt) | `lockForUpdate()` on attempt row inside transaction |
| Session lost mid-attempt | Auto-redirect to `start()` fallback |
| File upload collision | Storage service generates unique paths per student/quest/session |
| Checkpoint vs session mismatch | DB checkpoint data takes precedence |

## 13. Role-Based Access / Permissions
- **Student**: Full access — list, start, attempt, save, submit, view result, download PDF
- **Parent**: Access via `ParentContextService::resolveChild()`
- **Other roles**: Allocation security gate blocks non-allocated users
- **No `Gate::authorize()` calls** in controller

## 14. Screens / UI States

| Screen | Route | UI Elements |
|--------|-------|-------------|
| My Quests (list) | GET /my-quests | Grid of quest cards with badge, subject, title, attempts used, progress |
| Quest Instructions | GET /quest/{id}/instructions | Quest metadata, instructions, Start button |
| Quest Attempt | GET /quest/{id}/attempt | Timer header, question navigator, MCQ options / text areas / file uploaders, Flag button, checkpoint indicator |
| Quest Result | GET /quest/{id}/result | Score card, XP earned display, badge badge, correct/wrong/unattempted, descriptive answer review with files |
| Quest Result PDF | GET /quest/{id}/result/pdf | A4 PDF marks card with school header, student info, question review |

## 15. API / Integration Points

| Integration | Direction | Mechanism |
|-------------|-----------|-----------|
| `LmsStorageService::buildPath()` | Outbound | Builds storage path for descriptive file attachments |
| `LmsStorageService::storeFile()` | Outbound | Stores uploaded files to configured disk |
| `LmsStorageService::getFileUrl()` | Outbound | Generates signed/unsigned URL for file access |
| `QuizQuestResultPublished` event | Outbound | Dispatched to Recommendation module (MCQ-only quests) |
| `AttemptActivityLog::logEvent()` | Internal | Security/activity event logging |

## 16. Feature Status
- **V1:** Complete
- **V2:** Not started
- **Status:** Complete
- **CR:** ◌

---
*Generated from: `StudentQuestAttemptController.php` (1126 lines), `STP_FRD_Complete_2026-06-30.md`, `pgdatabase/Backup/4-Module_Requirement/StudentPortal/learning/quest_attempt.md`*
