# Attendance — Business Requirements

## 1. What This Screen Does

The Attendance screen gives parents a read-only view of their active child's attendance records. It provides two complementary views:

1. **Monthly Calendar View** (`/parent-portal/attendance/`) — All attendance records for the academic session grouped by month in a collapsible accordion layout. Each month shows a daily attendance calendar with colour-coded status cells, plus a summary bar (present, absent, late, leave counts and percentage).

2. **Subject-Wise Breakdown** (`/parent-portal/attendance/subject-wise`) — Attendance records grouped by period/subject, showing per-subject totals, present/absent/late counts, and attendance percentage. This view is available only when period-level attendance data is populated.

An **AJAX Monthly endpoint** (`/parent-portal/attendance/monthly?month=2026-03`) returns JSON data for a single month, used by a month-picker widget for on-demand data loading without full page reload.

---

## 2. When This Screen Is Used

- **Daily check** — Parents verify if their child was marked present for the day
- **Monthly review** — Parents review attendance patterns at the end of each month
- **Subject-wise analysis** — Parents identify subjects where the child has low attendance
- **Attendance discrepancy** — Parents check for incorrect absent marks and follow up with the school
- **Parent-Teacher Meeting preparation** — Parents review attendance data before PTM discussions
- **End-of-term review** — Parents check year-to-date attendance percentage

---

## 3. Who Can Access This Screen

- **Parent / Guardian** — Full read-only access for their active linked child
- **System** — Reads data from `std_attendance` module; no write operations

No explicit Gate or Policy exists. Access is controlled by `ParentContextService::resolveChild()` which ensures the parent can only see data for their own linked children. The Attendance module data is read-only — parents cannot mark, edit, or delete attendance records.

---

## 4. How This Screen Works — Step by Step

### 4.1 Attendance Index (Monthly Calendar)

1. Parent navigates to `GET /parent-portal/attendance/`
2. `ParentAttendanceController@index` is invoked
3. `ParentContextService::resolveChild($request)` resolves the active child
4. The child's current academic session is loaded with class-section relationship
5. If no academic session is assigned, the system renders the view with empty collections and summary
6. All attendance records for the child in the current academic session are fetched from `std_attendance`, ordered by `attendance_date`
7. Records are grouped by month (`$records->groupBy(fn ($r) => $r->attendance_date->format('F Y'))`)
8. A summary is built: total count, present count, absent count, late count, leave count, attendance percentage
9. An activity log entry is created: "Viewed attendance" with student context
10. Data is passed to `parentportal::attendance.index` view

**Colour Coding (used by the view layer):**

| Status | Colour |
|---|---|
| Present | Green |
| Absent | Red |
| Half-Day / Late | Orange |
| Holiday | Grey |
| Leave | Blue |
| Not Marked | White |

### 4.2 Attendance Monthly (AJAX)

1. Front-end sends `GET /parent-portal/attendance/monthly?month=2026-03`
2. `ParentAttendanceController@monthly` is invoked
3. Child is resolved via `ParentContextService::resolveChild($request)`
4. Month parameter is parsed — expects `Y-m` format (e.g., `2026-03`)
5. Invalid month format returns HTTP 422 `{"error": "Invalid month format"}`
6. Records are fetched for the date range `[$startOfMonth, $endOfMonth]`, filtered by child and academic session
7. Summary is computed using `buildSummary($records)`
8. Days array is mapped: each record returns `date`, `day`, `weekday`, `status`, `period`, `remarks`
9. An activity log entry is created: "Viewed monthly attendance" with month parameter
10. JSON response is returned: `{ month, summary, days }`

### 4.3 Subject-Wise Attendance

1. Parent navigates to `GET /parent-portal/attendance/subject-wise`
2. `ParentAttendanceController@subjectWise` is invoked
3. Child is resolved; current session loaded with class-section
4. All attendance records for the child in the session are fetched, ordered by date
5. Summary is computed (same as index)
6. Records with a non-empty `attendance_period` are grouped by `attendance_period`
7. For each period, a summary is computed: total, present, absent, late, percentage
8. Periods are sorted by key and indexed
9. If the session has no academic_session_id, empty collections are returned
10. An activity log entry is created: "Viewed subject-wise attendance"
11. Data is passed to `parentportal::attendance.subject-wise` view

---

## 5. Validation Rules

### 5.1 Monthly AJAX Endpoint

| Parameter | Rule | Error Response |
|---|---|---|
| `month` (query) | Optional; defaults to `now()->format('Y-m')`; must be parseable as `Y-m` format | HTTP 422: `{"error": "Invalid month format"}` |

### 5.2 Controller-Level Guards

| Condition | Guard | Behaviour |
|---|---|---|
| No academic session assigned | `if (! $session?->academic_session_id)` | Render view with empty collections; `noSession` flag |
| No period-level attendance data | Filter `attendance_period !== null && attendance_period !== ''` | Empty `byPeriod` collection; friendly empty state |
| Child ownership | `ParentContextService::resolveChild()` | Redirect to no-access if no children |

---

## 6. Business Rules and Conditions

### Rule BR-PPT-001: Child Data Scoping
All attendance data exclusively belongs to the parent's active linked child. Enforced by `ParentContextService::resolveChild()` at the top of every attendance method.

### Rule BR-PPT-012: Child Ownership Verification
Every attendance endpoint calls `ParentContextService::resolveChild()` which verifies the guardian→child link via `std_student_guardian_jnt.can_access_parent_portal`.

### Rule: Read-Only Attendance Data
Parents cannot modify any attendance record. AttendanceController performs no create, update, or delete operations.

### Rule: Attendance Status Convention
The controller accepts multiple status conventions: `Present`, `P`, `present` are treated as present; `Absent`, `A`, `absent` as absent; `Late`, `L`, `late` as late; `Leave`, `leave`, `On Leave` as leave. This handles legacy data from different school setups.

### Rule: Subject-Wise Data Derived from Period
Subject-wise attendance derives subject context from `attendance_period` on the attendance record, not from a direct subject FK. Each period maps to a subject via the timetable. If per-period attendance is not populated, the subject-wise view shows an empty state.

---

## 7. Business Rules Summary

| Rule | What It Means |
|---|---|
| BR-PPT-001 | Attendance data scoped to parent's linked child only |
| BR-PPT-012 | Child ownership verified on every attendance endpoint |
| Read-Only | Parent cannot modify attendance records |
| Status Convention | Multiple status strings normalised (Present/P/present, etc.) |
| Period-Based Subjects | Subject-wise view uses `attendance_period` field, not subject FK |

---

## 8. Error Messages

| Scenario | Error Message / Behaviour |
|---|---|
| No academic session assigned | Empty attendance view with `noSession = true` flag |
| Invalid month format in AJAX | HTTP 422: `{"error": "Invalid month format"}` |
| No period attendance data | Subject-wise view shows empty period list with friendly message |
| Child resolution fails | Redirect to `/no-access` |

---

## 9. Success Scenarios

- **Monthly calendar loads**: Parent sees 12 accordion panels (one per month from session start). Each month shows colour-coded attendance for each school day. Summary bar shows "Present: 22, Absent: 1, Late: 1, Leave: 1 — 88%".
- **AJAX month change**: Parent clicks a different month in the month picker. JSON response updates the calendar without page reload. The new month's data appears.
- **Subject-wise view**: Parent sees a table with rows for each period (Period 1: Science, Period 2: Math, etc.). Each row shows total days, present/absent/late counts, and percentage. The parent identifies that Math attendance is only 70% versus overall 92%.
- **Empty attendance**: New student with no attendance records yet. The attendance page shows empty months with a "No attendance records found" message.

---

## 10. Failure Scenarios

- **Parent with no academic session**: Attendance page loads with empty data and `noSession = true` flag. No error is shown — the page gracefully shows "Academic session not assigned" message.
- **Invalid month parameter**: AJAX endpoint returns 422 with `{"error": "Invalid month format"}`. The front-end should display a user-friendly message.
- **Backend database timeout**: Laravel exception handler returns 500. No graceful degradation for infrastructure failure.

---

## 11. Example Scenario

Mr. Patel logs into the Parent Portal and navigates to Attendance for his daughter Ananya (Class 8A). The academic session runs April 2026 – March 2027.

1. **Monthly Calendar**: The page shows accordion panels for April, May, June (current month). April shows 22 working days: 20 green (Present), 1 red (Absent — Ananya was sick), 1 orange (Late — reached late after doctor's appointment). Summary: Present 20, Absent 1, Late 1 — 90.9%.

2. **AJAX Month Picker**: Mr. Patel picks "May 2026" from the month picker. The AJAX call returns JSON. The May panel shows 20 Present, 1 Leave (school trip), 1 Holiday (Buddha Purnima) — 95.2%.

3. **Subject-Wise**: Mr. Patel navigates to subject-wise view. He sees that Ananya's attendance in Mathematics is only 65% (13 Present, 7 Absent) while other subjects are above 90%. He makes a note to discuss this with the Math teacher at the next PTM.

---

## 12. Related Screens

| Screen | Route | Relationship |
|---|---|---|
| Dashboard | `/parent-portal/` | Attendance % widget deep-links to this page |
| Timetable | `/parent-portal/timetable` | Period-based attendance relates to timetable structure |
| Leave | `/parent-portal/leave` | Leave days appear as "Leave" (blue) in attendance calendar |

---

## 13. How Other Parts of the System Depend on This Screen

| Area | What It Needs From Attendance |
|---|---|
| **Dashboard** | Attendance % computed from same `std_attendance` data |
| **Leave Module** | Approved leave days marked as "Leave" status in attendance |
| **Absence Alerts** | System uses attendance marking to trigger absence notifications |

---

## 14. Dependencies

| Dependency | Type | Purpose |
|---|---|---|
| `ParentContextService` | Internal service | Child resolution |
| `std_attendance` (StudentAttendance model) | External model | Core attendance records |
| `student_id`, `academic_session_id` | Query filters | Scope attendance data to child and session |
| `attendance_period` | Field | Subject-wise grouping |
| `attendance_date` | Field | Monthly grouping and ordering |
| `activityLog()` | Global helper | Audit logging |

---

## 15. State Machine

### Attendance View Selection

| View | Trigger | Data Source | Output |
|---|---|---|---|
| Monthly Calendar | GET /attendance | All records grouped by month | Accordion panels with colour-coded days |
| Monthly JSON | GET /attendance/monthly?month=X | Single month filtered by date range | JSON with summary + day array |
| Subject-Wise | GET /attendance/subject-wise | All records grouped by period | Period-wise summary table |

### Attendance Data Flow

| Step | Event | Guard | Result |
|---|---|---|---|
| 1 | Parent opens attendance | Resolve child | Child + session obtained |
| 2 | Fetch records | academic_session_id exists | Records returned (or empty) |
| 3 | Group by month | Records exist | Monthly accordion built |
| 4 | Build summary | Records exist | Summary computed |
| 5 | Render view | All data ready | Attendance page displayed |

---

## 16. Notes and Gaps

| # | Note | Impact |
|---|---|---|
| 1 | **No explicit authorization Gate:** Like the dashboard, the attendance controller has no `Gate::authorize()` or policy check. All protection is via `ParentContextService`. | If any method bypasses context service, data would leak. |
| 2 | **Status values hardcoded:** The `buildSummary()` helper hardcodes status arrays without referencing a config, enum, or constant. If the Attendance module adds new status values, they won't be counted correctly. | Potential miscounting of new status types. |
| 3 | **Subject-wise uses period string, not FK:** The subject-wise view groups by `attendance_period` as a string. This means "Period 1" and "period 1" would be treated as different groups (case-sensitive). | Potential duplicate groups in subject-wise view. |
| 4 | **No caching:** Attendance data is queried from DB on every page load. For a full academic year with 200+ records, this is acceptable but could be optimised with a short TTL cache. | Acceptable performance; optimisation opportunity. |
| 5 | **No absence alert integration:** The FRD specifies same-day absence alerts delivered within 5 minutes. The controller reads attendance data but does not trigger or acknowledge absence notifications. | Absence alert feature is a separate system concern. |
