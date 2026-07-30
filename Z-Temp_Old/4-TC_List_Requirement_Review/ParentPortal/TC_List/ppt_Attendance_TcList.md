# ppt_Attendance_TcList

## Module: ParentPortal → Attendance

---

## 1. Feature Information

| Item | Details |
|---|---|
| Module | ParentPortal (PPT) |
| Tab Group | Attendance |
| Features | Monthly calendar view (collapsible accordion), Subject-wise breakdown table, AJAX monthly JSON endpoint |
| URL(s) | `GET /parent-portal/attendance/` (index), `GET /parent-portal/attendance/monthly?month=Y-m` (AJAX), `GET /parent-portal/attendance/subject-wise` (subject-wise) |
| Controller | `Modules\ParentPortal\Http\Controllers\ParentAttendanceController` (@index, @monthly, @subjectWise) |
| Service | `Modules\ParentPortal\Services\ParentContextService` |
| Model(s) | `StudentAttendance` (std_attendance) |
| External Tables | `std_attendance`, `sch_academic_sessions` |
| Permission Gates | None — ParentChildPolicy MISSING (P0 gap) |
| Soft Deletes | Not applicable (read-only queries) |
| Events | `activityLog()` on index, monthly, subjectWise |

---

## 2. Pre-conditions

- Authenticated parent session with at least one linked child
- Active child resolved via `ParentContextService::resolveChild()`
- For monthly calendar tests: attendance records in `std_attendance` for the child within the academic session, with various statuses (Present, Absent, Late, Leave)
- For subject-wise tests: attendance records with populated `attendance_period` field
- For AJAX tests: month parameter in `Y-m` format
- For empty-state tests: child with no attendance records or no academic session

---

## 3. Default Data Load

### 3.1 Index / Monthly Calendar

| Data | Source | Query | Pagination |
|---|---|---|---|
| Attendance records | `StudentAttendance::where('student_id', $child->id)->where('academic_session_id', ...)->orderBy('attendance_date')` | Academic session scope | None (full collection) |
| Summary | `buildSummary($records)` — computed inline | Aggregates: total, present, absent, late, leave, percentage | N/A |
| By Month | `$records->groupBy(fn ($r) => $r->attendance_date->format('F Y'))` | Grouped by month name | N/A |

### 3.2 Subject-Wise

| Data | Source | Query | Pagination |
|---|---|---|---|
| All records | Same as index | Academic session scope | None |
| By Period | `$records->filter(fn) ->groupBy('attendance_period')` | Filter non-empty period; group by period string | N/A |
| Period summary | Computed inline | total, present, absent, late, percentage per period | N/A |

### 3.3 Monthly AJAX

| Data | Source | Query | Pagination |
|---|---|---|---|
| Records | `StudentAttendance::where('student_id', ...)->whereBetween('attendance_date', [$start, $end])->orderBy('attendance_date')` | Single month date range | None |
| Summary | `buildSummary($records)` | Same as index | N/A |
| Days | `$records->map(fn ($r) => [date, day, weekday, status, period, remarks])` | Mapped to day array | N/A |

---

## 4. BC-DB — Database Schema

### 4.1 `std_attendance` — Student Attendance Records

| Column | Data Type | Nullable | Default | Notes |
|---|---|---|---|---|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| student_id | INT UNSIGNED | NOT NULL | — | FK → std_students.id |
| academic_session_id | INT UNSIGNED | NOT NULL | — | FK → sch_academic_sessions.id |
| attendance_date | DATE | NOT NULL | — | Date of attendance |
| status | VARCHAR(20) | NOT NULL | — | Present/Absent/Late/Leave/Half-Day/etc. |
| attendance_period | VARCHAR(50) | YES | NULL | Period name (Period 1, Period 2, etc.) |
| remarks | TEXT | YES | NULL | Optional teacher remarks |
| marked_by | INT UNSIGNED | YES | NULL | FK → sys_users.id (teacher who marked) |
| is_active | TINYINT(1) | NOT NULL | 1 | Soft-delete flag |
| created_at | TIMESTAMP | YES | NULL | Creation time |
| updated_at | TIMESTAMP | YES | NULL | Update time |
| deleted_at | TIMESTAMP | YES | NULL | Soft delete |

### 4.2 Fields Used by Attendance Controller

| Field | Usage | Notes |
|---|---|---|
| `student_id` | Primary filter — scoped to resolved active child | FK to std_students |
| `academic_session_id` | Secondary filter — scoped to child's current session | FK to sch_academic_sessions |
| `attendance_date` | Ordering, month grouping, date range filtering | DATE type |
| `status` | Classification: Present/P/present, Absent/A/absent, Late/L/late, Leave/leave/On Leave | Multiple conventions |
| `attendance_period` | Subject-wise grouping (non-null, non-empty) | String-based, not FK |
| `remarks` | Display only in monthly calendar day details | Nullable text |

---

## 5. BC-VAL — Validation Rules

### 5.1 Monthly AJAX Endpoint

| Parameter | Rule | Error Response |
|---|---|---|
| `month` (query) | Optional; default `now()->format('Y-m')`; must be parseable by `Carbon::createFromFormat('Y-m', $monthParam)` | HTTP 422: `{"error": "Invalid month format"}` |

### 5.2 Controller Guards

| Condition | Check | Behaviour |
|---|---|---|
| No `academic_session_id` | `if (! $session?->academic_session_id)` | Returns empty collection + `noSession = true` |
| Invalid month format | `try { Carbon::createFromFormat('Y-m', ...) } catch (\Throwable)` | HTTP 422 JSON error |
| No period data | Filter `$r->attendance_period !== null && $r->attendance_period !== ''` | Empty `byPeriod` collection |

---

## 6. BC-AUTH — Authorization

| Permission Gate | Controller Method | Status | Notes |
|---|---|---|---|
| N/A | index() | NO GATE | Protection via `ParentContextService::resolveChild()` only |
| N/A | monthly() | NO GATE | Same — service-level check only |
| N/A | subjectWise() | NO GATE | Same — service-level check only |

**Key Gap:** No `Gate::authorize()` or `$this->authorize()` in any attendance method.

---

## 7. BC-BIZ — Business Logic

| BC-BIZ ID | Rule | Description |
|---|---|---|
| BC-BIZ-01 | Child Resolution via Context | Every method starts with `$this->context->resolveChild($request)` — ensures data is scoped to authenticated parent's child |
| BC-BIZ-02 | Session Guard | If no `academic_session_id` on child's current session, views render with empty data (`noSession = true`) |
| BC-BIZ-03 | Status Normalisation | `buildSummary()` treats Present/P/present as present; Absent/A/absent as absent; Late/L/late as late; Leave/leave/On Leave as leave |
| BC-BIZ-04 | Month Grouping | Index view groups records by `attendance_date->format('F Y')` — produces "April 2026", "May 2026", etc. |
| BC-BIZ-05 | Period Filtering | Subject-wise filters `attendance_period !== null && attendance_period !== ''` — ignores records without period data |
| BC-BIZ-06 | Period Summary | Each period group computed: total, present, absent, late, percentage = `round(($present / $total) * 100, 1)` |
| BC-BIZ-07 | AJAX Month Parsing | Monthly endpoint uses `Carbon::createFromFormat('Y-m', $monthParam)` — catches exceptions for invalid format |
| BC-BIZ-08 | Academic Session Filter in AJAX | Monthly query includes `when($session?->academic_session_id, ...)` — scopes to session if available |
| BC-BIZ-09 | Activity Logging | All three methods log with student context and route name |
| BC-BIZ-10 | Empty Summary Helper | `emptySummary()` returns `['total'=>0, 'present'=>0, 'absent'=>0, 'late'=>0, 'leave'=>0, 'percentage'=>0]` |
| BC-BIZ-11 | Subject-Wise Sort | Periods sorted by `->sortKeys()->values()` — alphabetical/lexicographic order by period string |

---

## 8. Known Issues

| Issue ID | Description | Severity | Status |
|---|---|---|---|
| KI-PPT-ATT-01 | **No Authorization Policy:** No Gate or Policy exists on attendance controller — relies solely on `ParentContextService`. | P0 (Critical) | ⬜ Not Started |
| KI-PPT-ATT-02 | **Status Values Hardcoded:** `buildSummary()` uses inline arrays `['Present', 'P', 'present']` — not referenced from a config or enum. If Attendance module adds new status conventions, they won't be counted. | P2 (Low) | ⬜ Not Started |
| KI-PPT-ATT-03 | **Period Grouping is Case-Sensitive:** Subject-wise groups by `attendance_period` as a raw string — "Period 1" and "period 1" create separate groups. | P2 (Low) | ⬜ Not Started |
| KI-PPT-ATT-04 | **No Attendance Caching:** All queries hit the database on every page load. A full-year attendance with 200+ records loads quickly but is unoptimised. | P3 (Enhancement) | ⬜ Not Started |
| KI-PPT-ATT-05 | **No Absence Alert Integration:** Controller reads attendance data but does not trigger absence notifications (FRD requirement). | P1 (Medium) | ⬜ Not Started |

---

## 9. Route Reference

| Method | URI | Name | Controller@Method | Middleware |
|---|---|---|---|---|
| GET | `/parent-portal/attendance/` | `parent-portal.attendance.index` | `ParentAttendanceController@index` | web, tenant, auth, verified, ParentPortal |
| GET | `/parent-portal/attendance/monthly` | `parent-portal.attendance.monthly` | `ParentAttendanceController@monthly` | web, tenant, auth, verified, ParentPortal |
| GET | `/parent-portal/attendance/subject-wise` | `parent-portal.attendance.subject-wise` | `ParentAttendanceController@subjectWise` | web, tenant, auth, verified, ParentPortal |

Route prefix: `attendance` (grouped under `/parent-portal/attendance/`)
Name prefix: `parent-portal.attendance.`

---

## 10. Execution Status

| Item | Status | Notes |
|---|---|---|
| Controller Implementation | ✅ Complete | All 3 methods implemented: index (60 lines), monthly (53 lines), subjectWise (52 lines) |
| Views | ✅ Complete | `parentportal::attendance.index`, `parentportal::attendance.subject-wise` exist |
| FormRequest | ❌ Not Used | No FormRequest — AJAX validation inline in controller |
| Service Layer | ✅ Complete | ParentContextService fully integrated |
| Route Registration | ✅ Complete | All 3 routes registered with prefix and name prefix |
| Activity Logging | ✅ Complete | All three methods log with student context |
| Authorization Policy | ❌ **MISSING (P0)** | No Gate or Policy — service-layer check only |
| Caching | ❌ Not Implemented | Full DB query on every load |
| Pest Tests | ❌ Not Written | No test coverage for attendance |
| Colour-Coding (View) | ⬜ Partial | Backend passes status data; colour-coding is view-layer responsibility |

---

## 11. Test Case Summary

### 11.1 Attendance — Positive TCs

| TC ID | Feature | Type | Description | Steps |
|---|---|---|---|---|
| TC-PPT-ATT-P01 | Monthly Calendar | Positive | Attendance index loads with monthly accordion | 5 |
| TC-PPT-ATT-P02 | Monthly Calendar | Positive | Summary bar shows correct counts and percentage | 5 |
| TC-PPT-ATT-P03 | Monthly Calendar | Positive | Attendance records ordered by date ascending within each month | 4 |
| TC-PPT-ATT-P04 | Monthly Calendar | Positive | Multiple months displayed as separate accordion panels | 4 |
| TC-PPT-ATT-P05 | Monthly Calendar | Positive | Present status recognised (Present, P, present) | 4 |
| TC-PPT-ATT-P06 | Monthly Calendar | Positive | Absent status recognised (Absent, A, absent) | 4 |
| TC-PPT-ATT-P07 | Monthly Calendar | Positive | Late status recognised (Late, L, late) | 4 |
| TC-PPT-ATT-P08 | Monthly Calendar | Positive | Leave status recognised (Leave, leave, On Leave) | 4 |
| TC-PPT-ATT-P09 | Monthly Calendar | Positive | Activity log created on attendance view | 3 |

### 11.2 Attendance — Negative TCs

| TC ID | Feature | Type | Description | Steps |
|---|---|---|---|---|
| TC-PPT-ATT-N01 | Monthly Calendar | Negative | No academic session — empty attendance with noSession flag | 3 |
| TC-PPT-ATT-N02 | Monthly Calendar | Negative | No attendance records — empty month panels | 3 |
| TC-PPT-ATT-N03 | Monthly Calendar | Negative | Unknown status value (e.g., "HalfDay") — not counted in any category | 3 |

### 11.3 Monthly AJAX — Positive TCs

| TC ID | Feature | Type | Description | Steps |
|---|---|---|---|---|
| TC-PPT-ATT-AJAX-P01 | Monthly AJAX | Positive | Valid month parameter returns JSON with month, summary, days | 5 |
| TC-PPT-ATT-AJAX-P02 | Monthly AJAX | Positive | Default month (current) used when month param not provided | 4 |
| TC-PPT-ATT-AJAX-P03 | Monthly AJAX | Positive | Summary matches expected counts for the month | 4 |
| TC-PPT-ATT-AJAX-P04 | Monthly AJAX | Positive | Days array has correct structure: date, day, weekday, status, period, remarks | 4 |
| TC-PPT-ATT-AJAX-P05 | Monthly AJAX | Positive | Activity log created with month parameter | 3 |
| TC-PPT-ATT-AJAX-P06 | Monthly AJAX | Positive | Empty month returns empty days array and zero summary | 3 |

### 11.4 Monthly AJAX — Negative TCs

| TC ID | Feature | Type | Description | Steps |
|---|---|---|---|---|
| TC-PPT-ATT-AJAX-N01 | Monthly AJAX | Negative | Invalid month format (e.g., "abc") returns 422 error | 2 |
| TC-PPT-ATT-AJAX-N02 | Monthly AJAX | Negative | Partial month format (e.g., "2026") returns 422 | 2 |
| TC-PPT-ATT-AJAX-N03 | Monthly AJAX | Negative | Future month with no data returns empty days array | 3 |

### 11.5 Subject-Wise — Positive TCs

| TC ID | Feature | Type | Description | Steps |
|---|---|---|---|---|
| TC-PPT-ATT-SUBJ-P01 | Subject-Wise | Positive | Subject-wise page loads with period rows | 5 |
| TC-PPT-ATT-SUBJ-P02 | Subject-Wise | Positive | Each period shows total, present, absent, late, percentage | 4 |
| TC-PPT-ATT-SUBJ-P03 | Subject-Wise | Positive | Periods sorted alphabetically by key | 3 |
| TC-PPT-ATT-SUBJ-P04 | Subject-Wise | Positive | Multiple records in same period aggregated correctly | 5 |
| TC-PPT-ATT-SUBJ-P05 | Subject-Wise | Positive | Summary bar matches overall attendance (same as index) | 4 |
| TC-PPT-ATT-SUBJ-P06 | Subject-Wise | Positive | Activity log created on subject-wise view | 3 |

### 11.6 Subject-Wise — Negative TCs

| TC ID | Feature | Type | Description | Steps |
|---|---|---|---|---|
| TC-PPT-ATT-SUBJ-N01 | Subject-Wise | Negative | No period data (all attendance_period null) — empty period list | 3 |
| TC-PPT-ATT-SUBJ-N02 | Subject-Wise | Negative | No academic session — empty data with summary = 0 | 3 |
| TC-PPT-ATT-SUBJ-N03 | Subject-Wise | Negative | Mixed case period strings ("Period 1" vs "period 1") — separate groups (case-sensitivity) | 4 |

### 11.7 Code Review TCs

| TC ID | Feature | Type | Description | Steps |
|---|---|---|---|---|
| TC-CR-ATT-01 | Code Review | Review | index() — child resolution + session guard | 4 |
| TC-CR-ATT-02 | Code Review | Review | index() — full record fetch + month grouping logic | 4 |
| TC-CR-ATT-03 | Code Review | Review | monthly() — Carbon month parsing with try/catch | 5 |
| TC-CR-ATT-04 | Code Review | Review | monthly() — date range query with whereBetween | 4 |
| TC-CR-ATT-05 | Code Review | Review | monthly() — JSON response structure | 4 |
| TC-CR-ATT-06 | Code Review | Review | subjectWise() — period filter and groupBy logic | 5 |
| TC-CR-ATT-07 | Code Review | Review | subjectWise() — per-period summary computation | 5 |
| TC-CR-ATT-08 | Code Review | Review | buildSummary() — status normalisation arrays | 4 |
| TC-CR-ATT-09 | Code Review | Review | emptySummary() — zero-value defaults | 2 |
| TC-CR-ATT-10 | Code Review | Review | Activity logging consistency across all 3 methods | 4 |

---

## 12. Test Case Steps

### 12.1 Monthly Calendar Positive Steps

#### TC-PPT-ATT-P01: Attendance index loads with monthly accordion

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Log in as parent with linked child having attendance records across 3 months | Authenticated |
| 2 | Navigate to `GET /parent-portal/attendance/` | Attendance page loads |
| 3 | Verify 3 accordion panels visible (one per month with records) | Months displayed |
| 4 | Verify each panel shows colour-coded day cells | Daily status visible |
| 5 | Verify no JavaScript errors | Clean render |

#### TC-PPT-ATT-P02: Summary bar correct

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create 10 Present, 2 Absent, 1 Late, 1 Leave records for child | 14 total records |
| 2 | Load attendance page | Page loads |
| 3 | Verify summary shows: total=14, present=10, absent=2, late=1, leave=1 | Counts correct |
| 4 | Verify percentage = round(10/14 * 100) = 71.4 | 71.4% |
| 5 | Verify summary displayed on page (view responsibility) | Summary visible |

#### TC-PPT-ATT-P03: Records ordered by date ascending

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create attendance records on June 5, June 3, June 10, June 1 | 4 records |
| 2 | Load attendance page | Records displayed |
| 3 | Verify records in month accordion ordered: June 1, June 3, June 5, June 10 | Ascending order |
| 4 | Verify underlying collection is ordered by `attendance_date` | DB order confirmed |

#### TC-PPT-ATT-P04: Multiple months displayed

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create attendance records in April, May, June 2026 | 3 months |
| 2 | Load attendance page | Page loads |
| 3 | Verify 3 accordion panels: "April 2026", "May 2026", "June 2026" | All months present |
| 4 | Verify each panel contains only its own month's records | Correct grouping |

#### TC-PPT-ATT-P05–P08: Status recognition (4 conventions)

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create records with status='Present', 'P', 'present' | 3 conventions |
| 2 | Load attendance page | Page loads |
| 3 | Verify all 3 counted in `$summary['present']` | All treated as present |
| 4 | Repeat for Absent/A/absent, Late/L/late, Leave/leave/On Leave | All conventions accepted |

#### TC-PPT-ATT-P09: Activity log

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Load attendance page | Page renders |
| 2 | Query activity log for 'Viewed attendance' | Log entry exists |
| 3 | Verify log contains student context and route='parent-portal.attendance.index' | Context logged |

### 12.2 Monthly Calendar Negative Steps

#### TC-PPT-ATT-N01: No academic session

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Ensure child's currentSession has null academic_session_id | No session |
| 2 | Navigate to attendance | Page loads without error |
| 3 | Verify noSession flag set and empty data displayed | Graceful empty state |

#### TC-PPT-ATT-N02: No attendance records

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Ensure child has zero attendance records in current session | No data |
| 2 | Navigate to attendance | Page loads |
| 3 | Verify empty month panels with "No attendance records" message | Graceful empty state |

#### TC-PPT-ATT-N03: Unknown status value

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create record with status='HalfDay' (not in any normalisation array) | Unknown status |
| 2 | Load attendance | Page loads |
| 3 | Verify record displayed but not counted in present/absent/late/leave totals | Not miscategorised |

### 12.3 Monthly AJAX Positive Steps

#### TC-PPT-ATT-AJAX-P01: Valid month returns JSON

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create 5 Present records in June 2026 for the child | 5 records |
| 2 | GET `/parent-portal/attendance/monthly?month=2026-06` | AJAX request |
| 3 | Verify JSON response has `month = "June 2026"` | Month correct |
| 4 | Verify JSON has `summary` object with total=5, present=5, percentage=100 | Summary correct |
| 5 | Verify JSON has `days` array with 5 entries, each with date, day, weekday, status, period, remarks | Days correct |

#### TC-PPT-ATT-AJAX-P02: Default month when no param

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create records in current month | Data exists |
| 2 | GET `/parent-portal/attendance/monthly` (no month param) | AJAX request |
| 3 | Verify response shows current month's data (default = now()->format('Y-m')) | Default applied |

#### TC-PPT-ATT-AJAX-P06: Empty month

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Ensure no records in February 2025 for the child | No data |
| 2 | GET `/parent-portal/attendance/monthly?month=2025-02` | AJAX request |
| 3 | Verify `days` array is empty and `summary` shows all zeros | Empty data handled |

### 12.4 Monthly AJAX Negative Steps

#### TC-PPT-ATT-AJAX-N01: Invalid month format

| Step # | Action | Expected Result |
|---|---|---|
| 1 | GET `/parent-portal/attendance/monthly?month=abc` | Invalid format |
| 2 | Verify HTTP 422 response | Error returned |
| 3 | Verify `{"error": "Invalid month format"}` | Error message correct |

#### TC-PPT-ATT-AJAX-N02: Partial month format

| Step # | Action | Expected Result |
|---|---|---|
| 1 | GET `/parent-portal/attendance/monthly?month=2026` (missing month part) | Invalid format |
| 2 | Verify HTTP 422 response | Error returned |

#### TC-PPT-ATT-AJAX-N03: Future month with no data

| Step # | Action | Expected Result |
|---|---|---|
| 1 | GET `/parent-portal/attendance/monthly?month=2030-12` | Valid format, future date |
| 2 | Verify HTTP 200 with empty days array and zero summary | Graceful |

### 12.5 Subject-Wise Positive Steps

#### TC-PPT-ATT-SUBJ-P01: Subject-wise loads with period rows

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create attendance records with attendance_period = 'Period 1', 'Period 2', 'Period 3' | 3 periods |
| 2 | Navigate to `/parent-portal/attendance/subject-wise` | Page loads |
| 3 | Verify 3 period rows displayed | All periods shown |
| 4 | Verify rows ordered alphabetically by period name | Sorted |
| 5 | Verify each row shows total, present, absent, late, percentage | All columns present |

#### TC-PPT-ATT-SUBJ-P02: Period summary computation

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create records for 'Period 1': 8 Present, 2 Absent | 10 total |
| 2 | Navigate to subject-wise | Page loads |
| 3 | Verify Period 1 row: total=10, present=8, absent=2, late=0, percentage=80.0 | Correct calculation |
| 4 | Verify percentage uses `round(($present / $total) * 100, 1)` | 80.0% |

#### TC-PPT-ATT-SUBJ-P06: Activity log

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Navigate to subject-wise | Page loads |
| 2 | Query activity log for 'Viewed subject-wise attendance' | Log entry exists |
| 3 | Verify student context logged | Context recorded |

### 12.6 Subject-Wise Negative Steps

#### TC-PPT-ATT-SUBJ-N01: No period data

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create attendance records with attendance_period = NULL for all records | No period data |
| 2 | Navigate to subject-wise | Page loads |
| 3 | Verify `byPeriod` collection is empty | Graceful empty state |

#### TC-PPT-ATT-SUBJ-N03: Mixed case period strings

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create records with attendance_period = 'Period 1' and 'period 1' | Case difference |
| 2 | Navigate to subject-wise | Page loads |
| 3 | Verify TWO separate rows for "Period 1" and "period 1" | Case-sensitive grouping |

### 12.7 Code Review Steps

#### TC-CR-ATT-01: index() — child resolution + session guard

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Review `$this->context->resolveChild($request)` at top | Child resolved |
| 2 | Review `$session?->academic_session_id` guard for empty data | Session check |
| 3 | Review `noSession => true` passed to view on empty session | View flag |
| 4 | Review activityLog call at end | Logged |

#### TC-CR-ATT-03: monthly() — Carbon month parsing with try/catch

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Review `\Carbon\Carbon::createFromFormat('Y-m', $monthParam)` | Parse month |
| 2 | Review try/catch `catch (\Throwable)` block | Exception caught |
| 3 | Review `return response()->json(['error' => 'Invalid month format'], 422)` | Error response |
| 4 | Review `$start->copy()->endOfMonth()` for range | End of month computed |
| 5 | Review `whereBetween('attendance_date', [$start, $end])` query | Date range filter |

#### TC-CR-ATT-08: buildSummary() — status normalisation

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Review `$records->whereIn('status', ['Present', 'P', 'present'])` for present | Present statuses |
| 2 | Review `$records->whereIn('status', ['Absent', 'A', 'absent'])` for absent | Absent statuses |
| 3 | Review `$records->whereIn('status', ['Late', 'L', 'late'])` for late | Late statuses |
| 4 | Review `$records->whereIn('status', ['Leave', 'leave', 'On Leave'])` for leave | Leave statuses |
