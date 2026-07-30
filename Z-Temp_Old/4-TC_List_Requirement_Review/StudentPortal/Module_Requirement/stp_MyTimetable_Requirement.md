# stp_MyTimetable — Requirement Document

## 1. Module Information

| Field | Value |
|-------|-------|
| Module Code | STP |
| Module Name | StudentPortal |
| Feature Name | My Timetable |
| Table Prefix | stp_ (consumes `tmt_timetable_cells`, `tmt_school_days`) |
| DB Layer | Tenant (`tenant_{uuid}`) |
| Route Name | `student-portal.my-timetable` |
| HTTP Method + Path | GET `/student-portal/my-timetable` |
| Controller | `StudentTimetableController@index` |
| View | `studentportal::timetable.index` |
| Input Doc | `pgdatabase/Backup/4-Module_Requirement/StudentPortal/academics/my_timetable.md` |
| FRD Reference | REQ-STP-008, BR-STP-011, BR-STP-012, BR-STP-013 |

## 2. Feature Overview

Renders a weekly timetable matrix for the student's class and section from published/active timetable cells (`tmt_timetable_cells`). Displays a day–period grid with subject names, study format, teachers, room locations, and break period highlighting. Includes a weekly summary strip, per-day period count, subject legend, and a "Today's Schedule" table.

## 3. Functional Requirements

| ID | Requirement | Status |
|----|-------------|--------|
| F1 | Load timetable cells for the student's class and section from active/published timetables | ✅ |
| F2 | Order school days (Mon–Sat) excluding non-school days | ✅ |
| F3 | Build a grid: [day_of_week][period_ord] → TimetableCell | ✅ |
| F4 | Exclude `is_break` cells from subject display; render them as break slots | ✅ |
| F5 | Exclude `is_free` cells from subject display; render them as free periods | ✅ |
| F6 | Show weekly summary strip with per-day period count and subject count | ✅ |
| F7 | Display period column headers with name, time range, duration | ✅ |
| F8 | Each subject cell: coloured background, subject name, study format badge, teacher name(s), room | ✅ |
| F9 | Highlight today's column and row with purple accent | ✅ |
| F10 | Render conflict badge for cells with `has_conflict=true` | ✅ |
| F11 | Render lock icon for cells with `is_locked=true` | ✅ |
| F12 | Subject legend below grid showing all subjects with colour dots and weekly frequency | ✅ |
| F13 | Today's Schedule table: filtered non-break cells for today, with period/time/subject/format/teacher/room | ✅ |
| F14 | Record activity log on page view | ✅ |
| F15 | Show empty/no-session state when student, class, or timetable data missing | ✅ |

## 4. Business Rules

| Rule ID | Rule Description | Enforcement |
|---------|-----------------|-------------|
| BR-STP-001 | Data must belong to the authenticated student | Controller enforces via `auth()->user()->student` |
| BR-STP-011 | Timetable must be in ACTIVE, GENERATED, or PUBLISHED status | `whereIn('status', ['ACTIVE', 'GENERATED', 'PUBLISHED'])` |
| BR-STP-012 | Attendance system days = Mon–Sat, Sun excluded | `SchoolDay::where('is_school_day', true)->where('is_active', true)` |
| BR-STP-013 | Break cells excluded from subject rendering | `is_break` flag on cell; view checks `$isBreakPrd` and renders break slot |

## 5. User Interface & Layout

### 5.1 Page Header
- Breadcrumb: Home > My Timetable
- Title: "My Timetable"

### 5.2 Info Strip
- Student name, Class + Section, Roll number
- Today's date

### 5.3 Weekly Summary Cards
- One card per school day (Mon–Sat)
- Day name, period count (large number), subject count
- Today's card: purple top border + shadow; "(Today)" label

### 5.4 Main Timetable Grid
- **HTML table** with horizontal scroll for narrow screens
- **Top header row:** Period name/order + time range + duration
- **Rows:** One per school day, with day label on left

**Cell types:**
| Condition | Rendering |
|-----------|-----------|
| Break period (code=SBREAK/LUNCH/BREAK) | Grey (#f1f3f5) background, emoji (🍽/☕), break name, duration |
| Free cell (no cell or `is_free=true`) | White background, "—" |
| Subject cell | Colour-coded bg (from palette cycling by subject_id) |
| Today highlight | Row: `today-bg` class; Column: `today-col` header; Day cell: `today-row` |

**Subject cell content:**
- Subject name (bold, white text on coloured bg)
- Study format badge (e.g. "Theory", "Practical")
- Teacher name(s) with user icon
- Room name with room type
- Conflict badge (red, top-right) if `has_conflict`
- Lock icon (bottom-right) if `is_locked`

### 5.5 Subject Legend
- Card below grid showing each subject's colour swatch, name, code, and count per week

### 5.6 Today's Schedule Table
- Card with purple left border
- Columns: Period, Time, Subject (coloured), Format, Teacher, Room
- Only non-break, non-free cells for current day

## 6. Data Flow & Processing

```
User navigates → GET /student-portal/my-timetable
  ↓
StudentTimetableController@index()
  ↓
auth()->user()->student → null? → return empty with noSession=true
  ↓
currentSession() → null or no classSection? → return empty with noSession=true
  ↓
$classId = $session->classSection->class_id
$sectionId = $session->classSection->section_id
  ↓
TimetableCell::whereHas('activity', fn: class_id + section_id)
  ->whereHas('timetable', fn: status IN ['ACTIVE','GENERATED','PUBLISHED'])
  ->with(['activity.subject', 'activity.studyFormat', 'activity.subjectType',
          'activity.teachers.teacher.user', 'teachers.user', 'period', 'day', 'room.roomType'])
  ->orderBy('day_of_week')->orderBy('period_ord')
  ->get()
  ↓
$days = SchoolDay::where('is_school_day',true)->where('is_active',true)->orderBy('ordinal')
$periods = $cells->pluck('period')->filter()->unique('period_ord')->sortBy('period_ord')
$grid = []; foreach cells: $grid[$cell->day_of_week][$cell->period_ord] = $cell
  ↓
activityLog()
  ↓
Return view('studentportal::timetable.index', compact('session','days','periods','grid','cells'))
```

## 7. Database References

| Table | Model | Purpose |
|-------|-------|---------|
| `tmt_timetable_cells` | `Modules\TimetableFoundation\Models\TimetableCell` | Core timetable cell data |
| `tmt_school_days` | `Modules\TimetableFoundation\Models\SchoolDay` | School day definitions |
| `tmt_periods` | Via `->period` relation | Period timing and order |
| `sch_subjects` | Via `->activity->subject` | Subject details |
| `tmt_activity_teachers` | Via `->activity->teachers` | Teacher assignment junction |
| `tmt_rooms` | Via `->room` | Room/location details |
| `tmt_study_formats` | Via `->activity->studyFormat` | Format type (Theory/Practical) |
| `std_student_sessions` | Via `currentSession()` | Enrolment class/section |

## 8. Route Reference

| Route Name | Method | Path | Controller Method |
|------------|--------|------|-------------------|
| `student-portal.my-timetable` | GET | `/student-portal/my-timetable` | `StudentTimetableController@index` |

## 9. Permissions & Security

| Concern | Status | Notes |
|---------|--------|-------|
| Authentication | ✅ | Route behind `auth` + `verified` middleware |
| Data ownership | ✅ | Scoped to authenticated student's class/section |
| IDOR risk | ✅ | No parameter-based access |
| Activity logging | ✅ | Every view logged |
| `Gate::authorize()` | ❌ | Zero authorization gates — acceptable as data is self-scoped |

## 10. Validation & Error Handling

| Scenario | Handling |
|----------|----------|
| No student profile | Empty state: "You are not enrolled in any class for the current session" |
| No class section | Empty state with `noSession=true` |
| No timetable cells published | Empty state: "Timetable Not Published — Your class timetable has not been published yet" |
| No school days configured | Empty grid; "No school days configured" message implicitly through empty days collection |
| Cell without subject | Falls back to activity name or "Activity" |
| Cell without teacher(s) | Teacher field omitted or shows empty |
| Break period without duration | Duration hidden |
| Inconsistent period order | Sorted by `period_ord` |

## 11. Edge Cases & Empty States

| Edge Case | Expected Behaviour |
|-----------|--------------------|
| No timetable published for class | Empty state: "Timetable Not Published" |
| Saturday is a school day | Included in grid; shown in day header |
| Single-day school week | Grid renders with one row |
| Student has no class assigned | Empty state: "No Timetable Available" |
| Cell with both subject and break flag | `is_break` takes precedence — rendered as break |
| Subject taught by multiple teachers | All teacher names comma-separated in cell |
| Room with no type name | Room type omitted from display |
| Period with no start/end time | Time column in header shows empty |
| Past timetable status (DRAFT) | Excluded by `whereIn` status filter |

## 12. Performance Considerations

| Aspect | Analysis |
|--------|----------|
| Query load | Single query on `tmt_timetable_cells` with 6 eager-loaded relationships |
| N+1 risk | None — all relations eagerly loaded |
| Grid building | O(n) loop over cells; fine for typical 30–50 cell weekly timetable |
| Subject colour function | Uses modulo on subject_id — deterministic and fast |
| Today's Schedule filter | Collection filter — minimal overhead |

## 13. Dependencies

| Dependency Module | Entity Consumed |
|-------------------|-----------------|
| TimetableFoundation | TimetableCell, SchoolDay, Period, Room, StudyFormat |
| StudentProfile (STD) | Student, AcademicSession, ClassSection |

## 14. FRD Traceability

| FRD ID | Description | Status |
|--------|-------------|--------|
| REQ-STP-008 | Timetable View (P0) — Weekly day×period grid | ✅ Implemented |
| BR-STP-011 | Timetable must be ACTIVE/GENERATED/PUBLISHED | ✅ Enforced |
| BR-STP-012 | School days Mon–Sat, Sun excluded | ✅ Enforced |
| BR-STP-013 | Break cells excluded from subject display | ✅ Enforced |

## 15. Known Issues / Gaps

| ID | Issue | Severity | Status |
|----|-------|----------|--------|
| GAP-TT-01 | No session-based filtering — timetable cells not explicitly filtered by `academic_session_id`; relies on timetable status only | Low | ⬜ |
| GAP-TT-02 | Break period detection uses hardcoded codes `['SBREAK','LUNCH','BREAK']` — not configurable | Medium | ⬜ |
| GAP-TT-03 | `has_conflict` and `is_locked` badges rendered via Blade but data may not be populated from all timetable engines | Low | ⬜ |
| GAP-TT-04 | No week selector — only current week's timetable shown; no way to browse past/future weeks | Low | ⬜ |
| GAP-TT-05 | No teacher hyperlink in grid cells — teacher names are plain text, not linked to teacher profile | Low | ⬜ |

## 16. Change Log

| Version | Date | Author | Change Description |
|---------|------|--------|--------------------|
| V1 | — | — | Initial requirement as per input doc |
| V2 | 2026-07-23 | OpenCode | Controller code analysis added; grid-building logic documented; break/free cell handling detailed |

---

*Document generated from controller code analysis, input requirement doc, and FRD cross-reference.*
