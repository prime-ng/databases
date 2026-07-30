# STP — Online Exam Attempt (stp_OnlineExamAttempt)

## 1. Module Code
`stp_OnlineExamAttempt` — StudentPortal Online Exam Attempt Feature

## 2. Feature Name
Online Exam Attempt (Student Exam Player)

## 3. Feature Description
Provides a structured, proctored online exam attempt environment for formal assessments. Features section-wise questions (MCQ + descriptive), configurable randomization (questions within sections + options), timer enforcement with auto-submit, checkpoint crash recovery, violation logging (tab switch, keyboard shortcuts), descriptive answer file uploads, gated result publishing, and PDF marks card download. Includes a console command (`TimeoutStaleAttempts`) for auto-submitting stale IN_PROGRESS attempts.

## 4. FRD Reference / REQ Mapping
| REQ-ID | Priority | Description |
|--------|----------|-------------|
| REQ-STP-030 | P0 | Online Exam Player — Instructions → Start → Attempt → Submit → Result + PDF |
| BR-STP-023 | — | Exam attempt uniqueness: one attempt per student per paper (UNIQUE constraint) |
| BR-STP-024 | — | Attempt status for answers: Only IN_PROGRESS attempts accept saves |
| BR-STP-025 | — | Timer enforcement with 5-min server grace period |
| BR-STP-026 | — | Violation logging and flagging |

## 5. Route Structure

| # | Method | URI | Action | Name |
|---|--------|-----|--------|------|
| 1 | GET | `/online-exams` | `StudentExamAttemptController@index` | `online-exams` |
| 2 | GET | `/online-exam/{id}/instructions` | `StudentExamAttemptController@instructions` | `online-exam.instructions` |
| 3 | POST | `/online-exam/{id}/start` | `StudentExamAttemptController@start` | `online-exam.start` |
| 4 | GET | `/online-exam/{id}/attempt` | `StudentExamAttemptController@attempt` | `online-exam.attempt` |
| 5 | POST | `/online-exam/{id}/submit` | `StudentExamAttemptController@submit` | `online-exam.submit` |
| 6 | POST | `/online-exam/{id}/save-answer` | `StudentExamAttemptController@saveAnswer` | `online-exam.save-answer` |
| 7 | POST | `/online-exam/{id}/checkpoint` | `StudentExamAttemptController@checkpoint` | `online-exam.checkpoint` |
| 8 | POST | `/online-exam/{id}/log` | `StudentExamAttemptController@logActivity` | `online-exam.log` |
| 9 | GET | `/online-exam/{id}/result` | `StudentExamAttemptController@result` | `online-exam.result` |
| 10 | GET | `/online-exam/{id}/result/pdf` | `StudentExamAttemptController@resultPdf` | `online-exam.result.pdf` |
| 11 | GET | `/online-exam/{id}/grievance/create` | `StudentGrievanceController@create` | `online-exam.grievance.create` |
| 12 | POST | `/online-exam/{id}/grievance` | `StudentGrievanceController@store` | `online-exam.grievance.store` |

## 6. Database Tables Involved
| Table | Type | Purpose |
|-------|------|---------|
| `lms_exam_allocations` | Read | Exam allocation per CLASS/SECTION/STUDENT with paper set assignment |
| `lms_exam_papers` | Read | Exam paper config (duration, randomization, passing %, proctoring flags) |
| `lms_exams` | Read | Parent exam entity (is_result_published gate) |
| `lms_exam_paper_sets` | Read | Paper set (randomized version) assigned to allocation |
| `lms_paper_set_questions` | Read | Paper set-to-question mappings with section, ordinal, marks override |
| `qns_questions_bank` | Read | Question content, type, marks |
| `qns_question_options` | Read | MCQ options with is_correct flag |
| `slb_question_types` | Read | Question type codes |
| `lms_exam_attempts` | Write | Core attempt record (status, timestamps, violations) |
| `lms_exam_attempt_answers` | Write | Per-question answer rows (MCQ + descriptive) |
| `lms_exam_results` | Write | Published result record (gated by is_result_published) |
| `lms_attempt_checkpoints` | Write | Crash-recovery checkpoint data |
| `lms_attempt_activity_logs` | Write | Security/activity events (violations, tab switches) |
| `lms_attempt_activity_event_types` | Read | Event type codes |
| `sch_organizations` | Read | School info for PDF generation |

## 7. Finite State Machine (FSM)

### Online Exam Attempt Status Transitions

| From State | Event | Guard | To State | Side Effects |
|-----------|-------|-------|---------|-------------|
| NOT_STARTED | Allocation created | — | NOT_STARTED | — |
| NOT_STARTED | POST /start | Allocation is Published + student targeted | IN_PROGRESS | Attempt record created; paper set resolved; checkpoint initialized |
| IN_PROGRESS | POST /submit (MCQ-only) | No descriptive questions | SUBMITTED | Auto-grading complete; lms_exam_results created; result visibility gated by is_result_published |
| IN_PROGRESS | POST /submit (has descriptive) | Has descriptive questions | EVALUATION_PENDING | MCQ auto-graded; descriptive saved with is_evaluated=false; no result record yet |
| IN_PROGRESS | Timer expires (client) | elapsed > duration_minutes | SUBMITTED | Client-side auto-submit with current answers |
| IN_PROGRESS | Timer expires (server — cron) | detected by TimeoutStaleAttempts | TIMEOUT | Auto-submitted with answers as-is |
| IN_PROGRESS | Student abandons | no action, past timeout | TIMEOUT | `TimeoutStaleAttempts` command transitions |
| SUBMITTED | Admin evaluates | — | EVALUATED | Marks entered in lms_exam_results |
| EVALUATION_PENDING | Admin evaluates | — | EVALUATED | Teacher grades descriptive answers |
| EVALUATED | Admin publishes result | — | RESULT_PUBLISHED | Notification sent; student can view result |
| — | Admin cancels exam | — | CANCELLED | All IN_PROGRESS attempts cancelled |
| — | Student was absent | — | ABSENT | Manually set by admin |

**Terminal states:** SUBMITTED, TIMEOUT, EVALUATION_PENDING, EVALUATED, RESULT_PUBLISHED, ABSENT, CANCELLED
**Key difference from Quiz/Quest:** Exam has EVALUATION_PENDING state for descriptive answers, EVALUATED state after teacher grading, and RESULT_PUBLISHED state that gates student visibility.

## 8. Business Rules / Logic

### BR-STP-023: Exam Attempt Uniqueness
- One attempt per student per exam paper — enforced by `getAttempt()` + DB UNIQUE constraint
- `getAttempt()` returns existing SUBMITTED/EVALUATION_PENDING/EVALUATED/RESULT_PUBLISHED attempt
- IN_PROGRESS attempts checked separately to prevent duplicate insert
- If existing attempt found in non-IN_PROGRESS state: redirect with info message

### BR-STP-024: IN_PROGRESS Status for Answer Saves
- `saveAnswer()` and `checkpoint()` only accept data for IN_PROGRESS attempts
- Session-based attempt ID must resolve to a valid active attempt

### BR-STP-025: Timer Enforcement
- Server-side: `actual_started_time` + `duration_minutes` + 5 min grace period
- Late submissions logged as warning but still processed
- Client-side: remaining timer computed as `totalTimerSecs - elapsed`

### BR-STP-026: Violation Logging
- Tab switches, keyboard shortcuts (copy-paste), camera violations logged via `logActivity()`
- Violation count queried from DB on submit (never trust client value)
- `countDbViolations()` joins `lms_attempt_activity_logs` with event type code 'VIOLATION'

### Question Shuffle Configurations
| Flag | Effect |
|------|--------|
| `is_randomized` | Questions randomized within sections (seeded by attempt ID + section name) |
| `shuffle_questions` | Same as is_randomized (OR check) |
| `shuffle_options` | MCQ options shuffled per question (seeded by attempt ID + question ID) |

### Descriptive Answer Handling
- SHORT_ANSWER and LONG_ANSWER types require teacher evaluation
- Text via `text_answers[question_id]`; file upload via `descriptive_files[question_id]`
- Max file size: 5 MB; allowed: PDF, JPG, PNG
- Files stored via `LmsStorageService::storeFile()` with exam-specific path config
- Status set to `EVALUATION_PENDING` when descriptive questions present
- Result record ONLY created for fully auto-graded (MCQ-only) submissions

### Result Publishing Gate
- Student can only view result when `lms_exams.is_result_published = true`
- Until published: result-pending screen shown with "results will be published" message
- PDF download similarly gated

### Proctoring Flags
| Flag | Description |
|------|-------------|
| `is_proctored` | Basic proctoring enabled |
| `is_ai_proctored` | AI-based proctoring enabled |
| `fullscreen_required` | Fullscreen mode enforced |
| `browser_lock_required` | Browser lock enforced |
| `allow_calculator` | Calculator tool allowed |

### TimeoutStaleAttempts Command
- Console command that auto-submits stale IN_PROGRESS exam attempts
- Detects attempts where elapsed time > duration_minutes + grace period
- Transitions to TIMEOUT status with current answers preserved

## 9. Input / Payload Specifications

### POST /online-exam/{id}/submit
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `attempt_id` | integer | No | Client-resolved attempt ID (server falls back to session) |
| `answers` | array | No | `[question_id => option_id]` for MCQ selections |
| `text_answers` | array | No | `[question_id => string]` for descriptive answers |
| `descriptive_files` | file[] | No | `[question_id => UploadedFile]` file uploads |
| `started_at` | string (ISO) | No | Client-reported start time |

### POST /online-exam/{id}/save-answer
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `question_id` | integer | Yes | Question bank ID |
| `answer` | mixed | No | Selected option ID (null to clear) |
| `question_idx` | integer | No | Current question index |

### POST /online-exam/{id}/checkpoint
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `current_question_idx` | integer | No | Current question index |
| `flagged_question_ids` | array | No | Flagged question IDs |
| `answered_question_ids` | array | No | Answered question IDs |

### POST /online-exam/{id}/log
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `event_code` | string | No | Event code from event types |
| `event_data` | array | No | Event payload |

## 10. Validation Rules

### Submit Validation
| Rule | Implementation | Error Handling |
|------|---------------|---------------|
| Hard submit lock | `getAttempt()` check for SUBMITTED/EVALUATED/RESULT_PUBLISHED | Redirect with info flash |
| Timer enforcement | Server-side deadline check | Logged as late; still processed |
| File upload: max size | 5120 KB per file | 422 with field error |
| File upload: MIME types | PDF, JPG, JPEG, PNG | 422 with field error |

## 11. Error / Exception Handling

| Scenario | HTTP Code | Response |
|----------|-----------|----------|
| Missing student profile | 403 | `abort(403, 'Student profile not found.')` |
| No allocation for exam | 403 | `abort(403, 'You do not have access to this exam.')` |
| Already submitted | 302 | Redirect to results with info message |
| File upload too large | 422 | Validation error |
| File type not allowed | 422 | Validation error |
| Result not published yet | 302 | Result-pending screen with clock icon |
| No result for PDF | 302 | Redirect with warning |
| Result not published for PDF | 302 | Redirect with warning |

## 12. Concurrency / Race Conditions

| Scenario | Mitigation |
|----------|-----------|
| Double submit | `lockForUpdate()` on attempt row inside transaction |
| Two tabs start simultaneously | IN_PROGRESS check before insert; second finds existing attempt |
| Session lost mid-exam | Auto-start fallback redirects to `start()` |
| Checkpoint crash recovery | DB checkpoint data takes precedence over session |

## 13. Role-Based Access / Permissions
- **Student**: Full access — list, start, attempt, save, submit, view result (when published), download PDF
- **Parent**: Access via child resolution
- **Other roles**: Allocation security gate blocks non-allocated users
- **No `Gate::authorize()` calls** in controller

## 14. Screens / UI States

| Screen | Route | UI Elements |
|--------|-------|-------------|
| Online Exams (list) | GET /online-exams | List of allocated exams with paper title, subject, scheduled date, status, attempt info |
| Exam Instructions | GET /online-exam/{id}/instructions | Exam metadata (duration, sections, marks, proctoring info), instructions text, Start button |
| Exam Attempt | GET /online-exam/{id}/attempt | Timer (remaining seconds), section-wise questions, MCQ options / text areas / file uploaders, question navigator, flag, checkpoint indicator |
| Exam Result | GET /online-exam/{id}/result | Score card with section-wise breakdown, marks, percentage, grade, division, correct/wrong/unattempted |
| Result Pending | GET /online-exam/{id}/result (unpublished) | Clock icon with "Results will be published" message |
| Exam Result PDF | GET /online-exam/{id}/result/pdf | A4 PDF marks card with school header, student info, section-wise breakdown |

## 15. API / Integration Points

| Integration | Direction | Mechanism |
|-------------|-----------|-----------|
| `LmsStorageService::buildPath()` | Outbound | Builds storage path for descriptive file attachments |
| `LmsStorageService::storeFile()` | Outbound | Stores uploaded exam files |
| `LmsStorageService::getFileUrl()` | Outbound | Generates file access URL |
| `TimeoutStaleAttempts` command | Internal | Console command registered in Scheduler |
| `AttemptActivityLog::logEvent()` | Internal | Security/activity event logging |
| `ExamGrievance` model | Internal | Linked from exam result for grievance creation |

## 16. Feature Status
- **V1:** Complete
- **V2:** Not started
- **Status:** Complete
- **CR:** ◌

---
*Generated from: `StudentExamAttemptController.php` (1069 lines), `STP_FRD_Complete_2026-06-30.md`, `pgdatabase/Backup/4-Module_Requirement/StudentPortal/learning/online_exam_attempt.md`*
