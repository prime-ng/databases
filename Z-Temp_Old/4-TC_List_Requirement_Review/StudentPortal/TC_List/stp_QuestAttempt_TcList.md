# STP — Quest Attempt (stp_QuestAttempt) — TC List

## 1. TC List ID
`stp_QuestAttempt_TC`

## 2. Feature Name
Quest Attempt (Student Quest Player)

## 3. Module Code
`stp_QuestAttempt` — StudentPortal

## 4. FRD REQ Mapping
REQ-STP-032, BR-STP-028, BR-STP-020

## 5. Route / Endpoint Coverage

| # | TC ID | Route | Method | Test Scenario | Input / Condition | Expected Result | Priority | Status |
|---|-------|-------|--------|---------------|-------------------|----------------|----------|--------|
| 1 | QST-001 | GET /my-quests | GET | Student with valid allocations views quest list | Student has CLASS/SECTION/STUDENT allocations for active quests | Quest cards displayed with badge, subject, title, attempts used | P0 | ⬜ |
| 2 | QST-002 | GET /my-quests | GET | Student with no allocations views empty list | No quest allocations | Empty state displayed | P1 | ⬜ |
| 3 | QST-003 | GET /my-quests | GET | Expired allocation excluded | Allocation has cut_off_date in past | Quest not shown in list | P0 | ⬜ |
| 4 | QST-004 | GET /my-quests | GET | Duplicate allocations deduplicated | Same quest allocated to both CLASS and SECTION | Quest card appears only once in list | P1 | ⬜ |
| 5 | QST-005 | GET /quest/{id}/instructions | GET | Student views quest instructions | Valid quest ID with active allocation | Instructions page loaded with quest metadata, Start button visible | P0 | ⬜ |
| 6 | QST-006 | GET /quest/{id}/instructions | GET | Student without allocation gets 403 | Quest ID not allocated to student | 403 Forbidden: "You do not have access to this quest." | P0 | ⬜ |
| 7 | QST-007 | GET /quest/{id}/instructions | GET | Already completed quest — redirect | hasSubmittedAttempt = true | Redirect to quest result with warning | P0 | ⬜ |
| 8 | QST-008 | GET /quest/{id}/instructions | GET | Non-existent quest ID | Quest not in database | 404 Not Found | P0 | ⬜ |
| 9 | QST-009 | POST /quest/{id}/start | POST | First-time student starts quest | No previous attempts, within max_attempts limit | Attempt record created (IN_PROGRESS, assessment_type = QUEST), redirect to attempt page | P0 | ⬜ |
| 10 | QST-010 | POST /quest/{id}/start | POST | Start quest when max attempts reached | attempts_used >= max_attempts cap | Redirect to result with warning: "Max attempts reached." | P0 | ⬜ |
| 11 | QST-011 | POST /quest/{id}/start | POST | Start quest when already submitted | hasSubmittedAttempt = true | Redirect to result with warning: "You have already completed this quest." | P0 | ⬜ |
| 12 | QST-012 | POST /quest/{id}/start | POST | Resume existing IN_PROGRESS attempt | Existing IN_PROGRESS attempt found, not expired | Session set, redirect to attempt page | P0 | ⬜ |
| 13 | QST-013 | POST /quest/{id}/start | POST | Expired IN_PROGRESS attempt abandoned | Existing attempt exceeds time limit + grace | Attempt marked ABANDONED, new attempt created (if cap not reached) | P0 | ⬜ |
| 14 | QST-014 | GET /quest/{id}/attempt | GET | View active attempt page | IN_PROGRESS attempt exists, session has attempt_id | Attempt page loaded with quest questions, timer, saved answers | P0 | ⬜ |
| 15 | QST-015 | GET /quest/{id}/attempt | GET | No session attempt_id — auto-start | Student navigates directly to attempt URL without starting | Redirect to start() which creates attempt or aborts | P0 | ⬜ |
| 16 | QST-016 | GET /quest/{id}/attempt | GET | Already submitted — redirect to result | hasSubmittedAttempt = true | Redirect to quest result with warning | P0 | ⬜ |
| 17 | QST-017 | GET /quest/{id}/attempt | GET | Expired attempt shows warning | markAbandonedIfExpired returns true | Redirect to instructions with expiry warning, session cleared | P0 | ⬜ |
| 18 | QST-018 | GET /quest/{id}/attempt | GET | Randomized question order | quest.is_randomized = true | Questions shuffled deterministically based on attempt ID | P1 | ⬜ |
| 19 | QST-019 | GET /quest/{id}/attempt | GET | Checkpoint recovery (MCQ answers) | DB checkpoint exists with MCQ checkpoint_data | MCQ answers pre-populated from DB checkpoint | P0 | ⬜ |
| 20 | QST-020 | POST /quest/{id}/submit | POST | MCQ-only quest — all correct answers | All MCQ answers correct, no descriptive questions | Attempt SUBMITTED; auto-grading complete; result created; XP earned | P0 | ⬜ |
| 21 | QST-021 | POST /quest/{id}/submit | POST | MCQ-only quest — mixed answers | Mix of correct, incorrect, unattempted | Correct marks; negative marking deducted; percentage/threshold computed | P0 | ⬜ |
| 22 | QST-022 | POST /quest/{id}/submit | POST | Quest with descriptive answers (text only) | MCQ + text_answers provided, no files | MCQ auto-graded; descriptive saved with is_evaluated = false; message: "evaluated by teacher" | P0 | ⬜ |
| 23 | QST-023 | POST /quest/{id}/submit | POST | Quest with descriptive answers (text + file) | MCQ + text_answers + file upload per descriptive question | Descriptive file stored via StorageService; attachment_data saved | P0 | ⬜ |
| 24 | QST-024 | POST /quest/{id}/submit | POST | File upload exceeds 5 MB | File > 5120 KB | 422 validation error: "Each file must be under 5 MB." | P0 | ⬜ |
| 25 | QST-025 | POST /quest/{id}/submit | POST | File upload invalid type | .exe or .mp4 file | 422 validation error: "Allowed: PDF, JPG, PNG." | P0 | ⬜ |
| 26 | QST-026 | POST /quest/{id}/submit | POST | All MCQs unattempted (no descriptive) | Empty answers array, no descriptive questions | MCQ marks = 0; percentage = 0; is_passed = false | P0 | ⬜ |
| 27 | QST-027 | POST /quest/{id}/submit | POST | Already submitted (double submit) | Two simultaneous POST /submit requests | First succeeds; second redirects with warning "already completed" | P0 | ⬜ |
| 28 | QST-028 | POST /quest/{id}/submit | POST | Max attempts reached at submit time | attempts_used >= cap | Redirect with warning, no grading | P0 | ⬜ |
| 29 | QST-029 | POST /quest/{id}/submit | POST | Session lost mid-attempt (fallback INSERT) | No existing attempt ID found | Fallback attempt record created; submission processed | P1 | ⬜ |
| 30 | QST-030 | POST /quest/{id}/submit | POST | Negative marking applied correctly | quest.negative_marks = 1; wrong MCQ answers | Marks deducted; MCQ marksObtained = max(0.0, computed) | P0 | ⬜ |
| 31 | QST-031 | POST /quest/{id}/submit | POST | Student passes — XP earned (100) | percentage >= passing_percentage, MCQ-only | Message: "You earned 100 XP!"; result shows xp_earned = 100 | P0 | ⬜ |
| 32 | QST-032 | POST /quest/{id}/submit | POST | Student fails — no XP | percentage < passing_percentage | No XP message; xp_earned = 0 | P1 | ⬜ |
| 33 | QST-033 | POST /quest/{id}/submit | POST | Descriptive quest — recommendation NOT dispatched | Quest has descriptive questions | QuizQuestResultPublished NOT dispatched | P1 | ⬜ |
| 34 | QST-034 | POST /quest/{id}/submit | POST | MCQ-only quest — recommendation dispatched | Quest is fully MCQ | QuizQuestResultPublished dispatched with shouldPublish flag | P1 | ⬜ |
| 35 | QST-035 | POST /quest/{id}/submit | POST | Late submission within grace period | Timer expired but within 5-min grace | Still processed; late_by_s logged as warning | P1 | ⬜ |
| 36 | QST-036 | GET /quest/{id}/result | GET | View MCQ-only quest result | SUBMITTED attempt exists; result record exists | Score card: marks, percentage, grade, correct/wrong/unattempted, XP, badge | P0 | ⬜ |
| 37 | QST-037 | GET /quest/{id}/result | GET | View descriptive quest result | SUBMITTED attempt with descriptive answers | Score card with MCQ results + descriptive answer review with files | P0 | ⬜ |
| 38 | QST-038 | GET /quest/{id}/result | GET | Descriptive answer shows attachment_data files | File uploaded via StorageService | File URL, name, size displayed in descriptive answer section | P1 | ⬜ |
| 39 | QST-039 | GET /quest/{id}/result | GET | Descriptive answer falls back to legacy Spatia media | No attachment_data but has descriptive_files | Legacy media files displayed | P2 | ⬜ |
| 40 | QST-040 | GET /quest/{id}/result | GET | No attempt yet — no result | Student has no SUBMITTED/TIMEOUT attempts | Result section = null; empty state displayed | P1 | ⬜ |
| 41 | QST-041 | GET /quest/{id}/result | GET | XP already awarded on subsequent attempt | 2nd passed attempt, 1st also passed | xp_already_awarded = true; no duplicate XP celebration | P1 | ⬜ |
| 42 | QST-042 | GET /quest/{id}/result/pdf | GET | Download published result PDF | Result published, is_published = true | PDF file streamed with quest result data | P0 | ⬜ |
| 43 | QST-043 | GET /quest/{id}/result/pdf | GET | No attempt — redirect with warning | No SUBMITTED/TIMEOUT attempt | Redirect to result with warning "No result available" | P0 | ⬜ |
| 44 | QST-044 | GET /quest/{id}/result/pdf | GET | Result not published — redirect | Result record exists but is_published = false | Redirect to result with warning "not released by teacher" | P0 | ⬜ |
| 45 | QST-045 | POST /quest/{id}/save-answer | POST | Save MCQ answer | question_id + answer (option_id) | Answer saved to session + checkpoint DB | P0 | ⬜ |
| 46 | QST-046 | POST /quest/{id}/save-answer | POST | Clear saved answer | answer = null or '' | Answer removed from session; checkpoint updated | P1 | ⬜ |
| 47 | QST-047 | POST /quest/{id}/checkpoint | POST | Save checkpoint state | current_question_idx + flagged + answered IDs | Checkpoint upserted to lms_attempt_checkpoints | P0 | ⬜ |
| 48 | QST-048 | POST /quest/{id}/checkpoint | POST | No active attempt | No session attempt_id | JSON: 422 `{'ok': false, 'error': 'No active attempt'}` | P1 | ⬜ |
| 49 | QST-049 | POST /quest/{id}/log | POST | Log violation event | event_code = 'VIOLATION' | Event logged in lms_attempt_activity_logs | P0 | ⬜ |
| 50 | QST-050 | POST /quest/{id}/log | POST | Unrecognized event code | event_code = 'NONEXISTENT' | Silently skipped; JSON 200 | P1 | ⬜ |
| 51 | QST-051 | POST /quest/{id}/submit | POST | File upload failure (StorageService error) | Valid file but StorageService throws | Answer saved without file; error logged | P1 | ⬜ |

## 6. Business Rules Coverage

| BR-ID | Coverage | TC IDs |
|-------|----------|--------|
| BR-STP-020 (Cut-off date) | Covered | QST-003, QST-006 |
| BR-STP-028 (Max attempts) | Covered | QST-010, QST-011, QST-028 |

## 7. Validation Coverage

| Validation | Type | TC IDs |
|-----------|------|--------|
| Allocation existence | Security | QST-006 |
| Student profile exists | Data | (implied in multiple) |
| Hard lock (already submitted) | Workflow | QST-007, QST-011, QST-016, QST-027 |
| Max attempts cap | Workflow | QST-010, QST-028 |
| Timer expiry + grace period | Workflow | QST-013, QST-017, QST-035 |
| File upload: max size (5 MB) | Validation | QST-024 |
| File upload: allowed MIME types | Validation | QST-025 |
| Session consistency | Concurrency | QST-015, QST-029 |
| Negative marking floor | Calculation | QST-030 |
| XP reward gating | Business | QST-031, QST-032 |
| Recommendation dispatch gating | Business | QST-033, QST-034 |

## 8. FSM Coverage

| Transition | TC IDs |
|-----------|--------|
| NOT_STARTED → IN_PROGRESS | QST-009 |
| IN_PROGRESS → SUBMITTED (MCQ-only) | QST-020, QST-021 |
| IN_PROGRESS → SUBMITTED (with descriptive) | QST-022, QST-023 |
| IN_PROGRESS → ABANDONED (timer) | QST-013, QST-017 |
| SUBMITTED → (no further) | QST-027, QST-011 |

## 9. Concurrency Coverage

| Scenario | TC IDs |
|----------|--------|
| Double submit (race) | QST-027 |
| Session lost mid-attempt | QST-015, QST-029 |
| File upload concurrent | QST-023, QST-051 |

## 10. Error / Exception Coverage

| Scenario | TC IDs |
|----------|--------|
| 403 — No allocation | QST-006 |
| 404 — Non-existent quest | QST-008 |
| 302 — Already submitted | QST-007, QST-011, QST-016 |
| 302 — Max attempts | QST-010, QST-028 |
| 302 — Attempt expired | QST-013, QST-017 |
| 422 — File too large | QST-024 |
| 422 — Invalid file type | QST-025 |
| 422 — No active attempt (checkpoint/log) | QST-048, QST-050 |
| 302 — PDF not available | QST-043, QST-044 |
| Non-fatal file upload failure | QST-051 |

---
*Generated from: `StudentQuestAttemptController.php`, `STP_FRD_Complete_2026-06-30.md`, `pgdatabase/Backup/4-Module_Requirement/StudentPortal/learning/quest_attempt.md`*
