# STP — Performance Analytics (Performance Analytics Tab)

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
| **Route** | `GET /performance-analytics` (named `performance-analytics`) |
| **View** | `studentportal::reports.analytics` |
| **Table Prefix** | `std_*`, `lms_*` (reads from StudentProfile Attendance + LmsExam Results) |
| **DB Layer** | Tenant |
| **V1/V2** | — |
| **Status** | ⬜ |
| **CR** | ◌ |
| **Author** | OpenCode |
| **Date** | 2026-07-23 |

---

## 2. Feature Overview

An analytical dashboard that displays the student's attendance history and exam performance metrics across academic sessions. The page provides a session filter, attendance statistics (overall and monthly), and exam result aggregation including subject-wise performance breakdown.

---

## 3. Functional Requirements

### 3.1 Academic Session Filter
- A dropdown selector listing all academic sessions in which the student has been enrolled.
- The default selection is the student's current active academic session.
- Selecting a different session updates all displayed metrics to that session's data.

### 3.2 Attendance Metrics
- Display total number of attendance records for the selected session.
- Breakdown: total days present, total days absent.
- Overall attendance percentage: `round((present / total) * 100)`.
- Monthly attendance breakdown grouped by calendar month (`Y-m` → `M Y` format), with per-month counts of total, present, absent, late, and leave.

### 3.3 Academic Performance Metrics
- **Overall Stats**:
  - `avgPct` — average percentage across all published exam results for the selected session.
  - `bestPct` — highest percentage achieved across results.
  - `passRate` — percentage of results where `result_status = 'PASS'`.
- **Subject-wise Performance Table**:
  - Lists each subject with: subject name, number of exams taken, average percentage score, highest percentage achieved, number of exams passed.
  - Sorted by average percentage descending.
- **Performance Charts** (per FRD): Graphs showing score trends across exams chronologically — **NOT IMPLEMENTED (see GAP below)**.

### 3.4 Data Source Scope
- Attendance data: `std_student_attendance` filtered by `student_id` and `academic_session_id`.
- Exam results: `lms_exam_results` where `is_published = true`, joined via `exam.academic_session_id`.
- Only results whose `examPaper.subject` is not null are included in subject-wise aggregation.

---

## 4. Non-Functional Requirements

| NFR-ID | Requirement | Threshold |
|--------|------------|-----------|
| NFR-STP-001 | Page load time | < 2 seconds for a student with complete attendance + exam data across multiple sessions |
| NFR-STP-003 | Pagination | Not directly paginated (single-page analytics) |
| NFR-STP-006 | IDOR prevention | Only authenticated student's own data shown |
| NFR-STP-008 | Error handling | No stack traces shown; no-student state renders empty analytics with zeros |

---

## 5. Business Rules

| Rule ID | Description | Enforcement |
|---------|-------------|-------------|
| BR-STP-001 | Data must belong to the authenticated student | `$student = auth()->user()->student` — all queries scoped by `student_id` |
| — | Session filter defaults to current active session | `$request->get('session_id', $currentSession?->academic_session_id ?? 0)` |
| — | Session selector lists all sessions with enrollment | `$student->sessions()` ordered by `academic_session_id DESC` |
| — | Attendance status values normalized | Present-like: `Present, P, present, Late, Half Day, Short Leave`; Absent-like: `Absent, A, absent` |
| — | Exam results filtered to published only | `where('is_published', true)` |
| — | Pass determination | `strtoupper($r->result_status ?? '') === 'PASS'` |

---

## 6. User Interface / UX

- **Layout**: Single-page analytics with session selector at top, attendance section (summary + monthly table), exam performance section (overall stats + subject-wise table).
- **Empty State**: When no student record exists, renders page with empty collections and all metrics as zero.
- **Session Switch**: Changing session reloads the page with `?session_id=N` query parameter.
- **No Charts**: Per FRD (RPT-STP-007), "Performance Charts: Graphs showing score trends across exams chronologically" — this is a known gap.

---

## 7. Data Dictionary

| Variable | Source | Type | Description |
|----------|--------|------|-------------|
| `allSessions` | `$student->sessions()` | Collection | All academic session enrollments with class/section |
| `selectedSessionId` | Request or current session | int | Active session ID |
| `attTotal` | `StudentAttendance::count()` | int | Total attendance records |
| `attPresent` | Filtered attendance | int | Records with present-like status |
| `attAbsent` | Filtered attendance | int | Records with absent-like status |
| `overallPct` | Computed | float | Attendance percentage |
| `monthlyStats` | Grouped attendance | Collection | Per-month breakdown (month, total, present, absent, late, leave) |
| `examResults` | `ExamResult` | Collection | Published exam results for selected session |
| `subjectPerformance` | Grouped results | Collection | Subject-wise aggregation (subject, exams, avg_pct, best_pct, passed) |
| `avgPct` | Computed | float | Overall average exam percentage |
| `bestPct` | Computed | float | Highest exam percentage |
| `passRate` | Computed | float | Percentage of results with PASS status |

---

## 8. API / Controller Specifications

### `StudentPortalController@performanceAnalytics(Request $request)`

| Aspect | Detail |
|--------|--------|
| **Method** | `GET` |
| **Auth** | `auth` middleware (web) |
| **Parameters** | `session_id` (optional int) |
| **Ownership** | Scoped to `auth()->user()->student` |
| **Session Resolution** | Defaults to `currentSession()->academic_session_id` |
| **Attendance Scope** | `student_id + academic_session_id` |
| **Exam Scope** | `student_id + is_published + exam.academic_session_id` |
| **View Data** | 13 variables passed to `studentportal::reports.analytics` |

---

## 9. Validation Rules

| Field | Rule | Error |
|-------|------|-------|
| `session_id` | Optional int | Ignored if invalid; falls back to current session |
| No student record | Guard at top | Empty analytics view with zeros |

No Form Request is used — validation is inline.

---

## 10. Error Handling & Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Student has no user-student record | Page renders with empty collections, all metrics = 0 |
| Student has no academic sessions | `allSessions` empty; `selectedStudentSession` = null; attendance/exam sections show zeroes |
| Selected session has no attendance | `attTotal = 0`, `overallPct = 0`, empty `monthlyStats` |
| Selected session has no published exams | Empty `examResults`, `subjectPerformance`, all stats = 0 |
| Invalid `session_id` in querystring | `firstWhere()` returns null → falls back to current session |
| Attendance status contains unexpected values | Filtered by explicit `whereIn`; unrecognised values excluded from present/absent counts |
| Exam result has null subject | Filtered out of subject-wise aggregation (`$r->examPaper?->subject !== null`) |
| Division by zero | Guarded: `$total > 0 ? round(...) : 0` for all percentages |

---

## 11. Security & Compliance

| Concern | Status |
|---------|--------|
| **IDOR** | ✅ All queries scoped to `auth()->user()->student->id`; no user-supplied student ID |
| **Authentication** | ✅ Web auth middleware |
| **Data Minimization** | ✅ Only published results shown |
| **Authorization Gates** | ⚠️ No `Gate::authorize()` calls — relies entirely on student_id scoping |
| **Ownership Check** | ✅ Implicit via `auth()->user()->student` relation |

---

## 12. Integration Points

| Module | Integration | Direction |
|--------|-------------|-----------|
| StudentProfile (STD) | `std_student_attendance` — attendance records read | STP ← STD |
| LmsExam | `lms_exam_results` + `lms_exams` + `lms_exam_papers` + `sch_subjects` — exam results read | STP ← LmsExam |
| StudentProfile (STD) | `std_students` — student identity, session enrollment | STP ← STD |

---

## 13. Performance Considerations

- Attendance query fetches all records for the session (no pagination) — acceptable for typical school year (~200 days).
- Exam results eager-loaded with `exam` + `examPaper.subject` relations.
- Subject-wise aggregation loops over results collection in memory — acceptable for typical subject counts (8–15).
- No caching implemented.

---

## 14. Dependencies & Pre-requisites

| Dependency | Type | Status |
|-----------|------|--------|
| `std_student_attendance` table with data | Data | Required |
| `lms_exam_results` table with published records | Data | Required |
| `std_student_sessions` table with enrollment records | Data | Required |
| `lms_exams` table with `academic_session_id` linking | Schema | Required |
| Student has an active `currentSession()` | Data | Required for default filter |

---

## 15. Known Gaps & Issues

| Gap ID | Description | Severity | Status |
|--------|-------------|----------|--------|
| **GAP-STP-014** | Performance Charts (graphs showing score trends across exams chronologically) per FRD RPT-STP-007 are **not implemented**. Only a subject-wise table is shown. | Medium | 🟡 Open |
| **GAP-STP-005** | The academic-information page (separate) shows marksheet sessions; the analytics page does not link to exam result details | Low | 🟡 Open |
| — | No pagination or lazy-load for large exam result sets across multiple sessions | Low | ⬜ |
| — | No caching for session filter — each switch triggers fresh DB queries | Low | ⬜ |

---

## 16. Traceability Matrix

| Artifact | Reference |
|----------|-----------|
| FRD | REQ-STP-016 |
| Report Spec | RPT-STP-007 |
| Business Rules | BR-STP-001 |
| Controller Method | `StudentPortalController@performanceAnalytics` |
| Route | `GET /performance-analytics` |
| View | `studentportal::reports.analytics` |
| Input Doc | `pgdatabase/Backup/4-Module_Requirement/StudentPortal/my_reports/performance_analytics.md` |
