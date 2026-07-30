# STP — Online Exam Attempt (stp_OnlineExamAttempt) — TC List

## 1. TC List ID
`stp_OnlineExamAttempt_TC`

## 2. Feature Name
Online Exam Attempt (Student Exam Player)

## 3. Module Code
`stp_OnlineExamAttempt` — StudentPortal

## 4. FRD REQ Mapping
REQ-STP-030, BR-STP-023, BR-STP-024, BR-STP-025, BR-STP-026

## 5. Route / Endpoint Coverage

| # | TC ID | Route | Method | Test Scenario | Input / Condition | Expected Result | Priority | Status |
|---|-------|-------|--------|---------------|-------------------|----------------|----------|--------|
| 1 | OEA-001 | GET /online-exams | GET | Student with valid allocations views exam list | Student has CLASS/SECTION/STUDENT allocations for active exams | Exam list displayed with title, subject, scheduled date, attempt status | P0 | ⬜ |
| 2 | OEA-002 | GET /online-exams | GET | Student with no allocations views empty list | No exam allocations | Empty state displayed | P1 | ⬜ |
| 3 | OEA-003 | GET /online-exams | GET | Completed exam shows attempt info | Student has submitted attempt | Attempt status shown (submitted/evaluated/result published) | P0 | ⬜ |
| 4 | OEA-004 | GET /online-exam/{id}/instructions | GET | Student views exam instructions | Valid exam paper ID with active allocation | Instructions page loaded with paper metadata, sections, Start button | P0 | ⬜ |
| 5 | OEA-005 | GET /online-exam/{id}/instructions | GET | Student without allocation gets 403 | Exam paper not allocated to student | 403 Forbidden: "You do not have access to this exam." | P0 | ⬜ |
| 6 | OEA-006 | GET /online-exam/{id}/instructions | GET | Already submitted exam — shows info | Student has existing SUBMITTED attempt | Attempt info displayed on instructions page; no Start button | P1 | ⬜ |
| 7 | OEA-007 | GET /online-exam/{id}/instructions | GET | Non-existent exam paper ID | Paper not in database | 404 Not Found | P0 | ⬜ |
| 8 | OEA-008 | POST /online-exam/{id}/start | POST | First-time student starts exam | No previous attempts | Attempt record created (IN_PROGRESS), redirect to attempt page | P0 | ⬜ |
| 9 | OEA-009 | POST /online-exam/{id}/start | POST | Already submitted exam — redirect to results | Existing SUBMITTED/EVALUATED/RESULT_PUBLISHED attempt | Redirect to results with info: "already submitted" | P0 | ⬜ |
| 10 | OEA-010 | POST /online-exam/{id}/start | POST | Resume existing IN_PROGRESS attempt | IN_PROGRESS attempt exists from previous session | Session set, redirect to attempt page | P0 | ⬜ |
| 11 | OEA-011 | POST /online-exam/{id}/start | POST | No allocation — 403 | Student not allocated | 403 Forbidden | P0 | ⬜ |
| 12 | OEA-012 | GET /online-exam/{id}/attempt | GET | View active exam attempt page | IN_PROGRESS attempt exists, session has attempt_id | Attempt page loaded with section-wise questions, timer, saved answers | P0 | ⬜ |
| 13 | OEA-013 | GET /online-exam/{id}/attempt | GET | No session attempt_id — auto-start | Student navigates directly to attempt URL | Redirect to start() which creates attempt or aborts | P0 | ⬜ |
| 14 | OEA-014 | GET /online-exam/{id}/attempt | GET | Already submitted — redirect to results | Existing SUBMITTED/EVALUATED/RESULT_PUBLISHED attempt | Redirect to results with info message | P0 | ⬜ |
| 15 | OEA-015 | GET /online-exam/{id}/attempt | GET | Timer computed correctly (remaining seconds) | Timer enforced, 60 min exam, 10 min elapsed | totalTimerSecs ≈ 50 min remaining (minus elapsed) | P0 | ⬜ |
| 16 | OEA-016 | GET /online-exam/{id}/attempt | GET | Randomized questions within sections | paper is_randomized = true | Questions shuffled within each section; section order preserved | P1 | ⬜ |
| 17 | OEA-017 | GET /online-exam/{id}/attempt | GET | Shuffled MCQ options | paper shuffle_options = true | MCQ options in different order per question (seeded by attempt+question) | P1 | ⬜ |
| 18 | OEA-018 | GET /online-exam/{id}/attempt | GET | Checkpoint recovery loads saved answers | DB checkpoint exists with checkpoint_data | Saved answers pre-populated from DB checkpoint | P0 | ⬜ |
| 19 | OEA-019 | POST /online-exam/{id}/submit | POST | MCQ-only exam — submit with all correct answers | All MCQ answers correct, no descriptive | Attempt status = SUBMITTED; result record created; is_published = exam.is_result_published | P0 | ⬜ |
| 20 | OEA-020 | POST /online-exam/{id}/submit | POST | MCQ-only exam — mixed answers | Mix of correct, incorrect, unattempted | Auto-grading computes marks; negative marking for wrong answers | P0 | ⬜ |
| 21 | OEA-021 | POST /online-exam/{id}/submit | POST | Exam with descriptive questions (text + files) | MCQ + text_answers + file uploads | Status = EVALUATION_PENDING; MCQ graded; descriptive saved with is_evaluated = false; no result record | P0 | ⬜ |
| 22 | OEA-022 | POST /online-exam/{id}/submit | POST | All descriptive (no MCQ) | Only SHORT_ANSWER/LONG_ANSWER questions | Status = EVALUATION_PENDING; all answers saved for teacher evaluation | P0 | ⬜ |
| 23 | OEA-023 | POST /online-exam/{id}/submit | POST | File upload exceeds 5 MB | File > 5120 KB | 422 validation error: "Each file must be under 5 MB." | P0 | ⬜ |
| 24 | OEA-024 | POST /online-exam/{id}/submit | POST | File upload invalid type | .exe or .mp4 file | 422 validation error: "Allowed: PDF, JPG, PNG." | P0 | ⬜ |
| 25 | OEA-025 | POST /online-exam/{id}/submit | POST | Already submitted (double submit) | Two simultaneous POST /submit requests | First succeeds; second redirects with "Already submitted." | P0 | ⬜ |
| 26 | OEA-026 | POST /online-exam/{id}/submit | POST | Session lost mid-exam (fallback INSERT) | No existing attempt ID found | Fallback attempt record created; submission processed | P1 | ⬜ |
| 27 | OEA-027 | POST /online-exam/{id}/submit | POST | Late submission within grace period | Timer expired but within 5-min grace | Still processed; late_by_s logged as warning | P1 | ⬜ |
| 28 | OEA-028 | POST /online-exam/{id}/submit | POST | Violation count from DB (not client) | Client sends violation_count = 0; DB has 3 VIOLATION events | Server records violation_count = 3 from DB query | P0 | ⬜ |
| 29 | OEA-029 | POST /online-exam/{id}/submit | POST | Negative marking applied | paper.negative_marks = 1; wrong MCQ answers | Marks deducted; floored at 0.0 | P0 | ⬜ |
| 30 | OEA-030 | POST /online-exam/{id}/submit | POST | Result auto-published (MCQ-only) | exam.is_result_published = true | Result record created with is_published = true, published_at set | P0 | ⬜ |
| 31 | OEA-031 | POST /online-exam/{id}/submit | POST | Result NOT auto-published (MCQ-only) | exam.is_result_published = false | Result record created with is_published = false | P1 | ⬜ |
| 32 | OEA-032 | GET /online-exam/{id}/result | GET | View published exam result | Result published (is_result_published = true) | Score card with section-wise breakdown, marks, percentage, grade, division | P0 | ⬜ |
| 33 | OEA-033 | GET /online-exam/{id}/result | GET | Result not yet published — pending screen | is_result_published = false | Clock icon + "Results will be published by your teacher" message | P0 | ⬜ |
| 34 | OEA-034 | GET /online-exam/{id}/result | GET | Section-wise marks breakdown | Multiple sections with different marks | Section-wise table showing obtained/max per section | P0 | ⬜ |
| 35 | OEA-035 | GET /online-exam/{id}/result | GET | Descriptive answers review with files | Descriptive answers with attachment_data | File URLs, answer text, evaluation status shown | P1 | ⬜ |
| 36 | OEA-036 | GET /online-exam/{id}/result | GET | No attempt — redirect to results | No attempt found | Redirect to results page | P1 | ⬜ |
| 37 | OEA-037 | GET /online-exam/{id}/result | GET | AJAX request returns JSON HTML | request()->ajax() = true | JSON response with rendered HTML partial | P2 | ⬜ |
| 38 | OEA-038 | GET /online-exam/{id}/result/pdf | GET | Download published result PDF | Result published, is_published = true | PDF file streamed with exam result data and section-wise breakdown | P0 | ⬜ |
| 39 | OEA-039 | GET /online-exam/{id}/result/pdf | GET | No attempt — redirect with warning | No SUBMITTED/EVALUATED attempt | Redirect with warning "No result available" | P0 | ⬜ |
| 40 | OEA-040 | GET /online-exam/{id}/result/pdf | GET | Result not published — redirect | Result exists but is_published = false | Redirect with warning "Result not yet published." | P0 | ⬜ |
| 41 | OEA-041 | POST /online-exam/{id}/save-answer | POST | Save MCQ answer | question_id + answer (option_id) | Answer saved to session + checkpoint DB; JSON `{'ok': true}` | P0 | ⬜ |
| 42 | OEA-042 | POST /online-exam/{id}/save-answer | POST | Clear saved answer | answer = null or '' | Answer removed; checkpoint updated | P1 | ⬜ |
| 43 | OEA-043 | POST /online-exam/{id}/checkpoint | POST | Save checkpoint with answer state | current_question_idx + flagged + answered IDs + checkpoint_data (saved answers) | Full state saved to lms_attempt_checkpoints | P0 | ⬜ |
| 44 | OEA-044 | POST /online-exam/{id}/checkpoint | POST | No active attempt | No session attempt_id | JSON: 422 `{'ok': false, 'error': 'No active attempt'}` | P1 | ⬜ |
| 45 | OEA-045 | POST /online-exam/{id}/log | POST | Log violation (tab switch) | event_code = 'VIOLATION' | Event logged in lms_attempt_activity_logs | P0 | ⬜ |
| 46 | OEA-046 | POST /online-exam/{id}/log | POST | Unrecognized event code silently skipped | Unknown event_code | Silently skipped; JSON 200 | P1 | ⬜ |
| 47 | OEA-047 | POST /online-exam/{id}/log | POST | No active attempt | No session attempt_id | JSON: 422 `{'ok': false}` | P1 | ⬜ |
| 48 | OEA-048 | — | — | TimeoutStaleAttempts auto-submits stale attempt | IN_PROGRESS attempt > duration + grace period | Status changed to TIMEOUT; answers preserved | P0 | ⬜ |
| 49 | OEA-049 | — | — | Descriptive exam result pending until teacher publishes | EVALUATION_PENDING submission; teacher evaluates and publishes | Result visible after is_result_published = true | P0 | ⬜ |
| 50 | OEA-050 | — | — | Negative marking not applied to descriptive questions | Descriptive answer submitted with wrong text | Descriptive marks_obtained = 0 (not negative) | P1 | ⬜ |
| 51 | OEA-051 | — | — | Parent user attempts exam access | User type = PARENT, resolves child | Context resolved; flow proceeds normally | P1 | ⬜ |

## 6. Business Rules Coverage

| BR-ID | Coverage | TC IDs |
|-------|----------|--------|
| BR-STP-023 (Attempt uniqueness) | Covered | OEA-008, OEA-009, OEA-010, OEA-011 |
| BR-STP-024 (IN_PROGRESS saves) | Covered | OEA-041, OEA-043, OEA-044 |
| BR-STP-025 (Timer enforcement) | Covered | OEA-015, OEA-027 |
| BR-STP-026 (Violation logging) | Covered | OEA-028, OEA-045, OEA-046 |

## 7. Validation Coverage

| Validation | Type | TC IDs |
|-----------|------|--------|
| Allocation existence | Security | OEA-005, OEA-011 |
| Student profile exists | Data | (implied in multiple) |
| Hard lock (already submitted) | Workflow | OEA-009, OEA-014, OEA-025 |
| Attempt uniqueness | Concurrency | OEA-008, OEA-009, OEA-010 |
| File upload: max size (5 MB) | Validation | OEA-023 |
| File upload: allowed MIME types | Validation | OEA-024 |
| Session consistency | Concurrency | OEA-013, OEA-026 |
| Negative marking floor | Calculation | OEA-029 |
| Result publishing gate | Permission | OEA-030, OEA-031, OEA-033, OEA-032 |
| Violation count (server-trust) | Security | OEA-028 |

## 8. FSM Coverage

| Transition | TC IDs |
|-----------|--------|
| NOT_STARTED → IN_PROGRESS | OEA-008 |
| IN_PROGRESS → SUBMITTED (MCQ-only) | OEA-019, OEA-020 |
| IN_PROGRESS → EVALUATION_PENDING (descriptive) | OEA-021, OEA-022 |
| IN_PROGRESS → TIMEOUT (cron) | OEA-048 |
| SUBMITTED → (no further student transition) | OEA-025, OEA-009 |
| EVALUATION_PENDING → EVALUATED → RESULT_PUBLISHED | OEA-049 |

## 9. Concurrency Coverage

| Scenario | TC IDs |
|----------|--------|
| Double submit (race) | OEA-025 |
| Session lost mid-exam | OEA-013, OEA-026 |
| Two tabs simultaneous start | OEA-010 |

## 10. Error / Exception Coverage

| Scenario | TC IDs |
|----------|--------|
| 403 — No allocation | OEA-005, OEA-011 |
| 404 — Non-existent paper | OEA-007 |
| 302 — Already submitted | OEA-009, OEA-014 |
| 422 — File too large | OEA-023 |
| 422 — Invalid file type | OEA-024 |
| 422 — No active attempt (checkpoint/log) | OEA-044, OEA-047 |
| 302 — PDF not available | OEA-039, OEA-040 |
| 200 (pending) — Result not published | OEA-033 |

---
*Generated from: `StudentExamAttemptController.php`, `STP_FRD_Complete_2026-06-30.md`, `pgdatabase/Backup/4-Module_Requirement/StudentPortal/learning/online_exam_attempt.md`*
