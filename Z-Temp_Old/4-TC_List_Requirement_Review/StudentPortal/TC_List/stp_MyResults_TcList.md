# stp_MyResults — Test Case List

## 1. Module Feature Information

| Field | Value |
|-------|-------|
| Module Code | STP |
| Module Name | StudentPortal |
| Feature Name | My Results |
| FRD Reference | REQ-STP-010, BR-STP-001, BR-STP-021 |
| Route | `student-portal.results` (GET `/student-portal/results`) |
| Controller | `StudentPortalController@results` |
| View | `studentportal::results.index` |

## 2. Feature Overview

Consolidated results hub with 4 tabs: Online Exams, Quizzes, Quests, and Homework. Shows marks, percentages, grades, and pass/fail status from published/submitted assessment data. Includes exam detail AJAX modal and "Share with Parent" link generation.

## 3. Test Scope

### In Scope
- Stat cards (counts per assessment type)
- Online Exams tab — all table columns, marks display, status badges
- Quizzes tab — table, marks, pass/fail, view link
- Quests tab — table, marks, pass/fail, view link
- Homework tab — table, graded/submitted status, marks, remarks
- Exam detail AJAX modal
- "Share with Parent" modal and link generation
- Empty states per tab
- Published vs unpublished result handling
- Activity logging

### Out of Scope
- Individual quiz/quest/homework detail pages (separate routes)
- PDF download of results

## 4. Test Environment / Pre-requisites

| Requirement | Details |
|-------------|---------|
| Backend | Laravel 12, PHP 8.2+ |
| Database | MySQL 8 — Tenant DB with exam/quiz/quest/homework tables |
| Auth | Authenticated as Student user |
| Browser | Chrome/Firefox/Edge (latest), JavaScript enabled for tabs, modals, AJAX |

## 5. Test Data Setup

- **Student A:** 8 exam attempts (4 published results, 2 awaiting eval, 2 submitted), 5 quiz results (published), 3 quest results (published), 10 homework assignments (6 graded, 4 submitted ungraded)
- **Student B:** No results of any type
- **Edge cases:** Exam with 0 marks, 100% score, fail result, null grade, null remarks

## 6. Test Cases

| TC ID | Test Case | Pre-requisites | Test Steps | Expected Result | Status | CR |
|-------|-----------|----------------|------------|-----------------|--------|----|
| TC-RES-001 | Verify page loads for valid student | Student A with results data | 1. Navigate to `/student-portal/results` | Page loads with breadcrumb "Home > My Results", title "My Results" | ⬜ | ◌ |
| TC-RES-002 | Verify stat cards | 8 exams, 5 quizzes, 3 quests, 10 homework | 1. Load page 2. Observe stat row | 4 cards: Exams=8 (4 published), Quizzes=5, Quests=3, Homework=10 (6 graded) | ⬜ | ◌ |
| TC-RES-003 | Verify Online Exams tab active by default | Any data | 1. Load page 2. Observe tabs | "Online Exams" tab active, its content visible | ⬜ | ◌ |
| TC-RES-004 | Verify Quizzes tab switches | Quiz data exists | 1. Click "Quizzes" tab | Quiz content visible; Online Exams hidden | ⬜ | ◌ |
| TC-RES-005 | Verify Quests tab switches | Quest data exists | 1. Click "Quests" tab | Quest content visible | ⬜ | ◌ |
| TC-RES-006 | Verify Homework tab switches | Homework data exists | 1. Click "Homework" tab | Homework content visible | ⬜ | ◌ |
| TC-RES-007 | Verify Published exam shows marks | Exam with is_published=true | 1. Online Exams tab 2. Find published exam | Marks column shows "85.0 / 100"; % shows "85.0%"; grade shown; result badge "PASS" (green) | ⬜ | ◌ |
| TC-RES-008 | Verify ungraded exam shows "Awaiting Result" | Exam submitted but result not published | 1. Online Exams tab 2. Find ungraded | Marks "—"; % "—"; grade "—"; result badge "Awaiting Result" (grey) | ⬜ | ◌ |
| TC-RES-009 | Verify FAIL result badge | Exam with result_status='FAIL' | 1. Online Exams tab 2. Find failed exam | Result badge "FAIL" (red) | ⬜ | ◌ |
| TC-RES-010 | Verify exam table columns | Any exam row | 1. Online Exams tab 2. Observe table | Columns: #, Exam, Subject, Paper Code, Submitted, Marks, %, Grade, Result, Action | ⬜ | ◌ |
| TC-RES-011 | Verify View button opens modal for published exam | Published exam | 1. Click "View" on published exam | AJAX loads exam detail into modal | ⬜ | ◌ |
| TC-RES-012 | Verify View button shows "Pending" for unpublished | Submitted but not evaluated | 1. Find unpublished exam 2. Observe Action | Shows "Pending" text, no button | ⬜ | ◌ |
| TC-RES-013 | Verify quiz table columns | Quiz result row | 1. Click Quizzes tab | Columns: #, Quiz, Subject, Marks, %, Grade, Result, Date, Action | ⬜ | ◌ |
| TC-RES-014 | Verify quiz marks displayed | Quiz with 20/25 marks = 80% | 1. Quizzes tab 2. Find quiz | Shows "20.0 / 25"; % "80.0%"; grade; pass badge | ⬜ | ◌ |
| TC-RES-015 | Verify quiz fail badge | Quiz with is_passed=false | 1. Quizzes tab 2. Find failed quiz | Result badge shows "Fail" (red) | ⬜ | ◌ |
| TC-RES-016 | Verify quiz View links to quiz result page | Published quiz | 1. Quizzes tab 2. Click "View" | Navigates to `/student-portal/quiz/{id}/result` | ⬜ | ◌ |
| TC-RES-017 | Verify quest table columns | Quest result row | 1. Click Quests tab | Columns: #, Quest, Subject, XP/Marks, %, Grade, Result, Date, Action | ⬜ | ◌ |
| TC-RES-018 | Verify quest marks displayed | Quest with 15/20 marks = 75% | 1. Quests tab 2. Find quest | Shows "15.0 / 20"; % "75.0%"; grade; pass badge | ⬜ | ◌ |
| TC-RES-019 | Verify quest View links to quest result page | Published quest | 1. Quests tab 2. Click "View" | Navigates to `/student-portal/quest/{id}/result` | ⬜ | ◌ |
| TC-RES-020 | Verify homework table columns | Graded homework row | 1. Click Homework tab | Columns: #, Subject, Title, Due Date, Submitted, Marks, Status, Remarks, Action | ⬜ | ◌ |
| TC-RES-221 | Verify graded homework shows marks + % | Homework with 18/20, 90% | 1. Homework tab 2. Find graded | Shows "18 / 20"; 90% below; Status "Graded" (green) | ⬜ | ◌ |
| TC-RES-022 | Verify ungraded homework shows "Submitted" | Homework submitted but no marks | 1. Homework tab 2. Find ungraded | Marks shows "Submitted"; Status "Submitted" (blue) | ⬜ | ◌ |
| TC-RES-023 | Verify homework remarks shown | Submission with remarks "Good effort" | 1. Homework tab 2. Find entry | Remarks column shows "Good effort" | ⬜ | ◌ |
| TC-RES-024 | Verify homework View links to detail | Any homework | 1. Homework tab 2. Click "View" | Navigates to `/student-portal/homework/{id}` | ⬜ | ◌ |
| TC-RES-025 | Verify Share with Parent button visible | Page loaded | 1. Load page 2. Observe top right | "Share with Parent" button with share icon | ⬜ | ◌ |
| TC-RES-026 | Verify Share modal opens | Click Share button | 1. Click "Share with Parent" | Modal opens with explanation text | ⬜ | ◌ |
| TC-RES-027 | Verify share link generated | Successful AJAX call | 1. Open Share modal 2. Observe | Spinner shown; link appears in input; expiry date shown | ⬜ | ◌ |
| TC-RES-028 | Verify copy to clipboard works | Share link generated | 1. Click copy icon 2. Paste elsewhere | Link copied to clipboard | ⬜ | ◌ |
| TC-RES-029 | Verify share link error handling | AJAX fails | 1. Open Share modal 2. Simulate network error | Error message displayed in modal | ⬜ | ◌ |
| TC-RES-030 | Verify empty state: no exam results | Student B (no data) | 1. Online Exams tab | "No submitted exams yet." | ⬜ | ◌ |
| TC-RES-031 | Verify empty state: no quiz results | Student B | 1. Quizzes tab | "No published quiz results yet." | ⬜ | ◌ |
| TC-RES-032 | Verify empty state: no quest results | Student B | 1. Quests tab | "No published quest results yet." | ⬜ | ◌ |
| TC-RES-033 | Verify empty state: no homework | Student B | 1. Homework tab | "No homework submissions yet." | ⬜ | ◌ |
| TC-RES-034 | Verify activity log recorded | Student A | 1. Navigate 2. Check activity_log | Entry: "Student viewed results." with context | ⬜ | ◌ |
| TC-RES-035 | Verify page inaccessible without auth | No session | 1. Access without login | Redirected to login | ⬜ | ◌ |
| TC-RES-036 | Verify exam result detail modal loads | Click View on published exam | 1. Click View 2. Wait for AJAX | Modal shows exam detail content via AJAX | ⬜ | ◌ |
| TC-RES-037 | Verify exam result detail modal error | AJAX fails | 1. Click View 2. Simulate failure | Modal shows error message | ⬜ | ◌ |

## 7. Test Summary

| Metric | Count |
|--------|-------|
| Total Test Cases | 37 |
| Automated | — |
| Manual | 37 |
| Pass | — |
| Fail | — |
| Blocked | — |
| Not Executed | 37 |

## 8. Known Issues

| Issue ID | Description | Severity | Status |
|----------|-------------|----------|--------|
| GAP-RES-01 | No overall pass/fail summary across tabs | Medium | ⬜ |
| GAP-RES-02 | No print/PDF export for consolidated results | Low | ⬜ |
| GAP-RES-04 | Share link expiry enforcement unknown (UI says 7 days but backend not verified) | Medium | ⬜ |
| GAP-RES-05 | No pagination on any results table | Low | ⬜ |

## 9. Route Reference

| Method | Path | Route Name | Middleware |
|--------|------|------------|------------|
| GET | `/student-portal/results` | `student-portal.results` | `auth`, `verified` |
| GET | `/student-portal/quiz/{id}/result` | `student-portal.quiz.result` | `auth`, `verified` |
| GET | `/student-portal/quest/{id}/result` | `student-portal.quest.result` | `auth`, `verified` |
| GET | `/student-portal/homework/{id}` | `student-portal.homework.show` | `auth`, `verified` |
| GET | `/student-portal/online-exam/{id}/result` | `student-portal.online-exam.result` | `auth`, `verified` (AJAX) |

## 10. Execution Status

| Cycle | Date | Tester | Pass | Fail | Blocked | Not Executed | Signature |
|-------|------|--------|------|------|---------|--------------|-----------|
| V1 | — | — | — | — | — | 37 | — |

---

*Test cases derived from controller code analysis, input requirement doc, and FRD cross-reference.*
