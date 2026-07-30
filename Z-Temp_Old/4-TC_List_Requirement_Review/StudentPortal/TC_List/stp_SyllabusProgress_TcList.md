# stp_SyllabusProgress — Test Case List

## 1. Module Feature Information

| Field | Value |
|-------|-------|
| Module Code | STP |
| Module Name | StudentPortal |
| Feature Name | Syllabus Progress |
| FRD Reference | REQ-STP-013, BR-STP-001 |
| Route | `student-portal.syllabus-progress` (GET `/student-portal/syllabus-progress`) |
| Controller | `StudentProgressController@syllabusProgress` |
| View | `studentportal::syllabus.progress` |

## 2. Feature Overview

Displays syllabus completion progress for the student's class and section. Shows overall KPI cards (completed, in progress, upcoming, total topics), a stacked progress bar, per-subject cards with lesson→topic accordion, and dynamic status badges derived from scheduled start/end dates.

## 3. Test Scope

### In Scope
- Overall KPI card values (completed, in progress, upcoming, total)
- Overall progress bar (green + amber segments)
- Per-subject card rendering (name, progress %, lesson count, topic count)
- Lesson accordion expand/collapse
- Topic table columns and values
- Dynamic status computation (completed / in_progress / upcoming)
- Priority dot styling (HIGH=red, MEDIUM=amber, LOW=blue)
- Empty states (no student, no class, no schedules)
- Activity logging

### Out of Scope
- Syllabus schedule creation/management
- Cross-student data comparison

## 4. Test Environment / Pre-requisites

| Requirement | Details |
|-------------|---------|
| Backend | Laravel 12, PHP 8.2+ |
| Database | MySQL 8 — Tenant DB with `slb_syllabus_schedule`, `slb_lessons`, `slb_topics`, `sch_subjects` |
| Auth | Authenticated as Student user with class/section assigned |
| Browser | Chrome/Firefox/Edge (latest), JavaScript enabled for accordion |

## 5. Test Data Setup

- **Subject A (Mathematics):** 3 lessons, each with 3–5 topics, mixed completed/in_progress/upcoming statuses
- **Subject B (Science):** 2 lessons, all topics completed (100%)
- **Subject C (English):** 1 lesson, all topics upcoming (0%)
- **Student X:** No syllabus schedules for class/section
- **Student Y:** Class with section_id=NULL schedules (school-wide topics)

## 6. Test Cases

| TC ID | Test Case | Pre-requisites | Test Steps | Expected Result | Status | CR |
|-------|-----------|----------------|------------|-----------------|--------|----|
| TC-SYL-001 | Verify page loads for valid student | Student with class, session, and syllabus data | 1. Navigate to `/student-portal/syllabus-progress` | Page loads with breadcrumb "Home > Syllabus Progress", title "Syllabus Progress" | ⬜ | ◌ |
| TC-SYL-002 | Verify overall KPI cards display correct totals | 3 subjects, 6 lessons, 24 topics (12 completed, 5 in progress, 7 upcoming) | 1. Load page 2. Observe KPI row | Completed=12, In Progress=5, Upcoming=7, Total Topics=24 | ⬜ | ◌ |
| TC-SYL-003 | Verify overall progress bar | 12 completed / 24 total = 50% | 1. Load page 2. Observe progress bar | Green bar at ~50%, amber bar at ~21% (5/24), remainder grey | ⬜ | ◌ |
| TC-SYL-004 | Verify overall percentage label | 12 completed / 24 total = 50% | 1. Load page 2. Observe overall completion label | Shows "50%" | ⬜ | ◌ |
| TC-SYL-005 | Verify class/session header info | Student enrolled in Class 5-A, Session 2025-26 | 1. Load page 2. Observe header bar | Shows "Class 5 — Section A", "2025-26", roll number | ⬜ | ◌ |
| TC-SYL-006 | Verify per-subject card for Mathematics | Subject with 3 lessons, 12 topics | 1. Load page 2. Find Mathematics card | Shows subject name "Mathematics", lesson count "3 lessons", "12 topics", progress % | ⬜ | ◌ |
| TC-SYL-007 | Verify per-subject progress bar | Subject with mixed statuses | 1. Load page 2. Observe subject progress bar | Green + amber segments proportional to completed/in_progress | ⬜ | ◌ |
| TC-SYL-008 | Verify "X% COVERED" pill badge on subject | Mathematics at 60% completion | 1. Load page 2. Observe subject header | Pill badge shows "60% COVERED" with subject-colour background | ⬜ | ◌ |
| TC-SYL-009 | Verify lesson accordion expands | Any lesson (not first) collapsed by default | 1. Click on a collapsed lesson header | Lesson body expands; chevron rotates 180° | ⬜ | ◌ |
| TC-SYL-010 | Verify first lesson expanded by default | First lesson in first subject | 1. Load page 2. Observe first lesson | Lesson body visible with `aria-expanded="true"` | ⬜ | ◌ |
| TC-SYL-011 | Verify topic table columns | Lesson with topics | 1. Expand lesson 2. Observe table | Columns: Topic Details, Scheduled Timeline, Duration/Periods, Instructor, Priority, Status | ⬜ | ◌ |
| TC-SYL-012 | Verify completed topic styling | Topic with end date in past | 1. Expand lesson with completed topic 2. Observe row | Row has muted background; title shows strikethrough; status badge "Completed" green | ⬜ | ◌ |
| TC-SYL-013 | Verify in_progress topic styling | Topic where today is between start and end | 1. Expand lesson with active topic 2. Observe row | Status badge "In Progress" amber; no strikethrough | ⬜ | ◌ |
| TC-SYL-014 | Verify upcoming topic styling | Topic with start date in future | 1. Expand lesson with upcoming topic 2. Observe row | Status badge "Upcoming" grey; normal styling | ⬜ | ◌ |
| TC-SYL-015 | Verify topic level badge displayed | Topic with level type "Core" | 1. Expand lesson 2. Find topic with level | Shows grey badge "Core" next to topic name | ⬜ | ◌ |
| TC-SYL-016 | Verify topic notes displayed | Topic with notes="Use visual aids" | 1. Expand lesson 2. Find topic with notes | Italic text "Use visual aids" shown below topic name | ⬜ | ◌ |
| TC-SYL-017 | Verify priority dot colours | Topic with HIGH, MEDIUM, LOW priorities | 1. Expand lesson 2. Observe priority column | HIGH=red dot, MEDIUM=amber dot, LOW=blue dot | ⬜ | ◌ |
| TC-SYL-018 | Verify assigned teacher displayed | Topic with assigned teacher | 1. Expand lesson 2. Observe instructor column | Shows teacher name with user icon | ⬜ | ◌ |
| TC-SYL-019 | Verify scheduled date range | Topic with start=01 Apr 2026, end=03 Apr 2026 | 1. Expand lesson 2. Observe timeline column | Shows "01 Apr 2026 – 03 Apr 2026" | ⬜ | ◌ |
| TC-SYL-020 | Verify duration shown in minutes | Topic with duration_minutes=45 | 1. Expand lesson 2. Observe duration column | Shows "45 min" | ⬜ | ◌ |
| TC-SYL-021 | Verify periods shown when duration absent | Topic with planned_periods=2 | 1. Expand lesson 2. Observe duration column | Shows "2 periods" | ⬜ | ◌ |
| TC-SYL-022 | Verify "FULLY COVERED" badge | Lesson where all topics completed | 1. Expand fully covered lesson 2. Observe footer | Shows green badge "✓ FULLY COVERED" in footer | ⬜ | ◌ |
| TC-SYL-023 | Verify "ACTIVE" badge | Lesson with any in_progress topic | 1. Expand lesson with active topic 2. Observe footer | Shows amber badge "ACTIVE" in footer | ⬜ | ◌ |
| TC-SYL-024 | Verify empty state: no student profile | User without student relation | 1. Navigate to page | Empty state: "No active session found. Please contact your school admin." | ⬜ | ◌ |
| TC-SYL-025 | Verify empty state: no class assigned | Student with session but no class_id | 1. Navigate to page | Empty state with noSession=true | ⬜ | ◌ |
| TC-SYL-026 | Verify empty state: no syllabus schedules | Student with class but no schedules | 1. Navigate to page | Empty state: "No syllabus scheduled yet. Your class syllabus will appear here once your school adds it." | ⬜ | ◌ |
| TC-SYL-027 | Verify subject with 100% completion | All topics in subject completed | 1. Load page 2. Observe full subject | Progress bar 100% green; "100% COVERED" badge | ⬜ | ◌ |
| TC-SYL-028 | Verify subject with 0% completion | All topics upcoming | 1. Load page 2. Observe subject | Progress bar 0% green; "0% COVERED" badge | ⬜ | ◌ |
| TC-SYL-029 | Verify schedules with null section_id included | School-wide topic with section=NULL | 1. Load page 2. Observe subjects | Topic appears in schedule (included via orWhereNull) | ⬜ | ◌ |
| TC-SYL-030 | Verify topic with null teacher | Topic with no assigned teacher | 1. Expand lesson 2. Observe instructor | Shows "—" | ⬜ | ◌ |
| TC-SYL-031 | Verify topic with null scheduled dates | Topic with null start/end dates | 1. Expand lesson 2. Observe timeline | Shows "—" | ⬜ | ◌ |
| TC-SYL-032 | Verify activity log recorded | Valid student with schedules | 1. Navigate to page 2. Check activity_log | Entry: "Student viewed syllabus progress." with context | ⬜ | ◌ |
| TC-SYL-033 | Verify page inaccessible without auth | No session | 1. Access page without login | Redirected to login | ⬜ | ◌ |

## 7. Test Summary

| Metric | Count |
|--------|-------|
| Total Test Cases | 33 |
| Automated | — |
| Manual | 33 |
| Pass | — |
| Fail | — |
| Blocked | — |
| Not Executed | 33 |

## 8. Known Issues

| Issue ID | Description | Severity | Status |
|----------|-------------|----------|--------|
| GAP-SYL-01 | No subject code filter — may include subjects outside curriculum | Low | ⬜ |
| GAP-SYL-02 | Status computed from dates only — no teacher override | Low | ⬜ |
| GAP-SYL-04 | Priority values not standardised — case-sensitive match in view | Medium | ⬜ |
| GAP-SYL-05 | No caching — schedules re-queried on every load | Medium | ⬜ |

## 9. Route Reference

| Method | Path | Route Name | Middleware |
|--------|------|------------|------------|
| GET | `/student-portal/syllabus-progress` | `student-portal.syllabus-progress` | `auth`, `verified` |

## 10. Execution Status

| Cycle | Date | Tester | Pass | Fail | Blocked | Not Executed | Signature |
|-------|------|--------|------|------|---------|--------------|-----------|
| V1 | — | — | — | — | — | 33 | — |

---

*Test cases derived from controller code analysis, input requirement doc, and FRD cross-reference.*
