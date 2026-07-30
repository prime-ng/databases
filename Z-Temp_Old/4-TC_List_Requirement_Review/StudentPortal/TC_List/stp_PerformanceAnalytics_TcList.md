# STP — Performance Analytics: Test Case List

## 1. Document Control

| Field | Value |
|-------|-------|
| **Module** | StudentPortal (STP) |
| **Feature ID** | STP-F016 |
| **Feature Name** | Performance Analytics |
| **REQ ID(s)** | REQ-STP-016 |
| **RPT ID(s)** | RPT-STP-007 |
| **BR ID(s)** | BR-STP-001 |
| **Controller** | `StudentPortalController@performanceAnalytics` |
| **Route** | `GET /performance-analytics` |
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
| **Database** | MySQL 8 (Tenant DB) |
| **Auth** | Authenticated web session (student role) |
| **Browser** | Chrome/Firefox/Safari (responsive web) |
| **Test Data** | Seeded student with multiple academic sessions, attendance records, published exam results |

---

## 3. Test Approach

- **Level**: Functional / System
- **Type**: Positive, Negative, Boundary, UI, Security (IDOR)
- **Method**: Manual + Automated (Pest)
- **Data Setup**: Requires tenant DB with `std_students`, `std_student_attendance`, `lms_exam_results`, `std_student_sessions` records
- **Key Focus Areas**: Session filtering, attendance metrics accuracy, exam results aggregation, subject-wise computation, empty states, data ownership

---

## 4. Test Scope

### In Scope
- Session filter dropdown interaction
- Attendance metrics display and accuracy
- Monthly attendance breakdown
- Overall exam stats (avg %, best %, pass rate)
- Subject-wise performance table
- Empty state when no student record
- Empty state when no data for selected session
- Data ownership (IDOR) — cannot view another student's analytics
- Page load performance

### Out of Scope
- Performance charts/graphs (not implemented per GAP-STP-014)
- PDF export of analytics
- Comparison with other students
- Predictive analytics

---

## 5. Test Cases

| TC ID | Test Case | Pre-condition | Test Steps | Expected Result | Priority | Automation |
|-------|-----------|---------------|------------|----------------|----------|------------|
| TC-PA-001 | Verify page loads for authenticated student with data | Student A has attendance + exam results in current session | 1. Login as Student A<br>2. Navigate to `/performance-analytics` | Page renders without errors; session filter shows all enrolled sessions; default is current session | P1 | Yes |
| TC-PA-002 | Verify session filter dropdown lists all enrolled sessions | Student A enrolled in Session 2025-26 and 2026-27 | 1. Login as Student A<br>2. Navigate to Performance Analytics<br>3. Open session dropdown | Dropdown contains both sessions with correct labels (class-section-session info) | P1 | Yes |
| TC-PA-003 | Verify session filter switches data | Student A has different attendance/exam data in two sessions | 1. Login as Student A<br>2. Select Session 2025-26 from dropdown<br>3. Verify metrics<br>4. Switch to Session 2026-27 | Attendance and exam metrics update to reflect the selected session's data | P1 | Yes |
| TC-PA-004 | Verify attendance total matches DB count | Student A has 180 attendance records in session | 1. Login as Student A<br>2. Navigate to Performance Analytics | Attendance total displays 180; present + absent = 180 (approximately) | P1 | Yes |
| TC-PA-005 | Verify attendance percentage computation | Student A: 180 total, 162 present-like records | 1. Login as Student A<br>2. Navigate to Performance Analytics | Attendance percentage = 90% (162/180 × 100) | P1 | Yes |
| TC-PA-006 | Verify monthly attendance breakdown | Student A has attendance across Jan–Mar 2026 | 1. Login as Student A<br>2. Navigate to Performance Analytics | Monthly breakdown shows Jan 2026, Feb 2026, Mar 2026 with correct per-month totals and percentages | P2 | Yes |
| TC-PA-007 | Verify overall exam average percentage | Student A has 5 published results: 85%, 90%, 70%, 95%, 80% | 1. Login as Student A<br>2. Navigate to Performance Analytics | Average percentage = 84.0% | P1 | Yes |
| TC-PA-008 | Verify best/highest percentage | Student A's highest result is 95% | 1. Login as Student A<br>2. Navigate to Performance Analytics | Best percentage = 95.0% | P2 | Yes |
| TC-PA-009 | Verify pass rate computation | Student A: 4 PASS out of 5 results | 1. Login as Student A<br>2. Navigate to Performance Analytics | Pass rate = 80% | P1 | Yes |
| TC-PA-010 | Verify subject-wise performance table | Student A has results in Maths, Science, English across multiple exams | 1. Login as Student A<br>2. Navigate to Performance Analytics | Table lists each subject with: exams count, avg %, best %, passed count; sorted by avg % descending | P1 | Yes |
| TC-PA-011 | Verify subject aggregation — multiple exams per subject | Student A: 3 Maths exams (88%, 92%, 85%) | 1. Login as Student A<br>2. Navigate to Performance Analytics | Maths row: exams = 3, avg_pct = 88.3, best_pct = 92, passed = 3 | P2 | Yes |
| TC-PA-012 | Verify exam results with null subject are excluded from subject table | Student A has one result with null subject_id | 1. Login as Student A<br>2. Navigate to Performance Analytics | The null-subject result does not appear in subject performance table; overall stats still include it | P2 | Yes |
| TC-PA-013 | Verify empty state — no student record | User has no linked student record | 1. Login as user without student record<br>2. Navigate to `/performance-analytics` | Page renders with empty collections; all metrics display 0 | P1 | Yes |
| TC-PA-014 | Verify empty state — session with no attendance | Student A selects a session with zero attendance records | 1. Login as Student A<br>2. Navigate to Performance Analytics<br>3. Select session with no attendance recorded | Total = 0, present = 0, absent = 0, percentage = 0%; monthly breakdown empty | P2 | Yes |
| TC-PA-015 | Verify empty state — session with no published exam results | Student A selects a session with no published results | 1. Login as Student A<br>2. Navigate to Performance Analytics<br>3. Select session with no published results | Exam results section shows zeroes; subject table empty | P2 | Yes |
| TC-PA-016 | Verify IDOR — cannot access another student's analytics | Student A and Student B exist | 1. Login as Student A<br>2. Attempt to modify `session_id` parameter or student identifier | No other student's data exposed; all data scoped to authenticated user | P1 | Yes |
| TC-PA-017 | Verify page with malformed session_id | Student A passes `?session_id=abc` | 1. Login as Student A<br>2. Navigate to `/performance-analytics?session_id=abc` | Falls back to current session without error | P2 | Yes |
| TC-PA-018 | Verify page with non-existent session_id | Student A passes `?session_id=99999` | 1. Login as Student A<br>2. Navigate to `/performance-analytics?session_id=99999` | `selectedStudentSession` = null; page renders with empty data for all metrics | P2 | Yes |
| TC-PA-019 | Verify activity log entry on page view | Student A views the page | 1. Login as Student A<br>2. Navigate to `/performance-analytics` | Activity log records 'Viewed' with student_id and route name | P3 | No |
| TC-PA-020 | Verify page load time | Student A with complete data across 3 sessions | 1. Login as Student A<br>2. Measure load time (3 runs) | Average load time < 2 seconds | P2 | No |

---

## 6. Regression Impact

| Area | Impact | Suggested Tests |
|------|--------|----------------|
| StudentProfile module | Attendance data source change could affect metrics | Verify attendance count accuracy after any attendance schema change |
| LmsExam module | Exam result schema/status changes could affect aggregation | Verify subject-wise table after result schema changes |
| Student sessions | Session enrollment structure changes could break filter | Verify dropdown lists all sessions after enrollment changes |
| Dashboard | Dashboard also shows attendance % widget | Verify dashboard still shows correct attendance after any attendance logic change |

---

## 7. Known Gaps & Issues

| Gap ID | Description | Impact on Testing |
|--------|-------------|-------------------|
| GAP-STP-014 | Performance charts (graphs) not implemented per FRD RPT-STP-007 | TC-PA-007 through TC-PA-009 only verify numeric values; chart rendering cannot be tested |
| — | No Form Request validation — session_id validated inline | Cannot unit-test validation rules independently |
| — | Attendance status values include raw DB values (e.g. 'P', 'present') | Tests must account for inconsistent status values |
| — | No `Gate::authorize()` policy | Security relies entirely on query scoping |

---

## 8. Sign-off Criteria

| Criteria | Target |
|----------|--------|
| P1 Test Cases Passed | 100% |
| P2 Test Cases Passed | 100% |
| CRITICAL/SHOWSTOPPER defects | 0 |
| IDOR security test passed | TC-PA-016 pass |
| Page load time | < 2s average |

---

## 9. Appendices

### A. Test Data Requirements
- Student with 2+ academic sessions enrolled
- At least 100 attendance records across sessions with varied statuses
- At least 10 published exam results across 3+ subjects
- At least 1 result with PASS and 1 with FAIL status
- At least 1 result with null subject_id
- User account without linked student record (for empty state)

### B. Related Routes
```
GET /performance-analytics → StudentPortalController@performanceAnalytics
```

---

## 10. Traceability

| Artifact | Reference |
|----------|-----------|
| FRD | REQ-STP-016, RPT-STP-007 |
| Business Rules | BR-STP-001 |
| Requirement Doc | `stp_PerformanceAnalytics_Requirement.md` |
| Controller | `StudentPortalController@performanceAnalytics` |
| View | `studentportal::reports.analytics` |
| Input Doc | `pgdatabase/Backup/4-Module_Requirement/StudentPortal/my_reports/performance_analytics.md` |
