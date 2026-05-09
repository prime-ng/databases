# Mobile SRS — Batch 05 (Assessments — Quiz · Quest · Exam · Results)

> Index: `02_mobile_srs_index.md`. Features: F-050, F-051, F-052, F-053, F-054.

---

## F-050: Quiz List + Take Quiz (Student)

### 1. Overview
List of available / upcoming / completed quizzes. Take a quiz inside the app: question paper, timer, auto-submit on timeout, immediate score (if quiz is auto-graded). Module **LmsQuiz** is the most-mature LMS module (~72%).

### 2. User Stories
- **US-050.1** *As a student, I take a 10-minute formative quiz between classes.*
  - Edge — connectivity drop mid-quiz: state preserved locally; resume from last answer; timer continues server-authoritative.
- **US-050.2** *As a student, I see my score and explanation immediately for auto-graded MCQ quizzes.*

### 3. Functional Requirements
- **FR-050.1** Quiz attempt requires server-issued attempt token; token bound to student_id, quiz_id, started_at.
- **FR-050.2** Timer authoritative on server; client shows remaining ticked from `expires_at` provided in attempt response.
- **FR-050.3** Auto-submit on timer expiry with whatever answers captured.
- **FR-050.4** Each answer save is idempotent (`answer_key = attempt_id:question_id`).
- **FR-050.5** Mass-assignment fix (D25/D30) on quiz attempt controllers (BG-39, BG-40).

### 4. Screen Specifications

#### S-050.1 — Quiz list
Tabs: Upcoming / In progress / Completed. List rows with subject, duration, questions count, due-by.

#### S-050.2 — Attempt
```
┌──────────────────────────────────┐
│ ⏱ 04:32  · Q 3/10               │
│                                  │
│ Q: Which of these is …           │
│ ○ Option A                       │
│ ◉ Option B                       │
│ ○ Option C                       │
│                                  │
│ [Prev]              [Save & Next]│
└──────────────────────────────────┘
```

#### S-050.3 — Result
Score, accuracy, per-question correctness (if visible), retry option (if config allows).

States: loading, error, offline (block start; in-progress: queued auto-save).

### 5. API Contracts

#### `GET /api/mobile/v1/quizzes?status=`
- **Status:** REUSE (route prefix typo `lms-quize` cosmetic). Module: LmsQuiz.

#### `POST /api/mobile/v1/quizzes/{id}/attempt`
- Returns attempt token + `expires_at` + paginated questions.

#### `PATCH /api/mobile/v1/quizzes/attempts/{attempt_id}/answers`
- Body: `{ question_id, answer }`. Idempotent.

#### `POST /api/mobile/v1/quizzes/attempts/{attempt_id}/submit`
- Returns score + breakdown (if auto-graded).

### 6. Data Model
```sql
cache_quiz_attempt (attempt_id PRIMARY KEY, payload_json, expires_at)
pending_writes  feature_id='F-050' (queued answer saves)
```

### 7. Offline Behavior
- Cannot start a quiz offline.
- In-progress: answers stored locally + queued for save; on reconnect, drained.
- If timer expires while offline: client shows "submitted offline — server may auto-submit"; on reconnect server reconciles.

### 8. Push Notifications
- `QUIZ_ASSIGNED` (consumer).

### 9. Permissions & Security
- Authorize: student in class allocated to quiz.
- BG-NEW-002 / SEC-NEW-001 (hardcoded API keys in QuestionBank module — rotated separately).
- Audit: `QUIZ_ATTEMPT_STARTED`, `_SUBMITTED`.

### 10. Non-Functional Requirements
- Question render < 300 ms.
- Localization: `f050.cta.{prev,next,submit}`, `f050.timer.expired`.
- Analytics: `quiz_attempt_start`, `_submit`, `_timeout`.

### 11. Acceptance Criteria
- **AC-050.1** Timer expiry triggers submit even if user is on a question; unanswered questions saved as null.
- **AC-050.2** Reattempt blocked when `attempts_used >= attempts_allowed`.
- **AC-050.3** Mid-quiz network drop preserves state; resuming the screen from background continues without loss.

### 12. Dependencies
- F-002. LmsQuiz module.

### 13. Out of Scope
- Adaptive quiz, branching — v1.2.
- Voice-typed answers — v1.2.

---

## F-051: Quest Attempt (Student, P1)

### 1. Overview
Quests are gamified activities (LmsQuests module ~52%). Similar attempt mechanics to quiz; smaller-grain, tied to lesson topics.

### 2. User Stories
- **US-051.1** *As a student, I attempt a 5-question quest mid-lesson.*

### 3. Functional Requirements
- **FR-051.1** Pre-req: SEC-QZT-002 (commented Gate) MUST be uncommented.
- **FR-051.2** Same attempt-token mechanics as F-050.
- **FR-051.3** Reward / XP shown on completion (if module supports).

### 4. Screen Specifications
List + attempt + result, mirroring F-050.

### 5. API Contracts

#### `POST /api/mobile/v1/quests/{id}/attempt`
- **Status:** MODIFY (Gate uncomment, BG-39/40).

### 6. Data Model
`cache_quest_attempt`.

### 7. Offline Behavior
Same model as F-050.

### 8. Push Notifications
Optional `QUEST_AVAILABLE` (P2).

### 9. Permissions & Security
- SEC-QZT-002 fix (commented Gate).
- Audit: `QUEST_ATTEMPT_*`.

### 10. Non-Functional Requirements
As F-050.

### 11. Acceptance Criteria
- **AC-051.1** Quest accessible only to allocated student.
- **AC-051.2** Reattempt restriction honored.

### 12. Dependencies
- F-002. LmsQuests module gate fix.

### 13. Out of Scope
- Quest authoring — web-only.

---

## F-052: Exam Schedule View (Student / Parent)

### 1. Overview
Read-only list of upcoming exams (subject, date, time, hall, syllabus chapters).

### 2. User Stories
- **US-052.1** *As a student / parent, I want a one-page exam schedule, so I plan study weeks.*
- **US-052.2** *Tap exam → see syllabus + admit card link (CC-05).*

### 3. Functional Requirements
- **FR-052.1** Endpoint scoped to student's class-section; parent variant uses `X-Active-Student-Id`.
- **FR-052.2** Pulls from `lms_exam_*` tables; soft-deletes filtered.
- **FR-052.3** Admit card link via signed URL (BG-33).

### 4. Screen Specifications
Vertical timeline: each exam day grouped.

### 5. API Contracts

#### `GET /api/mobile/v1/exams/schedule`
- **Status:** NEW. Module: LmsExam.

### 6. Data Model
`cache_exam_schedule`.

### 7. Offline Behavior
Read-only cached.

### 8. Push Notifications
- `EXAM_REMINDER` T-24h, T-1h (consumer).

### 9. Permissions & Security
- SEC-EXM-005 (IDOR on grievance review) is unrelated to read but module must be hardened end-to-end.
- BG-12 / BR-PPT-012 for parent variant.

### 10. Non-Functional Requirements
- < 1 s p50 cached.
- Localization: `f052.title`, `f052.label.*`.

### 11. Acceptance Criteria
- **AC-052.1** Parent reading another child's schedule → 403.
- **AC-052.2** Admit card link works only via signed URL.

### 12. Dependencies
- F-002, F-005. LmsExam module.

### 13. Out of Scope
- Add-to-calendar; deferred (Calendar permission).

---

## F-053: Online Exam Player (Student, P1 — Q-8)

### 1. Overview
Take an online exam on mobile. **High-risk feature** — Q-8 open: recommend deferring to v1.1, restricting v1.0 to schedule + results only.

### 2. User Stories
- **US-053.1** *As a student in remote-learning context, I take an online exam on my phone with proctor mode (camera + fullscreen + no-notification).*

### 3. Functional Requirements
- **FR-053.1** Anti-cheat:
  - Foreground-service pin; backgrounding the app → auto-submit (configurable per exam).
  - Android `FLAG_SECURE` to prevent screenshot.
  - iOS `ScreenCaptureKit` detection if available.
  - Disable copy / paste in question text and answer fields.
- **FR-053.2** Camera proctor (optional per exam config) — periodic snapshot upload.
- **FR-053.3** Strict timer (server-authoritative, same as F-050).
- **FR-053.4** Single-attempt enforced.
- **FR-053.5** Pre-req: SEC-STP-008 IDOR on `StudentExamAttemptController::attempt` (BG-14).

### 4. Screen Specifications

#### S-053.1 — Pre-flight
Permissions check + agreement to proctor terms; "Start" disabled until all green.

#### S-053.2 — Exam
Question + answer; warning banner if backgrounded.

#### S-053.3 — Submission confirm
Final review screen; submit; on submit lock further attempts.

### 5. API Contracts

#### `POST /api/mobile/v1/exams/{id}/attempt`
- **Status:** MODIFY (BG-14, BG-22). Module: LmsExam / StudentPortal.

Mirrors F-050 attempt mechanics + proctor snapshot upload `POST /exams/attempts/{aid}/proctor` (multipart).

### 6. Data Model
`cache_exam_attempt`.

### 7. Offline Behavior
Block start when offline; once started, partial offline tolerance like F-050; backgrounding policy still triggers auto-submit.

### 8. Push Notifications
None during attempt (suppressed to avoid distraction).

### 9. Permissions & Security
- OS: Camera (if proctor), Notifications (suppressed mid-exam).
- SEC-STP-008 fix (BG-14).
- Audit: `EXAM_ATTEMPT_STARTED / SUBMITTED / FORCED_SUBMIT`.
- Jailbreak/root → block.

### 10. Non-Functional Requirements
- Question render < 300 ms; proctor snapshot upload non-blocking.
- Localization: `f053.alert.*`.
- Analytics: `exam_attempt_start`, `_forced_submit`, `_proctor_violation`.

### 11. Acceptance Criteria
- **AC-053.1** Backgrounding the app for > 3 s triggers auto-submit on configured exams.
- **AC-053.2** Tampered exam_id (other student's exam) → 403 (BG-14 fix).
- **AC-053.3** Jailbroken / rooted device → blocking dialog "This device cannot run secure exams".

### 12. Dependencies
- F-052. BG-14, BG-22.

### 13. Out of Scope at v1
- Confirmed deferred to v1.1 pending Q-8 decision.

---

## F-054: Results / Report Card (Student / Parent)

### 1. Overview
View term results, exam scorecards, marksheet PDF, HPC summary tile (deep-link to F-090).

### 2. User Stories
- **US-054.1** *As a student / parent, I see my term scorecard with subjects, marks, grades.*
- **US-054.2** *I download the marksheet PDF.*

### 3. Functional Requirements
- **FR-054.1** Endpoint returns published exam results only (`status='PUBLISHED'`).
- **FR-054.2** Marksheet PDF via signed URL (BG-33).
- **FR-054.3** Parent variant via active-child header.

### 4. Screen Specifications

#### S-054.1 — Term scorecard
```
┌──────────────────────────────────┐
│ Term 1 · 2026-27                  │
│ Math    87 / 100   A             │
│ Hindi   78 / 100   B+            │
│ Sci     92 / 100   A+            │
│ ...                              │
│ Overall  84.6%   A               │
│ [Download marksheet] [HPC →]    │
└──────────────────────────────────┘
```

States: loading, empty (no published results), error, offline (cached).

### 5. API Contracts

#### `GET /api/mobile/v1/exams/results?term_id=`
- **Status:** REUSE / NEW.

### 6. Data Model
`cache_exam_results` keyed by term.

### 7. Offline Behavior
Read-only cached.

### 8. Push Notifications
Consumes `EXAM_RESULT_PUBLISHED`.

### 9. Permissions & Security
- Per-student scoping; parent via active-child header.
- BG-33 signed URLs for marksheet.

### 10. Non-Functional Requirements
- Cached < 300 ms; PDF first-page < 3.5 s.
- Localization: `f054.label.{overall,grade,download}`.

### 11. Acceptance Criteria
- **AC-054.1** Unpublished results not visible.
- **AC-054.2** Marksheet URL is single-use signed URL — direct fetch by URL only works while signed.

### 12. Dependencies
- F-002, F-005. LmsExam, Hpc, MarksheetGeneration modules.

### 13. Out of Scope
- Term-over-term comparison chart — v1.1.
- Subject-wise teacher remark threading — v1.2.

---

> End Batch 05. Continue to `02_mobile_srs_batch_06.md` (Fees + Transport).
