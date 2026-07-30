# stp_ExamSchedule — Test Case List

## 1. Module Feature Information

| Field | Value |
|-------|-------|
| Module Code | STP |
| Module Name | StudentPortal |
| Feature Name | Exam Schedule |
| FRD Reference | REQ-STP-009, BR-STP-001, BR-STP-021 |
| Route | `student-portal.exam-schedule` (GET `/student-portal/exam-schedule`) |
| Controller | `StudentPortalController@examSchedule` |
| View | `studentportal::exams.schedule` |

## 2. Feature Overview

Displays scheduled exams for the student's class/section, categorised as Ongoing (currently in progress), Today, Upcoming (future), and Concluded (past). Supports filtering by exam mode (All / Online / Offline) via tabs.

## 3. Test Scope

### In Scope
- Stat cards (total, online, offline, today counts)
- Filter tabs (All, Online, Offline)
- Category sections (Ongoing, Today, Upcoming, Concluded)
- Exam table columns (exam name, subject, mode, date, time, duration, marks, venue, status)
- Days-remaining countdown (≤3 days red)
- Allocation scoping (CLASS, SECTION, STUDENT)
- Ongoing time-window computation
- Attempt attachment per allocation
- Empty state
- Activity logging

### Out of Scope
- Exam attempt flow itself
- Exam creation/management

## 4. Test Environment / Pre-requisites

| Requirement | Details |
|-------------|---------|
| Backend | Laravel 12, PHP 8.2+ |
| Database | MySQL 8 — Tenant DB with `lms_exam_allocations`, `lms_exam_papers`, `lms_exams` |
| Auth | Authenticated as Student user |
| Browser | Chrome/Firefox/Edge (latest), JavaScript enabled for tabs |

## 5. Test Data Setup

- **Student A:** Class 5-A with 12 exam allocations across dates (3 ongoing, 2 today, 4 upcoming, 3 concluded)
- **Student B:** Class with no exam allocations
- **Exam modes:** Mix of ONLINE and OFFLINE
- **Allocation types:** CLASS-level (e.g. unit test), SECTION-level (e.g. class test), STUDENT-level (e.g. remedial)
- **Edge cases:** Allocation with null scheduled_date, null start/end times

## 6. Test Cases

| TC ID | Test Case | Pre-requisites | Test Steps | Expected Result | Status | CR |
|-------|-----------|----------------|------------|-----------------|--------|----|
| TC-EXM-001 | Verify page loads for valid student | Student A with exam allocations | 1. Navigate to `/student-portal/exam-schedule` | Page loads with breadcrumb "Home > Exam Schedule", title "Exam Schedule" | ⬜ | ◌ |
| TC-EXM-002 | Verify stat cards | 12 total, 5 online, 7 offline, 2 today | 1. Load page 2. Observe stat row | Total=12, Online=5, Offline=7, Today's=2 | ⬜ | ◌ |
| TC-EXM-003 | Verify All tab selected by default | Student A with allocations | 1. Load page 2. Observe tabs | "All" tab active; all categories visible | ⬜ | ◌ |
| TC-EXM-004 | Verify Online tab filters | 5 online exams exist | 1. Click "Online" tab | Only online exams shown in categories | ⬜ | ◌ |
| TC-EXM-005 | Verify Offline tab filters | 7 offline exams exist | 1. Click "Offline" tab | Only offline exams shown in categories | ⬜ | ◌ |
| TC-EXM-006 | Verify Ongoing section visible | 3 exams currently in progress | 1. Load page during exam hours | Red-bordered "Ongoing Now" section with pulsing dot, 3 rows highlighted green | ⬜ | ◌ |
| TC-EXM-007 | Verify Ongoing only includes exams within time window | Exam 10:00–12:00, current=11:00 | 1. Check ongoing | Exam included; exam outside time excluded from ongoing | ⬜ | ◌ |
| TC-EXM-008 | Verify Today section | 2 exams today | 1. Load page 2. Observe Today section | Green-bordered "Today's Exams" section with 2 rows | ⬜ | ◌ |
| TC-EXM-009 | Verify Today shows "Today" date label | Exam today | 1. Load page 2. Check date column | Shows date with "Today" sub-label in green | ⬜ | ◌ |
| TC-EXM-010 | Verify Upcoming section | 4 future exams | 1. Load page 2. Observe Upcoming | Blue-bordered "Upcoming Exams" with 4 rows | ⬜ | ◌ |
| TC-EXM-011 | Verify days-remaining countdown | Exam in 3 days | 1. Load page 2. Check date column | Shows "in 3 days" with red text (≤3 days) | ⬜ | ◌ |
| TC-EXM-012 | Verify days-remaining normal styling | Exam in 10 days | 1. Load page 2. Check date column | Shows "in 10 days" with default muted colour | ⬜ | ◌ |
| TC-EXM-013 | Verify Concluded section | 3 past exams | 1. Load page 2. Observe Concluded | Grey-bordered "Concluded Exams" with 3 rows | ⬜ | ◌ |
| TC-EXM-014 | Verify exam table columns | Any exam allocation | 1. Load page 2. Observe table | Columns: #, Exam, Subject, Mode, Date, Time Slot, Duration, Max Marks, Venue, Status | ⬜ | ◌ |
| TC-EXM-015 | Verify mode badge: Online | Online exam | 1. Load page 2. Check Mode | Blue badge with desktop icon "Online" | ⬜ | ◌ |
| TC-EXM-016 | Verify mode badge: Offline | Offline exam | 1. Load page 2. Check Mode | Orange badge with pencil icon "Offline" | ⬜ | ◌ |
| TC-EXM-017 | Verify time slot displayed | Start 10:00, End 12:00 | 1. Load page 2. Check Time column | Shows "10:00 AM – 12:00 PM" | ⬜ | ◌ |
| TC-EXM-018 | Verify duration shown | 120 min | 1. Load page 2. Check Duration | Shows "120 min" | ⬜ | ◌ |
| TC-EXM-019 | Verify max marks | 100 marks | 1. Load page 2. Check Marks | Shows "100" (bold) | ⬜ | ◌ |
| TC-EXM-020 | Verify venue | "Room 201" | 1. Load page 2. Check Venue | Shows "Room 201" | ⬜ | ◌ |
| TC-EXM-021 | Verify status badge colours | Upcoming / Today / Concluded | 1. Observe status badges | Upcoming=blue, Today=green, Concluded=grey | ⬜ | ◌ |
| TC-EXM-022 | Verify CLASS allocations included | Class-level exam (class_id = 5) | 1. Load page 2. Find exam | CLASS allocation appears in schedule | ⬜ | ◌ |
| TC-EXM-023 | Verify SECTION allocations included | Section-level exam (class=5, section=A) | 1. Load page 2. Find exam | SECTION allocation appears | ⬜ | ◌ |
| TC-EXM-024 | Verify STUDENT allocations included | Student-specific exam | 1. Load page 2. Find exam | STUDENT allocation appears | ⬜ | ◌ |
| TC-EXM-025 | Verify allocation with null examPaper filtered out | Allocation with exam_paper_id=0 or null paper | 1. Load page 2. Count | Null-paper allocation not shown | ⬜ | ◌ |
| TC-EXM-026 | Verify allocation with null scheduled_date uses exam start_date | No scheduled_date, exam start=15 Apr | 1. Load page 2. Check date | Shows "15 Apr 2026" from exam.start_date | ⬜ | ◌ |
| TC-EXM-027 | Verify allocation with null start/end time excluded from ongoing | No start_time set | 1. Load in exam hours | Not shown in Ongoing section | ⬜ | ◌ |
| TC-EXM-028 | Verify empty state | Student B with no allocations | 1. Navigate to page | Empty state: "No exams scheduled at the moment." | ⬜ | ◌ |
| TC-EXM-029 | Verify attempt attached per allocation | Student has submitted attempt | 1. Load page 2. Check concluded exam | Attempt data accessible on allocation | ⬜ | ◌ |
| TC-EXM-030 | Verify activity log recorded | Valid student | 1. Navigate 2. Check activity_log | Entry: "Student viewed exam schedule." with context | ⬜ | ◌ |
| TC-EXM-031 | Verify page inaccessible without auth | No session | 1. Access page without login | Redirected to login | ⬜ | ◌ |

## 7. Test Summary

| Metric | Count |
|--------|-------|
| Total Test Cases | 31 |
| Automated | — |
| Manual | 31 |
| Pass | — |
| Fail | — |
| Blocked | — |
| Not Executed | 31 |

## 8. Known Issues

| Issue ID | Description | Severity | Status |
|----------|-------------|----------|--------|
| GAP-EXM-01 | No direct "Start Exam" action button in schedule | Medium | ⬜ |
| GAP-EXM-02 | Concluded exams don't show attempt status (attempted vs missed) | Medium | ⬜ |
| GAP-EXM-03 | Countdown only shows days, not hours/minutes for same-day | Low | ⬜ |
| GAP-EXM-04 | Offline exams may have null duration | Low | ⬜ |
| GAP-EXM-05 | Venue not linked to room master data | Low | ⬜ |

## 9. Route Reference

| Method | Path | Route Name | Middleware |
|--------|------|------------|------------|
| GET | `/student-portal/exam-schedule` | `student-portal.exam-schedule` | `auth`, `verified` |

## 10. Execution Status

| Cycle | Date | Tester | Pass | Fail | Blocked | Not Executed | Signature |
|-------|------|--------|------|------|---------|--------------|-----------|
| V1 | — | — | — | — | — | 31 | — |

---

*Test cases derived from controller code analysis, input requirement doc, and FRD cross-reference.*
