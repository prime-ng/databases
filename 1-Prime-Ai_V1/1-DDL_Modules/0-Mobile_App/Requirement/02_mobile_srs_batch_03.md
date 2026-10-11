# Mobile SRS — Batch 03 (Attendance · Timetable · Syllabus · Lesson Plan)

> Index: `02_mobile_srs_index.md`. Features: F-020, F-021, F-022, F-023, F-030, F-031, F-032.

---

## F-020: Mark Class Attendance (Teacher)

### 1. Overview
Open today's class roster (resolved from active period), mark each student Present / Absent / Late / Leave / Half-day, bulk "mark all present", optional remark per student, submit with idempotency key. Offline-tolerant (queued writes).

### 2. User Stories
- **US-020.1** *As a teacher, I want a one-tap roster, so I mark attendance in 30 s.*
  - Edge — flaky signal: rolls into queue, syncs later.
  - Edge — same period marked twice (own correction): server upsert returns 200; client shows "Updated".
- **US-020.2** *As a class teacher, I can correct same-day attendance on a student row.*
- **US-020.3** *As a teacher, I see who already marked the period if a substitute filled in (read-only badge).*

### 3. Functional Requirements
- **FR-020.1** Active period auto-resolved from `tt_timetable_cells` for `teacher_id = me, weekday = today, time-window contains now()`.
- **FR-020.2** Submit body uses idempotency key `att:{class_section_id}:{period_id}:{date}` so retries are safe.
- **FR-020.3** Half-day → split AM/PM rows OR boolean `is_half_day` on the record (Q-OQ — no half-day column today).
- **FR-020.4** Status values must come from `sys_dropdown_table` with type `ATTENDANCE_STATUS` (D29 — no enums).
- **FR-020.5** Successful submit → emits `ATTENDANCE_ABSENT` / `_LATE` push to absent students' parents.
- **FR-020.6** Backend MUST authorize: teacher is assigned to that class-section-period (`tt_timetable_cell_teachers`).
- **FR-020.7** Submission validation MUST be FormRequest-driven (D25, D30) — current `storeBulkAttendance` validation is fully commented out (BG-23).

### 4. Screen Specifications

#### S-020.1 — Class roster
```
┌──────────────────────────────────┐
│ ← VII-B Math · P3 · 8 May        │
│ [Mark all present]               │
│ ────────────────────────────     │
│ Asha Sharma         [P A L Lv]   │
│ Ravi Kumar          [P A L Lv]   │
│ Priya Patel         [P A L Lv]   │
│ ...                              │
│ ──────────────────────           │
│ 28 P · 4 A · 0 L      [Submit ➤] │
└──────────────────────────────────┘
```
- Per row: 4 toggle chips (P/A/Lt/Lv); long-press → remark.
- States: loading roster, error (no permission, period not active), offline (banner + queued indicator on submit).

#### S-020.2 — Submit confirm
"Marks queued — will sync when online." (offline) or "Submitted ✓" (online).

### 5. API Contracts

#### `POST /api/mobile/v1/attendance`
- **Auth:** Bearer + tenant + `X-Idempotency-Key: att:{cs}:{p}:{d}`.
- **Status:** NEW (BG-24 in new `Attendance` module — XL; v1 fallback through `StudentProfile/AttendanceController` after BG-23 fix).
- **Request:**
  ```json
  { "class_section_id":"...", "period_id":"...", "date":"2026-05-08",
    "marks":[
      {"student_id":"...","status_id":"<sys_dropdown_uuid>","remark":null,"is_half_day":false}
    ]
  }
  ```
- **Response 200:** `{ "data":{ "saved":32, "conflicts":[] } }`.
- **Response 4xx:**
  - `403 NOT_ASSIGNED_TO_PERIOD`
  - `409 CONFLICT` with canonical record (peer teacher overlap)
  - `422 VALIDATION_FAILED`.
- **Caching:** none (write).
- **Backend module/gap:** target `Modules/Attendance` (PLANNED) `att_attendance_*` 14 tables. Interim: `Modules/StudentProfile`. Pre-reqs: BG-23 (fix fatal Gate import + restore validation), BG-24 (new module), D29 (no enum), BG-39 / BG-40.

### 6. Data Model (client)
```sql
pending_writes: feature_id='F-020', endpoint='/attendance', request_body=<json>, idempotency_key
cache_today_roster (
  class_section_id TEXT, period_id TEXT, date INTEGER,
  payload_json TEXT, fetched_at INTEGER,
  PRIMARY KEY (class_section_id, period_id, date)
)
```

### 7. Offline Behavior
- Capture marks → write to `pending_writes` → optimistic UI shows "queued".
- Drain queue on connectivity-on; idempotency key ensures dedupe.
- Conflict (409): drop local copy, surface canonical record + "marked by Mr K (substitute)" badge.

### 8. Push Notifications
Emits: `ATTENDANCE_ABSENT`, `ATTENDANCE_LATE` (parents). Channel `academics`.

### 9. Permissions & Security
- Authorize via `tt_timetable_cell_teachers` lookup.
- BG-23 — fix fatal `Gate` import.
- BG-39 / BG-40 — replace `$request->all()` with `$request->validated()`.
- Audit: row in `sys_activity_logs` with `event=ATTENDANCE_SUBMITTED`, `meta={class_section_id,period_id,marks_count}`.

### 10. Non-Functional Requirements
- Performance: roster load < 1 s p50 (cached); submit perceived < 100 ms (queue).
- Accessibility: each chip labelled "Present, Absent, Late, Leave"; selected state read aloud.
- Localization: `f020.status.{P,A,L,LV,HD}`, `f020.cta.submit`, `f020.cta.allpresent`.
- Analytics: `attendance_submit_attempt`, `attendance_submit_success`, `attendance_submit_conflict`.

### 11. Acceptance Criteria
- **AC-020.1** Teacher can submit a class of 40 students offline; queue appears; on reconnection, single submission goes through; ABSENT pushes fire to parents within 60 s.
- **AC-020.2** Resubmit with same idempotency key returns 200 and does not duplicate.
- **AC-020.3** Submit with student outside this class returns 422 with that student rejected.
- **AC-020.4** Submit with a status_id not in `sys_dropdown_table` type ATTENDANCE_STATUS returns 422.

### 12. Dependencies
- F-012 (entry). BG-23, BG-24, BG-39, BG-40.

### 13. Out of Scope
- Subject-wise period attendance (only "I taught this period" snapshot at v1).
- Biometric attendance (face / fingerprint kiosk) — Phase 3+.

---

## F-021: View My Attendance (Student)

### 1. Overview
Calendar view + summary % for current term. Day-detail shows per-period status. Term-over-term trend chart.

### 2. User Stories
- **US-021.1** *As a student, I want a month calendar showing my attendance, so I can see patterns.*
- **US-021.2** *As a student preparing for a competition, I want my term % visible so I know if I'll cross the 75% rule.*

### 3. Functional Requirements
- **FR-021.1** Calendar shows current month with colour codes (P/A/L/Lv/Half/Holiday).
- **FR-021.2** Day detail shows per-period rows; on a no-school day shows "Holiday — {reason}" from `sch_holidays`.
- **FR-021.3** Aggregate metrics: term %, month %, longest streak.
- **FR-021.4** Endpoint scoped to authenticated student only — never accept `student_id` in path/query.

### 4. Screen Specifications

#### S-021.1 — Month calendar
```
┌──────────────────────────────────┐
│ My attendance · May 2026 · 92%   │
│ Mo Tu We Th Fr Sa Su             │
│  ●  ●  ●  ●  ●  ·  ·             │
│  ●  ●  ◑  ●  ✗  ·  ·             │
│ ...                              │
└──────────────────────────────────┘
```

#### S-021.2 — Day detail
List of periods with status + remark.

States: loading, empty (no school days yet), error, offline (cached).

### 5. API Contracts

#### `GET /api/mobile/v1/attendance/me?from=YYYY-MM-DD&to=YYYY-MM-DD`
- **Status:** NEW. Module: StudentProfile.
- **Response 200:**
  ```json
  { "data":{
    "summary":{"term_pct":92.0,"month_pct":94.4,"longest_streak":21},
    "days":[ {"date":"2026-05-01","status":"PRESENT","periods":[...]} ]
  }}
  ```
- **4xx:** `403 NOT_A_STUDENT`.

### 6. Data Model
```sql
cache_attendance_me (
  month_key TEXT PRIMARY KEY, payload_json TEXT, fetched_at INTEGER
)
```
Backend tables: `std_attendance_details`, `sch_holidays`, `tt_timetable_cells`.

### 7. Offline Behavior
Read-only cached per month.

### 8. Push Notifications
N/A (consumer of `ATTENDANCE_ABSENT` push to refresh on next open).

### 9. Permissions & Security
- Endpoint must NOT accept `student_id`. Hard-coded to `auth()->user()->student_uuid` resolution.
- BUG-007 student null-pointer on session must be fixed (BG-NEW-related).
- Audit: not logged.

### 10. Non-Functional Requirements
- Cached < 200 ms; network < 1.2 s.
- Localization: `f021.title`, `f021.status.*`.
- Accessibility: month calendar announces "May 2026, 92% present"; each day has accessibility label.

### 11. Acceptance Criteria
- **AC-021.1** Student without classes (just enrolled) sees "No attendance yet" empty state.
- **AC-021.2** Holiday days are colour-coded distinctly and labelled in day-detail.

### 12. Dependencies
- F-002. BUG-007 fix.

### 13. Out of Scope
- Multi-term comparison chart — v1.1.
- Reason-coded leave breakdown — v1.1.

---

## F-022: View Child Attendance (Parent)

### 1. Overview
Same as F-021 but for an active child, with an extra "Apply for leave" CTA shortcutting to F-100.

### 2. User Stories
- **US-022.1** *As a parent, I want my child's monthly attendance, so I notice early absences.*
- **US-022.2** *Tap on absent day → shortcut to "Apply leave (retroactive)" if same day still allowed by school policy.*

### 3. Functional Requirements
- **FR-022.1** Endpoint scoped by guardian binding (BR-PPT-012). Header `X-Active-Student-Id`.
- **FR-022.2** Same payload as F-021 plus `child` block.
- **FR-022.3** Retroactive leave allowed if `school_policy.late_leave_window_days >= 1`.
- **FR-022.4** SR-AUTH-001 fee-IDOR fix is a hard pre-req (parent endpoints sharing the same auth defect).

### 4. Screen Specifications
Mirrors F-021. Header pill (F-005). Day-detail bottom sheet has "Apply leave" CTA when applicable.

### 5. API Contracts

#### `GET /api/mobile/v1/attendance/student/{student_id}?from=&to=`
- **Header:** `X-Active-Student-Id` (must match path).
- **Status:** NEW. Module: StudentProfile / ParentPortal (PLANNED).
- **Response 200:** as F-021 + `child` (`uuid,name,class,section`).
- **4xx:** `403 CHILD_ACCESS_REVOKED`.

### 6. Data Model
`cache_attendance_child` keyed by `(student_uuid, month_key)`.

### 7. Offline Behavior
Read-only cached; switching child re-checks cache.

### 8. Push Notifications
Consumes `ATTENDANCE_ABSENT` / `_LATE` for refresh.

### 9. Permissions & Security
- BR-PPT-012 enforced on every request. SR-AUTH-001 fix prerequisite.
- Audit: not logged.

### 10. Non-Functional Requirements
As F-021.

### 11. Acceptance Criteria
- **AC-022.1** Parent A querying child of Parent B → 403.
- **AC-022.2** Switching active child triggers fresh fetch and renders within 1.2 s p50.

### 12. Dependencies
- F-005, F-022, F-100 (CTA target). BG-12 (SR-AUTH-001), BG-28.

### 13. Out of Scope
- Term-over-term comparison — v1.1.

---

## F-023: Self-Punch Attendance (Employee, P1)

### 1. Overview
Employees (Teacher / Staff) record their own daily punch-in / punch-out, optionally with selfie + GPS to verify on-premise. Replaces (for mobile) any manual register.

### 2. User Stories
- **US-023.1** *As a teacher arriving at school, I want to tap "Punch in", so the school registers my arrival.*
- **US-023.2** *As an admin, I want GPS-verified punches to deter buddy-punching.*

### 3. Functional Requirements
- **FR-023.1** Punch records: `(employee_id, type=IN|OUT, captured_at, lat, lon, selfie_media_id?)`.
- **FR-023.2** GPS optional but if disabled, server flags record `verification=UNVERIFIED`.
- **FR-023.3** Can punch only between configured windows (e.g. school 06:00–22:00) — anti-tamper.
- **FR-023.4** Idempotency: only one IN per day (unless OUT recorded between).
- **FR-023.5** Server validates location is within configured geofence radius (e.g. 200 m of `prm_tenant.location_lat/lon`).

### 4. Screen Specifications

#### S-023.1 — Punch screen
```
┌──────────────────────────────────┐
│ Today · 8 May · 09:14           │
│                                  │
│ Last punch: IN 09:13 (verified ✓)│
│                                  │
│         [Punch out]              │
│                                  │
│ ☐ Include selfie  ☑ Use GPS      │
└──────────────────────────────────┘
```

States: loading, verified/unverified, offline (allow queued IN, defer OUT).

### 5. API Contracts

#### `POST /api/mobile/v1/attendance/punch`
- **Status:** NEW (BG-31 part of HrStaff/SchoolSetup employee leave + attendance).
- **Request:** `{ "type":"IN|OUT", "captured_at":"...","lat":?,"lon":?,"selfie_media_id":? }`.
- **Response 201:** `{ "data":{ "id":"...", "verification":"VERIFIED|UNVERIFIED" } }`.
- **4xx:** `409 ALREADY_PUNCHED_IN`, `400 OUTSIDE_WINDOW`, `400 OUTSIDE_GEOFENCE`.

### 6. Data Model
```sql
cache_my_punches (date INTEGER PRIMARY KEY, payload_json TEXT)
pending_writes (...) for punches
```

### 7. Offline Behavior
Queue punches; sync when online.

### 8. Push Notifications
Optional `EMPLOYEE_PUNCH_REMINDER` (configurable) at end-of-day if no OUT recorded — channel `general`.

### 9. Permissions & Security
- OS: Camera (selfie optional), Location (foreground).
- Audit: every punch in `sys_activity_logs`.
- Anti-spoofing: server geofence; mocked-location detection (`safetyNet` Android, `DeviceCheck` iOS).

### 10. Non-Functional Requirements
- Punch perceived < 200 ms.
- Localization: `f023.cta.{in,out}`, `f023.flag.unverified`.
- Analytics: `punch_in/out`, `punch_unverified_reason`.

### 11. Acceptance Criteria
- **AC-023.1** GPS off → punch saved with `UNVERIFIED` flag; admin dashboard surfaces these.
- **AC-023.2** Outside-window punch returns 400.
- **AC-023.3** Already-punched-in IN returns 409.

### 12. Dependencies
- BG-31 employee leave / attendance APIs (DDL v4 ready, D33).

### 13. Out of Scope
- Biometric kiosk integration — Phase 4.
- Shift-based windows (multi-shift schools) — v1.1.

---

## F-030: My Timetable (Student / Teacher)

### 1. Overview
Weekly timetable. Student sees their class-section's schedule; Teacher sees their personal timetable. Read from SmartTimetable (`tt_*`).

### 2. User Stories
- **US-030.1** *As a student, I want to see my Tuesday at-a-glance, so I know what books to bring.*
- **US-030.2** *As a teacher, I want to see my own week of periods.*
- **US-030.3** *Today's column is highlighted; current period blinking border.*

### 3. Functional Requirements
- **FR-030.1** Endpoint resolves caller role; returns student-shaped or teacher-shaped payload.
- **FR-030.2** Honours `tt_holidays` and `tt_timetable_substitutions` (substitute teacher shows in italic + tag).
- **FR-030.3** Print/export → PDF download (CC-05).
- **FR-030.4** Cached locally for current term.

### 4. Screen Specifications

#### S-030.1 — Week grid
Day columns × period rows; today highlighted; current period pulse.

States: loading, error, empty (no timetable published).

### 5. API Contracts

#### `GET /api/mobile/v1/timetable/me?week_of=YYYY-MM-DD`
- **Status:** NEW (REUSE underlying SmartTimetable services).
- **Response 200:**
  ```json
  { "data":{
    "week_of":"2026-05-04",
    "days":[ {"date":"2026-05-04","periods":[ {"period_no":1,"start":"09:00","end":"09:45","subject":"Math","teacher":"Mr K","room":"R-12","is_substitute":false} ]} ]
  }}
  ```

### 6. Data Model
`cache_timetable_week` keyed by week.

### 7. Offline Behavior
Term-cached.

### 8. Push Notifications
- `TIMETABLE_CHANGED` (P1) — when a substitution affects me; data-only push triggers cache refresh.

### 9. Permissions & Security
- Read-only.
- Per-user scoping enforced server-side.

### 10. Non-Functional Requirements
- Cached < 200 ms.
- Localization: `f030.day.*`, `f030.period`.

### 11. Acceptance Criteria
- **AC-030.1** Substitution row shows italic + "Sub" tag.
- **AC-030.2** Current period highlights in real time (5-sec timer).

### 12. Dependencies
- F-002. SmartTimetable module.

### 13. Out of Scope
- Drag-to-reorder, edit — web-only (FET solver flow).

---

## F-031: Syllabus Progress (Student)

### 1. Overview
Per-subject syllabus tree (Subject → Chapter → Topic → Sub-topic) with covered / not-covered progress dots. Shows what teachers have covered and the % completion per chapter.

### 2. User Stories
- **US-031.1** *As a student, I want to see how much of each chapter is done, so I know what to revise.*
- **US-031.2** *As a parent (later), I want a similar view for my child.*

### 3. Functional Requirements
- **FR-031.1** Tree fetched per subject; nodes colored by coverage status from `syl_topic_coverage`.
- **FR-031.2** Tap leaf → optional notes / resources (links to lesson plans F-032).
- **FR-031.3** Covered % computed server-side.

### 4. Screen Specifications

```
┌──────────────────────────────────┐
│ Math · Chapter coverage          │
│ ─ Algebra (2/5 chapters)        │
│   ├ ◉ Linear Equations  100%   │
│   ├ ◉ Quadratic Equations 60%  │
│   ├ ○ Polynomials       0%     │
│   └ ...                         │
└──────────────────────────────────┘
```

States: loading, empty (no syllabus published — common since 14/15 Syllabus controllers unrouted).

### 5. API Contracts

#### `GET /api/mobile/v1/syllabus/progress/{subject_id}`
- **Status:** NEW. Module: Syllabus.
- **Response 200:** tree with progress.

### 6. Data Model
`cache_syllabus_progress` keyed by subject.

### 7. Offline Behavior
Read-only cached.

### 8. Push Notifications
None.

### 9. Permissions & Security
- Student endpoint scoped to their `(class_section, subject)` enrolment.
- 14/15 Syllabus controllers currently unrouted — surfacing endpoint requires route registration.

### 10. Non-Functional Requirements
- Cached < 300 ms.
- Localization: `f031.label.{covered,inprogress,notstarted}`.

### 11. Acceptance Criteria
- **AC-031.1** Subject not enrolled → 403.
- **AC-031.2** Empty syllabus → friendly empty state (no error).

### 12. Dependencies
- F-030 (entry from period card).

### 13. Out of Scope
- Editing syllabus, marking own coverage — web-only / teacher-only.

---

## F-032: Lesson Plan Viewer (Teacher, P1)

### 1. Overview
Teacher sees daily / weekly lesson plans. Per period: lesson title, learning objectives, attached resources, links to related quizzes / homework.

### 2. User Stories
- **US-032.1** *As a teacher, I want today's lesson plan in 1 tap, so I'm not flipping printouts.*
- **US-032.2** *As a class teacher, I want the whole class's lesson plans across subjects (read-only) for parent meetings.*

### 3. Functional Requirements
- **FR-032.1** Plan-per-period payload includes `objectives[]`, `resources[]` (file URLs), `linked_homework_ids`, `linked_quiz_ids`.
- **FR-032.2** Resource files use signed URLs (BG-33).
- **FR-032.3** Cached for current term offline.

### 4. Screen Specifications
Day list → tap period → plan detail.

### 5. API Contracts

#### `GET /api/mobile/v1/syllabus/lesson-plans?date=YYYY-MM-DD`
- **Status:** NEW. Module: Syllabus.
- **Response 200:** `{ data:{ date, periods:[ {period_id, plan:{...}} ] }}`.

### 6. Data Model
`cache_lesson_plans` per date + per-teacher.

### 7. Offline Behavior
Term-cached.

### 8. Push Notifications
None.

### 9. Permissions & Security
- Teacher-scoped only.
- Resource downloads via signed URLs (no IDOR on file access).

### 10. Non-Functional Requirements
- < 1 s p50 (cached).
- Localization: `f032.section.*`.

### 11. Acceptance Criteria
- **AC-032.1** Periods without a published plan show "Plan pending".
- **AC-032.2** Resource link works offline if pre-downloaded.

### 12. Dependencies
- F-012. BG-33 signed URLs.

### 13. Out of Scope
- Plan authoring / editing — web-only.

---

> End Batch 03. Continue to `02_mobile_srs_batch_04.md` (Homework).
