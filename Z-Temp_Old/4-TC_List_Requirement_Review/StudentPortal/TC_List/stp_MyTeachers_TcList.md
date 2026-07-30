# stp_MyTeachers — Test Case List

## 1. Module Feature Information

| Field | Value |
|-------|-------|
| Module Code | STP |
| Module Name | StudentPortal |
| Feature Name | My Teachers |
| FRD Reference | REQ-STP-014, BR-STP-001 |
| Route | `student-portal.my-teachers` (GET `/student-portal/my-teachers`) |
| Controller | `StudentTeachersController@index` |
| View | `studentportal::teachers.index` |

## 2. Feature Overview

Lists all teachers assigned to the student's class/section via published timetable cells. Each teacher card shows subjects taught, active days, email, and a chat button. Includes stat cards and a weekly schedule matrix.

## 3. Test Scope

### In Scope
- Stat cards (teacher count, subject count, school days, class name)
- Teacher profile cards (name, subjects, days, email, chat)
- Initials avatar generation
- Teacher Schedule matrix table
- Chat button click behaviour
- Empty states (no student, no class, no teachers)
- Activity logging

### Out of Scope
- Chat widget full functionality
- Teacher profile detail page

## 4. Test Environment / Pre-requisites

| Requirement | Details |
|-------------|---------|
| Backend | Laravel 12, PHP 8.2+ |
| Database | MySQL 8 — Tenant DB with timetable tables, teacher records |
| Auth | Authenticated as Student user |
| Browser | Chrome/Firefox/Edge (latest), JavaScript enabled for chat button |

## 5. Test Data Setup

- **Student A:** Class 5-A with published timetable assigning 8 teachers across 10 subjects
- **Student B:** Class with no published timetable
- **Teacher 1:** Mathematics — Mon, Wed, Fri (3 periods)
- **Teacher 2:** Science & Physics — Tue, Thu (2 subjects, 2 days)
- **Teacher 3:** Only assigned to a cell with `is_break=true` — should NOT appear
- **Teacher 4:** Has no user email

## 6. Test Cases

| TC ID | Test Case | Pre-requisites | Test Steps | Expected Result | Status | CR |
|-------|-----------|----------------|------------|-----------------|--------|----|
| TC-TCH-001 | Verify page loads for valid student | Student A with published timetable | 1. Navigate to `/student-portal/my-teachers` | Page loads with breadcrumb "Home > My Teachers", title "My Teachers" | ⬜ | ◌ |
| TC-TCH-002 | Verify stat cards | 8 teachers, 10 subjects, 6 days, Class 5-A | 1. Load page 2. Observe stat row | 4 cards: Teachers=8, Subjects=10, Days=6, Class="5 – A" | ⬜ | ◌ |
| TC-TCH-003 | Verify teacher cards rendered | 8 teachers assigned | 1. Load page 2. Count teacher cards | 8 teacher cards in the grid layout | ⬜ | ◌ |
| TC-TCH-004 | Verify teacher name displayed | Teacher "Rajesh Sharma" | 1. Load page 2. Find teacher card | Shows "Rajesh Sharma" | ⬜ | ◌ |
| TC-TCH-005 | Verify initials avatar | Teacher "Rajesh Sharma" | 1. Load page 2. Find avatar | Shows "R" in coloured circle | ⬜ | ◌ |
| TC-TCH-006 | Verify subjects taught listed | Teacher teaches Mathematics and Physics | 1. Load page 2. Find teacher card | Shows "Mathematics, Physics" | ⬜ | ◌ |
| TC-TCH-007 | Verify active days displayed | Teacher active Mon, Wed, Fri | 1. Load page 2. Find teacher card | Shows "Mon, Wed, Fri" with calendar icon | ⬜ | ◌ |
| TC-TCH-008 | Verify email link | Teacher has email "rajesh@school.com" | 1. Load page 2. Find email | Shows clickable "rajesh@school.com" with mailto link | ⬜ | ◌ |
| TC-TCH-009 | Verify email hidden when null | Teacher with no email | 1. Load page 2. Find teacher | Email section shows empty/nothing | ⬜ | ◌ |
| TC-TCH-010 | Verify chat button present | Teacher has user_id | 1. Load page 2. Find teacher card | "Chat" button with comment icon | ⬜ | ◌ |
| TC-TCH-011 | Verify chat button click triggers DM | Chat widget loaded | 1. Click Chat button on teacher card | Calls `window.studentChatApi.startDm(userId)` or redirects to chat page | ⬜ | ◌ |
| TC-TCH-012 | Verify chat button fallback redirect | Chat widget not loaded | 1. Click Chat button | Redirects to `/student-portal/chat` | ⬜ | ◌ |
| TC-TCH-013 | Verify teacher schedule matrix table | 8 teachers across 6 days | 1. Scroll below teacher cards | Table with columns: Teacher, Subjects, Mon–Sat. Shows period labels per teacher per day | ⬜ | ◌ |
| TC-TCH-014 | Verify schedule matrix period labels | Teacher has P1, P3 on Monday | 1. Find teacher in matrix 2. Check Mon column | Shows "P1, P3" | ⬜ | ◌ |
| TC-TCH-015 | Verify schedule matrix shows "—" for no-class days | Teacher not active on Thursday | 1. Find teacher in matrix 2. Check Thu column | Shows "—" | ⬜ | ◌ |
| TC-TCH-016 | Verify teacher with multiple subjects appears once | Teacher teaches 2 subjects | 1. Load page 2. Search for teacher | Single card listing both subjects | ⬜ | ◌ |
| TC-TCH-017 | Verify teacher from break cells excluded | Teacher only assigned to break activity | 1. Load page 2. Check all cards | Teacher not listed (break cells still carry activity teachers but should be filtered) — NOTE: current code does NOT filter break cells | ⬜ | ◌ |
| TC-TCH-018 | Verify empty state: no student profile | User without student relation | 1. Navigate to page | "No active session found. Teachers will appear once you are enrolled in a class." | ⬜ | ◌ |
| TC-TCH-019 | Verify empty state: no class section | Student without classSection | 1. Navigate to page | Empty state with noSession=true | ⬜ | ◌ |
| TC-TCH-020 | Verify empty state: no teachers found | Class with no published timetable | 1. Navigate to page | "No teachers found for your class in the active timetable." | ⬜ | ◌ |
| TC-TCH-021 | Verify teacher colour cycling | 9th teacher (index 8) | 1. Load page 2. Observe card colours | Cycle of 6 colours restarts: card 9 has colour[8 % 6] = colour[2] | ⬜ | ◌ |
| TC-TCH-022 | Verify teacher with no user name | Teacher with null user->name | 1. Load page 2. Find teacher | Shows "Unknown" as name | ⬜ | ◌ |
| TC-TCH-023 | Verify activity log recorded | Valid student with teachers | 1. Navigate 2. Check activity_log | Entry: "Student viewed my teachers." with context | ⬜ | ◌ |
| TC-TCH-024 | Verify page inaccessible without auth | No session | 1. Access page without login | Redirected to login | ⬜ | ◌ |

## 7. Test Summary

| Metric | Count |
|--------|-------|
| Total Test Cases | 24 |
| Automated | — |
| Manual | 24 |
| Pass | — |
| Fail | — |
| Blocked | — |
| Not Executed | 24 |

## 8. Known Issues

| Issue ID | Description | Severity | Status |
|----------|-------------|----------|--------|
| GAP-TCH-01 | Teachers sourced only from TimetableCell — unassigned class teachers excluded | Medium | ⬜ |
| GAP-TCH-02 | No profile picture — always initials avatar | Low | ⬜ |
| GAP-TCH-04 | No contact phone number displayed | Low | ⬜ |
| GAP-TCH-06 | Break cell teachers not explicitly filtered — teachers assigned only to break activities may appear | Medium | ⬜ |

## 9. Route Reference

| Method | Path | Route Name | Middleware |
|--------|------|------------|------------|
| GET | `/student-portal/my-teachers` | `student-portal.my-teachers` | `auth`, `verified` |

## 10. Execution Status

| Cycle | Date | Tester | Pass | Fail | Blocked | Not Executed | Signature |
|-------|------|--------|------|------|---------|--------------|-----------|
| V1 | — | — | — | — | — | 24 | — |

---

*Test cases derived from controller code analysis, input requirement doc, and FRD cross-reference.*
