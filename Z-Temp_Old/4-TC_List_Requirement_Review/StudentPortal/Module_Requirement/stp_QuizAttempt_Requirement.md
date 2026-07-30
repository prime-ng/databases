# STP — Quiz Attempt (stp_QuizAttempt)

## 1. Module Code
`stp_QuizAttempt` — StudentPortal Quiz Attempt Feature

## 2. Feature Name
Quiz Attempt (Student Quiz Player)

## 3. Feature Description
Provides a complete online quiz attempt interface for students. Students can view allocated quizzes, read instructions, start timed quiz attempts, answer MCQ questions with auto-save and checkpoint recovery, submit attempts, and view auto-graded results with PDF download. Supports negative marking, randomized question ordering, timer enforcement, remedial quiz auto-generation on failure, and recommendation engine dispatch.

## 4. FRD Reference / REQ Mapping
| REQ-ID | Priority | Description |
|--------|----------|-------------|
| REQ-STP-031 | P0 | Quiz Player — Full attempt flow: instructions → start → attempt → submit → result + PDF |
| BR-STP-020 | — | Quiz/Quest allocation cut-off: Expired allocations excluded |
| BR-STP-027 | — | Quiz max attempts: attempt_number < max_attempts enforced |

## 5. Route Structure

| # | Method | URI | Action | Name |
|---|--------|-----|--------|------|
| 1 | GET | `/my-quizzes` | `StudentQuizAttemptController@index` | `my-quizzes` |
| 2 | GET | `/quiz/{id}/instructions` | `StudentQuizAttemptController@instructions` | `quiz.instructions` |
| 3 | POST | `/quiz/{id}/start` | `StudentQuizAttemptController@start` | `quiz.start` |
| 4 | GET | `/quiz/{id}/attempt` | `StudentQuizAttemptController@attempt` | `quiz.attempt` |
| 5 | POST | `/quiz/{id}/submit` | `StudentQuizAttemptController@submit` | `quiz.submit` |
| 6 | POST | `/quiz/{id}/save-answer` | `StudentQuizAttemptController@saveAnswer` | `quiz.save-answer` |
| 7 | POST | `/quiz/{id}/checkpoint` | `StudentQuizAttemptController@checkpoint` | `quiz.checkpoint` |
| 8 | POST | `/quiz/{id}/log` | `StudentQuizAttemptController@logActivity` | `quiz.log` |
| 9 | GET | `/quiz/{id}/result` | `StudentQuizAttemptController@result` | `quiz.result` |
| 10 | GET | `/quiz/{id}/result/pdf` | `StudentQuizAttemptController@resultPdf` | `quiz.result.pdf` |

## 6. Database Tables Involved
| Table | Type | Purpose |
|-------|------|---------|
| `lms_quiz_allocations` | Read | Quiz visibility/allocation per CLASS/SECTION/STUDENT |
| `lms_quizzes` | Read | Quiz config (duration, timer, randomization, passing %) |
| `lms_quiz_questions` | Read | Quiz-to-question mappings with marks override |
| `qns_questions_bank` | Read | Question content, type, marks |
| `qns_question_options` | Read | MCQ options with is_correct flag |
| `lms_quiz_quest_attempts` | Write | Core attempt record (status, scores, timestamps) |
| `lms_quiz_quest_attempt_answers` | Write | Per-question answer rows with auto-grading results |
| `lms_attempt_checkpoints` | Write | Crash-recovery checkpoint data |
| `lms_attempt_activity_logs` | Write | Security/activity events during attempt |
| `lms_attempt_activity_event_types` | Read | Event type codes (VIOLATION, ATTEMPT_STARTED) |
| `lms_quiz_quest_results` | Write | Published result record |
| `sch_organizations` | Read | School info for PDF generation |

## 7. Finite State Machine (FSM)

### Quiz Attempt Status Transitions

| From State | Event | Guard | To State | Side Effects |
|-----------|-------|-------|---------|-------------|
| NOT_STARTED | Student opens quiz | Allocation valid + attempts_used < max_attempts | NOT_STARTED | — |
| NOT_STARTED | POST /start | — | IN_PROGRESS | Attempt record created; attempt_number incremented; ATTEMPT_STARTED event logged |
| IN_PROGRESS | POST /submit | — | SUBMITTED | Auto-grading computed; answers frozen; result record created; checkpoint deleted |
| IN_PROGRESS | Timer expires (server-side) | elapsed > duration_minutes + 5 min grace | ABANDONED | Attempt marked ABANDONED; checkpoint cleared; student redirected to instructions |
| IN_PROGRESS | Student closes browser | timeout detected on next request | ABANDONED | Same as timer expiry side-effects |
| IN_PROGRESS | POST /checkpoint | — | IN_PROGRESS | Checkpoint data upserted (no state change) |
| SUBMITTED | — | — | SUBMITTED | Terminal state — no further transitions for student |

**Terminal states:** SUBMITTED, ABANDONED
**Illegal transitions:** SUBMITTED → IN_PROGRESS (resumption forbidden); IN_PROGRESS → SUBMITTED after deadline (logged as late, but still processed)

## 8. Business Rules / Logic

### BR-STP-020: Allocation Cut-off
- Quiz allocations with `cut_off_date` in the past are excluded from listing
- `visibleAllocations()` filters: `whereNull('cut_off_date')` OR `cut_off_date >= now()`

### BR-STP-027: Max Attempts Enforcement
- If `allow_multiple_attempts = false`, cap = 1; else cap = `max_attempts`
- Only SUBMITTED and TIMEOUT attempts count toward `attempts_used`
- IN_PROGRESS and ABANDONED attempts do NOT count toward cap
- Check performed at: `start()`, `attempt()`, `submit()` methods

### Timer Enforcement
- `duration_minutes` read from quiz config; `timer_enforced` flag gates enforcement
- Server-side grace period: 5 minutes added to duration
- If no timer enforced and duration = 0: maximum window = 1440 minutes (24 hours)
- `markAbandonedIfExpired()` called on every `attempt()` and `start()` access

### Hard Lock (hasSubmittedAttempt)
- Once a student has any SUBMITTED or TIMEOUT attempt for a quiz, all further attempts are blocked
- Checked in `start()`, `attempt()`, and `submit()` — redirects to result with warning

### Auto-Grading Logic
- MCQ auto-grading: correct answer = full marks; incorrect = `-negative_marks`; unattempted = 0
- Negative marks floored: `marksObtained = max(0.0, marksObtained)`
- Passing: percentage >= `passing_percentage`

### Remedial Quiz Generation
- If `is_passed = false` AND the quiz is NOT `is_system_generated` (prevents infinite loops)
- `RemedialQuizGenerationService::generate()` creates a new remedial quiz allocation
- Failure is non-fatal — logged as warning, student flow uninterrupted

### Recommendation Engine Dispatch
- `QuizQuestResultPublished` event dispatched after every successful submission
- `$shouldPublish` flag gated by allocation's `is_auto_publish_result`
- Always dispatches (even when auto-publish is off) for hidden recommendation creation

### Checkpoint & Save System
- `saveAnswer()` AJAX: saves to session + persists to `lms_attempt_checkpoints`
- `checkpoint()` AJAX: saves navigation state (current index, flagged/answered IDs)
- On attempt load: prefers DB checkpoint data over session data
- On submit: checkpoint records deleted

## 9. Input / Payload Specifications

### POST /quiz/{id}/start
- No request body required
- Session used to track active attempt ID: `quiz_attempt_{id}_{studentId}`

### POST /quiz/{id}/submit
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `attempt_id` | integer | No | Client-resolved attempt ID (server falls back to session) |
| `answers` | array | No | `[question_id => option_id]` mapping of MCQ selections |
| `started_at` | string (ISO) | No | Client-reported start time (server overrides with DB value) |

### POST /quiz/{id}/save-answer
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `question_id` | integer | Yes | Question bank ID |
| `answer` | mixed | No | Selected option ID (null/empty to clear) |
| `question_idx` | integer | No | Current question index for checkpoint |

### POST /quiz/{id}/checkpoint
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `current_question_idx` | integer | No | Current question index |
| `flagged_question_ids` | array | No | List of flagged question IDs |
| `answered_question_ids` | array | No | List of answered question IDs |

### POST /quiz/{id}/log
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `event_code` | string | No | Event code from `lms_attempt_activity_event_types` |
| `event_data` | array | No | Arbitrary event payload data |

## 10. Validation Rules

### Submit Validation
| Rule | Implementation | Error Handling |
|------|---------------|---------------|
| Hard submit lock (already completed) | `hasSubmittedAttempt()` check | Redirect to result with warning flash |
| Max attempts check | `attempts_used >= cap` | Redirect to result with warning flash |
| Timer enforcement (server-side) | `serverStartedAt + duration + 5 min > now()` | Logged as late submission; still processed |

### File Validation (N/A for Quiz — MCQ only)

## 11. Error / Exception Handling

| Scenario | HTTP Code | Response |
|----------|-----------|----------|
| Missing student profile | 403 | `abort(403, 'Student profile not found.')` |
| No allocation for quiz | 403 | `abort(403, 'You do not have access to this quiz.')` |
| Already submitted (hard lock) | 302 | Redirect to result with `warning: 'You have already completed this quiz.'` |
| Max attempts reached | 302 | Redirect to result with `warning: 'Max attempts reached.'` |
| Attempt expired (abandoned) | 302 | Redirect to instructions with `warning: 'Your attempt has expired...'` |
| No checkpoint/active attempt | 422 | JSON: `{'ok': false, 'error': 'No active attempt'}` |
| No result for PDF download | 302 | Redirect with `warning: 'No result available to download.'` |
| Result not published for PDF | 302 | Redirect with `warning: 'Result has not been released by your teacher yet.'` |
| Remedial generation failure | — | Logged as warning; student flow continues unchanged |

## 12. Concurrency / Race Conditions

| Scenario | Mitigation |
|----------|-----------|
| Double submit (same attempt) | `lockForUpdate()` on attempt row inside DB transaction; second update sees IN_PROGRESS changed to SUBMITTED and falls through to fallback INSERT |
| Session lost mid-attempt | `start()` fallback: if no session attempt ID, auto-redirects to `start()` |
| Browser tab switch detected | Event logged via `logActivity()` with VIOLATION event code; violation count queried from DB on submit |
| Checkpoint vs session mismatch | On attempt load: DB checkpoint takes precedence over session data |

## 13. Role-Based Access / Permissions
- **Student**: Full access — list, start, attempt, save, submit, view result, download PDF
- **Parent**: Access via `ParentContextService::resolveChild()` — resolves active child
- **Other roles**: No access — allocation security gate blocks non-allocated users
- **No `Gate::authorize()` calls** in controller (security relies on student context resolution + allocation assertion)

## 14. Screens / UI States

| Screen | Route | UI Elements |
|--------|-------|-------------|
| My Quizzes (list) | GET /my-quizzes | Grid of quiz cards with subject, title, status, cut-off, attempts used, progress |
| Quiz Instructions | GET /quiz/{id}/instructions | Quiz metadata (duration, marks, passing %, negative marks), instructions text, Start button |
| Quiz Attempt | GET /quiz/{id}/attempt | Timer header, question navigator, MCQ options, Flag button, Save/Next buttons, checkpoint indicator |
| Quiz Result | GET /quiz/{id}/result | Score card (marks, percentage, grade, pass/fail), correct/wrong/unattempted counts, answers review, PDF download |
| Quiz Result PDF | GET /quiz/{id}/result/pdf | A4 PDF marks card with school header, student info, score breakdown |

## 15. API / Integration Points

| Integration | Direction | Mechanism |
|-------------|-----------|-----------|
| `QuizQuestResultPublished` event | Outbound | Dispatched to Recommendation module for recommendation generation |
| `RemedialQuizGenerationService::generate()` | Outbound | Creates remedial quiz allocation when student fails |
| `activityLog()` helper | Outbound | Logs all significant actions to activity log |
| `AttemptActivityLog::logEvent()` | Internal | Security/activity event logging during attempt |
| `AttemptCheckpoint` CRUD | Internal | Checkpoint save/load/clear for crash recovery |

## 16. Feature Status
- **V1:** Complete
- **V2:** Not started
- **Status:** Complete
- **CR:** ◌

---
*Generated from: `StudentQuizAttemptController.php` (1033 lines), `STP_FRD_Complete_2026-06-30.md`, `pgdatabase/Backup/4-Module_Requirement/StudentPortal/learning/quiz_attempt.md`*
