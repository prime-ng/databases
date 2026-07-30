# stp_MyAttendance — Requirement Document

## 1. Module Information

| Field | Value |
|-------|-------|
| Module Code | STP |
| Module Name | StudentPortal |
| Feature Name | My Attendance |
| Table Prefix | stp_ (consumes `std_student_attendance`) |
| DB Layer | Tenant (`tenant_{uuid}`) |
| Route Name | `student-portal.my-attendance` |
| HTTP Method + Path | GET `/student-portal/my-attendance` |
| Controller | `StudentProgressController@attendance` |
| View | `studentportal::attendance.index` |
| Input Doc | `pgdatabase/Backup/4-Module_Requirement/StudentPortal/academics/my_attendance.md` |
| FRD Reference | REQ-STP-007, BR-STP-001, BR-STP-014, BR-STP-015 |

## 2. Feature Overview

Displays a student's attendance records from the `std_student_attendance` table, scoped to the student's current academic session. The page presents a vitals summary (total, present, absent, late, leave counts + percentage), followed by month-wise grouped attendance logs. Each month supports two views: a colour-coded calendar grid and a tabular list view.

## 3. Functional Requirements

| ID | Requirement | Status |
|----|-------------|--------|
| F1 | Load attendance records for the authenticated student scoped to their current academic session | ✅ |
| F2 | Compute summary: total school days, present count, absent count, late count, leave count | ✅ |
| F3 | Calculate attendance percentage = (present / total) × 100, rounded to 1 decimal | ✅ |
| F4 | Group attendance records by month (format: "F Y", e.g. "March 2026") | ✅ |
| F5 | Render a colour-coded calendar grid per month with day-level status indicators | ✅ |
| F6 | Render a list table per month with Date, Day, Period (if applicable), Status badge, Remarks | ✅ |
| F7 | Provide toggle between Calendar view and List view (JS-driven) | ✅ |
| F8 | Apply status normalization: Present/P/Absent/A/Late/L/Leave/On Leave → unified display | ✅ |
| F9 | Record activity log on each page view via `activityLog()` | ✅ |
| F10 | Show empty/no-session state when student profile or session is missing | ✅ |

## 4. Business Rules

| Rule ID | Rule Description | Enforcement |
|---------|-----------------|-------------|
| BR-STP-001 | Data must belong to the authenticated student | Controller enforces via `auth()->user()->student` |
| BR-STP-014 | Attendance records scoped to current academic session | `where('academic_session_id', $sessionId)` |
| BR-STP-015 | Attendance status normalized to Present/Absent/Late/On Leave | Controller maps raw values: `['Present','P','present']` → present; `['Absent','A','absent']` → absent; `['Late','L','late']` → late; `['Leave','leave','On Leave']` → leave |

## 5. User Interface & Layout

### 5.1 Summary Cards (Row of 4)
- **Present Card** — Green (#00b894); icon: check-circle; value: present count; sub-text: "out of X school days"
- **Absent Card** — Red (#d63031); icon: x-circle; value: absent count; sub-text: "days missed this session"
- **Late / Leave Card** — Orange (#e17055); icon: clock; value: late + leave sum; sub-text: "X late · Y on leave"
- **Attendance % Card** — Dynamic colour: ≥75% green, ≥60% orange, <60% red; value: percentage; sub-text: "Good standing" / "Borderline" / "Below minimum (75%)"

### 5.2 Legend + View Toggle
- Colour legend: Present (green), Absent (red), Late (yellow), Leave (blue), No Record (grey)
- Two toggle buttons: Calendar view (default), List view

### 5.3 Month-wise Accordion
- Each month is a collapsible card with header showing: month name, percentage badge, P/A/L/Lv counts
- Latest month opens expanded by default

### 5.4 Calendar View
- 7-column grid (Mon–Sun)
- Colour-coded cells: Present=green, Absent=red, Late=yellow, Leave=blue, Unknown=grey
- Weekend cells rendered light grey; future days rendered faint
- Today highlighted with purple outline ring
- Hover tooltip shows day name, date, status, remarks

### 5.5 List View
- Table columns: Date, Day, Status badge (with icon), Remarks
- Status badges: success (Present), danger (Absent), warning (Late), info (Leave)

## 6. Data Flow & Processing

```
User navigates → GET /student-portal/my-attendance
  ↓
StudentProgressController@attendance()
  ↓
auth()->user()->student → null? → return empty state view
  ↓
$student->currentSession() → null? → return empty with noSession=true
  ↓
StudentAttendance::where('student_id', $student->id)
  ->when(sessionId, ... ->where('academic_session_id', $sessionId))
  ->orderByDesc('attendance_date')
  ->get()
  ↓
Compute $summary (total, present, absent, late, leave, percentage)
Group $records by $byMonth = $records->groupBy(fn($r) => $r->attendance_date->format('F Y'))
  ↓
activityLog() recorded
  ↓
Return view('studentportal::attendance.index', compact(records, summary, byMonth, session))
```

**Status normalization logic (in summary):**
- present count: `whereIn('status', ['Present', 'P', 'present'])`
- absent count: `whereIn('status', ['Absent', 'A', 'absent'])`
- late count: `whereIn('status', ['Late', 'L', 'late'])`
- leave count: `whereIn('status', ['Leave', 'leave', 'On Leave'])`

**Percentage formula:** `round(($summary['present'] / $summary['total']) * 100, 1)`

## 7. Database References

| Table | Model | Purpose |
|-------|-------|---------|
| `std_student_attendance` | `Modules\StudentProfile\Models\StudentAttendance` | Core attendance records |
| `std_students` | `Modules\StudentProfile\Models\Student` | Student profile chain |
| `std_academic_sessions` | Via student->currentSession() | Session scope |
| `sys_users` | Authenticated user | Identity chain |

**Key fields from `std_student_attendance`:**
- `student_id` — FK to student
- `academic_session_id` — FK to academic session
- `attendance_date` — Date of the attendance record
- `status` — Raw status value (variants: Present/P/Absent/A/Late/L/Leave/On Leave)
- `remarks` — Teacher comment
- `attendance_period` — Period number (optional)

## 8. Route Reference

| Route Name | Method | Path | Controller Method |
|------------|--------|------|-------------------|
| `student-portal.my-attendance` | GET | `/student-portal/my-attendance` | `StudentProgressController@attendance` |

## 9. Permissions & Security

| Concern | Status | Notes |
|---------|--------|-------|
| Authentication | ✅ | Route behind `auth` + `verified` middleware |
| Data ownership | ✅ | `auth()->user()->student` ensures own data only |
| No IDOR | ✅ | No parameter-based access — always scoped to authenticated user |
| `Gate::authorize()` | ❌ | Zero authorization gates — acceptable here as data is self-scoped |
| Activity logging | ✅ | Every view logged via `activityLog()` |

## 10. Validation & Error Handling

| Scenario | Handling |
|----------|----------|
| No student profile (user without `student` relation) | Returns empty state: "No active session found" — `$records=collect(), $summary=[]` |
| No current session | Returns `noSession=true` view with "No active session found" |
| No attendance records for session | Returns "No attendance records found for the current session" |
| Unknown status value in DB | Displayed as-is via `ucfirst($rec->status)`; badge renders as secondary/grey |
| Null `attendance_date` | Assumes date object — potential error if null stored |
| Missing `remarks` | Displayed as `—` |

## 11. Edge Cases & Empty States

| Edge Case | Expected Behaviour |
|-----------|--------------------|
| New student with no attendance records | Empty state with calendar icon and message |
| Student enrolled but session has no attendance data | Empty state, summary all zeros, percentage = 0 |
| Month with mixed statuses (Present, Absent, Late) | Calendar cells colour-coded correctly per day |
| Multiple attendance entries on same date | Grouped — latest record overwrites (natural DB order) — needs investigation |
| Student with no `student` relation at all | Empty state with noSession=true |
| Status variants not in the `whereIn` lists (e.g. "Half Day") | Not counted in summary; displayed in list view as-is |
| Current month has no records yet | Calendar grid shows empty/future cells faint |

## 12. Performance Considerations

| Aspect | Analysis |
|--------|----------|
| Query load | Single query on `std_student_attendance` filtered by student + session |
| N+1 risk | None — no eager loading needed for single-table query |
| Pagination | Not paginated — all attendance records loaded at once. Risk for students with years of data (>500 records) |
| View computation | Calendar grid computed in Blade — may be slow for large months |
| Recommendation | Add pagination or lazy-load for months beyond current academic year |

## 13. Dependencies

| Dependency Module | Dependency Type | Entity Consumed |
|-------------------|----------------|-----------------|
| StudentProfile (STD) | Inbound | Student model, StudentAttendance model, AcademicSession |

## 14. FRD Traceability

| FRD ID | Description | Status |
|--------|-------------|--------|
| REQ-STP-007 | Attendance View (P0) — View attendance records for current session | ✅ Implemented |
| BR-STP-001 | Data ownership — student data must belong to authenticated student | ✅ Enforced |
| BR-STP-014 | Attendance scoped to academic session | ✅ Implemented |
| BR-STP-015 | Attendance status normalization | ⚠️ Partially — normalized in summary counts but raw values still displayed in list/calendar view |

## 15. Known Issues / Gaps

| ID | Issue | Severity | Status |
|----|-------|----------|--------|
| GAP-ATT-01 | BR-STP-015 normalization incomplete: raw status values (e.g. "P", "A", "L") still rendered in UI rather than fully normalized display names | Medium | ⬜ |
| GAP-ATT-02 | `Half Day` status not included in any summary count bucket — falls through all `whereIn` filters and is uncounted | Medium | ⬜ |
| GAP-ATT-03 | Attendance data not paginated — all session records loaded at once; may cause slow renders for long academic years | Low | ⬜ |
| GAP-ATT-04 | `attendance_period` conditional column renders only if any record has non-zero value — inconsistent across months | Low | ⬜ |
| GAP-ATT-05 | Calendar grid uses inline style rendering in Blade — no component abstraction; hard to unit test | Low | ⬜ |

## 16. Change Log

| Version | Date | Author | Change Description |
|---------|------|--------|--------------------|
| V1 | — | — | Initial requirement as per input doc |
| V2 | 2026-07-23 | OpenCode | Controller code analysis added; view details documented; known issues identified |

---

*Document generated from controller code analysis, input requirement doc, and FRD cross-reference.*
