# stp_MyTeachers — Requirement Document

## 1. Module Information

| Field | Value |
|-------|-------|
| Module Code | STP |
| Module Name | StudentPortal |
| Feature Name | My Teachers |
| Table Prefix | stp_ (consumes `tmt_timetable_cells`) |
| DB Layer | Tenant (`tenant_{uuid}`) |
| Route Name | `student-portal.my-teachers` |
| HTTP Method + Path | GET `/student-portal/my-teachers` |
| Controller | `StudentTeachersController@index` |
| View | `studentportal::teachers.index` |
| Input Doc | `pgdatabase/Backup/4-Module_Requirement/StudentPortal/academics/my_teachers.md` |
| FRD Reference | REQ-STP-014, BR-STP-001 |

## 2. Feature Overview

Lists all teachers assigned to the student's class and section by analysing published timetable cells. Each teacher is shown with subjects they teach (to this class), active days, and contact email. Includes a weekly schedule matrix showing which periods each teacher covers each day, and a chat button for direct messaging.

## 3. Functional Requirements

| ID | Requirement | Status |
|----|-------------|--------|
| F1 | Load timetable cells for the student's class/section from published timetables | ✅ |
| F2 | Extract unique teachers from timetable cell activity teacher assignments | ✅ |
| F3 | Group teachers and map each to subjects taught (unique subject list) | ✅ |
| F4 | Map each teacher to active days (day_of_week codes where they appear) | ✅ |
| F5 | Display stat cards: Total Teachers, Subjects, School Days/Week, Class name | ✅ |
| F6 | Render teacher profile cards with initials avatar, name, subjects, active days, email, chat button | ✅ |
| F7 | Teacher Schedule weekly matrix table: Teacher × Day → period labels | ✅ |
| F8 | Chat button triggers in-page DM widget or redirects to chat page | ✅ |
| F9 | Record activity log on page view | ✅ |
| F10 | Show empty/no-session state when student, class, or timetable data missing | ✅ |

## 4. Business Rules

| Rule ID | Rule Description | Enforcement |
|---------|-----------------|-------------|
| BR-STP-001 | Data must belong to the authenticated student | Controller enforces via `auth()->user()->student` |
| BR-TCH-01 | Only teachers from published/active timetables included | `whereIn('status', ['ACTIVE', 'GENERATED', 'PUBLISHED'])` |
| BR-TCH-02 | Only teachers assigned to this class+section via timetable cells | `where('class_id', $classId)->where('section_id', $sectionId)` |
| BR-TCH-03 | Same teacher assigned to multiple subjects shows all subjects | `unique('id')` on subject collection per teacher |
| BR-TCH-04 | Day numbering: SchoolDay.id = Mon=1…Sat=6 | `$dayNames = [1 => 'Mon', 2 => 'Tue', …]` mapping |

## 5. User Interface & Layout

### 5.1 Page Header
- Breadcrumb: Home > My Teachers
- Title: "My Teachers"

### 5.2 Stat Cards (Row of 4)
- **Total Teachers** — Blue (#0984e3), users icon, count + "Teaching your class"
- **Subjects** — Green (#00b894), book-open icon, unique subject count + "Unique subjects covered"
- **School Days / Week** — Orange (#e17055), calendar icon, number of active timetable days
- **Your Class** — Purple (#6c5ce7), award icon, class name + section + "Current enrollment"

### 5.3 Teacher Cards (3-column grid)
- Colour accent bar on top (colour cycles from 6-colour palette)
- Initials avatar on coloured circle background
- Teacher name (bold)
- Subjects taught (coloured text)
- Active days (with calendar-check icon)
- Email link (if available)
- Chat button (round with comment icon)

### 5.4 Teacher Schedule Matrix
- Card titled "Teacher Schedule This Week"
- Table with columns: Teacher, Subjects, Mon—Tue—Wed—Thu—Fri—Sat
- Each cell shows period labels (e.g. "P1, P3, P5") or "—" if no class on that day

## 6. Data Flow & Processing

```
User navigates → GET /student-portal/my-teachers
  ↓
StudentTeachersController@index()
  ↓
auth()->user()->student → null? → return empty state
  ↓
currentSession() with classSection → null? → return empty
  ↓
$classId, $sectionId from session
  ↓
TimetableCell::whereHas('activity', fn: class_id + section_id)
  ->whereHas('timetable', fn: status IN ACTIVE/GENERATED/PUBLISHED)
  ->with(['activity.subject', 'activity.teachers.teacher.user', 'period'])
  ->orderBy('day_of_week')->orderBy('period_ord')
  ->get()
  ↓
$teachers = $cells
  ->flatMap(fn: $cell->activity->teachers)        // all activity-teacher joins
  ->filter(fn: teacher !== null)
  ->groupBy('teacher_id')
  ->map(function: for each teacher group:
      $subjects = cells where teacher appears → pluck subject → unique
      $days = cells where teacher appears → pluck day_of_week → unique → sort
      $teacher->setAttribute('class_subjects', $subjects)
      $teacher->setAttribute('active_days', $days)
  )
  ↓
$schedule = []; foreach cells:
  $schedule[$teacher->id][$day_of_week][] = period label
  ↓
activityLog()
  ↓
Return view('studentportal::teachers.index', compact('teachers', 'schedule', 'dayNames', 'session'))
```

## 7. Database References

| Table | Model | Purpose |
|-------|-------|---------|
| `tmt_timetable_cells` | `TimetableCell` | Core timetable cells for activity→teacher links |
| `tmt_activities` | Via `->activity` | Activity record linking subjects and teachers |
| `tmt_timetables` | Via `->timetable` | Timetable status filter |
| `sch_subjects` | Via `->activity->subject` | Subject details |
| `tmt_activity_teachers` | Via `->activity->teachers` | Many-to-many teacher assignment |
| `hrm_teachers` | Via `->activity->teachers->teacher` | Teacher profile |
| `sys_users` | Via `->activity->teachers->teacher->user` | User name, email |
| `std_student_sessions` | Via `currentSession()` | Enrolment class/section |

## 8. Route Reference

| Route Name | Method | Path | Controller Method |
|------------|--------|------|-------------------|
| `student-portal.my-teachers` | GET | `/student-portal/my-teachers` | `StudentTeachersController@index` |

## 9. Permissions & Security

| Concern | Status | Notes |
|---------|--------|-------|
| Authentication | ✅ | Route behind `auth` + `verified` middleware |
| Data ownership | ✅ | Scoped to authenticated student's class/section |
| IDOR risk | ✅ | No parameter-based access |
| Activity logging | ✅ | Every view logged |

## 10. Validation & Error Handling

| Scenario | Handling |
|----------|----------|
| No student profile | Empty state: "No active session found. Teachers will appear once you are enrolled in a class." |
| No class section | Empty state with `noSession=true` |
| No teachers found | Empty state: "No teachers found for your class in the active timetable." |
| Teacher without user relation | Name falls back to 'Unknown' |
| Teacher without email | Email link hidden |
| No subjects for teacher | Subjects shown as "—" |
| No active days for teacher | Days shown as "—" |

## 11. Edge Cases & Empty States

| Edge Case | Expected Behaviour |
|-----------|--------------------|
| No timetable published for class | Empty state: "No teachers found for your class" |
| Teacher teaches multiple subjects | All subjects listed, comma-separated |
| Teacher teaches same subject across multiple days | Days listed as "Mon, Wed, Fri" |
| Subject taught by multiple teachers | Both teachers listed in separate cards |
| Teacher active every day (Mon–Sat) | All 6 days listed in active_days |
| Chat widget not loaded | Fallback redirect to chat page |
| Teacher with no profile picture | Initials avatar generated from first letter of name |

## 12. Performance Considerations

| Aspect | Analysis |
|--------|----------|
| Query load | Single query on TimetableCell with 3 eager-loaded chains |
| In-memory processing | `flatMap` + `groupBy` on collection — fast for typical 30–50 cells |
| N+1 risk | None — all relations eagerly loaded |
| Schedule matrix building | Nested loops over cells and activity teachers — fine for <20 teachers |

## 13. Dependencies

| Dependency Module | Entity Consumed |
|-------------------|-----------------|
| TimetableFoundation | TimetableCell, Activity, ActivityTeacher |
| StudentProfile (STD) | Student, AcademicSession, ClassSection |
| HRM (hrm_teachers) | Teacher model linked to user |

## 14. FRD Traceability

| FRD ID | Description | Status |
|--------|-------------|--------|
| REQ-STP-014 | My Teachers (P1) — List teachers for student's class/subjects | ✅ Implemented |
| BR-STP-001 | Data ownership — student data must belong to authenticated student | ✅ Enforced |

## 15. Known Issues / Gaps

| ID | Issue | Severity | Status |
|----|-------|----------|--------|
| GAP-TCH-01 | Teachers sourced from TimetableCell only — class/subject teachers not assigned to any cell are excluded | Medium | ⬜ |
| GAP-TCH-02 | No teacher profile picture rendered — always shows initials avatar | Low | ⬜ |
| GAP-TCH-03 | CHAT button is hard-coupled to `window.studentChatApi` — no graceful degradation if chat not loaded | Medium | ⬜ |
| GAP-TCH-04 | No contact phone number displayed — only email shown | Low | ⬜ |
| GAP-TCH-05 | No teacher specialisation/qualification info displayed | Low | ⬜ |

## 16. Change Log

| Version | Date | Author | Change Description |
|---------|------|--------|--------------------|
| V1 | — | — | Initial requirement as per input doc |
| V2 | 2026-07-23 | OpenCode | Controller code analysis added; teacher extraction logic documented; schedule matrix building detailed |

---

*Document generated from controller code analysis, input requirement doc, and FRD cross-reference.*
