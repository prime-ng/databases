# STP — My Learning Hub (LMS Dashboard)

## 1. Document Control

| Field | Value |
|-------|-------|
| **Module** | StudentPortal (STP) |
| **Feature ID** | STP-F011 |
| **Feature Name** | My Learning Hub |
| **REQ ID(s)** | REQ-STP-011 |
| **BR ID(s)** | BR-STP-019, BR-STP-020, BR-STP-021 |
| **Controller** | `StudentLmsController@index` |
| **Route** | `GET /my-learning` (named `my-learning`) |
| **View** | `studentportal::learning.index` |
| **Table Prefix** | `hmw_*`, `lms_*`, `sch_*` (reads from Homework, Exam, Quiz, Quest, Profile modules) |
| **DB Layer** | Tenant |
| **V1/V2** | — |
| **Status** | ⬜ |
| **CR** | ◌ |
| **Author** | OpenCode |
| **Date** | 2026-07-23 |

---

## 2. Feature Overview

A consolidated learning dashboard that aggregates all learning activities for the student: homework assignments, online exam allocations, quiz allocations, and quest allocations. Each section shows relevant metadata and action buttons (Start, Resume, View Result, etc.) derived from the student's attempt state.

---

## 3. Functional Requirements

### 3.1 Homework Section
- Lists all active homework assignments for the student where:
  - `student_id` matches the authenticated student.
  - `is_released = true` and `is_active = true`.
- Each entry shows: subject, title, due date, status (derived from submission state).
- Sorted by `due_date` ascending.
- Wired with full assignment + submission data via `HomeworkAssignment` model.

### 3.2 Online Exams Section
- Lists all active exam allocations targeting the student's class, section, or directly:
  - Allocation types: `CLASS`, `SECTION`, `STUDENT`.
- Each entry shows: subject, scheduled date/timing, duration, and action button.
- Each allocation is decorated with the student's latest attempt status from `lms_exam_attempts` to drive action buttons:
  - No attempt → "Start Exam".
  - `IN_PROGRESS` → "Resume".
  - `SUBMITTED`/`EVALUATION_PENDING` → "Awaiting Evaluation".
  - `EVALUATED`/`RESULT_PUBLISHED` → "View Result".
- Filtered to active exam papers and exams only.

### 3.3 Quizzes Section
- Lists all active quiz allocations via `QuizAllocation` published scope:
  - Within cut-off date (NULL or `>= now()`).
  - Targeting class/section/student via polymorphic `target_table_name` + `target_id`.
- Decorated with attempt metadata:
  - `attempts_used`, `last_attempt` (latest completed attempt with score data).
  - `incomplete_attempt` (IN_PROGRESS or ABANDONED attempt for resume).
- Filtered to published + active quizzes only.

### 3.4 Quests Section
- Same pattern as Quizzes via `QuestAllocation` published scope.
- Decorated with same attempt metadata structure.
- Filtered to published + active quests only.

---

## 4. Non-Functional Requirements

| NFR-ID | Requirement | Threshold |
|--------|------------|-----------|
| NFR-STP-001 | Page load time | < 2 seconds with all 4 sections populated |
| NFR-STP-003 | Data completeness | All 4 sections loaded in a single controller invocation |
| NFR-STP-006 | IDOR prevention | Only authenticated student's data shown |
| NFR-STP-007 | Module gating | StudentPortal must be in tenant's plan |

---

## 5. Business Rules

| Rule ID | Description | Enforcement |
|---------|-------------|-------------|
| BR-STP-001 | Data belongs to authenticated student | All queries scoped by `$studentId`/`$userId` |
| BR-STP-019 | Homework assignments scoped to student | `HomeworkAssignment::where('student_id', $studentId)` |
| BR-STP-020 | Quiz/Quest allocations within cut-off date | `whereNull('cut_off_date')->orWhere('cut_off_date', '>=', now())` |
| BR-STP-021 | Exam allocations resolved by class/section/student | 3-way `orWhere` for each allocation type |
| — | Only released + active homework shown | `where('is_released', true)->where('is_active', true)` |
| — | Only published + active quizzes shown | `quiz->published()->active()` scope chain |
| — | Exam action button driven by attempt state | `$alloc->attempt` decorated via manual DB query per allocation |
| — | Quiz max attempts not enforced here | Enforced in quiz player start |

---

## 6. User Interface / UX

- **Layout**: Four distinct sections on a single page — Homework, Online Exams, Quizzes, Quests.
- **Homework**: Table/list rows with subject, title, due date, status badge.
- **Exams**: List with subject, date, time, duration, context-sensitive action button.
- **Quizzes**: List with quiz title, subject, attempts used/available, status.
- **Quests**: List with quest title, subject, attempt statistics.
- **Empty Section**: If no data for a section, section shows "No items" / empty state.
- **No student session**: If student has no current session (`$classId` or `$sectionId` null), exams/quizzes/quests sections are empty; homework may still show if assignments exist.

---

## 7. Data Dictionary

| Variable | Source | Type | Description |
|----------|--------|------|-------------|
| `homework` | `HomeworkAssignment::where('student_id', ...)` | Collection | Active homework with homework+submission+subject |
| `examAllocations` | `ExamAllocation::where(...)->get()` | Collection | Exam allocations with exam paper + subject + attempt decoration |
| `quizAllocations` | `QuizAllocation::published()-> ... ->get()` | Collection | Quiz allocations with quiz+subject + attempt metadata |
| `questAllocations` | `QuestAllocation::published()-> ... ->get()` | Collection | Quest allocations with quest+subject + attempt metadata |

---

## 8. API / Controller Specifications

### `StudentLmsController@index()`

| Aspect | Detail |
|--------|--------|
| **Method** | `GET /my-learning` |
| **Auth** | `auth` middleware (web) |
| **Session Resolution** | `$student->currentSession()->with('classSection')` |
| **Scope IDs** | `$studentId` (std_students.id), `$userId` (sys_users.id), `$classId`, `$sectionId` |
| **Homework Query** | `HomeworkAssignment::where('student_id', $studentId)->is_released->is_active->with('homework.subject', 'submission')->orderBy('due_date')` |
| **Exam Query** | `ExamAllocation::where('is_active', true)->where(allocation 3-way OR)->with('examPaper.exam', 'examPaper.subject')->get()->filter(not null)` |
| **Exam Decoration** | Per-allocation DB query on `lms_exam_attempts` for latest attempt by exam_paper_id + student_id |
| **Quiz Query** | `QuizAllocation::published()->is_active->cut_off check->allocation 3-way OR->with('quiz' => published()->active()->with('subject'))` |
| **Quiz Decoration** | Per-allocation DB query on `lms_quiz_quest_attempts` for completed + incomplete attempts |
| **Quest Query** | Same pattern as Quiz via `QuestAllocation` |
| **Quest Decoration** | Same as Quiz |

---

## 9. Validation Rules

| Field | Rule | Error |
|-------|------|-------|
| No student record | Handle null `$student` | Homework = empty; exam/quiz/quest sections empty (classId=0, sectionId=0 → queries return empty) |
| No current session | `$classId`/`$sectionId` null | Exam/quiz/quest queries return empty collections |
| No active homework | Empty collection | Section shows empty state |

No Form Request is used.

---

## 10. Error Handling & Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Student has no user-student record | `$student = null`; `$studentId = 0`; homework query returns empty; `$classId`/`$sectionId` null → exam/quiz/quest sections empty |
| Student has no active academic session | `$session = null`; `$classId`/`$sectionId` null → exam/quiz/quest sections empty; homework may still show |
| No homework assignments | Homework section empty |
| No exam allocations | Exams section empty |
| No quiz allocations | Quizzes section empty |
| No quest allocations | Quests section empty |
| Exam allocation has null examPaper | Filtered out: `$a->examPaper !== null` |
| Quiz allocation has null quiz | Filtered out: `$a->quiz !== null` |
| Quest is not active | Filtered out: `$a->quest->is_active ?? true` |
| All sections empty | Page renders with 4 empty sections, each showing appropriate empty state |

---

## 11. Security & Compliance

| Concern | Status |
|---------|--------|
| **IDOR** | ✅ All queries scoped to authenticated student's IDs |
| **Authentication** | ✅ Web auth middleware |
| **Allocation Scoping** | ✅ Exam/quiz/quest allocations only return those targeting the student's class/section/self |
| **Authorization Gates** | ⚠️ No `Gate::authorize()` calls |

---

## 12. Integration Points

| Module | Integration | Direction |
|--------|-------------|-----------|
| LmsHomework | `hmw_homework_assignments`, `hmw_homeworks`, `hmw_homework_submissions` | STP ← LmsHomework |
| LmsExam | `lms_exam_allocations`, `lms_exam_papers`, `lms_exams`, `lms_exam_attempts` | STP ← LmsExam |
| LmsQuiz | `lms_quiz_allocations`, `lms_quizzes`, `lms_quiz_quest_attempts` | STP ← LmsQuiz |
| LmsQuests | `lms_quest_allocations`, `lms_quests`, `lms_quiz_quest_attempts` | STP ← LmsQuests |
| StudentProfile (STD) | `std_students`, `std_student_sessions`, `sch_classes`, `sch_sections` | STP ← STD |

---

## 13. Performance Considerations

- Homework: Single eager-loaded query.
- Exams: N+1 potential — allocations query then per-allocation attempt DB query. For a student with 20 exams, this is 1 + 20 queries. Acceptable for typical load.
- Quizzes: Same N+1 pattern for attempt decorations.
- Quests: Same N+1 pattern.
- **Total queries**: ~1 (student) + 1 (homework) + 2 (exams + decoration) + 2 (quizzes + decoration) + 2 (quests + decoration) = ~8 queries baseline, plus N-per-type for decorations.
- No caching — every page load triggers all queries.

---

## 14. Dependencies & Pre-requisites

| Dependency | Type | Status |
|-----------|------|--------|
| LmsHomework module | Module | Required for homework section |
| LmsExam module | Module | Required for exams section |
| LmsQuiz module | Module | Required for quizzes section |
| LmsQuests module | Module | Required for quests section |
| StudentProfile (STD) module | Module | Required for student identity and session |
| Active academic session for student | Data | Required for exam/quiz/quest sections |
| Data in respective allocation tables | Data | Required for non-empty sections |

---

## 15. Known Gaps & Issues

| Gap ID | Description | Severity | Status |
|--------|-------------|----------|--------|
| — | N+1 query pattern for exam/quiz/quest attempt decorations (3 × N queries) | Medium | ⬜ Open |
| — | No caching — all 4 sections re-fetched on every page load | Low | ⬜ Open |
| — | Exam action buttons depend on `lms_exam_attempts` status strings — fragile to enum changes | Low | ⬜ Open |
| — | No `Gate::authorize()` policies on any section | Low | ⬜ Open |

---

## 16. Traceability Matrix

| Artifact | Reference |
|----------|-----------|
| FRD | REQ-STP-011 |
| Business Rules | BR-STP-019, BR-STP-020, BR-STP-021 |
| Controller | `StudentLmsController@index` |
| Route | `GET /my-learning` |
| View | `studentportal::learning.index` |
| Input Doc | `pgdatabase/Backup/4-Module_Requirement/StudentPortal/learning/lms_dashboard.md` |
