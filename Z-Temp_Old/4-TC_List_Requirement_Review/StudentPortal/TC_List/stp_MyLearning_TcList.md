# STP — My Learning Hub: Test Case List

## 1. Document Control

| Field | Value |
|-------|-------|
| **Module** | StudentPortal (STP) |
| **Feature ID** | STP-F011 |
| **Feature Name** | My Learning Hub |
| **REQ ID(s)** | REQ-STP-011 |
| **BR ID(s)** | BR-STP-019, BR-STP-020, BR-STP-021 |
| **Controller** | `StudentLmsController@index` |
| **Route** | `GET /my-learning` |
| **V1/V2** | — |
| **Status** | ⬜ |
| **CR** | ◌ |
| **Author** | OpenCode |
| **Date** | 2026-07-23 |

---

## 2. Test Environment

| Parameter | Value |
|-----------|-------|
| **Backend** | Laravel 12, PHP 8.2+ |
| **Database** | MySQL 8 (Tenant DB) — requires LmsHomework, LmsExam, LmsQuiz, LmsQuests, StudentProfile modules |
| **Auth** | Authenticated web session (student role) |
| **Browser** | Chrome/Firefox/Safari |
| **Test Data** | Seeded student with homework assignments, exam allocations, quiz allocations, quest allocations across multiple subjects |

---

## 3. Test Approach

- **Level**: Functional / System / Integration
- **Type**: Positive, Negative, UI, Data accuracy
- **Method**: Manual + Automated (Pest)
- **Data Setup**: Requires records in `hmw_homework_assignments`, `lms_exam_allocations`, `lms_quiz_allocations`, `lms_quest_allocations` tables
- **Key Focus Areas**: All 4 sections render correctly, data accuracy, attempt decoration for action buttons, empty states, IDOR

---

## 4. Test Scope

### In Scope
- Homework section — listing, status derivation, due dates
- Online exams section — allocation display, attempt-driven action buttons
- Quizzes section — allocation display, attempt used count, resume capability
- Quests section — same as quizzes pattern
- Empty state for each section
- Empty state for no-student / no-session
- Data ownership (IDOR)
- Activity logging

### Out of Scope
- Actual exam/quiz/quest attempt flow (separate controllers)
- Homework submission flow (separate controller)
- Cut-off date enforcement for quiz/quest start
- Max attempts enforcement (quiz player responsibility)

---

## 5. Test Cases

| TC ID | Test Case | Pre-condition | Test Steps | Expected Result | Priority | Automation |
|-------|-----------|---------------|------------|----------------|----------|------------|
| TC-LRN-001 | Verify page loads with all 4 sections | Student A has homework, exams, quizzes, quests | 1. Login as Student A<br>2. Navigate to `/my-learning` | All 4 sections visible: Homework, Online Exams, Quizzes, Quests | P1 | Yes |
| TC-LRN-002 | Verify homework section lists assignments | Student A has 5 active homework assignments | 1. Login as Student A<br>2. View My Learning | Homework section shows 5 entries with subject, title, due date, status | P1 | Yes |
| TC-LRN-003 | Verify homework status derivation: pending | Assignment exists, no submission, due date in future | 1. Login as Student A<br>2. View homework | Status = "pending" | P1 | Yes |
| TC-LRN-004 | Verify homework status derivation: submitted | Assignment has submission with submitted_at, no marks | 1. Login as Student A<br>2. View homework | Status = "submitted" | P1 | Yes |
| TC-LRN-005 | Verify homework status derivation: graded | Assignment has submission with marks_obtained | 1. Login as Student A<br>2. View homework | Status = "graded" | P1 | Yes |
| TC-LRN-006 | Verify homework status derivation: overdue | No submission, due date in past, late not allowed | 1. Login as Student A<br>2. View homework | Status = "overdue" | P1 | Yes |
| TC-LRN-007 | Verify exam section lists allocations | Student A has 3 exam allocations targeting class/section/student | 1. Login as Student A<br>2. View My Learning | Exams section shows 3 entries with subject, date, timing, action button | P1 | Yes |
| TC-LRN-008 | Verify exam action button: "Start Exam" | Exam allocation exists with no attempt | 1. Login as Student A<br>2. View My Learning | Action button labeled "Start Exam" | P1 | Yes |
| TC-LRN-009 | Verify exam action button: "Resume" | Exam has IN_PROGRESS attempt | 1. Login as Student A<br>2. View My Learning | Action button labeled "Resume" | P1 | Yes |
| TC-LRN-010 | Verify exam action button: "Awaiting Evaluation" | Exam has SUBMITTED attempt | 1. Login as Student A<br>2. View My Learning | Action button labeled accordingly or "View Result" disabled | P1 | Yes |
| TC-LRN-011 | Verify exam action button: "View Result" | Exam has EVALUATED/RESULT_PUBLISHED attempt | 1. Login as Student A<br>2. View My Learning | Action button labeled "View Result" | P1 | Yes |
| TC-LRN-012 | Verify quiz section lists allocations | Student A has 3 quiz allocations | 1. Login as Student A<br>2. View My Learning | Quizzes section shows 3 entries with title, subject, attempts used, status | P1 | Yes |
| TC-LRN-013 | Verify quiz section shows attempt count | Student A has used 1 of 3 attempts on a quiz | 1. Login as Student A<br>2. View My Learning | Quiz row shows "1/3 attempts used" | P1 | Yes |
| TC-LRN-014 | Verify quiz section shows completed attempt score | Student A completed a quiz with score 80% | 1. Login as Student A<br>2. View My Learning | Quiz row shows last attempt score (80%) and pass/fail indicator | P1 | Yes |
| TC-LRN-015 | Verify quiz section shows incomplete attempt for resume | Student A has IN_PROGRESS quiz attempt | 1. Login as Student A<br>2. View My Learning | Quiz shows option to resume, not start new | P1 | Yes |
| TC-LRN-016 | Verify quest section lists allocations | Student A has 2 quest allocations | 1. Login as Student A<br>2. View My Learning | Quests section shows 2 entries with title, subject, attempt stats | P2 | Yes |
| TC-LRN-017 | Verify quest section mirrors quiz decoration pattern | Student A has completed and incomplete quest attempts | 1. Login as Student A<br>2. View My Learning | Quest entries show attempt count, last score, resume option | P2 | Yes |
| TC-LRN-018 | Verify exam allocations filtered by allocation type: CLASS | Exam targets Student A's class | 1. Login as Student A from Class X-A<br>2. View My Learning | Exam appears in the list | P1 | Yes |
| TC-LRN-019 | Verify exam allocations filtered by allocation type: SECTION | Exam targets Student A's section | 1. Login as Student A from Class X-A<br>2. View My Learning | Exam appears in the list | P1 | Yes |
| TC-LRN-020 | Verify exam allocations filtered by allocation type: STUDENT | Exam directly targets Student A | 1. Login as Student A<br>2. View My Learning | Exam appears in the list | P1 | Yes |
| TC-LRN-021 | Verify exam allocation not shown for different class | Exam targets Class IX, Student A is in Class X | 1. Login as Student A<br>2. View My Learning | Exam not shown | P1 | Yes |
| TC-LRN-022 | Verify quiz allocations respect cut-off date | Quiz allocation with cut_off_date in the past | 1. Login as Student A<br>2. View My Learning | Expired quiz not shown | P1 | Yes |
| TC-LRN-023 | Verify empty homework section | Student A has no homework assignments | 1. Login as Student A<br>2. View My Learning | Homework section shows "No homework" empty state | P1 | Yes |
| TC-LRN-024 | Verify empty exams section | Student A has no exam allocations | 1. Login as Student A<br>2. View My Learning | Exams section shows empty state | P1 | Yes |
| TC-LRN-025 | Verify empty quizzes section | Student A has no quiz allocations | 1. Login as Student A<br>2. View My Learning | Quizzes section shows empty state | P1 | Yes |
| TC-LRN-026 | Verify empty quests section | Student A has no quest allocations | 1. Login as Student A<br>2. View My Learning | Quests section shows empty state | P1 | Yes |
| TC-LRN-027 | Verify no-student state | User has no linked student record | 1. Login as user without student<br>2. View My Learning | All 4 sections empty; page renders without error | P1 | Yes |
| TC-LRN-028 | Verify no-active-session state | Student A has no current academic session | 1. Login as Student A without session<br>2. View My Learning | Homework may still load; exams/quizzes/quests sections empty (classId=null) | P1 | Yes |
| TC-LRN-029 | Verify IDOR — data ownership | Student A and B both have data | 1. Login as Student A<br>2. Inspect data | Only Student A's homework/exams/quizzes/quests shown | P1 | Yes |
| TC-LRN-030 | Verify activity log entry | Student A views page | 1. Login as Student A<br>2. Navigate to `/my-learning` | Activity log records 'Viewed' with student_id | P3 | No |
| TC-LRN-031 | Verify homework sorted by due_date ASC | Student A has homework due on 5th, 10th, 15th | 1. Login as Student A<br>2. View homework section | Homework ordered: 5th first, 15th last | P2 | Yes |
| TC-LRN-032 | Verify exam allocation with null examPaper | ExamAllocation exists but related ExamPaper deleted | 1. Login as Student A<br>2. View My Learning | Allocation filtered out (null check) | P2 | Yes |
| TC-LRN-033 | Verify homework filter: is_released = false | Student has assignment where is_released = false | 1. Login as Student A<br>2. View My Learning | Non-released homework not shown | P2 | Yes |

---

## 6. Regression Impact

| Area | Impact | Suggested Tests |
|------|--------|----------------|
| LmsHomework | Schema/status changes affect homework section | Verify homework listing + status derivation |
| LmsExam | Allocation schema, attempt status changes affect exam section | Verify exam listing + action button derivation |
| LmsQuiz | Allocation scope, cut-off date changes affect quiz section | Verify quiz listing + attempt metadata |
| LmsQuests | Same as Quiz | Verify quest listing |
| StudentProfile | Session resolution changes affect all sections | Verify no-session empty state |

---

## 7. Known Gaps & Issues

| Gap ID | Description | Impact on Testing |
|--------|-------------|-------------------|
| — | N+1 queries for exam/quiz/quest attempt decorations | TC-LRN-007 through TC-LRN-016 test correctness but not performance |
| — | No caching — full reload on every visit | Cannot verify cache invalidation scenarios |
| — | Exam action button logic duplicates `StudentExamAttemptController` logic | Fragile to attempt engine changes |
| — | Quiz/Quest `published()` scope may have different meaning across modules | Verify scope behaviour matches expectation |

---

## 8. Sign-off Criteria

| Criteria | Target |
|----------|--------|
| P1 Test Cases Passed | 100% |
| P2 Test Cases Passed | 100% |
| All 4 sections render correctly | Verified |
| Action buttons drive correct attempt states | All states covered (Start/Resume/Await/View) |
| Empty states verified for all sections | All sections |

---

## 9. Appendices

### A. Test Data Requirements
- Student A with: 3 homework assignments (1 pending, 1 submitted, 1 graded)
- Student A with: 4 exam allocations (no attempt, IN_PROGRESS, SUBMITTED, EVALUATED)
- Student A with: 3 quiz allocations (not started, IN_PROGRESS, completed)
- Student A with: 2 quest allocations (not started, completed)
- Student B with separate data (for IDOR)
- Quiz allocation with cut_off_date in the past
- Exam allocation with null examPaper
- Homework assignment with is_released = false
- User account without student record
- Student without current session

### B. Related Routes
```
GET /my-learning → StudentLmsController@index
```

---

## 10. Traceability

| Artifact | Reference |
|----------|-----------|
| FRD | REQ-STP-011 |
| Business Rules | BR-STP-019, BR-STP-020, BR-STP-021 |
| Requirement Doc | `stp_MyLearning_Requirement.md` |
| Controller | `StudentLmsController@index` |
| View | `studentportal::learning.index` |
| Input Doc | `pgdatabase/Backup/4-Module_Requirement/StudentPortal/learning/lms_dashboard.md` |
