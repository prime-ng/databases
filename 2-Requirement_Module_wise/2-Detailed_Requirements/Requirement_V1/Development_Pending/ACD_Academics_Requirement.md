# Academics Module — Requirement Specification Document
**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Automated Extraction)
**Module Code:** ACD | **Module Type:** Tenant Module
**Table Prefix:** `acd_*` | **Processing Mode:** RBS_ONLY (Greenfield — no code exists)
**RBS Reference:** Module H — Academics Management (54 sub-tasks, lines 2474–2591)

---

## 1. Executive Summary

The Academics module (ACD) is the central coordination layer for all planned academic activity in Prime-AI. While the Syllabus module handles curriculum content, the Academics module manages the organisational and planning superstructure: who teaches what, when planned learning activities happen, how co-curricular life is managed, and how teachers plan and track lesson delivery. For Indian K-12 schools, the module satisfies requirements for CBSE/ICSE/State Board academic planning documentation, DISE (District Information System for Education) reporting, teacher workload compliance, and co-curricular transcript generation for student portfolios.

**Implementation Statistics (Greenfield):**
- Controllers: 0 (not started)
- Models: 0 (not started)
- Services: 0 (not started)
- FormRequests: 0 (not started)
- Tests: 0 (not started)
- Completion: 0%

**All features are proposed (📐). No code, DDL, or tests exist yet.**

---

## 2. Module Overview

### 2.1 Business Purpose

The Academics module provides six interconnected capability areas:

1. **Academic Calendar** — A single source of truth for all school events, holidays, exam windows, and special days. Every other module (Attendance, Timetable, Exam, LMS) depends on this calendar to understand working days.
2. **Teacher & Subject Assignment** — Formal recording of which teacher is assigned to which class-section-subject combination for a given academic session. This drives the Timetable module and gates teacher access to student work in LMS and Exam modules.
3. **Lesson Planning** — Structured weekly/fortnightly lesson plans submitted by teachers, reviewed and approved by department heads, with progress tracking against the submitted plan.
4. **Teacher Workload Management** — Calculation and balancing of teaching loads against policy limits; ensures no teacher is over- or under-assigned.
5. **Skill & Competency Framework** — Definition of skill categories (cognitive, creative, physical) and recording of per-student skill assessments beyond grades.
6. **Co-Curricular Activity Management** — Sports, arts, clubs, NSS, NCC: enrolling students, tracking participation, recording achievements, generating CCA transcripts.

### 2.2 Feature Summary

| Feature | Status |
|---------|--------|
| Academic Session Management (activate/deactivate) | 📐 Not Started |
| Academic Calendar Creation & Event Management | 📐 Not Started |
| Holiday Management (full/half-day, SMS alerts) | 📐 Not Started |
| Curriculum Mapping (subjects to class) | 📐 Not Started |
| Class Teacher Assignment | 📐 Not Started |
| Subject Teacher Assignment (class-section-subject-teacher) | 📐 Not Started |
| Lesson Plan Creation (draft/submit/approve) | 📐 Not Started |
| Lesson Plan Progress Tracking | 📐 Not Started |
| Digital Content Upload & Assignment | 📐 Not Started |
| Teacher Workload Calculation | 📐 Not Started |
| Workload Reports (subject-wise, department-wise) | 📐 Not Started |
| Skill Framework (categories, descriptors) | 📐 Not Started |
| Skill-to-Subject Mapping | 📐 Not Started |
| Student Skill Assessment & Rating | 📐 Not Started |
| Skill Reports & Improvement Insights | 📐 Not Started |
| Co-Curricular Activity Master | 📐 Not Started |
| Student CCA Enrollment | 📐 Not Started |
| CCA Attendance & Performance Tracking | 📐 Not Started |
| CCA Achievements & Awards | 📐 Not Started |
| Co-Curricular Transcript Generation | 📐 Not Started |
| Parent-Teacher Meeting (PTM) Schedule & Slots | 📐 Not Started |
| Academic Progress Dashboard | 📐 Not Started |

### 2.3 Menu Path

`Tenant Dashboard > Academics`
- Academic Calendar
  - Calendar Events
  - Holiday Management
- Curriculum & Assignment
  - Subject-Class Mapping
  - Class Teacher Assignment
  - Subject Teacher Assignment
  - Teacher Workload
- Lesson Planning
  - My Lesson Plans (Teacher view)
  - All Lesson Plans (Admin/HoD view)
  - Digital Content Library
- Skills & Competencies
  - Skill Framework
  - Student Skill Assessments
  - Skill Reports
- Co-Curricular
  - Activity Master
  - Student Enrollment
  - Achievements & Awards
  - CCA Transcript
- Parent-Teacher Meetings
  - PTM Schedule
  - PTM Slots

### 2.4 Architecture

```
[School Admin]
    → Creates Academic Calendar (events, holidays)
    → Assigns Class Teachers and Subject Teachers per session
    → Manages Leave Types, CCA Activities, Skill Framework

[Department Head]
    → Reviews and approves lesson plans
    → Monitors teacher workload

[Teacher]
    → Submits weekly lesson plans
    → Records student skill assessments
    → Manages CCA participation

[ACD Module]
    → Provides holiday calendar to ATT, EXM, TT modules
    → Provides subject-teacher mapping to TT, LMS, EXM modules
    → Fires events: CalendarEventPublished, HolidayAdded, LessonPlanPublished

[Student/Parent Portal]
    → Views academic calendar events
    → Books PTM slots
    → Views CCA transcript
```

---

## 3. Stakeholders & Actors

| Actor | Role | Access Level |
|-------|------|-------------|
| School Admin | Full academics management | Full CRUD across all ACD features |
| Principal | Approves curriculum, oversees workload, approves escalated leaves | Approve/view all; Edit: settings |
| Department Head (HoD) | Reviews lesson plans, manages subject teachers in department | CRUD: own dept lesson plans, subject assignments |
| Class Teacher | Marks class-level assessments, submits lesson plans | CRUD: own class/subject plans and assessments |
| Subject Teacher | Submits lesson plans, records skill assessments, manages CCA | CRUD: own subject plans; Read: own class data |
| Student | Views calendar, views own skill report, views CCA record | Read-only: own data |
| Parent/Guardian | Views calendar, books PTM slots, views child's CCA transcript | Read + Create: PTM slots |
| System (automated) | Event publication, workload recalculation, PTM reminders | System-level reads and event dispatch |

---

## 4. Functional Requirements

### FR-ACD-001: Academic Calendar Management

**RBS Ref:** H.H4.1, H.H4.2

**REQ-ACD-001.1 — Academic Calendar Creation**
- Admin shall create one or more academic calendars per academic session: `calendar_name`, `academic_session_id`, `description`.
- Only one calendar can be designated `is_primary = 1` per session. The primary calendar is used by all other modules.
- Once a calendar is published (`status = 'published'`), events can only be added/modified by admin (not deleted without a reason log).

**REQ-ACD-001.2 — Calendar Event Management**
- Admin shall create events on a calendar with: `event_name`, `event_type` (holiday/exam_window/sports/cultural/ptm/foundation_day/other), `from_date`, `to_date`, `description`, `is_working_day`, `is_all_day`.
- Multi-day events are supported (from_date ≠ to_date).
- Events shall be publishable to Student/Parent portals via the portal visibility flag `is_visible_to_portal`.
- On publishing, the system fires `CalendarEventPublished` event to the NTF module for portal notification.

**REQ-ACD-001.3 — Holiday Management**
- Holidays are a subset of events with `event_type = 'holiday'` and `is_working_day = 0`.
- Admin shall mark holidays as full-day or half-day.
- On saving a holiday, the system fires `HolidayAdded` event; NTF module sends SMS/email alert to parents and staff.
- The ATT module consumes `acd_calendar_events` with `is_working_day = 0` as its source of non-attendance-counting days.

**REQ-ACD-001.4 — Session Management**
- Admin creates academic sessions with: `name`, `short_name` (e.g., '2025-26'), `start_date`, `end_date`.
- Only one session can be `is_active = 1` at a time (enforced via generated column unique constraint matching `glb_academic_sessions` pattern).
- A closed session (`is_active = 0`) shall be read-only — no new attendance, lesson plans, or assessments can be created against it.

**Acceptance Criteria:**
- Given admin creates "Holi - 17 Mar 2026" as a full-day holiday on the primary calendar, ATT module reduces March attendance denominator by 1 for all students.
- Given a cultural event "Annual Day - 15 Apr 2026" is published with `is_visible_to_portal = 1`, parents see it in their portal calendar within 1 hour.

**Test Cases:**
- TC-ACD-001.1: Create primary calendar → is_primary set; second attempt to create another primary calendar on same session → rejected.
- TC-ACD-001.2: Holiday saved → ATT module's working-day count decremented.
- TC-ACD-001.3: Event with from_date > to_date → validation error.
- TC-ACD-001.4: Deactivate session → subsequent lesson plan creation against that session → rejected.

---

### FR-ACD-002: Class Teacher & Subject Teacher Assignment

**RBS Ref:** H.H1.2 (ST.H1.2.1.1–2), H.H5.1

**REQ-ACD-002.1 — Class Teacher Assignment**
- Admin shall assign exactly one primary class teacher per class-section per academic session via `acd_class_teacher_jnt`.
- An assistant/co-class-teacher may optionally be assigned (second record with `is_primary = 0`).
- Class teacher assignment has `effective_from` and `effective_to` to support mid-session changes (e.g., teacher goes on maternity leave).
- Only one active primary class teacher per class-section at any time — enforced via generated column.
- The class teacher in `sch_class_section_jnt.class_teacher_id` reflects the current assignment and is updated by the ACD module on assignment change.

**REQ-ACD-002.2 — Subject Teacher Assignment**
- Admin or HoD shall map subjects to class-sections and assign a teacher per mapping: `class_section_id`, `subject_id`, `teacher_profile_id`, `academic_session_id`.
- One subject per class-section can have only one primary teacher and optionally one co-teacher.
- Subject teacher assignment is the authoritative source for: (a) who can mark that subject's attendance, (b) who can create lesson plans for that subject-class, (c) who is the default teacher when TT module generates timetable.
- Reassignment mid-session requires `effective_from` and old assignment's `effective_to` to be set accordingly.

**REQ-ACD-002.3 — Curriculum / Subject-Class Mapping**
- Admin shall map which subjects are taught to which classes: `class_id`, `subject_id`, `academic_session_id`, `is_core` (core vs elective), `subject_type_id`.
- Elective subjects additionally track `max_enrollment` and `min_enrollment` per class.
- Student can be enrolled in elective subjects via `acd_student_elective_jnt`.

**Acceptance Criteria:**
- Given admin assigns Teacher A as class teacher of 10A from 01-Apr-2025, `acd_class_teacher_jnt` record created with `is_primary = 1`.
- Given Teacher A goes on leave and Teacher B takes over from 01-Dec-2025, Teacher A's `effective_to = 30-Nov-2025` and Teacher B's record is added with `effective_from = 01-Dec-2025`.

**Test Cases:**
- TC-ACD-002.1: Assign two primary class teachers to same class-section same session → second rejected.
- TC-ACD-002.2: Subject teacher assignment without corresponding class-subject mapping → rejected with FK constraint.
- TC-ACD-002.3: Reassign subject teacher mid-session with overlap in date range → validation error.

---

### FR-ACD-003: Lesson Plan Management

**RBS Ref:** H.H2.1, H.H2.2

**REQ-ACD-003.1 — Lesson Plan Creation**
- Subject teachers shall create lesson plans scoped to: `teacher_profile_id`, `class_section_id`, `subject_id`, `academic_session_id`, `week_number` (1–52).
- Plan fields: `title`, `topic`, `learning_objectives`, `teaching_methods_json`, `resources_json`, `expected_outcomes`, `assessment_plan`, `remarks`.
- A single lesson plan covers one week. Monthly plans are a collection of 4 weekly plans.
- Teachers may attach digital content via `acd_lesson_plan_content_jnt` (FK to `acd_digital_contents`).

**REQ-ACD-003.2 — Lesson Plan Approval Workflow**
- Status transitions: DRAFT → SUBMITTED → APPROVED or REVISION_REQUESTED → APPROVED.
- On SUBMITTED, Department Head receives in-app notification.
- HoD can approve or request revision with comments.
- APPROVED plans trigger `LessonPlanPublished` event — notifies students/parents on portal.
- Only teachers can edit their own plans when in DRAFT or REVISION_REQUESTED status.

**REQ-ACD-003.3 — Progress Tracking**
- Each lesson plan has a `completion_percentage` field (0–100) updated by the teacher at week end.
- Reasons for incomplete plans (topics not covered) are recorded in `incomplete_remarks`.
- Admin dashboard shows overall lesson plan completion rate per department/class.

**REQ-ACD-003.4 — Digital Content Management**
- Teachers upload digital content: PDF, Video (URL or file), SCORM packages, links.
- Content fields: `title`, `content_type` (pdf/video/scorm/link/image), `file_path` or `url`, `description`, `tags_json`, `subject_id`, `class_id`.
- Content can be reused across multiple lesson plans and directly assigned to class-sections.
- Content can have scheduled availability: `available_from`, `available_to`.

**Acceptance Criteria:**
- Given a teacher submits a lesson plan for Week 12, Class 9B, Mathematics, HoD receives in-app notification.
- Given HoD requests revision, plan status changes to `REVISION_REQUESTED`, teacher receives notification.
- Given plan approved, students/parents in Class 9B see the lesson plan summary on their portal.

**Test Cases:**
- TC-ACD-003.1: Create lesson plan → DRAFT status assigned.
- TC-ACD-003.2: Submit plan → status = SUBMITTED, HoD notification fired.
- TC-ACD-003.3: Teacher edits plan in SUBMITTED state → rejected.
- TC-ACD-003.4: Approve plan → LessonPlanPublished event fired.
- TC-ACD-003.5: Upload PDF content → stored, accessible via content library.

---

### FR-ACD-004: Teacher Workload Management

**RBS Ref:** H.H5.1, H.H5.2

**REQ-ACD-004.1 — Workload Calculation**
- System shall calculate each teacher's assigned teaching load: count of active subject-teacher assignments per session, weighted by subject periods per week (from TT module or manual entry).
- `acd_teacher_workloads` stores: `teacher_profile_id`, `academic_session_id`, `total_assigned_periods_weekly`, `total_classes_assigned`, `subjects_list_json`.
- Calculation triggers on any subject-teacher assignment create/update/delete.

**REQ-ACD-004.2 — Workload Policy Enforcement**
- System reads `sch_teacher_profile.max_allocated_periods_weekly` and `min_allocated_periods_weekly` as constraints.
- If a new subject assignment would push a teacher above `max_allocated_periods_weekly`, system shows a warning (not a hard block by default — admin can override with acknowledgement).
- Admin can reassign subjects from overloaded to underloaded teachers within the same department.

**REQ-ACD-004.3 — Workload Reports**
- Subject-wise workload report: each subject row shows assigned teacher, periods/week, class count.
- Department-level summary: average load per department, over/under capacity flags.
- Teacher comparison report: side-by-side load comparison across all teachers in a department.

**Acceptance Criteria:**
- Given Teacher A has 38 periods/week assigned (max = 40), assigning one more 4-period subject shows warning but allows save.
- Given Teacher A reaches 45 periods (above max), system shows prominent warning and requires admin acknowledgement checkbox before save.

**Test Cases:**
- TC-ACD-004.1: Subject assignment created → workload recalculated within 5 seconds.
- TC-ACD-004.2: Assignment pushes teacher above max → warning displayed, save allowed with acknowledgement.
- TC-ACD-004.3: Workload report → correct period counts per teacher.

---

### FR-ACD-005: Skill & Competency Framework

**RBS Ref:** H.H6.1, H.H6.2

**REQ-ACD-005.1 — Skill Category Management**
- Admin shall define skill categories: `name`, `code`, `category_type` (cognitive/creative/physical/social/emotional/vocational), `description`.
- Under each category, individual skills are defined: `skill_name`, `descriptor`, `assessment_criteria`, `levels_json` (e.g., ["Beginning","Developing","Proficient","Advanced"]).
- Skills can be mapped to subjects: skill X is observable and assessable in subject Y.

**REQ-ACD-005.2 — Skill Assessment Recording**
- Teachers record per-student skill ratings: `student_id`, `skill_id`, `academic_session_id`, `term`, `rating_level` (maps to levels_json index), `notes`, `evidence_media_id`.
- One rating per student per skill per term (upsert pattern).
- System computes progress delta between terms for each skill.

**REQ-ACD-005.3 — Skill Reports**
- Individual student skill report: table of all skills rated per term, comparison chart.
- Class-level skill analysis: distribution of ratings across class for each skill.
- Skill improvement insights: identify students with declining skill performance.
- Skills report is included in student report card generated by the EXM/Gradebook module.

**Acceptance Criteria:**
- Given teacher rates Student Rahul's "Critical Thinking" skill as "Proficient" in Term 1 and "Advanced" in Term 2, the delta report shows +1 level improvement.
- Given admin downloads student skill report for Class 10B, a PDF lists all students with all skill ratings and trend indicators.

**Test Cases:**
- TC-ACD-005.1: Create skill with 4 levels → saved, accessible in assessment form.
- TC-ACD-005.2: Rate same student same skill same term twice → upsert, not duplicate.
- TC-ACD-005.3: Skill-subject mapping → subject assignment form shows linked skills.

---

### FR-ACD-006: Co-Curricular Activity (CCA) Management

**RBS Ref:** H.H7.1, H.H7.2

**REQ-ACD-006.1 — Activity Master**
- Admin shall create CCA activities: `name`, `code` (unique), `category` (sports/arts/club/nss/ncc/cultural/competition/other), `description`, `coordinator_id` (FK→sch_teacher_profile), `academic_session_id`, `venue`, `schedule_json` (days and times), `max_enrollment`, `is_competitive`.

**REQ-ACD-006.2 — Student Enrollment**
- Admin or coordinator enrolls students: `student_id`, `activity_id`, `academic_session_id`, `role` (participant/captain/secretary/president), `joined_date`, `exit_date`.
- Student may be enrolled in multiple activities with a cap per school (configurable: max activities per student).
- Enrollment status: active/completed/withdrawn.

**REQ-ACD-006.3 — CCA Attendance & Performance**
- Coordinator marks session-level attendance for each CCA session (similar to period attendance).
- Performance records: `student_id`, `activity_id`, `assessment_date`, `performance_rating` (1–10 scale), `notes`, `graded_by`.

**REQ-ACD-006.4 — Achievements & Awards**
- Coordinator records student achievements: `student_id`, `activity_id`, `achievement_type` (award/position/certificate/participation), `title`, `position` (1st/2nd/3rd/participation), `level` (inter-house/inter-school/district/state/national/international), `achievement_date`, `certificate_media_id`.

**REQ-ACD-006.5 — CCA Transcript Generation**
- On request, system generates a CCA transcript PDF per student per academic session.
- Transcript layout: student details, session year, list of activities enrolled, attendance %, performance ratings, achievements and awards.
- Format: school letterhead, principal signature block, official looking report (compatible with university admissions requirements).

**Acceptance Criteria:**
- Given Student Priya is enrolled in Football (captain) and Art Club, her CCA transcript shows both activities with attendance percentages and any awards.
- Given Football coordinator records "District Champions 2026" for the Football team, participating students' transcripts show this under Achievements.

**Test Cases:**
- TC-ACD-006.1: Create activity → saved in master.
- TC-ACD-006.2: Enroll student in activity → record created with 'active' status.
- TC-ACD-006.3: Enroll student in more activities than school limit → warning displayed.
- TC-ACD-006.4: Achievement recorded → appears in student's CCA transcript.
- TC-ACD-006.5: Transcript PDF generated → includes all activities, achievements, correct session.

---

### FR-ACD-007: Parent-Teacher Meeting (PTM) Management

**RBS Ref:** (Domain knowledge — standard Indian school requirement)

**REQ-ACD-007.1 — PTM Schedule Management**
- Admin creates a PTM schedule: `title` (e.g., "Term 1 PTM"), `academic_session_id`, `scheduled_date`, `from_time`, `to_time`, `slot_duration_minutes` (e.g., 10 min per slot), `applicable_class_sections` (JSON array or all).
- Multiple PTMs per session are supported.

**REQ-ACD-007.2 — Teacher Slot Assignment**
- System auto-generates time slots for each teacher based on PTM duration and teachers assigned to the class-sections in the PTM.
- Admin can manually adjust teacher availability windows per PTM.
- `acd_ptm_teacher_slots`: `ptm_schedule_id`, `teacher_profile_id`, `class_section_id`, `slot_date`, `slot_time`, `status` (available/booked/completed/cancelled).

**REQ-ACD-007.3 — Parent Slot Booking**
- Parents book a slot for each teacher of their child's class via portal: student-teacher combination shown.
- Booking: `acd_ptm_bookings` — `ptm_slot_id`, `student_id`, `guardian_id`, `booked_at`, `status` (booked/attended/no_show/cancelled).
- Duplicate booking prevention: one booking per student-teacher per PTM.
- Reminder notification sent 24 hours before the PTM.

**REQ-ACD-007.4 — PTM Completion**
- Teacher marks slot as `completed` after meeting. Optional: record meeting notes (private, only teacher + admin can view).
- Post-PTM summary report: attendance rate per teacher, no-show count, feedback from parents.

**Acceptance Criteria:**
- Given Term 1 PTM is created for 25-Apr-2026, system generates 20-minute slots from 09:00 to 13:00 for each of the 12 teachers of Class 8A.
- Given parent books slot with Math teacher at 10:20, slot status changes to 'booked', confirmation SMS sent to parent.

**Test Cases:**
- TC-ACD-007.1: Create PTM schedule → slots auto-generated correctly.
- TC-ACD-007.2: Parent books same teacher twice for same PTM → duplicate rejected.
- TC-ACD-007.3: Teacher marks slot completed → status updated, meeting notes saved.

---

### FR-ACD-008: Academic Progress Reporting

**RBS Ref:** H.H6.2 (ST.H6.2.2.1–2)

**REQ-ACD-008.1 — Student Academic Progress Dashboard**
- Admin and class teacher view per-student academic progress: lesson plan coverage for each subject (% topics taught), skill assessments per term, CCA participation summary, attendance linkage.
- Progress data pulls from: `acd_lesson_plans` (completion_percentage), `acd_skill_assessments`, `acd_student_cca_jnt`, ATT module (attendance %).

**REQ-ACD-008.2 — Academic Reports**
- Department-wise lesson plan completion report: per teacher, per subject, per week.
- CCA participation report: activity-wise enrollment counts, attendance %.
- Skill assessment summary: class-level rating distributions per skill.
- Reports exportable as PDF and Excel.

**Acceptance Criteria:**
- Given admin requests academic progress report for Class 9B, system shows all 30 subjects with lesson plan completion %, at-risk skill areas, and CCA summary.

---

## 5. Data Model

### 5.1 Table: `acd_academic_calendars` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK→glb_academic_sessions | |
| org_session_id | INT UNSIGNED | NULL, FK→sch_org_academic_sessions_jnt | School-level session link |
| name | VARCHAR(100) | NOT NULL | e.g., 'Academic Calendar 2025-26' |
| description | TEXT | NULL | |
| is_primary | TINYINT(1) | NOT NULL DEFAULT 0 | Only one per session |
| primary_flag | INT UNSIGNED | GENERATED (is_primary=1 → academic_session_id, else NULL) STORED | Unique constraint |
| status | ENUM('draft','published','archived') | NOT NULL DEFAULT 'draft' | |
| published_at | TIMESTAMP | NULL | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |
| **UNIQUE KEY** | (primary_flag) | | Enforces one primary per session |

### 5.2 Table: `acd_calendar_events` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| calendar_id | INT UNSIGNED | NOT NULL, FK→acd_academic_calendars | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK→glb_academic_sessions | Denormalized for query efficiency |
| event_name | VARCHAR(150) | NOT NULL | |
| event_type | ENUM('holiday','exam_window','sports','cultural','ptm','foundation_day','national_holiday','half_day','other') | NOT NULL | |
| from_date | DATE | NOT NULL | |
| to_date | DATE | NOT NULL | Same as from_date for single-day |
| from_time | TIME | NULL | For half-day or timed events |
| to_time | TIME | NULL | |
| description | TEXT | NULL | |
| is_working_day | TINYINT(1) | NOT NULL DEFAULT 1 | 0 for holidays → ATT denominator |
| is_half_day | TINYINT(1) | NOT NULL DEFAULT 0 | 0.5 day for ATT calculation |
| is_all_day | TINYINT(1) | NOT NULL DEFAULT 1 | |
| is_visible_to_portal | TINYINT(1) | NOT NULL DEFAULT 1 | Show to students/parents |
| notify_on_publish | TINYINT(1) | NOT NULL DEFAULT 0 | Trigger NTF event on publish |
| colour_code | CHAR(7) | NULL | Hex colour for calendar UI (e.g., '#FF5733') |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |

### 5.3 Table: `acd_class_teacher_jnt` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| class_section_id | INT UNSIGNED | NOT NULL, FK→sch_class_section_jnt | |
| teacher_profile_id | INT UNSIGNED | NOT NULL, FK→sch_teacher_profile | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK→glb_academic_sessions | |
| is_primary | TINYINT(1) | NOT NULL DEFAULT 1 | 1=class teacher, 0=assistant |
| effective_from | DATE | NOT NULL | |
| effective_to | DATE | NULL | NULL = currently active |
| active_flag | INT UNSIGNED | GENERATED (effective_to IS NULL → class_section_id+academic_session_id hash, else NULL) STORED | Unique active primary per section |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |

### 5.4 Table: `acd_subject_teacher_jnt` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| class_section_id | INT UNSIGNED | NOT NULL, FK→sch_class_section_jnt | |
| subject_id | INT UNSIGNED | NOT NULL, FK→sch_subjects | |
| teacher_profile_id | INT UNSIGNED | NOT NULL, FK→sch_teacher_profile | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK→glb_academic_sessions | |
| is_primary | TINYINT(1) | NOT NULL DEFAULT 1 | 1=primary, 0=co-teacher |
| effective_from | DATE | NOT NULL | |
| effective_to | DATE | NULL | NULL = currently active |
| periods_per_week | TINYINT UNSIGNED | NULL | Used for workload calculation |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |

### 5.5 Table: `acd_class_subject_jnt` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| class_id | INT UNSIGNED | NOT NULL, FK→sch_classes | |
| subject_id | INT UNSIGNED | NOT NULL, FK→sch_subjects | |
| subject_type_id | INT UNSIGNED | NULL, FK→sch_subject_types | Core/Elective/Optional |
| academic_session_id | INT UNSIGNED | NOT NULL, FK→glb_academic_sessions | |
| is_core | TINYINT(1) | NOT NULL DEFAULT 1 | 0 = elective |
| max_enrollment | SMALLINT UNSIGNED | NULL | Only for electives |
| min_enrollment | SMALLINT UNSIGNED | NULL | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |
| **UNIQUE KEY** | (class_id, subject_id, academic_session_id) | | |

### 5.6 Table: `acd_student_elective_jnt` 📐

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
| **UNIQUE KEY** | (student_id, class_subject_id, academic_session_id) | | |

### 5.7 Table: `acd_lesson_plans` 📐

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
| topic | VARCHAR(255) | NOT NULL | Chapter / topic name |
| learning_objectives | TEXT | NULL | |
| teaching_methods_json | JSON | NULL | e.g., ["lecture","group_discussion","demonstration"] |
| resources_json | JSON | NULL | e.g., [{"type":"textbook","ref":"Ch5 pg 82"}] |
| expected_outcomes | TEXT | NULL | |
| assessment_plan | TEXT | NULL | How will learning be assessed |
| remarks | TEXT | NULL | |
| status | ENUM('draft','submitted','revision_requested','approved') | NOT NULL DEFAULT 'draft' | |
| submitted_at | TIMESTAMP | NULL | |
| reviewed_by | INT UNSIGNED | NULL, FK→sch_teacher_profile | HoD reviewer |
| reviewed_at | TIMESTAMP | NULL | |
| review_remarks | TEXT | NULL | |
| approved_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| approved_at | TIMESTAMP | NULL | |
| completion_percentage | TINYINT UNSIGNED | NOT NULL DEFAULT 0 | 0–100, teacher updates at week end |
| incomplete_remarks | TEXT | NULL | Reason if < 100% |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |
| **UNIQUE KEY** | (teacher_profile_id, class_section_id, subject_id, academic_session_id, week_number) | | One plan per week |

### 5.8 Table: `acd_digital_contents` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | |
| title | VARCHAR(150) | NOT NULL | |
| content_type | ENUM('pdf','video_file','video_url','scorm','link','image','audio','presentation') | NOT NULL | |
| file_path | VARCHAR(500) | NULL | For uploaded files |
| url | VARCHAR(500) | NULL | For links/video URLs |
| media_id | INT UNSIGNED | NULL, FK→sys_media | If stored in sys_media |
| description | TEXT | NULL | |
| subject_id | INT UNSIGNED | NULL, FK→sch_subjects | |
| class_id | INT UNSIGNED | NULL, FK→sch_classes | |
| tags_json | JSON | NULL | e.g., ["photosynthesis","biology","class9"] |
| uploaded_by | INT UNSIGNED | NOT NULL, FK→sch_teacher_profile | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK→glb_academic_sessions | |
| available_from | DATETIME | NULL | Scheduled availability start |
| available_to | DATETIME | NULL | Scheduled availability end |
| view_count | INT UNSIGNED | NOT NULL DEFAULT 0 | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |

### 5.9 Table: `acd_lesson_plan_content_jnt` 📐

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
| **UNIQUE KEY** | (lesson_plan_id, digital_content_id) | | |

### 5.10 Table: `acd_teacher_workloads` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| teacher_profile_id | INT UNSIGNED | NOT NULL, FK→sch_teacher_profile | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK→glb_academic_sessions | |
| total_classes_assigned | TINYINT UNSIGNED | NOT NULL DEFAULT 0 | Count of distinct class-sections |
| total_subjects_assigned | TINYINT UNSIGNED | NOT NULL DEFAULT 0 | |
| total_periods_weekly | TINYINT UNSIGNED | NOT NULL DEFAULT 0 | Sum of periods_per_week across assignments |
| subjects_list_json | JSON | NULL | Summary of subject-class assignments |
| is_over_capacity | TINYINT(1) | NOT NULL DEFAULT 0 | Computed flag |
| last_calculated_at | TIMESTAMP | NULL | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| **UNIQUE KEY** | (teacher_profile_id, academic_session_id) | | |

### 5.11 Table: `acd_skill_categories` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| name | VARCHAR(100) | NOT NULL | e.g., 'Cognitive Skills' |
| code | VARCHAR(10) | NOT NULL, UNIQUE | e.g., 'COG','CRE','PHY' |
| category_type | ENUM('cognitive','creative','physical','social','emotional','vocational','other') | NOT NULL | |
| description | TEXT | NULL | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |

### 5.12 Table: `acd_skills` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| skill_category_id | INT UNSIGNED | NOT NULL, FK→acd_skill_categories | |
| skill_name | VARCHAR(100) | NOT NULL | e.g., 'Critical Thinking' |
| code | VARCHAR(10) | NOT NULL, UNIQUE | |
| descriptor | TEXT | NULL | Detailed description of the skill |
| assessment_criteria | TEXT | NULL | How to assess this skill |
| levels_json | JSON | NOT NULL | e.g., ["Beginning","Developing","Proficient","Advanced"] |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |

### 5.13 Table: `acd_skill_subject_jnt` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| skill_id | INT UNSIGNED | NOT NULL, FK→acd_skills | |
| subject_id | INT UNSIGNED | NOT NULL, FK→sch_subjects | |
| is_primary_mapping | TINYINT(1) | NOT NULL DEFAULT 1 | Primary vs secondary link |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| **UNIQUE KEY** | (skill_id, subject_id) | | |

### 5.14 Table: `acd_skill_assessments` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | |
| student_id | INT UNSIGNED | NOT NULL, FK→std_students | |
| skill_id | INT UNSIGNED | NOT NULL, FK→acd_skills | |
| class_section_id | INT UNSIGNED | NOT NULL, FK→sch_class_section_jnt | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK→glb_academic_sessions | |
| term | TINYINT UNSIGNED | NOT NULL | 1, 2, or 3 (term number) |
| rating_level | TINYINT UNSIGNED | NOT NULL | Index into skill.levels_json (0-based) |
| rating_label | VARCHAR(50) | NULL | Denormalized level label for display |
| notes | TEXT | NULL | |
| evidence_media_id | INT UNSIGNED | NULL, FK→sys_media | Supporting evidence attachment |
| assessed_by | INT UNSIGNED | NOT NULL, FK→sch_teacher_profile | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| **UNIQUE KEY** | (student_id, skill_id, academic_session_id, term) | | One rating per student per skill per term |

### 5.15 Table: `acd_cca_activities` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| name | VARCHAR(100) | NOT NULL | e.g., 'Football', 'Art Club' |
| code | VARCHAR(10) | NOT NULL, UNIQUE | |
| category | ENUM('sports','arts','club','nss','ncc','cultural','competition','academic_club','other') | NOT NULL | |
| description | TEXT | NULL | |
| coordinator_id | INT UNSIGNED | NOT NULL, FK→sch_teacher_profile | In-charge teacher |
| academic_session_id | INT UNSIGNED | NOT NULL, FK→glb_academic_sessions | |
| venue | VARCHAR(150) | NULL | |
| schedule_json | JSON | NULL | e.g., [{"day":"Monday","from":"14:30","to":"16:00"}] |
| max_enrollment | SMALLINT UNSIGNED | NULL | |
| is_competitive | TINYINT(1) | NOT NULL DEFAULT 0 | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |

### 5.16 Table: `acd_student_cca_jnt` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| student_id | INT UNSIGNED | NOT NULL, FK→std_students | |
| activity_id | INT UNSIGNED | NOT NULL, FK→acd_cca_activities | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK→glb_academic_sessions | |
| role | ENUM('participant','captain','secretary','president','vice_captain','coordinator') | NOT NULL DEFAULT 'participant' | |
| joined_date | DATE | NOT NULL | |
| exit_date | DATE | NULL | NULL = active |
| status | ENUM('active','completed','withdrawn') | NOT NULL DEFAULT 'active' | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| **UNIQUE KEY** | (student_id, activity_id, academic_session_id) | | |

### 5.17 Table: `acd_cca_sessions` 📐

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

### 5.18 Table: `acd_cca_attendance` 📐

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
| **UNIQUE KEY** | (cca_session_id, student_id) | | |

### 5.19 Table: `acd_cca_achievements` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| student_id | INT UNSIGNED | NOT NULL, FK→std_students | |
| activity_id | INT UNSIGNED | NOT NULL, FK→acd_cca_activities | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK→glb_academic_sessions | |
| achievement_type | ENUM('award','position','certificate','selection','participation') | NOT NULL | |
| title | VARCHAR(200) | NOT NULL | e.g., 'District Football Championship' |
| position | ENUM('1st','2nd','3rd','participation','runner_up','winner') | NULL | |
| level | ENUM('inter_house','inter_class','inter_school','district','zone','state','national','international') | NOT NULL | |
| achievement_date | DATE | NOT NULL | |
| certificate_media_id | INT UNSIGNED | NULL, FK→sys_media | Scanned/digital certificate |
| notes | TEXT | NULL | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |

### 5.20 Table: `acd_ptm_schedules` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| academic_session_id | INT UNSIGNED | NOT NULL, FK→glb_academic_sessions | |
| title | VARCHAR(150) | NOT NULL | e.g., 'Term 1 PTM 2025' |
| scheduled_date | DATE | NOT NULL | |
| from_time | TIME | NOT NULL | |
| to_time | TIME | NOT NULL | |
| slot_duration_minutes | TINYINT UNSIGNED | NOT NULL DEFAULT 10 | |
| applicable_classes_json | JSON | NULL | NULL = all classes; or array of class_section_ids |
| status | ENUM('draft','published','completed','cancelled') | NOT NULL DEFAULT 'draft' | |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| deleted_at | TIMESTAMP | NULL | |

### 5.21 Table: `acd_ptm_teacher_slots` 📐

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
| **UNIQUE KEY** | (ptm_schedule_id, teacher_profile_id, slot_date, slot_time) | | |

### 5.22 Table: `acd_ptm_bookings` 📐

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | |
| ptm_slot_id | BIGINT UNSIGNED | NOT NULL, FK→acd_ptm_teacher_slots | |
| ptm_schedule_id | INT UNSIGNED | NOT NULL, FK→acd_ptm_schedules | Denormalized |
| student_id | INT UNSIGNED | NOT NULL, FK→std_students | |
| guardian_id | INT UNSIGNED | NULL, FK→std_guardians | Which parent is attending |
| booked_at | TIMESTAMP | NOT NULL | |
| status | ENUM('booked','attended','no_show','cancelled') | NOT NULL DEFAULT 'booked' | |
| meeting_notes | TEXT | NULL | Private notes by teacher |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL, FK→sys_users | |
| created_at | TIMESTAMP | NULL | |
| updated_at | TIMESTAMP | NULL | |
| **UNIQUE KEY** | (ptm_slot_id, student_id) | | One booking per student per slot |

---

## 6. API & Route Specification

**All routes are proposed (📐). No routes exist yet.**

```
Route::middleware(['auth', 'verified', 'EnsureTenantHasModule:academics'])
    ->prefix('academics')
    ->name('academics.')
    ->group(function () {

    // ── ACADEMIC CALENDAR ─────────────────────────────────────────
    GET    /calendars                             → CalendarController@index            academics.calendar.index
    POST   /calendars                             → CalendarController@store            academics.calendar.store
    GET    /calendars/{calendar}                  → CalendarController@show             academics.calendar.show
    PUT    /calendars/{calendar}                  → CalendarController@update           academics.calendar.update
    PUT    /calendars/{calendar}/publish          → CalendarController@publish          academics.calendar.publish

    GET    /calendars/{calendar}/events           → CalendarEventController@index       academics.event.index
    POST   /calendars/{calendar}/events           → CalendarEventController@store       academics.event.store
    PUT    /calendars/{calendar}/events/{event}   → CalendarEventController@update      academics.event.update
    DELETE /calendars/{calendar}/events/{event}   → CalendarEventController@destroy     academics.event.destroy

    // ── TEACHER ASSIGNMENTS ────────────────────────────────────────
    GET    /class-teachers                        → ClassTeacherController@index        academics.classTeacher.index
    POST   /class-teachers                        → ClassTeacherController@store        academics.classTeacher.store
    PUT    /class-teachers/{assignment}           → ClassTeacherController@update       academics.classTeacher.update

    GET    /subject-teachers                      → SubjectTeacherController@index      academics.subjectTeacher.index
    POST   /subject-teachers                      → SubjectTeacherController@store      academics.subjectTeacher.store
    PUT    /subject-teachers/{assignment}         → SubjectTeacherController@update     academics.subjectTeacher.update
    DELETE /subject-teachers/{assignment}         → SubjectTeacherController@destroy    academics.subjectTeacher.destroy

    // ── CURRICULUM MAPPING ────────────────────────────────────────
    GET    /curriculum                            → CurriculumController@index          academics.curriculum.index
    POST   /curriculum                            → CurriculumController@store          academics.curriculum.store
    PUT    /curriculum/{mapping}                  → CurriculumController@update         academics.curriculum.update

    // ── LESSON PLANS ─────────────────────────────────────────────
    GET    /lesson-plans                          → LessonPlanController@index          academics.lessonPlan.index
    POST   /lesson-plans                          → LessonPlanController@store          academics.lessonPlan.store
    GET    /lesson-plans/{plan}                   → LessonPlanController@show           academics.lessonPlan.show
    PUT    /lesson-plans/{plan}                   → LessonPlanController@update         academics.lessonPlan.update
    PUT    /lesson-plans/{plan}/submit            → LessonPlanController@submit         academics.lessonPlan.submit
    PUT    /lesson-plans/{plan}/review            → LessonPlanController@review         academics.lessonPlan.review
    PUT    /lesson-plans/{plan}/approve           → LessonPlanController@approve        academics.lessonPlan.approve

    // ── DIGITAL CONTENT ───────────────────────────────────────────
    GET    /digital-content                       → DigitalContentController@index      academics.content.index
    POST   /digital-content                       → DigitalContentController@store      academics.content.store
    PUT    /digital-content/{content}             → DigitalContentController@update     academics.content.update
    DELETE /digital-content/{content}             → DigitalContentController@destroy    academics.content.destroy

    // ── WORKLOAD ─────────────────────────────────────────────────
    GET    /workload                              → WorkloadController@index            academics.workload.index
    GET    /workload/report                       → WorkloadController@report           academics.workload.report

    // ── SKILLS ───────────────────────────────────────────────────
    GET    /skills/categories                     → SkillCategoryController@index       academics.skillCategory.index
    POST   /skills/categories                     → SkillCategoryController@store       academics.skillCategory.store
    GET    /skills                                → SkillController@index               academics.skill.index
    POST   /skills                                → SkillController@store               academics.skill.store
    PUT    /skills/{skill}                        → SkillController@update              academics.skill.update

    GET    /skill-assessments                     → SkillAssessmentController@index     academics.skillAssessment.index
    POST   /skill-assessments                     → SkillAssessmentController@store     academics.skillAssessment.store
    PUT    /skill-assessments/{assessment}        → SkillAssessmentController@update    academics.skillAssessment.update
    GET    /skill-assessments/report              → SkillAssessmentController@report    academics.skillAssessment.report

    // ── CO-CURRICULAR ─────────────────────────────────────────────
    GET    /cca/activities                        → CcaActivityController@index         academics.cca.index
    POST   /cca/activities                        → CcaActivityController@store         academics.cca.store
    PUT    /cca/activities/{activity}             → CcaActivityController@update        academics.cca.update

    POST   /cca/activities/{activity}/enroll      → CcaEnrollmentController@store       academics.cca.enroll
    PUT    /cca/enrollments/{enrollment}          → CcaEnrollmentController@update      academics.cca.enrollment.update

    GET    /cca/sessions                          → CcaSessionController@index          academics.ccaSession.index
    POST   /cca/sessions                          → CcaSessionController@store          academics.ccaSession.store
    POST   /cca/sessions/{session}/attendance     → CcaAttendanceController@store       academics.ccaAttendance.store

    POST   /cca/achievements                      → CcaAchievementController@store      academics.ccaAchievement.store
    PUT    /cca/achievements/{achievement}        → CcaAchievementController@update     academics.ccaAchievement.update

    GET    /cca/transcript/{student}              → CcaTranscriptController@show        academics.ccaTranscript.show

    // ── PTM ───────────────────────────────────────────────────────
    GET    /ptm                                   → PtmScheduleController@index         academics.ptm.index
    POST   /ptm                                   → PtmScheduleController@store         academics.ptm.store
    PUT    /ptm/{schedule}                        → PtmScheduleController@update        academics.ptm.update
    PUT    /ptm/{schedule}/publish                → PtmScheduleController@publish       academics.ptm.publish
    GET    /ptm/{schedule}/slots                  → PtmSlotController@index             academics.ptmSlot.index
    POST   /ptm/{schedule}/slots/{slot}/book      → PtmBookingController@store          academics.ptmBooking.store
    PUT    /ptm/bookings/{booking}/complete       → PtmBookingController@complete       academics.ptmBooking.complete
    PUT    /ptm/bookings/{booking}/cancel         → PtmBookingController@cancel         academics.ptmBooking.cancel
});
```

---

## 7. UI Screen Inventory

| Screen ID | Screen Name | Route | Description |
|-----------|-------------|-------|-------------|
| ACD-SCR-01 | Academic Calendar View | academics.calendar.index | Full-page calendar with event colour coding |
| ACD-SCR-02 | Calendar Event Form | academics.event.store | Create/edit event with date range picker |
| ACD-SCR-03 | Holiday Manager | academics.event.index (filtered) | Quick-add holidays, holiday list |
| ACD-SCR-04 | Class Teacher Assignment | academics.classTeacher.index | Class-section grid, assign/reassign teachers |
| ACD-SCR-05 | Subject Teacher Assignment | academics.subjectTeacher.index | Subject-class matrix, teacher dropdown per cell |
| ACD-SCR-06 | Curriculum Mapping | academics.curriculum.index | Class × Subject grid with type indicators |
| ACD-SCR-07 | Teacher Workload Dashboard | academics.workload.index | Bar chart: periods/week per teacher, over-capacity flags |
| ACD-SCR-08 | My Lesson Plans (Teacher) | academics.lessonPlan.index | Weekly planner calendar view, DRAFT/SUBMITTED/APPROVED badges |
| ACD-SCR-09 | Create/Edit Lesson Plan | academics.lessonPlan.store | Form: week, topic, objectives, methods, resources |
| ACD-SCR-10 | Lesson Plan Review (HoD) | academics.lessonPlan.review | Side-by-side view: plan details + approve/revise |
| ACD-SCR-11 | Digital Content Library | academics.content.index | Card grid with type icons, search/filter |
| ACD-SCR-12 | Upload Digital Content | academics.content.store | Drag-drop upload with metadata form |
| ACD-SCR-13 | Skill Framework Manager | academics.skillCategory.index | Expandable tree: categories → skills → levels |
| ACD-SCR-14 | Student Skill Assessment Form | academics.skillAssessment.store | Class roster × skill rating grid |
| ACD-SCR-15 | Student Skill Report | academics.skillAssessment.report | Radar chart + tabular ratings, term comparison |
| ACD-SCR-16 | CCA Activity Master | academics.cca.index | Activity cards with enrollment stats |
| ACD-SCR-17 | Student CCA Enrollment | academics.cca.enroll | Student search + activity multi-select |
| ACD-SCR-18 | CCA Session Attendance | academics.ccaAttendance.store | Roll call list for a single CCA session |
| ACD-SCR-19 | CCA Achievements | academics.ccaAchievement.store | Achievement entry form with level and certificate upload |
| ACD-SCR-20 | CCA Transcript | academics.ccaTranscript.show | Print-ready PDF preview per student |
| ACD-SCR-21 | PTM Schedule Manager | academics.ptm.index | List of scheduled PTMs with slot generation status |
| ACD-SCR-22 | PTM Slot Booking (Parent) | academics.ptmSlot.index | Teacher slots grid, parent selects available slot |
| ACD-SCR-23 | PTM Dashboard | academics.ptm.show | Live booking stats, no-show count, completion % |

---

## 8. Business Rules & Domain Constraints

**BR-ACD-01:** Only one academic calendar per session can be designated `is_primary = 1`. This primary calendar is the authoritative source of holidays and non-working days for the ATT, EXM, and TT modules.

**BR-ACD-02:** A calendar event's `from_date` must not be later than `to_date`. Single-day events have `from_date = to_date`.

**BR-ACD-03:** Once a calendar is published (`status = 'published'`), events cannot be deleted — only soft-deleted with a mandatory deletion reason recorded in `sys_activity_logs`. This protects historical records.

**BR-ACD-04:** Only one primary class teacher (`is_primary = 1`) may be active (no `effective_to`) per class-section per academic session at any point in time.

**BR-ACD-05:** Subject teacher assignments must reference a valid curriculum mapping in `acd_class_subject_jnt` — a teacher cannot be assigned to a subject that is not formally mapped to that class.

**BR-ACD-06:** A lesson plan is locked for editing once its status is `submitted`. The teacher must wait for HoD to request revision before editing. Approved plans are permanently read-only (archived if the teacher creates a new plan for the same week/subject, which is an admin-level override).

**BR-ACD-07:** Only one lesson plan per teacher-class-section-subject-week combination is permitted. Attempting to create a duplicate returns a validation error with a link to edit the existing plan.

**BR-ACD-08:** Teacher workload calculation must be triggered asynchronously (queued job) whenever a subject-teacher assignment is created, updated, or deleted. The UI must show "last calculated" timestamp to make this clear.

**BR-ACD-09:** A school may configure maximum CCA enrollments per student (default 3 activities per session). Exceeding this limit raises a warning but allows admin override.

**BR-ACD-10:** CCA achievements at 'district' level or above trigger an automatic notification to the Principal and the student's class teacher via the NTF module.

**BR-ACD-11:** PTM slot booking is limited to one booking per student-teacher combination per PTM schedule. A parent with two children in the same class would see separate slot selections per child.

**BR-ACD-12:** A closed academic session (`is_active = 0`) is read-only. No new lesson plans, skill assessments, CCA enrollments, or calendar events can be created against a closed session.

**BR-ACD-13:** Skill assessment follows an upsert pattern — re-assessing the same student-skill-session-term combination updates the existing record. The system logs the previous rating to `sys_activity_logs` for audit.

---

## 9. Workflow & State Machines

### 9.1 Lesson Plan Lifecycle

```
Teacher creates plan
    → Status: DRAFT
    → Teacher can edit freely

Teacher submits plan
    → Status: SUBMITTED
    → Plan locked for teacher editing
    → HoD receives in-app notification

HoD reviews:
    → APPROVED
        → Plan published to student/parent portal (if notify_on_publish = 1)
        → LessonPlanPublished event fired to NTF module
        → Teacher notified of approval
    → REVISION_REQUESTED (with comments)
        → Status: REVISION_REQUESTED
        → Teacher unlocked to edit
        → Teacher notified with HoD comments

At week end:
    Teacher updates completion_percentage (0–100)
    If < 100: incomplete_remarks required
```

### 9.2 PTM Booking Lifecycle

```
Admin creates PTM Schedule
    → Status: DRAFT
    → System generates teacher-slot records (acd_ptm_teacher_slots)

Admin publishes PTM
    → Status: PUBLISHED
    → NTF module notifies parents of upcoming PTM
    → Parent portal shows booking form

Parent books slot
    → acd_ptm_bookings record created (status = 'booked')
    → Slot status updated to 'booked'
    → Confirmation SMS/email sent to parent

24 hours before PTM: Reminder notification fired

PTM Day:
    Teacher marks slot as ATTENDED or NO_SHOW
    Optional: teacher records meeting notes

Post-PTM:
    Admin marks PTM Schedule as COMPLETED
    Post-PTM summary report auto-generated
```

### 9.3 Teacher Assignment Change Workflow

```
New subject-teacher assignment required mid-session:

1. Locate existing assignment (old teacher)
2. Set effective_to = change_date - 1 day on old assignment
3. Create new assignment with effective_from = change_date
4. System fires RecalculateWorkloadJob for both old and new teachers
5. TT module notified of assignment change (via service event)
   → Existing timetable cells retain old teacher until manually updated
6. LMS and Exam modules now see new teacher for that class-subject
```

### 9.4 Academic Calendar Holiday Flow

```
Admin adds holiday event (is_working_day = 0):
    → acd_calendar_events record saved
    → If notify_on_publish = 1:
        → HolidayAdded event dispatched to NTF module
        → NTF sends SMS/email to all parents and staff
    → ATT module automatically excludes this date from:
        → total_working_days denominator in att_student_analytics
        → monthly attendance register columns
```

---

## 10. Non-Functional Requirements

**NFR-ACD-01 (Performance):** The academic calendar page must load and render all events for the current month in ≤ 2 seconds. PTM slot grid for 20 teachers across 50 available slots must render in ≤ 3 seconds.

**NFR-ACD-02 (Data Integrity):** All teacher assignment changes (class teacher, subject teacher) must be versioned using `effective_from`/`effective_to` rather than overwriting. The full historical record must always be queryable by date range.

**NFR-ACD-03 (Soft Deletes):** All master records (activities, skills, skill categories, leave types) use soft deletes (`deleted_at`) — hard deletes are prohibited on all `acd_*` tables.

**NFR-ACD-04 (Concurrency):** PTM slot booking must handle concurrent booking attempts gracefully. Database-level row locking (`SELECT FOR UPDATE`) must be used to prevent double-booking of a slot.

**NFR-ACD-05 (PDF Quality):** CCA transcripts and lesson plan PDFs must be generated using DomPDF (consistent with HPC and compliance report generation in the platform) with school letterhead support.

**NFR-ACD-06 (Scalability):** Workload recalculation (`RecalculateWorkloadJob`) must run asynchronously on the queue. Direct HTTP requests must not block waiting for workload recalculation.

**NFR-ACD-07 (Security):** Meeting notes in PTM bookings (`acd_ptm_bookings.meeting_notes`) are visible only to the recording teacher and school admins. Parents and students cannot read meeting notes.

**NFR-ACD-08 (Multi-tenancy):** All `acd_*` tables operate within the tenant database. No cross-tenant data access is possible. The `EnsureTenantHasModule:academics` middleware enforces licensing.

---

## 11. Cross-Module Dependencies

| Dependency | Direction | Purpose |
|-----------|-----------|---------|
| School Setup (`sch_*`) | Consumes | `sch_classes`, `sch_sections`, `sch_class_section_jnt`, `sch_subjects`, `sch_subject_types`, `sch_teacher_profile`, `sch_employees`, `sch_departments` |
| Student Management (`std_*`) | Consumes | `std_students`, `std_student_academic_sessions`, `std_guardians` for CCA enrollment and PTM bookings |
| Global Masters (`glb_*`) | Consumes | `glb_academic_sessions` for session-scoped data |
| System Config (`sys_*`) | Consumes | `sys_users` (created_by, reviewed_by), `sys_media` (digital content, certificates, evidence), `sys_activity_logs` (audit trail), `sys_dropdown_table` (status lookups) |
| Notification (NTF) | Pushes events | `CalendarEventPublished`, `HolidayAdded`, `LessonPlanPublished`, `PtmPublished`, `PtmBookingConfirmed`, `CcaAchievementHighLevel` |
| Attendance (ATT) | Provides | Holiday/non-working days via `acd_calendar_events.is_working_day = 0` |
| Timetable (TT) | Provides | Subject-teacher assignments consumed by TT generator; `periods_per_week` feeds TT activity configuration |
| Examination (EXM) | Provides | Skill assessment data included in report cards; exam window dates from academic calendar |
| LMS / Homework | Provides | Subject-teacher assignment gates teacher access to create homework/quiz |
| Syllabus (SLB) | Complements | Syllabus module defines content; ACD lesson plans reference syllabus units |
| HR & Payroll | Provides | Teacher workload data for HR compliance reporting |

---

## 12. Test Coverage Plan

**No tests exist. Full test suite required.**

| Test Class | Type | Priority | Description |
|-----------|------|----------|-------------|
| AcademicCalendarControllerTest | Feature | P0 | Calendar CRUD, primary uniqueness, publish workflow |
| HolidayEventTest | Feature | P0 | Holiday creation fires ATT working-day update, NTF event |
| ClassTeacherAssignmentTest | Feature | P0 | Primary uniqueness, mid-session reassignment with dates |
| SubjectTeacherAssignmentTest | Feature | P0 | Assignment requires curriculum mapping, workload trigger |
| LessonPlanWorkflowTest | Feature | P0 | Full DRAFT→SUBMITTED→REVISION_REQUESTED→APPROVED cycle |
| SkillAssessmentTest | Feature | P1 | Upsert pattern, delta calculation between terms |
| CcaEnrollmentTest | Feature | P1 | Max enrollment enforcement, achievement recording |
| CcaTranscriptPdfTest | Feature | P1 | PDF generated correctly with achievements |
| PtmBookingConcurrencyTest | Feature | P1 | Double-booking prevention under concurrent requests |
| WorkloadCalculationTest | Unit | P1 | Period count correct, over-capacity flag |
| CalendarEventValidationTest | Unit | P2 | from_date <= to_date, future date rules |
| DigitalContentUploadTest | Feature | P2 | File upload, content type handling |

---

## 13. Glossary

| Term | Definition |
|------|-----------|
| Academic Calendar | A structured record of all school events, holidays, and key dates for an academic session |
| Primary Calendar | The designated main calendar for a session, consumed by ATT, TT, and EXM modules |
| Class Teacher | The teacher formally responsible for a class-section (homeroom teacher in Indian schools) |
| Subject Teacher | A teacher assigned to teach a specific subject to a specific class-section |
| Lesson Plan | A teacher's weekly written plan of teaching topics, methods, and objectives |
| CCA | Co-Curricular Activity — activities beyond the academic curriculum (sports, arts, clubs) |
| CCA Transcript | An official school document listing a student's participation and achievements in CCAs |
| PTM | Parent-Teacher Meeting — scheduled meetings where parents discuss student progress with teachers |
| Skill Assessment | A qualitative rating of a student's demonstrated competency in a defined skill category |
| Teacher Workload | The total number of periods per week a teacher is assigned to teach across all class-sections |
| Elective Subject | An optional subject a student chooses (vs. core subjects which are compulsory) |
| DISE | District Information System for Education — Indian government school data reporting system |

---

## 14. Additional Suggestions (Analyst Notes)

**Priority 1 — Foundation:**
1. The Academic Calendar module is the critical dependency for ATT, TT, and EXM. Build it first, even before lesson plans or CCA, to unblock other modules.
2. Implement the subject-teacher assignment screen as a matrix (rows = subjects, columns = class-sections, cells = teacher dropdowns) — this visual format is far faster for admin data entry than individual form submissions.
3. Use database-level generated columns (as already done in `glb_academic_sessions` for `current_flag`) to enforce the primary-calendar and active-class-teacher uniqueness constraints.

**Priority 2 — Integration:**
4. ACD's `acd_calendar_events` is the single source of truth for holidays. The ATT module must not have its own parallel holiday store — always consume from ACD. This requires coordinating module loading order on tenant setup.
5. The subject-teacher `periods_per_week` field must be kept in sync with the TT module. Consider a service contract: when TT updates timetable, it calls an ACD service to update `periods_per_week` for affected assignments.
6. Lesson plan PDF generation for parent portal must be a lightweight read-only export (not the full editable form view). Design the PDF template to match the school letterhead format used across the platform.

**Priority 3 — UX and Analytics:**
7. The lesson plan completion tracker is a powerful tool for principal oversight. Build an admin dashboard widget showing % of lesson plans submitted and approved per department per week.
8. CCA transcript at state/national level achievements should be filterable for student award ceremonies — add a feature to bulk print transcripts for all students enrolled in a specific activity.
9. PTM slot auto-generation should be intelligent: if Math teacher teaches 8 sections, they get 8 different time blocks, not overlapping slots.
10. Consider integrating the digital content library with the LMS module's content delivery — teachers who upload content for a lesson plan should be able to assign it as LMS homework directly, avoiding duplicate uploads.

---

## 15. Appendices

### Appendix A: Proposed Table Summary

| Table | Purpose | Rows (est. annual) |
|-------|---------|-------------------|
| `acd_academic_calendars` | Calendar master | 1–3 per year |
| `acd_calendar_events` | All school events and holidays | ~100/year |
| `acd_class_teacher_jnt` | Class teacher assignments | ~60 (one per class-section) |
| `acd_subject_teacher_jnt` | Subject-teacher assignments | ~300 (10 sections × 30 subjects) |
| `acd_class_subject_jnt` | Curriculum mappings | ~200 (20 classes × 10 subjects avg) |
| `acd_student_elective_jnt` | Student elective choices | ~500 |
| `acd_lesson_plans` | Weekly lesson plans | ~15,000/year (50 teachers × 52 weeks × 6 subjects avg) |
| `acd_digital_contents` | Uploaded teaching content | ~2,000/year |
| `acd_lesson_plan_content_jnt` | Plan-content links | ~5,000/year |
| `acd_teacher_workloads` | Teacher workload summaries | ~60 (one per teacher per session) |
| `acd_skill_categories` | Skill category master | ~10 |
| `acd_skills` | Individual skills | ~50 |
| `acd_skill_subject_jnt` | Skill-subject mappings | ~100 |
| `acd_skill_assessments` | Student skill ratings | ~15,000/year (500 students × 10 skills × 3 terms) |
| `acd_cca_activities` | CCA activity master | ~20/year |
| `acd_student_cca_jnt` | Student enrollments | ~1,000/year |
| `acd_cca_sessions` | CCA session records | ~500/year |
| `acd_cca_attendance` | CCA session attendance | ~10,000/year |
| `acd_cca_achievements` | Student achievements | ~100/year |
| `acd_ptm_schedules` | PTM schedule master | ~4/year |
| `acd_ptm_teacher_slots` | Auto-generated slots | ~2,000/year (4 PTMs × 50 teachers × 10 slots) |
| `acd_ptm_bookings` | Parent bookings | ~1,500/year |

### Appendix B: Notification Event Codes

| Event Code | Trigger | Recipients |
|-----------|---------|-----------|
| `HOLIDAY_ADDED` | New holiday saved with notify = 1 | All Parents + All Staff (SMS + Email) |
| `CALENDAR_EVENT_PUBLISHED` | Calendar event marked visible to portal | All Parents + Students (In-App) |
| `LESSON_PLAN_SUBMITTED` | Teacher submits for review | Department HoD (In-App) |
| `LESSON_PLAN_REVISION_REQUESTED` | HoD requests revision | Subject Teacher (In-App) |
| `LESSON_PLAN_APPROVED` | HoD approves | Subject Teacher (In-App); Parents/Students if notify_on_publish (In-App) |
| `PTM_SCHEDULE_PUBLISHED` | PTM published for parent booking | All Parents in applicable classes (SMS + In-App) |
| `PTM_BOOKING_CONFIRMED` | Parent books a slot | Parent (SMS + In-App) |
| `PTM_REMINDER` | 24h before PTM | Parent with booked slot (SMS + In-App) |
| `CCA_ACHIEVEMENT_HIGH_LEVEL` | State/national/international achievement recorded | Principal + Class Teacher (In-App) |
| `WORKLOAD_OVER_CAPACITY` | Teacher exceeds max periods/week | HR Admin + Department HoD (In-App) |

### Appendix C: RBS Sub-Task Coverage Map

| RBS Sub-Task | FR Coverage |
|-------------|------------|
| ST.H1.1.1.1–2 (Create Session) | FR-ACD-001 (REQ-001.4) |
| ST.H1.1.2.1–2 (Activate/Deactivate Session) | FR-ACD-001 (REQ-001.4) |
| ST.H1.2.1.1–2 (Assign Subjects to Class) | FR-ACD-002 (REQ-002.3) |
| ST.H1.2.2.1–2 (Define Lesson Units) | FR-ACD-003 (REQ-003.1) |
| ST.H2.1.1.1–3 (Create Lesson Plan) | FR-ACD-003 (REQ-003.1) |
| ST.H2.1.2.1–2 (Publish Lesson Plan) | FR-ACD-003 (REQ-003.2) |
| ST.H2.2.1.1–2 (Upload Digital Content) | FR-ACD-003 (REQ-003.4) |
| ST.H2.2.2.1–2 (Assign Content to Class) | FR-ACD-003 (REQ-003.4) |
| ST.H3.* (Homework & Assignments) | Deferred to LMS-Homework module (HWK) |
| ST.H4.1.1.1–2 (Create Academic Event) | FR-ACD-001 (REQ-001.2) |
| ST.H4.1.2.1–2 (Event Publishing) | FR-ACD-001 (REQ-001.2) |
| ST.H4.2.1.1–2 (Add Holiday) | FR-ACD-001 (REQ-001.3) |
| ST.H4.2.2.1–2 (Holiday Notifications) | FR-ACD-001 (REQ-001.3) |
| ST.H5.1.1.1–2 (Calculate Teacher Load) | FR-ACD-004 (REQ-004.1) |
| ST.H5.1.2.1–2 (Adjust Load) | FR-ACD-004 (REQ-004.2) |
| ST.H5.2.1.1–2 (Load Reports) | FR-ACD-004 (REQ-004.3) |
| ST.H6.1.1.1–2 (Create Skill Categories) | FR-ACD-005 (REQ-005.1) |
| ST.H6.1.2.1–2 (Assign Skills to Subjects) | FR-ACD-005 (REQ-005.1) |
| ST.H6.2.1.1–2 (Record Skill Performance) | FR-ACD-005 (REQ-005.2) |
| ST.H6.2.2.1–2 (Skill Reports) | FR-ACD-005 (REQ-005.3) |
| ST.H7.1.1.1–2 (Create CCA Activity) | FR-ACD-006 (REQ-006.1) |
| ST.H7.1.2.1–2 (Student Participation) | FR-ACD-006 (REQ-006.2, REQ-006.3) |
| ST.H7.2.1.1–2 (Evaluate CCA Performance) | FR-ACD-006 (REQ-006.4, REQ-006.5) |

### Appendix D: Scope Boundary with Syllabus Module (SLB)

The ACD module explicitly does NOT cover:
- Chapter/unit/topic content management (owned by SLB — `slb_lessons`, `slb_topics`)
- Syllabus completion tracking at chapter level (owned by SLB)
- Textbook master management (owned by SLB's Books sub-module: `bok_*`)

The ACD module's lesson plans reference SLB units/topics by ID (`slb_lesson_id` may be an optional FK in `acd_lesson_plans` in a future iteration) but do not own the content.
