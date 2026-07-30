# STP — Quiz Attempt (stp_QuizAttempt) — TC List

## 1. TC List ID
`stp_QuizAttempt_TC`

## 2. Feature Name
Quiz Attempt (Student Quiz Player)

## 3. Module Code
`stp_QuizAttempt` — StudentPortal

## 4. FRD REQ Mapping
REQ-STP-031, BR-STP-020, BR-STP-027

## 5. Route / Endpoint Coverage

| # | TC ID | Route | Method | Test Scenario | Input / Condition | Expected Result | Priority | Status |
|---|-------|-------|--------|---------------|-------------------|----------------|----------|--------|
| 1 | QAT-001 | GET /my-quizzes | GET | Student with valid allocations views quiz list | Student has CLASS/SECTION/STUDENT allocations for active quizzes | Quiz cards displayed with subject, title, status, attempts used | P0 | ⬜ |
| 2 | QAT-002 | GET /my-quizzes | GET | Student with no allocations views empty list | Student has no quiz allocations | Empty state displayed | P1 | ⬜ |
| 3 | QAT-003 | GET /my-quizzes | GET | Expired allocation excluded from listing | Allocation has cut_off_date in the past | Quiz not shown in list | P0 | ⬜ |
| 4 | QAT-004 | GET /my-quizzes | GET | Completed quiz shows attempts used and last result | Student has SUBMITTED attempts | Attempt count and last result data shown on card | P0 | ⬜ |
| 5 | QAT-005 | GET /my-quizzes | GET | In-progress quiz shows resume option | Student has IN_PROGRESS attempt | Incomplete attempt data shown | P1 | ⬜ |
| 6 | QAT-006 | GET /quiz/{id}/instructions | GET | Student views quiz instructions | Valid quiz ID with active allocation | Instructions page loaded with quiz metadata, Start button visible | P0 | ⬜ |
| 7 | QAT-007 | GET /quiz/{id}/instructions | GET | Student without allocation gets 403 | Quiz ID not allocated to student | 403 Forbidden: "You do not have access to this quiz." | P0 | ⬜ |
| 8 | QAT-008 | GET /quiz/{id}/instructions | GET | Already completed quiz — redirect to result | HasSubmittedAttempt = true | Redirect to quiz result with warning | P0 | ⬜ |
| 9 | QAT-009 | GET /quiz/{id}/instructions | GET | Non-existent quiz ID | Quiz not in database | 404 Not Found | P0 | ⬜ |
| 10 | QAT-010 | GET /quiz/{id}/instructions | GET | Student profile missing returns 403 | auth user has no Student relation | 403 Forbidden | P0 | ⬜ |
| 11 | QAT-011 | POST /quiz/{id}/start | POST | First-time student starts quiz | No previous attempts, within max_attempts limit | Attempt record created (IN_PROGRESS), redirect to attempt page | P0 | ⬜ |
| 12 | QAT-012 | POST /quiz/{id}/start | POST | Start quiz when max attempts reached | attempts_used >= max_attempts cap | Redirect to result with warning: "Max attempts reached." | P0 | ⬜ |
| 13 | QAT-013 | POST /quiz/{id}/start | POST | Start quiz when already submitted | hasSubmittedAttempt = true | Redirect to result with warning: "You have already completed this quiz." | P0 | ⬜ |
| 14 | QAT-014 | POST /quiz/{id}/start | POST | Resume existing IN_PROGRESS attempt | Existing IN_PROGRESS attempt found, not expired | Session set, redirect to attempt page | P0 | ⬜ |
| 15 | QAT-015 | POST /quiz/{id}/start | POST | Expired IN_PROGRESS attempt abandoned | Existing attempt exceeds time limit + grace | Attempt marked ABANDONED, new attempt created (if cap not reached) | P0 | ⬜ |
| 16 | QAT-016 | POST /quiz/{id}/start | POST | Multiple attempts allowed — second start | allow_multiple_attempts = true, 1 used, cap = 3 | New attempt with attempt_number = 2 created | P0 | ⬜ |
| 17 | QAT-017 | POST /quiz/{id}/start | POST | Single attempt quiz — restart blocked after abandon | allow_multiple_attempts = false, first attempt abandoned | ABANDONED counts toward attempts_used; redirect to result | P1 | ⬜ |
| 18 | QAT-018 | POST /quiz/{id}/start | POST | No allocation returns 403 | Student not allocated to this quiz | 403 Forbidden | P0 | ⬜ |
| 19 | QAT-019 | GET /quiz/{id}/attempt | GET | View active attempt page | IN_PROGRESS attempt exists, session has attempt_id | Attempt page loaded with questions, timer, saved answers | P0 | ⬜ |
| 20 | QAT-020 | GET /quiz/{id}/attempt | GET | No session attempt_id — auto-start | Student navigates directly to attempt URL without starting | Redirect to start() which creates attempt or aborts | P0 | ⬜ |
| 21 | QAT-021 | GET /quiz/{id}/attempt | GET | Already submitted — redirect to result | hasSubmittedAttempt = true | Redirect to quiz result with warning | P0 | ⬜ |
| 22 | QAT-022 | GET /quiz/{id}/attempt | GET | Max attempts used | attempts_used >= max_attempts | Redirect to result with warning | P0 | ⬜ |
| 23 | QAT-023 | GET /quiz/{id}/attempt | GET | Expired attempt shows warning | markAbandonedIfExpired returns true | Redirect to instructions with expiry warning, session cleared | P0 | ⬜ |
| 24 | QAT-024 | GET /quiz/{id}/attempt | GET | Randomized question order (per attempt) | quiz.is_randomized = true | Questions shuffled deterministically based on attempt ID | P1 | ⬜ |
| 25 | QAT-025 | GET /quiz/{id}/attempt | GET | Checkpoint recovery loads saved answers | DB checkpoint exists with checkpoint_data | Saved answers pre-populated from DB checkpoint | P0 | ⬜ |
| 26 | QAT-026 | POST /quiz/{id}/submit | POST | Successful quiz submission (MCQ answers correct) | All MCQ answers correct | Attempt status = SUBMITTED; result record created; score = 100% | P0 | ⬜ |
| 27 | QAT-027 | POST /quiz/{id}/submit | POST | Successful quiz submission (mixed answers) | Mix of correct, incorrect, and unattempted answers | Auto-grading computes correct marks; negative marking applied for wrong answers | P0 | ⬜ |
| 28 | QAT-028 | POST /quiz/{id}/submit | POST | All answers unattempted | Empty answers array | Marks = 0; percentage = 0; is_passed = false; remedial triggered | P0 | ⬜ |
| 29 | QAT-029 | POST /quiz/{id}/submit | POST | Already submitted (double submit) | Two simultaneous POST /submit requests | First succeeds; second redirects with warning "already completed" | P0 | ⬜ |
| 30 | QAT-030 | POST /quiz/{id}/submit | POST | Max attempts reached at submit time | attempts_used >= cap | Redirect with warning, no grading | P0 | ⬜ |
| 31 | QAT-031 | POST /quiz/{id}/submit | POST | Late submission within grace period | Timer expired but within 5-min grace period | Still processed; late_by_s logged as warning | P1 | ⬜ |
| 32 | QAT-032 | POST /quiz/{id}/submit | POST | Session lost mid-attempt (fallback INSERT) | No existing attempt ID found | Fallback attempt record created; submission processed | P1 | ⬜ |
| 33 | QAT-033 | POST /quiz/{id}/submit | POST | Negative marking applied correctly | quiz.negative_marks = 1; wrong answers submitted | Marks deducted; marksObtained = max(0.0, computed) | P0 | ⬜ |
| 34 | QAT-034 | POST /quiz/{id}/submit | POST | Auto-publish result enabled | allocation.is_auto_publish_result = true | Result record with is_published = true, published_at set | P0 | ⬜ |
| 35 | QAT-035 | POST /quiz/{id}/submit | POST | Auto-publish result disabled | allocation.is_auto_publish_result = false | Result record with is_published = false, published_at = null | P1 | ⬜ |
| 36 | QAT-036 | POST /quiz/{id}/submit | POST | Student fails quiz — remedial generation triggered | percentage < passing_percentage; not system_generated | RemedialQuizGenerationService called; allocation created | P0 | ⬜ |
| 37 | QAT-037 | POST /quiz/{id}/submit | POST | System-generated quiz — no remedial loop | quiz.is_system_generated = true; student fails | Remedial generation skipped | P0 | ⬜ |
| 38 | QAT-038 | POST /quiz/{id}/submit | POST | Remedial generation failure (non-fatal) | RemedialQuizGenerationService throws RuntimeException | Logged as warning; student redirected to result with success | P1 | ⬜ |
| 39 | QAT-039 | POST /quiz/{id}/submit | POST | Recommendation event dispatched | QuizQuestResultPublished event | Event dispatched with result model and shouldPublish flag | P1 | ⬜ |
| 40 | QAT-040 | GET /quiz/{id}/result | GET | View published quiz result | SUBMITTED attempt exists; result record exists | Score card displayed: marks, percentage, grade, correct/wrong/unattempted | P0 | ⬜ |
| 41 | QAT-041 | GET /quiz/{id}/result | GET | No attempt yet — no result | Student has no SUBMITTED/TIMEOUT attempts | Result section = null; empty state displayed | P1 | ⬜ |
| 42 | QAT-042 | GET /quiz/{id}/result | GET | Result for multiple attempts (last attempt shown) | 2 attempts on multi-attempt quiz | Latest attempt (highest attempt_number) shown | P1 | ⬜ |
| 43 | QAT-043 | GET /quiz/{id}/result | GET | No allocation — 403 | Student not allocated to quiz | 403 Forbidden | P0 | ⬜ |
| 44 | QAT-044 | GET /quiz/{id}/result/pdf | GET | Download published result PDF | Result published, is_published = true | PDF file streamed with quiz result data | P0 | ⬜ |
| 45 | QAT-045 | GET /quiz/{id}/result/pdf | GET | No attempt — redirect with warning | No SUBMITTED/TIMEOUT attempt | Redirect to result with warning "No result available" | P0 | ⬜ |
| 46 | QAT-046 | GET /quiz/{id}/result/pdf | GET | Result not published — redirect | Result record exists but is_published = false | Redirect to result with warning "not released by teacher" | P0 | ⬜ |
| 47 | QAT-047 | POST /quiz/{id}/save-answer | POST | Save answer for a question | question_id + answer (option_id) provided | Answer saved to session + checkpoint DB; JSON `{'ok': true}` | P0 | ⬜ |
| 48 | QAT-048 | POST /quiz/{id}/save-answer | POST | Clear saved answer | answer = null or '' | Answer removed from session; checkpoint updated | P1 | ⬜ |
| 49 | QAT-049 | POST /quiz/{id}/save-answer | POST | Save answer with question_idx | question_idx provided alongside answer | Checkpoint updated with current_question_idx | P1 | ⬜ |
| 50 | QAT-050 | POST /quiz/{id}/checkpoint | POST | Save checkpoint state | current_question_idx + flagged_question_ids + answered_question_ids | Checkpoint upserted to DB | P0 | ⬜ |
| 51 | QAT-051 | POST /quiz/{id}/checkpoint | POST | No active attempt | No session attempt_id | JSON: 422 `{'ok': false, 'error': 'No active attempt'}` | P1 | ⬜ |
| 52 | QAT-052 | POST /quiz/{id}/log | POST | Log security violation event | event_code = 'VIOLATION' | Event logged in lms_attempt_activity_logs | P0 | ⬜ |
| 53 | QAT-053 | POST /quiz/{id}/log | POST | Unrecognized event code silently skipped | event_code = 'NONEXISTENT' | Silently skipped; no error returned; JSON 200 | P1 | ⬜ |
| 54 | QAT-054 | POST /quiz/{id}/log | POST | No active attempt | No session attempt_id | JSON: 422 `{'ok': false}` | P1 | ⬜ |
| 55 | QAT-055 | — | — | Parent user attempts quiz access | User type = PARENT, resolves child student | Student context resolved; flow proceeds normally | P1 | ⬜ |
| 56 | QAT-056 | — | — | Parent with no linked student | Parent role but no child resolution | abort or studentId = 0, 403 | P1 | ⬜ |

## 6. Business Rules Coverage

| BR-ID | Coverage | TC IDs |
|-------|----------|--------|
| BR-STP-020 (Cut-off date) | Covered | QAT-003, QAT-007 |
| BR-STP-027 (Max attempts) | Covered | QAT-012, QAT-013, QAT-016, QAT-017, QAT-022, QAT-030 |

## 7. Validation Coverage

| Validation | Type | TC IDs |
|-----------|------|--------|
| Allocation existence | Security | QAT-007, QAT-018, QAT-043 |
| Student profile exists | Data | QAT-010 |
| Hard lock (already submitted) | Workflow | QAT-008, QAT-013, QAT-021, QAT-029 |
| Max attempts cap | Workflow | QAT-012, QAT-017, QAT-022, QAT-030 |
| Timer expiry + grace period | Workflow | QAT-015, QAT-023, QAT-031 |
| Session consistency | Concurrency | QAT-020, QAT-032 |
| Negative marking floor | Calculation | QAT-033 |
| Auto-publish gating | Permission | QAT-034, QAT-035 |
| Remedial generation preconditions | Business | QAT-036, QAT-037, QAT-038 |
| PDF result availability | Data | QAT-044, QAT-045, QAT-046 |

## 8. FSM Coverage

| Transition | TC IDs |
|-----------|--------|
| NOT_STARTED → IN_PROGRESS | QAT-011, QAT-016 |
| IN_PROGRESS → SUBMITTED | QAT-026, QAT-027, QAT-028, QAT-033 |
| IN_PROGRESS → ABANDONED (timer) | QAT-015, QAT-023 |
| IN_PROGRESS → IN_PROGRESS (checkpoint) | QAT-050 |
| SUBMITTED → (no further) | QAT-029, QAT-013 |

## 9. Concurrency Coverage

| Scenario | TC IDs |
|----------|--------|
| Double submit (race) | QAT-029 |
| Session lost mid-attempt | QAT-020, QAT-032 |
| Two tabs simultaneous start | QAT-014, QAT-029 |

## 10. Error / Exception Coverage

| Scenario | TC IDs |
|----------|--------|
| 403 — No allocation | QAT-007, QAT-018, QAT-043 |
| 403 — Missing student profile | QAT-010 |
| 404 — Non-existent quiz | QAT-009 |
| 302 — Already submitted | QAT-008, QAT-013, QAT-021 |
| 302 — Max attempts | QAT-012, QAT-017, QAT-022, QAT-030 |
| 302 — Attempt expired | QAT-015, QAT-023 |
| 422 — No active attempt (checkpoint/log) | QAT-051, QAT-054 |
| 302 — PDF not available | QAT-045, QAT-046 |
| Non-fatal remedial failure | QAT-038 |

---
*Generated from: `StudentQuizAttemptController.php`, `STP_FRD_Complete_2026-06-30.md`, `pgdatabase/Backup/4-Module_Requirement/StudentPortal/learning/quiz_attempt.md`*
