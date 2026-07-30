# stp_ExamSchedule — Requirement Document

## 1. Module Information

| Field | Value |
|-------|-------|
| Module Code | STP |
| Module Name | StudentPortal |
| Feature Name | Exam Schedule |
| Table Prefix | stp_ (consumes `lms_exam_allocations`) |
| DB Layer | Tenant (`tenant_{uuid}`) |
| Route Name | `student-portal.exam-schedule` |
| HTTP Method + Path | GET `/student-portal/exam-schedule` |
| Controller | `StudentPortalController@examSchedule` |
| View | `studentportal::exams.schedule` |
| Input Doc | `pgdatabase/Backup/4-Module_Requirement/StudentPortal/examinations/exam_schedule.md` |
| FRD Reference | REQ-STP-009, BR-STP-001, BR-STP-021 |

## 2. Feature Overview

Lists all exam allocations for the student's class, section, or individual student from the `lms_exam_allocations` table. Exams are split into Ongoing (currently in progress), Today (scheduled for today), Upcoming (future), and Concluded (past) sections. Supports filtering by mode (All / Online / Offline) via tabs. Links to the online exam attempt flow for online exams.

## 3. Functional Requirements

| ID | Requirement | Status |
|----|-------------|--------|
| F1 | Load exam allocations for the student's class, section, and student-specific | ✅ |
| F2 | Filter allocations where `examPaper` is not null (valid papers only) | ✅ |
| F3 | Sort allocations by scheduled date ascending | ✅ |
| F4 | Categorise into: ongoing (today + within time window), today, upcoming (future), concluded (past) | ✅ |
| F5 | Attach each allocation's attempt record (from `ExamAttempt`) keyed by allocation_id | ✅ |
| F6 | Display stat cards: Total Exams, Online Exams, Offline Exams, Today's Exams | ✅ |
| F7 | Provide filter tabs: All, Online, Offline | ✅ |
| F8 | Each category section (Ongoing/Today/Upcoming/Concluded) displays a table with: Exam name, Subject, Mode, Date, Time Slot, Duration, Max Marks, Venue, Status | ✅ |
| F9 | Show days-remaining countdown for upcoming exams (within 3 days = red highlight) | ✅ |
| F10 | Show attempt status for concluded online exams (attempted/submitted vs not attempted) | ✅ |
| F11 | Record activity log on page view | ✅ |
| F12 | Show empty state when no exams allocated | ✅ |

## 4. Business Rules

| Rule ID | Rule Description | Enforcement |
|---------|-----------------|-------------|
| BR-STP-001 | Data must belong to the authenticated student | `$studentId = $student->id` |
| BR-STP-021 | Exam allocations scoped by allocation_type (CLASS, SECTION, STUDENT) | `where(fn: CLASS where class_id, OR SECTION where class_id+section_id, OR STUDENT where student_id)` |
| BR-EXAM-01 | Only active allocations shown | `where('is_active', true)` |
| BR-EXAM-02 | Allocation date = `scheduled_date` or fallback to `exam.start_date` | `$alloc->scheduled_date ?? $exam->start_date` |
| BR-EXAM-03 | Ongoing = today's date AND current time between scheduled_start_time and scheduled_end_time | Controller computes via Carbon `now()->between($open, $close)` |
| BR-EXAM-04 | Concluded = date in past AND not today | `Carbon::parse($d)->isPast() && !isToday()` |
| BR-EXAM-05 | Upcoming = date in future | `Carbon::parse($d)->isFuture()` |
| BR-EXAM-06 | Attempt attached per allocation for attempt-status display | `ExamAttempt::where('student_id',$sid)->whereIn('allocation_id',...)->get()->keyBy('allocation_id')` |

## 5. User Interface & Layout

### 5.1 Page Header
- Breadcrumb: Home > Exam Schedule
- Title: "Exam Schedule"

### 5.2 Stat Cards (Row of 4)
- **Total Exams** — Purple (#6c5ce7), calendar icon
- **Online Exams** — Blue (#0984e3), monitor icon
- **Offline Exams** — Orange (#e17055), edit icon
- **Today's Exams** — Green (#00b894), alert-circle icon

### 5.3 Filter Tabs
- **All** (default, shows all categories)
- **Online** (filters by `mode === 'ONLINE'`)
- **Offline** (filters by `mode === 'OFFLINE'`)

### 5.4 Category Sections (within each tab)
#### 5.4.1 Ongoing (if any)
- Red left border, pulsing red dot, "zap" icon
- "Ongoing Now" header
- Table rows highlighted green

#### 5.4.2 Today's Exams
- Green left border, alert-circle icon
- "Today's Exams" header

#### 5.4.3 Upcoming
- Blue left border, calendar icon
- "Upcoming Exams" header
- Days-remaining countdown shown
- ≤3 days: red text; >3 days: light grey text

#### 5.4.4 Concluded
- Grey left border, check-circle icon
- "Concluded Exams" header
- Shows "Today"/"Upcoming"/"Concluded" status badges

### 5.5 Exam Table Columns
| Column | Content |
|--------|---------|
| # | Row number |
| Exam | Exam name + paper title (if different) + paper code |
| Subject | Subject name |
| Mode | Online (desktop icon, blue badge) or Offline (pencil icon, orange badge) |
| Date | Scheduled date + days left or "Today" label |
| Time Slot | Start – End time (e.g. "10:00 AM – 12:00 PM") |
| Duration | Duration in minutes |
| Max Marks | Total marks for the paper |
| Venue / Location | Room location text |
| Status | Badge: "Today" (green), "Upcoming" (blue), "Concluded" (grey) |

## 6. Data Flow & Processing

```
User navigates → GET /student-portal/exam-schedule
  ↓
StudentPortalController@examSchedule()
  ↓
auth()->user()->student
  ↓
currentSession() → classId, sectionId, studentId
  ↓
ExamAllocation::where('is_active', true)
  ->where(fn:
    CLASS where class_id,
    OR SECTION where class_id + section_id,
    OR STUDENT where student_id
  )
  ->with(['examPaper.exam', 'examPaper.subject'])
  ->get()
  ->filter(fn: examPaper !== null)
  ->sortBy(fn: scheduled_date ?? exam->start_date)
  ↓
$attempts = ExamAttempt::where('student_id', $sid)
  ->whereIn('allocation_id', $allocations->pluck('id'))
  ->get()->keyBy('allocation_id')
  ↓
Attach attempt to each allocation
  ↓
Categorise:
  $ongoing = today + time between scheduled_start_time and scheduled_end_time
  $today = scheduled_date is today
  $upcoming = scheduled_date is future
  $concluded = scheduled_date is past (and not today)
  ↓
activityLog()
  ↓
Return view('studentportal::exams.schedule', compact('upcoming','today','concluded','ongoing','session'))
```

**Ongoing computation:**
```php
$ongoing = $today->filter(function ($a) {
    $startTime = $a->scheduled_start_time;  // "2026-04-13 10:00:00"
    $endTime   = $a->scheduled_end_time;
    $start = Carbon::parse($startTime)->format('H:i:s');
    $end   = Carbon::parse($endTime)->format('H:i:s');
    $date  = Carbon::parse($a->scheduled_date)->format('Y-m-d');
    $open  = Carbon::parse($date . ' ' . $start);
    $close = Carbon::parse($date . ' ' . $end);
    return now()->between($open, $close);
});
```

## 7. Database References

| Table | Model | Purpose |
|-------|-------|---------|
| `lms_exam_allocations` | `Modules\LmsExam\Models\ExamAllocation` | Core exam allocation records |
| `lms_exam_papers` | Via `->examPaper` | Exam paper details (mode, duration, marks) |
| `lms_exams` | Via `->examPaper->exam` | Exam metadata (title, start_date) |
| `sch_subjects` | Via `->examPaper->subject` | Subject details |
| `lms_exam_attempts` | `Modules\StudentPortal\Models\ExamAttempt` | Student attempt record per allocation |
| `std_students` | Student model | Student identity |

**Key fields from `lms_exam_allocations`:**
- `allocation_type` — CLASS / SECTION / STUDENT
- `class_id`, `section_id`, `student_id` — Target scope
- `scheduled_date`, `scheduled_start_time`, `scheduled_end_time` — Schedule
- `location` — Venue text

## 8. Route Reference

| Route Name | Method | Path | Controller Method |
|------------|--------|------|-------------------|
| `student-portal.exam-schedule` | GET | `/student-portal/exam-schedule` | `StudentPortalController@examSchedule` |

## 9. Permissions & Security

| Concern | Status | Notes |
|---------|--------|-------|
| Authentication | ✅ | Route behind `auth` + `verified` middleware |
| Data ownership | ✅ | Scoped to student's class, section, or direct student allocation |
| IDOR risk | ✅ | No parameter-based access — derived from auth |
| Activity logging | ✅ | Every view logged |

## 10. Validation & Error Handling

| Scenario | Handling |
|----------|----------|
| No student profile | View still renders but `$student->id` = 0, allocations empty |
| No class/section | Empty allocations collection |
| No exam allocations | Empty state: "No exams scheduled at the moment." with calendar icon |
| Allocation with null examPaper | Filtered out via `->filter(fn($a) => $a->examPaper !== null)` |
| Null scheduled_date | Falls back to `exam.start_date` |
| Null scheduled_start_time / end_time | Excluded from ongoing filter |
| Null location | Displayed as "—" |
| Allocation mode not ONLINE or OFFLINE | Shows "—" badge |

## 11. Edge Cases & Empty States

| Edge Case | Expected Behaviour |
|-----------|--------------------|
| No exams allocated | Empty state: "No exams scheduled at the moment." |
| Exam today but outside current time | Shows in Today section but NOT in Ongoing |
| Online exam today with Start Exam button | Only through attempt flow; Exam Schedule shows date/status |
| All exams concluded | Only Concluded section visible; empty Ongoing/Today/Upcoming sections |
| Exam allocation without `scheduled_date` | Falls back to `exam.start_date` |
| Student-specific allocation | Included via `allocation_type = 'STUDENT'` filter |
| Multiple tabs (Online/Offline) | Active tab shows only matching mode allocations |

## 12. Performance Considerations

| Aspect | Analysis |
|--------|----------|
| Query load | 2 queries: ExamAllocations (with 2 eager loads) + ExamAttempts |
| N+1 risk | None — eager loaded |
| Filtering | Collection-level filtering (mode, time computation) — fine for <100 allocations |
| Time computation | Each allocation parsed via Carbon — negligible overhead |
| Recommendation | No caching needed given low query volume |

## 13. Dependencies

| Dependency Module | Entity Consumed |
|-------------------|-----------------|
| LmsExam | ExamAllocation, ExamPaper, Exam |
| StudentPortal (STP) | ExamAttempt (STP-owned) |
| StudentProfile (STD) | Student, AcademicSession |

## 14. FRD Traceability

| FRD ID | Description | Status |
|--------|-------------|--------|
| REQ-STP-009 | Exam Schedule (P0) — View upcoming/past exam schedule | ✅ Implemented |
| BR-STP-001 | Data ownership — student data must belong to authenticated student | ✅ Enforced |
| BR-STP-021 | Exam allocation scope (CLASS, SECTION, STUDENT) | ✅ Enforced |

## 15. Known Issues / Gaps

| ID | Issue | Severity | Status |
|----|-------|----------|--------|
| GAP-EXM-01 | No direct "Start Exam" action button in Exam Schedule — student must navigate to My Learning or Online Exams separately | Medium | ⬜ |
| GAP-EXM-02 | Concluded exams show "Concluded" status badge but do not indicate whether student attempted it (absent vs submitted) | Medium | ⬜ |
| GAP-EXM-03 | Countdown timer only shows days remaining (not hours/minutes for same-day exams) | Low | ⬜ |
| GAP-EXM-04 | Duration column reads from `paper.duration_minutes` — offline exams may not have duration set | Low | ⬜ |
| GAP-EXM-05 | Offline exam venue shown as `$alloc->location` — not linked to room master data | Low | ⬜ |

## 16. Change Log

| Version | Date | Author | Change Description |
|---------|------|--------|--------------------|
| V1 | — | — | Initial requirement as per input doc |
| V2 | 2026-07-23 | OpenCode | Controller code analysis added; ongoing/time-window logic documented; allocation scoping detailed |

---

*Document generated from controller code analysis, input requirement doc, and FRD cross-reference.*
