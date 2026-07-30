# stp_SyllabusProgress — Requirement Document

## 1. Module Information

| Field | Value |
|-------|-------|
| Module Code | STP |
| Module Name | StudentPortal |
| Feature Name | Syllabus Progress |
| Table Prefix | stp_ (consumes `slb_syllabus_schedule`) |
| DB Layer | Tenant (`tenant_{uuid}`) |
| Route Name | `student-portal.syllabus-progress` |
| HTTP Method + Path | GET `/student-portal/syllabus-progress` |
| Controller | `StudentProgressController@syllabusProgress` |
| View | `studentportal::syllabus.progress` |
| Input Doc | `pgdatabase/Backup/4-Module_Requirement/StudentPortal/academics/syllabus_progress.md` |
| FRD Reference | REQ-STP-013, BR-STP-001 |

## 2. Feature Overview

Tracks syllabus coverage for the student's class/section by reading `slb_syllabus_schedule` records. Displays overall completion percentage, per-subject progress bars with KPI cards, and a drill-down lesson→topic accordion showing scheduled timelines, assigned teachers, priority, and dynamic status (completed/in_progress/upcoming) computed from scheduled start/end dates relative to today.

## 3. Functional Requirements

| ID | Requirement | Status |
|----|-------------|--------|
| F1 | Load syllabus schedules for the student's class and section, filtered by active academic session | ✅ |
| F2 | Group schedules by subject → lesson → topic hierarchy | ✅ |
| F3 | Compute topic status dynamically: completed (end < today), in_progress (start ≤ today ≤ end), upcoming (start > today) | ✅ |
| F4 | Display overall KPI cards: Completed, In Progress, Upcoming, Total Topics counts | ✅ |
| F5 | Show overall completion progress bar with segmented green (done) + amber (in_progress) | ✅ |
| F6 | Render per-subject cards with subject name, progress percentage, lesson count, topic count | ✅ |
| F7 | Expandable lesson accordion within each subject showing topic-level table | ✅ |
| F8 | Topic table columns: Topic Details (name, level, notes), Scheduled Timeline (start–end), Duration/Periods, Instructor, Priority, Status badge | ✅ |
| F9 | Visual differentiation: completed topics have strikethrough + muted colours; in_progress topics have animated spinner | ✅ |
| F10 | Record activity log on each page view | ✅ |
| F11 | Show empty/no-session state when student profile, class, or schedules are missing | ✅ |

## 4. Business Rules

| Rule ID | Rule Description | Enforcement |
|---------|-----------------|-------------|
| BR-STP-001 | Data must belong to the authenticated student | Controller enforces via `auth()->user()->student` |
| BR-SYLL-01 | Schedule filtered by class_id AND (section_id OR null section) | `where('section_id', $sectionId)->orWhereNull('section_id')` — supports school-wide topics |
| BR-SYLL-02 | Only active schedules shown | `where('is_active', true)` |
| BR-SYLL-03 | Topic status derived from date comparison, not stored | `$end->lt($today)` → completed; `$start->lte($today) && (!$end || $end->gte($today))` → in_progress; else upcoming |
| BR-SYLL-04 | Subject colour cycled from palette of 7 colours | `$colors[$si % count($colors)]` in view |
| BR-SYLL-05 | Lesson accordion: first lesson expanded by default | `$isFirst = ($li === 0)` → `aria-expanded="true"` |

## 5. User Interface & Layout

### 5.1 Page Header
- Bradecrumb: Home > Syllabus Progress
- Title: "Syllabus Progress"

### 5.2 Class/Session Info Bar
- Graduation cap icon
- Class name + Section name
- Academic session name
- Roll number

### 5.3 Overall Progress Bar
- Stacked bar: green = completed %, amber = in_progress %
- Percentage label alongside
- Legend: Completed (green dot), In Progress (amber dot), Upcoming (grey dot)

### 5.4 KPI Cards (Row of 4)
- Completed — green accent, check-circle icon
- In Progress — amber accent, clock icon
- Upcoming — grey accent, calendar icon
- Total Topics — purple accent, book icon

### 5.5 Per-Subject Cards
- 4px colour accent border on left
- Subject name + icon
- Lesson count, topic count
- "X% COVERED" pill badge (colour matches subject)
- Progress bar (green + amber segments)
- Expandable lesson accordion

### 5.6 Lesson Accordion
- Lesson code badge, name, date range, period count, weightage %
- Compact progress bar + percentage
- Expandable → topic detail table

### 5.7 Topic Table
| Column | Content |
|--------|---------|
| Topic Details | Name, level badge, notes (italic) |
| Scheduled Timeline | Start – End date |
| Duration/Periods | Minutes or period count |
| Instructor | Teacher name |
| Priority | Red/amber/blue dot + label |
| Status | Pill badge: Completed (green), In Progress (amber), Upcoming (grey) |

**Special styling:**
- Completed topics: strikethrough title, muted text colour, light background row
- In Progress: animated striped progress bar
- Lesson footer: summary of completed/total topics, "ACTIVE" badge if in progress, "FULLY COVERED" badge if complete

## 6. Data Flow & Processing

```
User navigates → GET /student-portal/syllabus-progress
  ↓
StudentProgressController@syllabusProgress()
  ↓
auth()->user()->student → null? → return empty state view
  ↓
$student->currentSession()->with(classSection.class, classSection.section, academicSession)
  ↓
No class_id? → return empty with noSession=true
  ↓
SyllabusSchedule::where('class_id', $classId)
  ->where(fn: section_id OR null)
  ->when(sessionId)
  ->where('is_active', true)
  ->with(['subject', 'lesson', 'topic', 'topic.topicLevelType', 'assignedTeacher'])
  ->orderBy('lesson_id')->orderBy('scheduled_start_date')
  ->get()
  ↓
Group by subject_id → for each:
  Group by lesson_id → for each:
    Map topics with computed status (completed/in_progress/upcoming)
    Calculate lesson totals: completed, in_progress, upcoming, pct
  Calculate subject totals
  ↓
activityLog() recorded
  ↓
Return view('studentportal::syllabus.progress', compact('subjects', 'session'))
```

**Status computation logic:**
```php
$status = match (true) {
    $end && $end->lt($today)                                          => 'completed',
    $start && $start->lte($today) && (!$end || $end->gte($today))    => 'in_progress',
    default                                                           => 'upcoming',
};
```

**Percentage formula (per group):** `$total > 0 ? round(($completed / $total) * 100) : 0`

## 7. Database References

| Table | Model | Purpose |
|-------|-------|---------|
| `slb_syllabus_schedule` | `Modules\Syllabus\Models\SyllabusSchedule` | Core syllabus schedule records |
| `sch_subjects` | Via `->subject` relation | Subject details |
| `slb_lessons` | Via `->lesson` relation | Lesson details (code, name, periods, weightage) |
| `slb_topics` | Via `->topic` relation | Topic details (name, description, duration) |
| `slb_topic_level_types` | Via `->topic->topicLevelType` | Topic level/type name |
| `std_students` | `Modules\StudentProfile\Models\Student` | Student profile chain |
| `std_student_sessions` | Via `currentSession()` | Enrolment session, class, section |

## 8. Route Reference

| Route Name | Method | Path | Controller Method |
|------------|--------|------|-------------------|
| `student-portal.syllabus-progress` | GET | `/student-portal/syllabus-progress` | `StudentProgressController@syllabusProgress` |

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
| No student profile | Empty state: "No active session found. Please contact your school admin." |
| No class assigned | Empty state with `noSession=true` |
| No syllabus schedules found | Empty state: "No syllabus scheduled yet. Your class syllabus will appear here once your school adds it." |
| Subject with no name | Falls back to 'Subject' label |
| Lesson with no name | Falls back to 'Lesson N' label |
| Topic with no name | Falls back to 'Topic #ID' format |
| Null scheduled dates | Start/end rendered as '—' or null; status defaults to 'upcoming' |
| No teacher assigned | Displayed as '—' |
| Null priority | Not rendered (empty) |

## 11. Edge Cases & Empty States

| Edge Case | Expected Behaviour |
|-----------|--------------------|
| No schedules for any subject | Empty state: "No syllabus scheduled yet." |
| All topics completed | 100% bar; "FULLY COVERED" badge on all lessons |
| All topics upcoming | 0% progress; all pill badges show "Upcoming" |
| Single subject with one lesson | Single card, single accordion entry, expanded by default |
| Schedule with section_id = null | Included (school-wide topic) via `orWhereNull('section_id')` |
| Topic spanning multiple days | Status computed from scheduled_start_date to scheduled_end_date |
| Schedule with no topic linked | Falls back to "Topic #ID" display |

## 12. Performance Considerations

| Aspect | Analysis |
|--------|----------|
| Query load | Single query on `slb_syllabus_schedule` with 5 eager-loaded relationships |
| N+1 risk | None — all relations eagerly loaded |
| In-memory computation | Subject/lesson grouping and status computed in collection (no extra queries) |
| View rendering | Heavy Blade template with nested loops — could be slow for >10 subjects with >100 topics |
| Recommendation | Lazy-load lesson accordion bodies (already done via Bootstrap collapse) |

## 13. Dependencies

| Dependency Module | Entity Consumed |
|-------------------|-----------------|
| Syllabus | SyllabusSchedule, Lesson, Topic, TopicLevelType |
| StudentProfile (STD) | Student, AcademicSession, ClassSection |

## 14. FRD Traceability

| FRD ID | Description | Status |
|--------|-------------|--------|
| REQ-STP-013 | Syllabus Progress (P1) — Track syllabus completion progress | ✅ Implemented |
| BR-STP-001 | Data ownership — student data must belong to authenticated student | ✅ Enforced |

## 15. Known Issues / Gaps

| ID | Issue | Severity | Status |
|----|-------|----------|--------|
| GAP-SYL-01 | No subject code filter — schedules may include subjects outside student's enrolled curriculum | Low | ⬜ |
| GAP-SYL-02 | Status computed only from dates — no manual "completed" flag from teacher | Low | ⬜ |
| GAP-SYL-03 | No pagination on subjects/lessons — all data loaded at once | Low | ⬜ |
| GAP-SYL-04 | Priority values not standardised: view expects HIGH/MEDIUM/LOW uppercase but raw DB value may vary | Medium | ⬜ |
| GAP-SYL-05 | No caching — syllabus data re-queried on every page load, even though schedules change infrequently | Medium | ⬜ |

## 16. Change Log

| Version | Date | Author | Change Description |
|---------|------|--------|--------------------|
| V1 | — | — | Initial requirement as per input doc |
| V2 | 2026-07-23 | OpenCode | Controller code analysis added; view structure documented; status computation logic detailed |

---

*Document generated from controller code analysis, input requirement doc, and FRD cross-reference.*
