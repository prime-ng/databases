# stp_MyResults — Requirement Document

## 1. Module Information

| Field | Value |
|-------|-------|
| Module Code | STP |
| Module Name | StudentPortal |
| Feature Name | My Results |
| Table Prefix | stp_ (consumes `lms_exam_attempts`, `lms_exam_results`, `lms_quiz_quest_results`, `lms_homework_submissions`) |
| DB Layer | Tenant (`tenant_{uuid}`) |
| Route Name | `student-portal.results` |
| HTTP Method + Path | GET `/student-portal/results` |
| Controller | `StudentPortalController@results` |
| View | `studentportal::results.index` |
| Input Doc | `pgdatabase/Backup/4-Module_Requirement/StudentPortal/examinations/my_results.md` |
| FRD Reference | REQ-STP-010, BR-STP-001, BR-STP-021 |

## 2. Feature Overview

A consolidated results hub displaying the student's evaluated/submitted assessment results across four tabs: Online Exams, Quiz Results, Quest Results, and Homework Results. Shows marks obtained, percentages, grades, pass/fail status, and offers drill-down views. Includes a "Share with Parent" feature to generate a time-limited shareable link.

## 3. Functional Requirements

| ID | Requirement | Status |
|----|-------------|--------|
| F1 | Load online exam results — submitted attempts with LEFT JOIN to published exam results | ✅ |
| F2 | Load quiz results — published results from `lms_quiz_quest_results` where assessment_type=QUIZ | ✅ |
| F3 | Load quest results — published results from `lms_quiz_quest_results` where assessment_type=QUEST | ✅ |
| F4 | Load homework results — assignments with submissions (graded or submitted) | ✅ |
| F5 | Display stat cards per tab: Online Exam count, Quiz count, Quest count, Homework count | ✅ |
| F6 | Tabbed interface: Online Exams (default), Quizzes, Quests, Homework | ✅ |
| F7 | Online Exam table: Exam title, Subject, Paper Code, Submitted date, Marks (obtained/possible), %, Grade, Result status, View action | ✅ |
| F8 | Quiz table: Quiz title, Subject, Marks (obtained/max), %, Grade, Pass/Fail, Date, View action | ✅ |
| F9 | Quest table: Quest title, Subject, XP/Marks, %, Grade, Pass/Fail, Date, View action | ✅ |
| F10 | Homework table: Subject, Title, Due date, Submitted date, Marks, Status, Remarks, View action | ✅ |
| F11 | Exam detail modal (AJAX load from `/online-exam/{paperId}/result`) | ✅ |
| F12 | "Share with Parent" feature — generates 7-day expiring share link | ✅ |
| F13 | Record activity log on page view | ✅ |

## 4. Business Rules

| Rule ID | Rule Description | Enforcement |
|---------|-----------------|-------------|
| BR-STP-001 | Data must belong to the authenticated student | `$studentId = $student->id` |
| BR-RES-01 | Only submitted/evaluated attempts shown for online exams | `whereIn('status', ['SUBMITTED','EVALUATION_PENDING','EVALUATED','RESULT_PUBLISHED'])` |
| BR-RES-02 | Only published quiz/quest results shown | `where('is_published', true)` |
| BR-RES-03 | Quiz results filtered by assessment_type=QUIZ | `where('assessment_type', 'QUIZ')` |
| BR-RES-04 | Quest results filtered by assessment_type=QUEST | `where('assessment_type', 'QUEST')` |
| BR-RES-05 | Homework results: only assignments with submissions and active | `where('is_active', true)->whereHas('submission')` |
| BR-RES-06 | Soft-deleted records excluded | `whereNull('deleted_at')` on all joins |
| BR-RES-07 | Marks/percentage displayed only when result is published | View checks `$r->is_published` |

## 5. User Interface & Layout

### 5.1 Page Header
- Breadcrumb: Home > My Results
- Title: "My Results"
- "Share with Parent" button (top right)

### 5.2 Stat Cards (Row of 4)
- **Online Exams** — Blue, edit-3 icon; count + published sub-label
- **Quiz Results** — Green, check-square icon; count
- **Quest Results** — Yellow, star icon; count
- **Homework** — Orange, book-open icon; count + graded sub-label

### 5.3 Tabbed Results Tables

#### 5.3.1 Online Exams Tab (default active)
| Column | Content |
|--------|---------|
| # | Row number |
| Exam | Exam title (bold) |
| Subject | Subject name |
| Paper Code | Code in code element |
| Submitted | Submission date |
| Marks | obtained / possible (if published) or "—" |
| % | Percentage (if published) or "—" |
| Grade | Grade string (if published) or "—" |
| Result | Badge: "Awaiting Result", "PASS" (green), "FAIL" (red) |
| Action | "View" button (opens AJAX modal) or "Pending" |

#### 5.3.2 Quizzes Tab
| Column | Content |
|--------|---------|
| # | Row number |
| Quiz | Quiz title |
| Subject | Subject name |
| Marks | obtained / max |
| % | Percentage |
| Grade | Grade |
| Result | Pass (green) / Fail (red) badge |
| Date | Attempt date |
| Action | "View" link to quiz result page |

#### 5.3.3 Quests Tab
| Column | Content |
|--------|---------|
| # | Row number |
| Quest | Quest title |
| Subject | Subject name |
| XP / Marks | obtained / max |
| % | Percentage |
| Grade | Grade |
| Result | Pass / Fail badge |
| Date | Attempt date |
| Action | "View" link to quest result page |

#### 5.3.4 Homework Tab
| Column | Content |
|--------|---------|
| # | Row number |
| Subject | Subject name |
| Title | Homework title + description snippet |
| Due Date | Due date |
| Submitted | Submission date |
| Marks | obtained / max + % (if graded) or "Submitted" (if ungraded) |
| Status | "Graded" (green) or "Submitted" (blue) badge |
| Remarks | Teacher feedback |
| Action | "View" link to homework detail |

### 5.4 Share with Parent Modal
- Opens a modal explaining the 7-day expiring link
- Generates link AJAX via `results.share-link` route
- Copy to clipboard button
- Shows expiry date

## 6. Data Flow & Processing

```
User navigates → GET /student-portal/results
  ↓
StudentPortalController@results()
  ↓
$studentId = auth()->user()->student->id ?? 0
  ↓
── Online Exams ──
DB::table('lms_exam_attempts as a')
  ->join('lms_exam_papers', ...)
  ->join('lms_exams', ...)
  ->leftJoin('sch_subjects', ...)
  ->leftJoin('lms_exam_results as er', on: er.exam_paper_id = a.exam_paper_id AND er.student_id = $studentId)
  ->where('a.student_id', $studentId)
  ->whereIn('a.status', ['SUBMITTED','EVALUATION_PENDING','EVALUATED','RESULT_PUBLISHED'])
  ->whereNull('a.deleted_at')
  ->orderByDesc('a.created_at')
  ->get([...columns including marks if published])
  ↓
── Quiz Results ──
DB::table('lms_quiz_quest_results as rr')
  ->join('lms_quizzes as q', ...)
  ->leftJoin('sch_subjects', ...)
  ->where('rr.student_id', $studentId)
  ->where('rr.assessment_type', 'QUIZ')
  ->where('rr.is_published', true)
  ->whereNull('rr.deleted_at')
  ->orderByDesc('rr.created_at')
  ->get()
  ↓
── Quest Results ──
(Same pattern as quiz but assessment_type='QUEST', join lms_quests)
  ↓
── Homework Results ──
HomeworkAssignment::where('student_id', $studentId)
  ->where('is_active', true)
  ->whereHas('submission')
  ->with(['homework.subject', 'submission'])
  ->orderByDesc('due_date')
  ->get()
  ->filter(fn: homework !== null)
  ↓
activityLog()
  ↓
Return view('studentportal::results.index', compact('examResults','quizResults','questResults','homeworkResults'))
```

## 7. Database References

| Table | Model/Purpose | Used By |
|-------|---------------|---------|
| `lms_exam_attempts` | Student's exam attempts (STP-owned) | Online Exams |
| `lms_exam_papers` | Paper details (title, code, marks) | Online Exams |
| `lms_exams` | Exam metadata (title) | Online Exams |
| `lms_exam_results` | Published results (marks, grade, status) | Online Exams |
| `sch_subjects` | Subject names | All tabs |
| `lms_quiz_quest_results` | Published quiz/quest results (STP-owned) | Quiz + Quest tabs |
| `lms_quizzes` | Quiz metadata | Quiz tab |
| `lms_quests` | Quest metadata | Quest tab |
| `lms_homework_assignments` | Student homework assignments | Homework tab |
| `lms_homeworks` | Homework metadata (title, subject, max_marks) | Homework tab |
| `lms_homework_submissions` | Student submissions (marks, remarks) | Homework tab |

## 8. Route Reference

| Route Name | Method | Path | Controller Method |
|------------|--------|------|-------------------|
| `student-portal.results` | GET | `/student-portal/results` | `StudentPortalController@results` |
| `student-portal.quiz.result` | GET | `/student-portal/quiz/{id}/result` | `StudentQuizAttemptController@result` |
| `student-portal.quest.result` | GET | `/student-portal/quest/{id}/result` | `StudentQuestAttemptController@result` |
| `student-portal.homework.show` | GET | `/student-portal/homework/{id}` | `StudentHomeworkController@show` |
| `student-portal.results.share-link` | (AJAX) | Share link endpoint | (Named route used in JS) |

## 9. Permissions & Security

| Concern | Status | Notes |
|---------|--------|-------|
| Authentication | ✅ | Route behind `auth` + `verified` middleware |
| Data ownership | ✅ | All queries filtered by `$studentId` |
| IDOR risk | ✅ | No parameter-based access for the list; individual result pages have own guards |
| Activity logging | ✅ | Every view logged |
| Share link expiry | ✅ | 7-day expiry mentioned in UI |

## 10. Validation & Error Handling

| Scenario | Handling |
|----------|----------|
| No student profile | `$studentId = 0` — all queries return empty collections |
| No submitted exams | Empty table: "No submitted exams yet." |
| No published quiz results | Empty table: "No published quiz results yet." |
| No published quest results | Empty table: "No published quest results yet." |
| No homework submissions | Empty table: "No homework submissions yet." |
| Exam result not yet published | Marks shown as "—"; Result badge: "Awaiting Result" |
| Shared link generation failure | Error alert in modal |
| AJAX exam detail load failure | Error message in modal body |

## 11. Edge Cases & Empty States

| Edge Case | Expected Behaviour |
|-----------|--------------------|
| Student has never taken any exam | All tabs show empty states |
| Exam submitted but evaluation pending | Shows in Online Exams tab; marks = "—"; status = "Awaiting Result" |
| Exam evaluated but result not published | Shows "Awaiting Result" (status: EVALUATED but is_published = null) |
| Quiz result published with is_passed = false | Shows red "Fail" badge |
| Homework submitted but not graded | Marks = "Submitted" text; Status = "Submitted" badge |
| Homework with null marks_obtained | Treated as ungraded |
| Share link generation network failure | Modal shows error message |
| Multiple attempts on same exam paper | Only latest attempt shown (orderByDesc created_at) |

## 12. Performance Considerations

| Aspect | Analysis |
|--------|----------|
| Query load | 4 separate queries (exams, quizzes, quests, homework) plus AJAX on View |
| N+1 risk | Homework query uses eager loading (homework.subject, submission) — safe |
| Collection size | Exam results may grow over academic year — consider pagination |
| AJAX modal | Each "View" triggers an HTTP request — acceptable |
| Recommendation | Add pagination for exam results with >50 records |

## 13. Dependencies

| Dependency Module | Entity Consumed |
|-------------------|-----------------|
| LmsExam | ExamAllocation, ExamPaper, Exam, ExamResult |
| LmsQuiz | Quiz, QuizQuestResult |
| LmsQuests | Quest, QuizQuestResult |
| LmsHomework | Homework, HomeworkAssignment, HomeworkSubmission |
| StudentPortal (STP) | ExamAttempt (own model) |

## 14. FRD Traceability

| FRD ID | Description | Status |
|--------|-------------|--------|
| REQ-STP-010 | Results View (P0) — View exam results with actual marks | ✅ Implemented (marks shown when published) |
| BR-STP-001 | Data ownership — student data must belong to authenticated student | ✅ Enforced |
| BR-STP-021 | Exam allocation scope (indirectly via attempt queries) | ✅ Enforced |

## 15. Known Issues / Gaps

| ID | Issue | Severity | Status |
|----|-------|----------|--------|
| GAP-STP-05 | FRD noted "results currently show no actual marks" — this has been FIXED: marks, percentage, grade now display when `is_published=true` | Resolved | ✅ |
| GAP-RES-01 | No overall pass/fail summary across all exam types — student must check each tab individually | Medium | ⬜ |
| GAP-RES-02 | No print/PDF export for consolidated results (only individual exam PDF via result pdf route) | Low | ⬜ |
| GAP-RES-03 | Homework results show "Submitted" as status even when marks are entered — "Graded" badge only appears when marks_obtained is not null | Low | ⬜ |
| GAP-RES-04 | Share link expiry is UI-only (7 days mentioned in modal) — backend enforcement unknown | Medium | ⬜ |
| GAP-RES-05 | No pagination on any results table — may become slow with >100 submissions | Low | ⬜ |

## 16. Change Log

| Version | Date | Author | Change Description |
|---------|------|--------|--------------------|
| V1 | — | — | Initial requirement as per input doc |
| V2 | 2026-07-23 | OpenCode | Controller code analysis added; 4-tab structure documented; LEFT JOIN exam results logic detailed; GAP-STP-05 confirmed resolved |

---

*Document generated from controller code analysis, input requirement doc, and FRD cross-reference.*
