# ACD — Academics Management
## Module Requirement Document V2
**Version:** 2.0 | **Date:** 2026-03-26 | **Status:** Draft | **Mode:** RBS_ONLY
**Module Code:** ACD | **Table Prefix:** `acd_` | **Scope:** Tenant
**RBS Reference:** Module H — Academics & Curriculum (v2 spec lines 1708–1741)

---

## 1. Executive Summary

The Academics module (ACD) is the central coordination layer for all planned academic activity in Prime-AI. It manages the organisational superstructure of daily schooling: who teaches what, when planned learning activities happen, how co-curricular life is structured, and how teachers plan, log, and track lesson delivery.

V2 significantly expands V1 with seven new capability areas: Teaching Diary (daily lesson log per period), Class Diary (visible to parents), Bloom's Taxonomy tagging on lesson plans (NEP 2020 compliance), Remedial Class scheduling triggered by PAN module risk flags, Study Material distribution linked to SLB syllabus topics and feeding LXP, Academic Alert Engine (syllabus coverage and attendance-performance correlations), and timetable-slot binding for lesson plans.

**Implementation Statistics (Greenfield — all 📐 Proposed):**
- Controllers: 0 | Models: 0 | Services: 0 | FormRequests: 0 | Tests: 0
- Completion: 0%

---

## 2. Module Overview

### 2.1 Business Purpose

The Academics module provides ten interconnected capability areas:

1. **Academic Calendar** — Single source of truth for events, holidays, exam windows, and special days consumed by ATT, EXM, and TT modules.
2. **Teacher & Subject Assignment** — Formal recording of which teacher is assigned to which class-section-subject per academic session; drives TT generator and gates LMS access.
3. **Lesson Planning** — Structured weekly lesson plans submitted by teachers, reviewed by HoDs, with Bloom's taxonomy tagging and SLB topic linkage.
4. **Teaching Diary** — Daily per-period log of what was actually taught; feeds syllabus coverage tracking and parent-facing class diary.
5. **Class Diary** — Daily activities record visible to parents and students on portal; aggregates teaching diary entries and school announcements.
6. **Teacher Workload Management** — Period load calculation against policy limits; over/under capacity alerts.
7. **Skill & Competency Framework** — NEP 2020-aligned skill categories, per-student per-term assessments, delta tracking.
8. **Co-Curricular Activity (CCA) Management** — Sports, arts, clubs, NSS/NCC: enrollment, attendance, achievements, transcript generation.
9. **Remedial Class Management** — Scheduling and tracking of catch-up sessions for at-risk students identified by PAN module.
10. **Study Material Distribution** — Structured material upload linked to SLB topics, delivery to class-sections, feed into LXP content library.

### 2.2 Feature Summary

| Feature | V1 | V2 |
|---------|----|----|
| Academic Calendar & Event Management | 📐 | 📐 |
| Holiday Management with NTF alerts | 📐 | 📐 |
| Academic Session Management | 📐 | 📐 |
| Class Teacher Assignment (effective-date versioning) | 📐 | 📐 |
| Subject Teacher Assignment | 📐 | 📐 |
| Curriculum / Subject-Class Mapping | 📐 | 📐 |
| Elective Subject Student Enrollment | 📐 | 📐 |
| Lesson Plan Creation (DRAFT→SUBMIT→APPROVE) | 📐 | 📐 |
| Lesson Plan Bloom's Taxonomy Tagging | — | 🆕 📐 |
| Lesson Plan → SLB Topic Linkage | — | 🆕 📐 |
| Teaching Diary (daily period log) | — | 🆕 📐 |
| Class Diary (parent-visible daily record) | — | 🆕 📐 |
| Digital Content Upload & Library | 📐 | 📐 |
| Study Material Distribution (SLB-linked, LXP-fed) | — | 🆕 📐 |
| Teacher Workload Calculation & Reports | 📐 | 📐 |
| Skill Framework (categories, skills, levels) | 📐 | 📐 |
| Student Skill Assessment & Delta Tracking | 📐 | 📐 |
| CCA Activity Master | 📐 | 📐 |
| CCA Student Enrollment & Attendance | 📐 | 📐 |
| CCA Achievements & Transcript PDF | 📐 | 📐 |
| Parent-Teacher Meeting Schedule & Booking | 📐 | 📐 |
| Remedial Class Scheduling (PAN-triggered) | — | 🆕 📐 |
| Academic Alert Engine | — | 🆕 📐 |
| Academic Progress Dashboard (Principal/HoD) | 📐 | 📐 |

### 2.3 Menu Path

```
Tenant Dashboard > Academics
├── Academic Calendar
│   ├── Calendar View
│   ├── Event Management
│   └── Holiday Management
├── Assignments
│   ├── Class Teacher Assignment
│   ├── Subject Teacher Assignment
│   ├── Curriculum Mapping
│   └── Teacher Workload
├── Lesson Planning
│   ├── My Lesson Plans       (Teacher)
│   ├── All Lesson Plans      (Admin / HoD)
│   └── Teaching Diary
├── Class Diary               (Admin / Class Teacher)
├── Study Materials
│   ├── Material Library
│   └── Distribute Materials
├── Skills & Competencies
│   ├── Skill Framework
│   ├── Skill Assessments
│   └── Skill Reports
├── Co-Curricular
│   ├── Activity Master
│   ├── Student Enrollment
│   ├── CCA Attendance
│   ├── Achievements & Awards
│   └── CCA Transcript
├── Remedial Classes
│   ├── Remedial Schedule
│   └── Remedial Attendance
├── Parent-Teacher Meetings
│   ├── PTM Schedule
│   └── PTM Bookings
└── Academic Alerts
```

### 2.4 Architecture

```
[School Admin / Principal]
    → Manages academic calendar, sessions, curriculum maps
    → Views workload dashboards and academic alerts
    → Approves escalated lesson plans

[Department Head (HoD)]
    → Approves/revises lesson plans in own department
    → Views department-level syllabus coverage & workload

[Subject Teacher]
    → Creates lesson plans (linked to SLB topics + Bloom's levels)
    → Fills teaching diary each day after class
    → Uploads study materials for assigned class-sections

[Class Teacher]
    → Manages class diary entries
    → Schedules and logs remedial sessions for at-risk students

[ACD Module — Outbound Events]
    → Provides working-day calendar to ATT, EXM, TT modules
    → Provides subject-teacher map to TT generator, LMS, EXM
    → Teaching diary entries feed SLB syllabus coverage tracker
    → Study materials feed LXP content library
    → Remedial schedule feeds ATT module (extra attendance sessions)
    → Academic alerts → NTF module for in-app/SMS dispatch

[Student / Parent Portal]
    → Views academic calendar & class diary
    → Books PTM slots
    → Downloads CCA transcript
    → Accesses distributed study materials
```

---

## 3. Stakeholders & Roles

| Actor | Role | Key ACD Permissions |
|-------|------|-------------------|
| School Admin | Full academics management | Full CRUD on all ACD features |
| Principal | Strategic oversight; approves escalated content | Approve all; read reports; configure alerts |
| Department Head (HoD) | Manages own department's lesson plans and workload | CRUD own dept lesson plans; view workload; approve plans |
| Class Teacher | Homeroom management; class diary; remedial scheduling | CRUD class diary; manage remedial for own class |
| Subject Teacher | Lesson planning; teaching diary; study materials; CCA | CRUD own plans, diary, materials; CCA coordinator |
| CCA Coordinator | Manages a specific CCA activity | CRUD CCA sessions, attendance, achievements for own activity |
| Student | Read-own academic content | Read class diary, study materials, own skill report, CCA record |
| Parent/Guardian | Track child's academics; book PTM | Read class diary, calendar; book PTM; download CCA transcript |
| System (automated) | Alerts, event dispatch, coverage calculation | System-level reads; queue jobs; event dispatch |

---

## 4. Functional Requirements

### FR-ACD-001: Academic Calendar Management 📐

**RBS Ref:** H.H4.1, H.H4.2 | **Priority:** P0 (blocks ATT, TT, EXM)

**REQ-ACD-001.1 — Academic Calendar Creation**
- Admin creates one or more calendars per session: `calendar_name`, `academic_session_id`, `description`.
- Exactly one calendar per session is `is_primary = 1` (enforced via generated-column UNIQUE constraint).
- Published calendars are immutable except for additions; deletions require a soft-delete with mandatory reason in `sys_activity_logs`.

**REQ-ACD-001.2 — Calendar Event Management**
- Events: `event_name`, `event_type` (holiday / exam_window / sports / cultural / ptm / foundation_day / national_holiday / half_day / other), `from_date`, `to_date`, `description`, `is_working_day`, `is_half_day`, `is_all_day`, `is_visible_to_portal`, `colour_code`.
- Multi-day events supported (`from_date ≠ to_date`).
- Publishing with `notify_on_publish = 1` fires `CalendarEventPublished` → NTF module.

**REQ-ACD-001.3 — Holiday Management**
- Holidays: `event_type = 'holiday'`, `is_working_day = 0`. Admin marks full-day or half-day.
- On save: `HolidayAdded` event dispatched → NTF sends SMS/email to all parents + staff.
- ATT module consumes `acd_calendar_events WHERE is_working_day = 0` as its non-counting-day list.

**REQ-ACD-001.4 — Session Management**
- Admin creates sessions: `name`, `short_name`, `start_date`, `end_date`. One active session at a time.
- Closed session (`is_active = 0`) is read-only — no lesson plans, diary entries, or assessments can be created against it.

**Acceptance Criteria:**
- Holiday "Holi 17-Mar-2026" saved → ATT March denominator decrements by 1 for all students.
- Event published with portal flag → parents see it within 1 hour on portal.

---

### FR-ACD-002: Teacher & Subject Assignment 📐

**RBS Ref:** H.H1.2, H.H5.1

**REQ-ACD-002.1 — Class Teacher Assignment**
- One primary class teacher per class-section per session. Assistant/co-teacher optional (`is_primary = 0`).
- Versioned via `effective_from` / `effective_to`; only one active primary per section at any time.
- On assignment change: `sch_class_section_jnt.class_teacher_id` updated automatically.

**REQ-ACD-002.2 — Subject Teacher Assignment**
- Maps `class_section_id` + `subject_id` + `teacher_profile_id` + `academic_session_id`.
- One primary + optional co-teacher per class-section-subject combination.
- Authoritative source for: ATT subject marking rights, lesson plan creation rights, TT default teacher, LMS/EXM teacher access.
- Mid-session reassignment: set `effective_to` on old record, create new with `effective_from`.
- On any create/update/delete: `RecalculateWorkloadJob` dispatched asynchronously.

**REQ-ACD-002.3 — Curriculum / Subject-Class Mapping**
- Maps `class_id` + `subject_id` + `academic_session_id` with `is_core`, `subject_type_id`, `max_enrollment` / `min_enrollment` (for electives).
- Subject teacher assignment requires a matching curriculum mapping (FK enforced).

**REQ-ACD-002.4 — Student Elective Enrollment**
- Student enrolled in elective subject via `acd_student_elective_jnt` (references `acd_class_subject_jnt` where `is_core = 0`).
- System checks `max_enrollment` before allowing new enrollment.

---

### FR-ACD-003: Lesson Plan Management 📐

**RBS Ref:** H.H2.1, H.H2.2

**REQ-ACD-003.1 — Lesson Plan Creation**
- Scope: `teacher_profile_id`, `class_section_id`, `subject_id`, `academic_session_id`, `week_number` (1–52).
- Fields: `title`, `topic`, `learning_objectives`, `teaching_methods_json`, `resources_json`, `expected_outcomes`, `assessment_plan`, `remarks`.
- One plan per teacher-class-section-subject-week combination enforced via UNIQUE constraint.

**REQ-ACD-003.2 — SLB Topic Linkage 🆕**
- Teacher selects one or more SLB syllabus topics (`slb_lesson_id` / `slb_topic_id`) covered in this plan via `acd_lesson_plan_slb_jnt`.
- On lesson plan APPROVED, the SLB module's coverage tracker is notified: those topics are marked as "planned" for that class-section.
- On teaching diary entry (FR-ACD-004), those same topics are marked "taught".

**REQ-ACD-003.3 — Bloom's Taxonomy Tagging 🆕**
- Each lesson plan carries a `blooms_levels_json` array: one or more of [Remember, Understand, Apply, Analyse, Evaluate, Create].
- Admin/HoD may enforce a school policy: lesson plan must target at least two Bloom's levels (configurable via `sys_settings`).
- Bloom's distribution report shows per-teacher and per-department spread across taxonomy levels.

**REQ-ACD-003.4 — Lesson Plan Approval Workflow**
- Status transitions: `draft` → `submitted` → `approved` or `revision_requested` → `approved`.
- On `submitted`: HoD receives in-app notification.
- HoD approves or requests revision with comments. Only teacher can edit when in `draft` or `revision_requested`.
- On `approved`: `LessonPlanPublished` event fired; SLB coverage updated; lesson plan visible to students/parents on portal if `notify_on_publish = 1`.

**REQ-ACD-003.5 — Progress & Completion Tracking**
- `completion_percentage` (0–100) updated by teacher at week end; `incomplete_remarks` mandatory if < 100%.
- Admin dashboard shows lesson plan completion rate per department/class/week.

**REQ-ACD-003.6 — Digital Content Attachment**
- Teachers attach digital content via `acd_lesson_plan_content_jnt` (FK → `acd_digital_contents`).
- Attached content appears in the Class Diary for that week and is pushed to LXP content library.

---

### FR-ACD-004: Teaching Diary 🆕 📐

**REQ-ACD-004.1 — Daily Period Log**
- After each period, the subject teacher records a teaching diary entry: `class_section_id`, `subject_id`, `teacher_profile_id`, `diary_date`, `period_number`, `timetable_slot_id` (FK → tt slot, nullable), `topics_covered`, `methodology_used`, `homework_given`, `remarks`.
- One entry per teacher-class-period-date (UNIQUE constraint). Teacher may update until midnight of the same day; after that, locked (admin override required).

**REQ-ACD-004.2 — Timetable Slot Binding**
- When a timetable is active, the teaching diary form pre-fills `class_section_id`, `subject_id`, `period_number` from the timetable slot for that day.
- Teacher picks from their timetable slots for the current day — no free-form period number entry needed.

**REQ-ACD-004.3 — SLB Syllabus Coverage Update**
- On diary entry save, the system identifies linked SLB topics (from the approved lesson plan for that week) and marks them as `taught` in the SLB coverage tracker.
- If no lesson plan exists for the week, teacher can still tag topics manually from SLB topic picker.

**REQ-ACD-004.4 — Teaching Diary Reports**
- Per-teacher diary completeness report: % of periods logged per week.
- Unfilled diary alert: if teacher has not filled diary for a period by end of next day, system flags it.
- Admin can view all diary entries for a class-section on a given date.

---

### FR-ACD-005: Class Diary 🆕 📐

**REQ-ACD-005.1 — Class Diary Record**
- Class teacher (or admin) manages the class diary: a daily record for a class-section combining period-wise teaching summaries, announcements, and homework.
- `acd_class_diary` stores: `class_section_id`, `diary_date`, `general_announcement`, `homework_summary`, `behaviour_notes`, `is_published`, `published_at`.

**REQ-ACD-005.2 — Auto-Population from Teaching Diary**
- System auto-aggregates subject-wise teaching diary entries for the class on that date into the class diary `teaching_summary_json` column.
- Class teacher reviews and optionally adds a general announcement or behavioural note before publishing.

**REQ-ACD-005.3 — Portal Visibility**
- When class teacher publishes (`is_published = 1`), the diary entry becomes visible to students and parents in the portal.
- Parents are notified via NTF in-app notification (`CLASS_DIARY_PUBLISHED`).
- Portal shows diary in reverse-chronological order; students see homework summary prominently.

**REQ-ACD-005.4 — Homework Summary**
- Homework given per subject (from teaching diary entries) is automatically included in class diary.
- Parents see: Subject | Homework Description | Due Date | Teacher Name.

---

### FR-ACD-006: Study Material Distribution 🆕 📐

**REQ-ACD-006.1 — Digital Content Library**
- Teachers upload study materials: PDF, Video (file or URL), SCORM, presentation, image, audio, links.
- Metadata: `title`, `content_type`, `subject_id`, `class_id`, `tags_json`, `available_from`, `available_to`, `slb_topic_id` (optional FK → SLB topic).
- Content linked to SLB topic: when student accesses SLB topic page, linked materials appear automatically.

**REQ-ACD-006.2 — Distribution to Class-Sections**
- Teacher distributes a material to one or more class-sections via `acd_material_distribution`: `digital_content_id`, `class_section_id`, `distributed_by`, `distributed_at`, `available_from`, `available_to`, `is_mandatory`.
- Students in those sections see the material in their portal "Study Materials" feed.

**REQ-ACD-006.3 — LXP Integration**
- Materials marked `push_to_lxp = 1` are automatically added to the LXP content library for the relevant subject/class.
- LXP module consumes `acd_digital_contents` as its content source; no separate upload needed.

**REQ-ACD-006.4 — Material Access Tracking**
- `acd_material_views`: `digital_content_id`, `student_id`, `viewed_at`, `duration_seconds` (for video).
- Teacher and admin can see per-material view counts and per-student access logs.

---

### FR-ACD-007: Teacher Workload Management 📐

**RBS Ref:** H.H5.1, H.H5.2

**REQ-ACD-007.1 — Workload Calculation**
- Async `RecalculateWorkloadJob` aggregates active subject-teacher assignments per session: `total_periods_weekly` = sum of `periods_per_week` across all assignments.
- Stores in `acd_teacher_workloads` (upsert per teacher-session). Sets `is_over_capacity = 1` if total exceeds `sch_teacher_profile.max_allocated_periods_weekly`.

**REQ-ACD-007.2 — Policy Enforcement**
- Warning (not hard block) when new assignment would push teacher above max. Admin must acknowledge before save.
- `WORKLOAD_OVER_CAPACITY` notification dispatched to HR Admin + Department HoD on over-capacity.

**REQ-ACD-007.3 — Workload Reports**
- Subject-wise: teacher, periods/week, class count.
- Department summary: average load, over/under flags.
- Teacher comparison: side-by-side across department.

---

### FR-ACD-008: Skill & Competency Framework 📐

**RBS Ref:** H.H6.1, H.H6.2

**REQ-ACD-008.1 — Skill Framework**
- Admin defines skill categories (cognitive / creative / physical / social / emotional / vocational) and individual skills with `levels_json` (e.g., ["Beginning","Developing","Proficient","Advanced"]).
- Skills mapped to subjects via `acd_skill_subject_jnt`.

**REQ-ACD-008.2 — Skill Assessment**
- Teacher records per-student-per-skill-per-term ratings. Upsert pattern; previous rating logged to `sys_activity_logs`.
- System computes term-over-term delta for each student-skill pair.

**REQ-ACD-008.3 — Skill Reports**
- Individual radar chart + tabular term comparison.
- Class distribution of ratings per skill.
- Declining skills identification report.
- Skill data included in EXM report card.

---

### FR-ACD-009: Co-Curricular Activity (CCA) Management 📐

**RBS Ref:** H.H7.1, H.H7.2

**REQ-ACD-009.1 — Activity Master**
- Admin creates CCA activities: `name`, `code`, `category` (sports/arts/club/nss/ncc/cultural/competition/academic_club/other), `coordinator_id`, `schedule_json`, `max_enrollment`, `is_competitive`.

**REQ-ACD-009.2 — Student Enrollment**
- Coordinator enrolls students with `role` (participant/captain/secretary/president/vice_captain/coordinator).
- School-configurable max activities per student (default 3); warning on exceeding.

**REQ-ACD-009.3 — CCA Attendance & Performance**
- Coordinator creates CCA sessions; marks attendance (present/absent/excused) per session.
- Performance ratings (1–10) recorded per student per session.

**REQ-ACD-009.4 — Achievements & Awards**
- Record: `achievement_type`, `title`, `position`, `level` (inter_house → international), `certificate_media_id`.
- District-level and above: `CCA_ACHIEVEMENT_HIGH_LEVEL` notification to Principal + class teacher.

**REQ-ACD-009.5 — CCA Transcript PDF**
- Generated via DomPDF with school letterhead. Contents: student details, session, activities with attendance %, performance ratings, achievements.
- Bulk print for all students in an activity.

---

### FR-ACD-010: Remedial Class Management 🆕 📐

**REQ-ACD-010.1 — Remedial Class Scheduling**
- Admin or class teacher creates remedial sessions for students identified as at-risk: `class_section_id`, `subject_id`, `teacher_profile_id`, `scheduled_date`, `start_time`, `end_time`, `venue`, `topic_focus`, `remedial_type` (academic/behavioural/skill).
- Students added to a remedial session via `acd_remedial_student_jnt`: `remedial_session_id`, `student_id`, `referred_by`, `referral_reason`, `pan_alert_id` (nullable FK to PAN alert).

**REQ-ACD-010.2 — PAN Module Integration**
- When PAN (Predictive Analytics) module generates a risk alert for a student in a subject, it fires `StudentAtRisk` event.
- ACD listens: creates a suggested (draft) remedial session for that student-subject and notifies the class teacher.
- Teacher can accept (confirm) or reject the suggestion.

**REQ-ACD-010.3 — Remedial Attendance**
- Teacher marks attendance for each remedial session via `acd_remedial_attendance`: `remedial_session_id`, `student_id`, `status` (present/absent/excused).
- Remedial attendance is separate from regular ATT module attendance but recorded in ACD.

**REQ-ACD-010.4 — Remedial Outcome Tracking**
- After session: teacher records `outcome_notes` and `improvement_observed` (yes/no) on the session record.
- Per-student remedial history report available to class teacher and admin.

---

### FR-ACD-011: Academic Alert Engine 🆕 📐

**REQ-ACD-011.1 — Syllabus Coverage Alerts**
- System calculates syllabus coverage % per class-section-subject each week (topics taught / total topics in SLB).
- If coverage falls below a configurable threshold (default 70% at mid-session), alert generated:
  - Type: `SYLLABUS_COVERAGE_LOW`
  - Recipients: Subject teacher + HoD + (if critical) Principal
  - Alert shows: current %, expected % at this point in session, topics not yet covered.

**REQ-ACD-011.2 — Attendance-Performance Correlation Alerts**
- ACD reads ATT module's `att_student_analytics.attendance_percentage` and EXM module's latest marks.
- If a student's attendance is below 75% AND their last exam marks are below 40%, alert `ATTENDANCE_PERFORMANCE_RISK` generated.
- Alert routed to class teacher + counsellor (if assigned).

**REQ-ACD-011.3 — Lesson Plan Compliance Alerts**
- If teacher has not submitted a lesson plan for the current week by a configurable deadline (e.g., Friday prior), alert `LESSON_PLAN_MISSING` sent to teacher and HoD.
- Teaching diary unfilled for 2+ consecutive periods: alert `DIARY_NOT_FILLED` to teacher.

**REQ-ACD-011.4 — Alert Dashboard**
- Principal/Admin sees a consolidated alert dashboard: active alerts by type, severity (info/warning/critical), resolved vs unresolved.
- Alerts resolved manually by acknowledging or automatically when the triggering condition clears (e.g., coverage % rises above threshold).

---

### FR-ACD-012: Parent-Teacher Meeting (PTM) Management 📐

**REQ-ACD-012.1 — PTM Schedule**
- Admin creates PTM: `title`, `academic_session_id`, `scheduled_date`, `from_time`, `to_time`, `slot_duration_minutes`, `applicable_classes_json`.
- Multiple PTMs per session supported.

**REQ-ACD-012.2 — Teacher Slot Generation**
- System auto-generates slots for each teacher in applicable classes. PTM day ÷ slot duration = slots per teacher.
- Admin can adjust teacher availability windows per PTM before publishing.
- `acd_ptm_teacher_slots`: `ptm_schedule_id`, `teacher_profile_id`, `class_section_id`, `slot_date`, `slot_time`, `status`.

**REQ-ACD-012.3 — Parent Booking**
- Parents book via portal: one slot per student-teacher per PTM. Concurrent bookings use `SELECT FOR UPDATE` to prevent double-booking.
- On booking: confirmation SMS + in-app notification sent.
- 24-hour reminder notification fired automatically.

**REQ-ACD-012.4 — PTM Completion**
- Teacher marks slot as `attended` or `no_show`. Private meeting notes stored (visible to teacher + admin only).
- Post-PTM summary: attendance rate, no-show count.

---

### FR-ACD-013: Academic Progress Dashboard 📐

**REQ-ACD-013.1 — Principal / HoD Dashboard**
- Aggregated view: lesson plan submission rate (%), teaching diary fill rate (%), syllabus coverage heatmap, active alerts count.
- Filterable by class, department, week range.

**REQ-ACD-013.2 — Student Academic Progress**
- Per-student view for admin and class teacher: lesson plan coverage by subject, skill assessment ratings, CCA summary, attendance correlation, remedial sessions attended.

**REQ-ACD-013.3 — Report Exports**
- Department lesson plan completion: PDF + Excel.
- CCA participation: activity-wise enrollment, attendance %.
- Skill assessment summary: class-level distribution.
- Bloom's taxonomy distribution: per teacher, per department.

---

## 5. Data Model

All tables are `📐 Proposed`. Prefix: `acd_`.

### 5.1 `acd_academic_calendars`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK→glb_academic_sessions | |
| org_session_id | INT UNSIGNED | NULL, FK→sch_org_academic_sessions_jnt | School-level session link |
| name | VARCHAR(100) | NOT NULL | e.g., 'Academic Calendar 2025-26' |
| description | TEXT | NULL | |
| is_primary | TINYINT(1) | NOT NULL DEFAULT 0 | |
| primary_flag | INT UNSIGNED | GENERATED STORED | academic_session_id when is_primary=1, else NULL |
| status | ENUM('draft','published','archived') | NOT NULL DEFAULT 'draft' | |
| published_at | TIMESTAMP | NULL | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |
| **UNIQUE** | (primary_flag) | | One primary per session |

### 5.2 `acd_calendar_events`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| calendar_id | INT UNSIGNED | NOT NULL, FK→acd_academic_calendars | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK→glb_academic_sessions | Denormalized |
| event_name | VARCHAR(150) | NOT NULL | |
| event_type | ENUM('holiday','exam_window','sports','cultural','ptm','foundation_day','national_holiday','half_day','other') | NOT NULL | |
| from_date | DATE | NOT NULL | |
| to_date | DATE | NOT NULL | Same as from_date for single-day |
| from_time | TIME | NULL | For timed events |
| to_time | TIME | NULL | |
| description | TEXT | NULL | |
| is_working_day | TINYINT(1) | NOT NULL DEFAULT 1 | 0 → ATT denominator excluded |
| is_half_day | TINYINT(1) | NOT NULL DEFAULT 0 | |
| is_all_day | TINYINT(1) | NOT NULL DEFAULT 1 | |
| is_visible_to_portal | TINYINT(1) | NOT NULL DEFAULT 1 | |
| notify_on_publish | TINYINT(1) | NOT NULL DEFAULT 0 | Trigger NTF event |
| colour_code | CHAR(7) | NULL | Hex colour for UI |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |

### 5.3 `acd_class_teacher_jnt`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| class_section_id | INT UNSIGNED | NOT NULL, FK→sch_class_section_jnt | |
| teacher_profile_id | INT UNSIGNED | NOT NULL, FK→sch_teacher_profile | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK→glb_academic_sessions | |
| is_primary | TINYINT(1) | NOT NULL DEFAULT 1 | 1=class teacher, 0=assistant |
| effective_from | DATE | NOT NULL | |
| effective_to | DATE | NULL | NULL = currently active |
| active_flag | INT UNSIGNED | GENERATED STORED | Hashed key when effective_to IS NULL + is_primary=1 |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |
| **UNIQUE** | (active_flag) | | One active primary per section |

### 5.4 `acd_subject_teacher_jnt`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| class_section_id | INT UNSIGNED | NOT NULL, FK→sch_class_section_jnt | |
| subject_id | INT UNSIGNED | NOT NULL, FK→sch_subjects | |
| teacher_profile_id | INT UNSIGNED | NOT NULL, FK→sch_teacher_profile | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK→glb_academic_sessions | |
| is_primary | TINYINT(1) | NOT NULL DEFAULT 1 | 1=primary, 0=co-teacher |
| effective_from | DATE | NOT NULL | |
| effective_to | DATE | NULL | |
| periods_per_week | TINYINT UNSIGNED | NULL | For workload calculation |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |

### 5.5 `acd_class_subject_jnt`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| class_id | INT UNSIGNED | NOT NULL, FK→sch_classes | |
| subject_id | INT UNSIGNED | NOT NULL, FK→sch_subjects | |
| subject_type_id | INT UNSIGNED | NULL, FK→sch_subject_types | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK→glb_academic_sessions | |
| is_core | TINYINT(1) | NOT NULL DEFAULT 1 | 0 = elective |
| max_enrollment | SMALLINT UNSIGNED | NULL | Electives only |
| min_enrollment | SMALLINT UNSIGNED | NULL | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |
| **UNIQUE** | (class_id, subject_id, academic_session_id) | | |

### 5.6 `acd_student_elective_jnt`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| student_id | INT UNSIGNED | NOT NULL, FK→std_students | |
| class_subject_id | INT UNSIGNED | NOT NULL, FK→acd_class_subject_jnt | Elective subjects only |
| academic_session_id | INT UNSIGNED | NOT NULL, FK→glb_academic_sessions | |
| enrolled_date | DATE | NOT NULL | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| **UNIQUE** | (student_id, class_subject_id, academic_session_id) | | |

### 5.7 `acd_lesson_plans`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | |
| teacher_profile_id | INT UNSIGNED | NOT NULL, FK→sch_teacher_profile | |
| class_section_id | INT UNSIGNED | NOT NULL, FK→sch_class_section_jnt | |
| subject_id | INT UNSIGNED | NOT NULL, FK→sch_subjects | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK→glb_academic_sessions | |
| week_number | TINYINT UNSIGNED | NOT NULL | 1–52 |
| plan_week_start_date | DATE | NULL | Monday of the plan week |
| title | VARCHAR(150) | NOT NULL | |
| topic | VARCHAR(255) | NOT NULL | |
| learning_objectives | TEXT | NULL | |
| teaching_methods_json | JSON | NULL | |
| resources_json | JSON | NULL | |
| expected_outcomes | TEXT | NULL | |
| assessment_plan | TEXT | NULL | |
| blooms_levels_json | JSON | NULL | 🆕 e.g., ["Remember","Apply","Analyse"] |
| remarks | TEXT | NULL | |
| status | ENUM('draft','submitted','revision_requested','approved') | NOT NULL DEFAULT 'draft' | |
| submitted_at | TIMESTAMP | NULL | |
| reviewed_by | INT UNSIGNED | NULL, FK→sch_teacher_profile | |
| reviewed_at | TIMESTAMP | NULL | |
| review_remarks | TEXT | NULL | |
| approved_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| approved_at | TIMESTAMP | NULL | |
| completion_percentage | TINYINT UNSIGNED | NOT NULL DEFAULT 0 | 0–100 |
| incomplete_remarks | TEXT | NULL | |
| notify_on_publish | TINYINT(1) | NOT NULL DEFAULT 1 | Push to portal on approve |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |
| **UNIQUE** | (teacher_profile_id, class_section_id, subject_id, academic_session_id, week_number) | | |

### 5.8 `acd_lesson_plan_slb_jnt` 🆕

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| lesson_plan_id | BIGINT UNSIGNED | NOT NULL, FK→acd_lesson_plans | |
| slb_topic_id | INT UNSIGNED | NOT NULL, FK→slb_topics | |
| slb_lesson_id | INT UNSIGNED | NULL, FK→slb_lessons | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| **UNIQUE** | (lesson_plan_id, slb_topic_id) | | |

### 5.9 `acd_teaching_diary` 🆕

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | |
| teacher_profile_id | INT UNSIGNED | NOT NULL, FK→sch_teacher_profile | |
| class_section_id | INT UNSIGNED | NOT NULL, FK→sch_class_section_jnt | |
| subject_id | INT UNSIGNED | NOT NULL, FK→sch_subjects | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK→glb_academic_sessions | |
| diary_date | DATE | NOT NULL | |
| period_number | TINYINT UNSIGNED | NOT NULL | |
| timetable_slot_id | INT UNSIGNED | NULL, FK→tt timetable slot | |
| topics_covered | TEXT | NOT NULL | What was actually taught |
| methodology_used | VARCHAR(255) | NULL | e.g., "Lecture, Q&A" |
| homework_given | TEXT | NULL | |
| homework_due_date | DATE | NULL | |
| remarks | TEXT | NULL | |
| is_locked | TINYINT(1) | NOT NULL DEFAULT 0 | Locked after midnight of diary_date |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| **UNIQUE** | (teacher_profile_id, class_section_id, subject_id, diary_date, period_number) | | |

### 5.10 `acd_class_diary` 🆕

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | |
| class_section_id | INT UNSIGNED | NOT NULL, FK→sch_class_section_jnt | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK→glb_academic_sessions | |
| diary_date | DATE | NOT NULL | |
| general_announcement | TEXT | NULL | Class teacher's note |
| teaching_summary_json | JSON | NULL | Auto-aggregated from teaching diary |
| homework_summary_json | JSON | NULL | Per-subject homework list |
| behaviour_notes | TEXT | NULL | Private: admin + class teacher only |
| is_published | TINYINT(1) | NOT NULL DEFAULT 0 | 1 = visible to parents/students |
| published_at | TIMESTAMP | NULL | |
| published_by | INT UNSIGNED | NULL, FK→sch_teacher_profile | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| **UNIQUE** | (class_section_id, diary_date) | | |

### 5.11 `acd_digital_contents`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | |
| title | VARCHAR(150) | NOT NULL | |
| content_type | ENUM('pdf','video_file','video_url','scorm','link','image','audio','presentation') | NOT NULL | |
| file_path | VARCHAR(500) | NULL | |
| url | VARCHAR(500) | NULL | |
| media_id | INT UNSIGNED | NULL, FK→sys_media | |
| description | TEXT | NULL | |
| subject_id | INT UNSIGNED | NULL, FK→sch_subjects | |
| class_id | INT UNSIGNED | NULL, FK→sch_classes | |
| slb_topic_id | INT UNSIGNED | NULL, FK→slb_topics | 🆕 SLB linkage |
| tags_json | JSON | NULL | |
| push_to_lxp | TINYINT(1) | NOT NULL DEFAULT 0 | 🆕 Feed to LXP library |
| uploaded_by | INT UNSIGNED | NOT NULL, FK→sch_teacher_profile | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK→glb_academic_sessions | |
| available_from | DATETIME | NULL | |
| available_to | DATETIME | NULL | |
| view_count | INT UNSIGNED | NOT NULL DEFAULT 0 | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |

### 5.12 `acd_material_distribution` 🆕

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| digital_content_id | BIGINT UNSIGNED | NOT NULL, FK→acd_digital_contents | |
| class_section_id | INT UNSIGNED | NOT NULL, FK→sch_class_section_jnt | |
| distributed_by | INT UNSIGNED | NOT NULL, FK→sch_teacher_profile | |
| distributed_at | TIMESTAMP | NOT NULL | |
| available_from | DATETIME | NULL | |
| available_to | DATETIME | NULL | |
| is_mandatory | TINYINT(1) | NOT NULL DEFAULT 0 | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| **UNIQUE** | (digital_content_id, class_section_id) | | |

### 5.13 `acd_material_views` 🆕

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | |
| digital_content_id | BIGINT UNSIGNED | NOT NULL, FK→acd_digital_contents | |
| student_id | INT UNSIGNED | NOT NULL, FK→std_students | |
| viewed_at | TIMESTAMP | NOT NULL | |
| duration_seconds | INT UNSIGNED | NULL | Video watch time |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |

### 5.14 `acd_lesson_plan_content_jnt`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| lesson_plan_id | BIGINT UNSIGNED | NOT NULL, FK→acd_lesson_plans | |
| digital_content_id | BIGINT UNSIGNED | NOT NULL, FK→acd_digital_contents | |
| sort_order | TINYINT UNSIGNED | NULL DEFAULT 1 | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| **UNIQUE** | (lesson_plan_id, digital_content_id) | | |

### 5.15 `acd_teacher_workloads`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| teacher_profile_id | INT UNSIGNED | NOT NULL, FK→sch_teacher_profile | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK→glb_academic_sessions | |
| total_classes_assigned | TINYINT UNSIGNED | NOT NULL DEFAULT 0 | |
| total_subjects_assigned | TINYINT UNSIGNED | NOT NULL DEFAULT 0 | |
| total_periods_weekly | TINYINT UNSIGNED | NOT NULL DEFAULT 0 | |
| subjects_list_json | JSON | NULL | |
| is_over_capacity | TINYINT(1) | NOT NULL DEFAULT 0 | |
| last_calculated_at | TIMESTAMP | NULL | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| **UNIQUE** | (teacher_profile_id, academic_session_id) | | |

### 5.16 `acd_skill_categories`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| name | VARCHAR(100) | NOT NULL | |
| code | VARCHAR(10) | NOT NULL, UNIQUE | |
| category_type | ENUM('cognitive','creative','physical','social','emotional','vocational','other') | NOT NULL | |
| description | TEXT | NULL | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |

### 5.17 `acd_skills`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| skill_category_id | INT UNSIGNED | NOT NULL, FK→acd_skill_categories | |
| skill_name | VARCHAR(100) | NOT NULL | |
| code | VARCHAR(10) | NOT NULL, UNIQUE | |
| descriptor | TEXT | NULL | |
| assessment_criteria | TEXT | NULL | |
| levels_json | JSON | NOT NULL | e.g., ["Beginning","Developing","Proficient","Advanced"] |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |

### 5.18 `acd_skill_subject_jnt`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| skill_id | INT UNSIGNED | NOT NULL, FK→acd_skills | |
| subject_id | INT UNSIGNED | NOT NULL, FK→sch_subjects | |
| is_primary_mapping | TINYINT(1) | NOT NULL DEFAULT 1 | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| **UNIQUE** | (skill_id, subject_id) | | |

### 5.19 `acd_skill_assessments`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | |
| student_id | INT UNSIGNED | NOT NULL, FK→std_students | |
| skill_id | INT UNSIGNED | NOT NULL, FK→acd_skills | |
| class_section_id | INT UNSIGNED | NOT NULL, FK→sch_class_section_jnt | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK→glb_academic_sessions | |
| term | TINYINT UNSIGNED | NOT NULL | 1, 2, or 3 |
| rating_level | TINYINT UNSIGNED | NOT NULL | Index into skill.levels_json (0-based) |
| rating_label | VARCHAR(50) | NULL | Denormalized label |
| notes | TEXT | NULL | |
| evidence_media_id | INT UNSIGNED | NULL, FK→sys_media | |
| assessed_by | INT UNSIGNED | NOT NULL, FK→sch_teacher_profile | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| **UNIQUE** | (student_id, skill_id, academic_session_id, term) | | |

### 5.20 `acd_cca_activities`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| name | VARCHAR(100) | NOT NULL | |
| code | VARCHAR(10) | NOT NULL, UNIQUE | |
| category | ENUM('sports','arts','club','nss','ncc','cultural','competition','academic_club','other') | NOT NULL | |
| description | TEXT | NULL | |
| coordinator_id | INT UNSIGNED | NOT NULL, FK→sch_teacher_profile | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK→glb_academic_sessions | |
| venue | VARCHAR(150) | NULL | |
| schedule_json | JSON | NULL | |
| max_enrollment | SMALLINT UNSIGNED | NULL | |
| is_competitive | TINYINT(1) | NOT NULL DEFAULT 0 | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |

### 5.21 `acd_student_cca_jnt`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| student_id | INT UNSIGNED | NOT NULL, FK→std_students | |
| activity_id | INT UNSIGNED | NOT NULL, FK→acd_cca_activities | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK→glb_academic_sessions | |
| role | ENUM('participant','captain','secretary','president','vice_captain','coordinator') | NOT NULL DEFAULT 'participant' | |
| joined_date | DATE | NOT NULL | |
| exit_date | DATE | NULL | |
| status | ENUM('active','completed','withdrawn') | NOT NULL DEFAULT 'active' | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| **UNIQUE** | (student_id, activity_id, academic_session_id) | | |

### 5.22 `acd_cca_sessions`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| activity_id | INT UNSIGNED | NOT NULL, FK→acd_cca_activities | |
| session_date | DATE | NOT NULL | |
| session_topic | VARCHAR(255) | NULL | |
| conducted_by | INT UNSIGNED | NOT NULL, FK→sch_teacher_profile | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |

### 5.23 `acd_cca_attendance`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | |
| cca_session_id | INT UNSIGNED | NOT NULL, FK→acd_cca_sessions | |
| student_id | INT UNSIGNED | NOT NULL, FK→std_students | |
| activity_id | INT UNSIGNED | NOT NULL, FK→acd_cca_activities | Denormalized |
| status | ENUM('present','absent','excused') | NOT NULL | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| **UNIQUE** | (cca_session_id, student_id) | | |

### 5.24 `acd_cca_achievements`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| student_id | INT UNSIGNED | NOT NULL, FK→std_students | |
| activity_id | INT UNSIGNED | NOT NULL, FK→acd_cca_activities | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK→glb_academic_sessions | |
| achievement_type | ENUM('award','position','certificate','selection','participation') | NOT NULL | |
| title | VARCHAR(200) | NOT NULL | |
| position | ENUM('1st','2nd','3rd','participation','runner_up','winner') | NULL | |
| level | ENUM('inter_house','inter_class','inter_school','district','zone','state','national','international') | NOT NULL | |
| achievement_date | DATE | NOT NULL | |
| certificate_media_id | INT UNSIGNED | NULL, FK→sys_media | |
| notes | TEXT | NULL | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |

### 5.25 `acd_remedial_sessions` 🆕

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| class_section_id | INT UNSIGNED | NOT NULL, FK→sch_class_section_jnt | |
| subject_id | INT UNSIGNED | NOT NULL, FK→sch_subjects | |
| teacher_profile_id | INT UNSIGNED | NOT NULL, FK→sch_teacher_profile | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK→glb_academic_sessions | |
| scheduled_date | DATE | NOT NULL | |
| start_time | TIME | NOT NULL | |
| end_time | TIME | NOT NULL | |
| venue | VARCHAR(150) | NULL | |
| topic_focus | TEXT | NULL | |
| remedial_type | ENUM('academic','behavioural','skill') | NOT NULL DEFAULT 'academic' | |
| status | ENUM('suggested','scheduled','completed','cancelled') | NOT NULL DEFAULT 'suggested' | |
| outcome_notes | TEXT | NULL | |
| improvement_observed | TINYINT(1) | NULL | 1=yes, 0=no |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |

### 5.26 `acd_remedial_student_jnt` 🆕

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| remedial_session_id | INT UNSIGNED | NOT NULL, FK→acd_remedial_sessions | |
| student_id | INT UNSIGNED | NOT NULL, FK→std_students | |
| referred_by | INT UNSIGNED | NULL, FK→sch_teacher_profile | |
| referral_reason | TEXT | NULL | |
| pan_alert_id | INT UNSIGNED | NULL | FK to PAN alert (loose reference) |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| **UNIQUE** | (remedial_session_id, student_id) | | |

### 5.27 `acd_remedial_attendance` 🆕

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| remedial_session_id | INT UNSIGNED | NOT NULL, FK→acd_remedial_sessions | |
| student_id | INT UNSIGNED | NOT NULL, FK→std_students | |
| status | ENUM('present','absent','excused') | NOT NULL | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| **UNIQUE** | (remedial_session_id, student_id) | | |

### 5.28 `acd_academic_alerts` 🆕

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | |
| alert_type | ENUM('SYLLABUS_COVERAGE_LOW','ATTENDANCE_PERFORMANCE_RISK','LESSON_PLAN_MISSING','DIARY_NOT_FILLED','WORKLOAD_OVER_CAPACITY','OTHER') | NOT NULL | |
| severity | ENUM('info','warning','critical') | NOT NULL DEFAULT 'warning' | |
| entity_type | VARCHAR(50) | NOT NULL | e.g., 'student', 'teacher', 'class_section' |
| entity_id | INT UNSIGNED | NOT NULL | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK→glb_academic_sessions | |
| subject_id | INT UNSIGNED | NULL, FK→sch_subjects | |
| alert_data_json | JSON | NULL | Context data for the alert |
| status | ENUM('active','acknowledged','resolved','dismissed') | NOT NULL DEFAULT 'active' | |
| resolved_at | TIMESTAMP | NULL | |
| resolved_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |

### 5.29 `acd_ptm_schedules`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK→glb_academic_sessions | |
| title | VARCHAR(150) | NOT NULL | |
| scheduled_date | DATE | NOT NULL | |
| from_time | TIME | NOT NULL | |
| to_time | TIME | NOT NULL | |
| slot_duration_minutes | TINYINT UNSIGNED | NOT NULL DEFAULT 10 | |
| applicable_classes_json | JSON | NULL | NULL = all |
| status | ENUM('draft','published','completed','cancelled') | NOT NULL DEFAULT 'draft' | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |

### 5.30 `acd_ptm_teacher_slots`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | |
| ptm_schedule_id | INT UNSIGNED | NOT NULL, FK→acd_ptm_schedules | |
| teacher_profile_id | INT UNSIGNED | NOT NULL, FK→sch_teacher_profile | |
| class_section_id | INT UNSIGNED | NOT NULL, FK→sch_class_section_jnt | |
| slot_date | DATE | NOT NULL | |
| slot_time | TIME | NOT NULL | |
| status | ENUM('available','booked','completed','cancelled') | NOT NULL DEFAULT 'available' | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| **UNIQUE** | (ptm_schedule_id, teacher_profile_id, slot_date, slot_time) | | |

### 5.31 `acd_ptm_bookings`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | |
| ptm_slot_id | BIGINT UNSIGNED | NOT NULL, FK→acd_ptm_teacher_slots | |
| ptm_schedule_id | INT UNSIGNED | NOT NULL, FK→acd_ptm_schedules | Denormalized |
| student_id | INT UNSIGNED | NOT NULL, FK→std_students | |
| guardian_id | INT UNSIGNED | NULL, FK→std_guardians | |
| booked_at | TIMESTAMP | NOT NULL | |
| status | ENUM('booked','attended','no_show','cancelled') | NOT NULL DEFAULT 'booked' | |
| meeting_notes | TEXT | NULL | Private: teacher + admin only |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| **UNIQUE** | (ptm_slot_id, student_id) | | |

---

## 6. API Endpoints & Routes

All routes `📐 Proposed`. Middleware: `['auth','verified','EnsureTenantHasModule:academics']`, prefix: `academics`, name prefix: `academics.`

```
// ── ACADEMIC CALENDAR ──────────────────────────────────────────────
GET    /calendars                              CalendarController@index           academics.calendar.index
POST   /calendars                              CalendarController@store           academics.calendar.store
GET    /calendars/{calendar}                   CalendarController@show            academics.calendar.show
PUT    /calendars/{calendar}                   CalendarController@update          academics.calendar.update
PUT    /calendars/{calendar}/publish           CalendarController@publish         academics.calendar.publish
GET    /calendars/{calendar}/events            CalendarEventController@index      academics.event.index
POST   /calendars/{calendar}/events            CalendarEventController@store      academics.event.store
PUT    /calendars/{calendar}/events/{event}    CalendarEventController@update     academics.event.update
DELETE /calendars/{calendar}/events/{event}    CalendarEventController@destroy    academics.event.destroy

// ── TEACHER ASSIGNMENTS ────────────────────────────────────────────
GET    /class-teachers                         ClassTeacherController@index       academics.classTeacher.index
POST   /class-teachers                         ClassTeacherController@store       academics.classTeacher.store
PUT    /class-teachers/{assignment}            ClassTeacherController@update      academics.classTeacher.update
GET    /subject-teachers                       SubjectTeacherController@index     academics.subjectTeacher.index
POST   /subject-teachers                       SubjectTeacherController@store     academics.subjectTeacher.store
PUT    /subject-teachers/{assignment}          SubjectTeacherController@update    academics.subjectTeacher.update
DELETE /subject-teachers/{assignment}          SubjectTeacherController@destroy   academics.subjectTeacher.destroy

// ── CURRICULUM ─────────────────────────────────────────────────────
GET    /curriculum                             CurriculumController@index         academics.curriculum.index
POST   /curriculum                             CurriculumController@store         academics.curriculum.store
PUT    /curriculum/{mapping}                   CurriculumController@update        academics.curriculum.update

// ── LESSON PLANS ───────────────────────────────────────────────────
GET    /lesson-plans                           LessonPlanController@index         academics.lessonPlan.index
POST   /lesson-plans                           LessonPlanController@store         academics.lessonPlan.store
GET    /lesson-plans/{plan}                    LessonPlanController@show          academics.lessonPlan.show
PUT    /lesson-plans/{plan}                    LessonPlanController@update        academics.lessonPlan.update
PUT    /lesson-plans/{plan}/submit             LessonPlanController@submit        academics.lessonPlan.submit
PUT    /lesson-plans/{plan}/review             LessonPlanController@review        academics.lessonPlan.review
PUT    /lesson-plans/{plan}/approve            LessonPlanController@approve       academics.lessonPlan.approve
GET    /lesson-plans/blooms-report             LessonPlanController@bloomsReport  academics.lessonPlan.bloomsReport

// ── TEACHING DIARY 🆕 ──────────────────────────────────────────────
GET    /teaching-diary                         TeachingDiaryController@index      academics.diary.index
POST   /teaching-diary                         TeachingDiaryController@store      academics.diary.store
PUT    /teaching-diary/{entry}                 TeachingDiaryController@update     academics.diary.update
GET    /teaching-diary/report                  TeachingDiaryController@report     academics.diary.report

// ── CLASS DIARY 🆕 ─────────────────────────────────────────────────
GET    /class-diary                            ClassDiaryController@index         academics.classDiary.index
POST   /class-diary                            ClassDiaryController@store         academics.classDiary.store
PUT    /class-diary/{diary}                    ClassDiaryController@update        academics.classDiary.update
PUT    /class-diary/{diary}/publish            ClassDiaryController@publish       academics.classDiary.publish

// ── DIGITAL CONTENT & STUDY MATERIALS ─────────────────────────────
GET    /digital-content                        DigitalContentController@index     academics.content.index
POST   /digital-content                        DigitalContentController@store     academics.content.store
PUT    /digital-content/{content}              DigitalContentController@update    academics.content.update
DELETE /digital-content/{content}              DigitalContentController@destroy   academics.content.destroy
POST   /digital-content/{content}/distribute   DigitalContentController@distribute academics.content.distribute

// ── WORKLOAD ───────────────────────────────────────────────────────
GET    /workload                               WorkloadController@index           academics.workload.index
GET    /workload/report                        WorkloadController@report          academics.workload.report

// ── SKILLS ─────────────────────────────────────────────────────────
GET    /skills/categories                      SkillCategoryController@index      academics.skillCategory.index
POST   /skills/categories                      SkillCategoryController@store      academics.skillCategory.store
GET    /skills                                 SkillController@index              academics.skill.index
POST   /skills                                 SkillController@store              academics.skill.store
PUT    /skills/{skill}                         SkillController@update             academics.skill.update
GET    /skill-assessments                      SkillAssessmentController@index    academics.skillAssessment.index
POST   /skill-assessments                      SkillAssessmentController@store    academics.skillAssessment.store
PUT    /skill-assessments/{assessment}         SkillAssessmentController@update   academics.skillAssessment.update
GET    /skill-assessments/report               SkillAssessmentController@report   academics.skillAssessment.report

// ── CO-CURRICULAR ──────────────────────────────────────────────────
GET    /cca/activities                         CcaActivityController@index        academics.cca.index
POST   /cca/activities                         CcaActivityController@store        academics.cca.store
PUT    /cca/activities/{activity}              CcaActivityController@update       academics.cca.update
POST   /cca/activities/{activity}/enroll       CcaEnrollmentController@store      academics.cca.enroll
PUT    /cca/enrollments/{enrollment}           CcaEnrollmentController@update     academics.cca.enrollment.update
GET    /cca/sessions                           CcaSessionController@index         academics.ccaSession.index
POST   /cca/sessions                           CcaSessionController@store         academics.ccaSession.store
POST   /cca/sessions/{session}/attendance      CcaAttendanceController@store      academics.ccaAttendance.store
POST   /cca/achievements                       CcaAchievementController@store     academics.ccaAchievement.store
PUT    /cca/achievements/{achievement}         CcaAchievementController@update    academics.ccaAchievement.update
GET    /cca/transcript/{student}               CcaTranscriptController@show       academics.ccaTranscript.show

// ── REMEDIAL CLASSES 🆕 ────────────────────────────────────────────
GET    /remedial                               RemedialController@index           academics.remedial.index
POST   /remedial                               RemedialController@store           academics.remedial.store
PUT    /remedial/{session}                     RemedialController@update          academics.remedial.update
PUT    /remedial/{session}/confirm             RemedialController@confirm         academics.remedial.confirm
POST   /remedial/{session}/attendance          RemedialAttendanceController@store academics.remedial.attendance
GET    /remedial/history/{student}             RemedialController@history         academics.remedial.history

// ── ACADEMIC ALERTS 🆕 ─────────────────────────────────────────────
GET    /alerts                                 AlertController@index              academics.alert.index
PUT    /alerts/{alert}/acknowledge             AlertController@acknowledge        academics.alert.acknowledge
PUT    /alerts/{alert}/resolve                 AlertController@resolve            academics.alert.resolve

// ── PTM ────────────────────────────────────────────────────────────
GET    /ptm                                    PtmScheduleController@index        academics.ptm.index
POST   /ptm                                    PtmScheduleController@store        academics.ptm.store
PUT    /ptm/{schedule}                         PtmScheduleController@update       academics.ptm.update
PUT    /ptm/{schedule}/publish                 PtmScheduleController@publish      academics.ptm.publish
GET    /ptm/{schedule}/slots                   PtmSlotController@index            academics.ptmSlot.index
POST   /ptm/{schedule}/slots/{slot}/book       PtmBookingController@store         academics.ptmBooking.store
PUT    /ptm/bookings/{booking}/complete        PtmBookingController@complete      academics.ptmBooking.complete
PUT    /ptm/bookings/{booking}/cancel          PtmBookingController@cancel        academics.ptmBooking.cancel
```

---

## 7. UI Screens

| Screen ID | Screen Name | Route Name | Description |
|-----------|-------------|-----------|-------------|
| ACD-SCR-01 | Academic Calendar View | academics.calendar.index | Full-page calendar with event colour coding, month/week/list views |
| ACD-SCR-02 | Calendar Event Form | academics.event.store | Create/edit event with date range picker, type selector, colour picker |
| ACD-SCR-03 | Holiday Manager | academics.event.index | Quick-add holiday form; holiday list with SMS alert toggle |
| ACD-SCR-04 | Class Teacher Assignment | academics.classTeacher.index | Class-section grid, assign/reassign with effective date |
| ACD-SCR-05 | Subject Teacher Assignment | academics.subjectTeacher.index | Subject × class-section matrix, teacher dropdown per cell |
| ACD-SCR-06 | Curriculum Mapping | academics.curriculum.index | Class × Subject grid with core/elective type indicators |
| ACD-SCR-07 | Teacher Workload Dashboard | academics.workload.index | Bar chart: periods/week per teacher, over-capacity flags in red |
| ACD-SCR-08 | My Lesson Plans (Teacher) | academics.lessonPlan.index | Weekly planner calendar; DRAFT/SUBMITTED/APPROVED badges; Bloom's level chips |
| ACD-SCR-09 | Create/Edit Lesson Plan | academics.lessonPlan.store | Form: week, topic, objectives, methods, SLB topic picker, Bloom's multi-select |
| ACD-SCR-10 | Lesson Plan Review (HoD) | academics.lessonPlan.review | Plan details + approve/revise side-by-side; Bloom's coverage bar |
| ACD-SCR-11 | Teaching Diary Entry | academics.diary.store | Pre-filled from today's timetable; topics taught, homework, methodology |
| ACD-SCR-12 | Teaching Diary Report | academics.diary.report | Diary completeness % per teacher per week; unfilled periods highlighted |
| ACD-SCR-13 | Class Diary Editor | academics.classDiary.store | Auto-populated from teaching diary; class teacher adds announcement; publish button |
| ACD-SCR-14 | Class Diary View (Portal) | academics.classDiary.index | Parent/student view: date list, homework summary cards, announcements |
| ACD-SCR-15 | Digital Content Library | academics.content.index | Card grid with type icons, SLB topic tag, search/filter |
| ACD-SCR-16 | Upload & Distribute Material | academics.content.store | Drag-drop upload + metadata + class-section distribution picker |
| ACD-SCR-17 | Skill Framework Manager | academics.skillCategory.index | Expandable tree: categories → skills → levels |
| ACD-SCR-18 | Student Skill Assessment Form | academics.skillAssessment.store | Class roster × skill rating grid |
| ACD-SCR-19 | Student Skill Report | academics.skillAssessment.report | Radar chart + tabular ratings per term, delta arrows |
| ACD-SCR-20 | CCA Activity Master | academics.cca.index | Activity cards with enrollment counts, coordinator name |
| ACD-SCR-21 | CCA Student Enrollment | academics.cca.enroll | Student search + multi-select + role picker |
| ACD-SCR-22 | CCA Session Attendance | academics.ccaAttendance.store | Roll call list for one CCA session |
| ACD-SCR-23 | CCA Achievements | academics.ccaAchievement.store | Achievement form: type, level, position, certificate upload |
| ACD-SCR-24 | CCA Transcript | academics.ccaTranscript.show | Print-ready PDF preview per student |
| ACD-SCR-25 | Remedial Schedule | academics.remedial.index | List of remedial sessions with status; PAN-suggested sessions highlighted |
| ACD-SCR-26 | Remedial Attendance | academics.remedial.attendance | Roll call for a remedial session; outcome notes field |
| ACD-SCR-27 | Remedial Student History | academics.remedial.history | Per-student remedial session timeline with outcomes |
| ACD-SCR-28 | Academic Alerts Dashboard | academics.alert.index | Alert cards by type/severity; acknowledge and resolve actions |
| ACD-SCR-29 | PTM Schedule Manager | academics.ptm.index | List of PTMs with slot generation status |
| ACD-SCR-30 | PTM Slot Booking (Parent) | academics.ptmSlot.index | Teacher slots grid; parent selects available slot |
| ACD-SCR-31 | PTM Admin Dashboard | academics.ptm.show | Live booking stats: booked/available/no-show per teacher |
| ACD-SCR-32 | Bloom's Distribution Report | academics.lessonPlan.bloomsReport | Bar charts per teacher/dept across 6 Bloom's levels |

---

## 8. Business Rules

**BR-ACD-01:** Only one `is_primary = 1` calendar per academic session. Enforced via generated-column UNIQUE constraint.

**BR-ACD-02:** Calendar event `from_date` must not exceed `to_date`. Single-day events: `from_date = to_date`.

**BR-ACD-03:** Once a calendar is published, events cannot be hard-deleted. Soft-delete requires a mandatory reason recorded in `sys_activity_logs`.

**BR-ACD-04:** Only one active primary class teacher per class-section per session at any time. Enforced via generated-column UNIQUE on `active_flag`.

**BR-ACD-05:** Subject teacher assignment requires a valid matching record in `acd_class_subject_jnt`. Assigning a teacher to a subject not mapped to that class is rejected.

**BR-ACD-06:** A lesson plan is locked for teacher editing once `status = 'submitted'`. Teacher must wait for HoD to request revision. Approved plans are permanently read-only.

**BR-ACD-07:** One lesson plan per teacher-class-section-subject-week. Duplicate attempt returns validation error with a link to the existing plan.

**BR-ACD-08:** Workload recalculation (`RecalculateWorkloadJob`) runs asynchronously on queue. UI shows `last_calculated_at` timestamp to signal possible staleness.

**BR-ACD-09:** School-configurable max CCA activities per student per session (default 3). Exceeding this limit raises a warning but allows admin override with acknowledgement.

**BR-ACD-10:** CCA achievements at 'district' level or above trigger `CCA_ACHIEVEMENT_HIGH_LEVEL` notification to Principal + class teacher.

**BR-ACD-11:** PTM slot booking: one booking per student-teacher per PTM schedule. Concurrent booking attempts use `SELECT FOR UPDATE` row locking.

**BR-ACD-12:** A closed academic session (`is_active = 0`) is read-only. No new lesson plans, diary entries, skill assessments, CCA enrollments, or calendar events may be created against it.

**BR-ACD-13:** Skill assessment is upsert per student-skill-session-term. Previous rating logged to `sys_activity_logs` for audit trail.

**BR-ACD-14:** Teaching diary entries are locked after midnight of the diary date. Unlocking requires admin-level override, which is logged.

**BR-ACD-15:** Lesson plan must include at least one Bloom's taxonomy level if school policy `acd_blooms_minimum` is enabled (configurable, default off).

**BR-ACD-16:** Study materials with `push_to_lxp = 1` are automatically queued for LXP ingestion. LXP must not store a separate copy; it reads from `acd_digital_contents`.

**BR-ACD-17:** Remedial sessions in status `suggested` (PAN-triggered) require explicit teacher confirmation before appearing in the schedule and sending notifications to students.

**BR-ACD-18:** Academic alerts in `active` status that are not acknowledged within 48 hours are automatically escalated (severity upgraded from `warning` to `critical`).

---

## 9. Workflows

### 9.1 Lesson Plan Lifecycle

```
Teacher creates plan → status: DRAFT (free edit)
    Teacher selects SLB topics + Bloom's levels
    Teacher attaches digital content (optional)

Teacher submits → status: SUBMITTED (locked for teacher)
    → HoD receives in-app notification LESSON_PLAN_SUBMITTED

HoD reviews:
    → APPROVE: status = 'approved'
        → LessonPlanPublished event fired
        → SLB coverage updated: linked topics marked 'planned'
        → Portal notification to students/parents (if notify_on_publish = 1)
        → Teacher notified: LESSON_PLAN_APPROVED
    → REQUEST REVISION (with comments): status = 'revision_requested'
        → Teacher unlocked to edit
        → Teacher notified: LESSON_PLAN_REVISION_REQUESTED

Week end: teacher updates completion_percentage
    If < 100%: incomplete_remarks required
    If any linked SLB topic not taught: diary entry cross-check done
```

### 9.2 Teaching Diary → Class Diary → Portal Flow

```
Teacher finishes period → opens Teaching Diary
    Pre-filled: class, subject, period from timetable
    Teacher enters: topics_covered, methodology, homework_given
    Save → SLB topic marked 'taught' (if lesson plan linked)
    Save → class diary auto-aggregation triggered (async)

Class Teacher opens Class Diary for the day
    Auto-populated: subject-wise summaries from teaching diary entries
    Class teacher reviews; adds general_announcement if needed
    Publish → is_published = 1
    → NTF: CLASS_DIARY_PUBLISHED to all parents/students of that class-section
    → Portal: diary entry visible in reverse-chrono feed
```

### 9.3 Remedial Class Lifecycle (PAN-Triggered)

```
PAN module detects at-risk student
    → fires StudentAtRisk event (student_id, subject_id, risk_level)

ACD listener:
    → creates acd_remedial_sessions record (status: 'suggested')
    → adds student to acd_remedial_student_jnt with pan_alert_id
    → notifies class teacher: REMEDIAL_SUGGESTED

Class teacher reviews suggestion:
    → CONFIRM: status = 'scheduled'
        → Students notified via NTF
    → REJECT: status = 'cancelled', reason logged

On scheduled_date:
    Teacher conducts session
    Teacher marks attendance (acd_remedial_attendance)
    Teacher records outcome_notes + improvement_observed

Status → 'completed'
    Outcome visible in per-student remedial history report
```

### 9.4 PTM Booking Lifecycle

```
Admin creates PTM schedule (status: DRAFT)
    → System generates acd_ptm_teacher_slots records

Admin publishes PTM (status: PUBLISHED)
    → NTF: PTM_SCHEDULE_PUBLISHED to all applicable parents

Parent visits portal → sees PTM booking page
    → Selects teacher slot (SELECT FOR UPDATE prevents double booking)
    → acd_ptm_bookings created (status: 'booked')
    → Slot status → 'booked'
    → NTF: PTM_BOOKING_CONFIRMED (SMS + in-app)

T-24 hours: PTM_REMINDER notification dispatched

PTM Day:
    Teacher marks slot: attended / no_show
    Optional: records meeting_notes (private)

Admin closes PTM → status: COMPLETED
    Post-PTM summary report auto-generated
```

### 9.5 Teacher Assignment Change Workflow

```
Admin identifies need for mid-session reassignment:
1. Find existing active assignment (old teacher)
2. Set effective_to = (change_date - 1 day)
3. Create new assignment: effective_from = change_date
4. RecalculateWorkloadJob queued for both old and new teachers
5. TT module notified via TeacherAssignmentChanged event
   → Existing timetable cells retain old teacher until manually updated by TT admin
6. LMS, HMW, QUZ, EXM modules now see new teacher for that class-subject
```

### 9.6 Academic Alert Engine Cycle

```
Scheduled job (daily, configurable time):
    1. Compute syllabus coverage per class-section-subject
       If coverage < threshold → emit SYLLABUS_COVERAGE_LOW alert
    2. Check lesson plan submission for current week
       If missing by deadline → emit LESSON_PLAN_MISSING alert
    3. Check teaching diary completeness
       If ≥2 consecutive unfilled periods → emit DIARY_NOT_FILLED alert
    4. Cross ATT attendance % with EXM latest marks
       If att < 75% AND marks < 40% → emit ATTENDANCE_PERFORMANCE_RISK alert

On alert created:
    → Insert into acd_academic_alerts
    → NTF event dispatched to relevant recipients
    → Alert appears in ACD-SCR-28 dashboard

On condition cleared (next daily run):
    → Alert status → 'resolved' automatically
    → resolved_at timestamp set
```

---

## 10. Non-Functional Requirements

**NFR-ACD-01 (Performance):** Academic calendar page loads all events for current month in ≤ 2 seconds. PTM slot grid for 20 teachers × 50 slots renders in ≤ 3 seconds.

**NFR-ACD-02 (Data Integrity):** All teacher assignment changes use `effective_from` / `effective_to` versioning — overwriting is prohibited. Full history must be queryable by date range.

**NFR-ACD-03 (Soft Deletes):** All master records (activities, skills, skill categories, digital content) use soft deletes (`deleted_at`). Hard deletes on `acd_*` tables are prohibited.

**NFR-ACD-04 (Concurrency):** PTM slot booking uses `SELECT FOR UPDATE` row locking to prevent double-booking under concurrent parent requests.

**NFR-ACD-05 (PDF Quality):** CCA transcripts, lesson plan PDFs, and remedial history reports generated via DomPDF with school letterhead, consistent with the HPC module's PDF output style.

**NFR-ACD-06 (Async Processing):** `RecalculateWorkloadJob`, `GenerateAcademicAlertsJob`, and `SyncSyllabuscoverageJob` must run on the queue. No synchronous HTTP request may block waiting for these calculations.

**NFR-ACD-07 (Security):** PTM meeting notes visible only to recording teacher + school admin. Parents and students cannot read them. Teaching diary entries visible to admin, HoD, and the recording teacher only.

**NFR-ACD-08 (Multi-tenancy):** All `acd_*` tables operate within the tenant database. `EnsureTenantHasModule:academics` middleware enforces per-tenant module licensing.

**NFR-ACD-09 (Audit):** Skill assessment updates, lesson plan status changes, teacher reassignments, and alert resolutions are all logged to `sys_activity_logs` with before/after values.

**NFR-ACD-10 (Scalability):** Teaching diary entries are the highest-volume write (one per teacher per period per day). The `acd_teaching_diary` table must be indexed on `(class_section_id, diary_date)` and `(teacher_profile_id, diary_date)` for fast aggregation into class diary.

---

## 11. Cross-Module Dependencies

| Module | Direction | Dependency Detail |
|--------|-----------|------------------|
| School Setup (`sch_*`) | Consumes | `sch_classes`, `sch_sections`, `sch_class_section_jnt`, `sch_subjects`, `sch_subject_types`, `sch_teacher_profile`, `sch_departments` |
| Student Management (`std_*`) | Consumes | `std_students`, `std_student_academic_sessions`, `std_guardians` for CCA, PTM, and remedial |
| Global Masters (`glb_*`) | Consumes | `glb_academic_sessions` — all session-scoped ACD records |
| System Config (`sys_*`) | Consumes | `sys_users` (created_by, reviewed_by), `sys_media` (content, certificates, evidence), `sys_activity_logs` (audit), `sys_settings` (Bloom's policy, max CCA) |
| Syllabus (`slb_*`) | Bi-directional | ACD lesson plans reference `slb_topics`; teaching diary entries update SLB coverage tracker |
| Timetable (TT / TTF / STT) | Bi-directional | ACD provides subject-teacher map to TT generator; TT provides timetable slot IDs to teaching diary pre-fill |
| Notification (NTF) | Pushes events | HOLIDAY_ADDED, CALENDAR_EVENT_PUBLISHED, LESSON_PLAN_SUBMITTED, LESSON_PLAN_APPROVED, LESSON_PLAN_REVISION_REQUESTED, CLASS_DIARY_PUBLISHED, PTM_SCHEDULE_PUBLISHED, PTM_BOOKING_CONFIRMED, PTM_REMINDER, CCA_ACHIEVEMENT_HIGH_LEVEL, WORKLOAD_OVER_CAPACITY, REMEDIAL_SUGGESTED, academic alert events |
| Attendance (ATT) | Provides data to | `acd_calendar_events WHERE is_working_day = 0` is ATT's holiday source; ACD consumes ATT's `att_student_analytics.attendance_percentage` for alert engine |
| Examination (EXM) | Bi-directional | Skill assessments included in EXM report cards; exam window dates read from ACD academic calendar |
| LMS / Homework (HMW) / Quiz (QUZ) | Provides | Subject-teacher assignment gates teacher access to create LMS content for that class-subject |
| LXP | Provides | `acd_digital_contents WHERE push_to_lxp = 1` feeds LXP content library; no separate LXP upload needed |
| Predictive Analytics (PAN) | Consumes | ACD listens for `StudentAtRisk` event to trigger remedial session creation |
| HR & Payroll (HRS) | Provides | Teacher workload data (`acd_teacher_workloads`) for HR compliance and payroll deduction calculations |
| Parent Portal (PPT) | Provides | Class diary, study materials, CCA transcript, PTM booking available via portal APIs |

---

## 12. Test Scenarios

| Test Class | Type | Priority | Description |
|-----------|------|----------|-------------|
| AcademicCalendarControllerTest | Feature | P0 | Calendar CRUD; primary uniqueness enforcement; publish workflow; holiday NTF event fired |
| ClassTeacherAssignmentTest | Feature | P0 | Primary uniqueness; mid-session reassignment with effective dates; duplicate rejection |
| SubjectTeacherAssignmentTest | Feature | P0 | Assignment requires curriculum mapping; workload job dispatched on create/update/delete |
| LessonPlanWorkflowTest | Feature | P0 | Full DRAFT→SUBMITTED→REVISION_REQUESTED→APPROVED cycle; SLB coverage update on approve |
| LessonPlanBloomsTest | Feature | P1 | Bloom's levels saved; policy enforcement when minimum levels required; Bloom's report correct |
| TeachingDiaryTest | Feature | P0 | Entry created; lock after midnight; SLB topic marked taught; class diary aggregation triggered |
| ClassDiaryPublishTest | Feature | P1 | Auto-population from teaching diary; publish fires NTF CLASS_DIARY_PUBLISHED |
| StudyMaterialDistributionTest | Feature | P1 | Upload + distribute to class-sections; LXP push flag queues sync job; view count tracking |
| SkillAssessmentTest | Feature | P1 | Upsert pattern; delta calculation across terms; previous rating in activity log |
| CcaEnrollmentTest | Feature | P1 | Enrollment created; max limit warning; high-level achievement NTF fired |
| CcaTranscriptPdfTest | Feature | P1 | PDF generated with correct activities, attendance %, achievements |
| RemedialSessionTest | Feature | P1 | PAN event creates suggested session; teacher confirm flow; attendance and outcome recording |
| AcademicAlertEngineTest | Feature | P1 | SYLLABUS_COVERAGE_LOW generated when coverage < threshold; auto-resolve when coverage rises |
| WorkloadCalculationTest | Unit | P1 | Period count summed correctly; is_over_capacity flag set; async job dispatched |
| PtmBookingConcurrencyTest | Feature | P1 | SELECT FOR UPDATE prevents double-booking; confirmation SMS on success |
| CalendarEventValidationTest | Unit | P2 | from_date > to_date rejected; closed session rejects new events |
| TeacherAssignmentChangeWorkflowTest | Feature | P2 | effective_to set on old record; new record created; workload jobs for both teachers |

---

## 13. Glossary

| Term | Definition |
|------|-----------|
| Academic Calendar | Structured record of all school events, holidays, and key dates for an academic session; authoritative source for ATT, TT, and EXM |
| Academic Session | One school year period (e.g., April 2025 – March 2026); all ACD records scoped to a session |
| Bloom's Taxonomy | Six-level cognitive framework (Remember → Understand → Apply → Analyse → Evaluate → Create) for classifying learning objectives; mandated in NEP 2020 |
| CCA | Co-Curricular Activity — activities beyond the academic curriculum (sports, arts, clubs, NSS, NCC) |
| CCA Transcript | Official school document listing student participation, attendance %, performance ratings, and achievements in CCAs |
| Class Diary | Daily published record for a class-section combining teaching summaries and announcements; visible to parents and students on portal |
| Class Teacher | Teacher formally responsible for a class-section (homeroom teacher); manages class diary and remedial scheduling |
| DISE | District Information System for Education — Government of India school data reporting system |
| Elective Subject | Optional subject a student chooses, distinct from compulsory core subjects |
| Lesson Plan | Teacher's weekly written plan of teaching topics, methods, Bloom's levels, and objectives, submitted for HoD approval |
| PTM | Parent-Teacher Meeting — scheduled sessions where parents discuss student progress with teachers |
| Primary Calendar | The designated main calendar for a session; one per session; consumed by ATT, TT, and EXM |
| Remedial Class | An additional scheduled session to help at-risk or underperforming students catch up on missed or difficult content |
| Skill Assessment | Qualitative per-term rating of a student's demonstrated competency in a defined NEP skill category |
| Subject Teacher | Teacher assigned to teach a specific subject to a specific class-section; authoritative for LMS and EXM access |
| Teaching Diary | Per-period daily log by subject teacher recording topics actually taught, methodology, and homework given |
| Teacher Workload | Total periods per week assigned to a teacher across all class-sections; tracked against min/max policy limits |

---

## 14. Suggestions

**Priority 1 — Foundation (Build First):**

1. **Academic Calendar is the blocker.** Build FR-ACD-001 first — ATT's working-day denominator, EXM's exam window, and TT's holiday-aware slot generation all depend on it. Wire the `is_working_day = 0` consumer contract with ATT before any other integration.

2. **Subject Teacher Assignment matrix UI (ACD-SCR-05)** is the single highest-impact screen for admin productivity. Design it as a spreadsheet-like grid (rows = subjects, columns = class-sections, cells = teacher autocomplete dropdowns). Individual form submissions per assignment would be extremely tedious.

3. Use MySQL generated-column UNIQUE constraints (as already done in `glb_academic_sessions.current_flag`) for both `acd_academic_calendars.primary_flag` and `acd_class_teacher_jnt.active_flag` — this enforces the one-active-primary rule at the DB level without application code.

**Priority 2 — Teaching Operations:**

4. **Teaching Diary pre-fill from TT is essential for adoption.** If teachers must manually type class, subject, and period number each time, they won't use it. Wire the TT API to auto-populate today's schedule for each teacher's diary page.

5. **SLB coverage update should be near-real-time.** When a teacher saves a teaching diary entry, fire a `TeachingDiaryEntrySaved` event and process the SLB coverage update in a queued listener (< 5 second lag). The SLB syllabus progress bar in the Principal dashboard will reflect actual teaching activity daily.

6. Keep `acd_class_diary.teaching_summary_json` as auto-populated and non-editable by class teacher — only `general_announcement` and `behaviour_notes` should be editable. This prevents class teachers from accidentally overwriting subject-specific data aggregated from individual teachers.

**Priority 3 — Analytics and Integration:**

7. **The Bloom's distribution report (ACD-SCR-32)** is a high-value feature for CBSE/NAAC inspections. Build it as an exportable stacked bar chart: X-axis = teacher or department, each bar segment = proportion of lesson plans targeting each of the 6 Bloom's levels.

8. **Remedial scheduling needs a dashboard view** (not just a list) showing: students with most remedial sessions, subjects with highest remedial demand, and improvement rates post-remedial. This makes the feature valuable for principal reporting.

9. **CCA transcript bulk printing** (one PDF per student in an activity) should use a queued job with progress reporting — generating 200 student PDFs synchronously would time out. Use the same `GeneratePdfJob` pattern as HPC.

10. **Academic alerts require tuning.** The default syllabus coverage threshold (70%) may generate too many false positives at the start of session when coverage is naturally low. Consider: a) disabling alerts for the first 4 weeks, b) expressing threshold as a % of expected coverage at the current point in session (topics_planned_to_date / total_topics × 100) rather than absolute coverage.

---

## 15. Appendices

### Appendix A: Table Summary

| Table | Purpose | Est. Annual Rows |
|-------|---------|-----------------|
| `acd_academic_calendars` | Calendar master | 1–3 |
| `acd_calendar_events` | Events and holidays | ~100 |
| `acd_class_teacher_jnt` | Class teacher assignments (versioned) | ~70 |
| `acd_subject_teacher_jnt` | Subject-teacher assignments (versioned) | ~350 |
| `acd_class_subject_jnt` | Curriculum mapping | ~220 |
| `acd_student_elective_jnt` | Student elective choices | ~500 |
| `acd_lesson_plans` | Weekly lesson plans | ~15,000 |
| `acd_lesson_plan_slb_jnt` | Plan-topic linkage | ~45,000 |
| `acd_teaching_diary` | Daily period teaching log | ~35,000 (50 teachers × 200 days × 3-4 periods avg) |
| `acd_class_diary` | Daily class diary entries | ~12,000 (60 sections × 200 days) |
| `acd_digital_contents` | Uploaded teaching content | ~2,000 |
| `acd_material_distribution` | Content distributed to sections | ~6,000 |
| `acd_material_views` | Student material access log | ~50,000 |
| `acd_lesson_plan_content_jnt` | Plan-content links | ~5,000 |
| `acd_teacher_workloads` | Teacher workload summaries (upsert) | ~60 |
| `acd_skill_categories` | Skill category master | ~10 |
| `acd_skills` | Individual skills | ~50 |
| `acd_skill_subject_jnt` | Skill-subject mappings | ~100 |
| `acd_skill_assessments` | Student skill ratings | ~15,000 |
| `acd_cca_activities` | CCA activity master | ~20 |
| `acd_student_cca_jnt` | Student CCA enrollments | ~1,000 |
| `acd_cca_sessions` | CCA session records | ~500 |
| `acd_cca_attendance` | CCA session attendance | ~10,000 |
| `acd_cca_achievements` | Student achievements | ~100 |
| `acd_remedial_sessions` | Remedial session master | ~200 |
| `acd_remedial_student_jnt` | Students per remedial session | ~600 |
| `acd_remedial_attendance` | Remedial session attendance | ~600 |
| `acd_academic_alerts` | System-generated academic alerts | ~500/year |
| `acd_ptm_schedules` | PTM schedule master | ~4 |
| `acd_ptm_teacher_slots` | Auto-generated PTM slots | ~2,000 |
| `acd_ptm_bookings` | Parent PTM bookings | ~1,500 |

### Appendix B: Notification Event Codes

| Event Code | Trigger | Recipients |
|-----------|---------|-----------|
| `HOLIDAY_ADDED` | Holiday saved with notify = 1 | All Parents + All Staff (SMS + Email) |
| `CALENDAR_EVENT_PUBLISHED` | Event portal flag set | Students + Parents (In-App) |
| `LESSON_PLAN_SUBMITTED` | Teacher submits plan | Department HoD (In-App) |
| `LESSON_PLAN_REVISION_REQUESTED` | HoD requests revision | Subject Teacher (In-App) |
| `LESSON_PLAN_APPROVED` | HoD approves | Subject Teacher (In-App); Students/Parents if notify_on_publish (In-App) |
| `CLASS_DIARY_PUBLISHED` | Class teacher publishes diary | Students + Parents of class-section (In-App) |
| `PTM_SCHEDULE_PUBLISHED` | PTM published | All applicable Parents (SMS + In-App) |
| `PTM_BOOKING_CONFIRMED` | Parent books slot | Parent (SMS + In-App) |
| `PTM_REMINDER` | 24h before PTM | Parent with booked slot (SMS + In-App) |
| `CCA_ACHIEVEMENT_HIGH_LEVEL` | District+ achievement recorded | Principal + Class Teacher (In-App) |
| `WORKLOAD_OVER_CAPACITY` | Teacher exceeds max periods | HR Admin + Dept HoD (In-App) |
| `REMEDIAL_SUGGESTED` | PAN triggers remedial | Class Teacher (In-App) |
| `SYLLABUS_COVERAGE_LOW` | Coverage below threshold | Subject Teacher + HoD (In-App) |
| `LESSON_PLAN_MISSING` | Plan not submitted by deadline | Subject Teacher + HoD (In-App) |
| `DIARY_NOT_FILLED` | 2+ consecutive unfilled periods | Subject Teacher (In-App) |
| `ATTENDANCE_PERFORMANCE_RISK` | Att < 75% + Marks < 40% | Class Teacher + Counsellor (In-App) |

### Appendix C: RBS Sub-Task Coverage

| RBS Sub-Task (v2 Spec) | FR Coverage |
|------------------------|-------------|
| H.H1 Syllabus Management | FR-ACD-002 (curriculum mapping), FR-ACD-003 (SLB linkage) |
| H.H2 Lesson Planning | FR-ACD-003 (lesson plan CRUD + approval + Bloom's) |
| H.H3 Bloom's Taxonomy Tagging | FR-ACD-003.3 (Bloom's multi-select on lesson plans) |
| H.H4 Learning Outcomes | FR-ACD-003.2 (SLB topic linkage as learning outcome proxy) |
| Session Management | FR-ACD-001.4 |
| Academic Calendar | FR-ACD-001.1, FR-ACD-001.2 |
| Holiday Management | FR-ACD-001.3 |
| Class/Subject Assignment | FR-ACD-002 |
| Teacher Workload | FR-ACD-007 |
| Skill Framework | FR-ACD-008 |
| CCA Management | FR-ACD-009 |
| PTM Management | FR-ACD-012 |
| Teaching Diary (new) | FR-ACD-004 |
| Class Diary (new) | FR-ACD-005 |
| Study Material Distribution (new) | FR-ACD-006 |
| Remedial Classes (new) | FR-ACD-010 |
| Academic Alert Engine (new) | FR-ACD-011 |
| Progress Dashboard | FR-ACD-013 |

### Appendix D: Scope Boundary

**ACD explicitly does NOT own:**
- Chapter/unit/topic content definitions → owned by SLB module (`slb_*`)
- Syllabus completion percentage tracking at chapter level → owned by SLB
- Homework assignment creation → owned by LMS-Homework (HMW)
- Exam scheduling → owned by EXA/EXM
- Textbook master → owned by SLB's Books sub-module (`bok_*`)
- Regular period attendance marking → owned by ATT module
- Student behaviour records (disciplinary) → owned by BEH module

ACD's lesson plans reference SLB topics by FK (`acd_lesson_plan_slb_jnt.slb_topic_id`) but do not own the topic definitions. Teaching diary entries notify SLB of topic coverage but SLB owns the authoritative coverage percentage.

---

## 16. V1 → V2 Delta

| Area | V1 | V2 Change |
|------|----|-----------|
| Lesson Plans | Week-based, approval workflow | + Bloom's taxonomy tagging, + SLB topic linkage via `acd_lesson_plan_slb_jnt`, + `notify_on_publish` flag |
| Teaching | Not present | 🆕 FR-ACD-004 Teaching Diary — daily per-period log with TT slot binding and SLB coverage update |
| Class Diary | Not present | 🆕 FR-ACD-005 Class Diary — auto-aggregated from teaching diary; parent-visible on portal |
| Study Materials | Digital content library only | 🆕 FR-ACD-006 Material Distribution: per class-section distribution, LXP push flag, view tracking (`acd_material_distribution`, `acd_material_views`), `slb_topic_id` linkage on `acd_digital_contents` |
| Remedial | Not present | 🆕 FR-ACD-010 Remedial Class Management — scheduling, PAN integration, attendance, outcome tracking (3 new tables) |
| Alert Engine | Not present | 🆕 FR-ACD-011 Academic Alert Engine — syllabus coverage, lesson plan compliance, attendance-performance correlation, diary completeness (`acd_academic_alerts` table) |
| Data Model | 22 tables | 31 tables (9 new: `acd_lesson_plan_slb_jnt`, `acd_teaching_diary`, `acd_class_diary`, `acd_material_distribution`, `acd_material_views`, `acd_remedial_sessions`, `acd_remedial_student_jnt`, `acd_remedial_attendance`, `acd_academic_alerts`) |
| API Routes | ~38 routes | ~60 routes (+22 for teaching diary, class diary, material distribution, remedial, alerts) |
| UI Screens | 23 screens | 32 screens (+9 for new features) |
| Notifications | 10 event codes | 16 event codes (+6 for new features) |
| NFRs | 8 | 10 (+audit trail NFR-ACD-09, +teaching diary indexing NFR-ACD-10) |
