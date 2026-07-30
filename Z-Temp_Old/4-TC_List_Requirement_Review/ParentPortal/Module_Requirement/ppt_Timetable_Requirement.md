# Timetable — Business Requirements

## 1. What This Screen Does

The Timetable screen (`/parent-portal/timetable`) shows the active child's published weekly class timetable as a day × period grid. It displays all days of the week (Monday through Saturday by default) as columns, with period rows showing the subject name, teacher name, and room for each cell. The current day column and the current period cell are visually highlighted so the parent can quickly see what the child is studying right now.

The view is entirely read-only — parents cannot modify timetable data. Only published/active timetables are shown; draft or unpublished timetables are excluded.

---

## 2. When This Screen Is Used

- **Morning check** — Parents check what classes the child has today to help prepare books and materials
- **Period tracking** — Parents check which subject is currently being taught
- **Weekly planning** — Parents review the full weekly schedule for tuition scheduling or extracurricular planning
- **Teacher lookup** — Parents identify which teacher teaches which subject for their child
- **Academic term planning** — Parents review the timetable at the start of a new term

---

## 3. Who Can Access This Screen

- **Parent / Guardian** — Full read-only access for their active linked child
- **System** — Reads published timetable data from SmartTimetable module via `TimetableCell`

No explicit Gate or Policy exists. Access is controlled by `ParentContextService::resolveChild()` which ensures the parent can only see timetable data for their own linked children based on the child's current class-section enrollment.

---

## 4. How This Screen Works — Step by Step

1. Parent navigates to `GET /parent-portal/timetable`
2. `ParentTimetableController@index` is invoked
3. `ParentContextService::resolveChild($request)` resolves the active child
4. The child's current academic session is loaded with class-section relationships (class and section)
5. If the child has no class-section assignment, the view renders with empty collections and `noTimetable = true`
6. Timetable cells are queried from `TimetableCell`:
   - Filtered by the child's `class_id` and `section_id` through the timetable activity relationship
   - Filtered to only active/published timetables (status in `['ACTIVE', 'GENERATED', 'PUBLISHED']`)
   - Break periods (`is_break = true`) are excluded
   - Eager-loaded with: activity subject, activity teachers → teacher → user, period, room
   - Ordered by `period_ord` ascending
7. Cells are grouped by `day_of_week` (Carbon convention: 0 = Sunday, 1 = Monday, ... 6 = Saturday)
8. Unique periods are collected in sorted order (`period_ord` ascending)
9. Active days are determined — filtered to Monday–Saturday (1–6) by default; if no cells exist on those days, all available days are shown
10. An activity log entry is created: "Viewed timetable" with student context
11. Data is passed to `parentportal::timetable.index` view: `$child`, `$session`, `$byDay`, `$periods`, `$activeDays`

**Grid Structure (View Responsibility):**
The Blade view is expected to render a table with:
- Columns for each active day (Monday, Tuesday, ...)
- Rows for each unique period (Period 1, Period 2, ...)
- Each cell shows: subject name, teacher name, room
- Current day column highlighted (e.g., coloured header or border)
- Current period cell highlighted (e.g., different background colour) based on current time vs period time range

**Note:** The current day and current period highlighting logic is entirely in the view layer. The controller passes raw data; the view is responsible for comparing `now()->dayOfWeek` against `day_of_week` and `now()->format('H:i')` against period start/end times to apply highlight CSS classes.

---

## 5. Validation Rules

### 5.1 Controller-Level Guards

| Condition | Guard | Behaviour |
|---|---|---|
| No class-section assigned | `if (! $session?->classSection)` | Render view with empty collections; `noTimetable = true` |
| No published timetables | Empty `$cells` collection | Render view with empty grid |
| Child has no linked children | `ParentContextService::resolveChild()` | Redirect to `/no-access` |

---

## 6. Business Rules and Conditions

### Rule BR-PPT-001: Child Data Scoping
Timetable data scoped exclusively to the parent's active linked child. The class-section used for timetable lookup comes from the child's `currentSession` enrollment.

### Rule: Only Published Timetables Shown
Timetable cells are filtered to timetables with status `['ACTIVE', 'GENERATED', 'PUBLISHED']`. Draft timetables are excluded — parents never see unpublished schedule data.

### Rule: Break Periods Excluded
Cells with `is_break = true` are filtered out. Break/lunch periods are not shown in the parent's timetable view.

### Rule: Read-Only Data
Parents cannot modify timetable data — no create, update, or delete operations exist in `ParentTimetableController`.

### Rule: Day Filter (Mon–Sat)
Active days default to Monday through Saturday (1–6). If no timetable cells exist on any of these days (e.g., only Sunday has data), the fallback shows whatever days have cells.

---

## 7. Business Rules Summary

| Rule | What It Means |
|---|---|
| BR-PPT-001 | Timetable scoped to parent's linked child's class-section |
| Published Only | Draft/unpublished timetables excluded |
| No Breaks | Break/lunch periods filtered out |
| Read-Only | Parent cannot modify timetable |
| Mon–Sat Default | Grid shows weekdays; fallback to any available days |

---

## 8. Error Messages

| Scenario | Error Message / Behaviour |
|---|---|
| No class-section assigned | Empty timetable grid with `noTimetable = true` flag |
| No published timetable | Empty grid with "No timetable published" message |
| Child resolution fails | Redirect to `/no-access` |

---

## 9. Success Scenarios

- **Timetable grid loads**: Parent sees a full weekly timetable: columns for Mon, Tue, Wed, Thu, Fri, Sat; rows for Periods 1 through 8. Each cell shows "Science (Ms. Patel)" or "Math (Mr. Verma) — Room 201". Today's column has a highlighted header. The current period has a highlighted cell background.

- **Period with teacher info**: Hovering over a cell (or viewing on mobile) shows the teacher's name as displayed text. Multiple teachers can be assigned to a single subject — all are shown.

- **New term timetable**: At the start of the new academic term, the school publishes a new timetable. The parent sees the updated schedule immediately (no draft visibility).

---

## 10. Failure Scenarios

- **Child not yet assigned to a class-section**: The timetable page loads with an empty grid and `noTimetable = true` flag. The page shows "No class-section assigned" message. No error or crash.

- **School has not published any timetable**: The timetable page loads with an empty grid. The page shows "Timetable not yet published" message.

- **Only break periods exist**: If all timetable cells are break periods, the filter removes them all and the grid is empty.

---

## 11. Example Scenario

Mrs. Singh logs into the Parent Portal and navigates to Timetable for her son Rohit (Class 9B).

1. The page loads a grid with 6 columns (Mon–Sat) and 8 rows (Periods 1–8).

2. **Today is Wednesday** — the Wednesday column has a highlighted header. The current time is 10:15 AM, which falls within Period 3 (10:00–10:55 AM). The Period 3 cell in Wednesday's column has a different background colour.

3. **Monday's cells show:**
   - Period 1: English (Ms. Sharma) — Room 101
   - Period 2: Math (Mr. Verma) — Room 203
   - Period 3: Science (Ms. Patel) — Room 105
   - Period 4: Hindi (Mr. Singh) — Room 102
   - Period 5: Lunch (Break — not shown)
   - Period 6: Social Studies (Mr. Gupta) — Room 301
   - Period 7: PE (Mr. Khan) — Ground
   - Period 8: Computer (Ms. Mehta) — Lab 1

4. Mrs. Singh notes that Rohit has PE on Monday and Friday — she reminds him to carry his sports kit on those days.

5. She also sees that the Math teacher is Mr. Verma. She makes a note to contact him about Rohit's recent performance.

---

## 12. Related Screens

| Screen | Route | Relationship |
|---|---|---|
| Dashboard | `/parent-portal/` | Today's timetable widget is sourced from same `TimetableCell` data |
| Teachers | `/parent-portal/teachers` | Teacher names visible in timetable cells |

---

## 13. How Other Parts of the System Depend on This Screen

| Area | What It Needs From Timetable |
|---|---|
| **Dashboard** | Today's timetable widget queries the same `TimetableCell` with day filter |
| **Subject-wise Attendance** | Attendance periods correspond to timetable period structure |

---

## 14. Dependencies

| Dependency | Type | Purpose |
|---|---|---|
| `ParentContextService` | Internal service | Child resolution with class-section lookup |
| `TimetableCell` (tt_timetable_cells) | External model | Core timetable cell data |
| Timetable status filter | Query condition | `['ACTIVE', 'GENERATED', 'PUBLISHED']` — excludes drafts |
| `currentSession.classSection` | Child relationship | Provides class_id and section_id for timetable lookup |
| `activity.subject` | Eager-loaded relationship | Subject name for each cell |
| `activity.teachers.teacher.user` | Eager-loaded relationship | Teacher name for each cell |
| `period` | Eager-loaded relationship | Period order and time range |
| `room` | Eager-loaded relationship | Room/location for each cell |

---

## 15. State Machine

### Timetable View Loading

| Step | Event | Guard | Result |
|---|---|---|---|
| 1 | Parent opens timetable | Resolve child | Child + session obtained |
| 2 | Load class-section | session.classSection exists | class_id + section_id available |
| 2a | Load class-section | session.classSection is null | noTimetable = true; empty grid |
| 3 | Query timetable cells | Published/Active timetables | Cells returned (or empty) |
| 4 | Filter breaks | is_break = false | Breaks removed |
| 5 | Group by day | Cells exist | byDay collection built |
| 6 | Collect periods | Cells exist | Unique periods sorted |
| 7 | Determine active days | Cells exist | Mon–Sat or fallback |
| 8 | Render view | All data ready | Timetable grid displayed |

---

## 16. Notes and Gaps

| # | Note | Impact |
|---|---|---|
| 1 | **No explicit authorization Gate:** Like dashboard and attendance, the timetable controller has no `Gate::authorize()` or policy. | If child resolution is bypassed, timetable data could leak. |
| 2 | **Current day/period highlight is view-only:** The controller passes raw `day_of_week` and `period_ord` data. The highlighting logic (comparing against `now()->dayOfWeek` and current time vs period times) is entirely in the Blade view. | Inconsistency possible if view implementation differs from expected behaviour. |
| 3 | **No academic term selector in controller:** FRD mentions "Academic term selector available; defaults to current active term" (REQ-PPT-008 AC4). The current controller uses the child's current session implicitly and does not provide a term selector parameter. | Parents cannot view timetables from past or future terms via the controller. |
| 4 | **Period time range not used in controller:** The controller loads the `period` relationship but does not expose period start/end times for the view to determine current period. The view must independently access period times. | View may not have period time data for highlighting if not passed correctly. |
| 5 | **Day filter fallback may show Sunday:** If no cells exist Mon–Sat (e.g., timetable only has Sunday activities), the fallback includes Sunday (0). This is an edge case for most Indian K-12 schools. | Unlikely to occur but handled with fallback logic. |
